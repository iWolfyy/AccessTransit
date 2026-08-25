import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/enums/user_role.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../community/community_screen.dart';
import '../journey/journey_search_screen.dart';
import '../preferences/accessibility_preferences_screen.dart';
import 'rewards_contributions_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.initialUser,
    this.onMenu,
    this.onHomeTap,
    this.onNavTap,
  });

  final UserModel? initialUser;
  final VoidCallback? onMenu;
  final VoidCallback? onHomeTap;
  final void Function(String feature)? onNavTap;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _user = widget.initialUser;
    _isLoading = widget.initialUser == null;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (_user == null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() => _error = null);
    }

    try {
      final user = await _authService.getCurrentUserProfile();
      if (!mounted) return;

      setState(() {
        _user = user ?? _user;
        _isLoading = false;
        if (_user == null) {
          _error = 'No profile found. Please sign in again.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_user == null) {
          _error = 'Unable to load profile from the database.';
        }
      });
    }
  }

  String get _displayName {
    final name = _user?.name.trim() ?? '';
    return name.isEmpty ? 'Passenger' : name;
  }

  String get _roleLabel {
    switch (_user?.role) {
      case UserRole.contributor:
        return 'Community Contributor';
      case UserRole.passenger:
      case null:
        return 'Inclusive Commuter';
    }
  }

  String get _initials {
    final parts = _displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'AT';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _TopBar(
            initials: _initials,
            onMenu: widget.onMenu ?? () => Navigator.of(context).maybePop(),
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
      // Keep existing bottom nav unchanged.
      bottomNavigationBar: _ProfileBottomNav(
        onHomeTap: widget.onHomeTap ?? () => Navigator.of(context).pop(),
        onNavTap: (feature) {
          if (widget.onNavTap != null) {
            widget.onNavTap!(feature);
            return;
          }
          if (feature == 'Plan') {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const JourneySearchScreen()),
            );
            return;
          }
          if (feature == 'Community') {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CommunityScreen()),
            );
            return;
          }
          _showComingSoon(context, feature);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off_outlined, size: 48, color: AppColors.outline),
              const SizedBox(height: 12),
              Text(
                _error ?? 'Profile unavailable.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final user = _user!;

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _ProfileHeader(
            initials: _initials,
            name: _displayName,
            subtitle: _roleLabel,
            email: user.email,
            phone: user.phone,
          ),
          const SizedBox(height: 24),
          const _StatsSection(),
          const SizedBox(height: 24),
          _ImpactCard(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RewardsContributionsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _BadgesSection(
            onSeeAll: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RewardsContributionsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const _RecentActivitySection(),
          const SizedBox(height: 24),
          _AccountSection(
            onItemTap: (label) {
              if (label == 'Accessibility Preferences') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AccessibilityPreferencesScreen(
                      initialUser: _user,
                    ),
                  ),
                );
                return;
              }
              if (label == 'Rewards & Contributions') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RewardsContributionsScreen(),
                  ),
                );
                return;
              }
              if (widget.onNavTap != null) {
                widget.onNavTap!(label);
              } else {
                _showComingSoon(context, label);
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$feature will be available in a future update.')),
      );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.initials, required this.onMenu});

  final String initials;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 1,
      shadowColor: Colors.black26,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    onPressed: onMenu,
                    icon: const Icon(Icons.menu, color: AppColors.onSurfaceVariant),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Access Transit',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      height: 28 / 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimaryContainer,
                      child: Text(
                        initials,
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
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.initials,
    required this.name,
    required this.subtitle,
    required this.email,
    this.phone,
  });

  final String initials;
  final String name;
  final String subtitle;
  final String email;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer,
                border: Border.all(color: AppColors.surface, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.onPrimaryContainer,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              right: -8,
              bottom: -8,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.stars, color: AppColors.onSecondary, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 22,
            height: 28 / 22,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            height: 20 / 14,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        if (email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        if (phone != null && phone!.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            phone!.trim(),
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.campaign,
            iconColor: AppColors.primary,
            value: '42',
            label: 'Reports',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.verified,
            iconColor: AppColors.secondary,
            value: '128',
            label: 'Verifications',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.workspace_premium,
            iconColor: AppColors.tertiary,
            value: '12',
            label: 'Badges',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              height: 24 / 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              Positioned(
                right: -32,
                top: -32,
                child: Icon(
                  Icons.diversity_3,
                  size: 120,
                  color: AppColors.onPrimaryContainer.withValues(alpha: 0.20),
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite, color: AppColors.onPrimaryContainer),
                      SizedBox(width: 8),
                      Text(
                        'Your Impact',
                        style: TextStyle(
                          fontSize: 18,
                          height: 24 / 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 16,
                        height: 24 / 16,
                        color: AppColors.onPrimaryContainer,
                      ),
                      children: [
                        TextSpan(text: 'Your reports have helped '),
                        TextSpan(
                          text: '1,200+',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ' commuters this month.'),
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

class _BadgesSection extends StatelessWidget {
  const _BadgesSection({this.onSeeAll});

  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    const badges = [
      _BadgeData(
        icon: Icons.rocket_launch,
        label: 'Early Adopter',
        accent: Color(0xFFFFD700),
      ),
      _BadgeData(
        icon: Icons.accessible_forward,
        label: 'Ramp Specialist',
        accent: Color(0xFFC0C0C0),
      ),
      _BadgeData(
        icon: Icons.elevator,
        label: 'Elevator Scout',
        accent: Color(0xFFCD7F32),
      ),
      _BadgeData(
        icon: Icons.security,
        label: 'Safety Sentinel',
        accent: Color(0xFFC0C0C0),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Badges & Achievements',
                style: TextStyle(
                  fontSize: 18,
                  height: 24 / 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                child: const Text('See all'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final badge = badges[index];
              return Container(
                width: 128,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.30),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: badge.accent, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(badge.icon, color: badge.accent),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badge.label,
                      textAlign: TextAlign.center,
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
            },
          ),
        ),
      ],
    );
  }
}

class _BadgeData {
  const _BadgeData({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            height: 24 / 18,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        SizedBox(height: 16),
        _ActivityItem(
          icon: Icons.check_circle,
          iconBackground: AppColors.secondaryContainer,
          iconColor: AppColors.onSecondaryContainer,
          title: 'Verified Ramp on Bus 42',
          time: '2 hours ago',
        ),
        SizedBox(height: 8),
        _ActivityItem(
          icon: Icons.warning,
          iconBackground: AppColors.errorContainer,
          iconColor: AppColors.onErrorContainer,
          title: 'Reported Elevator Out at Central',
          time: 'Yesterday',
        ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.time,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.20),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: iconBackground,
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
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

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.onItemTap});

  final void Function(String label) onItemTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.stars, 'Rewards & Contributions'),
      (Icons.settings_accessibility, 'Accessibility Preferences'),
      (Icons.history, 'Route History'),
      (Icons.bookmark, 'Saved Places'),
      (Icons.help_outline, 'Help & Support'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account',
          style: TextStyle(
            fontSize: 18,
            height: 24 / 18,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.20),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: AppColors.outlineVariant.withValues(alpha: 0.20),
                  ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onItemTap(items[i].$2),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 64),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Icon(items[i].$1, color: AppColors.onSurfaceVariant),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                items[i].$2,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 24 / 16,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileBottomNav extends StatelessWidget {
  const _ProfileBottomNav({
    required this.onHomeTap,
    required this.onNavTap,
  });

  final VoidCallback onHomeTap;
  final void Function(String feature) onNavTap;

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
                onTap: onHomeTap,
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
                onTap: () => onNavTap('Community'),
              ),
              const _NavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                selected: true,
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
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

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
