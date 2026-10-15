import assert from 'node:assert/strict';
import { reconcileReport } from './reward-ledger.mjs';
import { readFileSync } from 'node:fs';
import { before, after, beforeEach, test } from 'node:test';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, collection, getDoc, getDocs, query, where, setDoc, updateDoc, deleteDoc, runTransaction, Timestamp, serverTimestamp, arrayUnion, arrayRemove, increment, writeBatch } from 'firebase/firestore';

let env;
const auth = (uid, claims = {}) => env.authenticatedContext(uid, { email: `${uid}@example.test`, ...claims }).firestore();
const guest = () => env.unauthenticatedContext().firestore();
const ref = (db, path) => doc(db, path);
const stamp = () => Timestamp.fromMillis(Date.now() - 3600000);
const profile = (uid = 'alice') => ({ uid, name: 'Rider', email: `${uid}@example.test`, phone: null,
  role: 'passenger', createdAt: serverTimestamp(), points: 0, reportsSubmitted: 0, verifiedCount: 0 });
const report = (uid = 'alice') => ({ userId: uid, targetType: 'bus', targetId: 'bus1', targetName: 'Bus 1',
  problemType: 'Ramp Broken', severity: 'major', category: 'rampAccess', subCategory: 'Ramp Broken',
  condition: 'barrier', crowdingLevel: 'low', description: '', photoUrl: '', publicationState: 'published',
  isDemo: false, status: 'active', createdAt: serverTimestamp(), lastConfirmedAt: null,
  confirmCount: 0, falseCount: 0, confirmedBy: [], flaggedBy: [] });
const request = (uid = 'alice') => ({ riderId: uid, riderName: 'Rider', busId: 'bus1', routeNo: '1',
  stationId: 's1', stopName: 'Stop 1', assistanceTypes: ['Deploy Ramp'], status: 'pending', createdAt: serverTimestamp() });
const telemetry = () => ({ busId: 'bus1', driverId: 'op', operatorId: 'op', latitude: 6.9, longitude: 79.8,
  speed: 12, timestamp: serverTimestamp(), status: 'active', isBroadcasting: true });

test('sample scope supports reports, assistance and operator writes without granting real approval', async () => {
  const p='sample_test/shared/';
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore();
    await Promise.all([
      setDoc(ref(db,p+'users/alice'),{...profile(),createdAt:stamp()}),
      setDoc(ref(db,p+'users/op'),{...profile('op'),role:'operator',createdAt:stamp()}),
      setDoc(ref(db,p+'operator_access/op'),{approved:true,sampleScenario:true}),
      setDoc(ref(db,'operator_access/op'),{approved:false}),
      setDoc(ref(db,p+'buses/bus1'),{driverId:'op',stops:['s1','s2'],occupancy:'low'}),
      setDoc(ref(db,p+'stations/s1'),{name:'SAMPLE Stop 1'}),
      setDoc(ref(db,p+'stations/s2'),{name:'SAMPLE Stop 2'}),
    ]);
  });
  await assertSucceeds(setDoc(ref(auth('alice'),p+'reports/check'),report()));
  await assertSucceeds(setDoc(ref(auth('alice'),p+'boarding_requests/request'),request()));
  await assertSucceeds(updateDoc(ref(auth('op'),p+'boarding_requests/request'),{status:'acknowledged'}));
  await assertSucceeds(setDoc(ref(auth('op'),p+'live_locations/bus1'),telemetry()));
  await assertFails(setDoc(ref(auth('op'),'live_locations/bus1'),telemetry()));
  await assertFails(updateDoc(ref(auth('op'),'buses/bus1'),{occupancy:'high'}));
  await assertFails(getDoc(ref(auth('op'),p+'users/alice')));
  await assertFails(setDoc(ref(auth('alice'),p+'operator_access/alice'),{approved:true}));
  await assertFails(setDoc(ref(auth('stranger'),p+'reports/stranger'),report('stranger')));
  await assertFails(setDoc(ref(auth('alice'),'boarding_requests/cross_scope'),{...request(),busId:'sample_only_bus'}));
});

before(async () => {
  const projectId = process.env.FIRESTORE_RULES_TEST_PROJECT ?? 'demo-accesstransit';
  if (!projectId.startsWith('demo-')) throw new Error('Rules tests require an isolated demo project.');
  env = await initializeTestEnvironment({ projectId, firestore: {
    host: '127.0.0.1', port: Number(process.env.FIRESTORE_RULES_TEST_PORT ?? 8087), rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8') } });
});
after(async () => { await env?.cleanup(); });

test('published timetables are readable and saveable but cannot be claimed or broadcast', async () => {
  await env.withSecurityRulesDisabled(async c => {
    await updateDoc(ref(c.firestore(), 'buses/bus1'), {catalogueRecordType:'published_timetable'});
    await updateDoc(ref(c.firestore(), 'buses/bus2'), {catalogueRecordType:'published_timetable'});
  });
  await assertSucceeds(getDoc(ref(guest(), 'buses/bus1')));
  await assertSucceeds(setDoc(ref(auth('alice'), 'journeys/published'), {
    journeyId:'published', passengerId:'alice', busId:'bus1', origin:'Stop 1', destination:'Stop 2',
    status:'confirmed', createdAt:serverTimestamp(),
  }));
  await assertFails(updateDoc(ref(auth('op'), 'buses/bus2'), {driverId:'op'}));
  await assertFails(updateDoc(ref(auth('op'), 'buses/bus1'), {occupancy:'high'}));
  await assertFails(setDoc(ref(auth('op'), 'live_locations/bus1'), telemetry()));
});

test('published timetables cannot receive vehicle equipment reports or assistance', async () => {
  await env.withSecurityRulesDisabled(async c => {
    await updateDoc(ref(c.firestore(), 'buses/bus1'), {catalogueRecordType:'published_timetable'});
  });
  await assertFails(setDoc(ref(auth('alice'), 'boarding_requests/published'), request()));
  await assertFails(setDoc(ref(auth('alice'), 'reports/published'), report()));
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    await Promise.all([
      setDoc(ref(db, 'users/alice'), { ...profile(), createdAt: stamp() }),
      setDoc(ref(db, 'users/op'), { ...profile('op'), role: 'operator', createdAt: stamp() }),
      setDoc(ref(db, 'buses/bus1'), { driverId: 'op', rampOk: true, occupancy: 'low', stops: ['s1', 's2'] }),
      setDoc(ref(db, 'buses/bus2'), { driverId: null, rampOk: true, occupancy: 'low', stops: ['s1', 's2'] }),
      setDoc(ref(db, 'stations/s1'), { name: 'Stop 1' }), setDoc(ref(db, 'stations/s2'), { name: 'Stop 2' }),
      setDoc(ref(db, 'routes/route1'), { stops: ['s1', 's2'] }),
      setDoc(ref(db, 'operator_access/op'), { approved: true }),
      setDoc(ref(db, 'operator_access/otherop'), { approved: true }),
      setDoc(ref(db, 'reports/r1'), { ...report(), createdAt: stamp() }),
      setDoc(ref(db, 'boarding_requests/a1'), { ...request(), createdAt: stamp() }),
      setDoc(ref(db, 'journeys/j1'), { journeyId: 'j1', passengerId: 'alice', busId: 'bus1',
        origin: 'Stop 1', destination: 'Stop 2', status: 'confirmed', createdAt: stamp() }),
    ]);
  });
});

test('public catalogue and reports remain readable without sign-in', async () => {
  for (const path of ['buses/bus1', 'stations/s1', 'routes/route1', 'reports/r1'])
    await assertSucceeds(getDoc(ref(guest(), path)));
});
test('unknown collections and every unauthenticated write are denied', async () => {
  await assertFails(setDoc(ref(guest(), 'reports/new'), report()));
  await assertFails(setDoc(ref(auth('alice'), 'unknown/document'), { value: 1 }));
  await assertFails(getDoc(ref(guest(), 'unknown/document')));
});
test('profiles are private: owner allowed, other account and guest denied', async () => {
  await assertSucceeds(getDoc(ref(auth('alice'), 'users/alice')));
  await assertFails(getDoc(ref(auth('bob'), 'users/alice')));
  await assertFails(getDoc(ref(guest(), 'users/alice')));
  await assertFails(getDocs(collection(auth('alice'), 'users')));
});
test('profile creation binds UID/email and initializes untrusted counters to zero', async () => {
  await assertSucceeds(setDoc(ref(auth('bob'), 'users/bob'), profile('bob')));
  await assertFails(setDoc(ref(auth('carol'), 'users/dave'), profile('dave')));
  await assertFails(setDoc(ref(auth('carol'), 'users/carol'), { ...profile('carol'), points: 999 }));
  await assertFails(setDoc(ref(auth('carol'), 'users/carol'), { ...profile('carol'), email: 'other@example.test' }));
});
test('profile edits cannot change role, counters, creation time or UID', async () => {
  const alice = auth('alice');
  await assertSucceeds(updateDoc(ref(alice, 'users/alice'), { name: 'New display name', phone: '123' }));
  for (const fields of [{ role: 'operator' }, { points: 10 }, { verifiedCount: 5 }, { reportsSubmitted: 3 },
    { uid: 'bob' }, { createdAt: serverTimestamp() }, { admin: true }])
    await assertFails(updateDoc(ref(alice, 'users/alice'), fields));
  await assertFails(updateDoc(ref(auth('bob'), 'users/alice'), { name: 'Impersonated' }));
});
test('approval cannot be self-granted through profile or access record', async () => {
  await assertFails(setDoc(ref(auth('alice'), 'operator_access/alice'), { approved: true }));
  await assertFails(updateDoc(ref(auth('op'), 'operator_access/op'), { approved: true, admin: true }));
  await assertSucceeds(getDoc(ref(auth('op'), 'operator_access/op')));
  await assertFails(getDoc(ref(auth('alice'), 'operator_access/op')));
});
test('self-selected operator profile does not grant operations permission', async () => {
  await assertSucceeds(setDoc(ref(auth('bob'), 'users/bob'), { ...profile('bob'), role: 'operator' }));
  await assertFails(updateDoc(ref(auth('bob'), 'buses/bus2'), { driverId: 'bob' }));
});
test('only approved assigned operators can update bus conditions', async () => {
  await assertSucceeds(updateDoc(ref(auth('op'), 'buses/bus1'), { rampOk: false, occupancy: 'high', rampCheckedAt: serverTimestamp(), rampCheckedBy: 'op' }));
  await assertFails(updateDoc(ref(auth('alice'), 'buses/bus1'), { rampOk: false }));
  await assertFails(updateDoc(ref(auth('otherop'), 'buses/bus1'), { rampOk: false }));
  await assertFails(updateDoc(ref(auth('op'), 'buses/bus1'), { occupancy: 'invented' }));
  await assertFails(updateDoc(ref(auth('op'), 'buses/bus1'), { stops: ['s2'] }));
});
test('approved operators can claim unassigned buses but cannot take over assigned buses', async () => {
  await assertSucceeds(updateDoc(ref(auth('otherop'), 'buses/bus2'), { driverId: 'otherop' }));
  await assertFails(updateDoc(ref(auth('otherop'), 'buses/bus1'), { driverId: 'otherop' }));
  await assertFails(updateDoc(ref(auth('op'), 'buses/bus1'), { driverId: 'alice' }));
});
test('catalogue writes require a trusted admin claim', async () => {
  await assertFails(setDoc(ref(auth('op'), 'stations/new'), { name: 'New stop' }));
  await assertSucceeds(setDoc(ref(auth('admin', { admin: true }), 'stations/new'), { name: 'New stop' }));
});
test('telemetry rejects passenger, wrong operator, spoofed driver and invalid coordinates', async () => {
  await assertSucceeds(setDoc(ref(auth('op'), 'live_locations/bus1'), telemetry()));
  await assertFails(setDoc(ref(auth('alice'), 'live_locations/bus1'), { ...telemetry(), driverId: 'alice', operatorId: 'alice' }));
  await assertFails(updateDoc(ref(auth('otherop'), 'live_locations/bus1'), { speed: 20 }));
  await assertFails(updateDoc(ref(auth('op'), 'live_locations/bus1'), { driverId: 'bob' }));
  await assertFails(updateDoc(ref(auth('op'), 'live_locations/bus1'), { latitude: 999 }));
  await assertFails(updateDoc(ref(auth('op'), 'live_locations/bus1'), { timestamp: Timestamp.fromMillis(Date.now() + 3600000) }));
});
test('journeys are owner-scoped and query constraints enforce privacy', async () => {
  await assertSucceeds(getDoc(ref(auth('alice'), 'journeys/j1')));
  await assertFails(getDoc(ref(auth('bob'), 'journeys/j1')));
  await assertSucceeds(getDocs(query(collection(auth('alice'), 'journeys'), where('passengerId', '==', 'alice'))));
  await assertFails(getDocs(collection(auth('alice'), 'journeys')));
  await assertSucceeds(updateDoc(ref(auth('alice'), 'journeys/j1'), { status: 'completed' }));
  await assertFails(updateDoc(ref(auth('alice'), 'journeys/j1'), { passengerId: 'bob' }));
});
test('journey creation validates ownership, target and document ID', async () => {
  const journey = { journeyId: 'new', passengerId: 'alice', routeId: 'route1', routeNumber: '1', routeTitle: 'Route 1',
    busId: 'bus1', origin: 'Stop 1', destination: 'Stop 2', status: 'confirmed', createdAt: serverTimestamp() };
  await assertSucceeds(setDoc(ref(auth('alice'), 'journeys/new'), journey));
  await assertFails(setDoc(ref(auth('bob'), 'journeys/other'), { ...journey, journeyId: 'other' }));
  await assertFails(setDoc(ref(auth('alice'), 'journeys/missing'), { ...journey, journeyId: 'missing', busId: 'absent' }));
});
test('published reports require their real author, known target and no fabricated confirmations', async () => {
  await assertSucceeds(setDoc(ref(auth('alice'), 'reports/new'), report()));
  for (const fields of [{ userId: 'bob' }, { targetId: 'missing' }, { confirmCount: 1, confirmedBy: ['bob'] },
    { lastConfirmedAt: serverTimestamp() }, { isDemo: true }, { publicationState: 'pendingUpload' },
    { photoUrl: 'file:///private/photo.jpg' }, { extra: true }])
    await assertFails(setDoc(ref(auth('alice'), 'reports/bad'), { ...report(), ...fields }));
});

test('saved journey transaction preserves endpoint/date/time selection and retry is read-only', async () => {
  const db = auth('alice');
  const target = ref(db, 'journeys/stable');
  const selection = { journeyId: 'stable', passengerId: 'alice', routeId: 'route1', routeNumber: '1', routeTitle: 'Route 1',
    busId: 'bus1', busNo: 'Plate 1', origin: 'Stop 1', destination: 'Stop 2', fromStationId: 's1', toStationId: 's2',
    selectedDate: Timestamp.fromMillis(1792022400000), selectedTimeMinutes: 540, departureAt: Timestamp.fromMillis(1792055400000),
    durationMinutes: 20, estimatedFareLkr: 70, wheelchairAccessRequired: true, stepFreeOnly: true,
    status: 'confirmed', createdAt: serverTimestamp() };
  const publish = () => runTransaction(db, async transaction => {
    const existing = await transaction.get(target);
    if (existing.exists()) return existing.data();
    transaction.set(target, selection);
    return selection;
  });
  await assertSucceeds(publish());
  await assertSucceeds(updateDoc(target, { status: 'completed' }));
  const restored = await assertSucceeds(publish());
  if (restored.status !== 'completed' || restored.fromStationId !== 's1' || restored.toStationId !== 's2' || restored.selectedTimeMinutes !== 540)
    throw new Error('Retry must preserve saved identity/selection and terminal status');
  await assertFails(updateDoc(target, { fromStationId: 's2' }));
  const otherDb = auth('bob');
  await assertFails(runTransaction(otherDb, transaction => transaction.get(ref(otherDb, 'journeys/stable'))));
});

test('new journey selection rejects incomplete target, invalid time and inconsistent stops', async () => {
  const base = { journeyId: 'invalid', passengerId: 'alice', busId: 'bus1', origin: 'Stop 1', destination: 'Stop 2',
    fromStationId: 's1', toStationId: 's2', selectedDate: stamp(), departureAt: stamp(), durationMinutes: 20,
    estimatedFareLkr: 70, wheelchairAccessRequired: false, stepFreeOnly: false, status: 'confirmed', createdAt: serverTimestamp() };
  await assertSucceeds(setDoc(ref(auth('alice'), 'journeys/invalid'), base));
  for (const fields of [{fromStationId: 'missing'}, {toStationId: 's1'}, {selectedTimeMinutes: 1440},
    {durationMinutes: 0}, {selectedDate: 'today'}, {departureAt: null}]) {
    await assertFails(setDoc(ref(auth('alice'), 'journeys/bad'), {...base, journeyId: 'bad', ...fields}));
  }
  await assertFails(getDoc(ref(guest(), 'journeys/missing')));
});
test('another rider can confirm only their own vote at server time', async () => {
  await assertSucceeds(updateDoc(ref(auth('bob'), 'reports/r1'), { confirmedBy: ['bob'], confirmCount: 1, lastConfirmedAt: serverTimestamp() }));
  await assertFails(updateDoc(ref(auth('carol'), 'reports/r1'), { confirmedBy: ['bob', 'forged'], confirmCount: 2, lastConfirmedAt: serverTimestamp() }));
  await assertFails(updateDoc(ref(auth('carol'), 'reports/r1'), { confirmedBy: ['carol'], confirmCount: 1, lastConfirmedAt: serverTimestamp() }));
  await assertFails(updateDoc(ref(auth('alice'), 'reports/r1'), { confirmedBy: ['bob', 'alice'], confirmCount: 2, lastConfirmedAt: serverTimestamp() }));
});
test('votes reject duplicate IDs, invented counts and cross-account modification', async () => {
  await assertFails(updateDoc(ref(auth('bob'), 'reports/r1'), { confirmedBy: ['bob', 'bob'], confirmCount: 2, lastConfirmedAt: serverTimestamp() }));
  await assertFails(updateDoc(ref(auth('bob'), 'reports/r1'), { confirmedBy: ['bob'], confirmCount: 99, lastConfirmedAt: serverTimestamp() }));
  await assertFails(updateDoc(ref(auth('bob'), 'reports/r1'), { description: 'Changed by voter' }));
});
test('flagging and changing your own flag to confirmation preserve other votes', async () => {
  await assertSucceeds(updateDoc(ref(auth('bob'), 'reports/r1'), { flaggedBy: ['bob'], falseCount: 1 }));
  await assertSucceeds(updateDoc(ref(auth('carol'), 'reports/r1'), { flaggedBy: ['bob', 'carol'], falseCount: 2 }));
  await assertSucceeds(updateDoc(ref(auth('bob'), 'reports/r1'), { flaggedBy: ['carol'], falseCount: 1,
    confirmedBy: ['bob'], confirmCount: 1, lastConfirmedAt: serverTimestamp() }));
});
const resolve = (db, uid, id = 'r1') => runTransaction(db, async tx => {
  const target = ref(db, `reports/${id}`);
  const r = (await tx.get(target)).data();
  if (r.status === 'resolved') return;
  tx.update(target, {status:'resolved', resolvedBy:uid, resolvedAt:serverTimestamp()});
  tx.set(ref(db, `report_resolutions/${id}`), {reportId:id, resolvedBy:uid, resolvedAt:serverTimestamp(),
    targetType:r.targetType, targetId:r.targetId, problemType:r.problemType, category:r.category,
    previousStatus:'active', status:'resolved'});
});
const vote = (db, uid, confirm, id = 'r1') => runTransaction(db, async tx => {
  const target = ref(db, `reports/${id}`);
  const r = (await tx.get(target)).data();
  if ((confirm ? r.confirmedBy : r.flaggedBy).includes(uid)) return;
  const confirmed = r.confirmedBy.filter(x => x !== uid);
  const flagged = r.flaggedBy.filter(x => x !== uid);
  (confirm ? confirmed : flagged).push(uid);
  const update = {confirmedBy:confirm ? arrayUnion(uid) : arrayRemove(uid), flaggedBy:confirm ? arrayRemove(uid) : arrayUnion(uid)};
  if (confirm) {
    update.confirmCount = increment(1); update.lastConfirmedAt = serverTimestamp();
    if (r.flaggedBy.includes(uid)) update.falseCount = increment(-1);
  } else {
    update.falseCount = increment(1);
    if (r.confirmedBy.includes(uid)) { update.confirmCount = increment(-1); update.lastConfirmedAt = null; }
  }
  if (flagged.length === 3) update.status = 'hidden';
  tx.update(target, update);
});
test('only the report owner can resolve with an atomic history record', async () => {
  await assertFails(updateDoc(ref(auth('bob'), 'reports/r1'), {status:'resolved'}));
  await assertFails(updateDoc(ref(auth('alice'), 'reports/r1'), {status:'resolved'}));
  await assertFails(deleteDoc(ref(auth('bob'), 'reports/r1')));
  await assertFails(resolve(auth('bob'), 'bob'));
  await assertSucceeds(resolve(auth('alice'), 'alice'));
});
test('third independent flag hides atomically; ordinary voters cannot delete', async () => {
  await assertSucceeds(vote(auth('bob'), 'bob', false));
  await assertSucceeds(vote(auth('carol'), 'carol', false));
  await assertFails(deleteDoc(ref(auth('bob'), 'reports/r1')));
  await assertFails(deleteDoc(ref(guest(), 'reports/r1')));
  await assertFails(deleteDoc(ref(auth('dave'), 'reports/r1')));
  await assertFails(updateDoc(ref(auth('bob'), 'reports/r1'), {status:'hidden'}));
  await assertSucceeds(vote(auth('dave'), 'dave', false));
  const r = (await getDoc(ref(auth('dave'), 'reports/r1'))).data();
  if (r.status !== 'hidden' || r.falseCount !== 3 || r.flaggedBy.length !== 3) throw new Error('Hidden report must retain three independent flags');
});
test('concurrent transactions preserve both voters; duplicate retry does not refresh time', async () => {
  await assertSucceeds(Promise.all([vote(auth('bob'), 'bob', true), vote(auth('carol'), 'carol', true)]));
  const first = (await getDoc(ref(auth('bob'), 'reports/r1'))).data();
  if (first.confirmCount !== 2 || !first.confirmedBy.includes('bob') || !first.confirmedBy.includes('carol')) throw new Error('Concurrent vote lost');
  await assertSucceeds(vote(auth('bob'), 'bob', true));
  const retried = (await getDoc(ref(auth('bob'), 'reports/r1'))).data();
  if (retried.confirmCount !== 2 || !retried.lastConfirmedAt.isEqual(first.lastConfirmedAt)) throw new Error('Duplicate retry changed totals/time');
  await assertSucceeds(vote(auth('bob'), 'bob', false));
  const reversed = (await getDoc(ref(auth('bob'), 'reports/r1'))).data();
  if (reversed.confirmCount !== 1 || reversed.confirmedBy[0] !== 'carol' || reversed.lastConfirmedAt !== null) throw new Error('Reversal lost another vote or invented check time');
});
test('resolution history is atomic, immutable and survives report removal', async () => {
  const db = auth('alice');
  await assertSucceeds(resolve(db, 'alice'));
  const record = ref(db, 'report_resolutions/r1');
  const event = (await assertSucceeds(getDoc(record))).data();
  const r = (await getDoc(ref(db, 'reports/r1'))).data();
  if (event.resolvedBy !== 'alice' || event.targetId !== 'bus1' || event.problemType !== 'Ramp Broken' || !event.resolvedAt.isEqual(r.resolvedAt)) throw new Error('Missing resolution evidence');
  await assertSucceeds(resolve(db, 'alice'));
  await assertFails(updateDoc(record, {resolvedBy:'bob'}));
  await assertFails(deleteDoc(record));
  await assertSucceeds(deleteDoc(ref(db, 'reports/r1')));
  await assertSucceeds(getDoc(record));
});
test('resolution events cannot be created independently or forge another condition', async () => {
  const db = auth('alice');
  const event = {reportId:'r1', resolvedBy:'alice', resolvedAt:serverTimestamp(), targetType:'bus', targetId:'bus1',
    problemType:'Ramp Broken', category:'rampAccess', previousStatus:'active', status:'resolved'};
  await assertFails(setDoc(ref(db, 'report_resolutions/r1'), event));
  await assertFails(runTransaction(db, async tx => {
    await tx.get(ref(db, 'reports/r1'));
    tx.update(ref(db, 'reports/r1'), {status:'resolved', resolvedBy:'alice', resolvedAt:serverTimestamp()});
    tx.set(ref(db, 'report_resolutions/r1'), {...event, problemType:'A different condition'});
  }));
});
test('assistance requests bind rider identity, actual stop and pending state', async () => {
  await assertSucceeds(setDoc(ref(auth('alice'), 'boarding_requests/new'), request()));
  for (const fields of [{ riderId: 'bob' }, { stationId: 'not-on-route' }, { status: 'completed' },
    { assistanceTypes: ['Invented'] }, { assistanceTypes: [] }])
    await assertFails(setDoc(ref(auth('alice'), 'boarding_requests/bad'), { ...request(), ...fields }));
  await assertFails(setDoc(ref(guest(), 'boarding_requests/guest'), request('guest_rider')));
});
test('alighting purpose accepts getting-off help without allowing mismatched help types', async () => {
  await assertSucceeds(setDoc(ref(auth('alice'), 'boarding_requests/alight'), {
    ...request(), purpose: 'alighting', assistanceTypes: ['Alighting Help', 'Extra Time'] }));
  await assertFails(setDoc(ref(auth('alice'), 'boarding_requests/mismatch'), {
    ...request(), purpose: 'boarding', assistanceTypes: ['Alighting Help'] }));
  await assertFails(setDoc(ref(auth('alice'), 'boarding_requests/badpurpose'), {
    ...request(), purpose: 'invented' }));
});
test('assistance reads permit the rider and assigned operator, not other accounts', async () => {
  await assertSucceeds(getDoc(ref(auth('alice'), 'boarding_requests/a1')));
  await assertSucceeds(getDoc(ref(auth('op'), 'boarding_requests/a1')));
  await assertSucceeds(getDocs(query(collection(auth('op'), 'boarding_requests'), where('busId', '==', 'bus1'))));
  await assertFails(getDoc(ref(auth('bob'), 'boarding_requests/a1')));
  await assertFails(getDoc(ref(auth('otherop'), 'boarding_requests/a1')));
});

test('assistance transaction creates a missing ID and retry preserves driver acknowledgement', async () => {
  const db = auth('alice');
  const target = ref(db, 'boarding_requests/stable_retry');
  const publish = () => runTransaction(db, async transaction => {
    const existing = await transaction.get(target);
    if (existing.exists()) return existing.data().status;
    transaction.set(target, { ...request(), purpose: 'boarding' });
    return 'pending';
  });
  await assertSucceeds(publish());
  await assertSucceeds(updateDoc(ref(auth('op'), 'boarding_requests/stable_retry'), { status: 'acknowledged' }));
  const status = await assertSucceeds(publish());
  if (status !== 'acknowledged') throw new Error('Retry must preserve driver acknowledgement');
  const otherDb = auth('bob');
  await assertFails(runTransaction(otherDb, async transaction => {
    await transaction.get(ref(otherDb, 'boarding_requests/stable_retry'));
  }));
  await assertFails(getDoc(ref(guest(), 'boarding_requests/missing')));
});

test('passenger history queries are owner scoped; driver decline closes pending request', async () => {
  await assertSucceeds(getDocs(query(collection(auth('alice'), 'boarding_requests'), where('riderId', '==', 'alice'))));
  await assertFails(getDocs(query(collection(auth('bob'), 'boarding_requests'), where('riderId', '==', 'alice'))));
  await assertFails(getDocs(collection(auth('alice'), 'boarding_requests')));
  await assertSucceeds(updateDoc(ref(auth('op'), 'boarding_requests/a1'), { status: 'rejected' }));
  await assertFails(updateDoc(ref(auth('op'), 'boarding_requests/a1'), { status: 'acknowledged' }));
});
test('only assigned driver can acknowledge/complete and transition order is enforced', async () => {
  await assertFails(updateDoc(ref(auth('alice'), 'boarding_requests/a1'), { status: 'acknowledged' }));
  await assertFails(updateDoc(ref(auth('otherop'), 'boarding_requests/a1'), { status: 'acknowledged' }));
  await assertFails(updateDoc(ref(auth('op'), 'boarding_requests/a1'), { status: 'completed' }));
  await assertSucceeds(updateDoc(ref(auth('op'), 'boarding_requests/a1'), { status: 'acknowledged' }));
  await assertSucceeds(updateDoc(ref(auth('op'), 'boarding_requests/a1'), { status: 'completed' }));
  await assertFails(updateDoc(ref(auth('op'), 'boarding_requests/a1'), { status: 'pending' }));
});
test('rider cancellation cannot alter request destination/identity', async () => {
  await assertSucceeds(updateDoc(ref(auth('alice'), 'boarding_requests/a1'), { status: 'cancelled' }));
  await assertFails(updateDoc(ref(auth('alice'), 'boarding_requests/a1'), { busId: 'bus2' }));
});
test('trips are created/updated only by their assigned approved operator', async () => {
  const trip = { tripId: 't1', busId: 'bus1', driverId: 'op', createdAt: serverTimestamp(), status: 'in_progress',
    stops: ['s1', 's2'], stopTimes: {}, currentStopIndex: 0 };
  await assertSucceeds(setDoc(ref(auth('op'), 'trips/t1'), trip));
  await assertFails(updateDoc(ref(auth('alice'), 'trips/t1'), { status: 'completed' }));
  await assertFails(updateDoc(ref(auth('otherop'), 'trips/t1'), { status: 'completed' }));
  await assertFails(updateDoc(ref(auth('op'), 'trips/t1'), { driverId: 'bob' }));
  await assertSucceeds(updateDoc(ref(auth('op'), 'trips/t1'), { status: 'completed' }));
});


// Operator transaction shape matches TripService's linked start/completion writes.
for (const stops of [['s1', 's2'], ['s1', 'middle1', 'middle2', 's2']]) {
  test(`linked ${stops.length}-stop trip completes on terminal arrival and closes broadcasting`, async () => {
    const db = auth('op');
    const tripRef = ref(db, 'trips/f17-trip');
    const liveRef = ref(db, 'live_locations/bus1');
    await assertSucceeds(runTransaction(db, async tx => {
      await tx.get(tripRef); await tx.get(liveRef);
      tx.set(tripRef, { tripId: 'f17-trip', busId: 'bus1', driverId: 'op',
        routeNo: '1', stops, status: 'in_progress',
        currentStopIndex: 0, stopTimes: {}, createdAt: serverTimestamp() });
      tx.set(liveRef, { ...telemetry(), tripId: 'f17-trip' });
    }));
    const arrivals = {};
    for (let index = 1; index < stops.length; index++) {
      const final = index === stops.length - 1;
      const arrival = Timestamp.fromMillis(Date.now() - (stops.length - index) * 1000);
      arrivals[stops[index]] = { estimatedArrival: arrival, actualArrival: arrival };
      await assertSucceeds(runTransaction(db, async tx => {
        await tx.get(tripRef); await tx.get(liveRef);
        tx.update(tripRef, { status: final ? 'completed' : 'in_progress',
          currentStopIndex: index, stopTimes: { ...arrivals } });
        tx.update(liveRef, { currentStopIndex: index, nextStop: stops[Math.min(index + 1, stops.length - 1)],
          ...(final ? { status: 'completed', isBroadcasting: false, addedDelayMinutes: 0 } : {}) });
      }));
      const trip = (await getDoc(tripRef)).data();
      const live = (await getDoc(liveRef)).data();
      assert.equal(trip.status, final ? 'completed' : 'in_progress');
      assert.equal(live.isBroadcasting, !final);
      for (const [stop, time] of Object.entries(arrivals))
        assert.equal(trip.stopTimes[stop].actualArrival.toMillis(), time.actualArrival.toMillis());
    }
    const persisted = (await getDoc(tripRef)).data();
    assert.equal(persisted.currentStopIndex, stops.length - 1);
    assert.equal((await getDoc(liveRef)).data().nextStop, stops.at(-1));
  });
}

test('a denied timeline write rolls back telemetry in the same transaction', async () => {
  const db = auth('op');
  await setDoc(ref(db, 'live_locations/bus1'), telemetry());
  await assertFails(runTransaction(db, async tx => {
    await tx.get(ref(db, 'live_locations/bus1'));
    tx.update(ref(db, 'live_locations/bus1'), {status: 'completed', isBroadcasting: false});
    tx.set(ref(db, 'trips/f08-denied'), {tripId: 'f08-denied', busId: 'bus2',
      driverId: 'op', status: 'in_progress', createdAt: serverTimestamp()});
  }));
  assert.equal((await getDoc(ref(db, 'live_locations/bus1'))).data().isBroadcasting, true);
  assert.equal((await getDoc(ref(db, 'trips/f08-denied'))).exists(), false);
});


test('claim cannot combine equipment edits or release an assignment', async () => {
  await assertFails(updateDoc(ref(auth('otherop'), 'buses/bus2'), { driverId: 'otherop', occupancy: 'high' }));
  await assertFails(updateDoc(ref(auth('op'), 'buses/bus1'), { driverId: null }));
  await assertFails(updateDoc(ref(auth('op'), 'buses/bus1'), { driverId: '' }));
  await assertSucceeds(updateDoc(ref(auth('otherop'), 'buses/bus2'), { driverId: 'otherop' }));
  await assertSucceeds(updateDoc(ref(auth('otherop'), 'buses/bus2'), { rampOk: false, rampCheckedAt: serverTimestamp(), rampCheckedBy: 'otherop' }));
});

test('concurrent claims have one winner and revoked operators lose write permission', async () => {
  const claim = (uid) => {
    const db = auth(uid);
    return runTransaction(db, async tx => {
      const bus = ref(db, 'buses/bus2');
      const snap = await tx.get(bus);
      if (snap.data().driverId) throw Error('already assigned');
      tx.update(bus, { driverId: uid });
    });
  };
  const results = await Promise.allSettled([claim('op'), claim('otherop')]);
  assert.equal(results.filter(result => result.status === 'fulfilled').length, 1);
  const adminDb = auth('admin', { admin: true });
  await updateDoc(ref(adminDb, 'operator_access/op'), { approved: false });
  await assertFails(updateDoc(ref(auth('op'), 'buses/bus1'), { rampOk: false }));
  await assertFails(setDoc(ref(auth('op'), 'live_locations/bus1'), telemetry()));
});


test('ramp checks bind actor and server time while occupancy cannot refresh evidence', async () => {
  const db = auth('op');
  const bus = ref(db, 'buses/bus1');
  await assertFails(updateDoc(bus, { rampOk: false }));
  await assertFails(updateDoc(bus, { rampOk: false, rampCheckedAt: serverTimestamp(), rampCheckedBy: 'otherop' }));
  await assertFails(updateDoc(bus, { rampOk: false, rampCheckedAt: stamp(), rampCheckedBy: 'op' }));
  await assertSucceeds(updateDoc(bus, { rampOk: false, rampCheckedAt: serverTimestamp(), rampCheckedBy: 'op' }));
  const before = (await getDoc(bus)).data();
  await assertSucceeds(updateDoc(bus, { occupancy: 'high' }));
  const after = (await getDoc(bus)).data();
  assert.equal(after.rampCheckedAt.toMillis(), before.rampCheckedAt.toMillis());
  assert.equal(after.rampCheckedBy, 'op');
  await assertFails(updateDoc(bus, { rampCheckedBy: 'forged' }));
});


test('marked demonstration targets cannot receive real reports, assistance or operator writes', async () => {
  const adminDb = auth('admin', { admin: true });
  await updateDoc(ref(adminDb, 'buses/bus1'), { isDemo: true, catalogueSource: 'demo' });
  await assertFails(setDoc(ref(auth('alice'), 'reports/demo-bus'), report()));
  await assertFails(setDoc(ref(auth('alice'), 'boarding_requests/demo-bus'), request()));
  await assertFails(setDoc(ref(auth('op'), 'live_locations/bus1'), telemetry()));
  await assertFails(updateDoc(ref(auth('op'), 'buses/bus1'), { occupancy: 'high' }));
  await updateDoc(ref(adminDb, 'buses/bus1'), { isDemo: false, catalogueSource: 'operator_catalogue' });
  await updateDoc(ref(adminDb, 'stations/s1'), { isDemo: true });
  await assertFails(setDoc(ref(auth('alice'), 'reports/demo-stop'), { ...report(), targetType: 'station', targetId: 's1' }));
  await assertFails(setDoc(ref(auth('alice'), 'boarding_requests/demo-stop'), request()));
});


async function rewardAdmin() {
  const db = auth('admin', { admin: true });
  await updateDoc(ref(db, 'buses/bus1'), { catalogueSource: 'operator_catalogue' });
  return db;
}

test('reward ledger and audit revisions are accessible only by trusted administrators', async () => {
  for (const db of [guest(), auth('alice'), auth('op')]) {
    await assertFails(setDoc(ref(db, 'reward_ledger/r1'), { policyVersion: 1 }));
    await assertFails(getDoc(ref(db, 'reward_ledger/r1')));
    await assertFails(setDoc(ref(db, 'reward_ledger/r1/revisions/1'), { points: 100 }));
  }
  await assertSucceeds(reconcileReport(auth('admin', { admin: true }), 'r1', { apply: true }));
});

test('reward dry-run, duplicate retries and simultaneous reports/workers preserve totals', async () => {
  const db = await rewardAdmin();
  await setDoc(ref(auth('bob'), 'users/bob'), profile('bob'));
  await updateDoc(ref(db, 'reports/r1'), { confirmedBy: ['bob', 'bob', 'alice'] });
  await reconcileReport(db, 'r1');
  assert.equal((await getDoc(ref(db, 'users/alice'))).data().points, 0);
  await Promise.all(Array.from({ length: 4 }, () => reconcileReport(db, 'r1', { apply: true })));
  assert.equal((await getDoc(ref(db, 'users/alice'))).data().points, 10);
  assert.equal((await getDoc(ref(db, 'users/bob'))).data().points, 5);
  assert.equal((await getDocs(collection(db, 'reward_ledger/r1/revisions'))).size, 1);
  await setDoc(ref(auth('alice'), 'reports/r2'), report());
  await Promise.all(['r1', 'r2'].map(id => reconcileReport(db, id, { apply: true })));
  assert.equal((await getDoc(ref(db, 'users/alice'))).data().points, 20);
  assert.equal((await getDoc(ref(db, 'users/alice'))).data().reportsSubmitted, 2);
});

test('vote reversal, restoration, hiding and deletion reconcile with revision history', async () => {
  const db = await rewardAdmin();
  await setDoc(ref(auth('bob'), 'users/bob'), profile('bob'));
  await updateDoc(ref(db, 'reports/r1'), { confirmedBy: ['bob'] });
  await reconcileReport(db, 'r1', { apply: true });
  await updateDoc(ref(db, 'reports/r1'), { flaggedBy: ['bob'] });
  await reconcileReport(db, 'r1', { apply: true });
  assert.equal((await getDoc(ref(db, 'users/bob'))).data().points, 0);
  await updateDoc(ref(db, 'reports/r1'), { flaggedBy: [] });
  await reconcileReport(db, 'r1', { apply: true });
  assert.equal((await getDoc(ref(db, 'users/bob'))).data().points, 5);
  await updateDoc(ref(db, 'reports/r1'), { status: 'hidden' });
  await reconcileReport(db, 'r1', { apply: true });
  assert.equal((await getDoc(ref(db, 'users/alice'))).data().points, 0);
  await updateDoc(ref(db, 'reports/r1'), { status: 'resolved' });
  await reconcileReport(db, 'r1', { apply: true });
  await deleteDoc(ref(db, 'reports/r1'));
  await reconcileReport(db, 'r1', { apply: true });
  assert.equal((await getDoc(ref(db, 'users/alice'))).data().points, 0);
  assert.equal((await getDoc(ref(db, 'users/bob'))).data().verifiedCount, 0);
  assert.equal((await getDocs(collection(db, 'reward_ledger/r1/revisions'))).size, 6);
});

test('ineligible reports/targets earn nothing; missing profiles and legacy balances fail atomically', async () => {
  const db = await rewardAdmin();
  for (const change of [{ isDemo: true }, { publicationState: 'queued' }, { createdAt: null }, { falseCount: 3 },
    { createdAt: Timestamp.fromMillis(Date.now() + 86400000) }]) {
    await setDoc(ref(db, 'reports/r1'), { ...report(), createdAt: stamp(), ...change });
    assert.equal((await reconcileReport(db, 'r1', { apply: true })).changed, false);
  }
  await setDoc(ref(db, 'reports/r1'), { ...report(), createdAt: stamp() });
  await updateDoc(ref(db, 'buses/bus1'), { isDemo: true });
  assert.equal((await reconcileReport(db, 'r1', { apply: true })).changed, false);
  await updateDoc(ref(db, 'buses/bus1'), { isDemo: false });
  await updateDoc(ref(db, 'reports/r1'), { confirmedBy: ['missing'] });
  await assert.rejects(reconcileReport(db, 'r1', { apply: true }), /Missing reward profile/);
  assert.equal((await getDoc(ref(db, 'reward_ledger/r1'))).exists(), false);
  await updateDoc(ref(db, 'reports/r1'), { confirmedBy: [] });
  await updateDoc(ref(db, 'users/alice'), { points: 100 });
  await assert.rejects(reconcileReport(db, 'r1', { apply: true }), /reviewed baseline/);
  assert.equal((await getDoc(ref(db, 'users/alice'))).data().points, 100);
  assert.equal((await getDoc(ref(db, 'reward_ledger/r1'))).exists(), false);
});


async function seedPreviousConfirmers(fields = {}) {
  const db = auth('admin', { admin: true });
  await updateDoc(ref(db, 'reports/r1'), {
    confirmedBy: ['bob', 'carol'], confirmCount: 2, lastConfirmedAt: stamp(), ...fields,
  });
  return db;
}
function recheckBatch(db, uid, checkId, fields = {}, record = {}) {
  const batch = writeBatch(db);
  batch.update(ref(db, 'reports/r1'), { lastRecheckedAt: serverTimestamp(),
    lastRecheckedBy: uid, lastRecheckId: checkId, ...fields });
  batch.set(ref(db, `reports/r1/rechecks/${checkId}`), {
    reportId: 'r1', userId: uid, checkedAt: serverTimestamp(), ...record,
  });
  return batch.commit();
}
async function transactionalRecheck(db, uid) {
  const check = doc(collection(db, 'reports/r1/rechecks'));
  return runTransaction(db, async tx => {
    const reportRef = ref(db, 'reports/r1');
    const r = (await tx.get(reportRef)).data();
    const latest = Math.max(...[r.createdAt, r.lastConfirmedAt, r.lastRecheckedAt]
      .filter(Boolean).map(t => t.toMillis()));
    if (latest + 30 * 60000 > Date.now()) return false;
    tx.update(reportRef, { lastRecheckedAt: serverTimestamp(), lastRecheckedBy: uid, lastRecheckId: check.id });
    tx.set(check, { reportId: 'r1', userId: uid, checkedAt: serverTimestamp() });
    return true;
  });
}

test('dated rechecks preserve unique votes and require atomic immutable observation history', async () => {
  await seedPreviousConfirmers();
  const db = auth('bob');
  await assertFails(updateDoc(ref(db, 'reports/r1'), { lastRecheckedAt: serverTimestamp(), lastRecheckedBy: 'bob', lastRecheckId: 'missing' }));
  await assertFails(setDoc(ref(db, 'reports/r1/rechecks/orphan'), { reportId: 'r1', userId: 'bob', checkedAt: serverTimestamp() }));
  await assertSucceeds(recheckBatch(db, 'bob', 'check1'));
  const r = (await getDoc(ref(db, 'reports/r1'))).data();
  assert.deepEqual(r.confirmedBy, ['bob', 'carol']);
  assert.equal(r.confirmCount, 2);
  assert.equal(r.falseCount, 0);
  assert.equal(r.lastRecheckedBy, 'bob');
  assert.equal(r.lastConfirmedAt.toMillis() < r.lastRecheckedAt.toMillis(), true);
  const check = ref(db, 'reports/r1/rechecks/check1');
  assert.equal((await getDoc(check)).data().checkedAt.toMillis(), r.lastRecheckedAt.toMillis());
  await assertFails(updateDoc(check, { userId: 'carol' }));
  await assertFails(deleteDoc(check));
  await assertFails(recheckBatch(db, 'bob', 'check2'));
  await assertFails(recheckBatch(auth('carol'), 'carol', 'check3'));
  // Ordinary confirm updates cannot bypass the recheck cooldown/history rule.
  await assertFails(updateDoc(ref(db, 'reports/r1'), { lastConfirmedAt: serverTimestamp() }));
});

test('rechecks deny spoofing, extra votes, unauthenticated and ineligible observations', async () => {
  const admin = await seedPreviousConfirmers();
  for (const [db, actor] of [[guest(), 'bob'], [auth('alice'), 'alice'], [auth('outsider'), 'outsider']])
    await assertFails(recheckBatch(db, actor, `denied-${actor}`));
  await assertFails(recheckBatch(auth('bob'), 'carol', 'spoof'));
  await assertFails(recheckBatch(auth('bob'), 'bob', 'backdated', { lastRecheckedAt: stamp() }, { checkedAt: stamp() }));
  await assertFails(recheckBatch(auth('bob'), 'bob', 'bonus', { confirmCount: 3 }));
  await assertFails(recheckBatch(auth('bob'), 'bob', 'wrong-report', {}, { reportId: 'other' }));
  for (const fields of [
    { status: 'resolved' }, { status: 'hidden' }, { isDemo: true },
    { publicationState: 'pendingUpload' }, { createdAt: null },
    { createdAt: Timestamp.fromMillis(Date.now() + 60000) },
    { lastConfirmedAt: Timestamp.now() }, { confirmedBy: ['carol'], confirmCount: 1 },
    { falseCount: 3, flaggedBy: ['a', 'b', 'c'] },
  ]) {
    await updateDoc(ref(admin, 'reports/r1'), { ...report(), createdAt: stamp(), confirmedBy: ['bob', 'carol'],
      confirmCount: 2, lastConfirmedAt: stamp(), ...fields });
    await assertFails(recheckBatch(auth('bob'), 'bob', 'ineligible'));
  }
});

test('competing rechecks serialize one observation and retry cannot multiply history', async () => {
  await seedPreviousConfirmers();
  const outcomes = await Promise.allSettled([
    transactionalRecheck(auth('bob'), 'bob'), transactionalRecheck(auth('carol'), 'carol'),
  ]);
  assert.equal(outcomes.filter(o => o.status === 'fulfilled' && o.value === true).length, 1);
  for (const outcome of outcomes) {
    if (outcome.status === 'rejected') assert.equal(outcome.reason.code, 'permission-denied');
    // The emulator may enforce cooldown against the newer resource before the
    // losing transaction's version precondition is retried. This is a truthful
    // rejected write, not a second saved observation.
  }
  assert.equal(await transactionalRecheck(auth('bob'), 'bob'), false);
  const records = await getDocs(collection(guest(), 'reports/r1/rechecks'));
  assert.equal(records.size, 1);
  const r = (await getDoc(ref(guest(), 'reports/r1'))).data();
  assert.equal(r.confirmCount, 2);
  assert.equal(r.confirmedBy.length, 2);
});

test('rechecking does not earn another reward contribution or ledger revision', async () => {
  const admin = await rewardAdmin();
  await seedPreviousConfirmers();
  for (const uid of ['bob', 'carol']) await setDoc(ref(auth(uid), `users/${uid}`), profile(uid));
  await reconcileReport(admin, 'r1', { apply: true });
  const before = (await getDoc(ref(admin, 'users/bob'))).data();
  await assertSucceeds(recheckBatch(auth('bob'), 'bob', 'reward-check'));
  assert.equal((await reconcileReport(admin, 'r1', { apply: true })).changed, false);
  const after = (await getDoc(ref(admin, 'users/bob'))).data();
  assert.equal(after.points, before.points);
  assert.equal(after.verifiedCount, before.verifiedCount);
  assert.equal((await getDocs(collection(admin, 'reward_ledger/r1/revisions'))).size, 1);
});
