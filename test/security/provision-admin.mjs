// Trusted project-owner setup, never bundled into the Flutter application.
// Default is read-only. --apply grants only the admin claim, preserving other claims.
import { createRequire } from 'node:module';
import { mkdir, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
const project = 'accesstransit-b615b';
const [email, mode] = process.argv.slice(2);
if (!email?.includes('@') || (mode && mode !== '--apply') || process.argv.length > 4) throw Error('Usage: node provision-admin.mjs EMAIL [--apply]');
const require = createRequire(import.meta.url);
const auth = require('firebase-tools/lib/auth.js');
const account = auth.getGlobalDefaultAccount();
if (!account) throw Error('Project-owner Firebase CLI authentication is required.');
const token = await auth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/firebase']);
async function request(method, body) {
  const response = await fetch(`https://identitytoolkit.googleapis.com/v1/projects/${project}/accounts:${method}`, {
    method: 'POST', headers: { Authorization: `Bearer ${token.access_token}`, 'Content-Type': 'application/json' }, body: JSON.stringify(body),
  });
  if (!response.ok) throw Error(`Trusted account operation failed (${response.status}). No credentials logged.`);
  return response.json();
}
async function lookup() {
  const result = await request('lookup', { email: [email] });
  if (result.users?.length !== 1 || result.users[0].email?.toLowerCase() !== email.toLowerCase() || result.users[0].disabled) throw Error('Exactly one enabled existing account is required.');
  return result.users[0];
}
const user = await lookup();
const previousClaims = JSON.parse(user.customAttributes || '{}');
const claims = { ...previousClaims, admin: true };
const directory = resolve(import.meta.dirname, '../../.private/admin-setup');
await mkdir(directory, { recursive: true });
const plan = { project, email, uid: user.localId, previousClaims, proposedClaims: claims, plannedAt: new Date().toISOString() };
await writeFile(resolve(directory, 'admin-claim-plan.json'), JSON.stringify(plan, null, 2));
if (mode === '--apply') {
  const fresh = await lookup();
  if (fresh.localId !== user.localId || fresh.customAttributes !== user.customAttributes) throw Error('Account changed. Review the plan again.');
  await request('update', { localId: user.localId, customAttributes: JSON.stringify(claims) });
  const verified = JSON.parse((await lookup()).customAttributes || '{}');
  if (verified.admin !== true || Object.entries(previousClaims).some(([k, v]) => JSON.stringify(verified[k]) !== JSON.stringify(v) && k !== 'admin')) throw Error('Claim verification failed.');
  await writeFile(resolve(directory, 'admin-claim-result.json'), JSON.stringify({ ...plan, appliedAt: new Date().toISOString(), verified: true }, null, 2));
}
console.log(JSON.stringify({ project, email, applied: mode === '--apply', admin: mode === '--apply' ? true : previousClaims.admin === true }));
process.exit(0);
