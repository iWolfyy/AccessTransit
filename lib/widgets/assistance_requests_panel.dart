import '../l10n/localization_context.dart';
import '../l10n/assistance_receipt_presentation.dart';

import 'package:flutter/material.dart';

import '../models/boarding_request.dart';
import '../services/assistance_submission_service.dart';
import '../services/firestore_service.dart';
import 'assistance_labels.dart';
import '../screens/journey/assistance_request_status_screen.dart';

/// Own request history and durable uploads remain reachable after leaving the form.
class AssistanceRequestsPanel extends StatefulWidget {
  const AssistanceRequestsPanel({
    super.key,
    required this.userId,
    this.service,
    this.repository,
  });
  final String? userId;
  final AssistanceSubmissionService? service;
  final FirestoreService? repository;
  @override
  State<AssistanceRequestsPanel> createState() =>
      _AssistanceRequestsPanelState();
}

class _AssistanceRequestsPanelState extends State<AssistanceRequestsPanel> {
  late Stream<List<BoardingRequest>> updates;
  AssistanceSubmissionService get service =>
      widget.service ?? AssistanceSubmissionService.instance;
  FirestoreService get repository => widget.repository ?? FirestoreService();
  void _resetStream() {
    updates = widget.userId == null
        ? Stream.value([])
        : repository.streamBoardingRequestsForRider(widget.userId!);
  }

  @override
  void initState() {
    super.initState();
    _resetStream();
  }

  @override
  void didUpdateWidget(covariant AssistanceRequestsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) _resetStream();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: service,
    builder: (context, _) {
      if (widget.userId == null || service.currentRiderId != widget.userId) {
        return const SizedBox.shrink();
      }
      return StreamBuilder<List<BoardingRequest>>(
        stream: updates,
        builder: (context, snapshot) {
          final rows = <String, (BoardingRequest, String)>{};
          for (final entry in service.entries.where(
            (e) => e.request.riderId == widget.userId,
          )) {
            rows[entry.request.id] = (
              entry.request,
              entry.delivery == AssistanceDeliveryState.sent
                  ? assistanceStatus(context, entry.request)
                  : context.assistanceReceiptText(entry.delivery.label),
            );
          }
          for (final r in snapshot.data ?? <BoardingRequest>[]) {
            if (r.riderId == widget.userId) {
              rows[r.id] = (r, assistanceStatus(context, r));
            }
          }
          if (rows.isEmpty && !snapshot.hasError && service.loadError == null) {
            return const SizedBox.shrink();
          }
          final sorted = rows.values.toList()
            ..sort((a, b) => b.$1.createdAt.compareTo(a.$1.createdAt));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                context.l10n.assistReceiptHistory,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (snapshot.hasError)
                Text(context.l10n.assistReceiptHistoryStale),
              if (service.loadError != null)
                Text(context.assistanceReceiptText(service.loadError!)),
              for (final row in sorted.take(10))
                ListTile(
                  title: Text(
                    context.l10n.assistReceiptSummary(
                      row.$1.routeNo,
                      row.$1.stopName,
                    ),
                  ),
                  subtitle: Text(row.$2),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AssistanceRequestStatusScreen(
                        request: row.$1,
                        service: service,
                        repository: repository,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    },
  );
}
