import '../../widgets/accessible_dropdown.dart';

import 'package:flutter/material.dart';

import '../../l10n/localization_context.dart';
import '../../l10n/journey_presentation.dart';
import '../../l10n/report_form_presentation.dart';
import '../../logic/status_logic.dart';
import '../../services/bus_details_repository.dart';
import '../../services/segment_reports.dart';
import '../../widgets/evidence_refresh.dart';
import '../community/report_details_screen.dart';

class SegmentReportsScreen extends StatefulWidget {
  const SegmentReportsScreen({
    super.key,
    required this.busId,
    required this.busName,
    required this.stops,
    required this.repository,
  });
  final String busId, busName;
  final Map<String, String> stops;
  final BusDetailsRepository repository;
  @override
  State<SegmentReportsScreen> createState() => _SegmentReportsScreenState();
}

class _SegmentReportsScreenState extends State<SegmentReportsScreen> {
  late ReportTarget target = ReportTarget('bus', widget.busId);
  final cursors = <String?>[null];
  late Stream<SegmentReportPage> stream = read();
  Stream<SegmentReportPage> read() =>
      widget.repository.reportPage(target, after: cursors.last);
  void refresh() {
    setState(() => stream = read());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.l10n.communityReports),
      actions: [
        IconButton(
          tooltip: context.l10n.operationsRefresh,
          onPressed: refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: StreamBuilder<SegmentReportPage>(
      stream: stream,
      builder: (context, snapshot) {
        final page =
            snapshot.hasError ||
                snapshot.connectionState == ConnectionState.waiting
            ? null
            : snapshot.data;
        final rows =
            page?.reports
                .where(
                  (r) => r.targetType == target.type && r.targetId == target.id,
                )
                .toList() ??
            [];
        return EvidenceRefresh(
          reports: rows,
          builder: (context, now) {
            final visible = rows
                .where((r) => StatusLogic.isReportActive(r, currentTime: now))
                .toList();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(context.l10n.segmentReportsHelp),
                DropdownButtonFormField<String>(
                  itemHeight: null,
                  initialValue: target.key,
                  isExpanded: true,
                  items: [
                    AccessibleDropdownMenuItem(
                      value: 'bus/${widget.busId}',
                      child: Text(
                        widget.busName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    for (final stop in widget.stops.entries)
                      AccessibleDropdownMenuItem(
                        value: 'station/${stop.key}',
                        child: Text(
                          stop.value,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (key) {
                    if (key == null) return;
                    setState(() {
                      final split = key.indexOf('/');
                      target = ReportTarget(
                        key.substring(0, split),
                        key.substring(split + 1),
                      );
                      cursors
                        ..clear()
                        ..add(null);
                      stream = read();
                    });
                  },
                ),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator()),
                if (snapshot.hasError)
                  Text(context.l10n.segmentReportsUnavailable),
                if (page != null && visible.isEmpty)
                  Text(context.l10n.segmentReportsEmptyPage),
                for (final r in visible)
                  Card(
                    child: ListTile(
                      title: Text(context.reportFormText(r.problemType)),
                      subtitle: Text(
                        '${r.targetName}\n${context.journeyText(StatusLogic.freshnessLabel(r, currentTime: now))}',
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReportDetailsScreen(
                            report: r,
                            targetTitle: r.targetName,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (page != null)
                  Wrap(
                    spacing: 8,
                    children: [
                      if (cursors.length > 1)
                        OutlinedButton(
                          onPressed: () => setState(() {
                            cursors.removeLast();
                            stream = read();
                          }),
                          child: Text(context.l10n.savedTripsPrevious),
                        ),
                      if (page.next != null)
                        OutlinedButton(
                          onPressed: () => setState(() {
                            cursors.add(page.next);
                            stream = read();
                          }),
                          child: Text(context.l10n.savedTripsNext),
                        ),
                    ],
                  ),
              ],
            );
          },
        );
      },
    ),
  );
}
