import 'package:flutter/material.dart';

import '../../services/accessibility_preferences_service.dart';
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
            inherit: false,
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
            inherit: false,
          ),
        ),
      ),
    );
  }
}

/// Extension on [BuildContext] providing convenient, consistent high-contrast tokens.
extension HighContrastX on BuildContext {
  /// Whether the app is currently rendering in WCAG AAA High Contrast mode.
  bool get isHighContrast =>
      Theme.of(this).colorScheme.outline == const Color(0xFF000000) ||
      AccessibilityPreferencesService.instance.isHighContrast;

  /// Background color for full screen scaffolds.
  Color get surfaceColor =>
      isHighContrast ? Colors.white : AppColors.surface;

  /// Background color for elevated containers and cards.
  Color get cardColor =>
      isHighContrast ? Colors.white : AppColors.surfaceContainerLowest;

  /// Primary high-contrast text color (pure black in high contrast).
  Color get textColor =>
      isHighContrast ? Colors.black : AppColors.onSurface;

  /// Secondary/subtext color (very dark gray #1A1A1A in high contrast).
  Color get subtextColor =>
      isHighContrast ? const Color(0xFF1A1A1A) : AppColors.onSurfaceVariant;

  /// Primary interactive brand color (high-contrast navy).
  Color get primaryColor =>
      isHighContrast ? const Color(0xFF001F3F) : AppColors.primary;

  /// Primary container color for highlights and chips.
  Color get primaryContainerColor =>
      isHighContrast ? const Color(0xFF001F3F) : AppColors.primaryContainer;

  /// On-primary-container text/icon color.
  Color get onPrimaryContainerColor =>
      isHighContrast ? Colors.white : AppColors.onPrimaryContainer;

  /// High contrast border for cards, buttons, and inputs.
  Border cardBorder({double width = 2.0}) => isHighContrast
      ? Border.all(color: Colors.black, width: width)
      : Border.all(color: AppColors.surfaceVariant);

  /// Solid border for dividers or containers.
  BorderSide get borderSide => isHighContrast
      ? const BorderSide(color: Colors.black, width: 2.0)
      : const BorderSide(color: AppColors.surfaceVariant);

  /// Shadows are eliminated in high contrast mode to avoid blurry edges.
  List<BoxShadow> cardShadow([List<BoxShadow>? normalShadow]) =>
      isHighContrast
          ? const []
          : (normalShadow ??
              const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ]);

  // ==========================================
  // Large Tap Targets (48dp+) Sizing Tokens
  // ==========================================

  /// Accessibility tokens from inherited theme extension, if available.
  AccessibilityTokens? get accessibilityTokens {
    try {
      return Theme.of(this).extension<AccessibilityTokens>();
    } catch (_) {
      return null;
    }
  }

  /// Whether large tap targets (48dp+) is currently enabled.
  bool get hasLargeTargets =>
      accessibilityTokens?.hasLargeTargets ??
      AccessibilityPreferencesService.instance.hasLargeTargets;

  /// Minimum interactive element height: 60dp when large targets, 44dp compact.
  double get minTapHeight => hasLargeTargets ? 60.0 : 44.0;

  /// Button height: 60dp when large targets, 48dp compact.
  double get buttonHeight => hasLargeTargets ? 60.0 : 48.0;

  /// Icon size for interactive controls: 28dp large, 20dp compact.
  double get tapIconSize => hasLargeTargets ? 28.0 : 20.0;

  /// Standard padding for interactive rows.
  EdgeInsets get tapPadding => hasLargeTargets
      ? const EdgeInsets.symmetric(horizontal: 20, vertical: 16)
      : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  /// Button text size: 18 large, 15 compact.
  double get buttonFontSize => hasLargeTargets ? 18.0 : 15.0;

  /// Bottom nav icon size: 28 large, 22 compact.
  double get navIconSize => hasLargeTargets ? 28.0 : 22.0;

  /// Bottom nav bar height: 84 large, 72 compact.
  double get navBarHeight => hasLargeTargets ? 84.0 : 72.0;

  /// Content padding vertical for inputs.
  double get inputVerticalPadding => hasLargeTargets ? 18.0 : 14.0;

  /// Chip / filter touch target height: 52dp large, 38dp compact.
  double get chipHeight => hasLargeTargets ? 52.0 : 38.0;

  /// Constraints for AppBar action icons and small tap targets.
  BoxConstraints get appBarActionConstraints => BoxConstraints(
        minWidth: hasLargeTargets ? 60.0 : 48.0,
        minHeight: hasLargeTargets ? 60.0 : 48.0,
      );
}

/// ThemeExtension delivering reactive accessibility sizing tokens to all screens.
class AccessibilityTokens extends ThemeExtension<AccessibilityTokens> {
  const AccessibilityTokens({
    required this.hasLargeTargets,
    required this.isHighContrast,
  });

  final bool hasLargeTargets;
  final bool isHighContrast;

  @override
  AccessibilityTokens copyWith({bool? hasLargeTargets, bool? isHighContrast}) {
    return AccessibilityTokens(
      hasLargeTargets: hasLargeTargets ?? this.hasLargeTargets,
      isHighContrast: isHighContrast ?? this.isHighContrast,
    );
  }

  @override
  AccessibilityTokens lerp(
    ThemeExtension<AccessibilityTokens>? other,
    double t,
  ) {
    if (other is! AccessibilityTokens) return this;
    return AccessibilityTokens(
      hasLargeTargets: t < 0.5 ? hasLargeTargets : other.hasLargeTargets,
      isHighContrast: t < 0.5 ? isHighContrast : other.isHighContrast,
    );
  }
}
