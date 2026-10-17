# Registration and onboarding presentation

Registration labels, validation, social-provider placeholders and errors, and
all three onboarding pages use generated English/Sinhala/Tamil resources (43
new entries per locale). Shared recovery/profile resources supply existing
email/password validation, visibility labels and messages. Provider codes map
to localized guidance; unknown errors use retry wording without raw provider
messages. Registration diagnostics retain codes or exception types only.

Role enums and backend authorization are unchanged. The role selector still
offers passenger, contributor/reporter and operator/driver. Approval remains
required for drivers. Registration waits for its existing AuthService result
before navigating using the returned role. Optional service injection supports
isolated UI fixtures; production uses the same AuthService by default.
Google/Apple controls remain explicit future-update placeholders. No new Auth
provider is activated.

Password/email validation rules are unchanged. The subsequent Unicode-name
pass accepts letters and combining marks across scripts, including Sinhala
and Tamil, and preserves Indic joiners used in conjuncts. Unicode spaces,
apostrophes, periods and hyphens are supported. A name needs at least two
grapheme clusters and one letter; orphan marks, punctuation-only input,
digits, emoji and embedded control/format characters outside the supported
joiners are rejected. The existing outer trim remains; names are not
transliterated, normalized or rewritten. This is input validation, not identity
verification or protection against visually similar names.

The `characters` package was already present as a transitive dependency at
1.4.1 and is now declared directly for visible-character counting. Existing
stored profiles and backend rules are unchanged. Additional unit/widget
coverage checks Sinhala/Tamil conjuncts, decomposed accents, typography,
invalid controls and unchanged name submission from the real registration
form in all three locales. Native fonts/TalkBack and fluent name review remain
separate checks.

Onboarding descriptions and headings scale and scroll; fixed illustrative
artwork is decorative, excluded from semantics and uses a bounded text scale.
The actual page explanations and controls retain system text scaling. Preview
labels remain visibly example/preview wording. Descriptions still disclose
unavailable voice guidance, the need for an operator's assistance response and
acknowledged report publication. This pass adds no operational bus/GPS data.

Reduced-motion Next now uses an immediate page jump. The previous attempt to
animate with zero duration triggered a framework assertion. Normal-motion Next
retains its existing transition. Skip/Get Started still lead to Login.
Large-text checks also prompted small wrapping fixes in Login's password/help
row and divider, and Preferences' section heading on the registration
destination. Those screens retain their broader localization scope.

Widget fixtures cover all three locales at 320dp/200% text, required fields,
submitted driver/reporter role values, failed acknowledgement, successful
reporter routing, unsupported social sign-up, all onboarding pages and
high-contrast Skip at 320x800. Existing registration/profile preservation and
touch-target tests are retained. No real account is created and no actual
Auth/Firestore update, deployment, billing change or APK build occurs.
Fluent wording review, native font/TalkBack and device walkthroughs remain
release gates; this is not a whole-app localization completion claim.
