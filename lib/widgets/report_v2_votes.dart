import 'package:flutter/material.dart';

import '../l10n/localization_context.dart';
import '../models/report.dart';
import '../services/firestore_service.dart';
import '../services/moderation_client.dart';

/// Per-user state comes from the authenticated endpoint, never a public UID list.
class ReportV2Votes extends StatefulWidget {
  const ReportV2Votes({super.key, required this.report, this.service});
  final Report report;
  final FirestoreService? service;
  @override
  State<ReportV2Votes> createState() => _ReportV2VotesState();
}

class _ReportV2VotesState extends State<ReportV2Votes> {
  late final service = widget.service ?? FirestoreService();
  Future<ModerationVoteStatus>? status;
  bool saving = false;
  String? owner;
  int revision = 0;
  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void didUpdateWidget(ReportV2Votes old) {
    super.didUpdateWidget(old);
    if (old.report.id != widget.report.id ||
        owner != service.currentReportActorId ||
        old.report.status != widget.report.status ||
        old.report.falseCount != widget.report.falseCount ||
        old.report.confirmCount != widget.report.confirmCount) {
      reload();
    }
  }

  void reload() {
    owner = service.currentReportActorId;
    revision++;
    status = owner == null || owner!.isEmpty || owner == widget.report.userId
        ? null
        : service.moderationClient.voteStatus(widget.report.id);
  }

  Future<void> vote(bool positive) async {
    final actor = service.currentReportActorId, version = revision;
    if (saving ||
        actor == null ||
        actor != owner ||
        actor == widget.report.userId) {
      return;
    }
    String reason = '';
    if (!positive) {
      var draft = '';
      final form = GlobalKey<FormState>();
      final answer = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.falseVoteReason),
          content: Form(
            key: form,
            child: TextFormField(
              onChanged: (value) => draft = value,
              maxLength: 1000,
              minLines: 2,
              maxLines: 5,
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.l10n.falseVoteReason,
              ),
              validator: (v) => (v ?? '').trim().length < 5
                  ? context.l10n.falseVoteReasonMinimum
                  : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.voteCancel),
            ),
            FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) {
                  Navigator.pop(ctx, draft.trim());
                }
              },
              child: Text(context.l10n.voteSubmit),
            ),
          ],
        ),
      );
      if (answer == null) return;
      reason = answer;
    }
    if (!mounted ||
        actor != service.currentReportActorId ||
        version != revision) {
      return;
    }
    setState(() => saving = true);
    try {
      await service.voteReportV2(
        widget.report,
        isTrue: positive,
        reason: reason,
      );
      if (!mounted || actor != service.currentReportActorId) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.voteAcknowledged)));
      setState(reload);
    } catch (_) {
      if (mounted && actor == service.currentReportActorId) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.voteUnavailable)));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (owner == null || owner!.isEmpty) return Text(l.voteSignIn);
    if (widget.report.userId == owner) return Text(l.authorVoteDisabled);
    return FutureBuilder<ModerationVoteStatus>(
      future: status,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return TextButton(
            onPressed: () => setState(reload),
            child: Text(l.voteRetry),
          );
        }
        final data = snapshot.data;
        if (data == null) return const LinearProgressIndicator();
        if (data.isAuthor) return Text(l.authorVoteDisabled);
        if (data.status != 'active' || widget.report.isDisputed) {
          return Text(l.votingClosed);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.voteNoPoints),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: saving || data.userVote == 'true'
                      ? null
                      : () => vote(true),
                  icon: const Icon(Icons.thumb_up_outlined),
                  label: Text('${l.voteTrue} (${data.confirmCount})'),
                ),
                OutlinedButton.icon(
                  onPressed: saving || data.userVote == 'false'
                      ? null
                      : () => vote(false),
                  icon: const Icon(Icons.flag_outlined),
                  label: Text('${l.voteFalse} (${data.falseCount}/5)'),
                ),
              ],
            ),
            if (saving) const LinearProgressIndicator(),
          ],
        );
      },
    );
  }
}
