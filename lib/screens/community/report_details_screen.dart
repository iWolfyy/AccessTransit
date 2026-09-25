import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../constants/firestore_constants.dart';
import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/time_utils.dart';
import '../../logic/status_logic.dart';
import '../../models/report.dart';
import '../../services/firestore_service.dart';

/// Community report details — status, vehicle, conditions, map, actions.
class ReportDetailsScreen extends StatefulWidget {
  const ReportDetailsScreen({
    super.key,
    this.report,
    this.reportId,
    this.targetTitle = 'Central Station',
    this.title = 'Crowded Bus',
    this.reportedAgo = 'Reported 10 min ago',
    this.vehicleLabel = 'Bus 138',
    this.routeLabel = 'Route: Colombo Fort',
    this.crowdLevel = 'High',
    this.accessibilityLabel = 'Limited',
    this.quote =
        '"Bus is full to the door. Wheelchair ramp cannot be deployed at this time due to crowding." - User report',
    this.mapLocationLabel = 'Near Galle Road',
    this.communityVerified = true,
    this.mapImageUrl =
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAOMMcLufr5bpq0EgIxEjqEV1LLclBgoIANV1g531KV4Zys1O3GHBI_pr_mgZ2otnxPhD2Eaae8tKy0R23GOFc7CPANsZxaAnGPObXTw92waN1G_9v-1maG4whOGa-BcLo2mimewhM-r-F4zDN1zAGyRZpXrvTu9GDEJAIFNY3_0yFb32q3xsG1Knafg-ipok7lYOiu-IpV3g6OBm2YTwAZC_QRWqnGN-FtO5QnEuTX3jVQD-r7iw-_KA',
  });

  final Report? report;
  final String? reportId;
  final String targetTitle;
  final String title;
  final String reportedAgo;
  final String vehicleLabel;
  final String routeLabel;
  final String crowdLevel;
  final String accessibilityLabel;
  final String quote;
  final String mapLocationLabel;
  final bool communityVerified;
  final String mapImageUrl;

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  static const double _desktopBreakpoint = 768;
  static const Color _tertiaryContainer = Color(0xFF7D3500);

  bool _isLoadingAction = false;

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onNavTap(String label) {
    AppNavigation.handleBottomNav(
      context,
      label,
      currentTab: 'Community',
      onUnsupported: _showSnack,
    );
  }

  Future<void> _handleConfirm(Report report) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'user_anon';
    if (report.confirmedBy.contains(userId)) {
      _showSnack('You already confirmed this report.');
      return;
    }

    setState(() => _isLoadingAction = true);
    try {
      await FirestoreService().confirmReport(report.id, userId);
      if (mounted) {
        _showSnack('Confirmed report! Expiry timer reset.');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Action failed: ${e.toString().replaceAll('Exception: ', '')}');
      }
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _handleResolve(Report report) async {
    setState(() => _isLoadingAction = true);
    try {
      await FirestoreService().resolveReport(report.id);
      if (mounted) {
        _showSnack('Report marked as resolved!');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Action failed: ${e.toString().replaceAll('Exception: ', '')}');
      }
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _handleFlag(Report report) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'user_anon';
    if (report.flaggedBy.contains(userId)) {
      _showSnack('You already flagged this report.');
      return;
    }

    setState(() => _isLoadingAction = true);
    try {
      await FirestoreService().flagReport(report.id, userId);
      if (mounted) {
        _showSnack('Report flagged as false.');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Action failed: ${e.toString().replaceAll('Exception: ', '')}');
      }
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;
    final targetReportId = widget.report?.id ?? widget.reportId ?? '';

    if (targetReportId.isNotEmpty) {
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(FirestoreConstants.reportsCollection)
            .doc(targetReportId)
            .snapshots(),
        builder: (context, snapshot) {
          Report currentReport = widget.report ??
              Report(
                id: targetReportId,
                targetType: 'station',
                targetId: '',
                problemType: widget.title,
                status: 'active',
                createdAt: DateTime.now(),
                userId: '',
              );

          if (snapshot.hasData && snapshot.data!.exists) {
            currentReport = Report.fromFirestore(snapshot.data!);
          }

          return _buildContent(context, isDesktop, currentReport);
        },
      );
    }

    return _buildContent(context, isDesktop, widget.report);
  }

  Widget _buildContent(
    BuildContext context,
    bool isDesktop,
    Report? report,
  ) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'user_anon';
    final isReportActive =
        report != null ? StatusLogic.isReportActive(report) : true;
    final isResolved = report?.status.toLowerCase() == 'resolved';
    final isHidden = report?.status.toLowerCase() == 'hidden';
    final hasConfirmed = report?.confirmedBy.contains(userId) ?? false;
    final hasFlagged = report?.flaggedBy.contains(userId) ?? false;

    final displayTitle = report?.problemType ?? widget.title;
    final timeAgoText = report != null
        ? 'Reported ${TimeUtils.formatRelativeTime(report.createdAt)}'
        : widget.reportedAgo;
    final lastConfirmedAgoText = report?.lastConfirmedAt != null
        ? TimeUtils.formatRelativeTime(report!.lastConfirmedAt!)
        : TimeUtils.formatRelativeTime(report?.createdAt ?? DateTime.now());

    final trustLine = report != null
        ? (report.confirmCount > 0
            ? 'Confirmed by ${report.confirmCount} ${report.confirmCount == 1 ? 'rider' : 'riders'}, $lastConfirmedAgoText'
            : 'Reported $timeAgoText')
        : 'Confirmed by riders';

    final targetNameLabel = widget.targetTitle;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _TopBar(
            onBack: () => Navigator.of(context).maybePop(),
            onProfile: isDesktop ? () => _onNavTap('Profile') : null,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                isDesktop ? 24 : 16,
                16,
                24,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1024),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StatusCard(
                          title: displayTitle,
                          reportedAgo: trustLine,
                          vehicleLabel: targetNameLabel,
                          routeLabel: report != null
                              ? 'Target: ${report.targetType.toUpperCase()} (${report.targetId})'
                              : widget.routeLabel,
                          crowdLevel: widget.crowdLevel,
                          accessibilityLabel: isResolved
                              ? 'Resolved / Fixed'
                              : (isReportActive ? 'Warning / Issue' : 'Expired'),
                          quote: widget.quote,
                          communityVerified: (report?.confirmCount ?? 0) > 0,
                          isResolved: isResolved,
                          isExpired: !isReportActive && !isResolved,
                          tertiaryContainer: _tertiaryContainer,
                        ),
                        const SizedBox(height: 24),
                        _MapSection(
                          imageUrl: widget.mapImageUrl,
                          locationLabel: targetNameLabel,
                        ),
                        const SizedBox(height: 24),
                        if (report != null && !isHidden) ...[
                          _ReportActionPanel(
                            report: report,
                            isReportActive: isReportActive,
                            isResolved: isResolved,
                            hasConfirmed: hasConfirmed,
                            hasFlagged: hasFlagged,
                            isLoading: _isLoadingAction,
                            onConfirm: () => _handleConfirm(report),
                            onResolve: () => _handleResolve(report),
                            onFlag: () => _handleFlag(report),
                          ),
                        ] else if (isHidden) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'This report has been hidden due to multiple false flags.',
                              style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ] else ...[
                          _ActionButtons(
                            onShare: () => _showSnack('Share Alert coming soon.'),
                            onAddUpdate: () =>
                                _showSnack('Add Update coming soon.'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : _DetailsBottomNav(
              onNavTap: _onNavTap,
            ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    this.onProfile,
  });

  final VoidCallback onBack;
  final VoidCallback? onProfile;

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
                  onPressed: onBack,
                  tooltip: 'Go back',
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'Report Details',
                    style: TextStyle(
                      fontSize: 22,
                      height: 28 / 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (onProfile != null)
                  IconButton(
                    onPressed: onProfile,
                    tooltip: 'User profile',
                    icon: const Icon(
                      Icons.account_circle,
                      color: AppColors.primary,
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.reportedAgo,
    required this.vehicleLabel,
    required this.routeLabel,
    required this.crowdLevel,
    required this.accessibilityLabel,
    required this.quote,
    required this.communityVerified,
    required this.isResolved,
    required this.isExpired,
    required this.tertiaryContainer,
  });

  final String title;
  final String reportedAgo;
  final String vehicleLabel;
  final String routeLabel;
  final String crowdLevel;
  final String accessibilityLabel;
  final String quote;
  final bool communityVerified;
  final bool isResolved;
  final bool isExpired;
  final Color tertiaryContainer;

  @override
  Widget build(BuildContext context) {
    final Color topBarColor;
    if (isResolved) {
      topBarColor = AppColors.success;
    } else if (isExpired) {
      topBarColor = AppColors.outline;
    } else {
      topBarColor = AppColors.error;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: 4, color: topBarColor),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isResolved
                                  ? AppColors.success.withValues(alpha: 0.2)
                                  : AppColors.errorContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isResolved ? Icons.check_circle : Icons.warning,
                              color: isResolved
                                  ? AppColors.success
                                  : AppColors.onErrorContainer,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    height: 24 / 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule,
                                      size: 16,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        reportedAgo,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 20 / 14,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isResolved) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Resolved',
                              style: TextStyle(
                                fontSize: 12,
                                height: 16 / 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (communityVerified) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: AppColors.onSecondary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Community Verified',
                              style: TextStyle(
                                fontSize: 12,
                                height: 16 / 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.onSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 560;
                    final vehicle = _VehicleInfo(
                      vehicleLabel: vehicleLabel,
                      routeLabel: routeLabel,
                    );
                    final conditions = _ConditionsInfo(
                      crowdLevel: crowdLevel,
                      accessibilityLabel: accessibilityLabel,
                      tertiaryContainer: tertiaryContainer,
                    );

                    if (stacked) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          vehicle,
                          const SizedBox(height: 16),
                          conditions,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: vehicle),
                        const SizedBox(width: 16),
                        Expanded(child: conditions),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleInfo extends StatelessWidget {
  const _VehicleInfo({
    required this.vehicleLabel,
    required this.routeLabel,
  });

  final String vehicleLabel;
  final String routeLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Target Location',
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicleLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 24 / 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    routeLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConditionsInfo extends StatelessWidget {
  const _ConditionsInfo({
    required this.crowdLevel,
    required this.accessibilityLabel,
    required this.tertiaryContainer,
  });

  final String crowdLevel;
  final String accessibilityLabel;
  final Color tertiaryContainer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Status',
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MetricBadge(
                icon: Icons.accessible,
                iconColor: tertiaryContainer,
                label: 'Status',
                value: accessibilityLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapSection extends StatelessWidget {
  const _MapSection({
    required this.imageUrl,
    required this.locationLabel,
  });

  final String imageUrl;
  final String locationLabel;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 768;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: isWide ? 256 : 192,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.surfaceContainer,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.map_outlined,
                  size: 48,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  locationLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Action panel for real report operations (AC-79, AC-80, AC-83).
class _ReportActionPanel extends StatelessWidget {
  const _ReportActionPanel({
    required this.report,
    required this.isReportActive,
    required this.isResolved,
    required this.hasConfirmed,
    required this.hasFlagged,
    required this.isLoading,
    required this.onConfirm,
    required this.onResolve,
    required this.onFlag,
  });

  final Report report;
  final bool isReportActive;
  final bool isResolved;
  final bool hasConfirmed;
  final bool hasFlagged;
  final bool isLoading;
  final VoidCallback onConfirm;
  final VoidCallback onResolve;
  final VoidCallback onFlag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Community Verification & Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (hasConfirmed)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'You already confirmed this report.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (hasFlagged)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'You already flagged this report.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: (hasConfirmed || isLoading || isResolved)
                        ? null
                        : onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.thumb_up, size: 18),
                    label: Text(
                      hasConfirmed ? 'Confirmed' : 'Still broken',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: (isResolved || isLoading) ? null : onResolve,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: BorderSide(
                        color: isResolved ? AppColors.outline : AppColors.success,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      isResolved ? 'Resolved' : 'Fixed now',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: (hasFlagged || isLoading) ? null : onFlag,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              icon: const Icon(Icons.flag_outlined, size: 16),
              label: Text(
                hasFlagged ? 'Flagged as false' : 'Report as false',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onShare,
    required this.onAddUpdate,
  });

  final VoidCallback onShare;
  final VoidCallback onAddUpdate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 520;
        final share = SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: onShare,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryContainer,
              side: const BorderSide(
                color: AppColors.primaryContainer,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: const Icon(Icons.share, size: 20),
            label: const Text('Share Alert'),
          ),
        );
        final update = SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: onAddUpdate,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: const Icon(Icons.add_comment, size: 20),
            label: const Text('Add Update'),
          ),
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              share,
              const SizedBox(height: 8),
              update,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            share,
            const SizedBox(width: 8),
            update,
          ],
        );
      },
    );
  }
}

/// App-standard nav: Home → Plan → Live → Community → Profile.
class _DetailsBottomNav extends StatelessWidget {
  const _DetailsBottomNav({required this.onNavTap});

  final ValueChanged<String> onNavTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: AppColors.onSurface.withValues(alpha: 0.12),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                onTap: () => onNavTap('Home'),
              ),
              _NavItem(
                icon: Icons.directions_bus_outlined,
                label: 'Plan',
                onTap: () => onNavTap('Plan'),
              ),
              _NavItem(
                icon: Icons.sensors,
                label: 'Live',
                onTap: () => onNavTap('Live'),
              ),
              _NavItem(
                icon: Icons.group_outlined,
                label: 'Community',
                selected: true,
                onTap: () => onNavTap('Community'),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                onTap: () => onNavTap('Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: selected
            ? BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected
                  ? AppColors.onPrimaryContainer
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                height: 16 / 12,
                color: selected
                    ? AppColors.onPrimaryContainer
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
