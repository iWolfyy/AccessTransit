// Explicit legacy SAMPLE fixture baselines only. Never migrates real accounts.
import {createRequire} from 'node:module';
import {mkdir,writeFile} from 'node:fs/promises';
const require=createRequire(import.meta.url),{Firestore}=require('@google-cloud/firestore');
const auth=require('firebase-tools/lib/auth.js'),api=require('firebase-tools/lib/api.js');
if(process.argv.slice(2).some(a=>a!=='--apply'))throw Error('Unknown mode');
const apply=process.argv.includes('--apply'),prefix='sample_test/shared/';
const account=auth.getProjectDefaultAccount(process.cwd())??auth.getGlobalDefaultAccount();
if(!account?.tokens?.refresh_token)throw Error('Existing CLI sign-in required');
const db=new Firestore({projectId:'accesstransit-b615b',preferRest:true,credentials:{type:'authorized_user',client_id:api.clientId(),client_secret:api.clientSecret(),refresh_token:account.tokens.refresh_token}});
try {
 const users=(await db.collection(prefix+'users').get()).docs;
 const pending=[];
 for(const user of users){
  const data=user.data(),ref=db.doc(prefix+'contribution_summaries/'+user.id),old=await ref.get();
  if(old.exists)continue;
  if(data.sampleScenario!==true||!Number.isSafeInteger(data.points??0))throw Error('Unexpected sample baseline');
  pending.push({uid:user.id,points:data.points??0});
 }
 console.log(JSON.stringify({namespace:prefix,apply,pending:pending.length,normalWrites:0}));
 if(apply){
  await mkdir('.private/realistic-sample',{recursive:true});
  await writeFile('.private/realistic-sample/sample-baseline-plan.json',JSON.stringify(pending,null,2));
  let created=0;
  for(const row of pending)await db.runTransaction(async tx=>{
   const summary=db.doc(prefix+'contribution_summaries/'+row.uid),profile=db.doc(prefix+'users/'+row.uid);
   const [current,u]=await Promise.all([tx.get(summary),tx.get(profile)]);
   if(current.exists)return;
   if(u.data()?.sampleScenario!==true||u.data().points!==row.points)throw Error('Sample baseline changed concurrently');
   const now=new Date();
   tx.create(summary,{policyVersion:2,points:row.points,falseReportStrikes:0,updatedAt:now,sampleScenario:true,baselineType:'preserved_sample_fixture'});
   tx.create(db.doc(prefix+'reward_events/sample_baseline_'+row.uid+'/entries/baseline'),{policyVersion:2,uid:row.uid,amount:row.points,kind:'baseline',createdAt:now,sampleScenario:true,reason:'Preserve historical fictional sample points; no retroactive strikes'});
   created++;
  });
  console.log(JSON.stringify({sampleBaselinesCreated:created,existingSummariesPreserved:true,normalWrites:0}));
 }
}finally{await db.terminate();}
