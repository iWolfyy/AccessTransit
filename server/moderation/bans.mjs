import {createHash} from 'node:crypto';
import {PolicyError} from './policy.mjs';
const fail=code=>{throw new PolicyError(code);};
const valid=v=>typeof v==='string'&&v.length>0&&v.length<=128&&!v.includes('/')&&!['.','..'].includes(v);
const date=v=>v instanceof Date?v:v?.toDate?.();
const revision=s=>s?.moderationRevision??0;
const active=(s,time)=>{
  if(s?.permanent||s?.communityPermanent||s?.manualSuspended||date(s?.communitySuspendedUntil)>time||date(s?.manualSuspendedUntil)>time)fail('account-suspended');
};

/** Trusted claim adapter supplies actorAdmin; accountAdmin checks Admin Auth. */
export function createBanPolicy({store,accountAdmin,now=()=>new Date()}){
  async function authorize(input){
    if(input.actorAdmin!==true)fail('admin-required');
    if(!valid(input.actorUid))fail('invalid-request');
    const p=input.scope==='normal'||input.scope==null?'':input.scope==='sample'?'sample_test/shared/':fail('invalid-scope');
    await store.runTransaction(async tx=>{
      const [profile,access]=await Promise.all([tx.get(p+'users/'+input.actorUid),tx.get(p+'account_access/'+input.actorUid)]);
      if(!profile)fail('account-missing');active(access,now());
    });return p;
  }
  const brief=(id,data)=>({accountId:id,status:data.status,strikeCount:data.strikeCount,createdAt:date(data.createdAt)?.toISOString()??null});
  const pageInput=input=>{if(input.after!=null&&!valid(input.after))fail('invalid-request');};
  return {
    async list(input){
      const p=await authorize(input);pageInput(input);
      const rows=await store.page({collection:p+'permanent_ban_reviews',after:input.after??null,limit:21});
      return {items:rows.slice(0,20).map(r=>brief(r.id,r.data)),next:rows.length>20?rows[19].id:null};
    },
    async detail(input){
      const p=await authorize(input);if(!valid(input.accountId))fail('invalid-request');
      const result=await store.runTransaction(async tx=>{
        const [review,total,user,access]=await Promise.all(['permanent_ban_reviews/','contribution_summaries/','users/','account_access/'].map(c=>tx.get(p+c+input.accountId)));
        const decision=review?await tx.get(p+'permanent_ban_decisions/'+(review.decisionKey??input.accountId)):null;
        if(!review||!user||total?.policyVersion!==2||!Number.isSafeInteger(total.falseReportStrikes)||!Number.isSafeInteger(revision(total)))fail('review-unavailable');
        return {...brief(input.accountId,review),name:user.name??'',email:user.email??'',currentStrikes:total.falseReportStrikes,revision:revision(total),
          restricted:access?.communityPermanent===true||access?.permanent===true,reason:decision?.reason??null,reviewedBy:decision?.actorUid??null};
      });
      const pending=await store.page({collection:p+'report_appeals',filters:[['authorUid','==',input.accountId],['status','==','pending']],limit:1});
      return {...result,pendingAppeals:pending.length>0};
    },
    async evidence(input){
      const p=await authorize(input);pageInput(input);if(!valid(input.accountId))fail('invalid-request');
      const rows=await store.page({collection:p+'moderation_decisions',filters:[['authorUid','==',input.accountId]],after:input.after??null,limit:21});
      return {items:rows.slice(0,20).map(r=>({reportId:r.id,strikeCounted:r.data.strikeCounted,reviewStatus:r.data.reviewStatus??'unreviewed'})),next:rows.length>20?rows[19].id:null};
    },
    async decide(input){
      const p=await authorize(input),{accountId,actorUid,outcome,expectedRevision}=input;
      if(!valid(accountId)||!['approve','reject'].includes(outcome)||!Number.isSafeInteger(expectedRevision)||expectedRevision<0)fail('invalid-request');
      if(accountId===actorUid)fail('self-review-forbidden');
      if(typeof input.reason!=='string'||input.reason.trim().length<5||input.reason.length>2000)fail('reason-required');
      const text=input.reason.trim();
      // Protect every administrator, including the last one. Never trust profile.role.
      if(typeof accountAdmin!=='function')fail('service-unavailable');
      if(await accountAdmin(accountId))fail('admin-account-protected');
      const pending=await store.page({collection:p+'report_appeals',filters:[['authorUid','==',accountId],['status','==','pending']],limit:1});
      return store.runTransaction(async tx=>{
        const review=await tx.get(p+'permanent_ban_reviews/'+accountId),key=review?.decisionKey??accountId;
        const [total,access,prior,reviewer,user]=await Promise.all([
          tx.get(p+'contribution_summaries/'+accountId),tx.get(p+'account_access/'+accountId),
          tx.get(p+'permanent_ban_decisions/'+key),tx.get(p+'account_access/'+actorUid),tx.get(p+'users/'+accountId),
        ]);
        const time=now();active(reviewer,time);
        if(prior){if(prior.outcome!==outcome)fail('review-already-decided');return {duplicate:true,outcome:prior.outcome};}
        if(!review||!user||review.status!=='pending')fail('review-unavailable');
        if(total?.policyVersion!==2||!Number.isSafeInteger(total.falseReportStrikes)||total.falseReportStrikes<0||!Number.isSafeInteger(revision(total)))fail('invalid-state');
        if(revision(total)!==expectedRevision)fail('review-stale');
        if(outcome==='approve'&&(total.falseReportStrikes<10||pending.length))fail(pending.length?'appeals-pending':'review-stale');
        const decision={accountId,actorUid,outcome,reason:text,strikeCount:total.falseReportStrikes,revision:revision(total),createdAt:time};
        tx.create(p+'permanent_ban_decisions/'+key,decision);
        tx.update(p+'permanent_ban_reviews/'+accountId,{status:outcome==='approve'?'approved':'rejected',reviewedBy:actorUid,reviewedAt:time,reason:text,strikeCount:total.falseReportStrikes});
        tx.create(p+'admin_audit/permanent-ban-'+key,{...decision,action:'review_permanent_ban'});
        if(outcome==='approve'){
          tx.set(p+'account_access/'+accountId,{...access,communityPermanent:true,communityPermanentReason:text,updatedAt:time});
          const job='ban-'+createHash('sha256').update(key).digest('hex');
          tx.create(`${p}notification_outbox/${job}/events/reconcile-operation`,{kind:'reconcile-suspended-operation',status:'pending',uid:accountId,createdAt:time});
        }
        return {duplicate:false,outcome};
      });
    },
  };
}
