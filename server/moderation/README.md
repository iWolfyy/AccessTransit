# Moderation policy v2: local trusted-server core

This module is implemented and tested locally. It is **not a deployed service**
and normal/shared Flutter uses policy v1 until the trusted HTTPS service, rules
and migration are activated together. The main app now supports v2 HTTPS
configuration in debug/release without requiring a local-validation app.
The separate native Local Test APK workflow is retired; automated emulator
tests remain available. Do not provision shared v2 reports before rollout.

`policy.mjs` exports `createModerationPolicy({store, now, effectiveAt})`.
`effectiveAt` is an explicit reviewed policy activation date. `now` defaults to
the trusted host clock; tests inject time. Never obtain either from a phone.

The store runs serializable Firestore transactions and exposes `get`, `create`,
`set` and `update` by document path. `admin_store.mjs` adapts an initialized
Firebase Admin Firestore instance, retaining native create preconditions.
It does not initialize credentials or expose a network endpoint. The emulator
tests use a modular-SDK store with rules disabled, missing-document create reads
and real Firestore transaction retries. The Admin adapter is syntax-checked;
an actual Admin SDK/hosted endpoint walkthrough remains outstanding.

## Operations

- `creditReport({reportId, scope})`: trusted publication worker only. A newly
  acknowledged, dated v2 report on a reviewed physical target gets one immutable
  +10 event. Retrying the worker does not award twice. Old/ineligible reports and
  unreviewed nonzero legacy totals fail rather than being reset or replayed.
- `voteReport({reportId, actorUid, value, reason, scope})`: a future server adapter
  must resolve `actorUid` from verified authentication, with revocation/access
  checks. It must never forward an arbitrary UID from a client request. True and
  False are rejected for the author. False requires a reason of 5-1,000 characters.
  Each UID has one current vote; switches before closure move that UID's counts.
  **Neither vote earns points.** True does not offset other users' False votes.
- At five False votes, report status, immutable -20 event, one decision/strike,
  signed author summary and durable notification intention commit together.
  Votes close after that decision. Retry/conflict cannot debit twice. A zero
  balance becomes -20; the original +10 is not separately reversed.
- Strike five creates a 72-hour community restriction once. Six through nine do
  not extend it. Strike ten creates a pending permanent-ban review, preserving
  independent restrictions and never setting permanent suspension or disabling
  Auth. New evidence updates an existing pending review count. No automatic
  permanent-ban decision is implemented.

`scope` accepts only `normal` or `sample`. Sample documents, summaries, access and
outbox entries remain under `sample_test/shared/`. This code never disables Auth.
Distinct UIDs are not proof of distinct people or objective report truth.

## Schema and migration boundary

V2 reports require `policyVersion: 2`, an acknowledged `createdAt`, stable
target/author identity and initially zero vote counts. The worker freezes
`awardedPoints` and `rewardPolicyVersion: 2`. The per-voter `votes` subcollection
replaces mutable UID arrays. `reward_events/<report>/entries`,
`contribution_summaries`, `moderation_decisions`, `account_access`,
`permanent_ban_reviews` and `notification_outbox` are server owned.

Contribution summaries hold a signed integer balance and counted strikes.
Zero-total new accounts can initialize a v2 summary; nonzero legacy accounts need
an explicit reviewed baseline migration. Existing points/reports are not
retroactively converted or punished. V1 reconciliation explicitly refuses v2
reports. The old +5 confirmer rewards remain historical v1 data; no silent
recalculation/removal of those balances occurs.

Local rules deny direct updates/deletions of v2 reports, including through the
legacy admin client path. Clients cannot create v2 reports or modify private v2
state. Trusted Admin operations bypass those rules and must enforce this policy.

## Required before activation

1. Choose and configure trusted hosting; no billing upgrade is implied here.
2. Configure/host the authenticated endpoint adapters and add atomic v2 publication/cooldown integration.
3. Migrate Flutter/report evidence/cache queries and signed contribution displays
   together. Legacy three-vote filters must not interpret v2 reports. Hidden v2
   reports need author/admin-only reads plus query-compatible public projections;
   the current legacy public report rules are not an acceptable v2 rollout policy.
4. Enforce `account_access` on all app operational/report/vote/assistance paths,
   including old sessions, and process active-driver reconciliation outbox events.
   Merely recording the suspension is not full-app ban enforcement.
5. Implement audited appeal/correction/permanent-ban review decisions, safe trip
   reconciliation, notification delivery and reviewed baseline migration/rollback.

The outbox is an intention, not a delivered notification or completed trip stop.
No scheduled worker, hosted endpoint, active UI switch, migration or production write is
included. Endpoint adapters and a staged Flutter transport now exist locally. Do not deploy only the new threshold or mix v1/v2 processing.

From `test/security`, with the isolated emulator on port 8088:

```powershell
$env:FIRESTORE_RULES_TEST_PROJECT='demo-phase9-moderation'
$env:FIRESTORE_RULES_TEST_PORT='8088'
node --test --test-concurrency=1 firestore.rules.test.mjs moderation-v2.test.mjs
```

Tests refuse non-demo project IDs. They cover retries/races, rollback, signed
penalties, author exclusion, reasons, switching, suspension boundaries, migration
refusal, Sample isolation and direct client-write rejection.


## Authenticated endpoint and Flutter transport checkpoint

`api.mjs` exports `createModerationApi({auth, policy, allowedScopes,
allowedOrigins})`, a Web Request/Response handler. `auth` must be the initialized
Firebase Admin Auth instance for the intended project. It invokes
`verifyIdToken(token, true)` and resolves the caller UID solely from the verified
identity, following [ID-token verification](https://firebase.google.com/docs/auth/admin/verify-id-tokens)
and [revocation checks](https://firebase.google.com/docs/auth/admin/manage-sessions).
Tests inject the verifier to exercise the security boundary; they do not verify
real project credentials or Firebase Auth revocation over the network.

Routes (POST JSON, bearer ID token):

- `/v2/reports/vote`: `reportId`, `value` (`true`/`false` string), optional `reason`
  and `scope`; response identifies the verified caller, exact report and counts.
- `/v2/account/status`: optional `scope`; returns only the caller's effective
  restriction, authoritative server time/temporary deadline and nullable signed
  v2 balance. Expired restrictions return active; a pending review adds no ban.

Unknown fields (including UID, role, points and client time) are rejected. Normal
scope is the default; Sample scope must be explicitly enabled on the server and
still needs a scoped profile. Browser origins are denied unless explicitly
allowlisted. Responses are private/no-store and failures use sanitized codes.
There is no public award, user-management or permanent-review endpoint.

`node_handler.mjs` adapts a Node IncomingMessage/ServerResponse listener using a
fixed HTTPS public origin. It caps JSON bodies at 4 KiB and rejects duplicate
Authorization headers. It starts no listener and reads no credentials. The host
must provide TLS termination, request/header deadlines, resource limits and
correct Admin SDK initialization; the configured origin is not TLS termination.
Loopback tests use fake tokens only and do not establish production TLS.

Composition in a managed Node host (dependencies supplied/initialized there):

```js
const policy = createModerationPolicy({store: adminStore(firestore), effectiveAt});
const api = createModerationApi({auth, policy, allowedScopes: ['normal']});
const handler = createNodeModerationHandler({api, publicOrigin});
// Mount handler behind the managed HTTPS host; do not auto-start from this module.
```

Flutter's `ModerationClient` uses the existing HTTP dependency and Firebase ID
token. `MODERATION_API_ORIGIN` is an explicit HTTPS origin without credentials,
query or path; unset configuration fails closed. Redirects are disabled, replies
are bounded and checked for caller/scope/report/policy/count consistency, and
late responses cannot apply after an account switch. Timeout/failure never
falls back to a direct Firestore vote. A lost acknowledgement remains uncertain;
retrying the same vote uses backend idempotency. Disposal ignores late results.

This transport is not yet invoked by existing report screens or the auth router.
Do not configure/activate v2 UI until publication, private/public report queries,
legacy filters, signed balances and full account-enforcement migration are ready.
No shared endpoint URL, real Admin authentication, billing or deployment was
configured by this checkpoint.


## Local activation checkpoint

Publication is now one trusted transaction: validated observation fields, verified
caller, explicit observation time separate from server publication time, reviewed
physical target, cooldown, report, +10 event and signed summary. The public API
now includes POST `/v2/reports/publish` (`reportId`, `report`, optional `scope`) and
POST `/v2/reports/vote-status` (`reportId`, optional `scope`). Neither accepts a
client-controlled author, policy version, points, role or server time. Publication
body limit is 16 KiB for multilingual text; other API bodies remain 4 KiB. Cooldown
errors include the server-derived retry deadline. Existing acknowledged IDs return
their original result; failed writes keep the mobile outbox draft.

V2 details/cards use authenticated per-user status, False reason validation,
acknowledged retries, author exclusion and a five-voter threshold. Public filtered
queries remove hidden v2 reports, and individual reads remain author/admin-only
for hidden v2 data. Cached v2 feed copies are removed on unavailable reads; a denied
Details subscription clears prior evidence. Legacy v1 thresholds/rewards are not
silently converted. Client mutations now check server-owned account restrictions
in rules. The local app gates/disposes its workspace on a confirmed suspension or
unverified access state, checks resume/expiry and reads signed v2 contributions.

The Admin store and Auth verifier were exercised against real local Auth and
Firestore emulators, not only injected test adapters. `serve-local-moderation.mjs`
provides a strictly loopback/demo-only host and retryable local reconciliation
worker. It marks owned operations cancelled, never fabricates completion, closes
GPS/releases matching locks and cancels old scoped pending assistance. Newer locks
and oversized assistance batches require review. Notification push, permanent-ban
review decisions, appeals/corrections and general production hosting/migration are
still outstanding. No shared service was deployed or billing changed.

See [local walkthrough instructions](../../docs/local-validation.md). Normal UI
activation is intentionally prohibited by `ModerationMode` until shared rollout
has separate review. The prior staged notes above describe the historical
endpoint checkpoint; this section records the current local-only integration.

## Local appeals and correction checkpoint

Compose `createAppealPolicy({store: adminStore(db)})` as the `appeals` dependency of
`createModerationApi`. The local server does this; no production host is activated.
POST `/v2/reviews/list` accepts `queue` and optional `after`, `/detail` accepts
`reportId`, `/evidence` accepts `reportId` and optional `after`, `/appeal` accepts
`reportId`/`reason`, and `/decide` accepts `reportId`/`outcome`/`reason`. Each accepts
optional allowed `scope`; every other field is rejected. Admin authority comes
only from a verified boolean `admin` claim, never the request body. Decision/appeal
bodies allow 8 KiB for up to 2,000 multilingual reason characters. Lists return at
most 20 cases or 10 votes with document-ID cursors; private replies remain no-store.

Authors, including suspended authors, can read their own decisions and submit one
appeal. Only an active admin can inspect other authors/vote reasons or decide a
case; self-review is forbidden. The transaction writes immutable `appeal_reviews`,
an admin audit event and the final appeal/decision status. Overturn restores the
original penalty through one immutable ledger event, decrements one counted strike,
restores public visibility with voting locked, recomputes community restrictions
and withdraws a pending permanent-ban case below ten. Independent restrictions are
preserved. A pending reconciliation job rechecks current access before cancellation;
review never restarts an already-ended trip. Direct client writes remain denied.

One final review per report is supported here; reopening/escalating a final case
requires a later audited workflow. Permanent-ban review decisions are not included.
The mobile views are enabled only in local debug v2 mode and use the authenticated
API rather than broad private Firestore listeners. See the latest checkpoint in
the implementation plan for evidence and limits.

## Local permanent-ban review checkpoint

The local API composes `createBanPolicy({store, accountAdmin})`; `accountAdmin`
must freshly read the target's Admin Auth custom claims and fail closed on errors.
POST `/v2/bans/list` accepts optional `after`; `/detail` accepts `accountId`;
`/evidence` accepts `accountId`/optional `after`; `/decide` accepts `accountId`,
`outcome` (`approve`/`reject`), `reason`, `expectedRevision`. Allowed scope is
optional on each request. Only verified boolean admin claims authorize these
operations; suspended reviewers, self-review and administrator targets are denied.
The same request/body/response privacy limits apply, with an 8 KiB decision body.
The pending-appeal composite index is prepared in `firestore.indexes.json`.

Strike changes and report-appeal submissions/decisions increment the trusted
summary's `moderationRevision`. Ban decisions compare the displayed revision
inside their transaction; a pending-appeal query plus the shared revision prevents
new appeals racing approval. Approval additionally requires at least ten current
strikes and no pending report appeals. The immutable `permanent_ban_decisions`
event, current review result, audit and access/outbox writes commit atomically.
Case decision keys support new cycles on genuinely new reports without overwriting
prior decisions or replaying an old threshold event. Pages are bounded to 20 items.

`communityPermanent` is separate from independent `permanent`/manual restrictions.
Account status, trusted mutations, normal and Sample rules enforce it immediately.
Approval queues the existing operation worker; rejection changes no access deadline.
An overturned report below ten clears only the community permanent restriction
and withdraws its case, retaining immutable history and independent restrictions.
Auth remains enabled for private appeal/status access. No production Auth disable,
token revocation, hosting or shared rollout is performed by this local module.

An existing trip-start test exposed excessive duplicate rule document accesses.
Prior-lock exclusivity remains in the lock write and bus occupancy is now checked
against the telemetry write's own resource. A trip must still atomically link its
run, lock and telemetry. This reduces redundant reads without allowing an active
bus to switch runs; the new occupied-bus regression and full rules suite pass.

## Local run-bound assistance checkpoint

`createAssistancePolicy({store})` is composed into the same authenticated API.
POST `/v2/assistance/submit` accepts request ID, exact service run/bus, target stop,
boarding/alighting stop IDs, purpose and assistance types. `/get` accepts request
ID; `/action` adds the requested transition; `/list` accepts optional service run
and cursor. Scope follows the existing allowlist. Rider/driver UIDs, deadlines,
status/version and publication timestamps are server-owned. Unknown fields fail.

Transactions resolve the current approved, route-authorized, active driver from
reviewed bus/run data. Active runs require matching operation locks and trip state.
Selected stop order must be unambiguous; existing dated-run models still reject
loop patterns without occurrence IDs. Scheduled targets must remain startable;
boarding falls inside the rolling 24-hour horizon, while alighting may occur later.
Publication creates a private immutable-target request and in-app outbox event.
Retries return the existing response without changing deadlines or resetting status.
Rider cancellation and eligible current-driver transitions are authoritative.

Reconciliation expires unresolved requests on deadline, ended runs, passed stops,
departed origin or unavailable driver. A matching driver handover increments its
assignment version, resets acceptance and writes a handover audit/new inbox event.
The local worker processes bounded pages, preserves its scan cursor, and continues
past a failing row. Old driver authorization is re-evaluated independently of worker
timing. It follows authoritative operation changes; it does not perform the full
operational run/lock/GPS transfer itself.

Flutter uses bounded authenticated API polling for this local slice, every 15
seconds on open views. Driver inbox supports paging; rider history is latest-first
with owner-validated cursors. List replies allow up to 64 KiB for at most 20 bounded
records; other transport limits remain unchanged. Prepared indexes cover rider/run/
status queries; none were deployed. The Admin store's optional ordering/cursor
extension preserves existing moderation queue ordering by default.

Local `assistance_config/active` closes legacy creation; v2 clients cannot directly
write status/targets/assignees. Existing legacy records remain reconcilable. Inbox
events explicitly use `available-in-app` and `in-app-only`, not a fabricated push
delivery status. No provider credentials/FCM host, production endpoint/rules/data
or billing were activated. See the plan checkpoint and local walkthrough for
actual Auth/worker smoke evidence and remaining active-handover/native/push work.

### Local active-operation handover

`operations.mjs` exposes admin-only list/detail/candidates/handover and a
current-driver accept endpoint through `/v2/operations/*`. Caller identity and
admin permission come exclusively from verified tokens. Transfers require a
stable operation ID, expected driver/version and reason. A transaction updates
run/trip/bus/locks/GPS/audit together; progress/timeline remain unchanged. GPS is
paused until the replacement accepts with a fresh, plausible, accurate fix.
Duplicate outcomes cannot replay a superseded handover. The normal Flutter build
does not activate this local-only integration.

`operation_handovers` is private trusted state. A bounded reconciliation scan
persists assistance reassignment; authorization independently follows the current
operation before that scan. Request run-handover versions invalidate acceptance
even after a round trip back to the original driver. Failed jobs are retried and
the local scan cursor prevents a bad first page starving later jobs. This local
timer is not a hosted uptime guarantee. Plan checkpoint 29 records emulator,
actual-token and UI validation; no production host/provider was activated.

### Notification dispatch preparation (local simulation)

`notifications.mjs` provides authenticated device registration/removal and safe
notification-open resolution through `/v2/notifications/*`. New assistance outbox
events opt in using `pushState`. Private device generations prevent an old account
or delayed invalid-token result disabling a rebound token. Eight active bindings
per account limit fanout. Each event/device generation has a leased, retryable
attempt; five failures terminate it. Work is paginated and eligibility rechecked
against current assistance/run authority before dispatch. A stale tray item never
grants request access. Default rules deny client access to registry/delivery data.

The loopback server exclusively instantiates `localNotificationProvider`: its
deduplicated receipt means **simulated**, never FCM accepted/device received.
`fcmNotificationProvider` is an inactive adapter requiring an explicitly supplied
trusted Messaging instance. It sends generic localized text, an opaque event ID,
bounded TTL and a stable tag/collapse key. It never receives passenger/location
details. Real provider acceptance is not device receipt. Sending is at-least-once;
network crashes after acceptance may duplicate messages. Production hosting must
add provider timeouts, monitoring, registry/receipt retention/cleanup and the
reviewed indexes before activation. No FCM credentials/token/project were used.

Flutter currently only exposes staged registration/removal/open transport methods.
OS permissions, Firebase Messaging callbacks, token refresh/logout and navigation
are not wired. Local smoke: `node test/security/verify-local-notifications.mjs`
with the guarded demo emulator variables. See plan checkpoint 30 for scope.

Checkpoint 31 adds the staged Android receiver/token/navigation adapter and
`assistance_requests` channel; the FCM provider payload now names that channel.
The Flutter activation gate stays closed until a dedicated test project and
trusted v2 HTTPS host are configured together. Normal/local builds retain disabled
auto-init and no Messaging token registration. No real send/device delivery was
performed. See checkpoint 31 for native compile and account-race test coverage.

Checkpoint 41 adds `createAccountPolicy` and optional `accounts` API wiring for
admin-only scoped application suspension/restoration. The guarded loopback host
wires it with trusted Admin Auth claim lookup and retains its normal-only scope
allowlist. It does not disable Auth, revoke tokens or delete accounts. See
[manual account controls](../../docs/manual-account-controls.md) for transaction,
retry, operation reconciliation and activation limits.

Checkpoint 44 adds the real-project localhost launcher at
`test/security/serve-shared-backend.mjs` (loopback 8788), main-app `LOCAL_API`
debug transport and readiness-gated bounded workers. It uses the existing
trusted CLI account in process, verifies real Firebase tokens and refuses
emulator/project overrides. The separately guarded demo launcher remains 8787.
No real push adapter is wired. Readiness requires exact reviewed deployed rules,
READY indexes, v2 activation and a valid effective policy date. See
[main-app localhost workflow](../../docs/localhost-real-firebase.md) for the
authorized shared changes, private recovery records and verification limits.

Checkpoint 45 adds the durable `auth_lifecycle.mjs` operations and session
cutoffs; see [Auth controls](../../docs/auth-account-lifecycle.md). Checkpoint 46
adds optional `manualAppeals` API wiring backed by `manual_appeals.mjs` for
revision-bound manual restriction appeals. Both localhost launchers wire these
policies. Main-app admin Users/Activity use bounded pages. See
[manual appeals](../../docs/manual-restriction-appeals.md) for privacy, restoration
boundaries, pending queue and recovery behavior.
