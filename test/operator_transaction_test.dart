import 'package:access_transit/models/trip_model.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/services/user_service.dart';
import 'package:access_transit/services/journey_service.dart';
import 'package:access_transit/models/journey_model.dart';
import 'package:access_transit/models/service_run.dart';
import 'package:access_transit/services/service_run_service.dart';

// Firestore interfaces are faked to exercise the production transaction callbacks.
// ignore_for_file: subtype_of_sealed_class
import 'dart:async';

import 'package:access_transit/models/bus_location_model.dart';
import 'package:access_transit/services/live_bus_service.dart';
import 'package:access_transit/services/trip_service.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('report publication commits cooldown with report; retry preserves its first receipt', () async {
    final db = _Firestore();
    final service = FirestoreService(firestore: db);
    final report = Report(
      id: 'cooldown-report',
      targetType: 'bus',
      targetId: 'bus1',
      problemType: 'Ramp broken',
      status: 'active',
      createdAt: DateTime.now(),
      userId: 'author',
    );
    await service.createReport(report);
    final path = 'report_cooldowns/author/bus/bus1/issues/rampAccess';
    expect(db.documents[path]?['reportId'], report.id);
    final first = Map.of(db.documents[path]!);
    await service.createReport(report);
    expect(db.documents[path], first);
    expect(
      db.documents.keys.where((p) => p.startsWith('reports/')),
      hasLength(1),
    );
    await expectLater(
      service.createReport(report.copyWith(category: 'crowding')),
      throwsStateError,
    );
  });

  test(
    'rejected report transaction leaves both report and cooldown absent',
    () async {
      final db = _Firestore()..reject = true;
      final service = FirestoreService(firestore: db);
      await expectLater(
        service.createReport(
          Report(
            id: 'rejected-report',
            targetType: 'station',
            targetId: 's1',
            problemType: 'Blocked ramp',
            status: 'active',
            createdAt: DateTime.now(),
            userId: 'author',
          ),
        ),
        throwsStateError,
      );
      expect(db.documents, isEmpty);
    },
  );
  void seedRun(_Firestore db, String id, String bus, DateTime planned) {
    db.documents['operator_access/driver'] = {'approved': true};
    db.documents['driver_route_assignments/driver'] = {
      'active': true,
      'routeId': 'r1',
    };
    db.documents['buses/$bus'] = {'driverId': 'driver', 'routeId': 'r1'};
    db.documents['service_runs/$id'] = {
      'busId': bus,
      'routeId': 'r1',
      'routeNo': '1',
      'serviceDate': '2026-10-16',
      'status': 'scheduled',
      'plannedDepartureAt': Timestamp.fromDate(planned),
      'latestStartAt': Timestamp.fromDate(
        planned.add(ServiceRun.maximumLateStart),
      ),
      'stops': ['a', 'b'],
      'initialStopTimes': {
        'a': {
          'estimatedArrival': Timestamp.fromDate(planned),
          'actualArrival': null,
        },
        'b': {
          'estimatedArrival': Timestamp.fromDate(
            planned.add(const Duration(minutes: 20)),
          ),
          'actualArrival': null,
        },
      },
    };
  }

  BusLocationModel fix(String bus) => BusLocationModel(
    busId: bus,
    driverId: 'driver',
    latitude: 7,
    longitude: 80,
  );

  test('dated start is boarding, retries preserve one run and departure is acknowledged separately', () async {
    final db = _Firestore();
    seedRun(
      db,
      'dated-one',
      'dated-bus',
      DateTime.now().toUtc().add(const Duration(minutes: 1)),
    );
    final service = ServiceRunService(firestore: db);
    final started = await service.startRun(
      runId: 'dated-one',
      driverId: 'driver',
      gps: fix('dated-bus'),
    );
    expect(started.isBoarding, isTrue);
    expect(started.actualDepartureTime, isNull);
    expect(started.stopTimes['a']!.actualArrival, isNull);
    await service.startRun(
      runId: 'dated-one',
      driverId: 'driver',
      gps: fix('dated-bus'),
    );
    expect(db.documents.keys.where((p) => p.startsWith('trips/')).length, 1);
    await expectLater(
      TripService(firestore: db).confirmNextStopArrival('dated-bus'),
      throwsStateError,
    );
    final departed = await service.recordDeparture('dated-one', 'driver');
    expect(departed.actualDepartureTime, isNotNull);
    expect(departed.isBoarding, isFalse);
    final actual = departed.actualDepartureTime;
    expect(
      (await service.recordDeparture(
        'dated-one',
        'driver',
      )).actualDepartureTime,
      actual,
    );
    final completed = await TripService(firestore: db)
        .confirmNextStopArrival('dated-bus');
    expect(completed!.isCompleted, isTrue);
    expect(db.documents['service_runs/dated-one']!['status'], 'completed');
    expect(db.documents['operation_locks/driver']!['active'], isFalse);
    expect(
      db.documents['live_locations/dated-bus']!['isBroadcasting'],
      isFalse,
    );
    await expectLater(
      service.startRun(
        runId: 'dated-one',
        driverId: 'driver',
        gps: fix('dated-bus'),
      ),
      throwsStateError,
    );
  });

  test('driver lock blocks a second bus; cancelling boarding releases it atomically', () async {
    final db = _Firestore();
    final now = DateTime.now().toUtc();
    seedRun(
      db,
      'lock-one',
      'lock-bus-one',
      now.add(const Duration(minutes: 1)),
    );
    seedRun(
      db,
      'lock-two',
      'lock-bus-two',
      now.add(const Duration(minutes: 1)),
    );
    final service = ServiceRunService(firestore: db);
    await service.startRun(
      runId: 'lock-one',
      driverId: 'driver',
      gps: fix('lock-bus-one'),
    );
    await expectLater(
      service.startRun(
        runId: 'lock-two',
        driverId: 'driver',
        gps: fix('lock-bus-two'),
      ),
      throwsStateError,
    );
    db.reject = true;
    await expectLater(
      TripService(firestore: db).completeTrip('lock-bus-one'),
      throwsStateError,
    );
    expect(db.documents['operation_locks/driver']!['active'], isTrue);
    db.reject = false;
    final cancelled = await TripService(firestore: db)
        .completeTrip('lock-bus-one');
    expect(cancelled!.status, 'cancelled');
    expect(db.documents['operation_locks/driver']!['active'], isFalse);
    await service.startRun(
      runId: 'lock-two',
      driverId: 'driver',
      gps: fix('lock-bus-two'),
    );
    expect(db.documents['operation_locks/driver']!['tripId'], 'lock-two');
  });

  test(
    'early/expired runs and unexplained late starts do not publish',
    () async {
      final db = _Firestore();
      final now = DateTime.now().toUtc();
      final service = ServiceRunService(firestore: db);
      for (final entry in {
        'early': now.add(const Duration(minutes: 6)),
        'expired': now.subtract(const Duration(minutes: 31)),
        'late': now.subtract(const Duration(minutes: 1)),
      }.entries) {
        seedRun(db, entry.key, 'timed-bus', entry.value);
        await expectLater(
          service.startRun(
            runId: entry.key,
            driverId: 'driver',
            gps: fix('timed-bus'),
          ),
          throwsStateError,
        );
        expect(db.documents['trips/${entry.key}'], isNull);
      }
      await service.startRun(
        runId: 'late',
        driverId: 'driver',
        gps: fix('timed-bus'),
        lateReason: 'Traffic delayed arrival',
      );
      expect(
        db.documents['driver_trip_notes/late']!['reason'],
        'Traffic delayed arrival',
      );
    },
  );
  test(
    'a rejected condition write retains a bus read from the shared backend',
    () async {
      final db = _Firestore();
      const id = 'remote-ack-bus';
      db.documents['buses/$id'] = {
        'routeNo': '1',
        'stops': ['a', 'b'],
        'rampOk': false,
        'hasRamp': true,
        'occupancy': 'high',
      };
      final shared = await FirestoreService(firestore: db).getBusById(id);
      expect(shared!.rampOk, isFalse);
      final rejected = FirestoreService(
        busWriter: (_, _) async => throw StateError('denied'),
      );
      await expectLater(
        rejected.updateBusAccessibility(id, rampOk: true),
        throwsStateError,
      );
      expect((await FirestoreService().getBusById(id))!.rampOk, isFalse);
    },
  );
  Future<void> start(
    _Firestore db,
    String bus, {
    String? id,
    List<String> stops = const ['a', 'b', 'c'],
  }) async {
    await TripService(firestore: db).startTrip(
      busId: bus,
      routeNo: '1',
      stops: stops,
      driverId: 'driver',
      requestedTripId: id ?? 'trip-$bus',
      initialTelemetry: BusLocationModel(
        busId: bus,
        driverId: 'driver',
        latitude: 7,
        longitude: 80,
      ),
    );
  }

  test(
    'production start rejection leaves both shared documents and cache absent',
    () async {
      final db = _Firestore()..reject = true;
      await expectLater(start(db, 'atomic-start-denied'), throwsStateError);
      expect(db.documents, isEmpty);
      expect(await TripService().getActiveTrip('atomic-start-denied'), isNull);
    },
  );

  test(
    'production retry/resume preserves stop progress and creates one trip',
    () async {
      final db = _Firestore();
      const bus = 'atomic-resume';
      await start(db, bus);
      await TripService(firestore: db).confirmNextStopArrival(bus);
      final previous = Map.of(db.documents['trips/trip-$bus']!);
      await start(db, bus);
      expect(db.documents.keys.where((p) => p.startsWith('trips/')).length, 1);
      expect(db.documents['trips/trip-$bus'], previous);
      expect(db.documents['live_locations/$bus']!['currentStopIndex'], 1);
      expect((await TripService().getActiveTrip(bus))!.currentStopIndex, 1);
    },
  );

  test('completion rollback keeps timeline and broadcasting; final arrival commits both', () async {
    final db = _Firestore();
    const bus = 'atomic-completion';
    final service = TripService(firestore: db);
    await start(db, bus);
    await service.confirmNextStopArrival(bus);
    db.reject = true;
    await expectLater(service.confirmNextStopArrival(bus), throwsStateError);
    expect(db.documents['trips/trip-$bus']!['currentStopIndex'], 1);
    expect(db.documents['live_locations/$bus']!['isBroadcasting'], isTrue);
    expect((await TripService().getActiveTrip(bus))!.currentStopIndex, 1);
    db.reject = false;
    final arrival = DateTime(2026, 10, 14, 12, 30);
    final saved = await service.confirmNextStopArrival(
      bus,
      arrivalTime: arrival,
    );
    expect(saved!.isCompleted, isTrue);
    expect(saved.stopTimes['c']!.actualArrival, arrival);
    expect(db.documents['live_locations/$bus']!['isBroadcasting'], isFalse);
    expect(db.documents['trips/trip-$bus']!['status'], 'completed');
    await expectLater(
      LiveBusService(firestore: db).updateLocationOnly(
        busId: bus,
        latitude: 8,
        longitude: 81,
        expectedTripId: 'trip-$bus',
      ),
      throwsStateError,
    );
    expect(db.documents['live_locations/$bus']!['latitude'], 7);
  });

  test(
    'old GPS and stop callbacks cannot write to a replacement session',
    () async {
      final db = _Firestore();
      const bus = 'atomic-replacement';
      await start(db, bus);
      db.documents['live_locations/$bus']!['tripId'] = 'replacement-trip';
      await expectLater(
        LiveBusService(firestore: db).updateLocationOnly(
          busId: bus,
          latitude: 8,
          longitude: 81,
          expectedTripId: 'trip-$bus',
        ),
        throwsStateError,
      );
      await expectLater(
        TripService(firestore: db).confirmNextStopArrival(bus),
        throwsStateError,
      );
      expect(db.documents['live_locations/$bus']!['latitude'], 7);
      expect(db.documents['trips/trip-$bus']!['currentStopIndex'], 0);
    },
  );

  test('pending telemetry cannot replace acknowledged GPS; authoritative deletion clears it', () async {
    final db = _Firestore();
    const bus = 'remote-gps-delete';
    final service = LiveBusService(firestore: db);
    final doc = db.collection('live_locations').doc(bus) as _Document;
    final iterator = StreamIterator(service.listenToLiveLocation(bus));
    await iterator.moveNext();
    final original = BusLocationModel(
      busId: bus,
      latitude: 7,
      longitude: 80,
      timestamp: DateTime(2026, 10, 14),
    ).toMap();
    doc.events.add(_Snapshot(doc.id, original));
    await iterator.moveNext();
    final events = <BusLocationModel?>[];
    final next = iterator.moveNext();
    doc.events.add(
      _Snapshot(doc.id, {...original, 'latitude': 8}, pending: true),
    );
    doc.events.add(_Snapshot(doc.id, null));
    expect(await next, isTrue);
    events.add(iterator.current);
    expect(events, [null]);
    expect(await LiveBusService().getLiveLocation(bus), isNull);
    await iterator.cancel();
  });
  test('bus claim requires authenticated approval and preserves existing assignment', () async {
    final db = _Firestore();
    db.documents['buses/claim-test'] = {
      'routeNo': '1',
      'routeId': 'r1',
      'stops': ['a', 'b'],
      'driverId': null,
    };
    final service = FirestoreService(
      firestore: db,
      operatorActorId: () => 'driver',
    );
    await expectLater(
      service.assignBusDriver('claim-test', 'driver'),
      throwsStateError,
    );
    expect(db.documents['buses/claim-test']!['driverId'], isNull);
    db.documents['operator_access/driver'] = {'approved': true};
    await expectLater(
      service.assignBusDriver('claim-test', 'driver'),
      throwsStateError,
    );
    db.documents['driver_route_assignments/driver'] = {
      'active': true,
      'routeId': 'wrong',
    };
    await expectLater(
      service.assignBusDriver('claim-test', 'driver'),
      throwsStateError,
    );
    db.documents['driver_route_assignments/driver'] = {
      'active': true,
      'routeId': 'r1',
    };
    await expectLater(
      service.assignBusDriver('claim-test', 'driver'),
      throwsStateError,
    );
    db.documents['routes/r1'] = {
      'stops': ['a', 'b'],
    };
    await expectLater(
      service.assignBusDriver('claim-test', 'other'),
      throwsStateError,
    );
    await service.assignBusDriver('claim-test', 'driver');
    await service.assignBusDriver('claim-test', 'driver');
    expect(db.documents['buses/claim-test']!['driverId'], 'driver');
    expect(
      db.documents['driver_route_assignments/driver']!['claimRevision'],
      1,
    );
    db.documents['buses/claim-test']!['driverId'] = 'other';
    await expectLater(
      service.assignBusDriver('claim-test', 'driver'),
      throwsStateError,
    );
    expect(db.documents['buses/claim-test']!['driverId'], 'other');
    db.documents['operator_access/driver'] = {'approved': false};
    await expectLater(
      service.assignBusDriver('claim-test', 'driver'),
      throwsStateError,
    );
  });
  test('condition writes preserve acknowledged server check attribution while occupancy does not refresh it', () async {
    final db = _Firestore();
    const id = 'checked-bus';
    db.documents['buses/$id'] = {
      'routeNo': '1',
      'stops': ['a', 'b'],
      'hasRamp': true,
      'rampOk': null,
      'occupancy': 'low',
      'driverId': 'driver',
    };
    final service = FirestoreService(
      firestore: db,
      operatorActorId: () => 'driver',
    );
    await service.getBusById(id);
    await service.updateBusAccessibility(id, rampOk: true);
    final check = db.documents['buses/$id']!['rampCheckedAt'];
    expect(check, isA<Timestamp>());
    expect(db.documents['buses/$id']!['rampCheckedBy'], 'driver');
    expect((await service.getBusById(id))!.wheelchairAccessible, isTrue);
    await service.updateBusAccessibility(id, occupancy: 'high');
    expect(db.documents['buses/$id']!['rampCheckedAt'], check);
    expect(db.documents['buses/$id']!['rampCheckedBy'], 'driver');
  });
  test('acknowledged profile edits preserve trusted counters and rejected edits preserve cache', () async {
    final db = _Firestore();
    const uid = 'reward-profile';
    db.documents['users/$uid'] = {
      'uid': uid,
      'name': 'Before',
      'email': 'rider@example.test',
      'points': 100,
      'reportsSubmitted': 2,
      'verifiedCount': 3,
    };
    final service = UserService(firestore: db);
    final original = (await service.getUser(uid))!;
    final saved = await service.updateUser(
      original.copyWith(name: 'After', points: 9999),
    );
    expect(saved.name, 'After');
    expect(saved.points, 100);
    expect(db.documents['users/$uid']!['points'], 100);
    db.reject = true;
    await expectLater(
      service.updateUser(saved.copyWith(name: 'Rejected', points: 500)),
      throwsStateError,
    );
    expect((await UserService().getUser(uid))!.name, 'After');
    expect((await UserService().getUser(uid))!.points, 100);
  });
  test('production recheck transaction commits dated history, preserves votes and rolls back rejection', () async {
    final db = _Firestore();
    const id = 'production-recheck';
    final original = Report(
      id: id,
      targetType: 'bus',
      targetId: 'bus1',
      problemType: 'Ramp Broken',
      status: 'active',
      userId: 'author',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      lastConfirmedAt: DateTime.now().subtract(const Duration(days: 2)),
      confirmedBy: ['rider'],
      confirmCount: 1,
    );
    db.documents['reports/$id'] = original.toMap();
    final service = FirestoreService(
      firestore: db,
      reportActorId: () => 'rider',
    );
    final saved = await service.recheckReport(id, 'rider');
    expect(saved.changed, isTrue);
    expect(saved.report!.lastRecheckedAt, isNotNull);
    expect(saved.report!.confirmCount, 1);
    expect(saved.report!.lastConfirmedAt, original.lastConfirmedAt);
    final history = db.documents.entries
        .where((e) => e.key.startsWith('reports/$id/rechecks/'))
        .toList();
    expect(history, hasLength(1));
    expect(history.single.value['userId'], 'rider');
    expect(history.single.value['checkedAt'], isA<Timestamp>());
    final count = db.documents.length;
    expect((await service.recheckReport(id, 'rider')).changed, isFalse);
    expect(db.documents.length, count);
    // A second eligible attempt denied at commit must not update the acknowledged cache or history.
    db.documents['reports/$id'] = original.toMap();
    db.reject = true;
    await expectLater(service.recheckReport(id, 'rider'), throwsStateError);
    expect(db.documents.length, count);
    expect(db.documents['reports/$id']!['lastRecheckedAt'], isNull);
    final cached = await FirestoreService().streamReportById(id).first;
    expect(cached!.lastRecheckedAt, saved.report!.lastRecheckedAt);
  });
  for (final stops in [
    ['a', 'b'],
    ['a', 'b', 'c', 'd'],
  ]) {
    test(
      '${stops.length}-stop trip completes on terminal arrival with no extra confirmation',
      () async {
        final db = _Firestore();
        final bus = 'f17-${stops.length}';
        final service = TripService(firestore: db);
        await start(db, bus, stops: stops);
        final tripPath = 'trips/trip-$bus';
        final livePath = 'live_locations/$bus';
        final arrivals = <String, DateTime>{};
        for (var index = 1; index < stops.length; index++) {
          final at = DateTime(2026, 10, 15, 12, index * 5);
          arrivals[stops[index]] = at;
          final result = await service.confirmNextStopArrival(
            bus,
            arrivalTime: at,
            expectedTripId: 'trip-$bus',
          );
          expect(result!.currentStopIndex, index);
          expect(result.isCompleted, index == stops.length - 1);
          expect(
            db.documents[livePath]!['isBroadcasting'],
            index != stops.length - 1,
          );
          for (final prior in arrivals.entries) {
            expect(result.stopTimes[prior.key]!.actualArrival, prior.value);
          }
        }
        expect(db.documents[tripPath]!['status'], 'completed');
        expect(db.documents[livePath]!['currentStopIndex'], stops.length - 1);
        expect(db.documents[livePath]!['nextStop'], stops.last);
        expect(db.documents[livePath]!['addedDelayMinutes'], 0);
        expect(await TripService().getActiveTrip(bus), isNull);
        expect(await service.confirmNextStopArrival(bus), isNull);
        final retry = await service.completeTrip(
          bus,
          expectedTripId: 'trip-$bus',
        );
        expect(
          retry!.stopTimes[stops.last]!.actualArrival,
          arrivals[stops.last],
        );
      },
    );
  }

  for (final priorArrival in [false, true]) {
    test(
      'legacy terminal index completes and ${priorArrival ? 'retains' : 'records'} its actual arrival',
      () async {
        final db = _Firestore();
        final bus = 'f17-legacy-$priorArrival';
        final service = TripService(firestore: db);
        await start(db, bus);
        final path = 'trips/trip-$bus';
        final at = DateTime(2026, 10, 15, 12);
        final legacy = TripModel.fromMap(db.documents[path]!)
            .copyWith(currentStopIndex: 2);
        final times = Map.of(legacy.stopTimes);
        if (priorArrival) times['c'] = times['c']!.copyWith(actualArrival: at);
        db.documents[path] = legacy.copyWith(stopTimes: times).toMap();
        // Retry/resume imports acknowledged legacy progress instead of resetting it.
        await start(db, bus);
        final confirmedAt = at.add(const Duration(minutes: 5));
        final result = await service.confirmNextStopArrival(
          bus,
          arrivalTime: confirmedAt,
          expectedTripId: 'trip-$bus',
        );
        expect(result!.isCompleted, isTrue);
        expect(result.currentStopIndex, 2);
        expect(
          result.stopTimes['c']!.actualArrival,
          priorArrival ? at : confirmedAt,
        );
        expect(db.documents['live_locations/$bus']!['isBroadcasting'], isFalse);
      },
    );
  }

  test('completion retry reconciles stale broadcasting while retaining saved terminal arrival', () async {
    final db = _Firestore();
    const bus = 'f17-reconcile';
    final service = TripService(firestore: db);
    await start(db, bus, stops: ['a', 'b']);
    final path = 'trips/trip-$bus';
    final actual = DateTime(2026, 10, 15, 12);
    final prior = TripModel.fromMap(db.documents[path]!);
    db.documents[path] = prior
        .copyWith(
          status: 'completed',
          currentStopIndex: 1,
          stopTimes: {
            ...prior.stopTimes,
            'b': prior.stopTimes['b']!.copyWith(actualArrival: actual),
          },
        )
        .toMap();
    // Simulate an acknowledged completion elsewhere with stale local progress
    // and a legacy broadcast that was not closed.
    db.reject = true;
    await expectLater(service.confirmNextStopArrival(bus), throwsStateError);
    expect(db.documents['live_locations/$bus']!['isBroadcasting'], isTrue);
    db.reject = false;
    final saved = await service.confirmNextStopArrival(
      bus,
      arrivalTime: actual.add(const Duration(minutes: 10)),
    );
    expect(saved!.stopTimes['b']!.actualArrival, actual);
    expect(db.documents['live_locations/$bus']!['isBroadcasting'], isFalse);
    expect(db.documents[path]!['status'], 'completed');
  });
  test('passenger journey save, rejection and retry never create or modify operator evidence', () async {
    final db = _Firestore();
    db.documents.addAll({
      'buses/confirmation25': {'hasRamp': true, 'rampOk': false},
      'trips/real-operator-trip': {
        'busId': 'confirmation25',
        'status': 'in_progress',
      },
      'live_locations/confirmation25': {
        'busId': 'confirmation25',
        'latitude': 7.1,
        'speed': 0,
        'operatorId': 'approved-operator',
      },
      'reports/existing-warning': {
        'targetId': 'confirmation25',
        'condition': 'barrier',
      },
    });
    final before = Map<String, Map<String, dynamic>>.from(db.documents);
    final service = JourneyService(
      firestore: db,
      currentPassengerId: () => 'rider',
    );
    final journey = JourneyModel(
      journeyId: 'passenger25',
      passengerId: 'rider',
      routeId: 'route25',
      routeNumber: '25',
      routeTitle: 'Selected route',
      busId: 'confirmation25',
      origin: 'Boarding',
      destination: 'Destination',
      fromStationId: 'a',
      toStationId: 'b',
      departureAt: DateTime(2026, 10, 25, 10),
      durationMinutes: 15,
      estimatedFareLkr: 70,
    );
    db.reject = true;
    await expectLater(service.createJourney(journey), throwsStateError);
    expect(db.documents, before);
    db.reject = false;
    final saved = await service.createJourney(journey);
    await service.createJourney(
      journey,
    ); // Same passenger selection is idempotent.
    expect(saved.status, JourneyStatus.confirmed);
    expect(db.documents.length, before.length + 1);
    expect(db.documents.containsKey('journeys/passenger25'), isTrue);
    for (final entry in before.entries) {
      expect(db.documents[entry.key], entry.value);
    }
    expect(db.refs.keys, everyElement(startsWith('journeys/')));
    final payload = db.documents['journeys/passenger25']!;
    for (final field in [
      'latitude',
      'longitude',
      'speed',
      'operatorId',
      'rampOk',
      'isBroadcasting',
    ]) {
      expect(payload.containsKey(field), isFalse);
    }
  });
}

class _Firestore extends Fake implements FirebaseFirestore {
  @override
  DocumentReference<Map<String, dynamic>> doc(String path) =>
      refs.putIfAbsent(path, () => _Document(this, path));
  final documents = <String, Map<String, dynamic>>{};
  final refs = <String, _Document>{};
  bool reject = false;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(this, path);
  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> handler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    final tx = _Transaction(this);
    final result = await handler(tx);
    if (reject) throw StateError('transaction denied');
    for (final change in tx.changes.entries) {
      documents[change.key] = change.value;
    }
    return result;
  }
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.db, this.path);
  final _Firestore db;
  @override
  final String path;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? id]) =>
      db.refs.putIfAbsent(
        '$path/${id ?? 'generated-${db.refs.length}'}',
        () => _Document(db, '$path/${id ?? 'generated-${db.refs.length}'}'),
      );
}

class _Document extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _Document(this.db, this.path);
  final _Firestore db;
  final events = StreamController<DocumentSnapshot<Map<String, dynamic>>>();
  @override
  final String path;
  @override
  String get id => path.split('/').last;
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _Collection(db, '$path/$collectionPath');
  @override
  Future<void> update(Map<Object, Object?> data) async {
    if (db.reject) throw StateError('denied');
    db.documents[path] = {
      ...?db.documents[path],
      ...data.map(
        (key, value) => MapEntry(
          key.toString(),
          value is FieldValue ? Timestamp.fromDate(DateTime.now()) : value,
        ),
      ),
    };
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async => _Snapshot(id, db.documents[path]);
  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => events.stream;
}

class _Transaction extends Fake implements Transaction {
  _Transaction(this.db);
  final _Firestore db;
  final changes = <String, Map<String, dynamic>>{};
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> ref,
  ) async => _Snapshot<T>(ref.id, db.documents[ref.path] as T?);
  @override
  Transaction set<T>(DocumentReference<T> ref, T data, [SetOptions? options]) {
    changes[ref.path] = _values(data as Map<String, dynamic>);
    return this;
  }

  @override
  Transaction update(DocumentReference ref, Map<Object, Object?> data) {
    changes[ref.path] = {
      ...?db.documents[ref.path],
      ..._values(data.map((k, v) => MapEntry(k.toString(), v))),
    };
    return this;
  }

  Map<String, dynamic> _values(Map<String, dynamic> data) => data.map(
    (key, value) => MapEntry(
      key,
      value is FieldValue ? Timestamp.fromDate(DateTime.now()) : value,
    ),
  );
}

class _Snapshot<T> extends Fake implements DocumentSnapshot<T> {
  _Snapshot(this.id, this.value, {bool pending = false})
    : metadata = _Metadata(pending);
  @override
  final String id;
  final T? value;
  @override
  bool get exists => value != null;
  @override
  T? data() => value;
  @override
  final SnapshotMetadata metadata;
}

class _Metadata extends Fake implements SnapshotMetadata {
  _Metadata(this.hasPendingWrites);
  @override
  final bool hasPendingWrites;
  @override
  bool get isFromCache => false;
}
