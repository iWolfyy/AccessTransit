// Read-only administrative inventory/backup. Never creates, updates or deletes.
import { createRequire } from 'node:module';
import { mkdir, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';

const require = createRequire(import.meta.url);
const auth = require('firebase-tools/lib/auth.js');
const projectId = 'accesstransit-b615b';
const account = auth.getGlobalDefaultAccount();
if (!account) throw new Error('Firebase CLI sign-in required; no credentials supplied.');
const tokens = await auth.getAccessToken(account.tokens.refresh_token, [
  'https://www.googleapis.com/auth/cloud-platform',
  'https://www.googleapis.com/auth/firebase',
]);
if (!tokens?.access_token) throw new Error('No administrative access token available.');
const firestoreRoot = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;
async function read(url, body) {
  const response = await fetch(url, {
    method: body ? 'POST' : 'GET',
    headers: { Authorization: `Bearer ${tokens.access_token}`, 'Content-Type': 'application/json' },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  if (!response.ok) throw new Error(`Administrative read failed (${response.status}); no database changes made.`);
  return response.json();
}
const collections = [];
const documents = [];
async function walk(parent) {
  let pageToken;
  do {
    const result = await read(`${parent}:listCollectionIds`, { pageSize: 1000, ...(pageToken ? { pageToken } : {}) });
    for (const collectionId of result.collectionIds ?? []) {
      const collection = `${parent}/${encodeURIComponent(collectionId)}`;
      const entry = { path: decodeURIComponent(collection.slice(firestoreRoot.length + 1)), documents: 0 };
      collections.push(entry);
      let documentToken;
      do {
        const url = new URL(collection);
        url.searchParams.set('pageSize', '1000');
        url.searchParams.set('showMissing', 'true');
        if (documentToken) url.searchParams.set('pageToken', documentToken);
        const page = await read(url);
        for (const document of page.documents ?? []) {
          // Missing parent documents can still have subcollections.
          if (document.createTime || document.updateTime || document.fields) {
            documents.push(document);
            entry.documents++;
          }
          await walk(`https://firestore.googleapis.com/v1/${document.name}`);
        }
        documentToken = page.nextPageToken;
      } while (documentToken);
    }
    pageToken = result.nextPageToken;
  } while (pageToken);
}
await walk(firestoreRoot);
let authCount = 0;
let authPage;
do {
  const url = new URL(`https://identitytoolkit.googleapis.com/v1/projects/${projectId}/accounts:batchGet`);
  url.searchParams.set('maxResults', '1000');
  if (authPage) url.searchParams.set('nextPageToken', authPage);
  const page = await read(url);
  authCount += page.users?.length ?? 0;
  authPage = page.nextPageToken;
} while (authPage);
const output = resolve(import.meta.dirname, '../../.private/firebase-reset', new Date().toISOString().replaceAll(':', '-'));
await mkdir(output, { recursive: true });
await writeFile(resolve(output, 'firestore-backup.json'), JSON.stringify({ projectId, capturedAt: new Date().toISOString(), documents }, null, 2));
const inventory = { projectId, readOnly: true, firestoreDocuments: documents.length, collections, authAccounts: authCount, backupDirectory: output };
await writeFile(resolve(output, 'inventory.json'), JSON.stringify(inventory, null, 2));
console.log(JSON.stringify(inventory));
