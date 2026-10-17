import assert from 'node:assert/strict';
import {test} from 'node:test';
import {createServer} from 'node:http';
import {validateSharedEnvironment,inspectSharedReadiness,guardedDevelopmentHandler,sharedProjectId} from '../../server/moderation/development_runtime.mjs';
import {createDevelopmentWorker} from '../../server/moderation/development_worker.mjs';
import {createModerationApi} from '../../server/moderation/api.mjs';
import {createNodeModerationHandler} from '../../server/moderation/node_handler.mjs';
import {indexCoverage} from '../../server/moderation/index_coverage.mjs';
import {verifyZeroBaselines,alreadyActivated} from '../../server/moderation/development_activation.mjs';

test('real-project environment refuses emulator and alternate project overrides',()=>{
  validateSharedEnvironment({});validateSharedEnvironment({GOOGLE_CLOUD_PROJECT:sharedProjectId});
  for(const env of [{FIRESTORE_EMULATOR_HOST:'127.0.0.1:8087'},{FIREBASE_AUTH_EMULATOR_HOST:'127.0.0.1:9099'},
    {GCLOUD_PROJECT:'other'},{FIREBASE_CONFIG:'not-json'},{FIREBASE_CONFIG:'{"projectId":"demo-test"}'}]){
    assert.throws(()=>validateSharedEnvironment(env));
  }
});
test('development activation cannot reset nonzero, invalid or already migrated balances',async()=>{
  const seen=[];
  await verifyZeroBaselines([{uid:'a'},{uid:'b',points:0,reportsSubmitted:0,verifiedCount:0}],async uid=>{seen.push(uid);return false;});
  assert.deepEqual(seen,['a','b']);
  for(const field of ['points','reportsSubmitted','verifiedCount'])for(const n of [10,-10,'0',NaN,Infinity]){
    await assert.rejects(verifyZeroBaselines([{uid:'a',[field]:n}],async()=>false),/migration-review-required/);
  }
  await assert.rejects(verifyZeroBaselines([{uid:'a'}],async()=>true),/migration-review-required/);
  await assert.rejects(verifyZeroBaselines(Array.from({length:101},()=>({uid:'a'})),async()=>false),/migration-review-required/);
});
test('activation retry retains its effective date and refuses partial or mismatched active policy',()=>{
  const time=new Date('2026-10-17T10:00:00Z'),m={enabled:true,policyVersion:2,effectiveAt:time,backendMode:'localhost',reviewedRulesHash:'reviewed'},a={enabled:true,policyVersion:2,backendMode:'localhost'};
  assert.equal(alreadyActivated(undefined,undefined,'reviewed'),false);
  assert.equal(alreadyActivated(m,a,'reviewed',time),true);assert.equal(m.effectiveAt,time);
  for(const [left,right] of [[m,undefined],[{...m,reviewedRulesHash:'old'},a],[{...m,localOnly:true},a],[{...m,effectiveAt:new Date('invalid')},a]]){
    assert.throws(()=>alreadyActivated(left,right,'reviewed',time),/activation-review-required/);
  }
});
const ruleSource="rules_version = '2';\nservice cloud.firestore {}";
function readinessFixture(){
  const rows={'moderation_config/active':{enabled:true,policyVersion:2,effectiveAt:new Date('2026-10-17T09:00:00Z')},
    'assistance_config/active':{enabled:true,policyVersion:2}};
  let writes=0;
  const db={projectId:sharedProjectId,doc:path=>({async get(){return {data:()=>rows[path]};},set(){writes++;throw Error('No startup writes');}})};
  return {rows,db,writes:()=>writes,inspect:(source=ruleSource)=>inspectSharedReadiness({db,readRules:async()=>source,indexesReady:async()=>true,expectedRules:ruleSource,now:()=>new Date('2026-10-17T10:00:00Z')})};
}
test('readiness requires READY indexes, including collection-group fields and explicit document-ID direction',()=>{
  const expected={indexes:[{collectionGroup:'reports',queryScope:'COLLECTION',fields:[{fieldPath:'status',order:'ASCENDING'},{fieldPath:'__name__',order:'DESCENDING'}]}],
    fieldOverrides:[{collectionGroup:'events',fieldPath:'status',indexes:[{queryScope:'COLLECTION_GROUP',order:'ASCENDING'}]}]};
  const index={...expected.indexes[0],name:'projects/p/databases/d/collectionGroups/reports/indexes/i',state:'READY'};
  const field={name:'projects/p/databases/d/collectionGroups/events/fields/status',indexConfig:{indexes:[{queryScope:'COLLECTION_GROUP',state:'READY',fields:[{fieldPath:'status',order:'ASCENDING'}]}]}};
  assert.equal(indexCoverage(expected,[index],[field]).ready,true);
  assert.equal(indexCoverage(expected,[{...index,state:'CREATING'}],[field]).ready,false);
  assert.equal(indexCoverage(expected,[{...index,fields:[{fieldPath:'status',order:'ASCENDING'}]}],[field]).ready,false);
  assert.equal(indexCoverage(expected,[index],[]).ready,false);
});
test('read-only preflight requires deployed rules and both real v2 activations',async()=>{
  const f=readinessFixture();assert.equal((await f.inspect(ruleSource.replaceAll('\n','\r\n'))).ready,true);
  assert.equal((await f.inspect('old rules')).ready,false);
  assert.deepEqual((await f.inspect('old rules')).reasons,['rules-review-required']);
  f.rows['moderation_config/active'].localOnly=true;
  assert.equal((await f.inspect()).ready,false);
  delete f.rows['moderation_config/active'];delete f.rows['assistance_config/active'];
  assert.deepEqual((await f.inspect()).reasons,['moderation-activation-required','assistance-activation-required']);
  assert.equal(f.writes(),0);
});
test('future policy, malformed time and wrong project cannot activate the real backend',async()=>{
  const f=readinessFixture();
  for(const effectiveAt of [new Date('2030-01-01'),new Date('invalid'),undefined]){
    f.rows['moderation_config/active'].effectiveAt=effectiveAt;assert.equal((await f.inspect()).ready,false);
  }
  f.db.projectId='demo-wrong';await assert.rejects(f.inspect(),/project mismatch/);
});
test('real loopback readiness gates mutations and ready API still requires verified, unrevoked auth',async()=>{
  let ready=false,fail=false,verified=0;
  const api=createModerationApi({auth:{async verifyIdToken(token,revoked){
    assert.equal(revoked,true);verified++;if(token!=='signed-for-project')throw Object.assign(Error(),{code:'auth/invalid-id-token'});return {uid:'owner'};
  }},policy:{async accountStatus(){return {state:'active'};}}});
  const server=createServer(guardedDevelopmentHandler({readiness:async()=>{
    if(fail)throw Error('Read failed');return {ready,reasons:ready?[]:['rules-review-required']};
  },handler:createNodeModerationHandler({api,publicOrigin:'https://fixed.internal.invalid'})}));
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  try{
    const origin=`http://127.0.0.1:${server.address().port}`;
    const send=token=>fetch(origin+'/v2/account/status',{method:'POST',headers:{'content-type':'application/json',authorization:'Bearer '+token},body:'{}'});
    assert.equal((await fetch(origin+'/healthz')).status,503);
    assert.equal((await send('signed-for-project')).status,503);assert.equal(verified,0);
    ready=true;assert.equal((await fetch(origin+'/healthz')).status,200);
    assert.equal((await send('other-project-or-forged')).status,401);
    assert.equal((await send('signed-for-project')).status,200);assert.equal(verified,2);
    fail=true;const r=await send('signed-for-project');assert.equal(r.status,503);
    assert.deepEqual(await r.json(),{error:{code:'service-unavailable'}});
  }finally{server.closeAllConnections();await new Promise(resolve=>server.close(resolve));}
});

function memoryDb(initial={}){
  const rows=new Map(Object.entries(initial)),queries=[];
  const ref=path=>({path,id:path.split('/').at(-1),parent:{parent:{id:path.split('/').at(-3)}}});
  const snapshot=(path,data)=>({id:path.split('/').at(-1),ref:ref(path),data:()=>data});
  function query(kind,path,filters=[],after=null,count=100){return {
    where:(...f)=>query(kind,path,[...filters,f],after,count),orderBy:()=>query(kind,path,filters,after,count),
    limit:n=>query(kind,path,filters,after,n),startAfter:a=>query(kind,path,filters,a,count),
    async get(){queries.push(path);
      const start=after?.path??(after?(kind==='group'?after:path+'/'+after):'');
      const values=[...rows].filter(([key,data])=>
        (kind==='group'?key.split('/').at(-2)===path:key.startsWith(path+'/')&&key.slice(path.length+1).indexOf('/')===-1)&&
        key>start&&filters.every(([field,op,value])=>op==='=='?data[field]===value:op==='in'?value.includes(data[field]):op==='<='?data[field]<=value:false))
        .sort(([a],[b])=>a.localeCompare(b)).slice(0,count).map(([p,d])=>snapshot(p,d));
      return {size:values.length,docs:values};
    },
  };}
  return {rows,queries,doc:ref,collection:path=>query('collection',path),collectionGroup:path=>query('group',path),
    async runTransaction(callback){const changes=[];await callback({get:async r=>snapshot(r.path,rows.get(r.path)),update:(r,d)=>changes.push([r.path,d])});for(const [p,d]of changes)rows.set(p,{...rows.get(p),...d});}};
}
test('worker performs no queries or mutations while activation is unavailable',async()=>{
  const db=memoryDb(),worker=createDevelopmentWorker({db,ready:async()=>false});await worker();assert.deepEqual(db.queries,[]);
});
test('worker cursor passes unknown pending events, ignores Sample scope and retries a failed reconciliation',async()=>{
  const records={};for(let n=0;n<22;n++)records[`notification_outbox/a${String(n).padStart(2,'0')}/events/unknown`]={status:'pending',kind:'unrelated'};
  records['notification_outbox/z/events/reconcile-operation']={status:'pending',kind:'reconcile-suspended-operation'};
  records['sample_test/shared/notification_outbox/s/events/reconcile-operation']={status:'pending',kind:'reconcile-suspended-operation'};
  const db=memoryDb(records),calls=[];let reject=true;
  const worker=createDevelopmentWorker({db,ready:async()=>true,assistance:{},operations:{},policy:{async reconcileOperation(i){
    calls.push(i.reportId);if(reject)throw Error('retry');db.rows.get('notification_outbox/z/events/reconcile-operation').status='completed';
  }}});
  await worker();assert.deepEqual(calls,[]);await worker();assert.deepEqual(calls,['z']);
  reject=false;await worker();await worker();assert.deepEqual(calls,['z','z']);
  assert.equal(db.rows.get('sample_test/shared/notification_outbox/s/events/reconcile-operation').status,'pending');
});
test('worker cancellation preserves handed-over, unrelated and already terminal assistance',async()=>{
  const time=new Date('2026-10-17T10:00:00Z'),before=new Date(+time-1000);
  const request={status:'pending',policyVersion:2,busId:'b',serviceRunId:'run',driverId:'old',createdAt:before};
  const db=memoryDb({
    'notification_outbox/j/events/expire-assistance':{status:'pending',kind:'expire-suspended-assistance',uid:'old',busId:'b',tripId:'run',suspendedAt:time},
    'boarding_requests/owned':{...request},'boarding_requests/handed-over':{...request,driverId:'new'},
    'boarding_requests/other-run':{...request,serviceRunId:'other'},'boarding_requests/terminal':{...request,status:'completed'},
  });
  const worker=createDevelopmentWorker({db,ready:async()=>true,policy:{},operations:{},assistance:{async reconcile(){}}});await worker();
  assert.equal(db.rows.get('boarding_requests/owned').status,'cancelled');
  for(const key of ['handed-over','other-run'])assert.equal(db.rows.get('boarding_requests/'+key).status,'pending');
  assert.equal(db.rows.get('boarding_requests/terminal').status,'completed');
  assert.equal(db.rows.get('notification_outbox/j/events/expire-assistance').status,'completed');
});
