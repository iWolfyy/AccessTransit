# Profile and shared sign-out presentation

The Profile screen uses generated English, Sinhala and Tamil resources for
roles, settings/support links, personal-information labels, contribution
summaries, edit validation, save acknowledgement and failure states.
`profile_presentation.dart` maps only fixed UI labels. Names, phone numbers,
email addresses, stored role values and contribution totals remain data.
Signed contribution balances are passed as integers to the localized summary.

The edit sheet wraps its heading and save action at large text sizes. The
profile header email/edit control, sign-out row and badge strip also adapt to
narrow screens. The previous fixed “9 more badges” claim is replaced with a
badge-details label. Unsupported profile links retain their future-update
message. The Profile Delete Account entry explicitly says self-service
deletion is unavailable here; it does not invoke the administrator's reviewed
deletion workflow.

The shared sign-out dialog localizes its confirmation, cancellation and draft
cleanup disclosure. Home, Profile and Driver capture localized success/failure
messages before awaiting sign-out, so changing the signed-in account's locale
does not change the outcome message. Draft cleanup, Auth sign-out and driver
trip handling keep their existing behavior.

`test/profile_localization_test.dart` covers all three locales at 320dp and
200% text, including high contrast, unchanged profile values, negative points,
unavailable deletion, required names, failed/unacknowledged saves and both
sign-out decisions. It initializes no Firebase project and performs no shared
profile, Auth or deletion mutation. Existing sign-out and accessibility
regressions are also run. These automated checks do not replace fluent
Sinhala/Tamil review, native font inspection or TalkBack testing.

Remaining operational/dashboard wording is a separate localization pass.
This change does not claim whole-app translation completion or native/device QA.
