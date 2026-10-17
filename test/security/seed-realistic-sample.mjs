// No normal-scope writes, Auth mutations, deletions or automatic refresh/reset.
// Default: dry run. --apply --batch=walkthrough_<UTC digits> commits this exact batch once.
import {createRequire} from 'node:module';
import {mkdir,writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {createHash} from 'node:crypto';
import {realisticFixtures,samplePrefix,fixtureNotice} from './realistic-sample-fixtures.mjs';
const require=createRequire(import.meta.url);
const {Firestore}=require('@google-cloud/firestore');
const auth=require('firebase-tools/lib/auth.js'),api=require('firebase-tools/lib/api.js');
const args=process.argv.slice(2);
if(args.some(a=>a!=='--apply'&&!/^--batch=walkthrough_[0-9T]+$/.test(a)))throw Error('Unknown argument');
const apply=args.includes('--apply'),batchId=args.find(a=>a.startsWith('--batch='))?.slice(8)??`walkthrough_${new Date().toISOString().replace(/[^0-9T]/g,'')}`;
const account=auth.getProjectDefaultAccount(process.cwd())??auth.getGlobalDefaultAccount();
if(!account?.tokens?.refresh_token)throw Error('Existing Firebase CLI sign-in required');
const db=new Firestore({projectId:'accesstransit-b615b',preferRest:true,credentials:{type:'authorized_user',client_id:api.clientId(),client_secret:api.clientSecret(),refresh_token:account.tokens.refresh_token}});
const digest=value=>createHash('sha256').update(JSON.stringify(value)).digest('hex');
async function collection(path){return Object.fromEntries((await db.collection(path).get()).docs.map(d=>[d.id,d.data()]));}
try {
  const normalNames=['routes','stations','buses','users','service_runs','operator_access','driver_route_assignments','moderation_config','assistance_config'];
  const normal=Object.fromEntries(await Promise.all(normalNames.map(async c=>[c,await collection(c)])));
  const sampleUsers=await collection(samplePrefix+'users'),existingGrants=await collection(samplePrefix+'driver_route_assignments');
  const users={...normal.users,...sampleUsers};
  const grants={...existingGrants};
  const drivers=Object.entries(users).filter(([,u])=>u.role==='operator');
  const routeIds=Object.keys(normal.routes);
  for(const [i,[uid]]of drivers.entries())if(!grants[uid])grants[uid]={driverId:uid,routeId:routeIds[i%routeIds.length],active:true,claimRevision:0};
  const locks=await collection(samplePrefix+'operation_locks');
  const previewDrivers=drivers.filter(([uid])=>!locks[uid]).map(([uid])=>uid);
  const fixture=realisticFixtures({now:new Date(),batchId,routes:normal.routes,stations:normal.stations,users,grants,previewDrivers});
  const records=fixture.records;
  const add=(path,data)=>records.push({path:samplePrefix+path,data:{...data,sampleScenario:true,fixtureBatch:batchId,scenarioNotice:fixtureNotice}});
  for(const [uid,u] of Object.entries(users))if(!sampleUsers[uid])add(`users/${uid}`,{...u,points:0,reportsSubmitted:0,verifiedCount:0});
  const approvals=await collection(samplePrefix+'operator_access');
  for(const [uid]of drivers){
    if(!existingGrants[uid])add(`driver_route_assignments/${uid}`,grants[uid]);
    if(!approvals[uid])add(`operator_access/${uid}`,{approved:true,approvalPurpose:'sample_namespace_only'});
  }
  for(const c of ['moderation_config','assistance_config']) {
    const current=await db.doc(samplePrefix+c+'/active').get();
    if(!current.exists)add(c+'/active',{enabled:true,policyVersion:2,effectiveAt:normal.moderation_config.active.effectiveAt,localOnly:false});
  }
  const manifest=db.doc(samplePrefix+'fixture_batches/'+batchId);
  if((await manifest.get()).exists)throw Error('Batch already exists; refusing to reset walkthrough activity');
  const snapshots=await db.getAll(...records.map(r=>db.doc(r.path)));
  for(let i=0;i<records.length;i++) {
    if(!records[i].path.startsWith(samplePrefix))throw Error('Write escaped sample namespace');
    // Shared sample catalogue fields may be refreshed; account activity is never overwritten.
    if(snapshots[i].exists && (!['routes','stations','route_geometries'].includes(records[i].path.split('/')[2]) || snapshots[i].data().sampleScenario!==true))throw Error('Refusing to overwrite non-fixture sample activity: '+records[i].path);
  }
  const counts=Object.fromEntries([...new Set(records.map(r=>r.path.split('/')[2]))].map(c=>[c,records.filter(r=>r.path.split('/')[2]===c).length]));
  console.log(JSON.stringify({projectId:db.projectId,namespace:samplePrefix,batchId,apply,counts,normalWrites:0}));
  const directory=resolve('.private','realistic-sample',batchId);await mkdir(directory,{recursive:true});
  await writeFile(resolve(directory,'plan.json'),JSON.stringify(records,null,2));
  if(apply){
    await writeFile(resolve(directory,'before.json'),JSON.stringify(snapshots.map((s,i)=>({path:records[i].path,exists:s.exists,data:s.data()??null})),null,2));
    await writeFile(resolve(directory,'fixtures.json'),JSON.stringify(records,null,2));
    // Summary credit and every fixture write commit atomically, preserving prior sample totals.
    if(records.length+2>500)throw Error('Fixture batch exceeds atomic write limit');
    const summaryRef=db.doc(samplePrefix+'contribution_summaries/'+fixture.author);
    const credits=records.filter(r=>r.path.includes('/reward_events/')).length;
    await db.runTransaction(async tx=>{
      const [marker,summary]=await Promise.all([tx.get(manifest),tx.get(summaryRef)]);
      if(marker.exists)throw Error('Batch already applied');
      const prior=summary.data()??{policyVersion:2,points:0,falseReportStrikes:0,reportsSubmitted:0};
      if(prior.policyVersion!==2||!Number.isSafeInteger(prior.points)||!Number.isSafeInteger(prior.falseReportStrikes))throw Error('Sample ledger requires review; not resetting balances');
      for(let i=0;i<records.length;i++) {
        const {path,data}=records[i],old=snapshots[i];
        if(old.exists)tx.update(db.doc(path),data,{lastUpdateTime:old.updateTime});
        else tx.create(db.doc(path),data);
      }
      tx.set(summaryRef,{...prior,points:(prior.points??0)+credits*10,reportsSubmitted:(prior.reportsSubmitted??0)+credits,updatedAt:new Date()});
      tx.create(manifest,{batchId,counts,createdAt:new Date(),sampleScenario:true,scenarioNotice:fixtureNotice});
    });
    const after=Object.fromEntries(await Promise.all(normalNames.map(async c=>[c,await collection(c)])));
    if(digest(normal)!==digest(after))throw Error('Normal data changed concurrently; inspect without resetting');
    const readback=await db.getAll(...records.map(r=>db.doc(r.path)));
    if(readback.some(s=>!s.exists||s.data().fixtureBatch!==batchId))throw Error('Fixture readback failed');
    const receipt={batchId,counts,verified:readback.length,normalDataUnchanged:true,createdAt:new Date().toISOString()};
    await writeFile(resolve(directory,'receipt.json'),JSON.stringify(receipt,null,2));console.log(JSON.stringify(receipt));
  }
} finally {await db.terminate();}
