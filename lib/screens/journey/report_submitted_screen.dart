import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
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
          appBar: AppBar(title: const Text('Report delivery')),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Icon(
                      published
                          ? Icons.cloud_done
                          : state == ReportPublicationState.failed
                          ? Icons.error_outline
                          : Icons.cloud_upload_outlined,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      removed ? 'Draft unavailable' : state.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      published
                          ? 'Your report is available to other commuters.'
                          : removed
                          ? 'This draft was removed, expired or belongs to another account. Publication has not been confirmed.'
                          : entry?.error ?? 'Saved on this device. Publication has not been confirmed.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      removed ? 'Local draft unavailable' : widget.targetName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (!removed && current != null) Text(current.problemType),
                    if (!removed &&
                        current != null &&
                        current.photoUrl.startsWith('https://')) ...[
                      const SizedBox(height: 12),
                      Image.network(
                        current.photoUrl,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Text('Photo preview unavailable'),
                      ),
                    ],
                    if (!published && entry != null) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        height: context.buttonHeight,
                        child: FilledButton(
                          onPressed: busy
                              ? null
                              : () async {
                                  try {
                                    final receipt = await service.retry(
                                      entry.report.id,
                                    );
                                    if (mounted) {
                                      setState(() => _receipt = receipt.report);
                                    }
                                  } catch (_) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Could not save the upload status. Please retry.',
                                              ),
                                            ),
                                          );
                                    }
                                  }
                                },
                          child: Text(busy ? 'Uploading…' : 'Retry upload'),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove draft from this device'),
                        onPressed: () async {
                          final remove = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Remove local draft?'),
                              content: const Text(
                                'Stops future retries and removes the local note/photo. A request already sent may still complete. This does not delete a public report or an uploaded photo.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Keep draft'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Remove draft'),
                                ),
                              ],
                            ),
                          );
                          if (remove != true) return;
                          try {
                            await service.remove(
                              entry.report.id,
                              userId: entry.report.userId,
                            );
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Local removal could not be saved. Please retry.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      const Text(
                        'Drafts expire after 7 days and are removed on sign-out/account change.',
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      height: context.buttonHeight,
                      child: FilledButton(
                        onPressed: published
                            ? () => Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const MainShell(initialTab: 'Community'),
                                ),
                                (route) => false,
                              )
                            : null,
                        child: const Text('View in Community Feed'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: context.buttonHeight,
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst),
                        child: const Text('Back to Home'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
