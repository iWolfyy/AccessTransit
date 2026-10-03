import 'dart:io';
import 'dart:io';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
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

  Widget _buildImageWidget(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return Image.network(
        pathOrUrl,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }

    try {
      final file = File(pathOrUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          height: 140,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        );
      }
    } catch (_) {}

    return Image.network(
      pathOrUrl,
      height: 140,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;
    final isHC = context.isHighContrast;
    final timeFormatted = report != null
        ? TimeUtils.formatRelativeTime(report!.createdAt)
        : 'Just now';

    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        shape: isHC
            ? const Border(bottom: BorderSide(color: Colors.black, width: 2))
            : null,
        leading: IconButton(
          constraints: context.appBarActionConstraints,
          icon: Icon(
            Icons.close_rounded,
            color: isHC ? Colors.black : AppColors.onSurface,
            size: context.tapIconSize,
          ),
          onPressed: () => _goToHome(context),
          tooltip: 'Close',
        ),
        title: Text(
          'Submission Confirmation',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.textColor,
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
                      color: isHC
                          ? Colors.white
                          : AppColors.success.withValues(alpha: 0.15),
                      border: isHC
                          ? Border.all(color: const Color(0xFF003833), width: 3)
                          : null,
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 58,
                      color: isHC ? const Color(0xFF003833) : AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Main Title
                Text(
                  'Report Submitted!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 8),

                // Reward Banner
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isHC
                          ? Colors.white
                          : AppColors.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: isHC
                          ? Border.all(color: Colors.black, width: 2)
                          : Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          color: isHC ? const Color(0xFF001F3F) : AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '+10 Community Points Earned 🎉',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isHC ? const Color(0xFF001F3F) : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Thank you for reporting. Your real-time update helps wheelchair and elderly commuters navigate with confidence.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.subtextColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                // Summary Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: isHC
                        ? Border.all(color: Colors.black, width: 2)
                        : Border.all(color: AppColors.outlineVariant),
                    boxShadow: isHC
                        ? null
                        : [
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
                              color: isHC
                                  ? Colors.white
                                  : AppColors.primaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                              border: isHC
                                  ? Border.all(color: Colors.black, width: 1.5)
                                  : null,
                            ),
                            child: Icon(
                              report?.targetType == 'bus'
                                  ? Icons.directions_bus_rounded
                                  : Icons.store_mall_directory_rounded,
                              size: 20,
                              color: isHC ? Colors.black : AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  targetName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: context.textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Submitted $timeFormatted',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.subtextColor,
                                  ),
                                ),
                              ],
                            ),
                            if (report?.photoUrl != null &&
                                report!.photoUrl!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildImageWidget(report!.photoUrl!),
                              ),
                            ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  size: 14,
                                  color: isHC ? const Color(0xFF003833) : AppColors.success,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Live',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isHC ? const Color(0xFF003833) : AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      Divider(
                        height: 24,
                        color: isHC ? Colors.black : null,
                      ),

                      // Issue Title
                      Text(
                        report != null ? report!.problemType : 'Accessibility Issue Reported',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: context.textColor,
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
                                  color: isHC
                                      ? Colors.white
                                      : AppColors.primaryContainer.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(6),
                                  border: isHC
                                      ? Border.all(color: const Color(0xFF001F3F), width: 1.5)
                                      : null,
                                ),
                                child: Text(
                                  _formatCategory(report!.category),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isHC ? const Color(0xFF001F3F) : AppColors.primary,
                                  ),
                                ),
                              ),
                            if (report!.severity.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isHC
                                      ? Colors.white
                                      : _severityColor(report!.severity).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: isHC
                                      ? Border.all(
                                          color: _severityColor(report!.severity, isHC: true),
                                          width: 1.5,
                                        )
                                      : null,
                                ),
                                child: Text(
                                  '${report!.severity[0].toUpperCase()}${report!.severity.substring(1)} Severity',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _severityColor(report!.severity, isHC: isHC),
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
                            color: isHC ? Colors.white : AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(10),
                            border: isHC ? Border.all(color: Colors.black, width: 1.5) : null,
                          ),
                          child: Text(
                            '“${report!.description.trim()}”',
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: context.textColor,
                            ),
                          ),
                        ),
                      ],

                      // Attached Photo Preview
                      if (report != null && report!.photoUrl.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: isHC ? Border.all(color: Colors.black, width: 2) : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
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
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Primary CTA: View in Community Feed
                SizedBox(
                  height: context.buttonHeight,
                  child: FilledButton.icon(
                    onPressed: () => _goToCommunity(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: isHC
                          ? const Color(0xFF001F3F)
                          : AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      side: isHC ? const BorderSide(color: Colors.black, width: 2) : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: Icon(Icons.forum_rounded, size: context.tapIconSize),
                    label: Text(
                      'View in Community Feed',
                      style: TextStyle(
                        fontSize: context.buttonFontSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Secondary CTA: Back to Home
                SizedBox(
                  height: context.buttonHeight,
                  child: OutlinedButton.icon(
                    onPressed: () => _goToHome(context),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isHC ? Colors.white : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(
                        color: isHC ? Colors.black : AppColors.outlineVariant,
                        width: isHC ? 2 : 1,
                      ),
                    ),
                    icon: Icon(
                      Icons.home_rounded,
                      size: context.tapIconSize,
                      color: isHC ? Colors.black : AppColors.onSurface,
                    ),
                    label: Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: context.buttonFontSize,
                        fontWeight: FontWeight.w600,
                        color: isHC ? Colors.black : AppColors.onSurface,
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

  Color _severityColor(String severity, {bool isHC = false}) {
    switch (severity.toLowerCase()) {
      case 'major':
        return isHC ? const Color(0xFF8B0000) : AppColors.error;
      case 'minor':
        return isHC ? const Color(0xFF003833) : AppColors.success;
      case 'moderate':
      default:
        return isHC ? const Color(0xFF8B4500) : const Color(0xFFF57F17);
    }
  }
}

