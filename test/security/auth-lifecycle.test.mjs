import assert from 'node:assert/strict';
import {test} from 'node:test';
import {createHash} from 'node:crypto';
import {createAuthLifecycle} from '../../server/moderation/auth_lifecycle.mjs';
import {createModerationApi} from '../../server/moderation/api.mjs';

const key=id=>createHash('sha256').update(id).digest('hex');
function fixture(){
  const time=new Date('2026-10-17T10:00:00Z'),rows=new Map([
    ['users/admin',{uid:'admin',name:'Admin'}],['users/other-admin',{uid:'other-admin'}],
    ['users/rider',{uid:'rider',name:'Private name',email:'private@example.test',phone:'123',points:40,reportsSubmitted:4}],
    ['reports/retained',{userId:'rider',description:'Shared history'}],['trips/retained',{driverId:'rider',status:'completed'}],
    ['driver_route_assignments/rider',{routeId:'route',active:true}],['operator_access/rider',{approved:true,privateEvidence:'Retained review evidence'}],
  ]);
  let tail=Promise.resolve(),rejectFinal=false;
  const store={async runTransaction(callback){
    let release;const old=tail;tail=new Promise(r=>release=r);await old;
    const writes=[];
    try{
      const result=await callback({get:async p=>rows.get(p)?structuredClone(rows.get(p)):null,
        create:(p,d)=>{if(rows.has(p))throw Error('exists');writes.push([p,d]);},
        set:(p,d)=>writes.push([p,d]),update:(p,d)=>writes.push([p,{...rows.get(p),...d}])});
      if(rejectFinal&&writes.some(([p])=>p.startsWith('admin_audit/auth-completed-'))){rejectFinal=false;throw Error('receipt-write-failed');}
      for(const [p,d]of writes)rows.set(p,structuredClone(d));return result;
    }finally{release();}
  }};
  const users=new Map([['admin',{uid:'admin',customClaims:{admin:true},disabled:false}],['other-admin',{uid:'other-admin',customClaims:{admin:true},disabled:false}],['rider',{uid:'rider',disabled:false}]]);
  const calls=[];let failAction=null;
  const auth={async getUser(uid){if(!users.has(uid))throw Object.assign(Error(),{code:'auth/user-not-found'});return structuredClone(users.get(uid));},
    async updateUser(uid,patch){calls.push(['update',uid,patch]);if(failAction==='update')throw Error('unavailable');users.set(uid,{...users.get(uid),...patch});},
    async revokeRefreshTokens(uid){calls.push(['revoke',uid]);if(failAction==='revoke')throw Error('unavailable');users.get(uid).tokensValidAfterTime=time.toISOString();},
    async deleteUser(uid){calls.push(['delete',uid]);if(failAction==='delete')throw Error('unavailable');users.delete(uid);}};
  const s=createAuthLifecycle({store,auth,now:()=>time});
  const input=(action,revision,operationId=action)=>({scope:'normal',actorUid:'admin',actorAdmin:true,accountId:'rider',action,expectedRevision:revision,operationId,reason:'Reviewed administration reason'});
  return {s,rows,users,calls,store,auth,time,input,setFailure:v=>{failAction=v;},rejectFinal:()=>{rejectFinal=true;}};
}

test('disable blocks old sessions immediately; retry is idempotent and enable preserves independent bans',async()=>{
  const f=fixture();f.rows.set('account_access/rider',{manualSuspended:true,communityPermanent:true,communityPermanentReason:'Reviewed dispute'});
  const i=f.input('disable',0);const result=await f.s.change(i);assert.equal(result.status,'completed');
  assert.equal(f.users.get('rider').disabled,true);assert.equal(f.rows.get('account_access/rider').authDisabled,true);
  await assert.rejects(f.s.validateSession({uid:'rider',auth_time:+f.time/1000}),{code:'authentication-required'});
  const n=f.calls.length;assert.equal((await f.s.change(i)).duplicate,true);assert.equal(f.calls.length,n);
  await f.s.change(f.input('enable',1));const access=f.rows.get('account_access/rider');
  assert.equal(f.users.get('rider').disabled,false);assert.equal(access.authDisabled,false);
  assert.equal(access.communityPermanent,true);assert.equal(access.manualSuspended,true);
  await assert.rejects(f.s.validateSession({uid:'rider',auth_time:+f.time/1000}),{code:'authentication-required'});
  await f.s.validateSession({uid:'rider',auth_time:+f.time/1000+1});
  assert.equal(f.rows.get('users/rider').points,40);
});
test('revocation leaves Auth enabled and rejects refreshed old auth_time until new sign-in',async()=>{
  const f=fixture();await f.s.change(f.input('revoke',0));assert.equal(f.users.get('rider').disabled,false);
  assert.equal(f.calls.filter(c=>c[0]==='revoke').length,1);
  for(const auth_time of [undefined,+f.time/1000-1,+f.time/1000])await assert.rejects(f.s.validateSession({uid:'rider',auth_time}),{code:'authentication-required'});
  await f.s.validateSession({uid:'rider',auth_time:+f.time/1000+1});
});
test('Auth failure never reports success; gate and durable request survive explicit retry',async()=>{
  const f=fixture();f.setFailure('update');const i=f.input('disable',0);
  const r=await f.s.change(i);assert.equal(r.status,'review-required');assert.equal(f.rows.get('account_access/rider').authDisabled,true);
  assert.equal(f.users.get('rider').disabled,false);
  await assert.rejects(f.s.change(f.input('enable',1)),{code:'auth-operation-pending'});
  f.setFailure(null);await f.s.retry({...i,operationId:'disable'});assert.equal(f.users.get('rider').disabled,true);
  assert.equal(f.rows.get('auth_operations/'+key('disable')).status,'completed');
});
test('receipt failure reconciles without repeating an already acknowledged revoke effect',async()=>{
  const f=fixture();f.rejectFinal();await f.s.change(f.input('revoke',0));
  const job=f.rows.get('auth_operations/'+key('revoke'));assert.equal(job.status,'review-required');assert.equal(job.effectAcknowledged,true);
  await f.s.retry(f.input('revoke',1));assert.equal(f.calls.filter(c=>c[0]==='revoke').length,1);
  assert.equal(f.rows.get('auth_operations/'+key('revoke')).status,'completed');
});
test('reviewed deletion requires pending review, disabled Auth, exact UID and no active lock',async()=>{
  const f=fixture();await assert.rejects(f.s.change({...f.input('approve-delete',0),confirmAccountId:'rider'}),{code:'review-unavailable'});
  await f.s.change(f.input('request-delete',0));
  await assert.rejects(f.s.change(f.input('approve-delete',1)),{code:'deletion-confirmation-required'});
  await assert.rejects(f.s.change({...f.input('approve-delete',1),confirmAccountId:'rider'}),{code:'disable-before-delete'});
  await f.s.change(f.input('disable',1));
  f.rows.set('operation_locks/rider',{active:true,tripId:'active'});
  await assert.rejects(f.s.change({...f.input('approve-delete',2),confirmAccountId:'rider'}),{code:'active-operation-blocks-delete'});
  f.rows.get('operation_locks/rider').active=false;
  const i={...f.input('approve-delete',2),confirmAccountId:'rider'};
  assert.equal((await f.s.change(i)).status,'completed');assert.equal(f.users.has('rider'),false);
  const profile=f.rows.get('users/rider');assert.equal(profile.name,'Deleted account');assert.equal(profile.email,undefined);assert.equal(profile.phone,undefined);
  assert.equal(profile.points,40);assert.equal(profile.accountDeleted,true);
  assert.equal(f.rows.get('driver_route_assignments/rider').active,false);assert.equal(f.rows.get('operator_access/rider').approved,false);
  assert.equal(f.rows.get('reports/retained').description,'Shared history');assert.equal(f.rows.get('trips/retained').status,'completed');
  assert.equal((await f.s.change(i)).duplicate,true);assert.equal(f.calls.filter(c=>c[0]==='delete').length,1);
  await assert.rejects(f.s.change(f.input('enable',3)),{code:'account-deleted'});
});
test('rejected deletion preserves Auth/profile and can later be requested again',async()=>{
  const f=fixture();await f.s.change(f.input('request-delete',0));await f.s.change(f.input('reject-delete',1));
  assert.equal(f.users.has('rider'),true);assert.equal(f.calls.length,0);assert.equal(f.rows.get('auth_deletion_reviews/rider').status,'rejected');
  await f.s.change(f.input('request-delete',2,'new-review'));assert.equal(f.rows.get('auth_deletion_reviews/rider').status,'pending');
});
test('normal-only Auth controls protect self, every admin and suspended/revoked reviewers',async()=>{
  const f=fixture();
  for(const action of ['disable','enable','revoke','request-delete','approve-delete']){
    const i={...f.input(action,0),confirmAccountId:'rider'};
    await assert.rejects(f.s.change({...i,scope:'sample'}),{code:'auth-scope-denied'});
    await assert.rejects(f.s.change({...i,actorAdmin:false}),{code:'admin-required'});
    await assert.rejects(f.s.change({...i,accountId:'admin',confirmAccountId:'admin'}),{code:'self-review-forbidden'});
    await assert.rejects(f.s.change({...i,accountId:'other-admin',confirmAccountId:'other-admin'}),{code:'admin-account-protected'});
  }
  assert.equal(f.calls.length,0);
  f.users.get('admin').customClaims.admin=false;
  await assert.rejects(f.s.change(f.input('disable',0)),{code:'admin-required'});
});
test('concurrent distinct decisions have one revision winner, conflicts never replace a payload',async()=>{
  const f=fixture(),r=await Promise.allSettled([f.s.change(f.input('disable',0,'a')),f.s.change(f.input('enable',0,'b'))]);
  assert.equal(r.filter(x=>x.status==='fulfilled').length,1);
  const winner=r[0].status==='fulfilled'?'a':'b',action=winner==='a'?'disable':'enable';
  await assert.rejects(f.s.change({...f.input(action,0,winner),reason:'Changed payload'}),{code:'request-id-conflict'});
  assert.equal(f.rows.get('account_access/rider').authRevision,1);
});
test('unobserved crashed in-flight effects are not stolen; completed observed Auth effects can be reconciled',async()=>{
  const f=fixture();f.setFailure('revoke');await f.s.change(f.input('revoke',0));
  const job=f.rows.get('auth_operations/'+key('revoke'));job.status='processing';
  await assert.rejects(f.s.retry(f.input('revoke',1)),{code:'auth-operation-pending'});
  f.users.get('rider').tokensValidAfterTime=f.time.toISOString();f.setFailure(null);
  await f.s.retry(f.input('revoke',1));assert.equal(job.status,'processing');
  assert.equal(f.rows.get('auth_operations/'+key('revoke')).status,'completed');
  assert.equal(f.calls.filter(c=>c[0]==='revoke').length,1);
});
test('API validates revocation cutoff on every route and rejects forged lifecycle authority',async()=>{
  const f=fixture();await f.s.change(f.input('revoke',0));
  let identity={uid:'rider',auth_time:+f.time/1000};
  const api=createModerationApi({auth:{async verifyIdToken(){return identity;}},policy:{async accountStatus(){return {state:'active'};}},lifecycle:f.s});
  const request=(path,body)=>new Request('https://server.test'+path,{method:'POST',headers:{'content-type':'application/json',authorization:'Bearer signed'},body:JSON.stringify(body)});
  assert.equal((await api(request('/v2/account/status',{}))).status,401);
  identity={uid:'admin',admin:true,auth_time:+f.time/1000};
  assert.equal((await api(request('/v2/auth/detail',{accountId:'rider'}))).status,200);
  assert.equal((await api(request('/v2/auth/change',{...f.input('enable',1),actorAdmin:true}))).status,400);
  assert.equal((await api(request('/v2/auth/detail',{accountId:'rider',scope:'sample'}))).status,403);
});
