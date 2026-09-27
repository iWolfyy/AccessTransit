import 'package:access_transit/logic/status_logic.dart';
import 'package:access_transit/models/boarding_request.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart'
    show AccessibilityStatus;
import 'package:access_transit/services/firestore_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sprint 3: Driver Side Unit & Integration Tests (AC-84, AC-85, AC-86)', () {
    late FirestoreService firestoreService;

    setUp(() {
      firestoreService = FirestoreService();
    });

    test('TASK 1 (AC-84): Bus model supports driverId and assignment', () {
      const bus = Bus(
        id: 'bus_test_1',
        routeNo: '138',
        stops: ['st_fort', 'st_pettah'],
        hasRamp: true,
        lowFloor: true,
        rampOk: true,
        occupancy: 'low',
        driverId: 'driver_operator_1',
      );

      expect(bus.driverId, equals('driver_operator_1'));

      final map = bus.toMap();
      expect(map['driverId'], equals('driver_operator_1'));

      final recreated = Bus.fromMap(map, id: 'bus_test_1');
      expect(recreated.driverId, equals('driver_operator_1'));
      expect(recreated, equals(bus));
    });

    test(
        'TASK 2 (AC-85): End-to-end driver ramp status toggle updates rider status (Safe -> Warning -> Safe)',
        () async {
      const busId = 'bus_138_outbound';

      // 1. Initial State: Bus ramp is OK
      await firestoreService.updateBusAccessibility(
        busId,
        rampOk: true,
        occupancy: 'low',
        driverId: 'op_dev',
      );

      var bus = await firestoreService.getBusById(busId);
      expect(bus, isNotNull);
      expect(bus!.rampOk, isTrue);

      var status = StatusLogic.getBusStatus(bus, []);
      expect(status.status, equals(AccessibilityStatus.accessible));
      expect(status.statusLabel, equals('Safe'));

      // 2. Operator flips rampOk to false on Dashboard -> status becomes Warning
      await firestoreService.updateBusAccessibility(busId, rampOk: false);

      bus = await firestoreService.getBusById(busId);
      expect(bus!.rampOk, isFalse);

      status = StatusLogic.getBusStatus(bus, []);
      expect(status.status, equals(AccessibilityStatus.partial));
      expect(status.statusLabel, equals('Warning'));
      expect(
        status.reasons.any((r) => r.contains('Ramp reported broken')),
        isTrue,
        reason: 'Should cite Ramp reported broken as requested in AC-85',
      );

      // 3. Operator flips rampOk back to true -> status returns to Safe
      await firestoreService.updateBusAccessibility(busId, rampOk: true);

      bus = await firestoreService.getBusById(busId);
      expect(bus!.rampOk, isTrue);

      status = StatusLogic.getBusStatus(bus, []);
      expect(status.status, equals(AccessibilityStatus.accessible));
      expect(status.statusLabel, equals('Safe'));
    });

    test(
        'TASK 2 (AC-85): Occupancy update does not alter accessibility badge status',
        () async {
      const busId = 'bus_138_outbound';

      // Safe bus with low occupancy
      await firestoreService.updateBusAccessibility(
        busId,
        rampOk: true,
        occupancy: 'low',
      );
      var bus = await firestoreService.getBusById(busId);
      var status = StatusLogic.getBusStatus(bus!, []);
      expect(status.status, equals(AccessibilityStatus.accessible));
      expect(status.statusLabel, equals('Safe'));

      // Change occupancy to high
      await firestoreService.updateBusAccessibility(
        busId,
        occupancy: 'high',
      );
      bus = await firestoreService.getBusById(busId);
      expect(bus!.occupancy, equals('high'));

      // Badge status must remain Safe (informational only)
      status = StatusLogic.getBusStatus(bus, []);
      expect(status.status, equals(AccessibilityStatus.accessible));
      expect(status.statusLabel, equals('Safe'));
    });

    test(
        'TASK 3 (AC-86): Boarding assistance requests lifecycle (submit -> stream -> acknowledge -> complete)',
        () async {
      const busId = 'bus_138_outbound';
      final requestTime = DateTime.now();

      final request = BoardingRequest(
        id: 'req_test_1',
        riderId: 'rider_123',
        riderName: 'Jane Doe',
        busId: busId,
        routeNo: '138',
        stationId: 'st_fort',
        stopName: 'Colombo Fort Station',
        assistanceTypes: const ['Deploy Ramp', 'Boarding Help'],
        status: 'pending',
        createdAt: requestTime,
      );

      // 1. Submit boarding request
      await firestoreService.createBoardingRequest(request);

      // 2. Stream requests for bus
      final requestsList =
          await firestoreService.streamBoardingRequestsForBus(busId).first;
      expect(requestsList.any((r) => r.id == 'req_test_1'), isTrue);

      final found = requestsList.firstWhere((r) => r.id == 'req_test_1');
      expect(found.riderName, equals('Jane Doe'));
      expect(found.stopName, equals('Colombo Fort Station'));
      expect(found.assistanceTypes, containsAll(['Deploy Ramp', 'Boarding Help']));
      expect(found.status, equals('pending'));

      // 3. Operator marks request as Acknowledged
      await firestoreService.updateBoardingRequestStatus(
        'req_test_1',
        'acknowledged',
      );

      final acknowledgedList =
          await firestoreService.streamBoardingRequestsForBus(busId).first;
      final acknowledged =
          acknowledgedList.firstWhere((r) => r.id == 'req_test_1');
      expect(acknowledged.status, equals('acknowledged'));

      // 4. Operator marks request as Completed
      await firestoreService.updateBoardingRequestStatus(
        'req_test_1',
        'completed',
      );

      final completedList =
          await firestoreService.streamBoardingRequestsForBus(busId).first;
      final completed = completedList.firstWhere((r) => r.id == 'req_test_1');
      expect(completed.status, equals('completed'));
    });
  });
}
