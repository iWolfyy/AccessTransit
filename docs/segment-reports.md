# Selected-segment report queries and live pages

Checkpoint 37 replaces consolidated Bus Details' whole-active-report listener
with an explicitly bounded preview for the selected physical bus and stop segment.
The compact Community reports section remains immediately above Save Trip.

The preview issues one bus query and one station query per thirty unique segment
stop IDs (boarding/intermediate/alighting). Each requires `status == active`, exact
`targetType`, target ID equality/`in` and descending document ID ordering, limited
to four records. With the supported maximum 300 segment stops, this is at most
eleven listeners/44 candidate records; typical routes require two. Rendering
retains at most three relevant visible reports. A published timetable does not
become a different physical bus because another route number matches.

All query receipts must be acknowledged. Cached/pending/error snapshots clear
preview evidence rather than preserving a stale hidden report. The combiner waits
for every scoped query, clears failed-query state and cancels subscriptions when
the Details screen/selection subscription is disposed. Existing public visibility,
dispute and evidence freshness checks still run after scoping. Hidden reports leave
the active query when their committed state changes; invalid/disputed candidates
cannot appear as useful public evidence solely because they were returned.

This is a **limited preview, not a complete evidence assessment**. Descending ID
order is stable and includes records lacking observation timestamps; it is not
chronological. Many reports at one stop can occupy a chunk preview ahead of other
stops. Old unresolved barriers can lie beyond the preview limit. The Details
preview and evidence expansion explicitly disclose partial coverage; absence of
visible reports cannot establish working equipment or safe access. Existing
Search/Results accessibility matching is separate and is not rewritten by this
slice. No preview-derived complete-accessibility claim is introduced.

**View all relevant reports** is always available, even if the preview is empty.
It opens a scoped browser with the selected bus and each selected segment stop as
target options. Only the current target's page is listened to: twenty records and
one lookahead, ordered by stable ID. Next/Previous preserve ID boundaries, changing
target starts at page one and Refresh retries the current page. Only the current
page is retained in memory. Future/current/ended trip dates do not turn present
condition reports into proof of conditions on a future departure.

Pages reapply exact target, publication/dispute and freshness filters. A page may
contain only expired observations, so its empty wording explains that older useful
records can remain on later pages. Pagination advances over raw query records,
not just visible rows, avoiding a stalled cursor on expired entries. Deleted or
hidden boundary documents do not invalidate their ID cursor. There is no frozen
cross-page snapshot: concurrent writes can move records between live page windows.
The same caution applies to target counts; no whole-history total is claimed.

Reports open the existing report detail/voting screen. This public browser does
not grant author/admin access to private disputed records or change True/False,
points, strike or appeal policies. Cached/error/target-switch transitions clear
the previous rows. The paged reader and Details preview convert Firebase setup/
query failures into unavailable/retry UI rather than throwing during screen init.
All new browser/preview labels have English/Sinhala/Tamil resources. Fluent/native
review and the wider operational translation backlog remain separate.

`firestore.indexes.json` contains the target/status/descending-ID query index.
Shared use still requires its reviewed deployment; no rules permissions change
is needed. Both normal and Sample collection paths use the same scoped design.
No production data/index/rules deployment, billing or real FCM activation occurred.

Local emulator smoke, from `test/security` with the existing Firestore emulator:

```powershell
$env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8087'
node verify-local-segment-reports.mjs
```

This loads local rules without clearing data and leaves unique fictional reports.
It verifies four-record previews, the thirty/31-stop query boundary, exact bus
45-record pagination, unrelated/hidden exclusions and live removal after a trusted
fixture write commits hidden/five-False state. This is a query-delivery test, not
a replay of five authenticated votes; existing moderation suites cover that policy.
