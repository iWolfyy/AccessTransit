import '../models/enums/report_condition.dart';
import '../models/report.dart';
import '../models/station.dart';
import 'status_logic.dart';

enum EquipmentObservation { unknown, positive, barrier, unresolved }

/// Equipment-specific evidence; GPS and capability flags are not a check record.
class LiveAccessibilityEvidence {
  const LiveAccessibilityEvidence(this.state, this.reports);
  final EquipmentObservation state;
  final List<Report> reports;
  String get label => switch (state) {
    EquipmentObservation.unknown => 'Unknown',
    EquipmentObservation.positive => 'Working reported',
    EquipmentObservation.barrier => 'Barrier reported',
    EquipmentObservation.unresolved => 'Unresolved barrier — needs recheck',
  };

  static String? resolveStopId(
    String name,
    Map<String, Station> stations, {
    String? preferredId,
  }) {
    if (preferredId != null &&
        stations.values.any(
          (s) =>
              s.id == preferredId &&
              (s.id == name ||
                  s.name.trim().toLowerCase() == name.trim().toLowerCase()),
        )) {
      return preferredId;
    }
    final matching = stations.values
        .where(
          (s) =>
              s.id == name ||
              s.name.trim().toLowerCase() == name.trim().toLowerCase(),
        )
        .map((s) => s.id)
        .toSet();
    return matching.length == 1 ? matching.single : null;
  }

  static LiveAccessibilityEvidence forEquipment({
    required List<Report> reports,
    required String targetType,
    required String? targetId,
    required String category,
    required DateTime now,
  }) {
    final scoped = targetId == null || targetId.isEmpty
        ? <Report>[]
        : reports
              .where(
                (r) =>
                    r.targetType.toLowerCase() == targetType &&
                    r.targetId == targetId &&
                    r.category == category &&
                    StatusLogic.isReportActive(r, currentTime: now),
              )
              .toList();
    final barriers = scoped
        .where((r) => r.observedCondition == ReportCondition.barrier)
        .toList();
    if (barriers.isNotEmpty) {
      return LiveAccessibilityEvidence(
        barriers.any((r) => StatusLogic.needsRecheck(r, currentTime: now))
            ? EquipmentObservation.unresolved
            : EquipmentObservation.barrier,
        scoped,
      );
    }
    // A newer uncertain observation cannot be erased by an older positive one.
    scoped.sort(
      (a, b) => Report.compareDatesDescending(
        StatusLogic.lastCheckedAt(a, currentTime: now),
        StatusLogic.lastCheckedAt(b, currentTime: now),
      ),
    );
    if (scoped.isEmpty) {
      return const LiveAccessibilityEvidence(EquipmentObservation.unknown, []);
    }
    final latest = StatusLogic.lastCheckedAt(scoped.first, currentTime: now);
    final positivesOnly = scoped
        .where((r) => StatusLogic.lastCheckedAt(r, currentTime: now) == latest)
        .every((r) => r.observedCondition == ReportCondition.positive);
    return LiveAccessibilityEvidence(
      positivesOnly
          ? EquipmentObservation.positive
          : EquipmentObservation.unknown,
      scoped,
    );
  }
}
