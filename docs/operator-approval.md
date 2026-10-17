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

An approved operator also needs an active administrator-owned
`driver_route_assignments/<UID>` record with an exact `routeId`. Approval alone no
longer permits claiming a bus. The driver workspace verifies both the grant and
the referenced route using acknowledged server snapshots, and shows only physical
buses on that route/direction. Missing/cached/inactive grants and withdrawn routes
close the workspace. Account changes, pause/resume, route changes and revocation
dispose the old operational UI and require a fresh authorization check.

Within the assigned route an operator may claim an unassigned bus. The transaction
reads approval, grant, route and bus, then atomically writes the bus `driverId` and
increments the grant's `claimRevision` with `lastClaimedBusId`. This revision makes
a concurrent administrative route change fail its stale-record check rather than
silently leaving an old-route claim. Rules reject unrecorded direct claims.
Concurrent claims on one bus have one winner; retrying one's own assignment is
idempotent. Another driver's bus cannot be taken over, and equipment edits cannot
be combined with a claim. Conditions, trip writes, GPS and assistance actions all
require current approval, route permission and bus assignment at the backend.

Admin -> Drivers -> Assign route sets/removes one route grant with a recorded
reason. Grant changes release stopped bus claims in the same audited transaction.
Active trips/broadcasts block route changes; transaction reads also guard the live
record against a simultaneous start. Bus preassignment requires an approved driver
with that exact route grant. Approval rejection/revocation also deactivates the
grant and releases claims. Active shared trip/telemetry reconciliation on approval
revocation remains as described below; it is not silently marked completed.

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

## In-app administrator review console

The [admin console](admin-console.md) now implements pending-driver discovery and
approve/reject/revoke review, including review evidence, reviewer attribution and
approved-driver assignment. Access requires the trusted `admin: true` custom claim;
profile roles cannot grant it. Existing operator gates and backend policy still
enforce approval independently. Live activation status and remaining Auth-account
management/reconciliation limits are documented in the console guide.

The route-grant extension is locally implemented and tested, not deployed by this
step. Existing normal and Sample/Test drivers need separate reviewed route grants
before the new rules are enabled. Seed/verification tools now describe local and
sample grants, but no seed script was executed against shared Firebase. Exclusive
driver/run operation locks and the scheduled-start gate subsequently progressed
in [checkpoint 17](product-flow-implementation-plan.md). They remain local pending
reviewed rollout and legacy-operation reconciliation.

## Dated operational runs

The current driver UI requires an administrator-published `service_runs` departure.
Start is allowed from five minutes before through thirty minutes after planned
departure using Firestore server time. A late-start reason is required and remains
private to that driver/admin in `driver_trip_notes`. A start opens boarding with
GPS, not a claimed actual departure. Record actual departure separately before
confirming the next stop. Cancelling boarding or completing the run ends GPS and
releases the driver's `operation_locks` record atomically. Retrying the same active
run resumes its acknowledged timeline; ended runs cannot be restarted.

Existing undated active operations must be reconciled/completed or migrated with
their appropriate locks before shared deployment. The local/Sample/Test fixture
tools were updated but were not run against the shared project. Normal real-data
runs require administrator-reviewed physical bus and timetable records.
