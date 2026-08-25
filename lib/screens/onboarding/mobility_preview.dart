import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Square illustration of diverse mobility needs for onboarding step 1.
class MobilityPreview extends StatelessWidget {
  const MobilityPreview({
    super.key,
    required this.entrance,
    required this.float,
    required this.orbit,
    required this.reduceMotion,
  });

  final double entrance;
  final double float;
  final double orbit;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceVariant),
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
                painter: _MobilityBackdropPainter(
                  progress: entrance,
                  orbit: orbit,
                ),
              ),
              _node(
                alignment: const Alignment(-0.55, 0.18),
                icon: Icons.accessible_rounded,
                background: AppColors.primaryContainer,
                foreground: AppColors.onPrimary,
                size: 76,
                delay: 0.08,
                floatPhase: 0,
              ),
              _node(
                alignment: const Alignment(0.02, -0.5),
                icon: Icons.elderly,
                background: AppColors.surfaceBright,
                foreground: AppColors.primary,
                size: 64,
                delay: 0.18,
                floatPhase: 0.45,
                outlined: true,
              ),
              _node(
                alignment: const Alignment(0.56, 0.1),
                icon: Icons.blind,
                background: AppColors.secondaryContainer,
                foreground: AppColors.onSecondaryContainer,
                size: 70,
                delay: 0.28,
                floatPhase: 0.7,
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _chips(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _node({
    required Alignment alignment,
    required IconData icon,
    required Color background,
    required Color foreground,
    required double size,
    required double delay,
    required double floatPhase,
    bool outlined = false,
  }) {
    final t = ((entrance - delay) / (1 - delay)).clamp(0.0, 1.0);
    final scale = reduceMotion ? 1.0 : Curves.easeOutBack.transform(t);
    final opacity = reduceMotion ? 1.0 : Curves.easeOut.transform(t);
    final bob = reduceMotion
        ? 0.0
        : math.sin((float + floatPhase) * math.pi * 2) * 6;

    return Align(
      alignment: alignment,
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(0, bob),
          child: Transform.scale(
            scale: scale,
            child: _MobilityNode(
              icon: icon,
              background: background,
              foreground: foreground,
              size: size,
              outlined: outlined,
            ),
          ),
        ),
      ),
    );
  }

  Widget _chips() {
    final t = Curves.easeOutCubic.transform(
      ((entrance - 0.45) / 0.55).clamp(0.0, 1.0),
    );

    return Opacity(
      opacity: reduceMotion ? 1 : t,
      child: Transform.translate(
        offset: Offset(0, reduceMotion ? 0 : (1 - t) * 12),
        child: const Row(
          children: [
            _PreferenceChip(label: 'Ramps', icon: Icons.accessible_rounded),
            SizedBox(width: 8),
            _PreferenceChip(
              label: 'Low-floor',
              icon: Icons.directions_bus_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _MobilityNode extends StatelessWidget {
  const _MobilityNode({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.size,
    this.outlined = false,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: outlined
            ? Border.all(color: AppColors.primaryFixedDim, width: 2)
            : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: foreground, size: size * 0.46),
    );
  }
}

class _PreferenceChip extends StatelessWidget {
  const _PreferenceChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobilityBackdropPainter extends CustomPainter {
  _MobilityBackdropPainter({
    required this.progress,
    required this.orbit,
  });

  final double progress;
  final double orbit;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.44);
    final shortest = math.min(size.width, size.height);

    canvas.drawCircle(
      center,
      shortest * 0.38,
      Paint()
        ..color = AppColors.primaryFixed.withValues(alpha: 0.28 * progress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );

    final ring = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.18 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(orbit * math.pi * 2);
    canvas.translate(-center.dx, -center.dy);

    const dashes = 18;
    final rect = Rect.fromCircle(center: center, radius: shortest * 0.28);
    for (var i = 0; i < dashes; i++) {
      final start = (i / dashes) * math.pi * 2;
      canvas.drawArc(rect, start, 0.12, false, ring);
    }
    canvas.restore();

    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.58)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.22,
        size.width * 0.78,
        size.height * 0.52,
      );

    final metric = path.computeMetrics().first;
    final visible = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(
      visible,
      Paint()
        ..color = const Color(0xFF335F99).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MobilityBackdropPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.orbit != orbit;
  }
}
