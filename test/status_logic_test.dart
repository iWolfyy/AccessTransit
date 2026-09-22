import 'package:access_transit/logic/status_logic.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/models/station.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart' show AccessibilityStatus;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StatusLogic Unit Tests (AC-74)', () {
    final now = DateTime.now();

    const stationFort = Station(
      id: 'st_fort',
      name: 'Colombo Fort Station',
      hasElevator: true,
      hasRamp: true,
      lat: 6.9333,
      lng: 79.8500,
    );

    final stationsMap = {'st_fort': stationFort};

    const safeBus = Bus(
      id: 'bus_safe',
      routeNo: '138',
      stops: ['st_fort', 'st_pettah'],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
    );

    const brokenRampBus = Bus(
      id: 'bus_broken_ramp',
      routeNo: '101',
      stops: ['st_fort', 'st_pettah'],
      hasRamp: true,
      lowFloor: true,
      rampOk: false,
      occupancy: 'high',
    );

    const nonAccessibleBus = Bus(
      id: 'bus_non_acc',
      routeNo: '120',
      stops: ['st_fort', 'st_pettah'],
      hasRamp: false,
      lowFloor: false,
      rampOk: false,
      occupancy: 'medium',
    );

    test('isReportActive returns true for active reports within 12 hours', () {
      final freshReport = Report(
        id: 'r1',
        targetType: 'station',
        targetId: 'st_fort',
        problemType: 'Elevator jammed',
        status: 'active',
        createdAt: now.subtract(const Duration(hours: 4)),
        userId: 'user_1',
      );

      expect(StatusLogic.isReportActive(freshReport, currentTime: now), isTrue);
    });

    test('isReportActive returns false for reports older than 12 hours (expiry check)', () {
      final expiredReport = Report(
        id: 'r2',
        targetType: 'station',
        targetId: 'st_fort',
        problemType: 'Elevator jammed',
        status: 'active',
        createdAt: now.subtract(const Duration(hours: 14)),
        userId: 'user_1',
      );

      expect(StatusLogic.isReportActive(expiredReport, currentTime: now), isFalse);
    });

    test('isReportActive returns false for resolved reports', () {
      final resolvedReport = Report(
        id: 'r3',
        targetType: 'station',
        targetId: 'st_fort',
        problemType: 'Elevator jammed',
        status: 'resolved',
        createdAt: now.subtract(const Duration(hours: 1)),
        userId: 'user_1',
      );

      expect(StatusLogic.isReportActive(resolvedReport, currentTime: now), isFalse);
    });

    test('getBusStatus evaluates Not Accessible branch when no ramp and no low floor', () {
      final result = StatusLogic.getBusStatus(
        nonAccessibleBus,
        [],
        currentTime: now,
      );

      expect(result.status, equals(AccessibilityStatus.notAccessible));
      expect(result.statusLabel, equals('Not accessible'));
      expect(result.reasons.first, contains('No ramp and no low-floor access'));
    });

    test('getBusStatus evaluates Warning branch when rampOk is false', () {
      final result = StatusLogic.getBusStatus(
        brokenRampBus,
        [],
        currentTime: now,
      );

      expect(result.status, equals(AccessibilityStatus.partial));
      expect(result.statusLabel, equals('Warning'));
      expect(result.reasons.first, contains('Vehicle wheelchair ramp is reported out of service'));
    });

    test('getBusStatus evaluates Warning branch when active report exists on a stop station', () {
      final activeStationReport = Report(
        id: 'r_st',
        targetType: 'station',
        targetId: 'st_fort',
        problemType: 'Elevator power failure',
        status: 'active',
        createdAt: now.subtract(const Duration(hours: 2)),
        userId: 'user_2',
      );

      final result = StatusLogic.getBusStatus(
        safeBus,
        [activeStationReport],
        stationsMap: stationsMap,
        currentTime: now,
      );

      expect(result.status, equals(AccessibilityStatus.partial));
      expect(result.statusLabel, equals('Warning'));
      expect(result.reasons.any((r) => r.contains('Colombo Fort Station')), isTrue);
    });

    test('getBusStatus evaluates Safe branch when bus is accessible and no active reports exist', () {
      final result = StatusLogic.getBusStatus(
        safeBus,
        [],
        currentTime: now,
      );

      expect(result.status, equals(AccessibilityStatus.accessible));
      expect(result.statusLabel, equals('Safe'));
      expect(result.reasons.first, contains('Step-free boarding'));
    });
  });
}
