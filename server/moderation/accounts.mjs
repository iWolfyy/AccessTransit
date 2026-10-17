import {createHash} from 'node:crypto';
import {PolicyError} from './policy.mjs';

const fail=code=>{throw new PolicyError(code);};
const id=v=>typeof v==='string'&&v.length>0&&v.length<=128&&!v.includes('/')&&!['.','..'].includes(v);
const date=v=>v instanceof Date?v:v?.toDate?.();
const restricted=(a,t)=>a?.authDisabled||a?.accountDeleted||a?.permanent||a?.communityPermanent||a?.manualSuspended||date(a?.manualSuspendedUntil)>t||date(a?.communitySuspendedUntil)>t;
const revision=a=>a?.manualRevision??0;

/** Scoped application restrictions only. Never changes shared Firebase Auth. */
export function createAccountPolicy({store,accountAdmin,now=()=>new Date()}) {
  const prefix=i=>i.scope==null||i.scope==='normal'?'':i.scope==='sample'?'sample_test/shared/':fail('invalid-scope');
  async function actor(tx,p,i,time){
    if(i.actorAdmin!==true)fail('admin-required');
    if(!id(i.actorUid))fail('invalid-request');
    const [user,access]=await Promise.all([tx.get(p+'users/'+i.actorUid),tx.get(p+'account_access/'+i.actorUid)]);
    if(!user)fail('account-missing');
    if(restricted(access,time))fail('account-suspended');
  }
  const view=(accountId,a,time)=>({accountId,revision:revision(a),
    manualActive:a?.manualSuspended===true||date(a?.manualSuspendedUntil)>time,
    manualUntil:date(a?.manualSuspendedUntil)?.toISOString()??null,
    manualReason:a?.manualReason??null,restricted:!!restricted(a,time),
    communityRestricted:a?.permanent===true||a?.communityPermanent===true||date(a?.communitySuspendedUntil)>time,
    serverTime:time.toISOString()});
  return {
    async detail(i){
      const p=prefix(i);if(!id(i.accountId))fail('invalid-request');
      return store.runTransaction(async tx=>{
        const time=now();await actor(tx,p,i,time);
        const [user,a]=await Promise.all([tx.get(p+'users/'+i.accountId),tx.get(p+'account_access/'+i.accountId)]);
        if(!user)fail('account-missing');
        return view(i.accountId,a,time);
      });
    },
    async change(i){
      const p=prefix(i),{accountId,operationId,expectedRevision,action}=i;
      if(!id(accountId)||!id(operationId)||!['suspend','restore'].includes(action)||!Number.isSafeInteger(expectedRevision)||expectedRevision<0||
          !(i.durationHours==null||i.durationHours===72)||action==='restore'&&i.durationHours!=null)fail('invalid-request');
      if(accountId===i.actorUid)fail('self-review-forbidden');
      const reason=typeof i.reason==='string'?i.reason.trim():'';
      if(reason.length<5||reason.length>2000)fail('reason-required');
      // Protect all trusted admins, including the last admin. Role fields are irrelevant.
      if(typeof accountAdmin!=='function')fail('service-unavailable');
      if(i.actorAdmin!==true)fail('admin-required');
      if(await accountAdmin(accountId))fail('admin-account-protected');
      const key=createHash('sha256').update(operationId).digest('hex'),path=p+'manual_account_decisions/'+key;
      return store.runTransaction(async tx=>{
        const time=now();await actor(tx,p,i,time);
        const [user,a,prior]=await Promise.all([tx.get(p+'users/'+accountId),tx.get(p+'account_access/'+accountId),tx.get(path)]);
        if(!user)fail('account-missing');
        if(prior){
          if(prior.accountId!==accountId||prior.actorUid!==i.actorUid||prior.action!==action||prior.reason!==reason||prior.expectedRevision!==expectedRevision||prior.durationHours!==(i.durationHours??null))fail('request-id-conflict');
          return {accountId,operationId,duplicate:true,revision:prior.revision};
        }
        if(!Number.isSafeInteger(revision(a))||revision(a)<0)fail('invalid-state');
        if(revision(a)!==expectedRevision)fail('review-stale');
        const next=expectedRevision+1;
        const decision={accountId,actorUid:i.actorUid,action,reason,expectedRevision,revision:next,durationHours:i.durationHours??null,createdAt:time};
        tx.set(p+'account_access/'+accountId,{...a,manualSuspended:action==='suspend'&&i.durationHours==null,
          manualSuspendedUntil:action==='suspend'&&i.durationHours===72?new Date(time.getTime()+72*3600000):null,
          manualReason:reason,manualRevision:next,manualUpdatedBy:i.actorUid,updatedAt:time});
        tx.create(path,decision);
        tx.create(p+'admin_audit/manual-account-'+key,{...decision,actorId:i.actorUid,targets:['users/'+accountId,'account_access/'+accountId],action:'manual_account_'+action});
        if(action==='suspend')tx.create(p+'notification_outbox/manual-account-'+key+'/events/reconcile-operation',
          {kind:'reconcile-suspended-operation',status:'pending',uid:accountId,createdAt:time});
        return {accountId,operationId,duplicate:false,revision:next};
      });
    },
  };
}
