# Admin console

The Flutter app includes an administrator-only console. Login and splash routing use the Firebase `admin: true` custom claim, not the editable profile role. An administrator can return to the passenger app from Overview; Profile has an Admin console entry for administrators.

## Included

- Overview counts, searchable buses/timetables, routes, stops, users and driver reviews.
- Catalogue create/edit/delete with source review, coordinate validation, ordered stops, complete 24-hour schedules, vehicle/timetable separation and approved-driver assignment.
- Equipment capability can remain Unknown. Catalogue editing does not manufacture a dated working-equipment check, live GPS, report or service guarantee.
- Pending driver applications are discovered from operator-role user profiles even when no approval document exists. Approval requires a review note and explicit identity/operating-authority confirmation. Reject/revoke requires a reason. Review decision, reviewer and time are stored privately.
- Drivers also have an independent route grant: Drivers -> Assign route selects or removes one exact route/direction with a reason. Approval is required before assigning a route. Bus editor driver options are restricted to approved drivers granted that route. Grant changes atomically release stopped bus claims and are blocked during active trips/broadcasts; live-document and claim-revision guards detect concurrent starts/claims. Approval revocation deactivates the route grant too.
- Revocation withdraws approval and releases current bus assignments in one transaction. Existing active trip/telemetry records are retained for reconciliation; the UI explicitly says they are not completed. Reconciliation of orphaned active trips remains a project-owner operation.
- User search and name/phone editing preserve identity, role, email and rewards. Auth password/email changes, disabling and deleting Auth accounts remain in Firebase Authentication; this console does not claim to perform those actions.
- Every dashboard mutation and its private activity record commit together. Activity shows the most recent 100 records. Clients cannot edit/delete activity records through Firestore rules.
- Concurrent target/reference edits are checked inside transactions. Failed or cached administrative reads hide controls; writes require fresh token authorization and server acknowledgement.

## Safe deletion

Referenced records and active buses are blocked. For an eligible target, deletion first commits `deletionPending: true`, then reads dependencies again before physically deleting it. The shared rules reject new passenger/operator references to withdrawn catalogue records, and admin forms transaction-check their references. The passenger cache removes withdrawn records. If connectivity or a new dependency interrupts deletion, the console offers Restore or Finish deletion. Restore is an acknowledged change, not a local-only undo. Concurrent direct Admin SDK writes bypass these client rules and must follow the same maintenance policy.

## Trusted setup

Use an already authenticated project-owner environment. The setup utility is not included in the app and never accepts a service key or password through Flutter:

```powershell
cd test/security
node provision-admin.mjs ADMIN_EMAIL
node provision-admin.mjs ADMIN_EMAIL --apply
```

The first command only prepares a private plan/backups; the second preserves other custom claims and grants `admin: true` to exactly one enabled existing account. Claim changes use Google's [authenticated project account update API](https://docs.cloud.google.com/identity-platform/docs/reference/rest/v1/projects.accounts/update). No registration option can grant admin access.

Deploy the reviewed `firestore.rules` before using dashboard writes. The change adds private, create-only admin activity and rejects references to pending-deletion records in normal and Sample/Test scopes. Existing owner and operator policies remain in place. `admin-rules-rollout.mjs backup` preserves deployed rules; `verify` compares the deployed source against the tested local file. Backups/plans/results are under ignored `.private/admin-setup/`.

## Validation and current rollout (2026-10-16)

- Full Flutter suite: **509 passed** (`admin-full-tests.log`).
- Isolated Firestore authorization suite: **52 passed** (`test/security/admin-rules-tests.log`, project `demo-admin-console`, port 8088).
- Full analyzer: **No issues found** (`admin-analyze.log`).
- Normal shared-backend Android debug APK: build passed (`admin-build.log`).
- Dashboard and editor widget tests cover 320dp, 200% text and high contrast. Generated widget previews are in `build/ui-admin/`; these are not native screenshots or TalkBack verification.
- Shared rules backup completed. Deployment was rejected by automatic approval review because exact authorization for the shared rules boundary change was required. No admin claim has been applied and no real driver has been approved by this implementation session. Live activation awaits that approval; do not describe the console as verified live yet.

The normal shared-backend APK was installed successfully with `adb install -r` and launched on `emulator-5554`; the package process was confirmed running. Installed artifact SHA-256: `C3B0AC5C2A5B05EAE7753A5ACB7FEEDF10569CFEB1C80190198AE86114696EB0`. Auth sessions were retained. This does not establish a live admin walkthrough because the custom claim and rules rollout are still pending approval.

## Dated departures extension (local implementation)

Buses -> Dated departures publishes a physical bus's reviewed stop intervals for a Colombo service date and departure time. The one-off departure shifts all stops together and preserves overnight rollover without editing the bus timetable. The start window is fixed at five minutes before through thirty minutes after departure. Cancel an unstarted run before publishing a rescheduled replacement; concurrent starts invalidate stale cancellation attempts. The editor lists the stored run timetable, its state and private late-start reason where present. Late reasons are stored separately from public run documents.

The driver must select a published dated run, start boarding within the server-enforced window, and record actual departure separately. Driver locks and linked run/trip/GPS changes enforce one active operation per driver and protect an occupied bus. No legacy records were automatically converted. Local validation is 532 Flutter tests, 60 rules tests and a clean analyzer; shared activation, fixture provisioning and a new APK install remain pending. See [implementation checkpoint 17](product-flow-implementation-plan.md).

The Dated departures screen now links to **Service calendar** for immutable
weekday/departure calendars and explicit bounded run generation. Existing runs
are preserved; retiring a calendar does not cancel them. See
[service calendars](service-calendars.md) and implementation checkpoint 38 for
current local validation and remaining rollout limits.
