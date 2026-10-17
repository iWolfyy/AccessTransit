import {createHash} from 'node:crypto';
import {PolicyError} from './policy.mjs';

const fail=code=>{throw new PolicyError(code);};
const valid=v=>typeof v==='string'&&v.length>0&&v.length<=128&&!v.includes('/')&&!['.','..'].includes(v);
const instant=v=>v instanceof Date?v:v?.toDate?.();
const text=v=>{if(typeof v!=='string'||v.trim().length<5||v.length>2000)fail('reason-required');return v.trim();};
const active=(a,t)=>a?.manualSuspended===true||instant(a?.manualSuspendedUntil)>t;
const blocked=(a,t)=>a?.authDisabled||a?.accountDeleted||a?.permanent||a?.communityPermanent||active(a,t)||instant(a?.communitySuspendedUntil)>t;

/** Appeals never reopen operational access until an explicit current review. */
export function createManualAppeals({store,now=()=>new Date()}){
  const prefix=i=>i.scope==null||i.scope==='normal'?'':i.scope==='sample'?'sample_test/shared/':fail('invalid-scope');
  async function authorize(tx,p,i,admin=false){
    if(!valid(i.actorUid))fail('invalid-request');
    if(admin&&i.actorAdmin!==true)fail('admin-required');
    const [u,a]=await Promise.all([tx.get(p+'users/'+i.actorUid),tx.get(p+'account_access/'+i.actorUid)]);
    if(!u)fail('account-missing');
    if(a?.authDisabled||a?.accountDeleted||(admin&&blocked(a,now())))fail('account-suspended');
    return a;
  }
  const brief=(appealId,a)=>({appealId,accountId:a.accountId,restrictionRevision:a.restrictionRevision,
    restrictionReason:a.restrictionReason,reason:a.reason,status:a.status,
    createdAt:instant(a.createdAt)?.toISOString()??null,reviewReason:a.reviewReason??null});
  return {
    async list(i){
      const p=prefix(i),admin=i.queue===true;
      if(i.after!=null&&!valid(i.after))fail('invalid-request');
      await store.runTransaction(tx=>authorize(tx,p,i,admin));
      const rows=await store.page({collection:p+'manual_account_appeals',filters:admin?[['status','==','pending']]:[['accountId','==',i.actorUid]],after:i.after??null,limit:21});
      return {items:rows.slice(0,20).map(r=>brief(r.id,r.data)),next:rows.length>20?rows[19].id:null};
    },
    async current(i){
      const p=prefix(i);
      return store.runTransaction(async tx=>{
        const a=await authorize(tx,p,i),revision=a?.manualRevision??0;
        const appealId=createHash('sha256').update(JSON.stringify([i.actorUid,revision])).digest('hex');
        const appeal=await tx.get(p+'manual_account_appeals/'+appealId);
        return {accountId:i.actorUid,revision,manualActive:!!active(a,now()),reason:a?.manualReason??null,
          appeal:appeal?brief(appealId,appeal):null};
      });
    },
    async submit(i){
      const p=prefix(i),reason=text(i.reason),revision=i.expectedRevision;
      if(!Number.isSafeInteger(revision)||revision<1)fail('invalid-request');
      const appealId=createHash('sha256').update(JSON.stringify([i.actorUid,revision])).digest('hex');
      return store.runTransaction(async tx=>{
        const a=await authorize(tx,p,i),prior=await tx.get(p+'manual_account_appeals/'+appealId);
        if(prior){if(prior.reason!==reason)fail('request-id-conflict');return {duplicate:true,status:prior.status,appealId};}
        if(a?.manualRevision!==revision)fail('review-stale');
        if(!active(a,now()))fail('review-unavailable');
        const time=now();
        tx.create(p+'manual_account_appeals/'+appealId,{accountId:i.actorUid,restrictionRevision:revision,
          restrictionReason:a.manualReason??'',reason,status:'pending',createdAt:time});
        tx.create(p+'admin_audit/manual-appeal-'+appealId,{actorId:i.actorUid,action:'submit_manual_restriction_appeal',appealId,createdAt:time});
        return {duplicate:false,status:'pending',appealId};
      });
    },
    async review(i){
      const p=prefix(i),reason=text(i.reason);
      if(!valid(i.appealId)||!['uphold','restore'].includes(i.outcome))fail('invalid-request');
      return store.runTransaction(async tx=>{
        await authorize(tx,p,i,true);
        const appeal=await tx.get(p+'manual_account_appeals/'+i.appealId);
        if(!appeal)fail('review-unavailable');
        if(appeal.accountId===i.actorUid)fail('self-review-forbidden');
        const a=await tx.get(p+'account_access/'+appeal.accountId);
        if(appeal.status!=='pending'){
          if(appeal.outcome!==i.outcome||appeal.reviewReason!==reason)fail('review-already-decided');
          return {duplicate:true,status:appeal.status,appealId:i.appealId};
        }
        if(i.outcome==='restore'&&a?.manualRevision!==appeal.restrictionRevision)fail('review-stale');
        const time=now(),status=i.outcome==='restore'?'accepted':'rejected';
        if(i.outcome==='restore')tx.set(p+'account_access/'+appeal.accountId,{...a,manualSuspended:false,
          manualSuspendedUntil:null,manualReason:reason,manualRevision:a.manualRevision+1,manualUpdatedBy:i.actorUid,updatedAt:time});
        tx.update(p+'manual_account_appeals/'+i.appealId,{status,outcome:i.outcome,reviewReason:reason,reviewedBy:i.actorUid,reviewedAt:time});
        tx.create(p+'admin_audit/manual-appeal-review-'+i.appealId,{actorId:i.actorUid,action:'review_manual_restriction_appeal',
          appealId:i.appealId,accountId:appeal.accountId,outcome:i.outcome,reason,createdAt:time});
        return {duplicate:false,status,appealId:i.appealId};
      });
    },
  };
}
