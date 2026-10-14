import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/boarding_request.dart';
import '../../services/assistance_submission_service.dart';
import '../../services/firestore_service.dart';

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
    appBar: AppBar(title: const Text('Assistance request')),
    body: ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        if (service.currentRiderId != widget.request.riderId) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Sign in with the account that created this request to view its status.',
            ),
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
                ? 'Sent to shared service'
                : local?.delivery.label ?? 'Request status unknown';
            final canRetry =
                !sent &&
                local != null &&
                local.delivery != AssistanceDeliveryState.expired;
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  delivery,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text('Route ${request.routeNo} · Bus ${request.busId}'),
                Text(
                  '${request.purpose == 'alighting' ? 'Getting off' : 'Boarding'} at ${request.stopName}',
                ),
                Text(request.assistanceTypes.join(', ')),
                const Divider(height: 32),
                Text(
                  sent
                      ? request.driverStatusLabel
                      : 'Driver acknowledgement is not confirmed.',
                ),
                if (sent && request.status == 'pending')
                  const Text(
                    'Saving the request does not mean the driver has accepted it.',
                  ),
                if (sent && request.status == 'acknowledged')
                  const Text(
                    'The driver has acknowledged the request. Assistance has not been marked completed.',
                  ),
                if (!sent && local?.error != null) Text(local!.error!),
                if (snapshot.hasError || (sent && remote == null))
                  const Text(
                    'Live status updates are unavailable. Displayed driver status is the last received status.',
                  ),
                if (service.loadError != null) Text(service.loadError!),
                if (actionError != null) Text(actionError!),
                const SizedBox(height: 20),
                if (canRetry)
                  FilledButton(
                    onPressed: service.isUploading(request.id) ? null : _retry,
                    child: Text(
                      service.isUploading(request.id)
                          ? 'Sending…'
                          : 'Retry upload',
                    ),
                  ),
                if (sent &&
                    const ['pending', 'acknowledged'].contains(request.status))
                  OutlinedButton(
                    onPressed: cancelling ? null : _cancel,
                    child: Text(cancelling ? 'Cancelling…' : 'Cancel request'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back'),
                ),
              ],
            );
          },
        );
      },
    ),
  );
}
