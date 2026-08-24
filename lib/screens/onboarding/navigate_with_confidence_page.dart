import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'transit_preview.dart';

/// Onboarding step 2: live updates and boarding assistance.
class NavigateWithConfidencePage extends StatefulWidget {
  const NavigateWithConfidencePage({
    super.key,
    required this.isActive,
    required this.reduceMotion,
  });

  final bool isActive;
  final bool reduceMotion;

  @override
  State<NavigateWithConfidencePage> createState() =>
      _NavigateWithConfidencePageState();
}

class _NavigateWithConfidencePageState extends State<NavigateWithConfidencePage>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _routeController;
  late final AnimationController _pulseController;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _routeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _checkScale = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.48, 0.82, curve: Curves.elasticOut),
      ),
    );

    if (widget.isActive) {
      _play();
    }
  }

  @override
  void didUpdateWidget(covariant NavigateWithConfidencePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion && !oldWidget.reduceMotion) {
      _entranceController.value = 1;
      _routeController.value = 0.55;
      _pulseController.stop();
      _routeController.stop();
      return;
    }
    if (widget.isActive && !oldWidget.isActive) {
      _play();
    }
  }

  void _play() {
    if (widget.reduceMotion) {
      _entranceController.value = 1;
      _routeController.value = 0.55;
      return;
    }
    _entranceController.forward(from: 0);
    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
    if (!_routeController.isAnimating) {
      _routeController.repeat();
    }
  }

  Animation<double> _fade(double start, double end) {
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _routeController.dispose();
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
            child: FadeTransition(
              opacity: _fade(0, 0.4),
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _routeController,
                  _pulseController,
                  _entranceController,
                ]),
                builder: (context, _) {
                  final routeProgress = widget.reduceMotion
                      ? 0.55
                      : _routeController.value;
                  final drawProgress = widget.reduceMotion
                      ? 1.0
                      : CurvedAnimation(
                          parent: _entranceController,
                          curve: const Interval(
                            0.05,
                            0.72,
                            curve: Curves.easeInOutCubic,
                          ),
                        ).value;
                  final pulse =
                      widget.reduceMotion ? 0.4 : _pulseController.value;

                  return FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: 400,
                      height: 300,
                      child: TransitPreview(
                        routeProgress: routeProgress,
                        drawProgress: drawProgress,
                        pulse: pulse,
                        busPill: FadeTransition(
                          opacity: _fade(0.16, 0.58),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(-0.12, 0),
                              end: Offset.zero,
                            ).animate(_fade(0.16, 0.58)),
                            child: OnboardingBusPill(pulse: pulse),
                          ),
                        ),
                        assistanceCard: FadeTransition(
                          opacity: _fade(0.24, 0.7),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.18),
                              end: Offset.zero,
                            ).animate(_fade(0.24, 0.7)),
                            child: OnboardingAssistanceCard(
                              checkScale: _checkScale.value,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FadeTransition(
          opacity: _fade(0.35, 0.8),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(_fade(0.35, 0.8)),
            child: Column(
              children: [
                Text(
                  'Navigate with Confidence',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: wide ? 24 : 22,
                    height: wide ? 32 / 24 : 28 / 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Get real-time updates and request boarding assistance directly from the app for a stress-free journey.',
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
