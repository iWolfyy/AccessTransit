import 'package:access_transit/models/bus_location_model.dart';
import 'package:access_transit/models/enums/bus_status.dart';
import 'package:access_transit/services/live_bus_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveBusService tests', () {
    late LiveBusService liveBusService;

    setUp(() {
      liveBusService = LiveBusService();
    });

    test('isLocationStale returns true for null timestamp', () {
      expect(liveBusService.isLocationStale(null), isTrue);
    });

    test('isLocationStale returns false for recent timestamp', () {
      final recentTimestamp = DateTime.now().subtract(const Duration(minutes: 1));
      expect(liveBusService.isLocationStale(recentTimestamp), isFalse);
    });

    test('isLocationStale returns true for old timestamp exceeding threshold', () {
      final oldTimestamp = DateTime.now().subtract(const Duration(minutes: 10));
      expect(
        liveBusService.isLocationStale(oldTimestamp, threshold: const Duration(minutes: 5)),
        isTrue,
      );
    });

    test('isBusStale returns true for offline bus regardless of timestamp', () {
      final busLocation = BusLocationModel(
        busId: 'BUS_101',
        latitude: 6.9271,
        longitude: 79.8612,
        status: BusStatus.offline,
        timestamp: DateTime.now(),
      );

      expect(liveBusService.isBusStale(busLocation), isTrue);
    });

    test('isBusStale returns true for completed bus trip', () {
      final busLocation = BusLocationModel(
        busId: 'BUS_102',
        latitude: 6.9271,
        longitude: 79.8612,
        status: BusStatus.completed,
        timestamp: DateTime.now(),
      );

      expect(liveBusService.isBusStale(busLocation), isTrue);
    });

    test('isBusStale returns false for active bus with recent timestamp', () {
      final busLocation = BusLocationModel(
        busId: 'BUS_103',
        latitude: 6.9271,
        longitude: 79.8612,
        status: BusStatus.active,
        timestamp: DateTime.now().subtract(const Duration(seconds: 30)),
      );

      expect(liveBusService.isBusStale(busLocation), isFalse);
    });
  });
}
