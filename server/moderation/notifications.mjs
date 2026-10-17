import {createHash,randomUUID} from 'node:crypto';
import {PolicyError} from './policy.mjs';
const fail=code=>{throw new PolicyError(code);};
const hash=v=>createHash('sha256').update(v).digest('hex');
const id=v=>typeof v==='string'&&v.length>0&&v.length<=128&&!v.includes('/')&&!['.','..'].includes(v);
const date=v=>v instanceof Date?v:v?.toDate?.();
const active=(a,t)=>!a?.permanent&&!a?.communityPermanent&&!a?.manualSuspended&&!(date(a?.communitySuspendedUntil)>t)&&!(date(a?.manualSuspendedUntil)>t);
const scopes=i=>i.scope==null||i.scope==='normal'?'':i.scope==='sample'?'sample_test/shared/':fail('invalid-scope');

/** Delivery is at-least-once. A provider receipt is never a device receipt or
 * driver acceptance. Messages contain only an opaque event ID and generic text. */
export function createNotificationPolicy({store,assistance,provider,now=()=>new Date()}) {
  if(!provider||!['local','fcm'].includes(provider.kind)||typeof provider.send!=='function')throw Error('invalid-provider');
  async function actor(tx,p,i){
    if(!id(i.actorUid))fail('invalid-request');
    const [u,a]=await Promise.all([tx.get(p+'users/'+i.actorUid),tx.get(p+'account_access/'+i.actorUid)]);
    if(!u)fail('account-missing');if(!active(a,now()))fail('account-suspended');
  }
  async function target(i){
    const {request:r}=await assistance.reconcile({scope:i.scope,requestId:i.requestId});
    return r.status==='pending'&&r.assignmentVersion===i.assignmentVersion?r:null;
  }
  return {
    async register(i){
      const p=scopes(i);
      if(typeof i.token!=='string'||i.token.length<32||i.token.length>4096||!/^[A-Za-z0-9_:.-]+$/.test(i.token)||
         !['en','si','ta'].includes(i.locale)||i.platform!=='android'||(provider.kind==='local'&&!i.token.startsWith('local-')))fail('invalid-request');
      const deviceId=hash(i.token);
      return store.runTransaction(async tx=>{
        await actor(tx,p,i);
        const path=p+'notification_devices/'+deviceId,old=await tx.get(path);
        if(old?.enabled&&old.uid===i.actorUid&&old.locale===i.locale&&old.provider===provider.kind)return {deviceId,generation:old.generation,provider:provider.kind};
        const countPath=p+'notification_device_counts/'+i.actorUid,count=await tx.get(countPath);
        const oldCountPath=old?.enabled&&old.uid!==i.actorUid?p+'notification_device_counts/'+old.uid:null;
        const oldCount=oldCountPath?await tx.get(oldCountPath):null;
        const adding=!old?.enabled||old.uid!==i.actorUid;
        if(adding&&(count?.active??0)>=8)fail('device-limit');
        // Possession of the opaque registration token permits rebinding after an
        // account switch. Tokens and registry documents are never public.
        const generation=(old?.generation??0)+1;
        tx.set(path,{uid:i.actorUid,token:i.token,locale:i.locale,platform:i.platform,provider:provider.kind,
          enabled:true,generation,updatedAt:now()});
        if(adding)tx.set(countPath,{active:(count?.active??0)+1});
        if(oldCountPath)tx.set(oldCountPath,{active:Math.max(0,(oldCount?.active??0)-1)});
        return {deviceId,generation,provider:provider.kind};
      });
    },
    async remove(i){
      const p=scopes(i);if(!id(i.deviceId))fail('invalid-request');
      await store.runTransaction(async tx=>{
        await actor(tx,p,i);const path=p+'notification_devices/'+i.deviceId,d=await tx.get(path);
        const countPath=p+'notification_device_counts/'+i.actorUid,count=await tx.get(countPath);
        if(d?.uid===i.actorUid&&d.enabled){tx.update(path,{enabled:false,updatedAt:now()});tx.set(countPath,{active:Math.max(0,(count?.active??0)-1)});}
      });return {removed:true};
    },
    async open(i){
      const p=scopes(i);if(!id(i.eventId))fail('invalid-request');
      const event=await store.runTransaction(async tx=>{
        await actor(tx,p,i);const e=await tx.get(p+'push_events/'+i.eventId);
        if(!e||e.uid!==i.actorUid)fail('notification-unavailable');return e;
      });
      // A stale tray item never grants access. Reconcile against today's run,
      // driver, route/access/lock and stop progress before returning any details.
      const result=await assistance.get({scope:i.scope,actorUid:i.actorUid,requestId:event.requestId});
      if(result.request.driverId!==i.actorUid||result.request.assignmentVersion!==event.assignmentVersion||
         !['pending','acknowledged'].includes(result.request.status))fail('notification-unavailable');
      return result;
    },
    async dispatch(i){
      const p=scopes(i);if(!id(i.requestId)||!Number.isInteger(i.assignmentVersion)||i.assignmentVersion<1)fail('invalid-request');
      const path=`${p}notification_outbox/${i.requestId}/events/assistance-${i.assignmentVersion}`,eventId=hash(path);
      const source=await store.runTransaction(tx=>tx.get(path));
      if(!source||source.kind!=='boarding-assistance'||source.pushState==null||['simulated','provider-accepted','skipped','failed'].includes(source.pushState))return;
      let r;
      try{r=await target(i);}catch(e){if(e?.code!=='assistance-unavailable')throw e;r=null;}
      if(!r||r.driverId!==source.uid){
        await store.runTransaction(async tx=>{const e=await tx.get(path);if(e)tx.update(path,{pushState:'skipped',pushReason:'no-longer-current'});});return;
      }
      // Maximum eight devices are dispatched in one page. The cursor is stored
      // on the source event, so a user with many devices cannot starve the scan.
      const devices=await store.page({collection:p+'notification_devices',filters:[['uid','==',r.driverId],['enabled','==',true],['provider','==',provider.kind]],after:source.pushCursor??null,limit:8});
      if(!devices.length&&source.pushCursor==null){
        await store.runTransaction(async tx=>{await tx.get(path);tx.update(path,{pushState:'retry',pushReason:'no-device',nextAttemptAt:new Date(+now()+60000)});});return;
      }
      let pending=false,failed=false;
      for(const row of devices){
        const attemptId=hash(eventId+':'+row.id+':'+row.data.generation),attemptPath=p+'push_attempts/'+attemptId,lease=randomUUID();
        const claim=await store.runTransaction(async tx=>{
          const [attempt,device]=await Promise.all([tx.get(attemptPath),tx.get(p+'notification_devices/'+row.id)]);
          if(!device?.enabled||device.uid!==r.driverId||device.generation!==row.data.generation)return 'obsolete';
          if(['simulated','provider-accepted','skipped'].includes(attempt?.state))return 'done';
          if(attempt?.state==='failed')return 'failed';
          if(date(attempt?.leaseUntil)>now()||date(attempt?.nextAttemptAt)>now())return 'pending';
          if((attempt?.attempts??0)>=5){tx.set(attemptPath,{...attempt,state:'failed',reason:'retry-limit'});return 'failed';}
          tx.set(attemptPath,{eventId,deviceId:row.id,generation:device.generation,state:'sending',lease,
            leaseUntil:new Date(+now()+30000),attempts:(attempt?.attempts??0)+1});
          tx.set(p+'push_events/'+eventId,{uid:r.driverId,requestId:i.requestId,assignmentVersion:i.assignmentVersion,createdAt:date(source.createdAt)??now()});
          return 'send';
        });
        if(claim==='pending'){pending=true;continue;}if(claim==='failed'){failed=true;continue;}if(claim!=='send')continue;
        let outcome,reason=null;
        try{
          const current=await target(i);
          const device=await store.runTransaction(tx=>tx.get(p+'notification_devices/'+row.id));
          if(!current||current.driverId!==r.driverId||device?.uid!==r.driverId||!device.enabled||device.generation!==row.data.generation){outcome='skipped';}
          else {
            await provider.send({scope:i.scope,token:device.token,eventId,locale:device.locale,expiresAt:new Date(current.expiresAt),dedupeKey:attemptId});
            outcome=provider.kind==='local'?'simulated':'provider-accepted';
          }
        }catch(e){
          reason=e?.code==='expired'?'expired':e?.code==='invalid-token'?'invalid-token':'provider-unavailable';outcome=reason==='expired'?'skipped':reason==='invalid-token'?'failed':'retry';
        }
        await store.runTransaction(async tx=>{
          const [a,d,count]=await Promise.all([tx.get(attemptPath),tx.get(p+'notification_devices/'+row.id),tx.get(p+'notification_device_counts/'+r.driverId)]);
          if(a?.lease!==lease)return;
          const terminal=outcome==='retry'&&a.attempts>=5;
          tx.update(attemptPath,{state:terminal?'failed':outcome,reason:terminal?'retry-limit':reason,leaseUntil:now(),
            nextAttemptAt:new Date(+now()+Math.min(300000,10000*2**a.attempts))});
          if(reason==='invalid-token'&&d?.enabled&&d.uid===r.driverId&&d.generation===row.data.generation){tx.update(p+'notification_devices/'+row.id,{enabled:false,updatedAt:now()});tx.set(p+'notification_device_counts/'+r.driverId,{active:Math.max(0,(count?.active??0)-1)});}
          if(terminal||outcome==='failed')failed=true;else if(outcome==='retry')pending=true;
        });
      }
      await store.runTransaction(async tx=>{
        const current=await tx.get(path);if(!current||['simulated','provider-accepted','skipped','failed'].includes(current.pushState)||(current.pushCursor??null)!==(source.pushCursor??null))return;
        const more=devices.length===8;
        const hadFailure=failed||current.pushHadFailure===true;
        tx.update(path,{pushState:pending?'retry':more?'pending':hadFailure?'failed':provider.kind==='local'?'simulated':'provider-accepted',pushHadFailure:hadFailure,
          pushCursor:pending?source.pushCursor??null:more?devices.at(-1).id:null,
          nextAttemptAt:new Date(+now()+(pending?20000:0))});
      });
    },
  };
}

/** Explicitly simulated provider: no Firebase Messaging or external network. */
export function localNotificationProvider(store){
  return {kind:'local',async send(message){
    const path=scopes(message)+'local_push_receipts/'+message.dedupeKey;
    await store.runTransaction(async tx=>{
      if(!await tx.get(path))tx.create(path,{eventId:message.eventId,simulated:true,createdAt:new Date()});
    });
  }};
}

/** Staged adapter. Construction requires an explicitly supplied trusted Admin
 * Messaging client. Local server never imports/initializes a real FCM client. */
export function fcmNotificationProvider(messaging,{clock=()=>Date.now()}={}){
  if(typeof messaging?.send!=='function')throw Error('invalid-messaging-client');
  const words={en:['Boarding assistance','A passenger has requested assistance. Open the app to review.'],
    si:['මගී සහාය','මගියෙකු සහාය ඉල්ලා ඇත. විස්තර බැලීමට යෙදුම විවෘත කරන්න.'],
    ta:['பயண உதவி','ஒரு பயணி உதவி கோரியுள்ளார். பார்க்க செயலியைத் திறக்கவும்.']};
  return {kind:'fcm',async send(m){
    const [title,body]=words[m.locale]??words.en;
    const ttl=Math.min(300000,+m.expiresAt-clock());if(ttl<=0)throw Object.assign(Error('expired'),{code:'expired'});
    try{const receipt=await messaging.send({token:m.token,notification:{title,body},data:{kind:'boarding-assistance',eventId:m.eventId},
      android:{priority:'high',ttl,collapseKey:m.eventId,notification:{tag:m.eventId,channelId:'assistance_requests'}}});
      if(typeof receipt!=='string'||!receipt.length)throw Error('invalid-provider-receipt');return receipt;}
    catch(e){if(['messaging/registration-token-not-registered','messaging/invalid-registration-token'].includes(e?.code))throw Object.assign(Error('invalid-token'),{code:'invalid-token'});throw Error('provider-unavailable');}
  }};
}
