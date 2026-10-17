// Read-only rollout preflight. Never applies rules, indexes, migration or claims.
import {createRequire} from 'node:module';
import {readFile,mkdir,writeFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {resolve} from 'node:path';
import {createHash} from 'node:crypto';
import {sharedProjectId,validateSharedEnvironment} from '../../server/moderation/development_runtime.mjs';

let stage='environment';
async function main(){
  validateSharedEnvironment(process.env);
  const require=createRequire(import.meta.url),auth=require('firebase-tools/lib/auth.js');
  const root=fileURLToPath(new URL('../../',import.meta.url));
  const account=auth.getProjectDefaultAccount(root)??auth.getGlobalDefaultAccount();
  if(!account)throw Error('CLI sign-in required');
  const token=await auth.getAccessToken(account.tokens.refresh_token,['https://www.googleapis.com/auth/cloud-platform','https://www.googleapis.com/auth/firebase']);
  async function read(url,body,optional=false){
    const res=await fetch(url,{method:body?'POST':'GET',headers:{Authorization:`Bearer ${token.access_token}`,'content-type':'application/json'},
      ...(body?{body:JSON.stringify(body)}:{}),signal:AbortSignal.timeout(15000)});
    if(optional&&res.status===404)return null;
    if(!res.ok){
      const error=await res.json();
      throw Object.assign(Error('Read-only preflight unavailable'),{status:res.status,detail:error.error?.message?.slice(0,240),endpoint:new URL(url).pathname});
    }return res.json();
  }
  const documents=`https://firestore.googleapis.com/v1/projects/${sharedProjectId}/databases/(default)/documents`;
  const rulesRoot='https://firebaserules.googleapis.com/v1/';
  stage='rules-read';
  const release=await read(rulesRoot+`projects/${sharedProjectId}/releases/cloud.firestore`);
  if(!release.rulesetName?.startsWith(`projects/${sharedProjectId}/rulesets/`))throw Error('Rules project mismatch');
  const ruleset=await read(rulesRoot+release.rulesetName),source=ruleset.source?.files?.find(f=>f.name==='firestore.rules')?.content;
  if(typeof source!=='string')throw Error('Rules source unavailable');
  const expectedRules=await readFile(resolve(root,'firestore.rules'),'utf8');
  const hash=s=>createHash('sha256').update(s.replaceAll('\r\n','\n').trim()).digest('hex');
  stage='indexes-read';
  const expectedIndexes=JSON.parse((await readFile(resolve(root,'firestore.indexes.json'),'utf8')).replace(/^\uFEFF/,''));
  const indexes=[];let pageToken;
  do{
    const url=new URL(`https://firestore.googleapis.com/v1/projects/${sharedProjectId}/databases/(default)/collectionGroups/-/indexes`);
    // The deployed Admin endpoint currently accepts only pageSize=0/default.
    if(pageToken)url.searchParams.set('pageToken',pageToken);
    const page=await read(url);indexes.push(...page.indexes??[]);pageToken=page.nextPageToken;
  }while(pageToken);
  const canonical=(index,group)=>{
    const fields=index.fields.map(f=>({fieldPath:f.fieldPath,...(f.order?{order:f.order}:{arrayConfig:f.arrayConfig})}));
    if(!fields.some(f=>f.fieldPath==='__name__'))fields.push({fieldPath:'__name__',order:fields.findLast(f=>f.order)?.order??'ASCENDING'});
    return JSON.stringify({collectionGroup:group??decodeURIComponent(index.name.split('/collectionGroups/')[1].split('/')[0]),queryScope:index.queryScope,fields});
  };
  const readyIndexes=new Set(indexes.filter(i=>i.state==='READY').map(i=>canonical(i)));
  const missingIndexes=expectedIndexes.indexes.filter(i=>!readyIndexes.has(canonical(i,i.collectionGroup)));
  const fieldMetadata=[],missingFieldIndexes=[];
  for(const field of expectedIndexes.fieldOverrides??[]){
    const current=await read(`https://firestore.googleapis.com/v1/projects/${sharedProjectId}/databases/(default)/collectionGroups/${encodeURIComponent(field.collectionGroup)}/fields/${encodeURIComponent(field.fieldPath)}`,undefined,true);
    fieldMetadata.push({expected:field,current});
    for(const wanted of field.indexes.filter(i=>i.queryScope==='COLLECTION_GROUP')){
      if(!(current?.indexConfig?.indexes??[]).some(i=>i.state==='READY'&&i.queryScope===wanted.queryScope&&i.fields?.some(f=>f.fieldPath===field.fieldPath&&f.order===wanted.order))){
        missingFieldIndexes.push({collectionGroup:field.collectionGroup,fieldPath:field.fieldPath,...wanted});
      }
    }
  }
  async function collection(path,fields){
    const results=[];let after;
    do{
      const query={from:[{collectionId:path}],select:{fields:fields.map(fieldPath=>({fieldPath}))},orderBy:[{field:{fieldPath:'__name__'},direction:'ASCENDING'}],limit:100,
        ...(after?{startAt:{values:[{referenceValue:after}],before:false}}:{})};
      const response=await read(documents+':runQuery',{structuredQuery:query});
      const docs=response.filter(r=>r.document).map(r=>r.document);results.push(...docs);
      after=docs.length===100?docs.at(-1).name:null;
      if(results.length>10000)throw Error('Manual paged inventory review required');
    }while(after);
    return results;
  }
  const value=v=>v?.integerValue!=null?Number(v.integerValue):v?.doubleValue??v?.booleanValue??v?.stringValue??null;
  const unpack=doc=>({id:doc.name.split('/').at(-1),fields:Object.fromEntries(Object.entries(doc.fields??{}).map(([k,v])=>[k,value(v)]))});
  stage='profile-and-activation-read';
  const [profiles,summaries,grants,runs,moderation,assistance]=await Promise.all([
    collection('users',['points','reportsSubmitted','verifiedCount','role']),
    collection('contribution_summaries',['policyVersion','points','falseReportStrikes']),
    collection('driver_route_assignments',['active','routeId']),collection('service_runs',['status']),
    read(documents+'/moderation_config/active',undefined,true),read(documents+'/assistance_config/active',undefined,true),
  ]);
  const totals=new Map(summaries.map(unpack).map(d=>[d.id,d.fields]));
  const candidates=profiles.map(unpack).filter(p=>!totals.has(p.id)).map(p=>({uid:p.id,
    previous:p.fields,proposed:{policyVersion:2,points:p.fields.points??0,falseReportStrikes:0,moderationRevision:0},
    requiresReview:[p.fields.points??0,p.fields.reportsSubmitted??0,p.fields.verifiedCount??0].some(v=>v!==0),
    valid:[p.fields.points??0,p.fields.reportsSubmitted??0,p.fields.verifiedCount??0].every(v=>Number.isSafeInteger(v)&&v>=0)}));
  let administrator={verified:false};
  try{
    const lookup=await read(`https://identitytoolkit.googleapis.com/v1/projects/${sharedProjectId}/accounts:lookup`,{email:['pasindushehan0927@gmail.com']});
    const u=lookup.users?.length===1?lookup.users[0]:null;
    administrator={verified:true,exists:!!u,enabled:!!u&&!u.disabled,adminClaim:u?JSON.parse(u.customAttributes??'{}').admin===true:false};
  }catch{administrator={verified:false};}
  const activeGrants=new Set(grants.map(unpack).filter(d=>d.fields.active===true&&d.fields.routeId).map(d=>d.id));
  const report={projectId:sharedProjectId,checkedAt:new Date().toISOString(),readOnly:true,
    rulesMatch:hash(source)===hash(expectedRules),deployedRulesHash:hash(source),expectedRulesHash:hash(expectedRules),
    missingCompositeIndexes:missingIndexes.length,missingFieldIndexes:missingFieldIndexes.length,
    profiles:profiles.length,existingV2Summaries:summaries.map(unpack).filter(d=>d.fields.policyVersion===2).length,
    legacyBaselinesRequiringReview:candidates.filter(c=>c.requiresReview).length,invalidLegacyBaselines:candidates.filter(c=>!c.valid).length,
    operatorsWithoutRouteGrant:profiles.map(unpack).filter(p=>p.fields.role==='operator'&&!activeGrants.has(p.id)).length,
    datedRuns:runs.length,moderationEnabled:value(moderation?.fields?.enabled)===true,assistanceEnabled:value(assistance?.fields?.enabled)===true,administrator};
  stage='private-review-write';
  const directory=resolve(root,'.private/shared-v2-preflight',report.checkedAt.replaceAll(':','-'));
  await mkdir(directory,{recursive:true});
  await writeFile(resolve(directory,'deployed-rules.json'),JSON.stringify({release,source},null,2));
  await writeFile(resolve(directory,'index-diff.json'),JSON.stringify({indexes,missingIndexes,fieldMetadata,missingFieldIndexes},null,2));
  await writeFile(resolve(directory,'baseline-proposal.json'),JSON.stringify({projectId:sharedProjectId,apply:false,candidates,existingSummaries:summaries},null,2));
  await writeFile(resolve(directory,'activation-before.json'),JSON.stringify({moderation,assistance},null,2));
  await writeFile(resolve(directory,'report.json'),JSON.stringify(report,null,2));
  console.log(JSON.stringify({...report,privateReviewFolder:directory}));
}
main().catch(e=>{console.error(JSON.stringify({error:'shared-v2-preflight-unavailable',stage,status:e.status??null,detail:e.detail,endpoint:e.endpoint,remoteChanges:false}));process.exitCode=1;});
