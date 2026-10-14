import 'dart:async';

import 'package:access_transit/models/bus_location_model.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:access_transit/services/live_bus_service.dart';
import 'package:access_transit/services/trip_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no backend cannot acknowledge operator writes', () async {
    await expectLater(
      LiveBusService().startOrUpdateLiveLocation(
        BusLocationModel(busId: 'no-backend', latitude: 7, longitude: 80),
      ),
      throwsStateError,
    );
    await expectLater(
      TripService().startTrip(
        busId: 'no-trip-backend',
        routeNo: '1',
        stops: ['a', 'b'],
        driverId: 'driver',
      ),
      throwsStateError,
    );
    expect(await TripService().getActiveTrip('no-trip-backend'), isNull);
    expect(await LiveBusService().getLiveLocation('no-backend'), isNull);
  });

  test(
    'pending GPS is local; passengers retain last acknowledgement on rejection',
    () async {
      final old = BusLocationModel(
        busId: 'gps-rejection',
        latitude: 7,
        longitude: 80,
        timestamp: DateTime(2026, 10, 14),
      );
      final receipt = Completer<BusLocationModel>();
      final driver = LiveBusService(telemetryWriter: (_, _) => receipt.future);
      driver.acceptAcknowledged(old);
      final passenger = LiveBusService();
      final pending = driver.updateLocationOnly(
        busId: old.busId,
        latitude: 8,
        longitude: 81,
      );
      final rejected = expectLater(pending, throwsStateError);
      expect((await passenger.getLiveLocation(old.busId))!.latitude, 7);
      receipt.completeError(StateError('permission denied'));
      await rejected;
      final observed = await passenger.getLiveLocation(old.busId);
      expect(observed!.latitude, 7);
      expect(observed.timestamp, old.timestamp);
    },
  );

  test('GPS retry publishes only after receipt and reaches existing passenger subscription', () async {
    final receipt = Completer<BusLocationModel>();
    final driver = LiveBusService(telemetryWriter: (_, _) => receipt.future);
    final passenger = StreamIterator(
      LiveBusService().listenToLiveLocation('gps-retry'),
    );
    await passenger.moveNext();
    expect(passenger.current, isNull);
    final next = passenger.moveNext();
    final pending = driver.startOrUpdateLiveLocation(
      BusLocationModel(busId: 'gps-retry', latitude: 8, longitude: 81),
    );
    final saved = BusLocationModel(
      busId: 'gps-retry',
      latitude: 8,
      longitude: 81,
      timestamp: DateTime(2026, 10, 14),
    );
    receipt.complete(saved);
    await pending;
    expect(await next, isTrue);
    expect(passenger.current!.timestamp, saved.timestamp);
    await passenger.cancel();
  });

  test(
    'failed condition/assignment writes preserve acknowledged bus',
    () async {
      const id = 'bus_138_nd4521';
      await FirestoreService(busWriter: (_, _) async {}).updateBusAccessibility(
        id,
        rampOk: true,
        occupancy: 'low',
        driverId: 'ack-driver',
      );
      final failed = FirestoreService(
        busWriter: (_, _) async => throw StateError('denied'),
      );
      await expectLater(
        failed.updateBusAccessibility(
          id,
          rampOk: false,
          occupancy: 'high',
          driverId: 'rejected-driver',
        ),
        throwsStateError,
      );
      final observed = await FirestoreService().getBusById(id);
      expect(observed!.rampOk, isTrue);
      expect(observed.occupancy, 'low');
      expect(observed.driverId, 'ack-driver');
    },
  );

  test('trip creation remains absent until acknowledgement and rejection leaves no phantom trip', () async {
    final receipt = Completer<void>();
    final driver = TripService(tripWriter: (_, _) => receipt.future);
    final pending = driver.startTrip(
      busId: 'trip-denied',
      routeNo: '1',
      stops: ['a', 'b'],
      driverId: 'driver',
    );
    final rejected = expectLater(pending, throwsStateError);
    expect(await TripService().getActiveTrip('trip-denied'), isNull);
    receipt.completeError(StateError('denied'));
    await rejected;
    expect(await TripService().getActiveTrip('trip-denied'), isNull);
  });

  test('arrival and completion rejection retain acknowledged progress; retry completes final arrival', () async {
    var reject = false;
    final driver = TripService(
      tripWriter: (_, _) async {
        if (reject) throw StateError('offline');
      },
    );
    final start = await driver.startTrip(
      busId: 'trip-progress',
      routeNo: '1',
      stops: ['a', 'b'],
      driverId: 'driver',
    );
    reject = true;
    await expectLater(
      driver.confirmNextStopArrival(start.busId),
      throwsStateError,
    );
    await expectLater(driver.completeTrip(start.busId), throwsStateError);
    expect(
      (await TripService().getActiveTrip(start.busId))!.currentStopIndex,
      0,
    );
    reject = false;
    final arrival = DateTime(2026, 10, 14, 12, 30);
    final end = await driver.confirmNextStopArrival(
      start.busId,
      arrivalTime: arrival,
    );
    expect(end!.status, 'completed');
    expect(end.currentStopIndex, 1);
    expect(end.stopTimes['b']!.actualArrival, arrival);
    expect(await TripService().getActiveTrip(start.busId), isNull);
  });

  test(
    'trip acknowledgement updates an existing passenger subscription',
    () async {
      final driver = TripService(tripWriter: (_, _) async {});
      final passenger = StreamIterator(
        TripService().watchActiveTripForBus('trip-stream-ack'),
      );
      await passenger.moveNext();
      expect(passenger.current, isNull);
      final next = passenger.moveNext();
      await driver.startTrip(
        busId: 'trip-stream-ack',
        routeNo: '1',
        stops: ['a', 'b', 'c'],
        driverId: 'driver',
      );
      expect(await next, isTrue);
      expect(passenger.current!.currentStopIndex, 0);
      final progress = passenger.moveNext();
      await driver.confirmNextStopArrival('trip-stream-ack');
      expect(await progress, isTrue);
      expect(passenger.current!.currentStopIndex, 1);
      await passenger.cancel();
    },
  );

  test('ordered overnight stop estimates cross midnight', () async {
    final driver = TripService(tripWriter: (_, _) async {});
    final trip = await driver.startTrip(
      busId: 'trip-night',
      routeNo: '1',
      stops: ['a', 'b', 'c'],
      driverId: 'driver',
      scheduleTimes: ['11:50 PM', '12:10 AM', '12:25 AM'],
      departureTime: DateTime(2026, 10, 14, 23, 50),
    );
    expect(
      trip.stopTimes['b']!.estimatedArrival,
      DateTime(2026, 10, 15, 0, 10),
    );
    expect(
      trip.stopTimes['c']!.estimatedArrival,
      DateTime(2026, 10, 15, 0, 25),
    );
  });
}
