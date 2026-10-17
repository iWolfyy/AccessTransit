import assert from 'node:assert/strict';
import {initializeApp,deleteApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore} from 'firebase-admin/firestore';
if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8087'||process.env.FIREBASE_AUTH_EMULATOR_HOST!=='127.0.0.1:9099')throw Error('Local Auth/Firestore emulators required');
const app=initializeApp({projectId:'demo-accesstransit'},'verify-handover'),db=getFirestore(app),auth=getAuth(app);
const key='local-handover-'+Date.now(),password='LocalTest-Only25!',uids=[],tokens=[];
try{
  for(let i=0;i<4;i++){
    const uid=key+'-'+i,email=uid+'@local.test';uids.push(uid);
    await auth.createUser({uid,email,password});
    if(i===0)await auth.setCustomUserClaims(uid,{admin:true});
    await db.doc('users/'+uid).set({uid,email,name:'LOCAL HANDOVER '+i,role:i===1||i===2?'operator':'passenger',points:0});
    if(i===1||i===2){await db.doc('operator_access/'+uid).set({approved:true});await db.doc('driver_route_assignments/'+uid).set({active:true,routeId:key});}
    const signed=await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=local-validation-key',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({email,password,returnSecureToken:true})});
    tokens.push((await signed.json()).idToken);
  }
  const stops=[key+'-a',key+'-b'],time=new Date();
  await db.doc('routes/'+key).set({stops,catalogueSource:'operator_catalogue'});
  for(const id of stops)await db.doc('stations/'+id).set({name:id,catalogueSource:'operator_catalogue'});
  await db.doc('buses/'+key).set({driverId:uids[1],routeId:key,stops,catalogueSource:'operator_catalogue'});
  const initialStopTimes={[stops[0]]:{estimatedArrival:time},[stops[1]]:{estimatedArrival:new Date(+time+840000)}};
  await db.doc('service_runs/'+key).set({busId:key,driverId:uids[1],routeId:key,routeNo:'LOCAL TEST',status:'boarding',stops,plannedDepartureAt:time,latestStartAt:new Date(+time+1800000),serviceDate:'2026-10-16',initialStopTimes});
  const trip={serviceRunId:key,driverId:uids[1],busId:key,routeNo:'LOCAL TEST',status:'in_progress',stops,stopTimes:initialStopTimes,currentStopIndex:0,actualDepartureTime:null,scheduledDepartureTime:time,createdAt:time};
  await db.doc('trips/'+key).set(trip);
  await db.doc('operation_locks/'+uids[1]).set({active:true,tripId:key,busId:key});
  await db.doc('live_locations/'+key).set({tripId:key,driverId:uids[1],operatorId:uids[1],latitude:6.9,longitude:79.8,speed:0,heading:0,timestamp:time,status:'stopped',isBroadcasting:true});
  const call=async(i,path,body,expected=200)=>{
    const response=await fetch('http://127.0.0.1:8787/v2/'+path,{method:'POST',headers:{authorization:'Bearer '+tokens[i],'content-type':'application/json'},body:JSON.stringify(body)});
    const data=await response.json();assert.equal(response.status,expected,JSON.stringify(data));return data;
  };
  await call(3,'assistance/submit',{requestId:key,serviceRunId:key,busId:key,stationId:stops[0],boardingStationId:stops[0],alightingStationId:stops[1],purpose:'boarding',assistanceTypes:['Deploy Ramp']});
  await call(1,'assistance/action',{requestId:key,status:'acknowledged'});
  assert.equal((await call(0,'operations/detail',{runId:key})).driverId,uids[1]);
  assert.ok((await call(0,'operations/candidates',{runId:key})).items.some(r=>r.driverId===uids[2]));
  const input={operationId:key,runId:key,newDriverId:uids[2],expectedDriverId:uids[1],expectedVersion:0,reason:'LOCAL TEST shift handover'};
  await call(1,'operations/handover',input,403);
  await call(0,'operations/handover',input);
  assert.equal((await call(0,'operations/handover',input)).duplicate,true);
  const transferred=(await db.doc('trips/'+key).get()).data();
  assert.deepEqual(transferred.stopTimes,(await db.doc('service_runs/'+key).get()).data().initialStopTimes);
  assert.equal(transferred.actualDepartureTime,null);
  const paused=(await db.doc('live_locations/'+key).get()).data();assert.equal(paused.isBroadcasting,false);assert.equal(paused.timestamp.toMillis(),+time);
  await call(1,'assistance/get',{requestId:key},409);
  const direct=async(i,path,fields)=>fetch('http://127.0.0.1:8087/v1/projects/demo-accesstransit/databases/(default)/documents/'+path+'?'+Object.keys(fields).map(k=>'updateMask.fieldPaths='+k).join('&'),{method:'PATCH',headers:{authorization:'Bearer '+tokens[i],'content-type':'application/json'},body:JSON.stringify({fields})});
  assert.equal((await direct(1,'trips/'+key,{currentStopIndex:{integerValue:'1'}})).status,403);
  assert.equal((await direct(1,'live_locations/'+key,{latitude:{doubleValue:7}})).status,403);
  assert.equal((await direct(2,'live_locations/'+key,{isBroadcasting:{booleanValue:true},timestamp:{timestampValue:new Date().toISOString()}})).status,403);
  await call(2,'operations/accept',{runId:key,handoverVersion:1,gps:{latitude:6.91,longitude:79.81,speed:0,heading:0,accuracy:5,observedAt:new Date().toISOString()}});
  assert.equal((await db.doc('live_locations/'+key).get()).data().isBroadcasting,true);
  const deadline=Date.now()+15000;
  while(Date.now()<deadline&&(await db.doc('operation_handovers/'+key).get()).data().assistanceState!=='completed')await new Promise(r=>setTimeout(r,300));
  assert.equal((await db.doc('operation_handovers/'+key).get()).data().assistanceState,'completed');
  const request=(await db.doc('boarding_requests/'+key).get()).data();assert.equal(request.driverId,uids[2]);assert.equal(request.status,'pending');assert.equal(request.assignmentVersion,2);
  await call(2,'assistance/action',{requestId:key,status:'acknowledged'});
  assert.equal((await db.doc('operation_locks/'+uids[1]).get()).data().active,false);
  assert.equal((await db.doc('operation_locks/'+uids[2]).get()).data().active,true);
  // End only these synthetic fixtures, leaving no artificial running vehicle.
  await db.runTransaction(async tx=>{
    tx.update(db.doc('trips/'+key),{status:'cancelled'});tx.update(db.doc('service_runs/'+key),{status:'cancelled'});
    tx.update(db.doc('operation_locks/'+uids[2]),{active:false});tx.update(db.doc('live_locations/'+key),{isBroadcasting:false,status:'completed'});
  });
  console.log('PASS: actual local admin/driver/rider tokens; atomic active handover, preserved timeline, paused GPS, old-driver API/rules denial, pending GPS bypass denial, fresh new-driver resume, real worker retarget/reset and re-acceptance. Synthetic demo fixtures only.');
}finally{await deleteApp(app);}
