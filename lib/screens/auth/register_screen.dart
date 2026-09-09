import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../models/enums/user_role.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth/auth_input_field.dart';
import '../../widgets/auth/password_strength_indicator.dart';
import '../operator/operator_dashboard_screen.dart';
import '../preferences/accessibility_preferences_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  late final AnimationController _entranceController;
  late final AnimationController _buttonScaleController;
  late final Animation<double> _buttonScale;

  UserRole _selectedRole = UserRole.passenger;
  PasswordStrength _passwordStrength = PasswordStrength.empty;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasAccessibilityNeeds = false;
  bool _autoValidate = false;

  static const _staggerDelay = 0.08;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _buttonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _buttonScale = Tween<double>(begin: 1, end: 0.96).animate(
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Animation<double> _fade(int index) {
    final start = index * _staggerDelay;
    final end = (start + 0.45).clamp(0.0, 1.0);

    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  Animation<Offset> _slide(int index) {
    return Tween<Offset>(
      begin: const Offset(0, 0.12),
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

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    setState(() => _autoValidate = true);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
      );

      if (!mounted) return;

      _showMessage('Welcome aboard, ${user.name}! Your account is ready.');
      if (user.role == UserRole.operator) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const OperatorDashboardScreen(),
          ),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => AccessibilityPreferencesScreen(
              initialUser: user,
              continueToHome: true,
            ),
          ),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showMessage(_getAuthErrorMessage(e), isError: true);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Registration failed. Please try again.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showComingSoon(String feature) {
    _showMessage('$feature will be available in a future update.');
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

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Try a stronger combination.';
      case 'operation-not-allowed':
        return 'Email/password authentication is not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'Unable to create account.';
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _autoValidate
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _staggered(0, _buildTitleSection()),
                          const SizedBox(height: 24),
                          _staggered(1, _buildNameField()),
                          const SizedBox(height: 16),
                          _staggered(2, _buildEmailField()),
                          const SizedBox(height: 16),
                          _staggered(3, _buildPasswordSection()),
                          const SizedBox(height: 16),
                          _staggered(4, _buildConfirmPasswordField()),
                          const SizedBox(height: 8),
                          _staggered(5, _buildAccessibilityCheckbox()),
                          const SizedBox(height: 16),
                          _staggered(6, _buildRoleSelector()),
                          const SizedBox(height: 24),
                          _staggered(7, _buildCreateAccountButton()),
                          const SizedBox(height: 24),
                          _staggered(7, _buildDivider()),
                          const SizedBox(height: 16),
                          _staggered(8, _buildSocialButtons()),
                          const SizedBox(height: 24),
                          _staggered(8, _buildLoginLink()),
                        ],
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
      decoration: const BoxDecoration(
        color: AppColors.surfaceBright,
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            IconButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.onSurface,
              tooltip: 'Go back',
            ),
            const Expanded(
              child: Text(
                'Register',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  height: 24 / 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
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
          'Join Access Transit',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            height: 40 / 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.64,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your journey to inclusive travel begins here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            height: 24 / 16,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.95),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return AuthInputField(
      controller: _nameController,
      label: 'Full Name',
      hint: 'Enter your full name',
      prefixIcon: Icons.person_outline_rounded,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.name],
      validator: Validators.fullName,
    );
  }

  Widget _buildEmailField() {
    return AuthInputField(
      controller: _emailController,
      label: 'Email Address',
      hint: 'Enter your email',
      prefixIcon: Icons.mail_outline_rounded,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      validator: Validators.email,
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthInputField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Create a password',
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
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
            tooltip: _obscurePassword ? 'Show password' : 'Hide password',
          ),
        ),
        PasswordStrengthIndicator(strength: _passwordStrength),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return AuthInputField(
      controller: _confirmPasswordController,
      label: 'Confirm Password',
      hint: 'Re-enter your password',
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.newPassword],
      validator: (value) => Validators.confirmPassword(
        value,
        _passwordController.text,
      ),
      suffixIcon: IconButton(
        onPressed: () {
          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
        },
        icon: Icon(
          _obscureConfirmPassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: AppColors.onSurfaceVariant,
          size: 20,
        ),
        tooltip: _obscureConfirmPassword ? 'Show password' : 'Hide password',
      ),
    );
  }

  Widget _buildAccessibilityCheckbox() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading
            ? null
            : () {
                setState(() {
                  _hasAccessibilityNeeds = !_hasAccessibilityNeeds;
                });
              },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: _hasAccessibilityNeeds
                ? AppColors.surfaceContainer.withValues(alpha: 0.6)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: _hasAccessibilityNeeds
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _hasAccessibilityNeeds
                        ? AppColors.primary
                        : AppColors.outline,
                    width: 2,
                  ),
                ),
                child: AnimatedScale(
                  scale: _hasAccessibilityNeeds ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.elasticOut,
                  child: const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'I have specific accessibility needs',
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '(e.g., wheelchair ramp, low floor bus)',
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Type',
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _RoleCard(
                title: 'Passenger',
                subtitle: 'Plan accessible journeys',
                icon: Icons.directions_transit_rounded,
                isSelected: _selectedRole == UserRole.passenger,
                onTap: _isLoading
                    ? null
                    : () => setState(() => _selectedRole = UserRole.passenger),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RoleCard(
                title: 'Contributor',
                subtitle: 'Report conditions',
                icon: Icons.report_outlined,
                isSelected: _selectedRole == UserRole.contributor,
                onTap: _isLoading
                    ? null
                    : () =>
                        setState(() => _selectedRole = UserRole.contributor),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RoleCard(
                title: 'Bus Operator',
                subtitle: 'Broadcast live GPS',
                icon: Icons.directions_bus,
                isSelected: _selectedRole == UserRole.operator,
                onTap: _isLoading
                    ? null
                    : () => setState(() => _selectedRole = UserRole.operator),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCreateAccountButton() {
    return GestureDetector(
      onTapDown: _isLoading
          ? null
          : (_) => _buttonScaleController.forward(),
      onTapUp: _isLoading
          ? null
          : (_) => _buttonScaleController.reverse(),
      onTapCancel: () => _buttonScaleController.reverse(),
      child: ScaleTransition(
        scale: _buttonScale,
        child: SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _isLoading ? null : _register,
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
              shadowColor: AppColors.primary.withValues(alpha: 0.2),
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
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Create Account'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.outlineVariant, height: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.9),
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.outlineVariant, height: 1),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed:
                _isLoading ? null : () => _showComingSoon('Google sign-up'),
            icon: const _GoogleLogo(size: 20),
            label: const Text('Sign up with Google'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.onSurface,
              side: const BorderSide(color: AppColors.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed:
                _isLoading ? null : () => _showComingSoon('Apple sign-up'),
            icon: const Icon(Icons.apple, size: 22),
            label: const Text('Sign up with Apple'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.onSurface,
              side: const BorderSide(color: AppColors.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            fontSize: 16,
            height: 24 / 16,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.95),
          ),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Log in',
            style: TextStyle(
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: Material(
        color: isSelected
            ? AppColors.primaryContainer.withValues(alpha: 0.12)
            : AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppColors.primaryContainer : AppColors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryContainer
                        : AppColors.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? AppColors.onPrimary
                        : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 14 / 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final blue = Paint()..color = const Color(0xFF4285F4);
    final green = Paint()..color = const Color(0xFF34A853);
    final yellow = Paint()..color = const Color(0xFFFBBC05);
    final red = Paint()..color = const Color(0xFFEA4335);

    canvas.drawArc(Rect.fromLTWH(0, 0, w, h), -0.4, 1.2, true, blue);
    canvas.drawArc(Rect.fromLTWH(0, 0, w, h), 0.8, 1.0, true, green);
    canvas.drawArc(Rect.fromLTWH(0, 0, w, h), 1.8, 1.0, true, yellow);
    canvas.drawArc(Rect.fromLTWH(0, 0, w, h), 2.8, 1.0, true, red);
    canvas.drawCircle(
      Offset(w / 2, h / 2),
      w * 0.32,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
