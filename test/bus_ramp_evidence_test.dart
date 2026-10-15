import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/logic/status_logic.dart';
import 'package:access_transit/widgets/bus_ramp_observation.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart'
    show AccessibilityStatus;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 15, 12);
  Bus bus([Map<String, dynamic> extra = const {}]) => Bus.fromMap({
    'id': 'bus',
    'routeNo': '1',
    'hasRamp': true,
    'lowFloor': true,
    'occupancy': 'low',
    'stops': <String>[],
    ...extra,
  });
  Bus checked() => bus({
    'rampOk': true,
    'rampCheckedAt': Timestamp.fromDate(now),
    'rampCheckedBy': 'operator',
  });
  Report report(String target, {bool broken = false}) => Report.fromMap({
    'id': 'r-$target',
    'targetId': target,
    'targetType': 'bus',
    'userId': 'observer',
    'category': 'rampAccess',
    'problemType': broken ? 'Ramp Broken' : 'Ramp Working',
    'condition': broken ? 'barrier' : 'positive',
    'createdAt': Timestamp.fromDate(now),
  });
  BusStatusResult assess(Bus vehicle, [List<Report> reports = const []]) =>
      StatusLogic.getBusStatus(
        vehicle,
        reports,
        currentTime: now,
        wheelchairAccessRequired: true,
      );

  test(
    'missing/null/malformed flags remain unknown despite ramp capability',
    () {
      for (final value in [null, 'true', 1, {}, []]) {
        final vehicle = bus({'rampOk': value});
        expect(vehicle.rampOk, isNull);
        expect(vehicle.wheelchairAccessible, isFalse);
        expect(assess(vehicle).status, AccessibilityStatus.unknown);
      }
    },
  );
  test('positive flags require check time, source and freshness', () {
    for (final extra in [
      <String, dynamic>{},
      {'rampCheckedAt': now},
      {'rampCheckedBy': 'operator'},
      {'rampCheckedAt': now, 'rampCheckedBy': ' '},
      {
        'rampCheckedAt': now.add(const Duration(seconds: 1)),
        'rampCheckedBy': 'operator',
      },
      {
        'rampCheckedAt': now.subtract(const Duration(hours: 25)),
        'rampCheckedBy': 'operator',
      },
    ]) {
      expect(
        assess(bus({'rampOk': true, ...extra})).status,
        AccessibilityStatus.unknown,
      );
    }
    expect(assess(checked()).status, AccessibilityStatus.accessible);
    expect(
      checked().rampCondition(
        currentTime: now.add(const Duration(hours: 24, seconds: 1)),
      ),
      isNull,
    );
  });
  test('invalid check timestamps cannot normalize into working evidence', () {
    for (final value in [
      'bad',
      '2026-02-30T12:00:00Z',
      '2026-10-15T25:00:00Z',
      9223372036854775807,
    ]) {
      final vehicle = bus({
        'rampOk': true,
        'rampCheckedAt': value,
        'rampCheckedBy': 'operator',
      });
      expect(vehicle.rampCheckedAt, isNull);
      expect(assess(vehicle).status, AccessibilityStatus.unknown);
    }
  });
  test('map and unrelated copy retain observation while condition changes invalidate old checks', () {
    final vehicle = checked();
    expect(Bus.fromMap(vehicle.toMap(), id: vehicle.id), vehicle);
    expect(vehicle.copyWith(occupancy: 'high').rampCheckedAt, now);
    final changed = vehicle.copyWith(rampOk: false);
    expect(changed.rampCheckedAt, isNull);
    expect(changed.rampCheckedBy, isNull);
    expect(changed.rampCondition(currentTime: now), isFalse);
    expect(
      changed.copyWith(rampOk: true).rampCondition(currentTime: now),
      isNull,
    );
  });
  test(
    'legacy negatives persist as warnings without inventing dates or sources',
    () {
      final vehicle = bus({'rampOk': false});
      expect(vehicle.rampCondition(currentTime: now), isFalse);
      expect(vehicle.rampCheckedAt, isNull);
      expect(vehicle.rampCheckedBy, isNull);
      expect(
        assess(vehicle, [report('bus')]).status,
        AccessibilityStatus.notAccessible,
      );
    },
  );
  test(
    'only recent scoped observations can supply an unknown operational check',
    () {
      expect(
        assess(bus(), [report('different')]).status,
        AccessibilityStatus.unknown,
      );
      expect(
        assess(bus(), [report('bus')]).status,
        AccessibilityStatus.accessible,
      );
      expect(
        assess(bus(), [
          report('bus')
              .copyWith(createdAt: now.subtract(const Duration(days: 2))),
        ]).status,
        AccessibilityStatus.unknown,
      );
      expect(
        assess(checked(), [report('bus', broken: true)]).status,
        AccessibilityStatus.notAccessible,
      );
    },
  );
  test(
    'working observations cannot supply missing physical ramp capability',
    () {
      expect(
        assess(bus({'hasRamp': false}), [report('bus')]).status,
        AccessibilityStatus.notAccessible,
      );
    },
  );
  testWidgets(
    'unknown condition and capability display separately without fabricated source',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BusRampObservation(bus: bus(), currentTime: now),
          ),
        ),
      );
      expect(find.text('Ramp capability: Equipped'), findsOneWidget);
      expect(
        find.textContaining('operational condition: Unknown'),
        findsOneWidget,
      );
      expect(find.text('Ramp last checked: Unknown'), findsOneWidget);
      expect(find.text('Ramp observation source: Unknown'), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BusRampObservation(
              bus: checked().copyWith(
                rampCheckedAt: now.add(const Duration(hours: 1)),
              ),
              currentTime: now,
            ),
          ),
        ),
      );
      expect(find.text('Ramp last checked: Unknown'), findsOneWidget);
      expect(
        find.textContaining('operational condition: Unknown'),
        findsOneWidget,
      );
    },
  );
  testWidgets('working observation displays actual source and check age', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BusRampObservation(bus: checked(), currentTime: now),
        ),
      ),
    );
    expect(find.text('Ramp observation source: operator'), findsOneWidget);
    expect(find.text('Ramp last checked: Just now'), findsOneWidget);
    expect(find.textContaining('Working observed'), findsOneWidget);
  });
}
