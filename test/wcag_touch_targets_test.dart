import 'package:access_transit/core/theme/app_theme.dart';
import 'package:access_transit/screens/auth/login_screen.dart';
import 'package:access_transit/screens/journey/boarding_assistance_screen.dart';
import 'package:access_transit/screens/journey/report_submitted_screen.dart';
import 'package:access_transit/screens/onboarding/onboarding_screen.dart';
import 'package:access_transit/screens/preferences/accessibility_preferences_screen.dart';
import 'package:access_transit/screens/profile/membership_card_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/widgets/app_bottom_nav_bar.dart';
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
      addTearDown(tester.view.resetDevicePixelRatio);

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

      // Scroll to ensure Save button is visible in ListView
      final saveBtn = find.text('Save Preferences');
      await tester.scrollUntilVisible(saveBtn, 200);
      await tester.pumpAndSettle();

      // Verify Save button touch target height is at least 48dp
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

    testWidgets('AppBottomNavBar items guarantee >= 48dp touch targets',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNavBar(
              currentTab: 'Home',
              onTabSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final navInkWells = find.descendant(
        of: find.byType(AppBottomNavBar),
        matching: find.byType(InkWell),
      );
      expect(navInkWells, findsNWidgets(4));

      for (final element in navInkWells.evaluate()) {
        final renderBox = element.renderObject as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          expect(renderBox.size.height, greaterThanOrEqualTo(48.0));
          expect(renderBox.size.width, greaterThanOrEqualTo(48.0));
        }
      }
    });

    test('AppTheme enforces padded tap target size and 48dp minimum IconButton size', () {
      expect(AppTheme.lightTheme.materialTapTargetSize, MaterialTapTargetSize.padded);
      expect(AppTheme.highContrastTheme.materialTapTargetSize, MaterialTapTargetSize.padded);

      final lightIconStyle = AppTheme.lightTheme.iconButtonTheme.style;
      final hcIconStyle = AppTheme.highContrastTheme.iconButtonTheme.style;

      expect(lightIconStyle?.minimumSize?.resolve({}), const Size(48, 48));
      expect(hcIconStyle?.minimumSize?.resolve({}), const Size(48, 48));
    });

    testWidgets('Dynamic sizing tokens scale appropriately when hasLargeTargets is toggled',
        (WidgetTester tester) async {
      final prefs = AccessibilityPreferencesService.instance;
      addTearDown(() => prefs.setLargeTargets(false));

      // Test standard/compact targets
      prefs.setLargeTargets(false);
      double? compactButtonHeight;
      double? compactMinTapHeight;
      double? compactTapIconSize;
      double? compactNavBarHeight;
      double? compactButtonFontSize;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              compactButtonHeight = context.buttonHeight;
              compactMinTapHeight = context.minTapHeight;
              compactTapIconSize = context.tapIconSize;
              compactNavBarHeight = context.navBarHeight;
              compactButtonFontSize = context.buttonFontSize;
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(compactButtonHeight, 48.0);
      expect(compactMinTapHeight, 44.0);
      expect(compactTapIconSize, 20.0);
      expect(compactNavBarHeight, 72.0);
      expect(compactButtonFontSize, 15.0);

      // Test large targets (60dp+)
      prefs.setLargeTargets(true);
      double? largeButtonHeight;
      double? largeMinTapHeight;
      double? largeTapIconSize;
      double? largeNavBarHeight;
      double? largeButtonFontSize;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              largeButtonHeight = context.buttonHeight;
              largeMinTapHeight = context.minTapHeight;
              largeTapIconSize = context.tapIconSize;
              largeNavBarHeight = context.navBarHeight;
              largeButtonFontSize = context.buttonFontSize;
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(largeButtonHeight, 60.0);
      expect(largeMinTapHeight, 60.0);
      expect(largeTapIconSize, 28.0);
      expect(largeNavBarHeight, 84.0);
      expect(largeButtonFontSize, 18.0);
    });

    testWidgets('AppBottomNavBar height scales between standard (72dp) and large targets (84dp)',
        (WidgetTester tester) async {
      final prefs = AccessibilityPreferencesService.instance;
      addTearDown(() => prefs.setLargeTargets(false));

      // Standard mode
      prefs.setLargeTargets(false);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNavBar(
              currentTab: 'Home',
              onTabSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final standardNavBarBox = tester.getSize(find.byType(AppBottomNavBar));
      expect(standardNavBarBox.height, 72.0);

      // Large targets mode
      prefs.setLargeTargets(true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNavBar(
              currentTab: 'Home',
              onTabSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final largeNavBarBox = tester.getSize(find.byType(AppBottomNavBar));
      expect(largeNavBarBox.height, 84.0);
    });

    Widget buildTestApp(Widget screen) {
      return MaterialApp(
        home: screen,
        builder: (context, child) {
          return ListenableBuilder(
            listenable: AccessibilityPreferencesService.instance,
            builder: (context, _) {
              final prefs = AccessibilityPreferencesService.instance;
              final isHighContrast = prefs.isHighContrast;
              final hasLargeTargets = prefs.hasLargeTargets;
              final baseTheme = isHighContrast
                  ? AppTheme.highContrastTheme
                  : AppTheme.lightTheme;
              return Theme(
                data: baseTheme.copyWith(
                  extensions: [
                    AccessibilityTokens(
                      hasLargeTargets: hasLargeTargets,
                      isHighContrast: isHighContrast,
                    ),
                  ],
                ),
                child: child!,
              );
            },
          );
        },
      );
    }

    testWidgets('Live reactive toggle immediately resizes buttons on LoginScreen without reload',
        (WidgetTester tester) async {
      final prefs = AccessibilityPreferencesService.instance;
      addTearDown(() => prefs.setLargeTargets(false));

      // Start with standard targets
      prefs.setLargeTargets(false);
      await tester.pumpWidget(buildTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      final signInFinder = find.widgetWithText(FilledButton, 'Sign In');
      expect(signInFinder, findsOneWidget);
      expect(tester.getSize(signInFinder).height, 48.0);

      // Toggle ON live — without rebuilding MaterialApp widget
      prefs.setLargeTargets(true);
      await tester.pumpAndSettle();
      expect(tester.getSize(signInFinder).height, 60.0);

      // Toggle OFF live — scales back to 48dp
      prefs.setLargeTargets(false);
      await tester.pumpAndSettle();
      expect(tester.getSize(signInFinder).height, 48.0);
    });

    testWidgets('BoardingAssistanceScreen buttons scale correctly in ON (60dp) and OFF (48dp)',
        (WidgetTester tester) async {
      final prefs = AccessibilityPreferencesService.instance;
      addTearDown(() => prefs.setLargeTargets(false));

      // Standard mode
      prefs.setLargeTargets(false);
      await tester.pumpWidget(buildTestApp(const BoardingAssistanceScreen()));
      await tester.pumpAndSettle();

      final sendBtnFinder = find.widgetWithText(FilledButton, 'Send Request');
      expect(sendBtnFinder, findsOneWidget);
      expect(tester.getSize(sendBtnFinder).height, 48.0);

      final cancelBtnFinder = find.widgetWithText(OutlinedButton, 'Cancel');
      expect(cancelBtnFinder, findsOneWidget);
      expect(tester.getSize(cancelBtnFinder).height, 48.0);

      // Large targets mode
      prefs.setLargeTargets(true);
      await tester.pumpAndSettle();

      expect(tester.getSize(sendBtnFinder).height, 60.0);
      expect(tester.getSize(cancelBtnFinder).height, 60.0);
    });

    testWidgets('ReportSubmittedScreen buttons scale correctly in ON (60dp) and OFF (48dp)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = AccessibilityPreferencesService.instance;
      addTearDown(() => prefs.setLargeTargets(false));

      // Standard mode
      prefs.setLargeTargets(false);
      await tester.pumpWidget(buildTestApp(const ReportSubmittedScreen()));
      await tester.pumpAndSettle();

      final communityBtn = find.widgetWithText(FilledButton, 'View in Community Feed');
      expect(communityBtn, findsOneWidget);
      expect(tester.getSize(communityBtn).height, 48.0);

      final homeBtn = find.widgetWithText(OutlinedButton, 'Back to Home');
      expect(homeBtn, findsOneWidget);
      expect(tester.getSize(homeBtn).height, 48.0);

      // Large targets mode
      prefs.setLargeTargets(true);
      await tester.pumpAndSettle();

      expect(tester.getSize(communityBtn).height, 60.0);
      expect(tester.getSize(homeBtn).height, 60.0);
    });

    testWidgets('MembershipCardScreen action button scales correctly in ON (60dp) and OFF (48dp)',
        (WidgetTester tester) async {
      final prefs = AccessibilityPreferencesService.instance;
      addTearDown(() => prefs.setLargeTargets(false));

      // Standard mode
      prefs.setLargeTargets(false);
      await tester.pumpWidget(buildTestApp(const MembershipCardScreen()));
      await tester.pumpAndSettle();

      final backToRewardsBtn = find.widgetWithText(FilledButton, 'Back to Rewards');
      expect(backToRewardsBtn, findsOneWidget);
      expect(tester.getSize(backToRewardsBtn).height, 48.0);

      // Large targets mode
      prefs.setLargeTargets(true);
      await tester.pumpAndSettle();

      expect(tester.getSize(backToRewardsBtn).height, 60.0);
    });

    testWidgets('OnboardingScreen Next button scales correctly in ON (60dp) and OFF (48dp)',
        (WidgetTester tester) async {
      final prefs = AccessibilityPreferencesService.instance;
      addTearDown(() => prefs.setLargeTargets(false));

      // Standard mode
      prefs.setLargeTargets(false);
      await tester.pumpWidget(buildTestApp(const OnboardingScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final nextBtn = find.widgetWithText(FilledButton, 'Next');
      expect(nextBtn, findsOneWidget);
      expect(tester.getSize(nextBtn).height, 48.0);

      // Large targets mode
      prefs.setLargeTargets(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.getSize(nextBtn).height, 60.0);
    });
  });
}
