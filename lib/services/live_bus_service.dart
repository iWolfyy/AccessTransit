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
  })  : _customFirestore = firestore,
        _collectionName =
            collectionName ?? FirestoreConstants.liveLocationsCollection;

  final FirebaseFirestore? _customFirestore;
  final String _collectionName;

  FirebaseFirestore get _db => _customFirestore ?? FirebaseFirestore.instance;

  /// Collection reference for live bus locations (`live_locations`).
  CollectionReference<Map<String, dynamic>> get _liveLocationsCollection =>
      _db.collection(_collectionName);

  /// Document reference for a specific bus ID (`live_locations/{busId}`).
  DocumentReference<Map<String, dynamic>> liveLocationDoc(String busId) {
    return _liveLocationsCollection.doc(busId);
  }

  /// 1. Start/update a bus's live location document in Firestore.
  ///
  /// Creates or merges full bus telemetry data into `live_locations/{busId}`.
  Future<void> startOrUpdateLiveLocation(BusLocationModel busLocation) async {
    await liveLocationDoc(busLocation.busId).set(
      busLocation.toMap(isServerTimestamp: true),
      SetOptions(merge: true),
    );
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

    await liveLocationDoc(busId).set(
      updateData,
      SetOptions(merge: true),
    );
  }

  /// 3. Change the bus status.
  ///
  /// Updates [status], updates [isBroadcasting] accordingly, and refreshes the timestamp.
  Future<void> updateBusStatus(String busId, BusStatus status) async {
    final isBroadcasting = status == BusStatus.active;
    await liveLocationDoc(busId).set({
      FirestoreConstants.fieldStatus: status.value,
      FirestoreConstants.fieldIsBroadcasting: isBroadcasting,
      FirestoreConstants.fieldTimestamp: FieldValue.serverTimestamp(),
      FirestoreConstants.fieldLastUpdated: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 4. Stop/end a trip.
  ///
  /// Sets status to [endStatus] (defaults to [BusStatus.completed]),
  /// turns off broadcasting flag, and updates timestamp.
  Future<void> stopTrip(
    String busId, {
    BusStatus endStatus = BusStatus.completed,
  }) async {
    await liveLocationDoc(busId).set({
      FirestoreConstants.fieldStatus: endStatus.value,
      FirestoreConstants.fieldIsBroadcasting: false,
      FirestoreConstants.fieldTimestamp: FieldValue.serverTimestamp(),
      FirestoreConstants.fieldLastUpdated: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
    return liveLocationDoc(busId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return BusLocationModel.fromMap(snapshot.data()!, documentId: snapshot.id);
    });
  }

  /// Fetches a one-time snapshot of a bus's live location.
  Future<BusLocationModel?> getLiveLocation(String busId) async {
    final doc = await liveLocationDoc(busId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return BusLocationModel.fromMap(doc.data()!, documentId: doc.id);
  }

  /// Listens to real-time streams of all active broadcasting buses.
  Stream<List<BusLocationModel>> listenToAllActiveBuses() {
    return _liveLocationsCollection
        .where(FirestoreConstants.fieldIsBroadcasting, isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BusLocationModel.fromMap(doc.data(), documentId: doc.id))
          .toList();
    });
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
