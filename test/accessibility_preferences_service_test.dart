import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:access_transit/core/theme/app_theme.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccessibilityPreferencesService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Loads default values aligned with WCAG 2.2 AA accessibility requirements', () async {
      final service = AccessibilityPreferencesService.instance;
      await service.init();

      expect(service.isInitialized, isTrue);
      expect(service.isHighContrast, isFalse);
      expect(service.isWheelchairOnly, isTrue);
      expect(service.wheelchairAccessRequired, isTrue);
      expect(service.isStepFree, isFalse);
      expect(service.hasLargeTargets, isTrue);
      expect(service.minimizeWalking, isFalse);
      expect(service.voiceGuidance, isTrue);
      expect(service.hapticAlerts, isFalse);
      expect(service.boardingAssistance, isFalse);
      expect(service.quietRoutes, isFalse);
    });

    test('Loads saved values from SharedPreferences correctly', () async {
      SharedPreferences.setMockInitialValues({
        AccessibilityPreferencesService.keyHighContrast: true,
        AccessibilityPreferencesService.keyWheelchairOnly: false,
        AccessibilityPreferencesService.keyStepFree: true,
        AccessibilityPreferencesService.keyHasLargeTargets: true,
        AccessibilityPreferencesService.keyMinimizeWalking: true,
        AccessibilityPreferencesService.keyVoiceGuidance: false,
        AccessibilityPreferencesService.keyHapticAlerts: true,
        AccessibilityPreferencesService.keyBoardingAssistance: true,
        AccessibilityPreferencesService.keyQuietRoutes: true,
      });

      final service = AccessibilityPreferencesService.instance;
      await service.init();

      expect(service.isHighContrast, isTrue);
      expect(service.isWheelchairOnly, isFalse);
      expect(service.isStepFree, isTrue);
      expect(service.hasLargeTargets, isTrue);
      expect(service.minimizeWalking, isTrue);
      expect(service.voiceGuidance, isFalse);
      expect(service.hapticAlerts, isTrue);
      expect(service.boardingAssistance, isTrue);
      expect(service.quietRoutes, isTrue);
    });

    test('Notifies listeners and persists when individual preferences change', () async {
      SharedPreferences.setMockInitialValues({});
      final service = AccessibilityPreferencesService.instance;
      await service.init();

      int notifyCount = 0;
      service.addListener(() => notifyCount++);

      await service.setHighContrast(true);
      expect(service.isHighContrast, isTrue);
      expect(notifyCount, 1);

      await service.setWheelchairOnly(false);
      expect(service.isWheelchairOnly, isFalse);
      expect(notifyCount, 2);

      await service.setStepFree(true);
      expect(service.isStepFree, isTrue);
      expect(notifyCount, 3);

      await service.setLargeTargets(false);
      expect(service.hasLargeTargets, isFalse);
      expect(notifyCount, 4);

      // Verify persistent values in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AccessibilityPreferencesService.keyHighContrast), isTrue);
      expect(prefs.getBool(AccessibilityPreferencesService.keyWheelchairOnly), isFalse);
      expect(prefs.getBool(AccessibilityPreferencesService.keyStepFree), isTrue);
      expect(prefs.getBool(AccessibilityPreferencesService.keyHasLargeTargets), isFalse);
    });

    test('Batch savePreferences updates all values and notifies listeners', () async {
      SharedPreferences.setMockInitialValues({});
      final service = AccessibilityPreferencesService.instance;
      await service.init();

      int notifyCount = 0;
      service.addListener(() => notifyCount++);

      await service.savePreferences(
        isHighContrast: true,
        isWheelchairOnly: false,
        isStepFree: true,
        hasLargeTargets: true,
        minimizeWalking: true,
        voiceGuidance: false,
        hapticAlerts: true,
        boardingAssistance: true,
        quietRoutes: true,
      );

      expect(notifyCount, 1);
      expect(service.isHighContrast, isTrue);
      expect(service.isWheelchairOnly, isFalse);
      expect(service.isStepFree, isTrue);
      expect(service.hasLargeTargets, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AccessibilityPreferencesService.keyHighContrast), isTrue);
      expect(prefs.getBool(AccessibilityPreferencesService.keyWheelchairOnly), isFalse);
      expect(prefs.getBool(AccessibilityPreferencesService.keyStepFree), isTrue);
      expect(prefs.getBool(AccessibilityPreferencesService.keyHasLargeTargets), isTrue);
    });

    test('AppTheme highContrastTheme conforms to WCAG 2.2 AA/AAA requirements', () {
      final highContrastTheme = AppTheme.highContrastTheme;

      // Surface is pure white, text is pure black for maximum contrast (21:1)
      expect(highContrastTheme.colorScheme.surface, const Color(0xFFFFFFFF));
      expect(highContrastTheme.colorScheme.onSurface, const Color(0xFF000000));
      expect(highContrastTheme.colorScheme.outline, const Color(0xFF000000));

      // Divider thickness >= 1.5dp for high visibility
      expect(highContrastTheme.dividerTheme.thickness, greaterThanOrEqualTo(1.5));
      expect(highContrastTheme.dividerTheme.color, const Color(0xFF000000));
    });
  });
}
