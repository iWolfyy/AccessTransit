import 'package:access_transit/logic/bus_matcher.dart';
import 'package:access_transit/logic/bus_details_state.dart';
import 'package:access_transit/logic/dated_boarding_matcher.dart';
import 'package:access_transit/logic/journey_selection.dart';
import 'package:access_transit/logic/search_session.dart';
import 'package:access_transit/logic/transit_time.dart';
import 'package:access_transit/models/assistance_target.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/boarding_request.dart';
import 'package:access_transit/models/bus_location_model.dart';
import 'package:access_transit/models/service_run.dart';
import 'package:access_transit/models/station.dart';
import 'package:access_transit/models/trip_model.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart';
import 'package:access_transit/services/admin_service.dart';
import 'package:access_transit/widgets/save_trip_control.dart';
import 'package:access_transit/logic/route_geometry.dart';
import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/screens/admin/catalogue_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'bus_details_flow_test.dart' as details;
import 'support/memory_admin_repository.dart';

const stops = ['a', 'b', 'a-return', 'c'];
const mapping = {'a': 'a', 'b': 'b', 'a-return': 'a', 'c': 'c'};
const bus = Bus(
  id: 'loop',
  routeId: 'route',
  routeNo: '17',
  busNo: 'TEST LOOP',
  driverId: 'driver',
  scheduledDeparture: '10:00',
  stops: stops,
  stopStationIds: mapping,
  scheduleTimes: ['10:00', '10:10', '10:20', '10:30'],
  hasRamp: false,
  lowFloor: false,
  occupancy: 'unknown',
);
final start = DateTime.utc(2026, 10, 19, 4, 30);
ServiceRun run([String status = 'scheduled']) => ServiceRun(
  id: 'loop-run',
  busId: bus.id,
  routeId: 'route',
  routeNo: '17',
  serviceDate: TransitTime.serviceDate(start),
  plannedDepartureAt: start,
  latestStartAt: start.add(ServiceRun.maximumLateStart),
  status: status,
  stopStationIds: mapping,
  stopTimes: {
    for (var i = 0; i < stops.length; i++)
      stops[i]: start.add(Duration(minutes: i * 10)),
  },
);
const stations = {
  'a': Station(
    id: 'a',
    name: 'Repeated stop',
    lat: 6.9,
    lng: 79.8,
    hasRamp: false,
    hasElevator: false,
  ),
  'b': Station(
    id: 'b',
    name: 'Middle stop',
    lat: 6.91,
    lng: 79.81,
    hasRamp: false,
    hasElevator: false,
  ),
  'c': Station(
    id: 'c',
    name: 'Destination',
    lat: 6.92,
    lng: 79.82,
    hasRamp: false,
    hasElevator: false,
  ),
};
RouteResultItem selection(String from) => RouteResultItem(
  id: 'loop',
  busId: 'loop',
  rawBus: bus,
  title: 'Loop',
  origin: 'Repeated stop',
  destination: 'Destination',
  fromStationId: from,
  toStationId: 'c',
  intermediateStops: from == 'a' ? ['b', 'a-return'] : [],
  serviceRunId: 'loop-run',
  nextDepartureDateTime: run().stopTimes[from],
  selectedDate: DateTime(2026, 10, 19),
  durationMinutes: from == 'a' ? 30 : 10,
  etaLabel: 'Scheduled',
  transfers: 0,
  crowdLevel: 'Unknown',
  accessibilityStatus: AccessibilityStatus.unknown,
  accessibilityLabel: 'Unknown',
  safetyLabel: 'Unknown',
  summary: 'Loop',
);

void main() {
  for (final language in ['si', 'ta']) {
    test(
      'calendar and occurrence wording retains $language Unicode glyphs',
      () async {
        final l = await AppLocalizations.delegate.load(Locale(language));
        final script = language == 'si'
            ? RegExp('[\u0d80-\u0dff]')
            : RegExp('[\u0b80-\u0bff]');
        for (final value in [
          l.calendarTitle,
          l.calendarHelp,
          l.calendarDates,
          l.calendarTime,
          l.calendarPublish,
          l.calendarGenerate,
          l.calendarRetire,
          l.calendarFailed,
          l.calendarConfirmed,
          l.calendarGenerated(2, 3),
          l.calendarPublished,
          l.calendarRetired,
          l.calendarEmpty,
          l.loopStopHelp,
          l.journeyVisitPositions(1, 3),
        ]) {
          expect(script.hasMatch(value), isTrue, reason: value);
          expect(value.contains('??'), isFalse);
        }
      },
    );
  }

  test('road progress targets a later visit on the return leg, never the passed first visit', () {
    final geometry = ReviewedRouteGeometry.parse('route', {
      'reviewed': true,
      'synthetic': true,
      'routeId': 'route',
      'version': 'loop-shape',
      'source': 'https://authority.example/FICTIONAL-loop',
      'stops': stops,
      'stopVertices': [0, 1, 2, 3],
      'points': [
        [6.9, 79.8],
        [6.91, 79.81],
        [6.9, 79.8],
        [6.92, 79.82],
      ],
    });
    final now = start.add(const Duration(minutes: 11));
    final trip = TripModel(
      tripId: 'loop-run',
      serviceRunId: 'loop-run',
      busId: 'loop',
      routeNo: '17',
      driverId: 'driver',
      stops: stops,
      status: 'in_progress',
      currentStopIndex: 1,
      createdAt: start,
      scheduledDepartureTime: start,
      actualDepartureTime: start,
      stopTimes: {},
    );
    final gps = BusLocationModel(
      busId: 'loop',
      tripId: 'loop-run',
      driverId: 'driver',
      latitude: 6.905,
      longitude: 79.805,
      timestamp: now,
      speed: 15,
    );
    final result = RouteProgressEta.estimate(
      geometry: geometry,
      run: run('in_progress'),
      trip: trip,
      gps: gps,
      target: 'a-return',
      now: now,
    );
    expect(result, isNotNull);
    expect(result!.arrival.difference(now).inSeconds, closeTo(300, 2));
    expect(
      RouteProgressEta.estimate(
        geometry: geometry,
        run: run('in_progress'),
        trip: trip,
        gps: gps,
        target: 'a',
        now: now,
      ),
      isNull,
    );
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('admin adds a second physical-stop visit at 320dp / $scale', (
      tester,
    ) async {
      final repo = adminFixture();
      addTearDown(repo.dispose);
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: CatalogueEditorScreen(
              service: AdminService(repo),
              kind: 'routes',
              original: repo.get('routes', 'r1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final picker = find.byWidgetPredicate(
        (w) =>
            w is DropdownButtonFormField<String> &&
            w.decoration.labelText == 'Add a stop',
      );
      await tester.scrollUntilVisible(
        picker,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(picker);
      await tester.pumpAndSettle();
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fort Main Boarding Stop').last);
      await tester.pumpAndSettle();
      expect(find.text('3. Fort Main Boarding Stop'), findsOneWidget);
      final review = find.byType(CheckboxListTile);
      await tester.scrollUntilVisible(
        review,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(review);
      await tester.pumpAndSettle();
      await tester.tap(review);
      await tester.pumpAndSettle();
      final save = find.text('Save catalogue record');
      await tester.scrollUntilVisible(
        save,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      final route = repo.get('routes', 'r1');
      final visits = List<String>.from(route.data['stops']);
      expect(visits.length, 3);
      expect(visits.toSet().length, 3);
      expect(visits.take(2), ['s1', 's2']);
      expect(AdminService.stationIdFor(route.data, visits.last), 's1');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  test('server-supplied assistance visit positions survive local persistence and copy', () {
    final value = BoardingRequest.fromMap({
      'id': 'loop-help',
      'boardingIndex': 2,
      'alightingIndex': 3,
      'boardingStationId': 'a-return',
      'alightingStationId': 'c',
      'stationId': 'a',
      'policyVersion': 2,
    });
    final saved = BoardingRequest.fromMap(
      value.copyWith(status: 'acknowledged').toMap(),
    );
    expect(saved.boardingIndex, 2);
    expect(saved.alightingIndex, 3);
    expect(saved.stationId, 'a');
  });

  test('legacy IDs survive round trip and loop visits remain distinct', () {
    final restored = Bus.fromMap(bus.toMap(), id: bus.id);
    expect(restored, bus);
    expect(restored.occurrencesAt('a'), ['a', 'a-return']);
    expect(restored.resolveStations(stations)['a-return']!.id, 'a');
    expect(BusMatcher.findDirectBuses([bus], 'b', 'a'), [bus]);
    expect(BusMatcher.findDirectBuses([bus], 'c', 'a'), isEmpty);
    expect(details.vehicle.stationIdFor('b'), 'b');
  });

  test(
    'search enumerates both boarding visits and the later return direction',
    () {
      final now = start.subtract(const Duration(minutes: 1));
      List<DatedBoardingOption> search(String from, String to) =>
          DatedBoardingMatcher.forBus(
            bus: bus,
            from: from,
            to: to,
            window: BoardingSearchWindow(now),
            notBefore: now,
            runs: [run()],
          );
      final options = search('a', 'c');
      expect(options.map((o) => o.plan.stops.first), ['a', 'a-return']);
      expect(options.map((o) => o.plan.durationMinutes), [30, 10]);
      expect(search('b', 'a').single.plan.stops, ['b', 'a-return']);
    },
  );

  test('active progress past first visit keeps only the future boarding occurrence', () {
    final now = start.add(const Duration(minutes: 11));
    final trip = TripModel(
      tripId: 'loop-run',
      serviceRunId: 'loop-run',
      busId: 'loop',
      routeNo: '17',
      driverId: 'driver',
      stops: stops,
      status: 'in_progress',
      currentStopIndex: 1,
      createdAt: start,
      scheduledDepartureTime: start,
      actualDepartureTime: start,
      stopTimes: {},
    );
    final gps = BusLocationModel(
      busId: 'loop',
      tripId: 'loop-run',
      driverId: 'driver',
      latitude: stations['b']!.lat,
      longitude: stations['b']!.lng,
      timestamp: now,
      speed: 0,
    );
    final found = DatedBoardingMatcher.forBus(
      bus: bus,
      from: 'a',
      to: 'c',
      window: BoardingSearchWindow(now),
      notBefore: now,
      runs: [run('in_progress')],
      trips: {'loop-run': trip},
      locations: {'loop': gps},
      stations: stations,
    );
    expect(found.single.plan.stops, ['a-return', 'c']);
    expect(found.single.boardingAt, now.add(const Duration(minutes: 10)));
  });

  test('details, bookmark identity and assistance keep selected visit but reports use physical stop', () {
    final first = selection('a'), later = selection('a-return');
    expect(BusDetailsState.matchesRun(run(), later), isTrue);
    expect(BusDetailsState.physicalSegment(first), ['a', 'b', 'c']);
    expect(
      BusDetailsState.relevantReports(
        [
          details.report('physical', 'station', 'a'),
          details.report('wrong', 'station', 'a-return'),
        ],
        later,
        details.clock,
      ).map((r) => r.id),
      ['physical'],
    );
    expect(
      SaveTripControl.selectionId(first, 'owner', 'loop-run'),
      isNot(SaveTripControl.selectionId(later, 'owner', 'loop-run')),
    );
    final saved = JourneySelection.create(
      later,
      id: 'save',
      passengerId: 'owner',
    );
    final restored = JourneySelection.restore(saved, bus, stations);
    expect(restored.fromStationId, 'a-return');
    expect(restored.durationMinutes, 10);
    expect(restored.journeyStations['a-return']!.name, 'Repeated stop');
    final target = AssistanceTarget.resolve(
      busId: 'loop',
      bus: bus,
      stationId: 'a-return',
      stopName: 'Repeated stop',
      stations: stations,
      serviceRunId: 'loop-run',
      boardingStationId: 'a-return',
      alightingStationId: 'c',
    );
    expect(target!.stationId, 'a');
    expect(target.boardingStationId, 'a-return');
    expect(
      AssistanceTarget.resolve(
        busId: 'loop',
        bus: bus,
        stopName: 'Repeated stop',
        stations: stations,
      ),
      isNull,
    );
  });

  test('admin publishes loop timings/calendar independently and rejects alias rebinding', () async {
    final repo = adminFixture();
    addTearDown(repo.dispose);
    repo.seed('stations', 's3', {'name': 'End'});
    final route = repo.get('routes', 'r1');
    const keys = ['s1', 's2', 'visit-return', 's3'];
    const map = {'s1': 's1', 's2': 's2', 'visit-return': 's1', 's3': 's3'};
    repo.seed('routes', 'r1', {
      ...route.data,
      'stops': keys,
      'stopStationIds': map,
    });
    final old = repo.get('buses', 'b1');
    final data = {
      ...old.data,
      'stops': keys,
      'stopStationIds': map,
      'scheduleTimes': ['23:50', '00:00', '00:10', '00:20'],
    };
    await AdminService(repo).saveCatalogue('buses', 'b1', data, original: old);
    await AdminService(repo)
        .scheduleServiceRun(repo.get('buses', 'b1'), DateTime(2026, 10, 19));
    final record = repo.data['service_runs']!.values.single;
    final parsed = ServiceRun.fromMap(record.id, record.data);
    expect(parsed.stationIdFor('visit-return'), 's1');
    expect(
      parsed.stopTimes['visit-return']!.difference(parsed.stopTimes['s1']!),
      const Duration(minutes: 20),
    );
    final current = repo.get('buses', 'b1');
    await expectLater(
      AdminService(repo).saveCatalogue('buses', 'b1', {
        ...data,
        'stopStationIds': {...map, 'visit-return': 's2'},
      }, original: current),
      throwsStateError,
    );
  });
}
