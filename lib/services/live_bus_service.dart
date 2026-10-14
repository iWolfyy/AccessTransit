import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
  }) : _customFirestore = firestore,
       _collectionName =
           collectionName ?? FirestoreConstants.liveLocationsCollection;

  final Future<BusLocationModel> Function(String, Map<String, dynamic>)?
  telemetryWriter;
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

  /// Last acknowledged observations, never unsent local GPS fixes.
  static final Map<String, BusLocationModel> _localLocationsFallback = {};
  static final StreamController<Map<String, BusLocationModel>>
  _localLocationsStreamController =
      StreamController<Map<String, BusLocationModel>>.broadcast();

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
    final writer = telemetryWriter;
    if (writer != null) {
      acceptAcknowledged(await writer(busLocation.busId, busLocation.toMap()));
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
    _localLocationsFallback[model.busId] = model;
    _localLocationsStreamController.add(
      Map.unmodifiable(_localLocationsFallback),
    );
  }

  Future<void> _refreshAcknowledged(
    DocumentReference<Map<String, dynamic>> doc,
  ) async {
    // A write receipt does not establish the exact server observation timestamp.
    // If this read fails, retain the previous observation until its stream updates.
    try {
      final snapshot = await doc
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 3));
      if (!snapshot.metadata.hasPendingWrites && snapshot.exists) {
        acceptAcknowledged(
          BusLocationModel.fromMap(snapshot.data()!, documentId: snapshot.id),
        );
      }
    } catch (_) {}
  }

  Future<void> _writeFields(
    String busId,
    Map<String, dynamic> fields, {
    String? expectedTripId,
  }) async {
    if (telemetryWriter != null) {
      acceptAcknowledged(await telemetryWriter!(busId, fields));
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
    late final StreamController<BusLocationModel?> controller;
    StreamSubscription? firestoreSub;
    StreamSubscription? localSub;

    controller = StreamController<BusLocationModel?>.broadcast(
      onListen: () {
        controller.add(_localLocationsFallback[busId]);

        localSub = _localLocationsStreamController.stream.listen((map) {
          controller.add(map[busId]);
        });

        final doc = liveLocationDoc(busId);
        if (doc != null) {
          try {
            firestoreSub = doc
                .snapshots(includeMetadataChanges: true)
                .listen(
                  (snapshot) {
                    if (snapshot.metadata.hasPendingWrites) return;
                    if (snapshot.exists && snapshot.data() != null) {
                      final model = BusLocationModel.fromMap(
                        snapshot.data()!,
                        documentId: snapshot.id,
                      );
                      _localLocationsFallback[busId] = model;
                      controller.add(model);
                    } else if (!snapshot.metadata.isFromCache) {
                      _localLocationsFallback.remove(busId);
                      controller.add(null);
                    } else {
                      controller.add(_localLocationsFallback[busId]);
                    }
                  },
                  onError: (dynamic e) {
                    debugPrint('LiveBusService.listenToLiveLocation error: $e');
                  },
                );
          } catch (e) {
            debugPrint('LiveBusService.listenToLiveLocation fallback: $e');
          }
        }
      },
      onCancel: () {
        localSub?.cancel();
        firestoreSub?.cancel();
      },
    );

    return controller.stream;
  }

  /// Fetches a one-time snapshot of a bus's live location.
  Future<BusLocationModel?> getLiveLocation(String busId) async {
    try {
      final doc = liveLocationDoc(busId);
      if (doc != null) {
        final snapshot = await doc.get();
        if (snapshot.metadata.hasPendingWrites) {
          return _localLocationsFallback[busId];
        }
        if (snapshot.exists && snapshot.data() != null) {
          final model = BusLocationModel.fromMap(
            snapshot.data()!,
            documentId: snapshot.id,
          );
          _localLocationsFallback[busId] = model;
          return model;
        }
        if (!snapshot.metadata.isFromCache) {
          _localLocationsFallback.remove(busId);
          return null;
        }
      }
    } catch (e) {
      debugPrint('LiveBusService.getLiveLocation fallback: $e');
    }
    return _localLocationsFallback[busId];
  }

  /// Listens to real-time streams of all active broadcasting buses.
  Stream<List<BusLocationModel>> listenToAllActiveBuses() {
    late final StreamController<List<BusLocationModel>> controller;
    StreamSubscription? firestoreSub;
    StreamSubscription? localSub;

    controller = StreamController<List<BusLocationModel>>.broadcast(
      onListen: () {
        controller.add(
          _localLocationsFallback.values
              .where((b) => b.isBroadcasting)
              .toList(),
        );

        localSub = _localLocationsStreamController.stream.listen((map) {
          controller.add(map.values.where((b) => b.isBroadcasting).toList());
        });

        final col = _liveLocationsCollection;
        if (col != null) {
          try {
            firestoreSub = col
                .where(FirestoreConstants.fieldIsBroadcasting, isEqualTo: true)
                .snapshots(includeMetadataChanges: true)
                .listen(
                  (snapshot) {
                    if (snapshot.metadata.hasPendingWrites) return;
                    final list = snapshot.docs
                        .map(
                          (doc) => BusLocationModel.fromMap(
                            doc.data(),
                            documentId: doc.id,
                          ),
                        )
                        .toList();
                    if (!snapshot.metadata.isFromCache) {
                      final ids = list.map((b) => b.busId).toSet();
                      _localLocationsFallback.removeWhere(
                        (id, b) => b.isBroadcasting && !ids.contains(id),
                      );
                    }
                    for (final b in list) {
                      _localLocationsFallback[b.busId] = b;
                    }
                    controller.add(list);
                  },
                  onError: (dynamic e) {
                    debugPrint(
                      'LiveBusService.listenToAllActiveBuses error: $e',
                    );
                  },
                );
          } catch (e) {
            debugPrint('LiveBusService.listenToAllActiveBuses fallback: $e');
          }
        }
      },
      onCancel: () {
        localSub?.cancel();
        firestoreSub?.cancel();
      },
    );

    return controller.stream;
  }

  /// 6. Detect whether a bus location is stale/offline based on its timestamp.
  ///
  /// Returns `true` if [timestamp] is `null` or older than [threshold] (defaults to 5 minutes).
  bool isLocationStale(
    DateTime? timestamp, {
    Duration threshold = const Duration(minutes: 5),
  }) {
    if (timestamp == null) return true;
    final now = DateTime.now();
    return timestamp.isAfter(now) || now.difference(timestamp) > threshold;
  }

  /// Detects whether a [BusLocationModel] is stale or offline.
  ///
  /// Returns `true` if the bus status is offline/completed or its timestamp is stale.
  bool isBusStale(
    BusLocationModel busLocation, {
    Duration threshold = const Duration(minutes: 5),
  }) {
    if (busLocation.status == BusStatus.offline ||
        busLocation.status == BusStatus.completed) {
      return true;
    }
    return isLocationStale(busLocation.timestamp, threshold: threshold);
  }
}
