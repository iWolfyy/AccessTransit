import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';

/// Animated three-bar password strength indicator.
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({
    super.key,
    required this.strength,
  });

  final PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    if (strength == PasswordStrength.empty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Row(
          children: List.generate(3, (index) {
            final isFilled = index < strength.filledBars;
            final isLast = index == 2;

            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                height: 4,
                margin: EdgeInsets.only(right: isLast ? 0 : 4),
                decoration: BoxDecoration(
                  color: isFilled
                      ? strength.color
                      : AppColors.outlineVariant,
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
            key: ValueKey(strength),
            alignment: Alignment.centerRight,
            child: Text(
              strength.label,
              style: TextStyle(
                fontSize: 12,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
                color: strength.color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
