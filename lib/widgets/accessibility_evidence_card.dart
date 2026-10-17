import 'evidence_refresh.dart';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/time_utils.dart';
import '../logic/status_logic.dart';
import '../models/enums/report_condition.dart';
import '../models/report.dart';
import '../services/user_service.dart';

/// Shows observation sources; vehicle capability flags are not verification.
class AccessibilityEvidenceCard extends StatelessWidget {
  const AccessibilityEvidenceCard({
    super.key,
    required this.reports,
    required this.busId,
    required this.origin,
    required this.destination,
    this.currentTime,
    this.strictStopIds = false,
    this.initiallyExpanded = false,
  });

  final List<Report> reports;
  final String busId;
  final String origin;
  final String destination;
  final DateTime? currentTime;
  final bool strictStopIds;
  final bool initiallyExpanded;

  bool _atStop(Report report, String stop) =>
      stop.trim().isNotEmpty &&
      report.targetType.toLowerCase() == 'station' &&
      (report.targetId == stop ||
          (!strictStopIds &&
              report.targetName.trim().isNotEmpty &&
              report.targetName.trim().toLowerCase() ==
                  stop.trim().toLowerCase()));

  String _time(DateTime? time) {
    if (time == null) return 'Unknown';
    final local = time.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${TimeUtils.formatTimeString(local)}';
  }

  /// An older unresolved barrier must remain visible beside newer positive checks.
  (String, IconData, bool) _summary(List<Report> observations, DateTime now) {
    if (observations.any(
      (r) => StatusLogic.needsRecheck(r, currentTime: now),
    )) {
      return (
        'Unresolved barrier - needs recheck',
        Icons.warning_amber_rounded,
        true,
      );
    }
    if (observations.any(
      (r) =>
          StatusLogic.isReportActive(r, currentTime: now) &&
          StatusLogic.planningCondition(r, currentTime: now) ==
              ReportCondition.barrier,
    )) {
      return (
        'Barrier reported - review before travel',
        Icons.warning_amber_rounded,
        true,
      );
    }
    if (observations.any(
      (r) =>
          StatusLogic.isReportActive(r, currentTime: now) &&
          StatusLogic.planningCondition(r, currentTime: now) ==
              ReportCondition.positive,
    )) {
      return (
        'Positive observation - view details',
        Icons.info_outline_rounded,
        false,
      );
    }
    return (
      'Unknown - no current observation',
      Icons.help_outline_rounded,
      false,
    );
  }

  Widget _observation(BuildContext context, Report report, DateTime now) {
    final accounts = report.confirmedBy
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final confirmedAt = report.lastConfirmedAt;
    final hasConfirmation =
        accounts.isNotEmpty &&
        confirmedAt != null &&
        report.createdAt != null &&
        !confirmedAt.isBefore(report.createdAt!) &&
        !confirmedAt.isAfter(now);
    final isCurrent = StatusLogic.isReportActive(report, currentTime: now);
    final String state;
    if (report.createdAt == null &&
        !StatusLogic.needsRecheck(report, currentTime: now)) {
      state = 'Unknown - observation time unavailable';
    } else if (!isCurrent) {
      state = 'Unknown — latest observation expired';
    } else if (StatusLogic.needsRecheck(report, currentTime: now)) {
      state = 'Unresolved barrier — needs recheck; current condition unknown';
    } else if (StatusLogic.planningCondition(report, currentTime: now) ==
        ReportCondition.unknown) {
      state = 'Unknown — condition could not be determined';
    } else if (hasConfirmation) {
      state =
          StatusLogic.planningCondition(report, currentTime: now) ==
              ReportCondition.barrier
          ? 'Barrier — community-confirmed observation'
          : 'Positive — community-confirmed observation';
    } else {
      state =
          StatusLogic.planningCondition(report, currentTime: now) ==
              ReportCondition.barrier
          ? 'Barrier reported — verification unknown'
          : 'Positive reported — verification unknown';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.problemType,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.textColor,
            ),
          ),
          Text(state, style: TextStyle(color: context.subtextColor)),
          Text(
            'Last checked: ${_time(StatusLogic.lastCheckedAt(report, currentTime: now))}',
            style: TextStyle(color: context.subtextColor),
          ),
          _AccountAttribution(reporter: report.userId, confirmers: accounts),
          if (report.lastRecheckedAt != null)
            Text(
              'Last recheck: ${_time(report.lastRecheckedAt!.isAfter(now) ? null : report.lastRecheckedAt)} by ${report.lastRecheckedBy?.trim().isNotEmpty == true ? 'Community member' : 'Unknown'}. Unique confirmations unchanged.',
              style: TextStyle(color: context.subtextColor),
            ),
          Text(
            '${StatusLogic.isPersistentBarrier(report) ? 'Recheck due' : 'Observation expires'}: ${_time(StatusLogic.freshUntil(report, currentTime: now))}',
            style: TextStyle(color: context.subtextColor),
          ),
          Text(
            'Reported at: ${_time(report.createdAt)}',
            style: TextStyle(color: context.subtextColor),
          ),
          if (hasConfirmation)
            Text(
              'Last confirmation recorded at: ${_time(confirmedAt)}',
              style: TextStyle(color: context.subtextColor),
            )
          else
            Text(
              'Confirmation time: Unknown',
              style: TextStyle(color: context.subtextColor),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => currentTime != null
      ? _buildAtTime(context, currentTime!)
      : EvidenceRefresh(reports: reports, builder: _buildAtTime);

  Widget _buildAtTime(BuildContext context, DateTime now) {
    final eligible =
        reports
            .where(
              (r) =>
                  r.isPublic &&
                  r.status.toLowerCase() == 'active' &&
                  !r.isDisputed &&
                  (r.createdAt == null || !r.createdAt!.isAfter(now)),
            )
            .toList()
          ..sort(
            (a, b) => Report.compareDatesDescending(
              StatusLogic.lastCheckedAt(a, currentTime: now),
              StatusLogic.lastCheckedAt(b, currentTime: now),
            ),
          );
    final vehicleReports = eligible
        .where(
          (r) => r.targetType.toLowerCase() == 'bus' && r.targetId == busId,
        )
        .toList();
    final sections = <(String, List<Report>)>[
      (
        'Vehicle ramp conditions',
        vehicleReports.where((r) => r.category == 'rampAccess').toList(),
      ),
      (
        'Boarding stop conditions',
        eligible.where((r) => _atStop(r, origin)).toList(),
      ),
      (
        'Destination stop conditions',
        eligible.where((r) => _atStop(r, destination)).toList(),
      ),
      (
        'Driver assistance observations',
        vehicleReports
            .where((r) => r.category == 'driverAssistanceDenied')
            .toList(),
      ),
    ];

    return Material(
      color: context.cardColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.isHighContrast
              ? Colors.black
              : AppColors.outlineVariant.withValues(alpha: 0.6),
          width: context.isHighContrast ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Accessibility evidence',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Community observations describe specific conditions; they do not verify the entire journey.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: context.subtextColor,
                  ),
                ),
              ],
            ),
          ),
          for (final section in sections) ...[
            const Divider(height: 1),
            if (section.$2.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.$1,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Unknown — no observation available',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.subtextColor,
                      ),
                    ),
                  ],
                ),
              )
            else
              Builder(
                builder: (context) {
                  final summary = _summary(section.$2, now);
                  final color = context.isHighContrast
                      ? Colors.black
                      : summary.$3
                      ? AppColors.error
                      : context.subtextColor;
                  return ExpansionTile(
                    key: PageStorageKey(
                      'evidence-$busId-$origin-$destination-${section.$1}',
                    ),
                    initiallyExpanded: initiallyExpanded,
                    shape: const Border(),
                    collapsedShape: const Border(),
                    tilePadding: const EdgeInsets.all(16),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                    title: Text(
                      section.$1,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.textColor,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(summary.$2, size: 18, color: color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              summary.$1,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    children: [
                      for (var i = 0; i < section.$2.length; i++) ...[
                        if (i > 0) const Divider(height: 24),
                        _observation(context, section.$2[i], now),
                      ],
                    ],
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}

class _AccountAttribution extends StatefulWidget {
  const _AccountAttribution({required this.reporter, required this.confirmers});
  final String reporter;
  final List<String> confirmers;

  @override
  State<_AccountAttribution> createState() => _AccountAttributionState();
}

class _AccountAttributionState extends State<_AccountAttribution> {
  late Future<Map<String, String>> _names;
  String _key(_AccountAttribution value) =>
      '${value.reporter}|${value.confirmers.join('|')}';

  Future<Map<String, String>> _loadNames() async {
    final id = widget.reporter.trim();
    if (id.isEmpty) return {};
    final profile = await UserService().getUser(id);
    final name = profile?.name.trim();
    return {id: name != null && name.isNotEmpty ? name : 'Community member'};
  }

  @override
  void initState() {
    super.initState();
    _names = _loadNames();
  }

  @override
  void didUpdateWidget(covariant _AccountAttribution oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_key(oldWidget) != _key(widget)) {
      _names = _loadNames();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, String>>(
    future: _names,
    builder: (context, snapshot) {
      final names = snapshot.data ?? const <String, String>{};
      String name(String id) =>
          id.trim().isEmpty ? 'Unknown' : names[id] ?? 'Community member';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reported by: ${name(widget.reporter)}',
            style: TextStyle(color: context.subtextColor),
          ),
          if (widget.confirmers.isNotEmpty)
            Text(
              'Confirmed by: ${widget.confirmers.length} community member${widget.confirmers.length == 1 ? '' : 's'}',
              style: TextStyle(color: context.subtextColor),
            ),
        ],
      );
    },
  );
}
