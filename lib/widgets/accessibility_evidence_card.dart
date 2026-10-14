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
  });

  final List<Report> reports;
  final String busId;
  final String origin;
  final String destination;
  final DateTime? currentTime;
  final bool strictStopIds;

  bool _atStop(Report report, String stop) =>
      stop.trim().isNotEmpty &&
      report.targetType.toLowerCase() == 'station' &&
      (report.targetId == stop ||
          (!strictStopIds &&
              report.targetName.trim().isNotEmpty &&
              report.targetName.trim().toLowerCase() ==
                  stop.trim().toLowerCase()));

  String _time(DateTime time) =>
      '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
      '${TimeUtils.formatTimeString(time)}';

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
        !confirmedAt.isBefore(report.createdAt) &&
        !confirmedAt.isAfter(now);
    final isCurrent = StatusLogic.isReportActive(report, currentTime: now);
    final String state;
    if (!isCurrent) {
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
  Widget build(BuildContext context) {
    final now = currentTime ?? DateTime.now();
    final eligible =
        reports
            .where(
              (r) =>
                  r.isPublic &&
                  r.status.toLowerCase() == 'active' &&
                  r.falseCount < 3 &&
                  r.flaggedBy.length < 3 &&
                  !r.createdAt.isAfter(now),
            )
            .toList()
          ..sort(
            (a, b) => StatusLogic.lastCheckedAt(
              b,
              currentTime: now,
            ).compareTo(StatusLogic.lastCheckedAt(a, currentTime: now)),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.isHighContrast
              ? Colors.black
              : AppColors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accessibility evidence',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Community observations describe specific conditions; they do not verify the entire journey.',
            style: TextStyle(color: context.subtextColor),
          ),
          for (final section in sections) ...[
            const Divider(height: 24),
            Text(
              section.$1,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            if (section.$2.isEmpty)
              Text(
                'Unknown — no observation available',
                style: TextStyle(color: context.subtextColor),
              ),
            for (final report in section.$2) _observation(context, report, now),
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
    final ids = {widget.reporter.trim(), ...widget.confirmers}..remove('');
    final service = UserService();
    final entries = await Future.wait(
      ids.map((id) async {
        final profile = await service.getUser(id);
        final name = profile?.name.trim();
        return MapEntry(
          id,
          name != null && name.isNotEmpty ? name : 'Account $id',
        );
      }),
    );
    return Map.fromEntries(entries);
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
          id.trim().isEmpty ? 'Unknown' : names[id] ?? 'Account $id';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reported by: ${name(widget.reporter)}',
            style: TextStyle(color: context.subtextColor),
          ),
          if (widget.confirmers.isNotEmpty)
            Text(
              'Confirmed by: ${widget.confirmers.map(name).join(', ')}',
              style: TextStyle(color: context.subtextColor),
            ),
        ],
      );
    },
  );
}
