import 'package:access_transit/core/routing/password_reset_link_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordResetLinkHandler', () {
    test('parseResetCode returns oobCode for valid reset link', () {
      final uri = Uri.parse(
        'https://accesstransit-b615b.firebaseapp.com/__/auth/action'
        '?mode=resetPassword&oobCode=abc123&lang=en',
      );

      expect(PasswordResetLinkHandler.parseResetCode(uri), 'abc123');
    });

    test('parseResetCode returns null for non-reset links', () {
      final uri = Uri.parse(
        'https://accesstransit-b615b.firebaseapp.com/__/auth/action'
        '?mode=verifyEmail&oobCode=abc123',
      );

      expect(PasswordResetLinkHandler.parseResetCode(uri), isNull);
    });

    test('parseResetCode returns null when oobCode is missing', () {
      final uri = Uri.parse(
        'https://accesstransit-b615b.firebaseapp.com/__/auth/action'
        '?mode=resetPassword',
      );

      expect(PasswordResetLinkHandler.parseResetCode(uri), isNull);
    });
  });
}
