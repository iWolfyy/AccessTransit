import '../models/bus.dart';
import '../models/report.dart';
import '../models/station.dart';
import '../screens/journey/route_results_screen.dart' show AccessibilityStatus;

/// Result structure containing computed accessibility status, reason strings, and active reports.
class BusStatusResult {
  const BusStatusResult({
    required this.status,
    required this.reasons,
    this.relevantReports = const [],
  });

  final AccessibilityStatus status;
  final List<String> reasons;
  final List<Report> relevantReports;

  /// User-facing short label ('Safe', 'Warning', 'Not accessible').
  String get statusLabel {
    switch (status) {
      case AccessibilityStatus.accessible:
        return 'Safe';
      case AccessibilityStatus.partial:
        return 'Warning';
      case AccessibilityStatus.notAccessible:
        return 'Not accessible';
    }
  }
}

/// Pure logic utility for checking report expiry and calculating bus accessibility status.
class StatusLogic {
  const StatusLogic._();

  /// Checks if a [Report] is active and within the 12-hour expiry threshold (AC-74).
  ///
  /// Returns `true` if `report.status == 'active'` AND timestamp (either [lastConfirmedAt]
  /// or [createdAt]) is within 12 hours of [currentTime] (defaults to `DateTime.now()`).
  static bool isReportActive(Report report, {DateTime? currentTime}) {
    if (report.status.trim().toLowerCase() != 'active') {
      return false;
    }

    final now = currentTime ?? DateTime.now();
    final timestamp = report.lastConfirmedAt ?? report.createdAt;
    final difference = now.difference(timestamp);

    // Active if created/confirmed within the last 12 hours
    return difference >= Duration.zero && difference <= const Duration(hours: 12);
  }

  /// Calculates the dynamic [BusStatusResult] for a [Bus] route (AC-74).
  ///
  /// Evaluates in exact order:
  /// 1. No ramp AND not low floor -> [AccessibilityStatus.notAccessible] (Not accessible)
  /// 2. rampOk == false OR active report on bus OR active report on any stop station -> [AccessibilityStatus.partial] (Warning)
  /// 3. Otherwise -> [AccessibilityStatus.accessible] (Safe)
  static BusStatusResult getBusStatus(
    Bus bus,
    List<Report> allReports, {
    Map<String, Station>? stationsMap,
    DateTime? currentTime,
  }) {
    final activeReports = allReports
        .where((r) => isReportActive(r, currentTime: currentTime))
        .toList();

    final List<String> reasons = [];
    final List<Report> relevantReports = [];

    // ── 1. Check Not Accessible Rule ──────────────────────────────────────
    if (!bus.hasRamp && !bus.lowFloor) {
      reasons.add('No ramp and no low-floor access on this vehicle.');
      return BusStatusResult(
        status: AccessibilityStatus.notAccessible,
        reasons: reasons,
        relevantReports: relevantReports,
      );
    }

    // ── 2. Check Warning Rule ─────────────────────────────────────────────
    bool isWarning = false;

    // 2a. Vehicle ramp marked broken
    if (!bus.rampOk) {
      isWarning = true;
      reasons.add('Vehicle wheelchair ramp is reported out of service or broken.');
    }

    // 2b. Active report on the bus itself
    final busReports = activeReports.where(
      (r) => r.targetType.toLowerCase() == 'bus' && r.targetId == bus.id,
    );
    for (final r in busReports) {
      isWarning = true;
      relevantReports.add(r);
      reasons.add('Vehicle report: ${r.problemType}');
    }

    // 2c. Active report on any station along the bus's stops list
    for (final stopId in bus.stops) {
      final stationReports = activeReports.where(
        (r) => r.targetType.toLowerCase() == 'station' && r.targetId == stopId,
      );
      for (final r in stationReports) {
        isWarning = true;
        relevantReports.add(r);
        final stationName =
            stationsMap?[stopId]?.name ?? 'Station $stopId';
        reasons.add('Active issue at $stationName: ${r.problemType}');
      }
    }

    if (isWarning) {
      return BusStatusResult(
        status: AccessibilityStatus.partial,
        reasons: reasons,
        relevantReports: relevantReports,
      );
    }

    // ── 3. Safe Rule ──────────────────────────────────────────────────────
    reasons.add('Step-free boarding · Ramp operational & verified.');
    return BusStatusResult(
      status: AccessibilityStatus.accessible,
      reasons: reasons,
      relevantReports: relevantReports,
    );
  }
}
