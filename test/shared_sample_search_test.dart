import 'dart:convert';
import 'dart:io';

import 'package:access_transit/logic/passenger_journey_plan.dart';
import 'package:access_transit/logic/status_logic.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/models/station.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart'
    show AccessibilityStatus;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('actual shared sample snapshot retains accessible results in each primary direction', () {
    final snapshot = jsonDecode(
      File('test/fixtures/shared_sample_search.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final now = DateTime.parse(snapshot['asOf'] as String).toLocal();
    final collections = snapshot['collections'] as Map<String, dynamic>;
    final buses = [
      for (final e in (collections['buses'] as Map<String, dynamic>).entries)
        Bus.fromMap(Map<String, dynamic>.from(e.value as Map), id: e.key),
    ];
    final stations = {
      for (final e in (collections['stations'] as Map<String, dynamic>).entries)
        e.key: Station.fromMap(
          Map<String, dynamic>.from(e.value as Map),
          id: e.key,
        ),
    };
    final reports = [
      for (final e in (collections['reports'] as Map<String, dynamic>).entries)
        Report.fromMap(Map<String, dynamic>.from(e.value as Map), id: e.key),
    ];
    for (final route in [
      'ncg_panadura_kandy',
      'ncg_kandy_panadura',
      'ncg_makumbura_badulla',
      'ncg_badulla_makumbura',
    ]) {
      final eligible = buses.where((bus) {
        if (bus.routeId != route || bus.isPublishedTimetable) return false;
        final plan = PassengerJourneyPlan.forBus(
          bus: bus,
          fromId: bus.stops.first,
          toId: bus.stops.last,
          travelDate: now,
          notBefore: now,
          rollToNextDay: true,
        );
        final status = StatusLogic.getBusStatus(
          bus,
          reports,
          stationsMap: stations,
          currentTime: now,
          fromStationId: bus.stops.first,
          toStationId: bus.stops.last,
          wheelchairAccessRequired: true,
          stepFreeOnly: true,
        );
        return plan != null && status.status == AccessibilityStatus.accessible;
      });
      expect(
        eligible,
        isNotEmpty,
        reason:
            'No accessible sample results for $route under default/step-free requirements.',
      );
    }
    expect(
      buses.any((b) => b.rampCondition(currentTime: now) == false),
      isTrue,
    );
    expect(buses.any((b) => b.rampCondition(currentTime: now) == null), isTrue);
    expect(
      reports.any(
        (r) => r.status == 'active' && r.condition?.name == 'barrier',
      ),
      isTrue,
    );
  });
}
