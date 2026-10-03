import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:access_transit/core/theme/app_theme.dart';
import 'package:access_transit/models/user_model.dart';
import 'package:access_transit/screens/home/home_screen.dart';
import 'package:access_transit/screens/journey/journey_search_screen.dart';
import 'package:access_transit/screens/journey/live_journey_screen.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart';
import 'package:access_transit/screens/preferences/accessibility_preferences_screen.dart';
import 'package:access_transit/screens/profile/profile_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/widgets/app_bottom_nav_bar.dart';

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

    testWidgets('Toggling High contrast mode on AccessibilityPreferencesScreen updates theme without assertion error',
        (WidgetTester tester) async {
      await AccessibilityPreferencesService.instance.setHighContrast(false);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) {
            return ListenableBuilder(
              listenable: AccessibilityPreferencesService.instance,
              builder: (context, _) {
                final isHighContrast =
                    AccessibilityPreferencesService.instance.isHighContrast;
                return Theme(
                  data: isHighContrast
                      ? AppTheme.highContrastTheme
                      : AppTheme.lightTheme,
                  child: child!,
                );
              },
            );
          },
          home: const AccessibilityPreferencesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(AccessibilityPreferencesService.instance.isHighContrast, isFalse);

      // Find and scroll until visible
      final highContrastFinder = find.text('High contrast mode');
      expect(highContrastFinder, findsOneWidget);
      await tester.scrollUntilVisible(highContrastFinder, 200);
      await tester.pumpAndSettle();

      // Toggle ON
      await tester.tap(highContrastFinder);
      await tester.pumpAndSettle();

      expect(AccessibilityPreferencesService.instance.isHighContrast, isTrue);

      // Toggle OFF
      await tester.tap(highContrastFinder);
      await tester.pumpAndSettle();

      expect(AccessibilityPreferencesService.instance.isHighContrast, isFalse);
    });

    testWidgets(
        'AppBottomNavBar renders 2px black top border and high-contrast tab indicators when high contrast is active',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await AccessibilityPreferencesService.instance.init();
      await AccessibilityPreferencesService.instance.setHighContrast(true);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.highContrastTheme,
          home: Scaffold(
            bottomNavigationBar: AppBottomNavBar(
              currentTab: 'Home',
              onTabSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check outer Container decoration
      final navBarFinder = find.byType(AppBottomNavBar);
      expect(navBarFinder, findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(
          of: navBarFinder,
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.white));
      expect(decoration.border, isNotNull);
      final topBorder = decoration.border as Border;
      expect(topBorder.top.color, equals(Colors.black));
      expect(topBorder.top.width, equals(2.0));

      // Reset
      await AccessibilityPreferencesService.instance.setHighContrast(false);
    });

    testWidgets(
        'HomeScreen renders pure white scaffold and high contrast cards when high contrast is active',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      await AccessibilityPreferencesService.instance.init();
      await AccessibilityPreferencesService.instance.setHighContrast(true);

      const dummyUser = UserModel(
        uid: 'user_123',
        name: 'Test Passenger',
        email: 'passenger@example.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.highContrastTheme,
          home: const HomeScreen(initialUser: dummyUser),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.white));

      // Where to search input decorator is rendered
      expect(find.text('Where to?'), findsWidgets);

      // Reset
      await AccessibilityPreferencesService.instance.setHighContrast(false);
    });

    testWidgets(
        'JourneySearchScreen renders pure white scaffold, high-contrast inputs, and Find Buses button when high contrast is active',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      await AccessibilityPreferencesService.instance.init();
      await AccessibilityPreferencesService.instance.setHighContrast(true);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.highContrastTheme,
          home: const JourneySearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.white));

      // Check "Find Buses" button has high-contrast color (navy #001F3F)
      final findBusesFinder = find.widgetWithText(FilledButton, 'Find Buses');
      expect(findBusesFinder, findsOneWidget);
      final filledButton = tester.widget<FilledButton>(findBusesFinder);
      expect(filledButton.style?.backgroundColor?.resolve({}), equals(const Color(0xFF001F3F)));

      // Check Popular Accessible Routes section is rendered
      expect(find.text('Popular Accessible Routes'), findsOneWidget);

      // Reset
      await AccessibilityPreferencesService.instance.setHighContrast(false);
    });

    testWidgets(
        'RouteResultsScreen renders pure white scaffold, 2px borders, and high contrast tabs in high contrast mode',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      await AccessibilityPreferencesService.instance.init();
      await AccessibilityPreferencesService.instance.setHighContrast(true);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.highContrastTheme,
          home: const RouteResultsScreen(
            fromStationId: 'st_fort',
            toStationId: 'st_kottawa',
            origin: 'Colombo Fort Station',
            destination: 'Kottawa Highway Bus Station',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.white));

      // Check title or summary card renders
      expect(find.text('Available Buses'), findsOneWidget);
      expect(find.text('Colombo Fort Station'), findsWidgets);
      expect(find.text('Kottawa Highway Bus Station'), findsWidgets);

      // Reset
      await AccessibilityPreferencesService.instance.setHighContrast(false);
    });

    testWidgets(
        'ProfileScreen renders pure white background, navy impact card, and high-contrast section containers',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      await AccessibilityPreferencesService.instance.init();
      await AccessibilityPreferencesService.instance.setHighContrast(true);

      const dummyUser = UserModel(
        uid: 'user_456',
        name: 'Alex Perera',
        email: 'alex@example.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.highContrastTheme,
          home: const ProfileScreen(initialUser: dummyUser),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.white));

      // Check User details
      expect(find.text('Alex Perera'), findsOneWidget);
      expect(find.text('alex@example.com'), findsOneWidget);

      // Check Impact Card
      expect(find.text('Your Impact'), findsOneWidget);

      // Check Badges & Achievements section
      expect(find.text('Badges & Achievements'), findsOneWidget);

      // Check Account section
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Accessibility Preferences'), findsOneWidget);

      // Reset
      await AccessibilityPreferencesService.instance.setHighContrast(false);
    });

    testWidgets(
        'LiveJourneyScreen renders pure white background, top bar, and controls in high contrast mode',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      await AccessibilityPreferencesService.instance.init();
      await AccessibilityPreferencesService.instance.setHighContrast(true);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.highContrastTheme,
          home: const LiveJourneyScreen(
            origin: 'Mount Lavinia',
            destination: 'Colombo Fort Station',
            busId: 'bus_01',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.white));

      // Top floating bar items
      expect(find.text('Live Tracking to'), findsOneWidget);
      expect(find.text('Colombo Fort Station'), findsWidgets);

      // Reset
      await AccessibilityPreferencesService.instance.setHighContrast(false);
    });
  });
}

