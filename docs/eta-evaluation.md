# Local prediction-versus-arrival diagnostics

Checkpoint 35 adds opt-in measurement to the separate **Local Test** build.
It is disabled in normal/release builds and makes no Firestore/API writes. It
does not enable production analytics, hosted collection or fleet-wide monitoring.

Open a selected trip's **Bus Details -> Local ETA diagnostics** (chart icon).
Enable Capture local forecasts, return to Details and keep that selected run
open while its fresh GPS and driver stop confirmations arrive. Both screens may
remain in the navigation stack. After arrivals, reopen diagnostics to inspect
separate timetable and geometry/timetable summaries. **Copy diagnostic JSON**
exports the current account's dataset; Clear deletes that account's local ledger.
Storage failures are explicit and do not masquerade as acknowledged saves.

Capture starts only after opt-in and account preferences/storage initialization.
The Details view requires its trusted time receipt, an acknowledged matching
run/trip/bus/driver and fresh valid GPS for new forecasts. Geometry forecasts use
the exact shared `RouteProgressEta` result shown by the passenger flow. The
baseline is the selected dated run's immutable timetable. Known stop arrivals
cannot be used to manufacture retrospective predictions. Normal builds show no
diagnostic action and perform no capture or diagnostic persistence.

Forecasts are immutable per run/target/source/minute, retaining generated time,
predicted arrival, optional interval, source/algorithm version, geometry version,
route/run/bus/stop IDs and service date. Account UID is used only for the local
storage key. Raw coordinates, driver IDs, emails and continuous GPS trails are
not persisted. At most 500 forecasts are kept; oldest-first capacity drops are
counted. Seven-day retention is applied on the next valid capture/observation,
not by a background deletion service. Signing into another account immediately
clears the in-memory view and loads that account's separate ledger. Old async
loads/writes cannot publish their state into the new account's view.

Only matching acknowledged trip updates resolve forecasts. The reference is
**the driver's reported `actualArrival` timestamp**, not a physically verified
GPS arrival, server write timestamp or proof of accessibility/boarding. Driver
clock skew and delayed confirmation can bias these measurements. Future or
pre-prediction arrivals, later corrections/removal, cancellations and terminal
runs missing arrivals are excluded explicitly. Pending/excluded rows never
become zero-error successes. A disconnected/closed Details view can leave records
pending; reopening the exact run can match its later acknowledged stop history.

Summaries group by source, algorithm version, geometry version, exact route and
actual lead-time bucket (0–5, 5–15, 15–30, over 30 minutes). Each run/stop/source/
bucket contributes its **first** forecast, preventing repeated rebuilds/high-rate
GPS from overweighting the same target. No best-error prediction is selected.
The two sources are reported separately; unequal sample coverage must not be
interpreted as a controlled accuracy comparison.

- Median absolute error: middle absolute error, averaging the two middle values
  for even sample sizes.
- P90 absolute error: nearest-rank value at `ceil(0.9 * n)` in sorted absolute
  errors, not an interpolated or rounded minute estimate.
- Signed mean error: predicted arrival minus reported arrival, in seconds;
  negative means an optimistic/early prediction.
- Interval diagnostics export covered/count observations for geometry's existing
  heuristic range. This is not calibrated confidence coverage.

Every summary includes matched sample and distinct-run counts. Fewer than twenty
samples is labelled a small sample. Twenty synthetic samples still do not prove
real-world accuracy. Capacity/retention/closed-screen/invalid-clock exclusions
create selection bias; retain counts and provenance when comparing results.

Replay exported JSON with the same measurement code, without trusting exported
summary numbers:

```powershell
flutter test test/eta_evaluation_replay_test.dart --dart-define=ETA_EVAL_INPUT=D:/path/to/local-export.json --reporter expanded
```

The replay validates schema/size, recomputes groups and prints counts/summaries
without uploading data or writing another file. With no input flag it checks the
fictional `test/fixtures/eta-evaluation.local.json` fixture. Its sample 120s/45s
errors are software test values, not measured AccessTransit route performance.

Remaining: independently timestamped device/road arrival references, trustworthy
GPS accuracy/sequence and multi-fix motion, reviewed operating geometry, historical
segment/dwell models, server-owned ingestion/privacy/retention/rollout design and
actual route/time-of-day evaluation. This local dataset must not automatically
train the model or justify a production accuracy percentage. Native TalkBack,
fluent Sinhala/Tamil review and real two-device road testing remain pending.
