import 'package:flutter/widgets.dart';

import 'localization_context.dart';
import 'recovery_presentation.dart';

/// Fixed labels/error codes only; account needs and user inputs stay unchanged.
extension LoginSettingsPresentation on BuildContext {
  String loginSettingsText(String label) => switch (label) {
    "Login failed. Please try again." => l10n.loginFailed,
    "Invalid email or password. Please check your details and try again." =>
      l10n.loginInvalidCredentials,
    "This account has been disabled. Please contact support." =>
      l10n.loginDisabled,
    "Too many login attempts. Please wait a moment and try again." =>
      l10n.loginTooMany,
    "Network error. Please check your connection and try again." =>
      l10n.loginNetwork,
    "Forgot Password?" => l10n.loginForgot,
    "Enter your password" => l10n.loginPasswordHint,
    "Please enter your password." => l10n.loginPasswordRequired,
    "Password must be at least 6 characters." => l10n.loginPasswordShort,
    "Or continue with" => l10n.loginOrContinue,
    "Sign in with Biometrics" => l10n.loginBiometrics,
    "Biometric sign-in" => l10n.loginBiometricFeature,
    "Sign in with Google" => l10n.loginGoogle,
    "Google sign-in" => l10n.loginGoogleFeature,
    "Don't have an account?" => l10n.loginNoAccount,
    "Sign up" => l10n.loginSignUp,
    "Preferences could not be saved. Please retry." => l10n.settingsSaveFailed,
    "Device settings saved. Guest travel needs last for this session." =>
      l10n.settingsGuestSaved,
    "Preferences saved for this account on this device." =>
      l10n.settingsAccountSaved,
    "User profile" => l10n.settingsProfile,
    "Personalized Travel Experience" => l10n.settingsPersonalized,
    "High contrast and tap targets apply to this device. Travel needs are saved separately for each signed-in account on this device. Guest needs last for this session. New accounts start with wheelchair access required; review your needs." =>
      l10n.settingsScopeHelp,
    "Mobility & Physical Access" => l10n.settingsMobility,
    "Wheelchair access required" => l10n.settingsWheelchair,
    "Require current ramp evidence for matching buses" => l10n.settingsRampHelp,
    "Step-free routes only" => l10n.settingsStepFree,
    "Avoid stops and terminals requiring stairs" => l10n.settingsStepFreeHelp,
    "Minimize walking distance" => l10n.settingsWalking,
    "Not available yet — walking paths and distances have not been measured" =>
      l10n.settingsWalkingUnavailable,
    "Sensory & Vision" => l10n.settingsSensory,
    "High contrast mode" => l10n.settingsContrast,
    "Enhance text clarity and strong border lines (WCAG AAA)" =>
      l10n.settingsContrastHelp,
    "Large tap targets (48dp+)" => l10n.settingsLargeTargets,
    "Enforce minimum 48dp touch targets across buttons & controls" =>
      l10n.settingsTargetsHelp,
    "Large tap targets (48dp+) enabled" => l10n.settingsTargetsEnabled,
    "Standard tap targets enabled" => l10n.settingsTargetsStandard,
    "Voice guidance for navigation" => l10n.settingsVoice,
    "Not available yet — use your phone screen reader for spoken interface labels" =>
      l10n.settingsVoiceUnavailable,
    "Haptic alerts for stops" => l10n.settingsHaptics,
    "Not available yet — automatic vibration alerts are not supported" =>
      l10n.settingsHapticsUnavailable,
    "Assistance & Environment" => l10n.settingsAssistance,
    "Boarding assistance required" => l10n.settingsBoarding,
    "Automatic requests are not available yet — request assistance from the journey screen" =>
      l10n.settingsBoardingUnavailable,
    "Show quiet routes" => l10n.settingsQuiet,
    "Not available yet — noise levels are unknown" =>
      l10n.settingsQuietUnavailable,
    "Save Preferences" => l10n.settingsSave,
    _ => label,
  };
  String? loginValidation(String? value) =>
      value == null ? null : loginSettingsText(recoveryText(value));
  String loginFailure(String code) => switch (code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => l10n.loginInvalidCredentials,
    'invalid-email' => l10n.recoveryEmailInvalid,
    'user-disabled' => l10n.loginDisabled,
    'too-many-requests' => l10n.loginTooMany,
    'network-request-failed' => l10n.loginNetwork,
    _ => l10n.loginFailed,
  };
}
