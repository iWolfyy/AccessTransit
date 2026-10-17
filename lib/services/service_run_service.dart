import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/service_run.dart';
import '../models/trip_model.dart';
import '../models/bus_location_model.dart';
import 'sample_test_mode.dart';
import 'transit_catalogue.dart';
import 'trip_service.dart';
import 'moderation_mode.dart';
import 'moderation_client.dart';

class ServiceRunService {
  ServiceRunService({FirebaseFirestore? firestore}) : _custom = firestore;
  final FirebaseFirestore? _custom;
  FirebaseFirestore get _db => _custom ?? FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> _ref(String kind, String id) =>
      _db.collection(SampleTestMode.collection(kind)).doc(id);

  Stream<List<ServiceRun>> watchRuns(String busId) => _db
      .collection(SampleTestMode.collection('service_runs'))
      .where('busId', isEqualTo: busId)
      .snapshots(includeMetadataChanges: true)
      .map((s) {
        if (s.metadata.isFromCache || s.metadata.hasPendingWrites) {
          throw StateError('Connect to verify dated departures.');
        }
        return s.docs.map((d) => ServiceRun.fromMap(d.id, d.data())).toList()
          ..sort(
            (a, b) => a.plannedDepartureAt.compareTo(b.plannedDepartureAt),
          );
      });

  Future<TripModel> startRun({
    required String runId,
    required String driverId,
    required BusLocationModel gps,
    String lateReason = '',
    double? gpsAccuracy,
  }) async {
    TransitCatalogue.requireSharedWrites();
    if (runId.isEmpty ||
        driverId.isEmpty ||
        gps.driverId != driverId ||
        !gps.latitude.isFinite ||
        !gps.longitude.isFinite ||
        gps.latitude.abs() > 90 ||
        gps.longitude.abs() > 180 ||
        (gps.latitude == 0 && gps.longitude == 0) ||
        !gps.speed.isFinite ||
        gps.speed < 0 ||
        gps.speed > 200 ||
        !gps.heading.isFinite) {
      throw StateError('Select a run and obtain a valid GPS fix.');
    }
    final tripRef = _ref('trips', runId), runRef = _ref('service_runs', runId);
    if (ModerationMode.enabled) {
      final current = await runRef.get(const GetOptions(source: Source.server));
      if (current.data()?['handoverPending'] == true) {
        final client = ModerationClient();
        try {
          await client.acceptOperation(
            runId,
            current.data()!['handoverVersion'] as int,
            {
              'latitude': gps.latitude,
              'longitude': gps.longitude,
              'speed': gps.speed,
              'heading': gps.heading,
              'accuracy': gpsAccuracy,
              'observedAt': gps.timestamp?.toUtc().toIso8601String(),
            },
            driverId: driverId,
          );
          final snapshot = await tripRef.get(
            const GetOptions(source: Source.server),
          );
          final trip = TripModel.fromFirestore(snapshot);
          if (trip.driverId != driverId || !trip.isInProgress) {
            throw StateError('This operation changed. Refresh and retry.');
          }
          TripService().acceptAcknowledgedTrip(trip);
          return trip;
        } finally {
          client.dispose();
        }
      }
    }
    final lockRef = _ref('operation_locks', driverId);
    final saved = await _db
        .runTransaction<TripModel>((tx) async {
          final runSnap = await tx.get(runRef);
          if (!runSnap.exists) {
            throw StateError('This dated departure is unavailable.');
          }
          final run = ServiceRun.fromMap(runId, runSnap.data()!);
          if (gps.busId != run.busId) {
            throw StateError('The selected bus/run changed.');
          }
          final liveRef = _ref('live_locations', run.busId);
          final existing = await tx.get(tripRef),
              live = await tx.get(liveRef),
              lock = await tx.get(lockRef);
          final bus = await tx.get(_ref('buses', run.busId));
          final approval = await tx.get(_ref('operator_access', driverId));
          final grant = await tx.get(
            _ref('driver_route_assignments', driverId),
          );
          if (approval.data()?['approved'] != true ||
              grant.data()?['active'] != true ||
              grant.data()?['routeId'] != run.routeId ||
              bus.data()?['routeId'] != run.routeId ||
              bus.data()?['driverId'] != driverId ||
              bus.data()?['deletionPending'] == true) {
            throw StateError(
              'Current approval, route permission and bus assignment are required.',
            );
          }
          if (existing.exists) {
            final prior = TripModel.fromFirestore(existing);
            if (!prior.isInProgress ||
                prior.driverId != driverId ||
                prior.busId != run.busId ||
                prior.serviceRunId != runId ||
                !['boarding', 'in_progress'].contains(run.status) ||
                live.data()?['tripId'] != runId ||
                live.data()?['isBroadcasting'] != true ||
                lock.data()?['active'] != true ||
                lock.data()?['tripId'] != runId) {
              throw StateError(
                'This run ended or another operation replaced it.',
              );
            }
            tx.update(liveRef, {
              'latitude': gps.latitude,
              'longitude': gps.longitude,
              'speed': gps.speed,
              'heading': gps.heading,
              'timestamp': FieldValue.serverTimestamp(),
            });
            return prior;
          }
          // The client check gives a useful error; Firestore request.time is the
          // authoritative boundary and cannot be bypassed with a modified clock.
          final now = DateTime.now().toUtc();
          if (!run.canStartAt(now)) {
            throw StateError(
              'Start is allowed from five minutes before departure until the administrator-set latest start.',
            );
          }
          if (now.isAfter(run.plannedDepartureAt) &&
              lateReason.trim().length < 5) {
            throw StateError('Enter a reason for this late start.');
          }
          if (lock.data()?['active'] == true ||
              live.data()?['isBroadcasting'] == true) {
            throw StateError(
              'This driver or bus already has an active operation.',
            );
          }
          final trip = TripModel(
            tripId: runId,
            serviceRunId: runId,
            busId: run.busId,
            routeNo: run.routeNo,
            stops: run.stopTimes.keys.toList(),
            status: 'in_progress',
            scheduledDepartureTime: run.plannedDepartureAt,
            actualDepartureTime: null,
            stopTimes: {
              for (final e in run.stopTimes.entries)
                e.key: StopTimingInfo(estimatedArrival: e.value),
            },
            driverId: driverId,
            createdAt: now,
          );
          tx.set(tripRef, trip.toMap(isServerTimestamp: true));
          tx.update(runRef, {
            'status': 'boarding',
            'driverId': driverId,
            'tripId': runId,
            'startedAt': FieldValue.serverTimestamp(),
            'actualDepartureAt': null,
          });
          if (lateReason.trim().isNotEmpty) {
            tx.set(_ref('driver_trip_notes', runId), {
              'driverId': driverId,
              'busId': run.busId,
              'reason': lateReason.trim(),
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
          tx.set(lockRef, {
            'active': true,
            'busId': run.busId,
            'tripId': runId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          tx.set(liveRef, {
            ...gps.toMap(isServerTimestamp: true),
            'tripId': runId,
            'status': 'stopped',
            'isBroadcasting': true,
            'currentStopIndex': 0,
            'nextStop': run.stopTimes.keys.first,
          });
          return trip;
        })
        .timeout(const Duration(seconds: 15));
    TripService().acceptAcknowledgedTrip(saved);
    return saved;
  }

  Future<TripModel> recordDeparture(String runId, String driverId) async {
    TransitCatalogue.requireSharedWrites();
    final runRef = _ref('service_runs', runId), tripRef = _ref('trips', runId);
    await _db
        .runTransaction((tx) async {
          final run = await tx.get(runRef), trip = await tx.get(tripRef);
          if (run.data()?['driverId'] != driverId ||
              trip.data()?['driverId'] != driverId ||
              trip.data()?['status'] != 'in_progress') {
            throw StateError('Refresh the active run.');
          }
          if (run.data()?['status'] == 'in_progress' &&
              trip.data()?['actualDepartureTime'] != null) {
            return;
          }
          if (run.data()?['status'] != 'boarding') {
            throw StateError('This run cannot depart.');
          }
          final liveRef = _ref(
            'live_locations',
            run.data()!['busId'] as String,
          );
          final live = await tx.get(liveRef);
          if (live.data()?['tripId'] != runId ||
              live.data()?['isBroadcasting'] != true) {
            throw StateError('The live session changed.');
          }
          tx.update(runRef, {
            'status': 'in_progress',
            'actualDepartureAt': FieldValue.serverTimestamp(),
          });
          tx.update(tripRef, {
            'actualDepartureTime': FieldValue.serverTimestamp(),
          });
          tx.update(liveRef, {'status': 'active'});
        })
        .timeout(const Duration(seconds: 15));
    final snapshot = await tripRef.get(const GetOptions(source: Source.server));
    final trip = TripModel.fromFirestore(snapshot);
    TripService().acceptAcknowledgedTrip(trip);
    return trip;
  }
}
