# Fare policy: reviewed published tariffs and labelled synthetic estimates

**2026-10-16 revision supersedes the historical F24 description below.** Normal
builds show **Fare unavailable** wherever an applicable reviewed tariff/stage
publication is absent. The duration/stop formula runs only in explicit debug LOCAL_VALIDATION,
SAMPLE_TEST or TRANSIT_DEMO builds, labelled **Sample est. LKR ...**. Shared amount/
disclosure components localize Results, Bus Details and legacy route/confirmation/
live entry points. Sinhala/Tamil text still needs fluent review. Old saved numeric
prototype amounts remain compatible records but normal mode suppresses their
numeric display. No saved journeys were reset or rewritten.

## Reviewed tariff lookup foundation

`lib/logic/tariff_fare.dart` is a pure lookup contract, not an official import,
admin editor or live quote service. Reviewed tables identify exact route pattern/
direction, service class, version, inclusive effective dates, LKR currency, HTTPS
source and a directed matrix in **integer minor units** (LKR 123.45 -> 12345).
Floating, negative and zero prices are rejected by this initial non-concession
contract. Concessions/free eligibility require their own reviewed policy.

Versioned mappings connect ordered stop occurrence IDs to authority fare stages
and a table. Distinct occurrences support first/return visits to the same physical
station. This contract does not migrate operational schemas that still reject
repeated physical stop IDs. Missing stages remain unknown. The exact selected
direction/class/occurrences and Colombo **boarding date** determine applicability;
phone timezone and destination arrival after midnight do not change it.

The listed directed matrix cell is used without subtracting stage indices or
adding adjacent fares. Missing/expired cells or mappings, reverse selections and
overlapping applicable versions return unavailable. Input maps/lists are copied
immutably. Quote snapshots carry amount/currency, selected occurrences, pattern/
class, Colombo service date, source and tariff/mapping versions. A client
`reviewed` boolean grants no authority: future catalogue ingestion requires
acknowledged trusted records and backend publication/read rules.

Checkpoint 33 wires published reviewed quotes into Results, consolidated Bus
Details and optional saved-trip snapshots. Without an applicable acknowledged
publication, normal mode continues to show Fare unavailable. Old standalone
confirmation/live surfaces still suppress prototype amounts in normal mode.
ETA geometry/measured accuracy remains separate.

## Admin publication and passenger integration

Admin dashboard -> Fares accepts a publication ID and JSON bundle. Validate and
preview the source, pattern, service class, effective dates, vehicle scope,
versions and directed matrix. Check the review acknowledgement, enter a reason
(at least ten characters) and publish. This is manual catalogue review, not
automatic verification of a source's authenticity. Only use authority-reviewed
values and stop-stage mappings for normal operations.

The [local-only example](fare-publication-example.local-only.json) contains a
fictional amount/source. It is not an importable operating tariff. Replace every
placeholder with synthetic local catalogue IDs, use the publication ID as
`mapping.tariffId`, and provide the bus's complete ordered stops. `12345` means
LKR 123.45, not LKR 12,345. `synthetic: true` is required in local/demo builds;
normal builds accept only non-synthetic publications. Do not convert this
fictional example into a normal fare by changing that flag.

Each bundle is an immutable `fare_publications/<ID>` document. Admin commits
recheck the route, physical buses and target ID transactionally and write an
audit event. Timetable-only vehicles cannot receive a publication. Archive old
versions with a reason and publish a new ID for changes; updates to published
amounts/mappings, deletion and reactivation are denied. Archive/publish are
separate acknowledged actions, so temporarily unavailable fares are possible.
The admin list fetches twenty records per page.

Passenger listeners query published, mode-matching, explicitly assigned bus
records. Cached/pending snapshots, failed reads, malformed records, ambiguous
versions or more than twenty matching publications fail closed. The composite
index is prepared locally and needs deployment before shared activation. The
selected bus itinerary must exactly match the reviewed mapping. The current
operational route ID is the directional pattern; buses with repeated physical
stops still need the separate occurrence-schema migration.

Results and Details use exact cents from one directed matrix cell, with source
and versions. Details refreshes the quote independently before optional saving;
old saved quotes are historical snapshots, not current authority. Changed or
archived tariffs show a change notice and current available/unavailable fare.
Saved records retain amount, currency, source, segment and mapping/table
versions. Rules reject forged amount/version/bus/segment/applicability on new
saves. An existing saved record survives archival; remove/re-save explicitly to
replace its original snapshot. This does not issue a ticket or payment quote.

Direct retrieval of the [NTC fare page](https://www.ntc.gov.lk/Bus_info/bus_fares.php)
failed during this step. No latest tariff/version, amount or applicable stage
mapping was imported or verified. Arithmetic tests use fictional `authority.example`
sources/amounts; they must never become normal operating fares. No production
data/rules/deployment, billing or push activation occurred.

## Historical F24 behavior (superseded)

Every amount produced by the app is a **prototype estimate**, not an official ticket price, booking quote or verified operator tariff. Results, route details, confirmation and live journey use the shared FareEstimateText/JourneyFare wording: **Est. LKR ...**, the prototype duration/stop source and a reminder to confirm the actual fare with the operator. Service class, fare stages and concessions are not included. Unsupported cash/digital-ticket claims have been removed.

The unchanged prototype formula uses only the selected segment: `35 + durationMinutes * 2.2 + intermediateStops * 4`, rounded to the nearest five and clamped to 40–450 LKR. These coefficients/limits are application design choices, not tariff evidence. Duration and stops do not establish official fare stages. This formula is unsuitable as a guaranteed amount to budget/pay; the app makes no accuracy claim. Missing timetable intervals may themselves be model estimates.

Results compute the segment amount once. Route selection carries that amount to details/confirmation, saved journeys retain it as estimatedFareLkr, and resume restores the saved value rather than recalculating a full-route or current-time price. It is not refreshed by GPS delays. Live journey uses its saved journey amount or the matching selected vehicle/segment amount. A different resolved vehicle/segment cannot inherit an unrelated route estimate.

There are no fabricated 95/250/80 LKR defaults. Missing, zero or negative amounts display **Fare unknown**, never a free ticket. Zero remains an existing-schema unknown sentinel where a route item requires an integer; it is not shown as a fare. A direct screen launch without a selected estimate therefore cannot invent a price. The semantics label also identifies the estimate and prototype source; physical TalkBack verification remains pending.

[NTC's official bus-fares page](https://ntc.gov.lk/Bus_info/bus_fares.php?lang=en) publishes fare-stage and route/service tables (checked during F24). These tables have not been integrated into this app. The current bus/station catalogue lacks a verified mapping from selected stop IDs to the applicable tariff stages/service classes/effective tariff. No official table value has been substituted using guessed stop counts or durations. An authoritative integration needs that reviewed mapping plus tariff applicability/version dates; until then all displayed numeric fares remain explicitly prototype estimates. No live fare data/configuration was changed.

Local automated tests verify the same selected-segment estimate through results/details/confirmation/save/restore/live, unknown direct launches, vehicle mismatch and accessible amount/source semantics. They do not verify real ticket prices or payment support.
