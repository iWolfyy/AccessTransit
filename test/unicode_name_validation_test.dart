import 'package:access_transit/core/utils/validators.dart';
import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/models/enums/user_role.dart';
import 'package:access_transit/screens/auth/register_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'registration_onboarding_localization_test.dart' as registration;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init();
    await AccessibilityPreferencesService.instance.setHighContrast(false);
  });
  test('Sinhala/Tamil names, marks, conjuncts and established punctuation pass without rewriting', () {
    for (final name in [
      'කසුන් පෙරේරා',
      'ශ්‍රී කාන්ත්',
      'சிவா குமார்',
      'தமிழ்ச்செல்வன்',
      'Anne-Marie',
      "O'Connor",
      'O’Connor',
      'A. Perera',
      'Jean‑Luc',
      'José Silva',
      'Jose\u0301 Silva',
      '  කසුන් පෙරේරා  ',
      '阿明',
    ]) {
      expect(Validators.fullName(name), isNull, reason: name);
    }
  });

  test(
    'name minimum uses visible characters rather than combining code units',
    () {
      for (final name in ['A', 'é', 'e\u0301', 'கு', 'කී']) {
        expect(
          Validators.fullName(name),
          'Name must be at least 2 characters.',
          reason: name,
        );
      }
      expect(Validators.fullName('குமார்'), isNull);
      expect(Validators.fullName('කසුන්'), isNull);
    },
  );

  test(
    'blank, punctuation-only, orphan marks and non-name input are rejected',
    () {
      expect(Validators.fullName(null), 'Please enter your full name.');
      expect(Validators.fullName('   '), 'Please enter your full name.');
      for (final name in [
        '..',
        "' -",
        '\u0301\u0300',
        '1234',
        'Rider25',
        'Name😀',
        '<Name>',
        'Na\nme',
        'Na\tme',
        'Na\u0000me',
        'Na\u202Eme',
        'Na\u200Bme',
        '\u200DName',
      ]) {
        expect(Validators.fullName(name), isNotNull, reason: name);
      }
    },
  );

  for (final entry in {
    'en': 'Anne-Marie O’Connor',
    'si': 'ශ්‍රී කාන්ත්',
    'ta': 'தமிழ்ச்செல்வன்',
  }.entries) {
    testWidgets('registration ${entry.key} submits the original Unicode name', (
      t,
    ) async {
      registration.narrow(t);
      final l = lookupAppLocalizations(Locale(entry.key));
      final f = registration.RegistrationFixture();
      await t.pumpWidget(
        registration.host(entry.key, RegisterScreen(authService: f)),
      );
      await t.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await t.enterText(fields.at(0), '  ${entry.value}  ');
      await t.enterText(fields.at(1), 'fixture@example.com');
      await t.enterText(fields.at(2), 'ExamplePassword25!');
      await t.enterText(fields.at(3), 'ExamplePassword25!');
      t.testTextInput.hide();
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text(l.registrationCreate).hitTestable(),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await t.pumpAndSettle();
      await t.tap(find.text(l.registrationCreate).hitTestable());
      await t.pump();
      expect(f.submittedName, entry.value);
      expect(f.submittedRole, UserRole.passenger);
      f.outcome.completeError(
        FirebaseAuthException(code: 'network-request-failed'),
      );
      await t.pumpAndSettle();
      expect(find.text(l.recoveryNetwork), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
}
