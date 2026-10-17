import 'admin_scaffold.dart';

import 'package:flutter/material.dart';

import '../../l10n/localization_context.dart';
import '../../models/service_run.dart';
import '../../services/moderation_client.dart';
import 'auth_account_screen.dart';

class AccountControlsScreen extends StatefulWidget {
  const AccountControlsScreen({
    super.key,
    required this.accountId,
    this.client,
  });
  final String accountId;
  final ModerationClient? client;
  @override
  State<AccountControlsScreen> createState() => _AccountControlsScreenState();
}

class _AccountControlsScreenState extends State<AccountControlsScreen> {
  late final client = widget.client ?? ModerationClient();
  late final actorId = client.currentAccountId;
  final reason = TextEditingController();
  Map<String, dynamic>? detail;
  bool busy = true;
  bool indefinite = false;
  String? error;
  // Preserve the operation and its payload after an ambiguous network response.
  ({String id, int revision, String action, String reason, int? hours})?
  pending;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    reason.dispose();
    if (widget.client == null) client.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (client.currentAccountId != actorId || actorId == null) {
      setState(() {
        detail = null;
        pending = null;
        busy = false;
        error = 'account-changed';
      });
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final value = await client.managedAccount(widget.accountId);
      if (!mounted) return;
      setState(() {
        detail = value;
        busy = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'unavailable';
        });
      }
    }
  }

  Future<void> change(String action) async {
    if (client.currentAccountId != actorId || actorId == null) {
      setState(() {
        detail = null;
        pending = null;
        busy = false;
        error = 'account-changed';
      });
      return;
    }
    if (pending == null && reason.text.trim().length < 5) {
      setState(() {
        error = 'reason-required';
      });
      return;
    }
    final operation = pending ??= (
      id: 'manual-${DateTime.now().microsecondsSinceEpoch}',
      revision: detail!['revision'] as int,
      action: action,
      reason: reason.text.trim(),
      hours: action == 'suspend' && !indefinite ? 72 : null,
    );
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await client.changeManagedAccount(
        accountId: widget.accountId,
        operationId: operation.id,
        revision: operation.revision,
        action: operation.action,
        reason: operation.reason,
        durationHours: operation.hours,
      );
      if (!mounted) return;
      pending = null;
      reason.clear();
      await load();
    } on ModerationException catch (e) {
      if (!mounted) return;
      // Explicit policy rejection is final; refresh before another decision.
      if ([
        'review-stale',
        'admin-account-protected',
        'self-review-forbidden',
        'account-suspended',
        'admin-required',
        'account-missing',
        'reason-required',
        'invalid-request',
        'request-id-conflict',
        'account-changed',
      ].contains(e.code)) {
        pending = null;
        detail = null;
      }
      setState(() {
        busy = false;
        error = e.code;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'unavailable';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final d = detail;
    final until = d?['manualUntil'] is String
        ? DateTime.tryParse(d!['manualUntil'] as String)
        : null;
    final civil = until == null ? null : ServiceRun.colomboClock(until);
    final material = MaterialLocalizations.of(context);
    return AdminScaffold(
      appBar: AppBar(title: Text(l.accountControlsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.accountId),
          Text(l.accountControlsExplanation),
          TextButton(
            onPressed: busy || pending != null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AuthAccountScreen(
                        accountId: widget.accountId,
                        client: client,
                      ),
                    ),
                  ),
            child: Text(l.authControlsTitle),
          ),
          if (busy) const LinearProgressIndicator(),
          if (error != null) ...[
            Text(switch (error) {
              'reason-required' => l.accountControlsReasonRequired,
              'review-stale' => l.accountControlsStale,
              'admin-account-protected' ||
              'self-review-forbidden' => l.accountControlsProtected,
              _ => l.accountControlsUnavailable,
            }),
            if (!busy && pending == null)
              TextButton(onPressed: load, child: Text(l.accountControlsRetry)),
          ],
          if (d != null) ...[
            const SizedBox(height: 16),
            Text(
              d['manualActive'] == true
                  ? l.accountControlsRestricted
                  : l.accountControlsClear,
            ),
            if (civil != null)
              Text(
                l.accountControlsUntil(
                  '${material.formatCompactDate(civil)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(civil))}',
                ),
              ),
            if (d['manualReason'] != null) Text(d['manualReason'] as String),
            if (d['communityRestricted'] == true)
              Text(l.accountControlsCommunity),
            TextField(
              controller: reason,
              enabled: !busy && pending == null,
              minLines: 2,
              maxLines: 5,
              maxLength: 2000,
              decoration: InputDecoration(labelText: l.reviewsReason),
            ),
            SwitchListTile(
              value: indefinite,
              onChanged: busy || pending != null
                  ? null
                  : (v) => setState(() {
                      indefinite = v;
                    }),
              title: Text(l.accountControlsIndefinite),
              subtitle: Text(l.accountControlsDuration),
            ),
            Wrap(
              spacing: 12,
              children: [
                if (pending != null)
                  FilledButton(
                    onPressed: busy ? null : () => change(pending!.action),
                    child: Text(l.accountControlsRetry),
                  )
                else ...[
                  FilledButton(
                    onPressed: busy ? null : () => change('suspend'),
                    child: Text(l.accountControlsSuspend),
                  ),
                  OutlinedButton(
                    onPressed: busy || d['manualActive'] != true
                        ? null
                        : () => change('restore'),
                    child: Text(l.accountControlsRestore),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
