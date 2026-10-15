import 'package:flutter/material.dart';

import '../models/enums/report_publication_state.dart';
import '../services/report_submission_service.dart';
import '../screens/journey/report_submitted_screen.dart';

class ReportOutboxList extends StatelessWidget {
  const ReportOutboxList({
    super.key,
    required this.userId,
    this.submissionService,
  });
  final String? userId;
  final ReportSubmissionService? submissionService;
  @override
  Widget build(BuildContext context) {
    final service = submissionService ?? ReportSubmissionService.instance;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final entries = service.entries
            .where(
              (entry) =>
                  userId != null &&
                  entry.report.userId == userId &&
                  entry.report.publicationState !=
                      ReportPublicationState.published,
            )
            .toList();
        if (entries.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Your uploads',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'Drafts expire after 7 days. Open an upload to retry or remove it. Sign-out removes local drafts.',
            ),
            for (final entry in entries)
              ListTile(
                title: Text(entry.report.problemType),
                subtitle: Text(entry.report.publicationState.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReportSubmittedScreen(
                      report: entry.report,
                      targetName: entry.report.targetName,
                      submissionService: service,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
