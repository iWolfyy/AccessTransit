import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:access_transit/core/theme/app_colors.dart';
import 'package:access_transit/core/theme/app_theme.dart';

/// Helper to compute contrast ratio according to WCAG 2.2 formula:
/// (L1 + 0.05) / (L2 + 0.05) where L1 is the relative luminance of the lighter color.
double contrastRatio(Color foreground, Color background) {
  final l1 = foreground.computeLuminance();
  final l2 = background.computeLuminance();
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('WCAG 2.2 Level AA - Color Contrast Requirements (>= 4.5:1)', () {
    const whiteSurface = Color(0xFFFFFFFF);
    const standardSurface = AppColors.surface; // #FDF8FD

    test('Primary on White / Standard Surface exceeds 4.5:1', () {
      final ratioWhite = contrastRatio(AppColors.primary, whiteSurface);
      final ratioSurface = contrastRatio(AppColors.primary, standardSurface);

      expect(ratioWhite, greaterThanOrEqualTo(4.5),
          reason: 'AppColors.primary must have >= 4.5:1 contrast against white');
      expect(ratioSurface, greaterThanOrEqualTo(4.5),
          reason: 'AppColors.primary must have >= 4.5:1 contrast against surface');
    });

    test('onPrimary on Primary Container exceeds 4.5:1 (WCAG AA)', () {
      final ratio = contrastRatio(AppColors.onPrimary, AppColors.primaryContainer);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Text on primaryContainer must exceed 4.5:1');
      // In fact, white on #1A4B84 provides 8.81:1 (WCAG AAA)
      expect(ratio, greaterThanOrEqualTo(7.0));
    });

    test('onSurface and onSurfaceVariant on Surface exceed 4.5:1', () {
      final ratioOnSurface = contrastRatio(AppColors.onSurface, whiteSurface);
      final ratioOnSurfaceVariant = contrastRatio(AppColors.onSurfaceVariant, whiteSurface);

      expect(ratioOnSurface, greaterThanOrEqualTo(7.0),
          reason: 'AppColors.onSurface provides AAA contrast');
      expect(ratioOnSurfaceVariant, greaterThanOrEqualTo(4.5),
          reason: 'AppColors.onSurfaceVariant must provide AA contrast (>= 4.5:1)');
    });

    test('Outline token on White meets AA requirements (>= 4.5:1)', () {
      final ratio = contrastRatio(AppColors.outline, whiteSurface);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'AppColors.outline used for text or borders must exceed 4.5:1');
    });

    test('Success token on White and Light Green Chip meets AA requirements (>= 4.5:1)', () {
      final ratioWhite = contrastRatio(AppColors.success, whiteSurface);
      const lightGreenBg = Color(0xFFE8F5E9);
      final ratioChip = contrastRatio(AppColors.success, lightGreenBg);

      expect(ratioWhite, greaterThanOrEqualTo(4.5),
          reason: 'AppColors.success on white must exceed 4.5:1');
      expect(ratioChip, greaterThanOrEqualTo(4.5),
          reason: 'AppColors.success on light green chip must exceed 4.5:1');
    });

    test('Error token on White meets AA requirements (>= 4.5:1)', () {
      final ratio = contrastRatio(AppColors.error, whiteSurface);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'AppColors.error on white must exceed 4.5:1');
    });

    test('Secondary token on White meets AA requirements (>= 4.5:1)', () {
      final ratio = contrastRatio(AppColors.secondary, whiteSurface);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'AppColors.secondary on white must exceed 4.5:1');
    });

    test('Bottom Navigation Bar selected tab pill meets AAA requirements (>= 7:1)', () {
      // Bottom nav selected tab uses AppColors.onPrimary (white) on AppColors.primaryContainer (#1A4B84)
      final ratio = contrastRatio(AppColors.onPrimary, AppColors.primaryContainer);
      expect(ratio, greaterThanOrEqualTo(7.0),
          reason: 'Selected bottom nav icon & label must exceed 7:1 (AAA) on primaryContainer');
    });

    test('Status Pills text against badge backgrounds meet AA requirements (>= 4.5:1)', () {
      // Ongoing: Green badge
      const ongoingFg = Color(0xFF1B5E20);
      const ongoingBg = Color(0xFFE8F5E9);
      expect(contrastRatio(ongoingFg, ongoingBg), greaterThanOrEqualTo(4.5));

      // Approaching: Blue badge
      const approachingFg = Color(0xFF0D47A1);
      const approachingBg = Color(0xFFE3F2FD);
      expect(contrastRatio(approachingFg, approachingBg), greaterThanOrEqualTo(4.5));

      // Delayed: Red badge
      const delayedFg = Color(0xFFB71C1C);
      const delayedBg = Color(0xFFFFEBEE);
      expect(contrastRatio(delayedFg, delayedBg), greaterThanOrEqualTo(4.5));
    });

    test('High Contrast Theme (WCAG AAA) guarantees >= 7:1 text contrast', () {
      final hcTheme = AppTheme.highContrastTheme;
      final ratio = contrastRatio(
        hcTheme.colorScheme.onSurface,
        hcTheme.colorScheme.surface,
      );

      // Pure black on pure white gives 21:1
      expect(ratio, greaterThanOrEqualTo(7.0),
          reason: 'High Contrast Theme text must provide AAA contrast (>= 7:1)');
      expect(ratio, greaterThanOrEqualTo(20.0));
    });
  });
}
