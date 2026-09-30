import 'package:flutter_test/flutter_test.dart';
import 'package:access_transit/models/bus_location_model.dart';
import 'package:access_transit/models/enums/bus_status.dart';
import 'package:access_transit/services/live_bus_service.dart';
import 'package:access_transit/services/trip_service.dart';

void main() {
  group('Driver Side Step 3: Next Stop Flow Sync with Live Telemetry', () {
    late LiveBusService liveBusService;
    late TripService tripService;

    const busId = 'bus_test_sync_138';
    final testStops = ['st_pettah', 'st_maradana', 'st_borella', 'st_kottawa'];

    setUp(() {
      liveBusService = LiveBusService();
      tripService = TripService();
    });

    test('1. LiveBusService.updateNextStop updates nextStop, currentStopIndex, and etaMinutes', () async {
      await liveBusService.startOrUpdateLiveLocation(
        BusLocationModel(
          busId: busId,
          routeId: 'route_138',
          latitude: 6.9344,
          longitude: 79.8530,
          status: BusStatus.active,
          nextStop: 'st_maradana',
          currentStopIndex: 0,
          etaMinutes: 10,
        ),
      );

      var location = await liveBusService.getLiveLocation(busId);
      expect(location, isNotNull);
      expect(location!.nextStop, equals('st_maradana'));
      expect(location.currentStopIndex, equals(0));
      expect(location.etaMinutes, equals(10));

      await liveBusService.updateNextStop(
        busId: busId,
        nextStop: 'st_borella',
        currentStopIndex: 1,
        etaMinutes: 6,
      );

      location = await liveBusService.getLiveLocation(busId);
      expect(location, isNotNull);
      expect(location!.nextStop, equals('st_borella'));
      expect(location.currentStopIndex, equals(1));
      expect(location.etaMinutes, equals(6));
    });

    test('2. TripService.confirmNextStopArrival advances trip and auto-syncs LiveBusService', () async {
      await tripService.startTrip(
        busId: busId,
        routeNo: '138',
        stops: testStops,
        driverId: 'driver_test',
        departureTime: DateTime.now(),
      );

      // Confirm arrival at stop 1 (st_maradana)
      final updatedTrip = await tripService.confirmNextStopArrival(busId);
      expect(updatedTrip, isNotNull);
      expect(updatedTrip!.currentStopIndex, equals(1));

      // Verify that LiveBusService received the synchronized upcoming stop (st_borella)
      final liveLocation = await liveBusService.getLiveLocation(busId);
      expect(liveLocation, isNotNull);
      expect(liveLocation!.currentStopIndex, equals(1));
      expect(liveLocation.nextStop, equals('st_borella'));
    });

    test('3. Passenger live location stream immediately emits new nextStop upon confirmation', () async {
      final emittedStops = <String>[];

      final sub = liveBusService.listenToLiveLocation(busId).listen((loc) {
        if (loc != null) {
          emittedStops.add(loc.nextStop);
        }
      });

      // Confirm arrival at stop 2 (st_borella) -> upcoming stop is st_kottawa
      await tripService.confirmNextStopArrival(busId);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(emittedStops, contains('st_kottawa'));
    });

    test('4. Reaching and completing final stop sets status to completed and stops broadcasting', () async {
      // Advance to final destination stop (st_kottawa, index 3)
      final finalArrival = await tripService.confirmNextStopArrival(busId);
      expect(finalArrival, isNotNull);
      expect(finalArrival!.currentStopIndex, equals(3));
      expect(finalArrival.stops[finalArrival.currentStopIndex], equals('st_kottawa'));

      // Confirm final stop departure -> completes trip
      final completedTrip = await tripService.confirmNextStopArrival(busId);
      expect(completedTrip, isNotNull);
      expect(completedTrip!.status, equals('completed'));

      final finalLocation = await liveBusService.getLiveLocation(busId);
      expect(finalLocation, isNotNull);
      expect(finalLocation!.isBroadcasting, isFalse);
    });
  });
}
