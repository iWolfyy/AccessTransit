# Shared language, contrast and touch preferences

Implemented in the main app source on 2026-10-17. This extends the individual
screen localization checkpoints; it does not describe an installed APK or a
native accessibility certification.

## App-wide behavior

`AccessTransitApp` builds the effective theme with `AppTheme.forPreferences`.
Buttons, icon buttons, app-bar leading controls, inputs, list tiles, chips and
dialog controls inherit the current preferences. Normal controls use a 48dp
minimum; Large tap targets uses 60dp. Content may grow beyond that minimum for
translated labels and increased text size. Existing explicit button minimums
also follow these sizes.

Custom tap regions, switches and chips use `AccessibleTapTarget`. Dropdown
rows use `AccessibleDropdownMenuItem` with variable item heights so a long
translated option can wrap. The language menu and admin, driver, report and
segment-report selectors share this behavior. On narrow screens, large-target
date/time pickers open in their localized input mode; date/time validation and
the boarding-search horizon are unchanged.

High contrast supplies the shared palette, outlined cards, readable chip
labels/checkmarks and contextual foreground colors. Custom driver statuses,
delay controls, auth fields, navigation and map controls use the contrast
tokens as well. Geographic tiles, evidence photos and original user content
retain their meaning and appearance; a stop-list alternative remains available.

## Language coverage

English, Sinhala and Tamil resources now cover the remaining catalogue
saved/offline/empty/refresh states, admin authorization gate, Add Stop dialog,
saved-trip controls/recovery, assistance actions and failures, stop-alert
availability, live accessibility observations and splash text. Retained legacy
journey entry points also translate fixed labels, dates, ETA and delay wording.
An old unassigned-bus message no longer claims that a seat booking is confirmed.
The main passenger path remains Search -> Results -> Bus Details.

Runtime language changes preserve canonical tab, issue, route, bus, run and
stop identifiers. Assistance failures are retained as state and rendered in
the current language. Unknown save/provider errors show localized retry
guidance instead of exposing arbitrary provider text. A failed catalogue
refresh retains an explicit unavailable/stale state and allows another attempt.
The catalogue notice can scroll within a bounded area on a small screen.

Original catalogue names, IDs, custom tiers, rider/driver descriptions, technical
version identifiers, the AccessTransit brand, language autonyms and map-source
attribution are data or identifiers. They are not automatically translated.
Known delay reasons translate, while custom reasons remain original.

## Validation and limits

`test/shared_accessibility_localization_test.dart` adds 21 checks, exercising
all three locales, 320dp screens, 200% text, normal/high contrast, reactive
60dp/48dp sizing, inputs/chips/app-bar controls, menu selection with stable IDs,
dialog actions, catalogue retry/failure states, denied admin access, disabled
stop-alert semantics, driver acknowledgements and language changes during a
displayed failure. No real report, assistance or administrative mutation is
used for these checks.

The focused final regressions passed 40 tests. The existing broader focused run
passed 64 tests. Final full-suite and analyzer evidence is recorded in checkpoint
69 of the implementation plan. All 1,716 resource keys are present in every
locale; 198 shared/retained presentation additions passed Unicode/script and
placeholder checks. A direct fixed-UI-literal inventory retains only the stated
brand, language, ID/example and map-attribution exceptions. This inventory is a
source check, not proof of every possible remote-content combination.

Fluent Sinhala/Tamil terminology review and physical-device font, TalkBack,
focus-order, picker/keyboard and screen-size checks remain release gates.
Automated layout checks and palette checks do not certify every rendered pixel
or native/platform surface. No APK build/install, shared Firebase/Auth/data
mutation, rules/backend deployment or billing change was performed for this work.
