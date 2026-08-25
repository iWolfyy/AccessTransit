import 'package:flutter/material.dart';

import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_colors.dart';

/// Digital Membership Card — QR, points, member benefits.
class MembershipCardScreen extends StatelessWidget {
  const MembershipCardScreen({
    super.key,
    this.memberName = 'PASINDU',
    this.memberTier = 'Gold Member',
    this.roleLabel = 'Community Contributor',
    this.points = 125,
    this.memberId = 'AT-4821-7936',
  });

  final String memberName;
  final String memberTier;
  final String roleLabel;
  final int points;
  final String memberId;

  static const double _desktopBreakpoint = 768;
  static const Color _tertiaryFixed = Color(0xFFFFDBCA);
  static const Color _onTertiaryFixed = Color(0xFF331200);
  static const Color _secondaryFixed = Color(0xFF8FF4E9);
  static const Color _onSecondaryFixed = Color(0xFF00201D);

  static const _qrImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuD2EQGr3mG0xmxMRtptwz2DxqjbTc0HOrxCPch-Fo9geg1Pw_IJ3nmXV-UPsNBAgZvJSJfKqLABsvPK1_RVKKh4mh5_ac6pmS3PwobkhPwvmSVN_TrRFeN6i0f-seR7xHBdv__RERvnbGphw-h9qeTu_cj9Z80Izax_vDtRyTsRzf-ByxyLP7tPOWf6Ld66B3PhHmIH6sO5eNryEaDB-RNoST4MMKNhZvUzhaMhZCRo1FbmMscPpjX0YA';

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onNavTap(BuildContext context, String label) {
    AppNavigation.handleBottomNav(
      context,
      label,
      onUnsupported: (message) => _showSnack(context, message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _TopBar(onBack: () => Navigator.of(context).maybePop()),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, isDesktop ? 24 : 16, 16, 32),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 768),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _MembershipCard(
                          memberName: memberName,
                          memberTier: memberTier,
                          roleLabel: roleLabel,
                          points: points,
                          memberId: memberId,
                          qrImageUrl: _qrImageUrl,
                          tertiaryFixed: _tertiaryFixed,
                          onTertiaryFixed: _onTertiaryFixed,
                        ),
                        const SizedBox(height: 24),
                        _BenefitsSection(
                          secondaryFixed: _secondaryFixed,
                          onSecondaryFixed: _onSecondaryFixed,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: () => Navigator.of(context).maybePop(),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: AppColors.onPrimaryContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 14,
                                height: 20 / 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                              ),
                            ),
                            icon: const Icon(Icons.arrow_back, size: 20),
                            label: const Text('Back to Rewards'),
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
          : _MembershipBottomNav(
              onNavTap: (label) => _onNavTap(context, label),
            ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

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
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                ),
                const Expanded(
                  child: Text(
                    'Digital Membership Card',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 22,
                      height: 28 / 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({
    required this.memberName,
    required this.memberTier,
    required this.roleLabel,
    required this.points,
    required this.memberId,
    required this.qrImageUrl,
    required this.tertiaryFixed,
    required this.onTertiaryFixed,
  });

  final String memberName;
  final String memberTier;
  final String roleLabel;
  final int points;
  final String memberId;
  final String qrImageUrl;
  final Color tertiaryFixed;
  final Color onTertiaryFixed;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 768;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceContainer),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 8,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondaryContainer,
                  AppColors.primary,
                  AppColors.primaryContainer,
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isWide ? 24 : 16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.directions_bus,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'ACCESS TRANSIT',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 16 / 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            memberName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 32,
                              height: 40 / 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.64,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.workspace_premium,
                                  size: 16,
                                  color: AppColors.onSecondaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  memberTier,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 16 / 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.onSecondaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tertiaryFixed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.handshake,
                                size: 16,
                                color: onTertiaryFixed,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                roleLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 16 / 12,
                                  fontWeight: FontWeight.w500,
                                  color: onTertiaryFixed,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$points Points',
                          style: const TextStyle(
                            fontSize: 18,
                            height: 24 / 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.surfaceVariant),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.outlineVariant),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Image.network(
                          qrImageUrl,
                          width: isWide ? 256 : 192,
                          height: isWide ? 256 : 192,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return SizedBox(
                              width: isWide ? 256 : 192,
                              height: isWide ? 256 : 192,
                              child: CustomPaint(
                                painter: _QrPlaceholderPainter(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: $memberId',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                          letterSpacing: 2,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Scan at participating partner locations or transit hubs.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            color: AppColors.outline,
                          ),
                        ),
                      ),
                    ],
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

class _QrPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.white;
    final fg = Paint()..color = Colors.black;
    canvas.drawRect(Offset.zero & size, bg);

    const cells = 11;
    final cell = size.width / cells;
    for (var y = 0; y < cells; y++) {
      for (var x = 0; x < cells; x++) {
        final corner = (x < 3 && y < 3) ||
            (x > cells - 4 && y < 3) ||
            (x < 3 && y > cells - 4);
        final pattern = ((x * 3 + y * 5) % 7) < 3;
        if (corner || pattern) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell, cell),
            fg,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BenefitsSection extends StatelessWidget {
  const _BenefitsSection({
    required this.secondaryFixed,
    required this.onSecondaryFixed,
  });

  final Color secondaryFixed;
  final Color onSecondaryFixed;

  @override
  Widget build(BuildContext context) {
    final benefits = [
      (
        Icons.loyalty,
        AppColors.primaryFixed,
        AppColors.primary,
        'Partner Discounts',
        'Exclusive rates at local businesses and transit services.',
      ),
      (
        Icons.card_membership,
        AppColors.primaryFixed,
        AppColors.primary,
        'Member Benefits',
        'Priority support and early access to new transit features.',
      ),
      (
        Icons.verified,
        secondaryFixed,
        onSecondaryFixed,
        'Community Recognition',
        'Earned for contributing accessibility reports and feedback.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Member Benefits',
            style: TextStyle(
              fontSize: 18,
              height: 24 / 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.surfaceVariant),
          const SizedBox(height: 8),
          for (var i = 0; i < benefits.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _BenefitRow(
              icon: benefits[i].$1,
              iconBg: benefits[i].$2,
              iconColor: benefits[i].$3,
              title: benefits[i].$4,
              subtitle: benefits[i].$5,
            ),
          ],
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
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
                  Text(
                    subtitle,
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
    );
  }
}

/// App-standard nav: Home → Plan → Live → Community → Profile.
class _MembershipBottomNav extends StatelessWidget {
  const _MembershipBottomNav({required this.onNavTap});

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
                onTap: () => onNavTap('Community'),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                selected: true,
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
