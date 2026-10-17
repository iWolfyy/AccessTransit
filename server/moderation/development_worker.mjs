/** Bounded, restart-safe normal-scope reconciliation; never sends real push. */
export function createDevelopmentWorker({db,policy,assistance,operations,lifecycle,ready,log=()=>{}}){
  let processing=false,assistanceCursor=null,handoverCursor=null,eventCursor=null,authCursor=null;
  return async()=>{
    if(processing)return;processing=true;
    try{
      if(!await ready())return;
      if(lifecycle){
        let authJobs=db.collection('auth_operations').where('status','==','pending').orderBy('__name__').limit(5);
        if(authCursor)authJobs=authJobs.startAfter(authCursor);
        const jobs=await authJobs.get();
        for(const job of jobs.docs){try{if(await ready())await lifecycle.process(job.id);}catch{log('auth-operation-review-required');}}
        authCursor=jobs.size===5?jobs.docs.at(-1).id:null;
      }
      let handovers=db.collection('operation_handovers').where('assistanceState','==','pending').orderBy('__name__').limit(5);
      if(handoverCursor)handovers=handovers.startAfter(handoverCursor);
      const h=await handovers.get();
      for(const doc of h.docs){try{if(await ready())await operations.reconcile({operationId:doc.id});}catch{log('handover-pending');}}
      handoverCursor=h.size===5?h.docs.at(-1).id:null;
      let requests=db.collection('boarding_requests').where('policyVersion','==',2).where('status','in',['pending','acknowledged']).orderBy('__name__').limit(20);
      if(assistanceCursor)requests=requests.startAfter(assistanceCursor);
      const r=await requests.get();
      for(const doc of r.docs){try{if(await ready())await assistance.reconcile({requestId:doc.id});}catch{log('assistance-pending');}}
      assistanceCursor=r.size===20?r.docs.at(-1).id:null;
      let events=db.collectionGroup('events').where('status','==','pending').orderBy('__name__').limit(20);
      if(eventCursor)events=events.startAfter(db.doc(eventCursor));
      const page=await events.get();
      for(const doc of page.docs){
        if(!/^notification_outbox\/[^/]+\/events\/[^/]+$/.test(doc.ref.path))continue;
        try{
          if(!await ready())return;
          const data=doc.data();
          if(data.kind==='reconcile-suspended-operation')await policy.reconcileOperation({reportId:doc.ref.parent.parent.id});
          if(data.kind==='expire-suspended-assistance'){
            const suspendedAt=data.suspendedAt?.toDate?.()??data.suspendedAt;
            if(!(suspendedAt instanceof Date)||!Number.isFinite(+suspendedAt)||typeof data.busId!=='string'||typeof data.tripId!=='string')throw Error('invalid-job');
            const rows=await db.collection('boarding_requests').where('busId','==',data.busId).where('status','in',['pending','acknowledged']).where('createdAt','<=',data.suspendedAt).limit(50).get();
            for(const row of rows.docs)await db.runTransaction(async tx=>{
              const [current,job]=await Promise.all([tx.get(row.ref),tx.get(doc.ref)]),v=current.data();
              const created=v?.createdAt?.toDate?.()??v?.createdAt;
              if(job.data()?.status!=='pending')return;
              if(v&&['pending','acknowledged'].includes(v.status)&&created instanceof Date&&created<=suspendedAt&&
                  (!v.serviceRunId||v.serviceRunId===data.tripId)&&v.driverId===data.uid){
                tx.update(row.ref,{status:'cancelled',cancellationReason:'driver-suspended'});
              }
            });
            // A full page may include another run's requests; require review
            // rather than looping forever or cancelling their independent data.
            await db.runTransaction(async tx=>{
              const job=await tx.get(doc.ref);
              if(job.data()?.status==='pending')tx.update(doc.ref,{status:rows.size===50?'review-required':'completed',completedAt:new Date()});
            });
          }
        }catch{log('operation-reconciliation-pending');}
      }
      eventCursor=page.size===20?page.docs.at(-1).ref.path:null;
    }catch{log('worker-scan-pending');}finally{processing=false;}
  };
}
