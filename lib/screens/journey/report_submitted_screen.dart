import '../../l10n/report_view_presentation.dart';
import '../../l10n/localization_context.dart';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../models/report.dart';
import '../../models/enums/report_publication_state.dart';
import '../../services/report_submission_service.dart';
import '../main_shell.dart';

/// Displays delivery acknowledgement, not an unconditional success message.
class ReportSubmittedScreen extends StatefulWidget {
  const ReportSubmittedScreen({
    super.key,
    this.report,
    this.targetName = 'Selected location',
    this.submissionService,
  });
  final Report? report;
  final String targetName;
  final ReportSubmissionService? submissionService;

  @override
  State<ReportSubmittedScreen> createState() => _ReportSubmittedScreenState();
}

class _ReportSubmittedScreenState extends State<ReportSubmittedScreen> {
  Report? _receipt;

  @override
  Widget build(BuildContext context) {
    final service =
        widget.submissionService ?? ReportSubmissionService.instance;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final entry = widget.report == null
            ? null
            : service.find(widget.report!.id);
        final current =
            entry?.report ??
            _receipt ??
            (widget.report != null && service.isAcknowledged(widget.report!.id)
                ? widget.report!.copyWith(
                    publicationState: ReportPublicationState.published,
                  )
                : widget.report);
        final removed =
            entry == null &&
            current?.publicationState != ReportPublicationState.published;
        final state =
            current?.publicationState ?? ReportPublicationState.pendingUpload;
        final published = state == ReportPublicationState.published;
        final busy = current != null && service.isUploading(current.id);

        return Scaffold(
          backgroundColor: context.surfaceColor,
          appBar: AppBar(
            backgroundColor: context.surfaceColor,
            centerTitle: true,
            elevation: context.isHighContrast ? 0 : 1,
            toolbarHeight: MediaQuery.textScalerOf(context).scale(22) > 33
                ? 96
                : 56,
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
              context.l10n.deliveryTitle,
              maxLines: 2,
              softWrap: true,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: context.textColor,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _card(
                        Semantics(
                          liveRegion: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _heading(context.l10n.deliveryStatus),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    removed
                                        ? Icons.help_outline_rounded
                                        : published
                                        ? Icons.cloud_done_outlined
                                        : state == ReportPublicationState.failed
                                        ? Icons.error_outline_rounded
                                        : Icons.cloud_upload_outlined,
                                    size: 32,
                                    color: _statusColor(
                                      published,
                                      state == ReportPublicationState.failed &&
                                          !removed,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      removed
                                          ? context
                                                .l10n
                                                .deliveryDraftUnavailable
                                          : context.reportViewText(state.label),
                                      style: TextStyle(
                                        fontSize: 22,
                                        height: 1.3,
                                        fontWeight: FontWeight.w700,
                                        color: _statusColor(
                                          published,
                                          state ==
                                                  ReportPublicationState
                                                      .failed &&
                                              !removed,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                published
                                    ? context.l10n.deliveryPublicHelp
                                    : removed
                                    ? context.l10n.deliveryRemovedHelp
                                    : context.deliveryError(entry?.error),
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: context.subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _card(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _heading(
                              removed
                                  ? context.l10n.deliveryLocalUnavailable
                                  : context.l10n.deliveryObservation,
                            ),
                            if (!removed) ...[
                              const SizedBox(height: 16),
                              _detail(
                                context.l10n.deliveryTarget,
                                widget.targetName,
                              ),
                              if (current != null) ...[
                                const SizedBox(height: 16),
                                _detail(
                                  context.l10n.deliveryCondition,
                                  current.problemType,
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                      if (!removed &&
                          current != null &&
                          current.photoUrl.startsWith('https://')) ...[
                        const SizedBox(height: 16),
                        _card(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _heading(context.l10n.deliveryPhoto),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  current.photoUrl,
                                  height: 160,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      context.l10n.deliveryPhotoUnavailable,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (!published && entry != null) ...[
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: busy
                              ? null
                              : () => _retry(service, entry.report.id),
                          style: _filledStyle(),
                          child: Text(
                            busy
                                ? context.l10n.deliveryUploading
                                : context.l10n.deliveryRetry,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: Text(context.l10n.deliveryRemoveDevice),
                          onPressed: () => _remove(service, entry.report),
                        ),
                        const SizedBox(height: 12),
                        _card(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _heading(context.l10n.deliveryAboutDrafts),
                              const SizedBox(height: 8),
                              Text(
                                context.l10n.deliveryDraftExpiry,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: context.subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: published
                            ? () => Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const MainShell(initialTab: 'Community'),
                                ),
                                (route) => false,
                              )
                            : null,
                        style: _filledStyle(),
                        child: Text(
                          context.l10n.deliveryViewFeed,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () =>
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst),
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
                          context.l10n.deliveryHome,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _retry(ReportSubmissionService service, String id) async {
    try {
      final receipt = await service.retry(id);
      if (mounted) setState(() => _receipt = receipt.report);
    } catch (_) {
      if (mounted) _snack(context.l10n.deliverySaveFailed);
    }
  }

  Future<void> _remove(ReportSubmissionService service, Report report) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deliveryRemoveQuestion),
        content: SingleChildScrollView(
          child: Text(context.l10n.deliveryRemoveHelp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.deliveryKeep),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.deliveryRemove),
          ),
        ],
      ),
    );
    if (remove != true) return;
    try {
      await service.remove(report.id, userId: report.userId);
    } catch (_) {
      if (mounted) _snack(context.l10n.deliveryRemoveFailed);
    }
  }

  void _snack(String value) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));

  Color _statusColor(bool published, bool failed) => context.isHighContrast
      ? Colors.black
      : published
      ? AppColors.secondary
      : failed
      ? AppColors.error
      : context.primaryColor;

  ButtonStyle _filledStyle() => FilledButton.styleFrom(
    backgroundColor: context.primaryColor,
    foregroundColor: Colors.white,
    minimumSize: Size(context.buttonHeight, context.buttonHeight),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    textStyle: Theme.of(context).textTheme.labelLarge
        ?.copyWith(fontSize: 16, fontWeight: FontWeight.w700, height: 1.25),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _detail(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 12, color: context.subtextColor)),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          fontSize: 16,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: context.textColor,
        ),
      ),
    ],
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
}
