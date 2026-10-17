# Report-entry form presentation

The report form now uses generated English, Sinhala and Tamil resources for
condition/category and crowding choices, photo controls, review/validation,
summary labels and submission errors. This pass adds 125 entries per locale.
Fixed catalogue labels are translated at presentation; the original option
IDs, categories, severity, subcategory and crowding values remain unchanged
in report payloads. Original bus/route/stop names and rider notes remain data.

The review dialog shows the effective translated choices, original target
and note, cooldown rule, public-photo privacy guidance and draft retention
disclosures. Editing the review returns to the existing form. Confirming
continues through the existing ReportSubmissionService; opening the form or
review does not publish. The destination remains the acknowledged/pending
delivery screen, rather than an unconditional success view.

Optional UID/submission-service/image-picker injection supports isolated UI
tests; the main app defaults to Firebase Auth, the existing submission singleton
and ImagePicker. Account identity is checked across review and submission;
an account change while reviewing requires a fresh review. A late camera
result from another account is discarded. Missing sign-in is explained, and
unknown submission/photo exceptions use localized retry guidance without raw
provider details. Duplicate submission while already sending is ignored.

Option/category cards use natural heights and two columns at ordinary sizes,
with one column for narrow large-text layouts. Full labels wrap instead of
being clipped to fixed grid heights. Photo choices scroll, add-photo and submit
controls retain minimum heights, and summary/dropdown labels wrap. Theme and
navigation remain unchanged. Existing photo-provider availability is respected;
no real camera/gallery provider or upload service is activated by this work.

New tests exercise all three locales at 320dp/200% text and high contrast:
station and bus payloads, translated review with original notes, validation,
delayed publication, review-account changes, all category tabs, and mocked
camera/gallery cancellation and failure. Existing target selection and
condition/evidence tests still validate the stored values. Tests use in-memory
catalogue/outbox data and injected publisher/identity/picker fixtures, with no
real Firebase/Auth writes, camera capture, gallery read or photo upload.

Fluent Sinhala/Tamil terminology review and native font/TalkBack/device QA
remain required. This pass does not claim complete translation of every
community/outbox/help screen. No live deployment, billing change, push send
or APK build/install is included.
