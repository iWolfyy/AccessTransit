# Audit fix progress

Updated: 2026-10-14 (Asia/Colombo). Original findings remain in system-audit-2026-10-14.md as an audit snapshot.

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

F09: trusted operator enrolment and assignment policy, approved-operator UI and backend enforcement verification. Live deployment remains separate.

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
