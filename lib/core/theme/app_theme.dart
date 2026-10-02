import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Central theme configuration supporting standard and high contrast (WCAG AAA) themes.
class AppTheme {
  const AppTheme._();

  /// Standard application theme with brand styling.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        surface: AppColors.surfaceBright,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.surfaceBright,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
        ),
      ),
    );
  }

  /// High Contrast Theme adhering to WCAG 2.2 AA/AAA guidelines.
  ///
  /// Guarantees:
  /// - Minimum 7:1 contrast ratio for normal text against surfaces.
  /// - Pure white background (#FFFFFF) with solid black text (#000000).
  /// - 2px dark outlines on interactive widgets for clear visual boundaries.
  /// - High visibility focus and switch controls.
  static ThemeData get highContrastTheme {
    const highContrastText = Color(0xFF000000);
    const highContrastSurface = Color(0xFFFFFFFF);
    const highContrastPrimary = Color(0xFF001F3F); // High visibility navy
    const highContrastOutline = Color(0xFF000000);

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: highContrastPrimary,
        onPrimary: Colors.white,
        secondary: Color(0xFF003833),
        onSecondary: Colors.white,
        error: Color(0xFF8B0000), // Dark pure red
        onError: Colors.white,
        surface: highContrastSurface,
        onSurface: highContrastText,
        onSurfaceVariant: Color(0xFF1A1A1A),
        outline: highContrastOutline,
        outlineVariant: Color(0xFF333333),
      ),
      scaffoldBackgroundColor: highContrastSurface,
      dividerTheme: const DividerThemeData(
        color: highContrastOutline,
        thickness: 1.5,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: highContrastSurface,
        foregroundColor: highContrastText,
        elevation: 1,
        iconTheme: IconThemeData(color: highContrastText, size: 26),
        titleTextStyle: TextStyle(
          color: highContrastText,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return highContrastText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return highContrastPrimary;
          }
          return const Color(0xFFE5E5E5);
        }),
        trackOutlineColor: const WidgetStatePropertyAll(highContrastOutline),
        trackOutlineWidth: const WidgetStatePropertyAll(2.0),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: highContrastPrimary,
          foregroundColor: Colors.white,
          side: const BorderSide(color: highContrastOutline, width: 2),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: highContrastText,
          side: const BorderSide(color: highContrastOutline, width: 2),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
