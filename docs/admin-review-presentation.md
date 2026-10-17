# Review and trip-handover presentation

Implemented 2026-10-17 in the main Flutter app. Added 13 English/Sinhala/Tamil
resources for specific review/session/access rejection messages and labeled
run/driver/evidence identifiers. Community True/False evidence uses the existing
localized vote labels; original vote values, IDs and authored reasons remain
unchanged. These are attributed community votes, not proof of factual truth.

Permanent-ban and report-review states now use explicit known-state mappings.
An unknown value shows status unavailable rather than pending/unreviewed. Report
decision controls are shown only for supported pending/unreviewed states;
permanent-ban controls still require a pending case. This is a client
presentation guard; trusted backend authorization and transactional decisions
are unchanged.

Known failures distinguish self-review, missing admin authority, expired/changed
sessions, account restrictions, an already decided/unavailable review and request
conflicts. Existing stale-evidence, pending-appeal and protected-admin messages
retain priority. Unknown failures keep generic recovery guidance. An operations
list that failed loading no longer also claims there are no active trips.

Existing reason requirements, current-revision checks, immutable handover retry
payloads, explicit permanent-ban approval, appeal correction behavior and scope
isolation remain intact. No decision, driver handover, account restriction or
auth effect is produced by this localization pass.

Coverage includes three locales at 320dp/200%, localized evidence labels,
unchanged authored reasons, unsupported review states without decision controls,
specific rejection wording and unavailable versus empty operations. Existing
report appeal, mandatory permanent-ban review and acknowledged/retry handover
regressions are retained. Remaining profile/operational strings, fluent language
review and native accessibility/device validation remain separate work.

No APK, shared Firebase mutation, rules/index update, backend deployment, billing
change or real push send is needed for this source change.
