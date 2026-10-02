import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/time_utils.dart';
import '../../logic/status_logic.dart';
import '../../models/bus.dart';
import '../../models/report.dart';
import '../../models/station.dart';
import '../../services/firestore_service.dart';
import '../journey/report_condition_screen.dart';
import 'report_details_screen.dart';

enum _CommunityTab { liveUpdates, myReports }

enum _ReportBadge { active, verified, resolved, expired }

/// Community hub — live updates feed and my reports matching LMT Go design.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  _CommunityTab _tab = _CommunityTab.liveUpdates;
  final FirestoreService _firestoreService = FirestoreService();

  Map<String, Station> _stationsMap = {};
  Map<String, Bus> _busesMap = {};

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    try {
      final stations = await _firestoreService.getStations();
      final buses = await _firestoreService.getBuses();

      if (mounted) {
        setState(() {
          _stationsMap = {for (final s in stations) s.id: s};
          _busesMap = {for (final b in buses) b.id: b};
        });
      }
    } catch (_) {}
  }

  void _openReportIssue() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ReportConditionScreen(),
      ),
    );
  }

  String _resolveTargetTitle(Report report) {
    if (report.targetName.trim().isNotEmpty) {
      return report.targetName;
    }
    if (report.targetType.toLowerCase() == 'station') {
      return _stationsMap[report.targetId]?.name ?? 'Station ${report.targetId}';
    } else {
      final bus = _busesMap[report.targetId];
      if (bus != null) {
        return 'Bus Route ${bus.routeNo}';
      }
      return 'Bus ${report.targetId}';
    }
  }

  void _openReportDetails(Report report) {
    final targetTitle = _resolveTargetTitle(report);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportDetailsScreen(
          report: report,
          targetTitle: targetTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community Hub',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              'Real-time accessibility alerts from fellow riders',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openReportIssue,
            tooltip: 'Report Issue',
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton.extended(
          onPressed: _openReportIssue,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(Icons.add_alert_rounded, size: 20),
          label: const Text(
            'Report Issue',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: _ModernFilterTabs(
                selected: _tab,
                onChanged: (tab) => setState(() => _tab = tab),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Report>>(
                stream: _firestoreService.streamReports(
                  userId: _tab == _CommunityTab.myReports ? currentUserId : null,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  final reports = snapshot.data ?? [];

                  // Separate active vs expired/resolved
                  final activeReports = <Report>[];
                  final inactiveReports = <Report>[];

                  for (final r in reports) {
                    if (StatusLogic.isReportActive(r)) {
                      activeReports.add(r);
                    } else {
                      inactiveReports.add(r);
                    }
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // If My Reports tab is active, show the points & contribution banner
                              if (_tab == _CommunityTab.myReports) ...[
                                _MyContributionsBanner(
                                  reportCount: reports.length,
                                  onNewReport: _openReportIssue,
                                ),
                                const SizedBox(height: 16),
                              ],

                              if (reports.isEmpty)
                                _buildEmptyState()
                              else ...[
                                // Active reports section
                                if (activeReports.isNotEmpty) ...[
                                  for (var i = 0; i < activeReports.length; i++) ...[
                                    if (i > 0) const SizedBox(height: 12),
                                    _ModernReportCard(
                                      report: activeReports[i],
                                      targetTitle: _resolveTargetTitle(activeReports[i]),
                                      isActive: true,
                                      onTap: () => _openReportDetails(activeReports[i]),
                                    ),
                                  ],
                                ],

                                // Inactive / Resolved section header
                                if (inactiveReports.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  const Row(
                                    children: [
                                      Expanded(child: Divider(color: AppColors.outlineVariant)),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          'Resolved & Past Reports',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      Expanded(child: Divider(color: AppColors.outlineVariant)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  for (var i = 0; i < inactiveReports.length; i++) ...[
                                    if (i > 0) const SizedBox(height: 12),
                                    _ModernReportCard(
                                      report: inactiveReports[i],
                                      targetTitle: _resolveTargetTitle(inactiveReports[i]),
                                      isActive: false,
                                      onTap: () => _openReportDetails(inactiveReports[i]),
                                    ),
                                  ],
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isMyReports = _tab == _CommunityTab.myReports;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMyReports ? Icons.assignment_turned_in_outlined : Icons.check_circle_outline_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isMyReports ? 'No Reports Yet' : 'All Clear on the Corridors',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isMyReports
                  ? 'Reports you submit about wheelchair access, crowding, or lifts will show up here.'
                  : 'No active accessibility issues reported right now. Help fellow commuters by reporting any hazards.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _openReportIssue,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.add_alert_rounded, size: 18, color: AppColors.primary),
              label: const Text(
                'Submit a Condition Report',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Equal 2-Segmented Tab Bar matching LMT Go
class _ModernFilterTabs extends StatelessWidget {
  const _ModernFilterTabs({
    required this.selected,
    required this.onChanged,
  });

  final _CommunityTab selected;
  final ValueChanged<_CommunityTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 720),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              icon: Icons.bolt_rounded,
              label: 'Live Updates',
              isSelected: selected == _CommunityTab.liveUpdates,
              onTap: () => onChanged(_CommunityTab.liveUpdates),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TabButton(
              icon: Icons.person_rounded,
              label: 'My Reports',
              isSelected: selected == _CommunityTab.myReports,
              onTap: () => onChanged(_CommunityTab.myReports),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Community contribution rewards banner shown under 'My Reports'
class _MyContributionsBanner extends StatelessWidget {
  const _MyContributionsBanner({
    required this.reportCount,
    required this.onNewReport,
  });

  final int reportCount;
  final VoidCallback onNewReport;

  @override
  Widget build(BuildContext context) {
    final earnedPoints = reportCount * 10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emoji_events_rounded, color: AppColors.onPrimary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Community Contributor',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$reportCount reports submitted • $earnedPoints Contribution Points',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
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

/// Modern Accessible Report Card matching LMT Go
class _ModernReportCard extends StatelessWidget {
  const _ModernReportCard({
    required this.report,
    required this.targetTitle,
    required this.isActive,
    required this.onTap,
  });

  final Report report;
  final String targetTitle;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isResolved = report.status.toLowerCase() == 'resolved';
    final isExpired = !isActive && !isResolved;

    final _ReportBadge badgeType;
    if (isResolved) {
      badgeType = _ReportBadge.resolved;
    } else if (isExpired) {
      badgeType = _ReportBadge.expired;
    } else if (report.confirmCount > 0) {
      badgeType = _ReportBadge.verified;
    } else {
      badgeType = _ReportBadge.active;
    }

    final isBus = report.targetType.toLowerCase() == 'bus';
    final timeAgo = TimeUtils.formatRelativeTime(report.createdAt);

    return Opacity(
      opacity: isActive ? 1.0 : 0.65,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? AppColors.outlineVariant.withValues(alpha: 0.6)
                  : AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Target Mode, Name & Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isBus ? Icons.directions_bus_rounded : Icons.store_mall_directory_rounded,
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
                          targetTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeAgo,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildBadgeWidget(badgeType),
                ],
              ),

              const SizedBox(height: 12),

              // Problem Condition Title
              Text(
                report.problemType,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: AppColors.onSurface,
                ),
              ),

              if (report.description.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '“${report.description.trim()}”',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Bottom Details Row: Photo indicator, Trust verification, Chevron
              Row(
                children: [
                  if (report.photoUrl.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_camera_rounded, size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Photo',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          report.confirmCount > 0
                              ? Icons.verified_rounded
                              : Icons.schedule_rounded,
                          size: 15,
                          color: report.confirmCount > 0 ? AppColors.success : AppColors.outline,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            report.confirmCount > 0
                                ? 'Confirmed by ${report.confirmCount} rider${report.confirmCount == 1 ? "" : "s"}'
                                : 'Awaiting confirmation',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: report.confirmCount > 0
                                  ? AppColors.success
                                  : AppColors.outline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeWidget(_ReportBadge badge) {
    final (bg, fg, icon, label) = switch (badge) {
      _ReportBadge.active => (
          AppColors.errorContainer,
          AppColors.onErrorContainer,
          Icons.error_outline_rounded,
          'Active',
        ),
      _ReportBadge.verified => (
          AppColors.success.withValues(alpha: 0.15),
          AppColors.success,
          Icons.verified_rounded,
          'Verified',
        ),
      _ReportBadge.resolved => (
          AppColors.primaryContainer.withValues(alpha: 0.3),
          AppColors.primary,
          Icons.check_circle_rounded,
          'Resolved',
        ),
      _ReportBadge.expired => (
          AppColors.surfaceContainer,
          AppColors.outline,
          Icons.history_rounded,
          'Past',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
