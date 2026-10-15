import 'dart:async';

import 'package:access_transit/logic/live_accessibility_evidence.dart';
import 'package:access_transit/models/bus_location_model.dart';
import 'package:access_transit/models/enums/report_condition.dart';
import 'package:access_transit/models/enums/report_publication_state.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/models/station.dart';
import 'package:access_transit/widgets/live_accessibility_panel.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('live evidence subscription surfaces backend read failure instead of successful fallback', () async {
    await expectLater(
      FirestoreService().streamReports(surfaceErrors: true),
      emitsInOrder([isA<List<Report>>(), emitsError(anything), emitsDone]),
    );
  });
  final now = DateTime(2026, 10, 14, 10);
  Report report({
    String type = 'bus',
    String id = 'bus1',
    String category = 'rampAccess',
    String problem = 'Ramp Working',
    ReportCondition condition = ReportCondition.positive,
    DateTime? time,
  }) => Report(
    id: 'evidence_$id',
    targetType: type,
    targetId: id,
    problemType: problem,
    category: category,
    condition: condition,
    status: 'active',
    createdAt: time ?? now.subtract(const Duration(minutes: 5)),
    userId: 'reporter',
  );
  LiveAccessibilityEvidence ramp(List<Report> reports) =>
      LiveAccessibilityEvidence.forEquipment(
        reports: reports,
        targetType: 'bus',
        targetId: 'bus1',
        category: 'rampAccess',
        now: now,
      );

  test('missing or malformed equipment fields remain unknown on parse and round trip', () {
    final empty = BusLocationModel.fromMap({'busId': 'bus1'});
    expect(empty.rampOperational, isNull);
    expect(empty.elevatorWorking, isNull);
    final parsed = BusLocationModel.fromMap(
      empty.toMap(isServerTimestamp: false),
    );
    expect(parsed.rampOperational, isNull);
    expect(parsed.elevatorWorking, isNull);
    expect(
      BusLocationModel.fromMap({'rampOperational': 'true'}).rampOperational,
      isNull,
    );
    expect(
      BusLocationModel.fromMap({'rampOperational': false}).rampOperational,
      isFalse,
    );
    expect(
      BusLocationModel.fromMap({'rampOperational': true}).rampOperational,
      isTrue,
    );
    expect(
      BusLocationModel(
        busId: 'bus1',
        latitude: 0,
        longitude: 0,
      ).rampOperational,
      isNull,
    );
  });
  test('absence, wrong bus, wrong equipment and expired positive do not establish Working', () {
    expect(ramp([]).state, EquipmentObservation.unknown);
    expect(ramp([report(id: 'other')]).state, EquipmentObservation.unknown);
    expect(
      ramp([report(category: 'cleanliness')]).state,
      EquipmentObservation.unknown,
    );
    expect(
      ramp([report(time: now.subtract(const Duration(hours: 25)))]).state,
      EquipmentObservation.unknown,
    );
  });
  test('published fresh positive is Working reported without claiming verification', () {
    expect(ramp([report()]).label, 'Working reported');
  });
  test('broken ramp persists beyond freshness and a positive cannot silently resolve it', () {
    final broken = report(
      problem: 'Ramp Broken',
      condition: ReportCondition.barrier,
    );
    expect(ramp([broken, report()]).state, EquipmentObservation.barrier);
    expect(
      ramp([
        broken.copyWith(createdAt: now.subtract(const Duration(days: 3))),
        report(),
      ]).state,
      EquipmentObservation.unresolved,
    );
    expect(
      ramp([broken.copyWith(status: 'resolved'), report()]).state,
      EquipmentObservation.positive,
    );
  });
  test(
    'future, demo, pending and independently flagged observations do not count',
    () {
      for (final r in [
        report(time: now.add(const Duration(minutes: 1))),
        report().copyWith(isDemo: true),
        report().copyWith(
          publicationState: ReportPublicationState.pendingUpload,
        ),
        report().copyWith(falseCount: 3, flaggedBy: ['a', 'b', 'c']),
      ]) {
        expect(ramp([r]).state, EquipmentObservation.unknown);
      }
    },
  );
  test('newer or tied uncertainty wins over older positive evidence', () {
    final unknown = report(
      condition: ReportCondition.unknown,
      problem: 'Not checked',
      time: now,
    );
    expect(ramp([report(), unknown]).state, EquipmentObservation.unknown);
    expect(
      ramp([report(time: now), unknown]).state,
      EquipmentObservation.unknown,
    );
    expect(
      ramp([
        report(time: now),
        unknown.copyWith(createdAt: now.subtract(const Duration(hours: 1))),
      ]).state,
      EquipmentObservation.positive,
    );
  });
  test('elevator evidence is scoped by exact endpoint ID and never comes from bus data', () {
    final reports = [
      report(category: 'elevatorOut', problem: 'Elevator Working'),
      report(
        type: 'station',
        id: 'other-stop',
        category: 'elevatorOut',
        problem: 'Elevator Working',
      ),
      report(
        type: 'station',
        id: 'origin',
        category: 'elevatorOut',
        problem: 'Elevator Working',
      ),
    ];
    LiveAccessibilityEvidence elevator(String? id) =>
        LiveAccessibilityEvidence.forEquipment(
          reports: reports,
          targetType: 'station',
          targetId: id,
          category: 'elevatorOut',
          now: now,
        );
    expect(elevator('origin').state, EquipmentObservation.positive);
    expect(elevator('destination').state, EquipmentObservation.unknown);
    expect(elevator(null).state, EquipmentObservation.unknown);
  });
  test('stop aliases deduplicate IDs; ambiguous or unknown names cannot pick a first stop', () {
    const first = Station(
      id: 's1',
      name: 'Fort',
      hasElevator: true,
      hasRamp: true,
      lat: 0,
      lng: 0,
    );
    const second = Station(
      id: 's2',
      name: 'Fort',
      hasElevator: true,
      hasRamp: true,
      lat: 0,
      lng: 0,
    );
    expect(
      LiveAccessibilityEvidence.resolveStopId('Fort', {
        's1': first,
        'Fort': first,
      }),
      's1',
    );
    expect(
      LiveAccessibilityEvidence.resolveStopId('Fort', {
        's1': first,
        's2': second,
      }),
      isNull,
    );
    expect(
      LiveAccessibilityEvidence.resolveStopId('Missing', {'s1': first}),
      isNull,
    );
  });

  Future<void> show(
    WidgetTester tester,
    Stream<List<Report>> stream, {
    DateTime Function()? clock,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LiveAccessibilityPanel(
              busId: 'bus1',
              origin: 'Fort',
              destination: 'Library',
              originId: 'origin',
              destinationId: 'destination',
              reportsStream: stream,
              now: clock ?? () => now,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'no checks show Unknown, with no verified or alternative-ramp claims',
    (tester) async {
      await show(tester, Stream.value([]));
      expect(find.text('Unknown'), findsNWidgets(3));
      expect(find.textContaining('Verified active'), findsNothing);
      expect(find.textContaining('Alternative ramp accessible'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'legacy positive GPS flags cannot establish ramp or either stop elevator',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LiveAccessibilityPanel(
                busId: 'bus1',
                origin: 'Fort',
                destination: 'Library',
                telemetry: BusLocationModel(
                  busId: 'bus1',
                  latitude: 0,
                  longitude: 0,
                  timestamp: now,
                  rampOperational: true,
                  elevatorWorking: true,
                ),
                reportsStream: Stream.value([]),
                now: () => now,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unknown'), findsNWidgets(3));
      expect(find.text('Working reported'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'negative ramp telemetry remains an unverified warning even with a positive report',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LiveAccessibilityPanel(
                busId: 'bus1',
                origin: 'Fort',
                destination: 'Library',
                telemetry: BusLocationModel(
                  busId: 'bus1',
                  latitude: 0,
                  longitude: 0,
                  rampOperational: false,
                  elevatorWorking: false,
                ),
                reportsStream: Stream.value([report()]),
                now: () => now,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Unknown — vehicle ramp warning needs checking'),
        findsOneWidget,
      );
      expect(find.text('Unknown'), findsNWidgets(2));
      expect(
        find.textContaining('Equipment-check time is Unknown'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'live changes update ramp while independently isolating both stop elevators',
    (tester) async {
      final updates = StreamController<List<Report>>();
      await show(tester, updates.stream);
      updates.add([
        report(),
        report(
          type: 'station',
          id: 'origin',
          category: 'elevatorOut',
          problem: 'Elevator Working',
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Working reported'), findsNWidgets(2));
      expect(find.text('Unknown'), findsOneWidget);
      expect(
        find.textContaining('Reported by: Account reporter'),
        findsNWidgets(2),
      );
      updates.add([
        report(problem: 'Ramp Broken', condition: ReportCondition.barrier),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Barrier reported'), findsOneWidget);
      expect(find.text('Unknown'), findsNWidgets(2));
      await tester.pumpWidget(const SizedBox());
      unawaited(updates.close());
    },
  );
  testWidgets(
    'freshness expires on a timer even when GPS and reports stop updating',
    (tester) async {
      var clock = now;
      await show(
        tester,
        Stream.value([report(time: now.subtract(const Duration(hours: 23)))]),
        clock: () => clock,
      );
      expect(find.text('Working reported'), findsOneWidget);
      clock = now.add(const Duration(hours: 2));
      await tester.pump(const Duration(minutes: 1));
      expect(find.text('Working reported'), findsNothing);
      expect(find.text('Unknown'), findsNWidgets(3));
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'failed updates retain previously received broken-equipment warning',
    (tester) async {
      final updates = StreamController<List<Report>>();
      await show(tester, updates.stream);
      updates.add([
        report(
          problem: 'Ramp Broken',
          condition: ReportCondition.barrier,
          time: now.subtract(const Duration(days: 3)),
        ),
      ]);
      await tester.pumpAndSettle();
      updates.addError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text('Unresolved barrier — needs recheck'), findsOneWidget);
      expect(
        find.textContaining('Condition updates unavailable'),
        findsOneWidget,
      );
      expect(find.text('Working reported'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      unawaited(updates.close());
    },
  );

  testWidgets('report stream errors visibly withdraw current working claims', (
    tester,
  ) async {
    final updates = StreamController<List<Report>>();
    await show(tester, updates.stream);
    updates.add([report()]);
    await tester.pumpAndSettle();
    expect(find.text('Working reported'), findsOneWidget);
    updates.addError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Condition updates unavailable'),
      findsOneWidget,
    );
    expect(find.text('Working reported'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    unawaited(updates.close());
  });
}
