import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:access_transit/logic/dated_boarding_matcher.dart';
import 'package:access_transit/logic/search_session.dart';
import 'package:access_transit/logic/transit_time.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/bus_location_model.dart';
import 'package:access_transit/models/service_run.dart';
import 'package:access_transit/models/station.dart';
import 'package:access_transit/models/trip_model.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/services/dated_search_state.dart';
import 'package:access_transit/services/transit_catalogue.dart';
import 'package:access_transit/services/transit_search_backend.dart';

final now = DateTime.utc(2026, 10, 16, 4, 20); // 09:50 Colombo.
const bus = Bus(
  id: 'dated-bus',
  busNo: 'DATED-17',
  routeNo: '17',
  routeId: 'route',
  driverId: 'driver',
  stops: ['a', 'b', 'c'],
  scheduleTimes: ['09:45', '10:00', '10:30'],
  hasRamp: false,
  lowFloor: false,
  occupancy: 'unknown',
);
const stations = {
  'a': Station(
    id: 'a',
    name: 'Origin',
    lat: 6.90,
    lng: 79.80,
    hasElevator: false,
    hasRamp: false,
  ),
  'b': Station(
    id: 'b',
    name: 'Boarding',
    lat: 6.91,
    lng: 79.81,
    hasElevator: false,
    hasRamp: false,
  ),
  'c': Station(
    id: 'c',
    name: 'Destination',
    lat: 6.92,
    lng: 79.82,
    hasElevator: false,
    hasRamp: false,
  ),
};
ServiceRun run({
  String status = 'scheduled',
  String id = 'run',
  Duration shift = Duration.zero,
}) {
  final departure = now.subtract(const Duration(minutes: 5)).add(shift);
  return ServiceRun(
    id: id,
    busId: bus.id,
    routeId: 'route',
    routeNo: '17',
    serviceDate: TransitTime.serviceDate(departure),
    plannedDepartureAt: departure,
    latestStartAt: departure.add(ServiceRun.maximumLateStart),
    status: status,
    stopTimes: {
      'a': departure,
      'b': departure.add(const Duration(minutes: 15)),
      'c': departure.add(const Duration(minutes: 45)),
    },
  );
}

TripModel operation({
  int index = 0,
  String status = 'in_progress',
  bool departed = true,
}) => TripModel(
  tripId: 'run',
  serviceRunId: 'run',
  busId: bus.id,
  routeNo: '17',
  stops: bus.stops,
  status: status,
  driverId: 'driver',
  createdAt: now,
  scheduledDepartureTime: run().plannedDepartureAt,
  actualDepartureTime: departed ? run().plannedDepartureAt : null,
  currentStopIndex: index,
  stopTimes: {},
);
BusLocationModel gps({String at = 'a'}) => BusLocationModel(
  busId: bus.id,
  tripId: 'run',
  driverId: 'driver',
  latitude: stations[at]!.lat,
  longitude: stations[at]!.lng,
  timestamp: now,
  speed: 0,
);

class ControlledSearch extends TransitSearchBackend {
  DateTime time = now;
  bool failTime = false;
  int synchronizations = 0;
  final runEvents = StreamController<List<ServiceRun>>.broadcast();
  final tripEvents = StreamController<TripModel?>.broadcast();
  final gpsEvents = StreamController<BusLocationModel?>.broadcast();
  @override
  Future<SearchTimeAnchor> synchronizeTime() async {
    synchronizations++;
    if (failTime) throw StateError('Offline');
    final receipt = time;
    return SearchTimeAnchor(receipt, elapsed: () => time.difference(receipt));
  }

  @override
  Stream<List<ServiceRun>> searchRuns(String id) => runEvents.stream;
  @override
  Stream<TripModel?> trip(String id) => tripEvents.stream;
  @override
  Stream<BusLocationModel?> location(String id) => gpsEvents.stream;
  void close() {
    unawaited(runEvents.close());
    unawaited(tripEvents.close());
    unawaited(gpsEvents.close());
  }
}

void main() {
  List<DatedBoardingOption> match(
    List<ServiceRun> runs, {
    TripModel? trip,
    BusLocationModel? location,
    DateTime? clock,
    DateTime? date,
    DateTime? earliest,
    Bus? vehicle,
  }) {
    final window = BoardingSearchWindow.colombo(clock ?? now);
    return DatedBoardingMatcher.forBus(
      bus: vehicle ?? bus,
      from: 'b',
      to: 'c',
      window: window,
      notBefore: earliest ?? window.now,
      selectedDate: date,
      runs: runs,
      trips: {'run': ?trip},
      locations: {bus.id: ?location},
      stations: stations,
    );
  }

  test('Colombo calendar is independent of UTC/local flag and explicit timezone offsets', () {
    final instant = DateTime.parse('2026-10-16T20:00:00Z');
    expect(TransitTime.civil(instant), DateTime.utc(2026, 10, 17, 1, 30));
    expect(
      TransitTime.civil(DateTime.parse('2026-10-16T16:00:00-04:00')),
      TransitTime.civil(instant),
    );
    expect(TransitTime.instant(DateTime.utc(2026, 10, 17, 1, 30)), instant);
    final window = BoardingSearchWindow.colombo(instant);
    expect(
      window.lowerBound(date: DateTime(2026, 10, 17), minutes: 90),
      instant,
    );
    expect(
      window.lowerBound(date: DateTime(2026, 10, 18), minutes: 91),
      isNull,
    );
  });

  test('monotonic receipt expires at five minutes and conservatively bounds network uncertainty', () {
    var elapsed = Duration.zero;
    final receipt = SearchTimeAnchor(
      now,
      elapsed: () => elapsed,
      uncertainty: const Duration(seconds: 2),
    );
    expect(receipt.now, now.add(const Duration(seconds: 2)));
    expect(receipt.windowEnd, now.add(const Duration(hours: 24)));
    elapsed = const Duration(minutes: 4);
    expect(receipt.now, now.add(const Duration(minutes: 4, seconds: 2)));
    expect(receipt.isFresh, isTrue);
    elapsed = const Duration(minutes: 5);
    expect(receipt.isFresh, isFalse);
  });

  test('physical buses require explicit dated runs; terminal, expired, reversed and wrong route are excluded', () {
    expect(match([]), isEmpty);
    expect(match([run()]).single.runId, 'run');
    expect(
      match([run(), run(id: 'second', shift: const Duration(hours: 1))]),
      hasLength(2),
    );
    expect(
      match([run(status: 'completed'), run(status: 'cancelled')]),
      isEmpty,
    );
    expect(
      match([run()], clock: now.add(const Duration(minutes: 40))),
      isEmpty,
    );
    expect(
      match([run()], vehicle: bus.copyWith(routeId: 'different')),
      isEmpty,
    );
    expect(match([run()], date: DateTime.utc(2026, 10, 20)), isEmpty);
  });

  test('24 hour horizon applies to boarding; destination can be beyond it', () {
    final boundary = run(shift: const Duration(hours: 23, minutes: 50));
    expect(
      match([boundary]).single.boardingAt,
      now.add(const Duration(hours: 24)),
    );
    expect(
      match([boundary]).single.plan.arrival
          .isAfter(now.add(const Duration(hours: 24))),
      isTrue,
    );
    expect(
      match([run(shift: const Duration(hours: 23, minutes: 50, seconds: 1))]),
      isEmpty,
    );
    expect(
      match([
        boundary,
      ], earliest: now.add(const Duration(hours: 24, seconds: 1))),
      isEmpty,
    );
  });

  test('active upstream bus uses timetable interval at fresh stationary recorded GPS stop', () {
    final result = match(
      [run(status: 'in_progress')],
      trip: operation(),
      location: gps(),
    ).single;
    expect(result.active, isTrue);
    expect(result.boardingAt, now.add(const Duration(minutes: 15)));
    expect(result.plan.departure, run().stopTimes['b']);
    expect(result.source, 'Timetable interval from GPS-observed stop');
    expect(
      match(
        [run(status: 'in_progress')],
        trip: operation(index: 1),
        location: gps(at: 'b'),
      ).single.boardingAt,
      now,
    );
    expect(
      match(
        [run(status: 'in_progress')],
        trip: operation(index: 2),
        location: gps(at: 'c'),
      ),
      isEmpty,
    );
  });

  test('moving, stale, cached, mismatched, unassigned and implausible active telemetry cannot confirm boarding', () {
    for (final location in [
      gps().copyWith(speed: 20),
      gps().copyWith(speed: double.nan),
      gps().copyWith(tripId: 'other'),
      gps().copyWith(driverId: 'other'),
      gps().copyWith(isCached: true),
      gps().copyWith(timestamp: now.subtract(const Duration(seconds: 31))),
      gps().copyWith(timestamp: now.add(const Duration(seconds: 1))),
      gps().copyWith(latitude: 0, longitude: 0),
      gps(at: 'c'),
    ]) {
      expect(
        match(
          [run(status: 'in_progress')],
          trip: operation(),
          location: location,
        ),
        isEmpty,
      );
    }
    expect(
      match(
        [run(status: 'in_progress')],
        trip: operation(),
        location: gps(),
        vehicle: bus.copyWith(driverId: 'other'),
      ),
      isEmpty,
    );
    expect(match([run(status: 'in_progress')]), isEmpty);
  });

  test('overnight published timetable keeps boarding date, duration and unassigned provenance', () {
    final published = Bus(
      id: 'published',
      routeNo: '1',
      catalogueRecordType: 'published_timetable',
      stops: ['a', 'b', 'c'],
      scheduleTimes: ['23:50', '00:10', '00:40'],
      hasRamp: false,
      lowFloor: false,
      occupancy: 'unknown',
    );
    final plan = DatedBoardingMatcher.publishedPlan(
      published,
      'b',
      'c',
      DateTime.utc(2026, 10, 17),
    )!;
    expect(plan.departure, DateTime.utc(2026, 10, 16, 18, 40));
    expect(plan.durationMinutes, 30);
    expect(
      match(
        [],
        vehicle: published,
        clock: DateTime.utc(2026, 10, 16, 18),
      ).single.runId,
      isNull,
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init(userId: 'rider');
    TransitCatalogue.installFixtures({
      'buses': {
        bus.id: {...bus.toMap(), 'catalogueSource': 'operator_catalogue'},
      },
      'stations': {
        for (final s in stations.values)
          s.id: {...s.toMap(), 'catalogueSource': 'operator_catalogue'},
      },
      'routes': {},
    });
  });

  testWidgets(
    'clock failure blocks verified results; retry and five minute refresh recover',
    (tester) async {
      final backend = ControlledSearch()..failTime = true;
      final state = DatedSearchState(backend);
      await state.start([bus.id]);
      backend.runEvents.add([run()]);
      await tester.pump();
      expect(state.window, isNull);
      expect(state.error, isNotNull);
      backend.failTime = false;
      await state.synchronize(force: true);
      expect(state.window, isNotNull);
      backend.time = now.add(const Duration(minutes: 5));
      backend.failTime = true;
      await tester.pump(const Duration(minutes: 5));
      await tester.pump();
      expect(state.window, isNull);
      expect(state.error, isNotNull);
      state.dispose();
      backend.close();
      await tester.pump();
    },
  );

  testWidgets(
    'active boarding results disappear on passed-stop progress and GPS expiry without server events',
    (tester) async {
      final backend = ControlledSearch();
      await tester.pumpWidget(
        MaterialApp(
          home: RouteResultsScreen(
            searchBackend: backend,
            fromStationId: 'b',
            toStationId: 'c',
            origin: 'Boarding',
            destination: 'Destination',
            wheelchairAccessRequired: false,
            stepFreeOnly: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      backend.runEvents.add([run(status: 'in_progress')]);
      await tester.pumpAndSettle();
      backend.tripEvents.add(operation());
      backend.gpsEvents.add(gps());
      await tester.pumpAndSettle();
      expect(find.text('DATED-17'), findsOneWidget);
      expect(find.text('Started run'), findsOneWidget);
      backend.tripEvents.add(operation(index: 2));
      await tester.pumpAndSettle();
      expect(find.text('DATED-17'), findsNothing);
      backend.tripEvents.add(operation());
      await tester.pumpAndSettle();
      expect(find.text('DATED-17'), findsOneWidget);
      backend.time = now.add(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 31));
      expect(find.text('DATED-17'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      backend.close();
      await tester.pumpAndSettle();
    },
  );
}
