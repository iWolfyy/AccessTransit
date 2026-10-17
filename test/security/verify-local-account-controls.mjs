import assert from 'node:assert/strict';
import {initializeApp,deleteApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore} from 'firebase-admin/firestore';
if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8087'||process.env.FIREBASE_AUTH_EMULATOR_HOST!=='127.0.0.1:9099')throw Error('Fixed local demo emulators required');
const projectId='demo-accesstransit',key='local-accounts-'+Date.now(),app=initializeApp({projectId},key),db=getFirestore(app),auth=getAuth(app);
async function call(token,path,body){
  const r=await fetch('http://127.0.0.1:8787/v2/'+path,{method:'POST',headers:{authorization:'Bearer '+token,'content-type':'application/json'},body:JSON.stringify(body)});
  return {status:r.status,body:await r.json()};
}
try {
  const users=[];
  for(const role of ['admin','driver']){
    const uid=key+'-'+role,email=uid+'@local.test',password='LocalTest-Only25!';
    await auth.createUser({uid,email,password});if(role==='admin')await auth.setCustomUserClaims(uid,{admin:true});
    await db.doc('users/'+uid).set({uid,email,name:'LOCAL ACCESS '+role,role:role==='driver'?'operator':'passenger'});
    const response=await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=local-validation-key',{
      method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({email,password,returnSecureToken:true})});
    const login=await response.json();assert.equal(typeof login.idToken,'string');users.push({uid,token:login.idToken});
  }
  const [admin,driver]=users;
  await db.doc('operation_locks/'+driver.uid).set({active:true,busId:key,tripId:key,updatedAt:new Date()});
  await db.doc('trips/'+key).set({driverId:driver.uid,busId:key,status:'in_progress'});
  await db.doc('service_runs/'+key).set({driverId:driver.uid,busId:key,status:'boarding'});
  await db.doc('live_locations/'+key).set({driverId:driver.uid,tripId:key,isBroadcasting:true});
  const base={accountId:driver.uid,expectedRevision:0,action:'suspend',durationHours:72,reason:'LOCAL TEST reviewed incident'};
  const inputs=[{...base,operationId:key+'-one'},{...base,operationId:key+'-two'}];
  const results=await Promise.all(inputs.map(i=>call(admin.token,'accounts/change',i)));
  assert.deepEqual(results.map(r=>r.status).sort(),[200,409]);
  const winner=inputs[results.findIndex(r=>r.status===200)];
  assert.equal((await call(admin.token,'accounts/change',winner)).body.duplicate,true);
  const status=await call(driver.token,'account/status',{});
  assert.equal(status.body.state,'temporary');assert.equal(status.body.banReason,base.reason);
  assert.equal((await call(driver.token,'accounts/detail',{accountId:driver.uid})).status,403);
  assert.equal((await call(admin.token,'accounts/change',{...base,accountId:admin.uid,operationId:key+'-self'})).status,403);
  for(let n=0;n<24;n++){
    if((await db.doc('operation_locks/'+driver.uid).get()).data().active===false)break;
    await new Promise(resolve=>setTimeout(resolve,500));
  }
  assert.equal((await db.doc('operation_locks/'+driver.uid).get()).data().active,false);
  assert.equal((await db.doc('trips/'+key).get()).data().status,'cancelled');
  assert.equal((await db.doc('live_locations/'+key).get()).data().isBroadcasting,false);
  await db.doc('account_access/'+driver.uid).update({communityPermanent:true,communityPermanentReason:'LOCAL TEST independent review'});
  assert.equal((await call(admin.token,'accounts/change',{accountId:driver.uid,expectedRevision:1,operationId:key+'-restore',action:'restore',reason:'LOCAL TEST manual appeal accepted'})).status,200);
  const restored=await call(admin.token,'accounts/detail',{accountId:driver.uid});
  assert.equal(restored.body.manualActive,false);assert.equal(restored.body.communityRestricted,true);
  assert.equal((await call(driver.token,'account/status',{})).body.state,'permanent');
  assert.equal((await auth.getUser(driver.uid)).disabled,false);
  assert.equal((await db.doc('sample_test/shared/account_access/'+driver.uid).get()).exists,false);
  console.log('PASS: actual local admin/driver tokens; concurrent revision winner, retry idempotency, private manual reason, protected admin, worker cancellation/GPS/lock release, restore preserves community ban, Sample scope unchanged and Auth stays enabled. Synthetic records only; no reset.');
}finally{await deleteApp(app);}
