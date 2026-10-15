// Firestore fakes exercise receipt metadata, query invalidation and read races.
// ignore_for_file: subtype_of_sealed_class, must_be_immutable
import 'dart:async';

import 'package:access_transit/logic/delay_eta_logic.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/bus_location_model.dart';
import 'package:access_transit/screens/journey/live_journey_screen.dart';
import 'package:access_transit/services/live_bus_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var sequence = 0;
  late _Db db;
  late LiveBusService service;
  late String collectionName;
  setUp(() {
    db = _Db();
    collectionName = 'f19-${sequence++}';
    service = LiveBusService(firestore: db, collectionName: collectionName);
  });
  Map<String, dynamic> data(String id) => BusLocationModel(
    busId: id,
    latitude: 7,
    longitude: 80,
    timestamp: DateTime.now(),
  ).toMap(isServerTimestamp: false);
  Future<void> flush() => Future<void>.delayed(Duration.zero);

  test('document deletion reaches every listener and queued local signals cannot resurrect it', () async {
    final first = <BusLocationModel?>[];
    final second = <BusLocationModel?>[];
    final a = service.listenToLiveLocation('a').listen(first.add);
    final b = LiveBusService(collectionName: collectionName)
        .listenToLiveLocation('a')
        .listen(second.add);
    await flush();
    db.document('a').events.add(_DocSnapshot('a', data('a')));
    await flush();
    expect(first.last!.busId, 'a');
    // A local event for another bus is already queued when deletion arrives.
    service.acceptAcknowledged(BusLocationModel.fromMap(data('b')));
    db.document('a').events.add(_DocSnapshot('a', null));
    await flush();
    expect(first.last, isNull);
    expect(second.last, isNull);
    db.document('a').events.add(_DocSnapshot('a', data('a'), cached: true));
    service.acceptAcknowledged(BusLocationModel.fromMap(data('b')));
    await flush();
    expect(first.last, isNull);
    expect(second.last, isNull);
    await a.cancel();
    await b.cancel();
  });

  test('authoritative active query prunes absent buses and later cached lists stay empty', () async {
    final events = <List<BusLocationModel>>[];
    final docEvents = <BusLocationModel?>[];
    final active = service.listenToAllActiveBuses().listen(events.add);
    final single = service.listenToLiveLocation('a').listen(docEvents.add);
    await flush();
    db.query.events.add(
      _QuerySnapshot([_QueryDoc('a', data('a')), _QueryDoc('b', data('b'))]),
    );
    await flush();
    expect(events.last.map((b) => b.busId), ['a', 'b']);
    db.query.events.add(_QuerySnapshot([_QueryDoc('b', data('b'))]));
    await flush();
    expect(docEvents.last, isNull);
    expect(events.last.map((b) => b.busId), ['b']);
    db.query.events.add(_QuerySnapshot([]));
    await flush();
    db.query.events.add(
      _QuerySnapshot([_QueryDoc('a', data('a'))], cached: true),
    );
    service.acceptAcknowledged(
      BusLocationModel.fromMap(data('unrelated'))
          .copyWith(isBroadcasting: false),
    );
    await flush();
    expect(events.last, isEmpty);
    expect(docEvents.last, isNull);
    await active.cancel();
    await single.cancel();
  });

  test('cached/pending snapshots cannot replace acknowledged telemetry; error and reconnect change provenance', () async {
    final events = <BusLocationModel?>[];
    final sub = service.listenToLiveLocation('a').listen(events.add);
    await flush();
    db
        .document('a')
        .events
        .add(_DocSnapshot('a', {...data('a'), 'latitude': 8}, pending: true));
    await flush();
    expect(events.last, isNull);
    db.document('a').events.add(_DocSnapshot('a', data('a')));
    await flush();
    final observed = events.last!.timestamp;
    db
        .document('a')
        .events
        .add(_DocSnapshot('a', {...data('a'), 'latitude': 9}, cached: true));
    await flush();
    expect(events.last!.latitude, 7);
    expect(events.last!.timestamp, observed);
    expect(events.last!.isCached, isTrue);
    expect(service.isBusStale(events.last!), isTrue);
    db.document('a').events.addError(StateError('offline'));
    await flush();
    db
        .document('a')
        .events
        .add(_DocSnapshot('a', {...data('a'), 'latitude': 8}));
    await flush();
    expect(events.last!.isCached, isFalse);
    expect(events.last!.latitude, 8);
    await sub.cancel();
  });

  test('one-time missing server read clears watchers and an old in-flight read loses to query deletion', () async {
    service.acceptAcknowledged(BusLocationModel.fromMap(data('a')));
    final events = <BusLocationModel?>[];
    final sub = service.listenToLiveLocation('a').listen(events.add);
    await flush();
    expect(await service.getLiveLocation('a'), isNull);
    await flush();
    expect(events.last, isNull);
    expect(db.document('a').lastOptions!.source, Source.server);
    final active = service.listenToAllActiveBuses().listen((_) {});
    await flush();
    // This ID was not cached, so collection-level invalidation must fence it too.
    final oldRead = Completer<DocumentSnapshot<Map<String, dynamic>>>();
    db.document('unknown').read = oldRead.future;
    final pending = service.getLiveLocation('unknown');
    db.query.events.add(_QuerySnapshot([]));
    await flush();
    oldRead.complete(_DocSnapshot('unknown', data('unknown')));
    expect(await pending, isNull);
    await sub.cancel();
    await active.cancel();
  });

  test('failed reads keep only labelled acknowledged data, never SDK cached replacements', () async {
    service.acceptAcknowledged(BusLocationModel.fromMap(data('a')));
    db.document('a').read = Future.error(StateError('offline'));
    final saved = await service.getLiveLocation('a');
    expect(saved!.isCached, isTrue);
    expect(service.isBusStale(saved), isTrue);
    db.document('a').read = Future.value(
      _DocSnapshot('a', {...data('a'), 'latitude': 9}, cached: true),
    );
    expect((await service.getLiveLocation('a'))!.latitude, 7);
    db.document('a').read = Future.value(_DocSnapshot('a', data('a')));
    expect((await service.getLiveLocation('a'))!.isCached, isFalse);
  });

  test('collection caches are isolated and metadata cannot be forged by cloud fields', () async {
    service.acceptAcknowledged(BusLocationModel.fromMap(data('a')));
    final other = LiveBusService(collectionName: '$collectionName-other');
    expect(await other.getLiveLocation('a'), isNull);
    final model = BusLocationModel.fromMap({...data('a'), 'isCached': true});
    expect(model.isCached, isFalse);
    expect(
      model.copyWith(isCached: true).toMap().containsKey('isCached'),
      isFalse,
    );
  });

  testWidgets(
    'silent telemetry crosses expiry and emits stale state without backend changes',
    (tester) async {
      var now = DateTime(2026, 10, 15, 12);
      service = LiveBusService(
        firestore: db,
        collectionName: collectionName,
        clock: () => now,
      );
      final events = <BusLocationModel?>[];
      final sub = service.listenToLiveLocation('a').listen(events.add);
      await tester.pump();
      db
          .document('a')
          .events
          .add(
            _DocSnapshot('a', {
              ...data('a'),
              'timestamp': Timestamp.fromDate(now),
            }),
          );
      await tester.pump();
      expect(service.isBusStale(events.last!), isFalse);
      now = now.add(const Duration(minutes: 6));
      await tester.pump(const Duration(minutes: 1));
      expect(service.isBusStale(events.last!), isTrue);
      unawaited(sub.cancel());
      await tester.pump();
    },
  );

  testWidgets(
    'initial saved data cannot become live from a timer or unrelated bus receipt',
    (tester) async {
      var now = DateTime(2026, 10, 15, 12);
      service = LiveBusService(
        firestore: db,
        collectionName: collectionName,
        clock: () => now,
      );
      service.acceptAcknowledged(
        BusLocationModel.fromMap({
          ...data('a'),
          'timestamp': Timestamp.fromDate(now),
        }),
      );
      final events = <BusLocationModel?>[];
      final sub = service.listenToLiveLocation('a').listen(events.add);
      await tester.pump();
      expect(events.last!.isCached, isTrue);
      now = now.add(const Duration(minutes: 1));
      await tester.pump(const Duration(minutes: 1));
      service.acceptAcknowledged(BusLocationModel.fromMap(data('b')));
      await tester.pump();
      expect(events.last!.isCached, isTrue);
      db
          .document('a')
          .events
          .add(
            _DocSnapshot('a', {
              ...data('a'),
              'timestamp': Timestamp.fromDate(now),
            }),
          );
      await tester.pump();
      expect(events.last!.isCached, isFalse);
      unawaited(sub.cancel());
      await tester.pump();
    },
  );

  test('cached, missing-time and old telemetry cannot claim current GPS or apply live driver delay', () {
    final now = DateTime.now();
    const bus = Bus(
      id: 'a',
      routeNo: '1',
      stops: ['s1', 's2'],
      scheduleTimes: ['08:00', '08:10'],
      hasRamp: false,
      lowFloor: false,
      occupancy: 'low',
    );
    for (final model in [
      BusLocationModel(busId: 'a', latitude: 7, longitude: 80),
      BusLocationModel.fromMap(data('a'))
          .copyWith(isCached: true, addedDelayMinutes: 30),
      BusLocationModel.fromMap(data('a'))
          .copyWith(timestamp: now.subtract(const Duration(minutes: 6))),
    ]) {
      final result = DelayEtaCalculator.calculateArrivalEta(
        bus: bus,
        targetStopIdOrName: 's1',
        liveBusLocation: model,
        currentTime: now,
      );
      expect(result.isLive, isFalse);
      expect(result.addedDelayMinutes, 0);
    }
  });

  testWidgets('live journey explicitly labels saved GPS as unavailable', (
    tester,
  ) async {
    service.acceptAcknowledged(
      BusLocationModel.fromMap(data('a')).copyWith(isCached: true),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: LiveJourneyScreen(busId: 'a', liveBusService: service),
      ),
    );
    await tester.pump();
    db.document('a').events.add(_DocSnapshot('a', data('a')));
    await tester.pump();
    db.document('a').events.addError(StateError('offline'));
    await tester.pump();
    expect(
      find.textContaining('Live GPS updates are unavailable'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });
}

class _Db extends Fake implements FirebaseFirestore {
  final docs = <String, _Doc>{};
  final query = _Query();
  _Doc document(String id) => docs.putIfAbsent(id, () => _Doc(id));
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(this);
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.db);
  final _Db db;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? id]) => db.document(id!);
  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) => db.query;
}

class _Doc extends Fake implements DocumentReference<Map<String, dynamic>> {
  _Doc(this.id);
  @override
  final String id;
  final events =
      StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();
  Future<DocumentSnapshot<Map<String, dynamic>>>? read;
  GetOptions? lastOptions;
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) {
    lastOptions = options;
    return read ?? Future.value(_DocSnapshot(id, null));
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => events.stream;
}

class _Query extends Fake implements Query<Map<String, dynamic>> {
  final events =
      StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => events.stream;
}

class _DocSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  _DocSnapshot(this.id, this.value, {bool cached = false, bool pending = false})
    : metadata = _Metadata(cached, pending);
  @override
  final String id;
  final Map<String, dynamic>? value;
  @override
  bool get exists => value != null;
  @override
  Map<String, dynamic>? data() => value;
  @override
  final SnapshotMetadata metadata;
}

class _QueryDoc extends _DocSnapshot
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _QueryDoc(super.id, Map<String, dynamic> super.value);
  @override
  Map<String, dynamic> data() => value!;
}

class _QuerySnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  _QuerySnapshot(this.docs, {bool cached = false, bool pending = false})
    : metadata = _Metadata(cached, pending);
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  @override
  final SnapshotMetadata metadata;
}

class _Metadata extends Fake implements SnapshotMetadata {
  _Metadata(this.isFromCache, this.hasPendingWrites);
  @override
  final bool isFromCache;
  @override
  final bool hasPendingWrites;
}
