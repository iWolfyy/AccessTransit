import assert from 'node:assert/strict';
import {initializeApp,deleteApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore} from 'firebase-admin/firestore';
if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8087'||process.env.FIREBASE_AUTH_EMULATOR_HOST!=='127.0.0.1:9099')throw Error('Local Auth/Firestore emulators required');
const app=initializeApp({projectId:'demo-accesstransit'},'verify-assistance'),db=getFirestore(app),auth=getAuth(app);
const key='local-assistance-'+Date.now(),password='LocalTest-Only25!',uids=[],tokens=[];
try {
  for(let i=0;i<3;i++){
    const uid=key+'-'+i,email=uid+'@local.test';uids.push(uid);await auth.createUser({uid,email,password});
    await db.doc('users/'+uid).set({uid,email,name:'LOCAL TEST '+i,role:i?'operator':'passenger',points:0,reportsSubmitted:0,verifiedCount:0});
    const signed=await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=local-validation-key',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({email,password,returnSecureToken:true})});
    tokens.push((await signed.json()).idToken);
    if(i){await db.doc('operator_access/'+uid).set({approved:true});await db.doc('driver_route_assignments/'+uid).set({active:true,routeId:key});}
  }
  const stops=[key+'-a',key+'-b'];
  await db.doc('routes/'+key).set({stops,catalogueSource:'operator_catalogue'});
  for(const id of stops)await db.doc('stations/'+id).set({name:id,catalogueSource:'operator_catalogue'});
  await db.doc('buses/'+key).set({driverId:uids[1],routeId:key,stops,catalogueSource:'operator_catalogue'});
  await db.doc('service_runs/'+key).set({busId:key,routeId:key,routeNo:'LOCAL TEST',status:'scheduled',stops,latestStartAt:new Date(Date.now()+1800000),initialStopTimes:{[stops[0]]:{estimatedArrival:new Date(Date.now()+240000)},[stops[1]]:{estimatedArrival:new Date(Date.now()+840000)}}});
  const call=(i,path,body)=>fetch('http://127.0.0.1:8787/v2/assistance/'+path,{method:'POST',headers:{authorization:'Bearer '+tokens[i],'content-type':'application/json'},body:JSON.stringify(body)});
  const input={requestId:key,serviceRunId:key,busId:key,stationId:stops[0],boardingStationId:stops[0],alightingStationId:stops[1],purpose:'boarding',assistanceTypes:['Deploy Ramp']};
  assert.equal((await call(0,'submit',{...input,driverId:uids[2]})).status,400);
  const submitted=await call(0,'submit',input);assert.equal(submitted.status,200);assert.equal((await submitted.json()).request.driverId,uids[1]);
  assert.equal((await (await call(0,'list',{})).json()).items[0].id,key);
  assert.equal((await (await call(0,'list',{after:key})).json()).items.length,0);
  assert.equal((await call(2,'get',{requestId:key})).status,409);
  assert.equal((await call(1,'action',{requestId:key,status:'acknowledged'})).status,200);
  assert.equal((await (await call(0,'submit',input)).json()).request.status,'acknowledged');
  // Simulate a trusted, stopped-bus assignment change with an audit event.
  await db.runTransaction(async tx=>{tx.update(db.doc('buses/'+key),{driverId:uids[2]});tx.create(db.doc('admin_audit/'+key),{action:'LOCAL TEST stopped-bus handover',oldDriver:uids[1],newDriver:uids[2],createdAt:new Date()});});
  assert.equal((await call(1,'get',{requestId:key})).status,409);
  const inbox=await call(2,'list',{serviceRunId:key});assert.equal(inbox.status,200);const item=(await inbox.json()).items[0];assert.equal(item.driverId,uids[2]);assert.equal(item.status,'pending');assert.equal(item.assignmentVersion,2);
  const direct=i=>fetch('http://127.0.0.1:8087/v1/projects/demo-accesstransit/databases/(default)/documents/boarding_requests/'+key,{headers:{authorization:'Bearer '+tokens[i]}});
  assert.equal((await direct(1)).status,403);assert.equal((await direct(2)).status,200);
  assert.equal((await call(2,'action',{requestId:key,status:'acknowledged'})).status,200);
  await db.doc('service_runs/'+key).update({status:'cancelled'});
  const deadline=Date.now()+15000;
  while(Date.now()<deadline&&(await db.doc('boarding_requests/'+key).get()).data().status!=='expired')await new Promise(r=>setTimeout(r,300));
  assert.equal((await db.doc('boarding_requests/'+key).get()).data().status,'expired');
  assert.equal((await (await call(0,'get',{requestId:key})).json()).request.endReason,'run-ended');
  console.log('PASS: actual local Auth -> run-bound submit/retry/ack -> audited stopped-bus assignment change -> old driver API/rules denied -> new driver re-ack -> terminal run expires via real worker. Synthetic demo data only.');
}finally{await deleteApp(app);}
