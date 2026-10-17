import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/localization_context.dart';
import '../models/boarding_request.dart';
import '../services/firestore_service.dart';
import 'assistance_operator_actions.dart';
import 'assistance_labels.dart';

class RunAssistanceInbox extends StatefulWidget {
  const RunAssistanceInbox({
    super.key,
    required this.runId,
    required this.repository,
  });
  final String? runId;
  final FirestoreService repository;
  @override
  State<RunAssistanceInbox> createState() => _RunAssistanceInboxState();
}

class _RunAssistanceInboxState extends State<RunAssistanceInbox> {
  final rows = <BoardingRequest>[];
  String? next;
  bool busy = false, failed = false;
  int generation = 0, pages = 1;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    load();
    timer = Timer.periodic(const Duration(seconds: 15), (_) => load());
  }

  @override
  void didUpdateWidget(covariant RunAssistanceInbox old) {
    super.didUpdateWidget(old);
    if (old.runId != widget.runId) {
      generation++;
      pages = 1;
      rows.clear();
      next = null;
      busy = false;
      load();
    }
  }

  Future<void> load({bool more = false}) async {
    if (busy) return;
    if (widget.runId == null) {
      setState(() => rows.clear());
      return;
    }
    final version = ++generation, runId = widget.runId!;
    setState(() {
      busy = true;
      failed = false;
    });
    try {
      final result = <BoardingRequest>[];
      String? cursor;
      final wanted = pages + (more ? 1 : 0);
      int fetched = 0;
      do {
        final page = await widget.repository.moderationClient
            .assistanceRequests(runId: runId, after: cursor);
        result.addAll(page.items);
        cursor = page.next;
        fetched++;
      } while (cursor != null && fetched < wanted);
      if (!mounted || version != generation) return;
      setState(() {
        rows
          ..clear()
          ..addAll(result);
        next = cursor;
        pages = fetched;
      });
    } catch (_) {
      if (mounted && version == generation) {
        setState(() {
          rows.clear();
          next = null;
          failed = true;
        });
      }
    } finally {
      if (mounted && version == generation) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    generation++;
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.assistanceInbox,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (widget.runId == null)
            Text(context.l10n.assistanceChooseRun)
          else if (failed)
            Text(context.l10n.assistanceUnavailable)
          else if (rows.isEmpty && !busy)
            Text(context.l10n.assistanceEmpty),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${r.riderName} • ${r.stopName}'),
                  Text(
                    r.assistanceTypes
                        .map((t) => assistanceType(context, t))
                        .join(', '),
                  ),
                  if (r.assignmentVersion > 1 && r.status == 'pending')
                    Text(context.l10n.assistanceRetargeted),
                  AssistanceOperatorActions(
                    key: ValueKey('${r.id}-${r.assignmentVersion}-${r.status}'),
                    request: r,
                    repository: widget.repository,
                  ),
                ],
              ),
            ),
          ),
          if (busy) const LinearProgressIndicator(),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: busy ? null : () => load(),
                child: Text(context.l10n.accountStatusRetry),
              ),
              if (next != null)
                TextButton(
                  onPressed: busy ? null : () => load(more: true),
                  child: Text(context.l10n.reviewsMore),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
