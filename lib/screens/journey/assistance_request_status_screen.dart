import '../../l10n/assistance_receipt_presentation.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/boarding_request.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../services/assistance_submission_service.dart';
import '../../services/firestore_service.dart';
import '../../l10n/localization_context.dart';
import '../../widgets/assistance_labels.dart';

class AssistanceRequestStatusScreen extends StatefulWidget {
  const AssistanceRequestStatusScreen({
    super.key,
    required this.request,
    this.service,
    this.repository,
    this.requestUpdates,
    this.startUpload = false,
  });
  final BoardingRequest request;
  final AssistanceSubmissionService? service;
  final FirestoreService? repository;
  final Stream<BoardingRequest?>? requestUpdates;
  final bool startUpload;
  @override
  State<AssistanceRequestStatusScreen> createState() =>
      _AssistanceRequestStatusScreenState();
}

class _AssistanceRequestStatusScreenState
    extends State<AssistanceRequestStatusScreen> {
  late final AssistanceSubmissionService service;
  late final FirestoreService repository;
  late final Stream<BoardingRequest?> updates;
  bool cancelling = false;
  String? actionError;
  @override
  void initState() {
    super.initState();
    service = widget.service ?? AssistanceSubmissionService.instance;
    repository = widget.repository ?? FirestoreService();
    updates =
        widget.requestUpdates ??
        repository.watchBoardingRequest(widget.request.id);
    if (widget.startUpload) scheduleMicrotask(_retry);
  }

  Future<void> _retry() async {
    if (service.find(widget.request.id) == null) return;
    if (mounted) setState(() => actionError = null);
    try {
      await service.retry(widget.request.id);
    } catch (_) {
      if (mounted) {
        setState(
          () => actionError =
              'Could not save the retry on this device. Please try again.',
        );
      }
    }
  }

  Future<void> _cancel() async {
    if (cancelling) return;
    setState(() {
      cancelling = true;
      actionError = null;
    });
    try {
      await repository
          .updateBoardingRequestStatus(widget.request.id, 'cancelled')
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      if (mounted) {
        setState(
          () => actionError = 'Cancellation is not confirmed. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.surfaceColor,
    appBar: AppBar(
      backgroundColor: context.surfaceColor,
      centerTitle: true,
      elevation: context.isHighContrast ? 0 : 1,
      toolbarHeight: MediaQuery.textScalerOf(context).scale(22) > 33 ? 96 : 56,
      leading: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => Navigator.of(context).maybePop(),
        icon: Icon(
          Icons.arrow_back_rounded,
          color: context.primaryColor,
          size: 28,
        ),
      ),
      title: Text(
        context.l10n.assistReceiptTitle,
        maxLines: 2,
        softWrap: true,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: context.textColor,
        ),
      ),
    ),
    body: ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        if (service.currentRiderId != widget.request.riderId) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      color: context.primaryColor,
                      size: 32,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.assistReceiptOwner,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: context.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return StreamBuilder<BoardingRequest?>(
          stream: updates,
          builder: (context, snapshot) {
            final local = service.find(widget.request.id);
            final remote = snapshot.data?.riderId == widget.request.riderId
                ? snapshot.data
                : null;
            final shared =
                remote ??
                (local?.delivery == AssistanceDeliveryState.sent
                    ? local?.request
                    : null);
            final request = shared ?? local?.request ?? widget.request;
            final sent = shared != null;
            final delivery = sent
                ? context.l10n.assistReceiptSent
                : (local == null
                      ? context.l10n.assistReceiptUnknown
                      : context.assistanceReceiptText(local.delivery.label));
            final canRetry =
                !sent &&
                local != null &&
                local.delivery != AssistanceDeliveryState.expired;

            final failed = local?.delivery == AssistanceDeliveryState.failed;
            final driverWarning = sent && request.status == 'rejected';
            final hint = sent && request.status == 'pending'
                ? context.l10n.assistReceiptPendingHint
                : sent && request.status == 'acknowledged'
                ? context.l10n.assistReceiptAcceptedHint
                : null;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _statusCard(
                          context.l10n.assistReceiptDelivery,
                          delivery,
                          sent
                              ? Icons.cloud_done_outlined
                              : failed
                              ? Icons.error_outline_rounded
                              : Icons.cloud_upload_outlined,
                          warning: failed,
                        ),
                        const SizedBox(height: 16),
                        _card(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _heading(context.l10n.assistReceiptOwn),
                              const SizedBox(height: 12),
                              Wrap(
                                children: [
                                  Chip(
                                    label: Text(
                                      context.l10n.assistReceiptRoute(
                                        request.routeNo,
                                      ),
                                    ),
                                    avatar: Icon(
                                      Icons.directions_bus_outlined,
                                      size: 18,
                                      color: context.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 22,
                                    color: context.primaryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      request.purpose == 'alighting'
                                          ? context.l10n.assistFormAlightAt(
                                              request.stopName,
                                            )
                                          : context.l10n.assistFormBoardAt(
                                              request.stopName,
                                            ),
                                      style: TextStyle(
                                        fontSize: 16,
                                        height: 1.4,
                                        fontWeight: FontWeight.w600,
                                        color: context.textColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 28),
                              Text(
                                context.l10n.assistReceiptSupport,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.subtextColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (request.assistanceTypes.isEmpty)
                                Text(
                                  context.l10n.assistReceiptUnspecified,
                                  style: TextStyle(color: context.subtextColor),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: request.assistanceTypes
                                      .map(
                                        (type) => Chip(
                                          label: Text(
                                            assistanceType(context, type),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _statusCard(
                          context.l10n.assistReceiptDriver,
                          sent
                              ? assistanceStatus(context, request)
                              : context.l10n.assistReceiptUnconfirmed,
                          !sent
                              ? Icons.hourglass_empty_rounded
                              : switch (request.status) {
                                  'acknowledged' => Icons.pan_tool_outlined,
                                  'completed' =>
                                    Icons.check_circle_outline_rounded,
                                  'rejected' => Icons.block_outlined,
                                  'cancelled' => Icons.cancel_outlined,
                                  _ => Icons.schedule_rounded,
                                },
                          hint: hint,
                          warning: driverWarning,
                        ),
                        if (request.policyVersion == 2) ...[
                          const SizedBox(height: 12),
                          Text(context.l10n.assistanceInAppOnly),
                          if (assistanceEndReason(context, request.endReason) !=
                              null)
                            Text(
                              assistanceEndReason(context, request.endReason)!,
                            ),
                          if (request.assignmentVersion > 1 &&
                              request.status == 'pending')
                            Text(context.l10n.assistanceRetargeted),
                          if (request.expiresAt != null)
                            Text(
                              context.l10n.assistanceExpiry(
                                request.expiresAt!.toUtc().toIso8601String(),
                              ),
                            ),
                        ],
                        if (!sent && local?.error != null) ...[
                          const SizedBox(height: 16),
                          _notice(
                            context.assistanceReceiptText(local!.error!),
                            warning: true,
                          ),
                        ],
                        if (snapshot.hasError || (sent && remote == null)) ...[
                          const SizedBox(height: 16),
                          _notice(context.l10n.assistReceiptStale),
                        ],
                        if (service.loadError != null) ...[
                          const SizedBox(height: 16),
                          _notice(
                            context.assistanceReceiptText(service.loadError!),
                            warning: true,
                          ),
                        ],
                        if (actionError != null) ...[
                          const SizedBox(height: 16),
                          Semantics(
                            liveRegion: true,
                            child: _notice(
                              context.assistanceReceiptText(actionError!),
                              warning: true,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        if (canRetry)
                          FilledButton(
                            onPressed: service.isUploading(request.id)
                                ? null
                                : _retry,
                            style: FilledButton.styleFrom(
                              backgroundColor: context.primaryColor,
                              foregroundColor: Colors.white,
                              minimumSize: Size(
                                context.buttonHeight,
                                context.buttonHeight,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              service.isUploading(request.id)
                                  ? context.l10n.assistReceiptSending
                                  : context.l10n.assistReceiptRetry,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (sent &&
                            const [
                              'pending',
                              'acknowledged',
                            ].contains(request.status))
                          OutlinedButton(
                            onPressed: cancelling ? null : _cancel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.primaryColor,
                              minimumSize: Size(
                                context.buttonHeight,
                                context.buttonHeight,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              cancelling
                                  ? context.l10n.assistReceiptCancelling
                                  : context.l10n.assistReceiptCancel,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            MaterialLocalizations.of(context).backButtonTooltip,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ),
  );

  Widget _heading(String title) => Semantics(
    header: true,
    child: Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: context.textColor,
      ),
    ),
  );

  Widget _card(Widget child) => Material(
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
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );

  Widget _statusCard(
    String title,
    String value,
    IconData icon, {
    String? hint,
    bool warning = false,
  }) => _card(
    Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading(title),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 24,
                color: warning && !context.isHighContrast
                    ? AppColors.error
                    : context.primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: warning && !context.isHighContrast
                        ? AppColors.error
                        : context.textColor,
                  ),
                ),
              ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 12),
            Text(
              hint,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: context.subtextColor,
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _notice(String value, {bool warning = false}) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        warning ? Icons.error_outline_rounded : Icons.info_outline_rounded,
        size: 22,
        color: warning && !context.isHighContrast
            ? AppColors.error
            : context.primaryColor,
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          value,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: context.subtextColor,
          ),
        ),
      ),
    ],
  );
}
