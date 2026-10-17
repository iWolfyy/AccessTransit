# Passenger Search presentation

Search, its stop picker, travel-time sheet and temporary-needs sheet now use
generated English/Sinhala/Tamil resources. This pass adds 64 entries per locale,
including typed time/date/selected-stop parameters and plural active-need counts.
Material localization formats displayed dates and the existing time picker
formats times. Stable stop IDs, original catalogue names and internal filter
keys remain unchanged; translated chip labels do not become matching inputs.

The trusted-time receipt, rolling boarding window, dated/active-run matcher,
account-scoped needs draft and Results navigation are unchanged. Temporary
needs edits and reset continue to use the existing draft service, without
writing saved preferences. My Location still obtains one foreground fix,
offers nearby stops and waits for explicit selection. This pass adds no
location collection, persistence or background tracking.

The former microphone control only displayed suggested stops; it did not
capture or recognize speech. It now has a suggestions icon/label, explicitly
states that speech recognition is unavailable, and acknowledges a manually
selected stop as Selected instead of Recognized. No speech provider is enabled.
The catalogue refresh tooltip also describes its actual refresh operation.

Search controls and headings wrap, and the needs/time sheets scroll for long
translations and large text. Buttons retain minimum touch heights and grow
where needed. Switch tiles have a Material surface for visible feedback.
The existing theme and navigation destinations remain in use.

Isolated tests exercise all three locales at 320dp/200% text, original stop
names, explicit nearby selection, time/suggestion sheets, temporary needs,
reset and unchanged saved defaults. Needs tests also enable high contrast.
Existing search, window, account-switch, proximity and matching regressions
remain part of the full Flutter suite. No real GPS, Firebase writes, Auth
mutations, deployment, billing changes or APK build/install are involved.

Fluent Sinhala/Tamil terminology review and native fonts/TalkBack/device QA
remain required. Results, Bus Details and other nested journey/report panels
retain their separate remaining localization scope; this pass does not claim
that the entire passenger journey is fully translated.
