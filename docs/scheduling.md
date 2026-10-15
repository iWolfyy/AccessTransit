# Timetable and actual trip times

F18 uses `OrderedSchedule` for passenger segments, operator trip initialization
and ETA timetable comparisons. Timetable clocks use local calendar dates.
Supported clocks are `HH:mm` (00–23 hours) and `h:mm AM/PM` (1–12 hours).
Invalid clock values reject passenger options/operator starts instead of
normalizing into another hour/day. A decreasing clock advances to the next
calendar day; equal clocks retain the same instant. Month/year boundaries and
multiple midnight crossings are retained.

The passenger's selected date is their boarding date. If boarding is after
midnight, the full itinerary can consequently start on the previous day. Depart-now
can select the next daily service; explicit date/time searches do not silently
roll an earlier boarding to another day.

Operator `departureTime` is actual departure. For a timetable-backed start, the
initial estimates equal the ordered planned times plus actual-minus-planned
departure offset. The trip stores `scheduledDepartureTime` separately from
`actualDepartureTime`; the first stop records actual departure. Later arrival
confirmations retain their observations and adjust remaining estimates. Retry/resume
retains the acknowledged trip rather than restarting its timeline.

Without an explicit `serviceDate`, the operator service infers the daily start
nearest actual departure: times more than 12 hours away move to the adjacent day.
For example, a 23:50 service started at 00:05 retains yesterday's planned departure
and shifts a planned 00:10 arrival to 00:25. An early 23:55 start for a 00:10 service
uses tomorrow's planned departure. The optional service date overrides inference
for unusually late/early runs. The dashboard displays planned and actual dates;
there is currently no operator run/date picker. Multiple daily runs or delays
beyond that inference window need an explicitly reviewed service date/integration.

Missing trailing intervals use a six-minute model estimate in both flows. These
are not authoritative timetable observations. An interior gap followed by another
supplied time is rejected so an invented interval cannot push that time into a
false extra day. With no timetable departure, the operator trip keeps planned
departure Unknown and estimates from actual departure. Results/details/confirmation
disclose model times; operator UI explains the estimate policy. ETA comparisons
show Unknown for stops without supplied timetable times. Date-qualified labels
identify tomorrow/other dates separately from live delay classification.

Validation is local automated testing, not confirmation of real timetable accuracy,
physical movement or cross-device delivery. No live timetable migration, deployment
or device test was performed for F18.

F22: search results are timetable planning cards. Their Scheduled/Demo timetable
labels and departure/arrival times never infer vehicle movement from a departure
countdown or a recorded active trip. Cards explain that departure is unconfirmed
and direct riders to route details for GPS status. Near/passed departure labels
remain explicitly scheduled, including when the clock changes without a backend
event. Result selection carries the same timetable provenance into details.
The previous isLive/liveStatusLabel result fields and elapsed-trip departure badge
have been removed. Results do not subscribe to GPS or claim a current departure;
route details/live journey retain their separate acknowledged, matching-bus,
fresh-timestamp GPS checks and stale/offline labels introduced in F19.
