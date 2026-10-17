import 'dart:async';

import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/l10n/login_settings_presentation.dart';
import 'package:access_transit/models/user_model.dart';
import 'package:access_transit/screens/auth/login_screen.dart';
import 'package:access_transit/screens/preferences/accessibility_preferences_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account_preferences_test.dart' show ControlledPreferences;
import 'registration_onboarding_localization_test.dart' show host, narrow;

class LoginFixture extends AuthService {
  final outcome = Completer<UserCredential>();
  int calls = 0;
  @override
  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    calls++;
    return outcome.future;
  }

  @override
  Future<UserModel?> getCurrentUserProfile() async => null;
  @override
  Future<bool> hasAdminAccess() async => false;
}

class CredentialFixture extends Fake implements UserCredential {}

Future<void> press(WidgetTester t, String label) async {
  t.testTextInput.hide();
  await t.pumpAndSettle();
  final target = find.text(label);
  await t.scrollUntilVisible(
    target,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await t.pumpAndSettle();
  await t.tap(target);
  await t.pump();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init(userId: 'a');
    await AccessibilityPreferencesService.instance.setHighContrast(false);
  });
  testWidgets(
    'pending settings save cannot acknowledge or navigate another account',
    (t) async {
      narrow(t);
      final l = lookupAppLocalizations(const Locale('si'));
      final prefs = ControlledPreferences();
      final service = AccessibilityPreferencesService.instance;
      await service.init(prefs: prefs, userId: 'a');
      await t.pumpWidget(host('si', const AccessibilityPreferencesScreen()));
      prefs.gate = Completer<void>();
      await press(t, l.settingsSave);
      final switching = service.activateAccount('b');
      prefs.gate!.complete();
      await switching;
      await t.pumpAndSettle();
      expect(service.userId, 'b');
      expect(find.byType(AccessibilityPreferencesScreen), findsOneWidget);
      expect(find.text(l.settingsAccountSaved), findsNothing);
      expect(
        prefs.values.containsKey(
          AccessibilityPreferencesService.accountKey('b'),
        ),
        isFalse,
      );
      expect(t.takeException(), isNull);
    },
  );
  for (final lang in ['en', 'si', 'ta']) {
    testWidgets(
      'login $lang validates and waits for acknowledged authentication',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        final auth = LoginFixture();
        await t.pumpWidget(host(lang, LoginScreen(authService: auth)));
        await press(t, l.signIn);
        expect(find.text(l.recoveryEmailRequired), findsOneWidget);
        expect(find.text(l.loginPasswordRequired), findsOneWidget);
        expect(auth.calls, 0);
        final fields = find.byType(TextFormField);
        await t.enterText(fields.at(0), 'fixture@example.com');
        await t.enterText(fields.at(1), 'FixturePassword25!');
        await press(t, l.signIn);
        expect(auth.calls, 1);
        expect(find.byType(AccessibilityPreferencesScreen), findsNothing);
        auth.outcome.complete(CredentialFixture());
        await t.pumpAndSettle();
        expect(find.byType(AccessibilityPreferencesScreen), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets('login $lang shows safe translated provider errors', (t) async {
      narrow(t);
      final l = lookupAppLocalizations(Locale(lang));
      final auth = LoginFixture();
      await t.pumpWidget(host(lang, LoginScreen(authService: auth)));
      final fields = find.byType(TextFormField);
      await t.enterText(fields.at(0), 'fixture@example.com');
      await t.enterText(fields.at(1), 'FixturePassword25!');
      await press(t, l.signIn);
      auth.outcome.completeError(
        FirebaseAuthException(
          code: 'invalid-credential',
          message: 'PRIVATE PROVIDER DETAIL',
        ),
      );
      await t.pumpAndSettle();
      expect(find.text(l.loginInvalidCredentials), findsOneWidget);
      expect(find.textContaining('PRIVATE PROVIDER DETAIL'), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets(
      'settings $lang saves only after receipt and keeps unsupported controls disabled',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        final prefs = ControlledPreferences();
        await AccessibilityPreferencesService.instance.init(
          prefs: prefs,
          userId: 'a',
        );
        await t.pumpWidget(
          host(
            lang,
            Builder(
              builder: (c) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(c).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AccessibilityPreferencesScreen(),
                    ),
                  ),
                  child: const Text('OPEN'),
                ),
              ),
            ),
          ),
        );
        await t.tap(find.text('OPEN'));
        await t.pumpAndSettle();
        final walking = find.text(l.settingsWalking);
        await t.scrollUntilVisible(
          walking,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await t.pumpAndSettle();
        final row = find
            .ancestor(of: walking, matching: find.byType(InkWell))
            .first;
        expect(t.widget<InkWell>(row).onTap, isNull);
        await press(t, l.settingsLargeTargets);
        await t.pumpAndSettle();
        expect(find.text(l.settingsTargetsStandard), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.pump(const Duration(seconds: 2));
        await t.pumpAndSettle();
        prefs.gate = Completer<void>();
        await press(t, l.settingsSave);
        expect(find.byType(AccessibilityPreferencesScreen), findsOneWidget);
        expect(find.text(l.settingsAccountSaved), findsNothing);
        prefs.gate!.complete();
        await t.pumpAndSettle();
        expect(find.byType(AccessibilityPreferencesScreen), findsNothing);
        expect(find.text(l.settingsAccountSaved), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'settings $lang failure remains on screen with translated retry message',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        final prefs = ControlledPreferences();
        await AccessibilityPreferencesService.instance.init(
          prefs: prefs,
          userId: 'a',
        );
        await t.pumpWidget(host(lang, const AccessibilityPreferencesScreen()));
        prefs.reject = true;
        await press(t, l.settingsSave);
        await t.pumpAndSettle();
        expect(find.byType(AccessibilityPreferencesScreen), findsOneWidget);
        expect(find.text(l.settingsSaveFailed), findsOneWidget);
        expect(find.text(l.settingsAccountSaved), findsNothing);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'login $lang maps stable error codes without exposing server messages',
      (t) async {
        final l = lookupAppLocalizations(Locale(lang));
        await t.pumpWidget(
          host(
            lang,
            Builder(
              builder: (c) {
                expect(c.loginFailure('user-disabled'), l.loginDisabled);
                expect(
                  c.loginFailure('network-request-failed'),
                  l.loginNetwork,
                );
                expect(c.loginFailure('too-many-requests'), l.loginTooMany);
                expect(c.loginFailure('unknown-private-code'), l.loginFailed);
                return const SizedBox();
              },
            ),
          ),
        );
      },
    );
  }
}
