# In-app Help Center

Profile -> Support -> Help Center now opens an in-app guide instead of a
Coming soon message. Eight expandable topics explain search/defaults, optional
Save Trip, My Location, timetable versus live position, pending uploads,
community voting/disputes, assistance status and account access/review.

The guide uses 17 new English/Sinhala/Tamil resources and the existing translated
Help Center title. It follows the existing theme and high-contrast colors, wraps
titles and body text, scrolls, and retains expanded topic state while navigating
within its route. It reads no private account, location or backend data.

Guidance distinguishes saved trips from seat bookings, submitted assistance from
acceptance, scheduled runs from live GPS, local drafts from published reports,
and community disputes from proven false reports. It describes the existing
review workflow without inventing a support address or promising an action.
Other unavailable Profile actions retain their existing honest status.

Tests expand and collapse all eight topics in all three locales at 320dp/200%
text with normal/high contrast, and open Help from Profile and return. Tests
use a fixture profile without real Firebase/Auth mutations. Fluent translation
review and native font/TalkBack/device checks remain required.

No backend operation, deployment, billing change or APK build/install is part
of this change.
