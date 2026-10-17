import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {initializeApp as adminApp,deleteApp as deleteAdminApp} from 'firebase-admin/app';
import {getAuth as adminAuth} from 'firebase-admin/auth';
import {getFirestore as adminFirestore} from 'firebase-admin/firestore';
import {initializeTestEnvironment} from '@firebase/rules-unit-testing';
import {initializeApp,deleteApp} from 'firebase/app';
import {getAuth,connectAuthEmulator,signInWithEmailAndPassword} from 'firebase/auth';
import {getFirestore,connectFirestoreEmulator,doc,getDocFromServer,setDoc,updateDoc,runTransaction,serverTimestamp,deleteDoc,Timestamp,terminate,setLogLevel} from 'firebase/firestore';
if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8087'||process.env.FIREBASE_AUTH_EMULATOR_HOST!=='127.0.0.1:9099')throw Error('Local demo emulators required');
setLogLevel('silent'); // Expected denied writes are asserted below.
const projectId='demo-accesstransit',key='local-loop-'+Date.now(),app=adminApp({projectId},key),db=adminFirestore(app),auth=adminAuth(app),clients=[];
let environment;
try{
  if ((await auth.listUsers(1)).users.length === 0) {
    const existing = await Promise.all(['users','buses','routes','stations','service_runs','reports','journeys']
      .map(kind=>db.collection(kind).limit(1).get()));
    if (existing.every(rows=>rows.empty)) {
      await import('./seed-local-validation.mjs');
      await import('./provision-local-admin.mjs');
      console.log('Initialized named synthetic fixtures only because Auth and functional demo collections were empty.');
    }
  }
  environment=await initializeTestEnvironment({projectId,firestore:{host:'127.0.0.1',port:8087,rules:readFileSync(new URL('../../firestore.rules',import.meta.url),'utf8')}});
  for(const role of ['admin','rider','driver']){
    const uid=key+'-'+role,email=uid+'@local.test',password='LocalTest-Only25!';
    await auth.createUser({uid,email,password});if(role==='admin')await auth.setCustomUserClaims(uid,{admin:true});
    await db.doc('users/'+uid).set({uid,email,name:'LOCAL LOOP '+role,role:role==='driver'?'operator':'passenger',points:0});
    const c=initializeApp({projectId,apiKey:'local-validation-key'},uid),a=getAuth(c),f=getFirestore(c);
    connectAuthEmulator(a,'http://127.0.0.1:9099',{disableWarnings:true});connectFirestoreEmulator(f,'127.0.0.1',8087);
    await signInWithEmailAndPassword(a,email,password);clients.push({app:c,db:f,uid});
  }
  const [admin,rider,driver]=clients;
  const stops=[key+'-a',key+'-b',key+'-return',key+'-c'];
  const physical=[stops[0],stops[1],stops[3]];
  const mapping={[stops[0]]:stops[0],[stops[1]]:stops[1],[stops[2]]:stops[0],[stops[3]]:stops[3]};
  const start=new Date(Date.now()+300000);
  const serviceDate=new Date(+start+19800000).toISOString().slice(0,10);
  await db.doc('routes/'+key).set({routeNo:'LOCAL LOOP',stops,stopStationIds:mapping,physicalStopIds:physical,catalogueSource:'operator_catalogue'});
  for(const id of physical) await db.doc('stations/'+id).set({name:'LOCAL LOOP '+id,lat:6.9,lng:79.8,catalogueSource:'operator_catalogue'});
  await db.doc('buses/'+key).set({busNo:'LOCAL LOOP',routeNo:'LOCAL LOOP',routeId:key,driverId:driver.uid,stops,stopStationIds:mapping,physicalStopIds:physical,catalogueRecordType:'vehicle',catalogueSource:'operator_catalogue'});
  await db.doc('operator_access/'+driver.uid).set({approved:true});
  await db.doc('driver_route_assignments/'+driver.uid).set({routeId:key,active:true});
  await db.doc('service_runs/'+key).set({busId:key,routeId:key,routeNo:'LOCAL LOOP',status:'scheduled',serviceDate,timezone:'Asia/Colombo',scheduleVersion:1,stops,stopStationIds:mapping,plannedDepartureAt:start,latestStartAt:new Date(+start+1800000),initialStopTimes:Object.fromEntries(stops.map((s,i)=>[s,{estimatedArrival:new Date(+start+i*600000),actualArrival:null}]))});
  const receipt=await getDocFromServer(doc(rider.db,'buses',key));assert.deepEqual(receipt.data().stops,stops);
  assert.equal(receipt.data().stopStationIds[stops[2]],stops[0]);
  assert.equal((await getDocFromServer(doc(rider.db,'stations',stops[2]))).exists(),false);
  const saved={journeyId:key,passengerId:rider.uid,busId:key,routeId:key,routeNumber:'LOCAL LOOP',routeTitle:'LOCAL TEST loop',origin:'Returning physical stop',destination:'End',
    fromStationId:stops[2],toStationId:stops[3],serviceRunId:key,selectedDate:Timestamp.fromDate(start),departureAt:Timestamp.fromMillis(+start+1200000),durationMinutes:10,estimatedFareLkr:0,
    wheelchairAccessRequired:false,stepFreeOnly:false,status:'confirmed',createdAt:serverTimestamp()};
  await setDoc(doc(rider.db,'journeys',key),saved);
  assert.equal((await getDocFromServer(doc(rider.db,'journeys',key))).data().fromStationId,stops[2]);
  const call=async(client,path,body)=>fetch('http://127.0.0.1:8787/v2/assistance/'+path,{method:'POST',headers:{authorization:'Bearer '+await getAuth(client.app).currentUser.getIdToken(),'content-type':'application/json'},body:JSON.stringify(body)});
  const input={requestId:key,serviceRunId:key,busId:key,stationId:stops[0],boardingStationId:stops[2],alightingStationId:stops[3],purpose:'boarding',assistanceTypes:['Deploy Ramp']};
  const response=await call(rider,'submit',input);assert.equal(response.status,200,await response.clone().text());
  const submitted=(await response.json()).request;assert.equal(submitted.stopIndex,2);assert.equal(submitted.stationId,stops[0]);assert.equal(submitted.driverId,driver.uid);
  assert.equal((await call(rider,'submit',{...input,requestId:key+'-wrong',stationId:stops[1]})).status,400);
  const inbox=await call(driver,'list',{serviceRunId:key});assert.equal(inbox.status,200);assert.equal((await inbox.json()).items[0].boardingIndex,2);
  assert.equal((await call(driver,'action',{requestId:key,status:'acknowledged'})).status,200);
  await db.doc('operation_locks/'+driver.uid).set({active:true,busId:key,tripId:key});
  await db.doc('trips/'+key).set({driverId:driver.uid,busId:key,status:'in_progress',currentStopIndex:1,actualDepartureTime:new Date()});
  await db.doc('service_runs/'+key).update({status:'in_progress',driverId:driver.uid});
  assert.equal((await call(rider,'submit',{...input,requestId:key+'-passed',boardingStationId:stops[0]})).status,409);
  const retained=await call(rider,'get',{requestId:key});assert.equal(retained.status,200);assert.equal((await retained.json()).request.status,'acknowledged');
  await db.doc('trips/'+key).update({currentStopIndex:3});
  const ended=await call(rider,'get',{requestId:key});assert.equal((await ended.json()).request.endReason,'stop-passed');
  await db.doc('service_runs/'+key).update({status:'completed'});
  await db.doc('trips/'+key).update({status:'completed'});
  await db.doc('operation_locks/'+driver.uid).update({active:false});
  console.log('PASS: real local tokens -> canonical visit mapping/public bus receipt -> later-visit owner bookmark -> exact driver assistance/ack -> first visit passed without expiring later visit -> expiry only after later visit. Progress changes are trusted synthetic fixtures, not a GPS/device test. Local rules loaded; no reset/shared data change.');

}finally{
  for(const c of clients){await terminate(c.db);await deleteApp(c.app);}await environment?.cleanup();await deleteAdminApp(app);
}
