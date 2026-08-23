import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    if (strength == PasswordStrength.empty && !showWhenEmpty) {
      return const SizedBox.shrink();
    }

    final filledBars = strength.filledBars;
    final label = strength == PasswordStrength.empty
        ? 'Password strength'
        : strength.label;
    final labelColor = strength == PasswordStrength.empty
        ? AppColors.onSurfaceVariant
        : strength.color;

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
                height: 4,
                margin: EdgeInsets.only(right: isLast ? 0 : 4),
                decoration: BoxDecoration(
                  color: isFilled ? strength.color : AppColors.outlineVariant,
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
                fontWeight: FontWeight.w500,
                color: labelColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
