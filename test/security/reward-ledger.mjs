// Trusted administrative tool; never bundle in the mobile app.
import { doc, runTransaction, serverTimestamp } from 'firebase/firestore';
const version = 1;
const counters = ['points', 'reportsSubmitted', 'verifiedCount'];
const validUid = uid => typeof uid === 'string' && uid.length > 0 && uid.length <= 128 && !uid.includes('/');

function contributions(id, report, target) {
  if (!report || !target || target.isDemo === true || target.catalogueSource !== 'operator_catalogue'
      || report.isDemo === true || report.publicationState !== 'published'
      || (report.falseCount ?? 0) >= 3 || new Set(report.flaggedBy ?? []).size >= 3
      || !['active', 'resolved'].includes(report.status) || !validUid(report.userId)
      || typeof report.createdAt?.toMillis !== 'function'
      || !Number.isFinite(report.createdAt.toMillis()) || report.createdAt.toMillis() > Date.now()
      || ['report_1:user_demo_1', 'report_2:user_demo_2', 'report_3:user_demo_3'].includes(`${id}:${report.userId}`)) return [];
  const flags = new Set(report.flaggedBy ?? []);
  const voters = [...new Set(report.confirmedBy ?? [])]
    .filter(uid => validUid(uid) && uid !== report.userId && !flags.has(uid));
  return [{ uid: report.userId, points: 10, reportsSubmitted: 1, verifiedCount: 0 },
    ...voters.map(uid => ({ uid, points: 5, reportsSubmitted: 0, verifiedCount: 1 }))]
    .sort((a, b) => a.uid.localeCompare(b.uid));
}

export async function reconcileReport(db, id, { apply = false } = {}) {
  return runTransaction(db, async tx => {
    const ledgerRef = doc(db, 'reward_ledger', id);
    const [reportSnap, ledgerSnap] = await Promise.all([
      tx.get(doc(db, 'reports', id)), tx.get(ledgerRef),
    ]);
    const report = reportSnap.data();
    if (report?.policyVersion === 2 || report?.rewardPolicyVersion === 2) {
      throw Error('Policy v2 reports require the trusted moderation service; v1 reconciliation is forbidden');
    }
    let target;
    if (report && ['bus', 'station'].includes(report.targetType) && validUid(report.targetId)) {
      target = (await tx.get(doc(db, report.targetType === 'bus' ? 'buses' : 'stations', report.targetId))).data();
    }
    const previous = ledgerSnap.data();
    if (previous && previous.policyVersion !== version) throw Error('Unsupported reward policy; explicit migration required');
    const before = previous?.contributions ?? [];
    const after = contributions(id, report, target);
    if (JSON.stringify(before) === JSON.stringify(after)) return { changed: false };
    const uids = [...new Set([...before, ...after].map(entry => entry.uid))].sort();
    if (uids.length > 498) throw Error('Transaction too large; manual review required');
    const profiles = await Promise.all(uids.map(uid => tx.get(doc(db, 'users', uid))));
    const updates = profiles.map((snap, index) => {
      if (!snap.exists()) throw Error('Missing reward profile; manual review required');
      const user = snap.data();
      if (user.rewardPolicyVersion !== version && (user.rewardPolicyVersion != null ||
          counters.some(key => (user[key] ?? 0) !== 0))) throw Error('Legacy balances require a reviewed baseline migration');
      const oldEntry = before.find(entry => entry.uid === uids[index]);
      const newEntry = after.find(entry => entry.uid === uids[index]);
      const update = { rewardPolicyVersion: version, rewardsUpdatedAt: serverTimestamp() };
      for (const key of counters) {
        const value = (user[key] ?? 0) + (newEntry?.[key] ?? 0) - (oldEntry?.[key] ?? 0);
        if (!Number.isSafeInteger(value) || value < 0) throw Error('Invalid reward balance; manual review required');
        update[key] = value;
      }
      return update;
    });
    const revision = (previous?.revision ?? 0) + 1;
    if (apply) {
      profiles.forEach((snap, index) => tx.update(snap.ref, updates[index]));
      const record = { policyVersion: version, revision, contributions: after, checkedAt: serverTimestamp() };
      tx.set(ledgerRef, record);
      tx.set(doc(db, 'reward_ledger', id, 'revisions', String(revision)), { ...record, previousContributions: before });
    }
    return { changed: true, revision };
  });
}
