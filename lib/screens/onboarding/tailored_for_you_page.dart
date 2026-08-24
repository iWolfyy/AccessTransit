import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'mobility_preview.dart';

/// Onboarding step 1: accessibility preferences.
class TailoredForYouPage extends StatefulWidget {
  const TailoredForYouPage({
    super.key,
    required this.isActive,
    required this.reduceMotion,
  });

  final bool isActive;
  final bool reduceMotion;

  @override
  State<TailoredForYouPage> createState() => _TailoredForYouPageState();
}

class _TailoredForYouPageState extends State<TailoredForYouPage>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _floatController;
  late final AnimationController _orbitController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    if (widget.isActive) {
      _play();
    }
  }

  @override
  void didUpdateWidget(covariant TailoredForYouPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion && !oldWidget.reduceMotion) {
      _entranceController.value = 1;
      _floatController.stop();
      _orbitController.stop();
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
    if (!_orbitController.isAnimating) {
      _orbitController.repeat();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    _orbitController.dispose();
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
                _orbitController,
              ]),
              builder: (context, _) {
                return FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: 360,
                    height: 360,
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _entranceController,
                        curve: const Interval(0, 0.4, curve: Curves.easeOut),
                      ),
                      child: MobilityPreview(
                        entrance: _entranceController.value,
                        float: _floatController.value,
                        orbit: _orbitController.value,
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
                  'Tailored for You',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: wide ? 32 : 22,
                    height: wide ? 40 / 32 : 28 / 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: wide ? -0.64 : 0,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                const ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 320),
                  child: Text(
                    'Set your accessibility preferences to find the best routes for your specific needs, from wheelchair ramps to low-floor buses.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 24 / 16,
                      color: AppColors.onSurfaceVariant,
                    ),
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
