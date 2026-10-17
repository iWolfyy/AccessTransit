# Results and Bus Details presentation

The main Results and Bus Details screens use English/Sinhala/Tamil resources
for timetable/run states, requirement review, empty/loading/retry guidance,
boarding/alighting labels, selected-segment duration, capability/crowding
badges and report freshness. This pass adds 94 entries per locale, including
typed route/date/time/endpoint/source parameters and plural counts. Existing
fare, geometry ETA, save and shared preference resources remain in use.

Displayed dates use Material localization. Original bus plates, stop names,
route names and user-authored report text are preserved. Stable IDs, crowd
values and backend run states remain data; fixed UI labels are translated at
presentation. Known boarding-estimate source labels are localized without
changing their source keys or confidence. Unknown source text is preserved.
Report ages reuse the existing localized Home age formatter, and freshness
labels retain the existing StatusLogic policy.

Results still distinguish timetable opportunities from actual started runs.
The header now invites opening bus details without implying that selecting a
result starts tracking. Requirement review only changes the existing search
draft. The selected segment, timetable/fare selection and owner-scoped Save
Trip flow are unchanged. Details retains selected-run matching and GPS
freshness checks; a scheduled/completed/cancelled run never gains live state
merely from the screen's wording.

Results rows keep their normal layout at standard text sizes and adapt to
stacked content on narrow large-text layouts. Long badge labels wrap. No
global redesign or navigation destination change is included.

New isolated widget tests cover all three locales at 320dp/200% text, high
contrast Details, timetable identity, temporary requirement review, explicit
run start/completion, matching GPS, selected-segment report relevance,
five-False hiding and reports immediately above optional Save Trip. Opening
and inspecting Details performs zero journey writes. Existing save/retry,
fare, ETA, window and matching tests remain part of the full suite.

This pass does not claim complete localization of every nested widget:
remaining accessibility evidence explanations, map/progress panels and report
detail/action screens require their own review. Fluent Sinhala/Tamil review,
native fonts/TalkBack and device QA remain required. Tests use isolated
in-memory fixtures; no real Firebase/Auth mutation, real GPS, deployment,
billing change or APK build/install is included.
