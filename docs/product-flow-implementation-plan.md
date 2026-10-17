# AccessTransit: agreed flow and implementation plan

Prepared 2026-10-16, Asia/Colombo. Status: implementation started; the requirements below are the target behavior, not a deployment or completed-feature claim. See the implementation checkpoint at the end.

Workflow revision confirmed 2026-10-17: implement directly in the main application
against its existing real Firebase project. Do not build/install a separate Local
Test APK or generate intermediate APKs; build the main APK at final delivery.
Automated tests and isolated emulator checks remain verification tools, without
requiring a second installed application. Preserve real records; do not seed
fictional test data into the real catalogue or reset the database. Real Firestore
access and deploying the trusted moderation/Auth server are distinct operations;
backend hosting/billing configuration must be established before activating those
server-dependent features. Historical local checkpoints below remain evidence
of earlier work and do not override this workflow revision.

Latest development setup agreed 2026-10-17: main app on the Android emulator,
real Firebase Auth/Firestore, and trusted server code running on the development
computer. Defer hosted deployment and billing changes. The emulator reaches the
computer through `10.0.2.2`; permit that endpoint only in an explicit main-app
debug configuration, with HTTPS still required for release. This setup is now
implemented in checkpoint 44 with the real-project server on loopback port 8788
and `LOCAL_API=true` for the main debug app. The old demo launcher stays on port
8787 and its native APK flag remains retired. Do not redirect synthetic seed/
reset tooling to the real project. See checkpoint 44 for actual activation,
verification limits and the current remaining work.

Latest reward revision: v2 awards points only to report authors; True/False voters receive no points. Historical v1 balances require a reviewed migration.

Latest user revision: five distinct other users' false votes trigger automatic hiding/deduction; authors cannot vote True or False on their own reports; permanent bans require admin review. The passenger journey is Search -> Results -> Bus Details, with optional Save Trip on the details screen. These decisions supersede earlier four-vote and confirmation/live-screen proposals.

Additional confirmed requirements: show relevant bus/stop reports as a compact, theme-matched section immediately above Save Trip; search only within the next rolling 24 hours; initialize search needs from saved accessibility preferences, with search edits remaining temporary and Settings changes updating account-wide defaults.

This plan follows the user's latest requirements. Keep the existing app theme and layouts; integrate new controls using the existing components. Preserve the historical system audit. Sample/Test data remains visibly identified and isolated from real operating records.

## 1. Current implementation and gaps

Reviewed the current working tree, including uncommitted admin work. Production permissions/data were not queried or changed for this plan. Previous recorded validation is 509 Flutter tests, 52 isolated rules tests and a clean analyzer; those checks predate this plan and do not validate the proposed features.

- **Registration and routing:** passenger, contributor and operator choices exist in `lib/screens/auth/register_screen.dart`. Local `firestore.rules` currently allows profile creation only for passenger/operator: contributor registration has a client/rules mismatch. Operator approval gate exists. Login/splash route administrators using a trusted custom claim, operators to their dashboard, and other users to passenger flows.
- **Admin:** `lib/screens/admin/` and `lib/services/admin_service.dart` implement catalogue CRUD, driver review, bus-level assignment, basic profile name/phone editing and an activity log. Route-level driver permissions, account suspension/Auth management, fare management and moderation appeals are missing. Recorded live activation is still pending the admin claim/rules rollout; do not describe this dashboard as verified in production.
- **Driver access:** approved drivers can claim an unassigned physical bus. Bus ownership is enforced, but authorization is not restricted to an administrator-assigned route. Approval withdrawal currently leaves active shared trips for manual reconciliation.
- **Trips:** `lib/services/trip_service.dart` already supports acknowledged starts, final-stop completion and ordered overnight schedules. There is no authoritative scheduled-departure-minus-five-minutes start gate. Client-supplied departure times are unsuitable as authorization evidence.
- **Accessibility:** bus and station capabilities exist separately from dated condition reports; admin editors already expose several capability fields. Preserve Unknown and evidence freshness. Expand only fields supported by data and rider needs.
- **Reports:** publication/outbox and transactional community votes exist. `checkRateLimit` and the submission UI currently use 15 minutes per user/target; this is not the requested server-enforced five-minute same-issue rule. Later rechecks have a separate 30-minute policy.
- **Rewards/moderation:** `docs/rewards.md` and `test/security/reward-ledger.mjs` give eligible report authors 10 points and unique confirmers 5. Processing is an administrator-run reconciliation script. Three flags hide a report and reverse credits. There is no automatic double penalty, strike counter or 72-hour/permanent ban policy.
- **Assistance:** correct bus/stop targeting, acknowledged submission, driver/passenger status flows and retry handling already exist. Add trip/driver handover guarantees and background notification delivery; do not assume a Firestore write means the driver saw or accepted it.
- **Maps:** the live journey already contains `flutter_map`, OpenStreetMap tiles and bus/stop markers; driver GPS is implemented. This needs reliability, background/device and route-geometry work, not a replacement map feature.
- **ETA:** `lib/services/eta_service.dart` uses straight-line distance/current speed, a 20 km/h fallback, and name-based coordinate fallbacks. Separate delay logic applies trip/timetable offsets. This is not road-distance/traffic-aware prediction.
- **Fare:** `lib/logic/journey_fare.dart` uses `35 + minutes * 2.2 + intermediateStops * 4`, rounded and capped at LKR 40–450. Disclosures and selected-segment persistence exist; authoritative tariff integration does not.
- **Languages:** English strings are widespread; the reviewed app has no complete Sinhala/Tamil/English localization setup.
- **Passenger navigation:** the current implementation has separate route details, journey confirmation, live journey and resume screens. The new requirement consolidates the passenger journey into Bus Details with optional saving; reuse their evidence/map/persistence logic without keeping those extra required navigation steps.

## 2. Roles and navigation

Use one authentication system and login screen, with three role-specific dashboard destinations. Separate login forms are unnecessary unless explicitly wanted; selecting a login tab must never grant a role.

1. **Passenger/reporter:** immediately usable after registration, with no administrator approval. Both can plan journeys and report conditions. Preserve `passenger`/`contributor` as onboarding preferences with equivalent application privileges, allowing both in the backend schema. Reporting must not require changing accounts.
2. **Driver:** registration creates a pending application. Show approval status, reason when rejected, and a way to correct/resubmit details. Pending/rejected/revoked drivers cannot claim buses, start trips, publish GPS or handle assistance. Approval is separate from route assignment.
3. **Admin:** trusted custom claim only, never public registration or a writable role field. Administrator account is the previously specified existing account. Keep privileged actions audited and deny them when fresh authorization cannot be established.

Suspension is an independent account state, not another role. Route every role through the same account-status check. Client gates improve UX; backend checks enforce all privileged mutations, including requests from old app versions.

### Passenger flow: Search -> Results -> Bus Details

This is the complete required passenger journey. There is no separate mandatory journey confirmation, passenger Start Journey action or separate Live Journey destination. Reporting, assistance and profile remain optional existing features, not extra required steps in this flow.

1. **Search:** choose boarding location, destination, time and date within the next rolling 24 hours. Automatically prefill accessibility needs from the signed-in account's saved preferences; allow temporary edits for this search only. Preserve all selected values when navigating forward/back. Match the correct ordered boarding/alighting stop occurrences and service date/direction.
2. **Results:** show matching buses/service runs within that same 24-hour window, with route/vehicle identity, the selected segment's scheduled times, applicable fare/source and requirement/evidence summary. Separate scheduled services from genuinely active runs. Selecting a result opens its Bus Details directly; selection alone does not create a saved journey or change account preferences.
3. **Bus Details:** show the chosen bus/route/direction, selected date/time/needs, boarding and alighting stops, all intermediate stops in order, departure/arrival/duration, applicable fare, and scoped bus/endpoint accessibility evidence. Highlight the passenger's selected segment rather than substituting full-route endpoints/times/fares. Place relevant community reports near the bottom, immediately above Save Trip, using normal theme styling rather than a prominent warning/banner treatment.
4. **Optional Save Trip:** place the action at the bottom of Bus Details. It bookmarks this bus/service run and selected segment; it does not start tracking, book a seat or require another confirmation screen. The user can inspect everything and leave without saving.

Map and current-position behavior on that same Bus Details screen:

- **Scheduled/not started, including future dates:** show a static route/selected-segment map when reviewed geometry exists, with boarding/intermediate/alighting stops and timetable information. Do not show a live GPS layer, current-bus marker, current-stop label or live ETA. Timetable time passing does not establish a trip start. Never reuse today's GPS for tomorrow's departure of the same vehicle.
- **Started active run with fresh matching GPS:** show its live bus marker/current position, the selected route segment, remaining stops and live estimates. Identify a current stop only when actual stop progress/proximity supports it; while between stops, say so and show the next stop. Match run ID as well as bus ID and service date.
- **Started run with missing/stale GPS:** retain the route map and show location unavailable or last update time; do not present an old marker/current-stop label as current or animate guessed motion. Recorded stop progress may be shown explicitly as last recorded progress.
- **Completed/cancelled run:** show its terminal state, timetable/recorded times and static route details; remove live GPS/current-position treatment. Another run using the same bus must not replace the selected run.
- Subscribe to the selected run so a scheduled service can become active while details are open without navigation to another screen. Missing route geometry/coordinates produces an honest map-unavailable state with the stop timeline still usable.

Saved trips use the existing saved-items entry and reopen this same Bus Details screen. Save bus/route/run identity, service date, stop occurrence IDs, selected needs/time and fare/schedule version. Saving is owner-scoped, acknowledged and idempotent; show Saved/Remove saved trip and an error/retry state when necessary. Reopening refreshes operational status and clearly explains schedule changes/cancellations while preserving the original selection. Old saved journeys/deep links migrate to the consolidated details view. No additional independent bus-favourites workflow is required for this request.

### Search horizon: next 24 hours only

- Use a rolling window from the current trusted time through `now + 24 hours`, inclusive of the upper boundary, not the remainder of today and not 24 hours after an arbitrarily selected future date. For example, searching at 14:00 permits times up to 14:00 tomorrow.
- Constrain both date/time pickers and the actual search/query validation. A deep link, old saved search or manually constructed request cannot expand the window. The selected time narrows results inside this window; it never moves the upper limit beyond `now + 24 hours`.
- Apply the window to the passenger's boarding opportunity at the selected boarding stop, using the scheduled boarding time for upcoming runs and trustworthy current progress/ETA for active runs. A bus that started earlier may still be offered if it has not passed that stop and its supported boarding estimate falls within the window; do not discard all active trips based on the route-origin departure alone. Unknown active-run boarding eligibility must not be presented as a confirmed match.
- Exclude completed/cancelled runs and runs already past the selected boarding occurrence. Arrival at the destination can be later than the search window; the 24-hour restriction concerns boarding, not maximum journey duration.
- Refresh eligibility on resume, rerun and when the displayed window becomes outdated. Explain unavailable/past selections instead of silently changing the user's selected date/time. Use Asia/Colombo service dates and retain overnight rollover handling.
- Saved trips remain viewable as records even after they fall outside the current search window; they are not injected back into fresh search results as upcoming services.

### Saved preferences versus temporary search needs

- Account-scoped Settings are the source of app-wide accessibility defaults. On a new search, copy the latest saved values into the draft; do not share a mutable settings object with the search form. Wait for the correct account's preferences to load, using explicit guest defaults when signed out.
- Search fields are editable. Store edits only in the current search session and pass its effective needs through Results, Bus Details and optional saved-trip context. Results must actually use those effective needs for matching; they must not silently reread the old settings values instead.
- Searching, choosing a result and saving a trip never persist the temporary overrides to accessibility Settings. Back navigation within the same search retains them. A genuinely new/reset search starts with the saved defaults again; offer Use saved preferences to discard temporary changes explicitly.
- Saving changes in Settings updates the account-wide defaults and refreshes screens that depend on those defaults. For an open search, fields still following defaults update; explicitly overridden fields remain temporary for that session until reset. Recompute affected results instead of leaving badges and filtering inconsistent.
- Saved trips preserve the needs used for their original selection. Updated global defaults do not silently rewrite that snapshot; on reopen, compare current default needs where relevant and make any mismatch clear without auto-selecting a different bus.
- Keep preference persistence separate from search-draft state and saved-trip snapshots. Account switches clear the draft and load the new account's defaults, preventing cross-account leakage. Global preference changes happen only through the explicit Settings save flow.

### Relevant reports above Save Trip

- Show published, publicly visible reports for the exact selected physical bus and relevant stops in the selected boarding-to-alighting segment, including its endpoints. Label each report's target clearly. Match stable IDs/direction/platform where available, not route-name similarity. Exclude another bus's reports and stops outside that selected segment.
- Use a small Community reports section with the existing typography, spacing, neutral cards/dividers and compact condition/freshness labels. Do not add oversized headings, loud alert banners or duplicate prominent evidence panels. Keep report text readable and the target/status explicit; relevance includes useful conditions even if the user has no matching accessibility preference selected.
- Show a concise issue/condition summary, bus/stop name, observation age and current report status. Allow opening/expanding details for full description, attribution, photos and eligible non-author voting. With many reports, show a short preview and View all relevant reports; do not let a long report feed overwhelm Bus Details or obscure the optional Save Trip action.
- Reuse the existing evidence freshness policy. Do not present stale positives or resolved faults as current problems; unresolved old barriers retain their recheck label. A report from the current day is not proof of conditions at a future departure. Never invent verified accessibility from the report count.
- Hidden/disputed reports must disappear here when the fifth eligible False vote commits, including from visible cached state. Keep author/admin review access separate. Pending local drafts are not public bus/stop evidence.
- With no relevant reports, use a compact No recent reports message rather than an oversized empty-state panel or a claim of safety. Distinguish loading, unavailable/offline and empty results. If offline evidence is displayed, retain its source/age and label it as saved data.
- The final lower-page order is the compact relevant-reports section followed by the optional Save Trip control. Optional report/assistance actions fit the existing layout without changing the required Search -> Results -> Bus Details flow.

## 3. Admin workflows and catalogue

### User and driver management

- Search/filter people by role, approval, account state and assigned route; view profile, contribution ledger and moderation history.
- Review driver identity/licence/operating authority using minimal necessary private evidence; never publish documents or approval notes with passenger data.
- Approve, reject with reason, revoke, and assign an approved driver to a route/direction. Approval alone does not assign a route.
- Suspend/restore accounts with a reason and audit event; provide an appeal/review queue. Auth disabling, token revocation and account deletion need a trusted server endpoint, not an Admin SDK key in Flutter.
- Review permanent-ban cases raised at ten counted strikes. Inspect contributing reports/votes, appeals and prior corrections; only an explicit admin decision with reason can impose a permanent ban. Record approve/reject decisions and reviewer/time.
- Use a reviewed account-deletion workflow that preserves or anonymizes necessary trip/report audit references; avoid cascading deletion of shared history.
- Protect the last administrator from accidental removal. No arbitrary silent points editing: corrections use explicit ledger adjustment events.

### Catalogue CRUD

- **Stops:** multilingual names, precise reviewed coordinates, direction/platform identifiers where needed, capabilities, active/archive state, data source/review timestamp.
- **Routes:** public route number, stable direction/pattern ID, ordered stop occurrences, route geometry when available, source and service calendar. A stop can occur twice on a loop: use occurrence IDs rather than a map keyed solely by station ID.
- **Buses:** real registration, route/pattern membership, service class, capabilities, operational status and data provenance. A published timetable is not a physical vehicle and cannot broadcast GPS or receive vehicle-specific equipment reports.
- **Schedules:** separate vehicle identity from recurring departures. Store service calendar, departure, ordered stop offsets, route direction and effective dates. Create explicit service runs for a given service date.
- Archive referenced buses/routes/stops; allow physical deletion only when dependency-safe. Existing journey history retains its selected names/times/version.

### Driver-to-route assignment

Proposed initial policy: one active assigned route pattern/direction per driver; allow multiple route grants later without changing the authorization model. This is a proposed default, not an additional user requirement.

Drivers see only their assigned route's eligible physical buses in the operation selector. Within that route, a driver may select an available bus, or admin may preassign it. A transaction verifies approval, account state, active route grant, bus route, service run and exclusive driver/bus operation lock. Only one driver can operate a bus, and a driver cannot run two buses simultaneously.

Passengers may still read the public route/bus catalogue. Hiding another route from a driver's operation selector is not a confidentiality rule; backend authorization must reject operating that route even with a guessed ID.

Route reassignment/revocation during an active trip uses an explicit admin handover/stop workflow: reconcile the trip, stop old driver's write authority/broadcast, release locks and retarget or expire assistance. Do not silently abandon an in-progress trip or mark it completed.

## 4. Accessibility ownership and observations

Admin maintains **capability**: ramp equipped, low floor, wheelchair space, stop step-free access, elevator presence and other reviewed fields. Keep each as Yes/No/Unknown. Do not infer that an installed ramp/elevator is working.

Reports record **condition**: working, faulty, blocked, crowded, assistance denied, etc., scoped to the specific bus or stop, observation time, author and optional photo. Drivers may submit their own attributed checks for the bus they operate; these do not override community evidence automatically.

Reuse the existing evidence/freshness components. Display capability, current observation, freshness and conflicting/unresolved reports separately. Expired positive checks become Unknown; equipment presence must not pass an operational accessibility filter by itself. Admin resolution requires a reason/evidence and preserves the report audit trail.

## 5. Scheduled trip start and GPS

Store timestamps in UTC and calculate service days/departures in `Asia/Colombo`, independent of phone timezone. Each run contains an admin-controlled planned departure and immutable schedule version.

The authoritative start condition is `serverNow >= plannedDepartureAt - 5 minutes`, plus approved driver, allowed route, eligible bus, valid GPS and unused active run. Example: a 10:00 run is blocked at 09:54:59 and allowed from 09:55:00. A UI countdown mirrors this condition; changing the phone clock or posting directly cannot bypass it.

Confirmed late-start policy: permit the selected service run to start until **30 minutes after planned departure**, inclusive, with a reason required after departure time. After that, admin must cancel the previous scheduled run and publish a rescheduled replacement. The start window is therefore planned departure minus 5 minutes through plus 30 minutes. Do not quietly start tomorrow's run or reuse an already completed/cancelled run. The reason is private to its driver and admin, separate from public timetable data.

Starting a trip should not automatically mark the first stop as departed. Use `ready/boarding -> in_progress -> completed/cancelled`; show actual departure only once movement or an explicit departure action establishes it. The user permits starting up to five minutes early; any separate prohibition on physically departing early needs a distinct operator policy.

Atomically create the trip, acquire bus/driver locks and publish initial acknowledged telemetry. Repeated start requests return the same run. Final stop/cancel/handover releases locks and ends broadcasting. Offline startup remains unconfirmed and cannot claim shared operation.

GPS plan:

- Reuse existing location service and map. Validate coordinate range, accuracy, age, route plausibility and active trip identity; store server receipt time as well as device observation time/sequence.
- Begin with adaptive publication around every 10–15 seconds while moving and slower stationary heartbeats; tune with measured latency/battery/usage. Subscribe only to relevant buses/trips.
- Example load budget: four buses broadcasting every 15 seconds for eight hours produce 7,680 location writes/day before other writes. Listener reads grow with concurrent passengers. This is a workload estimate, not a cost quotation.
- On Bus Details, show a fresh bus marker/current position only for the selected started run with matching fresh telemetry. Future/not-started runs retain only the static route/segment map and timetable, with no current stop or GPS layer. Include last-updated/stale treatment and an accessible stop-list alternative; animate only between valid observations.
- Broadcast only during an explicitly active trip. Verify Android foreground-service/background-location behavior on physical devices, with persistent notification and appropriate permission explanations. Test screen lock, process kill, denied GPS, reconnect and route deviation.
- Public telemetry exposes the operating vehicle, not driver's email/private profile or off-duty location. Define minimal retention for any historical GPS used for ETA training.

For an initial limited deployment, retain the existing OSM-based map. Public tiles require visible attribution, app identification, caching and no bulk/offline prefetch; availability is best-effort. Make the provider configurable. Free map data/software does not promise unlimited hosted tiles or zero Firebase usage cost. [OSMF tile policy](https://operations.osmfoundation.org/policies/tiles/).

## 6. Boarding assistance

Request targets a reviewed bus + service run + boarding/alighting stop occurrence. Server resolves the current driver from assignment, never from a client-provided UID.

Offer assistance as an optional action from Bus Details; a passenger does not need to save a trip, confirm a journey or open a separate live screen first. Keep the request/status view outside the required Search -> Results -> Bus Details path.

Use `queued on device -> submitted -> accepted/declined -> completed`, with cancellation and expiry terminal states. Preserve existing acknowledged request IDs across retries. The assigned driver gets an in-app request stream; optional push is an additional wake-up/notification channel, not the authoritative state.

Show passenger whether the request is merely submitted or accepted. If no driver/run is assigned, show that explicitly and avoid promising direct delivery. Driver handover retargets pending requests under an audited transaction, revokes the old driver's access and informs the rider. Avoid stale push messages granting access: always reload authorization/state when opened. Only rider, assigned driver and authorized administrator can read assistance details.

## 7. Reports, points, false flags and bans

### Five-minute submission rule

No per-account daily/lifetime report cap. Define the same issue as `(author UID, target type, target ID, stable issue/category ID)`. Wording, photo, severity or working/broken toggles do not bypass the cooldown for that issue. A different issue at the same stop, or the same issue at another stop, can be submitted immediately.

Accept at most one publication for that key in a rolling 300 seconds using server time and a transaction over the cooldown and report ID. At exactly 300 seconds the next report is eligible. Duplicate retries of the same request return its previous result instead of charging the cooldown or awarding points again. Concurrent phones cannot both publish for the same key.

An offline draft is not a published report. Validate cooldown/account status when reconnecting, preserve observation time separately, and show the retry time on rejection. Existing finite local storage/photo bounds remain: unlimited contributions does not mean unlimited phone storage. Prevent deletion/recreation of a report from bypassing the cooldown.

Keep the existing 30-minute repeat-confirmation policy for eligible non-author users separate unless changed explicitly. A new report and a recheck on an existing report are different actions; explain this in the UI. The author cannot use a recheck to self-confirm their report or earn a self-vote reward.

### Reward policy v2: author-only points

Use the existing **10 points per eligible acknowledged report** as the default. No reward for local-only, failed, duplicate or sample publications. Store the awarded value and policy version on its immutable ledger event so future changes do not rewrite past penalties.

The revised threshold is **5 distinct eligible non-author users voting False**. An author cannot mark their own report **True or False**: hide/disable both controls for the author and reject both operations at the backend, including direct requests, stale sessions and recheck paths. Other eligible users may mark True or False; each UID has at most one current vote per report and cannot count on both sides. True votes do not subtract from the five-False threshold. Require a reason for False and exclude suspended accounts. Unique accounts are not proof of independent people or factual truth; review suspected coordinated voting.

Requested automatic behavior: when the fifth valid False vote commits, mark the report disputed/hidden, subtract **2 × the originally awarded points**, and add exactly one false-report strike for its author. Apply these together transactionally without waiting for admin review. Example: `+10 publication -20 penalty = -10 net`. Do not additionally reverse the initial +10 and charge -20, which would over-penalize to -20 net. Remove hidden reports from public community/evidence queries and invalidate visible cached copies; retain them privately for the author, admin review and appeal rather than deleting the evidence.

Use a signed contribution balance so a zero balance does not erase the required penalty. Redemption remains unsupported. The current nonnegative-ledger assumptions and badges need migration. Confirmed revision: True/False voters earn no points in v2; only the report author receives the publication award. Preserve historical v1 confirmation credits through the reviewed migration rather than silently recalculating them.

Call the result **community-disputed**, not objectively proven false. The user has approved mandatory admin review before any permanent ban. This does not delay the automatic five-vote report hide/deduction or the existing five-strike temporary suspension policy. Provide the author with the hide reason, point deduction and appeal action; preserve an audited correction path.

### Suspension thresholds

- At five counted false-report strikes: temporary suspension for **72 hours**, from authoritative decision time.
- At ten counted false-report strikes: create a **pending permanent-ban review** case for admin. Do not automatically permanently suspend or disable Auth. Admin reviews the current evidence/appeals and records a decision and reason; only an approved decision applies permanent suspension, which then takes priority over temporary suspension.
- Proposed default: strikes are cumulative per account until an admin overturns them. The five-strike suspension occurs once on crossing that threshold, not on every retry or every subsequent read. Strikes six through nine do not silently restart 72 hours; ten opens admin review. These cumulative/repeat-suspension details remain proposed defaults.
- A pending permanent-ban review does not silently extend an existing temporary ban or create an indefinite suspension. Existing valid restrictions continue until their own expiry. Persist one open review case per account, append new evidence without duplicate cases, and recheck the current strike count/admin authority transactionally before a decision. An overturned strike or rejected review cannot be ignored by replaying an old threshold event.
- At exact temporary expiry the account may resume without the phone deciding eligibility. A newly submitted appeal does not itself cancel a suspension.
- A ban blocks authenticated operational actions/reporting/voting/assistance and trip starts; provide an explanatory state, expiry/reason and appeal access. Public route reading may remain available. A suspended active driver triggers safe server trip/broadcast reconciliation; it must not leave an authoritative bus running indefinitely.
- Use a server-owned account-access document for immediate enforcement. Permanent Auth disable/token revocation is an additional action; old tokens and open sessions must also fail privileged backend checks. Do not depend solely on scheduled Auth re-enabling after temporary bans.
- Repeated flags/trigger deliveries count one report once. After a threshold decision, users cannot toggle votes to repeatedly debit/credit. An admin reversal restores the correct ledger amount/strike exactly once and recomputes derived suspension while retaining independent manual restrictions.

### Server operation

Implement these rules behind trusted transactional operations such as `publishReport`, `voteReport`, `reviewReport`, `reviewPermanentBan`, `startTrip`, `reviewDriver` and `assignDriverRoute`. `voteReport` checks non-authorship for both True and False. Clients cannot write reward balances, strikes, deadlines, approvals or permanent-ban decisions. All current direct-write paths must either migrate or be denied by matching security rules; old app versions must not bypass new policy.

Recommended hosted implementation: Firebase callable functions plus narrow Firestore rules, audit events and an idempotent notification outbox. Firebase production Functions deployment requires Blaze/billing; local emulation does not. This plan does not authorize a billing upgrade. If zero new billing is mandatory, run the same trusted service on an existing managed server; a developer laptop/manual batch is only a supervised test fallback and cannot promise continuous automatic enforcement. [Firebase deployment requirements](https://firebase.google.com/docs/functions/get-started).

Firestore event handlers may be retried and delivered out of order. Use immutable operation IDs, transactionally persisted outcomes, current-state rechecks and explicit idempotency instead of assuming one invocation. [Firebase trigger behavior](https://firebase.google.com/docs/functions/firestore-events).

## 8. Fare and ETA accuracy

### Fare: tariff lookup, not a more elaborate guess

Import an administrator-reviewed official tariff with source, effective dates, route applicability, direction, service class and fare-stage/stop mapping. NTC publishes fare-stage and route/service documents; its indexed fare page shows a March 2026 revision, but direct page retrieval failed during this planning check. Do not assume that indexed revision is the latest applicable tariff. Recheck the source and applicable authority before importing. [NTC fare publications](https://www.ntc.gov.lk/Bus_info/bus_fares.php).

For a selected segment: resolve board/alight stop occurrences -> validated fare-stage mapping -> applicable route/class/date tariff -> listed amount or tariff-defined calculation. Stop count and kilometres do not establish fare-stage count. Support explicit route fare matrices where that is how the authority publishes fares; do not assume universal subtraction of stage indices.

Store integer minor units, currency, tariff version, effective date and source with the selected segment. Share that one quote across Results and Bus Details; persist it only if Save Trip is chosen and restore it when saved details reopen. Identify later tariff changes explicitly. There is no extra confirmation screen. Fare does not rise when GPS indicates a delay. Apply concessions only when eligibility and an authoritative concession rule exist. Without the required mapping, show Fare unavailable; keep the prototype formula only in clearly marked Sample/Test mode.

### ETA: road progress plus measured journey times

Consolidate current competing ETA paths into one result contract: arrival time/range, source, observation timestamp, confidence and reason.

1. Match fresh, plausible GPS to the correct ordered route geometry/stop occurrence. Use along-route remaining distance, not geodesic distance or partial city-name matches.
2. Estimate the remaining current segment using smoothed recent motion and observed segment travel times. Do not substitute 20 km/h when stopped and call it reliable.
3. Add expected later-segment travel time and stop dwell time. Initialize from reviewed timetable intervals; improve with actual completed trips grouped by route direction/time of day when sufficient samples exist.
4. Update from actual stop arrivals/departures. Avoid double-counting delays already reflected by observed progress.
5. Downgrade to timetable-only/low-confidence when GPS is stale, off-route or implausible. Show Unknown where no usable basis exists. Display an uncertainty range rather than false precision.
6. Record prediction vs actual arrival. Measure median and 90th-percentile absolute error separately for live and timetable estimates. Set release targets using collected route data; do not claim an unmeasured accuracy percentage.

No paid traffic API is required for this baseline. Genuine real-time traffic awareness needs a source; an open-source routing engine alone does not provide traffic. Route geometry also does not establish a wheelchair-safe pedestrian path.

## 9. Sinhala, Tamil and English

Introduce localization foundations in the first implementation phase and localize each new feature as it is built. Use Flutter localization generation and `en`, `si`, `ta` ARB resources with typed parameters/plurals. [Flutter internationalization](https://docs.flutter.dev/ui/internationalization).

- Language chooser before login and in settings; account locale with a guest/device default, reload safely on account switch.
- Translate all three dashboards, registration, errors, validation, empty states, permission explanations, notifications, report categories, assistance options, fare/ETA wording and accessibility labels.
- Localize database catalogue names separately from UI strings. Preserve original names and fall back visibly to a reviewed available name, rather than inventing translations.
- Use stable backend enums/error codes, translating only at presentation. User-authored descriptions remain original text with an optional language label.
- Validate Sinhala/Tamil glyph coverage, wrapping, line height, date/time/currency, 200% text, small screens and TalkBack. Human reviewers fluent in each language must check terminology and accessibility instructions.

## 10. Data and authorization changes

Names below are proposed, not existing deployed collections:

- `users`: private profile, role/onboarding preference, preferred locale; server-owned contribution summary. Existing account-scoped accessibility preference storage remains the authority for defaults; search-session overrides are separate transient state, not profile/settings updates.
- `operator_access`: approval state, private review metadata and version.
- `driver_route_assignments`: driver, route pattern/direction, validity, active flag and reviewer. Driver may read their own grant, never create it.
- `routes`, `stations`, `buses`: reviewed catalogue, capabilities, provenance and archive state. Keep minimal public fields apart from private driver/admin information.
- `service_schedules`, `service_runs`: recurring template vs dated run, immutable planned times and schedule version.
- `trips`, `live_locations`, `operation_locks`: actual execution, current bus GPS, exclusive bus/driver state.
- `journeys` (existing passenger persistence, adapted as saved trips): owner-scoped optional bookmark of bus/run, service date, selected stop occurrences, needs/time and schedule/fare snapshot. Reading Bus Details does not create one; this record is separate from the driver's operational `trips`.
- `boarding_requests`: rider, run, bus, stop occurrence, authorized driver, status/version and expiry.
- `reports`, per-report `votes`, `report_cooldowns`: scoped observations, unique voters and authoritative next eligible publication time. Per-voter documents avoid growing unbounded UID arrays.
- `reward_events`, contribution summaries, `moderation_decisions`, `permanent_ban_reviews`, `account_access`, `appeals`: immutable credits/debits, strike decisions, mandatory admin review outcomes and effective access state. A pending review is not a permanent ban.
- `fare_tables`/`fare_mappings`: versioned tariff applicability and reviewed stop-stage mappings.
- `admin_audit`, `notification_outbox`: attributable changes and retryable notification intentions.

Define required indexes with query design. Paginate admin users/reports; avoid permanent listeners over whole collections. Deny client writes to trusted state and protect private review/vote/account data. Sample/Test mirrors applicable rules but has independent balances, sanctions, assignments and notifications; sample actions must never disable shared Auth accounts or alter normal access.

## 11. Screen inventory and UI scope

Keep the existing app theme. Reuse the current cards, spacing, typography, navigation and evidence widgets; this is a workflow extension, not a global redesign.

- **Shared authentication:** existing splash/onboarding, login, registration, forgot/reset password and preferences; add language selection and driver application/status handling. Add one shared suspended-account/appeal state.
- **Passenger/reporter dashboard:** required journey path is Search -> Results -> consolidated Bus Details. Search has a rolling 24-hour limit and editable needs prefilled from Settings, with session-only overrides. Embed the selected segment's evidence, static/live map as appropriate, stop timeline and fare/ETA; place compact relevant bus/stop reports immediately above the bottom Save Trip action. Saved trips reopen Bus Details. Reuse useful logic from existing confirmation/live/resume screens, retire their separate required navigation steps and migrate old entry points. Keep community reporting, outbox, assistance, profile and contributions as optional features; add dispute/appeal status and ledger debit history. Existing unsupported membership redemption stays disabled.
- **Driver dashboard:** existing operational dashboard, extended with approved-route bus selection, dated service runs/start countdown, live trip/stop progression, assistance inbox/detail, equipment checks, application status and profile/language controls. These can be tabs/sheets within the existing dashboard rather than many new top-level screens.
- **Admin dashboard:** existing Overview, Buses, Routes, Stops, Users, Driver review and Activity; extend editors and add route assignments, schedules/service runs, account moderation/appeals, mandatory permanent-ban review, fare tables/stage mappings and trip handover/reconciliation. Search, pagination, loading, denied, stale/offline, empty and failed-save states belong to each management view.

## 12. Implementation order and completion gates

1. **Policy/schema foundation:** confirm the proposed defaults below; introduce shared enums, migration versions, locale resources, server operation contracts and authorization tests. Fix contributor registration mismatch. Gate: all registration paths have consistent client/backend policy and cannot self-promote.
2. **Admin and route assignments:** extend existing CRUD with service patterns/schedules, route grants, account states and safe driver handover. Gate: approved driver sees their assigned route's buses; direct wrong-route starts/claims fail; concurrent claims have one winner.
3. **Trip timing, GPS and consolidated passenger flow:** explicit service runs, server five-minute rule, run/driver/bus locks, overnight handling, truthful start/departure, reliable end/revocation. Wire Search -> Results -> Bus Details with a rolling 24-hour boarding window, saved-default preference initialization and isolated temporary search edits. Migrate live/evidence components into details, place scoped reports immediately above optional Save Trip and propagate explicit Settings changes to app-wide defaults. Gate: boundary/clock-tampering/retry/race tests pass; active runs show matching live data, future runs show no GPS/current stop, unrelated reports are excluded, search edits never change Settings, and saved selections reopen the same details without a confirmation screen.
4. **Reports, rewards and moderation:** five-minute same-issue lock, author excluded from both vote types, automatic ledger, five-False-voter threshold, double penalty, strike policy, temporary bans, mandatory admin permanent-ban review and appeals. Gate: simultaneous fifth votes/retries produce one debit/strike; ten strikes create a review case, never an automatic permanent ban; admin decisions and expiry/restoration work.
5. **Assistance integration:** bind requests to run/current driver, foreground stream, push delivery outbox and handover/expiry. Gate: correct driver receives request; passenger sees actual acceptance; another driver cannot read/act.
6. **Fare and ETA:** review/import tariff-stage mappings; add geometry and unified ETA; validate against known fares and recorded journeys. Gate: no unsupported official fare or fabricated live estimate, consistent quote across navigation/resume.
7. **Complete multilingual/accessibility QA:** finish translation backlog across existing screens and all roles; fluent-review, TalkBack, 200% font, offline/error tests. Gate: no untranslated operational/error strings and no inaccessible critical action.
8. **Migration and rollout:** dry-run schema/ledger migration with backups; isolated emulators and two-account/two-device exercises; exact deployment diff, cost/limits and rollback prepared before shared rollout. Gate: actual deployed rules/backend/version and admin account access verified, with runtime logs and truthful evidence.

Do not reset the database again to introduce this flow. Preserve UIDs, legitimate reports and saved journeys. Grandfather old reward totals only through a reviewed baseline; do not retroactively ban users under a newly introduced flag threshold. Use a policy effective timestamp and migration records. Published timetables lacking a reviewed real vehicle remain unassignable until an administrator supplies that data.

## 13. Minimum acceptance scenarios

- Passenger and contributor register and enter the shared dashboard without admin review; pending driver cannot operate; custom profile edits cannot create admin access.
- Approved driver with no route sees an actionable waiting-for-assignment state. Wrong-route bus IDs fail at backend; route revocation races safely with start.
- 10:00 departure: 09:54:59 denied, 09:55 accepted; midnight service dates and a manipulated phone clock cannot bypass policy. Repeated start and two-driver start races create one active operation.
- The same issue at 299 seconds is denied and at 300 accepted; different issues are allowed; concurrent sessions, changing text and deleting the prior report cannot bypass the cooldown.
- False-vote counts 0–4 do not trigger the requested penalty; the fifth distinct eligible other user's vote hides the report and applies one deduction/strike. The author's True and False controls are unavailable and both direct backend requests are rejected; duplicate votes fail. True votes do not cancel the threshold. Retried/concurrent transactions award +10 and charge -20 only once, including zero/negative balances; hidden evidence disappears from public lists and caches but remains reviewable by author/admin.
- Fifth strike suspends for exactly 72 hours; old sessions are rejected. The tenth opens one permanent-ban review case without auto-banning or extending the temporary ban. Non-admin decisions fail. Admin approval with a reason permanently suspends; rejection/appeal corrections and stale review decisions reconcile without duplicate penalties or replaying a rejected case.
- Search preserves boarding/destination, needs, date and time through Results into the selected segment's Bus Details. No selection or screen opening saves a journey. There is no required confirmation/live screen; the optional bottom Save Trip is acknowledged/idempotent and a saved trip reopens the same details with current run status.
- Search accepts a boarding time exactly at now + 24 hours and rejects one second beyond it; an arbitrary future search date cannot shift the window. Midnight rollover, resume, deep links, past/cancelled runs, destination arrivals beyond the window, and an already-started bus still approaching the selected boarding stop are covered.
- New search prefills the correct account's saved needs. Editing them changes matching/results/details only for that session; Settings values stay unchanged even after Search or Save Trip. Back navigation retains edits, a new/reset search restores defaults, Settings save updates default-dependent screens, explicit draft overrides stay scoped, and account switching clears them.
- Bus Details shows only visible reports matching the selected bus and relevant segment stops, immediately above Save Trip in compact theme-matched styling. Another bus/out-of-segment stop cannot leak into this section. Five-False hiding removes a visible report; loading/offline/no-report states are truthful, and a long list expands without dominating the page.
- Future/not-started runs show only a static segment map/timetable and no live GPS/current stop, even if another run of the same bus is broadcasting. A selected run starting while details are open enables live display only with matching fresh GPS. Stale/missing/ended telemetry never claims current position; ordered segment stops/times/fare remain correct for both directions, loops and overnight services.
- GPS stops/stales on trip end/revocation, remains truthful offline, and does not reveal off-duty tracking. No false map movement after data deletion.
- Assistance reaches the assigned driver and acceptance reaches the rider; cancellation, offline timeout, driver handover, denied push permission and expired runs are covered.
- Official fare fixtures cover short/long segments, direction/class/effective-date changes and unknown mappings. ETA covers stopped buses, bends/loops, missed stops, old GPS and insufficient historical samples.
- Sinhala/Tamil/English pass text scaling, date/time, error, notification and screen-reader checks. Shared-device account switches do not inherit private needs, role or language incorrectly.
- Sample actions cannot alter normal users' rewards, bans, approvals or notifications. Backend failure never appears as saved/accepted/started success.

## 14. Confirmed revisions and remaining decisions

Confirmed user revisions: authors cannot vote True or False on their own report; five distinct other users' False votes automatically hide it and deduct twice its awarded points; a permanent ban requires admin review. Retain five strikes -> 72-hour temporary suspension, with ten strikes -> permanent-ban review rather than automatic permanent suspension. Passenger path is Search -> Results -> Bus Details with optional bottom Save Trip; active matching runs may show live GPS/current position, while future/not-started runs show neither. Saved trips reopen that same details screen.

Also confirmed: relevant bus/stop reports appear unobtrusively immediately above Save Trip; search is restricted to the next rolling 24 hours; saved accessibility preferences prefill Search, search edits apply only to that temporary search, and only explicit Settings changes update app-wide defaults. The boarding-time interpretation keeps an already-started bus eligible when it can still serve the selected stop within the window.

Recommended remaining defaults: +10 report points and -20 penalty for that award; cumulative strikes; one 72-hour suspension on crossing five; no extra suspension solely while permanent-ban review is pending; shared passenger/reporter privileges; one active route grant per driver; one login with three dashboard destinations.

Firebase Functions is the future hosted deployment choice (2026-10-17); the
latest decision defers deployment and uses a localhost trusted server during
development against real Auth/Firestore. A
read-only billing check found no linked billing account and billing disabled for
the existing project; Cloud Functions API is also disabled. No upgrade, account
link, API enablement or deployment has been performed. Billing setup and a
reviewed Functions rollout remain required for eventual hosted deployment.
The development setup instead requires the scoped localhost connection,
trusted server authentication and coherent real-project rules/migration before
shared v2 activation. Other outstanding decisions/data include verified tariff mappings,
physical bus ownership and human Sinhala/Tamil translation reviewers. These do
not prevent main-app source implementation and automated verification. Mandatory
admin review, the five-False-vote threshold and the 30-minute reason-required
late-start limit are settled requirements, not open questions.

The original planning work made no application source or live Firebase changes. The prior automatic approval rejection for shared admin rules remains a separate rollout issue; this document does not imply that deployment occurred.

## 15. Implementation checkpoint: registration and localization foundation

Implemented locally on 2026-10-16:

- Root and generated Sample/Test profile rules accept `contributor` alongside passenger/operator while keeping admin registration and self-granted approval forbidden. Reporter tests cover immediate report/assistance access and denied bus operation/privilege escalation.
- Registration rejects an admin role before calling Firebase Auth. The reporter label now reads Reporter, and the driver description explains approval instead of promising immediate broadcasting.
- Added Flutter localization generation, English/Sinhala/Tamil resources, Material localization delegates, named greeting placeholders and an English fallback for isolated screen hosts.
- Login and Profile expose the language selector. Local language choices are scoped by account, with separate guest and Sample/Test storage. Auth changes reload the correct account. A delayed save cannot change another account's language; rejected saves retain the old selection and show an error.
- Initial localized strings cover the new language controls, login greeting/email/sign-in, registration role labels/descriptions and account-ready/approval messages. Existing untranslated screens remain English until their feature/localization pass. Sinhala/Tamil wording still requires fluent human review; account locale is local-device storage, not cross-device profile synchronization.

Validation: **516 Flutter tests passed** (`phase1-full-tests.log`), including **7 new focused tests** (`phase1-targeted-tests.log`); **53 isolated Firestore rules tests passed** (`test/security/phase1-rules-tests.log`, project `demo-phase1-foundation`, port 8088); full analyzer **No issues found** (`phase1-analyze.log`). Widget coverage loads all three Material locales and exercises the selector at 320dp/200% text, including a failed save. Existing map tests emit mocked HTTP tile failures; the Flutter suite still completed successfully. No native TalkBack/font review or new APK build/install was performed.

No shared rules deployment, admin claim, billing upgrade or production data change occurred. Reporter registration on the shared backend still needs the reviewed local rules deployed. Route assignments progressed in the next checkpoint below; new moderation rules/ban decisions, consolidated passenger flow, 24-hour search, temporary search preferences, official fares and improved ETA remain later implementation work.

## 16. Implementation checkpoint: admin driver-route grants

Implemented locally on 2026-10-16:

- Admin Drivers view shows the assigned route and supports assigning/removing one route with a reason. Approval and route assignment remain independent. Bus editor offers only approved drivers with the selected route grant; service validation checks it again inside the audited commit.
- `driver_route_assignments/<UID>` stores the active route grant in the current normal/Sample/Test scope. Drivers can privately read their grant but cannot create, remove or change its route/active state. Passenger/public catalogue reads remain unchanged.
- Driver dashboard requires server-acknowledged approval, route grant and available referenced route. Missing/stale/revoked authorization closes the operational workspace. Route/account changes dispose old subscriptions; physical buses are filtered by exact route ID and published timetable records are excluded. A route with no buses has an explicit empty state and no operational controls. Existing fabricated default bus/route selection was removed.
- Claim transaction verifies approval, route grant, route and bus. Atomic bus/grant claim revision updates make retries idempotent and invalidate concurrent admin changes. Backend rules enforce route scope for claims, equipment, GPS, trips and assistance actions, even for direct requests.
- Admin route changes release stopped bus claims in the same transaction, guard live records against a simultaneous start, and reject active trip/broadcast changes. Approval revocation also deactivates the route grant. Active shared trip reconciliation on approval revocation remains a known separate lifecycle task; this step does not fabricate completion.
- Local and shared Sample/Test seed/verification scripts were updated for scoped route grants and syntax-checked. They were not executed against shared Firebase. Existing driver accounts need reviewed grants in each intended scope before these rules are deployed; approval or an old bus claim is not a fallback permission.

Validation: **523 full Flutter tests passed** (`phase2-full-tests.log`), **26 focused admin/gate tests passed** (`phase2-targeted-tests.log`), **16 production-transaction callback tests passed** (`phase2-transaction-tests.log`), **56 isolated rules tests passed** (`test/security/phase2-rules-tests.log`, `demo-phase2-routes`, port 8088), full analyzer **No issues found** (`phase2-analyze.log`). Tests cover route UI at normal/200%/high-contrast settings, authorization withdrawal/account/resume, exact-route bus filtering, wrong-route direct requests and concurrent administrative changes. These are automated tests, not a native/live admin walkthrough.

No shared deployment, admin claim, catalogue/approval/assignment write, billing change or APK build/install occurred in this step. Exclusive driver/service-run locks, dated service schedules, the five-minute start boundary, full handover/reconciliation and the consolidated passenger screen remain the next implementation phase. This checkpoint completes the route-permission slice, not every scheduling/account-control feature listed in phase 2 of the target plan.

## 17. Implementation checkpoint: dated departures and operational start window

Implemented locally on 2026-10-16:

- Admin -> Buses -> Dated departures publishes the reviewed physical bus itinerary for a Colombo date, with an optional one-off departure time. Stop intervals/overnight rollover are retained and the bus timetable is unchanged. The fixed latest start is departure +30 minutes. Cancelling a scheduled run and publishing a replacement provides explicit rescheduling; active runs cannot be cancelled through this scheduling editor. Snapshot checks reject a simultaneous start while admin cancellation is committing.
- `service_runs` stores the dated bus/route, UTC planned departure/latest start, Colombo service date and immutable initial stop timings. This is a dated snapshot from the existing timetable; a full recurring service-calendar/template editor is not claimed here. Missing/estimated stop intervals and published-timetable records cannot become operational runs through the admin service. Administrators remain responsible for reviewing timetable provenance before publishing real runs.
- Driver selects a dated run; the UI exposes its Colombo start window and refreshes at clock boundaries. Production starts now use `ServiceRunService.startRun`. Firestore `request.time` independently enforces departure -5 minutes through +30 minutes, so a client clock or forged planned-departure field cannot grant early/expired access. Late starts require at least five reason characters, committed privately in `driver_trip_notes`; passengers cannot read those notes.
- Start atomically creates one trip under the run ID, transitions the run to boarding, acquires `operation_locks/<driver UID>` and acknowledges GPS. The driver lock prevents simultaneous operation of another bus, and existing active bus telemetry prevents another run on that bus. Retrying the same acknowledged run updates GPS without creating another trip or replacing the timeline. Current approval, route grant and bus ownership are rechecked.
- Starting a session records boarding with no actual departure or invented first-stop arrival. Record actual departure writes the server timestamp into both run and trip; retries preserve it. Next-stop confirmation is blocked until departure is recorded. Boarding cancellation and terminal completion atomically end the run, close broadcasting and release the matching lock; rejected writes retain shared operation state for retry.
- New undated trip creation is denied by rules. Existing legacy active records remain reconcilable under their owner/route permissions, but completed legacy records cannot be restarted. Drivers cannot delete active telemetry to bypass bus occupancy. The older `TripService.startTrip` adapter remains for injected/legacy compatibility tests; the production driver UI no longer calls it.
- Local and Sample/Test fixture scripts now describe dated runs and scoped locks. They were syntax-checked, not executed against shared Firebase. Existing active legacy operations must be reviewed/completed or migrated with locks before enabling the new policy; no fabricated live runs were created for normal transit.

Validation: **532 full Flutter tests passed** (`phase3-full-tests.log`), **60 isolated Firestore rules tests passed** (`test/security/phase3-rules-tests.log`, `demo-phase3-runs`, port 8088), full analyzer **No issues found** (`phase3-analyze.log`). Exact client-model boundary tests cover -5 and +30 minutes; server tests reject early/expired/clock-spoofed starts, absent late reasons, partial writes, duplicate starts and competing bus operations. Transaction tests cover retry, separate actual departure, cancellation/completion rollback and lock release. The admin editor publishes/cancels at 320dp and 200% text. After final boarding/time-label edits, **7 UI regressions passed** (`phase3-ui-final-tests.log`).

No shared deployment, admin claim, billing upgrade, fixture seed execution or APK build/install occurred. The timing gate uses existing Firestore security rules and transactions and does not require a new paid function for this slice. A native background-GPS/TalkBack walkthrough and shared rules/run provisioning remain unverified. Initial stop estimates remain timetable-based until the later ETA work; this checkpoint makes no road-traffic accuracy claim. Full admin handover/revocation reconciliation is still separate. Next implementation slice: the consolidated passenger Search -> Results -> Bus Details flow, rolling 24-hour search and temporary search preferences.

## 18. Implementation checkpoint: search drafts and timetable-window foundation

Implemented locally on 2026-10-16, as the first part of the passenger-flow slice:

- Added a search-session needs draft shared by Search and Results. Wheelchair/step-free edits and the Results requirement-review dialog never write Settings. Explicit overrides survive Settings changes; unedited fields follow updated saved defaults. Reset restores saved defaults, back navigation retains the session and a new Search creates a fresh draft.
- Account changes clear draft overrides, selected stops/date/time and invalidate the previous Results screen, including after switching back. An already-open Results requirements dialog cannot apply captured values to another account. Searching waits for preferences initialization.
- Date picking is limited to today/tomorrow, time selection and submission reject selections outside the rolling next 24 hours, and Results independently checks both the request and each scheduled boarding time. The upper boundary is inclusive; destination arrival can be later. Expired timetable opportunities roll to the next daily occurrence only when no explicit time was requested, and are still bounded by now +24 hours. Arbitrary future-date entry points cannot extend the window.
- Existing evidence refresh/lifecycle handling re-evaluates Results without a cloud event, and card selection rechecks expiry before navigating. An explicitly empty bus stream no longer falls back to an old nonempty catalogue. Selected-segment station context now includes intermediate stops for the forthcoming details/report integration.
- Added English/Sinhala/Tamil messages for the window, expired selection and account change. Existing theme/components are retained. Translations still require fluent review.

Validation: **538 full Flutter tests passed** (`phase4-search-full-tests.log`), **39 focused search/journey tests passed** (`phase4-search-targeted-tests.log`), **17 additional accessibility/evidence regressions passed** (`phase4-search-regression-tests.log`), full analyzer **No issues found** (`phase4-search-analyze.log`). Tests cover exact 24-hour bounds, midnight, arrival beyond the horizon, future-date rejection, unchanged Settings/storage, default updates versus overrides, new searches and account switching. Existing map test hosts emit mocked tile-request failures; the suite passed. Older tests that deliberately searched seven days ahead now use in-window timetable fixtures while retaining fare/evidence/filter assertions.

This checkpoint does **not** complete phase 3. Search still uses the existing daily timetable matcher and device clock/local calendar; authoritative clock/Asia-Colombo normalization independent of device timezone, dated-run search, passed-stop/active boarding eligibility and trustworthy live boarding estimates remain to be integrated. The consolidated Bus Details, run-matched static/live map, compact relevant reports above optional Save Trip, and saved-entry migration remain next. Existing confirmation/live navigation is retained until that integration, rather than claiming it has been retired. No Firestore rules/backend changes, deployment, production writes, APK build/install or native walkthrough occurred in this step.

## 19. Implementation checkpoint: consolidated passenger Bus Details

Implemented locally on 2026-10-16:

- Normal Results now opens `BusDetailsScreen` directly. It shows the selected boarding/alighting segment, intermediate stops, timetable departure/arrival/duration, selected needs, disclosed fare estimate and existing capability/evidence components using the existing theme. Opening or selecting a bus performs no bookmark write. There is no mandatory confirmation or passenger Start Journey action in this path.
- Relevant community reports appear as a compact section immediately above optional Save Trip. Exact physical bus and selected-segment stop IDs are used, including endpoints. The initial preview is three reports, with explicit expansion. Report details remain accessible. Observation age and recheck status use existing freshness logic; hidden/disputed/expired positives and unrelated targets are excluded. The new report reader requires acknowledged server data and shows loading/unavailable separately from an empty result, with retry. The later five-False-vote policy is not implemented by this display change: current moderation thresholds remain until phase 4.
- Details resolves a unique acknowledged dated run matching bus, route, ordered segment and both selected endpoint times, and pins that identity. An explicitly saved run must match that ID; another run of the same vehicle cannot replace it. Scheduled/not-started and terminal runs show no live marker or current-stop claim. Started runs require matching trip ID, service-run ID, bus, driver, itinerary and planned departure plus valid, acknowledged, broadcasting GPS aged 0–30 seconds. Cache/error, future-dated, stale and unrelated GPS are suppressed. The 30-second expiry refreshes without another remote event. Progress is labelled as itinerary information rather than a guessed current stop; no fabricated live ETA is introduced.
- The map shows available selected-stop coordinates and a qualifying current bus marker. No road geometry exists in the current schema, so it explicitly describes stop locations and draws no invented road route. Missing coordinates retain the stop-list alternative. Unavailable map tiles have a retry/stop-list fallback, provider attribution and the app user-agent. This does not establish wheelchair-safe walking paths or verify hosted-tile availability.
- Optional Save Trip uses a deterministic selection ID, acknowledged owner-scoped creation and removal, stable retry identity and explicit failure states. It stays on Details after saving. Run identity is serialized in `JourneyModel`/`JourneySelection`; local root/generated Sample/Test rules validate the saved run's physical bus and boarding time. Another account cannot remove it. A remote bookmark deletion clears the prior Saved state. Saving never changes accessibility Settings.
- Saved-entry reopening now loads the specific owner document and opens the same Bus Details with the original segment/times/needs. Existing bookmarks without run identity remain static; they never attach to an arbitrary current trip. Incomplete legacy selections retain the existing replan error. A saved-needs/defaults mismatch is disclosed. Legacy confirmation/live/details classes remain for compatibility/tests, but no normal Result or saved-entry caller opens them.
- Added English/Sinhala/Tamil core labels for Details, community reports, save/remove and optional actions. Operational/explanatory strings still have a translation backlog and need fluent review.

Validation: **545 full Flutter tests passed** (`phase5-details-full-final.log`); **37 focused passenger-flow regressions passed** (`phase5-details-targeted-final.log`); **7 final details/bookmark tests passed** (`phase5-details-final-widget-tests.log`); **61 isolated Firestore rules tests passed** (`test/security/phase5-details-rules-final.log`, `demo-phase5-details`, port 8088). Full analyzer: **No issues found** (`phase5-details-analyze-clean.log`). Coverage includes no automatic save/navigation, scoped/hidden reports, run/GPS mismatch and silent expiry, serialization, save/remove rejection and retry, remote removal, saved-entry migration and 320dp/200% text. A pre-existing late-start authorization test exposed redundant catalogue document reads reaching the rules access-call limit; `realCatalogue` now reads once with the same existence/provenance conditions, and the complete 61-test authorization suite passed. Tests used workspace temporary storage after the system temporary drive reported insufficient space. No personal files were removed.

Remaining phase-3 work: authoritative search clock, device-timezone-independent Colombo search dates, searching dated/active runs with supported boarding eligibility, reviewed geometry and live arrival estimates. The current Results matcher remains daily-timetable based; resolving a matching run on Details is not a claim that active-run search is complete. Full stop-occurrence/version snapshots for loops and schedule/fare changes, a paginated saved-bookmark list (the existing entry still surfaces the latest open bookmark), bounded target-scoped report queries, run-aware assistance/handover and complete localization remain follow-up work. No shared rules deployment, backend/data mutation, billing change, APK build/install or native/live-device verification occurred. Local rules must be reviewed/deployed before shared clients can save the new run-ID field.


## 20. Implementation checkpoint: trusted time and dated/active-run search

Implemented locally on 2026-10-16:

- Search obtains an owner-scoped Firestore server-timestamp receipt, rejects cached/pending or slow receipts (over five seconds), and advances it with a monotonic elapsed clock for at most five minutes. Results refresh the receipt on expiry/resume; failed verification closes search eligibility with an explicit retry state. The measured round trip conservatively narrows the rolling boarding window rather than extending it. This is a bounded-uncertainty time receipt, not an exact network-free clock. Search still requires signing in and connectivity.
- `search_clock/<UID>` accepts only that owner's server timestamp, has no listing permission, and cannot carry profile/role/reward fields. Normal and Sample/Test policies are isolated. The clock uses existing Firestore operations, with no new hosted function or billing upgrade. A probe uses a write and server read; repeated searches reuse a fresh receipt, and resume/expiry can require another probe. No shared probe was executed during implementation.
- Production search now interprets dates/times in Asia/Colombo and stores operational instants in UTC, independently of the device timezone. Pickers, Results, Details and saved-selection date restoration use the same conversion. Temporary search needs remain separate from Settings. Asynchronous clock/picker work checks account changes before applying or navigating.
- Physical vehicles require explicit administrator-published dated `service_runs`; their daily bus timetable is no longer promoted into an invented run. Multiple departures of one bus remain separate results with their exact run IDs. Terminal, incompatible and unstarted runs past their latest-start boundary are excluded. Published timetable catalogue records remain visibly unassigned planning information, with no operational run identity or live GPS.
- Eligibility uses the selected boarding opportunity within trusted now through now +24 hours, with an inclusive upper boundary and arrival permitted later. Origin departure may be earlier for an already-started run. Scheduled times remain the identity/snapshot; a supported active boarding estimate is stored and displayed separately. Results recheck eligibility on selection and refresh at boarding/start-window/GPS boundaries without needing another backend event.
- Active search requires matching run/trip/bus/current driver, ordered stop progress that has not passed boarding, fresh acknowledged GPS (at most 30 seconds), plausible coordinates and stationary motion at a known recorded stop within 100 metres. At boarding, the estimate is current availability; upstream, it explicitly uses the timetable interval from that GPS-observed stop. Early origin boarding waits until the planned departure for that interval. Cached, stale, future, moving/off-stop, missing or mismatched evidence cannot establish a confirmed boarding match. This conservative baseline does not estimate moving buses between stops or claim road/traffic accuracy; reviewed geometry and measured segment ETA remain future work.
- Results pass the exact run and trusted receipt into the consolidated Bus Details. Details renews time before showing current GPS and offers time retry when verification fails. Another run of the same vehicle cannot replace the selection. New clock/loading/retry messages have English/Sinhala/Tamil resources; wider operational wording and fluent translation review remain outstanding.
- Added the bus/status composite-index manifest and Firebase index configuration. Before any shared deployment, compare and merge it with the deployed index inventory; this local file is not evidence that existing production indexes were inventoried or that an index was deployed. Shared clock rules, dated-run provisioning and index readiness must be verified during rollout before shared search is claimed operational. Fixtures that synthesize daily runs are confined to automated test support.

Validation: **554 full Flutter tests passed** (`phase6-search-full-verified.log`), **14 focused core/draft tests passed** (`phase6-dated-core-tests.log`), **16 final boundary/localization regressions passed** (`phase6-search-boundary-final.log`), **6 filter regressions passed** (`phase6-filter-regression.log`), and **62 isolated Firestore rules tests passed** (`test/security/phase6-search-rules-tests.log`, project `demo-phase6-search`, port 8088). Full analyzer: **No issues found** (`phase6-search-analyze-clean.log`). Tests cover monotonic expiry/uncertainty, Colombo conversions, exact boarding boundaries, overnight schedules, dated-run identity, absence of fabricated physical runs, active stop progress, invalid/stale/cached GPS, silent GPS expiry and failed-clock retry. Rules tests reject forged/extra-field/cross-account/guest clock writes and private-clock listing in both scopes. The full suite exposed a filter-chip test tapping below the viewport after the new clock status; its scroll is now allowed to settle before the tap. Existing map test hosts still emit mocked HTTP tile failures; tests pass.

No shared rules/index deployment, production data changes, billing upgrade, APK build/install or native/device walkthrough occurred. The historical audit is preserved. Phase 3 still needs reviewed road geometry/moving-bus ETA and native GPS reliability checks; saved-list/loop/version completeness, scoped report pagination, run-aware assistance and safe admin handover remain separate follow-ups. This checkpoint does not change the old report moderation policy or complete the whole product plan. The next planned feature phase is reports/rewards/moderation, with its trusted-backend hosting choice still requiring a deployment decision.


## 21. Implementation checkpoint: My Location boarding-stop selection

Implemented locally on 2026-10-16 following the user's request:

- Search -> My Location now requests foreground location permission and one current GPS fix, then presents up to five catalogue stops ranked by approximate straight-line distance. Selection is explicit: the closest stop is not silently applied. Choosing a stop updates only the boarding field; destination, travel time and accessibility preferences remain unchanged. A result from a previous account cannot apply after an account change.
- The theme-matched, scrollable sheet explains that distance is not a walking route or travel time and asks the rider to check direction/road side. The current station schema does not establish route direction/platform or a safe pedestrian path; this feature does not infer either, calculate walk-to-stop time or guarantee that the rider can catch a departure.
- Missing/non-finite/out-of-range/zero-pair station coordinates are excluded. Invalid GPS coordinates or accuracy worse than 1,000 metres are rejected. The position request has a 15-second platform limit plus a 20-second retrieval timeout. Disabled GPS, denied/permanently denied permission, unavailable fixes and empty results have explicit states, retry/manual selection, and system settings actions where applicable. Returning from system settings requires retry. One location fix is used per attempt, with no continuous passenger tracking or location persistence/broadcast.
- Added English/Sinhala/Tamil sheet instructions, distance labels and location-error/actions. Human translation review and native permission/GPS verification remain pending. Existing manual station selection remains available, and no new package, backend rule or permission declaration was required.

Validation: **23 focused Flutter tests passed** (`phase7-nearby-final-tests.log`), including **7 new nearby-stop tests** for ranking/filtering, permission outcomes, weak accuracy, explicit choice, the actual Search My Location wiring, settings/retry at 320dp/200% text, and GPS failure recovery. Existing search preferences, draft and locale regressions also passed. Full analyzer: **No issues found** (`phase7-nearby-analyze-final.log`). The complete Flutter suite was not rerun for this scoped change; checkpoint 20's 554-test result predates it. No production writes/deployment, APK build/install or native-device walkthrough occurred.


## 22. Implementation checkpoint: authoritative same-issue report cooldown

Implemented locally on 2026-10-16 as the first reports/moderation slice:

- Production `createReport` atomically creates the published report and its scoped guard at `report_cooldowns/<UID>/<bus|station>/<target ID>/issues/<category ID>`. Stable existing category enums define the issue bucket; free text, photo, severity and positive/barrier condition do not create a new bucket. A different category or target can publish immediately, with no daily/lifetime publication counter.
- Firestore rules use authoritative `request.time`: another publication for that guard requires the previous publication to be at least 300 seconds old, inclusive. The guard links to a newly created matching report in the same commit, with server timestamps; a standalone report, standalone guard, forged time, private guard read by another user or guard deletion is denied. Root and generated Sample/Test scopes enforce independent guards. Owner deletion of the public report does not delete/reset the cooldown.
- The production transaction reads the guard to participate in contention retries. Retrying the same acknowledged report ID returns the original publication without touching its cooldown; changed owner/target/category/problem identity cannot reuse that ID. Competing publication transactions have one winner. Failed commits cannot appear publicly cached as saved and preserve the existing outbox retry flow.
- Removed the submission screen's 15-minute whole-target preflight, which incorrectly blocked different issues. Added an English/Sinhala/Tamil notice explaining the five-minute same-category policy. The older `checkRateLimit` repository helper remains for compatibility tests as a five-minute target-level advisory; the production submission flow no longer calls it and it is not an authorization control.
- After a permission denial, a server-only guard read plus a verified time receipt can identify an unexpired cooldown. The outbox then retains the draft and original retry ID with the UTC retry deadline. If that diagnostic cannot be verified, the original denial remains a generic access failure rather than being presented as a confirmed cooldown. Offline drafts still wait for publication acknowledgement; they do not consume the shared guard. Error/deadline copy still has the wider localization backlog, and the existing observation/publication timestamp model is not expanded by this slice.
- Rechecked existing author exclusion: report mutation logic, the report details controls, `ownVoteOnly` and `ownRecheck` already reject author True/False/self-recheck paths. This slice preserves those protections. The existing 30-minute non-author repeat-confirmation policy is unchanged.

Validation: **564 full Flutter tests passed** (`phase8-report-full-tests.log`), **65 isolated Firestore rules tests passed** (`test/security/phase8-report-rules-final.log`, `demo-phase8-reports`, port 8088), full analyzer **No issues found** (`phase8-report-analyze-final.log`). New callback tests exercise the real production publication transaction's paired writes, acknowledged retry, identity mismatch and rollback. Outbox coverage verifies that a cooldown failure retains its deadline/identity and a later retry publishes the same draft. Rules coverage includes different category/target, unchanged-key wording/condition changes, deletion/recreation, a 299-second-old guard rejection, a guard at least 300 seconds old acceptance, concurrency, standalone/old-client bypasses, forged guard writes and independent Sample/Test enforcement. Emulator request timing is real, so these are not a claim of sub-millisecond deterministic boundary measurement. Existing map hosts emit mocked tile HTTP errors; the suite passed.

No shared deployment, migration, production data write, billing upgrade or APK/native verification occurred. Rollout must pair these rules with the client transaction: old clients' direct new-report writes will be denied after deployment. Existing reports/UIDs are retained; no cooldown history or punishment was backfilled. This Firestore-rules/transaction slice requires no newly hosted paid function.

Phase 4 is not complete: the old three-flag hide/reward reconciliation policy remains in place. Five-False auto-hide with transactional double penalty/one strike, signed automatic ledger, account-access enforcement, 72-hour bans, mandatory permanent-ban review, appeals, immutable per-voter records and False reasons still require their coherent backend/client migration. Do not change the vote threshold alone while leaving the ledger and public evidence policy inconsistent. Trusted-backend hosting/billing choice and the proposed +5 confirmer reward policy remain decisions for that next slice. No claim of automatic points/bans is made here.


## 23. Implementation checkpoint: local moderation/reward v2 transaction core

Implemented locally on 2026-10-16. Confirmed user decision during this step: **only report authors earn points; True/False voters earn none**. This supersedes the earlier proposed +5 confirmer reward for v2. Historical v1 balances remain unchanged.

- Added `server/moderation/policy.mjs` with a trusted-store transaction contract and `admin_store.mjs` for an initialized Firebase Admin Firestore instance. No credentials, SDK initialization, public endpoint, trigger or deployment configuration was added. The API is server-only: any eventual adapter must derive the voter UID from verified authentication, never a request-body UID. A deployment/migration effective timestamp is required.
- An acknowledged eligible v2 report receives one immutable +10 publication event and a signed contribution summary. Report identity, reviewed physical catalogue provenance, effective timestamp and original award are checked. Nonzero unreviewed legacy balances fail migration checks rather than being reset/replayed. V1 reconciliation explicitly refuses v2 records, preventing accidental dual processing.
- Per-report/per-UID vote documents allow one current True or False vote. Authors are rejected from both; False requires a reason, missing/suspended accounts are rejected, retries are idempotent, and switching before closure moves only that voter's count. Neither vote awards points and True does not offset other False votes.
- The fifth distinct False vote atomically hides/locks the report, creates a -20 event for its frozen +10 award, counts one strike, updates the signed author balance and writes the decision/notification intention. The initial +10 is not separately reversed. Competing fifth voters and concurrent reports retry against shared state; after closure, a different new vote or a switch cannot repeatedly debit/reopen it. A zero balance still receives the full penalty.
- At strike five the core records exactly 72 hours of community suspension and a durable active-operation reconciliation intention. Strikes six through nine do not extend it. At ten it opens one pending permanent-ban review, without setting a permanent ban, disabling Auth or extending the temporary restriction. Existing pending review counts can be updated with new strikes. These are persisted states/outbox intentions, not a claim that all old app sessions or active driver operations are already reconciled.
- Normal and Sample/Test ledgers, decisions, access and notification intentions remain independently scoped; this module never disables shared Auth. Local root/generated rules prohibit legacy direct update/delete paths for v2 reports and keep the new private server-owned documents unwritable by clients. Existing v1 permissions/tests are retained.

Validation: **75 isolated emulator tests passed** (`test/security/phase9-moderation-final.log`, project `demo-phase9-moderation`, port 8088): 65 existing authorization/regression scenarios and 10 new v2 scenarios. Coverage includes concurrent fifth voters/reports, duplicate credits/votes, before-threshold behavior, no True rewards, full zero/negative balance penalties, self-votes/reasons, rollback, exact temporary-expiry eligibility, five/ten-strike behavior, v1 processor/migration refusal, Sample isolation and client-write denial. Production policy callbacks ran over real emulator transactions through a test store with create preconditions; the Admin SDK adapter was syntax-checked, not exercised against a hosted Admin endpoint. No Flutter source changed in this step, so the prior 564-test/analyzer result was not represented as a new run.

This is a **local trusted-core checkpoint, not activation of v2 in the app**. Flutter still uses v1 voting/evidence/reward behavior. Before shared v2 provisioning, implement verified server endpoints and atomic v2 publication/cooldown integration, migrate Flutter's threshold/signed balances and public/private report queries/cache handling, enforce account access on every operational/report/assistance path, and process trip reconciliation/notification outbox events. The legacy public report read policy is not a v2 hidden-report privacy solution. Audited appeals/reversals/admin permanent-ban decisions, baseline migration and rollback remain required. See `server/moderation/README.md` for the activation gates. No shared backend/rules deployment, production writes, billing change, data migration, APK build/install or native verification occurred.


## 24. Implementation checkpoint: authenticated endpoint adapters and Flutter transport

Implemented locally on 2026-10-16:

- Added a managed-host Web Request/Response API plus a Node HTTP adapter. POST vote and own-account-status endpoints accept Firebase bearer ID tokens. The trusted Admin Auth verifier is called with revocation checking enabled; the verified identity supplies the voter UID. Request-body UID/role/points/time and unknown fields are rejected. No public award/admin-review endpoint exists. These adapters do not initialize credentials, start a production server or select a billing/hosting platform.
- Normal scope is the default and Sample must be explicitly allowed by server configuration, with its own scoped profile/state. Browser origins are explicitly allowlisted, JSON bodies are capped at 4 KiB, duplicate Authorization headers are rejected by the Node adapter, private replies use no-store and errors are sanitized. Host configuration still supplies actual HTTPS, request deadlines/resource limits and initialized Admin SDK/project credentials.
- The policy exposes only the verified caller's account state, server time, effective temporary deadline and nullable signed v2 balance. Exact temporary expiry returns active using trusted server time; a pending permanent review creates no extra restriction. Duplicate vote receipts now retain confirmed counts so the client can validate retries.
- Added Flutter `ModerationClient`, typed vote receipts/status and stable error codes using existing Firebase Auth/HTTP dependencies. An explicit HTTPS `MODERATION_API_ORIGIN` is required; it defaults to disabled, accepts no URL credentials/query/path, and does not follow redirects with bearer tokens. Requests omit caller-controlled UIDs/points, use the build's scope, bound time/reply size, validate account/report/scope/policy/counts and ignore late results after account changes/disposal. Offline, malformed or lost replies cannot appear as acknowledged votes and never trigger direct-Firestore fallback.

Validation: **576 full Flutter tests passed** (`phase10-full-tests.log`), including **12 new client tests** (`phase10-client-tests.log`); full analyzer **No issues found** (`phase10-analyze-final.log`). **8 endpoint/real-loopback HTTP tests passed** (`phase10-http-final.log`). **76 isolated rules/policy/API transaction tests passed** (`test/security/phase10-policy-api-tests.log`, project `demo-phase10-api`, port 8088), followed by **11 focused final policy tests** (`phase10-policy-final.log`) covering real account-status expiry and authenticated fifth-vote/retry receipts. Auth tests stub the trusted verifier and assert revocation checking, UID binding and no mutation for rejected identities; they are not proof of live Firebase Auth configuration, cryptographic verification or real revocation delivery. The actual policy callbacks commit over emulator transactions. Node adapter tests use only synthetic tokens on loopback. Existing map hosts emit mocked tile failures; the Flutter suite passed.

**This completes the endpoint/transport slice, not v2 UI activation or full account enforcement.** Existing report screens/auth routing still use the legacy paths. Atomic v2 publication/cooldown, a per-voter UI read path/False reason form, all report evidence/cache/privacy query migration, signed balance presentation, account-status routing and checks on every old/new operational mutation remain required before configuring v2 for real users. Hosted Admin setup, operation/notification outbox processing, appeals/admin decisions and reviewed migration/rollback are also outstanding. No production endpoint, shared rules/data write, billing change, APK build/install or native authentication walkthrough occurred. See `server/moderation/README.md` for composition and release gates.


## 25. Implementation checkpoint: local/emulator v2 publication and voting UI activation

Implemented and exercised locally on 2026-10-16. The user explicitly selected **local/emulator UI activation first**. No shared/live activation is claimed.

- Added `publishReport` to the trusted policy/API: validated observation fields, authenticated author, reviewed physical target, server publication timestamp, independent observation timestamp, five-minute same-category guard, immutable +10 event and signed summary commit atomically. Input cannot assign UID/policy/points/privileges. A retry of an acknowledged ID returns the prior publication, different text/condition cannot bypass its guard, concurrent same-issue requests have one winner and cooldown rejection preserves the mobile draft with the server retry deadline. The per-request publication limit is 16 KiB to accommodate multilingual text; voting/status endpoints remain 4 KiB.
- `MODERATION_V2` activation is now explicitly restricted to `LOCAL_VALIDATION` debug mode, which already uses the hard-coded demo Auth/Firestore project and separate Android package. The local client has one fixed HTTP exception for `10.0.2.2:8787`; other HTTP origins remain forbidden. Normal/shared builds retain the v1 flow and disabled/staged HTTPS transport. New report submission in local v2 calls the backend and waits for a server-read publication receipt; it cannot silently fall back to direct report writes.
- Added authenticated per-voter status and connected v2 controls in Community cards and Report Details. False opens a reason form (5-1,000 characters), author controls are unavailable, guest/failed-status/retry/closed states are explicit, and success appears only after acknowledgement. Counts refresh with shared report changes. True and False earn no points. Report models preserve policy/observation metadata; v2 evidence stays usable through four False votes and hides at five, while v1 reports retain their historical threshold. The client-side legacy transaction planner rejects v2 mutations.
- Public report list queries now request active/resolved states. Local rules distinguish individual gets from list queries and deny hidden v2 reads to other users while retaining author/admin access. Client rules deny direct v2 writes/deletion. Feed cache copies of v2 reports are removed when shared reads become unavailable, and permission-denied individual subscriptions clear prior visible evidence. Details does not retain previously visible v2 evidence after a read error. Scoped relevant-report display uses the same policy-aware evidence threshold.
- Added server-owned account-access checks to client write rules, including stale authenticated sessions. The local app's shared account gate checks server status, account changes, resume and exact temporary expiry; a suspension or unverified access removes the authenticated workspace. Old subscription callbacks cannot apply to a different account. The Rewards screen reads the signed v2 contribution balance rather than clamping negative points or falling back to legacy totals; failed/uninitialized reads have an explicit refresh state. English/Sinhala/Tamil resources cover the new voting/account gate/points wording; human review and the wider translation backlog remain pending.
- Added an actual Admin SDK local host at `test/security/serve-local-moderation.mjs`, strictly limited to loopback demo Auth :9099/Firestore :8087/API :8787. No cloud credential, remote project override, billing change or public listener is required. A server-owned local configuration switch prevents old direct report creation while v2 is active. New tooling dependency/lock includes the official Firebase Admin SDK, whose real Auth-emulator verification and native Firestore transaction adapter were exercised.
- Added a local retry worker for suspended-operation reconciliation. It cancels the matching driver-owned trip/run, closes matching telemetry, releases the matching lock and schedules cancellation of old pending/acknowledged assistance. It does not fabricate trip completion. A newer lock is preserved with review-required status, retries are idempotent and oversized assistance batches are marked for review. The actual local worker was tested through the fifth-strike flow; this is not a hosted/push-delivery guarantee or general legacy-operation migration.

Validation:

- **582 full Flutter tests passed** (`phase11-full-verified.log`), then **18 final UI/client regressions passed** (`phase11-ui-verified.log`) after final count-refresh/account-callback guards. The same **18 tests passed with the exact local activation build flags** (`phase11-local-mode-tests.log`). Coverage includes False reason validation/acknowledgement, author exclusion, 320dp/200% text, failed-status retry, signed policy-aware evidence and workspace removal. Full analyzer **No issues found** (`phase11-analyze-done.log`). An earlier test-only stream-close wait was fixed for fake-async teardown; the focused suite completed.
- **89 backend/security tests passed** (`phase11-backend-verified.log`): existing permissions, atomic publication/cooldown/retries, five-vote policy, private hidden reports/list-query behavior, old-session write denial and operation reconciliation. A privacy test initially exposed a missing-document get exception being shared with list permission; get/list rules are now separate and the complete suite passed. Existing write permissions remain covered after adding account-access reads.
- **Actual local Admin/Auth end-to-end smoke passed** (`phase11-worker-smoke.log`): emulator ID tokens, authenticated API, publication/retry/cooldown, author denial, five voters, hide/-20/strike-five/72-hour state, real worker cancellation of trip/GPS/assistance and disabled-session rejection. These were synthetic uniquely named local accounts, not injected verifier identities or production credentials. `verify-local-moderation.mjs` is repeatable and refuses nonlocal emulator addresses.
- **Local debug APK built** with `LOCAL_VALIDATION=true` and `MODERATION_V2=true` (`phase11-local-build-final.log`). Manifest inspection confirmed `com.accesstransit.access_transit.validation`; installation succeeded and its activity launched on `emulator-5554`. The process remained running and the inspected startup log contained no Flutter/unhandled/fatal exception (`phase11-launch-final.log`). The normal application package was not installed/replaced. This is an install/startup check plus automated widget/backend coverage, **not a complete manual screen-by-screen Android walkthrough**, physical GPS/background-device verification or TalkBack review.

The local emulator/API are prepared for a walkthrough. `docs/local-validation.md` documents start/build commands and synthetic passenger/reader1-5 logins. The seed is a fixture tool, not migration; do not rerun it mid-walkthrough or against a shared project. Existing legitimate production UIDs/reports/saved journeys/rewards were not queried or rewritten.

Remaining before shared activation: production hosting/TLS/Admin configuration, reviewed schema/ledger baseline migration and indexes, explicit rollout/rollback, audited report appeals/corrections and mandatory permanent-ban review decisions, fuller driver handover/legacy-operation reconciliation, notification delivery, complete localization/native acceptance. The current local suspension screen has status/retry/sign-out, not a finished appeal flow. This checkpoint activates the requested v2 publication/voting slice **locally**; phase 4 and the overall plan are not complete. No shared Firebase rules deployment, live endpoint activation, production reads/writes, real account sanction or billing upgrade occurred.

## 26. Implementation checkpoint: local report appeals and admin corrections

Implemented locally on 2026-10-16, following the user's approval to continue the
author dispute view, appeal submission and admin moderation queue:

- Profile and hidden author-owned report details link to My report reviews.
  Authors see their private disputed reports, original deduction, counted strike,
  hide reason, report evidence and appeal/review status. Restricted accounts can
  open this private view from the account gate without reopening operations.
  Appeals require a reason and server acknowledgement; failed writes remain
  retryable and duplicate submissions preserve the original appeal.
- Admin console has a moderation entry with bounded case/vote pages. An active
  admin can inspect report text/photo, the appeal and individual vote reasons,
  then uphold or overturn with an audited reason. Verified Auth custom claims
  supply administrator authority; profile roles/request fields cannot grant it.
  Authors cannot review their own case. Other users cannot inspect private cases
  and clients cannot write appeals, decisions or restoration events directly.
- A final overturn atomically restores exactly the original deduction, removes
  exactly this counted strike, restores the report publicly with voting locked,
  and records an immutable restoration/review/audit event. Historical five-vote
  counts remain evidence; the model now honors the trusted overturned marker.
  Duplicate same-outcome reviews return the existing result, conflicting final
  decisions fail. Upholding makes no extra deduction. This initial workflow has
  one appeal/final review per report; reopening/escalation is future work.
- Community suspension is cleared below five remaining strikes while preserving
  independent manual/permanent restrictions. A pending permanent-ban review is
  withdrawn below ten; this is not a permanent-ban decision endpoint. Pending
  operation reconciliation rechecks current restrictions so an overturned case
  cannot cancel an otherwise permitted operation later. Ended trips are never
  restarted by review. Normal/Sample records remain separate.
- English/Sinhala/Tamil labels cover the new flow. Fluent translation, native
  TalkBack and a complete manual Android walkthrough remain unverified. All new
  entry points stay behind local-debug v2 mode and use the existing theme.
- Added guarded `provision-local-admin.mjs`: `admin@local.test` uses the public
  local-only password from `docs/local-validation.md`. The actual Admin SDK sets
  only this synthetic demo account's claim and creates a missing profile without
  resetting existing data. The real administrator account was not changed.

Validation: **589 full Flutter tests passed** (`phase12-full-tests.log`), including
**7 new review/model/widget tests** (`phase12-reviews-ui-final.log`); **18 existing
moderation UI/client regressions passed** (`phase12-existing-ui.log`). Full analyzer
**No issues found** (`phase12-analyze-verified.log`). **25 focused UI/client/review
tests passed under the exact local activation flags** (`phase12-local-mode-tests.log`).
**95 isolated backend/rules tests passed** (`phase12-backend-verified.log`,
demo-phase12-appeals, port 8088),
covering private ownership, admin claim binding, self-review denial, contention,
rollback, one penalty restoration, independent restrictions, bounded pagination,
scope isolation and stale reconciliation. The emulator-only test adapter now
retries concurrent create conflicts as transaction aborts, matching the trusted
store contract; an initial race-test adapter failure was corrected.

**Actual local Auth/Admin smoke passed** (`phase12-worker-smoke-final.log`) through
publication, five voters, fifth-strike restriction/worker cancellation, restricted
author appeal, denied other-user read/non-admin decision, claim-based queue/vote
evidence, duplicate overturn, +20/strike restoration and disabled-session denial.
Synthetic records remain in demo-accesstransit only. **Local debug APK built**
(`phase12-local-build.log`), manifest-checked as `.validation`, installed and
launched on emulator-5554. The process remained running with no inspected
fatal/unhandled Flutter startup error (`phase12-local-launch.log`); this does not
claim a full native screen-by-screen or physical-device walkthrough.

No production reads/writes, shared rules deployment, live endpoint activation,
real admin claim/account sanction or billing change occurred. Next moderation
slice: mandatory permanent-ban review decisions and their admin UI, with current
strikes/appeals rechecked before a reasoned decision. Full phase 4/shared rollout,
migrations, notification delivery and remaining plan features are not complete.

## 27. Implementation checkpoint: local permanent-ban review decisions

Implemented locally on 2026-10-16:

- Admin console now opens a paginated Permanent-ban reviews queue. Case details
  show the current trusted strike count, account identity, appeal state and links
  into the existing report/appeal/vote-evidence review view. Returning from report
  review refreshes the case. Approve/reject requires a reason and acknowledged save.
  English/Sinhala/Tamil resources and 320dp/200% text coverage were added.
- Authenticated ban endpoints derive administrator authority exclusively from
  verified boolean custom claims. Current reviewer restrictions are checked again
  at commit. Self-review is denied; fresh trusted Admin Auth target lookup protects
  administrator accounts, including the last one. Private queues/details are not
  exposed through public Firestore queries or client-controlled role fields.
- Report strikes, appeal submissions and report-review decisions advance one
  trusted moderation revision. Permanent-ban decisions require the displayed
  revision to match inside the transaction. Approval also requires ten current
  strikes and no unresolved report appeals. A new appeal racing the pending query
  invalidates the revision; stale/corrected cases cannot silently approve.
- Approval atomically records the immutable decision, review outcome, admin audit,
  `communityPermanent` access restriction and operation-reconciliation intention.
  Existing API/rules/account gates immediately reject operational actions, even
  with old sessions. The reason appears in the restriction screen; private report
  appeals remain accessible. Rejection adds no restriction and never extends a
  temporary deadline. Auth stays enabled for private status/appeals; production
  Auth disabling/token revocation is not claimed as part of this local workflow.
- Duplicate decisions in one cycle are idempotent; conflicting final outcomes
  fail. A genuinely new counted report can reopen a rejected/withdrawn case with
  a new immutable decision key. Previous decisions remain history and replaying
  an old threshold event cannot reopen a case. A later report overturn below ten
  withdraws the community permanent restriction without clearing independent
  manual/permanent restrictions or restarting ended operations. Normal/Sample
  state remains scoped and no shared Auth account is disabled by Sample actions.
- Added the pending-appeal query index to the local deployment preparation. It
  has not been deployed. Existing data needs no reset; missing moderation revision
  fields begin at zero and advance only through trusted mutations. This is not a
  production ledger-baseline migration or retroactive application of strikes.
- An existing concurrent trip-start test exposed a document-access limit in the
  rules. Duplicate prior-lock/bus reads were removed from trip creation: the lock
  write still enforces its prior state, and telemetry's own resource enforces bus
  occupancy. Linked run/trip/lock/GPS writes remain mandatory. A new occupied-bus
  test verifies that a different run cannot replace active telemetry even without
  a driver lock, while ordinary updates to the same run remain allowed. Normal
  and Sample rules received the matching change.

Validation:

- **596 full Flutter tests passed** (`phase13-full-tests.log`); **32 focused
  moderation/review UI/client tests passed** (`phase13-focused.log`), then the same
  **32 passed with exact local activation flags** (`phase13-local-mode-tests.log`).
  Seven new widgets cover approval/rejection, revision propagation, pending appeal
  gating, stale/failed saves and all three locales at 320dp/200% text. Full analyzer
  **No issues found** (`phase13-analyze-verified.log`).
- **105 isolated backend/rules tests passed** (`phase13-backend-complete.log`,
  demo-phase13-bans, port 8088). Coverage includes tenth-strike non-banning,
  explicit/admin-only approvals, old-session enforcement, concurrent duplicates,
  pending/stale/racing appeals, independent restrictions, rollback, Sample scope,
  new-evidence review cycles and retained immutable decisions. Initial runs exposed
  the pre-existing trip-start access limit; the full suite passed after its fix.
- **Actual local Auth/Admin smoke passed** (`phase13-auth-smoke-final.log`):
  publication/votes/temporary restriction/worker/appeal/overturn, a synthetic
  nine-strike baseline followed by the tenth counted report, pending review with
  no auto-ban, denied non-admin/stale/pending decisions, resolved appeal, explicit
  idempotent admin approval, author-visible reason and old-token publication
  denial. Synthetic demo records are retained; no real user's strike baseline
  or account access was modified.
- Local debug APK built (`phase13-local-build.log`), manifest-checked as
  `com.accesstransit.access_transit.validation` and installed on emulator-5554.
  An offline emulator interval interrupted initial startup verification. After
  reconnecting, the activity was confirmed running, its process remained present,
  and inspected logs contained no fatal/unhandled Flutter error
  (`phase13-local-launch-command.log`, `phase13-local-launch.log`). This is not a
  complete manual native, TalkBack, physical-device or fluent translation review.

This completes the local permanent-ban decision slice. No production reads/writes,
shared rules/index deployment, real administrator claim/account sanction, hosted
endpoint activation or billing upgrade occurred. Production migration, Auth
administration/rollout and full native acceptance remain separate. Next planned
feature slice: boarding assistance bound to the selected run/current driver, with
handover/expiry guarantees and notification delivery handled explicitly.

## 28. Implementation checkpoint: local run-bound assistance and inbox lifecycle

Implemented locally on 2026-10-16, as the first assistance-integration slice:

- Bus Details supplies the selected dated run and boarding/alighting stop IDs to
  the existing optional assistance form. Missing/unavailable run/driver context
  cannot silently select another departure. Confirmation and durable outbox retain
  the same run/segment across retry/process restart; reusing an ID for another run
  or segment fails. A prior account's draft cannot publish under a new account.
- Trusted submit/get/action/list operations derive rider identity from Auth and
  driver identity from the reviewed bus/run. Approval, route grant, account access,
  route/bus availability and stop order are checked transactionally. Active runs
  additionally require matching run/trip driver, bus and active operation lock.
  Clients cannot supply assignees, publication timestamps, deadlines or versions.
  The existing dated-run schema rejects ambiguous repeated stops; full route-loop
  occurrence support is not newly claimed by this slice.
- Driver dashboard now has a paginated inbox for the selected run, with no fallback
  to another bus/run. Acknowledge/Decline/Complete use authoritative transitions;
  only the current authorized driver may act. Rider receipts distinguish submission
  from acknowledgement/completion and show expiry/terminal reasons. API failure
  clears unavailable driver rows and never appears as successful acceptance.
  English/Sinhala/Tamil strings cover new controls/status/type/expiry messages;
  existing wider translation backlog and fluent review remain outstanding.
- A bounded local worker reconciles open requests. Matching driver changes retarget
  them once, increment assignment version, reset acknowledgement and write a
  handover audit/new inbox event. Old drivers fail API and direct Firestore reads
  independently of worker timing. It follows trusted run/assignment changes; it
  does not itself implement full active-trip run/lock/GPS transfer administration.
- Exact server expiry, ended/cancelled runs, passed target stops, departed origin
  and unavailable/revoked drivers close unresolved requests. Completed, cancelled,
  rejected or expired requests do not reopen. Current local expiry default is target
  timetable arrival +30 minutes, and for active runs at least 30 minutes from
  submission. This deadline is not an ETA promise. The separate local-draft retry
  window remains 30 minutes. Boarding's 24-hour upper bound does not restrict a
  selected later alighting time.
- Foreground views poll acknowledged API state every 15 seconds; the local worker
  scans bounded pages about every two seconds and continues past failing rows.
  Driver inbox supports Load more; rider history starts with latest publications
  and cursors are ownership-scoped. The optional Admin store query-order extension
  leaves existing moderation queues unchanged. Prepared assistance indexes are
  local files, not deployed indexes.
- Local `assistance_config/active` closes legacy creation as a bypass. Direct v2
  writes, including admin-client status/assignee edits, are denied. Legacy records
  retain their reconciliation path; normal and Sample policies are regenerated
  consistently with independent scoped data/outbox state. Shared production v1
  behavior is not activated or migrated by the local build flag.
- Notification records explicitly say `available-in-app`/`in-app-only`. The rider
  sees that background push is unavailable locally. No Firestore write is described
  as proof the driver saw/accepted it, and no fake push-delivered state is recorded.

Validation:

- **605 full Flutter tests passed** (`phase14-full-verified.log`). **41 assistance
  tests passed under exact local-v2 flags** (`phase14-local-mode-verified.log`),
  including eight new model/outbox/inbox tests and expanded form context coverage.
  Coverage includes stable run/segment snapshots, cross-account publication denial,
  retryable unavailable responses, acknowledged actions, removal of stale private
  rows, missing-run rejection and three-language 320dp/200% layouts. Earlier legacy
  target fixtures were updated to carry the selected run/endpoints; their existing
  target/auth/cancellation assertions are retained. UTC expiry round-trip and an
  unused test import/brace lints were corrected. Full analyzer **No issues found**
  (`phase14-analyze-clean.log`).
- **112 isolated backend/rules tests passed** (`phase14-backend-complete.log`,
  demo-phase14-assistance, port 8088), covering publication, retry, wrong driver,
  target mismatch, handover/re-acknowledgement, terminal states, exact expiry,
  passed/departed origin, route revocation, private reads/direct mutation denial,
  rollback, scope isolation and latest-first/owner-scoped history.
- **Actual local Auth/Admin assistance smoke passed**
  (`phase14-auth-smoke-complete.log`): synthetic rider/two-driver identities,
  submit/retry/ack, audited stopped-bus assignment change, old-driver API/direct
  Firestore denial, new-driver re-ack, real worker terminal-run expiry and native
  Admin SDK history/cursor query behavior. The active-run request handover uses
  matching trusted operation fixtures in policy tests; the smoke does not perform
  a real active operation transfer. **Existing moderation/appeal/ban/operation smoke
  also passed** (`phase14-moderation-smoke.log`) on the updated local server.
- Local debug APK built (`phase14-local-build-final.log`), manifest-checked as
  `com.accesstransit.access_transit.validation`, installed and confirmed running on
  emulator-5554. The first activity wait timed out; a subsequent check returned
  Status ok for the running top activity, with a present process and no inspected
  fatal/unhandled Flutter startup error (`phase14-local-launch-final-command.log`,
  `phase14-local-launch.log`). This is automated widget/backend and install/startup
  evidence, not a complete manual native two-device/TalkBack/background walkthrough.

This completes local run-bound publication, current-driver inbox and request
lifecycle integration, not all of phase 5. Remaining assistance work: complete
audited active-trip admin handover with run/bus/driver locks, GPS and assistance
coordinated together; actual background push/provider delivery and device tests;
hosted worker guarantees and production migration/rollout. No production reads,
writes, rules/index deployment, real account assignment/claim or billing change
occurred. Existing theme/layouts and historical audit remain preserved.

## 29. Implementation checkpoint: local active-trip admin handover

Implemented locally on 2026-10-16:

- Admin console overflow -> **Active trips** lists dated boarding/in-progress runs.
  Open a run, choose an approved, available driver with the exact route grant,
  enter a reason and transfer it. Lists/candidates are paginated; unavailable,
  stale, loading and retry states use existing theme components. Failed retries
  retain the same operation ID and inputs. New controls/messages have en/si/ta
  resources; fluent review remains outstanding.
- Trusted `operations.mjs` verifies the actual admin claim/current account state,
  expected driver/version, physical bus, run/trip identity, route and locks.
  One transaction transfers run/trip/bus ownership, releases the old driver lock,
  acquires the replacement lock and writes a private reason/audit. It preserves
  stop progress, actual departure/arrivals and timetable snapshots. Competing
  transfers have one winner; retries return the stored receipt without replaying
  a superseded transfer. A busy, suspended, unapproved or wrong-route replacement
  cannot acquire the operation.
- GPS pauses during transfer. Its old coordinates retain their observation
  timestamp and are not presented as fresh telemetry. **Accept and resume GPS**
  on the replacement driver's existing dashboard requires fresh location (at
  most 30 seconds old, no more than 5 seconds ahead, reported accuracy <=100m).
  The server rechecks assignment/version/approval/access before acknowledging it.
  The phone's originating account is checked before sending acceptance. These
  are plausibility checks, not proof against a device fabricating GPS.
- Old-driver Firestore/API writes fail immediately after transfer. The former
  dashboard stops its local broadcast when ownership changes. Pending replacement
  drivers cannot bypass acceptance by writing GPS or clearing the pending field;
  paused active telemetry cannot be deleted by a driver. Normal/Sample rules mirror
  these protections. Admin approval withdrawal now requires transferring/ending
  an active bus operation first, with a transactional stopped-state guard.
- Assistance authority follows the current run immediately. A bounded worker
  persists reassignment, resets acceptance and writes inbox/audit events. The
  screen explicitly distinguishes this background work from the committed trip
  transfer. Run handover versions also invalidate acceptance when multiple
  transfers return to the same driver before a worker catches up. Old jobs consult
  current authority, never restore a superseded driver, and resume across pages.
- Prepared the route-grant candidate index. No index/rules deployment occurred.
  This workflow requires internally consistent dated runs/locks; malformed or
  legacy undated operations need separate reviewed reconciliation. An admin
  cancellation/forced-stop editor and general legacy repair are not claimed.

Validation: **611 full Flutter tests passed** (`phase15-full-verified.log`),
**39 focused tests under exact local-v2 flags**, including the final localized
GPS-retry feedback (`phase15-local-verified.log`),
**120 isolated backend/rules tests passed** (`phase15-backend-complete.log`),
and clean analyzer (`phase15-analyze-complete.log`). Coverage includes moving-trip
progress, competing transfers, stale/failing commits, fresh-GPS acceptance,
old/new driver direct-write denial, Sample isolation, more than twenty assistance
records and superseded worker jobs. Three-locale widget checks use 320dp/200% text.
Final API transport tests passed (`phase15-api-final.log`), including trusted-claim
derivation; **actual local Auth/Admin handover smoke passed**
(`phase15-auth-smoke-final.log`) through the real loopback API/worker. Synthetic
smoke operations are ended after checking their handover. The final validation APK
built, its separate package was manifest-checked and it installed successfully
(`phase15-local-build-final.log`, `phase15-apk-manifest-final.log`,
`phase15-local-install-final.log`). Initial launch wait timed out; a subsequent
check returned Status ok for the running top activity with process 14626 and no
inspected fatal/unhandled startup error (`phase15-local-launch-confirmed.log`,
`phase15-local-startup-confirmed.log`). This is automated startup evidence, not a
complete native two-device/background/TalkBack walkthrough.

No production deployment, real assignment/claim, account change or billing change
occurred. This advances the active-handover portion of phase 5; actual push-provider
delivery, hosted worker availability, native background/two-device acceptance,
fare/ETA accuracy, complete translation/accessibility QA and rollout remain open.

## 30. Implementation checkpoint: local notification delivery foundation

Implemented locally on 2026-10-16. This checkpoint prepares notification delivery;
it does **not** activate Android background push or claim device receipt.

- New assistance/handover outbox events opt into a trusted notification dispatcher.
  Existing historical events are not replayed. Delivery remains separate from
  in-app request state and driver acceptance. Only the current pending assignment
  is eligible; cancelled/expired/acknowledged or superseded work is skipped.
- Authenticated registration binds an opaque Android token to the caller, locale
  and generation. Registration retries are idempotent, active devices are capped
  at eight per account, and logout/removal can disable only the caller's binding.
  Shared-device rebinding increments generation; a delayed failure/removal from
  the old account cannot disable the new binding. Registry/counts/attempts/events
  and simulation receipts are private server-owned documents.
- Transactional attempt leases coordinate concurrent workers. Transient failures
  retry with backoff, at most five attempts per event/device generation. Invalid
  tokens are disabled only if the current binding still matches. Bounded event
  and device pages retain cursors; one failed page does not claim every device
  received a message. Network delivery is at-least-once: a crash after provider
  acceptance can repeat a send. Stable notification tags/collapse keys reduce
  duplicates; exact-once network delivery is not promised.
- `localNotificationProvider` writes a deduplicated **simulated** receipt inside
  the current normal/Sample scope and makes no external network call. The local
  loopback API/worker uses this provider exclusively and rejects non-local tokens.
  Event `pushState: simulated` is distinct from `provider-accepted`, device receipt
  and driver acknowledgement; the existing in-app delivery wording stays honest.
- A staged FCM adapter accepts an explicitly supplied trusted Admin Messaging
  client. Payloads contain generic en/si/ta text and an opaque event ID, with no
  passenger name, needs, stop or location. TTL is bounded by request expiry and
  five minutes. Only genuine invalid-token errors disable a token. No FCM client,
  credentials, real device token or real push send was initialized in this step.
- Notification-open API reloads current run/driver/route/access/stop state before
  returning request details. Old tray items cannot grant access after handover,
  cancellation or account switch. Flutter has staged typed registration/removal/
  open contracts with strict payload/receipt/account checks. These contracts are
  **not wired to Firebase Messaging, app startup, OS permissions or navigation**;
  no native SDK dependency or production activation is implied.
- Prepared device-registry and event-dispatch indexes; none were deployed.

Firebase does not list Cloud Messaging among the Emulator Suite's emulated
products. Real background delivery needs a separately configured Firebase test
project/app, FCM token/permission lifecycle, Android channels and receiving/open
callbacks, a trusted test host and physical/background/device exercises. The
existing local-only authorization remains in force. See [Firebase emulator
support](https://firebase.google.com/docs/emulator-suite) and [Flutter FCM
setup](https://firebase.google.com/docs/cloud-messaging/flutter/get-started).
Sinhala/Tamil notification text still needs fluent review.

Local actual-token smoke passed (`phase16-auth-smoke.log`): synthetic device
enrolment, real bounded worker queries, explicitly simulated delivery, current
driver opens, shared-token account rebinding, driver retargeting, stale/terminal
denial and unregister. It sends no FCM message and does not display an Android
notification. Automated suite results and exact logs are recorded in the local
walkthrough. No APK build/install, shared deployment, production data/rules,
real account/token registration or billing change occurred in this step.

Validation: **615 full Flutter tests passed** (`phase16-full.log`), **27 focused
notification/assistance tests with exact local-v2 flags passed**
(`phase16-local-mode.log`), **130 isolated backend/rules/provider tests passed**
(`phase16-backend-final.log`), clean analyzer (`phase16-analyze-final.log`).
Tests cover concurrent leases, retries/limits, device cap and invalid-token cleanup,
rebinding during delivery, full device-page draining, cancelled/stale opens,
Sample isolation, private direct-write/read denial, authenticated API contracts
and staged FCM payload/error mapping without a real Messaging call.

## 31. Implementation checkpoint: staged Android notification lifecycle and navigation

Implemented locally on 2026-10-16. This advances checkpoint 30's native client
preparation; real background push remains inactive and unverified.

- Added the official `firebase_messaging` Flutter plugin (resolved 16.7.0).
  Android manifest disables Messaging auto-init and Analytics collection. The
  adapter keeps auto-init disabled and obtains a token explicitly only for a
  signed-in account with notification opt-in and OS permission. No real token was
  generated/registered during this implementation.
- Added a private Android `assistance_requests` notification channel and matched
  the staged server FCM payload's channel ID. Generic three-language text remains
  separate from passenger details. Foreground messages offer a normal app
  SnackBar Review action; background/terminated opens use Messaging callbacks.
  The background entry point does not read private data, log tokens/messages,
  navigate or acknowledge requests. Android displays the generic notification
  payload when delivery is actually configured; no data-only wake-up promise is
  made. Force-stop and device delivery behavior still require real tests.
- Account-bound `DriverNotifications` handles explicit permission, restored
  opt-in, locale changes, token rotation, retryable registration failures and
  revoked permission on app resume. Logout invalidates UI immediately, attempts
  server removal/token deletion before Auth sign-out and has a bounded wait.
  Failed/offline removal cannot guarantee immediate remote deregistration or
  removal of an already displayed OS notification; payloads remain generic and
  any later open must pass current server authorization.
- Duplicate foreground/open events are suppressed separately in a bounded
  in-memory set. Cold-start opens require a restored, opted-in account. Account
  epochs prevent a delayed permission/token/open result navigating with another
  account's details. Notification request screen reloads the opaque event through
  the trusted API, refreshes while open and clears private content when account
  or opt-in changes. Existing acknowledged driver controls handle request actions;
  simply opening a notification never accepts assistance.
- Driver Profile can show localized opt-in/status/retry/off controls when the
  staged runtime exists. Existing normal/local layouts are preserved: no runtime
  exists in current builds, so these controls remain hidden. A live notifier
  accommodates delayed staging initialization without requiring profile reopen.
- `PUSH_NOTIFICATIONS` is deliberately fail-closed: reviewed dedicated project ID
  is unset, shared project ID is forbidden, local/Sample/demo/release/web builds
  cannot enable it, and the initialized Firebase project must match. Future test
  activation still needs reviewed test Firebase/app configuration and a trusted
  v2 HTTPS host. This checkpoint does not activate a production or test provider
  merely because the plugin compiles. No iOS implementation is claimed.

Validation: **629 full Flutter tests passed** (`phase17-full.log`), **26 focused
tests with exact local-v2 flags passed** (`phase17-local-mode.log`), **20 final
notification/profile tests passed** (`phase17-final-ui-verified.log`) and **clean
analyzer** (`phase17-analyze-clean.log`). Closed activation with the explicit push
flag also passed (`phase17-activation-guard.log`). Tests cover denied/revoked
permission, rotation/locale, offline and bounded logout, permission/open account
races, stale requests, duplicates and restored cold opens. Three-language controls
and server-authorized request screens pass 320dp/200% text checks. **13 provider/
API tests passed** (`phase17-provider-api-final.log`), including the Android channel.

Final local APK compiled (`phase17-local-build-final.log`) with the Messaging
plugin and channel; Gradle emitted existing-style built-in Kotlin migration and
deprecated API notices but the build succeeded. Compiled manifest/install/startup
checks are recorded in the local walkthrough. This is compile/automated/startup
evidence, not actual FCM delivery, native notification tapping, TalkBack or a
two-device background walkthrough. No shared deployment, credentials/test-project
setup, real account/token registration or billing change occurred.

Checkpoint 31 native verification: manifest-checked separate `.validation` package
(`phase17-apk-manifest.log`), compiled Messaging auto-init and Analytics collection
both false with the assistance channel (`phase17-apk-xml.log`), successful install
(`phase17-local-install.log`). Initial activity wait timed out; repeat inspection
returned Status ok for the running top activity/process
(`phase17-local-launch-confirmed.log`, `phase17-local-pid-confirmed.log`) with no
inspected fatal/unhandled startup error (`phase17-local-startup-confirmed.log`).
These are startup checks with push disabled, not a notification delivery/tap test.

## 32. Implementation checkpoint: fare safety and reviewed tariff lookup foundation

Confirmed user steering: defer real push-project/device testing and continue other
plan work. Push activation remains disabled. This step begins phase 6 with fare
policy and a pure tariff lookup; it does not complete fare/ETA integration.

Implemented locally on 2026-10-16:

- Normal builds no longer calculate/display numeric prices from the prototype
  duration/stop formula. Results, Bus Details and legacy route/confirmation/live
  surfaces show **Fare unavailable** with an explanation that the reviewed tariff/
  stage mapping is missing. Even a numeric legacy saved estimate cannot become a
  normal displayed fare. Old saved records remain intact; zero is only the existing
  unknown sentinel, never shown as a free fare.
- The original formula is confined to explicitly identified debug local/Sample/
  demo builds, labelled **Sample est. LKR ...**. Synthetic selected-segment amount
  persistence remains consistent across navigation/save/reopen and does not change
  with GPS delay. Shared fare/disclosure widgets now use en/si/ta resources and
  accessible amount/source semantics. Existing app theme/layouts are retained;
  translations still require fluent review.
- Added `tariff_fare.dart`: immutable reviewed table/mapping contracts, exact
  direction/pattern/service-class selection, inclusive effective-date checks using
  Colombo boarding date, ordered stop occurrence mappings and explicit directed
  fare matrix lookup. Integer minor-unit amounts preserve cents without floating
  arithmetic/rounding. It does not infer stages from duration, stop count or km,
  subtract arbitrary stage indices or add neighbouring fares.
- Missing stages/cells, wrong route/class/direction, invalid stop ordering,
  expired applicability or overlapping versions return unavailable. Quotes record
  amount/currency, selected occurrences, service date, source and tariff/mapping
  versions. Repeated physical stops can be distinguished by occurrence IDs in
  this contract; the existing operational schema is not silently migrated.
- Parser validation rejects unreviewed objects, invalid dates/source format,
  noninteger/negative/zero matrix amounts and duplicate occurrence IDs. This is an
  initial non-concession contract: free/concession eligibility needs its own
  reviewed policy. A client-supplied `reviewed` flag is not authorization; trusted
  ingestion/publication/read rules remain necessary before integration.

No official tariff or stop-stage mapping was imported. Direct NTC fare-page
retrieval failed; no latest fare revision or amount is claimed verified. Fixtures
use fictional prices and `authority.example` sources. This lookup is not yet wired
to Firestore/admin import, operational search quotes or saved tariff snapshots.
Normal-mode Fare unavailable is therefore the honest interim behavior. See
`docs/fare-estimates.md` for the new policy and the superseded F24 history.

Next fare work: trusted catalogue/schema/rules, reviewed admin import and mapped
route/class data, then shared quote persistence/display and changed-tariff notices.
ETA geometry/historical measurement remains separate. No shared rules/data,
production deployment, real tariff/account, billing or FCM activation changed.

Validation: **639 full Flutter tests passed** (`phase18-full.log`), **23 focused
fare tests with exact local-v2 flags passed** (`phase18-local-mode.log`), clean
analyzer (`phase18-analyze-clean.log`). Initial normal-mode focused run also
passed (`phase18-targeted.log`); the full suite includes final locale checks.
Tests cover exact Colombo midnight/effective boundaries, immutable input snapshots,
matrix cents/through fares, loops, overlaps/missing values, normal-mode suppression
and synthetic selected-segment persistence. Three-language fare widgets pass
320dp/200% text checks. Existing mocked map tile HTTP failures appear in logs but
did not fail suites. Local APK built successfully (`phase18-local-build.log`).
These tests validate software policy/arithmetic, not real ticket prices or ETA.

The separate validation APK was manifest-checked and installed
(`phase18-apk-manifest.log`, `phase18-local-install.log`). Initial launch wait timed
out; a repeat check returned Status ok for the running top activity/process with
no inspected fatal/unhandled startup error (`phase18-local-launch-confirmed.log`,
`phase18-local-startup-confirmed.log`). No manual native fare walkthrough or real
ticket-price verification was performed.

## 33. Implementation checkpoint: reviewed fare publication and passenger quotes

Implemented locally on 2026-10-16:

- Admin -> Fares imports a bounded JSON table/mapping bundle, previews exact
  cents, applicability, source, versions and assigned physical buses, and requires
  a review acknowledgement/reason. Publication checks current route/bus snapshots
  in the audited transaction. The existing theme is retained; labels are provided
  in English/Sinhala/Tamil, pending fluent review. The management list is paginated.
- `fare_publications` versions are immutable. Admin may archive with a reason;
  corrections require a new publication ID. Clients cannot edit published amounts,
  mappings or versions, delete records or reactivate archived ones. Public reads
  expose published records only; creation/archival require active trusted admin.
- Results and consolidated Bus Details read published, mode-matching, explicitly
  bus-scoped fares and use the selected directed segment's exact integer cents.
  Cached/pending/error/malformed/ambiguous catalogue results fail closed. An exact
  itinerary match is required; source/version are displayed. More than twenty
  candidate publications also fail closed. The required index is prepared locally.
- Optional Save Trip persists the validated quote's amount/currency/source and
  table/mapping/segment versions. Backend rules reject forged prices and mismatched
  versions, buses, segments and date applicability. Details revalidates saved
  snapshots against current publications and explains changed/unavailable fares;
  historical saved records survive archival. Existing records are not rewritten.
- Added a documented local-only JSON example and actual local Auth-token smoke
  script, `test/security/verify-local-fares.mjs`. Its unique synthetic fixtures are
  separate from operating data; it loads local rules without clearing the database.

This completes the catalogue/publication/quote software slice, not authoritative
fare-data review. No real official tariff or stop-stage mapping has been imported
or verified. Normal operations without those publications still show Fare
unavailable. The route ID is the current directional pattern; recurring template,
repeated-stop occurrence migration and concession policy are not claimed complete.
No shared deployment, real account/catalogue write, billing or FCM activation
occurred. The user has deferred real push/device tests. Next fare/ETA work is
reviewed operational data and route-geometry/measured ETA integration.

Validation: **648 full Flutter tests passed** (`phase19-full-final.log`), **39
focused local-v2 tests passed** (`phase19-local-final.log`), **132 isolated
backend/rules tests passed** (`phase19-backend.log`), and **clean analyzer**
(`phase19-analyze-clean.log`). Tests cover exact cents, matching/overlap failures,
immutable audited publication/concurrent catalogue changes, quote persistence,
archived fare removal and three-language admin preview at 320dp/200% text. The
English UI exercises failed publication and acknowledged retry. Actual local
admin/rider tokens pass publication/query/save/forgery denial/archive checks
(`phase19-auth-smoke.log`); expected permission-denied logs are negative assertions.
These fictional fixtures do not establish real fare accuracy. The separate local
APK built successfully (`phase19-local-build.log`).

The manifest-checked `.validation` APK installed successfully
(`phase19-apk-manifest.log`, `phase19-local-install.log`, package update time
2026-10-16 22:45:13 Colombo). This is not a native fare walkthrough or official
ticket-price verification. The normal installed package was not replaced.

Initial Android launch wait timed out; the repeated launch returned Status ok
(`phase19-local-launch-confirmed.log`). No fatal/unhandled Flutter startup error
was found in the inspected log window (`phase19-local-startup.log`). This is
startup evidence only.

## 34. Implementation checkpoint: reviewed road geometry and moving-run search

Implemented locally on 2026-10-16:

- Admin -> Route geometry imports/previews a reviewed directed trace, source and
  version, full ordered stops and stop vertex indices. Explicit review/reason is
  required. Publication transaction guards current route and station snapshots;
  each stop vertex must lie within 100m of its reviewed station coordinate.
  Corrections require a new version through the service. Withdrawal is acknowledged
  and clears passenger geometry. Admin actions are audited; public catalogue review
  reasons must not contain private information. No physical deletion is permitted.
- `route_geometries/<route ID>` is admin-owned and normal/Sample/Test scoped.
  Coordinates are stored as maps, compatible with Firestore. Readers reject
  cached/pending/withdrawn/malformed/mode-mismatched data. Publication/withdrawal
  refuse to overwrite another data mode. Exact route and full bus stop ordering
  are required; route numbers/name similarity cannot authorize a geometry match.
- Moving active-run search projects fresh matching run/trip/driver GPS onto the
  recorded current road leg. Off-route fixes, ambiguous crossings, stale/future/
  cached/offline coordinates, invalid speeds and passed target stops cannot produce
  a moving estimate. A future or terminal run never inherits another run's GPS.
  Search rechecks boarding eligibility when geometry arrives or is withdrawn.
- One shared baseline estimates current-leg time from remaining **road distance
  fraction × timetable interval**, then adds later timetable intervals. Results
  shows estimated boarding; Details recomputes estimated destination arrival and
  draws the reviewed selected-segment polyline. No paid traffic/routing API, default
  20km/h motion or straight-line stop shortcut is introduced in this path.
- English/Sinhala/Tamil labels explicitly identify a low-confidence road-progress/
  timetable estimate and a range. The ±30%/minimum-one-minute allowance is a
  heuristic, not calibrated coverage. Stationary-between-stop GPS does not acquire
  a moving ETA; the existing stationary-at-recorded-stop timetable fallback remains.
  Timetable/fare/saved selection timestamps are not rewritten as observed times.

See `docs/route-geometry-eta.md` and its local-only JSON example for schema,
publication and limitations. No real route geometry has been imported/verified;
fixtures are fictional. This is geometry/timetable integration, not completion
of smoothed multi-fix motion, historical dwell/segment models, GPS accuracy/sequence
validation, road-data re-review, immutable geometry history or measured median/P90
ETA evaluation. Repeated physical stop occurrences and subset route patterns still
need migration. Legacy EtaService compatibility screens retain their old algorithm;
the consolidated passenger flow uses the new shared baseline. Physical background
GPS, native TalkBack and two-device road validation remain pending. Real FCM tests
stay deferred as requested. No shared deployment, production data, billing or Auth
changes occurred.

Validation for checkpoint 34: **659 full Flutter tests passed**
(`phase20-full-final.log`), **27 focused local-v2 geometry/search/details tests
passed** (`phase20-local-final.log`), **133 isolated backend/rules tests passed**
(`phase20-backend-verified.log`). Tests include bent-road remaining distances,
ambiguous crossings, stale/off-route/wrong-run rejection, matching moving search,
withdrawal, future-run static path/no live ETA, concurrent admin catalogue changes,
mode protection and three-language preview at 320dp/200% text. English admin UI
also exercises failed publication and acknowledged retry. Actual local admin/rider
token publication/server-read/unauthorized-write/withdrawal-listener smoke passes
(`phase20-auth-smoke-final.log`). These are fictional software fixtures, not road
or ETA accuracy validation.

Analyzer: **No issues found** (`phase20-analyze-verified.log`). Final local APK
build succeeded (`phase20-local-build-verified.log`). No shared rules deployment
is implied by local UI/backend validation.

The manifest-checked final `.validation` APK installed successfully
(`phase20-apk-manifest-verified.log`, `phase20-local-install-verified.log`). Initial
launch waiting was slow/timed out; a repeated launch returned Status ok for the
running top activity (`phase20-local-launch-confirmed.log`). No fatal/unhandled
Flutter error was found in the inspected startup window
(`phase20-local-startup-confirmed.log`). This is startup evidence only, not a
manual road/geometry/ETA walkthrough; the normal installed package is unchanged.

## 35. Implementation checkpoint: local ETA prediction/arrival evaluation

Implemented locally on 2026-10-17:

- Added an opt-in Local ETA diagnostics action to consolidated Bus Details, using
  the existing theme. Normal/release builds have no capture/action/persistence.
  The selected run's acknowledged live updates and trusted search clock capture
  forecasts before arrival, then pair them with matching driver-reported stop
  arrivals. The exact shared geometry ETA result is recorded; timetable forecasts
  remain a separate source. Timetable, fare, saved trips and operation state are
  not changed by diagnostics.
- Records freeze at most one forecast per run/stop/source/minute. Summaries use
  the first observation per run/stop/source/actual-lead bucket, with separate
  route/algorithm/geometry version groups. Median/P90 absolute error, signed mean
  error, matched/distinct-run counts and heuristic interval covered/count are
  computed; pending/excluded records never count as zero error. Small samples are
  labelled, and no accuracy percentage or calibrated confidence is claimed.
- Known/earlier/future/corrected/removed arrivals, cancelled runs, stale/wrong-run
  GPS and terminal missing arrivals cannot produce misleading success samples.
  New accounts have capture disabled. Device storage is account-scoped and bounded
  to 500 forecasts; seven-day retention applies during capture. Delayed account
  loads/writes cannot overwrite another account's visible ledger. Storage failures
  remain explicit/retryable. No raw GPS, email or driver ID is persisted.
- Local diagnostics shows counts and source-separated metrics, supports JSON copy
  and clear, and has English/Sinhala/Tamil labels. A replay test recomputes metrics
  from exported records rather than trusting saved summary values. Its default
  fixture is visibly fictional. See `docs/eta-evaluation.md` for use and definitions.

The reference is acknowledged **driver-reported actualArrival**, whose clock and
confirmation delay are not independently validated. This is a local measurement
tool, not server-owned fleet analytics, physical arrival ground truth, historical
model training or real ETA accuracy evidence. Capture observes only selected Details
views; pending records and sampling/storage limits can bias results. Production
capture requires separate privacy/retention/trusted-ingestion decisions and device/
road validation. No shared deployment, production data, backend/rules mutation,
new billing or FCM activation occurred. Native and fluent translation review remain
pending; real push tests stay deferred as requested.

Validation for checkpoint 35: **673 full Flutter tests passed**
(`phase21-full-final.log`), **41 focused tests with exact local-v2 flags passed**
(`phase21-local-final.log`), **30 persistence/diagnostic/replay regressions passed**
(`phase21-regression-final.log`), and **clean analyzer** (`phase21-analyze-final.log`).
New coverage freezes forecasts before arrivals, verifies separate exact errors/
nearest-rank P90, avoids repeated-observation weighting, excludes invalid/corrected/
cancelled references, bounds retention/capacity, replays exports, handles storage
failure/retry/account races and exercises automatic Details capture/matching.
English/Sinhala/Tamil controls pass 320dp/200% text checks. An existing search test
used the host's current date around midnight; its clock/date fixture is now
deterministic while preserving navigation/no-auto-save assertions. Mocked map HTTP
failures remain in logs but suites pass. Local APK build succeeded
(`phase21-local-build-final.log`). Backend/rules were not changed for this slice.

Manifest-checked `.validation` APK installed successfully
(`phase21-apk-manifest.log`, `phase21-local-install.log`). The normal app package
was not replaced. Automated widget/fixture validation does not constitute a
manual native diagnostic-export walkthrough or a physical road measurement.

Repeat launch returned Status ok for the running validation activity
(`phase21-local-launch-confirmed.log`), following the initial Android launch wait.
No fatal/unhandled Flutter error was found in the inspected startup window
(`phase21-local-startup-confirmed.log`). This establishes startup only.

## 36. Implementation checkpoint: paginated owner-scoped saved trips

Implemented locally on 2026-10-17:

- Home has a View all saved trips entry even when no open preview exists. The
  existing preview remains, using a bounded latest-open query (limit 1) rather
  than subscribing to the entire owner history. The one-shot equivalent is also
  bounded. New list/control/resume labels support English/Sinhala/Tamil and reuse
  current Material cards, typography and actions.
- Saved Trips reads twenty owner-scoped records per page plus one lookahead,
  with Next/Previous, Refresh, loading/empty/error/retry states and explicit
  acknowledged removal. It retains only the current page. The cursor binds owner
  and document ID, still works after that document is deleted and is validated
  against returned rows. Retry preserves the attempted page boundary.
- All saved statuses and past records remain accessible; Search's 24-hour horizon
  does not filter them. Stable descending ID order includes legacy missing-date
  records. This is **not chronological/newest-first** ordering; current hash IDs
  do not establish save chronology. The Home preview independently uses indexed
  creation time. Chronological legacy ordering remains a migration consideration.
- Row opening rereads the exact owner-scoped saved record before using the
  existing consolidated Details adapter. Identity, segment, selected date/time,
  needs, run and fare snapshot remain intact; current run/fare state still refreshes
  through existing Details logic. No confirmation step, new save, seat booking,
  tracking start or Settings change is introduced. Missing/incompatible legacy
  vehicle/selection data has an honest unavailable/retry state.
- Saved list/resume views clear private data and invalidate late responses on
  account changes, including away/back races. Failed removals retain rows; an
  acknowledged owner bookmark deletion does not alter operational bus/run data.
  Returning from Details refreshes the current page. Other-device list changes
  require refresh/read acknowledgement rather than a whole-history listener.
- Required index definitions are prepared locally. Existing normal/Sample owner
  rules are unchanged; no broader client access is introduced. A guarded local
  Auth smoke script verifies both scopes without clearing existing emulator data.

See `docs/saved-trips.md` for ordering, legacy, query and refresh limitations.
This completes the saved-list/pagination slice, not loop occurrence migrations,
full schedule-version history or every remaining product gate. No shared index/
rules deployment, production writes, saved-data reset/migration, billing change
or FCM activation occurred. Fluent translation, native TalkBack and physical-device
walkthrough remain pending; real push tests stay deferred.

Validation for checkpoint 36: **684 full Flutter tests passed**
(`phase22-full.log`), **36 focused saved-trip/persistence/fare tests passed with
exact local-v2 flags** (`phase22-local-tests.log`), **27 saved-list/persistence
regressions passed** (`phase22-targeted-final.log`), clean analyzer
(`phase22-analyze-final.log`) and successful local APK build
(`phase22-local-build.log`). Coverage includes bounded pages, cursor/owner/order
validation, deleted boundaries, failed next-page retry, acknowledged removal,
exact Details navigation, late account responses and three-language 320dp/200%
layouts. Actual local Auth-token smoke passes normal/Sample 46-record paging,
legacy/past/closed inclusion, bounded latest-open preview and foreign/unscoped
read/delete denial (`phase22-auth-smoke-final.log`). Expected mocked map HTTP
failures do not fail the Flutter suite. No rules/backend policy mutation occurred.

Manifest-checked `.validation` APK installed successfully (`phase22-apk-manifest.log`,
`phase22-local-install.log`). Repeat launch returned Status ok for the running
activity (`phase22-local-launch-confirmed.log`), with no fatal/unhandled Flutter
error found in the inspected startup window (`phase22-local-startup-confirmed.log`).
This is startup evidence only, not a manual native saved-history/TalkBack
walkthrough. The normal installed package was not replaced.

## 37. Implementation checkpoint: scoped report previews and live pagination

Implemented locally on 2026-10-17:

- Consolidated Bus Details now passes exact selected bus and boarding/intermediate/
  alighting IDs into bounded report queries. It no longer listens to the entire
  active report collection. Preview queries require active status and target type/
  ID, limit to four records per bus/30-stop group, and show at most three relevant
  visible observations. Existing public/dispute/freshness checks remain in effect.
- Community reports stays immediately above optional Save Trip. Preview/evidence
  expansion disclose partial coverage; an empty preview cannot claim no barriers
  exist. View all relevant reports is available even with an empty preview and
  opens a bus/selected-stop browser with twenty-record live pages plus lookahead,
  Next/Previous, target switching, refresh and loading/unavailable/empty states.
- Each browser page subscribes only to its exact target and uses stable descending
  document IDs, including legacy records without dates. This is not newest-first
  chronology or complete evidence ranking. Raw-page cursors continue across expired
  entries; empty pages explain older useful reports may exist. Target changes/error/
  pending/cache transitions clear previous rows. Hidden/disputed records disappear
  from public evidence; author/admin private review remains separate.
- Scoped preview groups await acknowledged receipts, invalidate failures and cancel
  subscriptions on disposal. Firebase initialization/query errors become report
  unavailable/retry state rather than aborting Details navigation. Existing report
  detail/voting screens are reused; no reward/moderation policy changes occurred.
- English/Sinhala/Tamil resources cover new controls/disclosures. Required report
  index is prepared locally, with unchanged normal/Sample access rules. A guarded
  emulator smoke uses unique synthetic data and does not reset the database.

See `docs/segment-reports.md` for preview incompleteness, ordering, query budgets
and concurrency limits. This completes the scoped-report pagination slice, not
complete route evidence aggregation, chronology migration or legacy Search query
replacement. Native/fluent review remains pending. No shared deployment, production
data, billing or real FCM activation occurred; real push tests remain deferred.

Validation for checkpoint 37: **689 full Flutter tests passed**
(`phase23-full-verified.log`), **17 scoped-report/Details/navigation regressions
passed** (`phase23-regression.log`), and **clean analyzer**
(`phase23-analyze-verified.log`). Tests cover exact segment parameters, unrelated
target rejection, hidden/error clearing, target switching, page boundaries,
empty-but-continuable pages and three-language 320dp/200% layouts. Local emulator
smoke passes normal/Sample four-record previews, 31-stop chunk boundaries, 45 bus
reports across pages and visible-row removal after committed hidden/five-False
fixture state (`phase23-local-smoke.log`). This smoke validates query delivery;
it does not newly replay five voting accounts. Existing moderation policy is
unchanged. Initial whole-suite runs exposed synchronous Firebase query-init
errors; converting them into stream errors restored the unavailable/retry path.
Mocked map HTTP failures remain in logs but the final suite passes.

**36 local-v2 scoped-report/Details/geometry/diagnostic regressions passed**
(`phase23-local-verified.log`). The final report refresh tooltip uses the shared
server-refresh wording rather than a saved-trip label.

Five final browser UI tests passed (`phase23-ui-final.log`); the final Local Test
APK build succeeded (`phase23-local-build-final.log`). Automated query/widget
checks do not establish a native TalkBack or physical-device walkthrough.

Manifest-checked `.validation` APK installed successfully (`phase23-apk-manifest.log`,
`phase23-local-install.log`). Repeat launch returned Status ok for the running
activity (`phase23-local-launch-confirmed.log`); no fatal/unhandled Flutter error
was found in the inspected startup window (`phase23-local-startup-confirmed.log`).
This is startup evidence only. The normal installed package was not replaced.

## 38. Implementation checkpoint: recurring service calendars

Implemented locally on 2026-10-17:

- Admin → Buses → Dated departures → Service calendar publishes reviewed weekdays,
  Colombo departure time and an inclusive date range of at most 31 days. Each
  publication captures the physical bus itinerary as an immutable private
  `service_schedules` version. English/Sinhala/Tamil resources cover the new UI;
  fluent/native review remains pending.
- Generate dated departures explicitly materializes matching days using the
  existing overnight timetable and −5/+30 minute start window. New runs retain
  schedule ID/version. All writes use one audited transaction, including guards
  for the calendar, current bus/route and existing run slots.
- Deterministic bus/departure IDs prevent duplicate generation. Existing one-off,
  boarding, moving, completed and cancelled runs are preserved. Concurrent slot
  publication or calendar retirement rejects the stale transaction with no
  partial generation. Changed bus stop order/timetable/route requires a reviewed
  replacement calendar.
- Retirement is one-way and stops further generation; it does not cancel dated
  runs or rewrite saved trips. Cancel unwanted scheduled runs separately. Active
  operations retain the existing handover/reconciliation path. Catalogue deletion
  checks include calendar references to buses, routes and stops.
- Root and generated Sample/Test rules restrict calendar reads/publication to
  active trusted administrators, allow retirement only, and deny deletion or
  editing published schedule fields. Public run access remains unchanged.

Validation: **696 full Flutter tests passed** (`phase24-full.log`), **13 focused
local-v2 tests passed** (`phase24-local.log`), **70 isolated Firestore rules tests
passed** (`test/security/phase24-rules.log`, `demo-phase24-calendars`, port 8088),
and analyzer **No issues found** (`phase24-analyze.log`). Coverage includes Colombo
midnight rollover, weekday filtering, retries/terminal states, one-off collisions,
concurrent generation/retirement, invalid ranges and 320dp/200% UI operation.
The separate Local Test APK built successfully (`phase24-local-build.log`).

This is bounded, admin-triggered generation, not an unattended scheduler or
rolling calendar extension. Holiday imports, full schedule-change history,
repeated-stop occurrence migration and admin query pagination remain follow-ups.
Existing dated runs/saved snapshots were not migrated or rewritten. No shared
rules deployment, billing change, production calendar/data write or real push
test occurred. See [service calendar behavior](service-calendars.md).

Local demo activation: `verify-local-calendars.mjs` passed with actual emulator
admin/rider tokens in normal and Sample/Test scopes (`phase24-local-smoke.log`).
It loaded the current rules into the local demo only, without resetting existing
data, and checked audited publication, server receipt, private access, immutable
fields and one-way retirement. Generation itself is covered by Flutter tests;
this smoke does not claim a native calendar walkthrough. Manifest-checked
`.validation` APK installation succeeded (`phase24-apk-manifest.log`,
`phase24-local-install.log`); repeat launch returned Status ok and the inspected
startup log contained no fatal/unhandled Flutter error
(`phase24-local-launch-confirmed.log`, `phase24-local-startup.log`). Normal app
installation/data were preserved.

## 39. Implementation checkpoint: repeated-stop occurrences and loop journeys

Implemented locally on 2026-10-17:

- Route editing can add the same physical station again, assigning a new unique
  visit ID without renumbering existing visits. Bus editing selects exact route
  visits and preserves separate/reorderable time controls. `stopStationIds`
  resolves ordered unique `stops` to physical stations. Legacy identity mappings
  remain compatible; no existing shared record was converted or reset.
- Admin validation checks physical references, exact route visit order/bindings
  and prevents rebinding an existing bus visit to another physical station.
  Dated runs copy the mapping; recurring calendars guard it in their timetable
  snapshot. Catalogue dependency checks retain physical references.
- Search enumerates ordered visit pairs for physical endpoints. A loop's first
  and return boarding opportunities have their own times/segments; active
  progress can exclude the first while retaining the second. Results carry the
  exact chosen IDs and show route positions for repeated patterns. Details and
  bookmarks preserve them; distinct visit choices have distinct bookmark IDs.
- Details, endpoint accessibility, compact reports and the scoped report browser
  resolve physical stations. Observations about a physical stop remain relevant
  when the passenger uses its later visit; occurrence aliases are not reporting
  targets. Names/coordinates resolve correctly for driver progress and maps.
- Trusted v2 assistance validates visit order and the mapped physical target,
  retains server boarding/alighting indexes and expires only after the selected
  visit is passed. Driver request/push details expose route stop positions.
  Legacy v1 assistance is not claimed to have this trusted run/visit contract.
- Geometry review resolves occurrence vertices to physical stations. Existing
  current-leg projection, timetable maps and fare-stage mappings keep unique
  occurrence keys; no first-visit fare or GPS is substituted for a return visit.
  Production transaction callbacks were exercised through separate return-stop
  arrival and actual final-stop completion/lock release.
- Corrected the preceding calendar's Sinhala/Tamil UTF-8 strings after validation
  exposed replacement question marks. Unicode regression checks cover every
  calendar string and new occurrence wording. Human translation review remains.

Validation: **708 full Flutter tests passed** (`phase25-full-final.log`), **38
focused local-v2 tests passed** (`phase25-local.log`), **121 isolated rules/backend
tests passed** (`test/security/phase25-rules-backend.log`, `demo-phase25-loops`,
port 8088), and analyzer **No issues found** (`phase25-analyze-final.log`). Tests
include 320dp/200% route editing, both normal/Sample assistance scopes, physical
report relevance, saved visit identity, midnight schedules and return-leg ETA.

Local Auth/Firestore emulators had stopped; they were restarted on 9099/8087 and
the updated loopback API was started on 8787. The local-token loop smoke passed
(`phase25-local-smoke.log`): later-visit bookmark, exact driver acknowledgement,
physical station validation and passed-visit expiry. Its operation progress is
trusted synthetic fixture data, not measured GPS. Named synthetic fixtures/admin
were initialized only because the restarted Auth emulator was empty. No shared
rules deployment, real data migration, billing change or real FCM test occurred.

This does not claim automatic migration of old duplicate-ID records, complete
schedule-version history, arbitrary subpattern geometry matching, same-physical-
endpoint full-circuit search, or a native GPS/TalkBack walkthrough. Review real
catalogue occurrence IDs before any rollout. See [stop occurrence behavior](stop-occurrences.md).

The final Local Test APK built successfully (`phase25-local-build.log`), its
manifest was checked as `.validation` (`phase25-apk-manifest.log`) and installation
succeeded (`phase25-local-install.log`). The normal installed package was not
replaced. Startup confirmation is separate from a manual native loop journey.

Repeat launch returned Status ok (`phase25-local-launch-confirmed.log`); no fatal
or unhandled Flutter error was found in the inspected process startup log
(`phase25-local-startup.log`). The smoke's optional bootstrap additionally checks
that functional demo collections are empty before seeding named fixtures.

## 40. Implementation checkpoint: dated replacements and saved timetable snapshots

Implemented locally on 2026-10-17:

- Admin Dated departures offers Publish replacement with a reviewed Colombo
  date/time and a clearly public reason. One audited transaction cancels the
  original, creates its linked replacement with the next run schedule version,
  and appends immutable `service_run_changes` history. Original departure/stop
  timings remain unchanged. Concurrent starts, stale edits, failed commits and
  occupied replacement slots cannot partly cancel the source; predecessors
  cannot fork. Active operations retain the separate reconciliation workflow.
- New saved trips capture the selected visit IDs, physical station mappings,
  names, available intermediate times and acknowledged run version. Unknown
  intermediate times remain unknown. Retries return the first acknowledged
  snapshot instead of overwriting it with later catalogue labels. Existing fare
  and accessibility-needs snapshots remain separate and unchanged.
- Bus Details watches the original run and explains cancellation, public reason,
  published replacement and timetable/version mismatch without switching the
  saved selection. GPS still requires exact run/timetable matching. If the
  catalogue bus/route/segment changes or disappears, the same destination shows
  the original saved timetable record, timeline, saved fare where available and
  optional removal; it does not certify live GPS/current accessibility or offer
  assistance for an unavailable selection. Shared run subscriptions retain their
  last receipt across presentation changes and are disposed with the screen.
- Rules validate new snapshot shape/times/version, keep snapshots owner-scoped
  and immutable, and restrict append-only public change history to active trusted
  administrators. Root policy is mirrored into Sample/Test. Old clients without
  the new field remain accepted; shared rules must precede release of new clients.
- Admin dated/calendar/replacement publication uses timezone-neutral civil-clock
  arithmetic before explicit Colombo-to-UTC conversion, avoiding host DST clock
  normalization. Overnight rollover and the authoritative −5/+30 start gate are
  retained. New messages have English/Sinhala/Tamil resources; fluent review and
  native accessibility checks remain pending.

Validation: **715 full Flutter tests passed** (`phase26-full-final.log`), **42
local-v2 focused tests passed** (`phase26-local.log`), **73 isolated rules tests
passed** (`test/security/phase26-rules.log`, `demo-phase26-history`, port 8088),
and clean analyzer (`phase26-analyze-final.log`). Coverage includes version chains,
rollback/start races, snapshot retry idempotency, catalogue loss, truthful static
history at 320dp/200% text, loop regressions and nominal clocks/overnight rollover.
Actual local admin/rider tokens verified both scopes' snapshots, linked atomic
replacement/history and denied rewrites (`phase26-local-smoke.log`); this smoke
tests the rules contract while Flutter exercises the production Dart callbacks.

This is per-dated-run history and new-bookmark snapshot capture, not a complete
calendar-template migration/history or historical backfill. Legacy bookmarks
without snapshots retain the existing restore/retry/replan behavior; missing old
intermediate history is not invented. No shared rules deployment, production
data change, database reset, billing upgrade or real FCM test occurred. See
[schedule history behavior](schedule-history.md).

The final Local Test APK built successfully (`phase26-local-build-final.log`),
was manifest-checked as `.validation` (`phase26-apk-manifest-final.log`), and
installed successfully (`phase26-local-install-final.log`). Launch returned
Status ok (`phase26-local-launch-final.log`); no fatal/unhandled Flutter error
was found in the inspected process startup window (`phase26-local-startup-final.log`).
The normal installed package/data were preserved. This is startup evidence,
not a native reschedule/TalkBack walkthrough.

## 41. Implementation checkpoint: scoped manual account suspension/restoration

Implemented locally on 2026-10-17:

- Local-v2 Admin -> Users -> Account access now loads an acknowledged restriction
  snapshot and supports a reasoned 72-hour suspension or an explicit restriction
  until admin restoration. Restore requires a reason and clears only the manual
  restriction. Community deadlines/permanent decisions, points, strikes, driver
  approvals and route grants remain independent. Deadline presentation uses
  Asia/Colombo; the owner account-status response includes the effective manual
  reason. English/Sinhala/Tamil resources are present, pending fluent review.
- New trusted `accounts/detail` and `accounts/change` endpoints derive actor and
  admin authority from verified Firebase claims, recheck current account access
  and protect self-action and all trusted admin accounts. Public profile roles
  cannot grant this permission. The scope is server-allowlisted; point lookups
  and transactions require no new query index or client-write permission.
- A manual revision and immutable operation ID guard each atomic access,
  decision, activity audit and suspension outbox commit. Concurrent distinct
  decisions have one revision winner. Exact retries return the first receipt;
  changed payloads conflict, and replaying an old suspension after restoration
  never reapplies it. The UI preserves ambiguous request payloads for retry,
  reloads after stale decisions and blocks captured controls on account change.
- Existing access rules immediately deny suspended operational mutations. The
  existing worker reconciles a matching active driver trip, cancels its run,
  ends broadcasting, releases its lock and reconciles assistance. It preserves
  newer conflicting operations for review. Restoration does not restart a
  cancelled trip or release unrelated community restrictions. At exactly 72
  hours, the server expires a temporary manual restriction without relying on
  phone time or scheduled Auth re-enabling.
- Normal and Sample/Test policy state, revisions and decisions remain isolated.
  The running local API retains its existing normal-only scope allowlist.
  Neither path writes Firebase Auth disable/revocation state. Direct client
  access/decision writes remain denied under existing root and Sample rules.

Validation: **721 full Flutter tests passed** (`phase27-full-final.log`), **29
local-v2 UI/client/admin gate tests passed** (`phase27-local-tests.log`), **142
isolated rules/backend/API/provider tests passed**
(`test/security/phase27-final.log`, `demo-phase27-accounts-final`, port 8088),
and full analyzer **No issues found** (`phase27-analyze-clean.log`). Coverage
includes exact expiry, scoped indefinite restriction, rollback, idempotent
concurrent decisions, preserved community sanctions, actor/admin protection,
account switching and all three locales at 320dp/200% text.

Actual loopback API admin/driver tokens verified concurrent revision rejection,
retry receipt, manual reason, worker trip/GPS/lock cancellation and restoration
that preserves a separate community ban (`phase27-local-smoke-final.log`). The
smoke created uniquely named fictional accounts/records, preserved Sample scope
and left Auth enabled; it did not reset the emulators. Local API was restarted
on its existing loopback port with the new endpoints.

The Local Test APK built (`phase27-local-build.log`), was manifest-checked as
`.validation` (`phase27-apk-manifest.log`), installed successfully and launched
with Status ok (`phase27-local-install.log`, `phase27-local-launch.log`). No
fatal/unhandled Flutter error appeared in the inspected process startup log
(`phase27-local-startup.log`). This is automated/startup evidence, not a native
manual-suspension/TalkBack walkthrough. Normal installed app/data were preserved.

This completes the scoped manual application-access slice, not all account
administration. Auth disable/enable, refresh-token revocation, reviewed deletion
and a dedicated manual-restriction appeal submission remain separate work; the
existing report-dispute appeals are unchanged. No production/shared deployment,
claim change, real FCM test, billing upgrade or database reset occurred. See
[manual account controls](manual-account-controls.md). Remaining release gates
also include real fare/geometry data, measured ETA accuracy, fluent/native QA and
reviewed hosted-backend/migration rollout; real push testing stays deferred.

## 42. Implementation checkpoint: main-app workflow and HTTPS activation

Implemented on 2026-10-17 following the user's workflow correction:

- Future implementation targets the existing main application and its real
  Firebase project. No separate Local Test APK or intermediate APK is to be
  built/installed; the main APK is deferred to final delivery. Automated tests
  remain available without a second installed app. Earlier validation records
  are retained as historical evidence.
- Main-app moderation v2 now accepts the configured trusted HTTPS origin in
  debug or release without requiring `LOCAL_VALIDATION`. The shared client no
  longer chooses emulator HTTP merely because v2 is enabled. Missing/invalid
  origins fail explicit activation; main activation cannot grant the HTTP
  emulator exception. Existing publication/voting, account gates and admin
  workflows consume this configuration. This does not invent a hosted URL or
  change Firebase project IDs, seed data or administrator claims.
- Android's separate `.validation` suffix/label branch was retired. Native
  `LOCAL_VALIDATION=true` is rejected before assembly, preventing an old test
  command from overwriting the main app with a synthetic backend. The main
  package keeps real Google Services configuration and cleartext disabled.
- Firebase Functions is the confirmed hosting choice. A read-only check of
  `accesstransit-b615b` returned no linked billing account and billing disabled
  (`phase28-billing-preflight.log`). Functions inventory returned 403
  `SERVICE_DISABLED`. No billing upgrade/link or API enablement occurred.
  The new guarded billing-read script prints only sanitized status, not tokens
  or billing account identifiers. Shared Functions/rules migration and an actual
  HTTPS endpoint are still required for v2 server operations to run live.

Validation: **725 Flutter tests passed**, with **2 main-activation tests skipped**
under the ordinary unconfigured build (`phase28-full.log`); those tests were
executed with main v2 HTTPS defines and mocked transport as part of **27 passing
main-backend/client/account-control tests** (`phase28-main-backend-tests.log`).
An additional focused configuration/client run passed **19 tests**
(`phase28-targeted.log`). Full analyzer **No issues found** (`phase28-analyze.log`).
Coverage includes release-compatible activation, actual main-client origin
selection, authenticated normal scope and rejected emulator HTTP in main mode.
These are mocked HTTP tests, not a claim of real hosted operation.

Android Gradle `help --offline` accepted the main configuration
(`phase28-gradle-config.log`) and rejected the retired native test flag for the
intended reason (`phase28-retired-apk-guard.log`). Neither task assembled an APK.
No APK build/install/uninstall, production user/catalogue write, database reset,
billing change, shared rules/function deployment or real push test occurred.
See [main app and backend workflow](main-app-backend.md). Next deployment work
is preparing the Firebase Functions package and coherent rollout; account Auth
lifecycle controls remain implementation work, not an activated feature claim.

## 43. Current remaining work and development setup decision

Updated 2026-10-17. This section records the latest agreement and outstanding
work; it does not claim a new implemented or deployed connection.

Use the main app on the Android emulator with real Firebase Auth/Firestore and
trusted server code on localhost. Defer hosted deployment, billing upgrades and
APK generation until needed/final delivery. Automated tests do not require a
second installed app. Firebase Functions remains a future hosting option.

Priority order for the remaining work:

1. **Wire the agreed development connection (completed in checkpoint 44).** Add explicit main-app debug-only
   localhost transport (`10.0.2.2`), a real-project server launcher with trusted
   server credentials and matching token verification, and operation/outbox
   workers. Keep keys out of Flutter, release HTTPS-only and synthetic tools
   locked to demo projects. Handle an unavailable localhost service truthfully.
   This was not yet implemented by checkpoint 42; checkpoint 44 supplies it.
2. **Verify real-project activation coherently (advanced in checkpoint 44).** Inspect deployed rules/indexes,
   admin access, driver grants and required catalogue/run data; prepare backups
   and any legacy reward/schema baseline before switching v2 writes. Align the
   real server, rules and main-app configuration, without resetting data or
   retroactively banning accounts. Existing local tests do not prove this gate.
3. **Finish account/admin management.** Add trusted Auth disable/enable,
   refresh-token revocation, reviewed deletion retaining necessary audit/history,
   and dedicated manual-restriction appeals. Complete remaining admin query
   pagination. Existing manual suspension/restoration and report-dispute appeals
   are already implemented; they are not the same as Auth lifecycle controls.
4. **Supply and validate real fare/route/ETA data.** Review/import applicable
   official tariff and stop-stage mappings, reviewed geometry and real vehicle
   information; measure predictions against actual journeys and tune ETA from
   sufficient samples. Editors and baseline algorithms exist; real data coverage
   and measured accuracy are still outstanding.
5. **Finish language and device QA.** Translate remaining existing-screen text,
   obtain fluent Sinhala/Tamil review, and check TalkBack, large text, physical
   background GPS, screen lock/process loss, offline/reconnect and two-device
   assistance/handover behavior.
6. **Real push delivery tests (explicitly deferred).** Configure the intended FCM
   project/provider and verify actual notification receipt, tap routing and token
   lifecycle. Simulated provider tests are not real device delivery evidence.
7. **Final migration/release.** Complete required calendar-template lineage and
   reviewed legacy-data handling (without inventing missing saved history), run
   backup/migration/rollback exercises and final end-to-end checks. Build the
   main APK at final delivery. Hosted Functions/billing and production release
   are later decisions, not prerequisites for all remaining source work.

These are work areas, not seven equally sized implementation tasks. Next action
is item 1; the accepted mixed backend setup still needs code and verification.
No app source, rules, production records, billing or APK was changed by this
planning update.

## 44. Implementation checkpoint: main app + real Firebase + localhost runtime

Implemented/verified on 2026-10-17, Asia/Colombo:

- Added explicit `LOCAL_API=true` + `MODERATION_V2=true` main-app debug routing
  to the computer through `http://10.0.2.2:8788`. Real Firebase options remain
  unchanged. The synthetic demo backend stays separately guarded on 8787.
  Arbitrary HTTP origins and mixing real-localhost/synthetic modes are rejected;
  release/profile cannot use localhost. Android network security enables
  cleartext only for the emulator alias in that debug configuration, with the
  main application ID retained and release HTTPS-only.
- Added `.vscode/launch.json` for the main emulator application and a dedicated
  loopback-only real-project launcher. Existing trusted Firebase CLI credentials
  stay in the server process; no key is generated or embedded in Flutter. The
  launcher rejects emulator/other-project overrides, checks real Admin Auth
  access, verifies ID tokens with revocation checking and exposes normal scope
  only. The service remains running on `127.0.0.1:8788` at this checkpoint.
- Added readiness guards for exact reviewed deployed rules, READY composite/
  collection-group indexes and acknowledged v2 config/effective time. Unknown,
  missing, stale or unavailable readiness blocks API operations and workers.
  Policy-date changes require restart. Bounded cursors reconcile handovers,
  assistance and suspended operations, pass unrelated pending jobs and exclude
  Sample paths; no real/simulated push provider is enabled for real accounts.
- Real-project read-only preflight backed up rules/index/config metadata and
  prepared a private reward-baseline proposal. It initially found 8 profiles,
  zero legacy reward counters, no v2 summaries, missing indexes, no dated runs
  and no trusted claim on the requested admin account. No fixture data/reset
  was used to fill those gaps. Route grants and actual timetable/run publishing
  remain administrator data tasks requiring legitimate operating information.
- Granted and read-back verified the previously requested existing account's
  trusted admin claim, preserving its other claims/profile. The user then
  explicitly authorized the Firestore rules/index update. Applied only that
  Firestore deployment: the reviewed rules, 15 composite indexes and one
  collection-group field index. No Functions or billing change was made.
  Deployed rules match the tested source; indexes reached READY before activation.
- Prepared/verified an activation plan, then transactionally enabled normal-scope
  v2 moderation/assistance with an authoritative server policy timestamp, audit
  and rollback metadata. All 8 profiles' zero legacy counters/no existing v2
  summaries were freshly checked. No profile, balance, strike, UID or historical
  report was reset or rewritten. Nonzero/invalid/existing migrated baselines
  require separate review; automatic retroactive bans are not introduced.
  Retrying activation returned duplicate with the original timestamp unchanged.

Validation: **726 full Flutter tests passed**, **4 build-mode-specific tests
skipped in the ordinary build** (`phase29-full.log`). Explicit real-Firebase
localhost defines executed the applicable transport/config/client/admin UI tests:
**28 passed** (`phase29-main-localhost-tests.log`); ordinary focused run **20
passed** (`phase29-targeted.log`). Full analyzer **No issues found**
(`phase29-analyze.log`). Final isolated rules/backend/API/provider/readiness/
activation suite: **152 passed** (`test/security/phase29-final.log`,
`demo-phase29-localhost-final`, port 8088); final standalone focused backend run
**24 passed** (`phase29-backend-final.log`). Test resets only targeted that
separate demo project, never the real project.

A verification-only Gradle task checked the main ID and debug/release transport
policies (`phase29-gradle-localhost.log`); XML parsed with debug cleartext limited
to `10.0.2.2`. No APK was assembled. Real read-back and a non-mutating loopback
probe returned `ready:true`, the expected project and 401 rejection for missing/
invalid Firebase tokens (`phase29-shared-final-preflight.log`,
`phase29-shared-final-verify.log`). Actual Admin SDK read/write credentials were
exercised by the real config transaction; no actual passenger report, vote or
assistance was fabricated for a positive UI test. No native walkthrough was run.

Evidence/recovery: `phase29-shared-rules-index-deploy.log`,
`phase29-shared-rules-verify.log`, `phase29-admin-claim-applied.log`,
`phase29-activation-applied.log` and `phase29-activation-retry.log`. Private
before/after records are under `.private/shared-v2-preflight/`,
`.private/shared-v2-activation/` and `.private/admin-setup/`. See
[main app with real Firebase and localhost](localhost-real-firebase.md) for
startup, launch profile and recovery guidance. Old direct v1 report/assistance
writes are now blocked deliberately; use the main v2 localhost configuration
with the server running. Refresh login to receive the new administrator claim.

No APK build/install/uninstall, Functions deployment, billing upgrade, real FCM
send, synthetic real-project seed or database reset occurred. Shared changes
were limited to the requested admin claim, approved rules/indexes and audited v2
activation metadata; existing user balances/history were preserved.

### Next remaining work after checkpoint 44

1. Auth disable/enable, refresh-token revocation and reviewed deletion progressed
   in checkpoint 45 below. Dedicated manual-restriction appeals and remaining
   admin pagination remain.
2. Admin-reviewed real route grants/physical bus information/dated services;
   official fare-stage imports, geometry coverage and measured ETA calibration.
3. Remaining screen translations, fluent Sinhala/Tamil review, native TalkBack,
   background GPS/offline/process-loss and two-device end-to-end validation.
4. Real FCM/device delivery remains deferred. Complete the remaining calendar/
   legacy-history review and final backup/migration/rollback exercises; build
   the main APK at final delivery. Hosted Functions/billing stays deferred.

## 45. Implementation checkpoint: Auth lifecycle and reviewed deletion

Implemented 2026-10-17 in the main app and real-Firebase localhost backend:

- Admin account controls now offer reasoned disable/enable, session revocation,
  deletion request/rejection and reviewed deletion. Self and trusted admin
  targets are protected; Sample/Test cannot mutate shared Auth identities.
- Durable transactional requests, revisions, operation IDs and audit receipts
  distinguish pending/review-required from completed. Pending jobs resume in
  the localhost worker. Failed/ambiguous effects retain access gates; explicit
  reconciliation reuses the same operation and avoids repeating acknowledged
  effects. Unproven processing jobs remain blocked for inspection.
- Disabling immediately blocks authenticated operations before the Auth effect.
  API and Firestore enforce server-owned session cutoffs, including root session
  restrictions in Sample/Test. Enabling preserves manual/community bans and
  requires a new sign-in for revoked sessions. Existing operation reconciliation
  handles suspended drivers, GPS, locks and assistance.
- Deletion requires a pending review, disabled Auth, no active operation lock,
  exact UID and final UI confirmation. Auth deletion anonymizes the private
  profile and deactivates driver access; shared reports/trips/ledger/audit and
  their references are retained. This does not claim complete historical
  content/photo/private-evidence erasure. See
  [Auth lifecycle and recovery](auth-account-lifecycle.md).
- English/Sinhala/Tamil controls use the existing theme. Automated coverage
  checks reason/confirmation, ambiguous retries, account changes and 320dp/200%
  text. Fluent translation and native device review remain outstanding.

Validation: **733 Flutter tests passed, 4 skipped** (`phase30-full-tests.log`);
**15 main-configuration tests passed, 2 skipped** (`phase30-main-mode-tests.log`);
analyzer **No issues found** (`phase30-analyze.log`). **161 isolated backend/rules
tests passed**, followed by actual Admin Auth SDK disable/enable/revoke/delete
and real emulator ID-token verification using synthetic guarded demo accounts
(`test/security/phase30-integration.log`). This includes failed-effect/receipt
recovery, concurrency, protected actors, direct-write/session rejection and
retained history. No real user was used for destructive validation.

Authorized shared rules were backed up and deployed; read-back matched the
tested source, SHA-256
`17d0d8bf9be6301f29cd3ed4a81128d8e6f8a71befa640ee4d78554752c0bdaa`
(`phase30-rules-backup.log`, `phase30-rules-deploy.log`,
`phase30-rules-verify.log`). Indexes and policy effective timestamp were unchanged.
The verified loopback backend was restarted with the lifecycle worker;
non-mutating verification returned ready and rejected missing/invalid tokens
(`phase30-shared-runtime.log`). An initial transient cloud preflight returned
503; subsequent readiness verification passed without weakening the guard.

No actual shared Auth disable/enable/revoke/delete, APK build/install, Functions
deployment, billing change, real push send, database reset or synthetic shared
seed occurred. Dedicated manual-restriction appeals and admin pagination remain
the next account-management work; real catalogue/fare/geometry and native QA
gates listed above remain pending.

## 46. Implementation checkpoint: manual appeals and admin user/activity pages

Implemented 2026-10-17 in the main application and localhost trusted service:

- Restricted users can submit a manual-restriction appeal without reopening
  operations, and can read history from Profile. A deterministic author/revision
  key makes retries idempotent and prevents duplicate appeals for one decision.
  Submission itself never restores access. Invalid/revoked Auth is still denied.
- Admin has a private paginated pending queue. Reasoned restore/uphold reviews
  are transactional and audited; self-review/non-admin/restricted reviewers fail.
  Restoration requires the appealed manual revision still to be current. Older
  appeals may be closed without modifying newer access. Accepted appeals clear
  only manual fields, preserving Auth restrictions, community bans and history.
- Admin Users/Activity now read 20-record pages with a 21st lookahead. Users use
  ID cursors; Activity has stable descending timestamp/ID ordering. Driver review
  filters loaded user pages. Counts and search disclose their loaded-page scope;
  empty filtered pages still offer Load more. Failed page loads preserve records,
  refresh/live first-page changes reset extra pages and old requests are ignored.
  Existing catalogue/approval/grant reference listeners remain; this does not
  claim every catalogue dependency read is paginated.
- New controls use existing styling and English/Sinhala/Tamil resources.
  Sinhala/Tamil encoding was corrected before final locale checks; fluent review
  and native accessibility checks remain pending. See
  [manual appeals and admin pages](manual-restriction-appeals.md).

Validation: **741 Flutter tests passed, 4 skipped** (`phase31-full-tests.log`),
analyzer **No issues found** (`phase31-final-analyze.log`), **35 targeted tests
passed** (`phase31-targeted-tests.log`). After final locale regeneration,
**15 main-configuration regressions passed** (`phase31-main-final-tests.log`).
The final isolated backend/rules run passed **166 of 167**, with one existing
unknown-collection denial test failing because the emulator client went offline,
not because access was granted (`test/security/phase31-integration.log`). That
test, the actual manual-appeal privacy/transaction test and all **7** new policy
tests then passed in a focused emulator recheck
(`test/security/phase31-focused-recheck.log`). Earlier full run also passed all
167 before the final queue/older-appeal closure refinement.

The verified real-Firebase loopback process was restarted with the new routes;
readiness and missing/invalid-token rejection passed without user-data writes
(`phase31-shared-runtime.log`). Existing rules already deny direct access to the
new private collection; no shared rules/index/config update was needed. No real
restriction/appeal/Auth mutation, seed/reset, APK build/install, Functions
deployment, billing change or real push send occurred.

Remaining work includes catalogue/dependency scale and wider admin localization,
reviewed real route grants/vehicles/dated services, official fare-stage imports,
geometry coverage/measured ETA calibration, translation review, native/device QA
and final migration/rollback exercises. Real FCM and hosted Functions remain
deferred; build the main APK only at final delivery.

## 47. Implementation checkpoint: catalogue pages and admin language resources

Implemented locally on 2026-10-17 in the main Flutter application:

- Buses, Routes and Bus stops now join Users/Activity in the existing 20-record
  paging flow. First-page listeners are bounded to 21 documents for lookahead;
  catalogue continuation queries use stable document IDs. Loaded-page search,
  retry, deduplication and refresh/in-flight invalidation are retained. Overview
  catalogue counts now disclose that they cover loaded pages.
- Catalogue editors collect complete reference pages for stops/routes/users,
  approval and route-grant selectors. Driver route assignment also reloads all
  eligible route pages. An assigned route outside the visible catalogue page
  displays its ID instead of falsely claiming no assignment. An incomplete
  editor reference load disables Save. Real Firestore reference collection
  rejects account/scope switches and repeated cursors.
- Reference selectors still collect their complete set in memory on demand;
  page reads are bounded, total selector reads/memory are not constant. Existing
  approval/grant listeners and catalogue commit dependency scans remain complete
  reads. Further scaling can replace large selectors with targeted server queries;
  no catalogue references were silently truncated to page one.
- Added **105** English/Sinhala/Tamil entries for navigation, common forms/actions,
  driver review, source review, catalogue fields and parameterized titles. A
  presentation adapter leaves backend enums/IDs and authored catalogue data
  unchanged. Remaining advanced explanatory text, some summaries/validation
  errors and separate admin tools still need localization; this is not a claim
  of fully translated dashboards. Unicode retention and 320dp/200% text checks
  passed; fluent review and native font/TalkBack review remain outstanding.

Validation: **750 Flutter tests passed, 4 skipped** (`phase32-full-tests.log`),
analyzer **No issues found** (`phase32-final-analyze.log`). The earlier focused
run passed **33 tests** (`phase32-targeted-tests.log`); the final full suite also
includes the added beyond-page route-assignment regression. New tests cover
later bus/route/stop pages through an empty search, complete unique references,
the existing route grant outside page one, disabled Save after reference failure
and all three locales at 320dp/200% text. Existing audited admin CRUD, approval,
route assignment and offline regressions passed. See
[catalogue pages and language controls](admin-catalogue-pages.md).

No APK build/install, shared Firebase data/config/rules/index mutation, backend
deployment, billing change or real push send occurred. No rules/index change
was required for these existing document-ID queries. Native admin walkthrough,
remaining translations, real catalogue/fare/geometry provisioning, measured ETA,
device QA and final backup/rollback/release gates remain as described above.

## 48. Implementation checkpoint: advanced admin guidance and validation

Implemented locally on 2026-10-17 in the main app:

- Added **49** English/Sinhala/Tamil resources for advanced catalogue guidance,
  capability versus observed condition, timetable limitations, stop-order tools,
  driver assignment/review guidance, save/load failures and catalogue/profile/
  driver validation. Main-workspace bus/timetable summaries, audit attribution
  and ordered-stop counts now use typed localization; English counts use plurals.
- Required-field and coordinate errors carry presentation codes and field/limit
  metadata through a FormatException subtype, retaining existing diagnostic
  messages. Dependency failures retain StateError compatibility with a typed
  referenced kind. The UI formats known parameters using localized labels rather
  than parsing English. Validation, approval, dependency and authorization rules
  are unchanged. User-authored names/review notes and stable IDs remain original.
- Catalogue editor retains the error object for locale-aware rendering.
  Workspace actions translate known failures and server verification/loading
  states. Existing source/condition warnings remain explicit. Separate admin
  tools, some raw audit/role identifiers and legacy wording still need their
  localization pass; this is not a full-app translation-completion claim.

Validation: **757 Flutter tests passed, 4 skipped** (`phase33-full-tests.log`);
analyzer **No issues found** (`phase33-final-analyze.log`);
the focused run passed **39 tests** (`phase33-targeted-tests.log`). Seven new
tests cover metadata produced by actual validation, unchanged diagnostics,
localized field/limit/dependency values and advanced guidance/stop controls in
all three languages at 320dp/200% text. Sinhala/Tamil Unicode checks passed.
Existing catalogue CRUD/dependencies, route assignment, pagination and account
regressions passed. Fluent translation and native font/TalkBack review remain
pending. See [advanced catalogue guidance and validation](admin-advanced-localization.md).

No APK build/install, shared Firebase mutation, rules/index change, server
deployment, billing change or push send occurred. Real catalogue provisioning,
official fare data/geometry, measured ETA and native/device release gates remain.

## 49. Implementation checkpoint: scheduling tools localization and load states

Implemented locally on 2026-10-17 in the main app:

- Added **37** English/Sinhala/Tamil scheduling resources. Dated-departure
  publication/cancellation, start-window/reschedule guidance, service date,
  Colombo departure, run status, late-start label and stop-time snapshot are
  localized. Locale formatting retains Colombo civil fields and overnight dates;
  original driver/public reasons and persisted schedule identities stay unchanged.
- Known scheduling/calendar policy failures now use the shared presentation
  adapter. Calendar action failures retain and display their translated specific
  reason alongside recovery guidance. Unknown run/calendar states do not claim
  scheduled/completed/retired status. Existing calendar weekday/date limits,
  idempotent materialization, replacement snapshots and start boundaries remain
  unchanged; opening a screen does not create runs.
- Dated departures distinguish loading, empty and unavailable. Actions wait for
  the load to settle, failed reloads clear old run/note rows, and late older
  reload results cannot overwrite a newer request. Confirmed writes still rely
  on the existing service acknowledgement.

Validation: **767 Flutter tests passed, 4 skipped** (`phase34-full-tests.log`);
analyzer **No issues found** (`phase34-final-analyze.log`);
**25 targeted scheduling tests passed** (`phase34-targeted-tests.log`). Ten new
tests cover three locales at 320dp/200%, unchanged driver reason text, unknown
states, stale-calendar rejection without generated runs and loading failure
versus empty presentation. Existing dated publish/cancel, recurring generation/
retirement, overnight, idempotency and saved replacement regressions passed.
Sinhala/Tamil resources retained Unicode; fluent terminology/native font and
TalkBack review remain pending. See
[admin scheduling language and loading states](admin-scheduling-localization.md).

No APK build/install, shared Firebase data/rules/index/config mutation, backend
deployment, billing change or real push send occurred. Fare/geometry tools and
remaining admin/operational localization are separate follow-up work; reviewed
real data, measured ETA, device QA and final release gates remain outstanding.

## 50. Implementation checkpoint: fare/geometry admin language and failures

Implemented locally on 2026-10-17 in the main app:

- Added **45** English/Sinhala/Tamil resources for fare/geometry imports,
  preview metadata, publication status and known validation/review failures.
  Fare previews label route/class, mapping dates, source, versions, buses and
  directed stage amounts. Geometry previews label route/version, source and
  ordered stop/distance information. Locale date/currency/distance formatting
  changes presentation only; stored IDs, amounts, mappings and coordinates stay
  unchanged. Unknown fare states do not claim published/archived status.
- Both tools retain failures for locale-aware rendering. Known service/parser
  reasons accompany generic recovery guidance; arbitrary raw JSON diagnostics
  are not echoed as error text. Geometry errors now follow locale changes, with
  geometry-specific recovery text instead of captured fare wording. Failed fare
  list loading no longer also claims a confirmed empty catalogue.
- Review/reason gates, immutable fare IDs, explicit bus mappings, data-mode
  isolation, route/stop consistency and geometry version requirements remain
  enforced by the existing services. Failed publish/withdraw requests retain
  their draft and do not show successful acknowledgement. This work imports no
  official tariffs or actual road geometry and makes no new ETA accuracy claim.

Validation: **775 Flutter tests passed, 4 skipped** (`phase35-full-tests.log`),
analyzer **No issues found** (`phase35-final-analyze.log`), **34 targeted tests
passed** (`phase35-targeted-tests.log`). Eight new tests cover invalid minor-unit
fare rejection and duplicate geometry version rejection in all three languages,
no writes on failure, unknown/unavailable catalogue state, locale changes after
an error and hidden raw parser diagnostics. Existing reviewed publication,
archive/withdraw/retry, passenger fare/geometry and 320dp/200% preview checks pass.
Sinhala/Tamil Unicode checks passed; fluent terminology and native font/TalkBack
review remain pending. See
[fare and geometry admin language pass](admin-fare-geometry-localization.md).

No APK build/install, shared Firebase mutation, rules/index/config change,
backend deployment, billing upgrade or real push send occurred. Remaining
operational/admin wording, reviewed real data imports, measured ETA, native/
device QA and final backup/rollback/release gates remain separate work.

## 51. Implementation checkpoint: review and trip-handover presentation

Implemented locally on 2026-10-17 in the main app:

- Added **13** English/Sinhala/Tamil resources for specific administrative
  review/access/session rejection messages and run/driver/evidence identifiers.
  Community vote evidence uses existing localized True/False labels, preserving
  original IDs, backend vote values and authored reasons. Community votes still
  do not establish objective factual truth.
- Known permanent-ban/report review states have explicit presentation mappings.
  Unknown states show status unavailable rather than pending/unreviewed. Report
  decision controls open only for supported pending/unreviewed states; permanent
  bans still require an explicit pending-case review. These client guards do
  not replace or modify trusted backend authorization/decision transactions.
- Known rejection codes now distinguish self-review, missing authority,
  invalid/changed sessions, restrictions, already decided/unavailable reviews
  and request conflicts. Existing stale-evidence/pending-appeal/protected-admin
  messages retain priority. Failed operations loading no longer also claims an
  empty active-trip list. Reason/revision gates and immutable handover retries
  remain unchanged.

Validation: **783 Flutter tests passed, 4 skipped** (`phase36-full-tests.log`);
analyzer **No issues found** (`phase36-final-analyze.log`);
**26 targeted tests passed** (`phase36-targeted-tests.log`). Eight new tests
cover localized community evidence, specific review wording and unknown-ban
states in three locales at 320dp/200%, unknown report state without decision
controls and failed operations load without a false empty state. Existing
report appeal, mandatory permanent-ban approval/pending-appeal gates, revision
rechecks and acknowledged/retried handover regressions pass. Sinhala/Tamil
Unicode checks passed; fluent terminology/native font/TalkBack review remains
pending. See [review and trip-handover presentation](admin-review-presentation.md).

No actual moderation/appeal/handover/Auth mutation, shared Firebase write,
rules/index update, backend deployment, billing change, real push send or APK
build/install occurred. Remaining profile/operational wording and native/device
QA are separate work, alongside reviewed real data, measured ETA and final
backup/rollback/release gates.

## 52. Implementation checkpoint: Profile and shared sign-out localization

Implemented locally on 2026-10-17:

- Profile roles, personal-information labels, settings/support links,
  contribution summaries and edit-sheet labels/validation now use generated
  English/Sinhala/Tamil resources (45 resources per locale). Profile values,
  stored role enums and signed contribution totals remain unchanged.
- Unacknowledged profile saves show a localized retry message without exposing
  internal exceptions or claiming success. Unsupported links retain a localized
  future-update message. Profile self-service deletion explicitly says it is
  unavailable here; administrator-reviewed deletion is a separate workflow.
- The shared sign-out confirmation localizes draft/photo cleanup disclosure,
  cancellation and confirmation. Home, Profile and Driver capture outcome
  wording before sign-out changes the account locale. Existing draft cleanup,
  Auth and trip behavior is unchanged.
- Profile edit/header/email, sign-out and badge layouts wrap at narrow widths
  and large text. The fabricated fixed “9 more badges” label is replaced with
  a badge-details label. Existing theme and high-contrast styling are retained.

Validation: **792 Flutter tests passed, 4 skipped** (`phase37-full-tests.log`);
analyzer **No issues found** (`phase37-final-analyze.log`);
**25 targeted tests passed** (`phase37-targeted-tests.log`). Nine new tests cover
all three locales at 320dp/200%, high contrast, untouched profile values,
negative points, unavailable deletion, required names, failed saves and both
sign-out decisions. Sinhala/Tamil resource Unicode checks passed. See
[Profile and shared sign-out presentation](profile-localization.md).

No shared profile/Auth/deletion mutation, backend deployment, rules/index
update, billing change, real push send or APK build/install occurred.
Remaining dashboard/operational wording, fluent Sinhala/Tamil review and native
font/TalkBack/device QA remain separate work, alongside reviewed real data,
measured ETA and final backup/rollback/release gates.

## 53. Implementation checkpoint: driver operational localization

Implemented locally on 2026-10-17:

- Driver approval/route gates and dashboard wording now use generated
  English/Sinhala/Tamil resources (180 additions per locale), including dated
  departures, late reasons, start/stop/departure controls, GPS publication,
  vehicle observations, route progress, timetable/ETA labels, delay sheets and
  legacy assistance summaries. The foreground tracking notification captures
  the locale used when tracking starts.
- The main dashboard uses reusable presentation widgets for dated runs, trip
  controls, GPS/vehicle status, late reasons and delay notices. Existing service
  authorization, acknowledged writes, operation epochs, route grants, start
  boundaries and GPS subscriptions remain in their existing operational paths.
  No alternative app or test APK was introduced.
- Local/pending/stale GPS and acknowledged shared data retain distinct wording.
  Failed writes use localized retry messages without exposing raw exceptions.
  Unknown run/countdown states show unavailable wording. Driver/rider names,
  stop/route data, IDs, boolean observations, occupancy values and published
  delay reasons retain their original backend values. Delay selections survive
  changing the UI locale while the sheet is open.
- ETA presentation retains the existing calculator's estimates and evidence
  distinctions; no accuracy/traffic improvement is claimed. Time-of-day uses
  Material localization and other-day arrivals keep explicit dates. Legacy
  assistance rows use explicit Colombo creation timestamps and existing
  assistance type/status translations.

Validation: **819 Flutter tests passed, 4 skipped** (`phase38-full-tests.log`);
analyzer **No issues found** (`phase38-final-analyze.log`);
**71 targeted tests passed** (`phase38-targeted-tests.log`). Twenty-seven new
tests cover all three locales, 320dp/200% core controls, exact -5/+30-minute
boundaries, busy/read-only states, stable values, unavailable vs empty runs,
unknown contracts, stale GPS, late-reason cancellation and locale changes in
the delay sheet. Existing approval/route withdrawal, transactional delivery,
run lifecycle and delay regressions pass. All 180 resource entries passed
Unicode checks. See [driver operational presentation](driver-localization.md).

No actual bus operation, shared Firebase/Auth mutation, backend deployment,
rules/index update, billing change, real push send or APK build/install
occurred. Fluent Sinhala/Tamil review and full native dashboard/font/TalkBack,
keyboard and background-GPS testing remain release work. Other screens such
as the shared Add Station editor retain their own localization scope; this
checkpoint does not claim whole-app translation completion. Reviewed real
data, measured ETA, deferred push/device checks and final backup/rollback/
release gates remain outstanding.

## 54. Implementation checkpoint: password recovery localization

Implemented locally on 2026-10-17:

- Forgot Password, Reset Password and Password Updated use generated
  English/Sinhala/Tamil resources (47 additions per locale), including form
  instructions, validation, visibility tooltips, strength feedback, reset-link
  failures and provider-code outcomes. Unknown provider errors use a localized
  retry message instead of raw server text. Password strength feedback is also
  localized in other hosts of the shared indicator.
- The existing validators, reset-code verification and password-confirmation
  sequence remain unchanged. Missing codes never contact Auth; success is
  shown only after confirmation returns. The production service remains the
  default, with optional service injection for isolated UI fixtures.
- Reset-email acknowledgement retains the actual submitted address even if
  the field changes while delivery is pending. Resend retains its existing
  return-to-form flow and retry behavior. Headers/actions/security notes wrap,
  shared auth validation errors allow multiple lines, and the final success
  card scrolls at large text sizes.

Validation: **834 Flutter tests passed, 4 skipped** (`phase39-full-tests.log`);
analyzer **No issues found** (`phase39-final-analyze.log`);
**29 targeted tests passed** (`phase39-targeted-tests.log`). Fifteen new tests
cover all three locales at 320dp/200% text, high-contrast missing-link handling,
required/mismatched fields, original submitted email, resend/retry, delayed
acknowledgement, failed confirmation without success and safe error fallbacks.
Existing reset-link parsing and shared touch-target regressions pass. All 47
resource entries passed Sinhala/Tamil Unicode checks. Fluent review and actual
email delivery are not inferred from these tests.

No real email, password/Auth mutation, shared data write, deployment, billing
change or APK build/install occurred. Fluent Sinhala/Tamil review and native
font/TalkBack/keyboard and actual reset-email/deep-link delivery checks remain
release work. Other untranslated screens, reviewed real data, measured ETA,
deferred push/device checks and final backup/rollback gates remain separate.
See [password recovery presentation](password-recovery-localization.md).

## 55. Implementation checkpoint: passenger Home localization

Implemented locally on 2026-10-17:

- Passenger Home greetings, quick actions, drawer/desktop navigation, report
  previews and recent-journey wording use generated English/Sinhala/Tamil
  resources (44 additions per locale), reusing existing shared role/settings
  labels. Navigation retains stable internal keys. Names, report descriptions
  and saved endpoint text remain original data.
- Report/journey age labels use localized plurals. Hidden/disputed reports
  still pass through the existing visibility/freshness filter and disappear
  on streamed updates. Delivered report errors and recent-journey waiting,
  failed and empty snapshots have distinct wording. Repository offline/cache
  fallbacks are unchanged; an upstream emitted empty fallback is not claimed
  to carry provenance the widget does not receive.
- Header branding, drawer role/header and report headings/vote summaries wrap
  at narrow widths and large text. Standalone Home's Profile tab now passes
  the same profile snapshot as its avatar entry. The main app uses its existing
  repositories; optional stream arguments support isolated widget fixtures.

Validation: **852 Flutter tests passed, 4 skipped** (`phase40-full-tests.log`);
analyzer **No issues found** (`phase40-final-analyze.log`);
**30 targeted tests passed** (`phase40-targeted-tests.log`). Eighteen new tests
cover all three locales, 320dp/200% text and high contrast, desktop Profile
navigation, locale changes with preserved saved endpoints, original report
text, live five-False hiding, unavailable-to-empty stream recovery and relative
age boundaries. Existing Home/accessibility regressions pass. All 44 resource
entries passed Sinhala/Tamil Unicode checks.

No real report/journey/profile mutation, shared Firebase write, deployment,
billing change, push send or APK build/install occurred. Fluent Sinhala/Tamil
review and native font/TalkBack/device QA remain outstanding, as do remaining
screen translations, reviewed real data, measured ETA and final backup/rollback
gates. Nested saved/assistance panels retain their separate localization scope.
See [Passenger Home presentation](home-localization.md).

## 56. Implementation checkpoint: registration and onboarding localization

Implemented locally on 2026-10-17:

- Registration labels, validation, social-provider placeholders/errors and all
  three onboarding pages now use generated English/Sinhala/Tamil resources
  (43 additions per locale), reusing shared recovery/profile wording. Unknown
  provider errors show localized retry guidance; diagnostics retain codes or
  exception types rather than raw provider messages.
- Registration still submits the existing passenger/contributor/operator
  values and navigates only after the existing AuthService result, using its
  returned role. Driver approval and backend authorization are unchanged.
  Google/Apple sign-up remain future-update placeholders. Optional service
  injection supports isolated UI tests without creating real accounts.
- Onboarding explanations/headings scale and scroll. Decorative illustration
  text is bounded and excluded from semantics; scalable page copy retains the
  example/preview, unavailable voice guidance, operator-response and
  acknowledged-publication disclosures. No new live data is invented.
- Reduced-motion Next uses an immediate page jump instead of a zero-duration
  animation that triggered a framework assertion. Normal Next, Skip and
  Get Started keep their destinations. Small large-text wrapping fixes were
  also applied to the destination Login password/help/divider and Preferences
  section heading; those screens retain their broader translation scope.

Validation: **867 Flutter tests passed, 4 skipped** (`phase41-full-tests.log`);
analyzer **No issues found** (`phase41-final-analyze.log`);
**32 targeted tests passed** (`phase41-targeted-tests.log`). Fifteen new tests
cover all three locales, 320dp/200% text, high-contrast 320x800 Skip, all three
onboarding pages, reduced-motion Next/Get Started, required fields, failed
registration without routing, reporter acknowledgement/routing and social
placeholders without account creation. Existing registration/profile
preservation and touch-target regressions pass. All 43 resource entries passed
Sinhala/Tamil Unicode checks.

No real registration/Auth mutation, shared Firebase write, backend deployment,
billing change or APK build/install occurred. Existing validation rules are
unchanged, including the legacy Latin-letter full-name pattern: Unicode name
acceptance remains a separate change. Fluent Sinhala/Tamil review, native
font/TalkBack/device QA, remaining screen translations, reviewed real data,
measured ETA and final backup/rollback/release gates remain outstanding.
See [registration and onboarding presentation](registration-onboarding-localization.md).

## 57. Implementation checkpoint: Unicode personal-name validation

Implemented locally on 2026-10-17:

- Registration accepts Unicode letters and combining marks, including Sinhala
  and Tamil names and Indic joiners used in conjuncts. Spaces, apostrophes,
  periods and hyphens remain supported, including common typographic variants.
  The minimum is two visible grapheme clusters with at least one letter.
- Punctuation-only names, orphan combining marks, digits, emoji and embedded
  control/unsupported format characters are rejected. The existing outer trim
  remains; no transliteration, normalization or rewriting is applied to names.
  This does not claim identity verification or detection of similar names.
- The already-locked `characters` 1.4.1 package is now a direct dependency for
  grapheme counting. Name validation guidance in all three locales describes
  the supported punctuation. Existing profiles, passwords, emails, role values
  and backend rules remain unchanged. This supersedes checkpoint 56's
  Latin-letter-only name limitation.

Validation: **873 Flutter tests passed, 4 skipped** (`phase42-full-tests.log`);
analyzer **No issues found** (`phase42-final-analyze.log`);
**27 targeted tests passed** (`phase42-targeted-tests.log`). Six new tests cover
Sinhala/Tamil names and conjuncts, decomposed accents, typographic punctuation,
grapheme-based minimum length, invalid controls/marks/digits/emoji and unchanged
name submission from the registration form in all three locales. Existing role,
registration acknowledgement, profile-preservation and onboarding tests pass.
The dependency change resolved offline from the existing package cache
(`phase42-pub-get.log`); localized validation-message Unicode checks passed.

No real registration/profile/Auth mutation, shared Firebase write, deployment,
billing change or APK build/install occurred. Fluent name/terminology review,
native fonts/TalkBack/device QA, remaining Login/Settings translations,
reviewed real data, measured ETA and final backup/rollback/release gates remain
outstanding. See the updated [registration presentation](registration-onboarding-localization.md).

## 58. Implementation checkpoint: Login and accessibility Settings localization

Implemented locally on 2026-10-17:

- Login and Accessibility Preferences now use English/Sinhala/Tamil resources
  for their remaining fixed labels, validation, provider failures, tooltips,
  switch semantics and save feedback. Added 46 entries per locale, reusing
  existing shared resources. Unknown login failures use localized retry
  guidance without exposing raw provider messages.
- Login retains the existing trusted admin-claim check and role routing,
  navigating only after its authentication/profile checks finish. Optional
  AuthService injection supports isolated fixtures; production uses its
  existing service. Biometric/Google buttons remain future-update placeholders.
- Settings keeps account/device/guest scope explicit. Existing supported
  toggle setters and Save persistence are unchanged; Save feedback/navigation
  waits for acknowledgement and is suppressed after an account change.
  Failed saves retain the screen with retry guidance. Temporary search drafts
  remain separate. Unsupported controls stay disabled with localized reasons.
- Category headings, password/forgot-password controls, buttons and target-size
  feedback accommodate wrapped translations and 200% text using the existing
  theme and minimum touch sizes.

Validation: **889 Flutter tests passed, 4 skipped** (`phase43-full-tests.log`);
analyzer **No issues found** (`phase43-final-analyze.log`). **26 focused tests
passed** (`phase43-targeted-tests.log`), including 16 new tests covering all
three locales at 320dp/200% text, login validation/acknowledgement/errors,
disabled controls, delayed/failed Settings writes and account switching during
a save. Final target-size feedback wrapping was checked in the focused suite
after the full run. New-resource Unicode and fixed Settings label mapping
checks passed.

No real Auth/profile/Firestore mutation, deployment, provider activation,
billing change or APK build/install occurred. This does not claim every app
screen is localized. Fluent Sinhala/Tamil review, native font/TalkBack/device
QA, remaining screen translations, reviewed real data, measured ETA and final
backup/rollback/release gates remain outstanding. See
[Login and Settings presentation](login-settings-localization.md).

## 59. Implementation checkpoint: passenger Search localization

Implemented locally on 2026-10-17:

- Passenger Search, stop selection, time/date options and temporary-needs
  controls use English/Sinhala/Tamil resources (64 additions per locale).
  Selected-stop/time/date messages have typed parameters, active needs use
  plurals, and displayed dates use Material localization. Original catalogue
  names, stable IDs and matching/filter keys remain unchanged.
- Trusted-time synchronization, the rolling boarding window, dated/active-run
  matching and Results navigation retain their existing behavior. Needs edits
  and reset remain temporary and never persist to Settings. My Location still
  offers nearby stops and waits for explicit selection; no additional location
  collection or tracking was added.
- The existing microphone-labelled action only offered manual suggestions.
  Its icon/wording now describe suggested stops and explain that voice
  recognition is unavailable. A chosen stop is acknowledged as Selected,
  without the previous fabricated Listening/Recognized wording. No speech
  provider was enabled. The refresh tooltip describes fetching catalogue data.
- Controls and headings wrap at large text sizes; needs/time sheets scroll,
  and action buttons retain minimum heights while accommodating translations.
  Switch tiles have a Material surface for visible feedback. Existing theme
  styling and navigation destinations are retained.

Validation: **898 Flutter tests passed, 4 skipped** (`phase44-full-tests.log`);
analyzer **No issues found** (`phase44-final-analyze.log`). Nine new widget
tests cover all three locales at 320dp/200% text, high-contrast needs editing,
original stop names, explicit nearby-stop choice, temporary needs/reset,
time-window wording and truthful manual suggestions. Existing boarding-window,
dated-search, nearby-stop and account/draft tests also pass. New-resource
Sinhala/Tamil script and Unicode checks passed.
The final focused Search/draft/nearby/dated-run suite passed **30 tests**
(`phase44-search-regressions.log`).

No real GPS/Auth/Firestore mutation, deployment, provider activation, billing
change or APK build/install occurred. Fluent translation review and native
font/TalkBack/device QA remain required. Results, Bus Details and other nested
journey/report panels retain their remaining localization scope; this does
not claim complete translation of the passenger journey. Reviewed real data,
measured ETA and final backup/rollback/release gates also remain outstanding.
See [Search presentation](search-localization.md).

## 60. Implementation checkpoint: Results and Bus Details presentation

Implemented locally on 2026-10-17:

- The main Results/Bus Details screens use English/Sinhala/Tamil resources
  for timetable/run states, requirement review, empty/loading/retry guidance,
  selected-segment stops/duration, capability/crowding badges and report
  freshness. Added 94 entries per locale with typed parameters and plural
  counts, reusing shared fare, geometry ETA, save and preference resources.
- Displayed dates use Material localization. Stable IDs, backend run/crowd
  states, original bus/stop/route names and user-authored report text remain
  data. Known boarding-estimate sources are translated at presentation without
  changing source/confidence keys. Report ages reuse the localized age helper;
  freshness continues to use the existing evidence policy.
- Results invites opening bus details without implying that selection starts
  tracking. Requirement review still edits only the current search draft.
  Run matching, GPS freshness, selected timetable/fare segment and optional
  owner-scoped saving retain their existing behavior.
- Standard-size Results rows retain their layout. Narrow large-text layouts
  stack full labels and wrap badges, with existing theme styles and navigation.
  The schedule-summary test now expects Material's locale-aware date format
  instead of the former hard-coded English formatter.

Validation: **904 Flutter tests passed, 4 skipped** (`phase45-full-tests.log`);
analyzer **No issues found** (`phase45-final-analyze.log`). Six new widget tests
cover all three locales at 320dp/200% text, high-contrast Details, timetable
identity, temporary requirement review, scheduled/active/completed run states,
matching GPS, segment-scoped reports, five-False hiding and reports above
optional Save Trip. Opening/inspecting Details performs zero journey writes.
Existing save/retry, fare, ETA, boarding-window and account tests pass. All 94
new keys have Sinhala/Tamil resources and passed Unicode/script checks.

No real GPS/Auth/Firestore mutation, deployment, provider activation, billing
change or APK build/install occurred. Remaining nested evidence explanations,
map/progress panels and report detail/actions require further localization;
this does not claim complete translation of every child widget. Fluent
Sinhala/Tamil review, native font/TalkBack/device QA, reviewed real data,
measured ETA and final backup/rollback/release gates remain outstanding.
See [Results and Details presentation](results-details-localization.md).

## 61. Implementation checkpoint: nested evidence, ramp and map presentation

Implemented locally on 2026-10-17:

- Accessibility Evidence, Vehicle Ramp, Selected Segment Map and the published
  timetable notice use English/Sinhala/Tamil resources for their remaining
  fixed labels. Added 48 entries per locale with typed attribution, source and
  timestamp parameters and plural confirmation counts. Existing unknown,
  localized relative-age and geometry ETA resources are reused.
- Capability, positive/negative observations, expired checks and unresolved
  barriers retain their existing distinctions and freshness policy. Visibility,
  exact target matching and five-False hiding are unchanged. Evidence section
  storage keys stay stable; actual names and user-authored report text remain
  original. Missing names use localized presentation fallbacks, without storing
  those fallbacks as profile names or displaying private UIDs.
- Map messages explain missing coordinates/road geometry and tile failures;
  current-bus semantics and update wording are localized. Original stop names
  and OpenStreetMap attribution remain intact. Selected-run/GPS validation
  remains in the enclosing Details state. The timetable notice still discloses
  an unassigned vehicle, unknown conditions and unavailable driver assistance.
- Existing numeric recorded timestamps/device-local conversion and operational
  timing rules are unchanged. Existing theme, scalable evidence layout and
  navigation are retained. This pass does not introduce speech, location
  tracking or new verified-accessibility claims.

Validation: **916 Flutter tests passed, 4 skipped** (`phase46-full-tests.log`);
analyzer **No issues found** (`phase46-final-analyze.log`). **31 focused tests
passed** (`phase46-targeted-tests.log`), including 12 new tests for all three
locales at 320dp/200% text and high contrast: unresolved/conflicting evidence,
real-name preservation, plural attribution, expired positive versus unresolved
broken ramp checks, static/current marker semantics, map attribution,
published-source disclosures and ETA target preservation. The full run also
checks the localized tile-failure retry label. All 48 resource entries passed
locale completeness and Sinhala/Tamil Unicode/script checks.

No real GPS/Auth/Firestore mutation, deployment, billing change, push send or
APK build/install occurred. Test user lookups use the in-memory fallback with
no Firebase app initialized; map requests receive test responses. Report
detail/publication/voting and other existing screens retain their remaining
translation scope. Fluent review, native font/TalkBack/device QA, reviewed real
data, measured ETA and final backup/rollback/release gates remain outstanding.
See [Evidence and map presentation](evidence-map-localization.md).

## 62. Implementation checkpoint: Report Details and publication delivery

Implemented locally on 2026-10-17:

- Report Details and the delivery/retry view use English/Sinhala/Tamil resources
  for fixed labels, condition/status wording, legacy mutation receipts, delivery
  states and errors. Added 100 entries per locale with typed count/time/share
  parameters. Original report titles, rider notes, target names and stored
  category/severity keys remain data; known category labels are translated only
  in the view. The existing localized v2 voting controls are reused.
- Hidden-report wording reads the report's policy threshold: v2 five, historical
  v1 three. It explicitly avoids treating a community dispute as proof of false
  conditions. Resolved wording describes the author's observation rather than
  a verified repair; active/expired wording no longer invents live telemetry or
  an archive operation. Backend moderation/reward policies are unchanged.
- Pending/failed/local drafts remain distinct from acknowledged publication.
  Known delivery failures are translated; valid cooldown deadlines retain their
  UTC timestamp. Unknown error text uses generic retry guidance. Draft storage,
  retention, retry identity and account ownership checks are unchanged.
- Share copies localized alert text containing the original condition/target,
  waits for clipboard acknowledgement and handles failure. It no longer claims
  a link was copied. Status/target/category/note/photo labels wrap at large text;
  legacy action buttons retain minimum heights and accommodate their text.

Validation: **934 Flutter tests passed, 4 skipped** (`phase47-full-tests.log`).
After the final photo heading/badge wrapping edits, **49 focused tests passed**
(`phase47-targeted-tests.log`), including 21 new tests across all three locales
at 320dp/200% text and high contrast. Coverage includes original report text,
author vote exclusion, five-vote hiding wording, False-reason validation,
delayed voting/publication receipts, draft account changes, cooldown/error
presentation, delayed clipboard receipts and failed photo previews. Existing
v2, legacy mutation and delivery-layout regressions pass. Analyzer **No issues
found** (`phase47-final-analyze.log`); all 100 resources passed locale
completeness and Sinhala/Tamil Unicode/script checks.

No real Auth/Firestore mutation, live vote/publication, actual clipboard change,
deployment, billing change, push send or APK build/install occurred. Tests use
in-memory storage/streams and mocked HTTP/clipboard responses. The report-entry
form's condition/category catalogue, camera/gallery controls and review dialog
remain the next translation slice. Fluent review, native font/TalkBack/device
QA, reviewed real data, measured ETA and final release gates remain outstanding.
See [Report views presentation](report-views-localization.md).

## 63. Implementation checkpoint: report-entry form localization

Implemented locally on 2026-10-17:

- Report-entry condition/category and crowding choices, photo controls,
  validation, review/summary and failure messages use English/Sinhala/Tamil
  resources (125 additions per locale). Stored option IDs, category, severity,
  subcategory and crowding values remain unchanged. Original catalogue names
  and user-written notes stay data; only their surrounding labels translate.
- Review displays the effective translated choices, original target/note,
  cooldown and public-photo/draft-retention guidance. Editing returns to the
  current form. Submission still uses the existing outbox/acknowledgement flow
  and delivery destination; inspection/review alone never publishes.
- Optional identity/submission/image-picker injection supports isolated tests,
  while production defaults to Firebase Auth, the existing submission singleton
  and ImagePicker. Account changes across review prevent submission and require
  a fresh review; late photo results from another account are discarded. Missing
  sign-in and unknown submission/photo errors use localized guidance. An already
  active submission cannot be launched twice from the same form action.
- Option cards have natural heights, two columns at ordinary sizes and one
  column on narrow large-text layouts. Full labels wrap, photo choices scroll,
  submit/add-photo controls retain minimum heights, and summary/dropdown labels
  fit the existing theme. No camera/gallery or upload provider was activated.

Validation: **955 Flutter tests passed, 4 skipped** (`phase48-full-tests.log`);
analyzer **No issues found** (`phase48-final-analyze.log`). **46 focused tests
passed** (`phase48-targeted-tests.log`), including 18 new tests across all three
locales at 320dp/200% text/high contrast. They cover bus/station payload values,
translated review preserving original notes, validation, delayed publication,
account change during review, every category tab, and mocked camera/gallery
cancel/failure behavior. Existing exact-target and condition/evidence tests
pass. All 125 resources passed locale completeness and Sinhala/Tamil
Unicode/script checks.

No live publication, real Auth/Firestore mutation, camera capture, gallery read,
photo upload, deployment, billing change or APK build/install occurred. Tests
use in-memory catalogue/outbox data and injected publisher/identity/picker
fixtures. Fluent translation review, native fonts/TalkBack/device QA and the
remaining community/outbox/help text still need work, alongside reviewed real
data, measured ETA and final release gates.
See [Report form presentation](report-form-localization.md).

## 64. Implementation checkpoint: Community feed and upload outbox localization

Implemented locally on 2026-10-17:

- Community headings, tabs, actions, target fallbacks, contribution summaries,
  freshness/age and vote/status labels use English/Sinhala/Tamil resources
  (30 additions per locale). Original target names, issues and descriptions
  remain data. Community confirmation is labelled as such rather than Verified;
  report-specific vote thresholds and stored values are unchanged.
- Read failures have explicit unavailable/retry guidance. Empty reports no
  longer imply an accessible or safe corridor. Guests receive sign-in guidance
  in My Reports. Shared cards exclude hidden/disputed/unpublished entries;
  My Reports filters retained snapshots against the current account. Existing
  author review/appeal access remains separate.
- The owner-scoped upload section translates status and retention/retry/removal
  guidance and opens the existing delivery screen with the same submission
  service. Opening an upload never publishes it. Main-app service defaults
  remain in place; optional injection supports isolated tests.
- Tabs and vote/photo/status labels wrap, large-text card headers stack, and
  legacy vote controls retain minimum heights. The existing theme is retained.
  The evidence-clock regression now injects its feed instead of depending on
  an unavailable Firebase fallback.

Validation: **970 Flutter tests passed, 4 skipped** (`phase49-full-tests.log`);
analyzer **No issues found** (`phase49-final-analyze.log`). **44 focused tests
passed** (`phase49-targeted-tests.log`), including 15 new Community/outbox tests
across all three locales at 320dp/200% text and normal/high contrast feed
layouts. They cover failed-versus-empty reads, recovery, original text,
fifth-False hiding, guest guidance, stale account snapshots, private upload
navigation and account cleanup. Existing delivery retry/acknowledgement and
voting regressions pass. All 31 Community/outbox-prefixed resources (including
one pre-existing entry) passed completeness, Unicode and script checks.

No real Firebase/Auth mutation, report publication, deployment, billing change
or APK build/install occurred. Fluent translation review, native fonts/TalkBack
and device QA remain required. Remaining untranslated support/help text,
reviewed real data, measured ETA and final release gates are separate work.
See [Community and outbox presentation](community-outbox-localization.md).

## 65. Implementation checkpoint: localized in-app Help Center

Implemented locally on 2026-10-17:

- Profile -> Support -> Help Center now opens a guide instead of its Coming
  soon message. Eight expandable topics explain search/defaults, optional
  saving, nearby stops, timetable/live position, drafts/publication, community
  voting/disputes, assistance and account review. This adds 17 resources per
  locale and reuses the existing translated Help Center title.
- Guidance distinguishes saving from seat booking, submitted assistance from
  acceptance, local drafts from published reports and community disputes from
  proven false reports. It explains current limitations without claiming a
  support inbox, self-service account deletion or a verified walking route.
- The guide follows existing theme/high-contrast colors, scrolls and wraps
  expanded text. Opening it reads no private account/location/backend data.
  Existing unavailable Profile actions retain their prior status.

Validation: **979 Flutter tests passed, 4 skipped** (`phase50-full-tests.log`);
analyzer **No issues found** (`phase50-analyze.log`). **18 focused tests passed**
(`phase50-targeted-tests.log`), including nine new tests expanding/collapsing
all eight topics in English/Sinhala/Tamil at 320dp/200% text with normal/high
contrast, and navigating from Profile into Help and back. Existing profile,
failed-save and sign-out regressions pass. All 17 added resources passed
Unicode/script checks.

No real Firebase/Auth mutation, report publication, backend deployment, billing
change or APK build/install occurred. Fluent translation review, native font/
TalkBack/device QA, remaining untranslated text, reviewed real catalogue/tariff
data, measured ETA accuracy and final release gates remain separate work.
See [In-app Help Center](help-center.md).

## 66. Implementation checkpoint: rewards and membership localization

Implemented locally on 2026-10-17:

- Rewards & Contributions and Digital Membership Card headings, stats,
  tier/points/identity labels, settings guidance and availability disclosures
  use English/Sinhala/Tamil resources (28 additions per locale). Known tier
  labels translate at presentation; internal tier derivation and stored values
  are unchanged. Unknown custom tiers, member IDs and role labels stay data.
- Negative balances remain signed. The legacy +5 confirmation explanation is
  explicitly historical and confined to its existing legacy branch. The v2
  author-only reward notice and balance refresh behavior remain in place.
  Membership wording refers to the recorded policy rather than implying every
  policy needs manual reconciliation. Redemption remains disabled; no cash,
  voucher, priority support or guaranteed access is promised.
- Headers/buttons use minimum heights, full titles wrap, chips wrap, and
  narrow/large-text membership headers stack. Existing theme and ordinary
  48dp/large-target 60dp button behavior are retained.

Validation: **988 Flutter tests passed, 4 skipped** (`phase51-full-tests.log`);
analyzer **No issues found** (`phase51-analyze.log`). **10 focused tests passed**
(`phase51-targeted-tests.log`), including nine new tests across all three locales
at 320dp/200% text with normal/high contrast. Tests cover signed balances,
translated Bronze/Gold labels, custom identity/tier values, card navigation and
return, and disabled redemption. Existing reward availability and touch-target
tests pass. All 28 added resources passed completeness/Unicode/script checks.

An Android emulator was detected, but no new APK was built/installed and no
native walkthrough of these source changes is claimed. No real Firebase/Auth
or balance mutation, backend deployment or billing change occurred. Fluent
Sinhala/Tamil review and physical-device/font/TalkBack QA remain required;
remaining untranslated text, reviewed real data, measured ETA and release
gates remain separate work.
See [Rewards and membership presentation](rewards-presentation.md).

## 67. Implementation checkpoint: boarding/alighting assistance form localization

Implemented locally on 2026-10-17:

- Assistance selection labels, target confirmation, validation/failure messages,
  boarding/alighting context and unknown/estimated-arrival wording use generated
  English/Sinhala/Tamil resources (23 additions per locale). Existing translated
  assistance labels are reused in review. Original catalogue names remain data;
  submitted assistance IDs and exact bus/run/stop identifiers are unchanged.
- Identity is captured before target lookup/review and checked before enqueue.
  An account change during review requires another review; guests retain the
  sign-in message. Editing review retains selection without sending. Confirmed
  submissions use the existing acknowledged submission/status destination.
- Selection tiles, actions and header use minimum heights, labels wrap and
  narrow/large-text arriving-bus panels stack. Unknown arrival remains unknown;
  estimates are labelled. Driver acknowledgement is still distinguished from
  merely sending the request.

Validation: **997 Flutter tests passed, 4 skipped** (`phase52-full-tests.log`);
analyzer **No issues found** (`phase52-analyze.log`). **14 focused tests passed**
(`phase52-targeted-tests.log`), including nine new tests across all three locales
at 320dp/200% text and normal/high contrast. They cover required selection,
review/edit, stable payloads, exact alighting targets, unknown/estimated arrival
and changed-account rejection. Existing guest, invalid-stop and missing-run
regressions pass. All 23 resources passed Unicode/script checks.

No real Firebase/Auth mutation, assistance request, backend deployment, billing
change or APK build/install occurred. Tests use injected identity, catalogue
and publisher fixtures. Request-status and saved-receipt panel localization
remains a separate next slice. Fluent translation review and physical-device/
font/TalkBack QA, reviewed data, measured ETA and release gates remain required.
See [Assistance form presentation](assistance-form-localization.md).

## 68. Implementation checkpoint: shared navigation and assistance receipts

Implemented locally on 2026-10-17:

- The shared Home/Plan/Community/Profile bottom bar now displays existing
  English/Sinhala/Tamil translations. Canonical tab IDs remain routing keys;
  callbacks, deep links and selected-tab state do not change with language.
  Full labels wrap in a minimum-height/content-sized bar, and the selected
  tab exposes selected button semantics. Theme and icons are retained.
- Assistance request-status and saved-receipt panels use 33 new resources per
  locale for delivery, driver response, retry/cancel, errors and typed route/
  stop summaries. Existing assistance type/state translations also cover
  legacy receipts. Original names and custom assistance types remain data;
  stored IDs, enums and backend policy are unchanged.
- Delivery, driver acceptance and completion remain distinct. Failed retry or
  cancellation cannot claim success; unavailable live streams retain explicit
  last-received wording. Known service messages translate at presentation and
  unknown provider/storage errors use localized generic guidance. Account
  changes hide another owner's receipt details and stale history snapshots.

Validation: **1,012 Flutter tests passed, 4 skipped** (`phase53-full-tests.log`);
analyzer **No issues found** (`phase53-analyze.log`). **24 focused tests passed**
(`phase53-targeted-tests.log`), including 15 new tests across all three locales
at 320dp/200% text with normal/high contrast. Tests cover translated navigation,
canonical callbacks, selected semantics, locale changes preserving selection,
failed/delayed/retried delivery, acceptance/completion, failed cancellation,
saved-receipt errors, original/custom data and account changes. Existing touch-
target and assistance delivery/layout tests pass. All 33 resources passed
Unicode/script checks; Sinhala/Tamil tab labels differ from the English labels.

No real Firebase/Auth mutation, assistance publication, deployment, billing
change or APK build/install occurred. These automated layout/semantics checks
do not replace fluent Sinhala/Tamil review or native font/TalkBack/device QA.
Remaining untranslated text, reviewed real data, measured ETA and final release
gates remain separate work.
See [Navigation and assistance receipts](navigation-assistance-receipts-localization.md).

## 69. Implementation checkpoint: shared language and accessibility coverage

Implemented locally in the main app source on 2026-10-17:

- The remaining catalogue saved/offline/empty/refresh messages, administrator
  access gate, Add Stop dialog, saved-trip controls/recovery, assistance actions,
  live accessibility observations, stop-alert availability and splash wording
  use English/Sinhala/Tamil resources. Retained journey screens also translate
  their fixed labels, dynamic ETA/delay wording and date/time presentation.
  An old unassigned-bus message no longer claims a confirmed seat booking.
  The required Search -> Results -> Bus Details path remains unchanged.
- The app root now uses one effective preference theme. Material buttons,
  icon buttons, app-bar leading controls, inputs, list tiles, chips and dialog
  controls inherit normal 48dp / large-target 60dp minimums. Explicit button
  overrides follow those same minimums. Custom tap regions, switches and chips
  use a shared minimum-size wrapper; navigation labels still wrap and retain
  their canonical routing keys.
- Dropdown rows across admin, driver, report, language and segment selectors
  have variable heights and minimum targets so long translations can wrap.
  Narrow-screen date/time pickers open in localized input mode when large
  targets are enabled. Existing selection bounds, search horizon, saved needs
  and backend IDs/policies are not changed by presentation preferences.
- High contrast is applied to shared controls/cards and remaining custom
  foregrounds, driver delay/status controls, auth inputs and map controls.
  Selected chips retain readable text/checkmarks. Original map tiles and
  evidence photos are retained, with the existing stop-list alternatives.
- Catalogue notices fit in a bounded scrollable region on small screens.
  Failed refreshes expose localized retry guidance. Assistance failures render
  in the current language even if language changes while the error is visible.
  Unknown save/provider errors use localized guidance rather than raw details;
  failed saves/removals still retain the previous acknowledged state and ID.
- Added 198 shared/retained presentation resources per locale. All 1,716 keys
  are present in every locale; the additions passed Unicode/script/placeholder
  checks. Direct fixed-UI-literal inventory retains only intentional brand,
  language-name, ID/example and map-attribution exceptions. Original catalogue
  names, authored/custom descriptions, stable enums and technical identifiers
  remain data, rather than being rewritten or automatically translated.

Validation: **1,033 Flutter tests passed, 4 skipped** (`phase54-full-tests.log`);
full analyzer **No issues found** (`phase54-analyze.log`). **21 new shared UI
tests passed** (`phase54-shared-tests.log`), covering all three locales at 320dp,
200% text, normal/high contrast, reactive 60dp/48dp sizing, inputs/chips/app-bar
controls, stable dropdown selection, dialog targets, catalogue failures/retry,
admin denial, stop-alert semantics, driver acknowledgements, language changes
during failure and dynamic/custom delay reasons. The focused broader run passed
**64 tests** (`phase54-targeted-tests.log`); final Settings/save/shared-control
regressions passed **40 tests** (`phase54-final-regressions.log`). Existing
Settings scrolling and save-failure assertions now cover the enlarged layout
and localized generic errors while preserving their authorization/retry checks.
After the final retained stop-alert text change, **29 shared/legacy UI checks
passed** (`phase54-ui-final-tests.log`). Existing map hosts still emit mocked
tile failures; the full suite passed.

No APK build/install, real Firebase/Auth/report/assistance/catalogue mutation,
shared deployment or billing change occurred. This completes the identified
source-level shared-control localization/accessibility gaps; it is not a claim
of native accessibility certification or completed human translation review.
Fluent Sinhala/Tamil review and physical-device font, TalkBack, focus, picker/
keyboard and screen-size QA remain release gates, alongside the existing real
data, ETA measurement and rollout work.
See [Shared language, contrast and touch preferences](shared-accessibility-localization.md).


## 70. UI corrections from screenshot review

Implemented locally on 2026-10-17:

- Search travel time keeps its icon beside the label/time and a compact trailing Change affordance. Boarding selection shows the station before a readable My Location action.
- Community Report Issue now occupies a reserved bottom action area instead of overlapping empty-state text.
- Profile Edit aligns to the trailing edge. Language selection uses separate selected-value widgets and a non-dense field to avoid clipping padded menu rows.
- Photo upload uses a light icon background with a readable foreground. Report review uses the existing card surface, consistent rounded corners, paragraph spacing and action padding; all disclosure content remains available in the scrollable dialog.

Validation: **72 focused Flutter tests passed** across search, profile, community, report form and shared accessibility/localization (`phase55-ui-tests.log`); analyzer **No issues found** (`phase55-analyze.log`). These are widget checks, not a new physical-device visual walkthrough. No APK build/install or deployment occurred.


## 71. Settings cards and clearer report review

Implemented locally on 2026-10-17:

- Profile Language and Admin console entries match the existing rounded settings cards, circular icons, spacing and typography. Language persistence and admin authorization remain unchanged.
- Report review leads with a selected-target/condition/note summary card. Short public-visibility and same-issue cooldown reminders remain visible. Full privacy, photo consent and draft-storage disclosures are available under an expandable section. Confirm and submit and Edit report use separate full-width actions. Added English/Sinhala/Tamil copy for the shorter reminders and disclosure heading.

Validation: **46 settings/profile/shared tests passed** (`phase56-settings-tests.log`), **18 report-form tests passed** including disclosure expansion in all three locales (`phase57-review-tests.log`); analyzer **No issues found** (`phase56-analyze.log`, `phase57-analyze.log`). Native visual/font review remains pending. No APK build/install, deployment or shared data changes occurred.


## 72. Publication failure diagnosis and actionable retry states

Implemented locally on 2026-10-17:

- Outbox retains stable v2 failure codes and translates service connectivity/configuration, sign-in, permission, account restriction, invalid request and catalogue eligibility failures instead of collapsing all into a generic Failed message. Raw provider messages and report contents remain hidden. Debug output includes only an error code/type.
- V2 service-unavailable failures now remain pending and participate in existing retries. Draft identity, owner isolation and acknowledged publication behavior are preserved.
- Read-only diagnostics found localhost health ready for the intended project and Kankesanthurai stop `ncg_kankesanthurai` marked operator_catalogue/non-demo. No report was submitted or changed to diagnose the screenshot. The older generic failure cannot identify its historical cause; a retry with the updated client is still needed to establish it.

Validation: **43 publication, privacy and localized report-view tests passed** (`phase58-publication-tests.log`), including same-ID recovery from v2 failures. No APK build/install, backend deployment, rules relaxation or shared data mutation occurred.


## 73. Realistic fictional data for main-app walkthroughs

Applied on 2026-10-17 to `sample_test/shared/` in the existing Firebase project:

- Batch `walkthrough_20261017T1200` atomically wrote and read-back verified **470 records**: 14 directions, 22 stops, 42 fictional physical buses, 258 dated runs, 42 reports/publication ledger events, 14 synthetic fare publications, 14 synthetic geometries, five saved trips, four assistance requests and two matched active-trip/GPS/lock scenarios (fresh/stale). Includes working/faulty/unknown equipment and completed/cancelled runs.
- Added an explicit Sample launch option for the same application package. Localhost server was restarted with opt-in `--sample`, preserving normal access. Both scopes are ready. Existing sample-account roles are reused; no new Auth accounts or passwords were created. Eight missing v2 sample summaries received explicit legacy sample baselines, preserving existing summaries and avoiding retroactive strikes.
- Seed tools default to read-only, restrict every write to the Sample prefix, back up target rows, use one atomic fixture commit, preserve activity/operation locks, reject batch replay, and compare normal catalogue/profile/access/config fingerprints. These normal records were unchanged. New synthetic coordinates are approximate anchors, never reviewed stop locations. GPS snapshots age naturally; no guessed animation/heartbeat was added.

Validation: **29 scenario/runtime/API tests passed** (`phase59-backend-tests.log`). A Flutter model/search contract parsed the complete prepared dataset and confirmed Badulla -> Bandarawela also passes wheelchair/step-free filtering (`phase59-model-tests.log`). An attempted emulator moderation suite lacked its Firestore emulator and is excluded from passing counts. No APK build/install, hosted deployment, rules relaxation, billing or normal-record update occurred. The normal launch mode intentionally does not show fictional vehicles; select the labelled Sample profile to inspect them. Real FCM, native device QA and destructive Auth tests are not implied complete.

See [Realistic sample data](realistic-sample-data.md) for launch, scenarios, limitations and repeatable refresh commands.


## 74. Recover the running main app's failed publication

Diagnosed and recovered on 2026-10-17:

- The actual main-app runtime had v2 publication disabled while shared policy denies retired direct writes. Earlier source-only fixes had not changed that installed session's configuration. The encrypted normal outbox still existed, while the separate Sample outbox was empty. No draft files were cleared or merged across scopes.
- Attached specifically to `com.accesstransit.access_transit` (the emulator also has an older validation package), and hot-restarted the existing app with `MODERATION_V2=true` and `LOCAL_API=true`. No APK was built/installed. Verified v2 and localhost flags are true and one owner-visible failed normal-mode draft was loaded.
- Retried that same user-created draft through `ReportSubmissionService.retry`, preserving its ID and owner validation. The app acknowledged publication. Read-back of the corresponding normal Firestore report confirmed policyVersion 2, publicationState published, status active and +10 awarded points. Its removal from the outbox followed acknowledgment, not a reset. Private ID-only receipt is in `.private/publication-recovery/` (ignored). No additional fictional normal report was created.
- Added a source guard: if server policy v2 is active, an unconfigured legacy launch now fails with backend-not-configured before attempting retired direct writes. Its existing localized guidance retains the draft. Normal and Sample drafts remain separate; successful publications leave the draft list and appear in Community. Older drafts already removed under existing sign-out/account-change/expiry policy are not claimed recovered.

Validation: **66 publication/transaction/privacy/localized-view tests passed** (`phase60-publication-recovery-tests.log`), including the v2-active/legacy-client guard with no report/cooldown writes. Full and targeted analyzers found no issues (`phase60-analyze.log`, `phase60-targeted-analyze.log`). This step includes an actual user-requested report retry/read-back, not just a simulated test. The data-preserving hot restart does not update the APK's bundled source; future debug runs should use **AccessTransit: main app, real Firebase + localhost**, or explicitly select the Sample profile for fictional walkthroughs. No rules relaxation, deployment, billing change or new APK occurred.


## 75. Permanent publication startup fix and restore expired live rules

Implemented/verified on 2026-10-17:

- Ordinary main Android debug startup now initializes the agreed real-Firebase localhost v2 connection when no explicit flags/origin were supplied. Explicit configurations, isolated emulator tests, other platforms and release/profile behavior remain separate. The main launch profile is listed first; Sample remains an explicit alternative.
- Shared moderation clients no longer capture an empty endpoint before initialization; unpinned clients resolve the current configured origin per request. Added regressions for an already-constructed client, two successive NEW reports (distinct IDs), photo URL publication and acknowledged outbox removal. The earlier one-draft native retry did not establish this fresh-start behavior.
- Live inspection found a separate rules regression: the deployed release updated at 2026-10-17 16:43:45 UTC contained the 19-line default rules expiring on 2026-09-18. It denied all current client reads/writes and made localhost readiness fail with rules-review-required. This explains an additional active backend failure; it was not repaired by changing client flags.
- Backed up that expired release under `.private/admin-setup/`, confirmed the workspace rules exactly matched the previously verified source, and restored only Firestore rules to `accesstransit-b615b`. Read-back matches the reviewed 1,086-line project source; localhost health is again ready with no reasons. No allow-all permission, index/data/Auth/billing change was introduced.

Validation: **1,037 full Flutter tests passed, 4 skipped** (`phase61-full-tests.log`); **128 isolated Firestore rules/v2 transaction tests passed** (`phase61-rules-tests.log`, demo-phase61-publication on port 8088); analyzer **No issues found** (`phase61-analyze.log`). The initial emulator launch selected Java 8 and stopped before tests; the passing run used installed Android Studio JBR.

Installed-main-app update remains pending the user's reply: an explicit question was sent because their earlier instruction deferred APK builds/installs until final delivery. A same-package debug update with account/drafts preserved was proposed; no separate test package or release APK. No native fresh-photo success is claimed for this step until that update and walkthrough are completed. A hot restart cannot replace old bundled source for future app launches.

## 76. Deploy current rules and update the installed main app

Completed on 2026-10-17 following the user's explicit request to update Firestore and run the app:

- Backed up the live rules and deployed the current workspace `firestore.rules` to `accesstransit-b615b`. Read-back exactly matches local SHA-256 `17d0d8bf9be6301f29cd3ed4a81128d8e6f8a71befa640ee4d78554752c0bdaa`. Localhost real-Firebase health returns ready with no blocking reasons. No Functions, billing or data reset was involved.
- Built and updated the same main debug package using `adb install -r`, with no uninstall/data clear. Cold startup, without extra runtime flags or hot restart, confirms v2 and localhost API are enabled and Firebase sign-in is retained. This completes the installed-main update left pending in checkpoint 75.
- Native verification exposed a repeated account-check/navigation reset. Pending trusted checks now block interaction while retaining the existing Navigator and unsaved screen state. Confirmed restrictions, failed checks and account changes still dispose the protected workspace. Temporary cached Firestore events trigger trusted API verification. The blocked UI has its own Overlay for review/appeal controls.
- The updated app reaches the signed-in Admin console and loads its normal Firestore catalogue. The actual main outbox currently contains no pending drafts; no fabricated normal report or fresh-photo publication was submitted during this verification.

Validation: **1,040 Flutter tests passed, 4 skipped** (`phase62-full-tests.log`), including three new Navigator/state-preservation regressions; **15 focused gate/review tests passed** (`phase62-gate-verified.log`). Debug build succeeded (`phase62-final-debug-build.log`), same-package installation returned Success, and native runtime/account/backend checks passed. Rules source is unchanged from the preceding 128-test isolated authorization run. Analyzer **No issues found** (`phase62-analyze.log`). Real push, release rollout and native fresh-photo publication remain separate validation work.

## 77. Keep verified navigation visible during account rechecks

Implemented on 2026-10-17 after the user reported the account-check page appearing between screens:

- Checkpoint 76 preserved Navigator state but still hid the entire screen on every account revalidation, including lifecycle/Firestore metadata events. For an already verified active account, revalidation now runs in the background without replacing the current screen. Initial verification and account switches remain blocked until verified; a confirmed restriction or failed verification still removes the protected workspace. Backend access checks continue to enforce mutations independently.
- Regression tests now exercise resume plus repeated change events with a pending response, preserving the visible selected route and unsaved input; active, suspended, unavailable and account-switch outcomes remain covered.

Validation: **15 focused tests passed** (`phase63-gate-tests.log`); analyzer **No issues found** (`phase63-analyze.log`); main debug build succeeded (`phase63-debug-build.log`). Updated the same main package with `adb install -r` and cold launched it. Native debug inspection confirms an active account remains ready while an explicit recheck is pending, with no failed state; localhost health remains ready. This is a client navigation correction; Firestore rules and backend permissions were unchanged.

## 78. Match admin screens to the app theme

Implemented on 2026-10-17:

- Added a shared admin scaffold to all ten admin screen files: dashboard, catalogue editor, dated departures, calendars, fare publications, geometry, active operations, ban reviews and account/Auth controls. Uses the existing app palette, navy headings, white rounded cards, outlined fields, consistent button corners and a bounded layout on wider screens.
- Dashboard tabs use a navy selected state; overview and record cards have matching icon containers, clearer navigation arrows, quieter outlines and no raised default Material shadow. Existing localization and accessibility sizing are inherited, including high-contrast borders and large controls.
- No catalogue, authorization or operational policy changes were made.

Validation: **42 admin UI/localization tests passed** (`phase64-admin-tests.log`), covering small layouts, 200% text, high contrast, catalogue edits and scheduling/import/account views; analyzer **No issues found** (`phase64-analyze.log`). Main debug build succeeded (`phase64-debug-build.log`). Widget captures use the test font and are layout evidence only; native rendering is checked on the main emulator installation.

## 79. Finish admin form and dialog presentation

Implemented on 2026-10-17 following screenshots of clipped capability selectors and inconsistent editors:

- Admin dropdown fields now use non-dense selected-value layout, allowing the accessible menu item's actual height instead of clipping its text. This covers catalogue type, route/driver assignment, capability and stop selectors, including admin dialogs.
- Catalogue editors now group identity, accessibility, ordered stops and source review with themed headings/icons. Source explanations wrap, review confirmation uses a padded leading checkbox card, and stop reorder/remove controls use separated outlined buttons. Scheduled time fields include a clock icon. Added an accessibility-section label in English/Sinhala/Tamil.
- All admin dialogs use the shared admin presentation. The admin variants of community report reviews and manual appeals now also use the admin scaffold; their passenger variants retain their existing presentation.
- Added a rendered selected-value bounds assertion at normal/200% text and high contrast. Test scrolling now reaches lazily built fields in the taller accessible form.

Validation: **55 focused admin/review/appeal UI tests passed** (`phase65-ui-tests.log`), plus **6 readable-font capture tests** (`phase65-capture-tests.log`). Inspected normal and large stop-editor previews for selected text and source wrapping. The initial test attempts exposed test scroll assumptions and one incorrect test filename; those runs are not counted as passing. See `phase65-analyze.log` and `phase65-debug-build.log` for final analysis/build. No operational policy or Firestore rules changes.

## 80. Stop transient startup/cache failures flashing as errors

Implemented on 2026-10-17:

- Root cause: admin listeners treated Firestore's initial cached/pending snapshot as an exception, showing a multi-collection error before the subsequent server snapshot automatically cleared it. Added a shared server-snapshot stream that withholds unverified data while synchronizing, reports a 15-second synchronization timeout, preserves actual listener errors, and recovers when server data arrives. Idle verified streams do not time out. Cancellation clears timers.
- Account verification starts directly on authentication instead of relying on a metadata event. Concurrent account checks are coalesced. Transient service/authentication-service failures receive up to two short retries (300ms/600ms), without flashing an error page between attempts. Auth/account denials are not retried as connectivity failures. An initial account remains blocked until verified; sustained failure still removes the protected workspace, and verified accounts retain navigation while rechecking.
- Updated the main debug package using data-preserving `adb install -r`; cold launch reaches Admin console with loaded catalogue, an active verified account and a ready localhost backend. No rules/data/billing update occurred.

Validation: **41 focused stream/account/admin/review tests passed** (`phase66-targeted-tests.log`), including cached-to-server startup, offline deadline, permission denial, recovery, cancellation, retry/coalescing and sustained failure. Analyzer **No issues found** (`phase66-analyze.log`); debug build succeeded (`phase66-debug-build.log`). Full suite initially recorded **1,039 passed, 4 skipped, 4 failed** (`phase66-full-tests.log`). Three fare UI failures were scroll-settle assumptions exposed by the preceding theme work; adding the missing settle made them pass in the additional run. That run has **24 passed, 1 failed** (`phase66-additional-tests.log`): the pre-existing normal result-selection fixture still has no matching Route 138 widget. Its attempted fixture reset did not solve it and was removed; this unrelated journey test remains unresolved and the full suite is not claimed clean.

## 81. Diagnose empty search results and restore explicit timetable recovery

Implemented on 2026-10-17:

- Read-only inspection of the normal Firebase catalogue found 36 published timetables and no dated physical runs. Those timetables have no supported wheelchair access, so the account's default wheelchair requirement correctly excludes them. The normal Badulla itinerary is Badulla -> Ella -> Wellawaya -> Mattala -> Makumbura; Bandarawela is not on this stored route. No invented normal run, GPS, accessibility claim or stop was added.
- Empty results now disclose when dated/timetable candidates exist outside the current accessibility requirements and offer an explicit, localized Show without accessibility filters action. It updates only the current draft, clears wheelchair/step-free overrides and opens the All view; Settings remain unchanged. Returned services retain their actual accessibility/evidence status.
- Results keeps stable bus/report stream subscriptions across rebuilds, avoiding repeated listener resets and temporarily empty evidence. Dated-run search now waits for verified server snapshots with the bounded cache-to-server handling used by admin loading.
- The previously failing navigation test inherited a wheelchair requirement while its positive evidence used wall-clock observation times against a fixed earlier search clock. It now explicitly requests an unfiltered selection, matching its navigation/persistence purpose. A separate deterministic regression verifies unknown-access services can be explicitly inspected, both draft needs reach Bus Details as false, and saved preferences remain true.

Validation: **41 focused search/journey tests passed** (`phase67-targeted-tests.log`); **5 empty-state recovery tests passed** (`phase67-recovery-tests.log`). Existing recovery tap helpers now wait for scrolling to settle. A read-only snapshot of the actual normal timetable data matched **36 upcoming timetable opportunities**, including **2 Badulla -> Ella** options (`phase67-normal-catalogue-test.log`); an initial Bandarawela probe correctly returned zero because that stop pair is absent. Analyzer **No issues found** (`phase67-analyze.log`), main debug build succeeded (`phase67-debug-build.log`) and same-package update/install returned Success. Final full-suite results are in `phase67-final-full-tests.log`; the earlier run still included two scroll-helper failures before their correction.

Final checkpoint 81 verification: **1,044 full Flutter tests passed, 4 skipped** (`phase67-final-full-tests.log`). This clears the previously recorded journey-selection and fare/scroll test failures. Normal published timetable matching was verified read-only; no catalogue records were changed. Main package was updated with sign-in/data retained and localhost health is ready.
