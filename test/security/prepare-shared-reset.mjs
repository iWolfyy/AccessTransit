// Creates a reviewable local reset plan. No remote writes.
import { createRequire } from 'node:module';
import { readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { createHash, randomBytes, randomUUID, pbkdf2Sync } from 'node:crypto';

const root = resolve(import.meta.dirname, '../..');
const privateRoot = resolve(root, '.private/firebase-reset');
const backupRoot = resolve(privateRoot, '2026-10-15T10-55-39.948Z');
const load = async path => JSON.parse(await readFile(path, 'utf8').then(s => s.replace(/^\uFEFF/, '')));
const save = (path, data) => writeFile(path, JSON.stringify(data, null, 2));
const projectId = 'accesstransit-b615b';
const firestore = await load(resolve(backupRoot, 'firestore-backup.json'));
const oldAuth = await load(resolve(backupRoot, 'auth-backup.json'));
if (firestore.projectId !== projectId || !oldAuth.users?.length) throw new Error('Complete target-project backups required.');

const require = createRequire(import.meta.url);
const auth = require('firebase-tools/lib/auth.js');
const account = auth.getGlobalDefaultAccount();
if (!account) throw new Error('Firebase CLI authentication required.');
const tokens = await auth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/firebase']);
const response = await fetch(`https://identitytoolkit.googleapis.com/admin/v2/projects/${projectId}/config`, {
  headers: { Authorization: `Bearer ${tokens.access_token}` },
});
if (!response.ok) throw new Error(`Auth configuration backup failed: ${response.status}`);
const authConfig = await response.json();
await save(resolve(backupRoot, 'auth-config-backup.json'), authConfig);
const hashConfig = authConfig.signIn?.hashConfig ?? authConfig.signIn?.email?.hashConfig;
if (!hashConfig?.signerKey || !hashConfig.algorithm) throw new Error('Password restoration hash parameters missing; reset is not ready.');

const input = await load(resolve(privateRoot, 'requested-accounts.json'));
if (input.accounts.length !== 8 || new Set(input.accounts.map(a => a.email)).size !== 8) throw new Error('Exactly eight unique accounts required.');
const accounts = input.accounts.map(a => ({...a, uid: randomUUID().replaceAll('-', '')}));
const importUsers = accounts.map(a => {
  const salt = randomBytes(16);
  return {localId: a.uid, email: a.email, displayName: a.name, emailVerified: false,
    passwordHash: pbkdf2Sync(input.password, salt, 100000, 32, 'sha256').toString('base64'), salt: salt.toString('base64')};
});
await save(resolve(privateRoot, 'new-auth-import.json'), { users: importUsers });
const records = accounts.map(a => ({path: `users/${a.uid}`, data: { uid: a.uid, name: a.name, email: a.email,
  role: a.role, phone: null, points: 0, reportsSubmitted: 0, verifiedCount: 0 }}));
for (const a of accounts.filter(a => a.role === 'operator')) records.push({path: `operator_access/${a.uid}`,
  data: {approved: false, status: 'pending_operator_identity_and_vehicle_authorization', setupPurpose: 'user_requested_account'}});

const catalogue = await load(resolve(root, 'docs/catalogue-review/published-timetables.json'));
const provenance = {catalogueSource: 'operator_catalogue', isDemo: false, sourceUrl: catalogue.sourceUrl,
  sourcePublisher: catalogue.publisher, sourceRetrievedDate: catalogue.retrievedDate, sourcePublicationDate: null};
for (const s of catalogue.stations) records.push({path: `stations/${s.id}`, data: {name:s.name, ...provenance,
  locationAssessment: 'timing_point_name_only_exact_boarding_location_unknown', lat: null, lng: null,
  capabilityAssessment: 'unknown', hasRamp: false, hasElevator: false, stepFreeAccess: null}});
for (const r of catalogue.routes) records.push({path: `routes/${r.id}`, data: {routeNo:r.routeNo,
  routeName:r.routeName, stops:r.stops, description:'Publisher-listed timing points only; intermediate stops incomplete.', ...provenance}});
for (const s of catalogue.services) {
  const route = catalogue.routes.find(r => r.id === s.routeId);
  if (!route || s.scheduleTimes.length !== route.stops.length) throw new Error('Timetable stop alignment failed.');
  const minutes = s.scheduleTimes.map(t => {const [h,m] = t.split(':').map(Number); return h*60+m;});
  if (minutes.some((m,i) => i && m <= minutes[i-1])) throw new Error('Non-monotonic timetable.');
  records.push({path: `buses/${s.id}`, data: {...provenance, catalogueRecordType:'published_timetable',
    routeId:route.id, routeNo:route.routeNo, busNo:null, driverId:null, stops:route.stops,
    scheduleTimes:s.scheduleTimes, scheduledDeparture:s.scheduleTimes[0], operatingDays:'daily_as_published',
    hasRamp:false, lowFloor:false, rampOk:null, occupancy:'unknown', capabilityAssessment:'unknown'}});
}
const rules = await readFile(resolve(root, 'firestore.rules'));
const digest = data => createHash('sha256').update(data).digest('hex');
const plan = {projectId, preparedAt:new Date().toISOString(), backupRoot,
  backups: {firestoreSha256:digest(await readFile(resolve(backupRoot, 'firestore-backup.json'))),
    authSha256:digest(await readFile(resolve(backupRoot, 'auth-backup.json')))},
  rulesSha256:digest(rules), importSha256:digest(await readFile(resolve(privateRoot, 'new-auth-import.json'))),
  accountInputSha256:digest(await readFile(resolve(privateRoot, 'requested-accounts.json'))),
  deleteFirestore:firestore.documents.map(d => ({name:d.name, updateTime:d.updateTime})),
  deleteAuth:oldAuth.users.map(u => u.localId), accounts, records,
  limitations:['No physical vehicle registrations verified or assigned.', 'Driver accounts require real operator authorization before approval.',
    'Accessibility/occupancy and exact boarding locations unknown.', 'Published timetable can change; no live operation guaranteed.']};
await save(resolve(privateRoot, 'reset-plan.json'), plan);
const planSha256 = digest(await readFile(resolve(privateRoot, 'reset-plan.json')));
await save(resolve(privateRoot, 'plan-fingerprint.json'), {planSha256});
console.log(JSON.stringify({projectId, readOnly:true, deleteFirestore:plan.deleteFirestore.length, deleteAuth:plan.deleteAuth.length,
  createAccounts:accounts.length, createFirestore:records.length, publishedServices:catalogue.services.length,
  operatorApproval:'pending', passwordBackupConfigSaved:true, planSha256}));
process.exit(0);
