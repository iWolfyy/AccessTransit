import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {initializeApp as adminApp,deleteApp as deleteAdminApp} from 'firebase-admin/app';
import {getAuth as adminAuth} from 'firebase-admin/auth';
import {getFirestore as adminFirestore} from 'firebase-admin/firestore';
import {initializeTestEnvironment} from '@firebase/rules-unit-testing';
import {initializeApp,deleteApp} from 'firebase/app';
import {getAuth,connectAuthEmulator,signInWithEmailAndPassword} from 'firebase/auth';
import {getFirestore,connectFirestoreEmulator,doc,getDocFromServer,setDoc,updateDoc,runTransaction,serverTimestamp,onSnapshot,terminate,setLogLevel} from 'firebase/firestore';
if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8087'||process.env.FIREBASE_AUTH_EMULATOR_HOST!=='127.0.0.1:9099')throw Error('Local demo emulators required');
setLogLevel('silent'); // Expected denied writes are asserted below.
const projectId='demo-accesstransit',key='local-geometry-'+Date.now(),app=adminApp({projectId},key),db=adminFirestore(app),auth=adminAuth(app),clients=[];
let environment;
try{
  environment=await initializeTestEnvironment({projectId,firestore:{host:'127.0.0.1',port:8087,rules:readFileSync(new URL('../../firestore.rules',import.meta.url),'utf8')}});
  for(const role of ['admin','rider']){
    const uid=key+'-'+role,email=uid+'@local.test',password='LocalTest-Only25!';
    await auth.createUser({uid,email,password});if(role==='admin')await auth.setCustomUserClaims(uid,{admin:true});
    await db.doc('users/'+uid).set({uid,email,name:'LOCAL GEOMETRY '+role,role:'passenger',points:0});
    const c=initializeApp({projectId,apiKey:'local-validation-key'},uid),a=getAuth(c),f=getFirestore(c);
    connectAuthEmulator(a,'http://127.0.0.1:9099',{disableWarnings:true});connectFirestoreEmulator(f,'127.0.0.1',8087);
    await signInWithEmailAndPassword(a,email,password);clients.push({app:c,db:f,uid});
  }
  const [admin,rider]=clients,stops=[key+'-a',key+'-b'];
  await db.doc('routes/'+key).set({stops,catalogueSource:'operator_catalogue'});
  const shape={reviewed:true,synthetic:true,routeId:key,version:'fictional-shape-v1',source:'https://authority.example/FICTIONAL-ROAD',
    stops,stopVertices:[0,2],points:[{lat:6.9,lng:79.8},{lat:6.91,lng:79.8},{lat:6.91,lng:79.81}],
    reviewReason:'LOCAL TEST synthetic road review',updatedBy:admin.uid,updatedAt:serverTimestamp()};
  const denied=async work=>assert.rejects(work,e=>e.code==='permission-denied');
  await denied(setDoc(doc(rider.db,'route_geometries',key),shape));
  await runTransaction(admin.db,async tx=>{
    assert.deepEqual((await tx.get(doc(admin.db,'routes',key))).data().stops,stops);
    assert.equal((await tx.get(doc(admin.db,'route_geometries',key))).exists(),false);
    tx.set(doc(admin.db,'route_geometries',key),shape);
    tx.set(doc(admin.db,'admin_audit',key),{actorId:admin.uid,action:'route_geometry_publish',createdAt:serverTimestamp(),targets:['route_geometries/'+key]});
  });
  const receipt=await getDocFromServer(doc(rider.db,'route_geometries',key));
  assert.equal(receipt.metadata.fromCache,false);assert.equal(receipt.data().version,'fictional-shape-v1');
  assert.deepEqual(receipt.data().points,shape.points);
  await denied(updateDoc(doc(rider.db,'route_geometries',key),{version:'forged'}));
  const withdrawal=new Promise((resolve,reject)=>{
    const timeout=setTimeout(()=>{stop();reject(Error('Withdrawal did not reach passenger listener'));},5000);
    const stop=onSnapshot(doc(rider.db,'route_geometries',key),{includeMetadataChanges:true},s=>{
      if(!s.metadata.fromCache&&!s.metadata.hasPendingWrites&&s.data()?.reviewed===false){clearTimeout(timeout);stop();resolve();}
    },reject);
  });
  await updateDoc(doc(admin.db,'route_geometries',key),{reviewed:false,reviewReason:'LOCAL TEST withdrawing fictional road',updatedBy:admin.uid,updatedAt:serverTimestamp()});
  await withdrawal;
  console.log('PASS: actual local admin/rider tokens -> audited synthetic geometry with Firestore coordinate maps -> acknowledged passenger receipt -> unauthorized changes denied -> withdrawal received by passenger listener. No operating road data or shared Firebase changed.');
}finally{
  for(const c of clients){await terminate(c.db);await deleteApp(c.app);}await environment?.cleanup();await deleteAdminApp(app);
}
