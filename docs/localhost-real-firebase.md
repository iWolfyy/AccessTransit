# Main app with real Firebase and a localhost API

Implemented 2026-10-17, Asia/Colombo. Main application ID:
`com.accesstransit.access_transit`. Real Firebase project:
`accesstransit-b615b`. No separate installed test app is required.

## Development connection

The main app retains real Firebase Auth/Firestore. Only trusted server operations
use the developer computer, reached from the Android emulator at
`http://10.0.2.2:8788`. The service binds to `127.0.0.1:8788`, not the LAN.
The old synthetic demo server at port 8787 is a separate guarded tool and is not
the real-project launcher. Do not change demo seed/reset tools to target real data.

From the workspace root, with the existing Firebase CLI sign-in:

```powershell
node test/security/serve-shared-backend.mjs
```

For explicitly labelled fictional walkthrough data in the same app, use
`node test/security/serve-shared-backend.mjs --sample` and the
**AccessTransit: realistic SAMPLE data (same app)** launch profile.
This opt-in adds the isolated Sample namespace while retaining normal access;
it does not permit Sample actions to disable/delete/revoke real Auth accounts.
See [Realistic sample data](realistic-sample-data.md) for coverage and refresh.

The launcher uses trusted CLI credentials only inside the computer's server
process, refreshing them through the installed Google/Firebase SDKs. It generates
no service-account key file and sends no administrative credential to Flutter.
It fixes the project, rejects emulator/project environment overrides and verifies
Firebase ID tokens with revocation checking. Normal scope only is exposed.

The VS Code launch profile **AccessTransit: main app, real Firebase + localhost**
selects `lib/main.dart`, Android emulator `emulator-5554`, debug mode and defines
`MODERATION_V2=true`, `LOCAL_API=true`. Select it when intentionally running the
main app. It uses the existing main package, not a new flavour/package. No app
launch/assembly/install was performed while implementing this connection; final
APK delivery stays deferred as requested.

`LOCAL_API` is rejected in release/profile builds. Android debug cleartext is
limited to the emulator alias by a dedicated network-security configuration;
the client further restricts it to exact port 8788 with no user-info/path/query
override. Release inherits the HTTPS-only policy. An arbitrary HTTP URL, old
demo port, or pairing `LOCAL_API` with synthetic `LOCAL_VALIDATION` is rejected.

## Readiness and current shared state

```powershell
node test/security/verify-shared-runtime.mjs
```

The non-mutating probe checks `/healthz`, the intended real project and rejected
missing/invalid tokens. It does not impersonate an account or publish fictional
reports. Ready does not mean a native passenger/driver walkthrough occurred.

Before accepting operations or running workers, the service requires deployed
rules matching the reviewed local source, every required index in `READY`,
valid v2 moderation/assistance activation, and readable trusted Auth. It checks
readiness with a five-second cache. Failure returns `service-unavailable`;
the app retains its unavailable/retry behavior rather than inventing success.
Changing the effective policy date requires a server restart. Stopping the
computer/server makes these operations unavailable; Firebase Auth/Firestore
themselves continue running in the cloud.

The existing worker reconciles bounded pages of driver handovers, active
assistance and suspended operations. Its event cursor passes unrelated pending
jobs; it ignores Sample/Test paths and never sends simulated or real push to
real accounts. Driver cancellation preserves assistance already handed over to
another driver/run. Real FCM remains deferred.

The user-approved real-project update applied the reviewed Firestore rules,
15 composite indexes and the `events.status` collection-group index. Read-back
verified the rules and index readiness. The previously requested administrator
account now has its trusted admin claim; signing in again refreshes the token.
Profiles, other claims and operating records were preserved.

The initial inventory found 8 profiles, all with zero legacy reward counters,
no v2 summaries, 4 operators without route grants and no dated runs. V2
moderation/assistance was then activated atomically with a server timestamp,
audit and prior configuration record. No balances, strike counters, profiles or
old reports were reset/migrated. Old reports are not retroactively penalized.
Granting route permissions and publishing legitimate dated runs remain admin
data tasks; no buses, timetables or live locations were fabricated to fill them.

Older app versions' direct v1 report/assistance writes are intentionally blocked
after v2 activation. Use the main-app localhost profile with the service running.
Do not disable v2 guards merely to let an old client bypass the agreed policy.

## Review and recovery records

Read-only inventory/planning scripts are
`prepare-shared-v2-activation.mjs` and `activate-shared-development.mjs` (default
read-only). Activation requires explicit `--apply`, fresh exact rules/READY
indexes and a transactionally checked zero-baseline cohort; nonzero or existing
migrated balances require a separate reviewed migration. An identical active
policy is not re-dated by retry. No script deletes shared history or creates
fixture accounts/catalogue data.

Private pre-update rules/index/config snapshots and a baseline proposal are in
`.private/shared-v2-preflight/`. Activation before/after receipts are in
`.private/shared-v2-activation/`; admin claim before/after records are in
`.private/admin-setup/`. These folders remain ignored by git. On failure, stop the
localhost service and retain the write guards while inspecting those records.
Restoring older permissions/configuration requires explicit review of any new
v2 data; rollback is not a blind balance reset or deletion of new history.

No Functions deployment, billing change, real push send or APK build/install
occurred. Auth disable/enable, session revocation and reviewed deletion are now
available through the main localhost service; see [Auth account controls](auth-account-lifecycle.md).
Manual restriction appeals and the admin pending queue are also wired to this
service; see [appeals and admin pages](manual-restriction-appeals.md).
Remaining translation/device QA and real fare/geometry coverage remain later work.

On 2026-10-17, the user's subsequent rules/run request authorized updating the
existing main debug installation. Current rules were deployed and read-back
verified; `adb install -r` preserved the package data and sign-in. Cold startup
enabled the main localhost v2 connection and loaded the Admin console catalogue.
Initial account checks block access; subsequent checks for a verified active
account run in the background without hiding navigation (checkpoint 77).
Confirmed restrictions or failed checks remove the protected workspace. See
checkpoints 76–77 in the implementation plan. The localhost service must remain
running for v2 operations; it has not been deployed as hosted Functions.
