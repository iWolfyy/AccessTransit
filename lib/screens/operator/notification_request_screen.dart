import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/boarding_request.dart';
import '../../services/driver_notifications.dart';
import '../../services/firestore_service.dart';
import '../../widgets/assistance_operator_actions.dart';
import '../../widgets/assistance_labels.dart';
import '../../l10n/localization_context.dart';

class NotificationRequestScreen extends StatefulWidget {
  const NotificationRequestScreen({
    super.key,
    required this.session,
    required this.payload,
  });
  final DriverNotifications session;
  final Map<String, dynamic> payload;
  @override
  State<NotificationRequestScreen> createState() =>
      _NotificationRequestScreenState();
}

class _NotificationRequestScreenState extends State<NotificationRequestScreen> {
  late final owner = widget.session.accountId;
  late final repository = FirestoreService(
    v2Assistance: true,
    moderation: widget.session.client,
  );
  BoardingRequest? request;
  Timer? timer;
  bool loading = false, failed = false;
  int epoch = 0;
  bool get authorizedSession =>
      widget.session.enabled && widget.session.accountId == owner;
  @override
  void initState() {
    super.initState();
    widget.session.addListener(changed);
    load();
    timer = Timer.periodic(const Duration(seconds: 15), (_) => load());
  }

  void changed() {
    if (!authorizedSession) {
      epoch++;
      if (mounted) {
        setState(() {
          request = null;
          failed = true;
          loading = false;
        });
      }
    }
  }

  Future<void> load() async {
    if (loading || !authorizedSession) return;
    final version = ++epoch;
    setState(() => loading = true);
    try {
      final value = await widget.session.resolve(widget.payload);
      if (!mounted || version != epoch || !authorizedSession) return;
      setState(() {
        request = value;
        failed = false;
      });
    } catch (_) {
      if (mounted && version == epoch) {
        setState(() {
          request = null;
          failed = true;
        });
      }
    } finally {
      if (mounted && version == epoch) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    epoch++;
    timer?.cancel();
    widget.session.removeListener(changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text(c.l10n.pushTitle)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (loading) const Center(child: CircularProgressIndicator()),
        if (failed || !authorizedSession) Text(c.l10n.pushOpenUnavailable),
        if (request != null && authorizedSession)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request!.riderName,
                    style: Theme.of(c).textTheme.titleMedium,
                  ),
                  Text('${request!.routeNo} · ${request!.stopName}'),
                  for (final type in request!.assistanceTypes)
                    Text(assistanceType(c, type)),
                  const SizedBox(height: 16),
                  AssistanceOperatorActions(
                    request: request!,
                    repository: repository,
                  ),
                ],
              ),
            ),
          ),
        if (authorizedSession)
          OutlinedButton(
            onPressed: loading ? null : load,
            child: Text(c.l10n.operationsRefresh),
          ),
      ],
    ),
  );
}
