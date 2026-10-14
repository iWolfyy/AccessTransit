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
