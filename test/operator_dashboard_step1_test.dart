import 'package:flutter_test/flutter_test.dart';
import 'package:access_transit/data/seed_data.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/core/utils/time_utils.dart';

void main() {
  group('Driver Side Step 1: Multi-Run Selector & Status Logic', () {
    test('1. Bus run status classifies future departures as Upcoming', () {
      final now = DateTime(2026, 10, 1, 10, 0); // 10:00 AM
      final today = DateTime(2026, 10, 1);

      const upcomingBus = Bus(
        id: 'bus_test_upcoming',
        routeId: 'route_138_pettah_homagama',
        routeNo: '138',
        hasRamp: true,
        lowFloor: true,
        rampOk: true,
        occupancy: 'low',
        scheduledDeparture: '10:30 AM',
        stops: ['st_pettah', 'st_homagama'],
        scheduleTimes: ['10:30 AM', '11:15 AM'],
      );

      final depTime = TimeUtils.parseTimeStringToDateTime(
        upcomingBus.effectiveDepartureTime,
        today,
      );
      final minsToDep = depTime.difference(now).inMinutes;

      expect(minsToDep, greaterThan(0));
      expect(minsToDep, equals(30));
    });

    test('2. Bus run status classifies active departures as In Progress', () {
      final now = DateTime(2026, 10, 1, 10, 45); // 10:45 AM
      final today = DateTime(2026, 10, 1);

      const inProgressBus = Bus(
        id: 'bus_test_active',
        routeId: 'route_138_pettah_homagama',
        routeNo: '138',
        hasRamp: true,
        lowFloor: true,
        rampOk: true,
        occupancy: 'low',
        scheduledDeparture: '10:30 AM',
        stops: ['st_pettah', 'st_homagama'],
        scheduleTimes: ['10:30 AM', '11:15 AM'],
      );

      final depTime = TimeUtils.parseTimeStringToDateTime(
        inProgressBus.effectiveDepartureTime,
        today,
      );
      final lastStopTime = TimeUtils.parseTimeStringToDateTime(
        inProgressBus.getScheduledTimeForStop(inProgressBus.stops.length - 1),
        today,
      );

      final minsToDep = depTime.difference(now).inMinutes;
      final minsToEnd = lastStopTime.difference(now).inMinutes;

      expect(minsToDep, lessThanOrEqualTo(0));
      expect(minsToEnd, greaterThanOrEqualTo(-5));
    });

    test('3. Bus run status classifies finished runs as Departed', () {
      final now = DateTime(2026, 10, 1, 12, 0); // 12:00 PM
      final today = DateTime(2026, 10, 1);

      const pastBus = Bus(
        id: 'bus_test_past',
        routeId: 'route_138_pettah_homagama',
        routeNo: '138',
        hasRamp: true,
        lowFloor: true,
        rampOk: true,
        occupancy: 'low',
        scheduledDeparture: '10:30 AM',
        stops: ['st_pettah', 'st_homagama'],
        scheduleTimes: ['10:30 AM', '11:15 AM'],
      );

      final lastStopTime = TimeUtils.parseTimeStringToDateTime(
        pastBus.getScheduledTimeForStop(pastBus.stops.length - 1),
        today,
      );
      final minsToEnd = lastStopTime.difference(now).inMinutes;

      expect(minsToEnd, lessThan(-5));
    });

    test('4. Auto-select picks nearest upcoming bus when no bus assigned', () {
      final now = DateTime(2026, 10, 1, 9, 0); // 9:00 AM
      final today = DateTime(2026, 10, 1);

      final buses = [
        const Bus(
          id: 'bus_far_upcoming',
          routeId: 'route_138',
          routeNo: '138',
          hasRamp: true,
          lowFloor: true,
          rampOk: true,
          occupancy: 'low',
          scheduledDeparture: '02:00 PM',
          stops: ['st_pettah', 'st_homagama'],
        ),
        const Bus(
          id: 'bus_near_upcoming',
          routeId: 'route_138',
          routeNo: '138',
          hasRamp: true,
          lowFloor: true,
          rampOk: true,
          occupancy: 'low',
          scheduledDeparture: '09:30 AM',
          stops: ['st_pettah', 'st_homagama'],
        ),
        const Bus(
          id: 'bus_departed',
          routeId: 'route_138',
          routeNo: '138',
          hasRamp: true,
          lowFloor: true,
          rampOk: true,
          occupancy: 'low',
          scheduledDeparture: '06:30 AM',
          stops: ['st_pettah', 'st_homagama'],
        ),
      ];

      Bus? bestUpcoming;
      Duration bestDelta = const Duration(days: 2);

      for (final bus in buses) {
        final depTime = TimeUtils.parseTimeStringToDateTime(
          bus.effectiveDepartureTime,
          today,
        );
        final delta = depTime.difference(now);
        if (delta.inMinutes >= -15 && delta < bestDelta) {
          bestDelta = delta;
          bestUpcoming = bus;
        }
      }

      expect(bestUpcoming?.id, equals('bus_near_upcoming'));
    });

    test('5. Seed sampleBuses contain multi-run schedules for routes', () {
      final route138Buses =
          SeedData.sampleBuses.where((b) => b.routeNo == '138').toList();

      expect(route138Buses.length, greaterThanOrEqualTo(5));
      final depTimes =
          route138Buses.map((b) => b.effectiveDepartureTime).toList();
      expect(depTimes, contains('06:30 AM'));
      expect(depTimes, contains('08:00 AM'));
    });
  });
}
