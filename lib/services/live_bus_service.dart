import 'transit_catalogue.dart';

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_constants.dart';
import '../models/bus_location_model.dart';
import '../models/enums/bus_status.dart';

/// Reusable Firestore service for real-time live bus telemetry and location tracking.
///
/// Documents are stored in Firestore under `live_locations/{busId}`.
class LiveBusService {
  /// Initializes [LiveBusService] with optional custom [FirebaseFirestore]
  /// or [collectionName] (defaults to [FirestoreConstants.liveLocationsCollection]).
  LiveBusService({
    FirebaseFirestore? firestore,
    String? collectionName,
    this.telemetryWriter,
    this.clock,
  }) : _customFirestore = firestore,
       _collectionName =
           collectionName ?? FirestoreConstants.liveLocationsCollection;

  final Future<BusLocationModel> Function(String, Map<String, dynamic>)?
  telemetryWriter;
  final DateTime Function()? clock;
  DateTime get _now => clock?.call() ?? DateTime.now();
  final FirebaseFirestore? _customFirestore;
  final String _collectionName;

  FirebaseFirestore? get _db {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Shared state is partitioned by collection. Signals contain no old snapshot
  /// payload: listeners always read the current cache after an invalidation.
  static final _caches = <String, Map<String, BusLocationModel>>{};
  static final _activeEpoch = <String, int>{};
  String _token(String id) =>
      '${_activeEpoch[_collectionName] ?? 0}:${_revision(id)}';
  static final _versions = <String, Map<String, int>>{};
  static final _changes = StreamController<String>.broadcast();
  Map<String, BusLocationModel> get _cache =>
      _caches.putIfAbsent(_collectionName, () => {});
  Map<String, int> get _revisions =>
      _versions.putIfAbsent(_collectionName, () => {});
  int _revision(String id) => _revisions[id] ?? 0;
  void _changed(Iterable<String> ids) {
    for (final id in ids) {
      _revisions[id] = _revision(id) + 1;
    }
    _changes.add(_collectionName);
  }

  void _invalidate(String id) {
    _cache.remove(id);
    _changed([id]);
  }

  void _saved([String? id]) {
    final ids = id == null ? _cache.keys.toList() : [id];
    final changed = <String>[];
    for (final key in ids) {
      final prior = _cache[key];
      if (prior != null && !prior.isCached) {
        _cache[key] = prior.copyWith(isCached: true);
        changed.add(key);
      }
    }
    if (changed.isNotEmpty) _changed(changed);
  }

  /// Collection reference for live bus locations (`live_locations`).
  CollectionReference<Map<String, dynamic>>? get _liveLocationsCollection =>
      _db?.collection(_collectionName);

  /// Document reference for a specific bus ID (`live_locations/{busId}`).
  DocumentReference<Map<String, dynamic>>? liveLocationDoc(String busId) {
    return _liveLocationsCollection?.doc(busId);
  }

  /// 1. Start/update a bus's live location document in Firestore.
  ///
  /// Creates or merges full bus telemetry data into `live_locations/{busId}`.
  Future<void> startOrUpdateLiveLocation(BusLocationModel busLocation) async {
    TransitCatalogue.requireSharedWrites();
    final writer = telemetryWriter;
    if (writer != null) {
      final version = _token(busLocation.busId);
      final acknowledged = await writer(busLocation.busId, busLocation.toMap());
      if (_token(busLocation.busId) == version) {
        acceptAcknowledged(acknowledged);
      }
      return;
    }
    final doc = liveLocationDoc(busLocation.busId);
    if (doc == null) throw StateError('Shared telemetry is unavailable');
    await _db!
        .runTransaction((tx) async {
          final snapshot = await tx.get(doc);
          final data = snapshot.data();
          if (data == null ||
              data['isBroadcasting'] != true ||
              data['tripId'] is! String) {
            throw StateError('Start the shared trip before updating telemetry');
          }
          tx.update(doc, {
            'latitude': busLocation.latitude,
            'longitude': busLocation.longitude,
            'speed': busLocation.speed,
            'heading': busLocation.heading,
            'timestamp': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
            'rampOperational': ?busLocation.rampOperational,
            'occupancyLevel': busLocation.occupancyLevel,
          });
        })
        .timeout(const Duration(seconds: 12));
    await _refreshAcknowledged(doc);
  }

  /// Only committed telemetry belongs in the passenger cache.
  void acceptAcknowledged(BusLocationModel model) {
    _cache[model.busId] = model.copyWith(isCached: false);
    _changed([model.busId]);
  }

  void _acceptDocument(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    if (!snapshot.exists || snapshot.data() == null) {
      _invalidate(snapshot.id);
      return;
    }
    final model = BusLocationModel.fromMap(
      snapshot.data()!,
      documentId: snapshot.id,
    );
    if (model.busId != snapshot.id) {
      _invalidate(snapshot.id);
      return;
    }
    acceptAcknowledged(model);
  }

  Future<void> _refreshAcknowledged(
    DocumentReference<Map<String, dynamic>> doc,
  ) async {
    final version = _token(doc.id);
    try {
      final snapshot = await doc
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 3));
      if (_token(doc.id) != version) return;
      if (snapshot.metadata.hasPendingWrites) return;
      if (snapshot.metadata.isFromCache) {
        _saved(doc.id);
        return;
      }
      _acceptDocument(snapshot);
    } catch (_) {
      if (_token(doc.id) == version) _saved(doc.id);
    }
  }

  Future<void> _writeFields(
    String busId,
    Map<String, dynamic> fields, {
    String? expectedTripId,
  }) async {
    TransitCatalogue.requireSharedWrites();
    if (telemetryWriter != null) {
      final version = _token(busId);
      final acknowledged = await telemetryWriter!(busId, fields);
      if (_token(busId) == version) acceptAcknowledged(acknowledged);
      return;
    }
    final db = _db;
    final doc = liveLocationDoc(busId);
    if (db == null || doc == null) {
      throw StateError('Shared telemetry is unavailable');
    }
    await db
        .runTransaction((tx) async {
          final snapshot = await tx.get(doc);
          final data = snapshot.data();
          if (data == null ||
              data['isBroadcasting'] != true ||
              (expectedTripId != null && data['tripId'] != expectedTripId)) {
            throw StateError(
              'The broadcasting session changed or ended. Refresh before retrying.',
            );
          }
          tx.update(doc, fields);
        })
        .timeout(const Duration(seconds: 12));
    await _refreshAcknowledged(doc);
  }

  /// Helper to start or initialize a bus's live location session.
  Future<void> startLiveLocation({
    required String busId,
    required String routeId,
    required String driverId,
    required double latitude,
    required double longitude,
    double speed = 0.0,
    double heading = 0.0,
    BusStatus status = BusStatus.active,
    String routeNumber = '',
    String routeName = '',
    String operatorName = 'Transit Operator',
  }) async {
    final busLocation = BusLocationModel(
      busId: busId,
      routeId: routeId,
      driverId: driverId,
      latitude: latitude,
      longitude: longitude,
      speed: speed,
      heading: heading,
      status: status,
      routeNumber: routeNumber.isNotEmpty ? routeNumber : routeId,
      routeName: routeName,
      operatorName: operatorName,
      isBroadcasting: status == BusStatus.active,
    );

    await startOrUpdateLiveLocation(busLocation);
  }

  /// 2. Update only the required location fields efficiently.
  ///
  /// Updates only coordinates ([latitude], [longitude]), motion telemetry
  /// ([speed], [heading]), and server timestamps without overwriting other fields.
  Future<void> updateLocationOnly({
    required String busId,
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
    String? expectedTripId,
  }) async {
    await _writeFields(busId, {
      'latitude': latitude,
      'longitude': longitude,
      'speed': ?speed,
      'heading': ?heading,
      'timestamp': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, expectedTripId: expectedTripId);
  }

  Future<void> updateNextStop({
    required String busId,
    required String nextStop,
    int? currentStopIndex,
    int? etaMinutes,
  }) async {
    await _writeFields(busId, {
      'nextStop': nextStop,
      'currentStopIndex': ?currentStopIndex,
      'etaMinutes': ?etaMinutes,
    });
  }

  Future<void> reportDelay({
    required String busId,
    required String reason,
    required int delayMinutes,
  }) async {
    await _writeFields(busId, {
      'delayReason': reason,
      'addedDelayMinutes': delayMinutes,
    });
  }

  Future<void> clearDelay(String busId) async {
    await _writeFields(busId, {
      'delayReason': FieldValue.delete(),
      'addedDelayMinutes': 0,
    });
  }

  Future<void> updateEquipment(
    String busId, {
    bool? rampOperational,
    String? occupancyLevel,
  }) async {
    await _writeFields(busId, {
      'rampOperational': ?rampOperational,
      'occupancyLevel': ?occupancyLevel,
    });
  }

  Future<void> updateBusStatus(String busId, BusStatus status) async {
    await _writeFields(busId, {
      'status': status.value,
      'isBroadcasting': status == BusStatus.active,
    });
  }

  Future<void> stopTrip(
    String busId, {
    BusStatus endStatus = BusStatus.completed,
  }) async {
    await _writeFields(busId, {
      'status': endStatus.value,
      'isBroadcasting': false,
      'delayReason': FieldValue.delete(),
      'addedDelayMinutes': 0,
    });
  }

  /// Alias for [stopTrip] to support trip ending terminology.
  Future<void> endTrip(
    String busId, {
    BusStatus endStatus = BusStatus.completed,
  }) async {
    await stopTrip(busId, endStatus: endStatus);
  }

  /// 5. Listen to a specific bus's live location in real time.
  ///
  /// Returns a stream of [BusLocationModel] or null if the document does not exist.
  Stream<BusLocationModel?> listenToLiveLocation(String busId) {
    if (TransitCatalogue.demo) return Stream.value(null);
    late StreamController<BusLocationModel?> controller;
    StreamSubscription? remote;
    StreamSubscription? local;
    Timer? timer;
    var listening = false;
    var initialRevision = 0;
    void emit({bool initial = false}) {
      if (!listening) return;
      timer?.cancel();
      final model = _cache[busId];
      controller.add(
        initial || _revision(busId) == initialRevision
            ? model?.copyWith(isCached: true)
            : model,
      );
      final delay = _expiryDelay([?model]);
      if (delay != null) timer = Timer(delay, emit);
    }

    void unavailable() {
      _saved(busId);
    }

    controller = StreamController<BusLocationModel?>.broadcast(
      onListen: () {
        listening = true;
        initialRevision = _revision(busId);
        emit(initial: true);
        local = _changes.stream
            .where((name) => name == _collectionName)
            .listen((_) => emit());
        final doc = liveLocationDoc(busId);
        if (doc == null) {
          unavailable();
          return;
        }
        try {
          remote = doc
              .snapshots(includeMetadataChanges: true)
              .listen(
                (snapshot) {
                  if (!listening || snapshot.metadata.hasPendingWrites) return;
                  if (snapshot.metadata.isFromCache) {
                    unavailable();
                    return;
                  }
                  try {
                    _acceptDocument(snapshot);
                  } catch (_) {
                    unavailable();
                  }
                },
                onError: (Object error) {
                  if (listening) unavailable();
                },
              );
        } catch (_) {
          unavailable();
        }
      },
      onCancel: () async {
        listening = false;
        timer?.cancel();
        await local?.cancel();
        await remote?.cancel();
      },
    );
    return controller.stream;
  }

  /// Server-only receipt; a failed/offline read may return labelled saved data.
  Future<BusLocationModel?> getLiveLocation(String busId) async {
    if (TransitCatalogue.demo) return null;
    final version = _token(busId);
    try {
      final doc = liveLocationDoc(busId);
      if (doc == null) {
        _saved(busId);
        return _cache[busId];
      }
      final snapshot = await doc
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));
      if (_token(busId) != version) return _cache[busId];
      if (snapshot.metadata.hasPendingWrites) return _cache[busId];
      if (snapshot.metadata.isFromCache) {
        _saved(busId);
        return _cache[busId];
      }
      _acceptDocument(snapshot);
    } catch (_) {
      if (_token(busId) == version) _saved(busId);
    }
    return _cache[busId];
  }

  Stream<List<BusLocationModel>> listenToAllActiveBuses() {
    if (TransitCatalogue.demo) return Stream.value([]);
    late StreamController<List<BusLocationModel>> controller;
    StreamSubscription? remote;
    StreamSubscription? local;
    Timer? timer;
    var listening = false;
    var initialRevisions = <String, int>{};
    void emit({bool initial = false}) {
      if (!listening) return;
      timer?.cancel();
      final models = _cache.values.where((b) => b.isBroadcasting).toList();
      controller.add(
        models
            .map(
              (model) =>
                  initial ||
                      _revision(model.busId) ==
                          (initialRevisions[model.busId] ?? 0)
                  ? model.copyWith(isCached: true)
                  : model,
            )
            .toList(),
      );
      final delay = _expiryDelay(models);
      if (delay != null) timer = Timer(delay, emit);
    }

    void unavailable() {
      _saved();
    }

    controller = StreamController<List<BusLocationModel>>.broadcast(
      onListen: () {
        listening = true;
        initialRevisions = Map.of(_revisions);
        emit(initial: true);
        local = _changes.stream
            .where((name) => name == _collectionName)
            .listen((_) => emit());
        final col = _liveLocationsCollection;
        if (col == null) {
          unavailable();
          return;
        }
        try {
          remote = col
              .where(FirestoreConstants.fieldIsBroadcasting, isEqualTo: true)
              .snapshots(includeMetadataChanges: true)
              .listen(
                (snapshot) {
                  if (!listening || snapshot.metadata.hasPendingWrites) return;
                  // SDK cache snapshots never resurrect records after an authoritative removal.
                  if (snapshot.metadata.isFromCache) {
                    unavailable();
                    return;
                  }
                  _activeEpoch[_collectionName] =
                      (_activeEpoch[_collectionName] ?? 0) + 1;
                  final records = <String, BusLocationModel>{};
                  for (final doc in snapshot.docs) {
                    try {
                      final model = BusLocationModel.fromMap(
                        doc.data(),
                        documentId: doc.id,
                      );
                      if (model.busId == doc.id && model.isBroadcasting) {
                        records[doc.id] = model;
                      }
                    } catch (_) {
                      /* Invalid remote records cannot establish tracking. */
                    }
                  }
                  final removed = _cache.entries
                      .where(
                        (e) =>
                            e.value.isBroadcasting &&
                            !records.containsKey(e.key),
                      )
                      .map((e) => e.key)
                      .toList();
                  for (final id in removed) {
                    _cache.remove(id);
                  }
                  _cache.addAll(records);
                  _changed({...removed, ...records.keys});
                },
                onError: (Object error) {
                  if (listening) unavailable();
                },
              );
        } catch (_) {
          unavailable();
        }
      },
      onCancel: () async {
        listening = false;
        timer?.cancel();
        await local?.cancel();
        await remote?.cancel();
      },
    );
    return controller.stream;
  }

  /// Wake visible tracking at its five-minute expiry even without remote events.
  Duration? _expiryDelay(Iterable<BusLocationModel> models) {
    Duration? next;
    for (final model in models) {
      if (isBusStale(model) ||
          !model.isBroadcasting ||
          model.timestamp == null) {
        continue;
      }
      var delay = model.timestamp!
          .add(const Duration(minutes: 5, milliseconds: 1))
          .difference(_now);
      if (delay > const Duration(minutes: 1)) {
        delay = const Duration(minutes: 1);
      }
      if (delay < const Duration(milliseconds: 1)) {
        delay = const Duration(milliseconds: 1);
      }
      if (next == null || delay < next) next = delay;
    }
    return next;
  }

  /// 6. Detect whether a bus location is stale/offline based on its timestamp.
  ///
  /// Returns `true` if [timestamp] is `null` or older than [threshold] (defaults to 5 minutes).
  bool isLocationStale(
    DateTime? timestamp, {
    Duration threshold = const Duration(minutes: 5),
  }) {
    if (timestamp == null) return true;
    final now = _now;
    return timestamp.isAfter(now) || now.difference(timestamp) > threshold;
  }

  /// Detects whether a [BusLocationModel] is stale or offline.
  ///
  /// Returns `true` if the bus status is offline/completed or its timestamp is stale.
  bool isBusStale(
    BusLocationModel busLocation, {
    Duration threshold = const Duration(minutes: 5),
  }) {
    if (busLocation.isCached ||
        !busLocation.isBroadcasting ||
        busLocation.status == BusStatus.offline ||
        busLocation.status == BusStatus.completed) {
      return true;
    }
    return isLocationStale(busLocation.timestamp, threshold: threshold);
  }
}
