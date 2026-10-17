# Passenger Home presentation

Home greetings, quick actions, drawer/desktop navigation, report previews and
recent-journey wording use generated English/Sinhala/Tamil resources (44 new
entries per locale). Existing Profile/Driver resources supply shared roles,
preferences and unsupported-action messages. Navigation still passes stable
Home/Plan/Community/Profile keys; translated labels never grant a role or
change routing privileges.

Only fixed UI labels go through `home_presentation.dart`. Profile names,
report target names/problem descriptions and saved journey endpoint names
remain original data, even when a name happens to equal an English label.
Relative observation/journey ages use localized plural resources. This is
presentation time, not the authoritative search clock or boarding eligibility.

Home report previews retain their existing evidence freshness/visibility
filter. A streamed hidden report disappears from the visible card immediately.
Reported stream errors show unavailable wording rather than an empty-state
claim. Recent journeys distinguish waiting, failed and empty snapshots; failure
to create the recent-journey subscription also becomes unavailable. Repository
fallback behavior and broader offline/cache provenance are unchanged by this
pass; an upstream fallback that emits an empty list cannot be distinguished
from empty data by the widget alone.

The header brand, drawer role/header and report headings/vote summaries wrap
at narrow widths and large text sizes. Standalone Home navigation to Profile
passes the current profile snapshot, matching its avatar entry. Existing
MainShell navigation remains unchanged. Optional report/journey streams let
tests drive the real Home widgets without initializing Firebase; the default
app continues to use its existing repositories.

Automated coverage includes all three locales at 320dp/200% text, high contrast,
desktop Profile navigation, locale changes with a saved segment, original
names/text, live five-False hiding, failed-to-empty stream recovery and age
boundaries. Native fonts/TalkBack, fluent terminology review and device/offline
walkthroughs remain separate. Other screens and nested saved/assistance panels
retain their own localization scope; this pass does not claim whole-app
translation completion. No real data mutation, deployment or APK build occurs.
