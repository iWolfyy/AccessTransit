// Trusted-server policy only. Never import into Flutter or expose an unverified UID.
// Store contract: runTransaction(callback); tx.get(path), create/set/update(path,data).
export class PolicyError extends Error {
  constructor(code,{retryAt}={}) { super(code); this.code = code; this.retryAt=retryAt; }
}
const fail = code => { throw new PolicyError(code); };
const id = value => typeof value === 'string' && value.length > 0 && value.length <= 128
  && !value.includes('/') && !['.', '..'].includes(value);
const date = value => value instanceof Date ? value : value?.toDate?.();
const timestamp = value => {
  const result = date(value);
  if (!(result instanceof Date) || !Number.isFinite(result.getTime())) fail('invalid-state');
  return result;
};
const integer = value => { if (!Number.isSafeInteger(value)) fail('invalid-state'); return value; };
const scopePrefix = scope => scope === 'normal' ? '' : scope === 'sample' ? 'sample_test/shared/' : fail('invalid-scope');
function requireActive(access, now) {
  if (access?.permanent === true || access?.communityPermanent === true || access?.manualSuspended === true ||
      (access?.communitySuspendedUntil && timestamp(access.communitySuspendedUntil) > now) ||
      (access?.manualSuspendedUntil && timestamp(access.manualSuspendedUntil) > now)) fail('account-suspended');
}
function summary(existing, profile) {
  if (existing) {
    if (existing.policyVersion !== 2) fail('migration-required');
    integer(existing.points); integer(existing.falseReportStrikes);
    if (existing.falseReportStrikes < 0) fail('invalid-state');
    return existing;
  }
  if (!profile || ['points', 'reportsSubmitted', 'verifiedCount'].some(k => (profile[k] ?? 0) !== 0)) {
    fail('migration-required');
  }
  return {policyVersion:2, points:0, falseReportStrikes:0};
}

export function createModerationPolicy({store, now = () => new Date(), effectiveAt}) {
  const effective = timestamp(effectiveAt);
  const run = (scope, callback) => store.runTransaction(tx => {
    const time = timestamp(now());
    return callback(tx, scopePrefix(scope), time);
  });
  function eligible(report, target, time) {
    if (!report || report.policyVersion !== 2 || report.publicationState !== 'published' ||
        report.isDemo === true || report.status !== 'active' || !id(report.userId) ||
        timestamp(report.createdAt) < effective || timestamp(report.createdAt) > time ||
        !target || target.isDemo === true || target.deletionPending === true ||
        target.catalogueSource !== 'operator_catalogue' || target.catalogueRecordType === 'published_timetable') {
      fail('report-ineligible');
    }
  }
  return {
    async reconcileOperation({reportId,scope='normal'}) {
      if(!id(reportId))fail('invalid-request');
      return run(scope,async(tx,p,time)=>{
        const jobPath=`${p}notification_outbox/${reportId}/events/reconcile-operation`,job=await tx.get(jobPath);
        if(!job||job.status==='completed')return {duplicate:true};
        if(!id(job.uid)||job.kind!=='reconcile-suspended-operation')fail('invalid-state');
        const access=await tx.get(`${p}account_access/${job.uid}`);
        const restricted=access?.permanent===true||access?.communityPermanent===true||access?.manualSuspended===true||
          (access?.communitySuspendedUntil&&timestamp(access.communitySuspendedUntil)>time)||
          (access?.manualSuspendedUntil&&timestamp(access.manualSuspendedUntil)>time);
        // An overturned strike may remove the restriction before this job runs.
        if(!restricted){tx.update(jobPath,{status:'completed',completedAt:time});return {duplicate:false};}
        const lockPath=`${p}operation_locks/${job.uid}`,lock=await tx.get(lockPath);
        if(!lock?.active){tx.update(jobPath,{status:'completed',completedAt:time});return {duplicate:false};}
        if(!id(lock.busId)||!id(lock.tripId))fail('invalid-state');
        const [trip,run,gps]=await Promise.all([tx.get(`${p}trips/${lock.tripId}`),tx.get(`${p}service_runs/${lock.tripId}`),tx.get(`${p}live_locations/${lock.busId}`)]);
        if(lock.updatedAt&&timestamp(lock.updatedAt)>timestamp(job.createdAt)){
          tx.update(jobPath,{status:'review-required',updatedAt:time});return {reviewRequired:true};
        }
        if(trip?.driverId===job.uid&&trip.busId===lock.busId&&trip.status==='in_progress')tx.update(`${p}trips/${lock.tripId}`,{status:'cancelled',cancelledAt:time,cancellationReason:'account-suspended'});
        if(run?.driverId===job.uid&&run.busId===lock.busId&&['boarding','in_progress'].includes(run.status))tx.update(`${p}service_runs/${lock.tripId}`,{status:'cancelled',completedAt:time});
        if(gps?.driverId===job.uid&&gps.tripId===lock.tripId)tx.update(`${p}live_locations/${lock.busId}`,{isBroadcasting:false,status:'completed',timestamp:time});
        tx.update(lockPath,{active:false,updatedAt:time});
        tx.create(`${p}notification_outbox/${reportId}/events/expire-assistance`,{kind:'expire-suspended-assistance',status:'pending',uid:job.uid,busId:lock.busId,tripId:lock.tripId,suspendedAt:job.createdAt,createdAt:time});
        tx.update(jobPath,{status:'completed',busId:lock.busId,tripId:lock.tripId,completedAt:time});
        return {duplicate:false,busId:lock.busId,tripId:lock.tripId,uid:job.uid};
      });
    },
    async voteStatus({reportId,actorUid,scope='normal'}) {
      if(!id(reportId)||!id(actorUid)) fail('invalid-request');
      return run(scope,async(tx,p)=>{
        const [report,vote,profile]=await Promise.all([tx.get(`${p}reports/${reportId}`),
          tx.get(`${p}reports/${reportId}/votes/${actorUid}`),tx.get(`${p}users/${actorUid}`)]);
        if(!profile) fail('account-missing');
        if(!report||report.policyVersion!==2||(report.status==='hidden'&&report.userId!==actorUid)) fail('report-ineligible');
        return {userVote:vote?.value??null,isAuthor:report.userId===actorUid,status:report.moderationLocked&&report.status==='active'?'resolved':report.status,
          falseCount:integer(report.falseCount),confirmCount:integer(report.confirmCount)};
      });
    },
    async publishReport({reportId,actorUid,report:input,scope='normal'}) {
      if(!id(reportId)||!id(actorUid)||!input||typeof input!=='object'||Array.isArray(input)) fail('invalid-request');
      const fields=['targetType','targetId','targetName','problemType','severity','category','subCategory','condition','crowdingLevel','description','photoUrl','observedAt'];
      if(Object.keys(input).some(k=>!fields.includes(k))) fail('invalid-request');
      const text=(value,max,required=false)=>typeof value==='string'&&value.length<=max&&(!required||value.trim().length>0);
      if(!['bus','station'].includes(input.targetType)||!id(input.targetId)||!text(input.targetName,200)||
        !text(input.problemType,300,true)||!text(input.subCategory,300)||!text(input.description,2000)||
        !text(input.photoUrl,2048)||!['minor','moderate','major'].includes(input.severity)||
        !['rampAccess','elevatorOut','crowding','cleanliness','safetyHazard','driverAssistanceDenied','tactilePavingBlocked'].includes(input.category)||
        typeof input.observedAt!=='string'||!['positive','barrier','unknown'].includes(input.condition)||!['','low','medium','high'].includes(input.crowdingLevel)||
        (input.photoUrl!==''&&!/^https:\/\/res\.cloudinary\.com\/dyrynkuh3\//.test(input.photoUrl))) fail('invalid-request');
      const observed=new Date(input.observedAt);
      if(!Number.isFinite(observed.getTime()))fail('invalid-request');
      return run(scope,async(tx,p,time)=>{
        if(time<effective||observed>time) fail('report-ineligible');
        const path=`${p}reports/${reportId}`,cooldown=`${p}report_cooldowns/${actorUid}/${input.targetType}/${input.targetId}/issues/${input.category}`;
        const [existing,profile,totals,access,target,guard]=await Promise.all([
          tx.get(path),tx.get(`${p}users/${actorUid}`),tx.get(`${p}contribution_summaries/${actorUid}`),
          tx.get(`${p}account_access/${actorUid}`),tx.get(`${p}${input.targetType==='bus'?'buses':'stations'}/${input.targetId}`),tx.get(cooldown),
        ]);
        if(!profile) fail('account-missing');requireActive(access,time);
        if(existing){
          if(existing.policyVersion!==2||existing.userId!==actorUid||existing.targetType!==input.targetType||existing.targetId!==input.targetId||existing.category!==input.category||existing.problemType!==input.problemType) fail('report-id-conflict');
          return {duplicate:true,awardedPoints:existing.awardedPoints};
        }
        const state=summary(totals,profile);
        const data={...input,observedAt:observed,userId:actorUid,policyVersion:2,rewardPolicyVersion:2,awardedPoints:10,
          createdAt:time,status:'active',publicationState:'published',isDemo:false,falseCount:0,confirmCount:0,moderationLocked:false};
        eligible(data,target,time);
        if(guard&&timestamp(guard.lastPublishedAt).getTime()+300000>time.getTime()) {
          throw new PolicyError('report-cooldown',{retryAt:new Date(timestamp(guard.lastPublishedAt).getTime()+300000).toISOString()});
        }
        tx.create(path,data);
        tx.set(cooldown,{reportId,lastPublishedAt:time});
        tx.create(`${p}reward_events/${reportId}/entries/publication`,{policyVersion:2,uid:actorUid,amount:10,kind:'publication',createdAt:time});
        tx.set(`${p}contribution_summaries/${actorUid}`,{...state,points:integer(state.points+10),updatedAt:time});
        return {duplicate:false,awardedPoints:10};
      });
    },
    async accountStatus({actorUid, scope = 'normal'}) {
      if (!id(actorUid)) fail('invalid-id');
      return run(scope, async (tx, p, time) => {
        const [profile, access, totals] = await Promise.all([
          tx.get(`${p}users/${actorUid}`), tx.get(`${p}account_access/${actorUid}`),
          tx.get(`${p}contribution_summaries/${actorUid}`),
        ]);
        if (!profile) fail('account-missing');
        const deadlines = [access?.communitySuspendedUntil, access?.manualSuspendedUntil]
          .filter(Boolean).map(timestamp).filter(d => d > time).sort((a,b) => b-a);
        const state = access?.permanent === true || access?.communityPermanent === true ? 'permanent'
          : access?.manualSuspended === true ? 'suspended' : deadlines.length ? 'temporary' : 'active';
        if (totals && totals.policyVersion !== 2) fail('migration-required');
        return {state,serverTime:time.toISOString(),banReason:access?.communityPermanent===true?access.communityPermanentReason??null:null,
          suspendedUntil:state === 'temporary' ? deadlines[0].toISOString() : null,
          points:totals ? integer(totals.points) : null};
      });
    },
    // Called by a trusted publication worker after an acknowledged v2 publication.
    async creditReport({reportId, scope = 'normal'}) {
      if (!id(reportId)) fail('invalid-id');
      return run(scope, async (tx, p, time) => {
        const reportPath = `${p}reports/${reportId}`;
        const report = await tx.get(reportPath);
        if (!report || !['bus', 'station'].includes(report.targetType) || !id(report.targetId) || !id(report.userId)) fail('report-ineligible');
        const [target, event, profile, totals, access] = await Promise.all([
          tx.get(`${p}${report.targetType === 'bus' ? 'buses' : 'stations'}/${report.targetId}`),
          tx.get(`${p}reward_events/${reportId}/entries/publication`),
          tx.get(`${p}users/${report.userId}`), tx.get(`${p}contribution_summaries/${report.userId}`),
          tx.get(`${p}account_access/${report.userId}`),
        ]);
        if (event) {
          if (event.policyVersion !== 2 || event.uid !== report.userId || event.amount !== 10) fail('invalid-state');
          return {duplicate:true, awardedPoints:10};
        }
        eligible(report, target, time); requireActive(access, time);
        if ((report.falseCount ?? 0) !== 0 || (report.confirmCount ?? 0) !== 0 || report.moderationLocked) fail('invalid-state');
        const state = summary(totals, profile);
        tx.create(`${p}reward_events/${reportId}/entries/publication`, {policyVersion:2,uid:report.userId,amount:10,kind:'publication',createdAt:time});
        tx.set(`${p}contribution_summaries/${report.userId}`, {...state,points:integer(state.points+10),updatedAt:time});
        tx.update(reportPath, {awardedPoints:10, rewardPolicyVersion:2, falseCount:0, confirmCount:0});
        return {duplicate:false, awardedPoints:10};
      });
    },

    // actorUid MUST come from verified authentication at the eventual server adapter.
    async voteReport({reportId, actorUid, value, reason = '', scope = 'normal'}) {
      if (!id(reportId) || !id(actorUid) || !['true','false'].includes(value)) fail('invalid-request');
      if (value === 'false' && (typeof reason !== 'string' || reason.trim().length < 5 || reason.length > 1000)) fail('false-reason-required');
      return run(scope, async (tx, p, time) => {
        const reportPath = `${p}reports/${reportId}`, votePath = `${reportPath}/votes/${actorUid}`;
        const report = await tx.get(reportPath);
        if (!report || !id(report.userId)) fail('report-ineligible');
        if (report.userId === actorUid) fail('author-cannot-vote');
        const author = report.userId;
        const [previous, actorAccess, actorProfile, authorTotals, authorAccess, award, decision, review] = await Promise.all([
          tx.get(votePath), tx.get(`${p}account_access/${actorUid}`), tx.get(`${p}users/${actorUid}`),
          tx.get(`${p}contribution_summaries/${author}`),
          tx.get(`${p}account_access/${author}`), tx.get(`${p}reward_events/${reportId}/entries/publication`),
          tx.get(`${p}moderation_decisions/${reportId}`), tx.get(`${p}permanent_ban_reviews/${author}`),
        ]);
        requireActive(actorAccess, time);
        if (!actorProfile) fail('account-missing');
        if (report.policyVersion !== 2 || report.rewardPolicyVersion !== 2 || !award || award.uid !== author || award.policyVersion !== 2 ||
            award.amount !== 10 || report.awardedPoints !== award.amount || timestamp(report.createdAt) < effective || timestamp(report.createdAt) > time) fail('migration-required');
        if (previous && (previous.uid !== actorUid || !['true','false'].includes(previous.value))) fail('invalid-state');
        if (previous?.value === value) return {duplicate:true, hidden:report.status === 'hidden',
          falseCount:integer(report.falseCount),confirmCount:integer(report.confirmCount)};
        if (report.status !== 'active' || report.moderationLocked || decision) fail('voting-closed');
        const oldFalse = integer(report.falseCount), oldTrue = integer(report.confirmCount);
        if (oldFalse < 0 || oldFalse >= 5 || oldTrue < 0) fail('invalid-state');
        const falseCount = oldFalse + (value === 'false' ? 1 : 0) - (previous?.value === 'false' ? 1 : 0);
        const confirmCount = oldTrue + (value === 'true' ? 1 : 0) - (previous?.value === 'true' ? 1 : 0);
        if (falseCount < 0 || confirmCount < 0) fail('invalid-state');
        const revision = integer(previous?.revision ?? 0) + 1;
        const hidden = falseCount === 5;
        let authorState;
        if (hidden) {
          authorState = summary(authorTotals, null);
          integer(authorState.points - 2*award.amount);
        }
        // All reads precede mutations; the store must retry conflicts atomically.
        tx.set(votePath,{uid:actorUid,value,reason:value === 'false' ? reason.trim() : '',revision,updatedAt:time});
        tx.update(reportPath,{falseCount,confirmCount,status:hidden ? 'hidden' : 'active',moderationLocked:hidden});
        if (hidden) {
          const strikes = integer(authorState.falseReportStrikes + 1);
          tx.create(`${p}reward_events/${reportId}/entries/dispute`,{policyVersion:2,uid:author,amount:-2*award.amount,kind:'community-dispute',createdAt:time});
          tx.create(`${p}moderation_decisions/${reportId}`,{policyVersion:2,reportId,authorUid:author,falseCount:5,strikeCounted:true,penalty:2*award.amount,createdAt:time});
          tx.set(`${p}contribution_summaries/${author}`,{...authorState,points:authorState.points-2*award.amount,falseReportStrikes:strikes,moderationRevision:integer((authorState.moderationRevision??0)+1),updatedAt:time});
          if (strikes === 5) {
            tx.set(`${p}account_access/${author}`,{...authorAccess,communitySuspendedUntil:new Date(time.getTime()+72*60*60*1000),updatedAt:time});
            tx.create(`${p}notification_outbox/${reportId}/events/reconcile-operation`,{kind:'reconcile-suspended-operation',status:'pending',uid:author,createdAt:time});
          }
          if (strikes >= 10 && !review) {
            tx.create(`${p}permanent_ban_reviews/${author}`,{status:'pending',strikeCount:strikes,triggerReportId:reportId,createdAt:time});
          } else if (review?.status === 'pending') {
            tx.update(`${p}permanent_ban_reviews/${author}`,{strikeCount:strikes,updatedAt:time});
          } else if (strikes >= 10 && ['withdrawn','rejected'].includes(review?.status)) {
            // A genuinely new counted report may open a new review cycle. Old
            // threshold deliveries cannot reach this branch twice for a report.
            tx.update(`${p}permanent_ban_reviews/${author}`,{status:'pending',strikeCount:strikes,triggerReportId:reportId,
              decisionKey:`${author}-r${integer((authorState.moderationRevision??0)+1)}`,reason:null,reviewedAt:null,reviewedBy:null,updatedAt:time});
          }
          tx.create(`${p}notification_outbox/${reportId}/events/dispute`,{kind:'report-disputed',uid:author,createdAt:time});

        }
        return {duplicate:false,hidden,falseCount,confirmCount};
      });
    },

  };
}
