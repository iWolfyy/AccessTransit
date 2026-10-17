import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Shared presentation for admin routes, retaining the app's accessibility
/// sizes, locale, colors and button behavior.
class AdminScaffold extends StatelessWidget {
  const AdminScaffold({
    super.key,
    required this.appBar,
    required this.body,
    this.backgroundColor,
    this.floatingActionButton,
    this.enabled = true,
  });

  final PreferredSizeWidget appBar;
  final Widget body;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final bool enabled;

  static ThemeData themeFor(BuildContext context) {
    final base = Theme.of(context);
    final colors = base.colorScheme;
    final contrast = context.isHighContrast;
    final border = BorderSide(
      color: contrast
          ? colors.outline
          : colors.outlineVariant.withValues(alpha: .5),
      width: contrast ? 2 : 1,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: border,
    );
    final buttonShape = WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: context.surfaceColor,
        foregroundColor: colors.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: colors.primary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: context.cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: shape,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: context.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: border,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: border,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: (base.filledButtonTheme.style ?? const ButtonStyle()).copyWith(
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: (base.outlinedButtonTheme.style ?? const ButtonStyle()).copyWith(
          shape: buttonShape,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: border,
        selectedColor: colors.primary,
        secondaryLabelStyle: TextStyle(
          color: colors.onPrimary,
          fontWeight: FontWeight.w700,
        ),
        checkmarkColor: colors.onPrimary,
        backgroundColor: context.cardColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Scaffold(
        appBar: appBar,
        body: body,
        backgroundColor: backgroundColor,
        floatingActionButton: floatingActionButton,
      );
    }
    return Theme(
      data: themeFor(context),
      child: Scaffold(
        backgroundColor: backgroundColor ?? context.surfaceColor,
        appBar: appBar,
        body: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: body,
            ),
          ),
        ),
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}

/// Dialogs opened from a route state inherit the same admin field/card styles.
class AdminDialog extends StatelessWidget {
  const AdminDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.scrollable = false,
  });
  final Widget? title, content;
  final List<Widget>? actions;
  final bool scrollable;
  @override
  Widget build(BuildContext context) => Theme(
    data: AdminScaffold.themeFor(context),
    child: AlertDialog(
      title: title,
      content: content,
      actions: actions,
      scrollable: scrollable,
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
