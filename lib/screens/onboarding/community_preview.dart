import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Community-reporting illustration for onboarding step 3.
class CommunityPreview extends StatelessWidget {
  const CommunityPreview({
    super.key,
    required this.entrance,
    required this.float,
    required this.pulse,
    required this.reduceMotion,
  });

  final double entrance;
  final double float;
  final double pulse;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final forumT = _interval(0, 0.45);
    final pillT = _interval(0.28, 0.72);
    final badgeT = _interval(0.42, 0.9);

    final forumScale = reduceMotion
        ? 1.0
        : Curves.easeOutBack.transform(forumT);
    final bob = reduceMotion ? 0.0 : math.sin(float * math.pi * 2) * 5;
    final badgeWobble = reduceMotion
        ? 0.21
        : 0.21 + math.sin((float + 0.35) * math.pi * 2) * 0.04;

    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryFixed,
                        AppColors.surfaceBright,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: ColoredBox(
                  color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _RipplePainter(progress: pulse, opacity: forumT),
                ),
              ),
              Align(
                alignment: const Alignment(0, -0.18),
                child: Opacity(
                  opacity: forumT,
                  child: Transform.translate(
                    offset: Offset(0, bob - 8),
                    child: Transform.scale(
                      scale: forumScale,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryContainer.withValues(
                                alpha: 0.28 + pulse * 0.18,
                              ),
                              blurRadius: 18 + pulse * 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.forum_rounded,
                          color: AppColors.onPrimary,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(0, 0.38),
                child: Opacity(
                  opacity: pillT,
                  child: Transform.translate(
                    offset: Offset(0, reduceMotion ? 0 : (1 - pillT) * 18),
                    child: const _ReportPill(),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 28,
                child: Opacity(
                  opacity: badgeT,
                  child: Transform.rotate(
                    angle: badgeWobble,
                    child: Transform.scale(
                      scale: reduceMotion
                          ? 1
                          : Curves.easeOutBack.transform(badgeT),
                      child: const _ContributionBadge(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _interval(double start, double end) {
    if (reduceMotion) return 1;
    if (end <= start) return 1;
    return ((entrance - start) / (end - start)).clamp(0.0, 1.0);
  }
}

class _ReportPill extends StatelessWidget {
  const _ReportPill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceBright,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.report, color: AppColors.error, size: 22),
            SizedBox(width: 6),
            Text(
              'Report Issue',
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContributionBadge extends StatelessWidget {
  const _ContributionBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surfaceBright, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.military_tech,
        color: AppColors.onTertiaryContainer,
        size: 22,
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.progress, required this.opacity});

  final double progress;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    for (var i = 0; i < 2; i++) {
      final t = (progress + i * 0.5) % 1.0;
      final radius = 36 + t * 70;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = AppColors.primaryContainer.withValues(
            alpha: (1 - t) * 0.16 * opacity,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.opacity != opacity;
  }
}
