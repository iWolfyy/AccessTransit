# Login and accessibility Settings presentation

Login and Accessibility Preferences use generated English, Sinhala and Tamil
resources for their remaining labels, validation, provider failures, tooltips,
switch semantics and save feedback. This pass adds 46 entries per locale and
reuses existing email/password, profile and Material navigation resources.
Provider errors map from stable codes to localized guidance; unknown errors
show a generic retry message without the provider's raw message.

Login retains the existing AuthService flow, trusted admin-claim check and
role routing. Optional service injection enables isolated UI tests; the main
app uses the same production service by default. Google and biometric buttons
remain future-update placeholders. Email/password rules are unchanged.

Settings retains its existing persistence: supported toggles apply through
the preference service, and Save awaits its write before feedback/navigation.
High contrast and target size are device preferences; travel needs are stored
separately per account on this device, with transient guest needs. This pass
does not add cross-device synchronization or change temporary search drafts.
An account change suppresses a pending previous account's save feedback and
navigation. A failed save stays on Settings with retry guidance. Unsupported
walking, voice, haptic, automatic assistance and quiet-route controls remain
disabled and explain their limitations.

Login/social and Settings save buttons retain their minimum touch heights
and can grow to accommodate translated text. Automated tests exercise all
three locales at 320dp and 200% text, local validation, acknowledged login,
safe provider errors, disabled controls, delayed/failed preference writes and
account switching during a save. Fixtures use in-memory authentication and
preferences without real Firebase writes. Existing account/search preference
tests continue to cover draft isolation and account-scoped persistence.

Fluent Sinhala/Tamil review and native font/TalkBack/device checks are still
required. This is a presentation pass, not a claim that all app screens have
complete translations. No APK build/install, live deployment, provider
activation or billing change is part of this work.
