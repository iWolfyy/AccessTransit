# Fare and geometry admin language pass

Implemented 2026-10-17 in the main Flutter application. Added 45
English/Sinhala/Tamil resources for reviewed-import metadata, publication state,
fare/geometry validation and source/version/stop-distance previews.

Fare preview now labels the route, service class, applicable mapping dates,
source, fare/mapping versions and bus IDs. Stage IDs remain verbatim; minor-unit
amounts use locale currency formatting for LKR. Geometry labels its route ID,
reviewed JSON input, version, source and ordered stop/distance preview. Persisted
JSON, identities, amounts, sources, coordinate order and versions are unchanged;
display formatting never recalculates a tariff or ETA.

Known parser/service failures retain their exception and display a localized
specific reason alongside recovery guidance. Examples include invalid minor
units, mismatched fare applicability, a changed bus itinerary, reused geometry
version and stop/road-vertex mismatch. Unknown JSON parser diagnostics are not
shown as raw error text; generic localized import guidance remains available.
Geometry errors follow locale changes instead of keeping a captured translated
string. Unknown publication state shows status unavailable rather than claiming
published or archived. Failed fare-list loading no longer also claims an empty
catalogue; previously displayed rows may remain while recovery is shown.

No publication/archive/withdraw policy was relaxed. Review confirmation/reason,
immutable fare IDs, explicit bus mapping, normal/Sample separation, route/stop
guards and new geometry version requirements still apply. Failed writes retain
the draft for correction/retry and are not presented as successful.

Validation covers invalid import rejection in all three languages, duplicate
geometry version rejection, preserved draft/retry behavior, no false empty or
known state, locale changes after an error, hidden raw parser output and the
existing preview tests at 320dp/200% text. Fluent translation, native font and
TalkBack review remain pending. No official tariff or real road geometry was
imported by this work; those remain reviewed-data tasks.

No APK, shared Firebase write/rules/index change, backend deployment, billing
upgrade or real push send is required for this UI source change. Moderation and
trip-handover presentation progressed in
[review and trip-handover presentation](admin-review-presentation.md).
