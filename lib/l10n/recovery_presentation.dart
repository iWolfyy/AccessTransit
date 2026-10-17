import 'package:flutter/widgets.dart';

import 'localization_context.dart';

/// Only fixed presentation messages, never email addresses, passwords or codes.
extension RecoveryPresentation on BuildContext {
  String recoveryText(String label) => switch (label) {
    "Reset Password" => l10n.recoveryTitle,
    "Check your email" => l10n.recoveryCheckEmail,
    "Please check your inbox and follow the link to create a new password." =>
      l10n.recoveryInboxHelp,
    "Back to Login" => l10n.recoveryBackLogin,
    "Resend email" => l10n.recoveryResend,
    "Forgot your password?" => l10n.recoveryForgot,
    "Enter the email address associated with your account and we'll send you instructions to reset your password." =>
      l10n.recoveryEmailHelp,
    "Email Address" => l10n.recoveryEmail,
    "e.g., name@example.com" => l10n.recoveryEmailHint,
    "We will never share your email." => l10n.recoveryPrivacy,
    "Send Reset Link" => l10n.recoverySend,
    "Create New Password" => l10n.recoveryCreate,
    "Please choose a strong password that you haven't used before." =>
      l10n.recoveryPasswordHelp,
    "New Password" => l10n.recoveryNewPassword,
    "Enter your new password" => l10n.recoveryPasswordHint,
    "Confirm New Password" => l10n.recoveryConfirm,
    "Re-enter your new password" => l10n.recoveryConfirmHint,
    "Show password" => l10n.recoveryShow,
    "Hide password" => l10n.recoveryHide,
    "Your security is our priority." => l10n.recoverySecurity,
    "Password Updated" => l10n.recoveryUpdated,
    "Your password has been reset successfully. You can now sign in with your new password." =>
      l10n.recoverySuccess,
    "Go to Login" => l10n.recoveryGoLogin,
    "Please enter your email address." => l10n.recoveryEmailRequired,
    "Please enter a valid email address." => l10n.recoveryEmailInvalid,
    "No account was found with this email address." =>
      l10n.recoveryAccountMissing,
    "This account has been disabled." => l10n.recoveryDisabled,
    "Too many requests. Please try again later." => l10n.recoveryTooMany,
    "Network error. Please check your internet connection." =>
      l10n.recoveryNetwork,
    "Unable to send password reset email." => l10n.recoverySendFailed,
    "Unable to reset password. Please try again." => l10n.recoveryResetFailed,
    "This reset link is invalid or has expired. Please request a new one." =>
      l10n.recoveryLinkUnavailable,
    "This reset link has expired. Please request a new one." =>
      l10n.recoveryExpired,
    "This reset link is invalid. Please request a new one." =>
      l10n.recoveryInvalid,
    "Password is too weak. Please choose a stronger password." =>
      l10n.recoveryWeak,
    "Please create a password." => l10n.recoveryCreateRequired,
    "Password must be at least 8 characters." => l10n.recoveryEightCharacters,
    "Password must include at least one letter." => l10n.recoveryLetterRequired,
    "Password must include at least one number." => l10n.recoveryNumberRequired,
    "Please confirm your password." => l10n.recoveryConfirmRequired,
    "Passwords do not match." => l10n.recoveryMismatch,
    "Password strength" => l10n.recoveryStrength,
    "Weak — add more characters" => l10n.recoveryStrengthWeak,
    "Fair — try adding numbers or symbols" => l10n.recoveryStrengthFair,
    "Good strength" => l10n.recoveryStrengthGood,
    "Strong password" => l10n.recoveryStrengthStrong,
    "Something went wrong. Please try again." => l10n.recoverySendFailed,
    "Unable to reset password." => l10n.recoveryResetFailed,
    _ => label,
  };
  String? recoveryValidation(String? message) =>
      message == null ? null : recoveryText(message);

  String recoveryFailure(String code, {required bool reset}) => switch (code) {
    'invalid-email' => l10n.recoveryEmailInvalid,
    'user-not-found' => l10n.recoveryAccountMissing,
    'user-disabled' => l10n.recoveryDisabled,
    'too-many-requests' => l10n.recoveryTooMany,
    'network-request-failed' => l10n.recoveryNetwork,
    'expired-action-code' => l10n.recoveryExpired,
    'invalid-action-code' => l10n.recoveryInvalid,
    'weak-password' => l10n.recoveryWeak,
    _ => reset ? l10n.recoveryResetFailed : l10n.recoverySendFailed,
  };
}
