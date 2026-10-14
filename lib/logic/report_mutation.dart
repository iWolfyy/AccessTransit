import '../models/report.dart';

enum ReportMutationAction { confirm, flag, resolve }

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
    DateTime now,
  ) {
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
      ? 'This action was already recorded.'
      : report == null
      ? 'Change saved. Shared details will refresh when connected.'
      : switch (action) {
          ReportMutationAction.confirm =>
            'Confirmation saved to the shared report.',
          ReportMutationAction.flag =>
            report!.status == 'hidden'
                ? 'Flag saved. Report hidden after three independent flags.'
                : 'Flag saved to the shared report.',
          ReportMutationAction.resolve =>
            'Resolution saved to the shared report.',
        };
}
