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
  })  : _customFirestore = firestore,
        _collectionName =
            collectionName ?? FirestoreConstants.liveLocationsCollection;

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

  /// In-memory cache for live bus locations to ensure tracking works
  /// reliably even when Firestore write permissions or network are restricted.
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
    _localLocationsFallback[busLocation.busId] = busLocation;
    _localLocationsStreamController.add(_localLocationsFallback);

    try {
      final doc = liveLocationDoc(busLocation.busId);
      if (doc != null) {
        await doc.set(
          busLocation.toMap(isServerTimestamp: true),
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      debugPrint('LiveBusService.startOrUpdateLiveLocation warning: $e');
    }
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
  }) async {
    final existing = _localLocationsFallback[busId];
    if (existing != null) {
      final updated = existing.copyWith(
        latitude: latitude,
        longitude: longitude,
        speed: speed ?? existing.speed,
        heading: heading ?? existing.heading,
        timestamp: DateTime.now(),
      );
      _localLocationsFallback[busId] = updated;
      _localLocationsStreamController.add(_localLocationsFallback);
    }

    try {
      final doc = liveLocationDoc(busId);
      if (doc != null) {
        final Map<String, dynamic> updateData = {
          FirestoreConstants.fieldLatitude: latitude,
          FirestoreConstants.fieldLongitude: longitude,
          FirestoreConstants.fieldTimestamp: FieldValue.serverTimestamp(),
          FirestoreConstants.fieldLastUpdated: FieldValue.serverTimestamp(),
        };

        if (speed != null) {
          updateData[FirestoreConstants.fieldSpeed] = speed;
        }
        if (heading != null) {
          updateData[FirestoreConstants.fieldHeading] = heading;
        }

        await doc.set(
          updateData,
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      debugPrint('LiveBusService.updateLocationOnly warning: $e');
    }
  }

  /// 3. Change the bus status.
  ///
  /// Updates [status], updates [isBroadcasting] accordingly, and refreshes the timestamp.
  Future<void> updateBusStatus(String busId, BusStatus status) async {
    final isBroadcasting = status == BusStatus.active;
    final existing = _localLocationsFallback[busId];
    if (existing != null) {
      _localLocationsFallback[busId] = existing.copyWith(
        status: status,
        isBroadcasting: isBroadcasting,
        timestamp: DateTime.now(),
      );
      _localLocationsStreamController.add(_localLocationsFallback);
    }

    try {
      final doc = liveLocationDoc(busId);
      if (doc != null) {
        await doc.set({
          FirestoreConstants.fieldStatus: status.value,
          FirestoreConstants.fieldIsBroadcasting: isBroadcasting,
          FirestoreConstants.fieldTimestamp: FieldValue.serverTimestamp(),
          FirestoreConstants.fieldLastUpdated: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('LiveBusService.updateBusStatus warning: $e');
    }
  }

  /// 4. Stop/end a trip.
  ///
  /// Sets status to [endStatus] (defaults to [BusStatus.completed]),
  /// turns off broadcasting flag, and updates timestamp.
  Future<void> stopTrip(
    String busId, {
    BusStatus endStatus = BusStatus.completed,
  }) async {
    final existing = _localLocationsFallback[busId];
    if (existing != null) {
      _localLocationsFallback[busId] = existing.copyWith(
        status: endStatus,
        isBroadcasting: false,
        timestamp: DateTime.now(),
      );
      _localLocationsStreamController.add(_localLocationsFallback);
    }

    try {
      final doc = liveLocationDoc(busId);
      if (doc != null) {
        await doc.set({
          FirestoreConstants.fieldStatus: endStatus.value,
          FirestoreConstants.fieldIsBroadcasting: false,
          FirestoreConstants.fieldTimestamp: FieldValue.serverTimestamp(),
          FirestoreConstants.fieldLastUpdated: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('LiveBusService.stopTrip warning: $e');
    }
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
  Stream<BusLocationModel?> listenToLiveLocation(String busId) async* {
    if (_localLocationsFallback.containsKey(busId)) {
      yield _localLocationsFallback[busId];
    }

    final doc = liveLocationDoc(busId);
    if (doc != null) {
      try {
        await for (final snapshot in doc.snapshots()) {
          if (snapshot.exists && snapshot.data() != null) {
            final model = BusLocationModel.fromMap(
              snapshot.data()!,
              documentId: snapshot.id,
            );
            _localLocationsFallback[busId] = model;
            yield model;
          } else if (_localLocationsFallback.containsKey(busId)) {
            yield _localLocationsFallback[busId];
          } else {
            yield null;
          }
        }
      } catch (e) {
        debugPrint('LiveBusService.listenToLiveLocation fallback: $e');
        yield _localLocationsFallback[busId];
      }
    } else {
      yield _localLocationsFallback[busId];
    }
  }

  /// Fetches a one-time snapshot of a bus's live location.
  Future<BusLocationModel?> getLiveLocation(String busId) async {
    try {
      final doc = liveLocationDoc(busId);
      if (doc != null) {
        final snapshot = await doc.get();
        if (snapshot.exists && snapshot.data() != null) {
          final model = BusLocationModel.fromMap(
            snapshot.data()!,
            documentId: snapshot.id,
          );
          _localLocationsFallback[busId] = model;
          return model;
        }
      }
    } catch (e) {
      debugPrint('LiveBusService.getLiveLocation fallback: $e');
    }
    return _localLocationsFallback[busId];
  }

  /// Listens to real-time streams of all active broadcasting buses.
  Stream<List<BusLocationModel>> listenToAllActiveBuses() async* {
    yield _localLocationsFallback.values.where((b) => b.isBroadcasting).toList();

    final col = _liveLocationsCollection;
    if (col != null) {
      try {
        await for (final snapshot in col
            .where(FirestoreConstants.fieldIsBroadcasting, isEqualTo: true)
            .snapshots()) {
          final list = snapshot.docs
              .map((doc) => BusLocationModel.fromMap(doc.data(), documentId: doc.id))
              .toList();
          for (final b in list) {
            _localLocationsFallback[b.busId] = b;
          }
          yield list;
        }
      } catch (e) {
        debugPrint('LiveBusService.listenToAllActiveBuses fallback: $e');
        yield _localLocationsFallback.values.where((b) => b.isBroadcasting).toList();
      }
    }
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
    return now.difference(timestamp) > threshold;
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
