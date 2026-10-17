import assert from 'node:assert/strict';
import {test} from 'node:test';
import {fcmNotificationProvider} from '../../server/moderation/notifications.mjs';
const time=Date.parse('2026-10-16T10:00:00Z');
const message={token:'opaque-private-token',eventId:'a'.repeat(64),locale:'en',expiresAt:new Date(time+600000)};
test('staged FCM adapter sends generic localized notification, opaque ID and bounded TTL',async()=>{
  for(const locale of ['en','si','ta','unknown']){
    const sent=[];const p=fcmNotificationProvider({async send(v){sent.push(v);return 'provider-id';}},{clock:()=>time});
    assert.equal(await p.send({...message,locale}),'provider-id');
    assert.deepEqual(sent[0].data,{kind:'boarding-assistance',eventId:message.eventId});
    assert.equal(sent[0].token,message.token);assert.equal(sent[0].android.ttl,300000);assert.equal(sent[0].android.notification.tag,message.eventId);
    assert.equal(sent[0].android.notification.channelId,'assistance_requests');
    assert.ok(sent[0].notification.title.length>0);assert.ok(!JSON.stringify(sent[0]).includes('riderId'));
  }
});
test('staged FCM adapter rejects expired work and distinguishes invalid tokens from retryable errors',async()=>{
  let sends=0;const p=fcmNotificationProvider({async send(){sends++;}},{clock:()=>time});
  await assert.rejects(p.send({...message,expiresAt:new Date(time)}),{code:'expired'});assert.equal(sends,0);
  for(const code of ['messaging/registration-token-not-registered','messaging/invalid-registration-token']){
    const invalid=fcmNotificationProvider({async send(){throw {code};}},{clock:()=>time});
    await assert.rejects(invalid.send(message),{code:'invalid-token'});
  }
  const broken=fcmNotificationProvider({async send(){throw Error('contains private token');}},{clock:()=>time});
  await assert.rejects(broken.send(message),e=>e.message==='provider-unavailable');
});
