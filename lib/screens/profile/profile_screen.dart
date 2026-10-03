import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/enums/user_role.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
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
      case UserRole.operator:
        return 'Transit Bus Operator';
      case UserRole.admin:
        return 'System Administrator';
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
      backgroundColor: context.surfaceColor,
      body: Column(
        children: [
          _TopBar(
            initials: _initials,
            onMenu: widget.onMenu,
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
      bottomNavigationBar: null,
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
                  minimumSize: Size(0, context.buttonHeight),
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
  const _TopBar({required this.initials, this.onMenu});

  final String initials;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return Material(
      color: context.surfaceColor,
      elevation: isHighContrast ? 0 : 1,
      shadowColor: Colors.black26,
      child: Container(
        decoration: BoxDecoration(
          border: isHighContrast
              ? const Border(bottom: BorderSide(color: Colors.black, width: 2.0))
              : null,
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: context.minTapHeight,
                    height: context.minTapHeight,
                    child: canPop
                        ? IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: isHighContrast ? Colors.black : AppColors.onSurfaceVariant,
                              size: context.tapIconSize,
                            ),
                          )
                        : (onMenu != null
                            ? IconButton(
                                onPressed: onMenu,
                                icon: Icon(
                                  Icons.menu_rounded,
                                  color: isHighContrast ? Colors.black : AppColors.onSurfaceVariant,
                                  size: context.tapIconSize,
                                ),
                              )
                            : null),
                  ),
                  Expanded(
                    child: Text(
                      'Access Transit',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        height: 28 / 22,
                        fontWeight: FontWeight.w700,
                        color: isHighContrast ? Colors.black : AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: context.minTapHeight,
                    height: context.minTapHeight,
                    child: Center(
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: isHighContrast ? const Color(0xFF001F3F) : AppColors.primaryContainer,
                        foregroundColor: isHighContrast ? Colors.white : AppColors.onPrimaryContainer,
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
    final isHighContrast = context.isHighContrast;

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
                color: isHighContrast ? const Color(0xFF001F3F) : AppColors.primaryContainer,
                border: Border.all(
                  color: isHighContrast ? Colors.black : AppColors.surface,
                  width: isHighContrast ? 3 : 4,
                ),
                boxShadow: isHighContrast
                    ? null
                    : const [
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
                  color: Colors.white,
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
                  color: isHighContrast ? Colors.white : AppColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isHighContrast ? Colors.black : AppColors.surface,
                    width: 2,
                  ),
                  boxShadow: isHighContrast
                      ? null
                      : const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                ),
                child: Icon(
                  Icons.stars,
                  color: isHighContrast ? Colors.black : AppColors.onSecondary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            fontSize: 22,
            height: 28 / 22,
            fontWeight: FontWeight.w700,
            color: isHighContrast ? Colors.black : AppColors.onSurface,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
            color: isHighContrast ? const Color(0xFF1A1A1A) : AppColors.onSurfaceVariant,
          ),
        ),
        if (email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
              color: isHighContrast ? const Color(0xFF1A1A1A) : AppColors.onSurfaceVariant,
            ),
          ),
        ],
        if (phone != null && phone!.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            phone!.trim(),
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
              color: isHighContrast ? const Color(0xFF1A1A1A) : AppColors.onSurfaceVariant,
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
    final isHighContrast = context.isHighContrast;
    final hasLargeTargets = context.hasLargeTargets;

    return Container(
      padding: EdgeInsets.all(hasLargeTargets ? 20 : 16),
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.white : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: isHighContrast ? Border.all(color: Colors.black, width: 2.0) : null,
        boxShadow: isHighContrast
            ? null
            : const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: hasLargeTargets ? 28 : 24,
            color: isHighContrast ? Colors.black : iconColor,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: hasLargeTargets ? 22 : 18,
              height: 24 / 18,
              fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w600,
              color: isHighContrast ? Colors.black : AppColors.onSurface,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: hasLargeTargets ? 13.5 : 12,
              height: 16 / 12,
              fontWeight: isHighContrast ? FontWeight.w700 : FontWeight.w500,
              color: isHighContrast ? const Color(0xFF1A1A1A) : AppColors.onSurfaceVariant,
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
    final isHighContrast = context.isHighContrast;
    final hasLargeTargets = context.hasLargeTargets;

    return Material(
      color: isHighContrast ? const Color(0xFF001F3F) : AppColors.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(hasLargeTargets ? 28 : 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighContrast ? Colors.black : Colors.transparent,
              width: isHighContrast ? 2 : 0,
            ),
            boxShadow: isHighContrast
                ? const []
                : const [
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
                  color: isHighContrast
                      ? Colors.white.withValues(alpha: 0.15)
                      : AppColors.onPrimaryContainer.withValues(alpha: 0.20),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        size: hasLargeTargets ? 26 : 22,
                        color: isHighContrast ? Colors.white : AppColors.onPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your Impact',
                        style: TextStyle(
                          fontSize: hasLargeTargets ? 21 : 18,
                          height: 24 / 18,
                          fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w600,
                          color: isHighContrast ? Colors.white : AppColors.onPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: hasLargeTargets ? 17.5 : 16,
                        height: 24 / 16,
                        color: isHighContrast ? Colors.white : AppColors.onPrimary,
                      ),
                      children: [
                        const TextSpan(text: 'Your reports have helped '),
                        TextSpan(
                          text: '1,200+',
                          style: TextStyle(
                            fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w700,
                          ),
                        ),
                        const TextSpan(text: ' commuters this month.'),
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
    final isHighContrast = context.isHighContrast;
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
            Expanded(
              child: Text(
                'Badges & Achievements',
                style: TextStyle(
                  fontSize: 18,
                  height: 24 / 18,
                  fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w600,
                  color: context.textColor,
                ),
              ),
            ),
            if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  minimumSize: Size(0, context.minTapHeight),
                ),
                child: Text(
                  'See all',
                  style: TextStyle(
                    color: isHighContrast ? const Color(0xFF001F3F) : null,
                    fontWeight: isHighContrast ? FontWeight.w800 : null,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 142,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final badge = badges[index];
              return Container(
                width: 128,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isHighContrast
                        ? Colors.black
                        : AppColors.outlineVariant.withValues(alpha: 0.30),
                    width: isHighContrast ? 2 : 1,
                  ),
                  boxShadow: isHighContrast
                      ? const []
                      : const [
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
                        color: context.cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isHighContrast ? Colors.black : badge.accent,
                          width: 2,
                        ),
                        boxShadow: isHighContrast
                            ? const []
                            : const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                      ),
                      child: Icon(
                        badge.icon,
                        color: isHighContrast
                            ? (badge.accent == const Color(0xFFFFD700)
                                ? const Color(0xFF8B6508)
                                : (badge.accent == const Color(0xFFCD7F32)
                                    ? const Color(0xFF8B4513)
                                    : Colors.black))
                            : badge.accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badge.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: isHighContrast ? FontWeight.w700 : FontWeight.w500,
                        color: context.textColor,
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
    final isHighContrast = context.isHighContrast;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            height: 24 / 18,
            fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w600,
            color: context.textColor,
          ),
        ),
        const SizedBox(height: 16),
        _ActivityItem(
          icon: Icons.check_circle,
          iconBackground: isHighContrast
              ? const Color(0xFF003833)
              : AppColors.secondaryContainer,
          iconColor: isHighContrast ? Colors.white : AppColors.onSecondaryContainer,
          title: 'Verified Ramp on Bus 42',
          time: '2 hours ago',
        ),
        const SizedBox(height: 8),
        _ActivityItem(
          icon: Icons.warning,
          iconBackground: isHighContrast
              ? const Color(0xFF8B0000)
              : AppColors.errorContainer,
          iconColor: isHighContrast ? Colors.white : AppColors.onErrorContainer,
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
    final isHighContrast = context.isHighContrast;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighContrast
              ? Colors.black
              : AppColors.outlineVariant.withValues(alpha: 0.20),
          width: isHighContrast ? 2 : 1,
        ),
        boxShadow: isHighContrast
            ? const []
            : const [
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
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: isHighContrast ? FontWeight.w700 : FontWeight.w500,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.w500,
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

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.onItemTap});

  final void Function(String label) onItemTap;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
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
        Text(
          'Account',
          style: TextStyle(
            fontSize: 18,
            height: 24 / 18,
            fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w600,
            color: context.textColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighContrast
                  ? Colors.black
                  : AppColors.outlineVariant.withValues(alpha: 0.20),
              width: isHighContrast ? 2 : 1,
            ),
            boxShadow: isHighContrast
                ? const []
                : const [
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
                    color: isHighContrast
                        ? Colors.black
                        : AppColors.outlineVariant.withValues(alpha: 0.20),
                  ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onItemTap(items[i].$2),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: context.minTapHeight),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: context.hasLargeTargets ? 20 : 14,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              items[i].$1,
                              size: context.tapIconSize,
                              color: isHighContrast
                                  ? Colors.black
                                  : AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                items[i].$2,
                                style: TextStyle(
                                  fontSize: context.hasLargeTargets ? 18 : 16,
                                  height: 24 / 16,
                                  fontWeight: isHighContrast
                                      ? FontWeight.w700
                                      : (context.hasLargeTargets ? FontWeight.w600 : FontWeight.normal),
                                  color: context.textColor,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: context.tapIconSize,
                              color: isHighContrast
                                  ? Colors.black
                                  : AppColors.onSurfaceVariant,
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




