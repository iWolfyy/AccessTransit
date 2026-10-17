import 'package:flutter/widgets.dart';

import 'localization_context.dart';
import 'recovery_presentation.dart';

/// Fixed registration/onboarding labels, never user input or persisted role values.
extension RegistrationPresentation on BuildContext {
  String registrationText(String label) => switch (label) {
    "Register" => l10n.registrationTitle,
    "Join Access Transit" => l10n.registrationJoin,
    "Your journey to inclusive travel begins here." => l10n.registrationIntro,
    "Enter your full name" => l10n.registrationNameHint,
    "Enter your email" => l10n.registrationEmailHint,
    "Password" => l10n.registrationPassword,
    "Create a password" => l10n.registrationPasswordHint,
    "Confirm Password" => l10n.registrationConfirm,
    "Re-enter your password" => l10n.registrationConfirmHint,
    "I have specific accessibility needs" => l10n.registrationNeeds,
    "(e.g., wheelchair ramp, low floor bus)" => l10n.registrationNeedsExample,
    "Account Type" => l10n.registrationAccountType,
    "Create Account" => l10n.registrationCreate,
    "OR" => l10n.registrationOr,
    "Sign up with Google" => l10n.registrationGoogle,
    "Sign up with Apple" => l10n.registrationApple,
    "Google sign-up" => l10n.registrationGoogleFeature,
    "Apple sign-up" => l10n.registrationAppleFeature,
    "Already have an account? " => l10n.registrationAlready,
    "Log in" => l10n.registrationLogin,
    "An account already exists with this email." => l10n.registrationExists,
    "Email/password authentication is not enabled." =>
      l10n.registrationNotEnabled,
    "Please fill in all required fields properly." =>
      l10n.registrationRequiredFields,
    "Registration failed. Please check your connection and try again." =>
      l10n.registrationFailed,
    "Please enter your full name." => l10n.registrationNameRequired,
    "Name must be at least 2 characters." => l10n.registrationNameShort,
    "Name can only contain letters and spaces." => l10n.registrationNameLetters,
    "Use letters, spaces, apostrophes, periods or hyphens in your name." =>
      l10n.registrationNameLetters,
    "Skip onboarding" => l10n.onboardingSkipTooltip,
    "Skip" => l10n.onboardingSkip,
    "Get Started" => l10n.onboardingStart,
    "Next" => l10n.onboardingNext,
    "Tailored for You" => l10n.onboardingTailored,
    "Choose wheelchair and step-free needs, then review current evidence. Voice guidance is unavailable." =>
      l10n.onboardingNeedsHelp,
    "Navigate with Confidence" => l10n.onboardingNavigate,
    "Preview only. Check shared GPS when available; assistance needs an operator response." =>
      l10n.onboardingLiveHelp,
    "Be the Eyes of the Community" => l10n.onboardingCommunity,
    "Share ramp and elevator observations. Reports are public after upload acknowledgement; rewards need review." =>
      l10n.onboardingReportsHelp,
    "Report Issue" => l10n.onboardingReportIssue,
    "Ramps" => l10n.onboardingRamps,
    "Low-floor" => l10n.onboardingLowFloor,
    "Example ETA: 3 min" => l10n.onboardingExampleEta,
    "Boarding Help" => l10n.onboardingBoardingHelp,
    "Example: awaiting reply" => l10n.onboardingAwaitingReply,
    _ => label,
  };
  String? registrationValidation(String? value) =>
      value == null ? null : registrationText(recoveryText(value));
  String registrationFailure(String code) => switch (code) {
    'email-already-in-use' => l10n.registrationExists,
    'operation-not-allowed' => l10n.registrationNotEnabled,
    'channel-error' => l10n.registrationRequiredFields,
    'invalid-email' ||
    'weak-password' ||
    'network-request-failed' ||
    'too-many-requests' => recoveryFailure(code, reset: false),
    _ => l10n.registrationFailed,
  };
}
