import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/assistance_target.dart';
import 'package:access_transit/services/transit_catalogue.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/screens/journey/live_journey_screen.dart';
import 'package:access_transit/screens/journey/route_details_screen.dart';
import 'package:access_transit/widgets/published_timetable_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final data = <String, dynamic>{
    'catalogueRecordType': 'published_timetable',
    'sourceUrl': 'https://ncgexpress.lk/bus-timetables/',
    'routeNo': 'EX 01 74/31-2',
    'stops': ['a', 'b'],
    'scheduleTimes': ['10:30', '15:00'],
    'hasRamp': false,
    'lowFloor': false,
    'occupancy': 'unknown',
  };
  late Bus bus;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init();
    bus = Bus.fromMap(data, id: 'published');
    TransitCatalogue.installFixtures({
      'buses': {'published': data},
      'routes': {},
      'stations': {},
    });
  });
  test('timetable identity survives serialization and cannot claim vehicle checks or assistance', () {
    expect(Bus.fromMap(bus.toMap(), id: bus.id), bus);
    expect(bus.copyWith(occupancy: 'unknown').isPublishedTimetable, isTrue);
    expect(bus.displayBusNo, 'Vehicle unassigned');
    expect(bus.rampCondition(), isNull);
    expect(
      () => TransitCatalogue.requireVehicleRecord(bus.id, data),
      throwsStateError,
    );
    expect(
      AssistanceTarget.resolve(
        busId: bus.id,
        bus: bus,
        stopName: 'a',
        stations: {},
      ),
      isNull,
    );
  });
  testWidgets('details disclose source and disable driver assistance', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RouteDetailsScreen(origin: 'a', destination: 'b', bus: bus),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PublishedTimetableNotice), findsOneWidget);
    expect(
      find.textContaining('Source: https://ncgexpress.lk'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(
              OutlinedButton,
              'Driver assistance unavailable',
            ),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'direct saved timetable tracking cannot show an invented vehicle map',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LiveJourneyScreen(busId: bus.id, origin: 'a', destination: 'b'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PublishedTimetableNotice), findsOneWidget);
      expect(find.byType(FlutterMap), findsNothing);
      expect(find.textContaining('Vehicle unassigned'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
