import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc, Timestamp } from 'firebase/firestore';

// This script has no credentials or remote host/project override.
const projectId = 'demo-accesstransit';
if (process.env.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:8087' ||
    process.env.FIREBASE_AUTH_EMULATOR_HOST !== '127.0.0.1:9099') {
  throw new Error('Start the documented local Auth/Firestore emulators first. No remote writes allowed.');
}
const password = 'LocalTest-Only25!';
const users = {};
for (const [role, email] of [['passenger','passenger@local.test'], ['operator','operator@local.test'],
    ...[1,2,3,4,5].map(i=>['reader'+i,`reader${i}@local.test`])]) {
  const body = JSON.stringify({email,password,returnSecureToken:true});
  let response = await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=local-validation-key',
    {method:'POST',headers:{'content-type':'application/json'},body});
  let data = await response.json();
  if (data.error?.message === 'EMAIL_EXISTS') {
    response = await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=local-validation-key',
      {method:'POST',headers:{'content-type':'application/json'},body});
    data = await response.json();
  }
  if (!response.ok || !data.localId) throw new Error(`Local ${role} account setup failed`);
  users[role] = {uid:data.localId,email};
}
const env = await initializeTestEnvironment({projectId,firestore:{host:'127.0.0.1',port:8087}});
try {
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    const write = (path,data) => setDoc(doc(db,path),data);
    for (const [role,user] of Object.entries(users)) {
      await write(`users/${user.uid}`,{uid:user.uid,email:user.email,name:`Local ${role}`,role:role==='operator'?'operator':'passenger',
        phone:null,points:0,reportsSubmitted:0,verifiedCount:0,createdAt:Timestamp.now()});
    }
    await write(`operator_access/${users.operator.uid}`,{approved:true,validationOnly:true});
    const stops=['local_test_a','local_test_b','local_test_c'];
    for (const [index,id] of stops.entries()) {
      await write(`stations/${id}`,{name:`LOCAL TEST Stop ${index+1}`,hasRamp:true,hasElevator:false,
        stepFreeAccess:true,lat:6.9+index*0.001,lng:79.86+index*0.001,catalogueSource:'operator_catalogue',validationOnly:true});
    }
    await write('routes/local_test_route',{routeNo:'TEST25',routeName:'LOCAL TEST synthetic route',stops,
      description:'Synthetic local fixture, not real transit',catalogueSource:'operator_catalogue',validationOnly:true});
    await write(`driver_route_assignments/${users.operator.uid}`,{driverId:users.operator.uid,
      routeId:'local_test_route',active:true,claimRevision:0,validationOnly:true});
    // A future local time keeps the short fixture selectable during walkthrough.
    const start = new Date(Math.floor(Date.now()/60000)*60000+4*60000);
    const clocks = [0,10,20].map(min => new Intl.DateTimeFormat('en-GB',{timeZone:'Asia/Colombo',
      hour:'2-digit',minute:'2-digit',hourCycle:'h23'}).format(new Date(+start+min*60000)));
    await write('buses/local_test_bus',{routeNo:'TEST25',routeId:'local_test_route',busNo:'LOCAL TEST BUS',stops,
      scheduleTimes:clocks,scheduledDeparture:clocks[0],hasRamp:true,lowFloor:true,rampOk:true,
      rampCheckedAt:Timestamp.now(),rampCheckedBy:users.operator.uid,occupancy:'low',driverId:users.operator.uid,
      catalogueSource:'operator_catalogue',validationOnly:true});
    await write('service_runs/local_test_run',{busId:'local_test_bus',routeId:'local_test_route',routeNo:'TEST25',
      serviceDate:new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Colombo'}).format(start),status:'scheduled',
      plannedDepartureAt:Timestamp.fromDate(start),latestStartAt:Timestamp.fromMillis(+start+30*60000),stops,
      initialStopTimes:Object.fromEntries(stops.map((id,i)=>[id,{estimatedArrival:Timestamp.fromMillis(+start+i*10*60000),actualArrival:null}])),
      validationOnly:true});
  });
  console.log('Local fixtures ready: demo-accesstransit; passenger@local.test and operator@local.test. No production writes.');
} finally { await env.cleanup(); }
