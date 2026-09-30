import 'package:access_transit/logic/bus_matcher.dart';
import 'package:access_transit/models/bus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BusMatcher Unit Tests (AC-72)', () {
    const busOutbound = Bus(
      id: 'bus_138_outbound',
      routeNo: '138',
      stops: ['st_pettah', 'st_borella', 'st_nugegoda', 'st_kottawa'],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
    );

    const busInbound = Bus(
      id: 'bus_138_inbound',
      routeNo: '138',
      stops: ['st_kottawa', 'st_nugegoda', 'st_borella', 'st_pettah'],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'medium',
    );

    const busShortRoute = Bus(
      id: 'bus_100_outbound',
      routeNo: '100',
      stops: ['st_pettah', 'st_kollupitiya', 'st_mt_lavinia'],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
    );

    final allBuses = [busOutbound, busInbound, busShortRoute];

    test('Finds direct buses when route matches in correct direction', () {
      final results = BusMatcher.findDirectBuses(
        allBuses,
        'st_pettah',
        'st_nugegoda',
      );

      expect(results.length, equals(1));
      expect(results.first.id, equals('bus_138_outbound'));
    });

    test('Excludes bus running in the opposite direction', () {
      // Searching from Kottawa to Pettah
      final results = BusMatcher.findDirectBuses(
        allBuses,
        'st_kottawa',
        'st_pettah',
      );

      expect(results.length, equals(1));
      expect(results.first.id, equals('bus_138_inbound'));
      expect(results.any((b) => b.id == 'bus_138_outbound'), isFalse);
    });

    test('Excludes bus when one or both stations are missing from stops list', () {
      final results = BusMatcher.findDirectBuses(
        allBuses,
        'st_kollupitiya',
        'st_kottawa',
      );

      expect(results, isEmpty);
    });

    test('Returns empty list when FROM and TO stations are identical (same station edge case)', () {
      final results = BusMatcher.findDirectBuses(
        allBuses,
        'st_pettah',
        'st_pettah',
      );

      expect(results, isEmpty);
    });

    test('Returns empty list when input station IDs are empty or whitespace', () {
      final results = BusMatcher.findDirectBuses(allBuses, '', 'st_kottawa');
      expect(results, isEmpty);
    });
  });
}
