# Recurring service calendars (local implementation)

Open Admin → Buses → Dated departures → Service calendar. Select Colombo
service dates (at most 31 inclusive), operating weekdays and departure time.
Publish only after reviewing the physical bus timetable. The calendar captures
that itinerary; it does not change the bus's normal timetable.

Publish saves a private, immutable `service_schedules` version. Generate dated
departures explicitly materializes its matching days in one audited transaction.
Each new public `service_runs` record retains the existing overnight offsets and
fixed −5/+30 minute start window, and records `scheduleId` / `scheduleVersion`.
Drivers and passengers continue using the existing dated-run flow.

Generation uses the same deterministic bus/departure run ID as one-off publishing.
It preserves every existing slot, including a manually published, started,
completed or cancelled run. The result reports created and preserved counts.
Concurrent slot creation, calendar retirement, bus changes or route changes
invalidate stale transaction reads; failed generation cannot partially publish
its remaining days. Retry after reloading. A cancelled slot stays cancelled.

To replace a calendar, retire it and publish a new reviewed calendar. Retirement
only stops further generation: it does not cancel existing runs or saved trips.
Cancel unwanted unstarted dated runs separately using Dated departures; active
operations need the existing handover/reconciliation workflow. Changed bus stop
order/timetable/route requires a replacement calendar. Existing runs keep their
original snapshot and identity; this slice does not rewrite saved-trip history.

This initial calendar supports one departure time and weekdays per publication.
Use separate calendars for distinct daily times. A one-off cancelled run is an
exception retained by subsequent generation. There is no unattended scheduler,
holiday importer or automatic rolling extension; administrators explicitly
generate the bounded date range. Calendar retirement and run cancellation remain
separate actions. The existing catalogue/run loading APIs are still used; admin
collection-query pagination remains a scaling follow-up.

Only an active trusted-claim administrator can read or publish calendars. Rules
permit only a published → retired state change, deny deletion and deny public,
passenger and driver reads/writes. Rules are mirrored into Sample/Test scope.
The captured bus snapshot is private; public runs do not copy it. Catalogue
deletion checks retain bus, route and stop references from calendars.

New controls and messages have English, Sinhala and Tamil resources. Fluent
translation review and native accessibility review remain required. No real
calendar, shared rules deployment or production data change is implied.
