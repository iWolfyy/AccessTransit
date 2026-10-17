import {createManualAppeals} from '../../server/moderation/manual_appeals.mjs';
// Developer-computer server for real Firebase, bound only to loopback :8788.
// No deployment, seed, reset, claim change or activation-document creation.
import {createServer} from 'node:http';
import {createRequire} from 'node:module';
import {readFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {initializeApp,deleteApp,refreshToken} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {Firestore} from '@google-cloud/firestore';
import {createModerationPolicy} from '../../server/moderation/policy.mjs';
import {createAppealPolicy} from '../../server/moderation/appeals.mjs';
import {createBanPolicy} from '../../server/moderation/bans.mjs';
import {createAccountPolicy} from '../../server/moderation/accounts.mjs';
import {createAssistancePolicy} from '../../server/moderation/assistance.mjs';
import {createOperationPolicy} from '../../server/moderation/operations.mjs';
import {adminStore} from '../../server/moderation/admin_store.mjs';
import {createModerationApi} from '../../server/moderation/api.mjs';
import {createNodeModerationHandler} from '../../server/moderation/node_handler.mjs';
import {sharedProjectId,sharedPort,validateSharedEnvironment,inspectSharedReadiness,guardedDevelopmentHandler,developmentScopes} from '../../server/moderation/development_runtime.mjs';
import {createDevelopmentWorker} from '../../server/moderation/development_worker.mjs';
import {indexCoverage} from '../../server/moderation/index_coverage.mjs';
import {createAuthLifecycle} from '../../server/moderation/auth_lifecycle.mjs';

async function main(){
validateSharedEnvironment(process.env);
const allowedScopes=developmentScopes(process.argv.slice(2));
const require=createRequire(import.meta.url),cliAuth=require('firebase-tools/lib/auth.js'),cliApi=require('firebase-tools/lib/api.js');
const account=cliAuth.getProjectDefaultAccount(fileURLToPath(new URL('../../',import.meta.url)))??cliAuth.getGlobalDefaultAccount();
if(!account?.tokens?.refresh_token)throw Error('Existing Firebase CLI sign-in is required on this computer. Never supply credentials to Flutter.');
// Refresh credentials stay in this process. No service-account key file is
// generated. Do not log this object, SDK settings or raw authentication errors.
const credentials={type:'authorized_user',client_id:cliApi.clientId(),client_secret:cliApi.clientSecret(),refresh_token:account.tokens.refresh_token};
const app=initializeApp({projectId:sharedProjectId,credential:refreshToken(credentials)},'real-firebase-localhost');
const db=new Firestore({projectId:sharedProjectId,credentials,preferRest:true});
const auth=getAuth(app),store=adminStore(db);
let authReadable=false;
try{await auth.getUserByEmail('pasindushehan0927@gmail.com');authReadable=true;}
catch(e){if(e.code==='auth/user-not-found')authReadable=true;}
async function readRules(){
  const token=await cliAuth.getAccessToken(account.tokens.refresh_token,['https://www.googleapis.com/auth/cloud-platform','https://www.googleapis.com/auth/firebase']);
  async function get(path){
    const res=await fetch(`https://firebaserules.googleapis.com/v1/${path}`,{headers:{Authorization:`Bearer ${token.access_token}`},signal:AbortSignal.timeout(10000)});
    if(!res.ok)throw Error('Deployed rules read unavailable.');return res.json();
  }
  const release=await get(`projects/${sharedProjectId}/releases/cloud.firestore`);
  if(typeof release.rulesetName!=='string'||!release.rulesetName.startsWith(`projects/${sharedProjectId}/rulesets/`))throw Error('Unexpected rules project.');
  const rules=await get(release.rulesetName);
  return rules.source?.files?.find(f=>f.name==='firestore.rules')?.content;
}
const expectedRules=await readFile(new URL('../../firestore.rules',import.meta.url),'utf8');
const expectedIndexes=JSON.parse((await readFile(new URL('../../firestore.indexes.json',import.meta.url),'utf8')).replace(/^\uFEFF/,''));
async function indexesReady(){
  const token=await cliAuth.getAccessToken(account.tokens.refresh_token,['https://www.googleapis.com/auth/cloud-platform','https://www.googleapis.com/auth/firebase']);
  const root=`https://firestore.googleapis.com/v1/projects/${sharedProjectId}/databases/(default)/collectionGroups/`;
  async function get(path){
    const r=await fetch(root+path,{headers:{Authorization:`Bearer ${token.access_token}`},signal:AbortSignal.timeout(10000)});
    if(!r.ok)throw Error('Index preflight unavailable');return r.json();
  }
  const [list,...fields]=await Promise.all([get('-/indexes'),...expectedIndexes.fieldOverrides.map(f=>get(`${encodeURIComponent(f.collectionGroup)}/fields/${encodeURIComponent(f.fieldPath)}`))]);
  return indexCoverage(expectedIndexes,list.indexes??[],fields).ready;
}
let state,checkedAt=0,inFlight;
let initialEffectiveAt;
async function readiness(){
  if(state&&Date.now()-checkedAt<5000)return state;
  if(inFlight)return inFlight;
  inFlight=(async()=>{
    try{
      const result=await inspectSharedReadiness({db,readRules,expectedRules,indexesReady});
      if(!authReadable){result.ready=false;result.reasons.push('auth-admin-read-unavailable');}
      if(initialEffectiveAt!==undefined&&result.effectiveAt!==initialEffectiveAt){
        result.ready=false;result.reasons.push('policy-changed-restart-required');
      }
      state=result;
    }catch{state={projectId:sharedProjectId,ready:false,reasons:['preflight-unavailable']};}
    checkedAt=Date.now();return state;
  })();
  try{return await inFlight;}finally{inFlight=null;}
}
const initial=await readiness();initialEffectiveAt=initial.effectiveAt??null;
const policy=createModerationPolicy({store,effectiveAt:new Date(initialEffectiveAt??Date.now())});
const assistance=createAssistancePolicy({store});
const operations=createOperationPolicy({store,assistance});
const accountAdmin=async uid=>(await auth.getUser(uid)).customClaims?.admin===true;
const lifecycle=createAuthLifecycle({store,auth});
const api=createModerationApi({auth,policy,assistance,appeals:createAppealPolicy({store}),
  accounts:createAccountPolicy({store,accountAdmin}),bans:createBanPolicy({store,accountAdmin}),
  operations,lifecycle,manualAppeals:createManualAppeals({store}),allowedScopes});
const handler=guardedDevelopmentHandler({readiness,handler:createNodeModerationHandler({api,publicOrigin:'https://real-firebase-localhost.invalid'})});
const server=createServer(handler);server.requestTimeout=15000;server.headersTimeout=10000;
await new Promise((resolve,reject)=>{server.once('error',reject);server.listen(sharedPort,'127.0.0.1',resolve);});
console.log(JSON.stringify({mode:'real-firebase-localhost',projectId:sharedProjectId,listen:`127.0.0.1:${sharedPort}`,ready:initial.ready,reasons:initial.reasons,allowedScopes}));
const sweep=createDevelopmentWorker({db,policy,assistance,operations,lifecycle,ready:async()=>(await readiness()).ready,log:code=>console.error(code)});
const timer=setInterval(()=>{void sweep();},5000);
let stopping=false;
async function stop(){
  if(stopping)return;stopping=true;clearInterval(timer);server.closeAllConnections();
  await new Promise(resolve=>server.close(resolve));await db.terminate();await deleteApp(app);
}
process.once('SIGINT',()=>void stop());process.once('SIGTERM',()=>void stop());
}
main().catch(()=>{console.error('Shared localhost startup unavailable. Check CLI sign-in, project/host environment and port 8788. No credentials logged.');process.exit(1);});
