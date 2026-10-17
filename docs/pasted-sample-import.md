# Imported user-pasted sample data

Imported on 2026-10-18 (Asia/Colombo) into `sample_test/shared/` of
`accesstransit-b615b`. Select **AccessTransit: realistic SAMPLE data (same app)**
in the existing VS Code launch configurations. This uses the same application
package, not an additional test APK.

The pasted Dart file is preserved as a normalized data snapshot in
`catalogue-review/pasted-legacy-sample.json`. Its `seedAll()` deletion code was
never executed. The adapted importer only creates missing records, atomically,
under Sample/Test scope. Original IDs are prefixed with `pasted_`, and displayed
names/registrations are visibly labelled SAMPLE. Existing normal and sample
activity is not overwritten.

Imported: 21 stops, 10 directed routes, 29 sample vehicles, 58 scheduled runs
(Colombo service dates 2026-10-18 and 2026-10-19), three sample reports, and three
fixture author profiles with their isolated summaries/ledger events: 130 records
plus one import manifest. No Firebase Auth account, route grant, operating lock,
GPS transmission or active trip was created. Dated records expire naturally;
re-running the importer does not roll them forward or reset walkthrough activity.

Source capability flags/coordinates are scenario claims, not reviewed travel
information. Undated `rampOk` and crowding were retained under `sourceClaims`;
current condition is Unknown and occupancy unknown. Wheelchair requirements may
therefore exclude these options; the existing explicit search-only filter action
can inspect them without changing Settings. Legacy vote counts/self-confirmation
arrays were not converted into valid votes. Report observations preserve the
source scenario ages/statuses, with fresh import publication timestamps and
isolated v2 sample ledger entries. Fictional author profiles have no Auth login.

Commands from the repository root:

```powershell
node test/security/import-pasted-sample.mjs --validate
node --test test/security/pasted-sample-fixtures.test.mjs
node test/security/import-pasted-sample.mjs
node test/security/import-pasted-sample.mjs --apply
```

Validation: four offline adaptation tests passed; a Flutter model/matcher check
parsed all 130 records and matched 29 upcoming service opportunities. Database
read-back verified all records, normal catalogue/user fingerprints were unchanged,
and a repeated apply verified existing records without writing. Logs:
`phase68-model-tests.log`, `phase68-import.log`, `phase68-idempotency.log`.
Private preflight snapshots/receipts are under `.private/pasted-sample/`.
