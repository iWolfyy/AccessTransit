import 'transit_catalogue.dart';
import 'sample_test_mode.dart';

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../logic/ordered_schedule.dart';
import '../models/trip_model.dart';
import '../models/bus_location_model.dart';
import 'eta_service.dart';

/// Repository service for managing bus trip executions (`trips/{tripId}`).
class TripService {
  TripService({FirebaseFirestore? firestore, this.tripWriter})
    : _customFirestore = firestore;

  /// Injected acknowledged backend for deterministic delivery tests.
  final Future<void> Function(TripModel, TripModel?)? tripWriter;

  void _cache(TripModel trip) {
    _localTripsFallback[trip.busId] = trip;
    _localTripsStreamController.add(Map.unmodifiable(_localTripsFallback));
  }

  void acceptAcknowledgedTrip(TripModel trip) => _cache(trip);

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore? get _db {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static final Map<String, TripModel> _localTripsFallback = {};
  static final StreamController<Map<String, TripModel>>
  _localTripsStreamController =
      StreamController<Map<String, TripModel>>.broadcast();

  CollectionReference<Map<String, dynamic>>? get _tripsRef =>
      _db?.collection(SampleTestMode.collection('trips'));

  /// Legacy/injected timeline adapter. Production operator UI starts dated runs
  /// through ServiceRunService; rules reject newly created undated trips.
  /// Builds ordered timetable intervals or explicit model estimates for compatibility.
  /// [departureTime] is the actual departure. [serviceDate] optionally fixes the
  /// first stop's timetable date; otherwise the nearest daily departure is used.
  /// Estimates shift by actual minus planned departure, retaining planned time.
  Future<TripModel> startTrip({
    required String busId,
    required String routeNo,
    required List<String> stops,
    required String driverId,
    List<String>? scheduleTimes,
    DateTime? departureTime,
    DateTime? serviceDate,
    String? scheduledDeparture,
    String? requestedTripId,
    BusLocationModel? initialTelemetry,
  }) async {
    TransitCatalogue.requireSharedWrites();
    final now = DateTime.now();
    final actualDepTime = departureTime ?? now;
    final tripId =
        requestedTripId ?? 'trip_${busId}_${now.microsecondsSinceEpoch}';
    if (stops.isEmpty || driverId.isEmpty) {
      throw StateError('Select a bus itinerary and sign in first');
    }

    final base = serviceDate ?? actualDepTime;
    final primaryRaw = scheduledDeparture?.trim() ?? '';
    final primary = primaryRaw.isEmpty
        ? null
        : OrderedSchedule.minutesOfDay(primaryRaw);
    if (primaryRaw.isNotEmpty && primary == null) {
      throw StateError('Invalid scheduled departure. Review the timetable.');
    }
    final raw = scheduleTimes ?? const <String>[];
    final hasTimetable =
        (raw.isNotEmpty && raw.first.trim().isNotEmpty) || primary != null;
    final fallback = primary == null
        ? DateTime(
            base.year,
            base.month,
            base.day,
            actualDepTime.hour,
            actualDepTime.minute,
            actualDepTime.second,
            actualDepTime.millisecond,
            actualDepTime.microsecond,
          )
        : DateTime(
            base.year,
            base.month,
            base.day,
            primary ~/ 60,
            primary % 60,
          );
    var schedule = OrderedSchedule.build(
      stopCount: stops.length,
      scheduleTimes: raw,
      serviceDate: base,
      fallbackDeparture: fallback,
    );
    if (schedule == null) {
      throw StateError('Invalid stop timetable. Review it before starting.');
    }
    if (hasTimetable && serviceDate == null) {
      schedule = schedule.nearestDepartureTo(actualDepTime);
    }
    final plannedDeparture = hasTimetable ? schedule.times.first : null;
    final offset = actualDepTime.difference(schedule.times.first);
    final stopTimes = <String, StopTimingInfo>{
      for (var i = 0; i < stops.length; i++)
        stops[i]: StopTimingInfo(
          estimatedArrival: schedule.times[i].add(offset),
          actualArrival: i == 0 ? actualDepTime : null,
        ),
    };

    final trip = TripModel(
      tripId: tripId,
      busId: busId,
      routeNo: routeNo,
      stops: stops,
      status: 'in_progress',
      scheduledDepartureTime: plannedDeparture,
      actualDepartureTime: actualDepTime,
      stopTimes: stopTimes,
      currentStopIndex: 0,
      driverId: driverId,
      createdAt: now,
    );

    if (tripWriter != null) {
      await tripWriter!(trip, null);
    } else {
      final db = _db;
      if (db == null || initialTelemetry == null) {
        throw StateError(
          'A shared backend and initial GPS observation are required',
        );
      }
      final ref = db.collection(SampleTestMode.collection('trips')).doc(tripId);
      final live = db
          .collection(SampleTestMode.collection('live_locations'))
          .doc(busId);
      final saved = await db
          .runTransaction<TripModel>((tx) async {
            final existing = await tx.get(ref);
            final currentLive = await tx.get(live);
            if (existing.exists) {
              final prior = TripModel.fromFirestore(existing);
              if (prior.driverId != driverId || prior.busId != busId) {
                throw StateError('Trip identity changed');
              }
              if (!prior.isInProgress ||
                  currentLive.data()?['tripId'] != tripId ||
                  currentLive.data()?['isBroadcasting'] != true) {
                throw StateError(
                  'This trip ended or its broadcast session changed. Refresh before starting.',
                );
              }
              // Resume/retry retains the acknowledged stop timeline and updates only GPS.
              tx.update(live, {
                'latitude': initialTelemetry.latitude,
                'longitude': initialTelemetry.longitude,
                'speed': initialTelemetry.speed,
                'heading': initialTelemetry.heading,
                'timestamp': FieldValue.serverTimestamp(),
                'lastUpdated': FieldValue.serverTimestamp(),
              });
              return prior;
            }
            if (currentLive.data()?['isBroadcasting'] == true) {
              throw StateError(
                'This bus already has a broadcasting trip. Refresh before starting.',
              );
            }
            tx.set(ref, trip.toMap(isServerTimestamp: true));
            tx.set(live, {
              ...initialTelemetry.toMap(isServerTimestamp: true),
              'tripId': tripId,
            });
            return trip;
          })
          .timeout(const Duration(seconds: 12));
      _cache(saved);
      return saved;
    }
    _cache(trip);

    return trip;
  }

  /// 2. Streams the current active trip for a given [busId].
  Stream<TripModel?> watchActiveTripForBus(String busId) {
    if (TransitCatalogue.demo) return Stream.value(null);
    TripModel? getLocal() {
      final t = _localTripsFallback[busId];
      return t?.isInProgress == true ? t : null;
    }

    late StreamController<TripModel?> controller;
    StreamSubscription? remote;
    StreamSubscription? local;
    controller = StreamController<TripModel?>(
      onListen: () {
        controller.add(getLocal());
        local = _localTripsStreamController.stream.listen(
          (_) => controller.add(getLocal()),
        );
        final col = _tripsRef;
        if (col != null) {
          remote = col
              .where('busId', isEqualTo: busId)
              .where('status', isEqualTo: 'in_progress')
              .snapshots(includeMetadataChanges: true)
              .listen(
                (snapshot) {
                  if (snapshot.metadata.hasPendingWrites) {
                    controller.add(getLocal());
                    return;
                  }
                  if (snapshot.docs.isNotEmpty) {
                    _localTripsFallback[busId] = TripModel.fromFirestore(
                      snapshot.docs.first,
                    );
                  } else if (!snapshot.metadata.isFromCache) {
                    _localTripsFallback.remove(busId);
                  }
                  controller.add(getLocal());
                },
                onError: (Object error) {
                  controller.addError(error);
                },
              );
        }
      },
      onCancel: () async {
        await local?.cancel();
        await remote?.cancel();
      },
    );
    return controller.stream;
  }

  /// 3. Confirms arrival at the next stop, advancing [currentStopIndex] and updating arrival times.
  Future<TripModel?> confirmNextStopArrival(
    String busId, {
    DateTime? arrivalTime,
    String? expectedTripId,
  }) async {
    TransitCatalogue.requireSharedWrites();
    final active = _localTripsFallback[busId];
    if (active == null || !active.isInProgress) return null;
    if (active.isBoarding) {
      throw StateError('Record departure before confirming the next stop.');
    }
    if (expectedTripId != null && active.tripId != expectedTripId) {
      throw StateError(
        'The active trip changed. Resume the current trip before confirming arrival.',
      );
    }

    if (active.stops.isEmpty ||
        active.currentStopIndex < 0 ||
        active.currentStopIndex >= active.stops.length) {
      throw StateError(
        'Invalid stop progress. Refresh the trip before confirming arrival.',
      );
    }
    // Legacy active records can already point at the terminal stop. Complete
    // that arrival without advancing beyond the itinerary or losing its time.
    final nextIndex = (active.currentStopIndex + 1).clamp(
      0,
      active.stops.length - 1,
    );
    final actTime =
        active.stopTimes[active.stops[nextIndex]]?.actualArrival ??
        arrivalTime ??
        DateTime.now();

    // Recalculate remaining stops' pace
    final updatedStopTimes = EtaService.recalculateRemainingStopsPace(
      stops: active.stops,
      currentStopTimes: active.stopTimes,
      confirmedIndex: nextIndex,
      actualArrivalTime: actTime,
    );

    final updatedTrip = active.copyWith(
      status: nextIndex == active.stops.length - 1
          ? 'completed'
          : 'in_progress',
      currentStopIndex: nextIndex,
      stopTimes: updatedStopTimes,
    );

    final acknowledged = await _commitProgress(active, updatedTrip);
    _cache(acknowledged);
    return acknowledged;
  }

  /// 4. Completes an active trip.
  Future<TripModel?> completeTrip(
    String busId, {
    String? expectedTripId,
  }) async {
    TransitCatalogue.requireSharedWrites();
    final active = _localTripsFallback[busId];
    if (active == null) return null;
    if (expectedTripId != null && active.tripId != expectedTripId) {
      throw StateError(
        'The active trip changed. Refresh before completing it.',
      );
    }

    final completedTrip = active.copyWith(
      status: active.isBoarding ? 'cancelled' : 'completed',
    );

    final acknowledged = await _commitProgress(active, completedTrip);
    _cache(acknowledged);
    return acknowledged;
  }

  /// Atomically acknowledge the timeline and its corresponding broadcast state.
  Future<TripModel> _commitProgress(TripModel before, TripModel after) async {
    TransitCatalogue.requireSharedWrites();
    if (tripWriter != null) {
      await tripWriter!(after, before);
      return after;
    }
    final db = _db;
    if (db == null) throw StateError('Shared trips are unavailable');
    final ref = db
        .collection(SampleTestMode.collection('trips'))
        .doc(before.tripId);
    final live = db
        .collection(SampleTestMode.collection('live_locations'))
        .doc(before.busId);
    return db
        .runTransaction<TripModel>((tx) async {
          final snapshot = await tx.get(ref);
          final telemetry = await tx.get(live);
          final runId = before.serviceRunId;
          final runRef = runId == null
              ? null
              : db
                    .collection(SampleTestMode.collection('service_runs'))
                    .doc(runId);
          final lockRef = runId == null
              ? null
              : db
                    .collection(SampleTestMode.collection('operation_locks'))
                    .doc(before.driverId);
          final run = runRef == null ? null : await tx.get(runRef);
          final lock = lockRef == null ? null : await tx.get(lockRef);
          if (runId != null &&
              (run?.data()?['tripId'] != before.tripId ||
                  lock?.data()?['tripId'] != before.tripId)) {
            throw StateError('The dated run or driver lock changed.');
          }
          if (!snapshot.exists ||
              telemetry.data()?['tripId'] != before.tripId) {
            throw StateError(
              'The trip session changed. Refresh before retrying.',
            );
          }
          final actual = TripModel.fromFirestore(snapshot);
          final alreadySaved =
              actual.status == after.status &&
              actual.currentStopIndex == after.currentStopIndex;
          if (!alreadySaved &&
              (actual.status != before.status ||
                  actual.currentStopIndex != before.currentStopIndex)) {
            throw StateError('Trip progress changed. Refresh before retrying.');
          }
          final saved = alreadySaved ? actual : after;
          if (saved.stops.isEmpty ||
              saved.currentStopIndex < 0 ||
              saved.currentStopIndex >= saved.stops.length) {
            throw StateError('Trip progress changed. Refresh before retrying.');
          }
          if (!alreadySaved) {
            tx.update(ref, {
              'status': saved.status,
              'currentStopIndex': saved.currentStopIndex,
              'stopTimes': saved.toMap()['stopTimes'],
            });
          }
          // Retry must also reconcile telemetry, while retaining the original
          // acknowledged actualArrival rather than writing a new retry time.
          final next = (saved.currentStopIndex + 1).clamp(
            0,
            saved.stops.length - 1,
          );
          tx.update(live, {
            'currentStopIndex': saved.currentStopIndex,
            'nextStop': saved.stops[next],
            if (!saved.isInProgress) 'status': 'completed',
            if (!saved.isInProgress) 'isBroadcasting': false,
            if (!saved.isInProgress) 'addedDelayMinutes': 0,
            if (!saved.isInProgress) 'delayReason': FieldValue.delete(),
          });
          if (!saved.isInProgress && runRef != null && lockRef != null) {
            tx.update(runRef, {
              'status': saved.status,
              'completedAt': FieldValue.serverTimestamp(),
            });
            tx.update(lockRef, {
              'active': false,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          return saved;
        })
        .timeout(const Duration(seconds: 12));
  }

  /// Fetches a one-time snapshot of the active trip for a bus.
  Future<TripModel?> getActiveTrip(String busId) async {
    if (TransitCatalogue.demo) return null;
    try {
      final col = _tripsRef;
      if (col != null) {
        final snapshot = await col
            .where('busId', isEqualTo: busId)
            .where('status', isEqualTo: 'in_progress')
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 12));
        if (snapshot.metadata.hasPendingWrites) {
          return _localTripsFallback[busId];
        }
        if (snapshot.docs.isNotEmpty) {
          final trip = TripModel.fromFirestore(snapshot.docs.first);
          _localTripsFallback[busId] = trip;
          return trip;
        }
        if (!snapshot.metadata.isFromCache &&
            !snapshot.metadata.hasPendingWrites) {
          _localTripsFallback.remove(busId);
          return null;
        }
      }
    } catch (e) {
      debugPrint('TripService.getActiveTrip fallback: $e');
    }
    final t = _localTripsFallback[busId];
    return (t != null && t.isInProgress) ? t : null;
  }
}
