import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../auth/login_screen.dart';
import 'transit_preview.dart';

/// First onboarding step: live transit updates and boarding assistance.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const int stepCount = 3;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  static const _staggerDelay = 0.08;

  late final AnimationController _entranceController;
  late final AnimationController _routeController;
  late final AnimationController _pulseController;
  late final AnimationController _buttonScaleController;

  late final Animation<double> _buttonScale;
  late final Animation<double> _checkScale;

  bool _prefersReducedMotion = false;

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
    _buttonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _buttonScale = Tween<double>(begin: 1, end: 0.98).animate(
      CurvedAnimation(
        parent: _buttonScaleController,
        curve: Curves.easeInOut,
      ),
    );
    _checkScale = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.48, 0.82, curve: Curves.elasticOut),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    if (!mounted) return;

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      setState(() => _prefersReducedMotion = true);
      _entranceController.value = 1;
      _routeController.value = 0.55;
      return;
    }

    _entranceController.forward();
    _pulseController.repeat(reverse: true);
    _routeController.repeat();
  }

  Animation<double> _fade(int index) {
    final start = index * _staggerDelay;
    final end = (start + 0.42).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  Animation<Offset> _slide(int index, {Offset begin = const Offset(0, 0.12)}) {
    return Tween<Offset>(begin: begin, end: Offset.zero).animate(_fade(index));
  }

  Widget _staggered(
    int index,
    Widget child, {
    Offset begin = const Offset(0, 0.12),
  }) {
    return FadeTransition(
      opacity: _fade(index),
      child: SlideTransition(position: _slide(index, begin: begin), child: child),
    );
  }

  void _finish() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) {
          return const LoginScreen();
        },
        transitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _onNext() {
    _finish();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _routeController.dispose();
    _pulseController.dispose();
    _buttonScaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.surfaceBright,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surfaceBright,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                      child: Column(
                        children: [
                          Flexible(
                            child: _staggered(
                              1,
                              FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: 400,
                                  height: 300,
                                  child: _buildPreview(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          _staggered(4, _buildCopy()),
                          const Spacer(),
                          _staggered(6, _buildProgress()),
                          const SizedBox(height: 16),
                          _staggered(7, _buildNextButton()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _staggered(
              0,
              const Row(
                children: [
                  Icon(
                    Icons.accessible_forward_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Access Transit',
                    style: TextStyle(
                      fontSize: 18,
                      height: 24 / 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            _staggered(
              0,
              Tooltip(
                message: 'Skip onboarding',
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.onSurfaceVariant,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                  child: const Text('Skip'),
                ),
              ),
              begin: const Offset(0.08, 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _routeController,
        _pulseController,
        _entranceController,
      ]),
      builder: (context, _) {
        final routeProgress = _prefersReducedMotion
            ? 0.55
            : _routeController.value;
        final drawProgress = _prefersReducedMotion
            ? 1.0
            : CurvedAnimation(
                parent: _entranceController,
                curve: const Interval(0.05, 0.72, curve: Curves.easeInOutCubic),
              ).value;
        final pulse = _prefersReducedMotion ? 0.4 : _pulseController.value;

        return TransitPreview(
          routeProgress: routeProgress,
          drawProgress: drawProgress,
          pulse: pulse,
          busPill: _staggered(
            2,
            OnboardingBusPill(pulse: pulse),
            begin: const Offset(-0.12, 0),
          ),
          assistanceCard: _staggered(
            3,
            OnboardingAssistanceCard(checkScale: _checkScale.value),
            begin: const Offset(0, 0.18),
          ),
        );
      },
    );
  }

  Widget _buildCopy() {
    final wide = MediaQuery.sizeOf(context).width >= 400;
    return Column(
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
    );
  }

  Widget _buildProgress() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(OnboardingScreen.stepCount, (index) {
        final isActive = index == 0;
        return AnimatedContainer(
          duration: _prefersReducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          width: isActive ? 32 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }

  Widget _buildNextButton() {
    return ScaleTransition(
      scale: _buttonScale,
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: Listener(
          onPointerDown: (_) => _buttonScaleController.forward(),
          onPointerUp: (_) => _buttonScaleController.reverse(),
          onPointerCancel: (_) => _buttonScaleController.reverse(),
          child: FilledButton(
            onPressed: _onNext,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimary,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Next'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
