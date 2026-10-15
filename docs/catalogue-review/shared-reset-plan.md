# Shared backend reset plan and execution - 2026-10-15

Target: `accesstransit-b615b`. **Applied after explicit user approval; backend accounts, inventory and deployed rules verified.**

The user explicitly requested deletion of all Firestore and existing Firebase Auth accounts, followed by four passenger and four operator accounts. The latest visible passenger addresses in the user's message take precedence over the old mailto targets. Requested account inputs, password/import payloads, UIDs and the exact reset plan are private and gitignored under `.private/firebase-reset/`; no credentials are recorded here.

## Inventory before reset and backups

The recursive administrative inventory contains **128 Firestore documents** across boarding_requests (9), buses (29), connection_test (1), journeys (13), live_locations (9), reports (13), routes (9), stations (21), transport_stops (1), trips (8) and users (15). Firebase Auth contains **16 accounts**.

Firestore document content, paths and update times were saved; Auth accounts including password hashes/salts were exported, and the project's password restoration hash configuration was separately saved. Private backup directory: `.private/firebase-reset/2026-10-15T10-55-39.948Z/`. These files contain private data and must remain outside Git. This is a local administrative snapshot, not a managed point-in-time backup or a completed restore drill. Cloudinary media and external storage are outside this Firestore/Auth reset scope.

`execute-shared-reset.mjs` defaults to a **read-only preflight**. It verifies project identity, backup/input/rules hashes, current account IDs and every Firestore document update time. The deletion batch uses update-time preconditions, so a changed Firestore document prevents that atomic delete. Remote apply requires the exact plan SHA-256, and a private journal records phases because Firestore and Auth cannot share a transaction. Unexpected concurrent records/accounts stop the procedure. Existing backup restoration would be an administrative recovery task, not an automatic undo.

## Replacement dataset

The [publisher's timetable page](https://ncgexpress.lk/bus-timetables/) lists daily Makumbura -> Badulla and reverse departures at 10:30 and 17:30. Selected timing points are Makumbura, Mattala, Wellawaya, Ella and Badulla. The [candidate data](published-timetables.json) records the source and retrieval date; its publication date is unknown. The detailed [outbound](https://ncgexpress.lk/makumbura-to-badulla/) and [inbound](https://ncgexpress.lk/badulla-to-makumbura/) pages were also inspected. The outbound detailed evening table has a non-monotonic Hali-Ela entry; it was not imported or silently corrected. Only the five unambiguous points on the summary were selected.

The plan creates **23 Firestore records**: 8 profiles, 4 pending operator approvals, 5 timing points, 2 route directions and 4 published timetable services. No vehicle registration, physical vehicle, real driver affiliation, occupancy observation, equipment check, exact boarding coordinates, community report or GPS/trip document is invented. Timing-point names do not establish exact boarding/accessible entrance locations. Intermediate stop coverage is incomplete.

The app distinguishes a `published_timetable` record from a vehicle, shows Vehicle unassigned and source information, suppresses an invented vehicle map, and does not infer Low crowding from unknown occupancy. Vehicle claims, accessibility writes, vehicle-equipment reports, assistance and broadcasting are blocked for these records by the candidate rules. Passenger journey saving remains allowed. Existing real vehicle records retain their earlier behavior. Driver role profiles do **not** establish NCG affiliation or permission to operate its vehicles: operator approval and assignment remain pending actual authorization.

## Verification and rollout state

- **461 Flutter tests passed** (`shared-reset-flutter-tests.log`), including three published-timetable regressions. A compile error and a missing live-screen vehicle label were corrected before the passing full run.
- **49 Firestore rules tests passed**, exit 0 (`test/security/published-timetable-rules.log`), on an isolated local project/port 8088. The original walkthrough backend on 8087 was not cleared. Two new authorization tests cover timetable read/save and rejected vehicle claims/equipment writes/GPS/reports/assistance.
- Full `flutter analyze lib test`: **No issues found**, exit 0 (`shared-reset-analyze.log`).
- Node scripts passed syntax checks. Final read-only preflight matched all 128 documents/update times and 16 account IDs; no cloud mutations were made.
- Normal Android debug APK (no demo/local flags) built with direct exit 0. Original package identity was checked with aapt. Candidate preserved as `build/app/outputs/flutter-apk/shared-backend-debug.apk`, with checksum in the private reset folder; not installed yet. An incorrect apply fingerprint was rejected before authentication or network operations.

The exact candidate plan fingerprint is saved privately in `plan-fingerprint.json`. The approval and execution below supersede the prepared-only state above. No verification/reset emails were sent by administrative account import.

## Approved execution and live checks

The user explicitly approved deployment/reset on 2026-10-15. The immediate read-only preflight again matched all 128 Firestore document update times and 16 Auth UIDs. Only Firestore rules were deployed; CLI exited 0. The published `cloud.firestore` release was read back through the Rules API, and its source SHA-256 matched the tested plan (`56cbd5621aa1804d2dd518356fec68a49f5f7fd2e35acb8f1dd5e4cbebe27937`). No indexes, Cloudinary configuration, Storage content or billing settings were changed.

The exact fingerprinted apply completed: all 128 old Firestore documents and 16 old Auth accounts were removed, eight requested Auth accounts were imported, and the 23 replacement Firestore records were created. The private phase journal ended at `complete`; final inventory was eight Auth accounts and 23 Firestore documents. The original backup remains separate and unchanged.

Real Firebase password sign-in succeeded for **all eight accounts**. Each could read its own correctly matched role/email profile; all eight attempts to read another account's profile were denied with HTTP 403. All four operator approval documents were readable only by their owner/admin policy and remained `approved: false`. Four public bus-catalogue records were verified as `published_timetable`, each with null driver assignment. No live-location, trip or report documents existed. These are actual shared-project checks; they do not verify operator writes, physical bus movement, photo uploads or simultaneous-device assistance.

The checksum-verified normal shared-backend APK was installed with `adb install -r` and launched successfully, with no demonstration/local-test banner. Existing local data was retained, including a stale cached old identity after server account deletion; the user was asked to sign out and manually sign in with a new account. UI automation did not handle authentication. The backend credentials were verified through API checks, not presented as a completed new-account UI login.

The user subsequently confirmed signing in manually with the new passenger and reaching Home. Home and Plan Journey were visually inspected: the new shared timing-point names loaded with no demo banner. Shared searches with Ramp Required active correctly showed no known-accessible matches; there are no dated vehicle/equipment checks in this sourced timetable catalogue. The user was actively changing routes in the emulator, and input arbitration rejected simultaneous automated clicks, so further app input was stopped. The requirement-review action was explained; no saved accessibility preference was changed. The new-account details/save UI walkthrough is not recorded as completed by this check.

Private evidence: `deployed-rules-verification.json`, `reset-journal.json`, `account-verification.json`, `new-account-credentials.txt`; CLI deployment log: `test/security/shared-reset-rules-deploy.log`. Credentials/backups remain Git-ignored and are not copied into public docs.
