// Fictional operating scenarios. This module never connects to Firebase.
export const samplePrefix = 'sample_test/shared/';
export const fixtureNotice = 'SAMPLE / TEST ONLY: fictional vehicle, observation, fare and GPS; not for travel decisions.';
const minute = 60000;
const clock = t => new Intl.DateTimeFormat('en-GB', {timeZone:'Asia/Colombo',hour:'2-digit',minute:'2-digit',hourCycle:'h23'}).format(t);
const day = t => new Intl.DateTimeFormat('en-CA', {timeZone:'Asia/Colombo'}).format(t);
// Approximate scenario anchors only; these are not reviewed stop/platform coordinates.
const anchors={badulla:[6.99,81.055],bandarawela:[6.83,80.985],colombo:[6.93,79.85],ella:[6.865,81.045],homagama:[6.84,80.005],
  jaffna:[9.66,80.025],jaffna_bus_stand:[9.665,80.02],jaffna_town:[9.664,80.027],kandy:[7.29,80.635],kankesanthurai:[9.815,80.045],
  karainagar:[9.745,79.885],kurunegala:[7.485,80.365],makumbura:[6.84,79.965],mattala:[6.285,81.13],nittambuwa:[7.145,80.095],
  panadura:[6.715,79.905],passara:[6.935,81.15],pettah:[6.935,79.855],point_pedro:[9.825,80.235],soysapura:[6.795,79.885],wellawatta:[6.875,79.86],wellawaya:[6.735,81.105]};

export function realisticFixtures({now, batchId, routes, stations, users, grants = {}, previewDrivers = []}) {
  if (!(now instanceof Date) || !Number.isFinite(+now) || !/^walkthrough_[0-9T]+$/.test(batchId)) throw Error('Invalid fixture clock or batch');
  const records = [];
  stations=Object.fromEntries(Object.entries(stations).map(([id,s])=>{
    if(Number.isFinite(s.lat)&&Number.isFinite(s.lng)&&!(s.lat===0&&s.lng===0))return [id,s];
    const p=anchors[id.replace(/^ncg_/,'')];
    if(!p)throw Error('Missing synthetic coordinate anchor: '+id);
    return [id,{...s,lat:p[0],lng:p[1],coordinateSource:'approximate_synthetic_anchor'}];
  }));
  const add = (path, data) => {
    if (!/^[a-z_]+\/[A-Za-z0-9_-]+(?:\/[a-z_]+\/[A-Za-z0-9_-]+)*$/.test(path)) throw Error('Unsafe fixture path');
    records.push({path:samplePrefix+path,data:{...data,sampleScenario:true,fixtureBatch:batchId,scenarioNotice:fixtureNotice}});
  };
  const profiles = Object.entries(users);
  if (profiles.length < 2) throw Error('At least two existing accounts are needed; no Auth accounts are created');
  const passengers = profiles.filter(([,u])=>u.role!=='operator');
  const author = (passengers[0]??profiles[0])[0];
  const drivers = profiles.filter(([,u])=>u.role==='operator');
  const start = new Date(Math.ceil(+now/minute)*minute);
  const positiveAt = new Date(+now-minute);
  const runIds = [], busIds = [], covered = [];
  const stationRecord = id => stations[id];
  for (const [sourceId, route] of Object.entries(routes)) {
    const stops = route.stops;
    if (!Array.isArray(stops) || stops.length<2 || new Set(stops).size!==stops.length || stops.some(s=>!stationRecord(s))) continue;
    const routeId = sourceId;
    covered.push({sourceId,routeId,stops});
    add(`routes/${routeId}`, { ...route, routeName:`SAMPLE - ${route.routeName}`, catalogueSource:'operator_catalogue', isDemo:false });
    // Deliberately synthetic densely sampled lines; never described as road geometry.
    const points=[],vertices=[];
    for (let i=0;i<stops.length;i++) {
      const a=stationRecord(stops[i]);
      if(i) {
        const b=stationRecord(stops[i-1]);
        const n=Math.max(1,Math.ceil(Math.hypot(a.lat-b.lat,a.lng-b.lng)*111/3));
        for(let k=1;k<n;k++)points.push([b.lat+(a.lat-b.lat)*k/n,b.lng+(a.lng-b.lng)*k/n]);
      }
      points.push([a.lat,a.lng]);vertices.push(points.length-1);
    }
    add(`route_geometries/${routeId}`,{reviewed:true,synthetic:true,routeId,version:batchId,source:'https://example.invalid/sample-only',stops,points:points.map(([lat,lng])=>({lat,lng})),stopVertices:vertices});
    const offsets=[0];
    for(let i=1;i<stops.length;i++) {
      const a=stationRecord(stops[i-1]),b=stationRecord(stops[i]);
      offsets.push(offsets.at(-1)+Math.max(12,Math.round(Math.hypot(a.lat-b.lat,a.lng-b.lng)*111/35*60)));
    }
    const driver = drivers.find(([uid])=>grants[uid]?.routeId===sourceId)?.[0];
    const fareId=`${batchId}_${routeId}_fare`;
    const applies={reviewed:true,version:batchId,routePatternId:routeId,serviceClass:'SAMPLE ordinary',effectiveFrom:day(now),effectiveUntil:day(new Date(+now+7*86400000))};
    add(`fare_publications/${fareId}`,{schemaVersion:1,state:'published',synthetic:true,
      busIds:[1,2,3].map(n=>`${batchId}_${routeId}_bus${n}`),
      table:{...applies,currency:'LKR',source:'https://example.invalid/sample-tariff',amounts:Object.fromEntries(stops.slice(0,-1).map((s,i)=>[s,Object.fromEntries(stops.slice(i+1).map((t,j)=>[t,Math.round(80+(offsets[i+j+1]-offsets[i])*1.5)*100]))]))},
      mapping:{...applies,tariffId:fareId,occurrences:stops,stageByOccurrence:Object.fromEntries(stops.map(s=>[s,s]))}});
    for(let variant=0;variant<3;variant++) {
      const busId=`${batchId}_${routeId}_bus${variant+1}`;
      busIds.push(busId);
      const rampOk=[true,false,null][variant];
      const data={routeId,routeNo:route.routeNo,busNo:`SAMPLE ${route.routeNo} - ${variant+1}`,stops,
        hasRamp:true,lowFloor:true,rampOk,rampCheckedAt:rampOk===null?null:positiveAt,
        rampCheckedBy:rampOk===null?null:(driver??author),occupancy:['low','medium','high'][variant],
        driverId:variant===0?(driver??null):null,catalogueSource:'operator_catalogue',catalogueRecordType:'vehicle',isDemo:false,
        scheduledDeparture:clock(new Date(+start+10*minute)),scheduleTimes:offsets.map(o=>clock(new Date(+start+(10+o)*minute)))};
      add(`buses/${busId}`,data);
      for(const departureOffset of [2,120,360,720,1080,1410]) {
        const departure=new Date(+start+departureOffset*minute);
        const runId=`${busId}_${departureOffset}`;runIds.push(runId);
        add(`service_runs/${runId}`,{busId,routeId,routeNo:route.routeNo,serviceDate:day(departure),scheduleVersion:1,
          plannedDepartureAt:departure,latestStartAt:new Date(+departure+30*minute),status:'scheduled',stops,
          initialStopTimes:Object.fromEntries(stops.map((s,i)=>[s,{estimatedArrival:new Date(+departure+offsets[i]*minute),actualArrival:null}]))});
      }
      add(`reports/${busId}_condition`,{targetType:'bus',targetId:busId,targetName:data.busNo,category:'rampAccess',
        subCategory:variant===0?'Ramp Working':variant===1?'Ramp Broken':'Ramp status unknown',
        problemType:variant===0?'Ramp Working':variant===1?'Ramp Broken':'Ramp status unknown',severity:variant===1?'major':'minor',
        condition:variant===0?'positive':variant===1?'barrier':'unknown',description:`${fixtureNotice} Equipment condition scenario.`,
        userId:author,photoUrl:'',createdAt:positiveAt,observedAt:positiveAt,lastConfirmedAt:null,
        status:'active',publicationState:'published',policyVersion:2,rewardPolicyVersion:2,awardedPoints:10,
        falseCount:0,confirmCount:0,moderationLocked:false,isDemo:false});
      add(`reward_events/${busId}_condition/entries/publication`,{policyVersion:2,uid:author,amount:10,kind:'publication',createdAt:positiveAt});
    }
  }
  if(!covered.length) throw Error('No valid directed routes');
  // Scoped station assessments and a public positive check allow the accessibility filter to be exercised.
  for(const id of new Set(covered.flatMap(r=>r.stops))) {
    const station=stations[id];
    add(`stations/${id}`,{...station,name:`SAMPLE - ${station.name.replace(/^SAMPLE - /,'')}`,hasRamp:true,stepFreeAccess:true,
      catalogueSource:'operator_catalogue',isDemo:false,capabilityAssessment:'synthetic_walkthrough'});
  }
  for(const [index,[uid]] of (passengers.length?passengers:profiles).entries()) {
    const c=covered[index%covered.length],busId=`${batchId}_${c.routeId}_bus1`, runId=`${busId}_120`;
    add(`journeys/${batchId}_${uid}`,{journeyId:`${batchId}_${uid}`,passengerId:uid,routeId:c.routeId,routeNumber:routes[c.sourceId].routeNo,
      routeTitle:`SAMPLE - ${routes[c.sourceId].routeName}`,busId,busNo:`SAMPLE ${routes[c.sourceId].routeNo} - 1`,
      origin:`SAMPLE - ${stations[c.stops[0]].name}`,destination:`SAMPLE - ${stations[c.stops.at(-1)].name}`,
      fromStationId:c.stops[0],toStationId:c.stops.at(-1),status:'confirmed',serviceRunId:runId,
      createdAt:now,selectedDate:new Date(`${day(new Date(+start+120*minute))}T00:00:00+05:30`),departureAt:new Date(+start+120*minute),
      wheelchairAccessRequired:false,stepFreeOnly:false});
  }
  for(const [index,[uid]] of drivers.entries()) {
    const c=covered.find(r=>r.sourceId===grants[uid]?.routeId);if(!c)continue;
    const busId=`${batchId}_${c.routeId}_bus1`,runId=`${busId}_120`;
    const requestId=`${batchId}_assistance_${index}`;
    add(`boarding_requests/${requestId}`,{policyVersion:2,riderId:author,riderName:'SAMPLE passenger',busId,serviceRunId:runId,
      routeNo:routes[c.sourceId].routeNo,boardingStationId:c.stops[0],alightingStationId:c.stops.at(-1),
      stationId:c.stops[0],boardingIndex:0,alightingIndex:c.stops.length-1,stopIndex:0,stopName:`SAMPLE - ${stations[c.stops[0]].name}`,
      purpose:'boarding',assistanceTypes:['Deploy Ramp'],driverId:uid,status:'pending',assignmentVersion:1,runHandoverVersion:0,
      createdAt:now,expiresAt:new Date(+start+150*minute)});
  }
  // Explicit terminal examples, without acquiring locks or inventing ongoing GPS.
  for(const [index,c]of covered.slice(0,4).entries()) {
    const busId=`${batchId}_${c.routeId}_bus1`,source=records.find(r=>r.path===samplePrefix+`service_runs/${busId}_120`).data;
    const runId=`${busId}_history`,departure=new Date(+start-180*minute),completed=index%2===0;
    const shift=+departure-+source.plannedDepartureAt;
    const initialStopTimes=Object.fromEntries(Object.entries(source.initialStopTimes).map(([s,t])=>[s,{estimatedArrival:new Date(+t.estimatedArrival+shift),actualArrival:null}]));
    add(`service_runs/${runId}`,{...source,serviceDate:day(departure),plannedDepartureAt:departure,latestStartAt:new Date(+departure+30*minute),
      initialStopTimes,status:completed?'completed':'cancelled',completedAt:new Date(+start-60*minute)});
  }
  for(const [index,uid]of previewDrivers.slice(0,2).entries()) {
    const c=covered.find(r=>r.sourceId===grants[uid]?.routeId);if(!c)continue;
    const busId=`${batchId}_${c.routeId}_bus${index+2}`;
    const bus=records.find(r=>r.path===samplePrefix+'buses/'+busId).data;bus.driverId=uid;
    const source=records.find(r=>r.path===samplePrefix+`service_runs/${busId}_120`).data;
    const runId=`${busId}_active`,departure=new Date(+now-5*minute),shift=+departure-+source.plannedDepartureAt;
    const initialStopTimes=Object.fromEntries(Object.entries(source.initialStopTimes).map(([s,t])=>[s,{estimatedArrival:new Date(+t.estimatedArrival+shift),actualArrival:null}]));
    const stopTimes=Object.fromEntries(c.stops.map(s=>[s,{...initialStopTimes[s],actualArrival:s===c.stops[0]?departure:null}]));
    add(`service_runs/${runId}`,{...source,serviceDate:day(departure),plannedDepartureAt:departure,latestStartAt:new Date(+departure+30*minute),initialStopTimes,
      status:'in_progress',tripId:runId,driverId:uid,actualDepartureAt:departure});
    add(`trips/${runId}`,{tripId:runId,serviceRunId:runId,busId,driverId:uid,routeNo:source.routeNo,stops:c.stops,status:'in_progress',
      currentStopIndex:0,scheduledDepartureTime:departure,actualDepartureTime:departure,createdAt:departure,stopTimes});
    add(`operation_locks/${uid}`,{active:true,busId,tripId:runId,updatedAt:now});
    const a=stations[c.stops[0]],b=stations[c.stops[1]],timestamp=new Date(+now-(index===0?0:30*minute));
    add(`live_locations/${busId}`,{busId,tripId:runId,routeId:c.routeId,routeNumber:source.routeNo,driverId:uid,operatorId:uid,operatorName:'SAMPLE driver',
      latitude:a.lat+(b.lat-a.lat)*0.01,longitude:a.lng+(b.lng-a.lng)*0.01,speed:20,heading:0,accuracy:10,timestamp,lastUpdated:timestamp,
      isBroadcasting:true,status:'active',currentStopIndex:0,occupancyLevel:bus.occupancy,rampOperational:bus.rampOk});
  }
  return {records,author,runIds,busIds,covered,createdAt:now,batchId};
}
