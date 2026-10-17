import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {initializeApp as adminApp,deleteApp as deleteAdminApp} from 'firebase-admin/app';
import {getAuth as adminAuth} from 'firebase-admin/auth';
import {getFirestore as adminFirestore} from 'firebase-admin/firestore';
import {initializeTestEnvironment} from '@firebase/rules-unit-testing';
import {initializeApp,deleteApp} from 'firebase/app';
import {getAuth,connectAuthEmulator,signInWithEmailAndPassword} from 'firebase/auth';
import {getFirestore,connectFirestoreEmulator,doc,getDoc,setDoc,updateDoc,runTransaction,serverTimestamp,Timestamp,collection,query,where,getDocs,terminate} from 'firebase/firestore';
if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8087'||process.env.FIREBASE_AUTH_EMULATOR_HOST!=='127.0.0.1:9099')throw Error('Local demo emulators required');
const projectId='demo-accesstransit',key='local-fares-'+Date.now(),app=adminApp({projectId},key),db=adminFirestore(app),auth=adminAuth(app),clients=[];
let environment;
try{
  // Load reviewed local rules without resetting or deleting any walkthrough data.
  environment=await initializeTestEnvironment({projectId,firestore:{host:'127.0.0.1',port:8087,rules:readFileSync(new URL('../../firestore.rules',import.meta.url),'utf8')}});
  for(const role of ['admin','rider']){
    const uid=key+'-'+role,email=uid+'@local.test',password='LocalTest-Only25!';
    await auth.createUser({uid,email,password});if(role==='admin')await auth.setCustomUserClaims(uid,{admin:true});
    await db.doc('users/'+uid).set({uid,email,name:'LOCAL FARE '+role,role:'passenger',points:0});
    const c=initializeApp({projectId,apiKey:'local-validation-key'},uid),a=getAuth(c),f=getFirestore(c);
    connectAuthEmulator(a,'http://127.0.0.1:9099',{disableWarnings:true});connectFirestoreEmulator(f,'127.0.0.1',8087);
    await signInWithEmailAndPassword(a,email,password);clients.push({app:c,db:f,uid});
  }
  const [admin,rider]=clients,stops=[key+'-a',key+'-b'];
  await db.doc('routes/'+key).set({stops,catalogueSource:'operator_catalogue'});
  await db.doc('buses/'+key).set({routeId:key,stops,catalogueSource:'operator_catalogue'});
  for(const id of stops)await db.doc('stations/'+id).set({name:id,catalogueSource:'operator_catalogue'});
  const time=Date.now(),source='https://authority.example/fictional-local-test';
  const publication={schemaVersion:1,state:'published',synthetic:true,busIds:[key],reviewReason:'LOCAL TEST fixture review only',
    validFromAt:Timestamp.fromMillis(time-86400000),validUntilAt:Timestamp.fromMillis(time+86400000),
    table:{reviewed:true,currency:'LKR',version:'fixture-table-v1',routePatternId:key,serviceClass:'normal',source,
      effectiveFrom:'2026-10-01',effectiveUntil:'2026-12-31',amounts:{A:{B:12345}}},
    mapping:{reviewed:true,version:'fixture-map-v1',tariffId:key,routePatternId:key,serviceClass:'normal',effectiveFrom:'2026-10-01',effectiveUntil:'2026-12-31',occurrences:stops,stageByOccurrence:{[stops[0]]:'A',[stops[1]]:'B'}},
    updatedBy:admin.uid,updatedAt:serverTimestamp()};
  const denied=async work=>{await assert.rejects(work,e=>e.code==='permission-denied');};
  await denied(setDoc(doc(rider.db,'fare_publications',key),publication));
  await runTransaction(admin.db,async tx=>{
    const route=await tx.get(doc(admin.db,'routes',key)),bus=await tx.get(doc(admin.db,'buses',key)),prior=await tx.get(doc(admin.db,'fare_publications',key));
    assert.equal(route.exists(),true);assert.deepEqual(bus.data().stops,stops);assert.equal(prior.exists(),false);
    tx.set(doc(admin.db,'fare_publications',key),publication);
    tx.set(doc(admin.db,'admin_audit',key),{actorId:admin.uid,action:'fare_publish',createdAt:serverTimestamp(),targets:['fare_publications/'+key]});
  });
  const visible=await getDocs(query(collection(rider.db,'fare_publications'),where('state','==','published'),where('synthetic','==',true),where('busIds','array-contains',key)));
  assert.equal(visible.size,1);assert.equal(visible.docs[0].data().table.amounts.A.B,12345);
  const quote={amountMinor:12345,currency:'LKR',tariffId:key,tariffVersion:'fixture-table-v1',mappingId:key,mappingVersion:'fixture-map-v1',source,
    routePatternId:key,serviceClass:'normal',boardingOccurrenceId:stops[0],alightingOccurrenceId:stops[1],serviceDate:new Date(time+19800000).toISOString().slice(0,10)};
  const journey={journeyId:key,passengerId:rider.uid,routeId:key,routeNumber:'LOCAL',routeTitle:'FICTIONAL TEST',busId:key,origin:'A',destination:'B',status:'confirmed',createdAt:serverTimestamp(),
    fromStationId:stops[0],toStationId:stops[1],selectedDate:Timestamp.fromMillis(time),departureAt:Timestamp.fromMillis(time+60000),durationMinutes:10,estimatedFareLkr:0,wheelchairAccessRequired:false,stepFreeOnly:false,fareQuote:quote};
  await setDoc(doc(rider.db,'journeys',key),journey);
  assert.deepEqual((await getDoc(doc(rider.db,'journeys',key))).data().fareQuote,quote);
  await denied(setDoc(doc(rider.db,'journeys',key+'-forged'),{...journey,journeyId:key+'-forged',fareQuote:{...quote,amountMinor:1}}));
  await denied(updateDoc(doc(admin.db,'fare_publications',key),{'table.amounts.A.B':1,updatedAt:serverTimestamp()}));
  await updateDoc(doc(admin.db,'fare_publications',key),{state:'archived',archiveReason:'LOCAL TEST finished',updatedBy:admin.uid,updatedAt:serverTimestamp()});
  assert.equal((await getDocs(query(collection(rider.db,'fare_publications'),where('state','==','published'),where('busIds','array-contains',key)))).size,0);
  await denied(setDoc(doc(rider.db,'journeys',key+'-retired'),{...journey,journeyId:key+'-retired'}));
  assert.equal((await getDoc(doc(rider.db,'journeys',key))).data().fareQuote.amountMinor,12345);
  console.log('PASS: actual local admin/rider tokens -> audited immutable synthetic fare publication -> bounded passenger query -> saved exact-cent/version snapshot -> forged amount denied -> archive removed current fare, preserved saved record, rejected new retired quotes. No official fares or shared Firebase were changed.');
}finally{
  for(const c of clients){await terminate(c.db);await deleteApp(c.app);}await environment?.cleanup();await deleteAdminApp(app);
}
