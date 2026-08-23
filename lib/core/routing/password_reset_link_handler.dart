/// Parses Firebase password reset deep links and extracts the action code.
class PasswordResetLinkHandler {
  PasswordResetLinkHandler._();

  /// Returns the password reset [oobCode] when the URI is a valid reset link.
  static String? parseResetCode(Uri uri) {
    final mode = uri.queryParameters['mode'];
    final oobCode = uri.queryParameters['oobCode'];

    if (mode == 'resetPassword' &&
        oobCode != null &&
        oobCode.isNotEmpty) {
      return oobCode;
    }

    return null;
  }
}
