import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {initializeApp,deleteApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore} from 'firebase-admin/firestore';
if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8087'||process.env.FIREBASE_AUTH_EMULATOR_HOST!=='127.0.0.1:9099')throw Error('Local Auth/Firestore emulators required');
const app=initializeApp({projectId:'demo-accesstransit'},'verify-notifications'),db=getFirestore(app),auth=getAuth(app);
const key='local-notification-'+Date.now(),password='LocalTest-Only25!',uids=[],tokens=[];
try{
  for(let i=0;i<3;i++){
    const uid=key+'-'+i,email=uid+'@local.test';uids.push(uid);await auth.createUser({uid,email,password});
    await db.doc('users/'+uid).set({uid,email,name:'LOCAL NOTIFICATION '+i,role:i?'operator':'passenger',points:0});
    if(i){await db.doc('operator_access/'+uid).set({approved:true});await db.doc('driver_route_assignments/'+uid).set({active:true,routeId:key});}
    const signed=await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=local-validation-key',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({email,password,returnSecureToken:true})});
    tokens.push((await signed.json()).idToken);
  }
  const call=async(i,path,body,expected=200)=>{
    const response=await fetch('http://127.0.0.1:8787/v2/'+path,{method:'POST',headers:{authorization:'Bearer '+tokens[i],'content-type':'application/json'},body:JSON.stringify(body)});
    const data=await response.json();assert.equal(response.status,expected,JSON.stringify(data));return data;
  };
  const registration={token:'local-'+createHash('sha256').update(key).digest('hex'),locale:'si',platform:'android'};
  const device=await call(1,'notifications/register',registration);assert.equal(device.provider,'local');
  assert.equal((await call(1,'notifications/register',registration)).generation,1);
  await call(1,'notifications/register',{...registration,token:'fcm-'+('x'.repeat(48))},400);
  const stops=[key+'-a',key+'-b'],time=new Date();
  await db.doc('routes/'+key).set({stops,catalogueSource:'operator_catalogue'});
  for(const id of stops)await db.doc('stations/'+id).set({name:id,catalogueSource:'operator_catalogue'});
  await db.doc('buses/'+key).set({driverId:uids[1],routeId:key,stops,catalogueSource:'operator_catalogue'});
  await db.doc('service_runs/'+key).set({busId:key,routeId:key,routeNo:'LOCAL',status:'scheduled',stops,latestStartAt:new Date(+time+1800000),initialStopTimes:{[stops[0]]:{estimatedArrival:new Date(+time+240000)},[stops[1]]:{estimatedArrival:new Date(+time+840000)}}});
  await call(0,'assistance/submit',{requestId:key,serviceRunId:key,busId:key,stationId:stops[0],boardingStationId:stops[0],alightingStationId:stops[1],purpose:'boarding',assistanceTypes:['Deploy Ramp']});
  const wait=async(version)=>{
    const path=`notification_outbox/${key}/events/assistance-${version}`,deadline=Date.now()+20000;
    while(Date.now()<deadline&&(await db.doc(path).get()).data()?.pushState!=='simulated')await new Promise(r=>setTimeout(r,300));
    assert.equal((await db.doc(path).get()).data()?.pushState,'simulated');
    return createHash('sha256').update(path).digest('hex');
  };
  const first=await wait(1);
  assert.equal((await db.doc('boarding_requests/'+key).get()).data().status,'pending');
  assert.equal((await call(1,'notifications/open',{eventId:first})).request.driverId,uids[1]);
  await call(2,'notifications/open',{eventId:first},409);
  // Same device token on a shared phone moves to the new signed-in identity.
  const rebound=await call(2,'notifications/register',registration);assert.equal(rebound.generation,2);
  await call(1,'notifications/remove',{deviceId:device.deviceId});
  assert.equal((await db.doc('notification_devices/'+device.deviceId).get()).data().enabled,true);
  await db.runTransaction(async tx=>{
    tx.update(db.doc('buses/'+key),{driverId:uids[2]});
    tx.create(db.doc('admin_audit/'+key),{action:'LOCAL TEST stopped-bus assignment change',createdAt:new Date()});
  });
  // The existing assistance worker retargets and creates a fresh notification.
  const second=await wait(2);
  await call(1,'notifications/open',{eventId:first},409);
  assert.equal((await call(2,'notifications/open',{eventId:second})).request.status,'pending');
  await call(2,'assistance/action',{requestId:key,status:'acknowledged'});
  await call(0,'assistance/action',{requestId:key,status:'cancelled'});
  await call(2,'notifications/open',{eventId:second},409);
  await call(2,'notifications/remove',{deviceId:device.deviceId});
  assert.equal((await db.doc('notification_devices/'+device.deviceId).get()).data().enabled,false);
  await db.doc('service_runs/'+key).update({status:'cancelled'});
  console.log('PASS: actual local tokens -> device registration -> real bounded worker -> SIMULATED delivery only -> current-driver open -> account/device rebind and retarget -> stale/terminal opens denied -> unregister. No FCM, OS notification or background-device delivery was performed.');
}finally{await deleteApp(app);}
