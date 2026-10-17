import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {initializeApp as adminApp,deleteApp as deleteAdminApp} from 'firebase-admin/app';
import {getFirestore as adminFirestore,Timestamp} from 'firebase-admin/firestore';
import {initializeTestEnvironment} from '@firebase/rules-unit-testing';
import {initializeApp,deleteApp} from 'firebase/app';
import {getFirestore,connectFirestoreEmulator,collection,doc,query,where,orderBy,documentId,startAfter,limit,getDocsFromServer,onSnapshot,terminate,setLogLevel} from 'firebase/firestore';
if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8087')throw Error('Local demo emulator :8087 required');
const projectId='demo-accesstransit',key='local-segment-'+Date.now(),app=adminApp({projectId},key),db=adminFirestore(app);
const client=initializeApp({projectId,apiKey:'local-validation-key'},key),firestore=getFirestore(client);
connectFirestoreEmulator(firestore,'127.0.0.1',8087);setLogLevel('silent');
let environment;
try {
  environment=await initializeTestEnvironment({projectId,firestore:{host:'127.0.0.1',port:8087,rules:readFileSync(new URL('../../firestore.rules',import.meta.url),'utf8')}});
  for(const scope of ['','sample_test/shared/']) {
    const path=scope+'reports',base={policyVersion:2,targetType:'bus',targetId:key,status:'active',publicationState:'published',isDemo:false,
      userId:'LOCAL-FIXTURE',targetName:'LOCAL bus',problemType:'LOCAL barrier',severity:'minor',createdAt:Timestamp.now(),falseCount:0};
    const batch=db.batch();
    for(let i=0;i<45;i++)batch.set(db.doc(path+'/'+key+'-'+String(i).padStart(3,'0')),base);
    for(let i=0;i<31;i++)batch.set(db.doc(path+'/'+key+'-stop-'+i),{...base,targetType:'station',targetId:key+'-stop-'+i});
    batch.set(db.doc(path+'/'+key+'-hidden'),{...base,status:'hidden'});
    batch.set(db.doc(path+'/'+key+'-foreign'),{...base,targetId:key+'-other'});
    await batch.commit();
    const target=(type,ids)=>query(collection(firestore,path),where('status','==','active'),where('targetType','==',type),
      Array.isArray(ids)?where('targetId','in',ids):where('targetId','==',ids),orderBy(documentId(),'desc'));
    const preview=await getDocsFromServer(query(target('bus',key),limit(4)));assert.equal(preview.size,4);
    for(const ids of [[...Array(30)].map((_,i)=>key+'-stop-'+i),[key+'-stop-30']]) {
      const p=await getDocsFromServer(query(target('station',ids),limit(4)));
      assert.ok(p.size<=4);assert.ok(p.docs.every(d=>ids.includes(d.data().targetId)));
    }
    let cursor=null;const seen=[];
    do {
      const result=await getDocsFromServer(query(target('bus',key),...(cursor?[startAfter(cursor)]:[]),limit(21)));
      const rows=result.docs.slice(0,20);seen.push(...rows.map(d=>d.id));cursor=result.size>20?rows.at(-1).id:null;
    } while(cursor);
    assert.equal(seen.length,45);assert.equal(new Set(seen).size,45);
    assert.ok(!seen.some(id=>id.endsWith('hidden')||id.endsWith('foreign')));
    const watched=query(target('bus',key),limit(21)),hiddenId=preview.docs[0].id;
    let stop;
    const disappeared=new Promise((resolve,reject)=>{
      let initial=false;
      const timer=setTimeout(()=>{stop?.();reject(Error('Hidden report did not disappear'));},5000);
      stop=onSnapshot(watched,{includeMetadataChanges:true},s=>{
        if(s.metadata.fromCache||s.metadata.hasPendingWrites)return;
        if(!initial){initial=true;db.doc(path+'/'+hiddenId).update({status:'hidden',falseCount:5}).catch(reject);return;}
        if(!s.docs.some(d=>d.id===hiddenId)){clearTimeout(timer);stop();resolve();}
      },reject);
    });
    await disappeared;
    const stopPage=await getDocsFromServer(query(target('station',key+'-stop-30'),limit(21)));assert.equal(stopPage.size,1);
  }
  console.log('PASS: normal/Sample public target-scoped previews bounded to four/query, 31-stop chunk boundaries, 45 exact bus reports paged without duplicates/unrelated/hidden records, and fifth-False committed hiding removes an already visible row from its live listener. No reset or production data changed.');
} finally {await terminate(firestore);await deleteApp(client);await environment?.cleanup();await deleteAdminApp(app);}
