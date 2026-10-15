// ignore_for_file: subtype_of_sealed_class
import 'dart:async';

import 'package:access_transit/services/firestore_service.dart';
import 'package:access_transit/services/transit_catalogue.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Metadata extends Fake implements SnapshotMetadata {
  _Metadata({this.isFromCache = false, this.hasPendingWrites = false});
  @override
  final bool isFromCache;
  @override
  final bool hasPendingWrites;
}

class _Snapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot({bool cached = false, bool pending = false})
    : metadata = _Metadata(isFromCache: cached, hasPendingWrites: pending);
  @override
  final SnapshotMetadata metadata;
  @override
  bool get exists => true;
  @override
  Map<String, dynamic> data() => {'routeId': 'route'};
}

class _Document extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final events = StreamController<DocumentSnapshot<Map<String, dynamic>>>();
  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => events.stream;
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final document = _Document();
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => document;
}

class _Database extends Fake implements FirebaseFirestore {
  final buses = _Collection();
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    expect(collectionPath, 'buses');
    return buses;
  }
}

void main() {
  test(
    'opening a bus preserves a shared catalogue; later disconnect stays saved',
    () async {
      SharedPreferences.setMockInitialValues({});
      TransitCatalogue.resetMemoryForTesting();
      await TransitCatalogue.ensureLoaded();
      await TransitCatalogue.accept('buses', {
        'bus': {'routeId': 'route'},
      });
      final receipt = TransitCatalogue.receipts.value['buses']!.receivedAt;
      final db = _Database();
      final subscription = FirestoreService(firestore: db)
          .streamBusById('bus')
          .listen((_) {});
      Future<void> settle() =>
          Future<void>.delayed(const Duration(milliseconds: 20));
      await settle();
      db.buses.document.events.add(_Snapshot(cached: true));
      await settle();
      expect(
        TransitCatalogue.receipts.value['buses']!.source,
        CatalogueSource.shared,
      );
      db.buses.document.events.add(_Snapshot());
      await settle();
      expect(
        TransitCatalogue.receipts.value['buses']!.source,
        CatalogueSource.shared,
      );
      expect(TransitCatalogue.receipts.value['buses']!.receivedAt, receipt);
      db.buses.document.events.add(_Snapshot(pending: true));
      await settle();
      expect(
        TransitCatalogue.receipts.value['buses']!.source,
        CatalogueSource.shared,
      );
      db.buses.document.events.add(_Snapshot(cached: true));
      await settle();
      expect(
        TransitCatalogue.receipts.value['buses']!.source,
        CatalogueSource.saved,
      );
      db.buses.document.events.add(_Snapshot());
      await settle();
      // A single bus cannot renew the entire catalogue after a disconnect.
      expect(
        TransitCatalogue.receipts.value['buses']!.source,
        CatalogueSource.saved,
      );
      await subscription.cancel();
      await db.buses.document.events.close();
    },
  );
}
