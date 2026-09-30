import 'package:flutter_test/flutter_test.dart';
import 'package:access_transit/logic/delay_eta_logic.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/bus_location_model.dart';
import 'package:access_transit/models/enums/bus_status.dart';
import 'package:access_transit/services/live_bus_service.dart';

void main() {
  group('Driver Side Step 4: Quick Delay & Traffic Reason Reporting', () {
    late LiveBusService liveBusService;
    const busId = 'bus_test_delay_reporting_138';

    const testBus = Bus(
      id: busId,
      routeId: 'route_138_pettah_homagama',
      routeNo: '138',
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
      scheduledDeparture: '08:00 AM',
      stops: ['st_pettah', 'st_maradana', 'st_borella'],
      scheduleTimes: ['08:00 AM', '08:15 AM', '08:30 AM'],
    );

    setUp(() {
      liveBusService = LiveBusService();
    });

    test('1. LiveBusService.reportDelay stores delayReason and addedDelayMinutes', () async {
      await liveBusService.startOrUpdateLiveLocation(
        BusLocationModel(
          busId: busId,
          routeId: 'route_138',
          latitude: 6.9344,
          longitude: 79.8530,
          status: BusStatus.active,
          nextStop: 'st_maradana',
          currentStopIndex: 0,
          etaMinutes: 5,
        ),
      );

      // Driver reports a 10 min traffic delay
      await liveBusService.reportDelay(
        busId: busId,
        reason: 'Traffic Congestion',
        delayMinutes: 10,
      );

      final loc = await liveBusService.getLiveLocation(busId);
      expect(loc, isNotNull);
      expect(loc!.delayReason, equals('Traffic Congestion'));
      expect(loc.addedDelayMinutes, equals(10));
    });

    test('2. DelayEtaCalculator incorporates driver delayReason and addedDelayMinutes into ETA', () {
      final now = DateTime(2026, 10, 1, 8, 10);

      final liveLocationWithDelay = BusLocationModel(
        busId: busId,
        routeId: 'route_138',
        latitude: 6.9344,
        longitude: 79.8530,
        status: BusStatus.active,
        nextStop: 'st_maradana',
        currentStopIndex: 0,
        etaMinutes: 5, // baseline 5 mins
        delayReason: 'Heavy Rain / Flooding',
        addedDelayMinutes: 8, // +8 mins added
      );

      final result = DelayEtaCalculator.calculateArrivalEta(
        bus: testBus,
        targetStopIdOrName: 'st_maradana',
        liveBusLocation: liveLocationWithDelay,
        currentTime: now,
      );

      expect(result.delayReason, equals('Heavy Rain / Flooding'));
      expect(result.addedDelayMinutes, equals(8));
      // Baseline countdown is 5 mins, + 8 mins delay = 13 mins countdown
      expect(result.countdownMinutes, equals(13));
      expect(result.delayType, equals(DelayType.delayed));
      expect(result.delayLabel, contains('Heavy Rain / Flooding'));
    });

    test('3. LiveBusService.clearDelay resets delayReason to null and addedDelayMinutes to 0', () async {
      await liveBusService.clearDelay(busId);

      final loc = await liveBusService.getLiveLocation(busId);
      expect(loc, isNotNull);
      expect(loc!.delayReason, isNull);
      expect(loc.addedDelayMinutes, equals(0));
    });

    test('4. Passenger live stream receives real-time delay broadcast', () async {
      final reasons = <String?>[];

      final sub = liveBusService.listenToLiveLocation(busId).listen((loc) {
        if (loc != null) {
          reasons.add(loc.delayReason);
        }
      });

      await liveBusService.reportDelay(
        busId: busId,
        reason: 'Accident Ahead',
        delayMinutes: 15,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(reasons, contains('Accident Ahead'));
    });
  });
}
