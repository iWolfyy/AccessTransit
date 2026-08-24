import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'community_preview.dart';

/// Onboarding step 3: community reporting and contribution badges.
class CommunityReportingPage extends StatefulWidget {
  const CommunityReportingPage({
    super.key,
    required this.isActive,
    required this.reduceMotion,
  });

  final bool isActive;
  final bool reduceMotion;

  @override
  State<CommunityReportingPage> createState() => _CommunityReportingPageState();
}

class _CommunityReportingPageState extends State<CommunityReportingPage>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _floatController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    if (widget.isActive) {
      _play();
    }
  }

  @override
  void didUpdateWidget(covariant CommunityReportingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion && !oldWidget.reduceMotion) {
      _entranceController.value = 1;
      _floatController.stop();
      _pulseController.stop();
      return;
    }
    if (widget.isActive && !oldWidget.isActive) {
      _play();
    }
  }

  void _play() {
    if (widget.reduceMotion) {
      _entranceController.value = 1;
      return;
    }
    _entranceController.forward(from: 0);
    if (!_floatController.isAnimating) {
      _floatController.repeat();
    }
    if (!_pulseController.isAnimating) {
      _pulseController.repeat();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 400;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _entranceController,
                _floatController,
                _pulseController,
              ]),
              builder: (context, _) {
                return FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: 320,
                    height: 320,
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _entranceController,
                        curve: const Interval(0, 0.35, curve: Curves.easeOut),
                      ),
                      child: CommunityPreview(
                        entrance: _entranceController.value,
                        float: _floatController.value,
                        pulse: _pulseController.value,
                        reduceMotion: widget.reduceMotion,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        FadeTransition(
          opacity: CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _entranceController,
                curve: const Interval(0.35, 0.8, curve: Curves.easeOutCubic),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Be the Eyes of the Community',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: wide ? 24 : 22,
                    height: wide ? 32 / 24 : 28 / 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Report elevator outages and ramp issues to help fellow travelers. Earn badges for your contributions!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 24 / 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
