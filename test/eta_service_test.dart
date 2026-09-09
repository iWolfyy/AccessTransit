import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:access_transit/models/bus_location_model.dart';
import 'package:access_transit/models/enums/bus_status.dart';
import 'package:access_transit/services/eta_service.dart';

void main() {
  group('EtaService Unit Tests', () {
    final etaService = EtaService();

    test('returns unreliable when liveBus is null', () {
      final result = etaService.calculateEta(
        liveBus: null,
        stopName: 'Central Station',
      );

      expect(result.isReliable, isFalse);
      expect(result.etaMinutes, isNull);
      expect(result.displayText, contains('ETA Unavailable'));
    });

    test('returns unreliable when bus is stale or offline', () {
      final bus = BusLocationModel(
        busId: 'bus_42',
        latitude: 6.9271,
        longitude: 79.8612,
        status: BusStatus.offline,
        isBroadcasting: false,
      );

      final result = etaService.calculateEta(
        liveBus: bus,
        stopName: 'Central Station',
        isStale: true,
      );

      expect(result.isReliable, isFalse);
      expect(result.etaMinutes, isNull);
      expect(result.displayText, contains('ETA Unavailable'));
    });

    test('returns unreliable when stop location cannot be resolved', () {
      final bus = BusLocationModel(
        busId: 'bus_42',
        latitude: 6.9271,
        longitude: 79.8612,
        status: BusStatus.active,
        nextStop: 'Unknown Stop X',
        isBroadcasting: true,
      );

      final result = etaService.calculateEta(
        liveBus: bus,
        stopName: 'Unknown Nonexistent Stop 999',
      );

      expect(result.isReliable, isFalse);
      expect(result.etaMinutes, isNull);
      expect(result.displayText, contains('ETA Unavailable'));
    });

    test('returns Arriving now when bus is within 50m of target stop', () {
      // Central Station is (6.9271, 79.8612)
      final bus = BusLocationModel(
        busId: 'bus_42',
        latitude: 6.92712,
        longitude: 79.86122,
        status: BusStatus.active,
        speed: 15.0,
        isBroadcasting: true,
      );

      final result = etaService.calculateEta(
        liveBus: bus,
        stopName: 'Central Station',
      );

      expect(result.isReliable, isTrue);
      expect(result.etaMinutes, equals(0));
      expect(result.displayText, equals('Bus arriving now'));
    });

    test('calculates accurate ETA minutes based on speed and distance', () {
      // Target: Custom location (6.9500, 79.8612)
      // Bus: (6.9000, 79.8612) -> ~5.5 km distance
      // Speed: 33 km/h -> ~10 min ETA
      final bus = BusLocationModel(
        busId: 'bus_42',
        latitude: 6.9000,
        longitude: 79.8612,
        status: BusStatus.active,
        speed: 33.0,
        isBroadcasting: true,
      );

      final target = const LatLng(6.9500, 79.8612);

      final result = etaService.calculateEta(
        liveBus: bus,
        stopName: 'Custom Stop',
        customStopLocation: target,
      );

      expect(result.isReliable, isTrue);
      expect(result.etaMinutes, equals(10));
      expect(
        result.displayText,
        equals('Bus arriving in approximately 10 minutes'),
      );
    });

    test('uses urban transit fallback speed (20 km/h) when bus speed is 0', () {
      // Target: Custom location (6.9360, 79.8612)
      // Bus: (6.9000, 79.8612) -> ~4 km distance
      // Speed: 0 km/h (stopped) -> Uses 20 km/h -> 12 min ETA
      final bus = BusLocationModel(
        busId: 'bus_42',
        latitude: 6.9000,
        longitude: 79.8612,
        status: BusStatus.stopped,
        speed: 0.0,
        isBroadcasting: true,
      );

      final target = const LatLng(6.9360, 79.8612);

      final result = etaService.calculateEta(
        liveBus: bus,
        stopName: 'Custom Stop',
        customStopLocation: target,
      );

      expect(result.isReliable, isTrue);
      expect(result.etaMinutes, equals(12));
      expect(
        result.displayText,
        equals('Bus arriving in approximately 12 minutes'),
      );
    });
  });
}
