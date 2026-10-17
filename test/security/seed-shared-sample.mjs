// Authenticated admin fixture setup. Writes ONLY sample_test/shared descendants.
// Default read-only. --apply creates fixtures; --refresh updates fixed fixture IDs
// with update-time preconditions, never deletes user-created sample activity.
import {createRequire} from 'node:module';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {resolve} from 'node:path';
import {isDeepStrictEqual} from 'node:util';
const root=resolve(import.meta.dirname,'../..');
const projectId='accesstransit-b615b';
const mode=process.argv[2];
if(![undefined,'--apply','--refresh'].includes(mode) || process.argv.length>3)throw new Error('Unknown mode.');
const plan=JSON.parse(await readFile(resolve(root,'.private/firebase-reset/reset-plan.json'),'utf8'));
if(plan.projectId!==projectId || plan.accounts.length!==8)throw new Error('Expected existing eight-account project.');
const require=createRequire(import.meta.url);const auth=require('firebase-tools/lib/auth.js');
const account=auth.getGlobalDefaultAccount();if(!account)throw new Error('Firebase CLI authentication required.');
const token=await auth.getAccessToken(account.tokens.refresh_token,['https://www.googleapis.com/auth/cloud-platform','https://www.googleapis.com/auth/firebase']);
const rootName=`projects/${projectId}/databases/(default)/documents`;
const prefix=`${rootName}/sample_test/shared/`;
const base=`https://firestore.googleapis.com/v1/${rootName}`;
async function request(url,body){const r=await fetch(url,{method:body?'POST':'GET',headers:{Authorization:`Bearer ${token.access_token}`,'Content-Type':'application/json'},...(body?{body:JSON.stringify(body)}:{})});
  if(!r.ok)throw new Error(`Firebase request failed (${r.status}); no credential details logged.`);return r.json();}
async function list(path){const records=[];let page;do{const u=new URL(`${base}/${path}`);u.searchParams.set('pageSize','1000');if(page)u.searchParams.set('pageToken',page);const r=await request(u);records.push(...(r.documents??[]));page=r.nextPageToken;}while(page);return records;}
const decode=v=>'nullValue'in v?null:'stringValue'in v?v.stringValue:'booleanValue'in v?v.booleanValue:'integerValue'in v?Number(v.integerValue):'doubleValue'in v?v.doubleValue:'timestampValue'in v?new Date(v.timestampValue):'arrayValue'in v?(v.arrayValue.values??[]).map(decode):Object.fromEntries(Object.entries(v.mapValue?.fields??{}).map(([k,x])=>[k,decode(x)]));
const encode=v=>v===null?{nullValue:'NULL_VALUE'}:v instanceof Date?{timestampValue:v.toISOString()}:typeof v==='string'?{stringValue:v}:typeof v==='boolean'?{booleanValue:v}:typeof v==='number'?Number.isInteger(v)?{integerValue:String(v)}:{doubleValue:v}:Array.isArray(v)?{arrayValue:{values:v.map(encode)}}:{mapValue:{fields:Object.fromEntries(Object.entries(v).map(([k,x])=>[k,encode(x)]))}};
const plain=d=>Object.fromEntries(Object.entries(d.fields??{}).map(([k,v])=>[k,decode(v)]));
const rootCollections=['stations','routes','buses','users','operator_access','driver_route_assignments','service_runs','operation_locks','reports','trips','live_locations','journeys','boarding_requests'];
const before=(await Promise.all(rootCollections.map(list))).flat();
const find=(collection,id)=>{const d=before.find(d=>d.name===`${rootName}/${collection}/${id}`);if(!d)throw new Error(`Missing source ${collection}/${id}`);return plain(d);};
for(const a of plan.accounts){const p=find('users',a.uid);if(p.role!==a.role||p.email!==a.email)throw new Error('Existing profile mismatch.');}
const passengers=plan.accounts.filter(a=>a.role==='passenger');
const operators=plan.accounts.filter(a=>a.role==='operator');
if(passengers.length!==4||operators.length!==4)throw new Error('Expected four passengers and four test operators.');
const now=new Date();const ago=m=>new Date(+now-m*60000);const later=m=>new Date(+now+m*60000);
const clock=d=>new Intl.DateTimeFormat('en-GB',{timeZone:'Asia/Colombo',hour:'2-digit',minute:'2-digit',hourCycle:'h23'}).format(d);
const records=[];const fixture={sampleScenario:true,scenarioNotice:'SAMPLE / TEST ONLY - invented observations and vehicles, not real transit'};
const add=(path,data)=>{if(!/^[a-z_]+\/[a-zA-Z0-9_-]+$/.test(path))throw new Error('Unexpected fixture path.');records.push({path,data:{...data,...fixture}});};
for(const a of plan.accounts)add(`users/${a.uid}`,{...find('users',a.uid),points:0,reportsSubmitted:0,verifiedCount:0});
for(const a of operators)add(`operator_access/${a.uid}`,{approved:true,approvalPurpose:'sample_namespace_only',...fixture});
for(const d of before.filter(d=>d.name.startsWith(`${rootName}/stations/`))){const id=d.name.split('/').at(-1);const data=plain(d);
  add(`stations/${id}`,{...data,name:`SAMPLE - ${data.name}`,hasRamp:true,stepFreeAccess:true,capabilityAssessment:'synthetic_test_assessment',hasElevator:['ncg_kandy','ncg_panadura'].includes(id)});}
for(const d of before.filter(d=>d.name.startsWith(`${rootName}/routes/`))){const id=d.name.split('/').at(-1);const data=plain(d);add(`routes/${id}`,{...data,routeName:`SAMPLE - ${data.routeName}`});}
for(const d of before.filter(d=>d.name.startsWith(`${rootName}/buses/`)))add(`buses/${d.name.split('/').at(-1)}`,plain(d));
const routeIds=['ncg_panadura_kandy','ncg_kandy_panadura','ncg_makumbura_badulla','ncg_badulla_makumbura'];
for(const [i,a] of operators.entries())add(`driver_route_assignments/${a.uid}`,{
  driverId:a.uid,routeId:routeIds[i],active:true,claimRevision:0,assignmentNote:'Isolated fictional route fixture only',
});
function routeOffsets(routeId){
  const template=before.filter(d=>d.name.startsWith(`${rootName}/buses/`)).map(plain).find(b=>b.routeId===routeId);
  if(!template)throw new Error('No sourced timing template for sample route.');
  let day=0,previous=-1;
  const minutes=template.scheduleTimes.map(t=>{const [h,m]=t.split(':').map(Number);const n=h*60+m;if(n<previous)day++;previous=n;return day*1440+n;});
  return minutes.map(m=>m-minutes[0]);
}
const vehicles=[];
for(let i=0;i<16;i++){
  const routeId=routeIds[i%4];const route=find('routes',routeId);const driver=operators[i%4];
  // Synthetic departure slots cover morning/evening plus one upcoming run per direction.
  const dep=i<4?later(15+i*2):new Date(+now+((Math.floor(i/4)*4*60)+30)*60000);
  const offsets=routeOffsets(routeId);
  const times=route.stops.map((_,s)=>clock(new Date(+dep+offsets[s]*60000)));
  const rampOk=Math.floor(i/4)===1?false:Math.floor(i/4)===2?null:true;
  const id=`sample_bus_${String(i+1).padStart(2,'0')}`;
  const data={routeId,routeNo:route.routeNo,busNo:`SAMPLE BUS ${String(i+1).padStart(2,'0')}`,driverId:driver.uid,
    stops:route.stops,scheduleTimes:times,scheduledDeparture:times[0],catalogueSource:'sample_test',isDemo:false,
    catalogueRecordType:'vehicle',hasRamp:true,lowFloor:true,rampOk,rampCheckedAt:rampOk===null?null:ago(2),rampCheckedBy:rampOk===null?null:driver.uid,
    occupancy:['low','medium','high','low'][Math.floor(i/4)],sourceUrl:null};
  vehicles.push({id,data});add(`buses/${id}`,data);
  add(`service_runs/sample_run_${String(i+1).padStart(2,'0')}`,{
    busId:id,routeId,routeNo:route.routeNo,serviceDate:new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Colombo'}).format(dep),
    status:'scheduled',plannedDepartureAt:dep,latestStartAt:new Date(+dep+30*60000),stops:route.stops,
    initialStopTimes:Object.fromEntries(route.stops.map((stop,s)=>[stop,{estimatedArrival:new Date(+dep+offsets[s]*60000),actualArrival:null}])),
  });
}
const observations=[
  ['rampAccess','Ramp working','positive','low'],['rampAccess','Ramp broken','barrier','medium'],
  ['crowding','Seats occupied','barrier','high'],['cleanliness','Clean & safe','positive','low'],
  ['safetyHazard','Broken grab rail','barrier','medium'],['driverAssistanceDenied','Driver refused','barrier','low'],
  ['rampAccess','Ramp status unknown','unknown','medium'],['crowding','Seats free','positive','low'],
  ['elevatorOut','Elevator out of service','barrier','low'],['rampAccess','Ramp clear','positive','low'],
  ['tactilePavingBlocked','Tactile paving blocked','barrier','medium'],['safetyHazard','Poor lighting','barrier','low'],
  ['rampAccess','Ramp repaired','positive','low'],['cleanliness','Dirty vehicle','barrier','medium'],
  ['crowding','Crowded earlier','barrier','high'],['rampAccess','Previous ramp fault','barrier','low'],
];
for(let i=0;i<observations.length;i++){
  const [category,subCategory,condition,crowdingLevel]=observations[i];const station=i>=8&&i<=11;
  // Keep the four primary walkthrough endpoints clear. Barrier scenarios belong
  // to other timing points so every primary direction retains a usable option.
  const bus=vehicles[i%vehicles.length];const targetId=station?['ncg_jaffna_bus_stand','ncg_panadura','ncg_soysapura','ncg_kankesanthurai'][i-8]:bus.id;
  const author=passengers[i%4];const voter=passengers[(i+1)%4];const resolved=i===12||i===13||i===15;
  const id=`sample_report_${String(i+1).padStart(2,'0')}`;
  const report={targetType:station?'station':'bus',targetId,targetName:station?`SAMPLE - ${find('stations',targetId).name}`:bus.data.busNo,
    problemType:subCategory,severity:condition==='barrier'?'major':'minor',category,subCategory,condition,crowdingLevel,
    description:`SAMPLE SCENARIO: ${subCategory}. Invented for app testing; not a real passenger observation.`,photoUrl:'',
    publicationState:'published',isDemo:false,status:resolved?'resolved':'active',createdAt:ago(i===14?90:10+i),
    lastConfirmedAt:ago(i===14?80:3),confirmCount:1,falseCount:0,userId:author.uid,confirmedBy:[voter.uid],flaggedBy:[],
    ...(resolved?{resolvedBy:author.uid,resolvedAt:ago(1)}:{})};
  add(`reports/${id}`,report);
  const authorProfile=records.find(r=>r.path===`users/${author.uid}`).data;authorProfile.points+=10;authorProfile.reportsSubmitted++;
  const voterProfile=records.find(r=>r.path===`users/${voter.uid}`).data;voterProfile.points+=5;voterProfile.verifiedCount++;
  if(resolved)add(`report_resolutions/${id}`,{reportId:id,resolvedBy:author.uid,resolvedAt:ago(1),targetType:report.targetType,targetId,
    problemType:subCategory,category,previousStatus:'active',status:'resolved'});
}
for(let i=0;i<8;i++){
  const rider=passengers[i%4],bus=vehicles[i%4];const route=find('routes',bus.data.routeId);const stop=bus.data.stops[0];
  add(`boarding_requests/sample_request_${i+1}`,{riderId:rider.uid,riderName:rider.name,busId:bus.id,routeNo:bus.data.routeNo,
    stationId:stop,stopName:`SAMPLE - ${find('stations',stop).name}`,assistanceTypes:['Deploy Ramp','Extra Time'],
    status:i<4?'pending':['acknowledged','completed','rejected','cancelled'][i-4],purpose:'boarding',createdAt:ago(2)});
  add(`journeys/sample_journey_${i+1}`,{journeyId:`sample_journey_${i+1}`,passengerId:rider.uid,routeId:bus.data.routeId,
    routeNumber:bus.data.routeNo,routeTitle:`SAMPLE - ${route.routeName}`,busId:bus.id,busNo:bus.data.busNo,
    origin:`SAMPLE - ${find('stations',stop).name}`,destination:`SAMPLE - ${find('stations',bus.data.stops.at(-1)).name}`,
    status:i<4?'confirmed':'completed',createdAt:ago(5),fromStationId:stop,toStationId:bus.data.stops.at(-1),
    selectedDate:now,selectedTimeMinutes:null,departureAt:later(15),durationMinutes:routeOffsets(bus.data.routeId).at(-1),
    estimatedFareLkr:300,wheelchairAccessRequired:false,stepFreeOnly:false});
}
for(let i=0;i<4;i++){
  const bus=vehicles[i];const tripId=`sample_trip_${i+1}`;
  add(`trips/${tripId}`,{tripId,serviceRunId:tripId,busId:bus.id,driverId:bus.data.driverId,routeNo:bus.data.routeNo,stops:bus.data.stops,
    status:i<2?'in_progress':'completed',currentStopIndex:i<2?0:bus.data.stops.length-1,
    scheduledDepartureTime:ago(5),actualDepartureTime:ago(5),createdAt:ago(6),
    stopTimes:Object.fromEntries(bus.data.stops.map((id,s)=>[id,{estimatedArrival:later(routeOffsets(bus.data.routeId)[s]),actualArrival:s===0?ago(5):i<2?null:ago(1)}]))});
  const [latitude,longitude]=[[6.713,79.908],[7.293,80.638],[6.839,79.967],[6.993,81.055]][i];
  add(`service_runs/${tripId}`,{busId:bus.id,routeId:bus.data.routeId,routeNo:bus.data.routeNo,tripId,driverId:bus.data.driverId,
    serviceDate:new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Colombo'}).format(ago(5)),
    status:i<2?'in_progress':'completed',plannedDepartureAt:ago(5),latestStartAt:later(25),stops:bus.data.stops,actualDepartureAt:ago(5),
    initialStopTimes:Object.fromEntries(bus.data.stops.map((id,s)=>[id,{estimatedArrival:new Date(+ago(5)+routeOffsets(bus.data.routeId)[s]*60000),actualArrival:null}]))});
  add(`operation_locks/${bus.data.driverId}`,{active:i<2,busId:bus.id,tripId,updatedAt:now});
  add(`live_locations/${bus.id}`,{busId:bus.id,routeId:bus.data.routeId,routeNumber:bus.data.routeNo,routeName:'SAMPLE GPS SNAPSHOT',
    driverId:bus.data.driverId,operatorId:bus.data.driverId,operatorName:'SAMPLE OPERATOR',latitude,longitude,
    speed:0,heading:0,timestamp:i===1?ago(30):now,lastUpdated:i===1?ago(30):now,status:i<2?'active':'offline',
    isBroadcasting:i<2,tripId,currentStopIndex:0,nextStop:`SAMPLE - ${find('stations',bus.data.stops[1]).name}`,etaMinutes:15,
    rampOperational:bus.data.rampOk,elevatorWorking:null,occupancyLevel:bus.data.occupancy});
}
const existing=(await Promise.all([...new Set(records.map(r=>r.path.split('/')[0]))].map(c=>list(`sample_test/shared/${c}`)))).flat();
const writes=records.map(r=>{const name=prefix+r.path;if(!name.startsWith(prefix))throw new Error('Write escaped sample scope.');
  const old=existing.find(d=>d.name===name);if(old&&mode==='--apply')throw new Error('Sample fixtures exist; use explicit --refresh to reset fixed fixture IDs.');
  return {update:{name,fields:Object.fromEntries(Object.entries(r.data).map(([k,v])=>[k,encode(v)]))},currentDocument:old?{updateTime:old.updateTime}:{exists:false}};});
const counts=Object.fromEntries([...new Set(records.map(r=>r.path.split('/')[0]))].map(c=>[c,records.filter(r=>r.path.startsWith(c+'/')).length]));
console.log(JSON.stringify({projectId,namespace:'sample_test/shared',mode:mode??'read_only',counts,total:records.length,realRecordsChanged:0}));
if(!mode)process.exit(0);
const evidence=resolve(root,'.private/shared-sample',new Date().toISOString().replaceAll(':','-'));await mkdir(evidence,{recursive:true});
await writeFile(resolve(evidence,'before.json'),JSON.stringify({projectId,root:before,sample:existing},null,2));
await writeFile(resolve(evidence,'fixtures.json'),JSON.stringify(records,null,2));
await request(`${base}:commit`,{writes});
const afterRoot=(await Promise.all(rootCollections.map(list))).flat();
if(before.length!==afterRoot.length || before.some(d=>!isDeepStrictEqual(d,afterRoot.find(x=>x.name===d.name))))throw new Error('Root data changed concurrently; inspect snapshot.');
const after=(await Promise.all(Object.keys(counts).map(c=>list(`sample_test/shared/${c}`)))).flat();
for(const record of records){const doc=after.find(d=>d.name===prefix+record.path);if(!doc||!isDeepStrictEqual(plain(doc),record.data))throw new Error(`Fixture readback mismatch ${record.path}`);}
const result={projectId,namespace:'sample_test/shared',counts,verified:records.length,realRecordsPreserved:before.length,verifiedAt:new Date().toISOString()};
await writeFile(resolve(evidence,'result.json'),JSON.stringify(result,null,2));console.log(JSON.stringify(result));
