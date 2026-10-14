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
  Future<void> start(_Firestore db, String bus, {String? id}) async {
    await TripService(firestore: db).startTrip(
      busId: bus,
      routeNo: '1',
      stops: ['a', 'b', 'c'],
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
}

class _Firestore extends Fake implements FirebaseFirestore {
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
      db.refs.putIfAbsent('$path/$id', () => _Document(db, '$path/$id'));
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
