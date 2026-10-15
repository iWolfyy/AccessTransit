# Operator approval and bus assignment (F09)

Registration's Operator role records the user's intended role. It grants no
operational permissions. The trusted source is `operator_access/<Firebase Auth UID>`
with boolean `approved: true`, provisioned by the project administrator after
reviewing the operator's identity and authorization to operate the service.
Missing, false, malformed, cached or unreadable approval does not open the dashboard.

No paid backend or billing upgrade is required for this prototype policy. A project
owner can provision the approval using the Firebase console or an existing trusted
Admin SDK environment. Do not expose admin credentials in Flutter or ask operators
to edit their own records. Record the reviewer, review date and decision privately;
approval is an administrative decision, not proof of vehicle accessibility.

All dashboard entry points share an internal approval gate, including direct
navigation. The gate observes authentication and server acknowledgement of the
approval document. Revocation, sign-out, account switching and stream failures
withdraw access and dispose local GPS subscriptions. App pause withdraws access;
resume requires a fresh check. Cached approval alone cannot authorize operation.
Passengers may still choose an operator role at registration, but see the approval
message until an administrator has approved that exact UID.

An approved operator may explicitly claim an unassigned bus. The service transaction
reads approval and the bus assignment before writing only `driverId`. Concurrent
claims contend on that document, and only the winner succeeds. Retrying one's own
assignment is idempotent. Other operators' buses cannot be taken over; release or
reassignment requires the project administrator. The claim cannot include equipment
changes. Equipment controls and trip start require the selected bus to be assigned
to the signed-in operator. Backend rules enforce assignment/approval independently
of the UI; removing or falsifying approval rejects subsequent operational writes.

Revocation or assignment withdrawal stops the local dashboard session. It does not
pretend to complete the shared trip or erase the last acknowledged location. A
project administrator must reconcile any active trip/telemetry during revocation
or reassignment, and passengers still need stale-location handling. A request
already committed before revocation remains acknowledged; authorization cannot
undo an earlier valid write. Background GPS and two-device behaviour need device
verification.

Local validation includes gate revocation/account/resume tests, service transaction
tests and emulator authorization/concurrent-claim tests. No live approval record,
bus assignment or rules deployment is performed by this change. Deploy and verify
the reviewed rules before claiming the live Firebase project is protected.

Subsequent shared setup on 2026-10-15 deployed/read-back-verified the rules and
created four requested operator-role accounts with **pending** approval records.
They have no bus assignment or claimed affiliation with the timetable publisher.
Creating a login is not an identity/operating-authority review. See the
[reset execution record](catalogue-review/shared-reset-plan.md).

## Shared Sample/Test mode

The [shared sample namespace](shared-sample-mode.md) has four approved fixture
operators and fictional bus assignments. Those approvals apply only to
`sample_test/shared`, not the normal catalogue. The eight existing authentication
accounts are reused; their normal operator approval records remain pending.
