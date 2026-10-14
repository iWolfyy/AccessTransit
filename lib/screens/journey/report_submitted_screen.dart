import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/report.dart';
import '../../models/enums/report_publication_state.dart';
import '../../services/report_submission_service.dart';
import '../main_shell.dart';

/// Displays delivery acknowledgement, not an unconditional success message.
class ReportSubmittedScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final service = submissionService ?? ReportSubmissionService.instance;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final entry = report == null ? null : service.find(report!.id);
        final current = entry?.report ?? report;
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
                      state.label,
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
                          : entry?.error ?? 'Saved on this device. Publication has not been confirmed.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      targetName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (current != null) Text(current.problemType),
                    if (current != null &&
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
                                    await service.retry(entry.report.id);
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
