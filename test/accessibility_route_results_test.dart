import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:access_transit/screens/journey/journey_search_screen.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart';
import 'package:access_transit/screens/preferences/accessibility_preferences_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Accessibility & Route Results Preferences Integration Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AccessibilityPreferencesService.instance.init();
    });

    testWidgets('RouteResultsScreen auto-selects "Accessible" tab when wheelchair preference is true',
        (WidgetTester tester) async {
      await AccessibilityPreferencesService.instance.setWheelchairOnly(true);

      await tester.pumpWidget(
        const MaterialApp(
          home: RouteResultsScreen(
            fromStationId: 'st_fort',
            toStationId: 'st_kottawa',
            origin: 'Colombo Fort Station',
            destination: 'Kottawa Highway Bus Station',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final accessibleTabFinder = find.textContaining('Accessible (');
      expect(accessibleTabFinder, findsOneWidget);

      final container = tester.widget<Container>(
        find.ancestor(
          of: accessibleTabFinder,
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, isNotNull);
    });

    testWidgets('RouteResultsScreen defaults to "All" tab when wheelchair preference is false',
        (WidgetTester tester) async {
      await AccessibilityPreferencesService.instance.setWheelchairOnly(false);

      await tester.pumpWidget(
        const MaterialApp(
          home: RouteResultsScreen(
            fromStationId: 'st_fort',
            toStationId: 'st_kottawa',
            origin: 'Colombo Fort Station',
            destination: 'Kottawa Highway Bus Station',
            wheelchairAccessRequired: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final allTabFinder = find.textContaining('All (');
      expect(allTabFinder, findsOneWidget);

      final container = tester.widget<Container>(
        find.ancestor(
          of: allTabFinder,
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, isNotNull);
    });

    testWidgets('JourneySearchScreen auto-syncs all 3 mobility preferences (wheelchair, step-free, min walk)',
        (WidgetTester tester) async {
      // Turn all 3 ON in global preferences
      await AccessibilityPreferencesService.instance.savePreferences(
        isWheelchairOnly: true,
        isStepFree: true,
        minimizeWalking: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: JourneySearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // All 3 active filter chips should be displayed
      expect(find.text('Ramp Required'), findsOneWidget);
      expect(find.text('Step-Free'), findsOneWidget);
      expect(find.text('Min Walk'), findsOneWidget);

      // Now toggle off Step-Free and Min Walk in preferences service
      await AccessibilityPreferencesService.instance.setStepFree(false);
      await AccessibilityPreferencesService.instance.setMinimizeWalking(false);
      await tester.pumpAndSettle();

      // Step-Free and Min Walk should disappear reactively, Ramp Required remains
      expect(find.text('Ramp Required'), findsOneWidget);
      expect(find.text('Step-Free'), findsNothing);
      expect(find.text('Min Walk'), findsNothing);

      // Now turn off wheelchair access
      await AccessibilityPreferencesService.instance.setWheelchairOnly(false);
      await tester.pumpAndSettle();

      expect(find.text('Ramp Required'), findsNothing);
      expect(find.text('All buses shown. Tap Configure to require ramps or step-free access.'), findsOneWidget);
    });

    testWidgets('JourneySearchScreen allows per-trip filter customization without mutating global preferences',
        (WidgetTester tester) async {
      // User has wheelchair = true, step-free = false, minimize-walking = false
      await AccessibilityPreferencesService.instance.savePreferences(
        isWheelchairOnly: true,
        isStepFree: false,
        minimizeWalking: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: JourneySearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ramp Required'), findsOneWidget);

      // Dismiss / clear the "Ramp Required" chip directly from the search screen
      final deleteIconFinder = find.descendant(
        of: find.widgetWithText(Chip, 'Ramp Required'),
        matching: find.byIcon(Icons.close),
      );
      expect(deleteIconFinder, findsOneWidget);
      await tester.tap(deleteIconFinder);
      await tester.pumpAndSettle();

      // Local search chip is now gone
      expect(find.text('Ramp Required'), findsNothing);

      // Global user preference in service MUST still be true!
      expect(AccessibilityPreferencesService.instance.isWheelchairOnly, isTrue);
    });

    testWidgets('AccessibilityPreferencesScreen toggles auto-save immediately to service',
        (WidgetTester tester) async {
      await AccessibilityPreferencesService.instance.savePreferences(
        isWheelchairOnly: false,
        isStepFree: false,
        minimizeWalking: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AccessibilityPreferencesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find the "Wheelchair access required" toggle tile and tap it
      final wheelchairToggle = find.text('Wheelchair access required');
      expect(wheelchairToggle, findsOneWidget);
      await tester.tap(wheelchairToggle);
      await tester.pumpAndSettle();

      // Global service should immediately be updated to true
      expect(AccessibilityPreferencesService.instance.isWheelchairOnly, isTrue);

      // Tap Step-free routes only
      final stepFreeToggle = find.text('Step-free routes only');
      expect(stepFreeToggle, findsOneWidget);
      await tester.tap(stepFreeToggle);
      await tester.pumpAndSettle();

      expect(AccessibilityPreferencesService.instance.isStepFree, isTrue);

      // Tap Minimize walking distance
      final minWalkToggle = find.text('Minimize walking distance');
      expect(minWalkToggle, findsOneWidget);
      await tester.tap(minWalkToggle);
      await tester.pumpAndSettle();

      expect(AccessibilityPreferencesService.instance.minimizeWalking, isTrue);
    });

    testWidgets('JourneySearchScreen renders title and no back button in top bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: JourneySearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Plan Journey'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byTooltip('Back'), findsNothing);
    });
  });
}
