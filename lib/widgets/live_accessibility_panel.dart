import 'evidence_refresh.dart';

import 'package:flutter/material.dart';

import '../logic/live_accessibility_evidence.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../models/report.dart';
import '../models/bus_location_model.dart';
import '../models/enums/report_condition.dart';
import '../services/firestore_service.dart';
import 'accessibility_evidence_card.dart';
import 'bus_ramp_observation.dart';
import '../models/bus.dart';

/// Shared reports for this vehicle and these endpoints, independently of GPS.
class LiveAccessibilityPanel extends StatefulWidget {
  const LiveAccessibilityPanel({
    super.key,
    required this.busId,
    required this.origin,
    required this.destination,
    this.originId,
    this.destinationId,
    this.reportsStream,
    this.now,
    this.telemetry,
  });
  final String busId;
  final String origin;
  final String destination;
  final String? originId;
  final String? destinationId;
  final Stream<List<Report>>? reportsStream;
  final DateTime Function()? now;
  final BusLocationModel? telemetry;

  @override
  State<LiveAccessibilityPanel> createState() => _LiveAccessibilityPanelState();
}

class _LiveAccessibilityPanelState extends State<LiveAccessibilityPanel> {
  late Stream<List<Report>> stream;
  List<Report> lastReports = const [];
  late Stream<Bus?> busStream;
  bool showDetails = false;
  @override
  void initState() {
    super.initState();
    busStream = FirestoreService().streamBusById(widget.busId);
    stream =
        widget.reportsStream ??
        FirestoreService().streamReports(surfaceErrors: true);
  }

  @override
  void didUpdateWidget(covariant LiveAccessibilityPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.busId != widget.busId ||
        oldWidget.originId != widget.originId ||
        oldWidget.destinationId != widget.destinationId) {
      showDetails = false;
    }
    if (oldWidget.busId != widget.busId) {
      busStream = FirestoreService().streamBusById(widget.busId);
    }
    if (oldWidget.reportsStream != widget.reportsStream) {
      stream =
          widget.reportsStream ??
          FirestoreService().streamReports(surfaceErrors: true);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Report>>(
    stream: stream,
    builder: (context, snapshot) {
      if (snapshot.hasData && !snapshot.hasError) lastReports = snapshot.data!;
      // Failed reads cannot establish a current working condition.
      final reports = snapshot.hasError
          ? lastReports
                .where((r) => r.observedCondition == ReportCondition.barrier)
                .toList()
          : snapshot.data ?? <Report>[];
      return EvidenceRefresh(
        reports: reports,
        now: widget.now,
        builder: (context, now) {
          final sections = [
            ('Vehicle ramp', 'bus', widget.busId, 'rampAccess'),
            (
              'Boarding stop elevator — ${widget.origin}',
              'station',
              widget.originId,
              'elevatorOut',
            ),
            (
              'Destination stop elevator — ${widget.destination}',
              'station',
              widget.destinationId,
              'elevatorOut',
            ),
          ];
          final rampWarning =
              widget.telemetry?.busId == widget.busId &&
              widget.telemetry?.rampOperational == false;

          final assistance = LiveAccessibilityEvidence.forEquipment(
            reports: reports,
            targetType: 'bus',
            targetId: widget.busId,
            category: 'driverAssistanceDenied',
            now: now,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Live Accessibility',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Equipment checks are separate from live GPS. A working report does not verify the whole journey.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: context.subtextColor,
                ),
              ),
              const SizedBox(height: 16),
              if (snapshot.hasError) ...[
                _warning(
                  context,
                  'Condition updates unavailable. Working conditions are Unknown; earlier warnings are retained.',
                ),
                const SizedBox(height: 16),
              ],
              if (rampWarning) ...[
                _warning(
                  context,
                  'Vehicle ramp telemetry reports a problem. Equipment-check time is Unknown; check before boarding.',
                ),
                const SizedBox(height: 16),
              ],
              Material(
                color: context.cardColor,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: context.isHighContrast
                        ? Colors.black
                        : AppColors.outlineVariant.withValues(alpha: .6),
                    width: context.isHighContrast ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Community observations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      for (var i = 0; i < sections.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        Builder(
                          builder: (context) {
                            final section = sections[i];
                            final evidence =
                                LiveAccessibilityEvidence.forEquipment(
                                  reports: reports,
                                  targetType: section.$2,
                                  targetId: section.$3,
                                  category: section.$4,
                                  now: now,
                                );
                            final telemetryConflict =
                                section.$2 == 'bus' &&
                                rampWarning &&
                                const [
                                  EquipmentObservation.positive,
                                  EquipmentObservation.unknown,
                                ].contains(evidence.state);
                            return _conditionRow(
                              context,
                              section.$1,
                              evidence,
                              warning: telemetryConflict,
                              label: telemetryConflict
                                  ? 'Unknown \u2014 vehicle ramp warning needs checking'
                                  : null,
                            );
                          },
                        ),
                      ],
                      if (assistance.reports.isNotEmpty) ...[
                        const Divider(height: 1),
                        _conditionRow(
                          context,
                          'Driver assistance',
                          assistance,
                          label:
                              assistance.state == EquipmentObservation.positive
                              ? 'Positive assistance observation'
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Operator vehicle check',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.subtextColor,
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<Bus?>(
                stream: busStream,
                builder: (context, snapshot) => BusRampObservation(
                  bus: snapshot.data?.id == widget.busId ? snapshot.data : null,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => showDetails = !showDetails),
                  icon: Icon(
                    showDetails
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
                  label: Text(
                    showDetails
                        ? 'Hide observation details'
                        : 'View observation details',
                  ),
                ),
              ),
              if (showDetails)
                AccessibilityEvidenceCard(
                  reports: reports,
                  busId: widget.busId,
                  origin: widget.originId ?? '',
                  destination: widget.destinationId ?? '',
                  strictStopIds: true,
                  currentTime: now,
                  initiallyExpanded: true,
                ),
            ],
          );
        },
      );
    },
  );

  Widget _conditionRow(
    BuildContext context,
    String title,
    LiveAccessibilityEvidence evidence, {
    bool warning = false,
    String? label,
  }) {
    final barrier =
        warning ||
        const [
          EquipmentObservation.barrier,
          EquipmentObservation.unresolved,
        ].contains(evidence.state);
    final color = context.isHighContrast
        ? Colors.black
        : barrier
        ? AppColors.error
        : evidence.state == EquipmentObservation.positive
        ? AppColors.secondary
        : context.subtextColor;
    final icon = barrier
        ? Icons.warning_amber_rounded
        : evidence.state == EquipmentObservation.positive
        ? Icons.info_outline_rounded
        : Icons.help_outline_rounded;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label ?? evidence.label,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _warning(BuildContext context, String message) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: context.isHighContrast
          ? Colors.white
          : AppColors.errorContainer.withValues(alpha: .3),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: context.isHighContrast
            ? Colors.black
            : AppColors.error.withValues(alpha: .4),
        width: context.isHighContrast ? 2 : 1,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.warning_amber_rounded,
          size: 22,
          color: context.isHighContrast ? Colors.black : AppColors.error,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: context.isHighContrast ? Colors.black : context.textColor,
            ),
          ),
        ),
      ],
    ),
  );
}
