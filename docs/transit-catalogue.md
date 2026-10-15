# Transit catalogue modes and provenance (F12)

For an interactive rehearsal with synthetic vehicles/reports/assistance in the
same Firebase project, see [Shared Sample/Test mode](shared-sample-mode.md).
It is separately namespaced; the read-only `TRANSIT_DEMO` flag below is unchanged.

## Shared catalogue expansion, 2026-10-16

After the user selected source-backed shared data rather than synthetic demo reports,
an additive import added 17 timing points, 12 route directions and 32 published daily
runs from [NCG Express](https://ncgexpress.lk/bus-timetables/). Current totals are
**22 timing points, 14 route directions and 36 published timetable records**.
These are timetable runs in the `buses` collection, not 36 verified physical buses.
New directions cover Soysapura/northern services, Panadura/Kankesanthurai,
Colombo/Passara, Panadura/Kandy and Panadura/Nittambuwa.

The [source transcription](catalogue-review/expanded-timetables.json) preserves
published times, including six overnight runs. Ambiguous AM/PM return entries,
rotation-only services without departure times and the duplicate Kandy 09:00 run
were excluded. Differently named Jaffna timing points remain distinct because
their exact boarding locations are unknown. Endpoint-only routes do not imply
non-stop service. Publication date and current operation are unverified.

The create-only import script is `test/security/expand-shared-catalogue.mjs`.
Default invocation is a read-only preflight; `--validate` checks local data,
`--apply` creates missing records atomically with `exists:false` preconditions,
and `--verify` compares the original snapshot and verifies public reads.
All 61 new records were read back; original 11 catalogue records retained their
fields and update times. Public app reads returned 22/14/36 records. A verification
comparison initially rejected Firestore's JSON-null representation; normalizing
the equivalent null enum resolved it, and read-only verification passed without
reimporting records. Private before/plan/result evidence is Git-ignored under
`.private/catalogue-expansion/`.

Accounts, approvals, existing records, reports, GPS, rules and passenger preferences
were not modified. No observations, vehicle registrations, fares, equipment checks
or driver affiliations were invented. Four focused Flutter tests passed, including
planning every timing-point pair in the new data and midnight rollover. The new
test's analyzer found no issues. For a simple search, choose Panadura to Kandy,
a future date and a time before a published departure; accessibility requirements
still require evidence that these timetables do not supply. Refresh Plan's catalogue
to obtain new data; no APK rebuild is needed for this import.

Default shared mode starts with no invented buses, routes or stops. Empty/error
reads never substitute SeedData. There is no automatic startup/search/debug cloud
seeding. Shared mode quarantines records marked `isDemo: true` or
`catalogueSource: demo`, plus known historical seed IDs without an explicit
administrator-reviewed `catalogueSource: operator_catalogue` designation.

An acknowledged catalogue means the server returned the record; it does not prove
that a bus is physically running, that a timetable is official, or that equipment
works. Equipment observations keep their original time/source and separate expiry
rules. GPS, equipment, fares and timetable estimates remain distinct evidence.

## Explicit read-only demonstration

For a sample-data walkthrough, run:

```powershell
flutter run --dart-define=TRANSIT_DEMO=true
```

Demo mode displays a persistent DEMONSTRATION notice and sample timetable wording.
It reads local sample catalogues, never a shared transit catalogue or live GPS.
Reporting/photos, community mutations, assistance, operator GPS/trips/assignment
and passenger journey writes are blocked at their service boundaries. Report/photo
submission and journey confirmation controls are disabled. Restored sender outboxes
do not auto-retry in demo mode. Authentication/profile functionality remains separate;
the demo flag is not a Firebase security control or an operator approval bypass.

`SeedData.seedAll` is now an unused development utility, marks catalogue writes as
demo, and no longer deletes existing catalogues. Do not run it against production.
No seeding, relabelling or live database migration was performed for this fix.

## Acknowledged offline cache

TransitCatalogue accepts only server snapshots without pending writes or cache-only
metadata. It persists public catalogue records, original observation timestamps,
provenance and collection receipt time under `acknowledged_transit_catalogue_v1`.
The serialized cache is bounded to 2 MiB; an oversized cache is removed rather than
leaving a misleading old disk snapshot. It contains public records, not private
journeys, report photos or assistance notes. Storage retention for those is F20.

Authoritative full snapshots replace the collection, including an empty result;
deleted individual records are pruned. Failed/offline/pending/SDK-cached reads use
only this previously acknowledged cache. No saved records means unavailable/empty.
Individual reads do not renew a complete catalogue's receipt or its source status.
The app-wide notice distinguishes shared empty, unavailable, saved and demo data.
Saved timetables/availability may have changed; receipt time is not equipment-check
time. Manual refresh retries reads and never writes seed data.

Plan Journey refreshes stations, routes and buses together on entry and retry.
The shared saved/unavailable notice also offers Refresh for all three collections.
Restored cache alone is not evidence of a failed connection: its wording asks for
refresh rather than asserting updates are unavailable. A failed server read keeps
the cache notice; successful full-catalogue acknowledgement clears it.

## Review and rollout

Before populating a real catalogue, the project administrator must verify each
service identity, route direction/stops, timetable source and equipment capability.
Previously seeded IDs require this review before marking them operator_catalogue.
Do not bulk relabel all sample records, fabricate equipment-check timestamps or
present sample schedules as official. Marked demo buses/stops cannot receive real
reports/assistance/operator writes under the updated local rules. The app also
quarantines unmarked historical seed IDs; the rules do not hard-code that ID list.

The current backend may consequently show no services until a reviewed catalogue
is supplied. This is the intended shared-mode behaviour. Local fixtures in
`test/flutter_test_config.dart` explicitly provide data for older planning tests;
they do not enable production fallbacks. Real-device offline/reconnect behaviour,
live catalogue review, deployment, GPS and two-device validation remain pending.

## Shared-project investigation, 2026-10-15

Read-only REST requests to the configured `accesstransit-b615b` public catalogue
succeeded without authentication. The server returned 21 station, 9 route and 29
bus records. Every returned document ID matches a historical SeedData ID, and
none supplied `catalogueSource` or `isDemo` provenance. Under the existing F12
policy, these unreviewed legacy IDs are excluded from the usable shared catalogue.
The visible empty-catalogue notice therefore does not mean the remote collections
are physically empty. This read check does not verify write authorization or
establish which rules are deployed.

Selected public identity/schedule/capability fields were saved in
[pending-catalogue.json](catalogue-review/pending-catalogue.json) for review.
Driver/user identifiers and telemetry were excluded. Every entry remains pending
with no source evidence. Matching IDs establish the quarantine reason, not that
the real-world station/service details are correct or incorrect. No cloud records
were changed and no legacy record was relabelled as reviewed. The user must
identify whether this is assignment sample data or provide actual service source
evidence before selecting the appropriate catalogue setup.

The user subsequently confirmed these are **assignment sample data only**.
The selected walkthrough setup is the existing explicit `TRANSIT_DEMO=true`
build on the original Android package, with a persistent DEMONSTRATION banner
and sample catalogue. This does not approve or relabel the shared records.
Shared catalogue/report/assistance/operator writes remain blocked in this mode;
the separately installed local validation build is used for synthetic end-to-end
write testing. A default build without the flag still applies the shared-catalogue
quarantine above.

## Current shared setup after approved reset

The subsequent user-approved reset on 2026-10-15 removed the legacy catalogue and
all old Firestore/Auth records after backup. The original Android package now
runs the normal shared build, without TRANSIT_DEMO or LOCAL_VALIDATION flags.
Shared data contains five publisher-named timing points, two route directions
and four NCG published timetable runs, with source/retrieval metadata. These are
`published_timetable` records with **Vehicle unassigned**, not approved physical
buses or confirmed operating trips. Equipment, occupancy, exact boarding locations
and real driver affiliation remain unknown. Driver accounts have pending approval.
See the [source dataset](catalogue-review/published-timetables.json) and
[approved reset execution](catalogue-review/shared-reset-plan.md).

The historical pending-catalogue snapshot above records the removed legacy data;
it is not the current import. The explicit demo build remains available for
separate sample previews, but is no longer the installed original app mode.
