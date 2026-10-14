import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/boarding_request.dart';
import '../services/firestore_service.dart';

/// Acknowledged transition feedback; failed writes keep the previous status.
class AssistanceOperatorActions extends StatefulWidget {
  const AssistanceOperatorActions({
    super.key,
    required this.request,
    required this.repository,
  });
  final BoardingRequest request;
  final FirestoreService repository;
  @override
  State<AssistanceOperatorActions> createState() =>
      _AssistanceOperatorActionsState();
}

class _AssistanceOperatorActionsState extends State<AssistanceOperatorActions> {
  late BoardingRequest request;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    request = widget.request;
  }

  @override
  void didUpdateWidget(covariant AssistanceOperatorActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request != widget.request) request = widget.request;
  }

  Future<void> change(String status) async {
    if (saving) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final saved = await widget.repository
          .updateBoardingRequestStatus(request.id, status)
          .timeout(const Duration(seconds: 15));
      if (mounted) setState(() => request = saved);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Status update was not confirmed. Check your connection, operator approval and bus assignment, then retry.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(request.driverStatusLabel),
      if (error != null) Text(error!),
      Wrap(
        spacing: 8,
        children: [
          if (request.status == 'pending') ...[
            OutlinedButton(
              onPressed: saving ? null : () => change('acknowledged'),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(0, context.minTapHeight),
              ),
              child: const Text('Acknowledge'),
            ),
            TextButton(
              onPressed: saving ? null : () => change('rejected'),
              child: const Text('Decline'),
            ),
          ],
          if (request.status == 'acknowledged')
            FilledButton(
              onPressed: saving ? null : () => change('completed'),
              style: FilledButton.styleFrom(
                minimumSize: Size(0, context.minTapHeight),
              ),
              child: const Text('Complete'),
            ),
        ],
      ),
      if (saving) const Text('Saving status…'),
    ],
  );
}
