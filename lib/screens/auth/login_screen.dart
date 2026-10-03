import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../models/enums/user_role.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth/auth_input_field.dart';
import '../operator/operator_dashboard_screen.dart';
import '../preferences/accessibility_preferences_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _autoValidate = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    setState(() => _autoValidate = true);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final profile = await _authService.getCurrentUserProfile();
      if (!mounted) return;

      if (profile?.role == UserRole.operator) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const OperatorDashboardScreen(),
          ),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const AccessibilityPreferencesScreen(
              continueToHome: true,
            ),
          ),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showMessage(_getAuthErrorMessage(e), isError: true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Login failed. Please try again.', isError: true);
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
          backgroundColor: isError ? AppColors.error : AppColors.primaryContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid email or password. Please check your details and try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many login attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      default:
        return e.message ?? 'Unable to sign in. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;
    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: isHC ? Border.all(color: Colors.black, width: 2) : null,
                  boxShadow: isHC
                      ? null
                      : const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
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
                        _buildHeader(isHC),
                        const SizedBox(height: 24),
                        AuthInputField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Enter your email address',
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 16),
                        _buildPasswordField(isHC),
                        const SizedBox(height: 24),
                        _buildSignInButton(isHC),
                        const SizedBox(height: 24),
                        _buildDivider(isHC),
                        const SizedBox(height: 24),
                        _buildBiometricButton(isHC),
                        const SizedBox(height: 8),
                        _buildGoogleButton(isHC),
                        const SizedBox(height: 24),
                        _buildSignUpLink(isHC),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isHC) {
    return Column(
      children: [
        Hero(
          tag: 'access-transit-logo',
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 64,
              height: 64,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isHC ? const Color(0xFF001F3F) : AppColors.primaryContainer,
                  shape: BoxShape.circle,
                  border: isHC ? Border.all(color: Colors.black, width: 2) : null,
                ),
                child: Icon(
                  Icons.accessible_forward_rounded,
                  color: isHC ? Colors.white : AppColors.onPrimaryContainer,
                  size: 36,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Access Transit',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            height: 40 / 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.64,
            color: isHC ? Colors.black : AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Welcome Back',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            height: 24 / 18,
            fontWeight: FontWeight.w600,
            color: isHC ? Colors.black : AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(bool isHC) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Password',
                style: TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: isHC ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: 0.1,
                  color: context.textColor,
                ),
              ),
            ),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ForgotPasswordScreen(
                            initialEmail: _emailController.text.trim(),
                          ),
                        ),
                      );
                    },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: context.hasLargeTargets ? 8 : 4,
                ),
                minimumSize: Size(0, context.minTapHeight),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: isHC ? const Color(0xFF001F3F) : AppColors.primary,
              ),
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: isHC ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AuthInputField(
          controller: _passwordController,
          hint: 'Enter your password',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          validator: Validators.password,
          onFieldSubmitted: (_) => _isLoading ? null : _login(),
          suffixIcon: IconButton(
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: isHC ? Colors.black : AppColors.onSurfaceVariant,
            ),
            tooltip: _obscurePassword ? 'Show password' : 'Hide password',
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton(bool isHC) {
    return SizedBox(
      height: context.buttonHeight,
      child: FilledButton(
        onPressed: _isLoading ? null : _login,
        style: FilledButton.styleFrom(
          backgroundColor: isHC ? const Color(0xFF001F3F) : AppColors.primaryContainer,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isHC
              ? const Color(0xFF001F3F).withValues(alpha: 0.6)
              : AppColors.primaryContainer.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isHC ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
          ),
          textStyle: TextStyle(
            fontSize: context.hasLargeTargets ? 19 : 18,
            height: 24 / 18,
            fontWeight: FontWeight.w600,
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
            : const Text('Sign In'),
      ),
    );
  }

  Widget _buildDivider(bool isHC) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isHC ? Colors.black : AppColors.outlineVariant,
            thickness: isHC ? 1.5 : 1,
            height: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Or continue with',
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: isHC ? FontWeight.w700 : FontWeight.w500,
              color: isHC ? Colors.black : AppColors.onSurfaceVariant.withValues(alpha: 0.9),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isHC ? Colors.black : AppColors.outlineVariant,
            thickness: isHC ? 1.5 : 1,
            height: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricButton(bool isHC) {
    return SizedBox(
      height: context.buttonHeight,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : () => _showComingSoon('Biometric sign-in'),
        icon: Icon(Icons.fingerprint_rounded, size: context.tapIconSize),
        label: const Text('Sign in with Biometrics'),
        style: OutlinedButton.styleFrom(
          backgroundColor: isHC ? Colors.white : null,
          foregroundColor: isHC ? Colors.black : AppColors.primaryContainer,
          side: BorderSide(
            color: isHC ? Colors.black : AppColors.primaryContainer,
            width: 2,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: TextStyle(
            fontSize: context.hasLargeTargets ? 15.5 : 14,
            height: 20 / 14,
            fontWeight: isHC ? FontWeight.w700 : FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(bool isHC) {
    return SizedBox(
      height: context.buttonHeight,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : () => _showComingSoon('Google sign-in'),
        icon: _GoogleLogo(size: context.tapIconSize),
        label: const Text('Sign in with Google'),
        style: OutlinedButton.styleFrom(
          backgroundColor: isHC ? Colors.white : null,
          foregroundColor: isHC ? Colors.black : AppColors.onSurface,
          side: BorderSide(
            color: isHC ? Colors.black : AppColors.outlineVariant,
            width: isHC ? 2 : 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: TextStyle(
            fontSize: context.hasLargeTargets ? 15.5 : 14,
            height: 20 / 14,
            fontWeight: isHC ? FontWeight.w700 : FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink(bool isHC) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Don\'t have an account?',
          style: TextStyle(
            fontSize: context.hasLargeTargets ? 15 : 14,
            height: 20 / 14,
            color: context.textColor,
          ),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
          style: TextButton.styleFrom(
            foregroundColor: isHC ? const Color(0xFF001F3F) : AppColors.primary,
            padding: EdgeInsets.symmetric(
              horizontal: 6,
              vertical: context.hasLargeTargets ? 10 : 4,
            ),
            minimumSize: Size(0, context.minTapHeight),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Sign up',
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: isHC ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
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

    canvas.drawArc(
      Rect.fromLTWH(0, 0, w, h),
      -0.4,
      1.2,
      true,
      blue,
    );
    canvas.drawArc(
      Rect.fromLTWH(0, 0, w, h),
      0.8,
      1.0,
      true,
      green,
    );
    canvas.drawArc(
      Rect.fromLTWH(0, 0, w, h),
      1.8,
      1.0,
      true,
      yellow,
    );
    canvas.drawArc(
      Rect.fromLTWH(0, 0, w, h),
      2.8,
      1.0,
      true,
      red,
    );

    canvas.drawCircle(
      Offset(w / 2, h / 2),
      w * 0.32,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
