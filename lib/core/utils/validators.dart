import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Password strength levels for registration UI.
enum PasswordStrength {
  empty,
  weak,
  fair,
  good,
  strong;

  int get filledBars {
    switch (this) {
      case PasswordStrength.empty:
        return 0;
      case PasswordStrength.weak:
        return 1;
      case PasswordStrength.fair:
        return 2;
      case PasswordStrength.good:
        return 3;
      case PasswordStrength.strong:
        return 3;
    }
  }

  String get label {
    switch (this) {
      case PasswordStrength.empty:
        return '';
      case PasswordStrength.weak:
        return 'Weak — add more characters';
      case PasswordStrength.fair:
        return 'Fair — try adding numbers or symbols';
      case PasswordStrength.good:
        return 'Good strength';
      case PasswordStrength.strong:
        return 'Strong password';
    }
  }

  Color get color {
    switch (this) {
      case PasswordStrength.empty:
        return AppColors.outlineVariant;
      case PasswordStrength.weak:
        return AppColors.error;
      case PasswordStrength.fair:
        return AppColors.tertiary;
      case PasswordStrength.good:
      case PasswordStrength.strong:
        return AppColors.secondary;
    }
  }
}

/// Form validation helpers for authentication screens.
abstract final class Validators {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _nameRegex = RegExp(r"^[a-zA-Z\s'.-]+$");

  static String? fullName(String? value) {
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) {
      return 'Please enter your full name.';
    }

    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters.';
    }

    if (!_nameRegex.hasMatch(trimmed)) {
      return 'Name can only contain letters and spaces.';
    }

    return null;
  }

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) {
      return 'Please enter your email address.';
    }

    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password.';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }

    return null;
  }

  static String? registerPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please create a password.';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }

    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'Password must include at least one letter.';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must include at least one number.';
    }

    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }

    if (value != password) {
      return 'Passwords do not match.';
    }

    return null;
  }

  static PasswordStrength evaluatePasswordStrength(String password) {
    if (password.isEmpty) {
      return PasswordStrength.empty;
    }

    var score = 0;

    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.fair;
    if (score <= 4) return PasswordStrength.good;
    return PasswordStrength.strong;
  }
}
