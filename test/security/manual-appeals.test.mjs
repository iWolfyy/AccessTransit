import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createManualAppeals} from '../../server/moderation/manual_appeals.mjs';
import {createModerationApi} from '../../server/moderation/api.mjs';

function fixture(){
  const rows=new Map([['users/admin',{}],['users/rider',{}],['users/other',{}],
    ['account_access/rider',{manualRevision:1,manualSuspended:true,manualReason:'Reviewed restriction',communityPermanent:true,authDisabled:false}]]);
  let tail=Promise.resolve();const time=new Date('2026-10-17T10:00:00Z');
  const store={async runTransaction(fn){let release;const previous=tail;tail=new Promise(r=>release=r);await previous;
    const writes=[];
    try{const result=await fn({get:async p=>structuredClone(rows.get(p)??null),
      set:(p,d)=>writes.push([p,d]),create:(p,d)=>{if(rows.has(p))throw Error('exists');writes.push([p,d]);},
      update:(p,d)=>writes.push([p,{...rows.get(p),...d}])});for(const [p,d]of writes)rows.set(p,structuredClone(d));return result;}finally{release();}},
    async page({collection,filters=[],after,limit}){return [...rows].filter(([p])=>p.startsWith(collection+'/')&&p.slice(collection.length+1).indexOf('/')<0)
      .map(([p,data])=>({id:p.slice(collection.length+1),data})).filter(r=>filters.every(([k,op,v])=>op==='=='&&r.data[k]===v)&&(!after||r.id>after))
      .sort((a,b)=>a.id.localeCompare(b.id)).slice(0,limit);}};
  const s=createManualAppeals({store,now:()=>time}),rider={actorUid:'rider',scope:'normal'},admin={actorUid:'admin',actorAdmin:true,scope:'normal'};
  return {rows,s,store,rider,admin,time,submit:()=>s.submit({...rider,expectedRevision:1,reason:'Please review my restriction'})};
}
test('suspended author can appeal once; duplicate retries do not restore access',async()=>{
  const f=fixture();const [a,b]=await Promise.all([f.submit(),f.submit()]);assert.equal(a.appealId,b.appealId);
  assert.equal([a,b].filter(r=>!r.duplicate).length,1);assert.equal((await f.s.current(f.rider)).appeal.status,'pending');
  assert.equal(f.rows.get('account_access/rider').manualSuspended,true);
  await assert.rejects(f.s.submit({...f.rider,expectedRevision:1,reason:'Different retry text'}),{code:'request-id-conflict'});
});
test('accepted appeal restores only the current manual restriction once and preserves Auth/community restrictions',async()=>{
  const f=fixture(),{appealId}=await f.submit();f.rows.get('account_access/rider').authDisabled=true;
  const i={...f.admin,appealId,outcome:'restore',reason:'Reviewed supporting evidence'};
  assert.equal((await f.s.review(i)).status,'accepted');assert.equal((await f.s.review(i)).duplicate,true);
  const a=f.rows.get('account_access/rider');assert.equal(a.manualSuspended,false);assert.equal(a.manualRevision,2);assert.equal(a.communityPermanent,true);assert.equal(a.authDisabled,true);
});
test('new administrative decision makes old appeal stale, including a concurrent decision',async()=>{
  const f=fixture(),{appealId}=await f.submit();f.rows.set('account_access/rider',{manualRevision:2,manualSuspended:true,manualReason:'New decision'});
  await assert.rejects(f.s.review({...f.admin,appealId,outcome:'restore',reason:'Reviewed old evidence'}),{code:'review-stale'});
  assert.equal(f.rows.get('account_access/rider').manualSuspended,true);
  await f.s.review({...f.admin,appealId,outcome:'uphold',reason:'Close the older restriction appeal'});
  assert.equal(f.rows.get('account_access/rider').manualRevision,2);
  assert.equal((await f.submit()).duplicate,true);
  const result=await f.s.submit({...f.rider,expectedRevision:2,reason:'Appeal the new restriction'});assert.notEqual(result.appealId,appealId);
});
test('competing review outcomes have one winner, immutable reason and one audit',async()=>{
  const f=fixture(),{appealId}=await f.submit();const base={...f.admin,appealId,reason:'Reviewed current evidence'};
  const results=await Promise.allSettled([f.s.review({...base,outcome:'uphold'}),f.s.review({...base,outcome:'restore'})]);
  assert.equal(results.filter(r=>r.status==='fulfilled').length,1);
  assert.equal([...f.rows.keys()].filter(p=>p.startsWith('admin_audit/manual-appeal-review-')).length,1);
});
test('privacy, reviewer role, self review, disabled account and invalid/expired requests',async()=>{
  const f=fixture(),{appealId}=await f.submit();assert.equal((await f.s.list({actorUid:'other'})).items.length,0);
  await assert.rejects(f.s.list({...f.rider,queue:true}),{code:'admin-required'});
  await assert.rejects(f.s.review({...f.rider,actorAdmin:true,appealId,outcome:'restore',reason:'Self review attempt'}),{code:'account-suspended'});
  f.rows.get('account_access/rider').manualSuspended=false;f.rows.get('account_access/rider').communityPermanent=false;
  await assert.rejects(f.s.review({...f.rider,actorAdmin:true,appealId,outcome:'restore',reason:'Self review attempt'}),{code:'self-review-forbidden'});
  f.rows.get('account_access/rider').manualRevision=2;
  await assert.rejects(f.s.submit({...f.rider,expectedRevision:2,reason:'No active restriction'}),{code:'review-unavailable'});
  await assert.rejects(f.s.submit({...f.rider,expectedRevision:2,reason:'bad'}),{code:'reason-required'});
  f.rows.get('account_access/rider').authDisabled=true;
  await assert.rejects(f.s.current(f.rider),{code:'account-suspended'});
});
test('private list pagination is bounded and sample review cannot change normal state',async()=>{
  const f=fixture();for(let n=0;n<25;n++)f.rows.set('manual_account_appeals/'+String(n).padStart(3,'0'),{accountId:'rider',restrictionRevision:n,status:'pending',reason:'Test reason',restrictionReason:'Restriction'});
  const first=await f.s.list(f.rider);assert.equal(first.items.length,20);assert.equal(first.next,'019');assert.equal((await f.s.list({...f.rider,after:first.next})).items.length,5);
  for(const uid of ['admin','rider'])f.rows.set('sample_test/shared/users/'+uid,{});
  f.rows.set('sample_test/shared/account_access/rider',{manualRevision:1,manualSuspended:true});
  const sample={...f.rider,scope:'sample',expectedRevision:1,reason:'Sample appeal reason'};const r=await f.s.submit(sample);
  await f.s.review({...f.admin,scope:'sample',appealId:r.appealId,outcome:'restore',reason:'Sample approved reason'});
  assert.equal(f.rows.get('account_access/rider').manualSuspended,true);
});
test('API derives authority from verified identity and rejects client author/queue spoofing',async()=>{
  const f=fixture();const api=createModerationApi({auth:{verifyIdToken:async()=>({uid:'rider'})},policy:{},manualAppeals:f.s});
  const request=async(path,body)=>(await api(new Request('https://test.local/v2/manual-appeals/'+path,{method:'POST',headers:{authorization:'Bearer signed','content-type':'application/json'},body:JSON.stringify(body)})));
  assert.equal((await request('list',{queue:true})).status,403);
  assert.equal((await request('submit',{actorUid:'admin',expectedRevision:1,reason:'Spoofed account'})).status,400);
  assert.equal((await request('list',{queue:'true'})).status,400);
  assert.equal((await request('submit',{expectedRevision:1,reason:'Please review my restriction'})).status,200);
});
