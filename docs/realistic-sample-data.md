# Realistic fictional walkthrough data

Loaded on 2026-10-17 into Firebase project `accesstransit-b615b`, exclusively
under `sample_test/shared/`. These are fictional operating conditions, schedules,
vehicles, fares and GPS snapshots. Existing place names provide familiar search
examples; coordinates are approximate scenario anchors and geometry is synthetic.
None of this establishes a real bus, reviewed road path or official fare.

## Open the data in the main app

Stop the current debug session. In VS Code Run and Debug select
**AccessTransit: realistic SAMPLE data (same app)** and run it. This uses the
existing application ID, Firebase sign-in and app screens, with a visible
Sample/Test banner. It does not introduce a second APK/package. A hot restart of
the normal launch configuration does not change its compile-time data scope.
The original real-Firebase launch configuration remains available.

The localhost server now supports an explicit Sample scope opt-in:

```powershell
node test/security/serve-shared-backend.mjs --sample
```

The default server command still accepts normal scope only. The running server
was restarted with `--sample` and verified ready for both scopes. Sample Auth
disable/delete/revoke remains prohibited; it must never modify shared Auth.
The normal background reconciliation worker does not process Sample jobs.

## Initial coverage

Batch `walkthrough_20261017T1200` wrote and verified 470 records, including:

- 14 directed routes, 22 stops, 42 fictional physical buses and 258 dated runs.
- Three equipment variants per route: working, faulty and unknown; low/medium/high
  occupancy. Initial scheduled departures cover six opportunities across the
  next 24 hours; boarding eligibility still follows the selected stop and time.
- 42 v2 reports with corresponding +10 publication ledger entries. Other accounts
  can exercise True/False voting; no confirmer reward is seeded.
- 14 synthetic fare publications and 14 synthetic route geometries.
- Five account-owned saved trips and four pending assistance requests bound to
  assigned sample drivers and dated runs.
- Two matched active run/trip/lock/GPS scenarios: one initially fresh and one
  30 minutes stale, plus four completed/cancelled run examples. Snapshots never
  receive an artificial heartbeat; they age naturally. End the seeded operation
  in the driver workflow before starting another bus under that driver's lock.
- Sample-only route grants, missing profile/config initialization, and eight
  explicit legacy sample balance baselines. Existing summaries are preserved;
  historical sample totals do not acquire retroactive strikes.

Try **SAMPLE - Badulla → SAMPLE - Bandarawela**, and the reverse direction.
The actual Flutter dated matcher and wheelchair/step-free filter were checked
against this segment. Other examples include Panadura ↔ Kandy and
Makumbura ↔ Badulla, using the stop occurrences supplied by those routes.
An endpoint-only route still has only its two supplied stops; the seed does not
invent all possible direct connections between unrelated stops.

Real push/device delivery, destructive Auth operations, human language review and
native accessibility QA are not established by loading fixtures. Photos can be
tested through the existing picker/upload flow; no third-party photo was seeded.

## Refresh without resetting activity

Dated runs and positive observations expire naturally. The following prepares
a new batch; the default invocation is read-only:

```powershell
node test/security/seed-realistic-sample.mjs
node test/security/seed-realistic-sample.mjs --apply
node test/security/initialize-sample-balances.mjs --apply
```

Each applied batch uses new vehicle/report/run IDs. Reusing an already applied
batch ID fails instead of resetting activity. Existing user-created sample
records and active driver locks are preserved. Only identified fixture catalogue
rows can be refreshed, guarded by update-time preconditions. Baseline setup only
creates missing summaries and retains old sample points; it never resets a
summary or changes normal balances. No deletion or Auth account creation occurs.

Private plans, before-images and verified receipts are under
`.private/realistic-sample/` (ignored by git). The main batch committed atomically
and verified the normal catalogue/profile/authorization/configuration fingerprint
was unchanged. No hosted deployment, billing change or APK build/install occurred.

Validation: 29 scenario/runtime/API tests passed (`phase59-backend-tests.log`).
An additional Flutter contract check parsed all prepared run, bus, geometry and
fare models and confirmed the screenshot's accessible segment
(`phase59-model-tests.log`). An attempted emulator moderation suite could not run
without its Firestore emulator; it is not included in these passing counts.
