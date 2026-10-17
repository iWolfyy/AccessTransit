# Owner-scoped saved trips

Checkpoint 36 adds **Home -> View all saved trips** using the existing app theme.
The entry remains available when no open preview exists, so completed/cancelled
legacy bookmarks can still be found. This is an optional saved-selection browser,
not a booking system, active journey requirement or additional search result feed.

The list reads at most twenty records per page, requesting one extra document to
detect the next page. Next/Previous retain page boundaries, retry repeats the
requested boundary and Refresh starts again. Only the current page's records are
kept in screen state. Cursors bind owner and document ID; account changes clear
the page and invalidate pending requests, including switching away and back.
The service checks the signed-in owner both before and after asynchronous reads.
Wrong-owner, duplicate, oversized or inconsistent page receipts fail closed.

Ordering is stable **descending document ID**, not chronological save/departure
order. This includes older records missing `createdAt`; it does not invent a
timestamp or silently omit them. Current bookmark IDs are hashes, so this list
must not be described as newest-first. A chronological-all-records view would need
a reviewed legacy timestamp/order migration. The Home preview separately uses a
bounded latest-open query ordered by actual `createdAt`, with a stable ID tie-break.
That preview cannot include records missing the indexed date/status, but the full
list can. Both normal and Sample paths use the same scoped query design.

Past selections and closed record states remain visible. The rolling 24-hour
boarding restriction applies to **new Search results**, not saved history. Dates
in the new list render in Colombo civil time with the selected Material locale.
Record-state labels do not claim that the bus itself is currently running,
completed or cancelled. Open details refreshes operational status independently.

Opening a row rereads the exact saved document from the server and then uses the
existing JourneyResume -> consolidated Bus Details adapter. It preserves identity,
selected stops/date/time/needs/run and any fare snapshot. Opening does not save,
start tracking, book a seat, change accessibility defaults or select another bus.
Current fares and run state are still independently revalidated by Details.
Missing/incompatible vehicle/selection data has an explicit error/retry state;
it is not replaced by fabricated schedule/stop information. Resume and list views
clear private content on account changes and reject late responses.

Remove saved trip deletes only the owner-scoped bookmark after server acknowledgement.
A failure retains the row with retry feedback. It does not cancel a shared service
run, remove a bus or modify another person's trip. Deleted cursor documents do not
prevent continuation because page boundaries use ID values. Navigation back from
Details refreshes the current page. Other-device changes are not a live whole-list
subscription: refresh/open/remove revalidate them. Concurrent edits/inserts between
page reads are not a transactionally frozen history snapshot.

List reads reject cached/pending/error receipts and do not present an old cache as
current saved history. The exact document subscriptions on Details retain their
existing acknowledged saved-state behavior. The Home latest-open listener and its
one-shot equivalent now use limit 1 instead of reading the entire owner history.
Composite indexes are prepared in `firestore.indexes.json`; shared activation
still requires reviewed index deployment. No rules expansion or new collection is
required. Normal/Sample owner read/delete protections remain unchanged.

English/Sinhala/Tamil labels cover the new list, controls and touched resume states;
the wider Home translation backlog and fluent/native review remain separate.
No database reset, timestamp backfill, saved-record rewrite, shared deployment,
production account change, billing upgrade or FCM activation occurred.

Repeat the unique synthetic Auth-token check from `test/security` with the local
walkthrough emulators running:

```powershell
$env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8087'
$env:FIREBASE_AUTH_EMULATOR_HOST='127.0.0.1:9099'
node verify-local-saved-trips.mjs
```

It loads current local rules without clearing data, creates one local fixture
account, and checks normal/Sample pages, past/closed/undated legacy records,
deleted-boundary continuation, latest-open preview and denied foreign/unscoped
reads/deletes. Unique fixture rows remain for inspection. It refuses remote hosts.
