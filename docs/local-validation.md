# Isolated Android/Firebase walkthrough

This mode uses synthetic local data only. It does not verify real services or deployed Firebase security. The original Android application/account data stays in `com.accesstransit.access_transit`; the separate local APK uses `com.accesstransit.access_transit.validation`, label **AccessTransit Local Test**.

Start the local backend from `test/security` (requires its installed dependencies and a compatible JDK):

```powershell
npx firebase emulators:start --project demo-accesstransit --only auth,firestore --config ../../firebase.validation.json
```

Keep that process running. In another terminal in `test/security`:

```powershell
$env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8087'
$env:FIREBASE_AUTH_EMULATOR_HOST='127.0.0.1:9099'
node seed-local-validation.mjs
```

The script refuses other emulator addresses and has no remote-project override or admin credentials. It creates synthetic accounts, three stops, one assigned test bus/route, local operator approval and a fresh **synthetic** ramp observation only in `demo-accesstransit`. Re-running replaces those fixed fixture profiles/catalogue/approval fields (including test counters), so use it before a new walkthrough, not in the middle of one. No existing real catalogue is copied or relabelled. The timetable starts approximately fifteen minutes after seeding; rerun before a later session. All test data is temporary unless separately exported.

Build from the repository root:

```powershell
flutter build apk --debug --dart-define=LOCAL_VALIDATION=true
```

Check the actual APK manifest/application ID before installing. The standard output path is reused by Flutter; do not assume an older file is the intended build. The default build without this flag remains the normal Firebase app. Local builds skip production Google Services initialization, use hard-coded Android emulator host `10.0.2.2` (Firestore 8087/Auth 9099), disable Firestore disk persistence and show a persistent LOCAL TEST ONLY banner. Release local builds are blocked. External Cloudinary photo upload is blocked; use text-only reports. Other Internet resources such as map tiles are not made offline by this mode. Do not enter real credentials or personal photos/notes into a local fixture account.

Local-only fixture logins:

- Passenger: `passenger@local.test`
- Approved assigned operator: `operator@local.test`
- Both use `LocalTest-Only25!` (a public local test password, never a real-account password).

The user performs sign-in in the app. Test passenger planning/saving/assistance, switch to the local operator for acknowledgement, then back to the passenger for status. One emulator with sequential accounts is not a simultaneous two-device test. For concurrent emulator instances use this same local backend and local package; physical devices require a separately reviewed network setup because `10.0.2.2` is emulator-specific.

Do not run the destructive rules-test fixture suite against this same backend while retaining walkthrough state; run it separately after stopping this backend. Do not deploy this seed data, change the hard-coded project to a real Firebase project or infer live operator approval from the local fixture. Real catalogue/approval review and live rollout remain separate administrator actions.
