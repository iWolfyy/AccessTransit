# Firestore authorization (F01)

The user-requested [shared Sample/Test mode](shared-sample-mode.md) adds a separately
scoped policy under `sample_test/shared`. The deployed normal root policy is
unchanged; scoped operator approval does not authorize normal vehicles. The sample
policy is generated from the root policy, and both are covered by the local rules
suite. Normal-mode claims below refer to root collections.

Client rules use default-deny authorization. Routes, stations, buses, bus telemetry, trips and published community reports are public information. Profiles, passenger journeys and assistance requests are private. Never put private pending reports in the public reports collection.

- Profiles: authenticated owner can create zero-stat profiles and edit name/phone/email. Role, identity, creation time and reward counters cannot be changed by that client. Selecting an operator profile is a UI preference, not a grant of authority.
- Operator approval (F09; see [policy and operation](operator-approval.md)): a project owner uses the Firebase console or trusted Admin SDK to create `operator_access/<AUTH_UID>` with boolean `approved: true`. App users cannot grant their own approval. Assigned approved operators can change their bus conditions and telemetry. An approved operator can claim an unassigned bus; taking another operator's assigned bus is denied.
- Catalogue: route/stop/bus creation and structural edits are administrator operations. The existing operator add-stop feature must be revised to an approval workflow in a later audit fix. Do not weaken these rules to make it appear to succeed.
- Journeys: owners read and create their journeys, and cancel/complete them. Global passenger journey queries are forbidden.
- F06 journey selections include endpoint IDs, requested date/time, chosen timetable departure, duration/fare estimates and access requirements. New selection fields require a complete typed selection with existing stops served by the selected bus. The app validates forward stop order. Clients cannot change saved selection/identity fields. Signed-in clients can read a missing ID for an idempotent creation transaction; an existing document remains owner-only. Legacy documents remain readable; resume requires actual selection details and cannot invent them.
- Reports: signed-in authors publish only to existing targets, with a server-created timestamp, no fabricated confirmations, and shared Cloudinary URLs. Riders can edit only their own vote; totals must match unique non-overlapping vote lists. F07 uses transactions and atomic transforms; three independent inaccuracy flags hide the report atomically. Ordinary voters cannot delete it. Hidden excludes it from planning/feed, while its record/photo are still public. Author removal and administrator moderation are separate operations; privacy/retention work remains F20.
- Resolution: an author must atomically mark an active report resolved with resolvedBy = their UID and resolvedAt = server request time, and create report_resolutions/<reportId> with the same actor/time and original target/condition text. Rules reject standalone/forged history records and client edits/deletions. The record survives report removal. Legacy resolution attribution/time may be Unknown. Privileged administrators retain administrative access.
- Assistance: the rider owns the request, the target stop must be on the selected bus, and only the assigned approved operator can acknowledge/reject/complete in valid order. Rider cancellation is allowed. Guest identities cannot publish assistance requests. The optional purpose is boarding or alighting (legacy default boarding); Alighting Help is accepted only for alighting requests, and Boarding Help only for boarding requests.
- Assistance reads split `get` and `list`: signed-in clients can check a missing document ID to create it transactionally, while existing documents remain private. History queries must constrain the rider ID or the assigned bus; unrestricted collection queries are denied. F04 retries preserve existing driver responses and do not overwrite requests. See assistance-delivery.md for acknowledgement and offline semantics.
- Private profiles are no longer a public attribution source. The evidence card can fall back to account identifiers; a consented public display-name profile can be designed separately.
- Rewards are read-only client fields. Report publication/voting/moderation no longer attempt client reward writes or derive points from report counts. F13 adds an administrator-only transactional reward ledger and dry-run reconciliation tool; see [rewards.md](rewards.md). It has not been run against production. Existing trusted stored totals can still be displayed.

The rules do not protect Admin SDK/IAM access, and Cloudinary unsigned uploads have a separate permission model. Restrict administrative credentials and enforce the photo preset's limits independently.

## Local tests

Install test-only dependencies with `npm --prefix test/security ci`. Use Java 21+ for the current Firebase emulator; the local Android Studio JBR can be used. Run:

```powershell
$env:JAVA_HOME = 'D:\Apps\Android Studio\jbr'
$env:PATH = "$env:JAVA_HOME\bin;" + $env:PATH
npm --prefix test/security run test:rules
```

The test script pins `demo-accesstransit` and localhost port 8087. It creates only emulator fixtures, never live reports, profiles or driver approvals. Tests cover authorized paths plus unauthenticated access, cross-account ownership, UID/role/stat forgery, operator approval/assignment, report target/time/votes, telemetry validation and assistance state transitions.

This follows [Firebase's rules emulator testing workflow](https://firebase.google.com/docs/firestore/security/test-rules-emulator) and [field allowlists](https://firebase.google.com/docs/firestore/security/rules-fields).

## Live deployment

On **2026-10-15**, the user-approved shared reset deployed the 49-test-validated
rules to `accesstransit-b615b`; the published release's source hash was read back
and matched the reviewed file. All eight new accounts signed in and read their
own profiles; eight cross-account profile reads were denied. See the
[execution record](catalogue-review/shared-reset-plan.md). These checks establish
that deployment and profile-read isolation, not complete live write-path/device
validation. Driver approvals are pending and published timetable records cannot
be claimed as vehicles. Index and other external configuration checks remain.

Rules are not active in a real project merely because this file changed. Validate them locally first. Before a live rollout, inventory existing schema/targets and approved operator UIDs; configure trusted approval records without exposing profiles. F04/F07/F08 acknowledgement/error handling is implemented and locally tested; see the fix log. Live rejected-write and cross-account checks are still required before calling the rollout verified.

Deployment command (a separate explicit live action):

```powershell
npx firebase-tools deploy --only firestore:rules --project accesstransit-b615b
```

Live deployment status must be recorded in the audit fix log. Do not mark deployed protection as verified without the deployment result and cross-account checks.


## Ramp observation metadata (F11)

An assigned approved operator may record rampOk only with rampCheckedBy equal to
its authenticated UID and rampCheckedAt equal to server request time. Occupancy
alone does not alter that observation. Clients cannot reuse stale times, forge an
observer or renew only the source. A legacy working flag without a dated source
is Unknown in the app; physical capability is separate. Deploy these reviewed
rules alongside the compatible app before relying on the live protection. No
live deployment or timestamp backfill was performed by this change.


F13: `reward_ledger` and revision history are admin-only. Mobile profile edits
cannot alter reward counters or policy metadata. Administrator reconciliation
atomically commits user deltas and ledger revisions; production baseline review
and execution remain separate actions.

## Dated repeat checks (F16)

Previous non-author confirmers may record that the same condition is still
accurate once 30 minutes have passed since the report's latest dated creation,
confirmation or recheck. This interval applies across the report, including
competing confirmers. Unique confirmation arrays/counts and rewards are unchanged.
Different conditions require a new report; a recheck cannot resolve a barrier.

The transaction writes `lastRecheckedAt`, `lastRecheckedBy`, `lastRecheckId` and a
new immutable `reports/<id>/rechecks/<checkId>` observation containing the report
ID, authenticated account ID and server check time. Both sides must commit
together. Rules deny isolated parent/history writes, forged observers/times,
reused history IDs, counter changes and early repeats. Existing confirmers cannot
refresh `lastConfirmedAt` through the ordinary voting path to bypass this policy.

The app uses only acknowledged receipts. A competing attempt can be denied by
the rules after another check commits; it displays failure/retry feedback and
cannot claim a second observation. A retry reads the new cooldown. History stores
minimal public account/time attribution and is retained as an audit record;
client edits/deletes are denied. Reversing the latest rechecker's vote invalidates
that check for freshness. Missing/invalid original time never becomes fresh.

Deploy the compatible rules/app together before relying on this feature on live
accounts. No rules deployment, live rechecks or two-device test was performed.
