import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialUser});

  final UserModel? initialUser;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _desktopBreakpoint = 768;

  final AuthService _authService = AuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _user = widget.initialUser;
    _isLoading = widget.initialUser == null;
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getCurrentUserProfile();
      if (!mounted) return;
      setState(() {
        _user = user ?? _user;
        _isLoading = false;
      });
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

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(initialUser: _user),
      ),
    );
  }

  void _onBottomNavTap(String feature) {
    if (feature == 'Profile') {
      _openProfile();
      return;
    }
    _showComingSoon(feature);
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.surface,
      drawer: _HomeDrawer(
        user: _user,
        initials: _initials,
        onLogout: _logout,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (isDesktop)
                  _DesktopTopNav(
                    initials: _initials,
                    onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                    onNavTap: _showComingSoon,
                    onProfileTap: () => _showProfileMenu(context),
                  )
                else
                  _MobileTopBar(
                    initials: _initials,
                    onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                    onProfileTap: () => _showProfileMenu(context),
                  ),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          isDesktop ? 24 : 16,
                          24,
                          isDesktop ? 24 : 16,
                          isDesktop ? 24 : 112,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1280),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _WhereToSearch(),
                                  const SizedBox(height: 24),
                                  _FavoritesSection(
                                    isDesktop: isDesktop,
                                    onTap: _showComingSoon,
                                  ),
                                  const SizedBox(height: 24),
                                  const _AlertsSection(),
                                  const SizedBox(height: 24),
                                  _RecentJourneyCard(
                                    onReplan: () => _showComingSoon('Re-plan'),
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
        padding: EdgeInsets.only(bottom: isDesktop ? 0 : 72),
        child: _AssistanceFab(
          showLabel: MediaQuery.sizeOf(context).width >= 640,
          onPressed: () => _showComingSoon('Assistance'),
        ),
      ),
      bottomNavigationBar: isDesktop
          ? null
          : _MobileBottomNav(onNavTap: _onBottomNavTap),
    );
  }

  Future<void> _showProfileMenu(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.onPrimaryContainer,
                  child: Text(_initials),
                ),
                title: Text(_user?.name.isNotEmpty == true ? _user!.name : 'Passenger'),
                subtitle: Text(_user?.email ?? ''),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Log out'),
                onTap: () => Navigator.pop(context, 'logout'),
              ),
            ],
          ),
        );
      },
    );

    if (result == 'logout') {
      await _logout();
    }
  }
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer({
    required this.user,
    required this.initials,
    required this.onLogout,
  });

  final UserModel? user;
  final String initials;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: AppColors.onPrimaryContainer,
                    child: Text(
                      initials,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name.isNotEmpty == true ? user!.name : 'Passenger',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: AppColors.primary),
              title: const Text('Home'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () {
                Navigator.pop(context);
                onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({
    required this.initials,
    required this.onMenu,
    required this.onProfileTap,
  });

  final String initials;
  final VoidCallback onMenu;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLow,
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
                _IconCircleButton(icon: Icons.menu, onPressed: onMenu),
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
                _AvatarButton(initials: initials, onPressed: onProfileTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
    return Material(
      color: AppColors.surface,
      elevation: 1,
      shadowColor: Colors.black26,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _IconCircleButton(icon: Icons.menu, onPressed: onMenu),
                const SizedBox(width: 16),
                const Text(
                  'Access Transit',
                  style: TextStyle(
                    fontSize: 24,
                    height: 32 / 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                const _DesktopNavChip(icon: Icons.home, label: 'Home', selected: true),
                _DesktopNavChip(
                  icon: Icons.directions_bus,
                  label: 'Plan',
                  onTap: () => onNavTap('Plan'),
                ),
                _DesktopNavChip(
                  icon: Icons.sensors,
                  label: 'Live',
                  onTap: () => onNavTap('Live'),
                ),
                _DesktopNavChip(
                  icon: Icons.groups,
                  label: 'Community',
                  onTap: () => onNavTap('Community'),
                ),
                const Spacer(),
                _AvatarButton(
                  initials: initials,
                  onPressed: onProfileTap,
                  bordered: true,
                ),
              ],
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
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: selected ? AppColors.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                    color: selected
                        ? AppColors.onPrimaryContainer
                        : AppColors.onSurfaceVariant,
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
  const _IconCircleButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({
    required this.initials,
    required this.onPressed,
    this.bordered = false,
  });

  final String initials;
  final VoidCallback onPressed;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryContainer,
            border: bordered
                ? Border.all(color: AppColors.outlineVariant, width: 2)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              color: AppColors.onPrimaryContainer,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _WhereToSearch extends StatelessWidget {
  const _WhereToSearch();

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Where to?',
        hintStyle: const TextStyle(
          fontSize: 16,
          height: 24 / 16,
          color: AppColors.onSurfaceVariant,
        ),
        prefixIcon: const Icon(Icons.search, color: AppColors.onSurfaceVariant),
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      style: const TextStyle(
        fontSize: 16,
        height: 24 / 16,
        color: AppColors.onSurface,
      ),
    );
  }
}

class _FavoritesSection extends StatelessWidget {
  const _FavoritesSection({required this.isDesktop, required this.onTap});

  final bool isDesktop;
  final void Function(String feature) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Favorites',
          style: TextStyle(
            fontSize: 18,
            height: 24 / 18,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: isDesktop ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: isDesktop ? 16 : 12,
          mainAxisSpacing: isDesktop ? 16 : 12,
          childAspectRatio: isDesktop ? 1.35 : 1.15,
          children: [
            _FavoriteCard(
              icon: Icons.home,
              filled: true,
              label: 'Home',
              subtitle: '15 min',
              subtitleColor: AppColors.secondary,
              onTap: () => onTap('Home favorite'),
            ),
            _FavoriteCard(
              icon: Icons.work_outline,
              label: 'Work',
              subtitle: '32 min',
              subtitleColor: AppColors.secondary,
              onTap: () => onTap('Work favorite'),
            ),
            _FavoriteCard(
              icon: Icons.local_hospital_outlined,
              label: 'Medical',
              subtitle: '-- min',
              subtitleColor: AppColors.onSurfaceVariant,
              onTap: () => onTap('Medical favorite'),
            ),
            _FavoriteCard(
              icon: Icons.add,
              label: 'Add New',
              dashed: true,
              onTap: () => onTap('Add favorite'),
            ),
          ],
        ),
      ],
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.subtitleColor,
    this.filled = false,
    this.dashed = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? subtitleColor;
  final bool filled;
  final bool dashed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: dashed ? AppColors.surfaceContainer : AppColors.surfaceContainerLowest,
      elevation: 1,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: dashed ? const _DashedBorderPainter() : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dashed
                        ? Colors.transparent
                        : AppColors.primaryContainer.withValues(alpha: 0.10),
                  ),
                  child: Icon(
                    icon,
                    color: dashed ? AppColors.onSurfaceVariant : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                    color: dashed ? AppColors.onSurfaceVariant : AppColors.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor ?? AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outlineVariant
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
          const Radius.circular(12),
        ),
      );

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AlertsSection extends StatelessWidget {
  const _AlertsSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Status & Alerts',
          style: TextStyle(
            fontSize: 18,
            height: 24 / 18,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        SizedBox(height: 16),
        _AlertCard(
          accent: AppColors.error,
          icon: Icons.warning,
          title: 'Red Line Delays',
          body: 'Expect up to 15 minute delays due to signal issues.',
        ),
        SizedBox(height: 8),
        _StatusCard(
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: accent),
                    const SizedBox(width: 16),
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
                          Text(
                            body,
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.secondary),
                    const SizedBox(width: 16),
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
                          Text(
                            body,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondary,
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

class _RecentJourneyCard extends StatelessWidget {
  const _RecentJourneyCard({required this.onReplan});

  final VoidCallback onReplan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Journey',
          style: TextStyle(
            fontSize: 18,
            height: 24 / 18,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 520;
              final map = Container(
                width: stacked ? double.infinity : 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.map, color: AppColors.primary, size: 36),
              );

              final details = Column(
                crossAxisAlignment:
                    stacked ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Central Station to Library',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      height: 24 / 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Yesterday, 2:45 PM',
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              );

              final button = SizedBox(
                height: 48,
                width: stacked ? double.infinity : null,
                child: FilledButton(
                  onPressed: onReplan,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Re-plan',
                    style: TextStyle(fontWeight: FontWeight.w600),
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

class _AssistanceFab extends StatelessWidget {
  const _AssistanceFab({required this.showLabel, required this.onPressed});

  final bool showLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.error,
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.support_agent, color: AppColors.onError),
              if (showLabel) ...[
                const SizedBox(width: 8),
                const Text(
                  'Assistance',
                  style: TextStyle(
                    color: AppColors.onError,
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
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

class _MobileBottomNav extends StatelessWidget {
  const _MobileBottomNav({required this.onNavTap});

  final void Function(String feature) onNavTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              const Expanded(
                child: _BottomNavItem(
                  icon: Icons.home,
                  label: 'Home',
                  selected: true,
                ),
              ),
              Expanded(
                child: _BottomNavItem(
                  icon: Icons.directions_bus,
                  label: 'Plan',
                  onTap: () => onNavTap('Plan'),
                ),
              ),
              Expanded(
                child: _BottomNavItem(
                  icon: Icons.sensors,
                  label: 'Live',
                  onTap: () => onNavTap('Live'),
                ),
              ),
              Expanded(
                child: _BottomNavItem(
                  icon: Icons.groups,
                  label: 'Community',
                  onTap: () => onNavTap('Community'),
                ),
              ),
              Expanded(
                child: _BottomNavItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  onTap: () => onNavTap('Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
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
    final content = Padding(
      padding: selected
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: selected ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
              color: selected ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    if (!selected) {
      return InkWell(onTap: onTap, child: content);
    }

    return Center(
      child: Material(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }
}
