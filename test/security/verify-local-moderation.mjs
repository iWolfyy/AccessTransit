import assert from 'node:assert/strict';
import {initializeApp,deleteApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore,Timestamp} from 'firebase-admin/firestore';
if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8087'||process.env.FIREBASE_AUTH_EMULATOR_HOST!=='127.0.0.1:9099') throw Error('Local emulators required');
const app=initializeApp({projectId:'demo-accesstransit'},'verify-local-v2'),auth=getAuth(app),db=getFirestore(app);
const prefix='local-v2-'+Date.now(),password='LocalTest-Only25!',tokens=[],uids=[];
try{
  for(let i=0;i<6;i++){
    const uid=prefix+'-'+i,email=uid+'@local.test';uids.push(uid);
    await auth.createUser({uid,email,password});
    await db.doc('users/'+uid).set({uid,email,name:'LOCAL V2 synthetic user',role:'passenger',points:0,reportsSubmitted:0,verifiedCount:0,createdAt:Timestamp.now()});
    const response=await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=local-validation-key',{
      method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({email,password,returnSecureToken:true})});
    const identity=await response.json();assert.equal(response.status,200);assert.ok(identity.idToken);tokens.push(identity.idToken);
  }
  async function call(token,path,body){return fetch('http://127.0.0.1:8787'+path,{method:'POST',headers:{authorization:'Bearer '+token,'content-type':'application/json'},body:JSON.stringify(body)});}
  const reportId=prefix,report={targetType:'bus',targetId:'local_test_bus',targetName:'LOCAL TEST BUS',problemType:'Ramp broken',
    severity:'major',category:'rampAccess',subCategory:'Ramp broken',condition:'barrier',crowdingLevel:'',description:'LOCAL synthetic observation',photoUrl:'',observedAt:new Date(Date.now()-1000).toISOString()};
  assert.equal((await call(tokens[0],'/v2/reports/publish',{reportId,report})).status,200);
  const duplicate=await call(tokens[0],'/v2/reports/publish',{reportId,report});assert.equal((await duplicate.json()).duplicate,true);
  assert.equal((await call(tokens[0],'/v2/reports/publish',{reportId:reportId+'-retry',report})).status,429);
  assert.equal((await call(tokens[0],'/v2/reports/vote',{reportId,value:'true'})).status,403);
  // Exercise the actual local reconciliation worker on the fifth counted strike.
  await db.doc('contribution_summaries/'+uids[0]).update({falseReportStrikes:4});
  const runId=prefix+'-operation';
  await db.doc('operation_locks/'+uids[0]).set({active:true,busId:'local_test_bus',tripId:runId,updatedAt:new Date(Date.now()-1000)});
  await db.doc('trips/'+runId).set({busId:'local_test_bus',driverId:uids[0],status:'in_progress'});
  await db.doc('service_runs/'+runId).set({busId:'local_test_bus',driverId:uids[0],status:'in_progress'});
  await db.doc('live_locations/local_test_bus').set({busId:'local_test_bus',driverId:uids[0],tripId:runId,isBroadcasting:true,status:'active'});
  await db.doc('boarding_requests/'+prefix).set({busId:'local_test_bus',serviceRunId:runId,status:'pending',createdAt:new Date(Date.now()-1000)});
  for(let i=1;i<=5;i++){
    const response=await call(tokens[i],'/v2/reports/vote',{reportId,value:'false',reason:'LOCAL test equipment works'});
    assert.equal(response.status,200);assert.equal((await response.json()).hidden,i===5);
  }
  const status=await call(tokens[0],'/v2/account/status',{});const access=await status.json();assert.equal(access.points,-10);assert.equal(access.state,'temporary');
  assert.equal((await db.doc('reports/'+reportId).get()).data().status,'hidden');
  assert.equal((await db.doc('contribution_summaries/'+uids[0]).get()).data().falseReportStrikes,5);
  const deadline=Date.now()+15000;
  while(Date.now()<deadline){
    if((await db.doc('boarding_requests/'+prefix).get()).data().status==='cancelled')break;
    await new Promise(resolve=>setTimeout(resolve,500));
  }
  assert.equal((await db.doc('trips/'+runId).get()).data().status,'cancelled');
  assert.equal((await db.doc('live_locations/local_test_bus').get()).data().isBroadcasting,false);
  assert.equal((await db.doc('boarding_requests/'+prefix).get()).data().status,'cancelled');
  // Restricted author can appeal; only a verified admin claim can review.
  assert.equal((await call(tokens[0],'/v2/reviews/appeal',{reportId,reason:'Please review the photograph'})).status,200);
  assert.equal((await call(tokens[1],'/v2/reviews/detail',{reportId})).status,404);
  assert.equal((await call(tokens[1],'/v2/reviews/decide',{reportId,outcome:'overturn',reason:'Reviewed the photograph'})).status,403);
  await auth.setCustomUserClaims(uids[4],{admin:true});
  const signed=await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=local-validation-key',{
    method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({email:uids[4]+'@local.test',password,returnSecureToken:true})});
  const adminToken=(await signed.json()).idToken;
  const queue=await call(adminToken,'/v2/reviews/list',{queue:true});assert.equal(queue.status,200);assert.ok(Array.isArray((await queue.json()).items));
  const evidence=await call(adminToken,'/v2/reviews/evidence',{reportId});assert.equal(evidence.status,200);assert.equal((await evidence.json()).items.length,5);
  const decision={reportId,outcome:'overturn',reason:'Reviewed the photograph'};
  assert.equal((await call(adminToken,'/v2/reviews/decide',decision)).status,200);
  assert.equal((await (await call(adminToken,'/v2/reviews/decide',decision)).json()).duplicate,true);
  const restored=await (await call(tokens[0],'/v2/account/status',{})).json();assert.equal(restored.points,10);assert.equal(restored.state,'active');
  assert.equal((await db.doc('contribution_summaries/'+uids[0]).get()).data().falseReportStrikes,4);
  assert.equal((await db.doc('report_appeals/'+reportId).get()).data().status,'accepted');
  assert.equal((await db.doc('trips/'+runId).get()).data().status,'cancelled'); // review never restarts an ended trip
  // Synthetic reviewed baseline at nine exercises the tenth-strike review boundary.
  await db.doc('contribution_summaries/'+uids[0]).update({falseReportStrikes:9});
  const banReport=prefix+'-ban',nextReport={...report,category:'cleanliness',problemType:'Dirty floor'};
  assert.equal((await call(tokens[0],'/v2/reports/publish',{reportId:banReport,report:nextReport})).status,200);
  for(let i=1;i<=5;i++)assert.equal((await call(tokens[i],'/v2/reports/vote',{reportId:banReport,value:'false',reason:'LOCAL condition contradicts report'})).status,200);
  assert.equal((await (await call(tokens[0],'/v2/account/status',{})).json()).state,'active');
  assert.equal((await call(tokens[1],'/v2/bans/list',{})).status,403);
  assert.equal((await call(adminToken,'/v2/bans/list',{})).status,200);
  const caseData=await (await call(adminToken,'/v2/bans/detail',{accountId:uids[0]})).json();
  const banInput={accountId:uids[0],outcome:'approve',reason:'Reviewed every report and appeal',expectedRevision:caseData.revision};
  assert.equal((await call(tokens[0],'/v2/reviews/appeal',{reportId:banReport,reason:'Please review this report'})).status,200);
  assert.equal((await call(adminToken,'/v2/bans/decide',banInput)).status,409);
  const pending=await (await call(adminToken,'/v2/bans/detail',{accountId:uids[0]})).json();assert.equal(pending.pendingAppeals,true);
  assert.equal((await call(adminToken,'/v2/bans/decide',{...banInput,expectedRevision:pending.revision})).status,409);
  assert.equal((await call(adminToken,'/v2/reviews/decide',{reportId:banReport,outcome:'uphold',reason:'Reviewed the contradictory evidence'})).status,200);
  const ready=await (await call(adminToken,'/v2/bans/detail',{accountId:uids[0]})).json();assert.equal(ready.pendingAppeals,false);
  const finalBan={...banInput,expectedRevision:ready.revision};
  assert.equal((await call(adminToken,'/v2/bans/decide',finalBan)).status,200);
  assert.equal((await (await call(adminToken,'/v2/bans/decide',finalBan)).json()).duplicate,true);
  const banned=await (await call(tokens[0],'/v2/account/status',{})).json();assert.equal(banned.state,'permanent');assert.equal(banned.banReason,banInput.reason);
  assert.equal((await call(tokens[0],'/v2/reports/publish',{reportId:banReport+'-blocked',report:{...report,category:'safetyHazard'}})).status,403);
  await auth.revokeRefreshTokens(uids[5]);
  // Emulator timestamps are second-granular; test the disabled-user rejection as well.
  await auth.updateUser(uids[5],{disabled:true});
  assert.equal((await call(tokens[5],'/v2/account/status',{})).status,401);
  console.log('PASS: local Auth/Admin publication/votes/temporary restriction/worker/appeal/overturn -> tenth strike pending review without auto-ban -> stale/pending appeal denial -> explicit idempotent admin permanent ban -> old-token publication denied; disabled session rejected.');
  console.log('Synthetic data retained in demo-accesstransit only; no production reads/writes.');
}finally{await deleteApp(app);}
