import 'dart:convert';

import 'sample_test_mode.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';

enum CatalogueSource { shared, saved, unavailable, demo }

class CatalogueReceipt {
  const CatalogueReceipt(this.source, this.receivedAt, this.count);
  final CatalogueSource source;
  final DateTime? receivedAt;
  final int count;
}

/// Only acknowledged public catalogue records enter the persistent cache.
class TransitCatalogue {
  static const demo = bool.fromEnvironment('TRANSIT_DEMO', defaultValue: false);
  static final storageKey = SampleTestMode.storage(
    'acknowledged_transit_catalogue_v1',
  );
  static final receipts = ValueNotifier<Map<String, CatalogueReceipt>>({});
  static final _records = <String, Map<String, Map<String, dynamic>>>{};
  static final _status = <String, CatalogueReceipt>{};
  static Future<void>? _loading;
  static bool _fixtures = false;
  static Future<void> _saving = Future.value();

  static void requireSharedWrites() {
    if (demo) {
      throw StateError(
        'Demonstration mode cannot publish or change shared data.',
      );
    }
  }

  static Map<String, Map<String, dynamic>> _samples(String collection) =>
      switch (collection) {
        'buses' => {
          for (final bus in SeedData.sampleBuses) bus.id: bus.toMap(),
        },
        'routes' => {
          for (final route in SeedData.sampleRoutes) route.id: route.toMap(),
        },
        'stations' => {
          for (final station in SeedData.colomboStations)
            station.id: station.toMap(),
        },
        _ => {},
      };

  static bool isDemonstration(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) =>
      data['isDemo'] == true ||
      data['catalogueSource'] == 'demo' ||
      (_samples(collection).containsKey(id) &&
          data['catalogueSource'] != 'operator_catalogue');

  static void requireRealRecord(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) {
    requireSharedWrites();
    if (data['deletionPending'] == true) {
      throw StateError('This catalogue record is pending deletion.');
    }
    if (isDemonstration(collection, id, data)) {
      throw StateError('Demonstration or unreviewed catalogue record.');
    }
  }

  static Map<String, Map<String, dynamic>> cached(String collection) =>
      Map.unmodifiable(
        demo ? _samples(collection) : _records[collection] ?? {},
      );

  static void requireVehicleRecord(String id, Map<String, dynamic> data) {
    requireRealRecord('buses', id, data);
    if (data['catalogueRecordType'] == 'published_timetable') {
      throw StateError(
        'Published timetable has no assigned vehicle or driver.',
      );
    }
  }

  static void _receipt(
    String collection,
    CatalogueSource source, {
    DateTime? time,
  }) {
    _status[collection] = CatalogueReceipt(
      source,
      time ?? _status[collection]?.receivedAt,
      cached(collection).length,
    );
    final next = Map<String, CatalogueReceipt>.from(_status);
    // Catalogue requests can begin while a navigator screen is being built.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback(
        (_) =>
            receipts.value = {...receipts.value, collection: next[collection]!},
      );
    } else {
      receipts.value = next;
    }
  }

  static Future<void> ensureLoaded() => _loading ??= _load();
  static Future<void> _load() async {
    if (demo || _fixtures) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.length > 2 * 1024 * 1024) return;
      final saved = jsonDecode(raw) as Map;
      for (final collection in ['buses', 'routes', 'stations']) {
        final item = saved[collection];
        if (item is! Map || item['records'] is! Map) continue;
        final records = <String, Map<String, dynamic>>{};
        for (final entry in (item['records'] as Map).entries) {
          final data = Map<String, dynamic>.from(entry.value as Map);
          if (!isDemonstration(collection, entry.key as String, data)) {
            records[entry.key] = data;
          }
        }
        _records[collection] = records;
        _receipt(
          collection,
          CatalogueSource.saved,
          time: DateTime.tryParse(item['receivedAt']?.toString() ?? ''),
        );
      }
    } catch (_) {
      /* Invalid cache is unavailable, never replaced with samples. */
    }
  }

  static Object? _jsonValue(Object? value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) {
      return value.map(
        (key, entry) => MapEntry(key.toString(), _jsonValue(entry)),
      );
    }
    if (value is List) return value.map(_jsonValue).toList();
    return value;
  }

  static Future<void> _persist() {
    if (demo || _fixtures) return Future.value();
    final raw = jsonEncode({
      for (final entry in _records.entries)
        entry.key: {
          'records': _jsonValue(entry.value),
          'receivedAt': _status[entry.key]?.receivedAt?.toIso8601String(),
        },
    });
    _saving = _saving
        .catchError((_) {})
        .then((_) async {
          final prefs = await SharedPreferences.getInstance();
          if (raw.length <= 2 * 1024 * 1024) {
            await prefs.setString(storageKey, raw);
          } else {
            await prefs.remove(storageKey);
          }
        })
        .catchError((_) {});
    return _saving;
  }

  static void markUnavailable(String collection) => _receipt(
    collection,
    _records.containsKey(collection)
        ? CatalogueSource.saved
        : CatalogueSource.unavailable,
  );

  static Future<void> accept(
    String collection,
    Map<String, Map<String, dynamic>> records, {
    bool replace = true,
  }) async {
    if (demo) return;
    final accepted = Map<String, Map<String, dynamic>>.fromEntries(
      records.entries.where(
        (entry) =>
            entry.value['deletionPending'] != true &&
            !isDemonstration(collection, entry.key, entry.value),
      ),
    );
    _records[collection] = replace
        ? accepted
        : {...?_records[collection], ...accepted};
    for (final entry in records.entries) {
      if (entry.value['deletionPending'] == true) {
        _records[collection]?.remove(entry.key);
      }
    }
    _receipt(
      collection,
      replace
          ? CatalogueSource.shared
          : _status[collection]?.source ?? CatalogueSource.shared,
      time: replace ? DateTime.now() : null,
    );
    await _persist();
  }

  static Future<void> remove(String collection, String id) async {
    _records[collection]?.remove(id);
    _receipt(collection, _status[collection]?.source ?? CatalogueSource.shared);
    await _persist();
  }

  static Future<Map<String, Map<String, dynamic>>> read(
    String collection,
    Future<QuerySnapshot<Map<String, dynamic>>> Function() fetch,
  ) async {
    if (demo) {
      _receipt(collection, CatalogueSource.demo);
      return cached(collection);
    }
    if (!_fixtures) await ensureLoaded();
    try {
      final snapshot = await fetch().timeout(const Duration(seconds: 8));
      if (snapshot.metadata.isFromCache || snapshot.metadata.hasPendingWrites) {
        throw StateError('Unacknowledged catalogue');
      }
      await accept(collection, {
        for (final doc in snapshot.docs) doc.id: doc.data(),
      });
    } catch (_) {
      markUnavailable(collection);
    }
    return cached(collection);
  }

  static Future<Map<String, dynamic>?> readDocument(
    String collection,
    String id,
    Future<DocumentSnapshot<Map<String, dynamic>>> Function() fetch,
  ) async {
    if (demo) return cached(collection)[id];
    if (!_fixtures) await ensureLoaded();
    try {
      final snapshot = await fetch().timeout(const Duration(seconds: 8));
      if (snapshot.metadata.isFromCache || snapshot.metadata.hasPendingWrites) {
        throw StateError('Unacknowledged catalogue');
      }
      final data = snapshot.data();
      if (snapshot.exists &&
          data != null &&
          !isDemonstration(collection, id, data)) {
        await accept(collection, {id: data}, replace: false);
      } else {
        await remove(collection, id);
      }
    } catch (_) {
      markUnavailable(collection);
    }
    return cached(collection)[id];
  }

  @visibleForTesting
  static void installFixtures(
    Map<String, Map<String, Map<String, dynamic>>> records,
  ) {
    _fixtures = true;
    _status.clear();
    _records.clear();
    _records.addAll(records);
    _loading = Future.value();
  }

  @visibleForTesting
  static void resetMemoryForTesting() {
    _fixtures = false;
    _records.clear();
    _status.clear();
    _loading = null;
    receipts.value = {};
  }
}
