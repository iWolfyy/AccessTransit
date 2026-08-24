import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Stylized live-map preview used on the first onboarding screen.
class TransitPreview extends StatelessWidget {
  const TransitPreview({
    super.key,
    required this.routeProgress,
    required this.drawProgress,
    required this.pulse,
    this.busPill,
    this.assistanceCard,
  });

  final double routeProgress;
  final double drawProgress;
  final double pulse;
  final Widget? busPill;
  final Widget? assistanceCard;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _CityMapPainter(
                  routeProgress: routeProgress,
                  drawProgress: drawProgress,
                  pulse: pulse,
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00F7F2F8),
                      Color(0xE6F7F2F8),
                    ],
                    stops: [0.42, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ?busPill,
                    const SizedBox(height: 8),
                    ?assistanceCard,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingBusPill extends StatelessWidget {
  const OnboardingBusPill({super.key, required this.pulse});

  final double pulse;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primaryFixedDim),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_bus_rounded,
              color: AppColors.onPrimary,
              size: 20,
            ),
            const SizedBox(width: 10),
            const Text(
              'Approaching: 3 mins',
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                color: AppColors.onPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondaryContainer,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryContainer.withValues(
                      alpha: 0.35 + (pulse * 0.45),
                    ),
                    blurRadius: 6 + (pulse * 6),
                    spreadRadius: pulse * 2,
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

class OnboardingAssistanceCard extends StatelessWidget {
  const OnboardingAssistanceCard({super.key, required this.checkScale});

  final double checkScale;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceBright,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.accessibility_new_rounded,
                color: AppColors.onSecondaryContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Boarding Help',
                    style: TextStyle(
                      fontSize: 18,
                      height: 24 / 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    'Driver notified',
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: checkScale,
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.secondary,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityMapPainter extends CustomPainter {
  _CityMapPainter({
    required this.routeProgress,
    required this.drawProgress,
    required this.pulse,
  });

  final double routeProgress;
  final double drawProgress;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.surfaceContainerLow,
    );

    _drawPark(canvas, Rect.fromLTWH(w * 0.58, h * 0.08, w * 0.34, h * 0.22));
    _drawPark(canvas, Rect.fromLTWH(w * 0.06, h * 0.62, w * 0.22, h * 0.18));

    const buildings = <List<double>>[
      [0.06, 0.08, 0.26, 0.20],
      [0.36, 0.06, 0.18, 0.16],
      [0.08, 0.34, 0.16, 0.20],
      [0.28, 0.32, 0.22, 0.18],
      [0.54, 0.36, 0.18, 0.16],
      [0.76, 0.34, 0.16, 0.22],
      [0.34, 0.58, 0.20, 0.18],
      [0.58, 0.56, 0.16, 0.20],
      [0.78, 0.64, 0.14, 0.16],
    ];

    for (final b in buildings) {
      _drawBuilding(
        canvas,
        Rect.fromLTWH(w * b[0], h * b[1], w * b[2], h * b[3]),
      );
    }

    final route = _routePath(size);
    final metric = route.computeMetrics().first;
    final visible = metric.extractPath(0, metric.length * drawProgress);

    final glow = Paint()
      ..color = AppColors.primaryFixedDim.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final line = Paint()
      ..color = const Color(0xFF335F99)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(visible, glow);
    canvas.drawPath(visible, line);

    _drawStops(canvas, metric, drawProgress);

    if (drawProgress > 0.12) {
      _drawBus(canvas, metric, routeProgress.clamp(0.0, 1.0));
    }
  }

  Path _routePath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.08, h * 0.30)
      ..cubicTo(w * 0.22, h * 0.30, w * 0.24, h * 0.52, w * 0.42, h * 0.52)
      ..cubicTo(w * 0.62, h * 0.52, w * 0.60, h * 0.28, w * 0.78, h * 0.28)
      ..cubicTo(w * 0.92, h * 0.28, w * 0.88, h * 0.72, w * 0.70, h * 0.78);
  }

  void _drawBuilding(Canvas canvas, Rect rect) {
    final shadow = rect.shift(const Offset(2, 3));
    canvas.drawRRect(
      RRect.fromRectAndRadius(shadow, const Radius.circular(6)),
      Paint()..color = const Color(0x14000000),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..color = AppColors.surfaceVariant,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + 4, rect.top + 4, rect.width - 8, 5),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  void _drawPark(Canvas canvas, Rect rect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()..color = AppColors.secondaryContainer.withValues(alpha: 0.35),
    );
  }

  void _drawStops(Canvas canvas, PathMetric metric, double progress) {
    const stops = [0.08, 0.38, 0.68, 0.96];
    for (final stop in stops) {
      if (progress < stop) continue;
      final tangent = metric.getTangentForOffset(metric.length * stop);
      if (tangent == null) continue;
      canvas.drawCircle(
        tangent.position,
        4.5,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        tangent.position,
        3,
        Paint()..color = AppColors.primaryContainer,
      );
    }
  }

  void _drawBus(Canvas canvas, PathMetric metric, double progress) {
    final t = 0.06 + (progress * 0.88);
    final tangent = metric.getTangentForOffset(metric.length * t);
    if (tangent == null) return;

    canvas.save();
    canvas.translate(tangent.position.dx, tangent.position.dy);
    canvas.rotate(tangent.angle);

    final halo = 10 + (pulse * 4);
    canvas.drawCircle(
      Offset.zero,
      halo,
      Paint()
        ..color = AppColors.primaryFixedDim.withValues(alpha: 0.28 + pulse * 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-11, -7, 22, 14),
      const Radius.circular(4),
    );
    canvas.drawRRect(body, Paint()..color = AppColors.primaryContainer);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-4, -5, 10, 10),
        const Radius.circular(2),
      ),
      Paint()..color = AppColors.primaryFixed,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CityMapPainter oldDelegate) {
    return oldDelegate.routeProgress != routeProgress ||
        oldDelegate.drawProgress != drawProgress ||
        oldDelegate.pulse != pulse;
  }
}
