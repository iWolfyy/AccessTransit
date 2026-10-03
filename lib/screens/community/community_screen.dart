import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
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

  Future<void> _handleCardConfirm(Report report) async {
    final userId = currentUserId ?? 'guest_user';
    if (report.confirmedBy.contains(userId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already confirmed this report as True.')),
      );
      return;
    }
    try {
      await _firestoreService.confirmReport(report.id, userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('True flag recorded! Thank you.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
  }

  Future<void> _handleCardFlag(Report report) async {
    final userId = currentUserId ?? 'guest_user';
    if (report.flaggedBy.contains(userId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already flagged this report as False.')),
      );
      return;
    }
    try {
      final newCount = report.falseCount + 1;
      await _firestoreService.flagReport(report.id, userId);
      if (!mounted) return;
      if (newCount >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report deleted and hidden due to 3 false flags.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('False flag recorded ($newCount/3 flags). Report deletes at 3.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
  }

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;

    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community Hub',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.textColor,
              ),
            ),
            Text(
              'Real-time accessibility alerts from fellow riders',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: context.subtextColor,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            constraints: context.appBarActionConstraints,
            onPressed: _openReportIssue,
            tooltip: 'Report Issue',
            icon: Icon(
              Icons.add_circle_outline_rounded,
              size: context.tapIconSize,
              color: isHC ? Colors.black : AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton.extended(
          onPressed: _openReportIssue,
          backgroundColor: isHC ? const Color(0xFF001F3F) : AppColors.primary,
          foregroundColor: isHC ? Colors.white : AppColors.onPrimary,
          elevation: isHC ? 0 : 4,
          extendedPadding: EdgeInsets.symmetric(
            horizontal: context.hasLargeTargets ? 22 : 16,
            vertical: context.hasLargeTargets ? 16 : 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isHC ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
          ),
          icon: Icon(Icons.add_alert_rounded, size: context.tapIconSize),
          label: Text(
            'Report Issue',
            style: TextStyle(
              fontSize: context.hasLargeTargets ? 15.5 : 14,
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
                    return Center(
                      child: CircularProgressIndicator(
                        color: isHC ? Colors.black : AppColors.primary,
                      ),
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
                                _buildEmptyState(context)
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
                                      onConfirm: () => _handleCardConfirm(activeReports[i]),
                                      onFlag: () => _handleCardFlag(activeReports[i]),
                                    ),
                                  ],
                                ],

                                // Inactive / Resolved section header
                                if (inactiveReports.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: isHC ? Colors.black : AppColors.outlineVariant,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          'Resolved & Past Reports',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: context.subtextColor,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: isHC ? Colors.black : AppColors.outlineVariant,
                                        ),
                                      ),
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
                                      onConfirm: () => _handleCardConfirm(inactiveReports[i]),
                                      onFlag: () => _handleCardFlag(inactiveReports[i]),
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

  Widget _buildEmptyState(BuildContext context) {
    final isMyReports = _tab == _CommunityTab.myReports;
    final isHC = context.isHighContrast;

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
                color: isHC
                    ? Colors.white
                    : AppColors.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: isHC ? Border.all(color: Colors.black, width: 2) : null,
              ),
              child: Icon(
                isMyReports ? Icons.assignment_turned_in_outlined : Icons.check_circle_outline_rounded,
                size: 40,
                color: isHC ? Colors.black : AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isMyReports ? 'No Reports Yet' : 'All Clear on the Corridors',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isMyReports
                  ? 'Reports you submit about wheelchair access, crowding, or lifts will show up here.'
                  : 'No active accessibility issues reported right now. Help fellow commuters by reporting any hazards.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.subtextColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _openReportIssue,
              style: OutlinedButton.styleFrom(
                backgroundColor: isHC ? Colors.white : null,
                foregroundColor: isHC ? Colors.black : AppColors.primary,
                side: BorderSide(
                  color: isHC ? Colors.black : AppColors.primary,
                  width: isHC ? 2 : 1,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: Icon(
                Icons.add_alert_rounded,
                size: 18,
                color: isHC ? Colors.black : AppColors.primary,
              ),
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
    final isHC = context.isHighContrast;

    return Container(
      constraints: const BoxConstraints(maxWidth: 720),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isHC
            ? Border.all(color: Colors.black, width: 2)
            : Border.all(color: AppColors.outlineVariant),
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
    final isHC = context.isHighContrast;

    final Color bgColor;
    final Color contentColor;
    Border? border;

    if (isSelected) {
      bgColor = isHC ? const Color(0xFF001F3F) : AppColors.primary;
      contentColor = isHC ? Colors.white : AppColors.onPrimary;
      if (isHC) {
        border = Border.all(color: Colors.black, width: 2);
      }
    } else {
      bgColor = Colors.transparent;
      contentColor = isHC ? Colors.black : AppColors.onSurfaceVariant;
    }

    final hasLargeTargets = context.hasLargeTargets;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: BoxConstraints(minHeight: context.chipHeight),
        padding: EdgeInsets.symmetric(
          vertical: hasLargeTargets ? 14 : 10,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: border,
          boxShadow: (isSelected && !isHC)
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
              size: hasLargeTargets ? 24 : (context.tapIconSize - 2),
              color: contentColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: hasLargeTargets ? 16 : 14,
                fontWeight: FontWeight.w700,
                color: contentColor,
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
    final isHC = context.isHighContrast;
    final earnedPoints = reportCount * 10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHC
            ? Colors.white
            : AppColors.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: isHC
            ? Border.all(color: Colors.black, width: 2)
            : Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isHC ? const Color(0xFF001F3F) : AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              border: isHC ? Border.all(color: Colors.black, width: 1.5) : null,
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Contributor',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$reportCount reports submitted • $earnedPoints Contribution Points',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.subtextColor,
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
    required this.onConfirm,
    required this.onFlag,
  });

  final Report report;
  final String targetTitle;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onConfirm;
  final VoidCallback onFlag;

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;
    final hasLargeTargets = context.hasLargeTargets;
    final isResolved = report.status.toLowerCase() == 'resolved';
    final isExpired = !isActive && !isResolved;

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final hasConfirmed = report.confirmedBy.contains(userId);
    final hasFlagged = report.flaggedBy.contains(userId);

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
      opacity: isActive ? 1.0 : (isHC ? 0.85 : 0.65),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(hasLargeTargets ? 20 : 16),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: isHC
                ? Border.all(color: Colors.black, width: 2)
                : Border.all(
                    color: isActive
                        ? AppColors.outlineVariant.withValues(alpha: 0.6)
                        : AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
            boxShadow: isHC
                ? null
                : [
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
                    padding: EdgeInsets.all(hasLargeTargets ? 11 : 8),
                    decoration: BoxDecoration(
                      color: isHC
                          ? Colors.white
                          : AppColors.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: isHC ? Border.all(color: Colors.black, width: 1.5) : null,
                    ),
                    child: Icon(
                      isBus ? Icons.directions_bus_rounded : Icons.store_mall_directory_rounded,
                      size: hasLargeTargets ? 26 : 20,
                      color: isHC ? Colors.black : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          targetTitle,
                          style: TextStyle(
                            fontSize: hasLargeTargets ? 17.5 : 15,
                            fontWeight: FontWeight.w700,
                            color: context.textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: hasLargeTargets ? 13.5 : 12,
                            color: context.subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildBadgeWidget(badgeType, context),
                ],
              ),

              const SizedBox(height: 12),

              // Problem Condition Title
              Text(
                report.problemType,
                style: TextStyle(
                  fontSize: hasLargeTargets ? 18.5 : 16,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: context.textColor,
                ),
              ),

              if (report.description.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '“${report.description.trim()}”',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: hasLargeTargets ? 14.5 : 13,
                    fontStyle: FontStyle.italic,
                    color: isHC ? Colors.black : AppColors.onSurfaceVariant,
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Flag Counter Chips (True count & False count out of 3)
              Row(
                children: [
                  // True Flag count pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isHC
                          ? (hasConfirmed ? const Color(0xFF003833) : Colors.white)
                          : (hasConfirmed
                              ? AppColors.success.withValues(alpha: 0.2)
                              : AppColors.success.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isHC ? Colors.black : AppColors.success,
                        width: isHC ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.thumb_up_alt_rounded,
                          size: 13,
                          color: isHC
                              ? (hasConfirmed ? Colors.white : const Color(0xFF003833))
                              : AppColors.success,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'True: ${report.confirmCount}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isHC
                                ? (hasConfirmed ? Colors.white : const Color(0xFF003833))
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // False Flag count pill (hides at 3)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isHC
                          ? (hasFlagged ? const Color(0xFF8B0000) : Colors.white)
                          : (report.falseCount > 0
                              ? AppColors.error.withValues(alpha: 0.15)
                              : AppColors.surfaceContainer),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isHC
                            ? const Color(0xFF8B0000)
                            : (report.falseCount > 0 ? AppColors.error : AppColors.outline),
                        width: isHC ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.flag_rounded,
                          size: 13,
                          color: isHC
                              ? (hasFlagged ? Colors.white : const Color(0xFF8B0000))
                              : (report.falseCount > 0 ? AppColors.error : AppColors.outline),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'False: ${report.falseCount}/3',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isHC
                                ? (hasFlagged ? Colors.white : const Color(0xFF8B0000))
                                : (report.falseCount > 0 ? AppColors.error : AppColors.outline),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  if (report.photoUrl.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isHC
                            ? Colors.white
                            : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: isHC ? Border.all(color: Colors.black, width: 1.5) : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo_camera_rounded,
                            size: 14,
                            color: isHC ? Colors.black : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Photo',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isHC ? Colors.black : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),
              Divider(
                color: isHC ? Colors.black : AppColors.outlineVariant.withValues(alpha: 0.5),
                height: 1,
              ),
              const SizedBox(height: 10),

              // Interactive True & False Quick Action Buttons
              Row(
                children: [
                  // True Flag Button
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: OutlinedButton.icon(
                        onPressed: onConfirm,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: hasConfirmed
                              ? (isHC ? const Color(0xFF003833) : AppColors.success.withValues(alpha: 0.15))
                              : (isHC ? Colors.white : null),
                          foregroundColor: isHC
                              ? (hasConfirmed ? Colors.white : const Color(0xFF003833))
                              : AppColors.success,
                          side: BorderSide(
                            color: isHC ? const Color(0xFF003833) : AppColors.success,
                            width: isHC ? 1.5 : 1,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(
                          hasConfirmed ? Icons.check_circle_rounded : Icons.thumb_up_outlined,
                          size: 15,
                        ),
                        label: Text(
                          hasConfirmed ? 'True (${report.confirmCount})' : 'True Flag (${report.confirmCount})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // False Flag Button
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: OutlinedButton.icon(
                        onPressed: isResolved ? null : onFlag,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: hasFlagged
                              ? (isHC ? const Color(0xFF8B0000) : AppColors.error.withValues(alpha: 0.15))
                              : (isHC ? Colors.white : null),
                          foregroundColor: isHC
                              ? (hasFlagged ? Colors.white : const Color(0xFF8B0000))
                              : AppColors.error,
                          side: BorderSide(
                            color: isHC ? const Color(0xFF8B0000) : AppColors.error,
                            width: isHC ? 1.5 : 1,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(
                          hasFlagged ? Icons.flag_rounded : Icons.flag_outlined,
                          size: 15,
                        ),
                        label: Text(
                          hasFlagged ? 'False (${report.falseCount}/3)' : 'False Flag (${report.falseCount}/3)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeWidget(_ReportBadge badge, BuildContext context) {
    final isHC = context.isHighContrast;

    if (isHC) {
      final (borderClr, fgClr, icon, label) = switch (badge) {
        _ReportBadge.active => (
            const Color(0xFF8B0000),
            const Color(0xFF8B0000),
            Icons.error_outline_rounded,
            'Active',
          ),
        _ReportBadge.verified => (
            const Color(0xFF003833),
            const Color(0xFF003833),
            Icons.verified_rounded,
            'Verified',
          ),
        _ReportBadge.resolved => (
            const Color(0xFF001F3F),
            const Color(0xFF001F3F),
            Icons.check_circle_rounded,
            'Resolved',
          ),
        _ReportBadge.expired => (
            Colors.black,
            Colors.black,
            Icons.history_rounded,
            'Past',
          ),
      };

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderClr, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fgClr),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fgClr,
              ),
            ),
          ],
        ),
      );
    }

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
