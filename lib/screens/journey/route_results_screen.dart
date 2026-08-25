import 'package:flutter/material.dart';

import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import 'route_details_screen.dart';

/// Sample route result used for Sprint 2 UI (before Firebase connect).
class RouteResultItem {
  const RouteResultItem({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.etaLabel,
    required this.transfers,
    required this.crowdLevel,
    required this.accessibilityStatus,
    required this.accessibilityLabel,
    required this.safetyLabel,
    required this.summary,
    this.recommended = false,
  });

  final String id;
  final String title;
  final int durationMinutes;
  final String etaLabel;
  final int transfers;
  final String crowdLevel;
  final AccessibilityStatus accessibilityStatus;
  final String accessibilityLabel;
  final String safetyLabel;
  final String summary;
  final bool recommended;
}

enum AccessibilityStatus { accessible, partial, notAccessible }

/// Route Results screen — list of routes with ETA, crowd, accessibility, safety.
class RouteResultsScreen extends StatefulWidget {
  const RouteResultsScreen({
    super.key,
    this.origin = 'Current Location',
    this.destination = 'Destination',
  });

  final String origin;
  final String destination;

  @override
  State<RouteResultsScreen> createState() => _RouteResultsScreenState();
}

class _RouteResultsScreenState extends State<RouteResultsScreen> {
  static const double _desktopBreakpoint = 768;

  String _sortBy = 'Best';

  static const _sampleRoutes = [
    RouteResultItem(
      id: '1',
      title: 'Bus 138 → Bus 177',
      durationMinutes: 42,
      etaLabel: 'Leave in 6 min',
      transfers: 1,
      crowdLevel: 'Low',
      accessibilityStatus: AccessibilityStatus.accessible,
      accessibilityLabel: 'Accessible',
      safetyLabel: 'Well lit stops',
      summary: 'Step-free boarding · Ramp available',
      recommended: true,
    ),
    RouteResultItem(
      id: '2',
      title: 'Bus 100 Direct',
      durationMinutes: 55,
      etaLabel: 'Leave in 12 min',
      transfers: 0,
      crowdLevel: 'Medium',
      accessibilityStatus: AccessibilityStatus.partial,
      accessibilityLabel: 'Partially Accessible',
      safetyLabel: 'Busy waiting area',
      summary: '1 stop with steps · Assistance available',
    ),
    RouteResultItem(
      id: '3',
      title: 'Bus 120 → Walk',
      durationMinutes: 38,
      etaLabel: 'Leave in 3 min',
      transfers: 0,
      crowdLevel: 'High',
      accessibilityStatus: AccessibilityStatus.notAccessible,
      accessibilityLabel: 'Not Accessible',
      safetyLabel: 'Crowded evening route',
      summary: 'Faster but limited accessibility',
    ),
  ];

  List<RouteResultItem> get _sortedRoutes {
    final routes = List<RouteResultItem>.from(_sampleRoutes);
    switch (_sortBy) {
      case 'Fastest':
        routes.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
      case 'Least crowded':
        routes.sort(
          (a, b) =>
              _crowdRank(a.crowdLevel).compareTo(_crowdRank(b.crowdLevel)),
        );
      case 'Best':
      default:
        routes.sort((a, b) {
          if (a.recommended == b.recommended) {
            return a.durationMinutes.compareTo(b.durationMinutes);
          }
          return a.recommended ? -1 : 1;
        });
    }
    return routes;
  }

  int _crowdRank(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return 0;
      case 'medium':
        return 1;
      default:
        return 2;
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$feature will be available soon.')),
      );
  }

  void _onSelectRoute(RouteResultItem route) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteDetailsScreen(
          origin: widget.origin,
          destination: widget.destination,
          route: route,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;
    final routes = _sortedRoutes;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _TopBar(
            onBack: () => Navigator.of(context).maybePop(),
            onFilter: () => _showComingSoon('Filters'),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                isDesktop ? 24 : 112,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 768),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TripSummaryCard(
                          origin: widget.origin,
                          destination: widget.destination,
                          resultCount: routes.length,
                        ),
                        const SizedBox(height: 16),
                        _SortChips(
                          selected: _sortBy,
                          onSelected: (value) =>
                              setState(() => _sortBy = value),
                        ),
                        const SizedBox(height: 16),
                        ...routes.map(
                          (route) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RouteCard(
                              route: route,
                              onTap: () => _onSelectRoute(route),
                            ),
                          ),
                        ),
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
          : _ResultsBottomNav(
              onNavTap: (label) {
                AppNavigation.handleBottomNav(
                  context,
                  label,
                  currentTab: 'Plan',
                  onUnsupported: _showComingSoon,
                );
              },
            ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.onFilter});

  final VoidCallback onBack;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLow,
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
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.primary,
                  tooltip: 'Back',
                ),
                const Expanded(
                  child: Text(
                    'Route Results',
                    style: TextStyle(
                      fontSize: 22,
                      height: 28 / 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onFilter,
                  icon: const Icon(Icons.tune_rounded),
                  color: AppColors.primary,
                  tooltip: 'Filters',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TripSummaryCard extends StatelessWidget {
  const _TripSummaryCard({
    required this.origin,
    required this.destination,
    required this.resultCount,
  });

  final String origin;
  final String destination;
  final int resultCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.my_location,
                size: 18,
                color: AppColors.primaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  origin,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: SizedBox(
              height: 12,
              child: VerticalDivider(
                width: 18,
                thickness: 1,
                color: AppColors.outlineVariant,
              ),
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 18,
                color: AppColors.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  destination,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 24 / 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$resultCount routes found · Depart now',
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SortChips extends StatelessWidget {
  const _SortChips({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  static const _options = ['Best', 'Fastest', 'Least crowded'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in _options) ...[
            FilterChip(
              label: Text(option),
              selected: selected == option,
              onSelected: (_) => onSelected(option),
              selectedColor: AppColors.primaryFixed,
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected == option
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
              side: BorderSide(
                color: selected == option
                    ? AppColors.primaryContainer
                    : AppColors.outlineVariant,
              ),
              backgroundColor: AppColors.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.onTap,
  });

  final RouteResultItem route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: route.recommended
                  ? AppColors.secondary
                  : AppColors.surfaceVariant,
              width: route.recommended ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (route.recommended) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Recommended',
                              style: TextStyle(
                                fontSize: 12,
                                height: 16 / 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSecondaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          route.title,
                          style: const TextStyle(
                            fontSize: 18,
                            height: 24 / 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          route.summary,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${route.durationMinutes} min',
                        style: const TextStyle(
                          fontSize: 22,
                          height: 28 / 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        route.etaLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.transfer_within_a_station,
                    label: route.transfers == 0
                        ? 'Direct'
                        : '${route.transfers} transfer',
                  ),
                  _InfoChip(
                    icon: Icons.groups_outlined,
                    label: 'Crowd: ${route.crowdLevel}',
                  ),
                  _AccessibilityChip(
                    status: route.accessibilityStatus,
                    label: route.accessibilityLabel,
                  ),
                  _InfoChip(
                    icon: Icons.shield_outlined,
                    label: route.safetyLabel,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryContainer,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View details',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
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
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessibilityChip extends StatelessWidget {
  const _AccessibilityChip({
    required this.status,
    required this.label,
  });

  final AccessibilityStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = switch (status) {
      AccessibilityStatus.accessible => (
          Icons.check_circle,
          AppColors.secondaryContainer,
          AppColors.onSecondaryContainer,
        ),
      AccessibilityStatus.partial => (
          Icons.warning_amber_rounded,
          const Color(0xFFFFDBCA),
          AppColors.tertiary,
        ),
      AccessibilityStatus.notAccessible => (
          Icons.cancel,
          AppColors.errorContainer,
          AppColors.onErrorContainer,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsBottomNav extends StatelessWidget {
  const _ResultsBottomNav({required this.onNavTap});

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
                icon: Icons.directions_bus,
                label: 'Plan',
                selected: true,
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
