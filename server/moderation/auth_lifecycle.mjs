import {createHash,randomUUID} from 'node:crypto';
import {PolicyError} from './policy.mjs';

const fail=code=>{throw new PolicyError(code);};
const id=v=>typeof v==='string'&&v.length>0&&v.length<=128&&!v.includes('/')&&!['.','..'].includes(v);
const date=v=>v instanceof Date?v:v?.toDate?.();
const revision=a=>a?.authRevision??0;
const blocked=(a,t)=>a?.authDisabled||a?.accountDeleted||a?.permanent||a?.communityPermanent||a?.manualSuspended||date(a?.manualSuspendedUntil)>t||date(a?.communitySuspendedUntil)>t;
const actions=['disable','enable','revoke','request-delete','approve-delete','reject-delete'];

/** Trusted Auth effects are durable jobs; Firestore gates commit before effects.
 * One normal-scope operation per target. Review never cascades shared history. */
export function createAuthLifecycle({store,auth,now=()=>new Date()}){
  async function user(uid){
    try{return await auth.getUser(uid);}catch(e){if(e.code==='auth/user-not-found')return null;throw e;}
  }
  async function actor(tx,i){
    if(i.scope!=null&&i.scope!=='normal')fail('auth-scope-denied');
    if(i.actorAdmin!==true)fail('admin-required');if(!id(i.actorUid))fail('invalid-request');
    const [profile,access]=await Promise.all([tx.get('users/'+i.actorUid),tx.get('account_access/'+i.actorUid)]);
    if(!profile)fail('account-missing');if(blocked(access,now()))fail('account-suspended');
  }
  async function protectedTarget(i){
    if(!id(i.accountId))fail('invalid-request');
    if(i.accountId===i.actorUid)fail('self-review-forbidden');
    const target=await user(i.accountId);
    if(target?.customClaims?.admin===true)fail('admin-account-protected');return target;
  }
  async function requireReviewer(uid){
    const reviewer=await user(uid);
    if(!reviewer||reviewer.disabled||reviewer.customClaims?.admin!==true)fail('admin-required');
  }
  const brief=j=>j?{operationId:j.operationId,action:j.action,status:j.status,revision:j.revision,error:j.error??null}:null;
  async function detail(i){
    if(!id(i.accountId))fail('invalid-request');
    const result=await store.runTransaction(async tx=>{
      await actor(tx,i);
      const [profile,a,review,lock]=await Promise.all(['users/','account_access/','auth_deletion_reviews/','operation_locks/'].map(c=>tx.get(c+i.accountId)));
      if(!profile)fail('account-missing');
      const job=a?.authOperationKey?await tx.get('auth_operations/'+a.authOperationKey):null;
      return {accountId:i.accountId,revision:revision(a),authBlocked:a?.authDisabled===true,
        deleted:a?.accountDeleted===true,reviewStatus:review?.status??'none',activeOperation:lock?.active===true,
        lastOperation:brief(job),reviewReason:review?.reason??null};
    });
    const target=await user(i.accountId);
    return {...result,authExists:!!target,authDisabled:target?.disabled===true,
      protected:i.accountId===i.actorUid||target?.customClaims?.admin===true};
  }
  async function change(i){
    if(i.scope!=null&&i.scope!=='normal')fail('auth-scope-denied');
    if(i.actorAdmin!==true)fail('admin-required');
    const {accountId,operationId,expectedRevision,action}=i;
    if(!id(operationId)||!actions.includes(action)||!Number.isSafeInteger(expectedRevision)||expectedRevision<0)fail('invalid-request');
    const reason=typeof i.reason==='string'?i.reason.trim():'';
    if(reason.length<5||reason.length>2000)fail('reason-required');
    if(action==='approve-delete'&&i.confirmAccountId!==accountId)fail('deletion-confirmation-required');
    // Authorization precedes target Auth lookup; role/UID is never client-owned.
    await store.runTransaction(tx=>actor(tx,i));await requireReviewer(i.actorUid);
    const target=await protectedTarget(i);
    const key=createHash('sha256').update(operationId).digest('hex');
    const receipt=await store.runTransaction(async tx=>{
      await actor(tx,i);
      const [profile,a,prior,review,lock]=await Promise.all([tx.get('users/'+accountId),tx.get('account_access/'+accountId),
        tx.get('auth_operations/'+key),tx.get('auth_deletion_reviews/'+accountId),tx.get('operation_locks/'+accountId)]);
      if(!profile)fail('account-missing');
      if(prior){
        if(prior.accountId!==accountId||prior.actorUid!==i.actorUid||prior.action!==action||prior.reason!==reason||prior.expectedRevision!==expectedRevision)fail('request-id-conflict');
        return {key,duplicate:true,...brief(prior)};
      }
      if(!Number.isSafeInteger(revision(a)))fail('invalid-state');
      if(revision(a)!==expectedRevision)fail('review-stale');
      const previous=a?.authOperationKey?await tx.get('auth_operations/'+a.authOperationKey):null;
      if(previous&&['pending','processing','review-required'].includes(previous.status))fail('auth-operation-pending');
      if(a?.accountDeleted)fail('account-deleted');
      if(!target)fail('auth-account-missing');
      if(['request-delete','approve-delete','reject-delete'].includes(action)){
        if(action==='request-delete'&&review?.status==='pending')fail('auth-operation-pending');
        if(action!=='request-delete'&&review?.status!=='pending')fail('review-unavailable');
        if(action==='approve-delete'&&(!a?.authDisabled||!target.disabled))fail('disable-before-delete');
        if(action==='approve-delete'&&lock?.active)fail('active-operation-blocks-delete');
      }
      const time=now(),next=revision(a)+1,needsAuth=['disable','enable','revoke','approve-delete'].includes(action);
      const j={operationId,accountId,actorUid:i.actorUid,action,reason,expectedRevision,revision:next,status:needsAuth?'pending':'completed',createdAt:time,previousTokensValidAfter:target.tokensValidAfterTime??null};
      const access={...a,authRevision:next,authOperationKey:key,updatedAt:time};
      if(['disable','approve-delete'].includes(action))access.authDisabled=true;
      if(action==='revoke'||action==='disable'||action==='approve-delete'){
        access.sessionsValidAfterSeconds=Math.max(a?.sessionsValidAfterSeconds??0,Math.floor(+time/1000)+1);
      }
      // Enable keeps the immediate block until Auth acknowledges success.
      tx.set('account_access/'+accountId,access);tx.create('auth_operations/'+key,j);
      tx.create('admin_audit/auth-request-'+key,{actorId:i.actorUid,action:'auth_'+action,reason,createdAt:time,targets:['users/'+accountId],operationId});
      if(action==='request-delete')tx.set('auth_deletion_reviews/'+accountId,{status:'pending',reason,requestedBy:i.actorUid,requestedAt:time,revision:next});
      if(action==='reject-delete')tx.set('auth_deletion_reviews/'+accountId,{...review,status:'rejected',reviewReason:reason,reviewedBy:i.actorUid,reviewedAt:time});
      if(action==='approve-delete')tx.set('auth_deletion_reviews/'+accountId,{...review,status:'approved',reviewReason:reason,reviewedBy:i.actorUid,reviewedAt:time});
      if(action==='disable'||action==='approve-delete')tx.create(`notification_outbox/auth-${key}/events/reconcile-operation`,{kind:'reconcile-suspended-operation',status:'pending',uid:accountId,createdAt:time});
      return {key,duplicate:false,...brief(j)};
    });
    if(receipt.status==='pending')await process(receipt.key);
    return store.runTransaction(async tx=>{await actor(tx,i);const j=await tx.get('auth_operations/'+key);return {accountId,duplicate:receipt.duplicate,...brief(j)};});
  }
  async function process(key){
    if(!id(key))fail('invalid-request');
    const lease=randomUUID();
    const job=await store.runTransaction(async tx=>{
      const j=await tx.get('auth_operations/'+key);
      if(!j||j.status==='completed'||j.status==='review-required')return null;
      // Never steal an in-flight Auth call. Crashed processing jobs require
      // explicit reconciliation, rather than racing an irreversible effect.
      if(j.status==='processing')return null;
      const a=await tx.get('account_access/'+j.accountId);
      if(a?.authOperationKey!==key||revision(a)!==j.revision)fail('review-stale');
      tx.update('auth_operations/'+key,{status:'processing',lease,startedAt:now()});return j;
    });
    if(!job)return;
    let effectAcknowledged=false;
    try{
      await requireReviewer(job.actorUid);
      await store.runTransaction(tx=>actor(tx,{actorAdmin:true,actorUid:job.actorUid}));
      const target=await protectedTarget(job);
      if(!target&&job.action!=='approve-delete')fail('auth-account-missing');
      if(job.effectAcknowledged===true){
        // Receipt-only retry: never re-revoke sessions or repeat an Auth effect.
      }else if(job.action==='approve-delete'){
        await store.runTransaction(async tx=>{
          const [a,lock]=await Promise.all([tx.get('account_access/'+job.accountId),tx.get('operation_locks/'+job.accountId)]);
          if(a?.authOperationKey!==key||!a.authDisabled)fail('review-stale');
          if(lock?.active)fail('active-operation-blocks-delete');
        });
        if(target&&!target.disabled)fail('disable-before-delete');
        if(target)await auth.deleteUser(job.accountId);
      }else if(job.action==='disable'){
        if(!target.disabled)await auth.updateUser(job.accountId,{disabled:true});
        await auth.revokeRefreshTokens(job.accountId);
      }else if(job.action==='enable'){
        if(target.disabled)await auth.updateUser(job.accountId,{disabled:false});
      }else if(job.action==='revoke')await auth.revokeRefreshTokens(job.accountId);
      effectAcknowledged=true;
      await store.runTransaction(async tx=>{
        const [current,a,profile,grant,approval]=await Promise.all([tx.get('auth_operations/'+key),tx.get('account_access/'+job.accountId),
          tx.get('users/'+job.accountId),tx.get('driver_route_assignments/'+job.accountId),tx.get('operator_access/'+job.accountId)]);
        if(current?.lease!==lease||a?.authOperationKey!==key)fail('review-stale');
        const time=now();
        tx.update('auth_operations/'+key,{status:'completed',completedAt:time,error:null});
        tx.set('account_access/'+job.accountId,{...a,...(job.action==='enable'?{authDisabled:false}:{}),
          ...(job.action==='approve-delete'?{accountDeleted:true,authDisabled:true}:{}),updatedAt:time});
        if(job.action==='approve-delete'){
          tx.set('users/'+job.accountId,{uid:job.accountId,name:'Deleted account',role:'passenger',accountDeleted:true,deletedAt:time,
            points:profile?.points??0,reportsSubmitted:profile?.reportsSubmitted??0,verifiedCount:profile?.verifiedCount??0});
          if(grant)tx.set('driver_route_assignments/'+job.accountId,{...grant,active:false,updatedAt:time});
          if(approval)tx.set('operator_access/'+job.accountId,{...approval,approved:false,status:'deleted',updatedAt:time});
        }
        tx.create('admin_audit/auth-completed-'+key,{actorId:job.actorUid,action:'auth_'+job.action+'_completed',createdAt:time,targets:['users/'+job.accountId],operationId:job.operationId});
      });
    }catch(e){
      // A failed/ambiguous Auth call is never presented as success. Keep the
      // gate and durable request; retry only the same operation after inspection.
      await store.runTransaction(async tx=>{
        const j=await tx.get('auth_operations/'+key);if(j?.lease!==lease||j.status!=='processing')return;
        tx.update('auth_operations/'+key,{status:'review-required',error:e instanceof PolicyError?e.code:'auth-effect-unconfirmed',effectAcknowledged,updatedAt:now()});
      });
    }
  }
  async function retry(i){
    if(!id(i.accountId)||!id(i.operationId))fail('invalid-request');
    await store.runTransaction(tx=>actor(tx,i));await requireReviewer(i.actorUid);const target=await protectedTarget(i);
    const key=createHash('sha256').update(i.operationId).digest('hex');
    await store.runTransaction(async tx=>{
      await actor(tx,i);const [j,a]=await Promise.all([tx.get('auth_operations/'+key),tx.get('account_access/'+i.accountId)]);
      if(!j||j.accountId!==i.accountId||a?.authOperationKey!==key)fail('review-unavailable');
      if(j.status==='processing'){
        const after=target?.tokensValidAfterTime?+new Date(target.tokensValidAfterTime):0;
        const before=j.previousTokensValidAfter?+new Date(j.previousTokensValidAfter):0;
        const proven=(j.action==='approve-delete'&&!target)||
          (j.action==='enable'&&target&&!target.disabled)||
          (['disable','revoke'].includes(j.action)&&target&&(j.action!=='disable'||target.disabled)&&after>before&&after>=Math.floor(+date(j.createdAt)/1000)*1000);
        // Only an acknowledged observable effect can recover a crashed worker.
        // Otherwise preserve the in-flight lock instead of racing its Auth call.
        if(!proven)fail('auth-operation-pending');
        tx.update('auth_operations/'+key,{status:'pending',effectAcknowledged:true,actorUid:i.actorUid,retryReviewedAt:now()});
      }else if(j.status==='review-required'){
        // Never repeat a known-acknowledged effect if its Firestore receipt
        // failed. Completion reconciliation is handled by process state reads.
        tx.update('auth_operations/'+key,{status:'pending',actorUid:i.actorUid,retryReviewedAt:now()});
      }
    });
    await process(key);return detail(i);
  }
  async function validateSession(identity){
    if(!id(identity.uid))fail('authentication-required');
    await store.runTransaction(async tx=>{
      const a=await tx.get('account_access/'+identity.uid);
      if(a?.authDisabled||a?.accountDeleted||((a?.sessionsValidAfterSeconds??0)>0&&
        (!Number.isInteger(identity.auth_time)||identity.auth_time<a.sessionsValidAfterSeconds)))fail('authentication-required');
    });
  }
  return {detail,change,retry,process,validateSession};
}
