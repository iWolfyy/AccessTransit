# Firebase Auth account controls

Implemented 2026-10-17 in the main app and real-Firebase localhost service.
Open Admin -> Users -> account controls -> Firebase account controls. The
localhost backend must be running; refresh login for the trusted admin claim.
No separate APK, Functions deployment or billing upgrade is required here.

Disable sign-in immediately commits a server-owned access gate, then disables
Firebase Auth and revokes refresh tokens. Session revocation also advances a
server-owned authentication-time cutoff: existing sessions cannot use trusted
API operations or protected Firestore reads/writes. Reauthentication is required;
refreshing an old session does not bypass the cutoff. Public catalogue reading
remains available. Enable sign-in waits for Auth acknowledgement and preserves
the cutoff and independent manual/community restrictions.

Every action requires a reason and current revision. Requests are durable,
audited and idempotent. Pending or review-required is not completed. Use Reload
status, then reconcile the same operation after reviewing a failed effect.
The worker resumes pending jobs. It never automatically steals a processing
job: recovery requires evidence that Auth reached the requested state. If that
cannot be established, leave it blocked for server-side inspection rather than
launching a competing destructive call. A successful Auth effect with a failed
Firestore receipt is reconciled without repeating the acknowledged effect.

Deletion is a separate review workflow:

1. Request deletion review with a reason.
2. Disable sign-in and finish active-operation reconciliation. Disable queues
   the existing worker to cancel matching operation/GPS and expire assistance.
3. Approve with a new reason, exact UID and final irreversible confirmation,
   or reject the review without deleting Auth.

The server rechecks approval, Auth disabled state and active-operation locks.
The requester may also review; this is not a two-administrator policy. Self
actions and all trusted administrator targets are protected. Auth effects are
normal-scope only; Sample/Test cannot disable or delete shared Auth accounts.

Successful deletion removes the Firebase sign-in identity and replaces the
private user profile with an anonymized tombstone retaining contribution
counters. Route grants/approval are deactivated. Shared reports, journeys,
operational history, ledger and audit references are retained. This is not
complete content/storage erasure: attributed descriptions, photos and private
review evidence have separate retention requirements. Do not promise that
deletion removes all historical personal content.

Validation uses synthetic accounts only in guarded Auth/Firestore emulators
(`firebase.phase30.json`, project `demo-phase30-auth`). The real shared rules
were backed up, updated and read back; the loopback readiness/token rejection
probe makes no user-data changes. No real account was disabled, enabled,
revoked or deleted for validation. Native admin/device walkthrough remains due.
