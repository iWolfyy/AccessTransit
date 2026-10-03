import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Styled text field matching the AccessTransit login/register design.
class AuthInputField extends StatelessWidget {
  const AuthInputField({
    super.key,
    required this.controller,
    this.label,
    required this.hint,
    required this.prefixIcon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.onFieldSubmitted,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String? label;
  final String hint;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final void Function(String)? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;
    final errorColor = isHC ? const Color(0xFF8B0000) : AppColors.error;

    final hasLargeTargets = context.hasLargeTargets;

    final field = TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onFieldSubmitted: onFieldSubmitted,
      autofillHints: autofillHints,
      textCapitalization: textCapitalization,
      style: TextStyle(
        fontSize: hasLargeTargets ? 15.5 : 14,
        height: 20 / 14,
        fontWeight: isHC ? FontWeight.w600 : FontWeight.normal,
        color: context.textColor,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isHC ? Colors.black54 : AppColors.onSurfaceVariant,
        ),
        prefixIcon: Icon(
          prefixIcon,
          size: context.tapIconSize,
          color: isHC ? Colors.black : AppColors.onSurfaceVariant,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isHC ? Colors.white : Colors.transparent,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: context.inputVerticalPadding,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isHC ? Colors.black : AppColors.outline,
            width: isHC ? 2 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isHC ? Colors.black : AppColors.outline,
            width: isHC ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isHC ? Colors.black : AppColors.primaryContainer,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: errorColor,
            width: isHC ? 2 : 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        errorStyle: TextStyle(
          color: errorColor,
          fontSize: 12,
          height: 16 / 12,
          fontWeight: isHC ? FontWeight.w700 : FontWeight.normal,
        ),
      ),
    );

    if (label == null || label!.isEmpty) {
      return field;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label!,
          style: TextStyle(
            fontSize: hasLargeTargets ? 15.5 : 14,
            height: 20 / 14,
            fontWeight: isHC ? FontWeight.w700 : FontWeight.w600,
            letterSpacing: 0.1,
            color: context.textColor,
          ),
        ),
        const SizedBox(height: 4),
        field,
      ],
    );
  }
}
