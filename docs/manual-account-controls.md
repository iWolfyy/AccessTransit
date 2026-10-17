# Manual account access controls

Implemented 2026-10-17. Open Admin -> Users -> Account access in the main debug
app with `LOCAL_API=true`, `MODERATION_V2=true` and the real-project localhost
service running (checkpoint 44). The earlier synthetic implementation is
historical evidence; the separate Local Test APK is retired. This manages
application access in the request's scope, without disabling Firebase Auth.

An administrator supplies a reason (5-2,000 characters), then chooses a 72-hour
suspension or an explicit restriction until an administrator restores access.
The default is 72 hours from server decision time. The screen shows the deadline
in Asia/Colombo. Restore requires its own reason and clears only manual fields.
Community deadlines, permanent decisions, strikes, points, driver approvals and
route grants are preserved. Restoring access never restarts a cancelled trip.

The trusted endpoints are `POST /v2/accounts/detail` and
`POST /v2/accounts/change`. Firebase verified claims supply administrator
authority; the body cannot supply an actor, role, deadline or balance. Both
operations verify the administrator's current scoped account access. Changes
reject self-action and protect every account with the trusted admin claim,
including the last administrator; a profile role is not proof of authority.

Each change includes a unique operation ID and the last acknowledged manual
revision. A transaction reads current access, preserves independent restrictions
and atomically writes the new manual state, immutable decision, activity audit
and suspension reconciliation intention. A competing revision fails with
`review-stale`. Retrying the same operation returns its original receipt;
reusing it for different input fails. Replaying an old suspension after a later
restore does not suspend the account again. The UI keeps an ambiguous request's
original payload and ID for retry and requires reload after a stale decision.
An account switch blocks submission of captured controls.

Existing server operations and Firestore write gates enforce `account_access`
immediately, including requests from old sessions. The owner status endpoint
exposes the current manual reason while that restriction is effective. At exact
temporary expiry it ceases to restrict access without a phone-clock decision or
scheduled Auth re-enabling. Suspension queues the existing bounded operation
reconciliation worker: a matching operation is cancelled, broadcasting is ended,
its lock is released and pending assistance is reconciled. A newer conflicting
lock is retained for review. This is cancellation, not a fabricated completed
trip. Handover remains the separate existing administrator workflow.

Normal and Sample/Test documents use separate prefixes, revisions and decisions.
The policy accepts both scopes; the running loopback API retains its existing
normal-only allowlist. No Sample/Test request disables or revokes a shared Auth
account. Clients cannot write access or manual decisions directly. No new
Firestore rule or index is needed for these point lookups/transactions.

Reproduce the real-token local API smoke with the fixed demo emulator settings:

```powershell
$env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8087'
$env:FIREBASE_AUTH_EMULATOR_HOST='127.0.0.1:9099'
node test/security/verify-local-account-controls.mjs
```

The smoke creates uniquely named fictional accounts/operation records, races two
decisions, retries the winner, checks worker cancellation/lock/GPS handling and
proves restoration preserves a separate community ban. It does not reset data.
Automated isolated policy tests also cover expiry, Sample-only restrictions,
rollback, actor protection and denied direct client writes. Flutter tests cover
reason validation, retry identity, stale decisions, account switches and all
three locales at 320dp/200% text. Fluent translation and native accessibility
review remain pending.

Auth disable/enable, refresh-token revocation and reviewed account deletion are
now separate controls described in [Auth account controls](auth-account-lifecycle.md).
Dedicated appeals are now available from the restricted-account state and
Profile, with a private admin queue; see [manual restriction appeals](manual-restriction-appeals.md).
Application suspension alone keeps Auth enabled; explicitly disabling Auth
requires reauthentication after restoration. The real-Firebase localhost service,
admin claim and reviewed rules are active; hosted Functions and real FCM remain
deferred.
