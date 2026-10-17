import 'dart:async';

import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/l10n/recovery_presentation.dart';
import 'package:access_transit/screens/auth/forgot_password_screen.dart';
import 'package:access_transit/screens/auth/reset_password_screen.dart';
import 'package:access_transit/screens/auth/password_reset_success_screen.dart';
import 'package:access_transit/services/auth_service.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecoveryFixture extends AuthService {
  final sent = <String>[];
  final verified = <String>[];
  final confirmed = <String>[];
  final send = <Completer<void>>[];
  Completer<void> confirm = Completer<void>();
  @override
  Future<void> sendPasswordResetEmail(String email) {
    sent.add(email);
    final result = Completer<void>();
    send.add(result);
    return result.future;
  }

  @override
  Future<String> verifyPasswordResetCode(String code) async {
    verified.add(code);
    return 'original@example.com';
  }

  @override
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) {
    confirmed.add(code);
    return confirm.future;
  }
}

Widget host(String lang, Widget child) => MaterialApp(
  locale: Locale(lang),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (c, w) => MediaQuery(
    data: MediaQuery.of(c).copyWith(textScaler: const TextScaler.linear(2)),
    child: w!,
  ),
  home: child,
);
void narrow(WidgetTester t) {
  t.view.physicalSize = const Size(320, 1200);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

Future<void> press(WidgetTester t, String label) async {
  await t.ensureVisible(find.text(label).last);
  await t.pumpAndSettle();
  await t.tap(find.text(label).last);
  // Pending requests show an indeterminate spinner, so don't settle here.
  await t.pump();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init();
    await AccessibilityPreferencesService.instance.setHighContrast(false);
  });
  for (final lang in ['en', 'si', 'ta']) {
    testWidgets(
      'reset failure $lang leaves retry available without success or raw provider details',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        final f = RecoveryFixture();
        await t.pumpWidget(
          host(
            lang,
            ResetPasswordScreen(actionCode: 'fixture-code', authService: f),
          ),
        );
        await t.pumpAndSettle();
        await t.enterText(
          find.byType(TextFormField).first,
          'ExamplePassword25!',
        );
        await t.enterText(
          find.byType(TextFormField).last,
          'ExamplePassword25!',
        );
        await press(t, l.recoveryTitle);
        await t.pump();
        f.confirm.completeError(
          FirebaseAuthException(
            code: 'future-code',
            message: 'private provider detail',
          ),
        );
        await t.pumpAndSettle();
        expect(find.text(l.recoveryResetFailed), findsOneWidget);
        expect(find.byType(PasswordResetSuccessScreen), findsNothing);
        expect(find.textContaining('private provider detail'), findsNothing);
        expect(
          t.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull,
        );
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'forgot $lang validates, awaits receipt, preserves address and retries from the form',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        final f = RecoveryFixture();
        await t.pumpWidget(host(lang, ForgotPasswordScreen(authService: f)));
        await t.pumpAndSettle();
        await press(t, l.recoverySend);
        await t.pumpAndSettle();
        expect(find.text(l.recoveryEmailRequired), findsOneWidget);
        expect(f.sent, isEmpty);
        await t.enterText(find.byType(TextFormField), 'original@example.com');
        await press(t, l.recoverySend);
        expect(find.text(l.recoveryCheckEmail), findsNothing);
        expect(f.sent, ['original@example.com']);
        await t.enterText(find.byType(TextFormField), 'changed@example.com');
        f.send[0].complete();
        await t.pumpAndSettle();
        expect(
          find.text(l.recoveryInstructionsSent('original@example.com')),
          findsOneWidget,
        );
        await press(t, l.recoveryResend);
        await t.pumpAndSettle();
        await t.enterText(find.byType(TextFormField), 'original@example.com');
        await press(t, l.recoverySend);
        expect(f.sent, ['original@example.com', 'original@example.com']);
        f.send[1].completeError(
          FirebaseAuthException(
            code: 'network-request-failed',
            message: 'private server detail',
          ),
        );
        await t.pumpAndSettle();
        expect(find.text(l.recoveryNetwork), findsOneWidget);
        expect(find.textContaining('private server detail'), findsNothing);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'reset $lang validates and shows success only after confirm receipt',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        final f = RecoveryFixture();
        await t.pumpWidget(
          host(
            lang,
            ResetPasswordScreen(actionCode: 'fixture-code', authService: f),
          ),
        );
        await t.pumpAndSettle();
        await press(t, l.recoveryTitle);
        await t.pumpAndSettle();
        expect(find.text(l.recoveryCreateRequired), findsOneWidget);
        expect(find.text(l.recoveryConfirmRequired), findsOneWidget);
        await t.enterText(
          find.byType(TextFormField).first,
          'ExamplePassword25!',
        );
        await t.enterText(find.byType(TextFormField).last, 'different');
        await press(t, l.recoveryTitle);
        await t.pumpAndSettle();
        expect(find.text(l.recoveryMismatch), findsOneWidget);
        expect(f.verified, isEmpty);
        await t.enterText(
          find.byType(TextFormField).last,
          'ExamplePassword25!',
        );
        await press(t, l.recoveryTitle);
        await t.pump();
        expect(f.verified, ['fixture-code']);
        expect(f.confirmed, ['fixture-code']);
        expect(find.byType(PasswordResetSuccessScreen), findsNothing);
        f.confirm.complete();
        await t.pumpAndSettle();
        expect(find.text(l.recoveryUpdated), findsOneWidget);
        expect(find.text(l.recoverySuccess), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets('missing reset link $lang never contacts Auth', (t) async {
      narrow(t);
      await AccessibilityPreferencesService.instance.setHighContrast(true);
      final l = lookupAppLocalizations(Locale(lang));
      final f = RecoveryFixture();
      await t.pumpWidget(host(lang, ResetPasswordScreen(authService: f)));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField).first, 'ExamplePassword25!');
      await t.enterText(find.byType(TextFormField).last, 'ExamplePassword25!');
      await press(t, l.recoveryTitle);
      await t.pumpAndSettle();
      expect(find.text(l.recoveryLinkUnavailable), findsOneWidget);
      expect(f.verified, isEmpty);
      expect(f.confirmed, isEmpty);
      expect(find.byType(PasswordResetSuccessScreen), findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets(
      'recovery errors $lang expose code-specific guidance with safe fallbacks',
      (t) async {
        final l = lookupAppLocalizations(Locale(lang));
        late BuildContext c;
        await t.pumpWidget(
          host(
            lang,
            Builder(
              builder: (context) {
                c = context;
                return const SizedBox();
              },
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(
          c.recoveryFailure('expired-action-code', reset: true),
          l.recoveryExpired,
        );
        expect(
          c.recoveryFailure('invalid-action-code', reset: true),
          l.recoveryInvalid,
        );
        expect(c.recoveryFailure('weak-password', reset: true), l.recoveryWeak);
        expect(
          c.recoveryFailure('too-many-requests', reset: false),
          l.recoveryTooMany,
        );
        expect(
          c.recoveryFailure('future-code', reset: true),
          l.recoveryResetFailed,
        );
        expect(
          c.recoveryFailure('future-code', reset: false),
          l.recoverySendFailed,
        );
      },
    );
  }
}
