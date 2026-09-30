import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_constants.dart';
import '../models/bus_location_model.dart';
import 'live_bus_service.dart';

/// Manages real-time Firestore synchronization for bus tracking telemetry.
///
/// Fully unified with [LiveBusService] to ensure seamless real-time telemetry
/// synchronization across Bus Operators and Passenger Journey screens.
class BusTrackingService {
  BusTrackingService({
    FirebaseFirestore? firestore,
    LiveBusService? liveBusService,
  })  : _firestore = firestore,
        _liveBusService = liveBusService ?? LiveBusService(firestore: firestore);

  final FirebaseFirestore? _firestore;
  final LiveBusService _liveBusService;

  /// Collection reference to `live_locations`.
  CollectionReference<Map<String, dynamic>>? get _busesCollection {
    try {
      final db = _firestore ?? FirebaseFirestore.instance;
      return db.collection(FirestoreConstants.liveLocationsCollection);
    } catch (_) {
      return null;
    }
  }

  /// Document reference for a specific [busId].
  DocumentReference<Map<String, dynamic>>? busDocument(String busId) {
    return _busesCollection?.doc(busId);
  }

  /// Listens to real-time telemetry updates for a single bus by [busId].
  ///
  /// Delegates directly to [LiveBusService.listenToLiveLocation] to guarantee
  /// in-memory fallback and live Firestore stream unification.
  Stream<BusLocationModel?> watchBusLocation(String busId) {
    return _liveBusService.listenToLiveLocation(busId);
  }

  /// Listens to all currently broadcasting buses.
  Stream<List<BusLocationModel>> watchActiveBuses() {
    return _liveBusService.listenToAllActiveBuses();
  }

  /// Updates real-time telemetry published by a Bus Operator.
  Future<void> updateBusTelemetry(BusLocationModel bus) async {
    await _liveBusService.startOrUpdateLiveLocation(bus);
  }

  /// Sets broadcasting status to false when an operator completes a trip.
  Future<void> stopBroadcasting(String busId) async {
    await _liveBusService.stopTrip(busId);
  }

  /// Fetches a one-time snapshot of bus location data.
  Future<BusLocationModel?> getBusLocation(String busId) async {
    return _liveBusService.getLiveLocation(busId);
  }
}
