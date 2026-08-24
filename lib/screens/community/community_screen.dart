import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../journey/journey_search_screen.dart';
import '../journey/report_condition_screen.dart';
import '../profile/profile_screen.dart';

enum _CommunityTab { liveUpdates, myReports }

enum _ReportBadge { major, verified, minor }

class _FeedItem {
  const _FeedItem({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.icon,
    required this.badge,
    this.verifyCount,
    this.verifiedByUsers,
    this.dimmed = false,
  });

  final String title;
  final String subtitle;
  final String timeLabel;
  final IconData icon;
  final _ReportBadge badge;
  final int? verifyCount;
  final int? verifiedByUsers;
  final bool dimmed;
}

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

  static const _liveFeed = <_FeedItem>[
    _FeedItem(
      title: 'Elevator Out',
      subtitle: 'Central Station - North Exit',
      timeLabel: 'Reported 5 mins ago',
      icon: Icons.accessible,
      badge: _ReportBadge.major,
      verifyCount: 32,
    ),
    _FeedItem(
      title: 'Ramp Operational',
      subtitle: 'Bus 42',
      timeLabel: 'Reported 12 mins ago',
      icon: Icons.accessible_forward,
      badge: _ReportBadge.verified,
      verifiedByUsers: 15,
    ),
    _FeedItem(
      title: 'Heavy Crowding',
      subtitle: 'Main St Subway',
      timeLabel: 'Reported 20 mins ago',
      icon: Icons.groups,
      badge: _ReportBadge.minor,
      dimmed: true,
    ),
  ];

  static const _myReports = <_FeedItem>[
    _FeedItem(
      title: 'Ramp/Access',
      subtitle: 'Central Station - Main Entrance',
      timeLabel: 'Submitted just now',
      icon: Icons.accessible,
      badge: _ReportBadge.minor,
    ),
  ];

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

  void _onNavTap(String label) {
    if (label == 'Home') {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    if (label == 'Community') return;
    if (label == 'Plan') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const JourneySearchScreen()),
      );
      return;
    }
    if (label == 'Profile') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
      return;
    }
    _showSnack('$label will be available soon.');
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;
    final items =
        _tab == _CommunityTab.liveUpdates ? _liveFeed : _myReports;

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: isDesktop ? 8 : 8),
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
            child: ListView(
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
                        if (items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Text(
                              'No reports yet.',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          )
                        else
                          ...[
                            for (var i = 0; i < items.length; i++) ...[
                              if (i > 0) const SizedBox(height: 16),
                              _ReportCard(
                                item: items[i],
                                minorBg: _minorBg,
                                minorFg: _minorFg,
                                onTap: () => _showSnack(
                                  '${items[i].title} details coming soon.',
                                ),
                                onComment: () => _showSnack(
                                  'Comments will be available soon.',
                                ),
                              ),
                            ],
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

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.item,
    required this.minorBg,
    required this.minorFg,
    required this.onTap,
    required this.onComment,
  });

  final _FeedItem item;
  final Color minorBg;
  final Color minorFg;
  final VoidCallback onTap;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: item.dimmed ? 0.8 : 1,
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
                            item.title,
                            style: const TextStyle(
                              fontSize: 18,
                              height: 24 / 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _BadgeChip(
                      badge: item.badge,
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
                        item.icon,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item.timeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.surfaceVariant),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (item.verifyCount != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.verified,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${item.verifyCount}',
                            style: const TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      )
                    else if (item.verifiedByUsers != null)
                      Text(
                        'Verified by ${item.verifiedByUsers} users',
                        style: const TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant,
                        ),
                      )
                    else
                      const Spacer(),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: onComment,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.onSurfaceVariant,
                        minimumSize: const Size(48, 48),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 20),
                      label: const Text(
                        'Comment',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
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
      _ReportBadge.major => (
          AppColors.errorContainer,
          AppColors.onErrorContainer,
          Icons.warning,
          'Major',
        ),
      _ReportBadge.verified => (
          AppColors.secondary,
          AppColors.onSecondary,
          Icons.check_circle,
          'Verified',
        ),
      _ReportBadge.minor => (
          minorBg,
          minorFg,
          Icons.info,
          'Minor',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: badge == _ReportBadge.minor
            ? Border.all(color: minorFg.withValues(alpha: 0.2))
            : null,
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
