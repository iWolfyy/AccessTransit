import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/time_utils.dart';
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
      _db?.collection('trips');

  /// 1. Starts a new trip for a bus route using seeded [scheduleTimes] or fallback geodesic ETA.
  Future<TripModel> startTrip({
    required String busId,
    required String routeNo,
    required List<String> stops,
    required String driverId,
    List<String>? scheduleTimes,
    DateTime? departureTime,
    String? requestedTripId,
    BusLocationModel? initialTelemetry,
  }) async {
    final now = DateTime.now();
    final actualDepTime = departureTime ?? now;
    final tripId =
        requestedTripId ?? 'trip_${busId}_${now.microsecondsSinceEpoch}';
    if (stops.isEmpty || driverId.isEmpty) {
      throw StateError('Select a bus itinerary and sign in first');
    }

    Map<String, StopTimingInfo> stopTimes = {};

    if (scheduleTimes != null &&
        scheduleTimes.isNotEmpty &&
        scheduleTimes.length == stops.length) {
      DateTime? previous;
      for (int i = 0; i < stops.length; i++) {
        final timeStr = scheduleTimes[i];
        var scheduledDt = TimeUtils.parseTimeStringToDateTime(
          timeStr,
          actualDepTime,
        );
        while (previous != null && scheduledDt.isBefore(previous)) {
          scheduledDt = scheduledDt.add(const Duration(days: 1));
        }
        previous = scheduledDt;
        stopTimes[stops[i]] = StopTimingInfo(
          estimatedArrival: scheduledDt,
          actualArrival: i == 0 ? actualDepTime : null,
        );
      }
    } else {
      stopTimes = EtaService.computeTripStopEstimates(stops, actualDepTime);
    }

    final trip = TripModel(
      tripId: tripId,
      busId: busId,
      routeNo: routeNo,
      stops: stops,
      status: 'in_progress',
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
      final ref = db.collection('trips').doc(tripId);
      final live = db.collection('live_locations').doc(busId);
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
    final active = _localTripsFallback[busId];
    if (active == null || !active.isInProgress) return null;
    if (expectedTripId != null && active.tripId != expectedTripId) {
      throw StateError(
        'The active trip changed. Resume the current trip before confirming arrival.',
      );
    }

    final nextIndex = active.currentStopIndex + 1;
    if (nextIndex >= active.stops.length) {
      // Reached final stop -> auto complete trip
      return await completeTrip(busId);
    }

    final actTime = arrivalTime ?? DateTime.now();

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
    final active = _localTripsFallback[busId];
    if (active == null) return null;
    if (expectedTripId != null && active.tripId != expectedTripId) {
      throw StateError(
        'The active trip changed. Refresh before completing it.',
      );
    }

    final completedTrip = active.copyWith(status: 'completed');

    final acknowledged = await _commitProgress(active, completedTrip);
    _cache(acknowledged);
    return acknowledged;
  }

  /// Atomically acknowledge the timeline and its corresponding broadcast state.
  Future<TripModel> _commitProgress(TripModel before, TripModel after) async {
    if (tripWriter != null) {
      await tripWriter!(after, before);
      return after;
    }
    final db = _db;
    if (db == null) throw StateError('Shared trips are unavailable');
    final ref = db.collection('trips').doc(before.tripId);
    final live = db.collection('live_locations').doc(before.busId);
    return db
        .runTransaction<TripModel>((tx) async {
          final snapshot = await tx.get(ref);
          final telemetry = await tx.get(live);
          if (!snapshot.exists ||
              telemetry.data()?['tripId'] != before.tripId) {
            throw StateError(
              'The trip session changed. Refresh before retrying.',
            );
          }
          final actual = TripModel.fromFirestore(snapshot);
          if (actual.status == after.status &&
              actual.currentStopIndex == after.currentStopIndex) {
            return actual;
          }
          if (actual.status != before.status ||
              actual.currentStopIndex != before.currentStopIndex) {
            throw StateError('Trip progress changed. Refresh before retrying.');
          }
          tx.update(ref, {
            'status': after.status,
            'currentStopIndex': after.currentStopIndex,
            'stopTimes': after.toMap()['stopTimes'],
          });
          final next = (after.currentStopIndex + 1).clamp(
            0,
            after.stops.length - 1,
          );
          tx.update(live, {
            'currentStopIndex': after.currentStopIndex,
            'nextStop': after.stops[next],
            if (!after.isInProgress) 'status': 'completed',
            if (!after.isInProgress) 'isBroadcasting': false,
            if (!after.isInProgress) 'addedDelayMinutes': 0,
            if (!after.isInProgress) 'delayReason': FieldValue.delete(),
          });
          return after;
        })
        .timeout(const Duration(seconds: 12));
  }

  /// Fetches a one-time snapshot of the active trip for a bus.
  Future<TripModel?> getActiveTrip(String busId) async {
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
