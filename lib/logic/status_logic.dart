import '../models/bus.dart';
import '../models/report.dart';
import '../models/enums/report_condition.dart';
import '../models/station.dart';
import '../screens/journey/route_results_screen.dart' show AccessibilityStatus;

/// Result structure containing computed accessibility status, reason strings, and active reports.
class BusStatusResult {
  const BusStatusResult({
    required this.status,
    required this.reasons,
    this.relevantReports = const [],
    this.rampWorking = false,
  });

  final AccessibilityStatus status;
  final List<String> reasons;
  final List<Report> relevantReports;
  final bool rampWorking;

  /// User-facing short label ('Safe', 'Warning', 'Not accessible').
  String get statusLabel {
    switch (status) {
      case AccessibilityStatus.accessible:
        return 'Safe';
      case AccessibilityStatus.partial:
        return 'Warning';
      case AccessibilityStatus.notAccessible:
        return 'Not accessible';
      case AccessibilityStatus.unknown:
        return 'Unknown';
    }
  }
}

/// Pure logic utility for checking report expiry and calculating bus accessibility status.
class StatusLogic {
  const StatusLogic._();

  /// Confirmations may refresh evidence only with an account and valid timestamp.
  static DateTime? lastCheckedAt(Report report, {DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();
    final created = report.observedAt ?? report.createdAt;
    if (created == null) return null;
    final confirmed = report.lastConfirmedAt;
    final confirmation =
        confirmed != null &&
            report.confirmedBy.any((id) => id.trim().isNotEmpty) &&
            !confirmed.isBefore(created) &&
            !confirmed.isAfter(now)
        ? confirmed
        : created;
    final rechecked = report.lastRecheckedAt;
    return rechecked != null &&
            report.lastRecheckId?.trim().isNotEmpty == true &&
            report.lastRecheckedBy?.trim().isNotEmpty == true &&
            report.confirmedBy.contains(report.lastRecheckedBy) &&
            !report.flaggedBy.contains(report.lastRecheckedBy) &&
            !rechecked.isBefore(confirmation) &&
            !rechecked.isAfter(now)
        ? rechecked
        : confirmation;
  }

  /// These are product defaults, not guarantees about physical conditions.
  static Duration freshnessWindow(Report report) {
    final text = '${report.subCategory} ${report.problemType}'.toLowerCase();
    if (report.category == 'crowding' ||
        RegExp(r'seats (free|occupied)|bay blocked|wheelchair bay')
            .hasMatch(text)) {
      return const Duration(minutes: 30);
    }
    if (report.category == 'driverAssistanceDenied' ||
        text.contains('reckless') ||
        text.contains('blocked')) {
      return const Duration(hours: 2);
    }
    if (report.category == 'cleanliness') return const Duration(hours: 6);
    return const Duration(hours: 24);
  }

  static bool isPersistentBarrier(Report report) =>
      report.observedCondition == ReportCondition.barrier &&
      (report.category == 'elevatorOut' ||
          RegExp(
            r'broken|damaged|jammed|power failure|out of service|not working|missing|unsafe gap',
            caseSensitive: false,
          ).hasMatch('${report.subCategory} ${report.problemType}'));

  static bool isReportFresh(Report report, {DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();
    final checked = lastCheckedAt(report, currentTime: now);
    if (checked == null || report.createdAt!.isAfter(now)) return false;
    final age = now.difference(checked);
    return !report.createdAt!.isAfter(now) &&
        age >= Duration.zero &&
        age <= freshnessWindow(report);
  }

  static DateTime? freshUntil(Report report, {DateTime? currentTime}) =>
      lastCheckedAt(
        report,
        currentTime: currentTime,
      )?.add(freshnessWindow(report));

  static bool needsRecheck(Report report, {DateTime? currentTime}) =>
      isReportActive(report, currentTime: currentTime) &&
      isPersistentBarrier(report) &&
      !isReportFresh(report, currentTime: currentTime);

  static bool hasFreshCrowding(Report report, {DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();
    final checked = lastCheckedAt(report, currentTime: now);
    if (checked == null || report.createdAt!.isAfter(now)) return false;
    final age = now.difference(checked);
    return age >= Duration.zero && age <= const Duration(minutes: 30);
  }

  static ReportCondition planningCondition(
    Report report, {
    DateTime? currentTime,
  }) => report.createdAt == null && !isPersistentBarrier(report)
      ? ReportCondition.unknown
      : hasFreshCrowding(report, currentTime: currentTime)
      ? report.effectiveCondition
      : report.observedCondition;

  static String freshnessLabel(Report report, {DateTime? currentTime}) {
    if (report.status.toLowerCase() == 'resolved') return 'Resolved';
    if (report.createdAt == null) {
      return needsRecheck(report, currentTime: currentTime)
          ? 'Unresolved barrier - observation time unknown; needs recheck'
          : 'Observation time unknown';
    }
    if (!isReportActive(report, currentTime: currentTime)) {
      return 'Expired or unavailable';
    }
    if (needsRecheck(report, currentTime: currentTime)) {
      return 'Unresolved barrier — needs recheck';
    }
    return 'Recent observation';
  }

  /// Structural barriers remain unresolved until explicitly resolved/hidden.
  /// Being relevant to planning does not mean an old observation is fresh.
  static bool isReportActive(Report report, {DateTime? currentTime}) {
    if (!report.isPublic) return false;
    if (report.status.trim().toLowerCase() != 'active') {
      return false;
    }
    if (report.isDisputed) {
      return false;
    }

    final now = currentTime ?? DateTime.now();
    final timestamp = lastCheckedAt(report, currentTime: now);
    if (timestamp == null) return isPersistentBarrier(report);
    final difference = now.difference(timestamp);

    return difference >= Duration.zero &&
        !report.createdAt!.isAfter(now) &&
        (isPersistentBarrier(report) || difference <= freshnessWindow(report));
  }

  /// Calculates the dynamic [BusStatusResult] for a [Bus] route (AC-74).
  ///
  /// Evaluates in exact order:
  /// 1. No ramp AND not low floor -> [AccessibilityStatus.notAccessible] (Not accessible)
  /// 2. Broken ramp or active barrier -> Warning; positive reports do not clear barriers.
  /// 3. Unclassified active observation -> Unknown.
  /// 4. Otherwise -> accessible according to vehicle data and known observations.
  /// With both station IDs, only boarding/alighting station reports apply.
  /// Required access at either endpoint is Unknown when it cannot be established.
  static BusStatusResult getBusStatus(
    Bus bus,
    List<Report> allReports, {
    Map<String, Station>? stationsMap,
    DateTime? currentTime,
    String? fromStationId,
    String? toStationId,
    bool wheelchairAccessRequired = false,
    bool stepFreeOnly = false,
  }) {
    final activeReports = allReports
        .where((r) => isReportActive(r, currentTime: currentTime))
        .toList();

    final List<String> reasons = [];
    final List<String> positiveReasons = [];
    final List<String> unknownReasons = [];
    final List<Report> relevantReports = [];
    final scoped = fromStationId != null && toStationId != null;
    final accessStops = scoped
        ? {fromStationId, toStationId}
        : bus.stops.toSet();
    bool unsuitable = false;

    final rampCondition = bus.rampCondition(currentTime: currentTime);
    final rampReports = activeReports
        .where(
          (r) =>
              r.targetType == 'bus' &&
              r.targetId == bus.id &&
              r.category == 'rampAccess',
        )
        .toList();
    final hasBarrier =
        rampCondition == false ||
        rampReports.any((r) => r.observedCondition == ReportCondition.barrier);
    final workingReport = rampReports.any(
      (r) =>
          isReportFresh(r, currentTime: currentTime) &&
          r.observedCondition == ReportCondition.positive,
    );
    final rampWorking =
        bus.hasRamp && !hasBarrier && (rampCondition == true || workingReport);
    final unknownRamp = bus.hasRamp && !hasBarrier && !rampWorking;
    if (unknownRamp) {
      unknownReasons.add(
        'Ramp equipped; operational condition Unknown. A dated check is required.',
      );
    }
    if (wheelchairAccessRequired && !rampWorking && !unknownRamp) {
      unsuitable = true;
      reasons.add(
        'An operational wheelchair ramp is required for this journey.',
      );
    }
    if (stepFreeOnly && !bus.lowFloor && !rampWorking && !unknownRamp) {
      unsuitable = true;
      reasons.add('Step-free boarding is not available on this vehicle.');
    }

    if (scoped && (wheelchairAccessRequired || stepFreeOnly)) {
      for (final stopId in accessStops) {
        final station = stationsMap?[stopId];
        final observedAccess = activeReports.any(
          (r) =>
              r.targetType.toLowerCase() == 'station' &&
              r.targetId == stopId &&
              planningCondition(r, currentTime: currentTime) ==
                  ReportCondition.positive &&
              (r.category == 'rampAccess' || r.category == 'elevatorOut') &&
              (r.condition != null ||
                  const {
                    'ramp clear',
                    'ramp working',
                    'elevator working',
                  }.contains(
                    (r.subCategory.trim().isNotEmpty
                            ? r.subCategory
                            : r.problemType.split('•').last)
                        .trim()
                        .toLowerCase(),
                  )),
        );
        final knownAccess =
            station?.stepFreeAccess ??
            (station != null && (station.hasRamp || station.hasElevator)
                ? true
                : observedAccess
                ? true
                : null);
        final name = station?.name ?? stopId;
        if (knownAccess == false) {
          unsuitable = true;
          reasons.add('No step-free access at $name.');
        } else if (knownAccess == null) {
          unknownReasons.add('Step-free access at $name is unknown.');
        }
      }
    }

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

    void addObservation(Report report, String target) {
      relevantReports.add(report);
      if (needsRecheck(report, currentTime: currentTime)) {
        isWarning = true;
        reasons.add(
          'Unresolved issue at $target: ${report.problemType}. Last checked ${lastCheckedAt(report, currentTime: currentTime)?.toLocal() ?? 'Unknown'}; needs recheck.',
        );
        return;
      }
      switch (planningCondition(report, currentTime: currentTime)) {
        case ReportCondition.barrier:
          isWarning = true;
          final crowding =
              report.crowdingLevel == 'high' &&
                  hasFreshCrowding(report, currentTime: currentTime)
              ? ' (crowding: high)'
              : '';
          reasons.add(
            'Active issue at $target: ${report.problemType}$crowding',
          );
        case ReportCondition.positive:
          positiveReasons.add(
            'Positive condition at $target: ${report.problemType}',
          );
        case ReportCondition.unknown:
          unknownReasons.add(
            'Condition unknown at $target: ${report.problemType}',
          );
      }
    }

    // 2a. Vehicle ramp marked broken
    if (rampCondition == false) {
      isWarning = true;
      reasons.add(
        'Ramp reported broken: Vehicle wheelchair ramp is reported out of service.',
      );
    }

    // 2b. Active report on the bus itself
    final busReports = activeReports.where(
      (r) => r.targetType.toLowerCase() == 'bus' && r.targetId == bus.id,
    );
    for (final r in busReports) {
      addObservation(r, 'vehicle');
    }

    // 2c. Active report on any station along the bus's stops list
    for (final stopId in accessStops) {
      final stationReports = activeReports.where(
        (r) => r.targetType.toLowerCase() == 'station' && r.targetId == stopId,
      );
      for (final r in stationReports) {
        final stationName = stationsMap?[stopId]?.name ?? 'Station $stopId';
        addObservation(r, stationName);
      }
    }

    reasons.addAll(unknownReasons);
    reasons.addAll(positiveReasons);

    // ── 3. Safe Rule ──────────────────────────────────────────────────────
    if (reasons.isEmpty) {
      reasons.add(
        'Vehicle lists accessible boarding; no active barriers reported.',
      );
    }
    return BusStatusResult(
      status: unsuitable
          ? AccessibilityStatus.notAccessible
          : isWarning
          ? AccessibilityStatus.partial
          : unknownReasons.isNotEmpty
          ? AccessibilityStatus.unknown
          : AccessibilityStatus.accessible,
      reasons: reasons,
      relevantReports: relevantReports,
      rampWorking: rampWorking,
    );
  }
}
