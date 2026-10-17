# Password recovery presentation

Forgot Password, Reset Password and Password Updated use generated English,
Sinhala and Tamil resources (47 entries per locale). Email/password labels,
instructions, validation, visibility tooltips, strength feedback and outcomes
are localized. Firebase error codes select presentation messages; unknown
errors use retry guidance instead of displaying raw provider messages.

Validation still uses the existing `Validators` rules. Password strength
calculation and reset-code verification/confirmation remain unchanged.
`PasswordStrengthIndicator` translates its visible feedback wherever it is
used, including registration. `AuthInputField` allows multiline validation
errors so translated messages can wrap.

The recovery screens retain the existing service path by default. Their
optional `AuthService` argument permits isolated UI fixtures. Tests supply
in-memory services; no Firebase project, email delivery or real account reset
is required. Missing action codes never reach Auth. The success screen is
entered only after verification and password confirmation return successfully.
Failure ends loading and leaves the form available for retry.

The reset-email acknowledgement displays a snapshot of the email submitted to
the service, even if the text field changes while the request is pending.
Resend keeps its existing behavior: return to the email form, then submit a
new request. The acknowledged address does not change until another request
succeeds. This screen state is transient and is not account preference storage.

Headers and security notes wrap, actions can grow vertically, and the final
success card scrolls at large text sizes. Automated coverage runs all three
locales at 320dp/200% text, includes high-contrast invalid-link handling, checks
validation, delayed acknowledgement, resend, failed confirmation and safe
error fallbacks, and retains reset-link/touch-target regressions.

Fluent Sinhala/Tamil review, native fonts/TalkBack/keyboard inspection and
actual reset-email/deep-link delivery on the intended device remain separate
release checks. No real email, password/Auth mutation, shared data write,
deployment or APK build/install is performed by this localization pass.
