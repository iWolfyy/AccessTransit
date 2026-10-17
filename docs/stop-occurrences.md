# Repeated stop visits and loop patterns

Local implementation, 2026-10-17. No shared data migration/deployment is implied.

`stops` remains the ordered **unique visit/occurrence IDs** used by timetables,
run/trip stop-time maps, progress, geometry and fare-stage mappings.
`stopStationIds` resolves those visits to physical `stations` document IDs.
Legacy records without that map keep their original IDs: visit ID = station ID.
Never create a fake station document to represent a second visit.

For example, `stops: [a, b, a-return, c]` and
`stopStationIds: {a: a, b: b, a-return: a, c: c}` retain separate arrivals at
`a` and `a-return` while sharing stop A's coordinates, capability and reports.
IDs are opaque. Their spelling does not establish direction, platform or time.

## Administrator editing and schedules

The route editor allows adding the same physical station again. A new visit
gets a unique ID; existing visit IDs are preserved when reordered. The bus
editor selects exact route visits and keeps a separate time controller for each.
Moving a visit moves its time. The bus visit sequence must follow the selected
route and resolve to the same physical stations. Existing bus visit IDs cannot
be rebound to another station; use new IDs and review dependent schedules.

Dated runs capture the mapping and separate stop-time entries. Recurring
calendars compare mappings as part of their captured itinerary. A changed
mapping requires a reviewed replacement calendar. `physicalStopIds` supports
catalogue dependency checks; repeated physical stop reports are not duplicated.
Existing routes/runs/bookmarks are not automatically converted or rewritten.
Do not bypass active-operation guards to change a bus itinerary.

## Search, details and bookmarks

Search takes physical boarding/destination stations and enumerates every valid
ordered visit pair. For A → C above, boarding at visit A or A-return yields
distinct timed options. B → A selects A-return. After progress passes the first
A, that opportunity is excluded while A-return remains eligible when supported
by fresh GPS/progress. Existing 24-hour, clock and stale-data checks still apply.
The existing same-origin/destination search guard is unchanged; this extension
supports repeated visits within journeys between distinct physical endpoints.

Results retain the selected visit IDs, intermediate visits and corresponding
times. Repeated patterns add route stop positions to their result summary.
Details/saved trips use those exact IDs, not the first name/physical-ID match.
Bookmark IDs include the chosen visits, so the two boarding opportunities do not
overwrite each other. Compatibility fields named `fromStationId`/`toStationId`
in saved selections, and `boardingStationId`/`alightingStationId` in assistance,
carry the selected visit IDs; legacy single-visit values remain unchanged.

Physical station names/coordinates are resolved for display. Accessibility and
community report queries use physical station IDs, including the scoped report
browser and retry path. A report about A applies when the selected segment
contains A-return. An occurrence ID is not a new public reporting target.

## Operations, assistance, geometry and fares

Trip progression and stop-time updates operate on unique visits. Arriving at
A-return does not overwrite A's time or end the trip early; actual final-stop
completion releases the operation lock and GPS as before. Driver stop names
resolve through the physical mapping.

The trusted v2 assistance backend validates selected visit order and resolves
the target physical station from the run's mapping. Requests retain server-owned
boarding/alighting/stop indexes; passing the first A does not expire a request
for A-return. Driver request cards/push detail show the server-supplied route
stop positions. No client-supplied driver/position fields grant authorization.
The legacy v1 assistance path has no full run/visit contract; use the trusted v2
activation for repeated-visit assistance rather than claiming v1 equivalence.

Reviewed geometry and fare mappings use the same ordered occurrence IDs. Geometry
review validates each vertex against its physical stop, so the path may return
to the same coordinates at a later vertex. Live projection remains constrained
to the recorded current leg; it cannot jump to the passed occurrence. Full
ordered-pattern matching is still required for moving ETA/geometry. An old
physical-stop-only fare mapping cannot invent a quote for a new return visit;
publish a reviewed occurrence-stage mapping or retain Fare unavailable.

## Validation limits

Automated coverage includes route editing at 320dp/200% text, loop pair matching,
passed-first/future-second boarding, return-leg geometry ETA, distinct bookmarks,
physical report relevance, exact assistance targeting and production transaction
callbacks through final completion. Rules/backend tests cover physical station
resolution, fake visit denial, both scopes and later-visit assistance expiry.

The local-token smoke `test/security/verify-local-loops.mjs` creates unique
fictional route/bus/visit records and tests bookmarks/assistance against the
loopback API. Its progress changes are trusted fixtures, not measured GPS motion.
It loads local rules without clearing the database. Named synthetic fixtures are
initialized only for the restarted empty Auth environment. Real catalogue
migration, native GPS/TalkBack, fluent translation review and live rollout remain
separate gates. Calendar Sinhala/Tamil UTF-8 strings were corrected; Unicode
regressions cover all calendar and new occurrence wording.
