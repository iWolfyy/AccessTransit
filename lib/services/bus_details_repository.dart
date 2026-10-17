import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/bus.dart';
import '../models/bus_location_model.dart';
import '../models/report.dart';
import '../models/service_run.dart';
import '../models/station.dart';
import '../models/trip_model.dart';
import 'firestore_service.dart';
import 'live_bus_service.dart';
import 'sample_test_mode.dart';
import 'service_run_service.dart';
import 'segment_reports.dart';

/// Exact-run subscriptions; cached trip state cannot establish current movement.
class BusDetailsRepository {
  Stream<Bus?> bus(String id) => FirestoreService().streamBusById(id);
  Stream<List<Report>> reports({
    required String busId,
    required List<String> stopIds,
  }) async* {
    yield* SegmentReports().preview(busId, stopIds);
  }

  Stream<SegmentReportPage> reportPage(
    ReportTarget target, {
    String? after,
  }) async* {
    yield* SegmentReports().page(target, after: after);
  }

  Future<List<Station>> stations() => FirestoreService().getStations();
  Stream<List<ServiceRun>> runs(String busId) async* {
    yield* ServiceRunService().watchRuns(busId);
  }

  Stream<BusLocationModel?> location(String busId) =>
      LiveBusService().listenToLiveLocation(busId);
  Stream<TripModel?> trip(String runId) async* {
    yield* FirebaseFirestore.instance
        .collection(SampleTestMode.collection('trips'))
        .doc(runId)
        .snapshots(includeMetadataChanges: true)
        .map((s) {
          if (s.metadata.isFromCache || s.metadata.hasPendingWrites) {
            throw StateError('Connect to verify this trip.');
          }
          return s.exists ? TripModel.fromFirestore(s) : null;
        });
  }
}
