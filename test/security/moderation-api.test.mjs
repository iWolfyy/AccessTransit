import assert from 'node:assert/strict';
import {test} from 'node:test';
import {createModerationApi} from '../../server/moderation/api.mjs';
import {PolicyError} from '../../server/moderation/policy.mjs';

function fixture(extra={}) {
  const calls=[];
  const policy={
    async voteReport(data) {calls.push(data);return {duplicate:false,hidden:false,falseCount:1,confirmCount:0};},
    async accountStatus(data) {calls.push(data);return {state:'active',serverTime:'2026-10-16T10:00:00.000Z',suspendedUntil:null,points:-10};},
  };
  const auth={async verifyIdToken(token,checkRevoked) {assert.equal(checkRevoked,true);assert.equal(token,'signed-token');return {uid:'verified-user'};}};
  return {calls,handler:createModerationApi({auth,policy,...extra})};
}
const request=(body={},path='/v2/reports/vote',headers={},method='POST')=>new Request('https://service.test'+path,{
  method,headers:{'content-type':'application/json',authorization:'Bearer signed-token',...headers},
  ...(method==='POST' ? {body:JSON.stringify(body)} : {}),
});
const vote={reportId:'r',value:'false',reason:'The ramp works'};

test('notification registration/open derive the viewer and reject token/target impersonation',async()=>{
  const calls=[],notifications={async register(i){calls.push(i);return {deviceId:'d'};},async open(i){calls.push(i);throw new PolicyError('notification-unavailable');}};
  const {handler}=fixture({notifications}),body={token:'local-opaque-token',locale:'si',platform:'android'};
  assert.equal((await handler(request(body,'/v2/notifications/register'))).status,200);
  assert.deepEqual(calls[0],{...body,scope:'normal',actorUid:'verified-user'});
  for(const field of ['uid','actorUid','driverId','provider','enabled'])assert.equal((await handler(request({...body,[field]:'forged'},'/v2/notifications/register'))).status,400);
  assert.equal((await handler(request({eventId:'id'},'/v2/notifications/open'))).status,409);
  assert.equal((await handler(request({eventId:'id',requestId:'guessed'},'/v2/notifications/open'))).status,400);
});

test('operation API derives admin claim and rejects transfer impersonation fields',async()=>{
  for(const admin of [false,true,'true']){
    const calls=[],operations={async handover(i){calls.push(i);if(!i.actorAdmin)throw new PolicyError('admin-required');return {operationId:i.operationId};}};
    const {handler}=fixture({auth:{async verifyIdToken(){return {uid:'admin',admin};}},operations});
    const body={operationId:'op',runId:'run',newDriverId:'next',expectedDriverId:'old',expectedVersion:0,reason:'Shift changed'};
    assert.equal((await handler(request(body,'/v2/operations/handover'))).status,admin===true?200:403);
    assert.equal(calls[0].actorUid,'admin');assert.equal(calls[0].actorAdmin,admin===true);
    for(const field of ['actorUid','actorAdmin','admin','handoverPending','timestamp'])assert.equal((await handler(request({...body,[field]:true},'/v2/operations/handover'))).status,400);
    assert.equal(calls.length,1);
  }
});

test('assistance endpoint never accepts a client-selected driver or rider identity',async()=>{
  const calls=[],assistance={async submit(input){calls.push(input);return {request:{id:input.requestId}};}};
  const {handler}=fixture({assistance}),body={requestId:'help',serviceRunId:'run',busId:'b',stationId:'s1',boardingStationId:'s1',alightingStationId:'s3',purpose:'boarding',assistanceTypes:['Deploy Ramp']};
  assert.equal((await handler(request(body,'/v2/assistance/submit'))).status,200);
  assert.equal(calls[0].actorUid,'verified-user');
  for(const field of ['driverId','riderId','actorUid','expiresAt','policyVersion'])assert.equal((await handler(request({...body,[field]:'forged'},'/v2/assistance/submit'))).status,400);
  assert.equal(calls.length,1);
});

test('ban API derives trusted admin identity and forwards only validated target/revision fields',async()=>{
  const calls=[];
  const bans={async decide(input){calls.push(input);return {duplicate:false,outcome:'approve'};}};
  const {handler}=fixture({auth:{async verifyIdToken(){return {uid:'admin',admin:true};}},bans});
  const body={accountId:'author',outcome:'approve',reason:'Reviewed evidence',expectedRevision:12};
  assert.equal((await handler(request(body,'/v2/bans/decide'))).status,200);
  assert.deepEqual(calls,[{...body,scope:'normal',actorUid:'admin',actorAdmin:true}]);
  for(const field of ['actorUid','actorAdmin','admin','points','communityPermanent'])assert.equal((await handler(request({...body,[field]:true},'/v2/bans/decide'))).status,400);
});

test('review transport derives admin from verified claims and rejects body impersonation',async()=>{
  for(const admin of [false,true,'true']){
    const calls=[];
    const {handler}=fixture({auth:{async verifyIdToken(){return {uid:'reviewer',admin};}},appeals:{async list(input){calls.push(input);if(!input.actorAdmin)throw new PolicyError('admin-required');return {items:[],next:null};}}});
    const response=await handler(request({queue:true},'/v2/reviews/list'));
    assert.equal(response.status,admin===true?200:403);assert.equal(calls[0].actorAdmin,admin===true);
    for(const field of ['actorUid','actorAdmin','uid','admin'])assert.equal((await handler(request({queue:true,[field]:true},'/v2/reviews/list'))).status,400);
    assert.equal(calls.length,1);
  }
});

test('API binds votes exclusively to verified UID and checks token revocation',async()=>{
  const {handler,calls}=fixture();const response=await handler(request(vote));
  assert.equal(response.status,200);assert.equal(response.headers.get('cache-control'),'no-store');
  assert.deepEqual(calls,[{...vote,actorUid:'verified-user',scope:'normal'}]);
  const data=await response.json();assert.equal(data.uid,'verified-user');assert.equal(data.reportId,'r');
  for(const field of ['actorUid','uid','admin','points','now']) {
    assert.equal((await handler(request({...vote,[field]:'forged'}))).status,400);
  }
  assert.equal(calls.length,1);
});

test('missing/revoked/disabled tokens and verifier outages never reach policy',async()=>{
  for(const code of ['auth/id-token-revoked','auth/user-disabled','auth/id-token-expired','auth/argument-error','auth/network-request-failed','auth/insufficient-permission']) {
    const {handler,calls}=fixture({auth:{async verifyIdToken(){throw Object.assign(Error('secret-token'),{code});}}});
    const response=await handler(request(vote));
    assert.equal(response.status,['auth/network-request-failed','auth/insufficient-permission'].includes(code) ? 503 : 401);
    assert.doesNotMatch(await response.text(),/secret-token/);assert.equal(calls.length,0);
  }
  const {handler,calls}=fixture();assert.equal((await handler(request(vote,undefined,{authorization:''}))).status,401);
  assert.equal(calls.length,0);
});

test('sample scope is explicit server configuration and browser origins are allowlisted',async()=>{
  const plain=fixture();assert.equal((await plain.handler(request({...vote,scope:'sample'}))).status,403);
  assert.equal((await plain.handler(request(vote,undefined,{origin:'https://evil.test'}))).status,403);
  const {handler,calls}=fixture({allowedScopes:['sample'],allowedOrigins:['https://app.test']});
  const response=await handler(request({...vote,scope:'sample'},undefined,{origin:'https://app.test'}));
  assert.equal(response.status,200);assert.equal(response.headers.get('access-control-allow-origin'),'https://app.test');
  assert.equal(calls[0].scope,'sample');
  const preflight=await handler(request({},'/v2/reports/vote',{origin:'https://app.test','access-control-request-method':'POST'},'OPTIONS'));
  assert.equal(preflight.status,204);assert.equal(calls.length,1);
});

test('strict JSON envelope, size limits and methods reject malformed requests',async()=>{
  const {handler,calls}=fixture();
  assert.equal((await handler(request(vote,undefined,{},'GET'))).status,405);
  assert.equal((await handler(request(vote,'/credit-report'))).status,404);
  assert.equal((await handler(request(vote,undefined,{'content-type':'text/plain'}))).status,415);
  assert.equal((await handler(request({...vote,reason:'a'.repeat(5000)}))).status,413);
  const broken=new Request('https://service.test/v2/reports/vote',{method:'POST',headers:{authorization:'Bearer signed-token','content-type':'application/json'},body:'{'});
  assert.equal((await handler(broken)).status,400);
  assert.equal((await handler(request([]))).status,400);assert.equal(calls.length,0);
});

test('known policy errors are stable; internal failures never expose details',async()=>{
  for(const [code,status] of [['author-cannot-vote',403],['false-reason-required',400],['voting-closed',409],['invalid-state',409]]) {
    const {handler}=fixture({policy:{async voteReport(){throw new PolicyError(code);}}});
    const response=await handler(request(vote));assert.equal(response.status,status);
    if(status===503) assert.deepEqual(await response.json(),{error:{code:'service-unavailable'}});
  }
  const {handler}=fixture({policy:{async voteReport(){throw Error('database credentials');}}});
  assert.doesNotMatch(await (await handler(request(vote))).text(),/credentials/);
});

test('account status exposes only the verified caller; no public credit or review endpoint exists',async()=>{
  const {handler,calls}=fixture();const response=await handler(request({},'/v2/account/status'));
  const data=await response.json();assert.equal(data.uid,'verified-user');assert.equal(data.points,-10);
  assert.deepEqual(calls,[{actorUid:'verified-user',scope:'normal'}]);
  assert.equal((await handler(request({uid:'someone-else'},'/v2/account/status'))).status,400);
  assert.equal((await handler(request({},'/v2/reports/credit'))).status,404);
});

test('manual-account API derives trusted actor and rejects forged authority and stale updates',async()=>{
  const calls=[],accounts={async change(i){calls.push(i);throw new PolicyError('review-stale');},async detail(i){calls.push(i);return {accountId:i.accountId};}};
  const {handler}=fixture({auth:{async verifyIdToken(){return {uid:'admin',admin:true};}},accounts});
  const body={accountId:'rider',operationId:'request',expectedRevision:0,action:'suspend',reason:'Reviewed issue',durationHours:72};
  assert.equal((await handler(request(body,'/v2/accounts/change'))).status,409);
  assert.deepEqual(calls[0],{...body,scope:'normal',actorUid:'admin',actorAdmin:true});
  for(const key of ['actorAdmin','actorUid','manualSuspended','points','serverTime'])assert.equal((await handler(request({...body,[key]:true},'/v2/accounts/change'))).status,400);
  assert.equal((await handler(request({accountId:'rider'},'/v2/accounts/detail'))).status,200);
  assert.equal((await fixture().handler(request(body,'/v2/accounts/change'))).status,404);
});
