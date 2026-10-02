import 'package:access_transit/screens/preferences/accessibility_preferences_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WCAG 2.2 Level AA - 48dp Minimum Touch Targets Tests', () {
    testWidgets('AccessibilityPreferencesScreen toggle rows exceed 48dp minimum tap target',
        (WidgetTester tester) async {
      // Set typical mobile screen size
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AccessibilityPreferencesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find all InkWell or Switch widgets
      final inkWells = find.byType(InkWell);
      expect(inkWells, findsWidgets);

      for (final element in inkWells.evaluate()) {
        final renderBox = element.renderObject as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final size = renderBox.size;
          // Verify that touch target height is at least 48dp
          expect(
            size.height,
            greaterThanOrEqualTo(48.0),
            reason: 'Interactive element height must be >= 48dp per WCAG 2.2 SC 2.5.8',
          );
        }
      }

      // Verify Save button touch target height is at least 48dp
      final saveBtn = find.text('Save Preferences');
      expect(saveBtn, findsOneWidget);
      final saveBtnBox = tester.getSize(find.byType(FilledButton));
      expect(saveBtnBox.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('AccessibilityPreferencesScreen AppBar icons have 48dp minimum bounds',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AccessibilityPreferencesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final iconButtons = find.byType(IconButton);
      expect(iconButtons, findsWidgets);

      for (final finder in iconButtons.evaluate()) {
        final renderBox = finder.renderObject as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final size = renderBox.size;
          expect(
            size.width,
            greaterThanOrEqualTo(48.0),
            reason: 'IconButton width must be >= 48dp per WCAG 2.2 AA',
          );
          expect(
            size.height,
            greaterThanOrEqualTo(48.0),
            reason: 'IconButton height must be >= 48dp per WCAG 2.2 AA',
          );
        }
      }
    });
  });
}
