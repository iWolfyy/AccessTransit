// Narrow, reviewed zero-baseline activation. No account/catalogue/reset writes.
// Default prepares a private plan. --apply rechecks rules/indexes and every
// current profile in the transaction, preserving all UIDs and prior totals.
import {createRequire} from 'node:module';
import {readFile,mkdir,writeFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {resolve} from 'node:path';
import {createHash,randomUUID} from 'node:crypto';
import {Firestore,FieldValue} from '@google-cloud/firestore';
import {sharedProjectId,validateSharedEnvironment} from '../../server/moderation/development_runtime.mjs';
import {indexCoverage} from '../../server/moderation/index_coverage.mjs';
import {verifyZeroBaselines,alreadyActivated} from '../../server/moderation/development_activation.mjs';

let stage='environment';
async function main(){
  validateSharedEnvironment(process.env);
  if(process.argv.slice(2).some(a=>a!=='--apply')||process.argv.length>3)throw Error('Use no arguments or --apply.');
  const apply=process.argv.includes('--apply'),require=createRequire(import.meta.url),cli=require('firebase-tools/lib/auth.js'),api=require('firebase-tools/lib/api.js');
  const root=fileURLToPath(new URL('../../',import.meta.url)),account=cli.getProjectDefaultAccount(root)??cli.getGlobalDefaultAccount();
  if(!account?.tokens?.refresh_token)throw Error('CLI sign-in required');
  const token=await cli.getAccessToken(account.tokens.refresh_token,['https://www.googleapis.com/auth/cloud-platform','https://www.googleapis.com/auth/firebase']);
  async function get(url){
    const r=await fetch(url,{headers:{Authorization:`Bearer ${token.access_token}`},signal:AbortSignal.timeout(15000)});
    if(!r.ok)throw Error('Activation preflight read failed');return r.json();
  }
  stage='rules-read';
  const rulesRoot='https://firebaserules.googleapis.com/v1/';
  const release=await get(rulesRoot+`projects/${sharedProjectId}/releases/cloud.firestore`);
  if(!release.rulesetName?.startsWith(`projects/${sharedProjectId}/rulesets/`))throw Error('Unexpected rules project');
  const rules=await get(rulesRoot+release.rulesetName),source=rules.source?.files?.find(f=>f.name==='firestore.rules')?.content;
  const hash=s=>createHash('sha256').update(s.replaceAll('\r\n','\n').trim()).digest('hex');
  const expected=await readFile(resolve(root,'firestore.rules'),'utf8');
  if(typeof source!=='string'||hash(source)!==hash(expected))throw Error('Deployed rules review required');
  const spec=JSON.parse((await readFile(resolve(root,'firestore.indexes.json'),'utf8')).replace(/^\uFEFF/,''));
  stage='index-readiness';
  const indexRoot=`https://firestore.googleapis.com/v1/projects/${sharedProjectId}/databases/(default)/collectionGroups/`;
  const [indexes,...fields]=await Promise.all([get(indexRoot+'-/indexes'),...spec.fieldOverrides.map(f=>get(indexRoot+`${encodeURIComponent(f.collectionGroup)}/fields/${encodeURIComponent(f.fieldPath)}`))]);
  const coverage=indexCoverage(spec,indexes.indexes??[],fields);
  if(!coverage.ready)throw Object.assign(Error('Required indexes are not READY'),{missingIndexes:coverage.missingIndexes.length,missingFields:coverage.missingFields.length});
  const db=new Firestore({projectId:sharedProjectId,preferRest:true,credentials:{type:'authorized_user',
    client_id:api.clientId(),client_secret:api.clientSecret(),refresh_token:account.tokens.refresh_token}});
  try{
    stage='baseline-read';
    const query=db.collection('users').select('points','reportsSubmitted','verifiedCount').limit(101);
    const mRef=db.doc('moderation_config/active'),aRef=db.doc('assistance_config/active');
    const [profiles,mBefore,aBefore]=await Promise.all([query.get(),mRef.get(),aRef.get()]);
    const plan={projectId:sharedProjectId,preparedAt:new Date().toISOString(),apply,profileCount:profiles.size,
      rulesHash:hash(source),beforeModeration:mBefore.data()??null,beforeAssistance:aBefore.data()??null,
      policyVersion:2,backendMode:'localhost',operationId:randomUUID()};
    const directory=resolve(root,'.private/shared-v2-activation');await mkdir(directory,{recursive:true});
    await writeFile(resolve(directory,plan.operationId+'-plan.json'),JSON.stringify(plan,null,2));
    async function zeroBaseline(tx,rows){
      await verifyZeroBaselines(rows.docs.map(d=>({uid:d.id,...d.data()})),async uid=>(await tx.get(db.doc('contribution_summaries/'+uid))).exists);
    }
    if(!apply){
      await db.runTransaction(async tx=>{const rows=await tx.get(query);await zeroBaseline(tx,rows);});
      console.log(JSON.stringify({projectId:sharedProjectId,readOnly:true,profileCount:profiles.size,zeroBaselineVerified:true,privatePlan:plan.operationId}));return;
    }
    const result=await db.runTransaction(async tx=>{
      const [m,a,rows]=await Promise.all([tx.get(mRef),tx.get(aRef),tx.get(query)]);
      if(alreadyActivated(m.data(),a.data(),hash(source)))return {duplicate:true};
      await zeroBaseline(tx,rows);
      const at=FieldValue.serverTimestamp();
      tx.set(mRef,{...m.data(),enabled:true,policyVersion:2,effectiveAt:at,localOnly:false,developmentOnly:true,backendMode:'localhost',reviewedRulesHash:hash(source),activationId:plan.operationId});
      tx.set(aRef,{...a.data(),enabled:true,policyVersion:2,localOnly:false,developmentOnly:true,backendMode:'localhost',activationId:plan.operationId,updatedAt:at});
      tx.create(db.doc('backend_activations/'+plan.operationId),{...plan,beforeModeration:m.data()??null,beforeAssistance:a.data()??null,profileCount:rows.size,createdAt:at,zeroBaselineVerified:true});
      tx.create(db.doc('admin_audit/'+plan.operationId),{actorId:account.user.email,action:'activate_localhost_v2',createdAt:at,
        targets:['moderation_config/active','assistance_config/active'],rulesHash:hash(source),reason:'Reviewed real-project rules/indexes; existing profiles have zero legacy totals; no retroactive strikes or balance reset.'});
      return {duplicate:false};
    });
    const current=await mRef.get();
    const receipt={projectId:sharedProjectId,applied:true,duplicate:result.duplicate,activationId:current.get('activationId'),effectiveAt:current.get('effectiveAt').toDate().toISOString(),backendMode:'localhost'};
    await writeFile(resolve(directory,plan.operationId+'-receipt.json'),JSON.stringify(receipt,null,2));console.log(JSON.stringify(receipt));
  }finally{await db.terminate();}
}
main().catch(e=>{console.error(JSON.stringify({error:'shared-development-activation-unconfirmed',stage,missingIndexes:e.missingIndexes,missingFields:e.missingFields}));process.exitCode=1;});
