import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/boarding_request.dart';
import '../services/firestore_service.dart';
import '../l10n/localization_context.dart';
import 'assistance_labels.dart';

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
  bool failed = false;
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
      failed = false;
    });
    try {
      final saved = await widget.repository
          .updateBoardingRequestStatus(request.id, status)
          .timeout(const Duration(seconds: 15));
      if (mounted) setState(() => request = saved);
    } catch (_) {
      if (mounted) {
        setState(() => failed = true);
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(assistanceStatus(context, request)),
      if (failed)
        Text(
          request.policyVersion == 2
              ? context.l10n.assistanceUnavailable
              : context.l10n.sharedOperatorStatusError,
        ),
      Wrap(
        spacing: 8,
        children: [
          if (request.status == 'pending') ...[
            OutlinedButton(
              onPressed: saving ? null : () => change('acknowledged'),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(context.buttonHeight, context.minTapHeight),
              ),
              child: Text(context.l10n.assistanceAcknowledge),
            ),
            TextButton(
              onPressed: saving ? null : () => change('rejected'),
              child: Text(context.l10n.assistanceDecline),
            ),
          ],
          if (request.status == 'acknowledged')
            FilledButton(
              onPressed: saving ? null : () => change('completed'),
              style: FilledButton.styleFrom(
                minimumSize: Size(context.buttonHeight, context.minTapHeight),
              ),
              child: Text(context.l10n.assistanceComplete),
            ),
        ],
      ),
      if (saving) Text(context.l10n.sharedSavingStatus),
    ],
  );
}
