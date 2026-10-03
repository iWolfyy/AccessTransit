import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';

/// Animated three-bar password strength indicator.
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({
    super.key,
    required this.strength,
    this.showWhenEmpty = false,
  });

  final PasswordStrength strength;
  final bool showWhenEmpty;

  Color _getStrengthColor(bool isHC) {
    if (!isHC) return strength.color;
    switch (strength) {
      case PasswordStrength.empty:
        return Colors.black;
      case PasswordStrength.weak:
        return const Color(0xFF8B0000);
      case PasswordStrength.fair:
        return const Color(0xFF8B4500);
      case PasswordStrength.good:
      case PasswordStrength.strong:
        return const Color(0xFF003833);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (strength == PasswordStrength.empty && !showWhenEmpty) {
      return const SizedBox.shrink();
    }

    final isHC = context.isHighContrast;
    final filledBars = strength.filledBars;
    final strengthColor = _getStrengthColor(isHC);
    final label = strength == PasswordStrength.empty
        ? 'Password strength'
        : strength.label;
    final labelColor = strength == PasswordStrength.empty
        ? (isHC ? Colors.black : AppColors.onSurfaceVariant)
        : strengthColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Row(
          children: List.generate(3, (index) {
            final isFilled = index < filledBars;
            final isLast = index == 2;

            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                height: isHC ? 6 : 4,
                margin: EdgeInsets.only(right: isLast ? 0 : 4),
                decoration: BoxDecoration(
                  color: isFilled
                      ? strengthColor
                      : (isHC ? Colors.white : AppColors.outlineVariant),
                  border: isHC
                      ? Border.all(color: Colors.black, width: 1.5)
                      : null,
                  borderRadius: BorderRadius.horizontal(
                    left: index == 0 ? const Radius.circular(999) : Radius.zero,
                    right: isLast ? const Radius.circular(999) : Radius.zero,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Align(
            key: ValueKey(label),
            alignment: Alignment.centerRight,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                height: 16 / 12,
                fontWeight: isHC ? FontWeight.w700 : FontWeight.w500,
                color: labelColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
