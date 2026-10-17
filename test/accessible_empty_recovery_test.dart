import 'support/fixture_search_backend.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart';
import 'package:access_transit/screens/journey/bus_details_screen.dart';
import 'package:access_transit/services/transit_catalogue.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bus = Bus(
  id: 'inaccessible23',
  routeNo: '23',
  busNo: 'WP TEST-23',
  stops: ['a', 'b'],
  scheduleTimes: ['10:00', '10:20'],
  hasRamp: false,
  lowFloor: false,
  occupancy: 'low',
);
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init(userId: 'owner');
    TransitCatalogue.installFixtures({
      'buses': {
        bus.id: {...bus.toMap(), 'catalogueSource': 'operator_catalogue'},
      },
      'stations': {},
      'routes': {},
    });
  });
  Future<void> show(
    WidgetTester tester, {
    bool wheelchair = false,
    bool stepFree = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RouteResultsScreen(searchBackend: FixtureSearchBackend(), 
          fromStationId: 'a',
          toStationId: 'b',
          origin: 'A',
          destination: 'B',
          wheelchairAccessRequired: wheelchair,
          stepFreeOnly: stepFree,
          selectedDate: null,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    final target = find.text(label);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'optional Accessible empty state exposes matching-all recovery with disclosure',
    (tester) async {
      await AccessibilityPreferencesService.instance.setWheelchairOnly(false);
      await show(tester);
      expect(find.text('WP TEST-23'), findsOneWidget);
      await tap(tester, 'Accessible (0)');
      expect(find.text('WP TEST-23'), findsNothing);
      expect(
        find.textContaining('unknown access or reported barriers'),
        findsOneWidget,
      );
      await tap(tester, 'Show all matching buses');
      expect(find.text('WP TEST-23'), findsOneWidget);
      await tap(tester, 'WP TEST-23');
      final route = tester
          .widget<BusDetailsScreen>(find.byType(BusDetailsScreen))
          .route;
      expect(route.wheelchairAccessRequired, isFalse);
      expect(route.stepFreeOnly, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'All and Fastest cannot bypass hard wheelchair needs; cancelling review preserves them',
    (tester) async {
      await show(tester, wheelchair: true);
      expect(find.text('Accessible (0)'), findsOneWidget);
      expect(find.text('Show all matching buses'), findsNothing);
      await tap(tester, 'All (0)');
      expect(find.text('WP TEST-23'), findsNothing);
      await tap(tester, 'Fastest');
      expect(find.text('WP TEST-23'), findsNothing);
      await tap(tester, 'Review trip requirements');
      expect(
        tester
            .widget<SwitchListTile>(
              find.widgetWithText(SwitchListTile, 'Wheelchair access required'),
            )
            .value,
        isTrue,
      );
      await tap(tester, 'Wheelchair access required');
      await tap(tester, 'Keep requirements');
      expect(find.text('WP TEST-23'), findsNothing);
      expect(
        AccessibilityPreferencesService.instance.wheelchairAccessRequired,
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'matching-all recovery retains an explicit step-free requirement in selection',
    (tester) async {
      await AccessibilityPreferencesService.instance.savePreferences(
        isWheelchairOnly: false,
        isStepFree: true,
      );
      TransitCatalogue.installFixtures({
        'buses': {
          bus.id: {
            ...bus.copyWith(lowFloor: true).toMap(),
            'catalogueSource': 'operator_catalogue',
          },
        },
        'stations': {
          for (final id in ['a', 'b'])
            id: {
              'name': id,
              'stepFreeAccess': true,
              'catalogueSource': 'operator_catalogue',
            },
        },
        'routes': {},
      });
      await show(tester, stepFree: true);
      expect(find.text('All (1)'), findsOneWidget);
      await tap(tester, 'Accessible (0)');
      await tap(tester, 'Show all matching buses');
      expect(find.text('WP TEST-23'), findsOneWidget);
      await tap(tester, 'WP TEST-23');
      final route = tester
          .widget<BusDetailsScreen>(find.byType(BusDetailsScreen))
          .route;
      expect(route.stepFreeOnly, isTrue);
      expect(route.wheelchairAccessRequired, isFalse);
      expect(AccessibilityPreferencesService.instance.isStepFree, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'only explicit apply relaxes wheelchair needs for this trip and selection',
    (tester) async {
      await show(tester, wheelchair: true);
      await tap(tester, 'Review trip requirements');
      expect(find.textContaining('Turning a requirement off'), findsOneWidget);
      await tap(tester, 'Wheelchair access required');
      await tap(tester, 'Apply to this search');
      expect(find.text('WP TEST-23'), findsOneWidget);
      expect(
        AccessibilityPreferencesService.instance.wheelchairAccessRequired,
        isTrue,
      );
      await tap(tester, 'WP TEST-23');
      expect(
        tester
            .widget<BusDetailsScreen>(find.byType(BusDetailsScreen))
            .route
            .wheelchairAccessRequired,
        isFalse,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'step-free empty state has review and preserves needs until explicit apply',
    (tester) async {
      await AccessibilityPreferencesService.instance.setStepFree(true);
      await show(tester, stepFree: true);
      expect(find.text('All (0)'), findsOneWidget);
      expect(find.text('Show all matching buses'), findsNothing);
      await tap(tester, 'Review trip requirements');
      expect(
        tester
            .widget<SwitchListTile>(
              find.widgetWithText(SwitchListTile, 'Step-free routes only'),
            )
            .value,
        isTrue,
      );
      await tap(tester, 'Apply to this search');
      expect(find.text('WP TEST-23'), findsNothing);
      await tap(tester, 'Review trip requirements');
      await tap(tester, 'Step-free routes only');
      await tap(tester, 'Apply to this search');
      expect(find.text('WP TEST-23'), findsOneWidget);
      expect(AccessibilityPreferencesService.instance.isStepFree, isTrue);
      await tap(tester, 'WP TEST-23');
      expect(
        tester
            .widget<BusDetailsScreen>(find.byType(BusDetailsScreen))
            .route
            .stepFreeOnly,
        isFalse,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
