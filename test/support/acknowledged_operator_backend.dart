import 'package:access_transit/models/bus_location_model.dart';
import 'package:access_transit/models/trip_model.dart';
import 'package:access_transit/services/live_bus_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Explicit simulated server receipts; never used by production.
class AcknowledgedOperatorBackend {
  static final Map<String, Map<String, dynamic>> data = {};
  LiveBusService liveService() => LiveBusService(telemetryWriter: write);
  Future<BusLocationModel> write(
    String id,
    Map<String, dynamic> changes,
  ) async {
    final map = {...?data[id]};
    for (final entry in changes.entries) {
      if (entry.value is FieldValue) {
        if (entry.key == 'delayReason') {
          map.remove(entry.key);
        } else {
          map[entry.key] = Timestamp.fromDate(DateTime.now());
        }
      } else {
        map[entry.key] = entry.value;
      }
    }
    data[id] = map;
    return BusLocationModel.fromMap(map, documentId: id);
  }

  Future<void> writeTrip(TripModel after, TripModel? before) async {
    if (before == null || !data.containsKey(after.busId)) return;
    final next = (after.currentStopIndex + 1).clamp(0, after.stops.length - 1);
    liveService().acceptAcknowledged(
      await write(after.busId, {
        'currentStopIndex': after.currentStopIndex,
        'nextStop': after.stops[next],
        if (!after.isInProgress) 'status': 'completed',
        if (!after.isInProgress) 'isBroadcasting': false,
      }),
    );
  }
}
