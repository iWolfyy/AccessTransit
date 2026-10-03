import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

/// Digital Membership Card — QR, points, member benefits.
class MembershipCardScreen extends StatefulWidget {
  const MembershipCardScreen({
    super.key,
    this.user,
    this.memberName,
    this.memberTier,
    this.roleLabel,
    this.points,
    this.memberId,
  });

  final UserModel? user;
  final String? memberName;
  final String? memberTier;
  final String? roleLabel;
  final int? points;
  final String? memberId;

  @override
  State<MembershipCardScreen> createState() => _MembershipCardScreenState();
}

class _MembershipCardScreenState extends State<MembershipCardScreen> {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    if (_user == null && widget.memberName == null) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _authService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _user = profile;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static const double _desktopBreakpoint = 768;
  static const Color _tertiaryFixed = Color(0xFFFFDBCA);
  static const Color _onTertiaryFixed = Color(0xFF331200);
  static const Color _secondaryFixed = Color(0xFF8FF4E9);
  static const Color _onSecondaryFixed = Color(0xFF00201D);

  static const _qrImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuD2EQGr3mG0xmxMRtptwz2DxqjbTc0HOrxCPch-Fo9geg1Pw_IJ3nmXV-UPsNBAgZvJSJfKqLABsvPK1_RVKKh4mh5_ac6pmS3PwobkhPwvmSVN_TrRFeN6i0f-seR7xHBdv__RERvnbGphw-h9qeTu_cj9Z80Izax_vDtRyTsRzf-ByxyLP7tPOWf6Ld66B3PhHmIH6sO5eNryEaDB-RNoST4MMKNhZvUzhaMhZCRo1FbmMscPpjX0YA';

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;
    final isHC = context.isHighContrast;

    final resolvedName = widget.memberName ??
        (_user?.name.trim().isNotEmpty == true ? _user!.name : 'Commuter');
    final resolvedPoints = widget.points ?? _user?.points ?? 0;
    final badges = _user?.badges ?? (resolvedPoints ~/ 100);
    final resolvedTier = widget.memberTier ??
        (badges >= 3
            ? 'Gold Member'
            : (badges >= 1 ? 'Silver Member' : 'Bronze Member'));
    final resolvedRole = widget.roleLabel ?? 'Community Contributor';
    final rawUid = _user?.uid ?? '';
    final shortUid = rawUid.length > 8 ? rawUid.substring(0, 8).toUpperCase() : (rawUid.isNotEmpty ? rawUid.toUpperCase() : '4821-7936');
    final resolvedMemberId = widget.memberId ?? 'AT-$shortUid';

    return Scaffold(
      backgroundColor: context.surfaceColor,
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
                          memberName: resolvedName,
                          memberTier: resolvedTier,
                          roleLabel: resolvedRole,
                          points: resolvedPoints,
                          memberId: resolvedMemberId,
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
                          height: context.buttonHeight,
                          child: FilledButton.icon(
                            onPressed: () => Navigator.of(context).maybePop(),
                            style: FilledButton.styleFrom(
                              backgroundColor: isHC
                                  ? const Color(0xFF001F3F)
                                  : AppColors.primaryContainer,
                              foregroundColor: AppColors.onPrimary,
                              side: isHC
                                  ? const BorderSide(color: Colors.black, width: 2)
                                  : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              textStyle: TextStyle(
                                fontSize: context.buttonFontSize,
                                height: 20 / 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                              ),
                            ),
                            icon: Icon(Icons.arrow_back, size: context.tapIconSize),
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
      bottomNavigationBar: null,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;

    return Material(
      color: isHC ? Colors.white : AppColors.surface,
      elevation: isHC ? 0 : 1,
      shadowColor: isHC ? null : AppColors.onSurface.withValues(alpha: 0.08),
      shape: isHC
          ? const Border(bottom: BorderSide(color: Colors.black, width: 2))
          : null,
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
                  icon: Icon(
                    Icons.arrow_back,
                    color: isHC ? Colors.black : AppColors.primary,
                    size: context.tapIconSize,
                  ),
                  constraints: context.appBarActionConstraints,
                ),
                Expanded(
                  child: Text(
                    'Digital Membership Card',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 22,
                      height: 28 / 22,
                      fontWeight: FontWeight.w700,
                      color: isHC ? Colors.black : AppColors.primary,
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
    final isHC = context.isHighContrast;

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isHC
            ? Border.all(color: Colors.black, width: 2)
            : Border.all(color: AppColors.surfaceContainer),
        boxShadow: isHC
            ? null
            : [
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
            height: isHC ? 4 : 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isHC ? const Color(0xFF001F3F) : null,
              gradient: isHC
                  ? null
                  : const LinearGradient(
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
                          Row(
                            children: [
                              Icon(
                                Icons.directions_bus,
                                color: isHC ? Colors.black : AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ACCESS TRANSIT',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 16 / 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: isHC ? Colors.black : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            memberName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 32,
                              height: 40 / 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.64,
                              color: context.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isHC
                                  ? Colors.white
                                  : AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(999),
                              border: isHC
                                  ? Border.all(color: Colors.black, width: 1.5)
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.workspace_premium,
                                  size: 16,
                                  color: isHC
                                      ? Colors.black
                                      : AppColors.onSecondaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  memberTier,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 16 / 12,
                                    fontWeight: FontWeight.w600,
                                    color: isHC
                                        ? Colors.black
                                        : AppColors.onSecondaryContainer,
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
                            color: isHC ? Colors.white : tertiaryFixed,
                            borderRadius: BorderRadius.circular(8),
                            border: isHC
                                ? Border.all(color: Colors.black, width: 1.5)
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.handshake,
                                size: 16,
                                color: isHC ? Colors.black : onTertiaryFixed,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                roleLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 16 / 12,
                                  fontWeight: FontWeight.w600,
                                  color: isHC ? Colors.black : onTertiaryFixed,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$points Points',
                          style: TextStyle(
                            fontSize: 18,
                            height: 24 / 18,
                            fontWeight: FontWeight.w700,
                            color: isHC
                                ? const Color(0xFF001F3F)
                                : AppColors.primary,
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
                    color: isHC ? Colors.white : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isHC ? Colors.black : AppColors.surfaceVariant,
                      width: isHC ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isHC ? Colors.black : AppColors.outlineVariant,
                            width: isHC ? 2 : 1,
                          ),
                          boxShadow: isHC
                              ? null
                              : [
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
                        style: TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          letterSpacing: 2,
                          color: context.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Scan at participating partner locations or transit hubs.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            color: context.subtextColor,
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
    final isHC = context.isHighContrast;
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
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isHC ? Border.all(color: Colors.black, width: 2) : null,
        boxShadow: isHC
            ? null
            : [
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
          Text(
            'Member Benefits',
            style: TextStyle(
              fontSize: 18,
              height: 24 / 18,
              fontWeight: FontWeight.w600,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: isHC ? Colors.black : AppColors.surfaceVariant,
          ),
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
    final isHC = context.isHighContrast;

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
                color: isHC ? Colors.white : iconBg,
                shape: BoxShape.circle,
                border: isHC ? Border.all(color: Colors.black, width: 1.5) : null,
              ),
              child: Icon(
                icon,
                color: isHC ? Colors.black : iconColor,
                size: 22,
              ),
            ),
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
                      fontWeight: FontWeight.w600,
                      color: context.textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: context.subtextColor,
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
