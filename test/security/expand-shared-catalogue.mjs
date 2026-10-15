// Additive import only: no deletes, updates, Auth, approvals or rules changes.
// Default: read-only preflight. --validate: offline validation. --apply: create missing records.
// --verify: compare imported records and the original catalogue snapshot; check public reads.
import {createRequire} from 'node:module';
import {readFile, writeFile, mkdir, readdir} from 'node:fs/promises';
import {resolve} from 'node:path';
import {isDeepStrictEqual} from 'node:util';
const root=resolve(import.meta.dirname,'../..');
const projectId='accesstransit-b615b';
const mode=process.argv[2];
if(process.argv.length>3 || ![undefined,'--validate','--apply','--verify'].includes(mode)) throw new Error('Unknown arguments.');
const load=async name=>JSON.parse((await readFile(resolve(root,name),'utf8')).replace(/^\uFEFF/,''));
const data=await load('docs/catalogue-review/expanded-timetables.json');
const original=await load('docs/catalogue-review/published-timetables.json');
const knownStops=new Set([...original.stations,...data.stations].map(s=>s.id));
const provenance={catalogueSource:'operator_catalogue',isDemo:false,sourceUrl:data.sourceUrl,
  sourcePublisher:data.publisher,sourceRetrievedDate:data.retrievedDate,sourcePublicationDate:null};
const records=[];
for(const s of data.stations) records.push({path:`stations/${s.id}`,data:{name:s.name,...provenance,
  locationAssessment:'timing_point_name_only_exact_boarding_location_unknown',lat:null,lng:null,
  capabilityAssessment:'unknown',hasRamp:false,hasElevator:false,stepFreeAccess:null}});
let overnightRuns=0;
for(const route of data.routes){
  if(route.stops.length<2 || route.stops.some(id=>!knownStops.has(id))) throw new Error('Missing route timing point.');
  records.push({path:`routes/${route.id}`,data:{...provenance,routeNo:route.routeNo,routeName:route.routeName,
    stops:route.stops,description:'Publisher-listed timing points only; intermediate stops incomplete.'}});
  if(!data.runs[route.id]?.length) throw new Error('Route has no published runs.');
  for(const times of data.runs[route.id]){
    if(times.length!==route.stops.length || times.some(t=>!/^([01]\d|2[0-3]):[0-5]\d$/.test(t))) throw new Error('Malformed/alignment error in timetable.');
    let day=0,previous=-1;
    const elapsed=times.map(t=>{const [h,m]=t.split(':').map(Number);const minutes=h*60+m;
      if(minutes<previous)day++;previous=minutes;return day*1440+minutes;});
    if(day>1 || elapsed.some((m,i)=>i && m<=elapsed[i-1]) || elapsed.at(-1)-elapsed[0]>12*60) throw new Error('Ambiguous ordered timetable.');
    if(day)overnightRuns++;
    records.push({path:`buses/${route.id}_${times[0].replace(':','')}`,data:{...provenance,
      catalogueRecordType:'published_timetable',routeId:route.id,routeNo:route.routeNo,busNo:null,driverId:null,
      stops:route.stops,scheduleTimes:times,scheduledDeparture:times[0],operatingDays:'daily_as_published',
      hasRamp:false,lowFloor:false,rampOk:null,occupancy:'unknown',capabilityAssessment:'unknown'}});
  }
}
if(Object.keys(data.runs).some(id=>!data.routes.some(r=>r.id===id)) || new Set(records.map(r=>r.path)).size!==records.length) throw new Error('Duplicate/orphan records.');
const counts=Object.fromEntries(['stations','routes','buses'].map(c=>[c,records.filter(r=>r.path.startsWith(`${c}/`)).length]));
if(mode==='--validate'){console.log(JSON.stringify({mode:'offline_validation',counts,overnightRuns}));process.exit(0);}
const config=await load('android/app/google-services.json');
if(config.project_info.project_id!==projectId)throw new Error('Configured project mismatch.');
const require=createRequire(import.meta.url);
const auth=require('firebase-tools/lib/auth.js');
const account=auth.getGlobalDefaultAccount();
if(!account)throw new Error('Firebase CLI authentication required.');
const token=await auth.getAccessToken(account.tokens.refresh_token,['https://www.googleapis.com/auth/cloud-platform','https://www.googleapis.com/auth/firebase']);
const prefix=`projects/${projectId}/databases/(default)/documents`;
const base=`https://firestore.googleapis.com/v1/${prefix}`;
async function request(url,body){
  const response=await fetch(url,{method:body?'POST':'GET',headers:{Authorization:`Bearer ${token.access_token}`,'Content-Type':'application/json'},...(body?{body:JSON.stringify(body)}:{})});
  if(!response.ok)throw new Error(`Catalogue request failed (${response.status}); no credentials logged.`);
  return response.json();
}
async function list(c){const docs=[];let page;
  do{const url=new URL(`${base}/${c}`);url.searchParams.set('pageSize','1000');if(page)url.searchParams.set('pageToken',page);
    const result=await request(url);docs.push(...(result.documents??[]));page=result.nextPageToken;}while(page);
  return docs;
}
function value(v){if(v===null)return {nullValue:'NULL_VALUE'};if(typeof v==='string')return {stringValue:v};if(typeof v==='boolean')return {booleanValue:v};if(Array.isArray(v))return {arrayValue:{values:v.map(value)}};throw new Error('Unsupported import value.');}
const fields=r=>Object.fromEntries(Object.entries(r.data).map(([k,v])=>[k,value(v)]));
// Firestore accepts enum NULL_VALUE and serializes the same value as JSON null.
function canonical(v){
  if(v && typeof v==='object' && Object.hasOwn(v,'nullValue'))return {nullValue:null};
  if(Array.isArray(v))return v.map(canonical);
  if(v && typeof v==='object')return Object.fromEntries(Object.entries(v).map(([k,x])=>[k,canonical(x)]));
  return v;
}
const sameValue=(a,b)=>isDeepStrictEqual(canonical(a),canonical(b));
const before=(await Promise.all(['stations','routes','buses'].map(list))).flat();
const missing=[];
for(const record of records){const existing=before.find(d=>d.name===`${prefix}/${record.path}`);
  if(!existing)missing.push(record);
  else if(Object.entries(fields(record)).some(([k,v])=>!sameValue(existing.fields?.[k],v)))throw new Error(`Existing record differs: ${record.path}; overwrite prohibited.`);
}
console.log(JSON.stringify({projectId,mode:mode==='--apply'?'create_only':'read_only_preflight',counts,overnightRuns,missing:missing.length,existingCatalogue:before.length}));
if(!['--apply','--verify'].includes(mode))process.exit(0);
const evidenceRoot=resolve(root,'.private/catalogue-expansion');
const evidence=mode==='--verify'
  ? resolve(evidenceRoot,(await readdir(evidenceRoot)).sort()[0])
  : resolve(evidenceRoot,new Date().toISOString().replaceAll(':','-'));
let baseline=before;
if(mode==='--apply'){
  await mkdir(evidence,{recursive:true});
  await writeFile(resolve(evidence,'catalogue-before.json'),JSON.stringify({projectId,documents:before},null,2));
  await writeFile(resolve(evidence,'create-plan.json'),JSON.stringify({projectId,records:missing},null,2));
  if(missing.length)await request(`${base}:commit`,{writes:missing.map(r=>({update:{name:`${prefix}/${r.path}`,fields:fields(r)},currentDocument:{exists:false}}))});
}else{
  if(missing.length)throw new Error('Import incomplete; verification cannot create records.');
  const saved=JSON.parse(await readFile(resolve(evidence,'catalogue-before.json'),'utf8'));
  if(saved.projectId!==projectId)throw new Error('Backup project mismatch.');
  baseline=saved.documents;
}
const after=(await Promise.all(['stations','routes','buses'].map(list))).flat();
for(const record of records){const actual=after.find(d=>d.name===`${prefix}/${record.path}`);
  if(!actual || Object.entries(fields(record)).some(([k,v])=>!sameValue(actual.fields?.[k],v)))throw new Error(`Post-import read verification failed: ${record.path}`);
}
for(const old of baseline){const actual=after.find(d=>d.name===old.name);
  if(!actual || !isDeepStrictEqual(actual.fields,old.fields) || actual.updateTime!==old.updateTime)throw new Error('Pre-existing catalogue changed concurrently; inspect snapshot.');
}
const publicReads={};
if(mode==='--verify')for(const collection of ['stations','routes','buses']){
  const response=await fetch(`${base}/${collection}?pageSize=1000`);
  if(!response.ok)throw new Error(`Public catalogue read denied: ${collection} (${response.status}).`);
  const data=await response.json();
  if(data.nextPageToken)throw new Error('Public verification needs pagination for this catalogue size.');
  for(const record of records.filter(r=>r.path.startsWith(`${collection}/`))){
    const actual=data.documents?.find(d=>d.name===`${prefix}/${record.path}`);
    if(!actual || Object.entries(fields(record)).some(([k,v])=>!sameValue(actual.fields?.[k],v)))throw new Error('Public catalogue content mismatch.');
  }
  publicReads[collection]=data.documents?.length??0;
}
const result={projectId,mode:mode==='--verify'?'verification_only':'create_only',created:mode==='--apply'?missing.length:0,verified:records.length,preExistingPreserved:baseline.length,
  publicReads,
  totals:Object.fromEntries(['stations','routes','buses'].map(c=>[c,after.filter(d=>d.name.startsWith(`${prefix}/${c}/`)).length])),verifiedAt:new Date().toISOString()};
await writeFile(resolve(evidence,'result.json'),JSON.stringify(result,null,2));
console.log(JSON.stringify(result));
