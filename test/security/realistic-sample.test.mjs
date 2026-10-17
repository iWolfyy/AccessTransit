import test from 'node:test';
import assert from 'node:assert/strict';
import {realisticFixtures,samplePrefix} from './realistic-sample-fixtures.mjs';
import {developmentScopes} from '../../server/moderation/development_runtime.mjs';
const now=new Date('2026-10-17T18:29:30Z'); // Colombo midnight rollover.
const stations={badulla:{name:'Badulla',lat:6.99,lng:81.05},ella:{name:'Ella',lat:6.86,lng:81.04},bandarawela:{name:'Bandarawela',lat:6.83,lng:80.98}};
const input={now,batchId:'walkthrough_20261017T1200',stations,routes:{out:{routeNo:'S01',routeName:'Badulla to Bandarawela',stops:['badulla','ella','bandarawela']},back:{routeNo:'S01',routeName:'Bandarawela to Badulla',stops:['bandarawela','ella','badulla']}},users:{rider:{role:'passenger'},driver:{role:'operator'}},grants:{driver:{routeId:'out',active:true}}};
test('fixtures are scoped, visibly fictional and have no duplicate document paths',()=>{
 const f=realisticFixtures(input);
 assert.equal(new Set(f.records.map(r=>r.path)).size,f.records.length);
 for(const r of f.records){assert.ok(r.path.startsWith(samplePrefix));assert.equal(r.data.sampleScenario,true);assert.match(r.data.scenarioNotice,/fictional/);}
 assert.equal(f.busIds.length,6);assert.equal(f.runIds.length,36);assert.equal(f.covered.length,2);
 assert.ok(f.records.filter(r=>r.path.includes('/buses/')).every(r=>r.data.busNo.startsWith('SAMPLE')));
});
test('dated departures retain ordered segments, midnight service date and the fixed start window',()=>{
 const f=realisticFixtures(input);
 for(const r of f.records.filter(r=>r.path.includes('/service_runs/'))){
  const d=r.data,t=d.stops.map(s=>d.initialStopTimes[s].estimatedArrival);
  assert.equal(+t[0],+d.plannedDepartureAt);assert.equal(+d.latestStartAt-+t[0],30*60000);
  assert.ok(t.every((v,i)=>!i||v>t[i-1]));
  if(d.status==='scheduled'){assert.equal(d.serviceDate,'2026-10-18');assert.ok(d.plannedDepartureAt>now);assert.ok(d.plannedDepartureAt<=+now+86400000);}
 }
});
test('equipment, saved segments, fares, assistance and ledger events reference matching scoped entities',()=>{
 const f=realisticFixtures(input),rows=new Map(f.records.map(r=>[r.path.slice(samplePrefix.length),r.data]));
 assert.deepEqual([...new Set([...rows].filter(([p])=>p.startsWith('buses/')).map(([,d])=>d.rampOk))],[true,false,null]);
 for(const [path,d]of rows){
  if(path.startsWith('reports/')){assert.ok(rows.has('buses/'+d.targetId));assert.equal(rows.get('reward_events/'+path.split('/')[1]+'/entries/publication').amount,10);}
  if(path.startsWith('boarding_requests/')){const run=rows.get('service_runs/'+d.serviceRunId);assert.equal(run.busId,d.busId);assert.equal(rows.get('buses/'+d.busId).driverId,d.driverId);}
  if(path.startsWith('fare_publications/')){assert.equal(d.synthetic,true);assert.ok(d.busIds.every(id=>rows.has('buses/'+id)));assert.equal(d.mapping.tariffId,path.split('/')[1]);}
  if(path.startsWith('journeys/'))assert.equal(rows.get('service_runs/'+d.serviceRunId).busId,d.busId);
 }
});
test('synthetic geometry is dense and occurrence vertices match station coordinates',()=>{
 for(const r of realisticFixtures(input).records.filter(r=>r.path.includes('/route_geometries/'))){
  const d=r.data;assert.equal(d.synthetic,true);
  for(let i=0;i<d.stops.length;i++)assert.deepEqual(d.points[d.stopVertices[i]],{lat:stations[d.stops[i]].lat,lng:stations[d.stops[i]].lng});
  for(let i=1;i<d.points.length;i++)assert.ok(Math.hypot(d.points[i].lat-d.points[i-1].lat,d.points[i].lng-d.points[i-1].lng)*111<10);
 }
});
test('sample localhost access requires an explicit opt-in and rejects unknown options',()=>{
 assert.deepEqual(developmentScopes(),['normal']);assert.deepEqual(developmentScopes(['--sample']),['normal','sample']);assert.throws(()=>developmentScopes(['--reset']));
 assert.throws(()=>realisticFixtures({...input,batchId:'../../normal'}));
});
test('active preview identity is consistent and stale GPS remains stale without an artificial heartbeat',()=>{
 const f=realisticFixtures({...input,users:{...input.users,driver2:{role:'operator'}},grants:{...input.grants,driver2:{routeId:'back',active:true}},previewDrivers:['driver','driver2']});
 const rows=new Map(f.records.map(r=>[r.path.slice(samplePrefix.length),r.data]));
 for(const uid of ['driver','driver2']){
  const lock=rows.get('operation_locks/'+uid),run=rows.get('service_runs/'+lock.tripId),trip=rows.get('trips/'+lock.tripId),gps=rows.get('live_locations/'+lock.busId);
  assert.equal(run.status,'in_progress');assert.equal(run.driverId,uid);assert.equal(trip.serviceRunId,lock.tripId);assert.equal(gps.tripId,lock.tripId);assert.equal(gps.busId,run.busId);
  assert.equal(rows.get('buses/'+run.busId).driverId,uid);
 }
 assert.equal(+now-+rows.get('live_locations/'+rows.get('operation_locks/driver2').busId).timestamp,30*60000);
});
test('fixtures serialize to Firestore without illegal directly nested arrays',()=>{
 function validate(v){if(Array.isArray(v)){assert.ok(v.every(x=>!Array.isArray(x)));v.forEach(validate);}else if(v&&typeof v==='object'&&!(v instanceof Date))Object.values(v).forEach(validate);}
 realisticFixtures(input).records.forEach(r=>validate(r.data));
});
