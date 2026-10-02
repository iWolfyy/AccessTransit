import 'dart:io';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/time_utils.dart';
import '../../models/report.dart';
import '../main_shell.dart';

/// Modern success screen after submitting a condition report, matching LMT Go design.
class ReportSubmittedScreen extends StatelessWidget {
  const ReportSubmittedScreen({
    super.key,
    this.report,
    this.targetName = 'Central Station',
  });

  final Report? report;
  final String targetName;

  void _goToCommunity(BuildContext context) {
    final shell = context.findAncestorStateOfType<MainShellState>();
    if (shell != null) {
      shell.switchToTab('Community');
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MainShell(),
        ),
        (route) => false,
      );
    }
  }

  void _goToHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;
    final timeFormatted = report != null
        ? TimeUtils.formatRelativeTime(report!.createdAt)
        : 'Just now';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.onSurface),
          onPressed: () => _goToHome(context),
          tooltip: 'Close',
        ),
        title: const Text(
          'Submission Confirmation',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isDesktop ? 32 : 20,
              ),
              children: [
                // Celebration Icon
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success.withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 58,
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Main Title
                const Text(
                  'Report Submitted!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Reward Banner
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars_rounded, color: AppColors.primary, size: 18),
                        SizedBox(width: 6),
                        Text(
                          '+10 Community Points Earned 🎉',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Thank you for reporting. Your real-time update helps wheelchair and elderly commuters navigate with confidence.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                // Summary Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              report?.targetType == 'bus'
                                  ? Icons.directions_bus_rounded
                                  : Icons.store_mall_directory_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  targetName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Submitted $timeFormatted',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt_rounded, size: 14, color: AppColors.success),
                                SizedBox(width: 4),
                                Text(
                                  'Live',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 24),

                      // Issue Title
                      Text(
                        report != null ? report!.problemType : 'Accessibility Issue Reported',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: AppColors.onSurface,
                        ),
                      ),
                      if (report != null) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (report!.category.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _formatCategory(report!.category),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            if (report!.severity.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _severityColor(report!.severity).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${report!.severity[0].toUpperCase()}${report!.severity.substring(1)} Severity',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _severityColor(report!.severity),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],

                      // User note if present
                      if (report != null && report!.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '“${report!.description.trim()}”',
                            style: const TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],

                      // Attached Photo Preview
                      if (report != null && report!.photoUrl.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: report!.photoUrl.startsWith('http')
                              ? Image.network(
                                  report!.photoUrl,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                                )
                              : Image.file(
                                  File(report!.photoUrl),
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                                ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Primary CTA: View in Community Feed
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => _goToCommunity(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.forum_rounded, size: 20),
                    label: const Text(
                      'View in Community Feed',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Secondary CTA: Back to Home
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _goToHome(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: AppColors.outlineVariant),
                    ),
                    icon: const Icon(Icons.home_rounded, size: 20, color: AppColors.onSurface),
                    label: const Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCategory(String category) {
    switch (category) {
      case 'rampAccess':
        return 'Ramp & Access';
      case 'elevatorOut':
        return 'Elevator / Lift';
      case 'crowding':
        return 'Crowding';
      case 'cleanliness':
        return 'Cleanliness';
      case 'safetyHazard':
        return 'Safety Hazard';
      default:
        return category;
    }
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'major':
        return AppColors.error;
      case 'minor':
        return AppColors.success;
      case 'moderate':
      default:
        return const Color(0xFFF57F17);
    }
  }
}

