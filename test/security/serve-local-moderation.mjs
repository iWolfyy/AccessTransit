// Loopback emulator server only. No cloud credentials or remote host overrides.
import {createServer} from 'node:http';
import {initializeApp,deleteApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore} from 'firebase-admin/firestore';
import {createModerationPolicy} from '../../server/moderation/policy.mjs';
import {createAppealPolicy} from '../../server/moderation/appeals.mjs';
import {createBanPolicy} from '../../server/moderation/bans.mjs';
import {createAssistancePolicy} from '../../server/moderation/assistance.mjs';
import {createOperationPolicy} from '../../server/moderation/operations.mjs';
import {createNotificationPolicy,localNotificationProvider} from '../../server/moderation/notifications.mjs';
import {adminStore} from '../../server/moderation/admin_store.mjs';
import {createModerationApi} from '../../server/moderation/api.mjs';
import {createNodeModerationHandler} from '../../server/moderation/node_handler.mjs';

if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8087'||process.env.FIREBASE_AUTH_EMULATOR_HOST!=='127.0.0.1:9099') {
  throw Error('Requires local Firestore :8087 and Auth :9099. Remote activation is forbidden.');
}
const projectId='demo-accesstransit';
const app=initializeApp({projectId},'local-moderation-v2');
const db=getFirestore(app);
if(db.projectId!==projectId)throw Error('Refusing a non-demo project');
const effectiveAt=new Date('2026-10-16T00:00:00Z');
const policy=createModerationPolicy({store:adminStore(db),effectiveAt});
const appeals=createAppealPolicy({store:adminStore(db)});
const bans=createBanPolicy({store:adminStore(db),accountAdmin:async uid=>(await getAuth(app).getUser(uid)).customClaims?.admin===true});
const assistance=createAssistancePolicy({store:adminStore(db)});
const operations=createOperationPolicy({store:adminStore(db),assistance});
const notifications=createNotificationPolicy({store:adminStore(db),assistance,provider:localNotificationProvider(adminStore(db))});
const api=createModerationApi({auth:getAuth(app),policy,appeals,bans,assistance,operations,notifications,allowedScopes:['normal']});
await db.doc('moderation_config/active').set({enabled:true,policyVersion:2,effectiveAt,localOnly:true});
await db.doc('assistance_config/active').set({enabled:true,policyVersion:2,localOnly:true});
const server=createServer(createNodeModerationHandler({api,publicOrigin:'https://local-validation.invalid'}));
server.requestTimeout=15000;server.headersTimeout=10000;
await new Promise(resolve=>server.listen(8787,'127.0.0.1',resolve));
console.log('LOCAL V2 ONLY: API http://127.0.0.1:8787, demo Auth/Firestore; no real transit or billing.');
let processing=false;
let assistanceCursor=null;
let handoverCursor=null;
let pushCursor=null;
const worker=setInterval(async()=>{
  if(processing)return;processing=true;
  try{
    let handoverQuery=db.collection('operation_handovers').where('assistanceState','==','pending').orderBy('__name__').limit(5);
    if(handoverCursor)handoverQuery=handoverQuery.startAfter(handoverCursor);
    const handovers=await handoverQuery.get();
    for(const job of handovers.docs){
      try{await operations.reconcile({operationId:job.id});}catch(_){console.error('Local handover assistance reconciliation pending.');}
    }
    handoverCursor=handovers.size===5?handovers.docs.at(-1).id:null;
    let query=db.collection('boarding_requests').where('policyVersion','==',2).where('status','in',['pending','acknowledged']).orderBy('__name__').limit(20);
    if(assistanceCursor)query=query.startAfter(assistanceCursor);
    const activeRequests=await query.get();
    for(const r of activeRequests.docs){
      try{await assistance.reconcile({requestId:r.id});}catch(_){console.error('Local assistance reconciliation unconfirmed; continuing the bounded scan.');}
    }
    assistanceCursor=activeRequests.size===20?activeRequests.docs.at(-1).id:null;
    let pushQuery=db.collectionGroup('events').where('kind','==','boarding-assistance').where('pushState','in',['pending','retry']).orderBy('__name__').limit(20);
    if(pushCursor)pushQuery=pushQuery.startAfter(db.doc(pushCursor));
    const pushes=await pushQuery.get();
    for(const event of pushes.docs){
      if(!/^notification_outbox\/[^/]+\/events\/assistance-[0-9]+$/.test(event.ref.path))continue;
      const data=event.data();if(data.nextAttemptAt?.toMillis()>Date.now())continue;
      try{await notifications.dispatch({requestId:data.requestId,assignmentVersion:data.assignmentVersion});}
      catch(_){console.error('Local simulated notification delivery pending.');}
    }
    pushCursor=pushes.size===20?pushes.docs.at(-1).ref.path:null;
    const jobs=await db.collectionGroup('events').where('status','==','pending').limit(20).get();
    for(const job of jobs.docs){
      if(!job.ref.path.startsWith('notification_outbox/'))continue;
      const data=job.data();
      if(data.kind==='reconcile-suspended-operation')await policy.reconcileOperation({reportId:job.ref.parent.parent.id});
      if(data.kind==='expire-suspended-assistance'){
        const requests=await db.collection('boarding_requests').where('busId','==',data.busId).where('status','in',['pending','acknowledged']).where('createdAt','<=',data.suspendedAt).limit(200).get();
        for(const request of requests.docs)await db.runTransaction(async tx=>{
          const current=await tx.get(request.ref),value=current.data();
          if(value&&['pending','acknowledged'].includes(value.status)&&value.createdAt?.toMillis()<=data.suspendedAt.toMillis()&&
            (!value.serviceRunId||value.serviceRunId===data.tripId))tx.update(request.ref,{status:'cancelled',cancellationReason:'driver-suspended'});
        });
        await job.ref.update({status:requests.size===200?'review-required':'completed',completedAt:new Date()});
      }
    }
  }catch(_){console.error('Local reconciliation pending; will retry.');}finally{processing=false;}
},2000);
async function stop(){clearInterval(worker);server.closeAllConnections();await new Promise(resolve=>server.close(resolve));await deleteApp(app);process.exit(0);}
process.once('SIGINT',stop);process.once('SIGTERM',stop);
