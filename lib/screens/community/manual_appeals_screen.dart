import '../admin/admin_scaffold.dart';

import 'package:flutter/material.dart';

import '../../l10n/localization_context.dart';
import '../../services/moderation_client.dart';

class ManualAppealsScreen extends StatefulWidget {
  const ManualAppealsScreen({
    super.key,
    this.admin = false,
    this.client,
    this.onClose,
  });
  final bool admin;
  final ModerationClient? client;
  final VoidCallback? onClose;
  @override
  State<ManualAppealsScreen> createState() => _ManualAppealsScreenState();
}

class _ManualAppealsScreenState extends State<ManualAppealsScreen> {
  late final client = widget.client ?? ModerationClient();
  late final owner = client.currentAccountId;
  final reason = TextEditingController();
  final rows = <Map<String, dynamic>>[];
  Map<String, dynamic>? current, selected;
  String? next, error;
  bool busy = false;
  int version = 0;
  ({int revision, String reason})? pending;
  ({String id, String outcome, String reason})? decision;
  bool get sameAccount => owner != null && owner == client.currentAccountId;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    version++;
    reason.dispose();
    if (widget.client == null) client.dispose();
    super.dispose();
  }

  bool validRow(Map<String, dynamic> r) =>
      r['appealId'] is String &&
      r['accountId'] is String &&
      r['restrictionRevision'] is int &&
      r['restrictionReason'] is String &&
      r['reason'] is String &&
      const ['pending', 'accepted', 'rejected'].contains(r['status']);

  Future<void> load({bool more = false}) async {
    if (!sameAccount) {
      setState(() {
        rows.clear();
        current = null;
        error = 'account-changed';
      });
      return;
    }
    final epoch = ++version;
    setState(() {
      busy = true;
      error = null;
      if (!more) {
        rows.clear();
        current = null;
        next = null;
      }
    });
    try {
      final data = await client.manualAppeals(
        admin: widget.admin,
        after: more ? next : null,
      );
      if (data['items'] is! List ||
          (data['next'] != null && data['next'] is! String)) {
        throw const ModerationException('invalid-response');
      }
      final values = (data['items'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (values.any((r) => !validRow(r))) {
        throw const ModerationException('invalid-response');
      }
      final c = widget.admin ? null : await client.currentManualAppeal();
      if (c != null &&
          (c['accountId'] != owner ||
              c['revision'] is! int ||
              c['manualActive'] is! bool ||
              (c['appeal'] != null &&
                  (c['appeal'] is! Map ||
                      !validRow(Map<String, dynamic>.from(c['appeal'])))))) {
        throw const ModerationException('invalid-response');
      }
      if (!mounted || epoch != version || !sameAccount) return;
      setState(() {
        final ids = rows.map((r) => r['appealId']).toSet();
        rows.addAll(values.where((r) => ids.add(r['appealId'])));
        next = data['next'];
        current = c;
        busy = false;
      });
    } catch (_) {
      if (mounted && epoch == version) {
        setState(() {
          busy = false;
          if (!sameAccount) {
            rows.clear();
            current = null;
            selected = null;
            pending = null;
            decision = null;
          }
          error = sameAccount ? 'unavailable' : 'account-changed';
        });
      }
    }
  }

  Future<void> send({String? outcome}) async {
    if (!sameAccount) {
      setState(() {
        current = null;
        selected = null;
        rows.clear();
        error = 'account-changed';
      });
      return;
    }
    final text = reason.text.trim();
    if (text.length < 5 || text.length > 2000) {
      setState(() => error = 'reason-required');
      return;
    }
    if (widget.admin) {
      decision ??= (
        id: selected!['appealId'] as String,
        outcome: outcome!,
        reason: text,
      );
    } else {
      pending ??= (revision: current!['revision'] as int, reason: text);
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (widget.admin) {
        final d = decision!;
        await client.reviewManualAppeal(d.id, d.outcome, d.reason);
      } else {
        final p = pending!;
        await client.submitManualAppeal(p.revision, p.reason);
      }
      if (!mounted || !sameAccount) return;
      setState(() {
        pending = null;
        decision = null;
        selected = null;
        reason.clear();
        busy = false;
      });
      await load();
    } on ModerationException catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = e.code;
          if (const [
            'review-stale',
            'review-unavailable',
            'review-already-decided',
            'account-changed',
            'account-suspended',
            'admin-required',
            'request-id-conflict',
          ].contains(e.code)) {
            pending = null;
            decision = null;
            selected = null;
            current = null;
            if (e.code == 'account-changed') rows.clear();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AdminScaffold(
      enabled: widget.admin,
      appBar: AppBar(
        title: Text(l.manualAppealsTitle),
        leading: widget.onClose == null
            ? null
            : IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.arrow_back),
              ),
        actions: [
          IconButton(
            tooltip: l.accountStatusRetry,
            onPressed: busy ? null : () => load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.manualAppealsExplanation),
          if (busy) const LinearProgressIndicator(),
          if (error != null)
            Text(
              error == 'reason-required'
                  ? l.accountControlsReasonRequired
                  : error == 'account-changed'
                  ? l.searchAccountChanged
                  : l.manualAppealFailed,
            ),
          if (!widget.admin && current != null) ...[
            if (current!['reason'] is String) Text(current!['reason']),
            if (current!['manualActive'] == true &&
                current!['appeal'] == null) ...[
              TextField(
                controller: reason,
                enabled: !busy && pending == null,
                maxLength: 2000,
                maxLines: 4,
                decoration: InputDecoration(labelText: l.manualAppealReason),
              ),
              FilledButton(
                onPressed: busy ? null : () => send(),
                child: Text(
                  pending == null ? l.manualAppealSubmit : l.accountStatusRetry,
                ),
              ),
            ] else
              Text(l.manualAppealNoNew),
          ],
          if (widget.admin && selected != null) ...[
            Text(selected!['accountId']),
            Text(
              l.manualAppealRevision(selected!['restrictionRevision'] as int),
            ),
            Text(selected!['restrictionReason']),
            Text(selected!['reason']),
            TextField(
              controller: reason,
              enabled: !busy && decision == null,
              maxLength: 2000,
              maxLines: 4,
              decoration: InputDecoration(labelText: l.manualAppealReason),
            ),
            if (decision != null)
              FilledButton(
                onPressed: busy ? null : () => send(outcome: decision!.outcome),
                child: Text(l.accountStatusRetry),
              )
            else
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: busy ? null : () => send(outcome: 'restore'),
                    child: Text(l.manualAppealRestore),
                  ),
                  OutlinedButton(
                    onPressed: busy ? null : () => send(outcome: 'uphold'),
                    child: Text(l.manualAppealUphold),
                  ),
                ],
              ),
            TextButton(
              onPressed: busy
                  ? null
                  : () => setState(() {
                      selected = null;
                      decision = null;
                      reason.clear();
                    }),
              child: Text(l.manualAppealClose),
            ),
          ],
          for (final row in rows)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.admin
                          ? row['accountId']
                          : row['restrictionReason'],
                    ),
                    Text(row['reason']),
                    Text(
                      l.manualAppealRevision(row['restrictionRevision'] as int),
                    ),
                    if (row['createdAt'] is String) Text(row['createdAt']),
                    Text(switch (row['status']) {
                      'pending' => l.manualAppealPending,
                      'accepted' => l.manualAppealAccepted,
                      _ => l.manualAppealRejected,
                    }),
                    if (row['reviewReason'] is String)
                      Text(row['reviewReason']),
                    if (widget.admin && row['status'] == 'pending')
                      TextButton(
                        onPressed: busy || decision != null
                            ? null
                            : () => setState(() {
                                selected = row;
                                reason.clear();
                              }),
                        child: Text(l.manualAppealReview),
                      ),
                  ],
                ),
              ),
            ),
          if (!busy && error == null && rows.isEmpty) Text(l.manualAppealEmpty),
          if (next != null)
            TextButton(
              onPressed: busy ? null : () => load(more: true),
              child: Text(l.adminLoadMore),
            ),
        ],
      ),
    );
  }
}
