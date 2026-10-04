import 'package:latlong2/latlong.dart';

import '../models/bus_location_model.dart';
import '../models/enums/bus_status.dart';
import '../models/trip_model.dart';

/// Result object holding calculated Bus Estimated Time of Arrival (ETA) telemetry.
class EtaResult {
  const EtaResult({
    this.etaMinutes,
    required this.distanceMeters,
    required this.displayText,
    required this.isReliable,
    required this.reason,
  });

  /// Estimated time of arrival in minutes (null when ETA is unreliable).
  final int? etaMinutes;

  /// Geodesic distance to the target stop in meters.
  final double distanceMeters;

  /// User-facing formatted ETA label (e.g. "Bus arriving in approximately 7 minutes").
  final String displayText;

  /// `true` if calculated from fresh live GPS telemetry and valid stop coordinates.
  final bool isReliable;

  /// Technical explanation or fallback reason (useful for debug/accessibility).
  final String reason;

  /// Short summary label (e.g. "7 mins" or "Arriving now").
  String get shortLabel {
    if (!isReliable || etaMinutes == null) return 'ETA N/A';
    if (etaMinutes! <= 0) return 'Arriving now';
    return '$etaMinutes min${etaMinutes == 1 ? '' : 's'}';
  }
}

/// Service for dynamic Bus Estimated Time of Arrival (ETA) calculation.
class EtaService {
  EtaService();

  static const Distance _distanceCalculator = Distance();

  /// Registry mapping known transit stops to geographic coordinates.
  static final Map<String, LatLng> _stopCoordinates = {
    'colombo': const LatLng(6.9271, 79.8612),
    'kandy': const LatLng(7.2906, 80.6337),
    'galle': const LatLng(6.0535, 80.2210),
    'jaffna': const LatLng(9.6615, 80.0255),
    'trincomalee': const LatLng(8.5874, 81.2152),
    'badulla': const LatLng(6.9934, 81.0550),
    'central station': const LatLng(6.9271, 79.8612),
    'city library': const LatLng(6.9042, 79.8607),
    'town hall': const LatLng(6.9147, 79.8640),
    'south terminal': const LatLng(6.8722, 79.8883),
    'city hospital': const LatLng(6.9180, 79.8730),
    'main st & 4th ave': const LatLng(6.9210, 79.8580),
    'maharagama': const LatLng(6.8480, 79.9265),
    'pettah': const LatLng(6.9360, 79.8527),
  };

  /// Resolves `LatLng` coordinates for a given stop name.
  static LatLng? getStopCoordinates(String stopName) {
    final key = stopName.trim().toLowerCase();
    if (_stopCoordinates.containsKey(key)) {
      return _stopCoordinates[key];
    }
    // Partial match lookup
    for (final entry in _stopCoordinates.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Calculates dynamic ETA for a bus arriving at a given target stop.
  ///
  /// Uses live bus location, speed, and target stop coordinates.
  /// Returns an [EtaResult] with [isReliable] set to `false` if telemetry is stale,
  /// offline, or stop coordinates cannot be resolved.
  EtaResult calculateEta({
    required BusLocationModel? liveBus,
    required String stopName,
    LatLng? customStopLocation,
    bool isStale = false,
  }) {
    // 1. Verify telemetry availability
    if (liveBus == null) {
      return const EtaResult(
        distanceMeters: 0,
        displayText: 'ETA Unavailable — Connecting to bus stream',
        isReliable: false,
        reason: 'No bus location data available.',
      );
    }

    // 2. Verify signal freshness and broadcasting state
    if (isStale ||
        !liveBus.isBroadcasting ||
        liveBus.status == BusStatus.offline ||
        liveBus.status == BusStatus.completed) {
      return const EtaResult(
        distanceMeters: 0,
        displayText: 'ETA Unavailable — Bus offline or signal delayed',
        isReliable: false,
        reason: 'Bus telemetry is stale or offline.',
      );
    }

    // 3. Verify valid bus coordinates
    if (liveBus.latitude == 0.0 && liveBus.longitude == 0.0) {
      return const EtaResult(
        distanceMeters: 0,
        displayText: 'ETA Unavailable — Waiting for GPS fix',
        isReliable: false,
        reason: 'Invalid bus coordinates (0, 0).',
      );
    }

    // 4. Resolve target stop coordinates
    final targetLocation =
        customStopLocation ??
        getStopCoordinates(stopName) ??
        getStopCoordinates(liveBus.nextStop);

    if (targetLocation == null) {
      return const EtaResult(
        distanceMeters: 0,
        displayText: 'ETA Unavailable — Showing live location',
        isReliable: false,
        reason: 'Target stop location coordinates not found.',
      );
    }

    // 5. Calculate geodesic distance in meters
    final busLocation = LatLng(liveBus.latitude, liveBus.longitude);
    final distanceMeters = _distanceCalculator.distance(
      busLocation,
      targetLocation,
    );

    // 6. Proximity check (< 50 meters)
    if (distanceMeters <= 50) {
      return EtaResult(
        etaMinutes: 0,
        distanceMeters: distanceMeters,
        displayText: 'Bus arriving now',
        isReliable: true,
        reason: 'Bus is at or near the target stop.',
      );
    }

    // 7. Calculate ETA using current speed or urban transit fallback (20 km/h)
    final double effectiveSpeedKmH = (liveBus.speed >= 5.0)
        ? liveBus.speed
        : 20.0;
    final double distanceKm = distanceMeters / 1000.0;
    final double rawMinutes = (distanceKm / effectiveSpeedKmH) * 60.0;
    final int etaMinutes = rawMinutes.round().clamp(1, 180);

    return EtaResult(
      etaMinutes: etaMinutes,
      distanceMeters: distanceMeters,
      displayText:
          'Bus arriving in approximately $etaMinutes minute${etaMinutes == 1 ? '' : 's'}',
      isReliable: true,
      reason: 'Dynamically calculated from live GPS coordinates & speed.',
    );
  }

  /// Computes cumulative estimated arrival times for an ordered list of stop station IDs
  /// starting from [departureTime].
  static Map<String, StopTimingInfo> computeTripStopEstimates(
    List<String> stops,
    DateTime departureTime,
  ) {
    final Map<String, StopTimingInfo> result = {};
    if (stops.isEmpty) return result;

    DateTime currentEst = departureTime;
    result[stops.first] = StopTimingInfo(
      estimatedArrival: currentEst,
      actualArrival: currentEst, // Start station actual departure/arrival
    );

    for (int i = 1; i < stops.length; i++) {
      final prevStop = stops[i - 1];
      final currStop = stops[i];

      final prevLoc = getStopCoordinates(prevStop);
      final currLoc = getStopCoordinates(currStop);

      double segmentMinutes = 5.0; // Fallback: 5 minutes per segment
      if (prevLoc != null && currLoc != null) {
        final distMeters = _distanceCalculator.distance(prevLoc, currLoc);
        // Average urban speed: 20 km/h = 333.33 meters / minute
        final calcMinutes = (distMeters / 1000.0 / 20.0) * 60.0;
        segmentMinutes = calcMinutes.clamp(2.0, 30.0);
      }

      currentEst = currentEst.add(Duration(seconds: (segmentMinutes * 60).round()));
      result[currStop] = StopTimingInfo(estimatedArrival: currentEst);
    }

    return result;
  }

  /// Recalculates remaining stops' estimated arrival times when actual arrival is confirmed at [confirmedIndex].
  ///
  /// Adjusts remaining stop estimates based on actual elapsed time / pace offset.
  static Map<String, StopTimingInfo> recalculateRemainingStopsPace({
    required List<String> stops,
    required Map<String, StopTimingInfo> currentStopTimes,
    required int confirmedIndex,
    required DateTime actualArrivalTime,
  }) {
    final updated = Map<String, StopTimingInfo>.from(currentStopTimes);
    if (confirmedIndex < 0 || confirmedIndex >= stops.length) return updated;

    final confirmedStopId = stops[confirmedIndex];
    final prevInfo = updated[confirmedStopId];

    // Mark actual arrival for confirmed stop
    updated[confirmedStopId] = (prevInfo ?? StopTimingInfo(estimatedArrival: actualArrivalTime))
        .copyWith(actualArrival: actualArrivalTime);

    if (prevInfo == null) return updated;

    // Time difference / offset between actual arrival and original estimated arrival
    final timeOffset = actualArrivalTime.difference(prevInfo.estimatedArrival);

    // Adjust remaining stops
    for (int i = confirmedIndex + 1; i < stops.length; i++) {
      final stopId = stops[i];
      final origInfo = updated[stopId];
      if (origInfo != null) {
        final newEst = origInfo.estimatedArrival.add(timeOffset);
        updated[stopId] = origInfo.copyWith(estimatedArrival: newEst);
      }
    }

    return updated;
  }
}

