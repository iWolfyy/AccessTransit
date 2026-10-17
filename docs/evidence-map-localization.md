# Evidence, ramp and selected-map presentation

Accessibility Evidence, Vehicle Ramp, Selected Segment Map and the published
timetable notice now use English/Sinhala/Tamil resources for their remaining
fixed labels. This pass adds 48 entries per locale, with typed timestamps,
attribution/source parameters and plural confirmation counts. Existing shared
unknown labels, localized relative ages and geometry ETA ranges are reused.

Evidence filtering and freshness are unchanged. Capability, observed working
state, unresolved barriers, expired positive checks and unknown conditions
remain separate. Public visibility, exact target matching and five-False
hiding retain their existing policy. Section storage keys remain stable across
language changes. User-authored observations and actual reporter names are
preserved, including names that happen to match an English fallback label.
Missing names now use a localized fallback at presentation, without storing
that fallback as if it were a profile name. Private account IDs are not shown.

Ramp equipment does not become proof that it works. Old positive checks expire
to Unknown, and old unresolved broken checks retain their warning. The existing
numeric recorded timestamps and device-local conversion remain unchanged;
this pass does not change operational time or timezone policy.

The map explains missing coordinates/road geometry and tile failures in the
selected locale. Current-bus semantics and location-update wording are
localized. Original stop names and OpenStreetMap attribution remain unchanged.
Selected-run/GPS freshness authorization still belongs to the enclosing
Details state; this presentation change does not guess a location or start
tracking. The published-timetable notice still discloses an unassigned vehicle,
unknown accessibility/location and unavailable driver assistance. Original
source URLs and geometry version/target names remain data.

New isolated tests cover all three locales at 320dp/200% text and high contrast:
conflicting/expired evidence, unresolved barriers, plural attribution and real
name preservation, ramp capability versus condition, static/current-marker
semantics, tile failure, map attribution, published-source disclosures and ETA
target preservation. Fixtures have no initialized Firebase app; user lookups
use the existing in-memory fallback, map HTTP requests receive test responses,
and no real GPS is read.

Fluent Sinhala/Tamil review and native font/TalkBack/device checks remain
required. Report detail/publication/voting and other existing screens retain
their separate remaining translation scope. No real Auth/Firestore mutation,
deployment, billing change, push send or APK build/install is included.
