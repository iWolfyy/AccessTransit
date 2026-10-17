import 'dart:async';

import 'package:access_transit/logic/bus_details_state.dart';
import 'package:access_transit/logic/journey_selection.dart';
import 'package:access_transit/logic/transit_time.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/bus_location_model.dart';
import 'package:access_transit/models/journey_model.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/models/service_run.dart';
import 'package:access_transit/models/station.dart';
import 'package:access_transit/models/trip_model.dart';
import 'package:access_transit/screens/journey/bus_details_screen.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/services/bus_details_repository.dart';
import 'package:access_transit/services/journey_service.dart';
import 'package:access_transit/widgets/evidence_refresh.dart';
import 'package:access_transit/widgets/save_trip_control.dart';
import 'package:access_transit/widgets/selected_segment_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final clock = DateTime(2026, 10, 16, 10);
const vehicle = Bus(
  id: 'physical',
  routeId: 'route',
  routeNo: '17',
  driverId: 'driver',
  busNo: 'TEST-17',
  stops: ['a', 'b', 'c', 'd', 'e'],
  scheduleTimes: ['09:00', '10:00', '10:30', '11:00', '12:00'],
  hasRamp: true,
  lowFloor: true,
  occupancy: 'unknown',
);
final selection = RouteResultItem(
  id: vehicle.id,
  busId: vehicle.id,
  rawBus: vehicle,
  title: 'Route 17 · TEST-17',
  origin: 'Boarding',
  destination: 'Destination',
  fromStationId: 'b',
  toStationId: 'd',
  intermediateStops: ['c'],
  nextDepartureDateTime: clock,
  selectedDate: clock,
  durationMinutes: 60,
  departureTimeStr: '10:00 AM',
  arrivalTimeStr: '11:00 AM',
  estimatedPriceLkr: 170,
  etaLabel: 'Scheduled',
  transfers: 0,
  crowdLevel: 'Unknown',
  accessibilityStatus: AccessibilityStatus.unknown,
  accessibilityLabel: 'Unknown',
  safetyLabel: 'Unknown',
  summary: 'Selected segment',
);
ServiceRun run([String status = 'in_progress']) => ServiceRun(
  id: 'run-1',
  busId: vehicle.id,
  routeId: 'route',
  routeNo: '17',
  serviceDate: '2026-10-16',
  status: status,
  plannedDepartureAt: clock.subtract(const Duration(hours: 1)).toUtc(),
  latestStartAt: clock.subtract(const Duration(minutes: 30)).toUtc(),
  stopTimes: {
    for (var i = 0; i < vehicle.stops.length; i++)
      vehicle.stops[i]: clock
          .add(Duration(minutes: [-60, 0, 30, 60, 120][i]))
          .toUtc(),
  },
);
TripModel trip() => TripModel(
  tripId: 'run-1',
  serviceRunId: 'run-1',
  busId: vehicle.id,
  routeNo: '17',
  stops: vehicle.stops,
  status: 'in_progress',
  driverId: 'driver',
  scheduledDepartureTime: run().plannedDepartureAt,
  actualDepartureTime: run().plannedDepartureAt,
  stopTimes: {},
  createdAt: clock,
);
BusLocationModel gps() => BusLocationModel(
  busId: vehicle.id,
  tripId: 'run-1',
  driverId: 'driver',
  latitude: 6.9,
  longitude: 79.8,
  timestamp: clock,
);
Report report(String id, String type, String target) => Report(
  id: id,
  targetType: type,
  targetId: target,
  targetName: target,
  problemType: id,
  status: 'active',
  createdAt: clock,
  userId: 'observer',
);

class DetailsFixture extends BusDetailsRepository {
  final runEvents = StreamController<List<ServiceRun>>();
  final reportEvents = StreamController<List<Report>>();
  String? reportBus;
  List<String>? reportStops;
  @override
  Stream<Bus?> bus(String id) => Stream.value(vehicle);
  @override
  Future<List<Station>> stations() async => [
    for (final id in vehicle.stops)
      Station(
        id: id,
        name: 'Stop $id',
        hasElevator: false,
        hasRamp: false,
        lat: 0,
        lng: 0,
      ),
  ];
  @override
  Stream<List<ServiceRun>> runs(String id) => runEvents.stream;
  @override
  Stream<List<Report>> reports({
    required String busId,
    required List<String> stopIds,
  }) {
    reportBus = busId;
    reportStops = List.of(stopIds);
    return reportEvents.stream;
  }

  @override
  Stream<TripModel?> trip(String id) => Stream.value(
    TripModel(
      tripId: 'run-1',
      serviceRunId: 'run-1',
      busId: vehicle.id,
      routeNo: '17',
      stops: vehicle.stops,
      status: 'in_progress',
      driverId: 'driver',
      scheduledDepartureTime: run().plannedDepartureAt,
      actualDepartureTime: run().plannedDepartureAt,
      stopTimes: {},
      createdAt: clock,
    ),
  );
  @override
  Stream<BusLocationModel?> location(String id) => Stream.value(gps());
  void close() {
    unawaited(runEvents.close());
    unawaited(reportEvents.close());
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init(userId: 'rider');
  });

  test('only the selected dated run can establish current GPS', () {
    BusLocationModel? visible({
      ServiceRun? service,
      TripModel? operation,
      BusLocationModel? location,
      DateTime? now,
    }) => BusDetailsState.currentLocation(
      selection: selection,
      run: service ?? run(),
      trip: operation ?? trip(),
      location: location ?? gps(),
      now: now ?? clock,
    );
    expect(visible(), isNotNull);
    expect(visible(service: run('scheduled')), isNull);
    expect(visible(service: run('completed')), isNull);
    expect(visible(service: run('cancelled')), isNull);
    expect(visible(location: gps().copyWith(tripId: 'another-run')), isNull);
    expect(visible(location: gps().copyWith(busId: 'another-bus')), isNull);
    expect(
      visible(location: gps().copyWith(driverId: 'another-driver')),
      isNull,
    );
    expect(visible(location: gps().copyWith(isCached: true)), isNull);
    expect(visible(location: gps().copyWith(isBroadcasting: false)), isNull);
    expect(
      visible(
        location: gps().copyWith(
          timestamp: clock.add(const Duration(seconds: 1)),
        ),
      ),
      isNull,
    );
    expect(visible(now: clock.add(const Duration(seconds: 30))), isNotNull);
    expect(
      visible(now: clock.add(const Duration(seconds: 30, microseconds: 1))),
      isNull,
    );
  });

  test('reports match only this bus and the selected ordered stop segment', () {
    final found = BusDetailsState.relevantReports(
      [
        report('bus issue', 'bus', vehicle.id),
        report('middle issue', 'station', 'c'),
        report('boarding issue', 'station', 'b'),
        report('alighting issue', 'station', 'd'),
        report('outside', 'station', 'a'),
        report('other bus', 'bus', 'other'),
        report('hidden', 'bus', vehicle.id).copyWith(status: 'hidden'),
        report('disputed', 'bus', vehicle.id).copyWith(falseCount: 5),
        report(
          'old positive',
          'bus',
          vehicle.id,
        ).copyWith(createdAt: clock.subtract(const Duration(days: 2))),
      ],
      selection,
      clock,
    );
    expect(found.map((r) => r.id).toSet(), {
      'bus issue',
      'middle issue',
      'boarding issue',
      'alighting issue',
    });
  });

  test('run identity survives bookmark serialization and restore', () {
    final saved = JourneySelection.create(
      selection,
      id: 'saved',
      passengerId: 'rider',
      serviceRunId: 'run-1',
    );
    final restored = JourneySelection.restore(
      JourneyModel.fromMap(saved.toMap()),
      vehicle,
      {},
    );
    expect(restored.serviceRunId, 'run-1');
    expect(saved.copyWith(status: JourneyStatus.active).serviceRunId, 'run-1');
    expect(
      BusLocationModel.fromMap(gps().toMap(isServerTimestamp: false))
          .copyWith(speed: 20)
          .tripId,
      'run-1',
    );
  });

  testWidgets(
    'details stays on one page; matching GPS expires without remote activity',
    (tester) async {
      final repository = DetailsFixture();
      var now = clock;
      var writes = 0;
      final service = JourneyService(
        currentPassengerId: () => 'rider',
        journeyReader: (_) => Stream.value(null),
        writer: (j) async {
          writes++;
          return j;
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: EvidenceClock(
            now: () => now,
            child: BusDetailsScreen(
              origin: 'Boarding',
              destination: 'Destination',
              route: selection,
              searchClock: SearchTimeAnchor(
                clock,
                elapsed: () => now.difference(clock),
              ),
              repository: repository,
              journeyService: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      repository.runEvents.add([run('scheduled')]);
      repository.reportEvents.add([
        report('Inside report', 'station', 'c'),
        report('Outside report', 'station', 'a'),
      ]);
      expect(repository.reportBus, 'physical');
      expect(repository.reportStops, ['b', 'c', 'd']);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SelectedSegmentMap>(find.byType(SelectedSegmentMap))
            .location,
        isNull,
      );
      expect(writes, 0);
      repository.runEvents.add([run()]);
      await tester.pumpAndSettle();
      expect(find.text('LIVE GPS'), findsOneWidget);
      expect(
        tester
            .widget<SelectedSegmentMap>(find.byType(SelectedSegmentMap))
            .location
            ?.tripId,
        'run-1',
      );
      now = clock.add(const Duration(seconds: 30, microseconds: 1));
      await tester.pump(const Duration(seconds: 31));
      expect(
        tester
            .widget<SelectedSegmentMap>(find.byType(SelectedSegmentMap))
            .location,
        isNull,
      );
      expect(find.text('LIVE GPS'), findsNothing);
      await tester.scrollUntilVisible(find.text('Inside report'), 350);
      expect(find.text('Outside report'), findsNothing);
      await tester.scrollUntilVisible(find.text('Save Trip'), 250);
      expect(
        tester.getTopLeft(find.text('Inside report')).dy,
        lessThan(tester.getTopLeft(find.text('Save Trip')).dy),
      );
      expect(writes, 0);
      repository.reportEvents.add([
        report('Inside report', 'station', 'c').copyWith(falseCount: 5),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Inside report'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      repository.close();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'failed saves retry the same ID; success stays in details and removal is acknowledged',
    (tester) async {
      final attempts = <JourneyModel>[];
      var reject = true, removeReject = true;
      JourneyModel? stored;
      final service = JourneyService(
        currentPassengerId: () => 'rider',
        journeyReader: (_) => Stream.value(stored),
        writer: (j) async {
          attempts.add(j);
          if (reject) throw StateError('Denied');
          stored = j;
          return j;
        },
        remover: (_) async {
          if (removeReject) throw StateError('Remove denied');
          stored = null;
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SaveTripControl(
              route: selection,
              runId: 'run-1',
              service: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(attempts, isEmpty);
      await tester.tap(find.text('Save Trip'));
      await tester.pumpAndSettle();
      expect(find.text('Denied'), findsOneWidget);
      expect(find.text('Saved trip'), findsNothing);
      reject = false;
      await tester.tap(find.text('Save Trip'));
      await tester.pumpAndSettle();
      expect(attempts[0].journeyId, attempts[1].journeyId);
      expect(attempts.last.serviceRunId, 'run-1');
      expect(find.text('Saved trip'), findsOneWidget);
      await tester.tap(find.text('Remove saved trip'));
      await tester.pumpAndSettle();
      expect(find.text('Remove denied'), findsOneWidget);
      expect(find.text('Saved trip'), findsOneWidget);
      removeReject = false;
      await tester.tap(find.text('Remove saved trip'));
      await tester.pumpAndSettle();
      expect(find.text('Saved trip'), findsNothing);
      expect(find.text('Save Trip'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'remote bookmark deletion clears a previous save acknowledgement',
    (tester) async {
      JourneyModel? stored;
      final changes = StreamController<JourneyModel?>.broadcast();
      Stream<JourneyModel?> watch(String _) async* {
        yield stored;
        yield* changes.stream;
      }

      final service = JourneyService(
        currentPassengerId: () => 'rider',
        journeyReader: watch,
        writer: (j) async {
          stored = j;
          return j;
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SaveTripControl(
              route: selection,
              runId: 'run-1',
              service: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Trip'));
      await tester.pumpAndSettle();
      expect(find.text('Saved trip'), findsOneWidget);
      stored = null;
      changes.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Saved trip'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      unawaited(changes.close());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'details fits 320dp at 200 percent text and reports precede optional save',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = DetailsFixture();
      final service = JourneyService(
        currentPassengerId: () => 'rider',
        journeyReader: (_) => Stream.value(null),
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: EvidenceClock(
            now: () => clock,
            child: BusDetailsScreen(
              origin: 'Boarding',
              destination: 'Destination',
              route: selection,
              repository: repository,
              journeyService: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      repository.runEvents.add([run('scheduled')]);
      repository.reportEvents.add([]);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Save Trip'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('No current reports in this preview.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      repository.close();
      await tester.pumpAndSettle();
    },
  );
}
