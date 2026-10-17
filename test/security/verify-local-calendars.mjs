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
const projectId='demo-accesstransit',key='local-calendars-'+Date.now(),app=adminApp({projectId},key),db=adminFirestore(app),auth=adminAuth(app),clients=[];
let environment;
try{
  environment=await initializeTestEnvironment({projectId,firestore:{host:'127.0.0.1',port:8087,rules:readFileSync(new URL('../../firestore.rules',import.meta.url),'utf8')}});
  for(const role of ['admin','rider']){
    const uid=key+'-'+role,email=uid+'@local.test',password='LocalTest-Only25!';
    await auth.createUser({uid,email,password});if(role==='admin')await auth.setCustomUserClaims(uid,{admin:true});
    await db.doc('users/'+uid).set({uid,email,name:'LOCAL CALENDAR '+role,role:'passenger',points:0});
    const c=initializeApp({projectId,apiKey:'local-validation-key'},uid),a=getAuth(c),f=getFirestore(c);
    connectAuthEmulator(a,'http://127.0.0.1:9099',{disableWarnings:true});connectFirestoreEmulator(f,'127.0.0.1',8087);
    await signInWithEmailAndPassword(a,email,password);clients.push({app:c,db:f,uid});
  }
  const [admin,rider]=clients;
  const denied=async work=>assert.rejects(work,e=>e.code==='permission-denied');
  for(const prefix of ['', 'sample_test/shared/']) {
    if(prefix) await db.doc(prefix+'users/'+admin.uid).set({uid:admin.uid,role:'passenger'});
    const path=prefix+'service_schedules/'+key;
    const template={schemaVersion:1,version:1,state:'published',synthetic:true,
      busId:key,routeId:key,stops:['local-a','local-b'],weekdays:[1,3],departureMinutes:480,
      from:Timestamp.fromDate(new Date('2026-10-19T00:00:00Z')),
      until:Timestamp.fromDate(new Date('2026-10-26T00:00:00Z')),
      timezone:'Asia/Colombo',busSnapshot:{stops:['local-a','local-b'],scheduleTimes:['08:00','08:20']},
      updatedBy:admin.uid,updatedAt:serverTimestamp()};
    await denied(setDoc(doc(rider.db,path),template));
    await runTransaction(admin.db,async tx=>{
      assert.equal((await tx.get(doc(admin.db,path))).exists(),false);
      tx.set(doc(admin.db,path),template);
      tx.set(doc(admin.db,prefix+'admin_audit/'+key),{actorId:admin.uid,action:'publish_service_schedule',createdAt:serverTimestamp(),targets:[path]});
    });
    const receipt=await getDocFromServer(doc(admin.db,path));
    assert.equal(receipt.metadata.fromCache,false);assert.deepEqual(receipt.data().weekdays,[1,3]);
    await denied(getDocFromServer(doc(rider.db,path)));
    await denied(updateDoc(doc(admin.db,path),{departureMinutes:500,updatedAt:serverTimestamp()}));
    await denied(deleteDoc(doc(admin.db,path)));
    await updateDoc(doc(admin.db,path),{state:'retired',updatedBy:admin.uid,updatedAt:serverTimestamp()});
    assert.equal((await getDocFromServer(doc(admin.db,path))).data().state,'retired');
    await denied(updateDoc(doc(admin.db,path),{state:'published',updatedAt:serverTimestamp()}));
  }
  console.log('PASS: actual local admin/rider tokens; normal and Sample/Test calendar publication/audit, server receipt, private reads, immutable fields, denied deletion and one-way retirement. Existing demo data preserved; local rules loaded, no shared deployment. Run-generation algorithm is covered by Flutter service/transaction tests, not duplicated by this smoke.');

}finally{
  for(const c of clients){await terminate(c.db);await deleteApp(c.app);}await environment?.cleanup();await deleteAdminApp(app);
}
