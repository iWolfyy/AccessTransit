// ignore_for_file: subtype_of_sealed_class
import 'package:access_transit/services/transit_catalogue.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/screens/journey/journey_search_screen.dart';
import 'package:access_transit/widgets/catalogue_notice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Metadata extends Fake implements SnapshotMetadata {
  _Metadata({this.hasPendingWrites = false, this.isFromCache = false});
  @override
  final bool hasPendingWrites;
  @override
  final bool isFromCache;
}

class _Doc extends Fake implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _Doc(this.id, this.value, {this.exists = true});
  @override
  final String id;
  final Map<String, dynamic> value;
  @override
  final bool exists;
  @override
  Map<String, dynamic> data() => value;
  @override
  SnapshotMetadata get metadata => _Metadata();
}

class _Query extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  _Query(
    Map<String, Map<String, dynamic>> records, {
    bool pending = false,
    bool cached = false,
  }) : docs = records.entries
           .map((entry) => _Doc(entry.key, entry.value))
           .toList(),
       metadata = _Metadata(hasPendingWrites: pending, isFromCache: cached);
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  @override
  final SnapshotMetadata metadata;
}

class _CatalogueDb extends Fake implements FirebaseFirestore {
  final requested = <String>[];
  bool offline = false;
  final data = <String, Map<String, Map<String, dynamic>>>{
    'stations': {
      'a': {'name': 'A'},
      'b': {'name': 'B'},
    },
    'routes': {
      'route': {
        'routeNo': '1',
        'stops': ['a', 'b'],
      },
    },
    'buses': {
      'bus': {
        'routeNo': '1',
        'stops': ['a', 'b'],
        'scheduleTimes': ['10:30', '11:00'],
      },
    },
  };
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _CatalogueCollection(this, collectionPath);
}

class _CatalogueCollection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _CatalogueCollection(this.db, this.name);
  final _CatalogueDb db;
  final String name;
  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    expect(options?.source, Source.server);
    db.requested.add(name);
    if (db.offline) throw StateError('offline');
    return _Query(db.data[name]!);
  }
}

void main() {
  final checkedAt = DateTime(2026, 10, 15, 12);
  Map<String, dynamic> vehicle() => {
    'hasRamp': true,
    'lowFloor': true,
    'rampOk': true,
    'rampCheckedAt': Timestamp.fromDate(checkedAt),
    'rampCheckedBy': 'observer',
  };
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TransitCatalogue.resetMemoryForTesting();
  });
  testWidgets(
    'Plan refreshes all saved collections and clears the global saved notice',
    (tester) async {
      final db = _CatalogueDb();
      TransitCatalogue.installFixtures(db.data);
      for (final collection in db.data.keys) {
        TransitCatalogue.markUnavailable(collection);
      }
      expect(
        TransitCatalogue.receipts.value.values.every(
          (r) => r.source == CatalogueSource.saved,
        ),
        isTrue,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              const CatalogueNotice(),
              Expanded(
                child: JourneySearchScreen(
                  service: FirestoreService(firestore: db),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(db.requested, unorderedEquals(['stations', 'routes', 'buses']));
      expect(
        TransitCatalogue.receipts.value.values.every(
          (r) => r.source == CatalogueSource.shared,
        ),
        isTrue,
      );
      expect(find.textContaining('Saved transit data'), findsNothing);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'saved notice does not claim connection failure and Refresh recovers all collections',
    (tester) async {
      final db = _CatalogueDb();
      TransitCatalogue.installFixtures(db.data);
      for (final collection in db.data.keys) {
        TransitCatalogue.markUnavailable(collection);
      }
      final service = FirestoreService(firestore: db);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CatalogueNotice(onRefresh: service.refreshCatalogue),
          ),
        ),
      );
      expect(find.textContaining('updates unavailable'), findsNothing);
      expect(find.text('Refresh'), findsOneWidget);
      db.offline = true;
      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Saved transit data'), findsOneWidget);
      expect(TransitCatalogue.cached('buses').keys, ['bus']);
      db.offline = false;
      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Saved transit data'), findsNothing);
      expect(
        TransitCatalogue.receipts.value.values.every(
          (r) => r.source == CatalogueSource.shared,
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'first offline launch has no catalogue or fabricated services',
    () async {
      final records = await TransitCatalogue.read(
        'buses',
        () async => throw StateError('offline'),
      );
      expect(records, isEmpty);
      expect(
        TransitCatalogue.receipts.value['buses']!.source,
        CatalogueSource.unavailable,
      );
      expect(await FirestoreService().getStations(), isEmpty);
      expect(await FirestoreService().getRoutes(), isEmpty);
    },
  );
  test('failed reads retain only acknowledged cache with original observation dates', () async {
    await TransitCatalogue.read(
      'buses',
      () async => _Query({'real': vehicle()}),
    );
    await TransitCatalogue.read(
      'buses',
      () async => throw StateError('offline'),
    );
    expect(
      TransitCatalogue.receipts.value['buses']!.source,
      CatalogueSource.saved,
    );
    expect(
      Bus.fromMap(TransitCatalogue.cached('buses')['real']!).rampCheckedAt,
      checkedAt,
    );
  });
  test(
    'disk reload retains acknowledgement and original ramp check time',
    () async {
      await TransitCatalogue.read(
        'buses',
        () async => _Query({'real': vehicle()}),
      );
      final received = TransitCatalogue.receipts.value['buses']!.receivedAt;
      TransitCatalogue.resetMemoryForTesting();
      await TransitCatalogue.ensureLoaded();
      expect(
        Bus.fromMap(TransitCatalogue.cached('buses')['real']!).rampCheckedAt,
        checkedAt,
      );
      expect(TransitCatalogue.receipts.value['buses']!.receivedAt, received);
      expect(
        TransitCatalogue.receipts.value['buses']!.source,
        CatalogueSource.saved,
      );
    },
  );
  test(
    'authoritative empty catalogue removes old services and survives restart',
    () async {
      await TransitCatalogue.read(
        'buses',
        () async => _Query({'real': vehicle()}),
      );
      expect(
        await TransitCatalogue.read('buses', () async => _Query({})),
        isEmpty,
      );
      TransitCatalogue.resetMemoryForTesting();
      await TransitCatalogue.ensureLoaded();
      expect(TransitCatalogue.cached('buses'), isEmpty);
    },
  );
  test(
    'pending and SDK cached snapshots cannot replace acknowledged data',
    () async {
      await TransitCatalogue.read(
        'buses',
        () async => _Query({'real': vehicle()}),
      );
      for (final snapshot in [
        _Query({'pending': vehicle()}, pending: true),
        _Query({}, cached: true),
      ]) {
        expect(
          (await TransitCatalogue.read('buses', () async => snapshot)).keys,
          ['real'],
        );
      }
    },
  );
  test('marked samples and known legacy seed IDs need explicit administrator review', () async {
    final records = await TransitCatalogue.read(
      'buses',
      () async => _Query({
        'demo': {...vehicle(), 'isDemo': true},
        'marked': {...vehicle(), 'catalogueSource': 'demo'},
        'bus_138_nd4521': vehicle(),
        'real': vehicle(),
      }),
    );
    expect(records.keys, ['real']);
    final reviewed = await TransitCatalogue.read(
      'buses',
      () async => _Query({
        'bus_138_nd4521': {
          ...vehicle(),
          'catalogueSource': 'operator_catalogue',
        },
      }),
    );
    expect(reviewed.keys, ['bus_138_nd4521']);
  });
  test('authoritative document deletion invalidates a saved service', () async {
    await TransitCatalogue.read(
      'buses',
      () async => _Query({'real': vehicle()}),
    );
    final deleted = await TransitCatalogue.readDocument(
      'buses',
      'real',
      () async => _Doc('real', {}, exists: false),
    );
    expect(deleted, isNull);
    expect(TransitCatalogue.cached('buses'), isEmpty);
  });
  test(
    'single service receipt cannot refresh the entire saved catalogue',
    () async {
      await TransitCatalogue.read(
        'buses',
        () async => _Query({'real': vehicle(), 'other': vehicle()}),
      );
      final received = TransitCatalogue.receipts.value['buses']!.receivedAt;
      TransitCatalogue.markUnavailable('buses');
      await TransitCatalogue.readDocument(
        'buses',
        'real',
        () async => _Doc('real', vehicle()),
      );
      expect(TransitCatalogue.receipts.value['buses']!.receivedAt, received);
      expect(
        TransitCatalogue.receipts.value['buses']!.source,
        CatalogueSource.saved,
      );
    },
  );
  testWidgets(
    'empty search has no substituted stops or popular accessible routes',
    (tester) async {
      TransitCatalogue.installFixtures({
        'stations': {},
        'buses': {},
        'routes': {},
      });
      await tester.pumpWidget(const MaterialApp(home: JourneySearchScreen()));
      await tester.pumpAndSettle();
      expect(
        find.text('No shared stops available. Connect and retry.'),
        findsOneWidget,
      );
      expect(find.text('Popular Accessible Routes'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'catalogue notice distinguishes unavailable, saved and empty shared data',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CatalogueNotice())),
      );
      TransitCatalogue.markUnavailable('buses');
      await tester.pump();
      expect(find.textContaining('Transit data unavailable'), findsOneWidget);
      TransitCatalogue.receipts.value = {
        'buses': CatalogueReceipt(CatalogueSource.saved, checkedAt, 1),
      };
      await tester.pump();
      expect(find.textContaining('Saved transit data'), findsOneWidget);
      TransitCatalogue.receipts.value = {
        'buses': CatalogueReceipt(CatalogueSource.shared, checkedAt, 0),
      };
      await tester.pump();
      expect(find.textContaining('No shared transit data'), findsOneWidget);
    },
  );
}
