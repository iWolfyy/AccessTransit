# Admin scheduling language and loading states

Implemented 2026-10-17 in the main Flutter app. Dated departures now localize
publication/cancellation controls, start-window/rescheduling guidance, service
date, Colombo departure, run status, private late-start reason label and
published stop times. Authored reasons remain unchanged. Times retain the
Asia/Colombo conversion and overnight dates; Flutter locale formatting changes
presentation only. Unknown run/calendar states show status unavailable rather
than claiming scheduled/completed/retired.

Calendar failures retain their actual exception and show the translated known
reason alongside existing recovery guidance. Shared scheduling validation
messages now cover invalid date ranges/calendars, timetable changes, reviewed
physical-bus requirements, rescheduling restrictions and active-operation
reconciliation. The existing 31-day calendar bound, weekday selection,
idempotent generation, schedule snapshots and -5/+30-minute start policy are
unchanged. No departures are generated merely by opening a screen.

Dated-run loading has a visible progress state and disables actions until the
request settles. Empty and unavailable states are distinct. A failed reload
clears old run/note rows, and a late older reload cannot overwrite a newer
result. Existing successful writes still require their service acknowledgement.

Automated coverage checks all three languages at 320dp/200% text, original
driver reason preservation, known/unknown status presentation, a stale calendar
that cannot generate runs, loading/action availability and failed-load versus
empty treatment. Existing publish/cancel, recurring calendar, overnight and
saved replacement regressions are retained. Fluent translation and native
font/TalkBack review remain due.

Fare/geometry tools and remaining operational/admin strings need their own
language passes. Fare/geometry progressed in
[fare and geometry admin language pass](admin-fare-geometry-localization.md).
No APK, shared Firebase mutation, backend deployment or billing
change is required for this source change.
