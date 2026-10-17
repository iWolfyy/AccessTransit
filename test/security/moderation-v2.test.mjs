import assert from 'node:assert/strict';
import {before,after,beforeEach,test} from 'node:test';
import {readFileSync} from 'node:fs';
import {initializeTestEnvironment,assertFails} from '@firebase/rules-unit-testing';
import {doc,getDoc,getDocs,collection,query,where,setDoc,updateDoc,deleteDoc,runTransaction,serverTimestamp,orderBy,documentId,startAfter,limit} from 'firebase/firestore';
import {createAppealPolicy} from '../../server/moderation/appeals.mjs';
import {createBanPolicy} from '../../server/moderation/bans.mjs';
import {createAccountPolicy} from '../../server/moderation/accounts.mjs';
import {createManualAppeals} from '../../server/moderation/manual_appeals.mjs';
import {createAssistancePolicy} from '../../server/moderation/assistance.mjs';
import {createOperationPolicy} from '../../server/moderation/operations.mjs';
import {createNotificationPolicy,localNotificationProvider} from '../../server/moderation/notifications.mjs';
import {createHash} from 'node:crypto';
import {FirebaseError} from 'firebase/app';
import {createModerationPolicy} from '../../server/moderation/policy.mjs';
import {reconcileReport} from './reward-ledger.mjs';
import {createModerationApi} from '../../server/moderation/api.mjs';

let env, clock;
const initial = new Date('2026-10-16T10:00:00Z');
before(async () => {
  const projectId = process.env.FIRESTORE_RULES_TEST_PROJECT ?? 'demo-phase9-moderation';
  if (!projectId.startsWith('demo-')) throw Error('Emulator demo project required');
  env = await initializeTestEnvironment({projectId,firestore:{host:'127.0.0.1',
    port:Number(process.env.FIRESTORE_RULES_TEST_PORT ?? 8088),
    rules:readFileSync(new URL('../../firestore.rules',import.meta.url),'utf8')}});
});
after(async () => env?.cleanup());
beforeEach(async () => { await env.clearFirestore(); clock = new Date(initial); });

// Emulator-only implementation of the same transactional store contract.
// Creates gain explicit missing-document reads, preserving contention retries.
function store(db, reject = false) {
  return {async page({collection:path,filters=[],after=null,limit:count=21,orderField='__name__',direction='asc'}) {
    const constraints=filters.map(f=>where(...f));constraints.push(orderBy(orderField==='__name__'?documentId():orderField,direction));
    if(orderField!=='__name__')constraints.push(orderBy(documentId(),direction));
    if(after)constraints.push(startAfter(orderField==='__name__'?after:await getDoc(doc(db,path+'/'+after))));constraints.push(limit(count));
    return (await getDocs(query(collection(db,path),...constraints))).docs.map(d=>({id:d.id,data:d.data()}));
  },runTransaction: callback => runTransaction(db,async native => {
    const writes = [];
    const result = await callback({
      async get(path) { const s=await native.get(doc(db,path)); return s.exists() ? s.data() : null; },
      create(path,data) { writes.push(['create',path,data]); },
      set(path,data) { writes.push(['set',path,data]); },
      update(path,data) { writes.push(['update',path,data]); },
    });
    for (const [kind,path] of writes) if (kind==='create' && (await native.get(doc(db,path))).exists()) throw new FirebaseError('aborted','Concurrent creation; retry the transaction');
    if (reject) throw Error('commit-rejected');
    for (const [kind,path,data] of writes) {
      if (kind==='update') native.update(doc(db,path),data); else native.set(doc(db,path),data);
    }
    return result;
  },{maxAttempts:10})};
}
const service = (db,reject=false) => createModerationPolicy({store:store(db,reject),now:()=>clock,effectiveAt:new Date('2026-10-16T00:00:00Z')});
const read = async (db,path) => (await getDoc(doc(db,path))).data();
const vote = (s,uid,id='r',value='false') => s.voteReport({reportId:id,actorUid:uid,value,reason:'Equipment still works'});
async function seed(db,p='') {
  for (const uid of ['author','u1','u2','u3','u4','u5','u6','truth']) {
    await setDoc(doc(db,p+'users/'+uid),{uid,points:0,reportsSubmitted:0,verifiedCount:0});
  }
  await setDoc(doc(db,p+'buses/b'),{catalogueSource:'operator_catalogue'});
  await newReport(db,'r',p);
}
async function newReport(db,id,p='') {
  await setDoc(doc(db,p+'reports/'+id),{policyVersion:2,userId:'author',targetType:'bus',targetId:'b',
    publicationState:'published',status:'active',createdAt:clock,falseCount:0,confirmCount:0});
}
async function disputed(s,id='r') { for(const uid of ['u1','u2','u3','u4','u5']) await vote(s,uid,id); }

const assistance=(db,extra={})=>createAssistancePolicy({store:store(db),now:()=>clock,...extra});
const operations=(db,reject=false)=>createOperationPolicy({store:store(db,reject),assistance:assistance(db),now:()=>clock});
const notifications=(db,provider=localNotificationProvider(store(db)))=>createNotificationPolicy({store:store(db),assistance:assistance(db),provider,now:()=>clock});
const deviceToken='local-'+('a'.repeat(48));
const registration={actorUid:'u1',token:deviceToken,locale:'en',platform:'android'};
const notice={requestId:'help1',assignmentVersion:1};
const noticeId=(p='',version=1)=>createHash('sha256').update(`${p}notification_outbox/help1/events/assistance-${version}`).digest('hex');
const handoverInput={actorUid:'author',actorAdmin:true,operationId:'transfer1',runId:'run1',newDriverId:'u2',expectedDriverId:'u1',expectedVersion:0,reason:'Driver shift changed'};
async function operationSeed(db,p=''){
  await assistanceSeed(db,p);
  for(const uid of ['u1','u2'])await updateDoc(doc(db,p+'users/'+uid),{role:'operator',name:uid});
  await updateDoc(doc(db,p+'trips/run1'),{serviceRunId:'run1',actualDepartureTime:null,stopTimes:{s1:{estimatedArrival:clock}},stops:['s1','s2','s3']});
  await setDoc(doc(db,p+'live_locations/b'),{tripId:'run1',driverId:'u1',latitude:6.9,longitude:79.8,speed:0,heading:0,timestamp:clock,isBroadcasting:true,status:'stopped',currentStopIndex:0});
}
test('active handover preserves timeline, pauses GPS and resets assistance acceptance once',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),o=operations(db),a=assistance(db);await operationSeed(db);
    await a.submit(helpInput);await a.action({actorUid:'u1',requestId:'help1',status:'acknowledged'});
    const before=await read(db,'trips/run1'),gps=await read(db,'live_locations/b');
    const result=await o.handover(handoverInput);assert.equal(result.handoverVersion,1);
    const after=await read(db,'trips/run1');assert.deepEqual(after,{...before,driverId:'u2'});
    assert.equal((await read(db,'operation_locks/u1')).active,false);
    assert.equal((await read(db,'operation_locks/u2')).active,true);
    const paused=await read(db,'live_locations/b');assert.equal(paused.isBroadcasting,false);assert.deepEqual(paused.timestamp,gps.timestamp);
    assert.equal((await o.handover(handoverInput)).duplicate,true);
    await assert.rejects(a.get({actorUid:'u1',requestId:'help1'}),{code:'assistance-unavailable'});
    await o.reconcile({operationId:'transfer1'});await o.reconcile({operationId:'transfer1'});
    const help=await read(db,'boarding_requests/help1');assert.equal(help.driverId,'u2');assert.equal(help.status,'pending');assert.equal(help.assignmentVersion,2);
    assert.equal((await read(db,'operation_handovers/transfer1')).assistanceState,'completed');
    await assert.rejects(o.accept({actorUid:'u1',runId:'run1',handoverVersion:1,gps:{latitude:6.91,longitude:79.81,speed:0,heading:0,accuracy:5,observedAt:clock.toISOString()}}),{code:'operation-stale'});
    await o.accept({actorUid:'u2',runId:'run1',handoverVersion:1,gps:{latitude:6.91,longitude:79.81,speed:0,heading:0,accuracy:5,observedAt:clock.toISOString()}});
    assert.equal((await read(db,'service_runs/run1')).handoverPending,false);assert.equal((await read(db,'live_locations/b')).isBroadcasting,true);
    assert.deepEqual((await read(db,'trips/run1')).stopTimes,before.stopTimes);
  });
});
test('handover rejects untrusted, stale, busy, banned and wrong-route transfers without partial writes',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),o=operations(db);await operationSeed(db);
    await assert.rejects(o.handover({...handoverInput,actorAdmin:false}),{code:'admin-required'});
    await assert.rejects(o.handover({...handoverInput,expectedVersion:1}),{code:'operation-stale'});
    await setDoc(doc(db,'operation_locks/u2'),{active:true,tripId:'other',busId:'other'});
    await assert.rejects(o.handover(handoverInput),{code:'driver-ineligible'});
    await updateDoc(doc(db,'operation_locks/u2'),{active:false});
    await updateDoc(doc(db,'driver_route_assignments/u2'),{routeId:'wrong'});
    await assert.rejects(o.handover(handoverInput),{code:'driver-ineligible'});
    await updateDoc(doc(db,'driver_route_assignments/u2'),{routeId:'route1'});
    await setDoc(doc(db,'account_access/u2'),{manualSuspended:true});
    await assert.rejects(o.handover(handoverInput),{code:'driver-ineligible'});
    assert.equal((await read(db,'buses/b')).driverId,'u1');assert.equal(await read(db,'operation_handovers/transfer1'),undefined);
    await updateDoc(doc(db,'account_access/u2'),{manualSuspended:false});
    await assert.rejects(operations(db,true).handover(handoverInput),/commit-rejected/);
    assert.equal((await read(db,'operation_locks/u1')).active,true);
  });
});
test('concurrent handovers have one winner and superseded acknowledgments cannot resume an old assignment',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),o=operations(db);await operationSeed(db);
    const results=await Promise.allSettled([o.handover(handoverInput),o.handover({...handoverInput,operationId:'transfer2'})]);
    assert.equal(results.filter(r=>r.status==='fulfilled').length,1);
    const winner=results[0].status==='fulfilled'?'transfer1':'transfer2';
    await assert.rejects(o.handover({...handoverInput,operationId:winner,reason:'Different reason'}),{code:'request-id-conflict'});
    await o.handover({...handoverInput,operationId:'back',newDriverId:'u1',expectedDriverId:'u2',expectedVersion:1});
    await assert.rejects(o.accept({actorUid:'u2',runId:'run1',handoverVersion:1,gps:{latitude:6.9,longitude:79.8,speed:0,heading:0,accuracy:5,observedAt:clock.toISOString()}}),{code:'operation-stale'});
    assert.equal((await read(db,'service_runs/run1')).handoverVersion,2);
    await o.handover({...handoverInput,operationId:winner}); // idempotent result cannot replay the old transfer
    assert.equal((await read(db,'buses/b')).driverId,'u1');
  });
});
test('handover requires fresh accurate GPS and isolates Sample/Test state',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),o=operations(db);await operationSeed(db);await operationSeed(db,'sample_test/shared/');
    await o.handover({...handoverInput,scope:'sample'});
    assert.equal((await read(db,'buses/b')).driverId,'u1');assert.equal((await read(db,'sample_test/shared/buses/b')).driverId,'u2');
    const input={actorUid:'u2',scope:'sample',runId:'run1',handoverVersion:1,gps:{latitude:6.9,longitude:79.8,speed:0,heading:0,accuracy:5,observedAt:clock.toISOString()}};
    for(const gps of [{...input.gps,accuracy:101},{...input.gps,latitude:91},{...input.gps,observedAt:new Date(+clock-30001).toISOString()},{...input.gps,observedAt:new Date(+clock+5001).toISOString()}])await assert.rejects(o.accept({...input,gps}),{code:'gps-unavailable'});
    assert.equal((await read(db,'sample_test/shared/live_locations/b')).isBroadcasting,false);
    await o.accept(input);
    assert.equal((await read(db,'sample_test/shared/live_locations/b')).isBroadcasting,true);
  });
});
test('handover immediately rejects old driver writes and pending new-driver GPS bypass',async()=>{
  await env.withSecurityRulesDisabled(async c=>{const db=c.firestore();await operationSeed(db);await operations(db).handover(handoverInput);});
  const old=env.authenticatedContext('u1').firestore(),next=env.authenticatedContext('u2').firestore();
  await assertFails(updateDoc(doc(old,'live_locations/b'),{timestamp:serverTimestamp(),latitude:7}));
  await assertFails(updateDoc(doc(old,'trips/run1'),{currentStopIndex:1}));
  await assertFails(updateDoc(doc(next,'live_locations/b'),{timestamp:serverTimestamp(),isBroadcasting:true,status:'active'}));
  await assertFails(deleteDoc(doc(next,'live_locations/b')));
  await assertFails(updateDoc(doc(next,'service_runs/run1'),{handoverPending:false}));
});
test('moving-trip handover preserves recorded progress and can rescue a suspended old driver',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),o=operations(db);await operationSeed(db);
    const departed=new Date(+clock-600000);
    await updateDoc(doc(db,'service_runs/run1'),{status:'in_progress',actualDepartureAt:departed});
    await updateDoc(doc(db,'trips/run1'),{currentStopIndex:1,actualDepartureTime:departed,stopTimes:{s1:{actualArrival:departed},s2:{actualArrival:clock}}});
    await setDoc(doc(db,'account_access/u1'),{manualSuspended:true});
    const before=await read(db,'trips/run1');
    await o.handover(handoverInput);
    await o.accept({actorUid:'u2',runId:'run1',handoverVersion:1,gps:{latitude:6.9,longitude:79.8,speed:10,heading:180,accuracy:5,observedAt:clock.toISOString()}});
    assert.deepEqual(await read(db,'trips/run1'),{...before,driverId:'u2'});
    const live=await read(db,'live_locations/b');assert.equal(live.currentStopIndex,1);assert.equal(live.status,'active');
  });
});
test('assistance handover reconciliation pages beyond twenty and never replays a superseded driver',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),o=operations(db),a=assistance(db);await operationSeed(db);await a.submit(helpInput);
    const base=await read(db,'boarding_requests/help1');
    for(let n=0;n<21;n++)await setDoc(doc(db,'boarding_requests/clone'+String(n).padStart(2,'0')),{...base,status:'acknowledged'});
    await o.handover(handoverInput);
    await o.reconcile({operationId:'transfer1'});
    assert.equal((await read(db,'operation_handovers/transfer1')).assistanceState,'pending');
    await o.handover({...handoverInput,operationId:'back',expectedVersion:1,expectedDriverId:'u2',newDriverId:'u1'});
    await o.reconcile({operationId:'transfer1'});await o.reconcile({operationId:'back'});await o.reconcile({operationId:'back'});
    assert.equal((await read(db,'operation_handovers/transfer1')).assistanceState,'completed');
    assert.equal((await read(db,'operation_handovers/back')).assistanceState,'completed');
    for(let n=0;n<21;n++){const r=await read(db,'boarding_requests/clone'+String(n).padStart(2,'0'));assert.equal(r.driverId,'u1');assert.equal(r.status,'pending');}
  });
});
test('notification registration is idempotent, capped, owner bound and private',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),n=notifications(db);await assistanceSeed(db);
    const first=await n.register(registration),again=await n.register(registration);assert.deepEqual(first,again);
    assert.equal((await read(db,'notification_device_counts/u1')).active,1);
    for(let k=0;k<7;k++)await n.register({...registration,token:deviceToken+k});
    await assert.rejects(n.register({...registration,token:deviceToken+'limit'}),{code:'device-limit'});
    await n.remove({actorUid:'u2',deviceId:first.deviceId});assert.equal((await read(db,'notification_devices/'+first.deviceId)).enabled,true);
    await n.remove({actorUid:'u1',deviceId:first.deviceId});assert.equal((await read(db,'notification_device_counts/u1')).active,7);
    const rebound=await n.register({...registration,actorUid:'u2'});assert.equal(rebound.generation,2);
    assert.equal((await read(db,'notification_devices/'+first.deviceId)).uid,'u2');
    await setDoc(doc(db,'account_access/u2'),{manualSuspended:true});
    await assert.rejects(n.register({...registration,actorUid:'u2'}),{code:'account-suspended'});
  });
  const db=env.authenticatedContext('u1').firestore(),key=createHash('sha256').update(deviceToken).digest('hex');
  await assertFails(getDoc(doc(db,'notification_devices/'+key)));
  await assertFails(setDoc(doc(db,'notification_devices/forged'),{uid:'u1',token:deviceToken,enabled:true}));
  await assertFails(setDoc(doc(db,'push_events/forged'),{uid:'u1',requestId:'help1'}));
});
test('local notification provider simulates one idempotent delivery without accepting the request',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),n=notifications(db);await assistanceSeed(db);await assistance(db).submit(helpInput);await n.register(registration);
    await n.dispatch(notice);await n.dispatch(notice);
    const event=await read(db,'notification_outbox/help1/events/assistance-1');assert.equal(event.pushState,'simulated');assert.equal(event.delivery,'in-app-only');
    const receipts=await getDocs(collection(db,'local_push_receipts'));assert.equal(receipts.size,1);assert.equal(receipts.docs[0].data().simulated,true);
    assert.equal((await read(db,'boarding_requests/help1')).status,'pending');
    assert.equal((await n.open({actorUid:'u1',eventId:noticeId()})).request.id,'help1');
    await assert.rejects(n.open({actorUid:'author',eventId:noticeId()}),{code:'notification-unavailable'});
  });
});
test('concurrent notification workers share a lease; transient failures retry without duplicate credits or acceptance',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore();await assistanceSeed(db);await assistance(db).submit(helpInput);
    let release,started,calls=0;const blocked=new Promise(r=>{release=r;}),seen=new Promise(r=>{started=r;});
    const n=notifications(db,{kind:'local',async send(){calls++;started();await blocked;}});await n.register(registration);
    const first=n.dispatch(notice);await seen;await n.dispatch(notice);assert.equal(calls,1);release();await first;
    assert.equal((await read(db,'notification_outbox/help1/events/assistance-1')).pushState,'simulated');
    await updateDoc(doc(db,'notification_outbox/help1/events/assistance-1'),{pushState:'pending'});
    const attempt=(await getDocs(collection(db,'push_attempts'))).docs[0];await deleteDoc(attempt.ref);
    const retry=notifications(db,{kind:'local',async send(){calls++;if(calls===2)throw Error('provider-down');}});
    await retry.dispatch(notice);assert.equal((await read(db,'notification_outbox/help1/events/assistance-1')).pushState,'retry');
    await retry.dispatch(notice);assert.equal(calls,2);
    clock=new Date(+clock+20000);await retry.dispatch(notice);assert.equal(calls,3);
    assert.equal((await read(db,'boarding_requests/help1')).status,'pending');
  });
});
test('notification handover discards old queued work and stale opens reload current driver authority',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),n=notifications(db),a=assistance(db);await operationSeed(db);await a.submit(helpInput);
    await n.register(registration);await n.dispatch(notice);
    await operations(db).handover(handoverInput);
    await assert.rejects(n.open({actorUid:'u1',eventId:noticeId()}),{code:'assistance-unavailable'});
    await a.reconcile({requestId:'help1'});
    await n.register({...registration,actorUid:'u2',token:deviceToken+'new'});
    await n.dispatch({requestId:'help1',assignmentVersion:2});
    assert.equal((await n.open({actorUid:'u2',eventId:noticeId('',2)})).request.status,'pending');
    await a.action({actorUid:'author',requestId:'help1',status:'cancelled'});
    await assert.rejects(n.open({actorUid:'u2',eventId:noticeId('',2)}),{code:'notification-unavailable'});
    // An unsent prior version must also be skipped, rather than waking old driver.
    await updateDoc(doc(db,'notification_outbox/help1/events/assistance-1'),{pushState:'pending'});
    await n.dispatch(notice);assert.equal((await read(db,'notification_outbox/help1/events/assistance-1')).pushState,'skipped');
  });
});
test('invalid token failure cannot disable a token rebound to another account during delivery',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore();await assistanceSeed(db);await assistance(db).submit(helpInput);
    let n;n=notifications(db,{kind:'local',async send(){await n.register({...registration,actorUid:'u2'});throw Object.assign(Error('bad-token'),{code:'invalid-token'});}});
    const device=await n.register(registration);await n.dispatch(notice);
    const value=await read(db,'notification_devices/'+device.deviceId);assert.equal(value.uid,'u2');assert.equal(value.enabled,true);assert.equal(value.generation,2);
    await assert.rejects(n.open({actorUid:'u2',eventId:noticeId()}),{code:'notification-unavailable'});
  });
});
test('notification delivery retries are bounded and sample receipts stay isolated',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),n=notifications(db,{kind:'local',async send(){throw Error('offline');}});await assistanceSeed(db);await assistance(db).submit(helpInput);await n.register(registration);
    for(let attempt=0;attempt<5;attempt++){await n.dispatch(notice);clock=new Date(+clock+300001);}
    assert.equal((await read(db,'notification_outbox/help1/events/assistance-1')).pushState,'failed');
    clock=new Date(initial);await assistanceSeed(db,'sample_test/shared/');
    await assistance(db).submit({...helpInput,scope:'sample'});const sample=notifications(db);
    await sample.register({...registration,scope:'sample'});await sample.dispatch({...notice,scope:'sample'});
    assert.equal((await getDocs(collection(db,'sample_test/shared/local_push_receipts'))).size,1);
    assert.equal((await getDocs(collection(db,'local_push_receipts'))).size,0);
  });
});
test('notification scan waits for devices, drains a full device page and disables only a definitively invalid token',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),n=notifications(db);await assistanceSeed(db);await assistance(db).submit(helpInput);
    await n.dispatch(notice);assert.equal((await read(db,'notification_outbox/help1/events/assistance-1')).pushReason,'no-device');
    for(let k=0;k<8;k++)await n.register({...registration,token:deviceToken+k});
    await n.dispatch(notice);assert.equal((await read(db,'notification_outbox/help1/events/assistance-1')).pushState,'pending');
    await n.dispatch(notice);assert.equal((await read(db,'notification_outbox/help1/events/assistance-1')).pushState,'simulated');
    assert.equal((await getDocs(collection(db,'local_push_receipts'))).size,8);
    // A new request gives the invalid-token case its own immutable event ID.
    await assistance(db).submit({...helpInput,requestId:'invalid-token'});
    const invalid=notifications(db,{kind:'local',async send(){throw Object.assign(Error('invalid'),{code:'invalid-token'});}});
    await invalid.dispatch({requestId:'invalid-token',assignmentVersion:1});
    await invalid.dispatch({requestId:'invalid-token',assignmentVersion:1});
    assert.equal((await read(db,'notification_device_counts/u1')).active,0);
    assert.equal((await read(db,'notification_outbox/invalid-token/events/assistance-1')).pushState,'failed');
  });
});
const helpInput={actorUid:'author',requestId:'help1',serviceRunId:'run1',busId:'b',stationId:'s1',boardingStationId:'s1',alightingStationId:'s3',purpose:'boarding',assistanceTypes:['Deploy Ramp']};
async function assistanceSeed(db,p=''){
  await seed(db,p);
  await setDoc(doc(db,p+'routes/route1'),{stops:['s1','s2','s3'],catalogueSource:'operator_catalogue'});
  for(const uid of ['u1','u2']){
    await setDoc(doc(db,p+'operator_access/'+uid),{approved:true});
    await setDoc(doc(db,p+'driver_route_assignments/'+uid),{active:true,routeId:'route1'});
  }
  await setDoc(doc(db,p+'buses/b'),{driverId:'u1',routeId:'route1',stops:['s1','s2','s3'],catalogueSource:'operator_catalogue'});
  for(const id of ['s1','s2','s3'])await setDoc(doc(db,p+'stations/'+id),{name:id,catalogueSource:'operator_catalogue'});
  await setDoc(doc(db,p+'service_runs/run1'),{busId:'b',driverId:'u1',routeId:'route1',routeNo:'1',status:'boarding',stops:['s1','s2','s3'],latestStartAt:new Date(+clock+1800000),initialStopTimes:{s1:{estimatedArrival:clock},s2:{estimatedArrival:new Date(+clock+600000)},s3:{estimatedArrival:new Date(+clock+1200000)}}});
  await setDoc(doc(db,p+'operation_locks/u1'),{active:true,busId:'b',tripId:'run1'});
  await setDoc(doc(db,p+'trips/run1'),{driverId:'u1',busId:'b',status:'in_progress',currentStopIndex:0});
}
test('assistance binds exact run/segment and resolves current driver with idempotent acknowledged retry',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),a=assistance(db);await assistanceSeed(db);
    const first=await a.submit(helpInput);assert.equal(first.request.driverId,'u1');assert.equal(first.request.serviceRunId,'run1');
    await assert.rejects(a.action({actorUid:'u2',requestId:'help1',status:'acknowledged'}),{code:'assistance-unavailable'});
    const ack=await a.action({actorUid:'u1',requestId:'help1',status:'acknowledged'});assert.equal(ack.request.status,'acknowledged');
    assert.equal((await a.submit(helpInput)).request.status,'acknowledged');
    await assert.rejects(a.submit({...helpInput,serviceRunId:'another-run'}),{code:'request-id-conflict'});
    await assert.rejects(a.submit({...helpInput,requestId:'bad-segment',boardingStationId:'s3',alightingStationId:'s1'}),{code:'invalid-request'});
    assert.equal((await read(db,'notification_outbox/help1/events/assistance-1')).uid,'u1');
    await a.action({actorUid:'u1',requestId:'help1',status:'completed'});
    await assert.rejects(a.action({actorUid:'u1',requestId:'help1',status:'acknowledged'}),{code:'assistance-transition-denied'});
  });
});
test('assistance handover revokes old driver, resets acceptance and retargets exactly once',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),a=assistance(db);await assistanceSeed(db);await a.submit(helpInput);await a.action({actorUid:'u1',requestId:'help1',status:'acknowledged'});
    await updateDoc(doc(db,'buses/b'),{driverId:'u2'});await updateDoc(doc(db,'service_runs/run1'),{driverId:'u2'});
    await updateDoc(doc(db,'trips/run1'),{driverId:'u2'});
    await setDoc(doc(db,'operation_locks/u2'),{active:true,busId:'b',tripId:'run1'});
    await assert.rejects(a.get({actorUid:'u1',requestId:'help1'}),{code:'assistance-unavailable'});
    const requests=await a.list({actorUid:'u2',serviceRunId:'run1'});assert.equal(requests.items[0].status,'pending');assert.equal(requests.items[0].assignmentVersion,2);
    await a.reconcile({requestId:'help1'});assert.equal((await read(db,'boarding_requests/help1')).assignmentVersion,2);
    assert.equal((await read(db,'notification_outbox/help1/events/assistance-2')).uid,'u2');
    assert.equal((await read(db,'assistance_audit/help1/events/handover-2')).oldDriver,'u1');
    await a.action({actorUid:'u2',requestId:'help1',status:'acknowledged'});
  });
});
test('assistance expires at exact deadline, passed stop and terminal run; rider cancellation is final',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),a=assistance(db);await assistanceSeed(db);const first=await a.submit(helpInput);
    clock=new Date(first.request.expiresAt);assert.equal((await a.get({actorUid:'author',requestId:'help1'})).request.status,'expired');
    clock=new Date(initial);await a.submit({...helpInput,requestId:'help2'});await updateDoc(doc(db,'trips/run1'),{currentStopIndex:1});
    assert.equal((await a.reconcile({requestId:'help2'})).request.endReason,'stop-passed');
    await updateDoc(doc(db,'trips/run1'),{currentStopIndex:0});await a.submit({...helpInput,requestId:'help3'});
    await a.action({actorUid:'author',requestId:'help3',status:'cancelled'});
    await assert.rejects(a.action({actorUid:'u1',requestId:'help3',status:'acknowledged'}),{code:'assistance-transition-denied'});
    await a.submit({...helpInput,requestId:'help4'});await updateDoc(doc(db,'service_runs/run1'),{status:'completed'});
    assert.equal((await a.reconcile({requestId:'help4'})).request.endReason,'run-ended');
    await assert.rejects(a.submit({...helpInput,requestId:'help5'}),{code:'assistance-unavailable'});
  });
});
test('assistance authorization, rollback, privacy and Sample isolation hold for old clients',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),a=assistance(db);await assistanceSeed(db);await assistanceSeed(db,'sample_test/shared/');
    await assert.rejects(assistance(db,{store:store(db,true)}).submit(helpInput),/commit-rejected/);assert.equal(await read(db,'boarding_requests/help1'),undefined);
    await a.submit(helpInput);assert.equal(await read(db,'sample_test/shared/boarding_requests/help1'),undefined);
    await assert.rejects(a.get({actorUid:'u6',requestId:'help1'}),{code:'assistance-unavailable'});
    await setDoc(doc(db,'account_access/author'),{communityPermanent:true});
    await assert.rejects(a.submit({...helpInput,requestId:'banned'}),{code:'account-suspended'});
    await setDoc(doc(db,'assistance_config/active'),{enabled:true});
  });
  const rider=env.authenticatedContext('author').firestore(),other=env.authenticatedContext('u6').firestore();
  await assertFails(getDoc(doc(other,'boarding_requests/help1')));
  await assertFails(updateDoc(doc(rider,'boarding_requests/help1'),{status:'cancelled'}));
  await assertFails(setDoc(doc(rider,'boarding_requests/direct'),{riderId:'author',policyVersion:2}));
});
test('assistance cannot use a revoked route grant or an origin already departed',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),a=assistance(db);await assistanceSeed(db);await a.submit(helpInput);
    await updateDoc(doc(db,'trips/run1'),{actualDepartureTime:clock});
    assert.equal((await a.reconcile({requestId:'help1'})).request.endReason,'stop-passed');
    await assert.rejects(a.submit({...helpInput,requestId:'departed'}),{code:'assistance-unavailable'});
    await updateDoc(doc(db,'trips/run1'),{actualDepartureTime:null});await a.submit({...helpInput,requestId:'grant-request'});
    await updateDoc(doc(db,'driver_route_assignments/u1'),{active:false});
    await assert.rejects(a.submit({...helpInput,requestId:'bad-route'}),{code:'assistance-unavailable'});
    assert.equal((await a.reconcile({requestId:'grant-request'})).request.endReason,'driver-unavailable');
  });
});
test('rider assistance history starts with latest publication and rejects another riders cursor',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),a=assistance(db);await assistanceSeed(db);await a.submit(helpInput);clock=new Date(+clock+1000);
    await a.submit({...helpInput,requestId:'new-help'});await a.submit({...helpInput,requestId:'other',actorUid:'u6'});
    const history=await a.list({actorUid:'author'});assert.equal(history.items[0].id,'new-help');
    await assert.rejects(a.list({actorUid:'author',after:'other'}),{code:'invalid-request'});
  });
});

const bans=(db,extra={})=>createBanPolicy({store:store(db),accountAdmin:async()=>false,now:()=>clock,...extra});
const banDecision={actorUid:'u6',actorAdmin:true,accountId:'author',outcome:'approve',reason:'Reviewed every contributing report',expectedRevision:0};
async function banSeed(db,p=''){
  await seed(db,p);
  await setDoc(doc(db,p+'contribution_summaries/author'),{policyVersion:2,points:-100,falseReportStrikes:10,moderationRevision:0});
  await setDoc(doc(db,p+'permanent_ban_reviews/author'),{status:'pending',strikeCount:10,createdAt:clock});
}
test('ban commit rechecks revision when a new appeal races its pending query',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore();await banSeed(db);
    await setDoc(doc(db,'moderation_decisions/r'),{policyVersion:2,authorUid:'author',strikeCounted:true,penalty:20,createdAt:clock,falseCount:5});
    const base=store(db),a=createAppealPolicy({store:base,now:()=>clock});let raced=false;
    const racing={...base,async page(input){const result=await base.page(input);if(input.collection==='report_appeals'&&!raced){raced=true;await a.submit({actorUid:'author',reportId:'r',reason:'Concurrent appeal evidence'});}return result;}};
    await assert.rejects(bans(db,{store:racing}).decide(banDecision),{code:'review-stale'});
    assert.equal(await read(db,'permanent_ban_decisions/author'),undefined);
  });
});
test('Sample ban remains scoped; only a new strike can reopen a never-decided withdrawn review',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore();await banSeed(db);await banSeed(db,'sample_test/shared/');
    await bans(db).decide({...banDecision,scope:'sample'});
    assert.equal((await read(db,'sample_test/shared/account_access/author')).communityPermanent,true);
    assert.equal(await read(db,'account_access/author'),undefined);
    const s=service(db);await s.creditReport({reportId:'r'});
    await setDoc(doc(db,'contribution_summaries/author'),{policyVersion:2,points:10,falseReportStrikes:9,moderationRevision:0});
    await setDoc(doc(db,'permanent_ban_reviews/author'),{status:'withdrawn',strikeCount:9,createdAt:clock});
    await disputed(s);assert.equal((await read(db,'permanent_ban_reviews/author')).status,'pending');
    assert.equal((await read(db,'permanent_ban_reviews/author')).triggerReportId,'r');
  });
});
test('new counted report can reopen rejected review while retaining immutable prior decision',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),s=service(db);await banSeed(db);await bans(db).decide({...banDecision,outcome:'reject'});
    await s.creditReport({reportId:'r'});await disputed(s);
    const review=await read(db,'permanent_ban_reviews/author'),total=await read(db,'contribution_summaries/author');
    assert.equal(review.status,'pending');assert.ok(review.decisionKey);
    await assert.rejects(bans(db).decide(banDecision),{code:'review-stale'});
    await bans(db).decide({...banDecision,expectedRevision:total.moderationRevision});
    assert.equal((await read(db,'permanent_ban_decisions/author')).outcome,'reject');
    assert.equal((await read(db,'permanent_ban_decisions/'+review.decisionKey)).outcome,'approve');
  });
});
test('permanent ban needs explicit active admin decision; duplicate concurrent approvals produce one audited restriction',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),b=bans(db);await banSeed(db);
    assert.equal((await service(db).accountStatus({actorUid:'author'})).state,'active');
    await assert.rejects(b.decide({...banDecision,actorAdmin:false}),{code:'admin-required'});
    await assert.rejects(b.decide({...banDecision,actorUid:'author'}),{code:'self-review-forbidden'});
    await assert.rejects(bans(db,{accountAdmin:async()=>true}).decide(banDecision),{code:'admin-account-protected'});
    const results=await Promise.all([b.decide(banDecision),b.decide(banDecision)]);assert.equal(results.filter(r=>!r.duplicate).length,1);
    assert.equal((await read(db,'account_access/author')).communityPermanent,true);
    assert.equal((await service(db).accountStatus({actorUid:'author'})).state,'permanent');
    assert.equal((await service(db).accountStatus({actorUid:'author'})).banReason,banDecision.reason);
    assert.equal((await read(db,'permanent_ban_decisions/author')).outcome,'approve');
    assert.equal((await read(db,'contribution_summaries/author')).points,-100);
    await assert.rejects(b.decide({...banDecision,outcome:'reject'}),{code:'review-already-decided'});
  });
  const db=env.authenticatedContext('author').firestore();
  await assertFails(setDoc(doc(db,'search_clock/author'),{serverTime:serverTimestamp()}));
  await assertFails(setDoc(doc(db,'permanent_ban_decisions/author'),{outcome:'reject'}));
});
test('permanent decision rejects stale revisions, unresolved appeals and inactive reviewers',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),b=bans(db),a=createAppealPolicy({store:store(db),now:()=>clock});await banSeed(db);
    await setDoc(doc(db,'moderation_decisions/r'),{policyVersion:2,authorUid:'author',strikeCounted:true,penalty:20,createdAt:clock,falseCount:5});
    await a.submit({actorUid:'author',reportId:'r',reason:'Photograph supports the report'});
    await assert.rejects(b.decide(banDecision),{code:'review-stale'});
    await assert.rejects(b.decide({...banDecision,expectedRevision:1}),{code:'appeals-pending'});
    assert.equal((await b.detail(banDecision)).pendingAppeals,true);
    await setDoc(doc(db,'account_access/u6'),{communityPermanent:true});
    await assert.rejects(b.list(banDecision),{code:'account-suspended'});
    assert.equal(await read(db,'permanent_ban_decisions/author'),undefined);
  });
});
test('rejection preserves independent access deadlines and never replays as permanent approval',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),b=bans(db);await banSeed(db);
    const deadline=new Date(+clock+3600000);await setDoc(doc(db,'account_access/author'),{manualSuspendedUntil:deadline});
    await b.decide({...banDecision,outcome:'reject'});
    assert.equal((await read(db,'account_access/author')).manualSuspendedUntil.toMillis(),+deadline);
    assert.equal((await service(db).accountStatus({actorUid:'author'})).state,'temporary');
    assert.equal((await b.decide({...banDecision,outcome:'reject'})).duplicate,true);
    await assert.rejects(b.decide(banDecision),{code:'review-already-decided'});
    clock=deadline;assert.equal((await service(db).accountStatus({actorUid:'author'})).state,'active');
  });
});
test('failed ban commit rolls back; scope and protected account checks fail closed',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore();await banSeed(db);await seed(db,'sample_test/shared/');
    await assert.rejects(bans(db,{store:store(db,true)}).decide(banDecision),/commit-rejected/);
    assert.equal(await read(db,'account_access/author'),undefined);
    assert.equal(await read(db,'permanent_ban_decisions/author'),undefined);
    assert.equal((await bans(db).list({...banDecision,scope:'sample'})).items.length,0);
    await assert.rejects(bans(db).decide({...banDecision,scope:'sample'}),{code:'review-unavailable'});
    await assert.rejects(bans(db,{accountAdmin:async()=>{throw Error('Auth unavailable');}}).decide(banDecision),/Auth unavailable/);
  });
});
test('later report overturn removes community permanent restriction below ten without clearing manual permanent state',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),s=service(db);await seed(db);await s.creditReport({reportId:'r'});await disputed(s);
    await setDoc(doc(db,'contribution_summaries/author'),{policyVersion:2,points:-100,falseReportStrikes:10,moderationRevision:1});
    await setDoc(doc(db,'permanent_ban_reviews/author'),{status:'pending',strikeCount:10,createdAt:clock});
    await bans(db).decide({...banDecision,expectedRevision:1});
    await setDoc(doc(db,'account_access/author'),{communityPermanent:true,permanent:true});
    await createAppealPolicy({store:store(db),now:()=>clock}).review({actorUid:'u6',actorAdmin:true,reportId:'r',outcome:'overturn',reason:'Evidence confirms author report'});
    const access=await read(db,'account_access/author');assert.equal(access.communityPermanent,false);assert.equal(access.permanent,true);
    assert.equal((await read(db,'permanent_ban_reviews/author')).status,'withdrawn');
    assert.equal((await read(db,'permanent_ban_decisions/author')).outcome,'approve');
    assert.equal((await bans(db).decide({...banDecision,expectedRevision:1})).duplicate,true);
    assert.equal((await read(db,'account_access/author')).communityPermanent,false);
  });
});

test('restricted author can privately appeal once; another user and forged admin cannot review',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),s=service(db),a=createAppealPolicy({store:store(db),now:()=>clock});await seed(db);await s.creditReport({reportId:'r'});await disputed(s);
    await setDoc(doc(db,'account_access/author'),{manualSuspended:true});
    const input={actorUid:'author',reportId:'r'};
    assert.equal((await a.detail(input)).penalty,20);
    assert.equal((await a.list({actorUid:'author'})).items.length,1);
    assert.equal((await a.list({actorUid:'u6'})).items.length,0);
    await assert.rejects(a.detail({actorUid:'u6',reportId:'r'}),{code:'dispute-unavailable'});
    await assert.rejects(a.list({actorUid:'u6',queue:true}),{code:'admin-required'});
    await assert.rejects(a.submit({...input,reason:'bad'}),{code:'reason-required'});
    const results=await Promise.all([a.submit({...input,reason:'The ramp was broken'}),a.submit({...input,reason:'The ramp was broken'})]);
    assert.equal(results.filter(r=>!r.duplicate).length,1);
    assert.equal((await a.detail(input)).appeal.status,'pending');
    await assert.rejects(a.review({...input,outcome:'overturn',reason:'Reviewed evidence'}),{code:'admin-required'});
    await assert.rejects(a.review({...input,actorAdmin:true,outcome:'overturn',reason:'Reviewed evidence'}),{code:'account-suspended'});
  });
});

test('admin overturn atomically restores one penalty/strike and preserves independent restrictions',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),s=service(db),a=createAppealPolicy({store:store(db),now:()=>clock});await seed(db);await s.creditReport({reportId:'r'});await disputed(s);
    await setDoc(doc(db,'contribution_summaries/author'),{policyVersion:2,points:-10,falseReportStrikes:5});
    await setDoc(doc(db,'account_access/author'),{communitySuspendedUntil:new Date(+clock+72*3600000),manualSuspended:true,permanent:true});
    await setDoc(doc(db,'permanent_ban_reviews/author'),{status:'pending',strikeCount:10});
    await a.submit({actorUid:'author',reportId:'r',reason:'Please review the photograph'});
    const input={actorUid:'u6',actorAdmin:true,reportId:'r',outcome:'overturn',reason:'Evidence supports the author'};
    const results=await Promise.all([a.review(input),a.review(input)]);assert.equal(results.filter(r=>!r.duplicate).length,1);
    const total=await read(db,'contribution_summaries/author'),access=await read(db,'account_access/author');
    assert.equal(total.points,10);assert.equal(total.falseReportStrikes,4);assert.equal(access.communitySuspendedUntil,null);
    assert.equal(access.manualSuspended,true);assert.equal(access.permanent,true);
    assert.equal((await read(db,'permanent_ban_reviews/author')).status,'withdrawn');
    assert.equal((await read(db,'reports/r')).moderationOverturned,true);
    assert.equal((await a.detail({actorUid:'author',reportId:'r'})).appeal.status,'accepted');
    assert.equal((await a.evidence(input)).items.length,5);
    assert.equal((await s.voteStatus({actorUid:'u1',reportId:'r'})).status,'resolved');
    await assert.rejects(vote(s,'u6'),{code:'voting-closed'});
    await assert.rejects(a.review({...input,outcome:'uphold'}),{code:'review-already-decided'});
  });
});

test('uphold and rejected commits never change the balance, one final review closes submission',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),s=service(db),a=createAppealPolicy({store:store(db),now:()=>clock});await seed(db);await s.creditReport({reportId:'r'});await disputed(s);
    const input={actorUid:'u6',actorAdmin:true,reportId:'r',outcome:'overturn',reason:'Reviewed condition evidence'};
    const rejecting=createAppealPolicy({store:store(db,true),now:()=>clock});
    await assert.rejects(rejecting.review(input),/commit-rejected/);
    assert.equal((await read(db,'contribution_summaries/author')).points,-10);
    assert.equal(await read(db,'appeal_reviews/r'),undefined);
    await a.review({...input,outcome:'uphold'});
    assert.equal((await read(db,'contribution_summaries/author')).falseReportStrikes,1);
    await assert.rejects(a.submit({actorUid:'author',reportId:'r',reason:'New appeal after final review'}),{code:'review-already-decided'});
    assert.equal((await a.detail({actorUid:'author',reportId:'r'})).reviewReason,'Reviewed condition evidence');
  });
});

test('review pages are bounded and private writes remain denied',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),a=createAppealPolicy({store:store(db),now:()=>clock});await seed(db);
    for(let i=0;i<22;i++)await setDoc(doc(db,'moderation_decisions/p'+String(i).padStart(2,'0')),{authorUid:'author',penalty:20,strikeCounted:true,createdAt:clock});
    const first=await a.list({actorUid:'author'}),second=await a.list({actorUid:'author',after:first.next});
    assert.equal(first.items.length,20);assert.equal(second.items.length,2);assert.equal(second.next,null);
    await assert.rejects(a.review({actorUid:'author',actorAdmin:true,reportId:'p00',outcome:'uphold',reason:'Self review request'}),{code:'self-review-forbidden'});
  });
  const db=env.authenticatedContext('author').firestore();
  for(const path of ['report_appeals/r','appeal_reviews/r','moderation_decisions/r','reward_events/r/entries/appeal-restoration'])await assertFails(setDoc(doc(db,path),{authorUid:'author'}));
});

test('appeals are scope-isolated and restored access cancels a pending suspension job',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),s=service(db),a=createAppealPolicy({store:store(db),now:()=>clock});await seed(db);await s.creditReport({reportId:'r'});await disputed(s);
    await seed(db,'sample_test/shared/');
    assert.equal((await a.list({actorUid:'author',scope:'sample'})).items.length,0);
    await assert.rejects(a.detail({actorUid:'author',scope:'sample',reportId:'r'}),{code:'dispute-unavailable'});
    await setDoc(doc(db,'notification_outbox/r/events/reconcile-operation'),{kind:'reconcile-suspended-operation',status:'pending',uid:'author',createdAt:clock});
    await setDoc(doc(db,'operation_locks/author'),{active:true,busId:'b',tripId:'run',updatedAt:clock});
    await setDoc(doc(db,'trips/run'),{busId:'b',driverId:'author',status:'in_progress'});
    await a.review({actorUid:'u6',actorAdmin:true,reportId:'r',outcome:'overturn',reason:'Report photograph supports appeal'});
    await s.reconcileOperation({reportId:'r'});
    assert.equal((await read(db,'trips/run')).status,'in_progress');
    assert.equal((await read(db,'notification_outbox/r/events/reconcile-operation')).status,'completed');
    assert.equal(await read(db,'sample_test/shared/reward_events/r/entries/appeal-restoration'),undefined);
  });
});

test('publication is +10 once, True is unrewarded, five distinct False votes give one -20/strike', async () => {
  await env.withSecurityRulesDisabled(async c => {
    const db=c.firestore(), s=service(db); await seed(db);
    await assert.rejects(reconcileReport(db,'r',{apply:true}),/Policy v2 reports require/);
    await Promise.all([s.creditReport({reportId:'r'}),s.creditReport({reportId:'r'})]);
    await vote(s,'truth','r','true');
    assert.equal(await read(db,'contribution_summaries/truth'),undefined);
    for (const uid of ['u1','u2','u3','u4']) await vote(s,uid);
    assert.equal((await read(db,'reports/r')).status,'active');
    assert.equal((await read(db,'contribution_summaries/author')).points,10);
    await Promise.all([vote(s,'u5'),vote(s,'u5')]);
    const report=await read(db,'reports/r'), totals=await read(db,'contribution_summaries/author');
    assert.equal(report.status,'hidden'); assert.equal(report.falseCount,5); assert.equal(report.confirmCount,1);
    assert.equal(totals.points,-10); assert.equal(totals.falseReportStrikes,1);
    assert.equal((await read(db,'reward_events/r/entries/dispute')).amount,-20);
    await assert.rejects(vote(s,'u6'),{code:'voting-closed'});
    await assert.rejects(vote(s,'u1','r','true'),{code:'voting-closed'});
    assert.equal((await read(db,'contribution_summaries/author')).points,-10);
  });
});

test('concurrent fifth voters and concurrent reports never duplicate or lose author penalties', async () => {
  await env.withSecurityRulesDisabled(async c => {
    const db=c.firestore(),s=service(db);await seed(db);await newReport(db,'r2');
    await s.creditReport({reportId:'r'});await s.creditReport({reportId:'r2'});
    for(const id of ['r','r2']) for(const uid of ['u1','u2','u3','u4']) await vote(s,uid,id);
    const results=await Promise.allSettled([vote(s,'u5'),vote(s,'u6'),vote(s,'u5','r2')]);
    assert.equal(results.filter(r=>r.status==='fulfilled').length,2);
    const totals=await read(db,'contribution_summaries/author');assert.equal(totals.points,-20);assert.equal(totals.falseReportStrikes,2);
  });
});

test('authors, missing accounts, banned voters and missing False reasons are rejected', async () => {
  await env.withSecurityRulesDisabled(async c => {
    const db=c.firestore(),s=service(db);await seed(db);await s.creditReport({reportId:'r'});
    for(const value of ['true','false']) await assert.rejects(vote(s,'author','r',value),{code:'author-cannot-vote'});
    await assert.rejects(s.voteReport({reportId:'r',actorUid:'u1',value:'false',reason:''}),{code:'false-reason-required'});
    await assert.rejects(vote(s,'missing'),{code:'account-missing'});
    await setDoc(doc(db,'account_access/u1'),{communitySuspendedUntil:new Date(clock.getTime()+1000)});
    await assert.rejects(vote(s,'u1'),{code:'account-suspended'});
    clock=new Date(clock.getTime()+1000);await vote(s,'u1');
    assert.equal((await read(db,'reports/r')).falseCount,1);
  });
});

test('switching a vote moves only its own count and True never cancels other False votes', async () => {
  await env.withSecurityRulesDisabled(async c => {
    const db=c.firestore(),s=service(db);await seed(db);await s.creditReport({reportId:'r'});
    await vote(s,'u1');await vote(s,'u2','r','true');await vote(s,'u1','r','true');
    let r=await read(db,'reports/r');assert.equal(r.falseCount,0);assert.equal(r.confirmCount,2);
    await vote(s,'u2');r=await read(db,'reports/r');assert.equal(r.falseCount,1);assert.equal(r.confirmCount,1);
    await vote(s,'u2');assert.equal((await read(db,'reports/r')).falseCount,1);
    assert.equal((await read(db,'contribution_summaries/author')).points,10);
  });
});

test('fifth strike is 72 hours once; tenth opens review without permanent ban or extension', async () => {
  await env.withSecurityRulesDisabled(async c => {
    const db=c.firestore(),s=service(db);await seed(db);
    await setDoc(doc(db,'contribution_summaries/author'),{policyVersion:2,points:0,falseReportStrikes:4});
    await s.creditReport({reportId:'r'});await disputed(s);
    const until=(await read(db,'account_access/author')).communitySuspendedUntil.toDate();
    assert.equal(until-clock,72*60*60*1000);
    const status=await s.accountStatus({actorUid:'author'});
    assert.equal(status.state,'temporary');assert.equal(status.suspendedUntil,until.toISOString());
    clock=new Date(until);
    assert.equal((await s.accountStatus({actorUid:'author'})).state,'active');
    for(let n=6;n<=10;n++) { await newReport(db,'r'+n);await s.creditReport({reportId:'r'+n});await disputed(s,'r'+n); }
    const access=await read(db,'account_access/author');assert.equal(access.communitySuspendedUntil.toMillis(),until.getTime());
    assert.notEqual(access.permanent,true);assert.equal((await read(db,'permanent_ban_reviews/author')).status,'pending');
    assert.equal((await read(db,'contribution_summaries/author')).falseReportStrikes,10);
    assert.equal((await read(db,'notification_outbox/r/events/reconcile-operation')).uid,'author');
  });
});

test('legacy reports/balances, demo targets and missing ledgers fail without mutation', async () => {
  await env.withSecurityRulesDisabled(async c => {
    const db=c.firestore(),s=service(db);await seed(db);
    await updateDoc(doc(db,'reports/r'),{policyVersion:1});await assert.rejects(s.creditReport({reportId:'r'}),{code:'report-ineligible'});
    await updateDoc(doc(db,'reports/r'),{policyVersion:2});await updateDoc(doc(db,'users/author'),{points:20});
    await assert.rejects(s.creditReport({reportId:'r'}),{code:'migration-required'});
    await updateDoc(doc(db,'users/author'),{points:0});await updateDoc(doc(db,'buses/b'),{isDemo:true});
    await assert.rejects(s.creditReport({reportId:'r'}),{code:'report-ineligible'});
    await assert.rejects(vote(s,'u1'),{code:'migration-required'});
    assert.equal(await read(db,'contribution_summaries/author'),undefined);
  });
});

test('rejected fifth-vote commit rolls back hide, vote, ledger and strike together', async () => {
  await env.withSecurityRulesDisabled(async c => {
    const db=c.firestore(),s=service(db);await seed(db);await s.creditReport({reportId:'r'});
    for(const uid of ['u1','u2','u3','u4']) await vote(s,uid);
    await assert.rejects(vote(service(db,true),'u5'),/commit-rejected/);
    assert.equal((await read(db,'reports/r')).falseCount,4);assert.equal((await read(db,'reports/r')).status,'active');
    assert.equal((await read(db,'contribution_summaries/author')).points,10);
    assert.equal(await read(db,'reports/r/votes/u5'),undefined);assert.equal(await read(db,'moderation_decisions/r'),undefined);
  });
});

test('sample decisions and strikes do not mutate normal access or contributions', async () => {
  await env.withSecurityRulesDisabled(async c => {
    const db=c.firestore(),s=service(db),p='sample_test/shared/';await seed(db);await seed(db,p);
    await s.creditReport({reportId:'r',scope:'sample'});
    for(const uid of ['u1','u2','u3','u4','u5']) await s.voteReport({reportId:'r',actorUid:uid,value:'false',reason:'Working equipment',scope:'sample'});
    assert.equal((await read(db,p+'contribution_summaries/author')).points,-10);
    assert.equal(await read(db,'contribution_summaries/author'),undefined);assert.equal((await read(db,'reports/r')).status,'active');
  });
});

test('zero balance still receives the full signed penalty once', async () => {
  await env.withSecurityRulesDisabled(async c => {
    const db=c.firestore(),s=service(db);await seed(db);await s.creditReport({reportId:'r'});
    // Represents an independently reviewed prior adjustment, never a clamp.
    await updateDoc(doc(db,'contribution_summaries/author'),{points:0});
    await disputed(s);await vote(s,'u5');await s.creditReport({reportId:'r'});
    const totals=await read(db,'contribution_summaries/author');
    assert.equal(totals.points,-20);assert.equal(totals.falseReportStrikes,1);
  });
});

test('authenticated API adapter reaches real fifth-vote transaction and idempotent receipt', async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),s=service(db);await seed(db);await s.creditReport({reportId:'r'});
    for(const uid of ['u1','u2','u3','u4']) await vote(s,uid);
    const handler=createModerationApi({auth:{async verifyIdToken(token,revoked){assert.equal(revoked,true);assert.equal(token,'test-token');return {uid:'u5'};}},policy:s});
    const send=()=>handler(new Request('https://test.local/v2/reports/vote',{method:'POST',
      headers:{authorization:'Bearer test-token','content-type':'application/json'},
      body:JSON.stringify({reportId:'r',value:'false',reason:'Equipment works'})}));
    const first=await send(),second=await send();assert.equal(first.status,200);assert.equal(second.status,200);
    assert.equal((await first.json()).hidden,true);const result=await second.json();
    assert.equal(result.duplicate,true);assert.equal(result.falseCount,5);assert.equal(result.uid,'u5');
    assert.equal((await read(db,'contribution_summaries/author')).points,-10);
  });
});

test('clients cannot mutate/delete v2 reports, votes, rewards, strikes or permanent review cases', async () => {
  await env.withSecurityRulesDisabled(async c=>{await seed(c.firestore());});
  for(const uid of ['author','u1','admin']) {
    const db=env.authenticatedContext(uid,{admin:uid==='admin'}).firestore();
    await assertFails(updateDoc(doc(db,'reports/r'),{falseCount:5,status:'hidden'}));
    await assertFails(deleteDoc(doc(db,'reports/r')));
    for(const path of ['reports/r/votes/u1','contribution_summaries/author','account_access/author','reward_events/r/entries/dispute','moderation_decisions/r','permanent_ban_reviews/author']) {
      await assertFails(setDoc(doc(db,path),{points:100,permanent:true}));
    }
  }
});

const publication = () => ({targetType:'bus',targetId:'b',targetName:'Test bus',problemType:'Ramp broken',
  severity:'major',category:'rampAccess',subCategory:'Broken',condition:'barrier',crowdingLevel:'',
  description:'Observed condition',photoUrl:'',observedAt:new Date(initial.getTime()-60000).toISOString()});
test('v2 publication atomically awards, locks cooldown and preserves observation time/retry identity',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),s=service(db);await seed(db);
    const publish=(reportId,report=publication())=>s.publishReport({reportId,actorUid:'author',report});
    await publish('published');await publish('published');
    const r=await read(db,'reports/published');assert.equal(r.policyVersion,2);assert.equal(r.userId,'author');
    assert.equal(r.createdAt.toMillis(),+initial);assert.equal(r.observedAt.toMillis(),+initial-60000);
    assert.equal((await read(db,'contribution_summaries/author')).points,10);
    await assert.rejects(publish('cooldown'),{code:'report-cooldown'});
    await assert.rejects(publish('wording',{...publication(),problemType:'Same issue wording',condition:'positive'}),{code:'report-cooldown'});
    await publish('different',{...publication(),category:'crowding'});
    clock=new Date(+initial+299999);await assert.rejects(publish('early'),{code:'report-cooldown'});
    clock=new Date(+initial+300000);await publish('boundary');
    assert.equal((await read(db,'contribution_summaries/author')).points,30);
  });
});
test('v2 publication rejects forged trusted fields and concurrent same-issue requests have one winner',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),s=service(db);await seed(db);
    for(const extra of [{userId:'u1'},{points:100},{status:'hidden'},{observedAt:'invalid'}]) {
      await assert.rejects(s.publishReport({reportId:'bad',actorUid:'author',report:{...publication(),...extra}}),{code:'invalid-request'});
    }
    const results=await Promise.allSettled(['a','z'].map(reportId=>s.publishReport({reportId,actorUid:'author',report:publication()})));
    assert.equal(results.filter(r=>r.status==='fulfilled').length,1);
    assert.equal((await read(db,'contribution_summaries/author')).points,10);
  });
});
test('public filtered queries lose hidden v2 evidence; author retains private review access',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),s=service(db);await seed(db);await s.creditReport({reportId:'r'});await disputed(s);
  });
  const other=env.authenticatedContext('u6').firestore(),author=env.authenticatedContext('author').firestore();
  await assertFails(getDoc(doc(other,'reports/r')));
  assert.equal((await getDoc(doc(author,'reports/r'))).data().status,'hidden');
  assert.equal((await getDocs(query(collection(other,'reports'),where('status','in',['active','resolved'])))).size,0);
  await assertFails(getDocs(collection(other,'reports')));
});
test('suspended old client sessions lose mutation permission but can read their access state',async()=>{
  await env.withSecurityRulesDisabled(async c=>{await seed(c.firestore());});
  const client=env.authenticatedContext('author').firestore();
  await setDoc(doc(client,'search_clock/author'),{serverTime:serverTimestamp()});
  await env.withSecurityRulesDisabled(async c=>{await setDoc(doc(c.firestore(),'account_access/author'),{permanent:true});});
  await assertFails(setDoc(doc(client,'search_clock/author'),{serverTime:serverTimestamp()}));
  assert.equal((await getDoc(doc(client,'account_access/author'))).data().permanent,true);
});

test('suspension reconciliation cancels the owned operation once and never touches a newer lock',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),s=service(db);await seed(db);
    const job='notification_outbox/r/events/reconcile-operation';
    await setDoc(doc(db,'account_access/author'),{manualSuspended:true});
    await setDoc(doc(db,job),{kind:'reconcile-suspended-operation',status:'pending',uid:'author',createdAt:clock});
    await setDoc(doc(db,'operation_locks/author'),{active:true,busId:'b',tripId:'run',updatedAt:clock});
    await setDoc(doc(db,'trips/run'),{busId:'b',driverId:'author',status:'in_progress'});
    await setDoc(doc(db,'service_runs/run'),{busId:'b',driverId:'author',status:'in_progress'});
    await setDoc(doc(db,'live_locations/b'),{driverId:'author',tripId:'run',isBroadcasting:true});
    await s.reconcileOperation({reportId:'r'});await s.reconcileOperation({reportId:'r'});
    assert.equal((await read(db,'trips/run')).status,'cancelled');
    assert.equal((await read(db,'operation_locks/author')).active,false);
    assert.equal((await read(db,'live_locations/b')).isBroadcasting,false);
    assert.equal((await read(db,'notification_outbox/r/events/expire-assistance')).status,'pending');
    await setDoc(doc(db,'notification_outbox/new/events/reconcile-operation'),{kind:'reconcile-suspended-operation',status:'pending',uid:'author',createdAt:clock});
    await setDoc(doc(db,'operation_locks/author'),{active:true,busId:'b',tripId:'newer',updatedAt:new Date(+clock+1000)});
    const result=await s.reconcileOperation({reportId:'new'});assert.equal(result.reviewRequired,true);
    assert.equal((await read(db,'operation_locks/author')).active,true);
  });
});


test('loop assistance targets the later visit while retaining the physical station and exact progress', async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore(),a=assistance(db);
    for(const [prefix,scope] of [['','normal'],['sample_test/shared/','sample']]) {
      await assistanceSeed(db,prefix);
      const stops=['s1','s2','s1-return','s3'],stopStationIds={s1:'s1',s2:'s2','s1-return':'s1',s3:'s3'};
      await updateDoc(doc(db,prefix+'service_runs/run1'),{stops,stopStationIds,
        initialStopTimes:{s1:{estimatedArrival:clock},s2:{estimatedArrival:new Date(+clock+600000)},'s1-return':{estimatedArrival:new Date(+clock+1200000)},s3:{estimatedArrival:new Date(+clock+1800000)}}});
      await updateDoc(doc(db,prefix+'buses/b'),{stops,stopStationIds});
      await updateDoc(doc(db,prefix+'trips/run1'),{currentStopIndex:1});
      await assert.rejects(a.submit({...helpInput,scope,requestId:'first-passed'}),{code:'assistance-unavailable'});
      const input={...helpInput,scope,requestId:'later-visit',boardingStationId:'s1-return'};
      const saved=(await a.submit(input)).request;
      assert.equal(saved.stationId,'s1');assert.equal(saved.boardingStationId,'s1-return');
      assert.equal(saved.stopIndex,2);assert.equal(saved.driverId,'u1');
      assert.equal((await a.submit(input)).request.id,'later-visit');
      await assert.rejects(a.submit({...input,requestId:'forged-station',stationId:'s2'}),{code:'invalid-request'});
      await assert.rejects(a.submit({...input,requestId:'reversed-visit',alightingStationId:'s1'}),{code:'invalid-request'});
      await updateDoc(doc(db,prefix+'trips/run1'),{currentStopIndex:3});
      assert.equal((await a.reconcile({scope,requestId:'later-visit'})).request.endReason,'stop-passed');
    }
  });
});

test('manual access is scoped, idempotent, revision checked and expires at exactly 72 hours', async () => {
  await env.withSecurityRulesDisabled(async c => {
    const db=c.firestore();
    for(const p of ['', 'sample_test/shared/']){
      await setDoc(doc(db,p+'users/admin'),{name:'Admin'});
      await setDoc(doc(db,p+'users/rider'),{name:'Rider'});
    }
    const s=createAccountPolicy({store:store(db),accountAdmin:async()=>false,now:()=>clock});
    const input={actorUid:'admin',actorAdmin:true,accountId:'rider',operationId:'manual-one',expectedRevision:0,action:'suspend',durationHours:72,reason:'Reviewed conduct issue'};
    const results=await Promise.all([s.change(input),s.change(input)]);
    assert.equal(results.filter(r=>!r.duplicate).length,1);
    assert.equal((await s.detail(input)).manualActive,true);
    assert.equal((await s.detail({...input,scope:'sample'})).manualActive,false);
    assert.equal((await service(db).accountStatus({actorUid:'rider'})).banReason,input.reason);
    const until=new Date(initial.getTime()+72*3600000);
    clock=new Date(until.getTime()-1);assert.equal((await s.detail(input)).restricted,true);
    clock=until;assert.equal((await s.detail(input)).restricted,false);
    await assert.rejects(s.change({...input,operationId:'stale'}),{code:'review-stale'});
    await s.change({...input,operationId:'restore',expectedRevision:1,action:'restore',durationHours:null});
    await s.change(input); // A late retry must never restore an old restriction.
    assert.equal((await s.detail(input)).manualActive,false);
    assert.equal((await s.detail(input)).revision,2);
    await s.change({...input,scope:'sample',operationId:'sample-only',durationHours:null});
    assert.equal((await s.detail({...input,scope:'sample'})).manualActive,true);
    assert.equal((await s.detail(input)).manualActive,false);
    assert.equal((await getDocs(collection(db,'manual_account_decisions'))).size,2);
    assert.equal((await read(db,'notification_outbox/manual-account-'+createHash('sha256').update('manual-one').digest('hex')+'/events/reconcile-operation')).uid,'rider');
  });
});

test('manual restore preserves community restrictions; scope and actor protections cannot be bypassed', async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore();await seed(db);
    await setDoc(doc(db,'users/admin'),{name:'Admin'});
    await setDoc(doc(db,'account_access/author'),{communityPermanent:true,communityPermanentReason:'Reviewed community dispute',manualSuspended:true,manualRevision:1});
    let protectedUid='protected';
    const s=createAccountPolicy({store:store(db),accountAdmin:async uid=>uid===protectedUid,now:()=>clock});
    const i={actorUid:'admin',actorAdmin:true,accountId:'author',operationId:'restore-community',expectedRevision:1,action:'restore',reason:'Restore manual restriction'};
    await s.change(i);
    const d=await s.detail(i);assert.equal(d.manualActive,false);assert.equal(d.communityRestricted,true);assert.equal(d.restricted,true);
    await assert.rejects(s.change({...i,actorAdmin:false}),{code:'admin-required'});
    await assert.rejects(s.change({...i,accountId:'admin'}),{code:'self-review-forbidden'});
    await assert.rejects(s.change({...i,accountId:'protected'}),{code:'admin-account-protected'});
    await assert.rejects(s.change({...i,reason:'Different reason'}),{code:'request-id-conflict'});
    await setDoc(doc(db,'account_access/admin'),{manualSuspended:true});
    await assert.rejects(s.detail(i),{code:'account-suspended'});
    await assert.rejects(s.change({...i,operationId:'blocked'}),{code:'account-suspended'});
  });
});

test('failed manual transaction changes neither restriction nor ledger; client decisions are denied', async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore();await setDoc(doc(db,'users/admin'),{});await setDoc(doc(db,'users/rider'),{});
    const s=createAccountPolicy({store:store(db,true),accountAdmin:async()=>false,now:()=>clock});
    await assert.rejects(s.change({actorUid:'admin',actorAdmin:true,accountId:'rider',operationId:'rollback',expectedRevision:0,action:'suspend',reason:'Reviewed incident'}));
    assert.equal(await read(db,'account_access/rider'),undefined);
    assert.equal((await getDocs(collection(db,'manual_account_decisions'))).size,0);
  });
  for(const p of ['', 'sample_test/shared/']) {
    const db=env.authenticatedContext('admin',{admin:true}).firestore();
    await assertFails(setDoc(doc(db,p+'account_access/rider'),{manualSuspended:true}));
    await assertFails(setDoc(doc(db,p+'manual_account_decisions/forged'),{action:'restore'}));
  }
});

test('Auth disabled/deleted and revoked sessions fail profile writes/reads across normal and Sample scopes',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    for(const p of ['', 'sample_test/shared/'])await setDoc(doc(c.firestore(),p+'users/session-user'),{
      uid:'session-user',name:'Original',email:'session@local.test',phone:null,role:'passenger',points:0,reportsSubmitted:0,verifiedCount:0});
    await setDoc(doc(c.firestore(),'account_access/session-user'),{sessionsValidAfterSeconds:100});
  });
  for(const p of ['', 'sample_test/shared/']){
    const old=env.authenticatedContext('session-user',{email:'session@local.test',auth_time:99}).firestore();
    const fresh=env.authenticatedContext('session-user',{email:'session@local.test',auth_time:100}).firestore();
    await assertFails(getDoc(doc(old,p+'users/session-user')));
    await assertFails(updateDoc(doc(old,p+'users/session-user'),{name:'Old session'}));
    await getDoc(doc(fresh,p+'users/session-user'));
    await updateDoc(doc(fresh,p+'users/session-user'),{name:'Fresh session'});
  }
  for(const state of [{authDisabled:true},{accountDeleted:true}]){
    await env.withSecurityRulesDisabled(c=>setDoc(doc(c.firestore(),'account_access/session-user'),state));
    for(const p of ['', 'sample_test/shared/']){
      const client=env.authenticatedContext('session-user',{email:'session@local.test',auth_time:1000}).firestore();
      await assertFails(getDoc(doc(client,p+'users/session-user')));
      await assertFails(updateDoc(doc(client,p+'users/session-user'),{name:'Forged restoration'}));
    }
  }
  const admin=env.authenticatedContext('admin',{admin:true,auth_time:1000}).firestore();
  for(const p of ['', 'sample_test/shared/'])for(const path of ['auth_operations/forged','auth_deletion_reviews/session-user','account_access/session-user']){
    await assertFails(setDoc(doc(admin,p+path),{authDisabled:false,status:'completed'}));
  }
});


test('manual appeals: suspended author can submit through trusted transactions, clients cannot read/write private queue',async()=>{
  await env.withSecurityRulesDisabled(async ctx=>{
    const db=ctx.firestore();
    for(const uid of ['admin','rider','other'])await setDoc(doc(db,'users/'+uid),{uid,role:'passenger'});
    await setDoc(doc(db,'account_access/rider'),{manualRevision:1,manualSuspended:true,manualReason:'Reviewed restriction',communityPermanent:true});
    const appeals=createManualAppeals({store:store(db),now:()=>clock});
    const input={actorUid:'rider',expectedRevision:1,reason:'Please review supporting evidence'};
    const result=await appeals.submit(input);
    assert.equal((await appeals.submit(input)).duplicate,true);
    assert.equal((await appeals.list({actorUid:'other'})).items.length,0);
    await assert.rejects(appeals.review({actorUid:'other',appealId:result.appealId,outcome:'restore',reason:'Unauthorized decision'}),{code:'admin-required'});
    await appeals.review({actorUid:'admin',actorAdmin:true,appealId:result.appealId,outcome:'restore',reason:'Review supports restoration'});
    const access=await read(db,'account_access/rider');assert.equal(access.manualSuspended,false);assert.equal(access.communityPermanent,true);
    const owner=env.authenticatedContext('rider').firestore(),admin=env.authenticatedContext('admin',{admin:true}).firestore();
    for(const client of [owner,admin]){
      await assertFails(getDoc(doc(client,'manual_account_appeals/'+result.appealId)));
      await assertFails(setDoc(doc(client,'manual_account_appeals/forged'),{accountId:'rider',status:'accepted'}));
      await assertFails(updateDoc(doc(client,'manual_account_appeals/'+result.appealId),{status:'rejected'}));
    }
  });
});
