# Contribution points: policy v1 and operation

Policy v1 below describes the existing client/batch behavior. The new, locally
tested v2 core is documented in [server/moderation](../server/moderation/README.md).
V2 gives points only to report authors; votes earn no points. V2 is wired into
the explicit LOCAL_VALIDATION + MODERATION_V2 debug app, not the shared/live app. V1 reconciliation now refuses v2 reports; do not mix the
processors or silently rewrite historical confirmation credits.

Local v2 now includes author appeals and audited admin uphold/overturn. An overturn
restores the original double penalty once through an immutable restoration event
and removes its counted strike; it does not award another publication credit.
Voting stays closed on the restored report. Other restrictions remain effective.
One final review per report is supported; permanent-ban decisions are still pending.
See [checkpoint 26](product-flow-implementation-plan.md) and
[local walkthrough](local-validation.md#local-report-appeals-and-admin-review-2026-10-16).


Points are nominal contribution counts with no cash/voucher value. A published,
dated, non-demo active/resolved report on a reviewed `operator_catalogue` target
earns its author 10 points and one report count. Each distinct non-author confirmer
earns 5 points and one confirmation count. Confirmations without an account do not
earn points. Self-votes and duplicate entries cannot multiply a credit.

Flags remove that person's confirmation credit. Hidden/deleted reports or reports
with three flags reverse their contributions. Later restoration can restore a
credit, but never exceed one credit per person/report. Resolved reports retain
historical contributions; time expiry alone does not erase them. Repeated checks
do not multiply rewards. Demo, pending, future/unknown-time reports, missing targets
and targets without administrator-reviewed provenance earn nothing. These counts
do not establish independent truth, safety or guaranteed accessibility.

F16 rechecks are stored as dated observations in the report's `rechecks`
subcollection, separately from unique confirmations. They do not change a person's
report contribution, points, confirmation count or reward-ledger revision. The
30-minute recheck policy is documented in [firestore-security.md](firestore-security.md).

There is no cash, voucher, partner-discount or priority-support fulfilment service.
Membership redemption is disabled regardless of balance. Mobile clients cannot
modify reward counters, including offline. New client profiles initialize counters
to zero; registration retries preserve existing acknowledged profiles. Profile
edits update only name/phone/email after acknowledgement and retain trusted totals.

## Administrator reconciliation

`test/security/reward-ledger.mjs` reads the report, its current target, prior ledger
and affected user profiles inside a Firestore transaction. User deltas, report
contribution state and a revision audit commit together. Concurrent reports contend
on user documents. Concurrent workers/retries for one report see its ledger and do
not credit it twice. Deletion reconciliation uses retained ledger IDs. Missing
profiles, invalid/negative counters and oversized transactions fail atomically for
manual review. Transactions are bounded to 498 affected profiles plus two records.

This is an administrator-operated batch, not an automatically deployed reward
service. Screens show recorded points and explain that reconciliation can be
pending. It uses existing Firebase SDK dependencies and requires no new paid
Cloud Functions deployment. Firebase usage remains subject to project quotas.
No billing upgrade or production reward processing was performed by this change.

From `test/security`, after `npm ci`, run `node reconcile-rewards.mjs` for a dry run.
Supply `REWARD_FIREBASE_CONFIG` (Firebase web configuration JSON) and
`REWARD_ADMIN_CUSTOM_TOKEN` securely. The custom token must authenticate a user
with the existing trusted `admin: true` claim. The tool verifies this claim before
scanning. It cannot grant privileges. Never embed credentials/service-account keys
in Flutter, Git, logs or chat. `--apply` enables writes; running against the live
project requires separate authorization and a reviewed baseline/configuration.

Dry-run results describe a snapshot. Apply rereads inside each transaction; it does
not trust that scan's report contents. The batch stops on an error. Earlier reports
that committed remain applied; rerunning is idempotent. The ledger and revision
history contain participant UIDs and are restricted to administrators by the rules.

## Existing balance migration

Nonzero profiles without `rewardPolicyVersion: 1` are rejected, never silently
reset or credited again. A trusted administrator must review whether legacy totals
represent genuine historical contributions. Document a reset or retained baseline
and its covered reports before enabling v1. Do not merely mark old balances v1 and
replay the same reports: that double counts the baseline. Retained historical
contributions require matching per-report ledger entries in the reviewed migration.
Do not invent replacement users or silently clamp corrupt totals. Manual resets,
baseline seeding and live credentials remain outside this local implementation.

Emulator tests cover authorization, dry-run, parallel workers/reports, duplicate
retry/self-votes, reversal/restoration/hide/delete, missing profiles, ineligible
reports/targets and migration refusal. Local tests do not verify production
deployment, administrator review, ongoing batch operation or cross-device delivery.
Voting transactions were implemented in F07; F16's later recheck lifecycle remains
separate from this unique-contribution reward policy.
