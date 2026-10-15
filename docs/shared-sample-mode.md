# Shared Sample/Test mode

The same Android application can use an isolated rehearsal namespace in the
existing Firebase project. Normal mode uses the sourced catalogue. Sample/Test
mode uses `sample_test/shared/{collection}/{id}` and displays a permanent amber
**SAMPLE / TEST MODE** banner. Vehicles, observations, equipment checks, boarding
locations and GPS snapshots in this namespace are fictional and cannot establish
real accessibility or service operation.

## Run

Stop an existing `flutter run` session with `q`, then run from the repository root:

```powershell
flutter run -d emulator-5554 --dart-define=SAMPLE_TEST=true
```

Return to the normal sourced catalogue with:

```powershell
flutter run -d emulator-5554
```

This is a startup/build mode, not an in-app switch. Restart with the desired
command; hot reload/restart cannot change Dart defines. It uses the same application
package and existing Firebase Auth session, so a signed-in passenger can remain
signed in. The eight existing passenger/operator credentials are unchanged. New
account registration is disabled in Sample/Test mode. Auth/password operations
are still attached to those real shared-project accounts; the mode does not create
a separate authentication service. Do not enter sensitive notes or photos.

## Populated scenarios

- 22 timing points and 14 route directions copied from the sourced catalogue, with
  SAMPLE labels and synthetic accessibility assessments. Exact boarding coordinates
  remain unknown.
- 36 publisher timetable records and **16 fictional assigned sample vehicles**.
  Four interactive directions cover Panadura/Kandy and Makumbura/Badulla, both ways.
  Sample departure groups include working, faulty and unknown ramps, with low/medium/high
  crowding. `SAMPLE BUS 01` etc. are labels, not invented registration plates.
- 16 synthetic reports covering ramp access, elevators, crowding, cleanliness,
  safety, assistance denial and tactile paving; active/resolved and expired evidence.
  Three resolution audit records are included. Photos are absent.
- Eight assistance fixtures covering pending, acknowledged, completed, rejected
  and cancelled states; eight saved journeys covering open/completed history.
- Four trip fixtures and four static GPS snapshots, including stale and offline
  cases. Snapshots are not continuous simulated movement; normal freshness expiry
  applies. Operators can run the app's scoped GPS/trip controls during testing.
- Eight scoped profiles with sample contribution totals and four scoped operator
  approvals. The actual normal-mode approvals remain pending.

Seeding produced **143 records**. Subsequent real-backend verification added three
cancelled assistance validation records in the sample namespace. The normal root
records and authentication accounts were not modified by seeding/testing.

For a simple walkthrough, use passenger 1 and search **SAMPLE - Panadura** to
**SAMPLE - Kandy** shortly after fixture creation. Review **SAMPLE BUS 01** and its
reports, save a journey, send assistance, then sign in as driver 1 to acknowledge.
Driver 1 is assigned buses 01/05/09/13; driver 2 gets 02/06/10/14; driver 3 gets
03/07/11/15; driver 4 gets 04/08/12/16. Driver ordering follows the existing
account plan. Do not confuse a seeded acknowledgement with a new driver's response.

Each of the four primary directions retains an accessible full-route sample
option under wheelchair and step-free requirements. Faulty/unknown vehicle groups
remain available for warning/filter scenarios. Station barrier scenarios use other
timing points, so an unrelated demonstration fault does not hide every primary
route. An anonymized public-backend snapshot in
`test/fixtures/shared_sample_search.json` covers these combinations through
`test/shared_sample_search_test.dart`; refresh it with
`node test/security/export-sample-search-fixture.mjs` after reviewing new fixtures.

Ramp observations, reports, request retry windows and GPS timestamps age naturally.
Synthetic timetable slots are anchored to fixture creation. Reseed before a later
walkthrough if fresh examples are needed; expired data should correctly become
stale/Unknown. Unsupported app features remain unavailable. External Cloudinary
uploads are disabled and the report form offers text-only submission in this mode.

## Isolation and administration

Collection constants and explicit service paths cover profiles, approvals,
catalogues, reports/audits, journeys, trips, GPS and assistance. Catalogue cache,
personal travel preferences and both durable outboxes have separate storage keys.
Android report drafts remain encrypted in a separate no-backup file. Display
preferences and the Firebase Auth session remain shared intentionally. Changing
mode restarts the process/listeners, preventing an active operation from crossing
environments. This mode cannot be combined with `TRANSIT_DEMO` or `LOCAL_VALIDATION`.

The generated namespaced Firestore policy reuses the normal policy with scoped
references and requires a pre-provisioned sample profile for authenticated actions.
Generate it after editing the normal policy:

```powershell
node test/security/generate-sample-rules.mjs
```

Test the rules in an isolated local Firebase emulator before deployment. Never
remove the root policy or grant blanket sample writes. Sample operator approval
does not grant normal operator approval; passengers cannot approve themselves or
read another user's sample profile.

Administrative setup scripts require the owner's Firebase CLI session and private
eight-account plan. No credentials are embedded in application code or these docs:

```powershell
node test/security/seed-shared-sample.mjs
node test/security/seed-shared-sample.mjs --apply
```

Default is a read-only preflight. `--apply` creates the fixed fixtures atomically,
refusing an existing fixture ID. `--refresh` explicitly replaces only fixed fixture
IDs with update-time preconditions; it resets fixture profiles/counters/history and
should only be used between walkthroughs. It does not delete user-created sample
records. Backups/plans/results are private under `.private/shared-sample/`.

`verify-shared-sample.mjs` verifies eight sign-ins, owner-only sample profiles,
isolated approvals, a synthetic request/acknowledgement/passenger-read/cancellation
cycle, the deployed policy hash and an exact comparison of the unchanged normal
policy against the prior deployed source. Each invocation adds a cancelled sample
validation request; it does not write normal transit or profile records.

The first execution passed **50 local rules tests**, **3 Sample/Test Flutter
checks**, normal Flutter regressions and Android debug build (final counts/build
are recorded in the fix progress log). Shared-backend checks succeeded for all
eight accounts and the assistance lifecycle. No visual UI walkthrough or two-device
delivery test for this new mode has been completed yet.
