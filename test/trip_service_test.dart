import 'package:access_transit/models/trip_model.dart';
import 'package:access_transit/services/eta_service.dart';
import 'package:access_transit/services/trip_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TripService & Per-Stop Timeline Unit Tests', () {
    late TripService tripService;

    setUp(() {
      tripService = TripService();
    });

    test('1. Trip creation computes initial estimated arrivals for ordered stops', () async {
      const busId = 'bus_138_test';
      const routeNo = '138';
      final stops = ['st_pettah', 'st_maradana', 'st_borella', 'st_kottawa'];
      final startTime = DateTime(2026, 9, 30, 14, 0, 0);

      final trip = await tripService.startTrip(
        busId: busId,
        routeNo: routeNo,
        stops: stops,
        driverId: 'driver_unit_test',
        departureTime: startTime,
      );

      expect(trip.busId, equals(busId));
      expect(trip.status, equals('in_progress'));
      expect(trip.actualDepartureTime, equals(startTime));
      expect(trip.currentStopIndex, equals(0));
      expect(trip.stops, equals(stops));

      // Check stopTimes map computed by EtaService
      expect(trip.stopTimes.length, equals(4));
      expect(trip.stopTimes.containsKey('st_pettah'), isTrue);
      expect(trip.stopTimes['st_pettah']!.estimatedArrival, equals(startTime));

      // Subsequent stops should have estimated arrival times strictly after startTime
      final maradanaEst = trip.stopTimes['st_maradana']!.estimatedArrival;
      final borellaEst = trip.stopTimes['st_borella']!.estimatedArrival;
      final kottawaEst = trip.stopTimes['st_kottawa']!.estimatedArrival;

      expect(maradanaEst.isAfter(startTime), isTrue);
      expect(borellaEst.isAfter(maradanaEst), isTrue);
      expect(kottawaEst.isAfter(borellaEst), isTrue);
    });

    test('2. Arrival confirmation advances currentStopIndex and updates stopTimes', () async {
      const busId = 'bus_100_test';
      const routeNo = '100';
      final stops = ['st_pettah', 'st_fort', 'st_kollupitiya', 'st_mt_lavinia'];
      final startTime = DateTime(2026, 9, 30, 10, 0, 0);

      // Start trip at T+0
      await tripService.startTrip(
        busId: busId,
        routeNo: routeNo,
        stops: stops,
        driverId: 'driver_unit_test',
        departureTime: startTime,
      );

      // Confirm arrival at stop 1 (st_fort) at T+6 minutes
      final fortArrivalTime = startTime.add(const Duration(minutes: 6));
      final updatedTrip = await tripService.confirmNextStopArrival(
        busId,
        arrivalTime: fortArrivalTime,
      );

      expect(updatedTrip, isNotNull);
      expect(updatedTrip!.currentStopIndex, equals(1));

      final fortTiming = updatedTrip.stopTimes['st_fort'];
      expect(fortTiming, isNotNull);
      expect(fortTiming!.actualArrival, equals(fortArrivalTime));

      // Downstream estimated arrivals for kollupitiya and mt_lavinia should be reprojected
      final kollupitiyaEst = updatedTrip.stopTimes['st_kollupitiya']!.estimatedArrival;
      expect(kollupitiyaEst.isAfter(fortArrivalTime), isTrue);
    });

    test('3. Bus with no active trip returns null / not_started state', () async {
      const inactiveBusId = 'bus_inactive_999';

      final activeTrip = await tripService.getActiveTrip(inactiveBusId);
      expect(activeTrip, isNull);

      final streamResult = await tripService.watchActiveTripForBus(inactiveBusId).first;
      expect(streamResult, isNull);
    });

    test('4. Completing trip sets status to completed', () async {
      const busId = 'bus_complete_test';
      final stops = ['st_pettah', 'st_fort'];

      await tripService.startTrip(
        busId: busId,
        routeNo: '100',
        stops: stops,
        driverId: 'driver_unit_test',
      );

      final completed = await tripService.completeTrip(busId);
      expect(completed, isNotNull);
      expect(completed!.status, equals('completed'));

      final activeAfterComplete = await tripService.getActiveTrip(busId);
      expect(activeAfterComplete, isNull);
    });

    test('5. Trip creation using seeded scheduleTimes initializes exact scheduled arrival times', () async {
      const busId = 'bus_scheduled_test';
      final stops = ['st_pettah', 'st_maradana'];
      final scheduleTimes = ['08:00 AM', '08:15 AM'];
      final baseDate = DateTime(2026, 9, 30, 8, 0, 0);

      final trip = await tripService.startTrip(
        busId: busId,
        routeNo: '138',
        stops: stops,
        driverId: 'driver_unit_test',
        scheduleTimes: scheduleTimes,
        departureTime: baseDate,
      );

      expect(trip.stopTimes['st_pettah']!.estimatedArrival, equals(baseDate));
      expect(
        trip.stopTimes['st_maradana']!.estimatedArrival,
        equals(DateTime(2026, 9, 30, 8, 15, 0)),
      );
    });
  });
}
