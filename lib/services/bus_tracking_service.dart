import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_constants.dart';
import '../models/bus_location_model.dart';

/// Manages real-time Firestore synchronization for bus tracking telemetry.
class BusTrackingService {
  BusTrackingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Collection reference to `active_buses`.
  CollectionReference<Map<String, dynamic>> get _busesCollection =>
      _firestore.collection(FirestoreConstants.busesCollection);

  /// Document reference for a specific [busId].
  DocumentReference<Map<String, dynamic>> busDocument(String busId) {
    return _busesCollection.doc(busId);
  }

  /// Listens to real-time telemetry updates for a single bus by [busId].
  Stream<BusLocationModel?> watchBusLocation(String busId) {
    return busDocument(busId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return BusLocationModel.fromMap(snapshot.data()!, documentId: snapshot.id);
    });
  }

  /// Listens to all currently broadcasting buses.
  Stream<List<BusLocationModel>> watchActiveBuses() {
    return _busesCollection
        .where(FirestoreConstants.fieldIsBroadcasting, isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BusLocationModel.fromMap(doc.data(), documentId: doc.id))
          .toList();
    });
  }

  /// Updates real-time telemetry published by a Bus Operator.
  Future<void> updateBusTelemetry(BusLocationModel bus) async {
    await busDocument(bus.busId).set(
      bus.toMap(isServerTimestamp: true),
      SetOptions(merge: true),
    );
  }

  /// Sets broadcasting status to false when an operator completes a trip.
  Future<void> stopBroadcasting(String busId) async {
    await busDocument(busId).update({
      FirestoreConstants.fieldIsBroadcasting: false,
      FirestoreConstants.fieldLastUpdated: FieldValue.serverTimestamp(),
    });
  }

  /// Fetches a one-time snapshot of bus location data.
  Future<BusLocationModel?> getBusLocation(String busId) async {
    final doc = await busDocument(busId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return BusLocationModel.fromMap(doc.data()!, documentId: doc.id);
  }
}
