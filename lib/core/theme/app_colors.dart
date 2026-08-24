import 'package:flutter/material.dart';

/// AccessTransit design tokens from the UI specification.
abstract final class AppColors {
  static const Color primary = Color(0xFF003466);
  static const Color primaryContainer = Color(0xFF1A4B84);
  static const Color primaryFixed = Color(0xFFD5E3FF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF93BCFC);

  static const Color surfaceBright = Color(0xFFFDF8FD);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFF1ECF2);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color onSurfaceVariant = Color(0xFF424750);

  static const Color outline = Color(0xFF737781);
  static const Color outlineVariant = Color(0xFFC3C6D1);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);

  static const Color secondary = Color(0xFF006A63);
  static const Color tertiary = Color(0xFF592400);
}
