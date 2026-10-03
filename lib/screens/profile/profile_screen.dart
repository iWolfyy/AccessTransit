import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/enums/user_role.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/logout_confirmation_dialog.dart';
import '../auth/login_screen.dart';
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

  Future<void> _logout() async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final isHighContrast = context.isHighContrast;

    final confirmed = await showLogoutConfirmationDialog(context);
    if (confirmed != true) return;

    await _authService.logout();
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    showLogoutSuccessSnackBar(
      messenger: messenger,
      isHighContrast: isHighContrast,
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$feature will be available in a future update.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context),
      bottomNavigationBar: null,
    );
  }

  Widget _buildBody(BuildContext context) {
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
      child: CustomScrollView(
        slivers: [
          // ── Gradient Profile Header ──
          SliverToBoxAdapter(
            child: _GradientProfileHeader(
              initials: _initials,
              name: _displayName,
              email: user.email,
              roleLabel: _roleLabel,
              onMenu: widget.onMenu,
              onEdit: () => _showComingSoon(context, 'Edit Profile'),
            ),
          ),

          // ── Body Content ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Personal Information Card ──
                  _PersonalInfoCard(
                    name: _displayName,
                    email: user.email,
                    phone: user.phone,
                  ),
                  const SizedBox(height: 20),

                  // ── Stats Row ──
                  const _StatsSection(),
                  const SizedBox(height: 20),

                  // ── Rewards & Contributions Card (merged Impact + Badges) ──
                  _RewardsCard(
                    onSeeAll: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RewardsContributionsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── Settings Section (LMT Go style) ──
                  _SectionTitle(title: 'SETTINGS'),
                  const SizedBox(height: 8),
                  _GroupedCardList(
                    items: [
                      _GroupedCardItem(
                        icon: Icons.accessibility_new_rounded,
                        title: 'Accessibility Preferences',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AccessibilityPreferencesScreen(
                                initialUser: _user,
                              ),
                            ),
                          );
                        },
                      ),
                      _GroupedCardItem(
                        icon: Icons.notifications_rounded,
                        title: 'Push Notifications',
                        trailing: _NotificationToggle(),
                        onTap: () =>
                            _showComingSoon(context, 'Push Notifications'),
                      ),
                      _GroupedCardItem(
                        icon: Icons.lock_rounded,
                        title: 'Change Password',
                        onTap: () =>
                            _showComingSoon(context, 'Change Password'),
                      ),
                      _GroupedCardItem(
                        icon: Icons.bookmark_rounded,
                        title: 'Saved Places',
                        onTap: () => _showComingSoon(context, 'Saved Places'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Support Section (LMT Go style) ──
                  _SectionTitle(title: 'SUPPORT'),
                  const SizedBox(height: 8),
                  _GroupedCardList(
                    items: [
                      _GroupedCardItem(
                        icon: Icons.star_rounded,
                        title: 'Rate Us',
                        onTap: () => _showComingSoon(context, 'Rate Us'),
                      ),
                      _GroupedCardItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Help Center',
                        onTap: () => _showComingSoon(context, 'Help Center'),
                      ),
                      _GroupedCardItem(
                        icon: Icons.system_update_rounded,
                        title: 'Check for Updates',
                        onTap: () =>
                            _showComingSoon(context, 'Check for Updates'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Danger Zone ──
                  _DangerZoneSection(
                    onSignOut: _logout,
                    onDeleteAccount: () =>
                        _showComingSoon(context, 'Delete Account'),
                  ),
                  const SizedBox(height: 32),

                  // ── Version Footer ──
                  const _VersionFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRADIENT PROFILE HEADER (Phase 2.1 — LMT Go inspired)
// ═══════════════════════════════════════════════════════════════════════════

class _GradientProfileHeader extends StatelessWidget {
  const _GradientProfileHeader({
    required this.initials,
    required this.name,
    required this.email,
    required this.roleLabel,
    this.onMenu,
    this.onEdit,
  });

  final String initials;
  final String name;
  final String email;
  final String roleLabel;
  final VoidCallback? onMenu;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final hasLargeTargets = context.hasLargeTargets;
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return Container(
      decoration: BoxDecoration(
        gradient: isHighContrast
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primaryContainer,
                ],
              ),
        color: isHighContrast ? const Color(0xFF001F3F) : null,
        border: isHighContrast
            ? const Border(
                bottom: BorderSide(color: Colors.black, width: 2.0))
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top bar: Back/Menu + Edit ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                              color: Colors.white,
                              size: context.tapIconSize,
                            ),
                          )
                        : (onMenu != null
                            ? IconButton(
                                onPressed: onMenu,
                                icon: Icon(
                                  Icons.menu_rounded,
                                  color: Colors.white,
                                  size: context.tapIconSize,
                                ),
                              )
                            : const SizedBox.shrink()),
                  ),
                  const Spacer(),
                  if (onEdit != null)
                    Material(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: hasLargeTargets ? 16 : 12,
                            vertical: hasLargeTargets ? 10 : 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                color: Colors.white,
                                size: hasLargeTargets ? 18 : 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: hasLargeTargets ? 15 : 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Avatar + Name + Email + Role Badge ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                24, 8, 24, hasLargeTargets ? 28 : 24,
              ),
              child: Column(
                children: [
                  // Avatar with verified badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: hasLargeTargets ? 110 : 100,
                        height: hasLargeTargets ? 110 : 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isHighContrast
                              ? Colors.white
                              : AppColors.primaryContainer.withValues(alpha: 0.6),
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: isHighContrast
                              ? null
                              : const [
                                  BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: isHighContrast ? Colors.black : Colors.white,
                            fontSize: hasLargeTargets ? 36 : 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      // Verified badge
                      Positioned(
                        right: 0,
                        bottom: 2,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: isHighContrast
                                ? Colors.white
                                : AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isHighContrast
                                  ? Colors.black
                                  : Colors.white,
                              width: 2.5,
                            ),
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: isHighContrast ? Colors.black : Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Name
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: hasLargeTargets ? 26 : 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Email
                  if (email.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.email_outlined,
                          color: Colors.white.withValues(alpha: 0.70),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: hasLargeTargets ? 15 : 14,
                            color: Colors.white.withValues(alpha: 0.70),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),

                  // Role badge chip
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: hasLargeTargets ? 16 : 12,
                      vertical: hasLargeTargets ? 7 : 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.30),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      roleLabel,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: hasLargeTargets ? 14 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PERSONAL INFORMATION CARD (Phase 2.2 — LMT Go style)
// ═══════════════════════════════════════════════════════════════════════════

class _PersonalInfoCard extends StatelessWidget {
  const _PersonalInfoCard({
    required this.name,
    required this.email,
    this.phone,
  });

  final String name;
  final String email;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;

    final rows = <_InfoRowData>[
      _InfoRowData(
        icon: Icons.person_outlined,
        title: name,
        subtitle: 'Full name',
      ),
      if (phone != null && phone!.trim().isNotEmpty)
        _InfoRowData(
          icon: Icons.phone_outlined,
          title: phone!.trim(),
          subtitle: 'Phone number',
        ),
      _InfoRowData(
        icon: Icons.email_outlined,
        title: email,
        subtitle: 'Email address',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'PERSONAL INFORMATION'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isHighContrast ? Colors.white : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: isHighContrast
                ? Border.all(color: Colors.black, width: 2.0)
                : null,
            boxShadow: isHighContrast
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 56,
                    color: isHighContrast
                        ? Colors.black
                        : AppColors.outlineVariant.withValues(alpha: 0.30),
                  ),
                _InfoRow(data: rows[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRowData {
  const _InfoRowData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.data});

  final _InfoRowData data;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final hasLargeTargets = context.hasLargeTargets;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: hasLargeTargets ? 16 : 14,
      ),
      child: Row(
        children: [
          Container(
            width: hasLargeTargets ? 42 : 36,
            height: hasLargeTargets ? 42 : 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isHighContrast
                  ? const Color(0xFFE5E5E5)
                  : AppColors.primaryContainer.withValues(alpha: 0.10),
              border: isHighContrast
                  ? Border.all(color: Colors.black, width: 1.5)
                  : null,
            ),
            child: Icon(
              data.icon,
              size: hasLargeTargets ? 20 : 18,
              color: isHighContrast
                  ? Colors.black
                  : AppColors.primaryContainer,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    fontSize: hasLargeTargets ? 17 : 15,
                    fontWeight:
                        isHighContrast ? FontWeight.w700 : FontWeight.w600,
                    color: isHighContrast
                        ? Colors.black
                        : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    fontSize: hasLargeTargets ? 13 : 12,
                    fontWeight:
                        isHighContrast ? FontWeight.w600 : FontWeight.w400,
                    color: isHighContrast
                        ? const Color(0xFF1A1A1A)
                        : AppColors.onSurfaceVariant,
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

// ═══════════════════════════════════════════════════════════════════════════
// STATS SECTION (Phase 2.3 — kept)
// ═══════════════════════════════════════════════════════════════════════════

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
        color: isHighContrast ? Colors.white : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: isHighContrast ? Border.all(color: Colors.black, width: 2.0) : null,
        boxShadow: isHighContrast
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
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

// ═══════════════════════════════════════════════════════════════════════════
// REWARDS & CONTRIBUTIONS CARD (Phase 2.4 — merged Impact + Badges)
// ═══════════════════════════════════════════════════════════════════════════

class _RewardsCard extends StatelessWidget {
  const _RewardsCard({this.onSeeAll});

  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final hasLargeTargets = context.hasLargeTargets;

    return Container(
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.white : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: isHighContrast
            ? Border.all(color: Colors.black, width: 2.0)
            : null,
        boxShadow: isHighContrast
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          // Impact section
          Material(
            color: isHighContrast
                ? const Color(0xFF001F3F)
                : AppColors.primaryContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: InkWell(
              onTap: onSeeAll,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(hasLargeTargets ? 22 : 18),
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  border: isHighContrast
                      ? Border.all(color: Colors.black, width: 2)
                      : null,
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    Positioned(
                      right: -24,
                      top: -24,
                      child: Icon(
                        Icons.emoji_events_rounded,
                        size: 100,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.emoji_events_rounded,
                              size: hasLargeTargets ? 24 : 20,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Community Impact Score',
                                style: TextStyle(
                                  fontSize: hasLargeTargets ? 18 : 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 32),
                          child: Text(
                            'Level 3 • 42 reports',
                            style: TextStyle(
                              fontSize: hasLargeTargets ? 14 : 13,
                              color: Colors.white.withValues(alpha: 0.80),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'See All →',
                            style: TextStyle(
                              fontSize: hasLargeTargets ? 14 : 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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

          // Badges row
          Padding(
            padding: EdgeInsets.all(hasLargeTargets ? 18 : 14),
            child: Row(
              children: [
                ...[
                  Icons.rocket_launch_rounded,
                  Icons.accessible_forward_rounded,
                  Icons.elevator_rounded,
                ].map(
                  (icon) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      width: hasLargeTargets ? 42 : 36,
                      height: hasLargeTargets ? 42 : 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isHighContrast
                            ? const Color(0xFFE5E5E5)
                            : AppColors.primaryContainer
                                .withValues(alpha: 0.10),
                        border: isHighContrast
                            ? Border.all(color: Colors.black, width: 1.5)
                            : Border.all(
                                color: AppColors.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                      ),
                      child: Icon(
                        icon,
                        size: hasLargeTargets ? 20 : 18,
                        color: isHighContrast
                            ? Colors.black
                            : AppColors.primaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '+ 9 more badges',
                  style: TextStyle(
                    fontSize: hasLargeTargets ? 14 : 12,
                    fontWeight:
                        isHighContrast ? FontWeight.w700 : FontWeight.w500,
                    color: isHighContrast
                        ? Colors.black
                        : AppColors.onSurfaceVariant,
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

// ═══════════════════════════════════════════════════════════════════════════
// SECTION TITLE (Shared component)
// ═══════════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w600,
        letterSpacing: 0.8,
        color: isHighContrast
            ? Colors.black
            : AppColors.onSurfaceVariant,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GROUPED CARD LIST (Phase 2.5 — LMT Go style sections)
// ═══════════════════════════════════════════════════════════════════════════

class _GroupedCardItem {
  const _GroupedCardItem({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
}

class _GroupedCardList extends StatelessWidget {
  const _GroupedCardList({required this.items});

  final List<_GroupedCardItem> items;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;

    return Container(
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.white : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: isHighContrast
            ? Border.all(color: Colors.black, width: 2.0)
            : null,
        boxShadow: isHighContrast
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 56,
                color: isHighContrast
                    ? Colors.black
                    : AppColors.outlineVariant.withValues(alpha: 0.25),
              ),
            _GroupedCardTile(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _GroupedCardTile extends StatelessWidget {
  const _GroupedCardTile({required this.item});

  final _GroupedCardItem item;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final hasLargeTargets = context.hasLargeTargets;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: context.minTapHeight),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: hasLargeTargets ? 16 : 14,
            ),
            child: Row(
              children: [
                Container(
                  width: hasLargeTargets ? 40 : 34,
                  height: hasLargeTargets ? 40 : 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isHighContrast
                        ? const Color(0xFFE5E5E5)
                        : AppColors.primaryContainer
                            .withValues(alpha: 0.08),
                    border: isHighContrast
                        ? Border.all(color: Colors.black, width: 1.5)
                        : null,
                  ),
                  child: Icon(
                    item.icon,
                    size: hasLargeTargets ? 20 : 18,
                    color: isHighContrast
                        ? Colors.black
                        : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: hasLargeTargets ? 17 : 15,
                      fontWeight: isHighContrast
                          ? FontWeight.w700
                          : (hasLargeTargets
                              ? FontWeight.w600
                              : FontWeight.w500),
                      color: isHighContrast
                          ? Colors.black
                          : AppColors.onSurface,
                    ),
                  ),
                ),
                item.trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      size: hasLargeTargets ? 24 : 20,
                      color: isHighContrast
                          ? Colors.black
                          : AppColors.onSurfaceVariant,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationToggle extends StatefulWidget {
  @override
  State<_NotificationToggle> createState() => _NotificationToggleState();
}

class _NotificationToggleState extends State<_NotificationToggle> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: _enabled,
      onChanged: (value) => setState(() => _enabled = value),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DANGER ZONE (Phase 2.6 — LMT Go style)
// ═══════════════════════════════════════════════════════════════════════════

class _DangerZoneSection extends StatelessWidget {
  const _DangerZoneSection({
    required this.onSignOut,
    required this.onDeleteAccount,
  });

  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final hasLargeTargets = context.hasLargeTargets;
    final dangerColor = isHighContrast ? const Color(0xFF8B0000) : AppColors.error;

    return Column(
      children: [
        // Sign Out
        Container(
          decoration: BoxDecoration(
            color: isHighContrast ? Colors.white : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: isHighContrast
                ? Border.all(color: Colors.black, width: 2.0)
                : null,
            boxShadow: isHighContrast
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onSignOut,
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: context.minTapHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: hasLargeTargets ? 16 : 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        size: hasLargeTargets ? 24 : 20,
                        color: dangerColor,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: hasLargeTargets ? 17 : 15,
                          fontWeight: FontWeight.w600,
                          color: dangerColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Delete Account
        Container(
          decoration: BoxDecoration(
            color: isHighContrast ? Colors.white : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: isHighContrast
                ? Border.all(color: Colors.black, width: 2.0)
                : null,
            boxShadow: isHighContrast
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onDeleteAccount,
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: context.minTapHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: hasLargeTargets ? 16 : 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: hasLargeTargets ? 24 : 20,
                        color: dangerColor,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delete Account',
                              style: TextStyle(
                                fontSize: hasLargeTargets ? 17 : 15,
                                fontWeight: FontWeight.w600,
                                color: dangerColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Permanently remove your account',
                              style: TextStyle(
                                fontSize: hasLargeTargets ? 13 : 12,
                                color: isHighContrast
                                    ? const Color(0xFF1A1A1A)
                                    : AppColors.onSurfaceVariant,
                                fontWeight: isHighContrast
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// VERSION FOOTER (Phase 2.7)
// ═══════════════════════════════════════════════════════════════════════════

class _VersionFooter extends StatelessWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;

    return Center(
      child: Column(
        children: [
          Text(
            'AccessTransit v1.0.0',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighContrast ? FontWeight.w700 : FontWeight.w500,
              color: isHighContrast
                  ? const Color(0xFF1A1A1A)
                  : AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Lanka MetroTransit',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.w400,
              color: isHighContrast
                  ? const Color(0xFF1A1A1A)
                  : AppColors.onSurfaceVariant.withValues(alpha: 0.70),
            ),
          ),
        ],
      ),
    );
  }
}
