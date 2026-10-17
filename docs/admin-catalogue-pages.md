# Admin catalogue pages and language controls

Implemented 2026-10-17 in the main Flutter application. Buses, Routes and Bus
stops now use the existing 20-record admin paging flow, alongside Users and
Activity. Firestore live queries return 21 documents for the first-page
lookahead; additional pages use document-ID cursors. Counts/search refer to
loaded pages. An empty local search still offers Load more, and page-load
failure preserves current records for retry. Refresh/first-page changes reset
extra pages and invalidate pending older responses.

Catalogue editors and driver route assignment explicitly collect reference
pages rather than assuming page one contains all eligible stops/routes/users.
They still load the full selector set on demand, using bounded page reads;
this does not promise constant total reads or constant memory for large
catalogues. Dependency checks used by trusted catalogue commits retain their
existing complete-read behavior. Approval/grant reference listeners are not
truncated by this change.

A failed/incomplete editor reference load disables Save until references load
successfully. The real Firestore collector checks the initiating account and
normal/Sample scope after each page, rejects repeated cursors and deduplicates
IDs. An assigned route outside the current catalogue page is shown using its
stable ID, rather than falsely reporting no assignment. Assignment dialogs
reload every eligible route page before presenting their selector; the existing
audited service revalidates approval/route membership when saving.

Added 105 English/Sinhala/Tamil resource entries for admin navigation, common
actions, account/driver review labels, catalogue fields, source review and
parameterized review/assignment titles. A presentation-only label adapter keeps
backend enums, stable IDs and user-authored text unchanged. Existing advanced
explanations, some generated summaries/validation errors and separate admin
tools still have a translation backlog. This is not a claim that the entire
admin area is fully localized. Advanced main-workspace/editor explanations,
summaries and validation progressed in [advanced localization](admin-advanced-localization.md).
Fluent Sinhala/Tamil and native font/TalkBack
review remain due.

Automated tests exercise later catalogue pages, empty search with Load more,
complete references, an assigned route beyond the loaded list, failed reference
loading and all three locales at 320dp/200% text. No APK or shared Firebase
deployment/data mutation is required for these Flutter source changes.
