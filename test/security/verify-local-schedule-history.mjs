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
const projectId='demo-accesstransit',key='local-history-'+Date.now(),app=adminApp({projectId},key),db=adminFirestore(app),auth=adminAuth(app),clients=[];
let environment;
try{
  environment=await initializeTestEnvironment({projectId,firestore:{host:'127.0.0.1',port:8087,rules:readFileSync(new URL('../../firestore.rules',import.meta.url),'utf8')}});
  for(const role of ['admin','rider']){
    const uid=key+'-'+role,email=uid+'@local.test',password='LocalTest-Only25!';
    await auth.createUser({uid,email,password});if(role==='admin')await auth.setCustomUserClaims(uid,{admin:true});
    await db.doc('users/'+uid).set({uid,email,name:'LOCAL HISTORY '+role,role:'passenger',points:0});
    const c=initializeApp({projectId,apiKey:'local-validation-key'},uid),a=getAuth(c),f=getFirestore(c);
    connectAuthEmulator(a,'http://127.0.0.1:9099',{disableWarnings:true});connectFirestoreEmulator(f,'127.0.0.1',8087);
    await signInWithEmailAndPassword(a,email,password);clients.push({app:c,db:f,uid});
  }
  const [admin,rider]=clients;
  const toAdmin=value=>value instanceof Timestamp?value.toDate():Array.isArray(value)?value.map(toAdmin):value&&typeof value==='object'?Object.fromEntries(Object.entries(value).map(([k,v])=>[k,toAdmin(v)])):value;
  for(const prefix of ['', 'sample_test/shared/']) {
    if(prefix) for(const client of clients) await db.doc(prefix+'users/'+client.uid).set({uid:client.uid,role:'passenger'});
    const stops=[key+'-a',key+'-b'],departure=Timestamp.fromMillis(Date.now()+900000),arrival=Timestamp.fromMillis(departure.toMillis()+600000);
    const oldId=key+'-old',nextId=key+'-new';
    const base={busId:key,routeId:key,routeNo:'LOCAL HISTORY',serviceDate:new Date(departure.toMillis()+19800000).toISOString().slice(0,10),timezone:'Asia/Colombo',scheduleVersion:1,status:'scheduled',stops,
      plannedDepartureAt:departure,latestStartAt:Timestamp.fromMillis(departure.toMillis()+1800000),initialStopTimes:{[stops[0]]:{estimatedArrival:departure,actualArrival:null},[stops[1]]:{estimatedArrival:arrival,actualArrival:null}}};
    await db.doc(prefix+'buses/'+key).set({routeId:key,routeNo:'LOCAL HISTORY',stops,catalogueSource:'operator_catalogue',catalogueRecordType:'vehicle'});
    for(const stop of stops) await db.doc(prefix+'stations/'+stop).set({name:'LOCAL HISTORY '+stop,catalogueSource:'operator_catalogue'});
    await db.doc(prefix+'routes/'+key).set({routeNo:'LOCAL HISTORY',stops,catalogueSource:'operator_catalogue'});
    await db.doc(prefix+'service_runs/'+oldId).set(toAdmin(base));
    const snapshot={schemaVersion:1,stops,stationIds:Object.fromEntries(stops.map(s=>[s,s])),names:{[stops[0]]:'Original boarding',[stops[1]]:'Original destination'},times:{[stops[0]]:departure,[stops[1]]:arrival},runVersion:1};
    const saved={journeyId:key,passengerId:rider.uid,busId:key,routeId:key,routeNumber:'LOCAL HISTORY',routeTitle:'LOCAL TEST history',origin:'Original boarding',destination:'Original destination',
      fromStationId:stops[0],toStationId:stops[1],selectedDate:departure,departureAt:departure,durationMinutes:10,estimatedFareLkr:0,serviceRunId:oldId,scheduleSnapshot:snapshot,
      wheelchairAccessRequired:false,stepFreeOnly:false,status:'confirmed',createdAt:serverTimestamp()};
    await setDoc(doc(rider.db,prefix+'journeys/'+key),saved);
    const nextDeparture=Timestamp.fromMillis(departure.toMillis()+1800000),nextArrival=Timestamp.fromMillis(arrival.toMillis()+1800000);
    await runTransaction(admin.db,async tx=>{
      const old=await tx.get(doc(admin.db,prefix+'service_runs/'+oldId));
      const next=await tx.get(doc(admin.db,prefix+'service_runs/'+nextId));
      assert.equal(old.data().status,'scheduled');assert.equal(next.exists(),false);
      tx.update(old.ref,{status:'cancelled',replacementRunId:nextId,replacementDepartureAt:nextDeparture,changeReason:'Public LOCAL TEST timetable change'});
      tx.set(next.ref,{...base,scheduleVersion:2,replacesRunId:oldId,plannedDepartureAt:nextDeparture,latestStartAt:Timestamp.fromMillis(nextDeparture.toMillis()+1800000),
        initialStopTimes:{[stops[0]]:{estimatedArrival:nextDeparture,actualArrival:null},[stops[1]]:{estimatedArrival:nextArrival,actualArrival:null}}});
      tx.set(doc(admin.db,prefix+'service_run_changes/'+oldId),{previousRunId:oldId,replacementRunId:nextId,previousVersion:1,replacementVersion:2,
        previousDepartureAt:departure,replacementDepartureAt:nextDeparture,reason:'Public LOCAL TEST timetable change',updatedBy:admin.uid,updatedAt:serverTimestamp()});
      tx.set(doc(admin.db,prefix+'admin_audit/'+oldId),{actorId:admin.uid,action:'LOCAL TEST replacement contract',createdAt:serverTimestamp(),targets:['service_runs/'+oldId,'service_runs/'+nextId]});
    });
    const receipt=await getDocFromServer(doc(rider.db,prefix+'journeys/'+key));
    assert.equal(receipt.metadata.fromCache,false);assert.equal(receipt.data().serviceRunId,oldId);
    assert.equal(receipt.data().scheduleSnapshot.runVersion,1);
    assert.equal(receipt.data().departureAt.toMillis(),departure.toMillis());
    assert.equal((await getDocFromServer(doc(rider.db,prefix+'service_runs/'+oldId))).data().replacementRunId,nextId);
    await assert.rejects(updateDoc(doc(rider.db,prefix+'journeys/'+key),{scheduleSnapshot:{...snapshot,runVersion:2}}),e=>e.code==='permission-denied');
    await assert.rejects(updateDoc(doc(admin.db,prefix+'service_run_changes/'+oldId),{reason:'Rewrite history'}),e=>e.code==='permission-denied');
  }
  console.log('PASS: actual local admin/rider tokens, normal/Sample acknowledged saved snapshots, atomic linked replacement/history, unchanged original saved times/version and denied snapshot/history rewrites. This exercises the production rules contract; Dart production service/transaction tests cover the reschedule implementation. No reset/shared deployment.');

}finally{
  for(const c of clients){await terminate(c.db);await deleteApp(c.app);}await environment?.cleanup();await deleteAdminApp(app);
}
