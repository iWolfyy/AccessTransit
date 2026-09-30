import 'package:flutter_test/flutter_test.dart';
import 'package:access_transit/logic/delay_eta_logic.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/bus_location_model.dart';
import 'package:access_transit/models/enums/bus_status.dart';
import 'package:access_transit/models/station.dart';
import 'package:access_transit/models/trip_model.dart';

void main() {
  group('DelayEtaCalculator Unit Tests', () {
    const sampleBus = Bus(
      id: 'bus_138_nd4521',
      routeNo: '138',
      busNo: 'WP ND-4521',
      routeId: 'route_138',
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
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
    );

    final stationsMap = {
      'st_pettah': const Station(
        id: 'st_pettah',
        name: 'Pettah Central Bus Stand',
        hasElevator: false,
        hasRamp: true,
        lat: 6.9360,
        lng: 79.8527,
      ),
      'st_maradana': const Station(
        id: 'st_maradana',
        name: 'Maradana Station',
        hasElevator: true,
        hasRamp: true,
        lat: 6.9272,
        lng: 79.8648,
      ),
      'st_borella': const Station(
        id: 'st_borella',
        name: 'Borella Junction Bus Stop',
        hasElevator: false,
        hasRamp: true,
        lat: 6.9142,
        lng: 79.8778,
      ),
      'st_kirulapone': const Station(
        id: 'st_kirulapone',
        name: 'Kirulapone Market Stop',
        hasElevator: false,
        hasRamp: false,
        lat: 6.8833,
        lng: 79.8755,
      ),
    };

    final clockDate = DateTime(2026, 9, 30, 7, 50); // 07:50 AM

    test('Identifies 3 min delay when estimated arrival is 08:03 AM for 08:00 AM schedule', () {
      final trip = TripModel(
        tripId: 'trip_101',
        busId: 'bus_138_nd4521',
        routeNo: '138',
        stops: sampleBus.stops,
        status: 'in_progress',
        driverId: 'driver_1',
        createdAt: DateTime(2026, 9, 30, 7, 30),
        stopTimes: {
          'st_pettah': StopTimingInfo(
            estimatedArrival: DateTime(2026, 9, 30, 8, 3), // 08:03 AM
          ),
        },
      );

      final result = DelayEtaCalculator.calculateArrivalEta(
        bus: sampleBus,
        targetStopIdOrName: 'st_pettah',
        activeTrip: trip,
        stationsMap: stationsMap,
        currentTime: clockDate,
      );

      expect(result.scheduledArrivalStr, '08:00 AM');
      expect(result.estimatedArrivalStr, '08:03 AM');
      expect(result.delayMinutes, 3);
      expect(result.delayType, DelayType.delayed);
      expect(result.isDelayed, isTrue);
      expect(result.delayLabel, 'Delayed by 3 mins');
      expect(result.countdownMinutes, 13); // 07:50 to 08:03 = 13 mins
      expect(result.countdownText, 'Arriving in 13 mins');
    });

    test('Identifies On Time when arrival matches schedule within 1 minute', () {
      final trip = TripModel(
        tripId: 'trip_102',
        busId: 'bus_138_nd4521',
        routeNo: '138',
        stops: sampleBus.stops,
        status: 'in_progress',
        driverId: 'driver_1',
        createdAt: DateTime(2026, 9, 30, 7, 30),
        stopTimes: {
          'st_pettah': StopTimingInfo(
            estimatedArrival: DateTime(2026, 9, 30, 8, 0), // 08:00 AM exactly
          ),
        },
      );

      final result = DelayEtaCalculator.calculateArrivalEta(
        bus: sampleBus,
        targetStopIdOrName: 'st_pettah',
        activeTrip: trip,
        stationsMap: stationsMap,
        currentTime: clockDate,
      );

      expect(result.delayMinutes, 0);
      expect(result.delayType, DelayType.onTime);
      expect(result.isOnTime, isTrue);
      expect(result.delayLabel, 'On Time');
    });

    test('Identifies Early when arrival is earlier than scheduled by more than 1 min', () {
      final trip = TripModel(
        tripId: 'trip_103',
        busId: 'bus_138_nd4521',
        routeNo: '138',
        stops: sampleBus.stops,
        status: 'in_progress',
        driverId: 'driver_1',
        createdAt: DateTime(2026, 9, 30, 7, 30),
        stopTimes: {
          'st_pettah': StopTimingInfo(
            estimatedArrival: DateTime(2026, 9, 30, 7, 58), // 07:58 AM (-2 min)
          ),
        },
      );

      final result = DelayEtaCalculator.calculateArrivalEta(
        bus: sampleBus,
        targetStopIdOrName: 'st_pettah',
        activeTrip: trip,
        stationsMap: stationsMap,
        currentTime: clockDate,
      );

      expect(result.delayMinutes, -2);
      expect(result.delayType, DelayType.early);
      expect(result.delayLabel, 'Running 2 mins early');
    });

    test('Calculates arrival from live driver telemetry when active_buses is broadcasting', () {
      final liveTelemetry = BusLocationModel(
        busId: 'bus_138_nd4521',
        routeNumber: '138',
        latitude: 6.9360,
        longitude: 79.8527,
        speed: 25.0,
        isBroadcasting: true,
        status: BusStatus.active,
        nextStop: 'st_pettah',
        etaMinutes: 4,
      );

      final result = DelayEtaCalculator.calculateArrivalEta(
        bus: sampleBus,
        targetStopIdOrName: 'st_pettah',
        liveBusLocation: liveTelemetry,
        stationsMap: stationsMap,
        currentTime: DateTime(2026, 9, 30, 7, 59),
      );

      expect(result.isLive, isTrue);
      expect(result.countdownMinutes, 4);
      expect(result.countdownText, 'Arriving in 4 mins');
    });

    test('Falls back to scheduled timetable when driver is offline', () {
      final result = DelayEtaCalculator.calculateArrivalEta(
        bus: sampleBus,
        targetStopIdOrName: 'st_pettah',
        liveBusLocation: null,
        activeTrip: null,
        stationsMap: stationsMap,
        currentTime: DateTime(2026, 9, 30, 7, 45),
      );

      expect(result.isLive, isFalse);
      expect(result.delayType, DelayType.scheduled);
      expect(result.delayLabel, 'Scheduled');
      expect(result.scheduledArrivalStr, '08:00 AM');
      expect(result.countdownMinutes, 15);
      expect(result.countdownText, 'Arriving in 15 mins');
    });

    test('Builds timeline progression accurately with passed and current stops', () {
      final trip = TripModel(
        tripId: 'trip_104',
        busId: 'bus_138_nd4521',
        routeNo: '138',
        stops: sampleBus.stops,
        status: 'in_progress',
        currentStopIndex: 1, // Currently at Maradana
        driverId: 'driver_1',
        createdAt: DateTime(2026, 9, 30, 7, 30),
        stopTimes: {
          'st_pettah': StopTimingInfo(
            estimatedArrival: DateTime(2026, 9, 30, 8, 0),
            actualArrival: DateTime(2026, 9, 30, 8, 2), // Departed Pettah
          ),
          'st_maradana': StopTimingInfo(
            estimatedArrival: DateTime(2026, 9, 30, 8, 15), // Arriving Maradana
          ),
        },
      );

      final result = DelayEtaCalculator.calculateArrivalEta(
        bus: sampleBus,
        targetStopIdOrName: 'st_borella',
        activeTrip: trip,
        stationsMap: stationsMap,
        currentTime: clockDate,
      );

      expect(result.stopsTimeline.length, 4);
      // Pettah should be marked passed
      expect(result.stopsTimeline[0].isPassed, isTrue);
      // Maradana should be marked current
      expect(result.stopsTimeline[1].isCurrent, isTrue);
      // Borella is the passenger target stop
      expect(result.stopsTimeline[2].isTargetStop, isTrue);
    });
  });
}
