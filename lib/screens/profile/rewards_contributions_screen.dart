import '../../l10n/reward_presentation.dart';
import '../../l10n/localization_context.dart';
import '../../services/moderation_mode.dart';
import '../../services/moderation_client.dart';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'membership_card_screen.dart';

/// Rewards & Contributions — points, level, and contribution stats.
class RewardsContributionsScreen extends StatefulWidget {
  const RewardsContributionsScreen({
    super.key,
    this.user,
    this.totalPoints,
    this.levelLabel,
    this.reportsSubmitted,
    this.verifiedSpots,
  });

  final UserModel? user;
  final int? totalPoints;
  final String? levelLabel;
  final int? reportsSubmitted;
  final int? verifiedSpots;

  @override
  State<RewardsContributionsScreen> createState() =>
      _RewardsContributionsScreenState();
}

class _RewardsContributionsScreenState
    extends State<RewardsContributionsScreen> {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  int? _v2Points;
  bool _v2Unavailable = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    if (ModerationMode.enabled) _loadV2Points();
    if (_user == null && widget.totalPoints == null) {
      _loadProfile();
    }
  }

  Future<void> _loadV2Points() async {
    final owner = _authService.currentUser?.uid;
    final client = ModerationClient();
    try {
      final value = await client.accountStatus();
      if (mounted && _authService.currentUser?.uid == owner) {
        setState(() {
          _v2Points = value.points;
          _v2Unavailable = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _v2Unavailable = true);
    } finally {
      client.dispose();
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

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;

    final points = ModerationMode.enabled
        ? (_v2Points ?? 0)
        : widget.totalPoints ?? _user?.points ?? 0;
    final reports = widget.reportsSubmitted ?? _user?.reportsSubmitted ?? 0;
    final verified = widget.verifiedSpots ?? _user?.verifiedCount ?? 0;
    final badges = ModerationMode.enabled
        ? (points < 0 ? 0 : points ~/ 100)
        : _user?.badges ?? (points ~/ 100);

    final String level =
        widget.levelLabel ??
        (badges >= 3
            ? 'Gold Contributor'
            : (badges >= 1 ? 'Silver Contributor' : 'Bronze Contributor'));

    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: Column(
        children: [
          _TopBar(
            onBack: () => Navigator.of(context).maybePop(),
            onSettings: () =>
                _showSnack(context, context.l10n.rewardsSettingsSoon),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: isHC ? Colors.black : AppColors.primary,
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                    children: [
                      Text(
                        context.l10n.rewardsMine,
                        style: TextStyle(
                          fontSize: 22,
                          height: 28 / 22,
                          fontWeight: FontWeight.w700,
                          color: context.textColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        ModerationMode.enabled
                            ? context.l10n.v2PointsNotice
                            : context.l10n.rewardsLegacyNotice,
                      ),
                      const SizedBox(height: 16),
                      if (ModerationMode.enabled &&
                          (_v2Unavailable || _v2Points == null))
                        TextButton(
                          onPressed: _loadV2Points,
                          child: Text(context.l10n.refreshV2Points),
                        )
                      else
                        _PointsHeroCard(totalPoints: points, levelLabel: level),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              icon: Icons.description_outlined,
                              iconBg: AppColors.primaryFixed,
                              iconColor: AppColors.primaryContainer,
                              value: '$reports',
                              label: context.l10n.rewardsReports,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.verified,
                              iconBg: AppColors.secondaryContainer,
                              iconColor: AppColors.onSecondaryContainer,
                              value: '$verified',
                              label: context.l10n.rewardsConfirmations,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: context.buttonHeight,
                        ),
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MembershipCardScreen(
                                  user: _user,
                                  points: points,
                                  memberTier: level.contains('Gold')
                                      ? 'Gold Member'
                                      : (level.contains('Silver')
                                            ? 'Silver Member'
                                            : 'Bronze Member'),
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
                                ? const BorderSide(
                                    color: Colors.black,
                                    width: 2,
                                  )
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
                          icon: Icon(
                            Icons.badge_outlined,
                            size: context.tapIconSize,
                          ),
                          label: Text(context.l10n.rewardsViewCard),
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
  const _TopBar({required this.onBack, required this.onSettings});

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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
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
                    context.l10n.rewardsTitle,
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
                  tooltip: context.l10n.profileSettings,
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
  const _PointsHeroCard({required this.totalPoints, required this.levelLabel});

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
                  border: isHC
                      ? Border.all(color: Colors.black, width: 1.5)
                      : null,
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(
                      Icons.stars,
                      size: 20,
                      color: isHC
                          ? Colors.black
                          : AppColors.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.rewardsLevel(context.rewardTier(levelLabel)),
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                        color: isHC
                            ? Colors.black
                            : AppColors.onSecondaryContainer,
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
                context.l10n.rewardsTotal,
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
            child: Icon(icon, color: isHC ? Colors.black : iconColor, size: 22),
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
