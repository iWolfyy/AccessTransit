# Assistance delivery (F04)

The confirmation form saves an owner-bound request in the device outbox before opening its receipt. It does not claim driver delivery from a local write. Home > Your assistance requests makes saved requests and shared history reachable after leaving the form.

## Two separate states

- Delivery: Pending upload, Sent, Failed, or Retry expired. Sent means the shared service acknowledged the transaction; it does not mean the driver saw or accepted the request.
- Driver response: Awaiting driver acknowledgement, Driver acknowledged, Driver marked completed, Driver declined, or Cancelled. Completion is an operator declaration, not independent proof that help occurred.

Live updates use server-backed snapshots, ignore pending client writes, and forward acknowledged local events to existing subscriptions. When only a saved receipt is available, the receipt explains that the displayed driver status is the last received status. Stream and persistence failures are visible. The in-memory assistance cache is scoped to the current signed-in account; switching accounts clears it and old-session listeners/late writes cannot refill another account's cache. Persisted Firestore cache snapshots are not used as fresh authorization evidence.

## Retry and offline behaviour

Requests keep one generated ID across retries and process restarts. The publication transaction reads that ID first. An existing matching request is returned with its current driver response; retry cannot reset acknowledged/completed status or publish to another target.

Transient network failures and timeouts stay Pending upload because delivery is unconfirmed. Permission and validation failures become Failed and require an explicit retry. Pending requests retry on authentication and every 60 seconds while the app process runs. This is not background delivery while the app is terminated.

After 30 minutes from enqueue, retry stops and the receipt shows Retry expired. This prevents a stale assistance request from being automatically sent much later. Expiry does not claim that an earlier timed-out write was cancelled or never arrived; check shared history and driver status. A sent pending/acknowledged request can be cancelled, with success shown only after the cancellation transaction is acknowledged.

Only the owning signed-in rider may enqueue/retry or view the passenger receipt. An approved assigned operator can acknowledge or decline a pending request, and complete an acknowledged request. Failed driver status writes retain the previous acknowledged state and offer retry feedback. The app does not implement push notifications or guarantee a driver's response time.

## Verification and live rollout

Regression tests cover durable restoration, pending acknowledgement, stable IDs, transient/permanent failures, timeout ambiguity, expiry, wrong-account/wrong-target rejection, stream forwarding, cache isolation, passenger receipts/history/cancellation and failed operator updates. Demo-emulator tests exercise owner history, transaction creation/retry and authorized driver transitions.

The repository's Firestore rules have not been deployed. A live check still needs two signed-in devices (passenger and approved assigned operator), rules/schema compatibility, an offline retry, cancellation and acknowledgement/completion. Local tests are not evidence of real-device delivery.

## Local run-bound v2 checkpoint

The historical F04 flow above remains the normal build's legacy path. The explicit
LOCAL_VALIDATION + MODERATION_V2 debug app now uses the trusted assistance API.
Server records include the selected service run, boarding/alighting stop indices,
resolved driver, assignment version and authoritative deadline. Retried outbox
IDs retain the same run/segment; a previous account's draft cannot publish under
a newly signed-in account. Publication never accepts client rider/driver IDs.

Scheduled runs use the approved bus assignee; started runs additionally require
matching run/trip driver, bus and active operation lock. Unresolved requests are
retargeted only to a valid current driver and reset acknowledgement on handover.
Old drivers fail reads/actions immediately at the backend; foreground views clear
unavailable rows on refresh. Terminal/completed/cancelled requests do not reopen.
Passed stops, departed origin, terminal runs, revoked driver access and exact
server deadlines expire unresolved requests. Current expiry defaults are described
in [the local walkthrough](local-validation.md#local-run-bound-boarding-assistance-2026-10-16).

The local bounded worker scans open v2 requests and persists handover audit/outbox
intentions. Driver inbox is paginated, rider history starts with newest publications,
and cursors cannot reference another rider's records. Views poll the authenticated
API every 15 seconds and distinguish failures/last receipts from confirmed state.
V2 direct client mutations are denied; the local config also closes legacy creation
as a bypass. Normal/Sample rules and trusted state remain independently scoped.

In-app inbox availability is implemented. Push notifications, guaranteed driver
attention, hosted worker uptime and a full active-trip handover UI are not claimed.
The actual-token smoke performs a synthetic stopped-bus assignment change; active
request retargeting is covered with matching trusted operation fixtures. Full
native two-device/TalkBack/background acceptance remains outstanding. See plan
checkpoint 28 for verification and deployment limits.

Local checkpoint 29 adds the active-trip transfer workflow: Admin -> overflow ->
Active trips. Its trusted transaction transfers the run, trip, bus and driver
locks, pauses GPS and records a reason/audit. The new driver explicitly accepts
with fresh GPS. Requests follow current run authority immediately; bounded
reconciliation resets acknowledgement, including when multiple transfers return
to the same driver before the worker runs. A superseded worker job cannot restore
an old assignee. No existing acknowledgement proves acceptance by the replacement.
Actual local Auth/worker smoke now covers this active transfer, not just stopped
bus assignment (`phase15-auth-smoke-final.log`). Push/provider delivery and native
background/two-device acceptance remain outstanding. See checkpoint 29 and the
local active-trip handover walkthrough for scope and verification.

Checkpoint 30 adds local notification dispatch preparation. New outbox events can
produce a private, deduplicated **simulated** receipt through the local worker.
The registry supports locale, removal, account rebinding and generation checks;
delivery attempts use leases and bounded retries. Old notifications must reload
current driver/run/assignment authority before exposing request details. A staged
FCM adapter sends generic text and an opaque event ID, never rider/location data.
Neither adapter receipt nor simulation acknowledges the assistance request.

Actual-token simulation passed in `phase16-auth-smoke.log`. Firebase Messaging
is not wired into Flutter app startup/token refresh/OS permissions/receivers or
navigation yet. Real FCM hosting/project/provider delivery and native background
acceptance remain outstanding. See checkpoint 30 and the local notification
simulation walkthrough; no background phone notification is claimed.

Checkpoint 31 adds staged Android Messaging callbacks, channel, opt-in/token/
logout lifecycle and driver notification request navigation. Every open reloads
current authority; account/opt-in withdrawal clears private on-screen details.
No background callback accepts requests or loads passenger information. Generic
foreground prompts and notification controls have en/si/ta resources. The native
plugin compiles with auto-init disabled, while the explicit activation gate remains
closed without a dedicated reviewed Firebase test project and trusted v2 host.
Normal/local builds do not contact FCM or show new opt-in controls. Real token/
provider/background/two-device/TalkBack acceptance remains outstanding. Refer to
plan checkpoint 31 and the local walkthrough for exact automated/build evidence.
