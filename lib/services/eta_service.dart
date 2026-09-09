import 'package:latlong2/latlong.dart';

import '../models/bus_location_model.dart';
import '../models/enums/bus_status.dart';

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
        customStopLocation ?? getStopCoordinates(stopName) ?? getStopCoordinates(liveBus.nextStop);

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
    final distanceMeters = _distanceCalculator.distance(busLocation, targetLocation);

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
    final double effectiveSpeedKmH =
        (liveBus.speed >= 5.0) ? liveBus.speed : 20.0;
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
}
