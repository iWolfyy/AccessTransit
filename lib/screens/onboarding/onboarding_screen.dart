import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../auth/login_screen.dart';
import 'navigate_with_confidence_page.dart';
import 'tailored_for_you_page.dart';

/// Multi-step onboarding shown after splash for signed-out users.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const int stepCount = 3;
  static const int pageCount = 2;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _buttonScaleController;
  late final Animation<double> _buttonScale;

  int _index = 0;
  bool _prefersReducedMotion = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _buttonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _buttonScale = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonScaleController,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      if (reduceMotion) {
        setState(() => _prefersReducedMotion = true);
      }
    });
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

  Future<void> _onNext() async {
    if (_index < OnboardingScreen.pageCount - 1) {
      await _pageController.nextPage(
        duration: _prefersReducedMotion
            ? Duration.zero
            : const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _finish();
  }

  @override
  void dispose() {
    _pageController.dispose();
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
                          Expanded(
                            child: PageView(
                              controller: _pageController,
                              physics: const BouncingScrollPhysics(),
                              onPageChanged: (index) {
                                setState(() => _index = index);
                              },
                              children: [
                                TailoredForYouPage(
                                  isActive: _index == 0,
                                  reduceMotion: _prefersReducedMotion,
                                ),
                                NavigateWithConfidencePage(
                                  isActive: _index == 1,
                                  reduceMotion: _prefersReducedMotion,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildProgress(),
                          const SizedBox(height: 24),
                          _buildNextButton(),
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
            const Icon(
              Icons.blind,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 4),
            const Text(
              'Access Transit',
              style: TextStyle(
                fontSize: 18,
                height: 24 / 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const Spacer(),
            Tooltip(
              message: 'Skip onboarding',
              child: TextButton(
                onPressed: _finish,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
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
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(OnboardingScreen.stepCount, (index) {
        final isActive = index == _index;
        return AnimatedContainer(
          duration: _prefersReducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          width: isActive ? 32 : 8,
          height: 8,
          margin: EdgeInsets.only(
            right: index == OnboardingScreen.stepCount - 1 ? 0 : 4,
          ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
            child: const Text('Next'),
          ),
        ),
      ),
    );
  }
}
