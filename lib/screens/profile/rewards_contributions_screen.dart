import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'membership_card_screen.dart';

/// Rewards & Contributions — points, level, and contribution stats.
class RewardsContributionsScreen extends StatelessWidget {
  const RewardsContributionsScreen({
    super.key,
    this.totalPoints = 125,
    this.levelLabel = 'Gold Contributor',
    this.reportsSubmitted = 12,
    this.verifiedSpots = 8,
  });

  final int totalPoints;
  final String levelLabel;
  final int reportsSubmitted;
  final int verifiedSpots;

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;

    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: Column(
        children: [
          _TopBar(
            onBack: () => Navigator.of(context).maybePop(),
            onSettings: () =>
                _showSnack(context, 'Settings will be available soon.'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              children: [
                Text(
                  'My Contributions',
                  style: TextStyle(
                    fontSize: 22,
                    height: 28 / 22,
                    fontWeight: FontWeight.w700,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 24),
                _PointsHeroCard(
                  totalPoints: totalPoints,
                  levelLabel: levelLabel,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.description_outlined,
                        iconBg: AppColors.primaryFixed,
                        iconColor: AppColors.primaryContainer,
                        value: '$reportsSubmitted',
                        label: 'Reports Submitted',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.verified,
                        iconBg: AppColors.secondaryContainer,
                        iconColor: AppColors.onSecondaryContainer,
                        value: '$verifiedSpots',
                        label: 'Verified Spots',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: context.buttonHeight,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MembershipCardScreen(
                            points: totalPoints,
                            memberTier: levelLabel.contains('Gold')
                                ? 'Gold Member'
                                : levelLabel,
                          ),
                        ),
                      );
                    },
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
                    icon: Icon(Icons.badge_outlined, size: context.tapIconSize),
                    label: const Text('View Membership Card'),
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
  const _TopBar({
    required this.onBack,
    required this.onSettings,
  });

  final VoidCallback onBack;
  final VoidCallback onSettings;

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
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  tooltip: 'Go back',
                  constraints: BoxConstraints(
                    minWidth: context.minTapHeight,
                    minHeight: context.minTapHeight,
                  ),
                  icon: Icon(
                    Icons.arrow_back,
                    color: isHC ? Colors.black : AppColors.primary,
                    size: context.tapIconSize,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Rewards & Contributions',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      height: 28 / 22,
                      fontWeight: FontWeight.w700,
                      color: isHC ? Colors.black : AppColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onSettings,
                  tooltip: 'Settings',
                  constraints: BoxConstraints(
                    minWidth: context.minTapHeight,
                    minHeight: context.minTapHeight,
                  ),
                  icon: Icon(
                    Icons.settings,
                    color: isHC ? Colors.black : AppColors.primary,
                    size: context.tapIconSize,
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

class _PointsHeroCard extends StatelessWidget {
  const _PointsHeroCard({
    required this.totalPoints,
    required this.levelLabel,
  });

  final int totalPoints;
  final String levelLabel;

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isHC
            ? Border.all(color: Colors.black, width: 2)
            : Border.all(color: AppColors.surfaceVariant),
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
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (!isHC)
            Positioned(
              top: -32,
              right: -32,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryFixed.withValues(alpha: 0.5),
                ),
              ),
            ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isHC ? Colors.white : AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                  border: isHC ? Border.all(color: Colors.black, width: 1.5) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.stars,
                      size: 20,
                      color: isHC ? Colors.black : AppColors.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Level: $levelLabel',
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                        color: isHC ? Colors.black : AppColors.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$totalPoints',
                style: TextStyle(
                  fontSize: 32,
                  height: 40 / 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.64,
                  color: isHC ? const Color(0xFF001F3F) : AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total Points',
                style: TextStyle(
                  fontSize: 18,
                  height: 24 / 18,
                  fontWeight: FontWeight.w600,
                  color: context.subtextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;

    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isHC
            ? Border.all(color: Colors.black, width: 2)
            : Border.all(color: AppColors.surfaceVariant),
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
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              height: 24 / 18,
              fontWeight: FontWeight.w600,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: context.subtextColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// App-standard nav: Home → Plan → Live → Community → Profile.
