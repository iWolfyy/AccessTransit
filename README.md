# AccessTransit - Inclusive Public Transport Companion

SE3050 User Experience Engineering project; SDG 10 and 11. Version 1.0.0+1.

AccessTransit is a Flutter prototype for direct-bus journey planning, scoped accessibility evidence, passenger assistance and approved operator updates. It is not ready for real-world reliance. Local implementation/tests do not establish deployed security, reliable background tracking, driver response or safe accessible travel.

## Current implementation

The maintained [feature inventory](docs/feature-inventory.md) distinguishes implemented code, unavailable capabilities and external validation. [Fix progress](docs/audit/fix-progress.md) records F01-F26 work and the exact test/build evidence; the [original audit](docs/audit/system-audit-2026-10-14.md) remains a historical snapshot.

- Search direct services by boarding/alighting segment and date/time; review evidence, confirm and save a journey, then resume it. Results are timetable estimates; numeric fares are disclosed prototype estimates.
- Review time/source-scoped ramp and endpoint evidence with Unknown/stale/barrier states. An accessibility preference or a working observation does not guarantee an accessible trip.
- Request boarding/alighting assistance for a reviewed target; distinguish publication from driver acknowledgement. Approved/assigned operators can respond, record conditions and manage trips/GPS updates.
- Submit public condition reports/photos with explicit pending/failed/published states, retry/remove local drafts, and use acknowledged community mutations. Android drafts use private encrypted storage; other platforms currently retain drafts for the app session only.
- Use device high contrast/large tap targets and account-scoped wheelchair/step-free needs. Unsupported preference switches are disabled.

Spoken TTS/voice navigation, stop/background notifications, emergency contact, walking/quiet-route ranking, transfers, localization, offline map download and ticket purchase/redemption are unavailable. The displayed membership card is not a transport ticket. No AI travel assistant is connected. See the inventory for details and evidence links.

## Run and validate

The app connects to online Firebase project `accesstransit-b615b`; no local
Firebase or API server is started. Use the **AccessTransit: online Firebase**
VS Code launch profile or `flutter run`. Trusted v2 server features need a
hosted HTTPS API, which is not configured yet. See the
[current connection policy](docs/main-app-backend.md).

For the populated shared **Sample/Test mode**, run
`flutter run -d emulator-5554 --dart-define=SAMPLE_TEST=true`.
It uses the same app/accounts, an isolated Firebase namespace and a persistent
sample banner. See [scenarios, switching modes and limitations](docs/shared-sample-mode.md).
Without that flag, the app uses the normal sourced catalogue.

The pubspec requires **Dart ^3.13.0**; the recorded local toolchain is **Flutter 3.47.0 stable**. Firebase project/platform configuration and shared catalogue/operator approval must be set up for connected features. No services are auto-seeded as real transit fallback data. See [catalogue/demo setup](docs/transit-catalogue.md), [operator approval](docs/operator-approval.md), [Firestore security](docs/firestore-security.md) and [photo publication](docs/report-publication.md).

```sh
flutter pub get
flutter test
flutter analyze lib test
flutter run
flutter build apk --debug
```

The debug APK path is `build/app/outputs/flutter-apk/app-debug.apk`; a debug build is not a signed release. Exact latest validation is in the fix log. Existing native-access and Firebase Kotlin-plugin upgrade warnings require maintenance.

Local security tests are in [test/security](test/security); with Node and a compatible JDK, run `npm ci` and `npm run test:rules` there against the configured demo emulator. This does not deploy rules. The [approved shared reset](docs/catalogue-review/shared-reset-plan.md) subsequently deployed/read-back-verified the rules and verified eight accounts' sign-in/profile-read isolation. Operator approval/assignment, indexes, live write-path tests, Cloudinary restrictions, two-device delivery, background/resume and TalkBack/large-font behaviour remain pending. Do not commit secrets or treat a saved unsigned preset as a verified upload test.

## Assignment evidence

[Interview guide](docs/assignment/milestone-1/02-interview-guide.md) exists. Real participant research/testing, report/design traceability, branding/pitch artifacts, member contributions and signed reflections remain pending or unsupplied; software tests do not replace participant studies.

[Sprint1_QA_Test_Plan.docx](Sprint1_QA_Test_Plan.docx) and [Sprint1_QA_Tracker.xlsx](Sprint1_QA_Tracker.xlsx) are present tracked files in the current workspace. Their content, coverage against the current implementation and sign-off have not been independently reviewed in F26; their presence is not evidence that all QA passed. This corrects the original audit's inventory gap without rewriting that snapshot. No pitch deck/poster/required MP4 submission artifacts were found in the current source/artifact inventory.
