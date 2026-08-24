import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

/// Branded launch screen shown while the app settles and auth state is resolved.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();

  late final AnimationController _entranceController;
  late final AnimationController _pulseController;
  late final AnimationController _orbitController;
  late final AnimationController _rippleController;
  late final AnimationController _dotsController;
  late final AnimationController _orbController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _dotsOpacity;

  bool _prefersReducedMotion = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );

    _logoScale = Tween<double>(begin: 0.55, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );
    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.28, 0.72, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.28, 0.72, curve: Curves.easeOutCubic),
      ),
    );
    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.42, 0.88, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.32),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.42, 0.88, curve: Curves.easeOutCubic),
      ),
    );
    _dotsOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.62, 1, curve: Curves.easeOut),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _runSplash());
  }

  Future<void> _runSplash() async {
    if (!mounted) return;

    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (reduceMotion) {
      setState(() => _prefersReducedMotion = true);
      _entranceController.value = 1;
      await Future<void>.delayed(const Duration(milliseconds: 700));
    } else {
      _pulseController.repeat(reverse: true);
      _orbitController.repeat();
      _rippleController.repeat();
      _dotsController.repeat();
      _orbController.repeat(reverse: true);
      await _entranceController.forward();
      await Future<void>.delayed(const Duration(milliseconds: 1400));
    }

    if (!mounted) return;
    _goNext();
  }

  void _goNext() {
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) {
      return;
    }

    final next = _authService.currentUser != null
        ? const HomeScreen()
        : const LoginScreen();

    Navigator.of(context).pushReplacement(_fadeRoute(next));
  }

  PageRouteBuilder<void> _fadeRoute(Widget page) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 520),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _orbitController.dispose();
    _rippleController.dispose();
    _dotsController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.primaryContainer,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primaryContainer,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _SplashBackdrop(),
            _AmbientOrbs(controller: _orbController),
            SafeArea(
              child: Semantics(
                label:
                    'Access Transit. Your journey to inclusive travel begins here. Loading.',
                child: Column(
                  children: [
                    Expanded(child: Center(child: _buildBrandBlock())),
                    FadeTransition(
                      opacity: _dotsOpacity,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: _LoadingDots(
                          controller: _dotsController,
                          animate: !_prefersReducedMotion,
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

  Widget _buildBrandBlock() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 448),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLogo(),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _titleOpacity,
              child: SlideTransition(
                position: _titleSlide,
                child: const Text(
                  'Access Transit',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    height: 40 / 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.64,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: _taglineOpacity,
              child: SlideTransition(
                position: _taglineSlide,
                child: const Text(
                  'Your journey to inclusive travel begins here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 24 / 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryFixedDim,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return FadeTransition(
      opacity: _logoOpacity,
      child: ScaleTransition(
        scale: _logoScale,
        child: SizedBox(
          width: 176,
          height: 176,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _pulseController,
              _orbitController,
              _rippleController,
            ]),
            builder: (context, child) {
              final pulse = 0.55 + (_pulseController.value * 0.45);
              return Stack(
                alignment: Alignment.center,
                children: [
                  _RippleRing(progress: _rippleController.value, delay: 0),
                  _RippleRing(progress: _rippleController.value, delay: 0.5),
                  CustomPaint(
                    size: const Size(168, 168),
                    painter: _DashedRingPainter(
                      progress: _orbitController.value,
                      color: AppColors.primaryFixed.withValues(alpha: 0.55),
                    ),
                  ),
                  Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryFixed.withValues(
                            alpha: 0.18 * pulse,
                          ),
                          blurRadius: 28 + (12 * pulse),
                          spreadRadius: 2 + (6 * pulse),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ],
              );
            },
            child: const Hero(
              tag: 'access-transit-logo',
              child: Material(
                color: Colors.transparent,
                child: _GlassLogo(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF245A9A),
                AppColors.primaryContainer,
                AppColors.primary,
              ],
              stops: [0, 0.45, 1],
            ),
          ),
        ),
        CustomPaint(painter: _TransitPathPainter()),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.12),
              radius: 0.85,
              colors: [
                Color(0x332B6CB0),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AmbientOrbs extends StatelessWidget {
  const _AmbientOrbs({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return IgnorePointer(
          child: Stack(
            children: [
              _orb(
                alignment: Alignment(-1.05 + (0.08 * t), -0.72 + (0.06 * t)),
                size: 220,
                color: const Color(0xFF4C8AD4).withValues(alpha: 0.18),
              ),
              _orb(
                alignment: Alignment(1.1 - (0.1 * t), -0.2 - (0.08 * t)),
                size: 180,
                color: AppColors.secondary.withValues(alpha: 0.14),
              ),
              _orb(
                alignment: Alignment(-0.95 + (0.06 * t), 0.85 - (0.05 * t)),
                size: 160,
                color: AppColors.primaryFixed.withValues(alpha: 0.10),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _orb({
    required Alignment alignment,
    required double size,
    required Color color,
  }) {
    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

class _GlassLogo extends StatelessWidget {
  const _GlassLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      height: 128,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.accessible_forward_rounded,
                size: 64,
                color: AppColors.primaryFixed,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RippleRing extends StatelessWidget {
  const _RippleRing({required this.progress, required this.delay});

  final double progress;
  final double delay;

  @override
  Widget build(BuildContext context) {
    final t = (progress + delay) % 1.0;
    final scale = 0.72 + (t * 0.55);
    final opacity = (1 - t) * 0.28;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 128,
        height: 128,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primaryFixed.withValues(alpha: opacity),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  _DashedRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    const dashCount = 14;
    const sweep = (2 * math.pi) / dashCount;
    final start = progress * 2 * math.pi;

    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(rect, start + (i * sweep), sweep * 0.42, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _TransitPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final pathA = Path()
      ..moveTo(-24, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.38,
        size.height * 0.08,
        size.width + 32,
        size.height * 0.32,
      );

    final pathB = Path()
      ..moveTo(-16, size.height * 0.78)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.62,
        size.width * 0.62,
        size.height * 0.92,
        size.width + 20,
        size.height * 0.68,
      );

    canvas.drawPath(pathA, paint);
    canvas.drawPath(pathB, paint);

    final nodePaint = Paint()..color = Colors.white.withValues(alpha: 0.14);
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.18), 3.5, nodePaint);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.76), 3.5, nodePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({
    required this.controller,
    required this.animate,
  });

  final AnimationController controller;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final delay = (2 - index) * 0.16;
          final alpha = index == 0 ? 1.0 : index == 1 ? 0.5 : 0.3;

          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final scale = animate ? _dotScale((controller.value + delay) % 1.0) : 1.0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Transform.scale(scale: scale, child: child),
              );
            },
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryFixed.withValues(alpha: alpha),
              ),
            ),
          );
        }),
      ),
    );
  }

  double _dotScale(double t) {
    if (t <= 0.4) {
      return Curves.easeInOut.transform(t / 0.4);
    }
    if (t <= 0.8) {
      return 1 - Curves.easeInOut.transform((t - 0.4) / 0.4);
    }
    return 0;
  }
}
