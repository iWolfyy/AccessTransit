# Reviewed geometry and timetable-paced moving estimates

Checkpoint 34 adds a local-tested baseline to the consolidated passenger flow.
It does not import a real operating road path, provide traffic information or
establish measured ETA accuracy. Existing OSM maps remain the map provider; no
new paid routing/traffic API is introduced.

Admin -> Route geometry accepts a route ID and JSON bundle. Use a reviewed,
directed road trace, its source/version, the complete ordered route stops and a
zero-based road vertex index for each stop. Preview the source, direction,
ordered stops and total distance, acknowledge review and give a reason of at
least ten characters. Publication checks the current route and station documents
inside the audited commit. Each stop vertex must lie within 100m of that station's
reviewed coordinates. An array of coordinate maps is stored in Firestore;
directly nested coordinate arrays are not a Firestore storage format.

The [local-only JSON example](route-geometry-example.local-only.json) is fictional
and contains placeholder IDs. It must never be converted into normal operating
geometry by changing `synthetic`. Replace its data only with reviewed evidence.
Coordinates use `lat`/`lng`; these are not GeoJSON longitude/latitude pairs.
The importer also accepts `[latitude, longitude]` JSON pairs and normalizes them
to maps before storage. The first and last stop vertices must be the trace's
first/last points; indices must strictly increase. Limits are 300 stops, 5,000
points, 10km per road edge and 1,000km total. Split or review unsuitable traces.

`route_geometries/<route ID>` holds the current version, provenance and review
reason. Only active trusted administrators can publish/withdraw; passengers and
drivers cannot write it. Corrections require a different version through the
admin service. Withdraw current geometry uses the entered route ID/reason and
sets `reviewed: false`, clearing passenger path/geometry estimates when received.
The UI is acknowledged, retains failed submissions for retry and records admin
actions. Review reasons are public catalogue metadata: do not include personal
information. Existing generic admin audit records identify actor/action/target;
this is not a full immutable geometry-version archive. Keep source revisions.

Readers require acknowledged snapshots and the current build's synthetic/normal
mode. Cached, pending, withdrawn, malformed or unavailable geometry yields no
road path or geometry ETA. The bus's full ordered stop list and exact route ID
must match; route-number similarity and partial city-name matches are not used.
This initial schema does not migrate repeated physical stop IDs/loop occurrences
or buses operating only a subset of a reviewed route pattern.

For fresh matching active run/trip/driver GPS, projection is restricted to the
driver's recorded current road leg. Fixes over 100m from it, ambiguous crossings,
invalid speed/coordinates, future/stale (>30s) timestamps, cached/offline telemetry
and wrong run identities fail closed. The recorded stop index must still precede
the target. Advancing the driver's stop progress remains essential: the matcher
does not jump to another leg when progress is missing. Future/scheduled/terminal
runs never acquire a moving ETA merely because the same bus broadcasts elsewhere.

The baseline estimates the remaining current-leg time by its **remaining road
distance fraction of the reviewed run's timetable interval**, then adds later
timetable intervals. It never divides straight-line distance by a fabricated
20km/h speed, and does not extrapolate instantaneous speed. Stopped-between-stop
GPS cannot support this moving estimate. The existing stationary-at-recorded-stop
search fallback remains separate and explicitly timetable-based.

Results shows the boarding estimate; Bus Details recomputes the destination
estimate from the same algorithm and draws only the selected segment's road path.
Times, fare applicability and saved timetable selections are not rewritten as if
they were measured arrival times. Ranges use a heuristic ±30% allowance, with a
minimum of one minute and a lower bound of now. **This is not a calibrated
confidence interval.** UI labels explicitly say low confidence; there is no ETA
accuracy percentage claim. Sinhala/Tamil labels still need fluent review.

Remaining work includes reviewed real route traces, re-review after station/route
changes, GPS observation accuracy/sequence and multi-fix motion/direction checks,
smoothed motion and observed dwell/segment travel times, immutable historical
geometry provenance, prediction-versus-arrival collection and measured median/P90
errors. Legacy `EtaService` compatibility surfaces still use their prior algorithm;
this integration targets Search -> Results -> consolidated Bus Details. Physical
background-GPS, TalkBack and two-device road validation remain pending. Real FCM
testing stays deferred as requested. No production rules/data deployment occurred.

Checkpoint 35 adds [opt-in local ETA evaluation](eta-evaluation.md) using the exact
shared geometry prediction and acknowledged driver-reported arrival timestamps.
This supplies a diagnostic measurement/replay tool, not the independent real-world
arrival ground truth or measured operating accuracy still required above.
