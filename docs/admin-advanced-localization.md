# Advanced catalogue guidance and validation

Implemented 2026-10-17 in the main Flutter app. This slice extends catalogue
paging/localization from checkpoint 47, without changing catalogue validation,
authorization, storage or operation policies.

Added 49 English/Sinhala/Tamil resources covering equipment-versus-condition
guidance, timetable limitations, stop ordering/reorder/remove tooltips, time and
route validators, driver-assignment/review guidance, server-load failures and
catalogue/profile/driver validation messages. Bus/timetable summaries, audit
attribution and ordered-stop counts now use typed localization resources; the
English stop count uses a plural rule. Catalogue names, IDs, authored review
notes and audit data remain original data, not invented translations.

Required-field and coordinate failures now carry stable presentation codes,
field metadata and character limits via `AdminValidationException`, preserving
the original `FormatException` diagnostic text. Dependency deletion failures
carry the referenced kind via `AdminDependencyException`, preserving StateError
compatibility. The UI formats these parameters using localized field/type
labels rather than parsing rendered English. Existing fixed policy messages
are translated by the presentation adapter. Server-side error decisions and
tests that rely on their diagnostic types/text retain their behavior.

The editor retains error objects until rendering; a locale change can reformat
the known error. Workspace actions translate known failures before showing the
message. Loading/unavailable states and relevant collection labels are also
localized. Source/equipment warnings remain explicit; localization does not
turn catalogue capabilities or published timetables into verified live service.

Coverage includes real validation-generated metadata, preserved diagnostics,
localized field/limit/dependency parameters and advanced editor guidance/stop
controls at 320dp/200% in all three languages. Fluent Sinhala/Tamil terminology
and native font/TalkBack review remain due. Separate admin tools (calendars,
fare/geometry editors and others), raw audit action identifiers and some legacy
operational/profile wording still require their own localization pass. This
does not claim that every dashboard or server diagnostic is fully translated.

No APK, shared Firebase mutation, rules/index change, hosted deployment or
billing change is needed for this slice. Scheduling tools progressed in
[admin scheduling language and loading states](admin-scheduling-localization.md).
