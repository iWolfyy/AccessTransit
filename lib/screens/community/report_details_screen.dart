import 'package:flutter/material.dart';

import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../journey/journey_search_screen.dart';

/// Community report details — status, vehicle, conditions, map, actions.
class ReportDetailsScreen extends StatelessWidget {
  const ReportDetailsScreen({
    super.key,
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

  static const double _desktopBreakpoint = 768;
  static const Color _tertiaryContainer = Color(0xFF7D3500);

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onNavTap(BuildContext context, String label) {
    if (label == 'Home') {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    if (label == 'Community') {
      Navigator.of(context).maybePop();
      return;
    }
    if (label == 'Plan') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const JourneySearchScreen()),
      );
      return;
    }
    if (label == 'Profile') {
      AppNavigation.openProfile(context);
      return;
    }
    _showSnack(context, '$label will be available soon.');
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _TopBar(
            onBack: () => Navigator.of(context).maybePop(),
            onProfile: isDesktop
                ? () => _onNavTap(context, 'Profile')
                : null,
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
                          title: title,
                          reportedAgo: reportedAgo,
                          vehicleLabel: vehicleLabel,
                          routeLabel: routeLabel,
                          crowdLevel: crowdLevel,
                          accessibilityLabel: accessibilityLabel,
                          quote: quote,
                          communityVerified: communityVerified,
                          tertiaryContainer: _tertiaryContainer,
                        ),
                        const SizedBox(height: 24),
                        _MapSection(
                          imageUrl: mapImageUrl,
                          locationLabel: mapLocationLabel,
                        ),
                        const SizedBox(height: 24),
                        _ActionButtons(
                          onShare: () =>
                              _showSnack(context, 'Share Alert coming soon.'),
                          onAddUpdate: () =>
                              _showSnack(context, 'Add Update coming soon.'),
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
          : _DetailsBottomNav(
              onNavTap: (label) => _onNavTap(context, label),
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
  final Color tertiaryContainer;

  @override
  Widget build(BuildContext context) {
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
            child: Container(height: 4, color: AppColors.error),
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
                            decoration: const BoxDecoration(
                              color: AppColors.errorContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.warning,
                              color: AppColors.onErrorContainer,
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
                    if (communityVerified) ...[
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: AppColors.surfaceVariant,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Text(
                    quote,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontStyle: FontStyle.italic,
                      color: AppColors.onSurfaceVariant,
                    ),
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
          'Vehicle Information',
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
            const Icon(Icons.directions_bus, color: AppColors.primary),
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
          'Current Conditions',
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
                icon: Icons.groups,
                iconColor: AppColors.error,
                label: 'Crowd Level',
                value: crowdLevel,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricBadge(
                icon: Icons.accessible,
                iconColor: tertiaryContainer,
                label: 'Accessibility',
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
