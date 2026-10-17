# Assistance request form presentation

Boarding/alighting assistance entry uses generated English, Sinhala and Tamil
resources for selection labels, target confirmation, validation/failure messages,
boarding/alighting stop context and estimated-arrival wording. This pass adds
23 resources per locale and reuses the existing assistance-type translations
in the review. Bus/route/stop names remain data.

The submitted values remain `Deploy Ramp`, `Extra Time`, `Boarding Help` and
`Alighting Help`; translated labels do not alter enum values or target IDs.
Review uses the verified catalogue bus and stop. Editing the review retains
selection and does not enqueue a request. Confirmed submissions continue to
the existing delivery/status screen and acknowledged submission service.

Identity is captured before target lookup/review and checked again before
enqueue. An account change during review requires reviewing again; signed-out
users retain explicit sign-in guidance. This adds a client safeguard alongside
the existing backend authorization, rather than granting permission by UI state.

Selection cards, action controls and the header use minimum heights; full labels
wrap and the arriving-bus panel stacks on narrow or large-text layouts. Unknown
ETA remains unknown, and estimated times are labelled as estimates. Driver
acknowledgement is still required before assistance is described as confirmed.

Nine new tests cover all three locales at 320dp/200% text with normal/high
contrast: required selection, exact-target review/edit, stable submission
payloads, boarding/alighting context, unknown/estimated arrival and account
change during review. Existing invalid-target, guest and missing-run tests also
pass. Tests use injected identity/catalogue/publisher fixtures and make no real
Firebase/Auth/assistance writes.

Request-status and saved-receipt panel localization is separate remaining work.
Fluent translation review and physical-device/font/TalkBack validation remain
required. No APK build/install, backend deployment or billing change is included.
