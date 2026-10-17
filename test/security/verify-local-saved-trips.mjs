import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {initializeApp as adminApp,deleteApp as deleteAdminApp} from 'firebase-admin/app';
import {getAuth as adminAuth} from 'firebase-admin/auth';
import {getFirestore as adminFirestore,Timestamp as AdminTimestamp} from 'firebase-admin/firestore';
import {initializeTestEnvironment} from '@firebase/rules-unit-testing';
import {initializeApp,deleteApp} from 'firebase/app';
import {getAuth,connectAuthEmulator,signInWithEmailAndPassword} from 'firebase/auth';
import {getFirestore,connectFirestoreEmulator,doc,collection,query,where,orderBy,documentId,startAfter,limit,getDocsFromServer,getDocFromServer,deleteDoc,setLogLevel,terminate} from 'firebase/firestore';
if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8087'||process.env.FIREBASE_AUTH_EMULATOR_HOST!=='127.0.0.1:9099')throw Error('Requires existing local demo emulators');
const projectId='demo-accesstransit',key='local-saved-'+Date.now(),app=adminApp({projectId},key),db=adminFirestore(app),auth=adminAuth(app);
const client=initializeApp({projectId,apiKey:'local-validation-key'},key),clientAuth=getAuth(client),clientDb=getFirestore(client);
let environment;
setLogLevel('silent');
try {
  environment=await initializeTestEnvironment({projectId,firestore:{host:'127.0.0.1',port:8087,rules:readFileSync(new URL('../../firestore.rules',import.meta.url),'utf8')}});
  await auth.createUser({uid:key,email:key+'@local.test',password:'LocalTest-Only25!'});
  connectAuthEmulator(clientAuth,'http://127.0.0.1:9099',{disableWarnings:true});connectFirestoreEmulator(clientDb,'127.0.0.1',8087);
  await signInWithEmailAndPassword(clientAuth,key+'@local.test','LocalTest-Only25!');
  for(const prefix of ['','sample_test/shared/']) {
    await db.doc(prefix+'users/'+key).set({uid:key,role:'passenger',name:'LOCAL saved list rider'});
    const batch=db.batch(),path=prefix+'journeys';
    const data={passengerId:key,routeId:'LOCAL-route',routeNumber:'LOCAL',routeTitle:'LOCAL ONLY',busId:'LOCAL-bus',origin:'LOCAL Boarding',destination:'LOCAL Destination',
      departureAt:AdminTimestamp.fromDate(new Date('2026-01-01T02:30:00Z')),status:'confirmed'};
    for(let i=0;i<45;i++) {
      const id=key+'-'+String(i).padStart(3,'0');
      batch.set(db.doc(path+'/'+id),{...data,journeyId:id,status:i===44?'completed':'confirmed',createdAt:AdminTimestamp.fromMillis(Date.now()-i*1000)});
    }
    batch.set(db.doc(path+'/'+key+'-legacy'),{...data,journeyId:key+'-legacy',status:'cancelled'});
    batch.set(db.doc(path+'/'+key+'-foreign'),{...data,journeyId:key+'-foreign',passengerId:key+'-other'});
    await batch.commit();
    const seen=[];let cursor=null,pages=0;
    do {
      const constraints=[where('passengerId','==',key),orderBy(documentId(),'desc'),...(cursor?[startAfter(cursor)]:[]),limit(21)];
      const response=await getDocsFromServer(query(collection(clientDb,path),...constraints));
      assert.equal(response.metadata.fromCache,false);assert.equal(response.metadata.hasPendingWrites,false);
      assert.ok(response.size<=21);
      const rows=response.docs.slice(0,20);assert.ok(rows.every(d=>d.data().passengerId===key));seen.push(...rows.map(d=>d.id));
      cursor=response.size>20?rows.at(-1).id:null;pages++;
      if(pages===1&&cursor) await deleteDoc(doc(clientDb,path,cursor)); // cursor remains usable after its document is removed.
    } while(cursor);
    assert.equal(pages,3);assert.equal(seen.length,46);assert.equal(new Set(seen).size,46);
    assert.ok(seen.includes(key+'-legacy'));assert.ok(!seen.includes(key+'-foreign'));
    const preview=await getDocsFromServer(query(collection(clientDb,path),where('passengerId','==',key),where('status','in',['confirmed','active']),orderBy('createdAt','desc'),orderBy(documentId(),'desc'),limit(1)));
    assert.equal(preview.size,1);assert.equal(preview.docs[0].id,key+'-000');
    await assert.rejects(getDocsFromServer(query(collection(clientDb,path),orderBy(documentId()),limit(20))),e=>e.code==='permission-denied');
    await assert.rejects(getDocFromServer(doc(clientDb,path,key+'-foreign')),e=>e.code==='permission-denied');
    await assert.rejects(deleteDoc(doc(clientDb,path,key+'-foreign')),e=>e.code==='permission-denied');
  }
  console.log('PASS: actual local rider token -> normal/Sample owner-scoped 20-row pages -> 46 past/closed/legacy records across 3 pages -> deleted cursor continuation -> bounded latest-open preview -> foreign/unscoped read and delete denied. Unique synthetic data only; no reset or shared deployment.');
} finally {
  await terminate(clientDb);await deleteApp(client);await environment?.cleanup();await deleteAdminApp(app);
}
