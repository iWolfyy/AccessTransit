import {PolicyError} from './policy.mjs';
const fail=code=>{throw new PolicyError(code);};
const id=v=>typeof v==='string'&&v.length>0&&v.length<=128&&!v.includes('/')&&!['.','..'].includes(v);
const date=v=>v instanceof Date?v:v?.toDate?.();
const open=r=>['pending','acknowledged'].includes(r.status);
const active=(a,t)=>!a?.permanent&&!a?.communityPermanent&&!a?.manualSuspended&&!(date(a?.communitySuspendedUntil)>t)&&!(date(a?.manualSuspendedUntil)>t);
const wire=(key,r)=>({...r,id:key,createdAt:date(r.createdAt)?.toISOString(),expiresAt:date(r.expiresAt)?.toISOString()});

export function createAssistancePolicy({store,now=()=>new Date()}) {
  const scope=i=>i.scope==null||i.scope==='normal'?'':i.scope==='sample'?'sample_test/shared/':fail('invalid-scope');
  async function actor(tx,p,uid,time){
    if(!id(uid))fail('invalid-request');
    const [user,access]=await Promise.all([tx.get(p+'users/'+uid),tx.get(p+'account_access/'+uid)]);
    if(!user)fail('account-missing');if(!active(access,time))fail('account-suspended');return user;
  }
  async function operation(tx,p,runId){
    const run=await tx.get(p+'service_runs/'+runId);
    if(!run||!id(run.busId)||!id(run.routeId))return null;
    const [bus,route]=await Promise.all([tx.get(p+'buses/'+run.busId),tx.get(p+'routes/'+run.routeId)]);
    const driver=run.status==='scheduled'?bus?.driverId:run.driverId;
    if(!id(driver))return {run,bus,driver:null};
    const [approval,grant,access,lock]=await Promise.all([tx.get(p+'operator_access/'+driver),tx.get(p+'driver_route_assignments/'+driver),tx.get(p+'account_access/'+driver),tx.get(p+'operation_locks/'+driver)]);
    const valid=route&&!route.archived&&!route.deletionPending&&bus&&!bus.isDemo&&!bus.deletionPending&&approval?.approved===true&&grant?.active===true&&grant.routeId===run.routeId&&bus?.routeId===run.routeId&&bus?.driverId===driver&&active(access,now())&&
      (run.status==='scheduled'||(lock?.active===true&&lock.tripId===runId&&lock.busId===run.busId));
    return {run,bus,driver:valid?driver:null};
  }
  async function refresh(tx,p,key,r,time,op){
    if(!open(r))return r;
    let reason=null;
    if(!date(r.expiresAt)||date(r.expiresAt)<=time)reason='expired';
    else if(!op||!['scheduled','boarding','in_progress'].includes(op.run.status))reason='run-ended';
    else if(!op.driver)reason='driver-unavailable';
    const trip=op?await tx.get(p+'trips/'+r.serviceRunId):null;
    if(!reason&&op.run.status!=='scheduled'&&(!trip||trip.driverId!==op.driver||trip.busId!==r.busId||trip.status!=='in_progress'))reason='driver-unavailable';
    if(!reason&&(trip?.currentStopIndex>r.stopIndex||(r.purpose==='boarding'&&r.stopIndex===0&&trip?.actualDepartureTime)))reason='stop-passed';
    if(reason)return {...r,status:'expired',endReason:reason,updatedAt:time};
    if(op.driver!==r.driverId||(op.run.handoverVersion??0)!==(r.runHandoverVersion??0))return {...r,driverId:op.driver,status:'pending',assignmentVersion:r.assignmentVersion+1,runHandoverVersion:op.run.handoverVersion??0,updatedAt:time,endReason:null};
    return r;
  }
  function save(tx,p,key,before,after,time){
    if(before===after)return;
    tx.set(p+'boarding_requests/'+key,after);
    if(before.assignmentVersion!==after.assignmentVersion){
      tx.create(`${p}notification_outbox/${key}/events/assistance-${after.assignmentVersion}`,{kind:'boarding-assistance',uid:after.driverId,requestId:key,serviceRunId:after.serviceRunId,assignmentVersion:after.assignmentVersion,status:'available-in-app',delivery:'in-app-only',pushState:'pending',createdAt:time});
      tx.create(`${p}assistance_audit/${key}/events/handover-${after.assignmentVersion}`,{kind:'driver-retargeted',oldDriver:before.driverId,newDriver:after.driverId,createdAt:time});
    }
  }
  async function single(input,action=null,trusted=false){
    const p=scope(input),key=input.requestId;if(!id(key))fail('invalid-request');
    return store.runTransaction(async tx=>{
      const time=now();if(!trusted)await actor(tx,p,input.actorUid,time);
      const r=await tx.get(p+'boarding_requests/'+key);if(!r||r.policyVersion!==2)fail('assistance-unavailable');
      const op=await operation(tx,p,r.serviceRunId);
      const rider=r.riderId===input.actorUid,driver=op?.driver===input.actorUid;
      if(!trusted&&!rider&&!driver&&input.actorAdmin!==true)fail('assistance-unavailable');
      const value=await refresh(tx,p,key,r,time,op);
      let result=value;
      if(action&&open(value)){
        if(action==='cancelled'&&rider)result={...value,status:action,updatedAt:time};
        else if(driver&&value.driverId===input.actorUid&&((value.status==='pending'&&['acknowledged','rejected'].includes(action))||(value.status==='acknowledged'&&action==='completed'))){result={...value,status:action,updatedAt:time};}
        else fail('assistance-transition-denied');
      }else if(action&&value.status!==action&&value.status!=='expired')fail('assistance-transition-denied');
      save(tx,p,key,r,result,time);return {request:wire(key,result)};
    });
  }
  return {
    async submit(input){
      const p=scope(input),{requestId,actorUid,serviceRunId,busId,stationId,boardingStationId,alightingStationId,purpose,assistanceTypes}=input;
      if(![requestId,serviceRunId,busId,stationId,boardingStationId,alightingStationId].every(id)||!['boarding','alighting'].includes(purpose)||!Array.isArray(assistanceTypes)||!assistanceTypes.length||assistanceTypes.length>3||new Set(assistanceTypes).size!==assistanceTypes.length||assistanceTypes.some(t=>!['Deploy Ramp','Extra Time',purpose==='boarding'?'Boarding Help':'Alighting Help'].includes(t)))fail('invalid-request');
      return store.runTransaction(async tx=>{
        const time=now(),user=await actor(tx,p,actorUid,time),existing=await tx.get(p+'boarding_requests/'+requestId);
        if(existing){
          if(existing.policyVersion!==2||existing.riderId!==actorUid||existing.serviceRunId!==serviceRunId||existing.busId!==busId||existing.stationId!==stationId||existing.boardingStationId!==boardingStationId||existing.alightingStationId!==alightingStationId||existing.purpose!==purpose||JSON.stringify(existing.assistanceTypes)!==JSON.stringify(assistanceTypes))fail('request-id-conflict');
          return {request:wire(requestId,existing)};
        }
        const op=await operation(tx,p,serviceRunId),run=op?.run;
        if(!op?.driver||!['scheduled','boarding','in_progress'].includes(run?.status)||run.busId!==busId||op.bus?.catalogueSource!=='operator_catalogue'||op.bus?.catalogueRecordType==='published_timetable'||(run.status==='scheduled'&&(!date(run.latestStartAt)||date(run.latestStartAt)<time)))fail('assistance-unavailable');
        const stops=run.stops??[],board=stops.indexOf(boardingStationId),alight=stops.indexOf(alightingStationId);
        if(board<0||alight<=board||new Set(stops).size!==stops.length||stationId!==(purpose==='boarding'?boardingStationId:alightingStationId))fail('invalid-request');
        const [station,trip]=await Promise.all([tx.get(p+'stations/'+stationId),tx.get(p+'trips/'+serviceRunId)]);
        const at=date(run.initialStopTimes?.[stationId]?.estimatedArrival),boardAt=date(run.initialStopTimes?.[boardingStationId]?.estimatedArrival),stopIndex=purpose==='boarding'?board:alight;
        if(station?.catalogueSource!=='operator_catalogue'||station?.isDemo||station?.deletionPending||!at||!boardAt||boardAt>new Date(+time+86400000)||trip?.currentStopIndex>stopIndex||(purpose==='boarding'&&stopIndex===0&&trip?.actualDepartureTime))fail('assistance-unavailable');
        if(run.status!=='scheduled'&&(!trip||trip.driverId!==op.driver||trip.busId!==busId||trip.status!=='in_progress'))fail('assistance-unavailable');
        const expiresAt=new Date(Math.max(+at+1800000,run.status==='scheduled'?0:+time+1800000));
        if(expiresAt<=time)fail('assistance-unavailable');
        const r={policyVersion:2,riderId:actorUid,riderName:user.name??'Rider',busId,serviceRunId,stationId,boardingStationId,alightingStationId,
          boardingIndex:board,alightingIndex:alight,stopIndex,stopName:station.name??stationId,routeNo:run.routeNo??'',purpose,assistanceTypes,driverId:op.driver,assignmentVersion:1,runHandoverVersion:run.handoverVersion??0,status:'pending',createdAt:time,expiresAt};
        tx.create(p+'boarding_requests/'+requestId,r);
        tx.create(`${p}notification_outbox/${requestId}/events/assistance-1`,{kind:'boarding-assistance',uid:op.driver,requestId,serviceRunId,assignmentVersion:1,status:'available-in-app',delivery:'in-app-only',pushState:'pending',createdAt:time});
        return {request:wire(requestId,r)};
      });
    },
    get:input=>single(input),
    action:input=>{if(!['acknowledged','rejected','completed','cancelled'].includes(input.status))fail('invalid-request');return single(input,input.status);},
    reconcile:input=>single(input,null,true),
    async list(input){
      const p=scope(input);if(input.after!=null&&!id(input.after))fail('invalid-request');
      await store.runTransaction(async tx=>{
        await actor(tx,p,input.actorUid,now());
        if(input.after){const cursor=await tx.get(p+'boarding_requests/'+input.after);if(!cursor||cursor.policyVersion!==2||(input.serviceRunId!=null?cursor.serviceRunId!==input.serviceRunId:cursor.riderId!==input.actorUid))fail('invalid-request');}
        if(input.serviceRunId!=null){if(!id(input.serviceRunId))fail('invalid-request');const op=await operation(tx,p,input.serviceRunId);if(op?.driver!==input.actorUid)fail('assistance-unavailable');}
      });
      const filters=[['policyVersion','==',2],input.serviceRunId!=null?['serviceRunId','==',input.serviceRunId]:['riderId','==',input.actorUid]];
      if(input.serviceRunId!=null)filters.push(['status','in',['pending','acknowledged']]);
      const rows=await store.page({collection:p+'boarding_requests',filters,after:input.after??null,limit:21,
        ...(input.serviceRunId==null?{orderField:'createdAt',direction:'desc'}:{})});
      const items=[];for(const row of rows.slice(0,20))items.push((await single({...input,requestId:row.id})).request);
      return {items,next:rows.length>20?rows[19].id:null};
    },
  };
}
