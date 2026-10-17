import '../../widgets/accessible_tap_target.dart';
import '../../l10n/evidence_presentation.dart';
import '../../l10n/journey_presentation.dart';
import '../../l10n/localization_context.dart';
import '../../l10n/report_view_presentation.dart';
import '../../widgets/report_v2_votes.dart';
import '../../logic/report_mutation.dart';
import '../../widgets/evidence_refresh.dart';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/status_logic.dart';
import '../../models/bus.dart';
import '../../models/report.dart';
import '../../models/station.dart';
import '../../services/firestore_service.dart';
import '../../services/report_submission_service.dart';
import '../../widgets/report_outbox_list.dart';
import '../journey/report_condition_screen.dart';
import 'report_details_screen.dart';

enum _CommunityTab { liveUpdates, myReports }

enum _ReportBadge { active, verified, resolved, expired }

/// Community hub — live updates feed and my reports matching LMT Go design.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key, this.service, this.submissionService});
  final FirestoreService? service;
  final ReportSubmissionService? submissionService;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  _CommunityTab _tab = _CommunityTab.liveUpdates;
  late final FirestoreService _firestoreService =
      widget.service ?? FirestoreService();

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
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ReportConditionScreen()));
  }

  String _resolveTargetTitle(Report report) {
    if (report.targetName.trim().isNotEmpty) {
      return report.targetName;
    }
    if (report.targetType.toLowerCase() == 'station') {
      return _stationsMap[report.targetId]?.name ??
          context.l10n.communityStationTarget(report.targetId);
    } else {
      final bus = _busesMap[report.targetId];
      if (bus != null) {
        return context.l10n.communityRouteTarget(bus.routeNo);
      }
      return context.l10n.communityBusTarget(report.targetId);
    }
  }

  void _openReportDetails(Report report) {
    final targetTitle = _resolveTargetTitle(report);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportDetailsScreen(
          report: report,
          targetTitle: targetTitle,
          service: _firestoreService,
        ),
      ),
    );
  }

  final Set<String> _pendingActions = {};
  Future<void> _handleCardConfirm(Report report) => _performCard(report, true);
  Future<void> _handleCardFlag(Report report) => _performCard(report, false);
  Future<void> _performCard(Report report, bool confirm) async {
    if (_pendingActions.contains(report.id)) return;
    final actor = _firestoreService.currentReportActorId;
    if (actor == null || actor.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.reportSignInChange)));
      return;
    }
    setState(() => _pendingActions.add(report.id));
    try {
      final result =
          await (confirm
                  ? (report.confirmedBy.contains(actor)
                        ? _firestoreService.recheckReport(report.id, actor)
                        : _firestoreService.confirmReport(report.id, actor))
                  : _firestoreService.flagReport(report.id, actor))
              .timeout(const Duration(seconds: 15));
      if (mounted && _firestoreService.currentReportActorId == actor) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.reportViewText(result.message))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.reportChangeUnconfirmed)),
        );
      }
    } finally {
      if (mounted) setState(() => _pendingActions.remove(report.id));
    }
  }

  String? get currentUserId => _firestoreService.currentReportActorId;

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;

    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(14) > 20
            ? 180
            : 80,
        backgroundColor: context.surfaceColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.communityHubTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.textColor,
              ),
            ),
            Text(
              context.l10n.communitySubtitle,
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
            tooltip: context.l10n.communityReportAction,
            icon: Icon(
              Icons.add_circle_outline_rounded,
              size: context.tapIconSize,
              color: isHC ? Colors.black : AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _openReportIssue,
            icon: const Icon(Icons.add_alert_rounded),
            label: Text(
              context.l10n.communityReportAction,
              textAlign: TextAlign.center,
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
                stream: _tab == _CommunityTab.myReports && currentUserId == null
                    ? Stream.value([])
                    : _firestoreService.streamReports(
                        surfaceErrors: true,
                        userId: _tab == _CommunityTab.myReports
                            ? currentUserId
                            : null,
                      ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        if (_tab == _CommunityTab.myReports)
                          ReportOutboxList(
                            userId: currentUserId,
                            submissionService: widget.submissionService,
                          ),
                        Text(context.l10n.communityUnavailable),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => setState(() {}),
                          child: Text(context.l10n.communityRetry),
                        ),
                      ],
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: isHC ? Colors.black : AppColors.primary,
                      ),
                    );
                  }

                  final reports = (snapshot.data ?? <Report>[])
                      .where(
                        (r) =>
                            r.isPublic &&
                            !r.isDisputed &&
                            (_tab != _CommunityTab.myReports ||
                                (currentUserId != null &&
                                    r.userId == currentUserId)),
                      )
                      .toList();
                  return EvidenceRefresh(
                    reports: reports,
                    builder: (context, now) {
                      // Separate active vs expired/resolved
                      final activeReports = <Report>[];
                      final inactiveReports = <Report>[];

                      for (final r in reports) {
                        if (StatusLogic.isReportActive(r, currentTime: now)) {
                          activeReports.add(r);
                        } else {
                          inactiveReports.add(r);
                        }
                      }

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 720),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // If My Reports tab is active, show the points & contribution banner
                                  if (_tab == _CommunityTab.myReports) ...[
                                    ReportOutboxList(
                                      userId: currentUserId,
                                      submissionService:
                                          widget.submissionService,
                                    ),
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
                                      for (
                                        var i = 0;
                                        i < activeReports.length;
                                        i++
                                      ) ...[
                                        if (i > 0) const SizedBox(height: 12),
                                        _ModernReportCard(
                                          service: _firestoreService,
                                          currentTime: now,
                                          report: activeReports[i],
                                          userId: currentUserId ?? '',
                                          isSaving: _pendingActions.contains(
                                            activeReports[i].id,
                                          ),
                                          targetTitle: _resolveTargetTitle(
                                            activeReports[i],
                                          ),
                                          isActive: true,
                                          onTap: () => _openReportDetails(
                                            activeReports[i],
                                          ),
                                          onConfirm: () => _handleCardConfirm(
                                            activeReports[i],
                                          ),
                                          onFlag: () =>
                                              _handleCardFlag(activeReports[i]),
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
                                              color: isHC
                                                  ? Colors.black
                                                  : AppColors.outlineVariant,
                                            ),
                                          ),
                                          Flexible(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              child: Text(
                                                context
                                                    .l10n
                                                    .communityPastReports,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: context.subtextColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Divider(
                                              color: isHC
                                                  ? Colors.black
                                                  : AppColors.outlineVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      for (
                                        var i = 0;
                                        i < inactiveReports.length;
                                        i++
                                      ) ...[
                                        if (i > 0) const SizedBox(height: 12),
                                        _ModernReportCard(
                                          service: _firestoreService,
                                          currentTime: now,
                                          report: inactiveReports[i],
                                          userId: currentUserId ?? '',
                                          isSaving: _pendingActions.contains(
                                            inactiveReports[i].id,
                                          ),
                                          targetTitle: _resolveTargetTitle(
                                            inactiveReports[i],
                                          ),
                                          isActive: false,
                                          onTap: () => _openReportDetails(
                                            inactiveReports[i],
                                          ),
                                          onConfirm: () => _handleCardConfirm(
                                            inactiveReports[i],
                                          ),
                                          onFlag: () => _handleCardFlag(
                                            inactiveReports[i],
                                          ),
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
                isMyReports
                    ? Icons.assignment_turned_in_outlined
                    : Icons.check_circle_outline_rounded,
                size: 40,
                color: isHC ? Colors.black : AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isMyReports
                  ? context.l10n.communityNoOwnReports
                  : context.l10n.communityEmptyTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isMyReports
                  ? (currentUserId == null
                        ? context.l10n.communityOwnSignIn
                        : context.l10n.communityOwnEmptyHelp)
                  : context.l10n.communityEmptyHelp,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              icon: Icon(
                Icons.add_alert_rounded,
                size: 18,
                color: isHC ? Colors.black : AppColors.primary,
              ),
              label: Text(
                context.l10n.communitySubmitReport,
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
  const _ModernFilterTabs({required this.selected, required this.onChanged});

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
              label: context.l10n.communityUpdatesTab,
              isSelected: selected == _CommunityTab.liveUpdates,
              onTap: () => onChanged(_CommunityTab.liveUpdates),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TabButton(
              icon: Icons.person_rounded,
              label: context.l10n.communityMyReportsTab,
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

    return AccessibleTapTarget(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: BoxConstraints(minHeight: context.chipHeight),
          padding: EdgeInsets.symmetric(vertical: hasLargeTargets ? 14 : 10),
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
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: hasLargeTargets ? 16 : 14,
                    fontWeight: FontWeight.w700,
                    color: contentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Community contribution rewards banner shown under context.l10n.communityMyReportsTab
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
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.communityContributor,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.communityContributionCount(reportCount),
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
    required this.service,
    required this.report,
    required this.currentTime,
    required this.targetTitle,
    required this.isActive,
    required this.onTap,
    required this.onConfirm,
    required this.onFlag,
    required this.userId,
    this.isSaving = false,
  });

  final Report report;
  final FirestoreService service;
  final DateTime currentTime;
  final String targetTitle;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onConfirm;
  final VoidCallback onFlag;
  final String userId;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;
    final hasLargeTargets = context.hasLargeTargets;
    final isResolved = report.status.toLowerCase() == 'resolved';
    final isExpired = !isActive && !isResolved;

    final hasConfirmed = report.confirmedBy.contains(userId);
    final hasFlagged = report.flaggedBy.contains(userId);

    final _ReportBadge badgeType;
    if (isResolved) {
      badgeType = _ReportBadge.resolved;
    } else if (isExpired) {
      badgeType = _ReportBadge.expired;
    } else if (report.confirmCount > 0 &&
        StatusLogic.isReportFresh(report, currentTime: currentTime)) {
      badgeType = _ReportBadge.verified;
    } else {
      badgeType = _ReportBadge.active;
    }

    final isBus = report.targetType.toLowerCase() == 'bus';
    final timeAgo = context.evidenceAge(report.createdAt, currentTime);

    return Opacity(
      opacity: isActive ? 1.0 : (isHC ? 0.85 : 0.65),
      child: AccessibleTapTarget(
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
                _CommunityHeader(
                  children: [
                    Container(
                      padding: EdgeInsets.all(hasLargeTargets ? 11 : 8),
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
                        isBus
                            ? Icons.directions_bus_rounded
                            : Icons.store_mall_directory_rounded,
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
                  context.l10n.communityChecked(
                    context.journeyText(
                      StatusLogic.freshnessLabel(
                        report,
                        currentTime: currentTime,
                      ),
                    ),
                    context.evidenceAge(
                      StatusLogic.lastCheckedAt(
                        report,
                        currentTime: currentTime,
                      ),
                      currentTime,
                    ),
                  ),
                  style: TextStyle(color: context.subtextColor),
                ),
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

                // Community vote counts use the report policy threshold.
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // True Flag count pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isHC
                            ? (hasConfirmed
                                  ? const Color(0xFF003833)
                                  : Colors.white)
                            : (hasConfirmed
                                  ? AppColors.success.withValues(alpha: 0.2)
                                  : AppColors.success.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isHC ? Colors.black : AppColors.success,
                          width: isHC ? 1.5 : 1,
                        ),
                      ),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(
                            Icons.thumb_up_alt_rounded,
                            size: 13,
                            color: isHC
                                ? (hasConfirmed
                                      ? Colors.white
                                      : const Color(0xFF003833))
                                : AppColors.success,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            context.l10n.communityTrueCount(
                              report.confirmCount,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isHC
                                  ? (hasConfirmed
                                        ? Colors.white
                                        : const Color(0xFF003833))
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // False Flag count pill (hides at 3)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isHC
                            ? (hasFlagged
                                  ? const Color(0xFF8B0000)
                                  : Colors.white)
                            : (report.falseCount > 0
                                  ? AppColors.error.withValues(alpha: 0.15)
                                  : AppColors.surfaceContainer),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isHC
                              ? const Color(0xFF8B0000)
                              : (report.falseCount > 0
                                    ? AppColors.error
                                    : AppColors.outline),
                          width: isHC ? 1.5 : 1,
                        ),
                      ),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(
                            Icons.flag_rounded,
                            size: 13,
                            color: isHC
                                ? (hasFlagged
                                      ? Colors.white
                                      : const Color(0xFF8B0000))
                                : (report.falseCount > 0
                                      ? AppColors.error
                                      : AppColors.outline),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            context.l10n.communityFalseCount(
                              report.falseCount,
                              report.flagThreshold,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isHC
                                  ? (hasFlagged
                                        ? Colors.white
                                        : const Color(0xFF8B0000))
                                  : (report.falseCount > 0
                                        ? AppColors.error
                                        : AppColors.outline),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (report.photoUrl.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isHC
                              ? Colors.white
                              : AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: isHC
                              ? Border.all(color: Colors.black, width: 1.5)
                              : null,
                        ),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_camera_rounded,
                              size: 14,
                              color: isHC ? Colors.black : AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.l10n.communityPhoto,
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
                  color: isHC
                      ? Colors.black
                      : AppColors.outlineVariant.withValues(alpha: 0.5),
                  height: 1,
                ),
                const SizedBox(height: 10),

                if (hasConfirmed && !report.isV2)
                  Text(context.l10n.communityRecheckHelp),
                // Interactive True & False Quick Action Buttons
                if (report.isV2)
                  ReportV2Votes(report: report, service: service)
                else
                  Row(
                    children: [
                      // True Flag Button
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: OutlinedButton.icon(
                            onPressed:
                                isSaving ||
                                    (hasConfirmed &&
                                        !ReportRecheck.canRecheck(
                                          report,
                                          userId,
                                          currentTime,
                                        )) ||
                                    isResolved ||
                                    userId.isEmpty ||
                                    report.userId == userId
                                ? null
                                : onConfirm,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: hasConfirmed
                                  ? (isHC
                                        ? const Color(0xFF003833)
                                        : AppColors.success.withValues(
                                            alpha: 0.15,
                                          ))
                                  : (isHC ? Colors.white : null),
                              foregroundColor: isHC
                                  ? (hasConfirmed
                                        ? Colors.white
                                        : const Color(0xFF003833))
                                  : AppColors.success,
                              side: BorderSide(
                                color: isHC
                                    ? const Color(0xFF003833)
                                    : AppColors.success,
                                width: isHC ? 1.5 : 1,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: Icon(
                              hasConfirmed
                                  ? Icons.check_circle_rounded
                                  : Icons.thumb_up_outlined,
                              size: 15,
                            ),
                            label: Text(
                              hasConfirmed
                                  ? context.l10n.reportRecheckAction
                                  : context.l10n.reportTrueCount(
                                      report.confirmCount,
                                    ),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // False Flag Button
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: OutlinedButton.icon(
                            onPressed:
                                isSaving ||
                                    hasFlagged ||
                                    isResolved ||
                                    userId.isEmpty ||
                                    report.userId == userId
                                ? null
                                : onFlag,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: hasFlagged
                                  ? (isHC
                                        ? const Color(0xFF8B0000)
                                        : AppColors.error.withValues(
                                            alpha: 0.15,
                                          ))
                                  : (isHC ? Colors.white : null),
                              foregroundColor: isHC
                                  ? (hasFlagged
                                        ? Colors.white
                                        : const Color(0xFF8B0000))
                                  : AppColors.error,
                              side: BorderSide(
                                color: isHC
                                    ? const Color(0xFF8B0000)
                                    : AppColors.error,
                                width: isHC ? 1.5 : 1,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: Icon(
                              hasFlagged
                                  ? Icons.flag_rounded
                                  : Icons.flag_outlined,
                              size: 15,
                            ),
                            label: Text(
                              hasFlagged
                                  ? context.l10n.reportFalseRecorded(
                                      report.falseCount,
                                      report.flagThreshold,
                                    )
                                  : context.l10n.reportFalseCount(
                                      report.falseCount,
                                      report.flagThreshold,
                                    ),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
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
          context.l10n.communityActiveBadge,
        ),
        _ReportBadge.verified => (
          const Color(0xFF003833),
          const Color(0xFF003833),
          Icons.verified_rounded,
          context.l10n.communityConfirmedBadge,
        ),
        _ReportBadge.resolved => (
          const Color(0xFF001F3F),
          const Color(0xFF001F3F),
          Icons.check_circle_rounded,
          context.l10n.communityResolvedBadge,
        ),
        _ReportBadge.expired => (
          Colors.black,
          Colors.black,
          Icons.history_rounded,
          context.l10n.communityPastBadge,
        ),
      };

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderClr, width: 2),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
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
        context.l10n.communityActiveBadge,
      ),
      _ReportBadge.verified => (
        AppColors.success.withValues(alpha: 0.15),
        AppColors.success,
        Icons.verified_rounded,
        context.l10n.communityConfirmedBadge,
      ),
      _ReportBadge.resolved => (
        AppColors.primaryContainer.withValues(alpha: 0.3),
        AppColors.primary,
        Icons.check_circle_rounded,
        context.l10n.communityResolvedBadge,
      ),
      _ReportBadge.expired => (
        AppColors.surfaceContainer,
        AppColors.outline,
        Icons.history_rounded,
        context.l10n.communityPastBadge,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
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

class _CommunityHeader extends StatelessWidget {
  const _CommunityHeader({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(14) > 20) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final child in children)
            if (child is Expanded) child.child else child,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
