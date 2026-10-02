import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/time_utils.dart';
import '../../models/report.dart';
import '../community/community_screen.dart';

/// Success state after submitting a condition report.
class ReportSubmittedScreen extends StatelessWidget {
  const ReportSubmittedScreen({
    super.key,
    this.report,
    this.targetName = 'Central Station',
  });

  final Report? report;
  final String targetName;

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _TopBar(
            onMenu: () => _showSnack(context, 'Menu will be available soon.'),
            onSearch: () =>
                _showSnack(context, 'Search will be available soon.'),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success.withValues(alpha: 0.2),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 64,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Report Submitted',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          height: 28 / 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Thank you for helping other commuters.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 24 / 16,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.primaryContainer,
                                  child: Icon(
                                    Icons.accessible_forward,
                                    color: AppColors.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        report != null
                                            ? report!.problemType
                                            : 'Report Active',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          height: 24 / 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$targetName • ${report != null ? TimeUtils.formatRelativeTime(report!.createdAt) : 'Just now'}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 20 / 14,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Status: Active • Visible in Community Hub',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (report?.photoUrl != null &&
                                report!.photoUrl!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  report!.photoUrl!,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const CommunityScreen(),
                              ),
                              (route) => route.isFirst,
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                            foregroundColor: AppColors.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                          ),
                          child: const Text('Back to Community'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: null,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onMenu,
    required this.onSearch,
  });

  final VoidCallback onMenu;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 1,
      shadowColor: AppColors.onSurface.withValues(alpha: 0.08),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: onMenu,
                  tooltip: 'Menu',
                  icon: const Icon(
                    Icons.menu,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Community',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      height: 28 / 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onSearch,
                  tooltip: 'Search',
                  icon: const Icon(
                    Icons.search,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// App-standard nav: Home → Plan → Live → Community → Profile.
