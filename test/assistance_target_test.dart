import 'package:access_transit/logic/delay_eta_logic.dart';
import 'package:access_transit/models/assistance_target.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/bus_location_model.dart';
import 'package:access_transit/models/enums/bus_status.dart';
import 'package:access_transit/models/station.dart';
import 'package:access_transit/screens/journey/boarding_assistance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bus = Bus(
    id: 'bus_101',
    routeNo: '101',
    busNo: 'NE-3390',
    hasRamp: true,
    lowFloor: true,
    rampOk: true,
    occupancy: 'low',
    stops: ['origin', 'shared', 'destination'],
  );
  const origin = Station(
    id: 'origin',
    name: 'Boarding stop',
    hasRamp: true,
    hasElevator: false,
    lat: 6.9,
    lng: 79.8,
  );
  const destination = Station(
    id: 'destination',
    name: 'Getting-off stop',
    hasRamp: true,
    hasElevator: false,
    lat: 6.8,
    lng: 79.8,
  );
  const shared = Station(
    id: 'shared',
    name: 'Shared stop',
    hasRamp: true,
    hasElevator: false,
    lat: 6.8,
    lng: 79.8,
  );
  final stations = {
    'origin': origin,
    'destination': destination,
    'shared': shared,
  };
  AssistanceTarget? resolve(
    String? id,
    String name, {
    AssistancePurpose purpose = AssistancePurpose.boarding,
  }) => AssistanceTarget.resolve(
    busId: bus.id,
    bus: bus,
    stationId: id,
    stopName: name,
    stations: stations,
    purpose: purpose,
  );

  test('boarding and alighting preserve the selected non-default bus and different endpoints', () {
    final board = resolve('origin', origin.name)!;
    final exit = resolve(
      'destination',
      destination.name,
      purpose: AssistancePurpose.alighting,
    )!;
    expect(board.busId, 'bus_101');
    expect(board.stationId, 'origin');
    expect(exit.stationId, 'destination');
    expect(exit.purpose, AssistancePurpose.alighting);
    expect(exit.busLabel, 'NE-3390 (Route 101)');
  });
  test('missing or changed bus never uses a different bus as fallback', () {
    expect(
      AssistanceTarget.resolve(
        busId: 'other-bus',
        bus: bus,
        stationId: 'origin',
        stopName: origin.name,
        stations: stations,
      ),
      isNull,
    );
    expect(
      AssistanceTarget.resolve(
        busId: bus.id,
        bus: null,
        stationId: 'origin',
        stopName: origin.name,
        stations: stations,
      ),
      isNull,
    );
  });
  test('an invalid explicit ID never falls back to a matching name or the first stop', () {
    expect(resolve('not-on-route', origin.name), isNull);
    expect(resolve(null, 'Boarding'), isNull);
    expect(resolve(null, ' boarding stop ')?.stationId, 'origin');
    expect(resolve('shared', shared.name)?.stationId, 'shared');
  });
  test('ambiguous legacy stop names are not resolved silently', () {
    final duplicatedNames = {
      ...stations,
      'destination': Station(
        id: 'destination',
        name: origin.name,
        hasRamp: true,
        hasElevator: false,
        lat: 6.8,
        lng: 79.8,
      ),
    };
    expect(
      AssistanceTarget.resolve(
        busId: bus.id,
        bus: bus,
        stopName: origin.name,
        stations: duplicatedNames,
      ),
      isNull,
    );
  });
  test(
    'only fresh same-bus same-stop live estimates appear on the request',
    () {
      final now = DateTime(2026, 10, 14, 12);
      final target = resolve('origin', origin.name)!;
      final telemetry = BusLocationModel(
        busId: bus.id,
        latitude: 6.9,
        longitude: 79.8,
        timestamp: now,
        isBroadcasting: true,
        status: BusStatus.active,
      );
      BusArrivalEtaResult eta({
        String id = 'origin',
        String vehicle = 'bus_101',
        bool live = true,
      }) => BusArrivalEtaResult(
        busId: vehicle,
        routeNo: '101',
        targetStopId: id,
        targetStopName: origin.name,
        scheduledArrival: now,
        scheduledArrivalStr: '',
        estimatedArrival: now.add(const Duration(minutes: 7)),
        estimatedArrivalStr: '',
        delayMinutes: 0,
        delayType: DelayType.onTime,
        delayLabel: '',
        countdownMinutes: 7,
        countdownText: '',
        isLive: live,
        liveStatusDescription: '',
        stopsTimeline: [],
      );
      expect(
        target.minutesFrom(eta(), telemetry: telemetry, currentTime: now),
        7,
      );
      expect(
        target.minutesFrom(
          eta(id: 'destination'),
          telemetry: telemetry,
          currentTime: now,
        ),
        isNull,
      );
      expect(
        target.minutesFrom(
          eta(vehicle: 'other'),
          telemetry: telemetry,
          currentTime: now,
        ),
        isNull,
      );
      expect(
        target.minutesFrom(
          eta(live: false),
          telemetry: telemetry,
          currentTime: now,
        ),
        isNull,
      );
      expect(target.minutesFrom(eta(), currentTime: now), isNull);
      expect(
        target.minutesFrom(
          eta(),
          telemetry: telemetry,
          currentTime: now.add(const Duration(minutes: 6)),
        ),
        isNull,
      );
    },
  );
  testWidgets(
    'navigation carries the exact alighting target; no ETA becomes Unknown',
    (tester) async {
      final target = resolve(
        'destination',
        destination.name,
        purpose: AssistancePurpose.alighting,
      )!;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    openBoardingAssistance(context, target: target),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final form = tester.widget<BoardingAssistanceScreen>(
        find.byType(BoardingAssistanceScreen),
      );
      expect(form.busId, bus.id);
      expect(form.stationId, 'destination');
      expect(form.purpose, AssistancePurpose.alighting);
      expect(form.minutesAway, isNull);
      expect(find.text('ETA unknown'), findsOneWidget);
      expect(find.textContaining('12 users today'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'unresolved target blocks navigation instead of opening a default form',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => openBoardingAssistance(context, target: null),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(BoardingAssistanceScreen), findsNothing);
      expect(
        find.textContaining('assistance bus or stop is unknown'),
        findsOneWidget,
      );
    },
  );
}
