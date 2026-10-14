# AccessTransit: system audit and assignment readiness

Audit date: 2026-10-14 (Asia/Colombo). Topic: Inclusive Public Transport Companion, SDG 10 and 11.

## Outcome and scope

This document preserves the original audit findings. Current implementation/rollout status is recorded in [fix-progress.md](fix-progress.md).

The app has substantial prototype functionality but is not ready for real-world reliance. This review records 26 actionable findings: 2 P0, 10 P1, 12 P2 and 2 P3. P0 means an immediate safety/security blocker; P1 means a core-flow or trust failure; P2 means reliability/UX correctness; P3 means documentation/dormant implementation risk. Priorities are engineering judgments, not assignment marks.

Reviewed authentication/roles, Firestore rules, profiles/rewards, route matching/scheduling/filtering, reporting/outbox/photos, freshness/evidence, driver GPS/trips, boarding assistance, preferences/accessibility, navigation and assignment artifacts. Read all eight assignment PDF pages and visually inspected their rendered layouts and rubric. Repository state includes substantial existing uncommitted work; this audit describes the current working tree rather than only the committed branch.

Evidence consists of source inspection, workspace artifact inventory, current automated tests and analyzer results. Findings below are source-confirmed unless specifically labelled dormant or a gap. They were not all reproduced on two live devices. Deployed Firestore rules, Cloudinary preset restrictions/secret rotation, GPS background behaviour and screen-reader experience have not been independently verified. No production writes or billing upgrades were made for this audit. An emulator walkthrough and cross-account live testing are still required.

User sequencing: complete the app first, then perform the pending assignment research/design/testing/report work. Reserve an iteration after real participant feedback; document the actual sequence honestly instead of describing planned studies as already completed.

## Validation

- Current full test run: **241 tests passed** (`audit-test-results.log`). These include pure logic, widget and injected service tests; they do not establish deployed security or live cross-device delivery.
- Full `flutter analyze lib test`: **0 errors, 0 warnings, 1 info** at `lib/screens/home/home_screen.dart:1392` (`unnecessary_underscores`). Analyzer exits nonzero for that info; do not report an entirely clean analyzer run.
- Current Android debug APK build: **passed**, direct verification exited 0; artifact `build/app/outputs/flutter-apk/app-debug.apk`. The initial redirected invocation reported an error status while still generating an APK; the direct rerun confirmed success. This is a debug build, not a signed release. Gradle emits native-access warnings and Flutter warns that the current firebase_auth/firebase_core Kotlin-plugin integration needs maintenance before a future Flutter upgrade. These are maintenance notes, not current build failures.
- No functional fixes are included in this audit. Recommendations are a review backlog.

## Findings

### F01 [P0] Firestore rules grant unrestricted access

Area: Security.

An unauthenticated client can read/write every document under the local catch-all rule. Specific collection rules cannot tighten an already allowed catch-all.

Required change: Replace with default-deny rules, owner-scoped passenger data, assigned/approved operator writes, immutable identity and server-controlled rewards; validate with Firebase Rules Emulator. Verify what is actually deployed separately.

Evidence: [firestore.rules:7](</D:/projects/Android Apps/Flutter/AccessTransit/firestore.rules:7>).

### F02 [P0] Emergency button falsely reports contact

Area: Safety.

The live journey emergency callback only shows 'Emergency services contacted.' No call, message or service request is performed.

Required change: Implement a reviewed contact/dial flow with truthful initiated/failed states, or remove the action until implemented. Confirm the appropriate contact through authoritative local sources before configuring it.

Evidence: [lib/screens/journey/live_journey_screen.dart:1641](</D:/projects/Android Apps/Flutter/AccessTransit/lib/screens/journey/live_journey_screen.dart:1641>).

### F03 [P1] Live journey sends users to the wrong assistance target

Area: Assistance.

Both assistance actions open const BoardingAssistanceScreen(), using its default bus_138_outbound, st_fort and three-minute arrival, even while viewing another bus or stop.

Required change: Pass the actual bus ID, boarding/alighting stop ID and name, route label and measured ETA; require target review. Test another route and a shared stop.

Evidence: [lib/screens/journey/live_journey_screen.dart:1575](</D:/projects/Android Apps/Flutter/AccessTransit/lib/screens/journey/live_journey_screen.dart:1575>).

### F04 [P1] Assistance can appear sent without reaching the driver

Area: Assistance.

createBoardingRequest caches first and swallows Firestore errors; the form then says sent and closes. Request status updates do the same. Its local-stream listener does not forward local events to the yielded stream.

Required change: Use acknowledged delivery states and a durable owner outbox. Add a passenger request-status stream with acknowledged/completed/cancelled states, failed-write UI and meaningful offline handling.

Evidence: [lib/services/firestore_service.dart:711](</D:/projects/Android Apps/Flutter/AccessTransit/lib/services/firestore_service.dart:711>).

### F05 [P1] Missing telemetry is presented as working equipment

Area: Accessibility.

LiveJourneyScreen defaults missing ramp/elevator telemetry to true and renders 'Verified active on this vehicle'. It does not subscribe to condition reports/StatusLogic for the live accessibility panel.

Required change: Reuse scoped evidence and freshness logic in the live screen; represent equipment as Unknown until checked, and separate vehicle ramp evidence from stop elevator evidence.

Evidence: [lib/screens/journey/live_journey_screen.dart:172](</D:/projects/Android Apps/Flutter/AccessTransit/lib/screens/journey/live_journey_screen.dart:172>).

### F06 [P1] Normal search bypasses route evidence and journey persistence

Area: Navigation.

_onSelectRoute navigates directly to LiveJourneyScreen. No production callers of RouteDetailsScreen or JourneyConfirmationScreen were found. The improved evidence card is therefore disconnected from the normal search flow; JourneyService.createJourney is in the unused confirmation screen.

Required change: Connect results -> route evidence -> explicit journey confirmation -> persisted journey -> live tracking. Preserve bus/stop IDs, selected date and time. Test restart/resume.

Evidence: [lib/screens/journey/route_results_screen.dart:187](</D:/projects/Android Apps/Flutter/AccessTransit/lib/screens/journey/route_results_screen.dart:187>).

### F07 [P1] Confirm/resolve/flag can falsely appear shared

Area: Reports.

Community mutations change local reports first, award/deduct local stats, then catch cloud errors. The details screen still reports confirmation or resolution success.

Required change: Return acknowledged results or queue explicit pending mutations; propagate rejection; update public evidence and rewards only after acknowledgement. Keep resolution audit records.

Evidence: [lib/services/firestore_service.dart:374](</D:/projects/Android Apps/Flutter/AccessTransit/lib/services/firestore_service.dart:374>).

### F08 [P1] Driver updates and trips can succeed only locally

Area: Operations.

updateBusAccessibility, TripService start/arrival/complete and LiveBusService updates swallow write failures. Driver UI announces updated/active/completed states without reliable shared acknowledgement.

Required change: Make operator writes report success/failure; keep local GPS visible as local only; reconcile retries and show broadcasting acknowledged/stale/offline states. Add cross-device failure tests.

Evidence: [lib/services/firestore_service.dart:616](</D:/projects/Android Apps/Flutter/AccessTransit/lib/services/firestore_service.dart:616>).

### F09 [P1] Operator role and bus assignment lack trusted approval

Area: Security.

Registration accepts an operator role from the user. _claimBusAssignment writes the current user's ID directly onto the bus, including already assigned buses; protection is a UI check and the permissive rules.

Required change: Decide approved-operator enrolment and assignment policy. Enforce it in backend rules/transactions; prevent reassignment without permission; eliminate operator_dev identities in real flows.

Evidence: [lib/screens/operator/operator_dashboard_screen.dart:229](</D:/projects/Android Apps/Flutter/AccessTransit/lib/screens/operator/operator_dashboard_screen.dart:229>).

### F10 [P1] Missing report timestamps become fresh now

Area: Evidence.

Report.fromMap uses DateTime.now() if createdAt is absent/invalid. Malformed or legacy evidence can look newly checked and pass freshness tests.

Required change: Represent unknown observation time explicitly or reject invalid records; never refresh missing evidence during parsing. Add missing/invalid timestamp fixtures.

Evidence: [lib/models/report.dart:92](</D:/projects/Android Apps/Flutter/AccessTransit/lib/models/report.dart:92>).

### F11 [P1] Unknown ramp condition defaults to working

Area: Accessibility.

Bus.fromMap defaults missing rampOk to true; wheelchairAccessible is hasRamp && rampOk. A record listing a ramp but no operational check can enter accessible results.

Required change: Separate capability from observed operational condition with nullable condition/time/source; treat absent check as Unknown for requirement matching.

Evidence: [lib/models/bus.dart:117](</D:/projects/Android Apps/Flutter/AccessTransit/lib/models/bus.dart:117>).

### F12 [P1] Sample services are exposed as real fallback transit data

Area: Data.

FirestoreService preloads sample buses/routes and returns SeedData stations when remote data is empty or unavailable. Reports are now separated from demos, but service availability, schedules and equipment flags are not.

Required change: Add explicit demo mode and provenance for transit catalogues; preserve acknowledged cache offline and show no data/stale states instead of substituting demo services.

Evidence: [lib/services/firestore_service.dart:31](</D:/projects/Android Apps/Flutter/AccessTransit/lib/services/firestore_service.dart:31>).

### F13 [P2] Concurrent votes and rewards can lose updates

Area: Reports.

confirmReport/flagReport read a document then overwrite complete arrays/counts using set, not a transaction. UserService.updateUserStats similarly computes totals from a prior read. Parallel clients can overwrite each other's changes.

Required change: Use transactions or authoritative server operations for votes and idempotent reward events. Test simultaneous votes, duplicate retry and reversal.

Evidence: [lib/services/firestore_service.dart:410](</D:/projects/Android Apps/Flutter/AccessTransit/lib/services/firestore_service.dart:410>).

### F14 [P2] Stop alert promises a notification without detection

Area: Navigation.

_toggleAlert only flips a bool and shows a snackbar. No use of that bool for stop proximity or notifications was found.

Required change: Implement stop-index/proximity detection, once-only foreground alerts and clearly scoped background delivery, or mark the control unavailable.

Evidence: [lib/screens/journey/live_journey_screen.dart:65](</D:/projects/Android Apps/Flutter/AccessTransit/lib/screens/journey/live_journey_screen.dart:65>).

### F15 [P2] Conditions do not refresh when time alone passes

Area: Freshness.

Freshness is calculated during build/stream events; results/feed/evidence do not have a clock-boundary or resume refresh. With no data event, a 30-minute crowding badge can remain on screen after expiry.

Required change: Rebuild at the next expiry/recheck boundary and on app resume, sharing a clock where possible. Test a visible report crossing expiry without Firestore events.

Evidence: [lib/screens/community/community_screen.dart:243](</D:/projects/Android Apps/Flutter/AccessTransit/lib/screens/community/community_screen.dart:243>).

### F16 [P2] A previous confirmer cannot perform a later recheck

Area: Freshness.

Both UI and service exit if confirmedBy already contains the user. The same commuter cannot refresh an unresolved fault on a later trip.

Required change: Separate unique vote totals from dated check observations; permit later recheck under a reasonable interval without awarding repeat voting rewards.

Evidence: [lib/services/firestore_service.dart:420](</D:/projects/Android Apps/Flutter/AccessTransit/lib/services/firestore_service.dart:420>).

### F17 [P2] Final-stop arrival needs an extra confirmation to complete

Area: Operations.

confirmNextStopArrival completes only when nextIndex >= stops.length. Confirming arrival at the last valid index still returns in_progress; a further press is needed.

Required change: Complete on arrival at the final stop, retaining its actualArrival; atomically stop broadcasting. Test two-stop and multi-stop trips.

Evidence: [lib/services/trip_service.dart:136](</D:/projects/Android Apps/Flutter/AccessTransit/lib/services/trip_service.dart:136>).

### F18 [P2] Operator overnight estimates do not roll into the next day

Area: Scheduling.

TripService.startTrip parses every schedule time on actualDepTime's date. A 23:50 then 00:10 itinerary produces the latter estimate earlier than departure. PassengerJourneyPlan handles rollover separately.

Required change: Share ordered schedule parsing between operator and passenger journeys, and clarify actual-versus-planned departure adjustments.

Evidence: [lib/services/trip_service.dart:49](</D:/projects/Android Apps/Flutter/AccessTransit/lib/services/trip_service.dart:49>).

### F19 [P2] Deleted telemetry can remain in local cache

Area: Data.

LiveBusService returns cached location after a remote document is missing, and its all-active snapshot handler does not remove cached buses absent from the snapshot. A later local event can reintroduce old broadcasting records.

Required change: Invalidate on authoritative remote deletion/empty active snapshots; retain stale cache only when explicitly offline and labelled accordingly.

Evidence: [lib/services/live_bus_service.dart:370](</D:/projects/Android Apps/Flutter/AccessTransit/lib/services/live_bus_service.dart:370>).

### F20 [P2] Local outbox lacks retention and account cleanup

Area: Privacy.

Outbox JSON includes report text and pending image bytes in SharedPreferences and retains all entries. Published entries remain in the map, and no cleanup/user deletion policy was found.

Required change: Bound retention, remove acknowledged entries when safe, add pending-report cancel/delete and account-scoped cleanup; evaluate private file storage for images and protect sensitive notes.

Evidence: [lib/services/report_submission_service.dart:71](</D:/projects/Android Apps/Flutter/AccessTransit/lib/services/report_submission_service.dart:71>).

### F21 [P2] Preferences carry across signed-in accounts

Area: Preferences.

Accessibility settings use global SharedPreferences keys; logout does not reset or load account-specific preferences. A second rider on a shared phone inherits the previous rider's requirements.

Required change: Choose explicit device settings versus account travel needs; scope personal needs by UID with guest defaults and reload on auth changes.

Evidence: [lib/services/accessibility_preferences_service.dart:18](</D:/projects/Android Apps/Flutter/AccessTransit/lib/services/accessibility_preferences_service.dart:18>).

### F22 [P2] Scheduled minutes are labelled as live bus movement

Area: Planning.

Results label buses Ongoing/Approaching/isLive from departure-time differences without live GPS. A scheduled bus that never starts can look live.

Required change: Use schedule wording until fresh operator telemetry confirms movement. Keep timetable estimates separate from live tracking.

Evidence: [lib/screens/journey/route_results_screen.dart:342](</D:/projects/Android Apps/Flutter/AccessTransit/lib/screens/journey/route_results_screen.dart:342>).

### F23 [P2] Accessible empty-state recovery button is unreachable

Area: Planning.

The empty state checks _selectedFilterTab == '♿ Accessible', while the actual tab value is 'Accessible'. The intended Show All Buses button cannot appear.

Required change: Use one typed tab value and provide a useful recovery action without silently dropping wheelchair/step-free requirements.

Evidence: [lib/screens/journey/route_results_screen.dart:666](</D:/projects/Android Apps/Flutter/AccessTransit/lib/screens/journey/route_results_screen.dart:666>).

### F24 [P2] Ticket prices are model estimates with incomplete disclosure

Area: Planning.

PassengerJourneyPlan uses an invented duration/stops formula, while route cards render bare LKR amounts. The unused details page also has an independent fixed ticket-price card.

Required change: Clearly label estimates and their source/limitations; replace with an authoritative fare dataset if available, and share the selected segment fare across all screens.

Evidence: [lib/logic/passenger_journey_plan.dart:21](</D:/projects/Android Apps/Flutter/AccessTransit/lib/logic/passenger_journey_plan.dart:21>).

### F25 [P3] Unused confirmation screen contains fabricated live/verified data

Area: Scope.

JourneyConfirmationScreen can create operator_system telemetry at hard-coded coordinates/speed and displays fixed verified-ramp statements. It has no current callers, so this is a dormant risk rather than a reproduced production flow.

Required change: Remove demo writes from production and replace static verification before reconnecting this screen for F06.

Evidence: [lib/screens/journey/journey_confirmation_screen.dart:43](</D:/projects/Android Apps/Flutter/AccessTransit/lib/screens/journey/journey_confirmation_screen.dart:43>).

### F26 [P3] Project documentation overstates implemented features

Area: Documentation.

read.md lists TTS voice navigation and QA DOCX/XLSX deliverables, while voice guidance is disabled and those artifacts were not found in the workspace inventory.

Required change: Reconcile README/read.md, onboarding and pitch claims with a tested feature inventory. Mark planned capabilities and external evidence links explicitly.

Evidence: [read.md:42](</D:/projects/Android Apps/Flutter/AccessTransit/read.md:42>).

## Improvements already present

Registration profile preservation; passenger segment/date/time planning; trip-cache invalidation on authoritative empty results; positive/barrier/unknown condition classification; endpoint-scoped wheelchair/step-free matching; evidence attribution; durable report publication states and Cloudinary upload adapter; explicit report target/condition review; condition-specific freshness with unresolved structural warnings; disabling unsupported preference switches. These are useful foundations. Some fixes remain disconnected from the main navigation (F06), and other mutation paths still need acknowledged delivery (F04/F07/F08).

## Features to implement or extend

### Required to finish the core app

1. Trustworthy route flow: results -> scoped evidence -> explicit selection/confirmation -> saved journey -> live journey, with stop IDs and selected date/time preserved.
2. Assistance lifecycle: correct target, acknowledged submission, driver acceptance/rejection, passenger status, cancellation and expiry. Sending a request must not imply the driver has accepted it.
3. Equipment observation model: capability separate from working/failed/unknown status, checked time, evidence source, resolution record and recheck history.
4. Trusted operator enrolment and bus assignment, backend authorization, transactional votes and idempotent rewards.
5. Explicit transit demo/offline/stale modes, actual live movement indicators and error/retry UI.
6. Account-aware local storage, retention controls and an accessible way to delete/cancel pending reports. Document which photos are public and obtain informed consent before upload.
7. Real-device accessibility verification: TalkBack focus order and labels, font scaling at 200%, small-screen overflow, tap targets, contrast, reduced motion and color-independent statuses. Automated color/touch tests cover only part of this.

### Research-dependent additions, not assumed requirements

- Seating preference: distinguish an actual seat/priority-seat/wheelchair bay requirement from general crowding. Use recent relevant observations and Unknown when unavailable; no seat guarantee.
- Walking support: collect boarding/exit entry points, usable pedestrian paths, slopes/crossings and walk/rest tolerances. Do not call straight-line distance a safe accessible walk. Add ranking only after the data exists.
- Assistance needs: ramp deployment, extra boarding time, carrying/mobility help and acknowledgement expectations, validated with riders and operators.
- Sinhala/Tamil language support and tested translations appropriate for participants; English-only source strings are currently common and no localization setup was found.
- Quiet routes require noise evidence; low crowding alone does not establish quietness. Spoken guidance needs a connected speech implementation and tested language/timing/mute controls. These are currently unavailable, not completed features.
- Low-bandwidth mode: optional compressed photos, controlled upload/retry, cached acknowledged data, manual stop selection when location is denied and clear offline state.
- Transfers and alternative accessible stops: current matching handles direct buses only. Validate whether these are in MVP scope before adding a routing engine.

## Assignment requirements and evidence status

Source: user-provided `D:/Internet Downloads/SE3050-Assignment1-with-Milestones (4).pdf`, 8 pages. Requirements in that document are assessment criteria; they do not authorize uploading, submitting, publishing or enrolling the team into external services.

Important inconsistency: the milestone plan labels testing M3 and implementation/stack M4, but the marking scheme labels implementation/stack/secure design M3 and testing M4. Cover both sets of deliverables and ask the lecturer which numbering to use. The document gives end-of-week-10 submission, not a verified calendar date.

The rubric totals 60 group marks and 40 individual marks. This is an arithmetic summary, not a prediction of the team's grade. For Excellent testing, plan TWO rounds (hi-fi prototype and implemented app), at least five users in each; 241 automated tests do not replace these sessions.

### M1: Research, ideation and wireframes

Requirement source: PDF p2; rubric p6.

Interview approximately 5–8 participants including an underserved group; scan 3–5 comparable apps; affinity diagram, empathy maps, 4 evidence-backed personas, user stories, journey maps, problem/HMW statements, ideation alternatives, sitemap/flows and low-fi wireframes with rationale.

Current evidence: Interview guide exists. Actual interviews, synthesis, personas, competitor scan and wireframes are pending per user; 01-research-plan.md was not found on disk.

### M2: Hi-fi prototype and EDI

Requirement source: PDF p2; rubric p6.

Clickable hi-fi prototype; typography, palette, spacing and component library; EDI checklist covering WCAG AA contrast/text scaling/screen-reader labels/touch targets, localization, cognitive/motor/visual needs and low-bandwidth/offline support.

Current evidence: Flutter screens and contrast/touch-target tests exist. Figma/hi-fi source, formal checklist, localization and user/device accessibility evaluation are pending or not supplied.

### M3: User testing, iteration and secure design (plan numbering)

Requirement source: PDF p3; rubric p6–7.

Task plan and metrics, think-aloud moderated sessions, SUS raw responses and scoring, completion rate/time-on-task, qualitative findings and before/after changes; authentication, authorization, storage, privacy and validation evidence. Excellent rubric calls for two rounds: prototype and implemented app, at least 5 users each.

Current evidence: Automated software tests exist; participant studies and SUS data are pending. Open rules and false safety/delivery claims block a defensible secure-design claim.

### M4: Stack justification and implementation (plan numbering)

Requirement source: PDF p3; rubric p6.

Compare 2–3 stacks on performance, team skills, accessibility, speed, cost and scalability; explain architecture/state/navigation; working APK, Git repository and requirements-to-feature/test/evidence traceability.

Current evidence: Flutter/Firebase/Cloudinary implementation and Git remote exist. Stack comparison and traceability matrix are pending. Current blockers remain in core flows.

### M5: Branding, promotion and business pitch

Requirement source: PDF p4–5; rubric p7.

Value proposition canvas, positioning, target audience/channels/launch plan, monetization and emerging UX trend discussion; professional logo/tagline; pitch deck appended to report; A3 poster appended; TWO AI-generated MP4s, 1–2 min each (technical demo and business pitch), narration and consistent branding.

Current evidence: App icon/splash assets exist. Dedicated A3 poster, pitch deck, videos, business model and value proposition evidence are pending/not supplied. Planned voice/AI features must be labelled as planned.

### M6: Contribution, reflection, AI declaration and VIVA

Requirement source: PDF p4,7–8.

Individual contribution log with commits/design files/meeting notes; one signed single-page self-reflection per student handed to panel separately from group report; presentation/VIVA understanding of whole project; honest AI-use declaration required by rubric.

Current evidence: Git history exists. Member registration IDs, ownership/evidence logs, signed reflections, AI-use declarations and VIVA deck are pending/not supplied.

## Report outline to prepare after app work

1. Cover page, team names/registration IDs, topic, SDG alignment, repository and prototype links.
2. Problem and stakeholders, underserved segment, primary-research method/consent/recruitment and raw evidence; 3–5 competitor comparisons with sources.
3. Research synthesis: affinity/empathy maps, four personas, stories, journeys, problem statement and HMW questions linked to evidence.
4. Ideation alternatives, chosen flow rationale, information architecture and low-fi wireframes.
5. Hi-fi prototype/design system and explicit EDI checklist with screenshots and measured checks.
6. Testing rounds: task plan, anonymous participant characteristics, raw outcomes, time/success metrics, SUS responses/calculation, pain points and before/after iterations.
7. Stack comparison (2–3 alternatives), architecture/state/navigation, secure design and privacy; implementation screenshots and limitations.
8. Requirements traceability: each story -> feature/screen -> code -> software test -> participant evidence/status. Keep planned and completed items distinct.
9. Value proposition/positioning, launch channels, cost/business model, branding and grounded emerging-UX discussion.
10. Team contribution log and honest AI-use declaration, references and evidence appendices; append the pitch deck and A3 poster as specified. Hand each signed one-page reflection to the panel separately. Deliver the two 1–2 minute AI-generated MP4s separately with the required submission.

The interview guide exists at `docs/assignment/milestone-1/02-interview-guide.md`. The IDE-referenced research-plan file was not present on disk during inventory. Research outputs and participant results have not yet been supplied/conducted per the user's clarification. No personas, participant quotes, SUS scores, signed reflections or team contributions are invented by this audit.

## Recommended work order

1. Safety/security blockers: F01/F02, followed by trusted operator policy F09.
2. Core passenger trust: correct assistance target/delivery F03/F04, connected evidence/journey flow F06, missing data and truthful accessibility F05/F10/F11/F12.
3. Shared state: moderation/operator acknowledgement F07/F08, concurrency F13, repeat checks F16 and cache/trip lifecycle F17–F19.
4. User-facing reliability: real alerts F14, expiry refresh F15, personal storage F20/F21, schedule-versus-live labels F22 and filter/fare UX F23/F24.
5. Remove dormant fabricated data and stale feature claims F25/F26; implement only the additional capabilities chosen for the MVP.
6. Validate with live accounts/devices and accessibility scenarios; capture the final APK and truthful implementation evidence.
7. Conduct and record assignment studies, revise as necessary, produce report/branding/contribution artifacts and rehearse VIVA.

## Completion checks for the app

- A non-owner cannot modify passenger data, an unapproved operator cannot change another bus, and denied cloud writes show failure.
- Route selection exposes relevant evidence and saves/resumes the same journey after restart.
- Assistance for a non-default bus arrives to its assigned operator and acknowledgement reaches the rider.
- No-data/stale/demonstration screens cannot claim verified access, actual movement or emergency contact.
- Report/photos are visible from a second device only after acknowledgement; malformed timestamps stay Unknown; expiry updates without remote activity.
- Concurrent votes/retries preserve counts and rewards; final-stop arrival ends broadcasting; overnight schedules are monotonic.
- TalkBack, large fonts, denied location, offline/reconnect, shared-device account switching and reduced motion pass documented manual tests.

## Unverified external configuration

Confirm the deployed Firebase rules and indexes; approve any necessary deployment separately. Confirm Cloudinary unsigned preset size/format restrictions and usage monitoring, and rotate the API secret previously disclosed in chat through the dashboard. No secret is recorded in this document. Perform a cross-device photo test before claiming live uploads are verified.


