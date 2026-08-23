import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/routing/password_reset_link_handler.dart';
import 'core/theme/app_colors.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/reset_password_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const AccessTransitApp());
}

class AccessTransitApp extends StatefulWidget {
  const AccessTransitApp({super.key});

  @override
  State<AccessTransitApp> createState() => _AccessTransitAppState();
}

class _AccessTransitAppState extends State<AccessTransitApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handlePasswordResetLink(initialUri);
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handlePasswordResetLink,
      onError: (_) {},
    );
  }

  void _handlePasswordResetLink(Uri uri) {
    final resetCode = PasswordResetLinkHandler.parseResetCode(uri);
    if (resetCode == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(actionCode: resetCode),
        ),
      );
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'AccessTransit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          surface: AppColors.surfaceBright,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.surfaceBright,
      ),
      home: const LoginScreen(),
    );
  }
}
