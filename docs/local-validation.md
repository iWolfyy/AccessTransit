# Isolated Android/Firebase walkthrough

This mode uses synthetic local data only. It does not verify real services or deployed Firebase security. The original Android application/account data stays in `com.accesstransit.access_transit`; the separate local APK uses `com.accesstransit.access_transit.validation`, label **AccessTransit Local Test**.

Start the local backend from `test/security` (requires its installed dependencies and a compatible JDK):

```powershell
npx firebase emulators:start --project demo-accesstransit --only auth,firestore --config ../../firebase.validation.json
```

Keep that process running. In another terminal in `test/security`:

```powershell
$env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8087'
$env:FIREBASE_AUTH_EMULATOR_HOST='127.0.0.1:9099'
node seed-local-validation.mjs
```

The script refuses other emulator addresses and has no remote-project override or admin credentials. It creates synthetic accounts, three stops, one assigned test bus/route, local operator approval and a fresh **synthetic** ramp observation only in `demo-accesstransit`. Re-running replaces those fixed fixture profiles/catalogue/approval fields (including test counters), so use it before a new walkthrough, not in the middle of one. No existing real catalogue is copied or relabelled. The timetable starts approximately fifteen minutes after seeding; rerun before a later session. All test data is temporary unless separately exported.

Build from the repository root:

```powershell
flutter build apk --debug --dart-define=LOCAL_VALIDATION=true
```

Check the actual APK manifest/application ID before installing. The standard output path is reused by Flutter; do not assume an older file is the intended build. The default build without this flag remains the normal Firebase app. Local builds skip production Google Services initialization, use hard-coded Android emulator host `10.0.2.2` (Firestore 8087/Auth 9099), disable Firestore disk persistence and show a persistent LOCAL TEST ONLY banner. Release local builds are blocked. External Cloudinary photo upload is blocked; use text-only reports. Other Internet resources such as map tiles are not made offline by this mode. Do not enter real credentials or personal photos/notes into a local fixture account.

Local-only fixture logins:

- Passenger: `passenger@local.test`
- Approved assigned operator: `operator@local.test`
- Both use `LocalTest-Only25!` (a public local test password, never a real-account password).

The user performs sign-in in the app. Test passenger planning/saving/assistance, switch to the local operator for acknowledgement, then back to the passenger for status. One emulator with sequential accounts is not a simultaneous two-device test. For concurrent emulator instances use this same local backend and local package; physical devices require a separately reviewed network setup because `10.0.2.2` is emulator-specific.

Do not run the destructive rules-test fixture suite against this same backend while retaining walkthrough state; run it separately after stopping this backend. Do not deploy this seed data, change the hard-coded project to a real Firebase project or infer live operator approval from the local fixture. Real catalogue/approval review and live rollout remain separate administrator actions.


## Local v2 publication and voting activation (2026-10-16)

This is now wired into the **local Android debug app only**. It does not activate
v2 in the normal/shared Firebase application. Keep the Auth/Firestore emulators
above running. Use JDK 21+ (the installed Android Studio JBR works); if the shell
finds Java 8, set `JAVA_HOME` and prepend its `bin` to `PATH` before starting CLI.
Run `npm ci` in `test/security` after pulling the updated dependency lock.

From `test/security`, with the same two emulator environment variables as above:

```powershell
node serve-local-moderation.mjs
```

The server binds `127.0.0.1:8787`, uses the actual Firebase Admin SDK and emulator
Auth verifier, and refuses any other emulator addresses or real project ID. It
writes only the local demo `moderation_config/active` switch. New publications
then require the v2 endpoint; an old direct-write client cannot bypass it. The
worker periodically cancels the matching suspended driver's operation/GPS and
cancels old pending assistance. It records a review-required state rather than
stopping a newer operation; oversized assistance batches require review. It does
not send push notifications or implement permanent-ban decisions. Private report
appeals and admin corrections are available as described below.

Build and launch the separate local package:

```powershell
flutter run -d emulator-5554 --dart-define=LOCAL_VALIDATION=true --dart-define=MODERATION_V2=true
```

`MODERATION_V2=true` without `LOCAL_VALIDATION` debug mode fails startup. This
mode's HTTP exception is fixed to the Android emulator's `10.0.2.2:8787`; arbitrary
HTTP origins remain forbidden. The normal app keeps the staged HTTPS-only client
and v1 flow. The local Android package remains
`com.accesstransit.access_transit.validation`. Do not change the demo host/project
constants to point to production or deploy these flags to users.

Fresh seeding also creates `reader1@local.test` through `reader5@local.test` with
the same public local-only password `LocalTest-Only25!`. Use
`passenger@local.test` to publish a text-only bus/stop report, then sign out and
use each reader account to mark False with a reason. At 0-4 False votes it remains
visible; the fifth hides it and applies one -20 event/strike against its +10 award.
The author cannot vote. True/False voters earn no points. The author's Rewards
screen reads the signed v2 balance; a zero balance is not used as a fallback for
an unavailable balance. Old v1 reports retain their original policy and are not
retroactively converted or charged. Seed only before a walkthrough, since it
replaces fixed synthetic profile/catalogue fields; it is not a production
migration or an account reset tool.

Optional repeatable backend smoke test (from repository root with both local
emulator environment variables set):

```powershell
node test/security/verify-local-moderation.mjs
```

It creates uniquely named **synthetic** local accounts and uses actual Auth
emulator ID tokens through the API: publish/retry/cooldown, author vote denial,
five distinct False votes, signed deduction, fifth-strike temporary suspension,
owned trip/GPS/assistance reconciliation and disabled-session denial. It retains
its synthetic evidence only in the demo emulator. It does not drive Android UI,
verify production token signing/TLS or test physical-device background GPS.

Recorded validation: 582 full Flutter tests, 18 focused v2 UI/client tests,
89 backend/security tests, successful actual Admin/Auth emulator smoke, and a
built/manifest-checked/installed/launched local debug APK. See checkpoint 25 in
[the implementation plan](product-flow-implementation-plan.md) for final logs and
remaining work. APK startup/log checks are not a claim of a complete manual
screen-by-screen native walkthrough.

## Local report appeals and admin review (2026-10-16)

Restart the local API after updating its sources. Existing emulator data can stay;
do not rerun the catalogue/profile seed mid-walkthrough. From `test/security`, with
the two emulator environment variables set, prepare the synthetic admin account:

```powershell
node provision-local-admin.mjs
```

This guarded Admin SDK script sets a trusted claim only in `demo-accesstransit` and
creates a missing local profile without resetting existing counters or reports.
Sign in as `admin@local.test`, password `LocalTest-Only25!`. Sign out/in again if
the account was already open, so its token contains the new claim. This account is
separate from the real administrator account; no real claim was changed.

1. As a report author, open Profile -> My report reviews. A disputed report shows
   its target/description, the five-False-vote hide reason, deducted points and
   whether its strike still counts. Enter an appeal reason of 5–2,000 characters.
   Only a confirmed server response submits it; one report has one appeal/final
   review in this initial workflow. A suspended account can open the same private
   reviews from the restriction screen while its operational workspace stays closed.
2. As the local admin, open the review icon in Admin console. The bounded review
   list includes pending, unreviewed and completed cases. Open a case to inspect
   the report, appeal and paginated vote reasons. Enter a reason and choose Uphold
   or Overturn. The backend verifies the admin custom claim and forbids self-review.
3. Uphold leaves points/strike unchanged. Overturn restores the deducted amount
   once, removes this report's strike and restores public visibility while keeping
   voting closed. A second identical review is idempotent; a conflicting final
   review is rejected. Community suspension clears only when remaining strikes
   fall below five; independent manual/permanent restrictions remain. Ended trips
   are not restarted. The author can refresh to read the final reason/status.

`verify-local-moderation.mjs` additionally exercises restricted-author appeal,
another user's denied private read, denied non-admin decisions, actual claim-based
queue/evidence access, duplicate overturn, +20 restoration and strike reduction.
All records remain synthetic and local. Sinhala/Tamil wording needs fluent review;
complete native/TalkBack acceptance is still separate from widget/startup checks.
Permanent-ban review decisions are now described in the next section. Push
delivery and production hosting/migration/rollout remain subsequent work.
See checkpoint 26 in the plan for the original report-appeal slice.

Previous checkpoint checks: 589 full Flutter tests, 25 focused tests under the exact
local activation flags, 95 isolated backend/rules tests and a clean analyzer.
The actual-token smoke passed and the separate local APK was built, manifest
checked, installed and launched. These checks do not establish full manual native
acceptance. The isolated suite uses `firebase.phase12.json` (port 8088) and a
separate `demo-phase12-appeals` project, preserving walkthrough data on port 8087.

## Local permanent-ban reviews (2026-10-16)

Use the same local admin login and local-v2 build flags. Restart the local API
after updating sources; no catalogue/profile reset is needed. Admin console's
gavel icon opens Permanent-ban reviews. The queue pages through pending, approved,
rejected and withdrawn cases. A case shows its account, current trusted strike
count, pending-appeal state and links to contributing reports/appeals/vote evidence.
Opening a report uses the existing admin report review screen; returning refreshes
the case. Refresh after any other reviewer/author changes its evidence.

- Ten strikes create a review, without imposing a permanent restriction or
  extending a temporary ban. Approve/reject needs a 5–2,000 character reason.
  Approval is unavailable while report appeals remain pending. Resolve those in
  the report-review screen first, then refresh the case.
- Decisions recheck the current moderation revision, strike count and reviewer
  access. A stale view fails instead of committing. Self-review and sanctioning
  an administrator account are forbidden; target administrator status comes from
  Admin Auth, not a writable profile role.
- Approval sets a server-owned community permanent restriction and queues active
  operation reconciliation. Old sessions fail operational backend checks. The
  account gate shows the reason and retains private report-appeal access. Auth is
  intentionally kept available for that access; this flow does not disable Auth
  or issue real/shared token-revocation changes. Rejection adds no restriction and
  never extends the existing 72-hour deadline.
- Repeated decisions in the same review cycle are idempotent; conflicting final
  outcomes fail. A genuinely new counted report can reopen a rejected/withdrawn
  case, using a new immutable decision key while preserving prior decisions.
  Old threshold deliveries cannot reopen it. A later report overturn below ten
  withdraws the community permanent restriction, retaining independent restrictions.

The repeatable smoke script now uses a clearly synthetic nine-strike baseline to
exercise the tenth-strike review boundary, pending/stale appeal rejection, explicit
admin approval and old-token publication denial with actual local Auth tokens.
It does not alter real users or establish production migration readiness.

Validation: **596 full Flutter tests**, **32 focused tests under local activation
flags**, **105 isolated backend/rules tests**, clean analyzer, successful actual
local Auth/Admin smoke, and local APK build/manifest/install/startup checks.
An emulator offline interval interrupted the first final launch check; it
reconnected and the validation activity/process and startup logs were verified.
Full manual native/TalkBack and fluent Sinhala/Tamil review remain unverified.
The separate test project is `demo-phase13-bans`, port 8088, with
`firebase.phase12.json`; the walkthrough backend on 8087 is preserved. See plan
checkpoint 27 for logs and remaining work.

## Local run-bound boarding assistance (2026-10-16)

The same local-v2 debug build now sends assistance through authenticated run-bound
endpoints. Restart the local API after updating sources. It enables only the demo
`assistance_config/active` switch; old direct-write publications are denied in
that scope. Existing legacy records remain readable/reconcilable under their
legacy rules. No shared project is activated or reset.

1. In local Admin -> Buses -> Dated departures, publish an upcoming synthetic run
   for the already assigned physical local-test bus. An old fixture departure may
   have expired; create a fresh dated departure instead of reseeding/resetting
   moderation data. The assigned driver needs current approval and the route grant.
2. As `passenger@local.test`, Search -> Results -> Bus Details for that run and
   segment, then request assistance. The form carries the exact run, boarding and
   alighting stop IDs through confirmation and durable outbox retries. Missing
   dated context cannot substitute another run. No driver UID is sent by Flutter;
   the server resolves it from the dated run/current bus assignment and rechecks
   approval, route, access and active operation locks where relevant.
3. Sign in as the assigned `operator@local.test` and select that dated run. Run
   assistance requests shows its current inbox, with refresh and Load more.
   Acknowledge/Decline/Complete changes appear only after server acknowledgement.
   The rider's receipt distinguishes submission from acceptance, shows expiry and
   explains local in-app availability. Both roles poll acknowledged API state every
   15 seconds while their view is open; these are not push delivery guarantees.
4. A stopped/scheduled bus assignment change retargets pending/acknowledged requests
   to the newly approved route-authorized driver. Old-driver API/rules access ends;
   acknowledgement resets to pending so the new driver must accept explicitly.
   A bounded local worker reconciles requests about every two seconds. It also
   follows a matching trusted active-run handover; this does **not** implement the
   separate full active-trip administration/lock/GPS handover workflow or its UI.
5. Rider cancellation is final. Run termination, a passed target stop, departed
   origin, unavailable driver or server expiry closes an unresolved request.
   Current local expiry default is scheduled target arrival +30 minutes; for an
   active run it is at least 30 minutes after submission. Stop/run progress can
   expire it sooner. This is a lifecycle deadline, not an ETA promise. Offline
   local drafts keep the existing 30-minute retry window, independently of server
   expiry. Reusing an acknowledged ID preserves its response and deadline.

Repeatable actual-token smoke from repository root, with both emulator variables:

```powershell
node test/security/verify-local-assistance.mjs
```

It creates unique synthetic riders/drivers/bus/stops/run, tests submission/retry,
current-driver acknowledgement, an audited stopped-bus assignment change,
old-driver API and direct Firestore denial, new-driver re-acknowledgement, private
latest-first history/cursors and terminal-run expiry by the real local worker.
Synthetic records remain in the demo emulator only. It does not drive Android UI
or perform a real active-trip handover.

Final checks: **605 full Flutter tests**, **41 focused assistance tests under exact
local-v2 flags**, **112 isolated backend/rules tests**, clean analyzer, successful
actual-token assistance and moderation smoke tests, and a built/manifest-checked/
installed/running local validation APK. The first launch wait timed out; a later
check confirmed the running top activity/process and no inspected fatal/unhandled
Flutter startup errors. Full manual native/TalkBack and fluent translation review
remain separate. See checkpoint 28 for logs.

Still outstanding for phase 5: complete audited active-trip admin handover and
background push provider/device delivery. The outbox explicitly records
`available-in-app`/`in-app-only`; no background receipt is invented. Hosted worker
availability, indexes, production migration/rollout and device background checks
also remain unverified. No production data/rules/permissions or billing changed.

## Local active-trip handover (2026-10-16)

Use the existing local Auth/Firestore/API processes and a debug build with both
`LOCAL_VALIDATION=true` and `MODERATION_V2=true`. Restart the loopback API after
updating its code; do not reseed an ongoing walkthrough. The normal package and
shared Firebase project remain untouched.

1. Sign in as the local admin. In the admin console overflow menu, open
   **Active trips**, then a consistent dated boarding/in-progress run.
2. Choose a replacement driver approved and assigned to the same route, with no
   active operation lock. More candidates are available through Load more.
   Enter a reason (5–2000 characters) and select **Transfer trip**.
3. A confirmed transfer preserves trip progress/times, changes bus/run/trip/locks
   together and pauses GPS. Failure is not shown as success. Retry retains the
   same request ID; Refresh reads the current authoritative state after conflicts.
4. The former driver loses operation/assistance authority immediately. Sign in as
   the new driver, select this bus/run and use **Accept and resume GPS**. A fresh
   fix with reported accuracy within 100m is required. Until acceptance, the map
   must not display the retained old fix as a current bus position.
5. Assistance is retargeted by the bounded worker or refreshed inbox read and
   requires renewed acknowledgement. Even a transfer back to the original driver
   invalidates the former acknowledgement. Push receipt/driver attention is not
   implied. Approval withdrawal requires ending/transferring an active operation.

Actual-token smoke (repository root, the same two loopback emulator variables):

```powershell
node test/security/verify-local-handover.mjs
```

This creates unique synthetic admin/rider/two-driver identities, a dated active
run and assistance request. It exercises real admin claims, atomic transfer/retry,
paused GPS, preserved timestamps/progress, direct old-driver denial, pending new
driver bypass denial, fresh GPS acceptance, real worker reassignment/reset and
new acknowledgement. Only its synthetic operation is cancelled afterwards.
It passed in `phase15-auth-smoke-final.log`. It does not operate Android controls
or prove background GPS/push/TalkBack behavior.

Checkpoint 29 validation: 611 full Flutter tests, 39 final focused local-v2 tests
(`phase15-local-verified.log`), 120 isolated backend/rules tests and clean analyzer
(`phase15-analyze-complete.log`). Final localized GPS retry feedback is included.
The APK built (`phase15-local-build-final.log`), was manifest-checked as the
separate validation package and installed successfully. The first launch wait
timed out; repeat inspection confirmed Status ok, the running top activity/process
and no inspected fatal/unhandled startup error (`phase15-local-launch-confirmed.log`,
`phase15-local-startup-confirmed.log`). This does not prove a full native
walkthrough or background operation. Remaining
work includes push provider/device delivery, reliable hosted workers, legacy
operation reconciliation, fare/ETA accuracy, full localization/accessibility QA
and production migration/rollout.

## Local notification simulation (2026-10-16)

The local API now supports authenticated notification device registration/removal
and notification-open checks. Its worker dispatches new assistance/handover events
through a **simulated provider only**. No FCM SDK/provider, OS permission prompt,
native tray notification or real device delivery is enabled. Flutter registration/
open methods are staged transport contracts and are not automatically called by
the app. Existing foreground driver inbox behavior is unchanged.

Restart the existing loopback API to load the updated worker; do not reseed the
ongoing walkthrough. With the same Auth/Firestore emulator variables set, run:

```powershell
node test/security/verify-local-notifications.mjs
```

This smoke creates unique synthetic rider/driver identities, an opaque `local-`
token and scheduled bus/run. It registers the device, submits assistance, waits
for the actual worker to record `pushState: simulated`, and verifies that this
does not acknowledge the request. It then rebinds the same device token to another
account, changes the stopped bus's assignment, checks retargeting and denial of
old/terminal notification opens, and unregisters/cancels only its own fixtures.
`phase16-auth-smoke.log` passed. Simulation receipts never contain a real FCM token.

Private server collections: `notification_devices`, `notification_device_counts`,
`push_events`, `push_attempts`, `local_push_receipts`. Their normal/Sample scopes
are separate. The loopback worker handles normal demo events only. Client direct
reads/writes cannot register a token or forge delivery. Active devices are capped
at eight per account. Token rotation/account switch advances binding generation;
delivery attempts recheck it before sending and before invalid-token cleanup.

Delivery uses leases, backoff and a five-attempt limit. A provider timeout/crash
can cause repeated network sends after lease expiry; exact-once delivery is not
promised. Stable IDs/notification tags support duplicate handling. No-device events
remain retryable until request eligibility expires. Historical outbox events are
not automatically backfilled. Local scan timers are not hosted uptime guarantees.

Remaining native work: Firebase Messaging dependency/configuration on a dedicated
test project, OS permissions/channel setup, token refresh/logout wiring, foreground/
background/terminated handlers and navigation using the server-validated open
contract. Test locked screen, permission denial, revoked tokens, force-stop,
handover and account switching on appropriate devices. Generic message text and
FCM acceptance do not prove device receipt, driver attention or assistance acceptance.
No production credentials, token, provider or billing was activated.

Validation: **615 full Flutter tests** (`phase16-full.log`), **27 focused tests
under exact local-v2 flags** (`phase16-local-mode.log`), **130 isolated backend/
rules/provider tests** (`phase16-backend-final.log`) and **clean analyzer**
(`phase16-analyze-final.log`). Actual local-token smoke:
`phase16-auth-smoke.log`. No APK build/install or native notification/device test
was performed for this backend/staged-client slice.

## Staged Android notification wiring (2026-10-16)

Checkpoint 31 adds the Firebase Messaging plugin, disabled-auto-init manifest,
native channel, foreground/background/terminated callbacks, account-bound token/
permission lifecycle, driver Profile controls and server-validated request screen.
These are staged behind `DriverPushConfiguration`. The reviewed test-project ID
is intentionally empty; adding `PUSH_NOTIFICATIONS=true` alone rejects startup.
Local/Sample/demo/release builds cannot activate it. **The local APK still does
not request a real token, show the notification settings or receive FCM pushes.**

The existing loopback simulation remains available through
`verify-local-notifications.mjs`; it is not routed into Android's notification
tray. Future staging requires a dedicated Firebase Android test app configuration,
reviewed project binding, trusted v2 HTTPS endpoint and provider setup before the
gate is changed. Do not replace normal/shared Firebase configuration to test this.

When that configuration exists, test driver Profile -> Assistance notifications
-> Enable; OS denial, settings revocation/resume, token refresh, locale change,
foreground review, background and terminated taps, logout/account switch and
handover while a tray item exists. Foreground text is generic. Opens reload
current authority and request state; acceptance uses the existing acknowledged
server action. Background callback never fetches passenger data or accepts a
request. Logout clears app access immediately and attempts deregistration/deletion
with a bounded wait; offline failure cannot recall an already displayed generic
notification or guarantee immediate remote token removal.

Automated checks: **629 full Flutter tests** (`phase17-full.log`), **26 focused
local-v2 tests** (`phase17-local-mode.log`), **20 final notification/profile tests**
(`phase17-final-ui-verified.log`), **clean analyzer** (`phase17-analyze-clean.log`),
explicit closed-activation test (`phase17-activation-guard.log`) and **13 provider/
API tests** (`phase17-provider-api-final.log`). New screens/controls cover en/si/ta
at 320dp/200% text; fluent/TalkBack review remains outstanding. APK built with
Messaging/plugin/channel code (`phase17-local-build-final.log`); native Gradle
Kotlin/deprecation notices did not prevent the successful build. No real FCM send,
device receipt or native notification-tap exercise occurred.

Final APK evidence: `phase17-apk-manifest.log` confirms the separate `.validation`
package; `phase17-apk-xml.log` confirms Messaging auto-init and Analytics collection
are both false, the assistance channel and Messaging receiver/service. Install
succeeded (`phase17-local-install.log`). Initial launch wait timed out; repeat
inspection returned Status ok for the running top activity/process
(`phase17-local-launch-confirmed.log`, `phase17-local-pid-confirmed.log`) with no
inspected fatal/unhandled startup error (`phase17-local-startup-confirmed.log`).
This verifies local startup with push disabled, not background delivery or taps.

## Fare foundation and mode checks (2026-10-16)

The user deferred real push/device testing. No Firebase test project/FCM provider
is being activated while fare work proceeds.

Normal app builds now show **Fare unavailable**, because reviewed official tariff
and stop-stage mappings are not integrated. Historic saved prototype values are
not silently promoted to official fares. Explicit debug local/Sample/demo builds
retain the same fictional formula under **Sample est. LKR ...** and a visible
Sample/Test disclosure. Do not compare these numbers with real ticket prices as
an accuracy test. Fare text/disclosures use English/Sinhala/Tamil resources.

`tariff_fare.dart` implements a pure directed-matrix lookup using immutable reviewed
table/mapping contracts, exact pattern/direction/class/occurrences and Colombo
boarding-date applicability. Synthetic unit fixtures cover cents, through fares,
loops, missing cells, class/direction/date mismatch, conflicting versions and
invalid catalogue inputs. `authority.example` and the amounts are fictional.
No official tariff import, Firestore fare collection/rules, admin editor or live
quote/saved-tariff integration is claimed. Operational fare stays unavailable.

Focused normal/synthetic fare tests can be repeated with:

```powershell
flutter test test/tariff_fare_test.dart test/fare_disclosure_test.dart test/passenger_journey_plan_test.dart test/journey_results_schedule_test.dart
flutter test --dart-define=LOCAL_VALIDATION=true --dart-define=MODERATION_V2=true test/tariff_fare_test.dart test/fare_disclosure_test.dart test/passenger_journey_plan_test.dart test/journey_results_schedule_test.dart
```

The difference is intentional: the normal build must suppress prototype prices;
the local build may show only clearly labelled synthetic estimates. Existing saved
UIDs/journeys/reports are preserved. No database reset, deployment, real tariff,
provider/billing or ETA algorithm change occurred in this step.

Validation: **639 full Flutter tests** (`phase18-full.log`), **23 focused local-v2
fare tests** (`phase18-local-mode.log`), **clean analyzer**
(`phase18-analyze-clean.log`) and successful local APK build
(`phase18-local-build.log`). Unit prices are fictional; these checks do not
establish official tariff accuracy. Existing mocked map HTTP failures are logged
but suites pass. See checkpoint 32 for the remaining fare integration.

Manifest-checked `.validation` APK installed successfully (`phase18-apk-manifest.log`,
`phase18-local-install.log`). Initial launch wait timed out; repeat inspection
returned Status ok for the running top activity/process with no inspected fatal/
unhandled startup error (`phase18-local-launch-confirmed.log`,
`phase18-local-startup-confirmed.log`). This is startup evidence, not a manual fare
or real ticket-price walkthrough. The normal installed package stays unchanged.

## Reviewed fare publications (checkpoint 33)

Admin -> Fares supports JSON validation/preview, explicit review/reason, immutable
publication and archival. See [fare policy/import instructions](fare-estimates.md)
and the [fictional local-only schema example](fare-publication-example.local-only.json).
The JSON must describe the complete current bus itinerary and an explicit directed
matrix. No official tariff has been imported. Local synthetic reviewed quotes are
labelled Sample tariff; normal mode remains Fare unavailable without an applicable
non-synthetic publication.

Results -> Bus Details -> Save Trip carries exact cents/source/versions. Details
refreshes against current publications. Archived versions no longer provide
current prices; old saved snapshots remain historical records. No payment or ticket
issuing is implemented. Failed/cached/malformed/ambiguous catalogue responses
cannot provide an authoritative current amount.

With the existing local emulators running, repeat the unique-fixture token check
from `test/security`:

```powershell
$env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8087'
$env:FIREBASE_AUTH_EMULATOR_HOST='127.0.0.1:9099'
node verify-local-fares.mjs
```

This loads current local rules without clearing data, creates unique synthetic
admin/rider identities/catalogue rows, publishes a fictional fare, tests exact
snapshot saving and forged-write denial, then archives the publication. It leaves
those synthetic records for inspection. Expected permission-denied messages are
negative test assertions. It refuses non-local emulator settings.

Validation: **648 full Flutter tests** (`phase19-full-final.log`), **39 focused
local-v2 tests** (`phase19-local-final.log`), **132 isolated backend/rules tests**
(`phase19-backend.log`), actual local Auth-token smoke (`phase19-auth-smoke.log`),
clean analyzer (`phase19-analyze-clean.log`) and local APK build
(`phase19-local-build.log`). No shared rules/index deployment, real tariff
verification, billing change or real FCM/device push test occurred.

The separate `.validation` APK was manifest-checked and installed successfully
(`phase19-apk-manifest.log`, `phase19-local-install.log`). Native fare interaction,
TalkBack and real ticket-price validation remain pending; automated widget checks
do not replace those exercises. The normal installed package was not replaced.

## Road geometry and moving-run estimates (checkpoint 34)

Admin -> Route geometry accepts reviewed JSON and a reason, then publishes or
withdraws the current directed road path. See [schema and ETA limitations](route-geometry-eta.md)
and [fictional local-only example](route-geometry-example.local-only.json).
No real route trace is seeded or claimed reviewed. Synthetic geometry must remain
synthetic. The current full stop order and station coordinates are checked before
an audited publication; use a new version for corrections.

With matching active run/trip/GPS, Results can show a moving boarding estimate;
Details shows the selected road segment and a destination estimate range. Cached,
stale, off-route, ambiguous or wrong-run inputs do not produce a moving ETA. Future
runs retain static geometry and no live ETA/current bus. Withdrawal removes the
road path and its dependent moving estimates. These are low-confidence timetable-
paced estimates, not traffic-aware predictions or a measured accuracy claim.

Repeat the actual local-token smoke test from `test/security` with the walkthrough
emulators running:

```powershell
$env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8087'
$env:FIREBASE_AUTH_EMULATOR_HOST='127.0.0.1:9099'
node verify-local-geometry.mjs
```

It refuses other emulator settings, loads current local rules without clearing
data and leaves unique fictional records/accounts for inspection. It asserts
admin publication, acknowledged passenger receipt, unauthorized write rejection
and live passenger-listener withdrawal. It does not seed a real road path.

Validation: **659 full Flutter tests** (`phase20-full-final.log`), **27 focused
local-v2 tests** (`phase20-local-final.log`), **133 isolated backend/rules tests**
(`phase20-backend-verified.log`), actual local-token smoke
(`phase20-auth-smoke-final.log`). English/Sinhala/Tamil admin previews pass at
320dp/200% text; the English UI covers publish failure/retry. Normal and synthetic
publication modes are tested independently. No real road/ETA accuracy, native
TalkBack or real FCM/device walkthrough is claimed.

Final analyzer is clean (`phase20-analyze-verified.log`); local APK build succeeds
(`phase20-local-build-verified.log`). The APK manifest identifies the separate
`.validation` package, not the normal app. Shared geometry rules still require a
reviewed deployment; local activation is not a production rollout.

Final `.validation` install succeeded (`phase20-local-install-verified.log`).
Repeat launch returned Status ok (`phase20-local-launch-confirmed.log`), following
the slow initial launch wait. No fatal/unhandled Flutter error was found in the
inspected startup log (`phase20-local-startup-confirmed.log`). This does not claim
a native map/ETA/road walkthrough. The normal installed package is unchanged.

## Local ETA measurements (checkpoint 35)

In Local Test, open **Bus Details -> Local ETA diagnostics** using the chart icon.
Enable capture and keep the selected run's Details open as GPS/driver stop updates
arrive. Diagnostics separates timetable and geometry forecasts, pending/excluded
records and matched median/P90 errors. The reference is an acknowledged driver-
reported timestamp, not independent physical ground truth. Normal builds do not
activate this capture or diagnostic storage.

Copy diagnostic JSON exports this account's bounded local ledger; Clear removes
it. No coordinates/email/driver ID are recorded. See [measurement definitions,
retention and replay instructions](eta-evaluation.md). The default replay fixture
uses fictional errors and cannot establish actual route performance. No backend
or security-rule rollout is needed for this local-only tool. Real road/device
accuracy validation and FCM testing remain separate.

Validation: **673 full Flutter tests** (`phase21-full-final.log`), **41 focused
local-v2 tests** (`phase21-local-final.log`), **30 persistence/diagnostic/replay
regressions** (`phase21-regression-final.log`), clean analyzer
(`phase21-analyze-final.log`) and successful Local Test APK build
(`phase21-local-build-final.log`). Coverage includes actual widget-stream capture
and arrival pairing plus account/storage/replay failure cases. These counts do not
represent real operating trips or real ETA accuracy. No backend/rules changes or
deployment occurred; native/road/fluent translation review remains pending.

The manifest-checked separate `.validation` APK installed successfully
(`phase21-apk-manifest.log`, `phase21-local-install.log`); the normal app package
was not replaced. No manual native export/road accuracy walkthrough is claimed.

## Saved Trips browser (checkpoint 36)

Home -> View all saved trips opens an owner-scoped twenty-row paged list. The entry
is present even without an open preview. Past/closed/undated legacy bookmarks are
included. Next/Previous/Refresh and failed-save/read states use the current theme;
dates display Colombo time. Ordering is stable by ID, not chronological.

Open bus details revalidates the exact saved record and preserves its selected
stops/time/needs/run/fare snapshot. Remove saved trip updates the list only after
acknowledged owner-scoped deletion; it does not cancel a bus service. Account
switching clears the list and blocks stale completions. See [saved-trip behavior
and query limitations](saved-trips.md).

Repeat `node verify-local-saved-trips.mjs` from `test/security`, with the same
8087/9099 environment variables shown above. It adds unique synthetic normal and
Sample records without a database reset. It verifies 46 past/closed/legacy records
in three pages per scope, continuation after deleting a cursor record, bounded
latest-open preview and denied foreign/unscoped reads/deletes. It does not deploy
the prepared indexes or change production data.

Validation: **684 full Flutter tests** (`phase22-full.log`), **36 focused local-v2
tests** (`phase22-local-tests.log`), **27 saved-list/persistence regressions**
(`phase22-targeted-final.log`), actual local Auth-token smoke
(`phase22-auth-smoke-final.log`), clean analyzer (`phase22-analyze-final.log`) and
local APK build (`phase22-local-build.log`). Native/manual saved-history, TalkBack
and fluent translation review remain pending; no shared deployment occurred.

Manifest-checked `.validation` install succeeded (`phase22-apk-manifest.log`,
`phase22-local-install.log`). Repeat launch reports Status ok
(`phase22-local-launch-confirmed.log`); no fatal/unhandled Flutter error was found
in the inspected startup window (`phase22-local-startup-confirmed.log`). This is
startup evidence, not a manual native saved-history walkthrough. The normal
installed package was not replaced.

## Selected-segment report browser (checkpoint 37)

Bus Details uses a bounded report preview for its exact bus and selected segment
stops. View all relevant reports opens live paginated bus/stop pages with twenty
records plus lookahead. A report disappearing under committed moderation updates
leaves the visible page; cached/pending/error states do not retain old public
evidence. The compact reports section remains above Save Trip.

Preview coverage is incomplete and explicitly labelled. ID order is stable, not
chronological; empty pages can precede older useful observations. See [query,
pagination and evidence limitations](segment-reports.md). No complete-accessibility
claim is inferred from a partial preview. Existing voting/private review is reused.

With the local Firestore emulator on 8087, run from `test/security`:

```powershell
$env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8087'
node verify-local-segment-reports.mjs
```

It leaves unique fictional rows, tests normal/Sample scoping and bounded previews,
31-stop chunk boundaries, 45-report pages and live hidden-state removal. This tests
query delivery after a trusted fixture transition, not five actual vote actions.
No database reset, shared index/rule deployment, billing or FCM activation occurs.

Validation: **689 full Flutter tests** (`phase23-full-verified.log`), **17 scoped
report/Details/navigation regressions** (`phase23-regression.log`), clean analyzer
(`phase23-analyze-verified.log`) and normal/Sample query smoke
(`phase23-local-smoke.log`). Existing mocked map HTTP failures do not fail the
final suite. No new backend/rules policy was added; native/fluent translation and
production query/index rollout remain pending.

**36 focused regressions pass with exact local-v2 flags**
(`phase23-local-verified.log`). The final browser refresh-label check passes all
five focused browser tests (`phase23-ui-final.log`). Local APK built successfully
(`phase23-local-build-final.log`).

Manifest-checked `.validation` APK installation succeeded (`phase23-apk-manifest.log`,
`phase23-local-install.log`). Repeat launch returned Status ok
(`phase23-local-launch-confirmed.log`), with no fatal/unhandled Flutter error found
in the inspected startup window (`phase23-local-startup-confirmed.log`). Startup
evidence does not constitute a manual native report-pagination walkthrough.

## Recurring calendars (2026-10-17)

Admin → Buses → Dated departures → Service calendar supports a reviewed weekday
calendar (maximum 31 inclusive dates) and an explicit Generate dated departures
action. Publish the calendar, generate, and repeat generation to verify preserved
counts. Cancel a generated scheduled run and generate again: it stays cancelled.
Retire the calendar to block further generation; existing runs are unchanged.
Use a new reviewed publication after changing the bus timetable. See
[service calendars](service-calendars.md) for replacement and exception behavior.

Validation: **696 full Flutter tests**, **13 focused local-v2 regressions**,
**70 isolated rules tests** on `demo-phase24-calendars`/8088 and clean analyzer
(`phase24-full.log`, `phase24-local.log`, `test/security/phase24-rules.log`,
`phase24-analyze.log`). Local Test APK build succeeded (`phase24-local-build.log`).
The existing demo database was not reset. The isolated rules suite clears only
its own distinct demo project. No shared rules/data deployment, paid scheduler
or real FCM test occurred. Background generation, complete schedule history,
loop occurrence IDs and fluent/native accessibility review remain pending.

Local demo activation smoke (no reset): set the emulator environment variables
above and run `node test/security/verify-local-calendars.mjs` from the root.
It loads local rules and creates unique fictional calendar/accounts to check
actual-token normal/Sample publication, audited server receipt, private access
and retirement (`phase24-local-smoke.log`). Run generation is tested separately
by the Flutter service tests. The manifest-checked `.validation` APK installed
successfully; repeat launch returned Status ok and no fatal/unhandled Flutter
error appeared in the inspected process log (`phase24-apk-manifest.log`,
`phase24-local-install.log`, `phase24-local-launch-confirmed.log`,
`phase24-local-startup.log`). This is startup evidence, not a native calendar
walkthrough. The normal installed app was not replaced.
