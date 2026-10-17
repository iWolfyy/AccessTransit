import '../models/report.dart';

class ReportCooldownException implements Exception {
  const ReportCooldownException(this.retryAt);
  final DateTime retryAt;
  @override
  String toString() =>
      'The same issue can be reported once every 5 minutes. Retry after ${retryAt.toUtc().toIso8601String()} (UTC). Your draft is saved.';
}

/// Stable categories, never editable wording or positive/negative conditions.
abstract final class ReportCooldown {
  static const interval = Duration(minutes: 5);
  static String path(Report report) {
    final parts = [
      report.userId,
      report.targetType,
      report.targetId,
      report.category,
    ];
    if (parts.any((p) => p.isEmpty || p.contains('/')) ||
        !const ['bus', 'station'].contains(report.targetType)) {
      throw ArgumentError('Invalid report cooldown identity.');
    }
    return 'report_cooldowns/${report.userId}/${report.targetType}/${report.targetId}/issues/${report.category}';
  }
}
