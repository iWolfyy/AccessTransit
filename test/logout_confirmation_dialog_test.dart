import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:access_transit/core/theme/app_theme.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/widgets/logout_confirmation_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init();
    await AccessibilityPreferencesService.instance.setHighContrast(false);
  });

  group('LogoutConfirmationDialog Tests', () {
    testWidgets('Renders title, message, Cancel and Sign Out buttons', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showLogoutConfirmationDialog(context);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap button to open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog elements
      expect(find.text('Sign Out'), findsNWidgets(2)); // Title and confirm button
      expect(
        find.textContaining('Are you sure you want to sign out?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);

      // Tap Cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog is dismissed and result is false
      expect(find.byType(AlertDialog), findsNothing);
      expect(result, isFalse);
    });

    testWidgets('Tapping Sign Out returns true', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showLogoutConfirmationDialog(context);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap the confirm button (the ElevatedButton)
      final confirmButton = find.widgetWithText(ElevatedButton, 'Sign Out');
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(result, isTrue);
    });

    testWidgets('Actions meet WCAG 48dp minimum touch target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showLogoutConfirmationDialog(context),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      final cancelSize = tester.getSize(find.widgetWithText(OutlinedButton, 'Cancel'));
      final signOutSize = tester.getSize(find.widgetWithText(ElevatedButton, 'Sign Out'));

      expect(cancelSize.height, greaterThanOrEqualTo(48.0));
      expect(signOutSize.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('showLogoutSuccessSnackBar displays confirmation message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showLogoutSuccessSnackBar(context: context),
                child: const Text('Show SnackBar'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show SnackBar'));
      await tester.pump();

      expect(
        find.text('You have been signed out successfully.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });
  });
}
