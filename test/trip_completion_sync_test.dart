// Firestore interfaces are faked only for deterministic remote snapshot tests.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:access_transit/models/trip_model.dart';
import 'package:access_transit/services/trip_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TripModel trip(String busId) => TripModel(
    tripId: 'trip-$busId',
    busId: busId,
    routeNo: '138',
    stops: ['a', 'b'],
    status: 'in_progress',
    stopTimes: {},
    driverId: 'driver',
    createdAt: DateTime(2026, 10, 13),
  );

  for (final change in ['completed', 'deleted']) {
    test(
      'remote $change trip clears passenger stream and fallback cache',
      () async {
        final busId = 'remote-$change';
        final db = _Firestore();
        final iterator = StreamIterator(
          TripService(firestore: db).watchActiveTripForBus(busId),
        );
        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current, isNull);
        db.query.controller.add(_Snapshot([trip(busId)]));
        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current!.isInProgress, isTrue);

        db.query.controller.add(_Snapshot([]));
        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current, isNull);
        expect(await TripService().getActiveTrip(busId), isNull);
        await iterator.cancel();
        await db.query.controller.close();
      },
    );
  }

  for (final pending in [false, true]) {
    test(
      'empty ${pending ? 'pending-write' : 'offline-cache'} snapshot keeps the active trip',
      () async {
        final busId = 'unconfirmed-$pending';
        final db = _Firestore();
        final iterator = StreamIterator(
          TripService(firestore: db).watchActiveTripForBus(busId),
        );
        await iterator.moveNext();
        db.query.controller.add(_Snapshot([trip(busId)]));
        await iterator.moveNext();
        db.query.controller.add(
          _Snapshot([], cached: !pending, pending: pending),
        );
        await iterator.moveNext();
        expect(iterator.current!.busId, busId);
        await iterator.cancel();
        await db.query.controller.close();
      },
    );
  }

  test(
    'authoritative empty one-time fetch also clears a cached active trip',
    () async {
      const busId = 'remote-fetch';
      final db = _Firestore();
      db.query.latest = _Snapshot([trip(busId)]);
      final service = TripService(firestore: db);
      expect(await service.getActiveTrip(busId), isNotNull);
      db.query.latest = _Snapshot([]);
      expect(await service.getActiveTrip(busId), isNull);
      expect(await TripService().getActiveTrip(busId), isNull);
      unawaited(db.query.controller.close());
    },
  );

  test(
    'local fallback stream emits completion after the initial trip',
    () async {
      final service = TripService(tripWriter: (_, _) async {});
      const busId = 'local-completion-stream';
      await service.startTrip(
        busId: busId,
        routeNo: '138',
        stops: ['a', 'b'],
        driverId: 'driver',
      );
      final iterator = StreamIterator(service.watchActiveTripForBus(busId));
      await iterator.moveNext();
      expect(iterator.current, isNotNull);
      final next = iterator.moveNext();
      // Allow the generator to subscribe to its local changes stream.
      await Future<void>.delayed(Duration.zero);
      await service.completeTrip(busId);
      expect(await next.timeout(const Duration(seconds: 2)), isTrue);
      expect(iterator.current, isNull);
      await iterator.cancel();
    },
  );
}

class _Firestore extends Fake implements FirebaseFirestore {
  final query = _Query();
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => query;
}

// Mutable responses let this test fake simulate changes on another device.
// ignore: must_be_immutable
class _Query extends Fake implements CollectionReference<Map<String, dynamic>> {
  final controller = StreamController<QuerySnapshot<Map<String, dynamic>>>();
  QuerySnapshot<Map<String, dynamic>>? latest;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #where) return this;
    if (invocation.memberName == #snapshots) return controller.stream;
    if (invocation.memberName == #get) return Future.value(latest!);
    return super.noSuchMethod(invocation);
  }
}

class _Snapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  _Snapshot(List<TripModel> trips, {bool cached = false, bool pending = false})
    : docs = trips.map((trip) => _Document(trip)).toList(),
      metadata = _Metadata(cached, pending);
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  @override
  final SnapshotMetadata metadata;
}

class _Document extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _Document(this.trip);
  final TripModel trip;
  @override
  String get id => trip.tripId;
  @override
  Map<String, dynamic> data() => trip.toMap();
}

class _Metadata extends Fake implements SnapshotMetadata {
  _Metadata(this.isFromCache, this.hasPendingWrites);
  @override
  final bool isFromCache;
  @override
  final bool hasPendingWrites;
}
