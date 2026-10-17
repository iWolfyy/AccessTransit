import '../l10n/localization_context.dart';
import '../l10n/report_view_presentation.dart';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/app_colors.dart';

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
            Text(
              context.l10n.outboxTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.outboxHelp,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: context.subtextColor,
              ),
            ),
            const SizedBox(height: 12),
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
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
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Icon(
                      entry.report.publicationState ==
                              ReportPublicationState.failed
                          ? Icons.error_outline_rounded
                          : Icons.cloud_upload_outlined,
                      color: context.primaryColor,
                    ),
                    title: Text(entry.report.problemType),
                    subtitle: Text(
                      context.reportViewText(
                        entry.report.publicationState.label,
                      ),
                    ),
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
                ),
              ),
          ],
        );
      },
    );
  }
}
