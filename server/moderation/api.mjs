import {PolicyError} from './policy.mjs';

const validId = uid => typeof uid === 'string' && uid.length > 0 && uid.length <= 128 && !uid.includes('/');
const errors = {
  'author-cannot-vote':403,'account-suspended':403,'account-missing':403,
  'false-reason-required':400,'invalid-request':400,'invalid-id':400,'invalid-scope':400,
  'report-ineligible':409,'migration-required':409,'voting-closed':409,
  'report-id-conflict':409,'report-cooldown':429,
  'admin-required':403,'self-review-forbidden':403,'reason-required':400,
  'dispute-unavailable':404,'review-already-decided':409,'invalid-state':409,
  'review-unavailable':404,'review-stale':409,'appeals-pending':409,'admin-account-protected':403,
  'assistance-unavailable':409,'assistance-transition-denied':403,'request-id-conflict':409,
  'operation-unavailable':409,'operation-stale':409,'driver-ineligible':409,'gps-unavailable':409,
  'notification-unavailable':409,'device-limit':429,
  'authentication-required':401,'auth-scope-denied':403,'auth-operation-pending':409,
  'account-deleted':409,'auth-account-missing':404,'disable-before-delete':409,
  'active-operation-blocks-delete':409,'deletion-confirmation-required':400,
};
class HttpError extends Error {
  constructor(status,code) { super(code);this.status=status;this.code=code; }
}
async function jsonBody(request,limit=4096) {
  if (!/^application\/json(?:\s*;|$)/i.test(request.headers.get('content-type') ?? '')) throw new HttpError(415,'json-required');
  if (Number(request.headers.get('content-length')) > limit) throw new HttpError(413,'request-too-large');
  const reader=request.body?.getReader();
  const chunks=[];let size=0;
  try {
    if (reader) while (true) {
      const {done,value}=await reader.read();if(done) break;
      size+=value.byteLength;
      if(size>limit) {await reader.cancel();throw new HttpError(413,'request-too-large');}
      chunks.push(value);
    }
    const bytes=new Uint8Array(size);let offset=0;
    for(const chunk of chunks) {bytes.set(chunk,offset);offset+=chunk.byteLength;}
    const value=JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(bytes));
    if (!value || typeof value !== 'object' || Array.isArray(value)) throw Error('object-required');
    return value;
  } catch(error) {
    if(error instanceof HttpError) throw error;
    throw new HttpError(400,'invalid-json');
  } finally {reader?.releaseLock();}
}

/** Web Request/Response handler for a managed HTTPS host.
 * auth is a trusted Firebase Admin Auth instance, initialized for one project.
 * No request-body UID, role, points or client-provided clock is accepted.
 */
export function createModerationApi({auth,policy,appeals,bans,assistance,operations,notifications,accounts,lifecycle,manualAppeals,allowedScopes=['normal'],allowedOrigins=[]}) {
  if (!auth || typeof auth.verifyIdToken !== 'function' || !policy ||
      !allowedScopes.length || allowedScopes.some(s=>!['normal','sample'].includes(s))) throw Error('invalid-server-configuration');
  return async request => {
    const headers={'content-type':'application/json; charset=utf-8','cache-control':'no-store',vary:'Origin'};
    const reply=(status,body)=>new Response(body === null ? null : JSON.stringify(body),{status,headers});
    try {
      const origin=request.headers.get('origin');
      if(origin) {
        if(!allowedOrigins.includes(origin)) throw new HttpError(403,'origin-denied');
        headers['access-control-allow-origin']=origin;
      }
      const path=new URL(request.url).pathname;
      const appealFields={
        '/v2/reviews/list':['scope','queue','after'],
        '/v2/reviews/detail':['scope','reportId'],
        '/v2/reviews/evidence':['scope','reportId','after'],
        '/v2/reviews/appeal':['scope','reportId','reason'],
        '/v2/reviews/decide':['scope','reportId','outcome','reason'],
      };
      const lifecycleFields={
        '/v2/auth/detail':['scope','accountId'],
        '/v2/auth/change':['scope','accountId','operationId','expectedRevision','action','reason','confirmAccountId'],
        '/v2/auth/retry':['scope','accountId','operationId'],
      };
      const manualFields={
        '/v2/manual-appeals/list':['scope','queue','after'],
        '/v2/manual-appeals/current':['scope'],
        '/v2/manual-appeals/submit':['scope','expectedRevision','reason'],
        '/v2/manual-appeals/review':['scope','appealId','outcome','reason'],
      };
      const accountFields={
        '/v2/accounts/detail':['scope','accountId'],
        '/v2/accounts/change':['scope','accountId','operationId','expectedRevision','action','reason','durationHours'],
      };
      const banFields={
        '/v2/bans/list':['scope','after'],
        '/v2/bans/detail':['scope','accountId'],
        '/v2/bans/evidence':['scope','accountId','after'],
        '/v2/bans/decide':['scope','accountId','outcome','reason','expectedRevision'],
      };
      const assistanceFields={
        '/v2/assistance/submit':['scope','requestId','serviceRunId','busId','stationId','boardingStationId','alightingStationId','purpose','assistanceTypes'],
        '/v2/assistance/get':['scope','requestId'],
        '/v2/assistance/action':['scope','requestId','status'],
        '/v2/assistance/list':['scope','serviceRunId','after'],
      };
      const operationFields={
        '/v2/operations/list':['scope','after'],
        '/v2/operations/detail':['scope','runId'],
        '/v2/operations/candidates':['scope','runId','after'],
        '/v2/operations/handover':['scope','operationId','runId','newDriverId','expectedDriverId','expectedVersion','reason'],
        '/v2/operations/accept':['scope','runId','handoverVersion','gps'],
      };
      const notificationFields={
        '/v2/notifications/register':['scope','token','locale','platform'],
        '/v2/notifications/remove':['scope','deviceId'],
        '/v2/notifications/open':['scope','eventId'],
      };
      if(!['/v2/reports/publish','/v2/reports/vote','/v2/reports/vote-status','/v2/account/status'].includes(path)&&!(manualAppeals&&manualFields[path])&&!(lifecycle&&lifecycleFields[path])&&!(accounts&&accountFields[path])&&!(appeals&&appealFields[path])&&!(bans&&banFields[path])&&!(assistance&&assistanceFields[path])&&!(operations&&operationFields[path])&&!(notifications&&notificationFields[path])) throw new HttpError(404,'not-found');
      if(request.method==='OPTIONS') {
        if(request.headers.get('access-control-request-method') !== 'POST') throw new HttpError(405,'method-not-allowed');
        headers['access-control-allow-methods']='POST';
        headers['access-control-allow-headers']='Authorization, Content-Type';
        return reply(204,null);
      }
      if(request.method!=='POST') throw new HttpError(405,'method-not-allowed');
      const match=/^Bearer ([^\s,]+)$/i.exec(request.headers.get('authorization') ?? '');
      if(!match) throw new HttpError(401,'authentication-required');
      let identity;
      try {identity=await auth.verifyIdToken(match[1],true);} catch(error) {
        if(['auth/id-token-revoked','auth/id-token-expired','auth/invalid-id-token',
            'auth/user-disabled','auth/user-not-found','auth/argument-error',
            'auth/invalid-argument'].includes(error?.code)) throw new HttpError(401,'authentication-required');
        throw new HttpError(503,'authentication-unavailable');
      }
      if(!validId(identity?.uid)) throw new HttpError(401,'authentication-required');
      if(lifecycle)await lifecycle.validateSession(identity);
      const body=await jsonBody(request,path==='/v2/reports/publish'?16384:['/v2/manual-appeals/submit','/v2/manual-appeals/review','/v2/auth/change','/v2/accounts/change','/v2/reviews/appeal','/v2/reviews/decide','/v2/bans/decide','/v2/operations/handover','/v2/notifications/register'].includes(path)?8192:4096), scope=body.scope ?? 'normal';
      if(!allowedScopes.includes(scope)) throw new HttpError(403,'scope-denied');
      const fields=manualFields[path]??lifecycleFields[path]??accountFields[path]??notificationFields[path]??operationFields[path]??assistanceFields[path]??banFields[path]??appealFields[path]??(path==='/v2/reports/publish' ? ['reportId','report','scope'] : path==='/v2/reports/vote' ? ['reportId','value','reason','scope'] : path==='/v2/reports/vote-status' ? ['reportId','scope'] : ['scope']);
      if(Object.keys(body).some(key=>!fields.includes(key))) throw new HttpError(400,'unknown-field');
      let result;
      if(manualFields[path]){
        if(body.queue!=null&&typeof body.queue!=='boolean')throw new HttpError(400,'invalid-request');
        result=await manualAppeals[path.split('/').at(-1)]({...body,scope,actorUid:identity.uid,actorAdmin:identity.admin===true});
        return reply(200,{...result,policyVersion:2,uid:identity.uid,scope});
      }
      if(lifecycleFields[path]){
        result=await lifecycle[path.split('/').at(-1)]({...body,scope,actorUid:identity.uid,actorAdmin:identity.admin===true});
        return reply(200,{...result,policyVersion:2,uid:identity.uid,scope});
      }
      if(accountFields[path]){
        result=await accounts[path.split('/').at(-1)]({...body,scope,actorUid:identity.uid,actorAdmin:identity.admin===true});
        return reply(200,{...result,policyVersion:2,uid:identity.uid,scope});
      }
      if(notificationFields[path]){
        result=await notifications[path.split('/').at(-1)]({...body,scope,actorUid:identity.uid});
        return reply(200,{...result,policyVersion:2,uid:identity.uid,scope});
      }
      if(operationFields[path]){
        result=await operations[path.split('/').at(-1)]({...body,scope,actorUid:identity.uid,actorAdmin:identity.admin===true});
        return reply(200,{...result,policyVersion:2,uid:identity.uid,scope});
      }
      if(assistanceFields[path]){
        result=await assistance[path.split('/').at(-1)]({...body,scope,actorUid:identity.uid,actorAdmin:identity.admin===true});
        return reply(200,{...result,policyVersion:2,uid:identity.uid,scope});
      }
      if(banFields[path]){
        const method=path.split('/').at(-1);
        result=await bans[method]({...body,scope,actorUid:identity.uid,actorAdmin:identity.admin===true});
        return reply(200,{...result,policyVersion:2,uid:identity.uid,scope});
      }
      if(appealFields[path]){
        if(body.queue!=null&&typeof body.queue!=='boolean')throw new HttpError(400,'invalid-request');
        const method={'/v2/reviews/list':'list','/v2/reviews/detail':'detail','/v2/reviews/evidence':'evidence','/v2/reviews/appeal':'submit','/v2/reviews/decide':'review'}[path];
        result=await appeals[method]({...body,scope,actorUid:identity.uid,actorAdmin:identity.admin===true});
        return reply(200,{...result,policyVersion:2,uid:identity.uid,scope});
      }
      if(path==='/v2/reports/vote-status') {
        result=await policy.voteStatus({reportId:body.reportId,actorUid:identity.uid,scope});
        return reply(200,{policyVersion:2,uid:identity.uid,scope,reportId:body.reportId,...result});
      }
      if(path==='/v2/reports/publish') {
        result=await policy.publishReport({reportId:body.reportId,actorUid:identity.uid,report:body.report,scope});
        return reply(200,{policyVersion:2,uid:identity.uid,scope,reportId:body.reportId,...result});
      }
      if(path==='/v2/reports/vote') {
        result=await policy.voteReport({reportId:body.reportId,actorUid:identity.uid,value:body.value,reason:body.reason ?? '',scope});
        return reply(200,{policyVersion:2,uid:identity.uid,scope,reportId:body.reportId,...result});
      }
      result=await policy.accountStatus({actorUid:identity.uid,scope});
      return reply(200,{policyVersion:2,uid:identity.uid,scope,...result});
    } catch(error) {
      if(error instanceof HttpError) return reply(error.status,{error:{code:error.code}});
      if(error instanceof PolicyError && errors[error.code]) return reply(errors[error.code],{error:{code:error.code,
        ...(error.code==='report-cooldown' && error.retryAt ? {retryAt:error.retryAt} : {})}});
      return reply(503,{error:{code:'service-unavailable'}});
    }
  };
}
