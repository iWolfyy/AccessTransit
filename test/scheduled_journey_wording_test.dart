import 'package:access_transit/models/bus.dart';
import 'package:access_transit/screens/journey/live_journey_screen.dart';
import 'package:access_transit/screens/journey/route_details_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/services/transit_catalogue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Bus bus;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init();
    final scheduled = DateTime.now().subtract(const Duration(minutes: 5));
    String clock(DateTime time) =>
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    bus = Bus(
      id: 'schedule-wording',
      routeNo: 'TEST',
      stops: ['a', 'b'],
      scheduleTimes: [
        clock(scheduled),
        clock(scheduled.add(const Duration(minutes: 20))),
      ],
      hasRamp: false,
      lowFloor: false,
      occupancy: 'low',
    );
    TransitCatalogue.installFixtures({
      'buses': {
        bus.id: {...bus.toMap(), 'catalogueSource': 'operator_catalogue'},
      },
      'stations': {},
      'routes': {},
    });
  });
  for (final details in [true, false]) {
    testWidgets(
      '${details ? 'details' : 'live journey'} labels an unconfirmed run as scheduled',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: details
                ? RouteDetailsScreen(origin: 'a', destination: 'b', bus: bus)
                : LiveJourneyScreen(
                    busId: bus.id,
                    origin: 'a',
                    destination: 'b',
                  ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Scheduled'), findsWidgets);
        expect(find.textContaining('Departed'), findsNothing);
        expect(find.textContaining('Arriving'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
