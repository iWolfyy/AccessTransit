import 'evidence_refresh.dart';

import 'package:flutter/material.dart';

import '../logic/live_accessibility_evidence.dart';
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Accessibility',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Text(
                'Equipment checks are separate from live GPS. A working report does not verify the whole journey.',
              ),
              StreamBuilder<Bus?>(
                stream: busStream,
                builder: (context, snapshot) => BusRampObservation(
                  bus: snapshot.data?.id == widget.busId ? snapshot.data : null,
                ),
              ),
              if (snapshot.hasError)
                const Text(
                  'Condition updates unavailable. Working conditions are Unknown; earlier warnings are retained.',
                ),
              if (rampWarning)
                const Text(
                  'Vehicle ramp telemetry reports a problem. Equipment-check time is Unknown; check before boarding.',
                ),
              for (final section in sections)
                Builder(
                  builder: (context) {
                    final evidence = LiveAccessibilityEvidence.forEquipment(
                      reports: reports,
                      targetType: section.$2,
                      targetId: section.$3,
                      category: section.$4,
                      now: now,
                    );
                    final icon = switch (evidence.state) {
                      EquipmentObservation.unknown => Icons.help_outline,
                      EquipmentObservation.positive => Icons.info_outline,
                      _ => Icons.warning_amber_rounded,
                    };
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(icon),
                      title: Text(section.$1),
                      subtitle: Text(
                        section.$2 == 'bus' &&
                                rampWarning &&
                                const [
                                  EquipmentObservation.positive,
                                  EquipmentObservation.unknown,
                                ].contains(evidence.state)
                            ? 'Unknown — vehicle ramp warning needs checking'
                            : evidence.label,
                      ),
                    );
                  },
                ),
              AccessibilityEvidenceCard(
                reports: reports,
                busId: widget.busId,
                origin: widget.originId ?? '',
                destination: widget.destinationId ?? '',
                strictStopIds: true,
                currentTime: now,
              ),
            ],
          );
        },
      );
    },
  );
}
