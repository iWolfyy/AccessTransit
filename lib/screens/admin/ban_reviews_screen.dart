import 'admin_scaffold.dart';
import '../../l10n/moderation_presentation.dart';

import 'package:flutter/material.dart';

import '../../l10n/localization_context.dart';
import '../../services/moderation_client.dart';
import '../community/report_reviews_screen.dart';

class BanReviewsScreen extends StatefulWidget {
  const BanReviewsScreen({super.key, this.client});
  final ModerationClient? client;
  @override
  State<BanReviewsScreen> createState() => _BanReviewsScreenState();
}

class _BanReviewsScreenState extends State<BanReviewsScreen> {
  late final client = widget.client ?? ModerationClient();
  final cases = <Map<String, dynamic>>[], evidence = <Map<String, dynamic>>[];
  Map<String, dynamic>? detail;
  String? next, evidenceNext, error;
  bool loading = true, busy = false;
  final reason = TextEditingController();
  int generation = 0;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    generation++;
    reason.dispose();
    if (widget.client == null) client.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> rows(Map<String, dynamic> value) {
    if (value['items'] is! List ||
        (value['next'] != null && value['next'] is! String)) {
      throw const ModerationException('invalid-response');
    }
    return (value['items'] as List)
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList();
  }

  Future<void> load({bool more = false}) async {
    final version = ++generation;
    setState(() {
      loading = true;
      error = null;
      detail = null;
      if (!more) {
        cases.clear();
        next = null;
      }
    });
    try {
      final data = await client.banReviews(after: more ? next : null),
          values = rows(data);
      if (values.any(
        (v) =>
            v['accountId'] is! String ||
            v['strikeCount'] is! int ||
            v['status'] is! String,
      )) {
        throw const ModerationException('invalid-response');
      }
      if (!mounted || version != generation) return;
      setState(() {
        cases.addAll(values);
        next = data['next'];
        loading = false;
      });
    } catch (e) {
      if (mounted && version == generation) {
        setState(() {
          loading = false;
          error = e is ModerationException ? e.code : 'unavailable';
        });
      }
    }
  }

  Future<void> open(String id) async {
    final version = ++generation;
    setState(() {
      loading = true;
      error = null;
      detail = null;
      evidence.clear();
      evidenceNext = null;
      reason.clear();
    });
    try {
      final data = await client.banDetail(id),
          entries = await client.banEvidence(id),
          values = rows(entries);
      if (data['accountId'] != id ||
          data['currentStrikes'] is! int ||
          data['revision'] is! int ||
          data['pendingAppeals'] is! bool) {
        throw const ModerationException('invalid-response');
      }
      if (!mounted || version != generation) return;
      setState(() {
        detail = data;
        evidence.addAll(values);
        evidenceNext = entries['next'];
        loading = false;
      });
    } catch (e) {
      if (mounted && version == generation) {
        setState(() {
          loading = false;
          error = e is ModerationException ? e.code : 'unavailable';
        });
      }
    }
  }

  Future<void> moreEvidence() async {
    final version = generation;
    setState(() => busy = true);
    try {
      final data = await client.banEvidence(
            detail!['accountId'],
            after: evidenceNext,
          ),
          values = rows(data);
      if (mounted && version == generation) {
        setState(() {
          evidence.addAll(values);
          evidenceNext = data['next'];
        });
      }
    } catch (e) {
      if (mounted && version == generation) {
        setState(
          () => error = e is ModerationException ? e.code : 'unavailable',
        );
      }
    } finally {
      if (mounted && version == generation) setState(() => busy = false);
    }
  }

  Future<void> decide(String outcome) async {
    final text = reason.text.trim();
    if (text.length < 5 || text.length > 2000) {
      setState(() => error = 'reason');
      return;
    }
    final version = generation, id = detail!['accountId'] as String;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await client.decideBan(id, outcome, text, detail!['revision']);
      if (!mounted || version != generation) return;
      await open(id);
    } on ModerationException catch (e) {
      if (mounted && version == generation) setState(() => error = e.code);
    } catch (e) {
      if (mounted && version == generation) {
        setState(
          () => error = e is ModerationException ? e.code : 'unavailable',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String status(String? value) => context.banReviewStatus(value);
  @override
  Widget build(BuildContext context) {
    final d = detail;
    final errorText = switch (error) {
      null => null,
      'reason' => context.l10n.reviewsReasonRequired,
      'review-stale' => context.l10n.bansStale,
      'appeals-pending' => context.l10n.bansAppealsPending,
      'admin-account-protected' => context.l10n.bansAdminProtected,
      _ => context.reviewFailure(error) ?? context.l10n.reviewsError,
    };
    return AdminScaffold(
      appBar: AppBar(
        title: Text(context.l10n.bansTitle),
        toolbarHeight: MediaQuery.textScalerOf(context).scale(20) > 30
            ? 104
            : 56,
        leading: d == null
            ? null
            : IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: busy ? null : () => load(),
                icon: const Icon(Icons.arrow_back),
              ),
        actions: [
          IconButton(
            tooltip: context.l10n.accountStatusRetry,
            onPressed: busy || loading
                ? null
                : () => d == null ? load() : open(d['accountId']),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (errorText != null) Text(errorText),
                if (d == null) ...[
                  if (cases.isEmpty && error == null)
                    Text(context.l10n.bansEmpty),
                  ...cases.map(
                    (c) => Card(
                      child: ListTile(
                        title: Text(c['accountId']),
                        subtitle: Text(
                          '${status(c['status'])} • ${context.l10n.bansStrikes(c['strikeCount'])}',
                        ),
                        onTap: () => open(c['accountId']),
                      ),
                    ),
                  ),
                  if (next != null)
                    TextButton(
                      onPressed: () => load(more: true),
                      child: Text(context.l10n.reviewsMore),
                    ),
                ] else ...[
                  Text(
                    d['name']?.toString() ?? d['accountId'],
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(d['email']?.toString() ?? ''),
                  Text(d['accountId']),
                  Text(status(d['status'])),
                  Text(context.l10n.bansStrikes(d['currentStrikes'])),
                  if (d['pendingAppeals'] == true)
                    Text(context.l10n.bansAppealsPending),
                  if (d['reason'] != null) ...[
                    Text(context.l10n.reviewsDecisionReason),
                    Text(d['reason']),
                  ],
                  const Divider(),
                  Text(context.l10n.bansEvidence),
                  ...evidence.map(
                    (e) => ListTile(
                      title: Text(e['reportId']),
                      subtitle: Text(
                        e['strikeCounted'] == true
                            ? context.l10n.bansCounted
                            : context.l10n.bansRemoved,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: busy
                          ? null
                          : () async {
                              final id = d['accountId'] as String;
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ReportReviewsScreen(
                                    admin: true,
                                    client: client,
                                    initialReportId: e['reportId'],
                                  ),
                                ),
                              );
                              if (mounted) open(id);
                            },
                    ),
                  ),
                  if (evidenceNext != null)
                    TextButton(
                      onPressed: busy ? null : moreEvidence,
                      child: Text(context.l10n.reviewsMore),
                    ),
                  if (d['status'] == 'pending') ...[
                    Text(context.l10n.bansExplanation),
                    TextField(
                      controller: reason,
                      enabled: !busy,
                      minLines: 2,
                      maxLines: 5,
                      maxLength: 2000,
                      decoration: InputDecoration(
                        labelText: context.l10n.reviewsReason,
                      ),
                    ),
                    Wrap(
                      spacing: 12,
                      children: [
                        OutlinedButton(
                          onPressed: busy || error == 'review-stale'
                              ? null
                              : () => decide('reject'),
                          child: Text(context.l10n.bansReject),
                        ),
                        FilledButton(
                          onPressed:
                              busy ||
                                  error == 'review-stale' ||
                                  d['pendingAppeals'] == true ||
                                  d['currentStrikes'] < 10
                              ? null
                              : () => decide('approve'),
                          child: Text(context.l10n.bansApprove),
                        ),
                      ],
                    ),
                  ],
                  if (busy) const LinearProgressIndicator(),
                ],
              ],
            ),
    );
  }
}
