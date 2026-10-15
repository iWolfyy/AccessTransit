import 'dart:convert';
import 'dart:io';

import 'package:access_transit/logic/passenger_journey_plan.dart';
import 'package:access_transit/models/bus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'published expansion supports every timing-point pair and overnight run',
    () {
      final catalogue = jsonDecode(
        File('docs/catalogue-review/expanded-timetables.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final original = jsonDecode(
        File('docs/catalogue-review/published-timetables.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final stationIds = {
        for (final s in [...original['stations'], ...catalogue['stations']])
          s['id'],
      };
      final runs = catalogue['runs'] as Map<String, dynamic>;
      var runCount = 0;
      var overnightCount = 0;
      for (final route in catalogue['routes']) {
        final stops = List<String>.from(route['stops']);
        expect(stationIds.containsAll(stops), isTrue);
        for (final raw in runs[route['id']]) {
          final times = List<String>.from(raw);
          final bus = Bus.fromMap({
            'routeId': route['id'],
            'routeNo': route['routeNo'],
            'stops': stops,
            'scheduleTimes': times,
            'scheduledDeparture': times.first,
            'catalogueRecordType': 'published_timetable',
            'sourceUrl': catalogue['sourceUrl'],
            'rampOk': null,
            'occupancy': 'unknown',
          });
          expect(bus.displayBusNo, 'Vehicle unassigned');
          expect(bus.rampCondition(), isNull);
          for (var from = 0; from < stops.length - 1; from++) {
            for (var to = from + 1; to < stops.length; to++) {
              final plan = PassengerJourneyPlan.forBus(
                bus: bus,
                fromId: stops[from],
                toId: stops[to],
                travelDate: DateTime(2026, 10, 17),
                notBefore: DateTime(2026, 10, 17),
              );
              expect(plan, isNotNull, reason: '${route['id']}: $from -> $to');
              expect(plan!.usesEstimatedTimes, isFalse);
              expect(plan.durationMinutes, inInclusiveRange(1, 720));
              expect(plan.departure.day, 17);
              if (from == 0 &&
                  to == stops.length - 1 &&
                  plan.arrival.day == 18) {
                overnightCount++;
              }
            }
          }
          runCount++;
        }
      }
      expect(runCount, 32);
      expect(overnightCount, 6);
    },
  );
}
