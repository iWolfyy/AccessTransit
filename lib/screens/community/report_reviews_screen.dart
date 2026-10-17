import '../admin/admin_scaffold.dart';
import '../../l10n/moderation_presentation.dart';

import 'package:flutter/material.dart';

import '../../l10n/localization_context.dart';
import '../../services/moderation_client.dart';

/// Private, paginated server views. Restricted authors can appeal without
/// reopening their authenticated operational workspace.
class ReportReviewsScreen extends StatefulWidget {
  const ReportReviewsScreen({
    super.key,
    this.admin = false,
    this.client,
    this.onClose,
    this.initialReportId,
  });
  final bool admin;
  final ModerationClient? client;
  final VoidCallback? onClose;
  final String? initialReportId;
  @override
  State<ReportReviewsScreen> createState() => _ReportReviewsScreenState();
}

class _ReportReviewsScreenState extends State<ReportReviewsScreen> {
  late final client = widget.client ?? ModerationClient();
  final items = <Map<String, dynamic>>[];
  String? next;
  bool loading = true, failed = false;
  Map<String, dynamic>? detail;
  final evidence = <Map<String, dynamic>>[];
  String? evidenceNext;
  final reason = TextEditingController();
  bool busy = false, sent = false;
  int revision = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialReportId != null) {
      open(widget.initialReportId!);
    } else {
      load();
    }
  }

  List<Map<String, dynamic>> rows(Map<String, dynamic> data) {
    if (data['items'] is! List ||
        (data['next'] != null && data['next'] is! String)) {
      throw const ModerationException('invalid-response');
    }
    return (data['items'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> load({bool more = false}) async {
    final version = ++revision;
    setState(() {
      loading = true;
      failed = false;
      if (!more) {
        items.clear();
        detail = null;
        next = null;
      }
    });
    try {
      final data = await client.reviews(
        admin: widget.admin,
        after: more ? next : null,
      );
      final values = rows(data);
      if (values.any(
        (e) =>
            e['reportId'] is! String ||
            e['penalty'] is! int ||
            e['strikeCounted'] is! bool,
      )) {
        throw const ModerationException('invalid-response');
      }
      if (!mounted || version != revision) return;
      setState(() {
        items.addAll(values);
        next = data['next'];
        loading = false;
      });
    } catch (_) {
      if (mounted && version == revision) {
        setState(() {
          loading = false;
          failed = true;
        });
      }
    }
  }

  Future<void> open(String id) async {
    final version = ++revision;
    setState(() {
      loading = true;
      failed = false;
      detail = null;
      evidence.clear();
      evidenceNext = null;
      sent = false;
      reason.clear();
    });
    try {
      final value = await client.reviewDetail(id);
      if (value['reportId'] != id ||
          value['penalty'] is! int ||
          value['strikeCounted'] is! bool ||
          value['falseCount'] is! int) {
        throw const ModerationException('invalid-response');
      }
      final votes = widget.admin ? await client.reviewEvidence(id) : null;
      final voteRows = votes == null ? <Map<String, dynamic>>[] : rows(votes);
      if (!mounted || version != revision) return;
      setState(() {
        detail = value;
        evidence.addAll(voteRows);
        evidenceNext = votes?['next'];
        loading = false;
      });
    } catch (_) {
      if (mounted && version == revision) {
        setState(() {
          loading = false;
          failed = true;
        });
      }
    }
  }

  Future<void> moreEvidence() async {
    final id = detail!['reportId'] as String, version = revision;
    setState(() => busy = true);
    try {
      final data = await client.reviewEvidence(id, after: evidenceNext);
      final values = rows(data);
      if (!mounted || version != revision) return;
      setState(() {
        evidence.addAll(values);
        evidenceNext = data['next'];
      });
    } on ModerationException catch (e) {
      if (mounted && version == revision) {
        message(context.reviewFailure(e.code) ?? context.l10n.reviewsError);
      }
    } catch (_) {
      if (mounted && version == revision) message(context.l10n.reviewsError);
    } finally {
      if (mounted && version == revision) setState(() => busy = false);
    }
  }

  void message(String text) =>
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(text)));
  Future<void> submit([String? outcome]) async {
    final text = reason.text.trim();
    if (text.length < 5 || text.length > 2000) {
      message(context.l10n.reviewsReasonRequired);
      return;
    }
    final id = detail!['reportId'] as String, version = revision;
    setState(() => busy = true);
    try {
      if (outcome == null) {
        await client.appealReport(id, text);
      } else {
        await client.decideReport(id, outcome, text);
      }
      if (!mounted || version != revision) return;
      // Reload acknowledged state; never label a failed write as submitted.
      await open(id);
      if (mounted) setState(() => sent = true);
    } on ModerationException catch (e) {
      if (mounted && version == revision) {
        message(context.reviewFailure(e.code) ?? context.l10n.reviewsError);
      }
    } catch (_) {
      if (mounted && version == revision) message(context.l10n.reviewsError);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    revision++;
    reason.dispose();
    if (widget.client == null) client.dispose();
    super.dispose();
  }

  String status(String? value) => context.reportReviewStatus(value);

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final appeal = d?['appeal'] as Map?;
    final closed = !const [
      'unreviewed',
      'pending',
    ].contains(d?['reviewStatus']);
    return AdminScaffold(
      enabled: widget.admin,
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(20) > 30
            ? 104
            : 56,
        title: Text(
          widget.admin
              ? context.l10n.reviewsAdminTitle
              : context.l10n.reviewsTitle,
        ),
        leading: d != null
            ? IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: busy ? null : () => load(),
                icon: const Icon(Icons.arrow_back),
              )
            : widget.onClose != null
            ? IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
              )
            : null,
        actions: [
          IconButton(
            tooltip: context.l10n.accountStatusRetry,
            onPressed: busy || loading
                ? null
                : () => d == null ? load() : open(d['reportId']),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : failed
          ? Center(
              child: TextButton(
                onPressed: () => load(),
                child: Text(context.l10n.reviewsError),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: d == null
                  ? [
                      if (items.isEmpty) Text(context.l10n.reviewsEmpty),
                      ...items.map(
                        (e) => Card(
                          child: ListTile(
                            title: Text(e['reportId']),
                            subtitle: Text(
                              '${status(e['reviewStatus'])}\n${context.l10n.reviewsPenalty(e['penalty'], e['strikeCounted'] == true ? 1 : 0)}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => open(e['reportId']),
                          ),
                        ),
                      ),
                      if (next != null)
                        TextButton(
                          onPressed: () => load(more: true),
                          child: Text(context.l10n.reviewsMore),
                        ),
                    ]
                  : [
                      Text(
                        '${d['targetName']} • ${d['summary']}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(context.l10n.reviewsHiddenReason(d['falseCount'])),
                      Text(
                        context.l10n.reviewsPenalty(
                          d['penalty'],
                          d['strikeCounted'] == true ? 1 : 0,
                        ),
                      ),
                      Text(status(d['reviewStatus'])),
                      const SizedBox(height: 12),
                      Text(d['description']?.toString() ?? ''),
                      if ((d['observedAt'] as String?)?.isNotEmpty == true)
                        Text(d['observedAt']),
                      if ((d['photoUrl'] as String?)?.startsWith('https://') ==
                          true)
                        Image.network(
                          d['photoUrl'],
                          height: 200,
                          semanticLabel: context.l10n.reviewsPhoto,
                          errorBuilder: (_, e, s) =>
                              Text(context.l10n.reviewsPhotoUnavailable),
                        ),
                      if (appeal != null) ...[
                        const Divider(),
                        Text(
                          context.l10n.reviewsAppealLabel,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(appeal['reason']?.toString() ?? ''),
                        Text(status(appeal['status'])),
                      ],
                      if (d['reviewReason'] != null) ...[
                        const Divider(),
                        Text(context.l10n.reviewsDecisionReason),
                        Text(d['reviewReason']),
                      ],
                      if (widget.admin) ...[
                        const Divider(),
                        Text(context.l10n.reviewsVotes),
                        ...evidence.map(
                          (v) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              context.l10n.reviewVoteEvidence(
                                v['uid'],
                                context.reviewVote(v['value']),
                              ),
                            ),
                            subtitle: Text(v['reason']?.toString() ?? ''),
                          ),
                        ),
                        if (evidenceNext != null)
                          TextButton(
                            onPressed: busy ? null : moreEvidence,
                            child: Text(context.l10n.reviewsMore),
                          ),
                      ],
                      if (!closed && (widget.admin || appeal == null)) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: reason,
                          enabled: !busy,
                          maxLength: 2000,
                          minLines: 2,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: context.l10n.reviewsReason,
                          ),
                        ),
                        if (widget.admin) ...[
                          Text(context.l10n.reviewsDecisionExplanation),
                          Wrap(
                            spacing: 12,
                            children: [
                              OutlinedButton(
                                onPressed: busy ? null : () => submit('uphold'),
                                child: Text(context.l10n.reviewsUphold),
                              ),
                              FilledButton(
                                onPressed: busy
                                    ? null
                                    : () => submit('overturn'),
                                child: Text(context.l10n.reviewsOverturn),
                              ),
                            ],
                          ),
                        ] else
                          FilledButton(
                            onPressed: busy ? null : () => submit(),
                            child: Text(context.l10n.reviewsSubmit),
                          ),
                      ],
                      if (busy) const LinearProgressIndicator(),
                      if (sent) Text(context.l10n.reviewsAcknowledged),
                    ],
            ),
    );
  }
}
