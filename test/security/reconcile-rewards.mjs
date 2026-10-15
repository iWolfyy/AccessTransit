import { initializeApp, deleteApp } from 'firebase/app';
import { getAuth, signInWithCustomToken } from 'firebase/auth';
import { getFirestore, collection, getDocs } from 'firebase/firestore';
import { reconcileReport } from './reward-ledger.mjs';

// Administrator-operated and dry-run by default. No credentials belong in Git.
const config = JSON.parse(process.env.REWARD_FIREBASE_CONFIG ?? '{}');
const token = process.env.REWARD_ADMIN_CUSTOM_TOKEN;
if (!config.projectId || !token) throw Error('Supply Firebase configuration and trusted admin custom token securely');
const app = initializeApp(config);
try {
  const credential = await signInWithCustomToken(getAuth(app), token);
  if ((await credential.user.getIdTokenResult()).claims.admin !== true) throw Error('Trusted admin claim required');
  const db = getFirestore(app);
  const apply = process.argv.includes('--apply');
  // Retained ledgers include deleted reports that still need reversal.
  const snapshots = await Promise.all(['reports', 'reward_ledger'].map(name => getDocs(collection(db, name))));
  const ids = [...new Set(snapshots.flatMap(snapshot => snapshot.docs.map(item => item.id)))].sort();
  for (const id of ids) {
    const result = await reconcileReport(db, id, { apply });
    console.log(JSON.stringify({ reportId: id, changed: result.changed, mode: apply ? 'apply' : 'dry-run' }));
  }
} finally { await deleteApp(app); }
