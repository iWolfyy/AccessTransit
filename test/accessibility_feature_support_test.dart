import 'package:access_transit/screens/preferences/accessibility_preferences_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final service = AccessibilityPreferencesService.instance;
  final unsupportedKeys = [
    AccessibilityPreferencesService.keyMinimizeWalking,
    AccessibilityPreferencesService.keyVoiceGuidance,
    AccessibilityPreferencesService.keyQuietRoutes,
    AccessibilityPreferencesService.keyHapticAlerts,
    AccessibilityPreferencesService.keyBoardingAssistance,
  ];

  test('old enabled unsupported settings migrate off; setters and batch cannot enable them', () async {
    SharedPreferences.setMockInitialValues({
      for (final key in unsupportedKeys) key: true,
    });
    final prefs = await SharedPreferences.getInstance();
    await service.init(prefs: prefs);
    for (final key in unsupportedKeys) {
      expect(prefs.getBool(key), isFalse);
    }
    await service.setVoiceGuidance(true);
    await service.setQuietRoutes(true);
    await service.setMinimizeWalking(true);
    await service.setHapticAlerts(true);
    await service.setBoardingAssistance(true);
    await service.savePreferences(
      voiceGuidance: true,
      quietRoutes: true,
      minimizeWalking: true,
      hapticAlerts: true,
      boardingAssistance: true,
    );
    expect([
      service.voiceGuidance,
      service.quietRoutes,
      service.minimizeWalking,
      service.hapticAlerts,
      service.boardingAssistance,
    ], everyElement(isFalse));
    for (final key in unsupportedKeys) {
      expect(prefs.getBool(key), isFalse);
    }
  });

  testWidgets(
    'unsupported preference switches cannot be toggled; implemented switches stay enabled',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await service.init();
      await tester.pumpWidget(
        const MaterialApp(home: AccessibilityPreferencesScreen()),
      );
      await tester.pumpAndSettle();
      for (final label in [
        'Minimize walking distance',
        'Voice guidance for navigation',
        'Show quiet routes',
        'Haptic alerts for stops',
        'Boarding assistance required',
      ]) {
        final target = find.text(label);
        await tester.scrollUntilVisible(target, 200, maxScrolls: 30);
        final row = find
            .ancestor(of: target, matching: find.byType(InkWell))
            .first;
        final toggle = tester.widget<Switch>(
          find.descendant(of: row, matching: find.byType(Switch)),
        );
        expect(toggle.value, isFalse);
        expect(toggle.onChanged, isNull);
        expect(tester.widget<InkWell>(row).onTap, isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
