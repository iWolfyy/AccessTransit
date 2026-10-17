import '../../widgets/accessible_tap_target.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../l10n/localization_context.dart';
import '../../l10n/recovery_presentation.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth/auth_input_field.dart';
import '../../widgets/auth/password_strength_indicator.dart';
import 'login_screen.dart';
import 'password_reset_success_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.actionCode, this.authService});

  /// Firebase password reset code from the email link (oobCode).
  final String? actionCode;
  final AuthService? authService;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final AuthService _authService = widget.authService ?? AuthService();

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
      CurvedAnimation(parent: _buttonScaleController, curve: Curves.easeInOut),
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
      child: SlideTransition(position: _slide(index), child: child),
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
      await _authService.verifyPasswordResetCode(code);
      await _authService.confirmPasswordReset(
        code: code,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PasswordResetSuccessScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(_getErrorMessage(e), isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(
        'Unable to reset password. Please try again.',
        isError: true,
      );
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.recoveryText(message)),
          backgroundColor: isError
              ? AppColors.error
              : AppColors.primaryContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  String _getErrorMessage(FirebaseAuthException e) =>
      context.recoveryFailure(e.code, reset: true);

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;
    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderBar(isHC),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: isHC
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                        boxShadow: isHC
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.onSurface.withValues(
                                    alpha: 0.08,
                                  ),
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
                              _staggered(0, _buildTitleSection(isHC)),
                              const SizedBox(height: 32),
                              _staggered(1, _buildPasswordField()),
                              const SizedBox(height: 16),
                              _staggered(2, _buildConfirmPasswordField()),
                              const SizedBox(height: 16),
                              _staggered(3, _buildSecurityNote(isHC)),
                              const SizedBox(height: 24),
                              _staggered(4, _buildResetButton(isHC)),
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

  Widget _buildHeaderBar(bool isHC) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: isHC ? Colors.black : AppColors.outlineVariant,
            width: isHC ? 2 : 1,
          ),
        ),
        boxShadow: isHC
            ? null
            : [
                BoxShadow(
                  color: AppColors.onSurface.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            IconButton(
              constraints: context.appBarActionConstraints,
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
              icon: Icon(Icons.arrow_back_rounded, size: context.tapIconSize),
              color: isHC ? Colors.black : AppColors.primary,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
            Expanded(
              child: Text(
                context.l10n.recoveryTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  height: 28 / 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: isHC ? Colors.black : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(bool isHC) {
    return Column(
      children: [
        Text(
          context.l10n.recoveryCreate,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            height: 32 / 24,
            fontWeight: FontWeight.w700,
            color: context.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.recoveryPasswordHelp,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: isHC ? FontWeight.w600 : FontWeight.normal,
            color: isHC
                ? Colors.black
                : AppColors.onSurfaceVariant.withValues(alpha: 0.95),
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
          label: context.l10n.recoveryNewPassword,
          hint: context.l10n.recoveryPasswordHint,
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          validator: (v) =>
              context.recoveryValidation(Validators.registerPassword(v)),
          suffixIcon: IconButton(
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: context.subtextColor,
              size: 20,
            ),
            tooltip: _obscurePassword
                ? context.l10n.recoveryShow
                : context.l10n.recoveryHide,
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
      label: context.l10n.recoveryConfirm,
      hint: context.l10n.recoveryConfirmHint,
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.newPassword],
      validator: (value) => context.recoveryValidation(
        Validators.confirmPassword(value, _passwordController.text),
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
          color: context.subtextColor,
          size: 20,
        ),
        tooltip: _obscureConfirmPassword
            ? context.l10n.recoveryShow
            : context.l10n.recoveryHide,
      ),
    );
  }

  Widget _buildSecurityNote(bool isHC) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 16,
          color: isHC
              ? const Color(0xFF003833)
              : AppColors.secondary.withValues(alpha: 0.9),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            context.l10n.recoverySecurity,
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: isHC ? FontWeight.w700 : FontWeight.w500,
              color: isHC
                  ? const Color(0xFF003833)
                  : AppColors.secondary.withValues(alpha: 0.95),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton(bool isHC) {
    return AccessibleTapTarget(
      child: GestureDetector(
        onTapDown: _isLoading ? null : (_) => _buttonScaleController.forward(),
        onTapUp: _isLoading ? null : (_) => _buttonScaleController.reverse(),
        onTapCancel: () => _buttonScaleController.reverse(),
        child: ScaleTransition(
          scale: _buttonScale,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: context.buttonHeight),
            child: FilledButton(
              onPressed: _isLoading ? null : _resetPassword,
              style: FilledButton.styleFrom(
                backgroundColor: isHC
                    ? const Color(0xFF001F3F)
                    : AppColors.primaryContainer,
                foregroundColor: Colors.white,
                disabledBackgroundColor: isHC
                    ? const Color(0xFF001F3F).withValues(alpha: 0.6)
                    : AppColors.primaryContainer.withValues(alpha: 0.6),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: isHC
                      ? const BorderSide(color: Colors.black, width: 2)
                      : BorderSide.none,
                ),
                elevation: isHC ? 0 : 1,
                shadowColor: isHC
                    ? null
                    : AppColors.primary.withValues(alpha: 0.15),
                textStyle: TextStyle(
                  fontSize: context.hasLargeTargets ? 15.5 : 14,
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
                        color: Colors.white,
                      ),
                    )
                  : Text(context.l10n.recoveryTitle),
            ),
          ),
        ),
      ),
    );
  }
}
