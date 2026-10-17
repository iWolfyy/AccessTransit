# Audit fix progress

Updated: 2026-10-16 (Asia/Colombo). Original findings remain in system-audit-2026-10-14.md as an audit snapshot.

## Batch 1: F01 and F02

### F01: implemented and emulator-tested; live rollout pending

`firestore.rules` now denies undeclared access, protects private profiles/journeys/assistance, binds report author and target, validates votes and timestamps, reserves reward counters for trusted writes, and restricts operational updates to approved assigned operators. Client-selected operator roles do not grant access. Approved operators can claim only unassigned buses.

Compatibility changes: new reports start with no confirmation timestamp. Rejected reward writes no longer fabricate updated cached rewards. Authoritative reward calculation and permission-error delivery UI remain later audit tasks. Private profiles are not readable by other riders; attribution can use account identifiers until a consented public display-name model is introduced.

Validation: **24 local Firestore emulator tests passed**, using only `demo-accesstransit`; authorized and unauthorized requests were both covered. **242 Flutter tests passed**. Analysis of the changed Dart files reported no issues.

The rules have **not** been deployed to `accesstransit-b615b`. A local rules file does not close the deployed project's exposure. Operator approval records and existing-schema compatibility must be prepared, and F04/F07/F08 acknowledgement/error flows still need work before an app-wide live rollout is verified. See ../firestore-security.md for the reviewed permission model, tests and deployment command.

### F02: false-contact behaviour fixed

The callback that claimed emergency services were contacted has been removed. The emergency button is disabled, with visible text and accessibility semantics explaining that calling is unavailable and users should use their phone. Reporting remains enabled. This is a truthful mitigation; it does not implement an emergency-call service.

Validation: the new widget test verifies the action is disabled, no contact-success message is produced, and Report Issue still invokes its callback. It is included in the 242 passing Flutter tests above.

## Next item

F01-F26 have been processed locally; current work is emulator/device validation. See the latest validation entry below for verified results and pending external prerequisites.

## Batch 2: F03 fixed in the app

All assistance entry points now resolve and carry the exact selected vehicle and stop. Boarding requests use the origin; getting-off requests use the destination. Explicit invalid IDs, mismatched buses and ambiguous legacy names cannot fall back to the first/default target. Missing target context prevents navigation with a useful message. The form constructor requires target fields, so new callers cannot silently inherit bus_138_outbound/st_fort.

The form rechecks the bus-stop relationship before confirmation and shows actual vehicle registration/route, canonical stop name, boarding/alighting purpose and selected help. Cancelling does not submit; committing requires a signed-in rider. The request persists the actual route number and purpose, and the driver card identifies boarding versus getting off. Legacy requests without purpose remain boarding requests.

The fixed three-minute ETA has been removed. Only matching same-bus/same-stop estimates backed by fresh active telemetry are passed; otherwise the form shows ETA unknown. The static '12 users today' ramp verification claim has been replaced by an acknowledgement note.

Validation: **253 Flutter tests passed**, including 11 new target/navigation/confirmation/submission regressions. **25 Firestore emulator tests passed**, including valid alighting help and rejected purpose/help mismatches. Analysis of the eight changed source/test files reported no issues. No real-device driver delivery is claimed here; F04 remains necessary because the existing write service can still swallow delivery failures. Live rules rollout remains pending as described under F01.

## Batch 3: F04 implemented and locally verified

Assistance submission now persists an owner-bound outbox entry before opening a receipt. It shows Pending upload until a shared-service transaction is acknowledged, and distinguishes Sent from the driver's acknowledgement/completion. Transient failures/timeouts remain unconfirmed Pending; permission/validation failures show Failed. Home > Your assistance requests reopens saved uploads and shared history. Only the owning signed-in rider can submit/retry or view the passenger receipt.

Retries preserve one request ID across restarts. The transaction checks any existing request, rejects different target/help/purpose reuse and preserves an existing driver response. Pending requests retry on authentication and every minute while the app runs; retries stop after 30 minutes to avoid delayed stale requests. Retry expired does not claim a timed-out write never arrived or was cancelled. Sent pending/acknowledged requests can be cancelled with acknowledged feedback.

Passenger request streams now forward acknowledged changes. Driver cards support pending -> acknowledge/decline and acknowledged -> complete. Failed updates retain the previous state and show an error. Device-pending writes do not appear as driver-visible requests. Shared assistance cache is scoped to the signed-in account; account changes clear it, old-session listeners and late acknowledgements cannot refill another account's cache, and persisted Firestore cache snapshots do not establish fresh access.

Validation: **271 Flutter tests passed**, including 18 new delivery/UI/privacy regressions. **27 local Firestore emulator tests passed**, including missing-ID transaction creation, retry preservation, owner-scoped history and driver decline. Analysis of the 14 changed source/test files reported no issues. See ../assistance-delivery.md for status, timeout and retry behaviour.

Live Firestore rules deployment, operator approval preparation and a two-device passenger/driver delivery check are still pending. No push-notification delivery or driver response-time guarantee is claimed. F07/F08 error-handling compatibility remains necessary for the wider rules rollout. Next: F05, truthful live accessibility evidence.

## Batch 4: F05 implemented and locally verified

The live journey panel now subscribes to shared condition reports independently of GPS. Vehicle ramp evidence is limited to that exact bus; boarding and destination elevator evidence are limited to their exact station IDs. Actual journey endpoints take precedence over old route context, and ambiguous/missing stop names remain Unknown rather than selecting a first stop. The same evidence card used by route details shows the reporter/confirmers, actual recorded check times, expiry/recheck times and unresolved state. Live endpoint matching does not use report display names as station identity.

Missing/malformed equipment fields in BusLocationModel remain nullable Unknown. GPS/capability flags, including legacy positive flags refreshed by location writes, do not establish a current working condition. Legacy negative ramp telemetry stays visible as a warning with unknown equipment-check time; bus elevator/lift telemetry never establishes a station elevator's condition. Removed the static verified-active claim and invented alternative ground-level ramp. Synthetic fallback bus data no longer declares ramp/low-floor capabilities.

Fresh positive equipment observations show Working reported, without claiming verified accessibility. Conflicting unresolved barriers are not cleared by positive reports; old structural faults show Unresolved barrier — needs recheck. A newer/tied uncertain observation prevents an older positive from claiming Working. A 30-second UI timer refreshes freshness even if GPS/reports stop updating. Report read errors surface to this panel: working claims become Unknown while earlier unresolved warnings remain visible. GPS failure leaves the independently subscribed condition panel reachable.

Validation: **287 Flutter tests passed**, including 16 new model/evidence/endpoint/live-update/freshness/error regressions. Analysis of the seven changed source/test files reported no issues. Firestore authorization rules were unchanged in this batch. Live rules rollout and cross-device checks remain pending. Dedicated operator equipment-check records are not present; legacy GPS flags are labelled accordingly. Next: F06, journey confirmation and persistence.

## Batch 5: F06 fixed locally; F25 dormant confirmation risk removed

Normal results now open route details/evidence. Both journey actions open an explicit confirmation showing the selected vehicle, canonical endpoint IDs/names, requested date/time, timetable departure, estimated arrival/fare and access requirements. Confirmation requires the signed-in owner and an acknowledged journey save before navigation. Failures remain on confirmation with retry; repeated taps are disabled and retries use one stable ID. The transaction rejects selection reuse and preserves an existing journey's terminal status. Route details now uses the selected segment fare instead of its disconnected fixed LKR 250; estimates are labelled as such. Wider fare-source work remains F24.

JourneyModel persists bus/route identity, boarding/destination IDs, selected date, requested time minutes, actual chosen timetable departure, duration/fare estimates and wheelchair/step-free requirements. The Home saved-journey panel subscribes to owner-scoped shared history while Home is mounted, so a newly confirmed journey becomes resumable without restarting Home. Resume rehydrates the saved selection and watches that exact journey document, not whichever journey later becomes newest. Missing legacy details or a changed bus/route/stop relationship require replanning; no default target/date is invented. Cancel/completion failures show feedback, and pending local writes cannot prematurely remove an already acknowledged saved plan.

F25 was addressed while connecting confirmation: removed all passenger-created operator_system GPS/coordinates/speed, fixed ramp-verification statements and fake departure-alert success. Saving a journey neither reserves a seat nor confirms the scheduled bus is running. Current GPS is separate from the chosen timetable. Current equipment reports remain independently scoped. A desktop overflow found by the resumed-journey test was also corrected.

Rules accept/validate the new private selection fields and allow the signed-in missing-ID transaction check; existing journey documents remain owner-only and selection fields remain immutable. Older records remain readable, but incomplete records cannot be silently upgraded into a guessed plan. These rules are local; production deployment is still pending.

Validation: **302 Flutter tests passed**, including 15 new selection/model/acknowledgement/ownership/history/navigation/mobile+desktop restart/resume regressions. **29 Firestore emulator tests passed**, including new selection validation, missing-ID transaction creation, retry preservation and forbidden target/identity edits. Analysis of the 11 changed source/test files reported no issues. A real Android restart and cross-device check remain pending; transit catalogue/demo provenance is still F12 work. Next: F07.

## Batch 6: F07 implemented and locally verified; F13 voting partially addressed

Confirm/flag/resolve now require the actual signed-in actor and return acknowledged results. They never change shared cache, vote counts, timestamps or status before the write succeeds. Details and feed prevent repeated taps while a change is pending, show failure/retry feedback, and do not substitute guest_user identities. Authors cannot vote on their own reports; only the author can resolve. Failed writes keep the prior acknowledged observation. If a transaction succeeds but fetching its exact server details fails, the receipt says the change was saved and details need refreshing; no client clock is presented as an exact server check time.

Votes use transactions plus atomic array/count transforms, preserving independent concurrent voters. Sequential duplicate retries do not increment totals or refresh confirmation time. Switching a confirmation to a flag preserves other votes and clears the aggregate confirmation timestamp whose contributing checker can no longer be established. Per-checker recheck history and repeat-check policy remain F16 work. Three independent flags atomically mark the report Hidden instead of deleting the record; this excludes it from the feed/planning but does not establish that the observation was false. The historical report/shared photo remain public, so Hidden is not a privacy-removal action; retention/photo deletion remains F20.

Author resolution atomically writes status/resolvedBy/resolvedAt and a condition-specific report_resolutions/<reportId> record with who, server time, target, category, original condition text and prior/new status. Rules require both sides of that transaction; ordinary clients cannot edit/delete the audit record, and it survives author removal of the report. Legacy resolved reports without recorded attribution/time show Unknown rather than invented history.

Report streams forward acknowledged local changes to existing subscriptions, ignore pending writes, and invalidate scoped cache on authoritative absence. Details no longer resurrect deleted records from constructor input or invent an active report when one is unavailable. Read errors label the last received observation and disable actions. Retrying report publication preserves an existing report's current status/votes/resolution instead of replacing the cache with the original active draft.

Removed report create/confirm/flag reward writes and the derived reportCount * 10 points display. Trusted stored profile rewards remain unchanged. This does not implement authoritative reward calculation; F13 still needs trusted, idempotent reward events/reconciliation. F07 selects acknowledged online mutations with explicit manual retry, not a durable offline mutation queue.

Validation: **321 Flutter tests passed**, including 19 new mutation/ownership/acknowledgement/error/stream/UI regressions. **32 local Firestore emulator tests passed**, including concurrent confirmations, duplicate retries, reversal, three-flag hiding and atomic/immutable resolution history. Analysis of the eight changed source/test files reported no issues. Live rules deployment and two-device mutation/history checks remain pending. Next: F08.

## Batch 7: F08 implemented and locally verified; F17 addressed

Operator condition/assignment writes now propagate rejection and change the shared cache only after acknowledgement. Catalogue reads and streams ignore pending writes, preserve received buses in the cache and forward acknowledged changes to existing subscribers. Station insertion now commits station and itinerary together, fails truthfully under the existing admin-only policy, and cannot report success after a rejected partial save. Catalogue demo provenance remains F12; these changes do not turn sample services into verified real services.

GPS coordinates in the operator dashboard are explicitly local fixes. Pending upload, shared receipt, failed/offline upload, stale receipt and locally stopped/unconfirmed completion are shown separately. GPS failure keeps the last shared observation, and subsequent fixes retry; old coordinates are not placed in a passenger-visible outbox. Delay changes no longer refresh the GPS timestamp or imply that the scheduled service resumed. Equipment updates no longer replace a complete telemetry document or silently swallow errors. The unsupported stop lift toggle is disabled; positive ramp observations no longer promise a Safe route.

Trip start atomically creates the trip and its linked live_locations session. A retained trip ID makes uncertain retries idempotent. Restart/resume discovers the signed-in driver's acknowledged active trip and refreshes its GPS while retaining its stop timeline. Starting over an existing unrelated broadcast fails instead of overwriting it. Arrival/completion atomically update the linked trip and telemetry; rejected writes retain prior progress. GPS updates check the expected trip ID and active broadcast in a transaction, so a delayed old callback cannot revive an ended trip or update a replacement session. Duplicate progress transactions return the stored timeline rather than caching a newly guessed arrival time.

Final-stop arrival now records its actualArrival, completes the trip and stops broadcasting in that same transaction (F17). Ordered operator schedule estimates also roll past midnight; sharing the passenger/operator parser and clarifying timetable-versus-actual departure adjustments remain F18 work. Telemetry reads invalidate cache on authoritative deletion and all-active snapshots prune absent buses; this addresses F19 code paths, while broader offline/cache/device verification remains pending.

The dashboard locks bus selection during writes and active/pending sessions, prevents competing arrival/settings actions, preserves a failed Stop action for retry and prevents late GPS receipts from overwriting its completion state. Leaving the screen stops the local GPS listener; it does not silently announce or initiate a shared trip completion. Use Stop to acknowledge completion before leaving; force-close/disconnect still requires stale-state handling and operator reconciliation. Driver role/approval UX remains F09. There is no claim that a server receipt establishes delivery to every passenger device or that background tracking was independently tested.

Validation: **335 Flutter tests passed**, including 14 new delivery/transaction/cache/session/overnight regressions. Existing driver tests now use explicit simulated backend receipts instead of default no-Firebase success. **34 local Firestore emulator tests passed**, including linked start/final arrival and denied-transaction rollback. Analysis of the 14 changed source/test files reported no issues. No production writes, rule deployment or new APK/device walkthrough were performed. Two-device delivery, offline/reconnect and Android background/resume checks remain pending. Next: F09.

## Test-tool maintenance note

The Node packages are private, test-only dependencies under test/security; they do not ship in the Flutter app. npm audit currently reports 17 advisories (5 moderate, 12 high), including upstream Firebase CLI/SDK transitive packages. Its suggested remedies include major downgrades, and at least one advisory spans all available versions. These are unresolved tooling advisories, not evidence that the Flutter production bundle has those Node packages. Keep this tooling isolated to local/CI demo-emulator use and review upstream fixes rather than force-downgrading the validated tools.


## Batch 8: F09 implemented; local validation complete, live rollout pending

Operator registration records role intent and explicitly explains that administrator approval is required. The dashboard itself wraps every entry point in an approval gate; profile role alone cannot initialize GPS or operator controls. The gate requires a server-acknowledged `operator_access/<UID>` approval, rejects cached/pending approval, and withdraws access on revocation, sign-out, account switching, stream failure and pause. Resume requires a new approval check. Pausing stops the local GPS listener; startup continuations are fenced against starting tracking after pause/disposal. Backend rejection remains authoritative for in-flight operations. No developer fallback identities are used in these flows.

An explicit claim transaction reads both approval and the existing assignment before writing only driverId. An operator cannot claim as another UID or replace another driver's assignment; a retry for their own bus is idempotent. Removed the Reassign to Me action. Equipment controls/trip start require an existing matching assignment and cannot silently claim a bus. Rules separately constrain claim-only changes and assigned-driver equipment changes, deny self-release/takeover and reject revoked operators' telemetry. Administrative reassignment remains a trusted project-owner operation, with active-trip/telemetry reconciliation documented in [operator-approval.md](../operator-approval.md).

Validation: **339 Flutter tests passed**, including gate/account/revocation/resume and production claim transaction regressions. **36 local Firestore emulator tests passed**, including competing claims, claim-plus-equipment rejection, self-release rejection and revoked-operator denial. No live approval provisioning, Firebase rules deployment, new APK build or two-device/background-device validation was performed. See f09-test-results.log and test/security/rules-test-results.log. Full `flutter analyze lib test` reported **No issues found** (f09-analyze-results.log).


## Batch 9: F10 implemented and locally verified

Report.createdAt is nullable. Missing/null/unsupported/invalid timestamps remain Unknown instead of defaulting to DateTime.now(). Valid Firestore timestamps, DateTime values, ISO strings and legacy epoch milliseconds retain their actual instant. Parsing rejects overflowing calendar dates/time components and out-of-range epoch values without throwing. Map/copy/outbox round trips preserve unknown dates; even server-timestamp serialization does not stamp an undated record as newly observed.

Freshness, crowding freshness, expiry and last-checked calculations require a known creation time. A recent confirmation cannot manufacture freshness for a report whose original time is unknown. Undated positive observations cannot establish current equipment or endpoint access. Undated structural barriers remain unresolved warnings requiring recheck, without an invented observation/expiry time; resolved/hidden/publication restrictions still apply. Unknown dates sort after dated observations without inventing an epoch date for display.

Community/home relative-time text, evidence cards and report details handle Unknown explicitly. Undated evidence shows Unknown reported/checked/expiry times; report details do not falsely claim that such a report was recently active or previously expired. Publication and community mutation paths reject undated records. A malformed/restored outbox entry fails before photo upload or publication, retains its unknown timestamp and asks for a new dated observation instead of silently refreshing it on retry.

Validation: **347 Flutter tests passed**, including eight new parsing/instant-preservation/freshness/structural-warning/sorting/mutation/publication/outbox/widget regressions. Existing freshness fixtures were adjusted for the nullable model. Full `flutter analyze lib test` reported **No issues found**. Logs: f10-test-results.log and f10-analyze-results.log. No rules changes were required for F10; the existing server timestamp validation remains. No live record migration, Firebase deployment, APK build or device validation was performed. Next: F11.


## Batch 10: F11 implemented; local checks complete, live rollout pending

Bus ramp capability is separate from nullable rampOk, rampCheckedAt and rampCheckedBy. Missing/null/malformed flags remain Unknown instead of defaulting to working. A working flag requires a valid nonfuture check time, a nonempty observer and a check within the 24-hour product default. Legacy negatives remain unresolved warnings without synthetic timestamps/sources. Map/copy/equality retain evidence; a condition change without a new time/source invalidates the old check, and unrelated occupancy/assignment edits do not refresh it.

Scoped fresh community ramp observations can supply a working check where catalogue evidence is unknown; another bus's report cannot. Physical capability is still required. Unresolved community barriers and negative vehicle observations take precedence over positives. Wheelchair-required matching with unknown condition remains Unknown and cannot enter Accessible results. Ramp barriers exclude wheelchair-required journeys. Low-floor capability does not establish that a wheelchair ramp works. Route card labels/badges use the same evidence decision. Runtime sample flags were not given fabricated check times; explicit demo provenance is F12.

Operator controls initially show Unknown and require an explicit Working/Broken observation. Production ramp updates attach the signed-in actor and server check time. Rules require current actor/request time on ramp/check changes; occupancy-only updates preserve evidence. The cache reads exact server metadata after acknowledgement, or keeps the condition unverified if that read fails; it never guesses a server timestamp. Route details/live panels display vehicle capability, operational observation, checked time and source separately from GPS. Invalid future times do not display Just now. A driver's working observation does not resolve existing community barriers or verify the entire journey.

Validation: **357 Flutter tests passed**, including nine new equipment parsing/freshness/copy/scoping/capability/UI regressions and an acknowledged production-write regression. Existing planning fixtures now supply explicit dated evidence instead of treating rampOk:true as proof; simulated writers without metadata correctly remain Unknown. **37 local Firestore emulator tests passed**, including missing/forged/stale attribution rejection and occupancy preservation. The final equipment UI regression was also rerun after future-time display handling. Full `flutter analyze lib test` reported **No issues found** (f11-analyze-results.log). No production data migration, rules deployment, new APK or physical-equipment/two-device validation was performed. Existing positive flags need an actual new check, not bulk synthetic timestamps. Next: F12.


## Batch 11: F12 implemented and locally verified; live catalogue review pending

Default shared mode no longer preloads sample buses/routes or substitutes SeedData stops after empty/error reads. Removed automatic startup/search cloud seeding, operator debug seed action, hard-coded popular accessible corridor claims and shortcuts that could substitute unrelated endpoints. Refresh only retries reads. The old nearest-stop action no longer claims a fixed sample stop is geographically nearest. Shared search has a truthful empty state instead of dereferencing an empty list. Missing/removed service identity cannot resurrect a default bus in details. Removed fabricated recent-journey fallback history and default live-screen timetable values; live stop lookup uses supplied or acknowledged catalogue stops.

TransitCatalogue preserves acknowledged public records, provenance, collection receipt and original observation timestamps in a bounded cache. Authoritative full/empty snapshots replace/prune old records, and authoritative document deletion invalidates that ID. Pending/cache-only SDK snapshots cannot enter the acknowledged cache. Failed reads use only saved acknowledgement and show a saved/unavailable notice. Single-record reads do not renew the entire catalogue receipt. Unknown initial state never becomes sample data. Known legacy seed IDs are quarantined unless individually reviewed and explicitly designated operator_catalogue; marked demo records are always excluded from shared data.

TRANSIT_DEMO=true is an explicit local sample mode with a persistent DEMONSTRATION notice and demo timetable labels. Shared reports/photos/community mutations, assistance, GPS/trips/assignment and saved journey writes are service-guarded, related submission controls are disabled, and restored sender outboxes do not auto-retry. Demo transit reads do not mix shared catalogue/live tracking. The unused seed utility marks catalogue records as demo and no longer deletes old catalogues. Marked demo targets are also excluded from real report/assistance/journey/operator writes by local rules. No live seeding, deployment or catalogue relabelling was performed.

Validation: **369 Flutter tests passed**, including ten catalogue/cache/source/empty-state regressions and two demo-mode tests. The demo tests were additionally run with `--dart-define=TRANSIT_DEMO=true`: **2 passed**, covering sample/banner/no-live state and blocked report/photo, assignment, assistance, journey and trip writes. **38 local Firestore emulator tests passed**, including demo target rejection. Existing planning tests explicitly install fixtures instead of relying on production sample fallbacks; the two old default-bus/popular-route assertions were corrected. Logs: f12-test-results.log, f12-demo-results.log, test/security/rules-test-results.log. Full `flutter analyze lib test` reported **No issues found** (f12-analyze-results.log). No new APK, real-device or two-device walkthrough was performed. A reviewed real catalogue is still required; current shared mode may correctly show no services. See [transit-catalogue.md](../transit-catalogue.md). Next: F13.


## Batch 12: F13 implemented; administrator rollout remains pending

F07 already moved shared votes into transactions. Reward counters now have an explicit trusted administrator ledger/reconciliation policy: dated published non-demo reports on reviewed operator_catalogue targets earn 10 nominal points/report count; distinct non-author confirmations earn 5 points/confirmation count. Flags remove a confirmer's credit; hidden/deleted/three-flag reports reverse their contributions. Restoration can restore a unique credit without multiplying it. Resolved/expired historical contributions are retained. Pending, undated/future, demo or unreviewed-target records cannot earn rewards.

The administrator tool reads report/target/prior ledger and affected profiles in each transaction, writes user deltas and ledger/revision audit atomically, and defaults to dry-run. Concurrent reports preserve shared user totals; duplicate workers/retries cannot award the same contribution twice. Client ledger access is denied. Missing/corrupt profiles, oversized transactions and nonzero legacy balances without an explicit reviewed baseline policy stop processing without partial writes for that report. A batch can have earlier committed reports; idempotent reruns are documented. No paid Cloud Functions deployment is assumed.

Removed the false cash/voucher claim path and invented partner/priority benefits. Redemption is disabled and points have no monetary value. Screens explain recorded totals may wait for administrator review. Clients cannot mutate reward totals even without Firebase; new client profiles start at zero. Registration retries preserve existing authoritative profiles. Profile edits now write only allowed fields in a transaction, preserve trusted counters, propagate failure and update UI/cache only after acknowledgement. Pending local user snapshots cannot expose unacknowledged reward totals.

Validation: **372 Flutter tests passed**, including disabled redemption, client counter initialization/mutation rejection and acknowledged/rejected profile-edit counter/cache preservation regressions. **42 local Firestore emulator tests passed**, including admin-only ledger access, dry-run, simultaneous workers/reports, duplicate/self votes, reversal/restoration/hide/delete, ineligible records/targets, missing profiles and legacy migration refusal. Node syntax checks passed for both new administrative modules. Logs: f13-test-results.log and test/security/rules-test-results.log. Full `flutter analyze lib test` reported **No issues found** (f13-analyze-results.log).

The executable batch is administrator-operated, not an automatically running reward service. Live credentials, baseline migration, rules deployment, ongoing reconciliation and two-device checks have not been performed. No production points, cash or vouchers were granted. See [rewards.md](../rewards.md) for the policy, dry-run/application instructions and baseline safeguards. Next: F14.

## Batch 13: F14 false notification promise removed; stop alerts unavailable

Removed the local alert toggle, haptic feedback and snackbar promising a notification one stop before the destination. Both live-journey layouts now show a disabled Stop alert unavailable control with visible text explaining that automatic stop alerts and background notifications are unavailable. The screen-reader label includes this limitation and exposes a disabled button without a tap action. Request Assistance remains a separate enabled action when its target is valid.

This implements the audit's unavailable-control mitigation. It does not implement stop detection, foreground alerts or background delivery. Riders are told to follow trip progress manually; no notification is promised. Actual alert delivery remains a future feature requiring reliable trip/stop detection and device verification.

Validation: **375 Flutter tests passed**, including three new tests covering disabled interaction/no success message, screen-reader state and a narrow action row at 200% text with high contrast. After replacing deprecated semantics assertions, the three focused tests passed again (f14-targeted-results.log). Full `flutter analyze lib test` reported **No issues found** (f14-analyze-results.log). Full-suite log: f14-test-results.log. No Firebase rules changes, deployment, APK build or real-device/background-notification verification were performed. Next: F15.

## Batch 14: F15 implemented and locally verified

A shared EvidenceRefresh widget now re-evaluates visible evidence at the next observation/confirmation, freshness, crowding or vehicle-ramp check boundary, without waiting for a Firestore event. Existing inclusive expiry policy is retained: an observation expires immediately after its final valid instant. A one-minute maximum interval also updates relative-time labels and recovers from wall-clock changes. Timers stop while the app is inactive/paused/hidden and are cancelled on disposal; resume immediately rebuilds and schedules from the current time. EvidenceClock provides a shared injectable clock for deterministic UI tests.

Connected home recent-report filtering, community feed grouping/badges, report details/actions, route results and Accessible filtering, route details status, standalone evidence/ramp widgets and the live accessibility panel. Recalculation stays inside the existing stream builder so timer ticks do not resubscribe to the backend. Time-based expiry withdraws positive evidence and outdated Accessible matches; structural barriers remain unresolved warnings with needs-recheck text. New report/confirmation/bus data rearms the next deadline.

Validation: **383 Flutter tests passed**, including eight new regressions for exact-boundary positive expiry, persistent barrier recheck, an open but silent live report stream, community crowding moving to past reports, Accessible results losing an expired ramp check, report details expiry, background/resume and confirmation deadline replacement/disposal. The previous live-panel clock-change test now uses the shared one-minute fallback interval. Logs: f15-test-results.log and f15-targeted-results.log. Full `flutter analyze lib test` reported **No issues found** (f15-analyze-results.log). No rules changes, deployment, APK build or real-device lifecycle validation were performed. Next: F16.

## Batch 15: F16 implemented; local validation complete, live rollout pending

Previous non-author confirmers now have a Recheck condition action in community cards and report details. It records the same condition as still observed after 30 minutes since the report's latest dated creation/confirmation/recheck. The report-wide interval prevents competing repeat observations from multiplying the same check. UI explains changed conditions need a new report and rechecks earn no extra votes/points. The action becomes available at its clock boundary without requiring a data event.

Rechecks are distinct from unique votes: confirmedBy, confirmCount and lastConfirmedAt stay unchanged. A transaction writes server-attributed lastRecheckedAt/By/Id and a new immutable reports/<id>/rechecks/<checkId> audit observation together. Rules enforce authenticated previous-confirmation eligibility, active/non-demo published state, known original time, cooldown, linked history and unchanged counters. Reused history, isolated writes, spoofed times/observers and ordinary-confirm timestamp bypasses are denied. A rejected write does not update acknowledged local evidence; an immediate retry reads the saved cooldown. Competing transactions yield one saved observation; an overlapping attempt may explicitly fail rules validation and requires refresh/retry.

Freshness uses the latest valid attributed check while retaining the original report time. Undated, future/unattributed or reversed rechecks cannot create freshness. Structural faults remain barrier observations after recheck; they are not marked repaired. Evidence/details display the separate latest recheck source/time, and historical checks remain in the immutable subcollection. Reward reconciliation sees unchanged unique contributors and grants no additional points or ledger revision.

Validation: **393 Flutter tests passed**, including eight new model/service/widget recheck tests, a production Dart transaction commit/rollback/history regression, and the existing failure loop extended to rechecks. **46 local Firestore emulator tests passed**, including four new groups covering linked history/immutability, cooldown/authorization/spoofing/counter rejection, competing checks/retries and unchanged reward reconciliation. Full `flutter analyze lib test` reported **No issues found** (f16-analyze-results.log). Logs: f16-test-results.log, f16-targeted-results.log and test/security/rules-test-results.log. No rules deployment, live recheck, APK build or two-device validation was performed. Compatible rule rollout remains necessary; see [firestore-security.md](../firestore-security.md). Next: F17.

## Batch 16: F17 completion edge cases closed and locally verified

The normal final-arrival fix introduced in F08 is retained: arrival at the last valid stop completes the trip, preserves that stop's actualArrival and closes its linked broadcast in one transaction. No additional confirmation is required. Operator UI already cancels its GPS listener/timer after acknowledgement, and active-trip readers stop exposing completed trips. An explicit manual Stop remains distinct from confirming an actual final arrival.

Legacy in-progress records already pointing at their terminal index now complete that arrival without indexing beyond the itinerary or discarding its observation time. An existing actualArrival is retained; otherwise the explicitly confirmed arrival is recorded. Empty/out-of-range progress is rejected. A production retry that finds the requested trip progress already saved now also reconciles the linked telemetry instead of returning early and leaving a legacy broadcast active. It retains the acknowledged stop timeline, does not replace arrival times with retry time and refuses a replacement broadcast session. Failed commits retain acknowledged local progress and do not announce completion.

Validation: **398 Flutter tests passed**, including five new production-transaction regressions for two-stop/multi-stop terminal completion, legacy terminal records with/without an arrival, and stale-broadcast reconciliation with rejection/retry. Existing rollback, late-GPS/session rejection and completion-stream tests also pass; targeted run: **29 passed** (f17-targeted-results.log). **47 local Firestore emulator tests passed**; linked two-stop and four-stop itineraries retain each arrival and stop broadcasting on the terminal confirmation. Full `flutter analyze lib test` reported **No issues found** (f17-analyze-results.log). Full-suite log: f17-test-results.log. No Firestore rules changes/deployment, new APK, live trip or two-device/background-device verification was performed. Next: F18.

## Batch 17: F18 implemented and locally verified

Passenger segment planning, operator trip starts and ETA timetable/timeline comparisons now use the same ordered local schedule parser. Clock decreases roll into the next calendar day, including month/year/multiple-midnight boundaries; equal clocks do not fabricate an extra interval/day. The selected passenger date remains the boarding date even when the run started yesterday. Invalid clocks and interior timetable gaps reject planning/starting instead of becoming current/midnight timestamps. Missing trailing intervals share a disclosed six-minute model estimate.

Operator trips retain scheduledDepartureTime separately from actualDepartureTime. Initial estimates shift the ordered timetable by actual-minus-planned departure, so late/early starts keep their route durations and cannot put downstream estimates before departure. Default daily-run inference selects the departure nearest actual start, including yesterday's 23:50 run starting at 00:05. An optional explicit serviceDate overrides that inference. This has a 12-hour ambiguity boundary and is not a multiple-run routing engine; the dashboard displays planned/actual dates but has no run/date picker. Retry/resume preserves the existing acknowledged timeline.

ETA comparisons anchor to the trip's planned service day, avoiding day-sized false early/late offsets after midnight. Offline target boarding is aligned to its next daily occurrence while the full timeline retains midnight crossings. Tomorrow/date-qualified labels also wrap inside the narrow desktop live panel. Missing stop timetable values show Unknown in comparisons; results/details/confirmation disclose model estimates. See [scheduling.md](../scheduling.md) for the policy and inference limits.

Validation: **408 Flutter tests passed**, including ten new strict-clock, calendar rollover, equal-time, downstream boarding-date, late/early/explicit service-day, missing/invalid schedule and overnight ETA regressions. Existing passenger planning, operator transaction/retry, ETA and desktop resume layout tests pass. Full `flutter analyze lib test` reported **No issues found** (f18-analyze-results.log). Full-suite log: f18-test-results.log; focused run: **33 passed** (f18-targeted-results.log). No rules changes, emulator rerun, live timetable migration, deployment, APK build or real-device verification was performed. Next: F19.

## Batch 18: F19 implemented and locally verified

Extended the deletion/active-snapshot pruning introduced in F08. Authoritative document deletion now invalidates the shared cache and notifies every existing subscriber. Authoritative active-query snapshots prune absent broadcasting records, including an empty result; they do not claim a non-broadcasting document was deleted. Shared notifications carry a collection signal rather than an old map payload, so a queued unrelated local update reads current state and cannot reintroduce removed records. Caches/signals are partitioned by collection.

Pending SDK writes never enter acknowledged telemetry. SDK cache snapshots cannot insert/replace records or resurrect an authoritative removal. One-time reads require Source.server, and post-write refreshes also invalidate authoritative missing documents. Per-bus revisions and active-query generations fence older asynchronous reads/receipts, including a read for an uncached ID started before an authoritative empty query. Failed/offline reads retain only previously acknowledged in-memory data. A cold offline start without that data shows no GPS rather than importing unverified SDK cache contents.

Retained data carries local-only isCached provenance; cloud fields cannot set it and serialization does not publish it. Initial saved data stays unverified until a new receipt for that bus, including across timers/unrelated bus events. Stream failures/cache-only snapshots label saved data stale even when its timestamp is recent; reconnect server acknowledgement restores current provenance. Five-minute telemetry expiry emits a refresh without backend activity, with timers cancelled on unsubscribe. Live/details screens explicitly label saved GPS unavailable. ETA current-GPS badges require matching, fresh, acknowledged telemetry; recorded trip progress can still inform estimates but cannot establish current GPS or apply stale live-driver delays. Scheduled-only search labels remain F22 work.

Validation: **418 Flutter tests passed**, including ten new deletion/multi-listener, empty/partial active-query, cached/pending snapshot, offline/reconnect, server-read race, collection isolation, source-metadata, clock expiry and saved-location UI regressions. Older positive GPS tests now provide dated receipts; the details test verifies saved data is not LIVE GPS until a fresh acknowledgement arrives. Full `flutter analyze lib test` reported **No issues found** (f19-analyze-results.log). Logs: f19-test-results.log, f19-targeted-results.log and f19-ui-results.log. No Firestore rules changes, emulator rerun, deployment, APK build or real-device offline/reconnect verification was performed. Next: F20.

## Batch 19: F20 implemented; local validation complete, device verification pending

Report drafts now have seven-day retention from their initial local save; retry cannot extend it. Initialization, submission/retry, account changes and running-app minute maintenance prune expired payloads. Limits are ten drafts, 2 MiB per photo, 4,000 note characters and 15 MiB for the serialized outbox. New work is rejected when full instead of silently evicting existing drafts. Cleanup requires the app to run; stopped devices are cleaned on next initialization.

Android draft notes/photos move from plaintext SharedPreferences to an atomic AES-GCM encrypted file in app-private noBackupFilesDir, with a key generated in Android Keystore. Valid pending legacy records migrate within the bounds; published, expired and malformed records are discarded and the legacy preference key is removed. Other platforms currently retain private drafts only for the app session. These are implementation properties, not a claim of independently tested device/backup security. See [report-outbox-privacy.md](../report-outbox-privacy.md).

Publication acknowledgement removes the durable payload immediately. Session retry/UI acknowledgements retain only a bounded set of identifiers. Your uploads opens a delivery screen with Remove draft from this device, a confirmation describing already-sent requests, retry and retention text. Removal/account changes fence asynchronous upload/publication completions so they cannot recreate local drafts. Storage failures show failure and permit retry; account transitions hide other owners immediately. Sign-out clears drafts before succeeding, warns about draft loss and displays cleanup/sign-out errors. No account-deletion UI currently exists; an auth sign-out/deletion event follows the same local cleanup path.

The submission review explains public notes/photos and permission/sensitive-content precautions. Local removal cannot recall a request already sent, remove a public report or delete a Cloudinary photo; timeouts/cancellation can leave remote content. Server/admin public-content and orphan-photo deletion remain separate backend lifecycle work. Photos/EXIF are not automatically anonymized, and historical OS backups from older app versions cannot be recalled.

Validation: **427 Flutter tests passed** (f20-test-results.log). Nine new privacy regressions cover acknowledged-payload cleanup, retention across retry, size/count bounds, account transitions, owner rejection, late upload/publication callbacks, legacy migration, removal-save failure and the removal UI. The final privacy run passed **9 tests** (f20-privacy-results.log), and the sign-out notice regression now checks the loss/remote-request warning. Full `flutter analyze lib test` reported **No issues found** (f20-analyze-results.log). Android debug APK generation passed, including the Kotlin private-storage adapter; direct build verification exited 0. Artifact: build/app/outputs/flutter-apk/app-debug.apk. Existing native-access/Kotlin-plugin maintenance warnings remain. No rules changes/emulator rerun, deployment or real-device Keystore/backup/account-switch/crash-recovery verification was performed. Next: F21.

## Batch 20: F21 implemented and locally verified

High contrast and large tap targets are explicit device settings and persist across account changes. Wheelchair/step-free travel needs now use separate local records per UID. Guests have session-only needs; signing in does not copy guest needs into the account, signing out restores guest defaults, and signing back in restores that UID's record. The existing conservative default remains wheelchair access required on and step-free off for every new account/guest; the UI explains this and asks riders to review their needs. This is a product default, not an inferred disability or a WCAG requirement.

Legacy global needs have no trustworthy owner and are removed rather than imported into the next account. Device display choices survive migration; unsupported switches remain disabled and their old keys are removed. Missing/malformed owner records use defaults. Account records remain local for later sign-in; namespacing is logical isolation, not encryption/cloud sync. See [accessibility-preferences.md](../accessibility-preferences.md).

Startup loads the current UID before rendering; auth-state changes reload/reset needs, including external account changes. Login/registration wait for activation and sign-out resets immediately, with reload of the still-signed-in account if sign-out fails. Preference forms now subscribe to changes, and the existing journey-search listener picks up the new needs. Forms cannot save a cached previous-owner snapshot after an account switch or navigate with a stale supplied profile. Serialized saves capture their original UID/value pair; delayed writes/completions cannot overwrite the next account or show its UI an old-account save failure. Rejected storage writes show failure instead of a saved-success message. Guest save wording explicitly describes session-only travel needs.

Validation: **437 Flutter tests passed** (f21-test-results.log), including ten new account tests for restart, guests, legacy removal, delayed/overlapping saves, write rejection, auth streams, malformed records/reset isolation, open forms and open journey search. The final account run passed **10 tests** (f21-account-results.log). Existing registration, unavailable-feature and touch-target fixtures now initialize preference storage and check the scoped policy; registration also checks the activated UID. Focused preference/filter run: **18 passed**; auth/support/touch-target run: **19 passed** (f21-targeted-results.log and f21-integration-results.log). Full `flutter analyze lib test` reported **No issues found** (f21-analyze-results.log). No Firestore rules changes/emulator rerun, deployment, new APK build or real-device shared-account/accessibility verification was performed. Next: F22.

## Batch 21: F22 implemented and locally verified

Route results now present timetable planning only. A departure-time difference cannot create Ongoing, Approaching, Arriving now or a live flag. Cards retain Scheduled/Demo timetable provenance and explicitly explain timetable estimates, unconfirmed departure and where to check GPS status. Near/passed departure labels remain scheduled and cannot imply that a bus arrived or departed. Date-qualified timetable selection continues to preserve the selected run/date/segment.

Removed the result model's isLive/liveStatusLabel fields and its active-trip elapsed-departure badge. A recorded trip and time since its departure do not establish current vehicle movement. Result selection carries timetable wording into route details. Results do not make GPS claims; details/live journey retain the F19 acknowledged/fresh/matching-bus GPS checks and saved/stale labels. See [scheduling.md](../scheduling.md). No new result-screen telemetry subscriptions or background tracking were introduced.

Validation: **442 Flutter tests passed** (f22-test-results.log). Five new widget regressions cover approaching-time, near-departure and just-passed-departure cases, a future selected day, and an open screen crossing departure without backend activity; selection checks timetable provenance in route details. New targeted provenance run: **5 passed** (f22-provenance-results.log). Existing schedule/navigation regressions passed (f22-targeted-results.log), and the saved-selection test checks Scheduled provenance. Full `flutter analyze lib test` reported **No issues found** (f22-analyze-results.log). No Firestore rules changes/emulator rerun, deployment, new APK build or real-device live-GPS verification was performed. Next: F23.

## Batch 22: F23 implemented and locally verified

Route filter state, comparisons and tab callbacks now use one RouteFilterTab enum rather than display strings. The Accessible empty-state recovery branch uses the actual typed tab value. Show all matching buses is reachable when removing the optional Accessible tab filter can reveal other journeys. Its disclosure explains that unknown access/reported barriers may be visible; explicit trip wheelchair/step-free requirements remain applied. All/Fastest cannot silently bypass those requirements.

When requirements leave no matching journeys, Review trip requirements opens an explicit per-trip review. It shows the currently effective wheelchair/step-free needs and warns that relaxing them may expose unknown access/barriers. Keep requirements cancels without mutation. Apply to this search changes only this result screen, recomputes matches and passes the reviewed needs into route selection; account preferences remain untouched. A zero-count matching-all button is not offered as a recovery that would reveal no results. See [accessibility-preferences.md](../accessibility-preferences.md).

Validation: **447 Flutter tests passed** (f23-test-results.log), including five new widget regressions for reachable optional-tab recovery/disclosure, hard-wheelchair protection across All/Fastest and cancellation, explicit per-trip relaxation, retained step-free requirements in matching-all selection, and step-free empty-state review/selection. Focused recovery run: **5 passed** (f23-recovery-results.log). Existing accessible-filter/preference tests also passed (f23-targeted-results.log). Full `flutter analyze lib test` reported **No issues found** (f23-analyze-results.log). No Firestore rules changes/emulator rerun, deployment, new APK build or real-device screen-reader/recovery verification was performed. Next: F24.

## Batch 23: F24 disclosure/consistency implemented; authoritative fare mapping remains unavailable

All fare amounts now use shared estimate/unknown wording and accessible source semantics across results, details, confirmation and live journey. Visible disclosure identifies the prototype duration/stop model, excludes official tariff/service-class/fare-stage/concession claims and asks riders to confirm the actual fare with the operator. The calculator is centralized; its existing coefficients/rounding/clamp remain explicitly prototype design choices. See [fare-estimates.md](../fare-estimates.md).

The selected passenger segment amount flows through selection, acknowledgement/save and resume without a separate full-route/current-time calculation. Live journey uses the saved journey value or a matching selected vehicle/segment value, so another resolved vehicle cannot inherit an unrelated route price. Removed the 95/250/80 LKR route/details/live defaults and unsupported standard-ticket/cash/digital-ticket claims. Missing/nonpositive amounts display Fare unknown instead of zero/free or a made-up default.

Checked [NTC's official fare page](https://ntc.gov.lk/Bus_info/bus_fares.php?lang=en), which publishes fare-stage and route/service tables. No reviewed mapping from this catalogue's selected stop IDs to applicable tariff stages/classes/effective tariffs exists in the app. Those official tables have therefore not been substituted using guessed stop counts/durations. Authoritative fare integration remains external data/mapping work; every current numeric fare remains a disclosed prototype estimate. No real fare accuracy or payment support is claimed.

Validation: **451 Flutter tests passed** (f24-test-results.log). Four new widget regressions cover results/details/confirmation/save/restore/live consistency for a 15-minute selected segment, unknown direct launches, mismatched vehicle selection and amount/source semantics. Focused fare run: **4 passed** (f24-fare-results.log); existing planning/schedule/persistence run: **24 passed** (f24-targeted-results.log). The route-results fare fixture now expects Est. LKR wording. Full `flutter analyze lib test` reported **No issues found** (f24-analyze-results.log). No Firestore rules changes/emulator rerun, tariff import, deployment, new APK build or real-device fare/TalkBack verification was performed. Next: F25.

## Batch 24: F25 already removed by F06; regression verification complete

The original dormant confirmation screen was replaced when F06 connected the production results/evidence/confirmation/save/resume flow. Current confirmation has no operator_system identity, fabricated coordinates/speed, telemetry model/writer or fixed verified-ramp statement. It saves the passenger's reviewed journey through JourneyService and explicitly distinguishes saving from booking/running-service confirmation. GPS creation/broadcasting remains in authorized operator flows. No additional runtime change was necessary for F25 in this batch.

Confirmation uses the existing scoped LiveAccessibilityPanel with the actual bus and boarding/destination IDs. Capability without a valid dated/attributed ramp check stays Unknown. Passenger acknowledgement does not create an equipment check or upgrade that Unknown condition to verified working access. Real scoped evidence remains independently observable, including barriers and freshness rules from earlier fixes.

Validation: **453 Flutter tests passed** (f25-test-results.log). Two new regressions exercise the production JourneyService transaction on rejection/save/idempotent retry while preserving existing bus/trip/GPS/report documents and writing only the passenger journey, and confirm that an undated ramp capability remains Unknown before/after saving with the correct scoped panel targets. Existing acknowledgement/failure/guest/ownership/navigation/resume tests also pass. Full `flutter analyze lib test` reported **No issues found** (f25-analyze-results.log). Source search found no fabricated operator_system/legacy verified-active claims in lib. No Firestore rules changes/emulator rerun, deployment, new APK build or real-device/cross-account verification was performed. Next: F26.

## Batch 25: F26 reconciled; feature claims and current evidence corrected

Replaced README/read.md's production-ready/feature-complete claims, stale file tree, audio-assisted/TTS completion, fallback-telemetry description and blanket completed-QA assertions. Both entry points now link the maintained [feature inventory](../feature-inventory.md) and this log. The inventory ties connected capabilities to source/tests/policies and distinguishes unavailable features, local evidence, external rollout/device checks and pending assignment outputs. It explicitly separates timetable/fare estimates, GPS receipts, assistance acceptance, informational membership/rewards and unavailable ticket/payment/voice/notification capabilities. Corrected the run prerequisites: pubspec's ^3.13.0 is the Dart constraint, not a Flutter version.

Current inventory found Sprint1_QA_Test_Plan.docx and Sprint1_QA_Tracker.xlsx as existing tracked files at repository root. The original audit's not-found note was an inventory gap; it is preserved as part of that snapshot and corrected in current documentation. F26 did not review their contents, coverage or sign-off and does not call those QA deliverables completed/validated. No pitch deck/poster/MP4 artifacts were found in the current source/artifact scan. Participant/design/contribution/reflection evidence remains pending or unsupplied; no results or pitch claims were invented.

Onboarding now describes evidence review, unavailable voice guidance, conditional shared GPS, operator-response-dependent assistance and reviewed rewards. Its static ETA/assistance states are explicitly Example/Preview only; the fixed Driver notified success/check state became an awaiting-reply illustration. Removed stress-free/best-route/automatic-badge implications. Updated supporting preference/security docs to reflect completed local fixes while retaining external verification limits. No new voice, notification, payment or other capability was added by changing the copy.

Validation: **453 Flutter tests passed** (f26-test-results.log); full `flutter analyze lib test` reported **No issues found** (f26-analyze-results.log). No new tests were added for wording-only edits. README/read.md/inventory local links were checked against existing files, artifact presence/tracking was inventoried and source/docs claims were searched. The current Android debug APK built successfully with direct exit 0 at build/app/outputs/flutter-apk/app-debug.apk, including the subsequent F21-F26 changes; it is not a signed release. Existing native-access/Firebase Kotlin-plugin maintenance warnings remain. No rules changes/emulator rerun, deployment, QA-document content review, participant study or physical-device onboarding/TalkBack verification was performed.

F01-F26 have now been individually processed in the local working tree; several findings use explicit unavailable/prototype mitigations rather than adding the missing capability. This is not production-readiness approval. Next work is the documented manual/emulator walkthrough and real-device/cross-account/accessibility validation, separately authorized external configuration/rollout, then the user's pending assignment studies and artifacts with an iteration after actual feedback.

## Emulator validation: isolated local backend, 2026-10-15

The user authorized a local Firebase Auth/Firestore setup because the real shared catalogue and operator approval are not provisioned. Added an opt-in Android debug build with a separate `.validation` package, explicit demo project/local endpoints, a LOCAL TEST ONLY banner and blocked external photo uploads. A guarded script provisions only synthetic local passenger/operator/catalogue fixtures. Default app configuration remains separate. See [setup instructions](../local-validation.md) and the [execution record](emulator-validation-2026-10-15.md).

The emulator walkthrough verified scheduled results -> scoped details -> confirmation -> saved journey -> tracking, with the same synthetic bus/stops and estimated fare. Passenger confirmation created no trip/GPS documents. A ramp request reached the assigned approved local operator; operator acknowledgement was saved and then displayed to the passenger after a manual account switch. The receipt explicitly says assistance has not been completed. This is one emulator with sequential accounts, not simultaneous devices or real-service verification.

Opening a bus listener exposed a false saved-catalogue notice caused by its initial SDK-cache event. The listener now preserves the previously acknowledged full-catalogue receipt during initial cache/pending events; later cache transitions still mark it saved, and a single-bus update cannot renew the whole catalogue. Targeted regression coverage: **11 passed**. Full Flutter suite after the fix: **455 passed** (`local-validation-full-tests.log`); full analyzer: **No issues found**, exit 0. Local Firestore rules suite before the walkthrough: **47 passed**. The verified separate local APK was installed and the notice fix was checked through refreshed results -> details. Restart/resume also preserved the journey and acknowledged assistance. A new follow-up remains: details/live timetable cards say Departed despite missing GPS, even though their badges/disclaimers say Scheduled. Build-command status caveat and remaining device checks are recorded in the execution log; no production deployment or participant evidence is claimed.

### Timetable wording follow-up

The shared ETA result now labels timetable-only observations as `Scheduled for <dated time>` or `Scheduled time passed`, including when GPS is absent, stale or cached. Details, live journey and their shared ETA cards consume this same result, so elapsed timetable time no longer produces Departed/Arriving claims. Unknown timetable data still displays ETA unavailable. Fresh telemetry and recorded active-trip calculations keep their existing estimate behaviour.

Regression coverage includes before/at/after the scheduled time, next-day rollover, missing/stale/cached telemetry and both details/live widgets. **458 Flutter tests passed** (`scheduled-wording-tests.log`), including three new regressions; targeted ETA/cache tests: **19 passed** (`scheduled-wording-targeted.log`). Full `flutter analyze lib test`: **No issues found**, exit 0 (`scheduled-wording-analyze.log`).

The local `.validation` debug APK built with direct exit 0, was package-verified and installed successfully. Resuming the saved synthetic journey in the emulator showed Scheduled for Tomorrow, 03:52 PM instead of Departed. The earlier wording follow-up is now corrected locally. Production rollout and remaining device validation are still separate.

### Shared catalogue diagnosis and assignment demonstration setup

The user returned to the original app and asked to address its empty-catalogue notice. Read-only public REST requests succeeded: the configured shared project contains 21 stops, 9 routes and 29 buses. All 59 document IDs match repository samples, with no catalogueSource/isDemo provenance; F12 excludes these unreviewed legacy IDs. This is a quarantine result, not an empty remote database or a reproduced read denial. Write rules/deployment were not tested by these reads. A public-field-only review input is saved at `docs/catalogue-review/pending-catalogue.json`.

The user confirmed the records are assignment samples only. Selected the existing explicit `TRANSIT_DEMO=true` mode for the original Android package, preserving the separate local validation app for synthetic write-flow testing. No shared records were relabelled and no production catalogue was seeded. Demo mode visibly identifies sample data and blocks shared reporting, assistance, journeys and operator writes; it does not turn samples into verified real services.

Demo-mode regression suite: **2 passed** (`assignment-demo-tests.log`). The original-package demo debug APK built with direct exit 0, was package-verified with aapt, installed with `adb install -r` and launched successfully. Artifact: `build/app/outputs/flutter-apk/assignment-demo-debug.apk`. Existing account data was preserved.

Visual verification: the original app displayed its DEMONSTRATION banner, Home and sample stop selectors. Pettah -> Mount Lavinia with the existing Ramp Required setting correctly returned no known-accessible buses because the sample equipment has no dated checks. For a sample-list preview, the explicit Review trip requirements dialog disabled the wheelchair constraint **only for that search**; saved preferences were retained. Results then showed **13 buses**, labelled Demo timetable, with Unknown access and estimated-fare disclosure. The app was left on that sample results screen. This does not demonstrate actual accessibility or real service availability.

### Shared reset and sourced-catalogue candidate (not applied)

The user subsequently authorized resetting all shared Firestore and Auth data, supplied eight replacement accounts, and requested internet-sourced transit information. Administrative backups contain 128 Firestore documents and 16 Auth accounts, including password-restoration configuration, in a gitignored private directory. The prepared reset plan is guarded by file hashes, current inventory/update-time checks and an apply fingerprint; its default read-only preflight passed. No deletion, account provisioning or deployment has occurred yet.

The candidate imports four publisher-listed NCG timetable runs, two directions and five timing points; vehicle identity/assignment, accessibility, occupancy and boarding coordinates remain unknown. Published timetables are now explicitly distinct from physical vehicles in models/UI/service guards/rules; maps cannot show a fabricated vehicle, unknown occupancy cannot default to Low, and timetable records cannot be claimed/broadcast or receive vehicle equipment reports/assistance. Passenger journey saving remains available. Replacement driver profiles have pending approval, not an invented affiliation with the operator.

Validation: **461 Flutter tests passed**, **49 isolated local rules tests passed**, full analyzer **No issues found**, normal Android debug build direct exit 0. Candidate APK is preserved but not installed. See the [concrete reset plan and sources](../catalogue-review/shared-reset-plan.md). The original audit explicitly calls for separate deployment approval; the tested rules are ready for that final approval before applying the reset and installing the shared build.

### Shared reset applied after explicit approval

The user approved rules deployment and the reset. The immediate preflight still matched all 128 old Firestore documents/update times and 16 old Auth account IDs. Firestore-only rules deployment exited 0; the active release was fetched and its source SHA-256 matched the tested rules. The exact approved plan completed, leaving **8 Auth accounts and 23 Firestore records**: eight profiles, four pending operator approvals, five timing points, two directions and four sourced timetable services. Old reports, journeys, GPS/trips and catalogue data were removed; backups and Auth restoration parameters remain in the private Git-ignored reset directory. No Cloudinary media, Storage objects, indexes or billing settings were changed.

Actual shared-project checks verified **all 8 password sign-ins**, correct own-profile role/email reads, **8 denied cross-account profile reads**, four pending operator approvals and four public unassigned timetable records. Live locations, trips and reports were empty. Credentials were written to `.private/firebase-reset/new-account-credentials.txt`; no credentials or private backup contents are in public docs. These are real backend checks, not simultaneous-device/operator delivery or real-fleet verification.

The checksum-verified normal shared-backend APK was installed and launched, without demo/local banners. The emulator retained a cached old account identity, so the user was asked to manually sign out/sign in to a new passenger account; UI automation did not authenticate. See the [updated execution record](../catalogue-review/shared-reset-plan.md) for sources, evidence and remaining vehicle/operator/accessibility limitations.

The user then confirmed the new passenger login/Home. Visual inspection confirmed Home and shared timing-point selectors, without a demo banner. Ramp Required searches correctly returned no known-accessible matches because the sourced timetable records have no equipment checks. Simultaneous user input prevented further automated navigation; clicks were stopped and search-only requirement review was explained. Saved travel preferences were not changed. This verifies new-account startup/catalogue loading, not a completed new-account journey-save or real operator flow.

### Saved catalogue notice refresh correction, 2026-10-16

The user reported the Saved transit data / updates unavailable banner on Plan after restarting the shared app. Source inspection found that disk restoration marks all catalogue collections saved, but Plan previously refreshed only stations. Buses/routes could remain saved indefinitely and keep the global notice visible despite a successful station read. Read-only shared REST checks succeeded with five stations, two routes and four timetable records; this does not prove emulator network connectivity, but rules/data availability was confirmed.

Plan now refreshes all three catalogue collections in parallel, including its existing retry action. The shared notice offers an explicit Refresh button that retries the same full catalogue. Saved-cache wording now asks the rider to refresh rather than claiming updates are unavailable merely because cache was restored. Actual failed reads retain acknowledged cached data; only server-acknowledged reads clear the saved state. No cloud records, rules, account data or accessibility preferences were changed.

Targeted catalogue/listener regression run: **13 passed** (`catalogue-refresh-tests.log`). New checks cover full saved-catalogue refresh from Plan and a failed offline retry followed by successful recovery through the notice action. Existing disk-restoration and listener-provenance tests remain included.

Final validation: **463 Flutter tests passed**, full analyzer **No issues found**, and normal Android debug APK build exited **0**. The user's active `flutter run` session was preserved; a capital `R` hot restart is needed to load the changed initialization. This correction has not yet been visually rechecked in that running session.

### Source-backed shared catalogue expansion, 2026-10-16

The user explicitly selected source-backed shared transit data rather than demo observations. Added 17 timing points, 12 route directions and 32 daily timetable runs from the operator's published timetable, leaving **22 stations, 14 routes and 36 published timetable records** in total. All 61 additions were verified through administrative and public reads; all original 11 catalogue records retained their exact fields/update times. No existing data, Auth accounts, approvals, reports, GPS or rules were changed. Six overnight runs are included; ambiguous AM/PM entries and duplicate departures were excluded. These records do not establish physical vehicle identity, equipment, live operation or precise boarding coordinates.

Validation: **4 focused Flutter tests passed**, including all selected timing-point pairs and midnight rollover in the new dataset; targeted analyzer **No issues found**. Before/plan/result evidence is under private `.private/catalogue-expansion/`. The initial post-write comparison failed on Firestore null serialization; normalized read-only verification subsequently passed, with no repeated import. See [catalogue details and sources](../transit-catalogue.md) and [source transcription](../catalogue-review/expanded-timetables.json). Refresh the running app's Plan catalogue; this data-only import needs no new build. A live visual walkthrough of these new directions remains unperformed.

### Interactive shared Sample/Test mode, 2026-10-16

The user subsequently requested plausible synthetic data for the remaining flows and explicitly chose a clearly labelled Sample/Test mode in the shared application. Added the `SAMPLE_TEST=true` startup flag and persistent amber warning. Same-project Firestore operations use `sample_test/shared` for profiles, approvals, catalogues, reports/audits, assistance, journeys, trips and GPS. Catalogue cache, account travel needs and both outboxes are partitioned; Android drafts remain encrypted in a separate no-backup file. Auth and device display settings remain shared. Sample registration and external Cloudinary upload are disabled with truthful unavailable states. Existing unsupported product features remain unavailable.

Seeded **143 scoped fixture records**: 8 profiles, 4 scoped approvals, 22 timing points, 14 route directions, 36 copied published timetables plus 16 fictional assigned vehicles, 16 reports, 3 resolution audits, 8 assistance requests, 8 journeys, 4 trips and 4 GPS snapshots. Sample timetable durations use source timing offsets with fictional departure slots. GPS snapshots/coordinates, observations and equipment assessments are synthetic, with original aging/expiry logic retained. Before a walkthrough, an explicit fixed-fixture refresh may be needed. Three backend lifecycle verification runs added three cancelled sample validation requests. All **84 original root records** were preserved by seeding and the fixture refresh; Auth credentials and normal operator approvals were unchanged.

Generated/scoped authorization was validated with **50 local Firestore rules tests**, then deployed successfully. Read-back source matched the final local SHA-256 `edbc10858c7a27771460930b60c20811cd3eba390229368f401afb52e78185fb`; the normal root policy was compared against the prior deployed rules source and was exactly unchanged after newline normalization. Actual shared-project checks verified all **8 sign-ins/owner sample profiles**, **8 denied cross-profile reads**, 4 sample approvals versus 4 pending normal approvals, passenger request creation, assigned operator acknowledgement, passenger receipt read and passenger cancellation. Private fixture backups/results and verification evidence are under `.private/shared-sample/`.

Final checks: **467 normal-mode Flutter tests passed**, **3 Sample/Test mode checks passed**, full analyzer **No issues found**, sample Android debug APK build direct **exit 0**. APK manifest confirms the normal shared package `com.accesstransit.access_transit`; preserved artifact `build/app/outputs/flutter-apk/shared-sample-debug.apk`, SHA-256 `D5BB3384D8093802A8AC792CD5909612030DEE90B86C89E3C94193A17A81AC90`. The existing running app/session was not replaced. Start with `flutter run -d emulator-5554 --dart-define=SAMPLE_TEST=true`; omit the flag to return to sourced mode. This is a startup/build mode, not an in-app toggle. No visual walkthrough or simultaneous two-device test of this new mode is claimed. See [shared sample guide](../shared-sample-mode.md).

### Sample buses missing: activation and scenario correction, 2026-10-16

The user reported no buses after setup. Read-only process/package checks showed the active Flutter run had no `SAMPLE_TEST` flag and the installed app predated the sample build. Installed the checksum-verified saved Sample/Test APK into the existing normal package and launched it, retaining the Auth session. The user confirmed the SAMPLE / TEST MODE banner. Emulator and host UTC clocks matched; filtered startup error logs were empty. Windows UI capture failed twice with `window crop is outside captured monitor`; input attempts stopped, so results were not independently visually inspected.

Source inspection also found a fixture design error: station barriers on Kandy and Badulla plus ramp condition grouped by direction could remove all four primary routes under the default wheelchair filter. Moved station barrier examples to other sample timing points and distributed working/faulty/unknown ramp cases by departure group. Every primary direction now retains a working, clear-endpoint option; no passenger requirements or safety filters were changed. Refreshed only the 143 fixed sample fixture IDs with update-time preconditions, preserved all 84 normal records and left non-fixture sample activity intact.

A new read-only exporter captured the actual public sample catalogue/reports and anonymized all eight actor IDs. The committed snapshot regression exercises real passenger planning plus wheelchair/step-free evidence matching in all four primary directions, while requiring faulty/unknown/barrier cases to remain present. **1 targeted regression passed**, targeted analyzer **No issues found** (`shared-sample-search-tests.log`, `shared-sample-search-analyze.log`). This supplements the preceding 467-test run; no new full-suite total is claimed. Users already on results should reopen Plan and search again to fetch the corrected catalogue.

### UI alignment step 1: vehicle ramp observation, 2026-10-16

Scope corrected per user feedback: retain the existing app UI and align newly added blocks individually, rather than redesigning whole screens. Styled only `BusRampObservation` using the existing surface/outline colors, 16px card radius, brand typography and high-contrast treatment. Capability, operational condition and check age remain visible; source and exact local check time expand inside the card. Replaced raw operator identifiers in presentation with the role label Operator observation. The community-barrier warning remains visible when collapsed. Freshness and operational matching logic are unchanged.

Validation: **49 focused regression tests passed**, **4 ramp layout tests passed** (320dp, normal/200% text, working/unknown/broken and high contrast), targeted analyzer **No issues found**. Generated widget renders were visually inspected under `build/ui-ramp-style/`; these are test renders, not native device screenshots. No APK installation or backend changes were made in this step. Existing Flutter run session was retained; hot reload is required to view the update. Next scoped component: Accessibility evidence.

### UI alignment step 2: accessibility evidence card, 2026-10-16

Aligned only the newly added AccessibilityEvidenceCard with the existing app card style. Vehicle, boarding-stop, destination-stop and driver-assistance scopes retain separate summaries. Observation metadata now expands per scope; empty scopes remain explicitly Unknown. Collapsed summaries prioritize unresolved/active barriers over newer positive observations. Exact check/report/confirmation/expiry metadata remains available, using local display time. Attribution retains available reporter names, uses Community member when unavailable and displays unique confirmer counts rather than raw account IDs; rechecker IDs are likewise omitted from presentation. Target scoping, eligibility, freshness and operational matching policies are unchanged.

Validation: **42 focused regression tests passed**, **3 evidence layout tests passed** (320dp, normal/200% text and high contrast), targeted analyzer **No issues found**. Layout checks cover a stale unresolved barrier alongside a newer positive observation, expanded metadata, unique confirmation counts and absence of raw actor IDs. Generated widget renders under `build/ui-evidence-style/` were visually inspected; native device/TalkBack validation is not claimed. No APK installation or backend changes were made. Use hot reload in the existing Flutter session. Next scoped surface: Confirm Journey, aligned to the existing UI rather than a global redesign.

### UI alignment step 3: Confirm Journey, 2026-10-16

Aligned the newly added JourneyConfirmationScreen with existing app colors, centered header, rounded outlined cards and navy action styling. Grouped the selected service/endpoints, travel schedule, estimated fare and requirements. Long endpoint names wrap; internal stop IDs and bus-ID fallback labels are omitted from presentation. Fare limitations remain visible through Fare details, with the estimate clearly labelled. Save errors are announced and scrolled into view. Existing acknowledged save, retry/idempotency, owner checks and live-journey navigation remain in place; no service/backend changes were made. LiveAccessibilityPanel remains the next separate alignment step.

Validation: **23 focused tests passed**, including the 20 existing save/persistence/fare regressions and 3 responsive confirmation tests at 320dp with normal/200% text and high contrast. Checks include full stop names, missing physical vehicle identification, accessible fare details and failed saves retaining the confirmation screen. Targeted analyzer **No issues found**. Widget renders under `build/ui-confirmation-style/` were visually inspected; native device/TalkBack behavior is not claimed. No APK installation was performed; use hot reload in the existing Flutter session.

### UI alignment step 4: Live Accessibility panel, 2026-10-16

Aligned only LiveAccessibilityPanel with the existing card colors, rounded outline, typography and spacing. Community observations now have separate readable ramp/boarding-elevator/destination-elevator rows, with non-color status icons. Operator vehicle checks are explicitly labelled as a separate source. Full scoped evidence is available through View observation details instead of repeating all summaries on initial display. Relevant driver-assistance observations remain visible in the summary, so collapsing detailed evidence cannot hide an assistance barrier. Stream failures and negative ramp telemetry receive distinct visible warnings. Existing equipment scoping, freshness policy, telemetry conflicts and failed-read barrier retention remain in use.

Validation: **40 focused regressions passed**, **3 responsive panel tests passed** (320dp, normal/200% text and high contrast), targeted analyzer **No issues found**. New checks cover long stop names, ramp/boarding/destination separation, driver-assistance barriers before disclosure, expanded timestamps, actor-ID-free presentation and failed updates removing working claims while retaining barriers. Generated widget renders under `build/ui-live-panel-style/` were visually inspected. No backend changes or APK installation were made; hot reload is required in the retained Flutter session. Native device/TalkBack validation remains pending.

Four-component alignment checkpoint: full Flutter suite **481 passed** (`ui-alignment-checkpoint-tests.log`); full `flutter analyze lib test` **No issues found** (`ui-alignment-checkpoint-analyze.log`). This validates the current working tree's automated checks, not native device/screen-reader or live backend delivery.

### UI alignment step 5: assistance request status, 2026-10-16

Aligned the newly added AssistanceRequestStatusScreen with existing app surfaces, rounded cards, typography and navy actions. Request delivery, route/stop/support details and driver response are separate cards. Raw bus identifiers are omitted from presentation. Pending/Sent/acknowledged/completed/declined/cancelled labels retain their existing meanings, with contextual acknowledgement guidance and visible offline/error notices. Retry/cancel conditions and owner-only access behavior are unchanged. The title wraps at large text sizes instead of truncating. No global theme, assistance form, operator workflow or service/backend changes were made.

Validation: **22 focused assistance regressions passed**, **3 receipt layout tests passed** (320dp, normal/200% text and high contrast), targeted analyzer **No issues found**. Layout checks exercise failed upload retry, remote delivery and all five driver states, full stop names and omission of internal actor/target IDs. Generated widget renders under `build/ui-assistance-status/` were visually inspected. No APK installation or native TalkBack/device validation was performed; use hot reload in the retained Flutter session. Next scoped surface: report delivery/upload receipt.

### UI alignment step 6: report delivery and uploads, 2026-10-16

Aligned ReportSubmittedScreen and ReportOutboxList with existing app cards, typography, spacing and navy actions. Publication status, observation details, attached photo and draft-retention guidance are grouped separately. Pending/failed/published states, acknowledged-only Community access, retry, owner-filtered uploads and local draft removal retain their existing delivery/storage behavior. The removal warning explicitly distinguishes deleting a local draft from deleting a public report or uploaded photo. Large-text dialogs scroll; actions wrap without fixed-height clipping. Button typography follows the existing theme with 48/60dp minimum sizing. No global theme, report form, backend or retention-policy changes were made.

Validation: **31 focused report/privacy/touch-target tests passed**; **3 responsive receipt tests passed** at 320dp with normal/200% text and high contrast. New checks exercise offline pending, rejected retry, successful acknowledgement and durable draft cleanup. Full alignment checkpoint: **487 Flutter tests passed**, full analyzer **No issues found** (`ui-alignment-final-tests.log`, `ui-alignment-final-analyze.log`). After the final button-font adjustment, responsive/touch-target tests passed again (`ui-report-delivery-layout-tests.log`); targeted analyzer was also clean. Widget renders under `build/ui-report-delivery/` were visually inspected; these are generated test renders, not native device screenshots. No APK installation or backend changes were performed. Use hot reload in the retained Flutter session; native device/TalkBack verification remains pending.

### Admin console implementation, 2026-10-16

Added an admin-only Flutter console using the trusted Firebase admin custom claim. Includes catalogue CRUD for physical buses/published timetables, routes and stops; ordered stops and complete schedules; explicit source review; approved-driver assignment; searchable user profiles and name/phone editing; pending driver discovery, approve/reject/revoke with review evidence and reviewer attribution; and transactional private activity records. Profile roles cannot grant admin authority. Revocation releases assignments but retains active trip/telemetry history for project-owner reconciliation. Auth account disabling/deletion/password operations remain outside this console.

Deletion checks dependencies, withdraws an eligible record from new references, rechecks dependencies and then deletes it. Interrupted deletions expose Restore/Finish deletion. New server rules reject references to withdrawn records, while passenger caches exclude them. Existing passenger/operator authorization was retained. Added admin account-switch/resume/error tests, permission and immutable-activity tests, and CRUD/assignment/deletion/failure regressions.

Validation: **509 Flutter tests passed**, **52 isolated Firestore rules tests passed**, full analyzer **No issues found**, normal-mode Android debug APK build passed. Widget previews were inspected at normal/large text; 320dp/200%/high-contrast tests passed. Live rules were backed up. Automatic approval review rejected the shared rules deployment because explicit authorization for that persistent authorization-boundary change was required. The requested account's claim plan/backup is prepared, but no claim was granted, no real driver was approved and no catalogue was mutated by this session. Live activation remains pending; see [admin console guide](../admin-console.md).

### Product flow phase 1: registration and localization foundation, 2026-10-16

Aligned contributor registration with passenger permissions in local root/generated Sample/Test rules. Added early rejection of public admin registration, clarified Reporter/Driver registration labels and retained the independent operator approval gate. New rules tests verify immediate reporter reporting/assistance access while denying self-promotion, approval writes and bus operation.

Added generated English/Sinhala/Tamil localization resources and app delegates, initial login/registration messages, and a language selector on Login/Profile. Language persists locally per UID, separately for guest and Sample/Test; account switching reloads defaults/saved language, delayed old-owner saves cannot change another account, and storage failures retain the old locale. This is the localization foundation, not a fully translated app or cross-device locale sync; fluent translation and native accessibility/font review remain pending.

Validation: **516 full Flutter tests passed**, **7 new focused tests passed**, **53 isolated Firestore rules tests passed**, full analyzer **No issues found**. Logs: `phase1-full-tests.log`, `phase1-targeted-tests.log`, `phase1-analyze.log`, `test/security/phase1-rules-tests.log`. No new APK build/install, shared deployment, admin claim or production writes. Shared reporter registration remains dependent on the pending reviewed rules rollout. The [implementation plan](../product-flow-implementation-plan.md) records this checkpoint and subsequent route-assignment, passenger-flow and moderation work.

### Product flow: admin driver-route grants, 2026-10-16

Added independent route assignment/removal in Admin -> Drivers, with reason, route labels and audited commits. Bus editor/service preassignment requires current approval plus that exact route grant. Driver dashboard verifies server-acknowledged grant and route, filters physical buses by exact route ID and disposes the old workspace on withdrawal/account/route changes. No assigned route or no eligible bus produces an explicit waiting/empty state; the hard-coded default vehicle/route selection was removed.

Rules and production claim transactions enforce route scope for bus claims, conditions, GPS, trips and assistance actions. Claims atomically record a grant revision to invalidate concurrent admin route changes. Administrative route changes release stopped bus claims and transaction-check telemetry; active trips/broadcasts block those changes. Approval revocation withdraws route access as well; shared active-trip reconciliation remains separate. Updated local/sample fixture tools without running shared seed operations.

Validation: **523 Flutter tests passed**, **26 focused admin/route-gate tests passed**, **16 operator transaction callback tests passed**, **56 isolated rules tests passed**, full analyzer **No issues found**. Logs: `phase2-full-tests.log`, `phase2-targeted-tests.log`, `phase2-transaction-tests.log`, `phase2-analyze.log`, `test/security/phase2-rules-tests.log`. No new APK build/install, shared deployment, admin claim or production data changes. Existing drivers need reviewed route grants before rollout. Dated-run scheduling, exclusive operation locks and the five-minute start gate remain next; see the [implementation checkpoint](../product-flow-implementation-plan.md).

### Product flow: dated service runs, timing and operation locks, 2026-10-16

Added admin dated departures with Colombo service dates, UTC immutable timetable snapshots and one-off departure overrides that preserve overnight intervals. Fixed the user-confirmed start window at -5 through +30 minutes; late starts require a private driver/admin reason. The driver selects an admin-published run. A server-rule-enforced atomic transaction starts boarding, creates a trip keyed by run ID, acquires the private driver operation lock and acknowledges bus GPS. Actual departure is a separate linked server timestamp; starting no longer invents first-stop arrival/departure. Retries preserve one run/timeline. Next-stop confirmation requires departure, while boarding cancellation/final completion atomically close run/GPS and release the matching driver lock.

Rules reject early/expired/forged starts, incomplete linked writes, competing operations, active telemetry deletion and legacy-trip resurrection. Newly created undated trips are denied; existing legacy active operations need reviewed reconciliation/migration before rollout. Updated local/sample fixture scripts without executing shared seeds. Recurring calendar/template management and full admin handover/revocation reconciliation remain separate work.

Validation: **532 full Flutter tests passed**, **60 isolated rules tests passed**, analyzer **No issues found**. Exact boundary/Colombo rollover, late reason/privacy, transaction retry/rollback, lock release, duplicate start and competing-bus cases are covered; admin run UI passes at 320dp/200% text. Final boarding/time-label UI regressions: **7 passed**. Logs: `phase3-full-tests.log`, `phase3-analyze.log`, `phase3-ui-final-tests.log`, `test/security/phase3-rules-tests.log`. No shared deployment, admin claim, billing upgrade, seed execution or APK build/install. Native/background GPS and TalkBack validation remain pending. See [checkpoint 17](../product-flow-implementation-plan.md).

### Product flow: temporary search needs and timetable window, 2026-10-16

Search and Results now share an account-aware draft: temporary needs never write Settings, unedited fields follow updated defaults, explicit overrides survive default changes, Reset restores defaults and new searches start fresh. Account switching clears Search and invalidates the old Results session. Pending requirement/date/time dialogs cannot apply captured values after an account change.

Date/time/submission validation and independent Results/card checks constrain scheduled boarding opportunities to the rolling next 24 hours, inclusive. Destination arrival may fall later. Old explicit future selections are rejected; no-time daily timetable matching may roll to the next occurrence inside the same horizon. Existing evidence/lifecycle refresh updates eligibility. Empty bus streams no longer resurrect the initial bus list. New status messages have English/Sinhala/Tamil resources; fluent review is pending.

Validation: **538 full Flutter tests passed**, **39 focused tests passed**, **17 additional accessibility/evidence regressions passed**, analyzer **No issues found**. Logs: `phase4-search-full-tests.log`, `phase4-search-targeted-tests.log`, `phase4-search-regression-tests.log`, `phase4-search-analyze.log`. No shared backend/rules/data changes or APK build/install. This is the timetable/search-draft foundation: trusted-time/device-timezone independence, dated/active-run boarding search and the consolidated Bus Details/map/reports/optional-save flow remain pending. See [checkpoint 18](../product-flow-implementation-plan.md).

### Product flow: consolidated passenger Bus Details, 2026-10-16

Results and owner-scoped saved-entry reopening now use one Bus Details screen with the selected segment/times/needs, stop timeline, fare disclosure, capability/evidence widgets and optional assistance/report actions. Compact exact-bus/selected-stop community reports appear immediately above optional Save Trip. Opening details never saves or starts a journey; saving/removing stays on the same screen, reports acknowledgement failures and uses stable retry identity. Saved run identity survives serialization; old bookmarks without it remain static. Remote removal clears Saved status.

Live GPS requires a pinned matching dated run and matching trip/bus/driver/itinerary/planned departure, fresh acknowledged telemetry and a started operational state. Future/terminal runs and stale/cached/unrelated/error telemetry show no current marker. Silent expiry is tested. Maps show stop coordinates without inventing road geometry; missing coordinates/tiles retain a stop-list alternative and tile retry. Local rules validate saved run/bus/boarding-time links. Redundant catalogue rule reads were reduced without changing permission conditions after a late-start access-call-limit failure.

Validation: **545 full Flutter tests passed**, **37 focused passenger regressions passed**, **7 final details/bookmark tests passed**, **61 isolated rules tests passed**, analyzer **No issues found**. Logs: `phase5-details-full-final.log`, `phase5-details-targeted-final.log`, `phase5-details-final-widget-tests.log`, `phase5-details-analyze-clean.log`, `test/security/phase5-details-rules-final.log`. No shared deployment/data changes, billing changes or APK build/install. Trusted-time/Colombo dated and active boarding search, full saved-list/version/loop support, scoped report-query pagination, run-aware assistance, road ETA and complete localization remain pending; existing moderation thresholds are unchanged. See [checkpoint 19](../product-flow-implementation-plan.md).


### Product flow: trusted time and dated/active-run search, 2026-10-16

Search now uses an owner-only server-timestamp receipt advanced monotonically for up to five minutes, with conservative network uncertainty, expiry/resume verification and explicit offline/retry states. Asia/Colombo civil dates are separate from UTC transport timestamps throughout search/details/bookmark restoration. Physical bus results require actual published dated runs; active boarding eligibility requires matching driver/run/progress and fresh stationary GPS at a known recorded stop. Scheduled identity stays separate from the explicitly labelled boarding estimate. Moving/off-stop buses without supported geometry are excluded rather than assigned a guessed speed. Exact-run propagation, account guards and silent eligibility/GPS expiry are preserved.

Validation: **554 full Flutter tests**, **14 core/draft tests**, **16 final boundary/localization regressions**, **6 filter regressions**, **62 isolated rules tests**, analyzer **No issues found**. Logs: `phase6-search-full-verified.log`, `phase6-dated-core-tests.log`, `phase6-search-boundary-final.log`, `phase6-filter-regression.log`, `phase6-search-analyze-clean.log`, `test/security/phase6-search-rules-tests.log`. Index configuration is prepared locally and must be merged against deployed inventory before rollout. No shared deployment/data write, billing change or APK/native verification occurred. Road geometry/moving-bus ETA, full saved-list/loop/version support, assistance/handover and moderation remain follow-ups. See [checkpoint 20](../product-flow-implementation-plan.md).


### Product flow: My Location nearby boarding stops, 2026-10-16

Search My Location now obtains one foreground GPS fix and offers the nearest five valid catalogue stops by approximate straight-line distance. The rider explicitly chooses a boarding stop; destination/time/needs are retained and late results cannot cross account changes. Disabled/denied/blocked/timeout/poor-location states support settings, retry and manual selection. The sheet has English/Sinhala/Tamil wording and explains road-side/direction checks and the absence of a walking-route/time guarantee. No passenger location is saved or broadcast.

Validation: **23 focused tests passed**, including **7 new location/selection tests**; analyzer **No issues found**. Logs: `phase7-nearby-final-tests.log`, `phase7-nearby-analyze-final.log`. No full-suite rerun, production/backend deployment, APK install or physical GPS/permission verification. See [checkpoint 21](../product-flow-implementation-plan.md).


### Product flow: server-enforced same-issue report cooldown, 2026-10-16

Report creation now commits a matching private cooldown guard atomically. Rules enforce 300 seconds per author/target-type/target/category using server time; wording/condition changes, deletion and concurrent phones cannot bypass the guard. Different categories/targets remain immediately reportable. An acknowledged same-ID retry preserves the original guard, and a rejected write retains the outbox draft. Removed the incorrect production 15-minute whole-target preflight and added a localized five-minute policy notice. Existing author voting/recheck exclusion is preserved.

Validation: **564 full Flutter tests**, **65 isolated rules tests**, analyzer **No issues found**. Logs: `phase8-report-full-tests.log`, `test/security/phase8-report-rules-final.log`, `phase8-report-analyze-final.log`. No production deployment/data write or billing/APK change. Client/rules must roll out together; no old reports or moderation history were rewritten. Five-voter hiding/double penalties, automated rewards/strikes/bans/admin review remain the next backend slice; existing three-flag/ledger behavior is unchanged. See [checkpoint 22](../product-flow-implementation-plan.md).


### Product flow: local trusted moderation/reward v2 core, 2026-10-16

Implemented atomic v2 publication credits and per-user voting, fifth-False hide/-20/one strike, signed balances, one 72-hour restriction at strike five and pending permanent-ban review at ten. The user confirmed that votes earn no points; only authors receive +10. Original v1 reports/balances are not migrated and v1 reconciliation now rejects v2 reports. Rules deny direct v2 mutation; Sample state remains scoped. Durable notification/operation reconciliation intentions are not delivery or completed reconciliation.

Validation: **75 isolated emulator tests passed** (`test/security/phase9-moderation-final.log`), comprising 65 existing cases and 10 v2 race/idempotency/rollback/threshold/access cases. Server modules passed syntax checks. No Flutter code changed or new full Flutter/analyzer run was claimed. The Admin adapter is not hosted/runtime verified. This is a staged backend core: Flutter v2 integration, authenticated endpoints/hosting, hidden-report privacy queries, full account enforcement, appeals/admin decisions and migrations remain rollout gates. No deployment/production write/billing/APK change occurred. See [checkpoint 23](../product-flow-implementation-plan.md) and [server notes](../../server/moderation/README.md).


### Product flow: authenticated moderation endpoint adapters and Flutter transport, 2026-10-16

Added bearer-token/revocation-checked vote and own-status API handlers, an HTTP host adapter, strict scope/input/response limits and sanitized errors. Flutter now has a staged HTTPS-only authenticated transport with scoped typed receipts, signed balances, account-change guards and no direct-write fallback. Existing screens/router are not switched to v2 yet; publication/privacy/filter/account-enforcement migrations remain activation gates.

Validation: **576 full Flutter tests**, **12 focused client tests**, analyzer **No issues found**, **8 API/loopback tests**, **76 isolated rules/policy/API tests**, **11 final policy regressions**. Logs: `phase10-full-tests.log`, `phase10-client-tests.log`, `phase10-analyze-final.log`, `phase10-http-final.log`, `test/security/phase10-policy-api-tests.log`, `phase10-policy-final.log`. Auth verifier tests are injected, not live Admin/Auth verification. No hosted deployment, production writes, billing or APK/native changes. See [checkpoint 24](../product-flow-implementation-plan.md).


### Product flow: local/emulator v2 publication and voting activation, 2026-10-16

The user chose local activation first. Local-debug v2 reports now publish through one trusted transaction (report/cooldown/+10), Community/Details use authenticated private vote state and False reasons, v2 evidence hides at five and signed points display correctly. Normal builds preserve v1. Rules distinguish private hidden v2 reads/public filtered queries, reject direct v2 writes and enforce account-access restrictions on old sessions. The local account gate removes the operational workspace; a retryable local Admin worker cancels the matching suspended operation/GPS/assistance without fabricating completion. Actual demo Auth tokens/Admin transactions/worker were exercised.

Validation: **582 full Flutter tests**, **18 final focused tests**, **18 tests with local activation flags**, analyzer **No issues found**, **89 backend/security tests**, and successful actual local Auth/Admin/worker smoke. Logs: `phase11-full-verified.log`, `phase11-ui-verified.log`, `phase11-local-mode-tests.log`, `phase11-analyze-done.log`, `phase11-backend-verified.log`, `phase11-worker-smoke.log`. Local-only APK built, manifest-checked, installed and launched on emulator-5554 under `.validation`; startup logs were free of the inspected fatal/Flutter exceptions. Complete native manual/TalkBack/GPS acceptance remains unverified. No shared deployment/data/billing change. Appeals/permanent-ban decisions, migrations and production rollout remain pending. See [checkpoint 25](../product-flow-implementation-plan.md) and [local instructions](../local-validation.md).

### Product flow: local author appeals and admin report correction, 2026-10-16

Added private author dispute views/appeals, including access while suspended, and
a claim-authorized admin queue with vote evidence and audited uphold/overturn.
Overturn atomically restores the original deduction/one strike, keeps further
voting closed and recomputes community restrictions without removing independent
restrictions or restarting ended trips. Duplicate reviews are idempotent and
self-review is denied. Local-only admin provisioning preserves existing records.

Validation: **589 Flutter tests**, **7 new review UI/model tests**, **18 existing
moderation regressions**, analyzer **No issues found**, **95 isolated backend/rules
tests**, and successful actual local Auth/Admin/worker/appeal/overturn smoke.
Logs: `phase12-full-tests.log`, `phase12-reviews-ui-final.log`,
`phase12-existing-ui.log`, `phase12-analyze-verified.log`,
`phase12-backend-verified.log`, `phase12-worker-smoke-final.log`.
Local `.validation` APK built/manifest-checked/installed/launched; inspected startup
logs contained no fatal/unhandled Flutter error. No complete native/TalkBack
walkthrough or fluent translation review is claimed. No production deployment,
data/real-account changes or billing change. Mandatory permanent-ban decisions,
migrations and hosted rollout remain pending. See [checkpoint 26](../product-flow-implementation-plan.md).

### Product flow: local mandatory permanent-ban review, 2026-10-16

Added a claim-authorized admin queue, contributing-report links and reasoned
approve/reject decisions. Approval requires ten current strikes, no pending
appeals and a matching trusted moderation revision. Restrictions/audit/immutable
decision/outbox commit atomically; rejection adds no restriction. Duplicate
decisions are idempotent, stale/racing appeals fail, administrator targets and
self-review are protected. Later report corrections preserve independent
restrictions; genuinely new reports can start a new review cycle while prior
decisions remain immutable. Local Auth stays enabled for private appeal access.

Validation: **596 Flutter tests**, **32 focused tests including exact local-v2
flags**, clean analyzer, **105 isolated backend/rules tests**, and actual local
Auth/Admin smoke including explicit permanent approval and old-session denial.
An existing trip-start rule access-limit failure was fixed by checking occupancy
against the telemetry resource and prior driver state in the lock write; linked
atomic writes remain required and the new occupied-bus regression passes.
Logs: `phase13-full-tests.log`, `phase13-local-mode-tests.log`,
`phase13-analyze-verified.log`, `phase13-backend-complete.log`,
`phase13-auth-smoke-final.log`. The local `.validation` APK was built, checked,
installed and verified running after an emulator reconnect; startup logs had no
inspected fatal/unhandled Flutter error. Full native/TalkBack/fluent-language QA
remains unverified. No production data/permissions, billing or shared Auth changes.
See [checkpoint 27](../product-flow-implementation-plan.md) and
[local walkthrough](../local-validation.md#local-permanent-ban-reviews-2026-10-16).

### Product flow: local run-bound assistance, 2026-10-16

Bus Details/form/outbox now retain the selected dated run and segment. Trusted
endpoints resolve the authorized current driver, require matching active operation
state, and enforce ownership/roles/transitions. Driver inbox is run-scoped and
paginated; rider history is latest-first. The local worker expires ended/passed/
revoked/deadline requests and retargets matching handovers with renewed driver
acknowledgement and an audit. Old-driver reads/actions fail independently of the
worker. Direct v2 mutations/legacy-creation bypasses are denied locally. Cross-account
outbox publication is rejected. New strings cover three-language statuses/controls.

Validation: **605 full Flutter tests**, **41 assistance tests with local-v2 flags**,
clean analyzer, **112 isolated backend/rules tests**, successful actual local
Auth/Admin assistance/worker smoke and existing moderation/appeal/ban smoke.
Logs: `phase14-full-verified.log`, `phase14-local-mode-verified.log`,
`phase14-analyze-clean.log`, `phase14-backend-complete.log`,
`phase14-auth-smoke-complete.log`, `phase14-moderation-smoke.log`.
The separate `.validation` APK was built/checked/installed and verified running
after an initial activity wait timeout; inspected startup logs had no fatal/
unhandled Flutter error. No full manual native/TalkBack/background acceptance is
claimed. Full active-trip administrative handover and actual push delivery remain;
in-app availability is explicit, with no fabricated background delivery status.
No production data/rules/permissions, real assignments/claims or billing changed.
See [checkpoint 28](../product-flow-implementation-plan.md) and
[local walkthrough](../local-validation.md#local-run-bound-boarding-assistance-2026-10-16).

### 2026-10-16: local active-trip admin handover

Added an existing-theme admin Active trips workflow and trusted transactional
handover of dated run/trip/bus/driver locks, with stable IDs, expected versions,
reason/audit and paused GPS. Replacement drivers explicitly resume with fresh
GPS; old-driver writes are rejected immediately. Assistance follows current
authority and resets acceptance through bounded, version-aware reconciliation.
Multiple transfers before worker processing cannot retain an obsolete acceptance.
Approval withdrawal now requires transferring/ending an active operation first.

Validation: 611 full Flutter tests, 39 final focused local-v2 tests, 120 isolated
backend/rules tests and clean analyzer; actual local admin/driver/rider token
smoke passed through the real API/worker. See plan checkpoint 29 and local
walkthrough for exact logs, APK checks and remaining native/provider work.
No production Firebase data/rules/permissions, real assignments or billing changed.

### 2026-10-16: local notification delivery preparation

Added a private authenticated device registry, bounded leased delivery/retry
pipeline and notification-open authorization checks. Device generations protect
shared-account rebinding and stale invalid-token/removal results. A local-only
provider records explicitly simulated receipts; the inactive FCM adapter uses
generic localized text and opaque event IDs. Neither simulation nor provider
acceptance changes assistance acknowledgement. Flutter has staged transport
contracts; Firebase Messaging/native callbacks, OS permissions and navigation
are not wired or activated.

Validation: 615 full Flutter tests, 27 focused local-v2 tests, 130 isolated
backend/rules/provider tests, clean analyzer and a passed actual-token local
worker simulation (`phase16-auth-smoke.log`). Plan checkpoint 30 and the local
notification walkthrough distinguish this from real background phone delivery.
No FCM credentials/provider/token, APK build/install, production state or billing
was changed. A dedicated test project and native/device acceptance remain open.

### 2026-10-16: staged Android notification lifecycle/navigation

Added official Messaging plugin with disabled auto-init, native assistance channel,
opt-in/permission/token/locale/logout lifecycle, foreground and opened-message
handlers and server-authorized driver request navigation. Account changes clear
private details; stale hints never authorize acceptance. Activation remains closed
without a reviewed dedicated test project/host. Current local APK does not obtain
an FCM token or receive background push.

Validation: 629 full Flutter tests, 26 local-v2 focused tests, 20 final notification/
profile checks, clean analyzer, explicit activation-denial check and 13 provider/
API tests. Native plugin/channel APK compile succeeded. See checkpoint 31 and
local walkthrough for manifest/install evidence and remaining real-device scope.
No production state, credentials/provider, real token/account or billing changed.

### 2026-10-16: fare mode safety and reviewed lookup foundation

User deferred actual push/device tests. Normal fare displays now stay unavailable
without reviewed tariff/stage mapping; the prototype calculation is confined to
explicit synthetic debug modes with Sample labels. Shared fare/disclosure widgets
have en/si/ta resources and hide historic prototype amounts in normal mode.
Added immutable directed fare-matrix/table/mapping contracts with exact pattern/
class/occurrences, integer minor units and Colombo boarding-date applicability.
Missing or conflicting data fails closed; no guessed stage arithmetic is used.

Validation: 639 full Flutter tests, 23 focused local-v2 fare tests, clean analyzer
and successful local APK build. See plan checkpoint 32/local walkthrough for logs.
No official fare/source mapping was imported or verified; trusted admin ingestion,
live quote/saved-version integration and ETA work remain. No shared data/rules,
production deployment, billing or FCM activation changed.

### Plan checkpoint 33: reviewed fare publication and quote integration

Admin JSON import/review publishes immutable, audited vehicle-scoped fare bundles;
archival replaces editing/deletion. Results and consolidated Bus Details show exact
directed-matrix cents/source/versions from acknowledged publications. Optional saved
trips retain the quote snapshot; current details revalidate and show changes.
Rules reject forged amount/version/segment snapshots and unauthorized publication.
Synthetic and normal fare inputs remain separate. See fare policy and plan
checkpoint 33 for schema limitations and remaining operational data review.

Validation: 648 Flutter tests, 39 local-v2 focused tests, 132 backend/rules tests,
actual local admin/rider-token publication/save/archive smoke and clean analyzer.
Local APK built. No official tariff import, shared deployment, billing or FCM
activation occurred; ETA geometry and real push/device validation remain separate.

### Plan checkpoint 34: reviewed road path and moving-run ETA baseline

Added audited admin geometry import/review/withdrawal, Firestore-compatible point
maps, current route/station transaction guards and isolated publication permissions.
The consolidated passenger flow uses exact-run fresh GPS projection restricted to
the recorded road leg. Results estimates boarding; Details shares the model and
draws only the selected reviewed road path. Wrong/stale/off-route/ambiguous inputs
fail closed. Future runs have no live ETA. Labels are localized and explicitly
low confidence; the range is heuristic, not measured accuracy.

No actual operating trace, traffic data or historical ETA model was imported.
Multi-fix motion/accuracy/sequence validation, measured errors, physical GPS and
native accessibility review remain pending. Real push testing stays deferred.
No shared deployment, billing or production account/data change occurred. See
plan checkpoint 34 and `docs/route-geometry-eta.md` for limits and validation logs.

### Plan checkpoint 35: opt-in local ETA measurement and replay

Added a Local Test-only Details diagnostic action, per-account bounded local
forecast ledger, separate timetable/geometry summaries and JSON export/replay.
Matching uses acknowledged driver-reported stop timestamps; this is explicitly
not independent physical arrival ground truth or production accuracy evidence.
Pending/cancelled/invalid/corrected records cannot become zero-error successes.
The tool freezes forecasts, balances repeated observations by run/stop/lead bucket,
and measures median/nearest-rank P90 absolute errors with sample/run counts.
Normal builds remain inactive and no operational/backend data is written.

Validation: 673 full Flutter tests, 41 focused local-v2 tests, 30 focused
persistence/diagnostic/replay regressions and clean analyzer. Local APK built.
Fixed an existing midnight-sensitive search test fixture without changing the
navigation assertion. See plan checkpoint 35, `docs/eta-evaluation.md` and local
validation notes. No production rollout, rule changes, billing or FCM activation.

### Plan checkpoint 36: Saved Trips pagination and owner-safe reopening

Home now exposes all saved records, including past/closed legacy bookmarks, in
twenty-row server-acknowledged pages. Next/Previous, retry, refresh and remove retain
owner/cursor boundaries and avoid whole-history listeners. Home's latest-open
preview is bounded separately. All-record ordering uses stable IDs rather than
claiming hash IDs establish chronology. Exact saved documents reopen consolidated
Details with their selection intact; account changes invalidate stale private views.
Removal acknowledgement affects only owner bookmarks. Existing owner rules remain
unchanged, and prepared query indexes are not deployed. See checkpoint 36 and
`docs/saved-trips.md`; native/fluent review and production rollout remain pending.

### Plan checkpoint 37: scoped report preview and paginated public evidence

Details now queries only its selected physical bus and segment stops with bounded
preview limits. The compact section remains above Save Trip and discloses partial
coverage. View all opens exact bus/stop live pages with bounded records, stable
cursor navigation, loading/error/retry and hidden-report removal. Existing report
details/votes and public freshness checks are reused. Prepared indexes remain local;
rules permissions, points and ban policy are unchanged. See checkpoint 37 and
`docs/segment-reports.md` for coverage/order limits and validation. Real FCM tests,
native/fluent review and production rollout remain separate.
