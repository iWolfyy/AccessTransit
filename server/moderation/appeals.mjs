import {PolicyError} from './policy.mjs';
const fail=code=>{throw new PolicyError(code);};
const valid=value=>typeof value==='string'&&value.length>0&&value.length<=128&&!value.includes('/')&&!['.','..'].includes(value);
const prefix=scope=>scope==='normal'?'':scope==='sample'?'sample_test/shared/':fail('invalid-scope');
const instant=value=>value instanceof Date?value:value?.toDate?.();
const iso=value=>instant(value)?.toISOString()??null;
const reason=value=>{if(typeof value!=='string'||value.trim().length<5||value.length>2000)fail('reason-required');return value.trim();};
function adminAccess(access,time){
  if(access?.authDisabled||access?.accountDeleted||access?.permanent||access?.communityPermanent||access?.manualSuspended||instant(access?.communitySuspendedUntil)>time||instant(access?.manualSuspendedUntil)>time)fail('account-suspended');
}

/** Admin authority is supplied ONLY by the verified server auth adapter. */
export function createAppealPolicy({store,now=()=>new Date()}){
  async function authorize({actorUid,actorAdmin=false,scope='normal'},adminOnly=false){
    if(!valid(actorUid))fail('invalid-request');
    if(adminOnly&&actorAdmin!==true)fail('admin-required');
    const p=prefix(scope);
    await store.runTransaction(async tx=>{
      const [user,access]=await Promise.all([tx.get(p+'users/'+actorUid),tx.get(p+'account_access/'+actorUid)]);
      if(!user)fail('account-missing');if(adminOnly)adminAccess(access,now());
    });return p;
  }
  const brief=(id,d)=>({reportId:id,authorUid:d.authorUid,penalty:d.penalty,strikeCounted:d.strikeCounted,
    createdAt:iso(d.createdAt),reviewStatus:d.reviewStatus??'unreviewed'});
  return {
    async list(input){
      const admin=input.queue===true,p=await authorize(input,admin);
      if(input.after!=null&&!valid(input.after))fail('invalid-request');
      const records=await store.page({collection:p+'moderation_decisions',filters:admin?[]:[['authorUid','==',input.actorUid]],after:input.after??null,limit:21});
      return {items:records.slice(0,20).map(r=>brief(r.id,r.data)),next:records.length>20?records[19].id:null};
    },
    async detail(input){
      const p=await authorize(input),{reportId,actorUid,actorAdmin=false}=input;
      if(!valid(reportId))fail('invalid-request');
      return store.runTransaction(async tx=>{
        const [decision,report,appeal,review,access]=await Promise.all([tx.get(p+'moderation_decisions/'+reportId),tx.get(p+'reports/'+reportId),tx.get(p+'report_appeals/'+reportId),tx.get(p+'appeal_reviews/'+reportId),tx.get(p+'account_access/'+actorUid)]);
        if(!decision||!report||(actorAdmin!==true&&decision.authorUid!==actorUid))fail('dispute-unavailable');
        if(decision.authorUid!==actorUid)adminAccess(access,now());
        return {...brief(reportId,decision),summary:report.problemType??'',targetName:report.targetName??report.targetId,
          description:report.description??'',photoUrl:report.photoUrl??'',falseCount:decision.falseCount,
          observedAt:iso(report.observedAt??report.createdAt),reviewReason:review?.reason??null,
          appeal:appeal?{reason:appeal.reason,status:appeal.status,submittedAt:iso(appeal.createdAt),
            reviewReason:appeal.reviewReason??null,reviewedAt:iso(appeal.reviewedAt)}:null};
      });
    },
    async evidence(input){
      const p=await authorize(input,true);
      if(!valid(input.reportId)||(input.after!=null&&!valid(input.after)))fail('invalid-request');
      const rows=await store.page({collection:`${p}reports/${input.reportId}/votes`,after:input.after??null,limit:11});
      return {items:rows.slice(0,10).map(r=>({uid:r.id,value:r.data.value,reason:r.data.reason??'',updatedAt:iso(r.data.updatedAt)})),next:rows.length>10?rows[9].id:null};
    },
    async submit(input){
      const {actorUid,reportId}=input,p=await authorize(input),text=reason(input.reason);
      if(!valid(reportId))fail('invalid-request');
      return store.runTransaction(async tx=>{
        const [decision,appeal,totals]=await Promise.all([tx.get(p+'moderation_decisions/'+reportId),tx.get(p+'report_appeals/'+reportId),tx.get(p+'contribution_summaries/'+actorUid)]);
        if(!decision||decision.authorUid!==actorUid||decision.strikeCounted!==true)fail('dispute-unavailable');
        if(appeal){if(appeal.authorUid!==actorUid)fail('invalid-state');return {duplicate:true,status:appeal.status};}
        if(['upheld','overturned'].includes(decision.reviewStatus))fail('review-already-decided');
        if(totals?.policyVersion!==2||!Number.isSafeInteger(totals.moderationRevision??0))fail('invalid-state');
        const time=now();
        tx.set(p+'contribution_summaries/'+actorUid,{...totals,moderationRevision:(totals.moderationRevision??0)+1,updatedAt:time});
        tx.create(p+'report_appeals/'+reportId,{reportId,authorUid:actorUid,reason:text,status:'pending',createdAt:time});
        tx.update(p+'moderation_decisions/'+reportId,{reviewStatus:'pending',updatedAt:time});
        return {duplicate:false,status:'pending'};
      });
    },
    async review(input){
      const p=await authorize(input,true),{reportId,actorUid,outcome}=input,text=reason(input.reason);
      if(!valid(reportId)||!['uphold','overturn'].includes(outcome))fail('invalid-request');
      return store.runTransaction(async tx=>{
        const decision=await tx.get(p+'moderation_decisions/'+reportId);
        if(!decision||!valid(decision.authorUid))fail('dispute-unavailable');
        if(decision.authorUid===actorUid)fail('self-review-forbidden');
        const author=decision.authorUid;
        const [appeal,prior,totals,access,ban,report,reviewerAccess]=await Promise.all([
          tx.get(p+'report_appeals/'+reportId),tx.get(p+'appeal_reviews/'+reportId),tx.get(p+'contribution_summaries/'+author),
          tx.get(p+'account_access/'+author),tx.get(p+'permanent_ban_reviews/'+author),tx.get(p+'reports/'+reportId),tx.get(p+'account_access/'+actorUid),
        ]);
        const time=now();adminAccess(reviewerAccess,time);
        if(prior){if(prior.outcome!==outcome)fail('review-already-decided');return {duplicate:true,outcome:prior.outcome};}
        if(!report||report.policyVersion!==2||!decision.strikeCounted||!Number.isSafeInteger(decision.penalty)||decision.penalty<=0)fail('invalid-state');
        if(totals?.policyVersion!==2||!Number.isSafeInteger(totals.moderationRevision??0))fail('invalid-state');
        const nextRevision=(totals.moderationRevision??0)+1;
        if(outcome==='overturn'){
          if(totals?.policyVersion!==2||!Number.isSafeInteger(totals.points)||!Number.isSafeInteger(totals.falseReportStrikes)||totals.falseReportStrikes<1)fail('invalid-state');
          const points=totals.points+decision.penalty,strikes=totals.falseReportStrikes-1;
          if(!Number.isSafeInteger(points))fail('invalid-state');
          tx.create(`${p}reward_events/${reportId}/entries/appeal-restoration`,{policyVersion:2,uid:author,amount:decision.penalty,kind:'appeal-restoration',createdAt:time});
          tx.set(p+'contribution_summaries/'+author,{...totals,points,falseReportStrikes:strikes,moderationRevision:nextRevision,updatedAt:time});
          tx.update(p+'reports/'+reportId,{status:'active',moderationLocked:true,moderationOverturned:true});
          tx.update(p+'moderation_decisions/'+reportId,{strikeCounted:false,reviewStatus:'overturned',reviewedAt:time,reviewedBy:actorUid});
          const changes={};
          if(strikes<5&&access?.communitySuspendedUntil)changes.communitySuspendedUntil=null;
          if(strikes<10&&access?.communityPermanent){changes.communityPermanent=false;changes.communityPermanentReason=null;}
          if(Object.keys(changes).length)tx.set(p+'account_access/'+author,{...access,...changes,updatedAt:time});
          if(['pending','approved'].includes(ban?.status))tx.update(p+'permanent_ban_reviews/'+author,{status:strikes<10?'withdrawn':ban.status,strikeCount:strikes,updatedAt:time});
        }else {
          tx.set(p+'contribution_summaries/'+author,{...totals,moderationRevision:nextRevision,updatedAt:time});
          tx.update(p+'moderation_decisions/'+reportId,{reviewStatus:'upheld',reviewedAt:time,reviewedBy:actorUid});
        }
        tx.create(p+'appeal_reviews/'+reportId,{reportId,authorUid:author,reviewedBy:actorUid,outcome,reason:text,createdAt:time});
        if(appeal)tx.update(p+'report_appeals/'+reportId,{status:outcome==='overturn'?'accepted':'rejected',reviewReason:text,reviewedBy:actorUid,reviewedAt:time});
        tx.create(`${p}admin_audit/appeal-${reportId}`,{actorId:actorUid,action:'review_report_appeal',reportId,outcome,reason:text,createdAt:time});
        return {duplicate:false,outcome};
      });
    },
  };
}
