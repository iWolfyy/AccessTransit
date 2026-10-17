// Actual Firebase Auth/Firestore SDK effects, only in the isolated demo project.
import assert from 'node:assert/strict';
import {initializeApp,deleteApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore} from 'firebase-admin/firestore';
import {createAuthLifecycle} from '../../server/moderation/auth_lifecycle.mjs';
import {adminStore} from '../../server/moderation/admin_store.mjs';
import {createModerationApi} from '../../server/moderation/api.mjs';
import {createModerationPolicy} from '../../server/moderation/policy.mjs';

if(process.env.FIREBASE_AUTH_EMULATOR_HOST!=='127.0.0.1:9098'||process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8088'||process.env.GCLOUD_PROJECT!=='demo-phase30-auth')throw Error('Fixed isolated demo Auth/Firestore required; refusing real-project changes');
const projectId='demo-phase30-auth',app=initializeApp({projectId},'auth-lifecycle-smoke'),auth=getAuth(app),db=getFirestore(app),prefix='auth-smoke-'+Date.now();
try{
  const accounts=[];
  for(const role of ['admin','rider']){
    const uid=prefix+'-'+role,email=uid+'@local.test',password='LocalTest-Only25!';
    await auth.createUser({uid,email,password});if(role==='admin')await auth.setCustomUserClaims(uid,{admin:true});
    await db.doc('users/'+uid).set({uid,name:'Synthetic '+role,email,role:'passenger',points:0,reportsSubmitted:0,verifiedCount:0});
    accounts.push({uid,email,password});
  }
  const [admin,rider]=accounts;
  async function login(account){
    const r=await fetch('http://127.0.0.1:9098/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=local',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({email:account.email,password:account.password,returnSecureToken:true})});
    const data=await r.json();assert.equal(r.status,200);assert.equal(typeof data.idToken,'string');return data.idToken;
  }
  const adminToken=await login(admin),oldToken=await login(rider),store=adminStore(db),lifecycle=createAuthLifecycle({store,auth});
  const api=createModerationApi({auth,lifecycle,policy:createModerationPolicy({store,effectiveAt:new Date('2026-10-17T00:00:00Z')})});
  async function post(token,path,body){const r=await api(new Request('https://isolated.invalid/v2/'+path,{method:'POST',headers:{authorization:'Bearer '+token,'content-type':'application/json'},body:JSON.stringify(body)}));return {status:r.status,body:await r.json()};}
  const input=(action,revision)=>({accountId:rider.uid,operationId:prefix+'-'+action+'-'+revision,action,expectedRevision:revision,reason:'Synthetic reviewed lifecycle test'});
  const disabled=await post(adminToken,'auth/change',input('disable',0));assert.equal(disabled.status,200);assert.equal(disabled.body.status,'completed');
  assert.equal((await auth.getUser(rider.uid)).disabled,true);
  assert.equal((await post(oldToken,'account/status',{})).status,401);
  assert.equal((await post(adminToken,'auth/change',input('enable',1))).body.status,'completed');
  assert.equal((await auth.getUser(rider.uid)).disabled,false);
  assert.equal((await post(adminToken,'auth/change',input('revoke',2))).body.status,'completed');
  assert.equal((await post(oldToken,'account/status',{})).status,401);
  const cutoff=(await db.doc('account_access/'+rider.uid).get()).get('sessionsValidAfterSeconds');
  const wait=Math.max(0,cutoff*1000-Date.now()+100);if(wait)await new Promise(resolve=>setTimeout(resolve,wait));
  const newToken=await login(rider);assert.equal((await post(newToken,'account/status',{})).status,200);
  const shared=db.doc('reports/'+prefix);await shared.set({userId:rider.uid,description:'Retained synthetic audit reference'});
  assert.equal((await post(adminToken,'auth/change',input('request-delete',3))).body.status,'completed');
  assert.equal((await post(adminToken,'auth/change',input('disable',4))).body.status,'completed');
  const deletion={...input('approve-delete',5),confirmAccountId:rider.uid};
  assert.equal((await post(adminToken,'auth/change',deletion)).body.status,'completed');
  await assert.rejects(auth.getUser(rider.uid),{code:'auth/user-not-found'});
  const tombstone=(await db.doc('users/'+rider.uid).get()).data();assert.equal(tombstone.name,'Deleted account');assert.equal(tombstone.email,undefined);
  assert.equal((await shared.get()).get('userId'),rider.uid);
  assert.equal((await post(adminToken,'auth/change',deletion)).body.duplicate,true);
  console.log('PASS: isolated real Admin Auth SDK disable/enable/revoke/delete, actual Firebase ID-token checks, new sign-in eligibility, deletion review and anonymized tombstone with retained shared history. No real project/account touched.');
}finally{await deleteApp(app);}
