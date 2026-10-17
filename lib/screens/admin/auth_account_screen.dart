import 'admin_scaffold.dart';

import 'package:flutter/material.dart';

import '../../l10n/localization_context.dart';
import '../../services/moderation_client.dart';

class AuthAccountScreen extends StatefulWidget {
  const AuthAccountScreen({super.key, required this.accountId, this.client});
  final String accountId;
  final ModerationClient? client;
  @override
  State<AuthAccountScreen> createState() => _AuthAccountScreenState();
}

class _AuthAccountScreenState extends State<AuthAccountScreen> {
  late final client = widget.client ?? ModerationClient();
  late final actor = client.currentAccountId;
  final reason = TextEditingController(),
      confirmation = TextEditingController();
  Map<String, dynamic>? detail;
  bool busy = false;
  String? error;
  ({
    String id,
    String action,
    String reason,
    int revision,
    String? confirmation,
  })?
  pending;
  bool get sameAccount => actor != null && actor == client.currentAccountId;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    reason.dispose();
    confirmation.dispose();
    if (widget.client == null) client.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (!sameAccount) {
      setState(() {
        detail = null;
        error = 'account-changed';
      });
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final d = await client.authAccount(widget.accountId);
      if (!mounted) return;
      setState(() {
        detail = d;
        busy = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          detail = null;
          busy = false;
          error = 'unavailable';
        });
      }
    }
  }

  Future<void> change(String action) async {
    if (!sameAccount) {
      setState(() {
        detail = null;
        pending = null;
        error = 'account-changed';
      });
      return;
    }
    if (pending == null) {
      if (reason.text.trim().length < 5) {
        setState(() {
          error = 'reason-required';
        });
        return;
      }
      if (action == 'approve-delete' &&
          confirmation.text.trim() != widget.accountId) {
        setState(() {
          error = 'deletion-confirmation-required';
        });
        return;
      }
      if (action == 'approve-delete') {
        final approved = await showDialog<bool>(
          context: context,
          builder: (ctx) => AdminDialog(
            title: Text(ctx.l10n.authDeleteApprove),
            content: Text(ctx.l10n.authDeleteExplanation),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(ctx.l10n.authCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(ctx.l10n.authDeleteApprove),
              ),
            ],
          ),
        );
        if (!mounted || approved != true || !sameAccount) return;
      }
      pending = (
        id: 'auth-${DateTime.now().microsecondsSinceEpoch}',
        action: action,
        reason: reason.text.trim(),
        revision: detail!['revision'] as int,
        confirmation: action == 'approve-delete' ? widget.accountId : null,
      );
    }
    final p = pending!;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await client.changeAuthAccount(
        accountId: widget.accountId,
        operationId: p.id,
        revision: p.revision,
        action: p.action,
        reason: p.reason,
        confirmAccountId: p.confirmation,
      );
      if (!mounted) return;
      pending = null;
      reason.clear();
      confirmation.clear();
      await load();
    } on ModerationException catch (e) {
      if (!mounted) return;
      if (![
        'service-unavailable',
        'invalid-response',
        'authentication-unavailable',
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

  Future<void> reconcile(String id) async {
    if (!sameAccount) {
      await load();
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final d = await client.retryAuthAccount(widget.accountId, id);
      if (mounted) {
        setState(() {
          detail = d;
          busy = false;
        });
      }
    } on ModerationException catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = e.code;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n, d = detail;
    final job = d?['lastOperation'] as Map?;
    final unfinished = job != null && job['status'] != 'completed';
    return AdminScaffold(
      appBar: AppBar(title: Text(l.authControlsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.accountId),
          Text(l.authControlsExplanation),
          if (busy) const LinearProgressIndicator(),
          if (error != null)
            Text(switch (error) {
              'reason-required' => l.accountControlsReasonRequired,
              'deletion-confirmation-required' => l.authConfirmRequired,
              'admin-account-protected' ||
              'self-review-forbidden' => l.accountControlsProtected,
              'disable-before-delete' => l.authDisableFirst,
              'active-operation-blocks-delete' => l.authActiveTrip,
              'review-stale' => l.accountControlsStale,
              'auth-operation-pending' => l.authPending,
              'auth-scope-denied' => l.authNormalScope,
              _ => l.accountControlsUnavailable,
            }),
          if (!busy && pending == null)
            TextButton(onPressed: load, child: Text(l.authReload)),
          if (d != null) ...[
            Text(
              d['deleted'] == true
                  ? l.authDeleted
                  : d['authDisabled'] == true
                  ? l.authDisabled
                  : l.authEnabled,
            ),
            if (d['authBlocked'] == true && d['authDisabled'] != true)
              Text(l.authPending),
            if (d['activeOperation'] == true) Text(l.authActiveTrip),
            if (job != null)
              Text(
                job['status'] == 'completed' ? l.authCompleted : l.authPending,
              ),
            if (job?['status'] == 'review-required' ||
                job?['status'] == 'processing')
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () => reconcile(job!['operationId'] as String),
                child: Text(l.authReconcile),
              ),
            if (d['protected'] == true)
              Text(l.accountControlsProtected)
            else if (d['deleted'] != true) ...[
              TextField(
                controller: reason,
                enabled: !busy && pending == null && !unfinished,
                minLines: 2,
                maxLines: 5,
                maxLength: 2000,
                decoration: InputDecoration(labelText: l.reviewsReason),
              ),
              if (d['reviewReason'] is String)
                Text(d['reviewReason'] as String),
              if (d['reviewStatus'] == 'pending') ...[
                Text(l.authDeleteExplanation),
                TextField(
                  controller: confirmation,
                  enabled: !busy && pending == null && !unfinished,
                  decoration: InputDecoration(labelText: l.authConfirmLabel),
                ),
              ],
              if (pending != null)
                FilledButton(
                  onPressed: busy ? null : () => change(pending!.action),
                  child: Text(l.accountControlsRetry),
                )
              else if (!unfinished)
                Wrap(
                  spacing: 12,
                  children: [
                    OutlinedButton(
                      onPressed: busy || d['authDisabled'] != true
                          ? null
                          : () => change('enable'),
                      child: Text(l.authEnable),
                    ),
                    OutlinedButton(
                      onPressed: busy || d['authDisabled'] == true
                          ? null
                          : () => change('disable'),
                      child: Text(l.authDisable),
                    ),
                    OutlinedButton(
                      onPressed: busy ? null : () => change('revoke'),
                      child: Text(l.authRevoke),
                    ),
                    if (d['reviewStatus'] != 'pending')
                      OutlinedButton(
                        onPressed: busy ? null : () => change('request-delete'),
                        child: Text(l.authDeleteRequest),
                      )
                    else ...[
                      OutlinedButton(
                        onPressed: busy ? null : () => change('reject-delete'),
                        child: Text(l.authDeleteReject),
                      ),
                      FilledButton(
                        onPressed:
                            busy ||
                                d['authDisabled'] != true ||
                                d['activeOperation'] == true
                            ? null
                            : () => change('approve-delete'),
                        child: Text(l.authDeleteApprove),
                      ),
                    ],
                  ],
                ),
            ],
          ],
        ],
      ),
    );
  }
}
