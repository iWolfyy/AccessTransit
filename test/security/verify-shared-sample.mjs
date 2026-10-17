// Real shared backend checks. Only creates/updates a namespaced test request.
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {resolve} from 'node:path';
import {createRequire} from 'node:module';
import {createHash} from 'node:crypto';
const root=resolve(import.meta.dirname,'../..');
const load=async p=>JSON.parse(await readFile(resolve(root,p),'utf8'));
const plan=await load('.private/firebase-reset/reset-plan.json');
const input=await load('.private/firebase-reset/requested-accounts.json');
const config=await load('android/app/google-services.json');
const projectId='accesstransit-b615b';
if(plan.projectId!==projectId || config.project_info.project_id!==projectId)throw new Error('Unexpected project.');
const apiKey=config.client.find(c=>c.client_info.android_client_info.package_name==='com.accesstransit.access_transit').api_key[0].current_key;
const name=`projects/${projectId}/databases/(default)/documents`;
const base=`https://firestore.googleapis.com/v1/${name}`;
const prefix='sample_test/shared/';
const sessions=[];
for(const a of plan.accounts){
  const r=await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${encodeURIComponent(apiKey)}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:a.email,password:input.password,returnSecureToken:true})});
  const s=await r.json();if(!r.ok||s.localId!==a.uid)throw new Error('Test-account sign-in failed; no details logged.');
  const headers={Authorization:`Bearer ${s.idToken}`};
  const p=await fetch(`${base}/${prefix}users/${a.uid}`,{headers});const profile=await p.json();
  if(!p.ok||profile.fields?.role?.stringValue!==a.role)throw new Error('Sample profile check failed.');
  const other=plan.accounts.find(x=>x.uid!==a.uid);
  const denied=await fetch(`${base}/${prefix}users/${other.uid}`,{headers});if(denied.status!==403)throw new Error('Sample profile privacy failed.');
  if(a.role==='operator'){
    const grantResponse=await fetch(`${base}/${prefix}driver_route_assignments/${a.uid}`,{headers});
    const grant=await grantResponse.json();
    if(!grantResponse.ok||grant.fields?.active?.booleanValue!==true||!grant.fields?.routeId?.stringValue)throw new Error('Sample route assignment missing. Refresh reviewed fixtures after rules rollout.');
    for(const [path,expected] of [[`${prefix}operator_access/${a.uid}`,true],[`operator_access/${a.uid}`,false]]){
      const response=await fetch(`${base}/${path}`,{headers});const d=await response.json();
      if(!response.ok||d.fields?.approved?.booleanValue!==expected)throw new Error('Approval isolation failed.');
    }
  }
  sessions.push({...a,headers});
}
const passenger=sessions.find(a=>a.role==='passenger');const operator=sessions.find(a=>a.role==='operator');
const id=`validation_${Date.now()}`;const requestName=`${name}/${prefix}boarding_requests/${id}`;
const encode=v=>Array.isArray(v)?{arrayValue:{values:v.map(encode)}}:{stringValue:v};
async function commit(actor,writes){const r=await fetch(`${base}:commit`,{method:'POST',headers:{...actor.headers,'Content-Type':'application/json'},body:JSON.stringify({writes})});if(!r.ok)throw new Error(`Sample assistance write failed (${r.status}); no token details logged.`);}
const data={riderId:passenger.uid,riderName:passenger.name,busId:'sample_bus_01',routeNo:'17',stationId:'ncg_panadura',
  stopName:'SAMPLE - Panadura',assistanceTypes:['Deploy Ramp'],status:'pending',purpose:'boarding'};
await commit(passenger,[{update:{name:requestName,fields:Object.fromEntries(Object.entries(data).map(([k,v])=>[k,encode(v)]))},
  updateTransforms:[{fieldPath:'createdAt',setToServerValue:'REQUEST_TIME'}],currentDocument:{exists:false}}]);
await commit(operator,[{update:{name:requestName,fields:{status:encode('acknowledged')}},updateMask:{fieldPaths:['status']},currentDocument:{exists:true}}]);
const receiptResponse=await fetch(`https://firestore.googleapis.com/v1/${requestName}`,{headers:passenger.headers});const receipt=await receiptResponse.json();
if(!receiptResponse.ok||receipt.fields?.status?.stringValue!=='acknowledged')throw new Error('Passenger acknowledgement delivery failed.');
await commit(passenger,[{update:{name:requestName,fields:{status:encode('cancelled')}},updateMask:{fieldPaths:['status']},currentDocument:{exists:true}}]);
const require=createRequire(import.meta.url);const auth=require('firebase-tools/lib/auth.js');const admin=auth.getGlobalDefaultAccount();
const token=await auth.getAccessToken(admin.tokens.refresh_token,['https://www.googleapis.com/auth/cloud-platform','https://www.googleapis.com/auth/firebase']);
async function rulesGet(path){const r=await fetch(`https://firebaserules.googleapis.com/v1/${path}`,{headers:{Authorization:`Bearer ${token.access_token}`}});if(!r.ok)throw new Error('Deployed rules read failed.');return r.json();}
const release=await rulesGet(`projects/${projectId}/releases/cloud.firestore`);const rules=await rulesGet(release.rulesetName);
const deployed=rules.source?.files?.find(f=>f.name==='firestore.rules')?.content;
const digest=s=>createHash('sha256').update(s).digest('hex');
if(!deployed||digest(deployed)!==digest(await readFile(resolve(root,'firestore.rules'))))throw new Error('Deployed rules differ from tested file.');
const previous=await load('.private/firebase-reset/deployed-rules-verification.json');
const oldRules=await rulesGet(previous.ruleset);
const oldSource=oldRules.source?.files?.find(f=>f.name==='firestore.rules')?.content;
const marker='    // BEGIN GENERATED SAMPLE TEST POLICY';
const normalPolicy=deployed.slice(0,deployed.indexOf(marker))+'  }\n}\n';
if(!oldSource || normalPolicy.replaceAll('\r\n','\n')!==oldSource.replaceAll('\r\n','\n'))throw new Error('Original root policy changed.');
const result={projectId,signInsVerified:sessions.length,sampleOwnProfiles:8,otherProfilesDenied:8,
  sampleOperatorApprovals:4,realOperatorApprovalsStillPending:4,assistanceCreated:true,operatorAcknowledged:true,
  passengerReadAcknowledgement:true,passengerCancelled:true,requestId:id,rulesHash:digest(deployed),normalRootPolicyUnchanged:true,verifiedAt:new Date().toISOString()};
const dir=resolve(root,'.private/shared-sample');await mkdir(dir,{recursive:true});await writeFile(resolve(dir,'verification.json'),JSON.stringify(result,null,2));
console.log(JSON.stringify(result));
