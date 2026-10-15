import 'package:access_transit/models/bus.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart';
import 'package:access_transit/screens/journey/route_details_screen.dart';
import 'package:access_transit/services/transit_catalogue.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/widgets/evidence_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bus = Bus(
  id: 'timed22',
  routeNo: '22',
  busNo: 'WP TEST-22',
  stops: ['a', 'b'],
  scheduleTimes: ['10:00', '10:20'],
  hasRamp: false,
  lowFloor: false,
  occupancy: 'low',
);
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init();
    TransitCatalogue.installFixtures({
      'buses': {
        bus.id: {...bus.toMap(), 'catalogueSource': 'operator_catalogue'},
      },
      'routes': {},
      'stations': {},
    });
  });
  Widget results(DateTime Function() now, {DateTime? date}) => MaterialApp(
    home: EvidenceClock(
      now: now,
      child: RouteResultsScreen(
        fromStationId: 'a',
        toStationId: 'b',
        origin: 'A',
        destination: 'B',
        selectedDate: date,
        wheelchairAccessRequired: false,
        stepFreeOnly: false,
      ),
    ),
  );
  void expectTimetable() {
    expect(find.text('Scheduled'), findsOneWidget);
    expect(
      find.textContaining('Timetable estimates - departure unconfirmed'),
      findsOneWidget,
    );
    for (final label in [
      'Ongoing',
      'Approaching',
      'LIVE GPS',
      'Departed now',
    ]) {
      expect(find.text(label), findsNothing);
    }
    expect(find.text('10:00 AM'), findsOneWidget);
    expect(find.text('10:20 AM'), findsOneWidget);
  }

  for (final time in [
    DateTime(2026, 10, 15, 9, 50),
    DateTime(2026, 10, 15, 9, 58),
    DateTime(2026, 10, 15, 10, 0, 30),
  ]) {
    testWidgets('clock at $time cannot establish bus movement', (tester) async {
      await tester.pumpWidget(results(() => time));
      await tester.pumpAndSettle();
      expectTimetable();
      await tester.tap(find.text('WP TEST-22'));
      await tester.pumpAndSettle();
      final route = tester
          .widget<RouteDetailsScreen>(find.byType(RouteDetailsScreen))
          .route!;
      expect(route.timetableStatusLabel, 'Scheduled');
      expect(route.etaLabel, startsWith('Scheduled'));
      expect(route.scheduledDeparture, startsWith('Scheduled'));
      expect(route.etaLabel, isNot(contains('Arriving')));
      if (time.isAfter(DateTime(2026, 10, 15, 10))) {
        expect(route.etaLabel, 'Scheduled time passed - departure unconfirmed');
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('future-day results retain timetable provenance', (tester) async {
    final now = DateTime(2026, 10, 15, 9, 58);
    await tester.pumpWidget(
      results(() => now, date: now.add(const Duration(days: 7))),
    );
    await tester.pumpAndSettle();
    expectTimetable();
    await tester.tap(find.text('WP TEST-22'));
    await tester.pumpAndSettle();
    final route = tester
        .widget<RouteDetailsScreen>(find.byType(RouteDetailsScreen))
        .route!;
    expect(route.etaLabel, startsWith('Scheduled'));
    expect(route.nextDepartureDateTime, DateTime(2026, 10, 22, 10));
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'crossing departure on a silent screen does not create a live badge',
    (tester) async {
      var now = DateTime(2026, 10, 15, 9, 59);
      await tester.pumpWidget(results(() => now));
      await tester.pumpAndSettle();
      expectTimetable();
      now = DateTime(2026, 10, 15, 10, 1);
      await tester.pump(const Duration(minutes: 2));
      await tester.pumpAndSettle();
      expectTimetable();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
