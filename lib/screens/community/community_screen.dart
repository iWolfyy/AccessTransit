import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/routing/app_navigation.dart';
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

/// Community hub — live updates feed and my reports.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  static const double _desktopBreakpoint = 768;
  static const Color _minorBg = Color(0xFFFFF8E1);
  static const Color _minorFg = Color(0xFFF57F17);

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

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openReportIssue() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ReportConditionScreen(),
      ),
    );
  }

  String _resolveTargetTitle(Report report) {
    if (report.targetType.toLowerCase() == 'station') {
      return _stationsMap[report.targetId]?.name ??
          'Station ${report.targetId}';
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

  void _onNavTap(String label) {
    AppNavigation.handleBottomNav(
      context,
      label,
      currentTab: 'Community',
      onUnsupported: _showSnack,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton.extended(
          onPressed: _openReportIssue,
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimaryContainer,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(Icons.add_alert),
          label: const Text(
            'Report Issue',
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _TopBar(
            onMenu: () => _showSnack('Menu will be available soon.'),
            onSearch: () => _showSnack('Search will be available soon.'),
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
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 768),
                        child: Column(
                          children: [
                            _FilterTabs(
                              selected: _tab,
                              onChanged: (tab) => setState(() => _tab = tab),
                            ),
                            const SizedBox(height: 24),
                            if (reports.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 48,
                                ),
                                child: Text(
                                  _tab == _CommunityTab.myReports
                                      ? 'You have not submitted any reports yet.'
                                      : 'No active reports right now.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              )
                            else ...[
                              // Active reports section
                              if (activeReports.isNotEmpty) ...[
                                for (var i = 0; i < activeReports.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 16),
                                  _ReportCardWidget(
                                    report: activeReports[i],
                                    targetTitle: _resolveTargetTitle(
                                      activeReports[i],
                                    ),
                                    isActive: true,
                                    minorBg: _minorBg,
                                    minorFg: _minorFg,
                                    onTap: () => _openReportDetails(
                                      activeReports[i],
                                    ),
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
                                          color: AppColors.outline,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: AppColors.outlineVariant)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                for (var i = 0; i < inactiveReports.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 16),
                                  _ReportCardWidget(
                                    report: inactiveReports[i],
                                    targetTitle: _resolveTargetTitle(
                                      inactiveReports[i],
                                    ),
                                    isActive: false,
                                    minorBg: _minorBg,
                                    minorFg: _minorFg,
                                    onTap: () => _openReportDetails(
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
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : _CommunityBottomNav(onNavTap: _onNavTap),
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

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.selected,
    required this.onChanged,
  });

  final _CommunityTab selected;
  final ValueChanged<_CommunityTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 448),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Live Updates',
              selected: selected == _CommunityTab.liveUpdates,
              onTap: () => onChanged(_CommunityTab.liveUpdates),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'My Reports',
              selected: selected == _CommunityTab.myReports,
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
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceContainerLowest : Colors.transparent,
      elevation: selected ? 1 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
              color: selected
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportCardWidget extends StatelessWidget {
  const _ReportCardWidget({
    required this.report,
    required this.targetTitle,
    required this.isActive,
    required this.minorBg,
    required this.minorFg,
    required this.onTap,
  });

  final Report report;
  final String targetTitle;
  final bool isActive;
  final Color minorBg;
  final Color minorFg;
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

    final trustLine = report.confirmCount > 0
        ? 'Confirmed by ${report.confirmCount} ${report.confirmCount == 1 ? 'rider' : 'riders'}, ${TimeUtils.formatRelativeTime(report.lastConfirmedAt ?? report.createdAt)}'
        : 'Reported ${TimeUtils.formatRelativeTime(report.createdAt)}';

    return Opacity(
      opacity: isActive ? 1.0 : 0.65,
      child: Material(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.problemType,
                            style: const TextStyle(
                              fontSize: 18,
                              height: 24 / 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            targetTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _BadgeChipWidget(
                      badge: badgeType,
                      minorBg: minorBg,
                      minorFg: minorFg,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        report.targetType.toLowerCase() == 'bus'
                            ? Icons.directions_bus
                            : Icons.accessible,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        trustLine,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.outline,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.onSurfaceVariant,
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
}

class _BadgeChipWidget extends StatelessWidget {
  const _BadgeChipWidget({
    required this.badge,
    required this.minorBg,
    required this.minorFg,
  });

  final _ReportBadge badge;
  final Color minorBg;
  final Color minorFg;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, label) = switch (badge) {
      _ReportBadge.active => (
          AppColors.errorContainer,
          AppColors.onErrorContainer,
          Icons.warning,
          'Active',
        ),
      _ReportBadge.verified => (
          AppColors.secondary,
          AppColors.onSecondary,
          Icons.check_circle,
          'Verified',
        ),
      _ReportBadge.resolved => (
          AppColors.success.withValues(alpha: 0.2),
          AppColors.success,
          Icons.check_circle_outline,
          'Resolved',
        ),
      _ReportBadge.expired => (
          AppColors.surfaceContainer,
          AppColors.outline,
          Icons.history,
          'Expired',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// App-standard nav: Home → Plan → Live → Community → Profile.
class _CommunityBottomNav extends StatelessWidget {
  const _CommunityBottomNav({required this.onNavTap});

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
