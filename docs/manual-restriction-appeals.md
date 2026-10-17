# Manual restriction appeals and admin pages

Implemented 2026-10-17 in the main application and the real-Firebase localhost
backend. No separate APK or hosted Functions deployment is required.

A restricted user opens Restriction appeals from the account-status screen.
Profile also provides the same entry for appeal history. Auth-disabled/deleted
accounts and revoked sessions must first regain valid sign-in; this flow does
not bypass Firebase Auth. Submission does not restore operational access.

Each appeal is tied to the author's server-owned manual restriction revision.
There is one submission per revision; ambiguous retries preserve the revision
and reason. A changed reason cannot create a second appeal for that revision.
Current restriction and previous outcomes are read from the server. Reasons
must contain 5–2,000 characters.

Admin -> menu -> Restriction appeals opens a private pending queue with pages
of 20. A reviewer supplies a reason and chooses Restore manual access or Uphold
restriction. Restoration requires the same current restriction revision and
increments it transactionally. A previous appeal cannot lift a newer restriction.
An outdated appeal can still be closed with Uphold without modifying current
access. Competing outcomes have one winner, and identical receipt retries do
not repeat changes. Self-review and restricted/non-admin reviewers are denied.
Owner history includes pending/accepted/rejected outcomes and review reasons.

Restoration changes only manual restriction fields. Auth disable/session
cutoffs, community bans, rewards, strikes and driver grants remain intact.
Cancelled operations are not restarted. Sample/Test documents are separately
scoped, while the main localhost host continues accepting normal scope only.

The endpoints are POST `/v2/manual-appeals/current`, `/list`, `/submit` and
`/review`. Actor UID/admin authority comes from verified Firebase tokens, never
request fields. `manual_account_appeals` and associated audit events are written
only by the trusted transactional service; existing rules deny direct client
reads/writes. No rules or composite-index change was needed for this slice.

Users and Activity in the existing admin dashboard now show 20 records per
page, fetching a 21st lookahead for Load more. Users use document-ID cursors;
Activity uses descending creation time plus document-ID ties. Driver review
uses the loaded user pages, with Load more still available when a local filter
matches nothing. Counts/search explicitly cover loaded pages rather than the
whole database. A first-page live change or Refresh resets extra pages; a late
old page response is discarded. Failed Load more preserves displayed records
and offers retry. Catalogue lists and editor reference reads progressed in
[catalogue pages and language controls](admin-catalogue-pages.md). Approval/grant
listeners and commit dependency checks remain complete reads.

Validation covers revisions, races, retry payloads, separate sanctions, scope,
private-list authorization/direct-write rejection, load-more failure, refresh,
stable Activity order and English/Sinhala/Tamil at 320dp/200% text. Fluent
language review, native accessibility and a real-user walkthrough remain due.
No real appeal/restriction was fabricated for testing.
