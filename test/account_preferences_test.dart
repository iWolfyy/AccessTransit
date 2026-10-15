import 'dart:async';
import 'dart:convert';

import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/screens/preferences/accessibility_preferences_screen.dart';
import 'package:access_transit/screens/journey/journey_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ControlledPreferences extends Fake implements SharedPreferences {
  final values = <String, Object>{};
  Completer<void>? gate;
  bool reject = false;
  @override
  bool? getBool(String key) => values[key] as bool?;
  @override
  String? getString(String key) => values[key] as String?;
  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    if (gate != null) await gate!.future;
    if (reject) return false;
    values[key] = value;
    return true;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    if (reject) return false;
    values[key] = value;
    return true;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'delayed write finishes in the old owner slot after a rapid account switch',
    () async {
      final prefs = ControlledPreferences();
      final service = AccessibilityPreferencesService();
      await service.init(prefs: prefs, userId: 'a');
      prefs.gate = Completer<void>();
      final pending = service.savePreferences(
        isWheelchairOnly: false,
        isStepFree: true,
      );
      final switching = service.activateAccount('b');
      expect(service.isStepFree, isFalse);
      prefs.gate!.complete();
      await Future.wait([pending, switching]);
      expect(service.userId, 'b');
      expect(service.isStepFree, isFalse);
      expect(
        prefs.values.containsKey(
          AccessibilityPreferencesService.accountKey('b'),
        ),
        isFalse,
      );
      await service.activateAccount('a');
      expect(service.isWheelchairOnly, isFalse);
      expect(service.isStepFree, isTrue);
      service.dispose();
    },
  );
  test('storage rejection is surfaced; an old owner failure cannot mark the next account failed', () async {
    final prefs = ControlledPreferences();
    final service = AccessibilityPreferencesService();
    await service.init(prefs: prefs, userId: 'a');
    prefs.reject = true;
    await expectLater(service.setStepFree(true), throwsStateError);
    expect(service.storageError, contains('could not be saved'));
    prefs.gate = Completer<void>();
    final pending = service.setStepFree(false);
    final failure = expectLater(pending, throwsStateError);
    final switching = service.activateAccount('b');
    prefs.gate!.complete();
    await failure;
    await switching;
    expect(service.storageError, isNull);
    expect(service.isStepFree, isFalse);
    prefs.reject = false;
    await service.setStepFree(true);
    expect(
      prefs.values.containsKey(AccessibilityPreferencesService.accountKey('b')),
      isTrue,
    );
    service.dispose();
  });
  test('accounts restore only their own needs; guests reset without losing display controls', () async {
    final service = AccessibilityPreferencesService();
    await service.init(userId: 'a');
    await service.savePreferences(
      isWheelchairOnly: false,
      isStepFree: true,
      isHighContrast: true,
      hasLargeTargets: false,
    );
    final switchAccount = service.activateAccount('b');
    expect(service.isWheelchairOnly, isTrue);
    expect(service.isStepFree, isFalse); // Immediate, before asynchronous work.
    await switchAccount;
    expect(service.isHighContrast, isTrue);
    expect(service.hasLargeTargets, isFalse);
    await service.savePreferences(isWheelchairOnly: false, isStepFree: false);
    await service.activateAccount('a');
    expect(service.isWheelchairOnly, isFalse);
    expect(service.isStepFree, isTrue);
    await service.activateAccount(null);
    expect(service.isWheelchairOnly, isTrue);
    expect(service.isStepFree, isFalse);
    expect(service.isHighContrast, isTrue);
    expect(service.hasLargeTargets, isFalse);
    service.dispose();
  });
  test(
    'new sessions restore a UID record but never persist guest needs',
    () async {
      final first = AccessibilityPreferencesService();
      await first.init(userId: 'a');
      await first.savePreferences(isWheelchairOnly: false, isStepFree: true);
      await first.activateAccount(null);
      await first.savePreferences(isWheelchairOnly: false, isStepFree: true);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.containsKey(AccessibilityPreferencesService.keyWheelchairOnly),
        isFalse,
      );
      first.dispose();
      final restarted = AccessibilityPreferencesService();
      await restarted.init();
      expect(restarted.isWheelchairOnly, isTrue);
      expect(restarted.isStepFree, isFalse);
      await restarted.activateAccount('a');
      expect(restarted.isWheelchairOnly, isFalse);
      expect(restarted.isStepFree, isTrue);
      restarted.dispose();
    },
  );
  test(
    'unowned legacy needs are discarded without changing device accessibility',
    () async {
      SharedPreferences.setMockInitialValues({
        'isHighContrast': true,
        'hasLargeTargets': false,
        'isWheelchairOnly': false,
        'isStepFree': true,
        'voiceGuidance': true,
      });
      final service = AccessibilityPreferencesService();
      await service.init(userId: 'new-owner');
      expect(service.isWheelchairOnly, isTrue);
      expect(service.isStepFree, isFalse);
      expect(service.isHighContrast, isTrue);
      expect(service.hasLargeTargets, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('isStepFree'), isFalse);
      expect(prefs.containsKey('isWheelchairOnly'), isFalse);
      expect(prefs.containsKey('voiceGuidance'), isFalse);
      expect(
        prefs.containsKey(
          AccessibilityPreferencesService.accountKey('new-owner'),
        ),
        isFalse,
      );
      service.dispose();
    },
  );
  test('overlapping saves capture their owner and final account ignores older completions', () async {
    final service = AccessibilityPreferencesService();
    await service.init(userId: 'a');
    final oldSave = service.savePreferences(
      isWheelchairOnly: false,
      isStepFree: true,
    );
    final switchB = service.activateAccount('b');
    final bSave = service.savePreferences(
      isWheelchairOnly: false,
      isStepFree: false,
    );
    await Future.wait([oldSave, switchB, bSave]);
    expect(service.userId, 'b');
    expect(service.isStepFree, isFalse);
    final prefs = await SharedPreferences.getInstance();
    final a = jsonDecode(
      prefs.getString(AccessibilityPreferencesService.accountKey('a'))!,
    ) as Map;
    final b = jsonDecode(
      prefs.getString(AccessibilityPreferencesService.accountKey('b'))!,
    ) as Map;
    expect(a['stepFree'], isTrue);
    expect(b['stepFree'], isFalse);
    await service.activateAccount('a');
    expect(service.isStepFree, isTrue);
    service.dispose();
  });
  test(
    'auth stream switches and signs out using independent owner keys',
    () async {
      final accounts = StreamController<String?>(sync: true);
      final service = AccessibilityPreferencesService();
      await service.init(userId: 'a');
      await service.setStepFree(true);
      service.bindAccounts(accounts.stream);
      accounts.add('b');
      expect(service.userId, 'b');
      expect(service.isStepFree, isFalse);
      await Future<void>.delayed(Duration.zero);
      accounts.add('a');
      await Future<void>.delayed(Duration.zero);
      expect(service.isStepFree, isTrue);
      accounts.add(null);
      expect(service.isStepFree, isFalse);
      await Future<void>.delayed(Duration.zero);
      service.dispose();
      await accounts.close();
    },
  );
  test('corrupt owner record uses defaults and reset affects only the active account', () async {
    SharedPreferences.setMockInitialValues({
      AccessibilityPreferencesService.accountKey('b'): 'not-json',
    });
    final service = AccessibilityPreferencesService();
    await service.init(userId: 'a');
    await service.setStepFree(true);
    await service.activateAccount('b');
    expect(service.isStepFree, isFalse);
    expect(service.isWheelchairOnly, isTrue);
    await service.resetToDefaults();
    await service.activateAccount('a');
    expect(service.isStepFree, isTrue);
    service.dispose();
  });
  testWidgets('an open preferences screen reloads toggles on account switch', (
    tester,
  ) async {
    final service = AccessibilityPreferencesService.instance;
    await service.init(userId: 'a');
    await service.savePreferences(isWheelchairOnly: false, isStepFree: true);
    await tester.pumpWidget(
      const MaterialApp(home: AccessibilityPreferencesScreen()),
    );
    await tester.pumpAndSettle();
    await service.activateAccount('b');
    await tester.pumpAndSettle();
    // Saving after the switch must persist B defaults rather than the old form snapshot.
    final save = find.text('Save Preferences');
    await tester.scrollUntilVisible(save, 400);
    await tester.tap(save);
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final b = jsonDecode(
      prefs.getString(AccessibilityPreferencesService.accountKey('b'))!,
    ) as Map;
    expect(b['wheelchair'], isTrue);
    expect(b['stepFree'], isFalse);
    await service.activateAccount('a');
    expect(service.isStepFree, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'an open journey search drops the previous account requirements on signout',
    (tester) async {
      final service = AccessibilityPreferencesService.instance;
      await service.init(userId: 'a');
      await service.setStepFree(true);
      await tester.pumpWidget(const MaterialApp(home: JourneySearchScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Step-Free'), findsOneWidget);
      await service.activateAccount(null);
      await tester.pumpAndSettle();
      expect(find.text('Step-Free'), findsNothing);
      expect(find.text('Ramp Required'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
