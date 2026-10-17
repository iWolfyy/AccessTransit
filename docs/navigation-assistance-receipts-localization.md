# Navigation and assistance receipts

The shared bottom navigation bar displays the existing Home/Plan/Community/
Profile translations. Canonical English tab IDs remain routing keys, so language
changes do not change the active tab or break callbacks/deep links. Full labels
wrap with a content-sized minimum-height bar, and selected tabs expose selected
button semantics. Existing theme and icons remain unchanged.

Assistance status and saved receipt panels use 33 new English/Sinhala/Tamil
resources for delivery states, retry/cancellation, errors, headings and typed
route/stop summaries. Existing assistance type/state translations are reused for
both legacy and v2 receipts. Stored enums, target IDs and service policies remain
unchanged. Original route/stop names and unknown custom assistance types remain
data.

Pending upload, sent, driver acceptance and completion remain distinct states.
A rejected cancellation does not claim success, failed delivery retains retry,
and missing live updates are identified as last-received data. Error rendering
translates known service-owned messages; unknown provider/storage errors use a
localized generic message rather than raw details. Account-scoped visibility
and saved-receipt access continue through the existing services.

New tests cover navigation labels/canonical callbacks/selected semantics and
locale switching in all three locales at 320dp/200% text with normal/high
contrast. Assistance tests exercise failed/retried/delayed acknowledgement,
driver acceptance/completion, failed cancellation, original/custom data,
account changes and unavailable saved-receipt streams. Existing delivery and
layout regressions are also included.

No real Firebase/Auth mutation, assistance publication, deployment, billing
change or APK build/install is included. Automated semantics/layout checks do
not replace fluent translation review or native font/TalkBack/device testing.
