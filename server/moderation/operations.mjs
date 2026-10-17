import {PolicyError} from './policy.mjs';

const fail=code=>{throw new PolicyError(code);};
const id=v=>typeof v==='string'&&v.length>0&&v.length<=128&&!v.includes('/')&&!['.','..'].includes(v);
const date=v=>v instanceof Date?v:v?.toDate?.();
const running=r=>r&&['boarding','in_progress'].includes(r.status);
const active=(a,t)=>!a?.authDisabled&&!a?.accountDeleted&&!a?.permanent&&!a?.communityPermanent&&!a?.manualSuspended&&!(date(a?.communitySuspendedUntil)>t)&&!(date(a?.manualSuspendedUntil)>t);

/** Trusted, transactional transfer of a dated operation. Assistance is reconciled
 * in bounded batches; authorization follows the run immediately, before batching. */
export function createOperationPolicy({store,assistance,now=()=>new Date()}) {
  const scope=i=>i.scope==null||i.scope==='normal'?'':i.scope==='sample'?'sample_test/shared/':fail('invalid-scope');
  async function actor(tx,p,i,admin=true){
    if(!id(i.actorUid))fail('invalid-request');
    const [user,access]=await Promise.all([tx.get(p+'users/'+i.actorUid),tx.get(p+'account_access/'+i.actorUid)]);
    if(!user)fail('account-missing');if(!active(access,now()))fail('account-suspended');
    if(admin&&i.actorAdmin!==true)fail('admin-required');
  }
  async function operation(tx,p,runId){
    if(!id(runId))fail('invalid-request');
    const run=await tx.get(p+'service_runs/'+runId);
    if(!running(run)||![run.busId,run.routeId,run.driverId].every(id))fail('operation-unavailable');
    const [trip,bus,live,lock,route]=await Promise.all([
      tx.get(p+'trips/'+runId),tx.get(p+'buses/'+run.busId),tx.get(p+'live_locations/'+run.busId),
      tx.get(p+'operation_locks/'+run.driverId),tx.get(p+'routes/'+run.routeId),
    ]);
    if(trip?.status!=='in_progress'||trip.driverId!==run.driverId||trip.busId!==run.busId||trip.serviceRunId!==runId||
       bus?.driverId!==run.driverId||bus.routeId!==run.routeId||bus.isDemo||bus.deletionPending||bus.catalogueRecordType==='published_timetable'||bus.catalogueSource!=='operator_catalogue'||
       live?.tripId!==runId||live.driverId!==run.driverId||!lock?.active||lock.tripId!==runId||lock.busId!==run.busId||
       !route||route.archived||route.deletionPending)fail('operation-unavailable');
    return {run,trip,bus,live};
  }
  async function eligible(tx,p,driver,routeId){
    const [user,approval,grant,access,lock]=await Promise.all(['users','operator_access','driver_route_assignments','account_access','operation_locks'].map(c=>tx.get(p+c+'/'+driver)));
    return user?.role==='operator'&&approval?.approved===true&&grant?.active===true&&grant.routeId===routeId&&active(access,now())&&lock?.active!==true;
  }
  const view=(runId,{run,trip})=>({runId,busId:run.busId,routeId:run.routeId,routeNo:run.routeNo??'',driverId:run.driverId,
    status:run.status,currentStopIndex:trip.currentStopIndex??0,handoverVersion:run.handoverVersion??0,handoverPending:run.handoverPending===true});
  return {
    async list(i){
      const p=scope(i);if(i.after!=null&&!id(i.after))fail('invalid-request');
      await store.runTransaction(tx=>actor(tx,p,i));
      const rows=await store.page({collection:p+'service_runs',filters:[['status','in',['boarding','in_progress']]],after:i.after,limit:21});
      return {items:rows.slice(0,20).map(({id:key,data:r})=>({runId:key,busId:r.busId,routeNo:r.routeNo??'',driverId:r.driverId,status:r.status})),next:rows.length>20?rows[19].id:null};
    },
    async detail(i){
      const p=scope(i);return store.runTransaction(async tx=>{await actor(tx,p,i);const op=await operation(tx,p,i.runId);return view(i.runId,op);});
    },
    async candidates(i){
      const p=scope(i);if(i.after!=null&&!id(i.after))fail('invalid-request');
      const op=await store.runTransaction(async tx=>{await actor(tx,p,i);return operation(tx,p,i.runId);});
      const rows=await store.page({collection:p+'driver_route_assignments',filters:[['active','==',true],['routeId','==',op.run.routeId]],after:i.after,limit:21});
      const items=[];
      for(const r of rows.slice(0,20)){
        const candidate=await store.runTransaction(async tx=>{
        await actor(tx,p,i);
        if(r.id!==op.run.driverId&&await eligible(tx,p,r.id,op.run.routeId)){
          const user=await tx.get(p+'users/'+r.id);return {driverId:r.id,name:typeof user.name==='string'?user.name.slice(0,100):r.id};
        }
        return null;
        });
        if(candidate)items.push(candidate);
      }
      return {items,next:rows.length>20?rows[19].id:null};
    },
    async handover(i){
      const p=scope(i),{operationId,runId,newDriverId,expectedDriverId,expectedVersion}=i,reason=i.reason?.trim();
      if(![operationId,runId,newDriverId,expectedDriverId].every(id)||!Number.isInteger(expectedVersion)||expectedVersion<0||newDriverId===expectedDriverId)fail('invalid-request');
      if(typeof reason!=='string'||reason.length<5||reason.length>2000)fail('reason-required');
      return store.runTransaction(async tx=>{
        await actor(tx,p,i);
        const path=p+'operation_handovers/'+operationId,prior=await tx.get(path);
        if(prior){
          if(prior.runId!==runId||prior.newDriverId!==newDriverId||prior.oldDriverId!==expectedDriverId||prior.expectedVersion!==expectedVersion||prior.reason!==reason||prior.adminId!==i.actorUid)fail('request-id-conflict');
          return {operationId,runId,handoverVersion:prior.handoverVersion,duplicate:true};
        }
        const op=await operation(tx,p,runId),r=op.run,time=now();
        if(r.driverId!==expectedDriverId||(r.handoverVersion??0)!==expectedVersion)fail('operation-stale');
        if(!await eligible(tx,p,newDriverId,r.routeId))fail('driver-ineligible');
        const version=expectedVersion+1;
        tx.update(p+'service_runs/'+runId,{driverId:newDriverId,handoverVersion:version,handoverPending:true,lastHandoverId:operationId});
        tx.update(p+'trips/'+runId,{driverId:newDriverId});
        tx.update(p+'buses/'+r.busId,{driverId:newDriverId});
        tx.update(p+'operation_locks/'+expectedDriverId,{active:false,updatedAt:time});
        tx.set(p+'operation_locks/'+newDriverId,{active:true,busId:r.busId,tripId:runId,updatedAt:time});
        // Preserve the observation time. An admin transfer is not a GPS fix.
        tx.update(p+'live_locations/'+r.busId,{driverId:newDriverId,operatorId:newDriverId,operatorName:'',isBroadcasting:false,status:'offline'});
        tx.create(path,{runId,busId:r.busId,oldDriverId:expectedDriverId,newDriverId,expectedVersion,handoverVersion:version,
          adminId:i.actorUid,reason,createdAt:time,assistanceState:'pending',assistanceCursor:null});
        tx.create(p+'admin_audit/'+operationId,{action:'active_trip_handover',actorUid:i.actorUid,runId,oldDriverId:expectedDriverId,newDriverId,reason,createdAt:time});
        return {operationId,runId,handoverVersion:version,duplicate:false};
      });
    },
    async accept(i){
      const p=scope(i),g=i.gps,time=now();
      if(!Number.isInteger(i.handoverVersion)||!g||Object.keys(g).some(k=>!['latitude','longitude','speed','heading','accuracy','observedAt'].includes(k)))fail('invalid-request');
      const observed=new Date(g.observedAt);
      if(!['latitude','longitude','speed','heading','accuracy'].every(k=>typeof g[k]==='number'&&Number.isFinite(g[k]))||
         Math.abs(g.latitude)>90||Math.abs(g.longitude)>180||(!g.latitude&&!g.longitude)||g.speed<0||g.speed>200||g.heading<0||g.heading>360||
         g.accuracy<0||g.accuracy>100||!Number.isFinite(+observed)||+time-+observed>30000||+observed-+time>5000)fail('gps-unavailable');
      return store.runTransaction(async tx=>{
        await actor(tx,p,i,false);const op=await operation(tx,p,i.runId),r=op.run;
        if(r.driverId!==i.actorUid||r.handoverVersion!==i.handoverVersion)fail('operation-stale');
        const [approval,grant,access]=await Promise.all(['operator_access','driver_route_assignments','account_access'].map(c=>tx.get(p+c+'/'+i.actorUid)));
        if(approval?.approved!==true||grant?.active!==true||grant.routeId!==r.routeId||!active(access,now()))fail('driver-ineligible');
        if(+now()-+observed>30000||+observed-+now()>5000)fail('gps-unavailable');
        if(r.handoverPending!==true)return {runId:i.runId,handoverVersion:r.handoverVersion,accepted:true};
        tx.update(p+'service_runs/'+i.runId,{handoverPending:false,handoverAcceptedAt:now()});
        tx.update(p+'live_locations/'+r.busId,{latitude:g.latitude,longitude:g.longitude,speed:g.speed,heading:g.heading,accuracy:g.accuracy,
          observedAt:observed,timestamp:now(),isBroadcasting:true,status:r.status==='boarding'?'stopped':'active',currentStopIndex:op.trip.currentStopIndex??0});
        return {runId:i.runId,handoverVersion:r.handoverVersion,accepted:true};
      });
    },
    async reconcile(i){
      const p=scope(i);if(!id(i.operationId))fail('invalid-request');
      const path=p+'operation_handovers/'+i.operationId;
      const job=await store.runTransaction(tx=>tx.get(path));
      if(!job||job.assistanceState!=='pending')return;
      const rows=await store.page({collection:p+'boarding_requests',filters:[['policyVersion','==',2],['serviceRunId','==',job.runId]],after:job.assistanceCursor,limit:20});
      for(const r of rows)await assistance.reconcile({scope:i.scope,requestId:r.id});
      await store.runTransaction(async tx=>{
        const current=await tx.get(path);
        if(current?.assistanceState!=='pending'||current.assistanceCursor!==job.assistanceCursor)return;
        tx.update(path,{assistanceCursor:rows.length===20?rows.at(-1).id:null,assistanceState:rows.length===20?'pending':'completed'});
      });
    },
  };
}
