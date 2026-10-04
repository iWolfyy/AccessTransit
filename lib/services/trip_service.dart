import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/time_utils.dart';
import '../models/trip_model.dart';
import 'eta_service.dart';
import 'live_bus_service.dart';

/// Repository service for managing bus trip executions (`trips/{tripId}`).
class TripService {
  TripService({FirebaseFirestore? firestore}) : _customFirestore = firestore;

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
  static final StreamController<Map<String, TripModel>> _localTripsStreamController =
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
  }) async {
    final now = DateTime.now();
    final actualDepTime = departureTime ?? now;
    final tripId = 'trip_${busId}_${now.millisecondsSinceEpoch}';

    Map<String, StopTimingInfo> stopTimes = {};

    if (scheduleTimes != null &&
        scheduleTimes.isNotEmpty &&
        scheduleTimes.length == stops.length) {
      for (int i = 0; i < stops.length; i++) {
        final timeStr = scheduleTimes[i];
        final scheduledDt = TimeUtils.parseTimeStringToDateTime(timeStr, actualDepTime);
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

    // Store in local fallback first
    _localTripsFallback[busId] = trip;
    _localTripsStreamController.add(_localTripsFallback);

    try {
      final ref = _tripsRef?.doc(tripId);
      if (ref != null) {
        await ref.set(trip.toMap(isServerTimestamp: true));
      }
    } catch (e) {
      debugPrint('TripService.startTrip warning: $e');
    }

    return trip;
  }

  /// 2. Streams the current active trip for a given [busId].
  Stream<TripModel?> watchActiveTripForBus(String busId) async* {
    TripModel? getLocal() {
      final t = _localTripsFallback[busId];
      if (t != null && t.isInProgress) return t;
      return null;
    }

    yield getLocal();

    final localSub = _localTripsStreamController.stream.listen((_) {});

    try {
      final col = _tripsRef;
      if (col != null) {
        final query = col
            .where('busId', isEqualTo: busId)
            .where('status', isEqualTo: 'in_progress');

        await for (final snapshot in query.snapshots()) {
          if (snapshot.docs.isNotEmpty) {
            final doc = snapshot.docs.first;
            final trip = TripModel.fromFirestore(doc);
            _localTripsFallback[busId] = trip;
            yield trip;
          } else {
            yield getLocal();
          }
        }
      } else {
        yield getLocal();
      }
    } catch (e) {
      debugPrint('TripService.watchActiveTripForBus fallback: $e');
      yield getLocal();
    } finally {
      await localSub.cancel();
    }
  }

  /// 3. Confirms arrival at the next stop, advancing [currentStopIndex] and updating arrival times.
  Future<TripModel?> confirmNextStopArrival(String busId, {DateTime? arrivalTime}) async {
    final active = _localTripsFallback[busId];
    if (active == null || !active.isInProgress) return null;

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
      currentStopIndex: nextIndex,
      stopTimes: updatedStopTimes,
    );

    _localTripsFallback[busId] = updatedTrip;
    _localTripsStreamController.add(_localTripsFallback);

    try {
      final ref = _tripsRef?.doc(active.tripId);
      if (ref != null) {
        await ref.update(updatedTrip.toMap());
      }
    } catch (e) {
      debugPrint('TripService.confirmNextStopArrival warning: $e');
    }

    // Instantly sync LiveBusService so passenger screens receive the new next stop
    try {
      final hasUpcoming = nextIndex + 1 < active.stops.length;
      final upcomingStop = hasUpcoming ? active.stops[nextIndex + 1] : active.stops[nextIndex];
      await LiveBusService().updateNextStop(
        busId: busId,
        nextStop: upcomingStop,
        currentStopIndex: nextIndex,
      );
    } catch (e) {
      debugPrint('TripService.confirmNextStopArrival LiveBusService sync warning: $e');
    }

    return updatedTrip;
  }

  /// 4. Completes an active trip.
  Future<TripModel?> completeTrip(String busId) async {
    final active = _localTripsFallback[busId];
    if (active == null) return null;

    final completedTrip = active.copyWith(status: 'completed');

    _localTripsFallback[busId] = completedTrip;
    _localTripsStreamController.add(_localTripsFallback);

    try {
      final ref = _tripsRef?.doc(active.tripId);
      if (ref != null) {
        await ref.update({'status': 'completed'});
      }
    } catch (e) {
      debugPrint('TripService.completeTrip warning: $e');
    }

    try {
      await LiveBusService().stopTrip(busId);
    } catch (e) {
      debugPrint('TripService.completeTrip stopTrip warning: $e');
    }

    return completedTrip;
  }

  /// Fetches a one-time snapshot of the active trip for a bus.
  Future<TripModel?> getActiveTrip(String busId) async {
    try {
      final col = _tripsRef;
      if (col != null) {
        final snapshot = await col
            .where('busId', isEqualTo: busId)
            .where('status', isEqualTo: 'in_progress')
            .get();
        if (snapshot.docs.isNotEmpty) {
          final trip = TripModel.fromFirestore(snapshot.docs.first);
          _localTripsFallback[busId] = trip;
          return trip;
        }
      }
    } catch (e) {
      debugPrint('TripService.getActiveTrip fallback: $e');
    }
    final t = _localTripsFallback[busId];
    return (t != null && t.isInProgress) ? t : null;
  }
}
