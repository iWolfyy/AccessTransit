import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/journey_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../models/enums/user_role.dart';
import '../../services/journey_service.dart';
import '../../widgets/logout_confirmation_dialog.dart';
import '../auth/login_screen.dart';
import '../journey/journey_search_screen.dart';
import '../main_shell.dart';
import '../operator/operator_dashboard_screen.dart';
import '../preferences/accessibility_preferences_screen.dart';
import '../profile/rewards_contributions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialUser});

  final UserModel? initialUser;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _desktopBreakpoint = 768;

  late final AuthService? _authService;
  late final JourneyService? _journeyService;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  UserModel? _user;
  JourneyModel? _activeJourney;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final hasFirebase = Firebase.apps.isNotEmpty;
    _authService = hasFirebase ? AuthService() : null;
    _journeyService = hasFirebase ? JourneyService() : null;
    _user = widget.initialUser;
    _isLoading = widget.initialUser == null;
    if (hasFirebase) {
      _loadUser();
    }
  }

  Future<void> _loadUser() async {
    if (_authService == null) return;
    try {
      final user = await _authService.getCurrentUserProfile();
      if (!mounted) return;
      setState(() {
        _user = user ?? _user;
        _isLoading = false;
      });
      _checkActiveJourney();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (_user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to load profile: $e')),
        );
      }
    }
  }

  /// Checks Firestore for an active/confirmed journey for the current user.
  Future<void> _checkActiveJourney() async {
    if (_authService == null || _journeyService == null) return;
    final uid = _authService.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    try {
      final journey = await _journeyService.getActiveJourney(uid);
      if (!mounted) return;
      setState(() => _activeJourney = journey);
    } catch (_) {
      // Non-fatal — journey recovery is best-effort.
    }
  }

  void _resumeJourney() {
    _openJourneySearch();
  }

  Future<void> _logout() async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final isHighContrast = context.isHighContrast;

    final confirmed = await showLogoutConfirmationDialog(context);
    if (confirmed != true) return;

    await _authService?.logout();
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    showLogoutSuccessSnackBar(
      messenger: messenger,
      isHighContrast: isHighContrast,
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$feature will be available in a future update.')),
      );
  }

  void _openProfile() {
    AppNavigation.openProfile(context, initialUser: _user);
  }

  void _openJourneySearch() {
    final shell = context.findAncestorStateOfType<MainShellState>();
    if (shell != null) {
      shell.switchToTab('Plan');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const JourneySearchScreen()),
    );
  }

  void _openAccessibilityPreferences() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AccessibilityPreferencesScreen(
          initialUser: _user,
        ),
      ),
    );
  }

  void _onNavTap(String label) {
    final shell = context.findAncestorStateOfType<MainShellState>();
    if (shell != null) {
      shell.switchToTab(label);
    } else {
      AppNavigation.handleBottomNav(context, label);
    }
  }

  String get _initials {
    final name = _user?.name.trim() ?? '';
    if (name.isEmpty) return 'AT';
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get _firstName {
    final name = _user?.name.trim() ?? '';
    if (name.isEmpty) return 'Passenger';
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    return parts.first;
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

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  IconData get _greetingIcon {
    final hour = DateTime.now().hour;
    if (hour < 6) return Icons.nights_stay_rounded;
    if (hour < 12) return Icons.wb_sunny_rounded;
    if (hour < 17) return Icons.wb_sunny_rounded;
    if (hour < 20) return Icons.wb_twilight_rounded;
    return Icons.nights_stay_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.surfaceColor,
      drawer: _HomeDrawer(
        user: _user,
        initials: _initials,
        roleLabel: _roleLabel,
        onLogout: _logout,
        onNavTap: _onNavTap,
        onAccessibilityTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AccessibilityPreferencesScreen(
                initialUser: _user,
              ),
            ),
          );
        },
        onRewardsTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const RewardsContributionsScreen(),
            ),
          );
        },
        onOperatorTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const OperatorDashboardScreen(),
            ),
          );
        },
        onFeatureTap: _showComingSoon,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (isDesktop)
                  _DesktopTopNav(
                    initials: _initials,
                    onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                    onNavTap: _onNavTap,
                    onProfileTap: _openProfile,
                  ),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      // ── Hero Gradient Header ──
                      SliverToBoxAdapter(
                        child: _HeroHeader(
                          greeting: _greeting,
                          greetingIcon: _greetingIcon,
                          firstName: _firstName,
                          initials: _initials,
                          isDesktop: isDesktop,
                          onSearchTap: _openJourneySearch,
                          onMenuTap: () =>
                              _scaffoldKey.currentState?.openDrawer(),
                          onProfileTap: _openProfile,
                        ),
                      ),
                      // ── Body Content ──
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          isDesktop ? 24 : 16,
                          20,
                          isDesktop ? 24 : 16,
                          isDesktop ? 24 : 24,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 1280),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // ── Quick Actions Row ──
                                  _QuickActionsRow(
                                    onTrackBus: _openJourneySearch,
                                    onPlanJourney: _openJourneySearch,
                                    onAccessPrefs:
                                        _openAccessibilityPreferences,
                                  ),
                                  // ── Active Journey Banner ──
                                  if (_activeJourney != null) ...[
                                    const SizedBox(height: 20),
                                    _ActiveJourneyBanner(
                                      journey: _activeJourney!,
                                      onResume: _resumeJourney,
                                    ),
                                  ],
                                  // ── Favorites Section ──
                                  const SizedBox(height: 24),
                                  _FavoritesSection(
                                    onTap: _showComingSoon,
                                  ),
                                  // ── Live Status & Alerts ──
                                  const SizedBox(height: 24),
                                  const _AlertsSection(),
                                  // ── Recent Journey ──
                                  const SizedBox(height: 24),
                                  _RecentJourneyCard(
                                    onReplan: _openJourneySearch,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: _AssistanceFab(
          showLabel: MediaQuery.sizeOf(context).width >= 640,
          onPressed: () => _showComingSoon('Assistance'),
        ),
      ),
      bottomNavigationBar: null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HERO GRADIENT HEADER (Phase 1.1 — LMT Go inspired)
// ═══════════════════════════════════════════════════════════════════════════

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.greeting,
    required this.greetingIcon,
    required this.firstName,
    required this.initials,
    required this.isDesktop,
    required this.onSearchTap,
    required this.onMenuTap,
    required this.onProfileTap,
  });

  final String greeting;
  final IconData greetingIcon;
  final String firstName;
  final String initials;
  final bool isDesktop;
  final VoidCallback onSearchTap;
  final VoidCallback onMenuTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final hasLargeTargets = context.hasLargeTargets;

    return Container(
      decoration: BoxDecoration(
        gradient: isHighContrast
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,        // #003466
                  AppColors.primaryContainer, // #1A4B84
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
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 24 : 20,
            8,
            isDesktop ? 24 : 20,
            hasLargeTargets ? 28 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: Menu + Title + Avatar ──
              if (!isDesktop)
                Row(
                  children: [
                    _HeaderIconButton(
                      icon: Icons.menu_rounded,
                      onPressed: onMenuTap,
                      semanticLabel: 'Open menu',
                    ),
                    const Spacer(),
                    Text(
                      'Access Transit',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                        shadows: isHighContrast
                            ? null
                            : const [
                                Shadow(
                                  color: Color(0x40000000),
                                  blurRadius: 4,
                                ),
                              ],
                      ),
                    ),
                    const Spacer(),
                    _HeaderAvatarButton(
                      initials: initials,
                      onPressed: onProfileTap,
                    ),
                  ],
                ),

              SizedBox(height: hasLargeTargets ? 20 : 16),

              // ── Greeting row ──
              Row(
                children: [
                  Icon(
                    greetingIcon,
                    color: const Color(0xFFFFD54F),
                    size: hasLargeTargets ? 28 : 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$greeting, $firstName',
                      style: TextStyle(
                        fontSize: hasLargeTargets ? 26 : 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Text(
                  'Ready to ride?',
                  style: TextStyle(
                    fontSize: hasLargeTargets ? 16 : 14,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(height: hasLargeTargets ? 20 : 16),

              // ── Prominent Search Card ──
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: isHighContrast ? 0 : 4,
                shadowColor: const Color(0x40000000),
                child: InkWell(
                  onTap: onSearchTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: hasLargeTargets ? 64 : 56,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: isHighContrast
                          ? Border.all(color: Colors.black, width: 2.0)
                          : null,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: hasLargeTargets ? 20 : 16,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: hasLargeTargets ? 44 : 40,
                          height: hasLargeTargets ? 44 : 40,
                          decoration: BoxDecoration(
                            color: isHighContrast
                                ? const Color(0xFFE5E5E5)
                                : AppColors.primaryContainer
                                    .withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            color: isHighContrast
                                ? Colors.black
                                : AppColors.primaryContainer,
                            size: hasLargeTargets ? 26 : 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Where are you going?',
                                style: TextStyle(
                                  fontSize: hasLargeTargets ? 18 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: isHighContrast
                                      ? Colors.black
                                      : AppColors.onSurface,
                                ),
                              ),
                              Text(
                                'Tap to plan your journey',
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
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: isHighContrast
                              ? Colors.black
                              : AppColors.primaryContainer,
                          size: hasLargeTargets ? 24 : 20,
                        ),
                      ],
                    ),
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: context.minTapHeight,
      height: context.minTapHeight,
      child: IconButton(
        onPressed: onPressed,
        tooltip: semanticLabel,
        icon: Icon(
          icon,
          color: Colors.white,
          size: context.tapIconSize,
        ),
      ),
    );
  }
}

class _HeaderAvatarButton extends StatelessWidget {
  const _HeaderAvatarButton({
    required this.initials,
    required this.onPressed,
  });

  final String initials;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final hasLargeTargets = context.hasLargeTargets;
    return SizedBox(
      width: context.minTapHeight,
      height: context.minTapHeight,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        tooltip: 'Open profile',
        icon: Container(
          width: hasLargeTargets ? 38 : 34,
          height: hasLargeTargets ? 38 : 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.20),
            border: Border.all(color: Colors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: hasLargeTargets ? 14 : 12,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// QUICK ACTIONS ROW (Phase 1.2 — LMT Go inspired)
// ═══════════════════════════════════════════════════════════════════════════

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onTrackBus,
    required this.onPlanJourney,
    required this.onAccessPrefs,
  });

  final VoidCallback onTrackBus;
  final VoidCallback onPlanJourney;
  final VoidCallback onAccessPrefs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.directions_bus_rounded,
            label: 'Track\nBus',
            onTap: onTrackBus,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.map_rounded,
            label: 'Plan\nJourney',
            onTap: onPlanJourney,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.accessibility_new_rounded,
            label: 'Access\nPrefs',
            onTap: onAccessPrefs,
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final hasLargeTargets = context.hasLargeTargets;
    final circleSize = hasLargeTargets ? 54.0 : 48.0;

    return Material(
      color: isHighContrast ? Colors.white : AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      elevation: isHighContrast ? 0 : 2,
      shadowColor: const Color(0x14000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: BoxConstraints(
            minHeight: hasLargeTargets ? 120 : 108,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isHighContrast
                ? Border.all(color: Colors.black, width: 2.0)
                : Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3)),
          ),
          padding: EdgeInsets.symmetric(
            vertical: hasLargeTargets ? 16 : 14,
            horizontal: 8,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: circleSize,
                height: circleSize,
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
                  icon,
                  size: hasLargeTargets ? 28 : 24,
                  color: isHighContrast
                      ? Colors.black
                      : AppColors.primaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: hasLargeTargets ? 14 : 12,
                  fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w600,
                  color: isHighContrast ? Colors.black : AppColors.onSurface,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FAVORITES SECTION (Phase 1.4 — horizontal scrollable pills)
// ═══════════════════════════════════════════════════════════════════════════

class _FavoritesSection extends StatelessWidget {
  const _FavoritesSection({required this.onTap});

  final void Function(String feature) onTap;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final hasLargeTargets = context.hasLargeTargets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Favorites',
          style: TextStyle(
            fontSize: 18,
            height: 24 / 18,
            fontWeight: FontWeight.w700,
            color: context.textColor,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: hasLargeTargets ? 88 : 76,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _FavoritePill(
                icon: Icons.home_rounded,
                label: 'Home',
                subtitle: '15 min',
                subtitleColor: AppColors.secondary,
                filled: true,
                onTap: () => onTap('Home favorite'),
              ),
              const SizedBox(width: 10),
              _FavoritePill(
                icon: Icons.work_outline_rounded,
                label: 'Work',
                subtitle: '32 min',
                subtitleColor: AppColors.secondary,
                onTap: () => onTap('Work favorite'),
              ),
              const SizedBox(width: 10),
              _FavoritePill(
                icon: Icons.local_hospital_outlined,
                label: 'Medical',
                subtitle: '-- min',
                subtitleColor: isHighContrast
                    ? const Color(0xFF1A1A1A)
                    : AppColors.onSurfaceVariant,
                onTap: () => onTap('Medical favorite'),
              ),
              const SizedBox(width: 10),
              _FavoritePill(
                icon: Icons.add_rounded,
                label: 'Add',
                isAdd: true,
                onTap: () => onTap('Add favorite'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FavoritePill extends StatelessWidget {
  const _FavoritePill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.subtitleColor,
    this.filled = false,
    this.isAdd = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? subtitleColor;
  final bool filled;
  final bool isAdd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final hasLargeTargets = context.hasLargeTargets;

    return Material(
      color: isHighContrast
          ? Colors.white
          : (isAdd
              ? AppColors.surfaceContainer
              : AppColors.surfaceContainerLowest),
      borderRadius: BorderRadius.circular(16),
      elevation: isHighContrast ? 0 : (isAdd ? 0 : 1),
      shadowColor: const Color(0x14000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: BoxConstraints(
            minWidth: hasLargeTargets ? 120 : 100,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isHighContrast
                ? Border.all(color: Colors.black, width: 2.0)
                : (isAdd
                    ? Border.all(
                        color: AppColors.outlineVariant,
                        style: BorderStyle.solid,
                      )
                    : Border.all(
                        color:
                            AppColors.outlineVariant.withValues(alpha: 0.3))),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: hasLargeTargets ? 18 : 14,
            vertical: hasLargeTargets ? 14 : 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: hasLargeTargets ? 44 : 40,
                height: hasLargeTargets ? 44 : 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isHighContrast
                      ? (isAdd ? Colors.transparent : const Color(0xFFE5E5E5))
                      : (isAdd
                          ? Colors.transparent
                          : (filled
                              ? AppColors.primaryContainer
                                  .withValues(alpha: 0.15)
                              : AppColors.primaryContainer
                                  .withValues(alpha: 0.08))),
                  border: isHighContrast && !isAdd
                      ? Border.all(color: Colors.black, width: 1.5)
                      : null,
                ),
                child: Icon(
                  icon,
                  size: hasLargeTargets ? 22 : 20,
                  color: isHighContrast
                      ? Colors.black
                      : (isAdd
                          ? AppColors.onSurfaceVariant
                          : AppColors.primaryContainer),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: hasLargeTargets ? 15 : 14,
                      fontWeight:
                          isHighContrast ? FontWeight.w800 : FontWeight.w600,
                      color: isHighContrast
                          ? Colors.black
                          : (isAdd
                              ? AppColors.onSurfaceVariant
                              : AppColors.onSurface),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: hasLargeTargets ? 12.5 : 11,
                        fontWeight:
                            isHighContrast ? FontWeight.w700 : FontWeight.w500,
                        color: isHighContrast
                            ? const Color(0xFF1A1A1A)
                            : (subtitleColor ?? AppColors.onSurfaceVariant),
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

// ═══════════════════════════════════════════════════════════════════════════
// DRAWER (preserved from original)
// ═══════════════════════════════════════════════════════════════════════════

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer({
    required this.user,
    required this.initials,
    required this.roleLabel,
    required this.onLogout,
    required this.onNavTap,
    required this.onAccessibilityTap,
    required this.onRewardsTap,
    required this.onOperatorTap,
    required this.onFeatureTap,
  });

  final UserModel? user;
  final String initials;
  final String roleLabel;
  final VoidCallback onLogout;
  final void Function(String label) onNavTap;
  final VoidCallback onAccessibilityTap;
  final VoidCallback onRewardsTap;
  final VoidCallback onOperatorTap;
  final void Function(String label) onFeatureTap;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final hasLargeTargets = context.hasLargeTargets;
    final isOperatorOrAdmin = user?.role == UserRole.operator || user?.role == UserRole.admin;

    return Drawer(
      backgroundColor: isHighContrast ? Colors.white : context.surfaceColor,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Drawer Header
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: isHighContrast ? const Color(0xFF001F3F) : AppColors.primary,
                      border: isHighContrast
                          ? const Border(bottom: BorderSide(color: Colors.black, width: 2.0))
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: hasLargeTargets ? 30 : 26,
                              backgroundColor: isHighContrast ? Colors.white : AppColors.primaryContainer,
                              foregroundColor: isHighContrast ? Colors.black : AppColors.onPrimaryContainer,
                              child: Text(
                                initials,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: hasLargeTargets ? 18 : 16,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(12),
                                border: isHighContrast ? Border.all(color: Colors.white, width: 1.5) : null,
                              ),
                              child: Text(
                                roleLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user?.name.isNotEmpty == true ? user!.name : 'Passenger',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: hasLargeTargets ? 20 : 18,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Navigation Tabs
                  _buildDrawerTile(
                    context,
                    icon: Icons.home_rounded,
                    title: 'Home',
                    selected: true,
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.directions_bus_rounded,
                    title: 'Plan Journey',
                    onTap: () {
                      Navigator.pop(context);
                      onNavTap('Plan');
                    },
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.people_rounded,
                    title: 'Community',
                    onTap: () {
                      Navigator.pop(context);
                      onNavTap('Community');
                    },
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.person_rounded,
                    title: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      onNavTap('Profile');
                    },
                  ),

                  Divider(
                    height: 1,
                    thickness: isHighContrast ? 2.0 : 1.0,
                    color: isHighContrast ? Colors.black : AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),

                  // Settings & Features
                  _buildDrawerTile(
                    context,
                    icon: Icons.settings_accessibility_rounded,
                    title: 'Accessibility Preferences',
                    onTap: () {
                      Navigator.pop(context);
                      onAccessibilityTap();
                    },
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.stars_rounded,
                    title: 'Rewards & Contributions',
                    onTap: () {
                      Navigator.pop(context);
                      onRewardsTap();
                    },
                  ),
                  if (isOperatorOrAdmin)
                    _buildDrawerTile(
                      context,
                      icon: Icons.dashboard_rounded,
                      title: 'Operator Dashboard',
                      onTap: () {
                        Navigator.pop(context);
                        onOperatorTap();
                      },
                    ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.bookmark_rounded,
                    title: 'Saved Places',
                    onTap: () {
                      Navigator.pop(context);
                      onFeatureTap('Saved Places');
                    },
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                      onFeatureTap('Help & Support');
                    },
                  ),
                ],
              ),
            ),

            // Bottom Logout Tile
            Divider(
              height: 1,
              thickness: isHighContrast ? 2.0 : 1.0,
              color: isHighContrast ? Colors.black : AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
            _buildDrawerTile(
              context,
              icon: Icons.logout_rounded,
              title: 'Log out',
              titleColor: isHighContrast ? Colors.black : AppColors.error,
              iconColor: isHighContrast ? Colors.black : AppColors.error,
              onTap: () {
                Navigator.pop(context);
                onLogout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
    Color? iconColor,
    Color? titleColor,
  }) {
    final isHighContrast = context.isHighContrast;
    final hasLargeTargets = context.hasLargeTargets;

    final effectiveIconColor = iconColor ??
        (isHighContrast
            ? Colors.black
            : (selected ? AppColors.primary : AppColors.onSurfaceVariant));

    final effectiveTitleColor = titleColor ??
        (isHighContrast
            ? Colors.black
            : (selected ? AppColors.primary : context.textColor));

    return Material(
      color: Colors.transparent,
      child: ListTile(
        selected: selected,
        selectedTileColor: isHighContrast
            ? const Color(0xFFE5E5E5)
            : AppColors.primaryContainer.withValues(alpha: 0.25),
        dense: !hasLargeTargets,
        minVerticalPadding: hasLargeTargets ? 16 : 8,
        minLeadingWidth: 28,
        leading: Icon(
          icon,
          size: context.tapIconSize,
          color: effectiveIconColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: hasLargeTargets ? 17 : 15,
            fontWeight: selected
                ? FontWeight.w800
                : (isHighContrast ? FontWeight.w700 : FontWeight.w600),
            color: effectiveTitleColor,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DESKTOP TOP NAV (preserved from original)
// ═══════════════════════════════════════════════════════════════════════════

class _DesktopTopNav extends StatelessWidget {
  const _DesktopTopNav({
    required this.initials,
    required this.onMenu,
    required this.onNavTap,
    required this.onProfileTap,
  });

  final String initials;
  final VoidCallback onMenu;
  final void Function(String feature) onNavTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;

    return Container(
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.white : AppColors.surface,
        border: isHighContrast
            ? const Border(bottom: BorderSide(color: Colors.black, width: 2.0))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        elevation: isHighContrast ? 0 : 1,
        shadowColor: Colors.black26,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _IconCircleButton(
                    icon: Icons.menu,
                    onPressed: onMenu,
                    isHighContrast: isHighContrast,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Access Transit',
                    style: TextStyle(
                      fontSize: 24,
                      height: 32 / 24,
                      fontWeight: FontWeight.w700,
                      color: isHighContrast ? Colors.black : AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 16),
                          _DesktopNavChip(
                            icon: Icons.home,
                            label: 'Home',
                            selected: true,
                            isHighContrast: isHighContrast,
                          ),
                          _DesktopNavChip(
                            icon: Icons.directions_bus,
                            label: 'Plan',
                            isHighContrast: isHighContrast,
                            onTap: () => onNavTap('Plan'),
                          ),
                          _DesktopNavChip(
                            icon: Icons.groups,
                            label: 'Community',
                            isHighContrast: isHighContrast,
                            onTap: () => onNavTap('Community'),
                          ),
                          _DesktopNavChip(
                            icon: Icons.person,
                            label: 'Profile',
                            isHighContrast: isHighContrast,
                            onTap: () => onNavTap('Profile'),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                  ),
                  _AvatarButton(
                    initials: initials,
                    onPressed: onProfileTap,
                    bordered: true,
                    isHighContrast: isHighContrast,
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

class _DesktopNavChip extends StatelessWidget {
  const _DesktopNavChip({
    required this.icon,
    required this.label,
    this.selected = false,
    this.isHighContrast = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool isHighContrast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final activeBg = isHighContrast ? const Color(0xFF001F3F) : AppColors.primaryContainer;
    final activeFg = Colors.white;
    final inactiveFg = isHighContrast ? Colors.black : AppColors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: selected ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: (selected && isHighContrast)
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 2),
                  )
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? activeFg : inactiveFg,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: selected ? FontWeight.w800 : (isHighContrast ? FontWeight.w700 : FontWeight.w600),
                    letterSpacing: 0.1,
                    color: selected ? activeFg : inactiveFg,
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

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({
    required this.icon,
    required this.onPressed,
    this.isHighContrast = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool isHighContrast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: context.minTapHeight,
      height: context.minTapHeight,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: context.tapIconSize,
          color: isHighContrast ? Colors.black : AppColors.primary,
        ),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({
    required this.initials,
    required this.onPressed,
    this.bordered = false,
    this.isHighContrast = false,
  });

  final String initials;
  final VoidCallback onPressed;
  final bool bordered;
  final bool isHighContrast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: context.minTapHeight,
      height: context.minTapHeight,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isHighContrast ? const Color(0xFF001F3F) : AppColors.primaryContainer,
            border: (bordered || isHighContrast)
                ? Border.all(
                    color: isHighContrast ? Colors.black : AppColors.outlineVariant,
                    width: 2,
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ALERTS SECTION (Phase 1.5 — kept with polish)
// ═══════════════════════════════════════════════════════════════════════════

class _AlertsSection extends StatelessWidget {
  const _AlertsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Status & Alerts',
          style: TextStyle(
            fontSize: 18,
            height: 24 / 18,
            fontWeight: FontWeight.w700,
            color: context.textColor,
          ),
        ),
        const SizedBox(height: 16),
        const _AlertCard(
          accent: AppColors.error,
          icon: Icons.warning,
          title: 'Red Line Delays',
          body: 'Expect up to 15 minute delays due to signal issues.',
        ),
        const SizedBox(height: 8),
        const _StatusCard(
          title: 'Bus 42',
          body: 'On time. Arriving in 4 min.',
          badge: 'Good',
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.body,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final effectiveAccent = isHighContrast ? const Color(0xFF8B0000) : accent;

    return Container(
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.white : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: isHighContrast
            ? Border.all(color: Colors.black, width: 2.0)
            : null,
        boxShadow: isHighContrast
            ? null
            : const [
                BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
              ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: isHighContrast ? 6 : 4,
              decoration: BoxDecoration(
                color: effectiveAccent,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: effectiveAccent),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              height: 24 / 18,
                              fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w600,
                              color: isHighContrast ? Colors.black : AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            body,
                            style: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              color: isHighContrast ? const Color(0xFF1A1A1A) : AppColors.onSurfaceVariant,
                              fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.body,
    required this.badge,
  });

  final String title;
  final String body;
  final String badge;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final accent = isHighContrast ? const Color(0xFF003833) : AppColors.secondary;

    return Container(
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.white : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: isHighContrast
            ? Border.all(color: Colors.black, width: 2.0)
            : null,
        boxShadow: isHighContrast
            ? null
            : const [
                BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
              ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: isHighContrast ? 6 : 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: accent),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              height: 24 / 18,
                              fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w600,
                              color: isHighContrast ? Colors.black : AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            body,
                            style: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              color: isHighContrast ? const Color(0xFF1A1A1A) : AppColors.onSurfaceVariant,
                              fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isHighContrast
                            ? const Color(0xFF003833)
                            : AppColors.secondary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: isHighContrast
                            ? Border.all(color: Colors.black, width: 1.5)
                            : null,
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w500,
                          color: isHighContrast ? Colors.white : AppColors.secondary,
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ACTIVE JOURNEY BANNER (Phase 1.3 — kept as-is)
// ═══════════════════════════════════════════════════════════════════════════

class _ActiveJourneyBanner extends StatelessWidget {
  const _ActiveJourneyBanner({
    required this.journey,
    required this.onResume,
  });

  final JourneyModel journey;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final hasLargeTargets = context.hasLargeTargets;

    return Material(
      color: isHighContrast
          ? Colors.white
          : AppColors.primaryContainer.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onResume,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(hasLargeTargets ? 20 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighContrast
                  ? Colors.black
                  : AppColors.primary.withValues(alpha: 0.3),
              width: isHighContrast ? 2.0 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: hasLargeTargets ? 54 : 48,
                height: hasLargeTargets ? 54 : 48,
                decoration: BoxDecoration(
                  color: isHighContrast ? const Color(0xFF001F3F) : AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: isHighContrast
                      ? Border.all(color: Colors.black, width: 1.5)
                      : null,
                ),
                child: Icon(
                  Icons.directions_bus_rounded,
                  color: Colors.white,
                  size: hasLargeTargets ? 32 : 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            journey.routeTitle.isNotEmpty
                                ? journey.routeTitle
                                : 'Active Journey',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: hasLargeTargets ? 18 : 16,
                              fontWeight: FontWeight.w700,
                              color: isHighContrast ? Colors.black : AppColors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isHighContrast ? const Color(0xFF001F3F) : AppColors.primary,
                            borderRadius: BorderRadius.circular(999),
                            border: isHighContrast
                                ? Border.all(color: Colors.black, width: 1.5)
                                : null,
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${journey.origin} → ${journey.destination}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: hasLargeTargets ? 15 : 14,
                        color: isHighContrast ? const Color(0xFF1A1A1A) : AppColors.onSurfaceVariant,
                        fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to resume live tracking →',
                      style: TextStyle(
                        fontSize: hasLargeTargets ? 14 : 13,
                        fontWeight: FontWeight.w700,
                        color: isHighContrast ? Colors.black : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RECENT JOURNEY CARD (Phase 1.6 — kept with polish)
// ═══════════════════════════════════════════════════════════════════════════

class _RecentJourneyCard extends StatelessWidget {
  const _RecentJourneyCard({required this.onReplan});

  final VoidCallback onReplan;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final hasLargeTargets = context.hasLargeTargets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Journey',
          style: TextStyle(
            fontSize: 18,
            height: 24 / 18,
            fontWeight: FontWeight.w700,
            color: isHighContrast ? Colors.black : AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(hasLargeTargets ? 20 : 16),
          decoration: BoxDecoration(
            color: isHighContrast ? Colors.white : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: isHighContrast
                ? Border.all(color: Colors.black, width: 2.0)
                : null,
            boxShadow: isHighContrast
                ? null
                : const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
                  ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 520;
              final mapBoxSize = hasLargeTargets ? 108.0 : 96.0;
              final map = Container(
                width: stacked ? double.infinity : mapBoxSize,
                height: mapBoxSize,
                decoration: BoxDecoration(
                  color: isHighContrast ? const Color(0xFFE5E5E5) : AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: isHighContrast ? Border.all(color: Colors.black, width: 1.5) : null,
                ),
                child: Icon(
                  Icons.map,
                  color: isHighContrast ? Colors.black : AppColors.primary,
                  size: hasLargeTargets ? 42 : 36,
                ),
              );

              final details = Column(
                crossAxisAlignment:
                    stacked ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  Text(
                    'Central Station to Library',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: hasLargeTargets ? 20 : 18,
                      height: 24 / 18,
                      fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w600,
                      color: isHighContrast ? Colors.black : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Yesterday, 2:45 PM',
                    style: TextStyle(
                      fontSize: hasLargeTargets ? 15 : 14,
                      height: 20 / 14,
                      color: isHighContrast ? const Color(0xFF1A1A1A) : AppColors.onSurfaceVariant,
                      fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              );

              final button = SizedBox(
                height: context.buttonHeight,
                width: stacked ? double.infinity : null,
                child: FilledButton(
                  onPressed: onReplan,
                  style: FilledButton.styleFrom(
                    backgroundColor: isHighContrast ? const Color(0xFF001F3F) : AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    side: isHighContrast ? const BorderSide(color: Colors.black, width: 2.0) : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Re-plan',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: context.buttonFontSize,
                    ),
                  ),
                ),
              );

              if (stacked) {
                return Column(
                  children: [
                    map,
                    const SizedBox(height: 16),
                    details,
                    const SizedBox(height: 16),
                    button,
                  ],
                );
              }

              return Row(
                children: [
                  map,
                  const SizedBox(width: 16),
                  Expanded(child: details),
                  button,
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ASSISTANCE FAB (Phase 1.7 — kept as-is)
// ═══════════════════════════════════════════════════════════════════════════

class _AssistanceFab extends StatelessWidget {
  const _AssistanceFab({required this.showLabel, required this.onPressed});

  final bool showLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final hasLargeTargets = context.hasLargeTargets;

    return Material(
      color: isHighContrast ? const Color(0xFF8B0000) : AppColors.error,
      elevation: isHighContrast ? 0 : 6,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: isHighContrast
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 2.0),
                )
              : null,
          padding: EdgeInsets.symmetric(
            horizontal: hasLargeTargets ? 28 : 24,
            vertical: hasLargeTargets ? 18 : 14,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.support_agent, color: Colors.white, size: context.tapIconSize),
              if (showLabel) ...[
                const SizedBox(width: 8),
                Text(
                  'Assistance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: hasLargeTargets ? 17 : 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
