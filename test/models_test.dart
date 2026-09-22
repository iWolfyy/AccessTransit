import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/models/station.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Station Model Tests', () {
    test('Station.fromMap and toMap roundtrip conversion', () {
      final stationMap = {
        'name': 'Colombo Fort Station',
        'hasElevator': true,
        'hasRamp': true,
        'lat': 6.9333,
        'lng': 79.8500,
      };

      final station = Station.fromMap(stationMap, id: 'st_fort');

      expect(station.id, equals('st_fort'));
      expect(station.name, equals('Colombo Fort Station'));
      expect(station.hasElevator, isTrue);
      expect(station.hasRamp, isTrue);
      expect(station.lat, equals(6.9333));
      expect(station.lng, equals(79.8500));

      final outputMap = station.toMap();
      expect(outputMap['name'], equals('Colombo Fort Station'));
      expect(outputMap['hasElevator'], isTrue);
      expect(outputMap['hasRamp'], isTrue);
      expect(outputMap['lat'], equals(6.9333));
      expect(outputMap['lng'], equals(79.8500));
    });

    test('Station fallback defaults for missing fields', () {
      final station = Station.fromMap({}, id: 'st_empty');

      expect(station.id, equals('st_empty'));
      expect(station.name, equals(''));
      expect(station.hasElevator, isFalse);
      expect(station.hasRamp, isFalse);
      expect(station.lat, equals(0.0));
      expect(station.lng, equals(0.0));
    });
  });

  group('Bus Model Tests', () {
    test('Bus.fromMap and toMap roundtrip conversion', () {
      final busMap = {
        'routeNo': '138',
        'stops': ['st_pettah', 'st_maradana', 'st_borella', 'st_nugegoda'],
        'hasRamp': true,
        'lowFloor': true,
        'rampOk': true,
        'occupancy': 'low',
      };

      final bus = Bus.fromMap(busMap, id: 'bus_138_outbound');

      expect(bus.id, equals('bus_138_outbound'));
      expect(bus.routeNo, equals('138'));
      expect(bus.stops.length, equals(4));
      expect(bus.stops[0], equals('st_pettah'));
      expect(bus.stops[3], equals('st_nugegoda'));
      expect(bus.hasRamp, isTrue);
      expect(bus.lowFloor, isTrue);
      expect(bus.rampOk, isTrue);
      expect(bus.occupancy, equals('low'));

      final outputMap = bus.toMap();
      expect(outputMap['routeNo'], equals('138'));
      expect(outputMap['stops'], equals(['st_pettah', 'st_maradana', 'st_borella', 'st_nugegoda']));
      expect(outputMap['hasRamp'], isTrue);
      expect(outputMap['lowFloor'], isTrue);
      expect(outputMap['rampOk'], isTrue);
      expect(outputMap['occupancy'], equals('low'));
    });

    test('Bus directional stop order preservation', () {
      final outboundMap = {
        'routeNo': '138',
        'stops': ['st_pettah', 'st_kottawa'],
        'hasRamp': true,
        'lowFloor': true,
        'rampOk': true,
        'occupancy': 'medium',
      };
      final inboundMap = {
        'routeNo': '138',
        'stops': ['st_kottawa', 'st_pettah'],
        'hasRamp': true,
        'lowFloor': true,
        'rampOk': true,
        'occupancy': 'medium',
      };

      final outboundBus = Bus.fromMap(outboundMap, id: 'bus_138_outbound');
      final inboundBus = Bus.fromMap(inboundMap, id: 'bus_138_inbound');

      expect(outboundBus.stops.first, equals('st_pettah'));
      expect(inboundBus.stops.first, equals('st_kottawa'));
      expect(outboundBus.stops, isNot(equals(inboundBus.stops)));
    });
  });

  group('Report Model Tests', () {
    test('Report.fromMap and toMap roundtrip conversion', () {
      final now = DateTime.now();
      final reportMap = {
        'targetType': 'station',
        'targetId': 'st_fort',
        'problemType': 'Elevator out of service',
        'status': 'active',
        'createdAt': now.toIso8601String(),
        'lastConfirmedAt': null,
        'confirmCount': 3,
        'falseCount': 0,
        'userId': 'usr_123',
        'confirmedBy': ['usr_123', 'usr_456'],
        'flaggedBy': [],
      };

      final report = Report.fromMap(reportMap, id: 'report_001');

      expect(report.id, equals('report_001'));
      expect(report.targetType, equals('station'));
      expect(report.targetId, equals('st_fort'));
      expect(report.problemType, equals('Elevator out of service'));
      expect(report.status, equals('active'));
      expect(report.confirmCount, equals(3));
      expect(report.falseCount, equals(0));
      expect(report.userId, equals('usr_123'));
      expect(report.confirmedBy, equals(['usr_123', 'usr_456']));
      expect(report.flaggedBy, isEmpty);

      final outputMap = report.toMap();
      expect(outputMap['targetType'], equals('station'));
      expect(outputMap['targetId'], equals('st_fort'));
      expect(outputMap['problemType'], equals('Elevator out of service'));
      expect(outputMap['status'], equals('active'));
      expect(outputMap['userId'], equals('usr_123'));
    });
  });
}
