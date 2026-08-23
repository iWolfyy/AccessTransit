import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../widgets/auth/auth_input_field.dart';
import '../../widgets/auth/password_strength_indicator.dart';
import 'login_screen.dart';
import 'password_reset_success_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.actionCode});

  /// Firebase password reset code from the email link (oobCode).
  final String? actionCode;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final AnimationController _entranceController;
  late final AnimationController _buttonScaleController;
  late final Animation<double> _buttonScale;

  PasswordStrength _passwordStrength = PasswordStrength.empty;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _autoValidate = false;

  static const _staggerDelay = 0.09;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _buttonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _buttonScale = Tween<double>(begin: 1, end: 0.98).animate(
      CurvedAnimation(
        parent: _buttonScaleController,
        curve: Curves.easeInOut,
      ),
    );

    _passwordController.addListener(_updatePasswordStrength);
    _entranceController.forward();
  }

  void _updatePasswordStrength() {
    final next = Validators.evaluatePasswordStrength(_passwordController.text);
    if (next != _passwordStrength) {
      setState(() => _passwordStrength = next);
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _buttonScaleController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Animation<double> _fade(int index) {
    final start = index * _staggerDelay;
    final end = (start + 0.5).clamp(0.0, 1.0);

    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  Animation<Offset> _slide(int index) {
    return Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(_fade(index));
  }

  Widget _staggered(int index, Widget child) {
    return FadeTransition(
      opacity: _fade(index),
      child: SlideTransition(
        position: _slide(index),
        child: child,
      ),
    );
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    setState(() => _autoValidate = true);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final code = widget.actionCode;
    if (code == null || code.isEmpty) {
      _showMessage(
        'This reset link is invalid or has expired. Please request a new one.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPasswordResetCode(code);
      await FirebaseAuth.instance.confirmPasswordReset(
        code: code,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const PasswordResetSuccessScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(_getErrorMessage(e), isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Unable to reset password. Please try again.', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? AppColors.error : AppColors.primaryContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'expired-action-code':
        return 'This reset link has expired. Please request a new one.';
      case 'invalid-action-code':
        return 'This reset link is invalid. Please request a new one.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'Unable to reset password.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBright,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderBar(),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.onSurface.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: _autoValidate
                              ? AutovalidateMode.onUserInteraction
                              : AutovalidateMode.disabled,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _staggered(0, _buildTitleSection()),
                              const SizedBox(height: 32),
                              _staggered(1, _buildPasswordField()),
                              const SizedBox(height: 16),
                              _staggered(2, _buildConfirmPasswordField()),
                              const SizedBox(height: 16),
                              _staggered(3, _buildSecurityNote()),
                              const SizedBox(height: 24),
                              _staggered(4, _buildResetButton()),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceBright,
        border: const Border(
          bottom: BorderSide(color: AppColors.outlineVariant),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            IconButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.primary,
              tooltip: 'Go back',
            ),
            const Expanded(
              child: Text(
                'Reset Password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  height: 28 / 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        const Text(
          'Create New Password',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            height: 32 / 24,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please choose a strong password that you haven\'t used before.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.95),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthInputField(
          controller: _passwordController,
          label: 'New Password',
          hint: 'Enter your new password',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          validator: Validators.registerPassword,
          suffixIcon: IconButton(
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
            tooltip: _obscurePassword ? 'Show password' : 'Hide password',
          ),
        ),
        PasswordStrengthIndicator(
          strength: _passwordStrength,
          showWhenEmpty: true,
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return AuthInputField(
      controller: _confirmPasswordController,
      label: 'Confirm New Password',
      hint: 'Re-enter your new password',
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.newPassword],
      validator: (value) => Validators.confirmPassword(
        value,
        _passwordController.text,
      ),
      onFieldSubmitted: (_) {
        if (!_isLoading) _resetPassword();
      },
      suffixIcon: IconButton(
        onPressed: () {
          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
        },
        icon: Icon(
          _obscureConfirmPassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppColors.onSurfaceVariant,
          size: 20,
        ),
        tooltip: _obscureConfirmPassword ? 'Show password' : 'Hide password',
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 16,
          color: AppColors.secondary.withValues(alpha: 0.9),
        ),
        const SizedBox(width: 6),
        Text(
          'Your security is our priority.',
          style: TextStyle(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w500,
            color: AppColors.secondary.withValues(alpha: 0.95),
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    return GestureDetector(
      onTapDown: _isLoading ? null : (_) => _buttonScaleController.forward(),
      onTapUp: _isLoading ? null : (_) => _buttonScaleController.reverse(),
      onTapCancel: () => _buttonScaleController.reverse(),
      child: ScaleTransition(
        scale: _buttonScale,
        child: SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimary,
              disabledBackgroundColor:
                  AppColors.primaryContainer.withValues(alpha: 0.6),
              disabledForegroundColor:
                  AppColors.onPrimary.withValues(alpha: 0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 1,
              shadowColor: AppColors.primary.withValues(alpha: 0.15),
              textStyle: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.onPrimary,
                    ),
                  )
                : const Text('Reset Password'),
          ),
        ),
      ),
    );
  }
}
