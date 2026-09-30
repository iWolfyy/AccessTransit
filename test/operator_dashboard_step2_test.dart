import 'package:flutter_test/flutter_test.dart';
import 'package:access_transit/data/seed_data.dart';
import 'package:access_transit/logic/delay_eta_logic.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/trip_model.dart';

void main() {
  group('Driver Side Step 2: Punctuality & Schedule Comparison (Delay Meter)', () {
    const testBus = Bus(
      id: 'bus_test_138',
      routeId: 'route_138_pettah_homagama',
      routeNo: '138',
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
      scheduledDeparture: '08:00 AM',
      stops: [
        'st_pettah',
        'st_maradana',
        'st_borella',
        'st_kirulapone',
      ],
      scheduleTimes: [
        '08:00 AM',
        '08:12 AM',
        '08:25 AM',
        '08:38 AM',
      ],
    );

    final stationsMap = {for (final s in SeedData.colomboStations) s.id: s};

    test('1. Punctuality status badge classifies within ±1 min as On Time', () {
      expect(DelayEtaCalculator.getDelayType(0), equals(DelayType.onTime));
      expect(DelayEtaCalculator.getDelayType(1), equals(DelayType.onTime));
      expect(DelayEtaCalculator.getDelayType(-1), equals(DelayType.onTime));
    });

    test('2. Punctuality status badge classifies > 1 min late as Delayed', () {
      expect(DelayEtaCalculator.getDelayType(2), equals(DelayType.delayed));
      expect(DelayEtaCalculator.getDelayType(10), equals(DelayType.delayed));
      expect(
        DelayEtaCalculator.formatDelayLabel(4),
        equals('Delayed by 4 mins'),
      );
    });

    test('3. Punctuality status badge classifies < -1 min as Running Early', () {
      expect(DelayEtaCalculator.getDelayType(-2), equals(DelayType.early));
      expect(DelayEtaCalculator.getDelayType(-5), equals(DelayType.early));
      expect(
        DelayEtaCalculator.formatDelayLabel(-3),
        equals('Running 3 mins early'),
      );
    });

    test('4. Computes accurate next-stop schedule vs ETA with active trip', () {
      final now = DateTime(2026, 10, 1, 8, 10); // 8:10 AM

      // Active trip moving towards st_maradana (stop index 1, scheduled 08:12 AM)
      final trip = TripModel(
        tripId: 'trip_test_01',
        busId: testBus.id,
        routeNo: testBus.routeNo,
        driverId: 'driver_01',
        status: 'in_progress',
        currentStopIndex: 0, // at Pettah, heading to Maradana
        actualDepartureTime: DateTime(2026, 10, 1, 8, 2), // 2 min late departure
        stops: testBus.stops,
        createdAt: DateTime(2026, 10, 1, 7, 55),
        stopTimes: {
          'st_pettah': StopTimingInfo(
            estimatedArrival: DateTime(2026, 10, 1, 8, 2),
            actualArrival: DateTime(2026, 10, 1, 8, 2),
          ),
          'st_maradana': StopTimingInfo(
            estimatedArrival: DateTime(2026, 10, 1, 8, 15), // +3 mins delay
          ),
        },
      );

      final nextStopEta = DelayEtaCalculator.calculateArrivalEta(
        bus: testBus,
        targetStopIdOrName: 'st_maradana',
        activeTrip: trip,
        stationsMap: stationsMap,
        currentTime: now,
      );

      expect(nextStopEta.targetStopId, equals('st_maradana'));
      expect(nextStopEta.scheduledArrivalStr, equals('08:12 AM'));
      expect(nextStopEta.delayMinutes, equals(3));
      expect(nextStopEta.delayType, equals(DelayType.delayed));
      expect(nextStopEta.delayLabel, equals('Delayed by 3 mins'));
      expect(nextStopEta.countdownMinutes, equals(5)); // 8:10 to 8:15
    });

    test('5. Reaching on-time next stop updates punctuality to On Time', () {
      final now = DateTime(2026, 10, 1, 8, 20);

      // Bus made up time and is estimated to arrive at st_borella on schedule
      final tripOnTime = TripModel(
        tripId: 'trip_test_02',
        busId: testBus.id,
        routeNo: testBus.routeNo,
        driverId: 'driver_01',
        status: 'in_progress',
        currentStopIndex: 1, // left Maradana, heading to Borella (08:25 AM)
        stops: testBus.stops,
        createdAt: DateTime(2026, 10, 1, 7, 55),
        stopTimes: {
          'st_borella': StopTimingInfo(
            estimatedArrival: DateTime(2026, 10, 1, 8, 25), // On time
          ),
        },
      );

      final result = DelayEtaCalculator.calculateArrivalEta(
        bus: testBus,
        targetStopIdOrName: 'st_borella',
        activeTrip: tripOnTime,
        stationsMap: stationsMap,
        currentTime: now,
      );

      expect(result.delayMinutes, equals(0));
      expect(result.delayType, equals(DelayType.onTime));
      expect(result.delayLabel, equals('On Time'));
      expect(result.scheduledArrivalStr, equals('08:25 AM'));
      expect(result.estimatedArrivalStr, equals('08:25 AM'));
    });
  });
}
