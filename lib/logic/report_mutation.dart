import '../models/report.dart';

enum ReportMutationAction { confirm, flag, resolve, recheck }

/// A later observation is distinct from a unique vote or reward event.
class ReportRecheck {
  static const interval = Duration(minutes: 30);
  static DateTime? availableAt(Report report) {
    var latest = report.createdAt;
    if (latest == null) return null;
    for (final date in [report.lastConfirmedAt, report.lastRecheckedAt]) {
      if (date != null && date.isAfter(latest!)) latest = date;
    }
    return latest!.add(interval);
  }

  static bool canRecheck(Report report, String actor, DateTime now) =>
      !report.isV2 &&
      report.isPublic &&
      report.status == 'active' &&
      report.falseCount < 3 &&
      report.flaggedBy.length < 3 &&
      actor.isNotEmpty &&
      actor != report.userId &&
      report.confirmedBy.contains(actor) &&
      !report.flaggedBy.contains(actor) &&
      availableAt(report) != null &&
      !now.isBefore(availableAt(report)!);
}

class ReportMutationPlan {
  const ReportMutationPlan({
    required this.before,
    required this.after,
    required this.actorId,
    required this.action,
    required this.changed,
  });
  final Report before;
  final Report after;
  final String actorId;
  final ReportMutationAction action;
  final bool changed;

  static ReportMutationPlan apply(
    Report report,
    String actorId,
    ReportMutationAction action,
    DateTime now, {
    String? recheckId,
  }) {
    if (report.isV2) {
      throw StateError('Policy v2 requires the trusted moderation service.');
    }
    if (report.createdAt == null) {
      throw StateError(
        'Observation time unknown. Submit a new dated observation.',
      );
    }
    if (actorId.trim().isEmpty || !report.isPublic || report.id.isEmpty) {
      throw StateError('Sign in and select a published report.');
    }
    ReportMutationPlan result(Report after, bool changed) => ReportMutationPlan(
      before: report,
      after: after,
      actorId: actorId,
      action: action,
      changed: changed,
    );
    if (action == ReportMutationAction.resolve) {
      if (actorId != report.userId) {
        throw StateError('Only the report author can mark it resolved.');
      }
      if (report.status == 'resolved') return result(report, false);
      if (report.status != 'active') {
        throw StateError('This report is no longer active.');
      }
      return result(
        report.copyWith(
          status: 'resolved',
          resolvedBy: actorId,
          resolvedAt: now,
        ),
        true,
      );
    }
    if (actorId == report.userId) {
      throw StateError('Authors cannot vote on their own reports.');
    }
    if (action == ReportMutationAction.flag &&
        report.flaggedBy.contains(actorId)) {
      return result(report, false);
    }
    if (action == ReportMutationAction.confirm &&
        report.confirmedBy.contains(actorId)) {
      return result(report, false);
    }
    if (report.status != 'active' || report.falseCount >= 3) {
      throw StateError('This report is no longer active.');
    }
    final confirmed = report.confirmedBy.toSet();
    final flagged = report.flaggedBy.toSet();
    if (confirmed.intersection(flagged).isNotEmpty ||
        report.confirmCount != confirmed.length ||
        report.falseCount != flagged.length) {
      throw StateError(
        'This report has inconsistent vote records. Refresh it before trying again.',
      );
    }
    if (action == ReportMutationAction.recheck) {
      if (!report.confirmedBy.contains(actorId) ||
          report.flaggedBy.contains(actorId) ||
          report.status != 'active' ||
          report.falseCount >= 3 ||
          report.flaggedBy.length >= 3) {
        throw StateError(
          'Only a previous confirmer can recheck an active report.',
        );
      }
      if (!ReportRecheck.canRecheck(report, actorId, now)) {
        return result(report, false);
      }
      if (recheckId == null || recheckId.trim().isEmpty) {
        throw StateError('A dated recheck record is required.');
      }
      return result(
        report.copyWith(
          lastRecheckedAt: now,
          lastRecheckedBy: actorId,
          lastRecheckId: recheckId,
        ),
        true,
      );
    }
    if (action == ReportMutationAction.confirm) {
      flagged.remove(actorId);
      confirmed.add(actorId);
      return result(
        report.copyWith(
          confirmedBy: confirmed.toList(),
          confirmCount: confirmed.length,
          flaggedBy: flagged.toList(),
          falseCount: flagged.length,
          lastConfirmedAt: now,
        ),
        true,
      );
    }
    final reversing = confirmed.remove(actorId);
    flagged.add(actorId);
    return result(
      report.copyWith(
        confirmedBy: confirmed.toList(),
        confirmCount: confirmed.length,
        flaggedBy: flagged.toList(),
        falseCount: flagged.length,
        clearLastConfirmedAt: reversing,
        status: flagged.length >= 3 ? 'hidden' : 'active',
      ),
      true,
    );
  }
}

/// The transaction was acknowledged; exact server times may still need refreshing.
class ReportMutationResult {
  const ReportMutationResult({
    required this.action,
    required this.changed,
    this.report,
  });
  final ReportMutationAction action;
  final bool changed;
  final Report? report;
  String get message => !changed
      ? action == ReportMutationAction.recheck
            ? 'Recheck not saved. Wait 30 minutes after the latest check, then retry.'
            : 'This action was already recorded.'
      : report == null
      ? 'Change saved. Shared details will refresh when connected.'
      : switch (action) {
          ReportMutationAction.confirm =>
            'Confirmation saved to the shared report.',
          ReportMutationAction.recheck =>
            'Recheck saved. Unique confirmations and points are unchanged.',
          ReportMutationAction.flag =>
            report!.status == 'hidden'
                ? 'Flag saved. Report hidden after three independent flags.'
                : 'Flag saved to the shared report.',
          ReportMutationAction.resolve =>
            'Resolution saved to the shared report.',
        };
}
