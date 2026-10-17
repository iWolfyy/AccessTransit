# Dated replacements and saved timetable history

Local implementation, 2026-10-17. No shared deployment or historical backfill.

## Administrator workflow

In Admin → Buses → Dated departures, choose the replacement Colombo date/time,
then Publish replacement on an unreplaced scheduled/cancelled run. Review the
dialog and enter a **public** reason (5–300 characters). Private late-start notes
remain separate and are not copied into this history.

`AdminService.rescheduleServiceRun` atomically cancels the original, creates a new
dated run with `scheduleVersion + 1`, links `replacementRunId` / `replacesRunId`,
and appends `service_run_changes/<previousRunId>` with the original/replacement
departure/version and public reason. The normal private admin audit also records
the action. Original planned departure and stop-time snapshot are retained.

Publication treats timetable clock fields as timezone-neutral civil values before
converting explicitly from Colombo into UTC, including midnight rollover. A
different administrator device timezone/DST must not normalize those clock fields.

The transaction guards the current reviewed bus/route, previous run, matching
trip, replacement slot and absent history entry. A concurrent start/publication,
stale editor or failed commit cannot partially cancel the original. Started
operations must use the existing reconciliation/handover workflow. Another bus
run already occupying the replacement timestamp is not overwritten. A chain can
continue by replacing the new scheduled run; one predecessor cannot fork into
multiple replacements. The existing −5/+30 minute start policy is unchanged.

Plain cancellation remains available. Calendar retirement does not cancel runs;
generation preserves cancelled/replaced slots instead of resurrecting them.
This is per-dated-run replacement history, not a recurring-calendar migration or
an unattended bulk rescheduler.

## Passenger history

New Save Trip records include `scheduleSnapshot`: the selected ordered visit
IDs, physical mappings, names, available stop times and acknowledged run version.
Intermediate times absent from the selected source remain explicitly unknown.
Fare/version and selected accessibility needs remain in the existing parent
journey fields. Opening details or selecting a result still performs no save.

Retries retain the first acknowledged snapshot. New catalogue labels are not
used to overwrite it or create a duplicate bookmark. Existing owner-only read,
remove, status updates and account-change gates remain in effect. Rules validate
snapshot shape/endpoints/times and a supplied version against its service run;
clients cannot update a saved snapshot or rewrite append-only public change
history.

Bus Details watches the original run ID. Cancellation, a published replacement,
public change reason, or a timetable/version mismatch is explained without
moving the bookmark to another service. Replacement wording records that a
replacement was **published**; it does not claim that replacement is still
available, active or serving the rider. Search again to review current options.
GPS remains gated by exact selected run/timetable matching and fresh telemetry.

When the selected bus/route/segment is unavailable or changed, the same Bus
Details destination shows an original saved timetable record with its stop
timeline, saved fare when available, original run status/replacement notice and
Remove saved trip. It does not certify current accessibility, show live GPS or
offer assistance for that unavailable selection. Run subscriptions are shared
across the normal/historical presentation with the last receipt retained, and
are cancelled when the screen is disposed.

Legacy bookmarks without `scheduleSnapshot` keep the previous restore/retry or
replan behavior. Missing old intermediate names/times are not fabricated and old
records are not silently rewritten. A complete historical backfill/template
replacement lineage and real data migration remain separate work.

## Validation

Flutter tests exercise atomic replacement/version chains, stale-start/failed
commit rollback, saved selection preservation after catalogue changes, snapshot
retry idempotency, original cancellation/replacement notices and 320dp/200% text.
The existing loop, fare, assistance, saved-list and journey suites remain part of
the full regression gate. Rules tests cover version/time forgery, private saved
records, denied snapshot updates and append-only public history in both scopes.

With the local demo Auth/Firestore emulators running, set the documented emulator
variables and run `node test/security/verify-local-schedule-history.mjs` from root.
It loads local rules and creates unique fictional records, checks actual-token
normal/Sample snapshot receipts and an atomic linked replacement/history, and
verifies original saved time/version and denied rewrites. This checks the rules
contract; the production Dart service/transaction implementation is exercised by
Flutter tests. No database reset, shared Firebase write, billing or real push
activation is involved. Fluent Sinhala/Tamil and native accessibility review are
still required.

Deploy the compatible reviewed rules before releasing clients that send
`scheduleSnapshot`; this local implementation does not imply shared activation.
