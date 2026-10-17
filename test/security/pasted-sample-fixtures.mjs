// Pure adaptation of a user-pasted legacy sample. No Firebase or deletes here.
export const prefix='sample_test/shared/';
export function pastedFixtures(input,now=new Date()) {
 const notice='SAMPLE / TEST: user-pasted legacy scenario; not verified for travel.';
 const tag='pasted_'+input.sourceSha256.slice(0,12), records=[];
 const id=x=>'pasted_'+x;
 const add=(path,data)=>records.push({path:prefix+path,data:{...data,sampleScenario:true,scenarioNotice:notice,fixtureBatch:tag,sourceSha256:input.sourceSha256}});
 const stations=new Map(input.stations.map(s=>[s.id,s])), routes=new Map(input.routes.map(r=>[r.id,r]));
 if(stations.size!==input.stations.length||routes.size!==input.routes.length||new Set(input.buses.map(b=>b.id)).size!==input.buses.length)throw Error('Duplicate source IDs');
 for(const s of input.stations){if(!Number.isFinite(s.lat)||!Number.isFinite(s.lng)||Math.abs(s.lat)>90||Math.abs(s.lng)>180)throw Error('Invalid coordinates');
 add('stations/'+id(s.id),{...s,name:'SAMPLE - '+s.name,stepFreeAccess:null,catalogueSource:'operator_catalogue',isDemo:false,coordinateSource:'user_pasted_sample',capabilityAssessment:'sample_claim_only'});}
 for(const r of input.routes){if(r.stops.length<2||r.stops.some(s=>!stations.has(s))||new Set(r.stops).size!==r.stops.length)throw Error('Invalid route');
 add('routes/'+id(r.id),{...r,routeName:'SAMPLE - '+r.routeName,stops:r.stops.map(id),catalogueSource:'operator_catalogue',isDemo:false});}
 const civil=new Date(+now+330*60000),day=Date.UTC(civil.getUTCFullYear(),civil.getUTCMonth(),civil.getUTCDate());
 const minutes=t=>{const m=/^(\d{1,2}):(\d{2})\s*(AM|PM)?$/i.exec(t);if(!m)throw Error('Invalid time: '+t);let h=+m[1],n=+m[2];if(n>59||h>(m[3]?12:23)||h<(m[3]?1:0))throw Error('Invalid clock');if(m[3])h=h%12+(m[3].toUpperCase()==='PM'?12:0);return h*60+n;};
 for(const b of input.buses){const r=routes.get(b.routeId);if(!r||b.routeNo!==r.routeNo||JSON.stringify(b.stops)!==JSON.stringify(r.stops)||b.scheduleTimes.length!==b.stops.length)throw Error('Bus itinerary mismatch: '+b.id);
 const offsets=[];let rollover=0,previous=-1;
 for(const raw of b.scheduleTimes){const m=minutes(raw);if(m<previous)rollover++;offsets.push(m+rollover*1440);previous=m;}
 if(rollover>1||offsets.some((m,i)=>i&&m<=offsets[i-1])||offsets[0]!==minutes(b.scheduledDeparture)||offsets.at(-1)-offsets[0]>720)throw Error('Ambiguous schedule: '+b.id);
 const busId=id(b.id),stops=b.stops.map(id);
 add('buses/'+busId,{...b,busNo:'SAMPLE - '+b.busNo,routeId:id(b.routeId),stops,catalogueRecordType:'vehicle',driverId:null,occupancy:'unknown',rampOk:null,rampCheckedAt:null,rampCheckedBy:null,sourceClaims:{rampOk:b.rampOk,occupancy:b.occupancy},catalogueSource:'operator_catalogue',isDemo:false});
 for(const days of [0,1]){const times=offsets.map(m=>new Date(day+days*86400000+m*60000-330*60000));const serviceDate=new Date(day+days*86400000).toISOString().slice(0,10);
 add(`service_runs/${busId}_${serviceDate}`,{busId,routeId:id(b.routeId),routeNo:b.routeNo,serviceDate,status:'scheduled',scheduleVersion:1,plannedDepartureAt:times[0],latestStartAt:new Date(+times[0]+30*60000),stops,initialStopTimes:Object.fromEntries(stops.map((s,i)=>[s,{estimatedArrival:times[i],actualArrival:null}])),createdAt:now});}
 }
 const examples=[['1','station','st_fort','Elevator entrance 2 out of service','elevatorOut','barrier',120,'active'],['2','bus','bus_101_ne3390','Wheelchair ramp deployment motor jammed','rampAccess','barrier',900,'active'],['3','station','st_bambalapitiya','Ramp pathway blocked by temporary scaffolding','rampAccess','barrier',1440,'resolved']];
 for(const [n,targetType,target,problemType,category,condition,age,status]of examples){if(!(targetType==='station'?stations.has(target):input.buses.some(b=>b.id===target)))throw Error('Report target missing');
 const author=id('demo_author_'+n),report=id('report_'+n);
 add('users/'+author,{name:'SAMPLE - imported report author '+n,role:'contributor',fixtureIdentityOnly:true});
 add('contribution_summaries/'+author,{policyVersion:2,points:10,reportsSubmitted:1,falseReportStrikes:0});
 add('reports/'+report,{targetType,targetId:id(target),targetName:'SAMPLE - '+target,problemType,subCategory:problemType,category,condition,description:notice,userId:author,createdAt:now,observedAt:new Date(+now-age*60000),status,publicationState:'published',policyVersion:2,rewardPolicyVersion:2,awardedPoints:10,confirmCount:0,falseCount:0,moderationLocked:false,photoUrl:'',isDemo:false,legacyVoteCountsNotImported:true});
 add(`reward_events/${report}/entries/publication`,{policyVersion:2,uid:author,amount:10,kind:'publication',createdAt:now});
 }
 if(records.some(r=>!r.path.startsWith(prefix))||new Set(records.map(r=>r.path)).size!==records.length)throw Error('Invalid import paths');
 return {tag,records,counts:Object.fromEntries([...new Set(records.map(r=>r.path.split('/')[2]))].map(k=>[k,records.filter(r=>r.path.split('/')[2]===k).length]))};
}
