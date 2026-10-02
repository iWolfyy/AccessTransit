import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'core/routing/password_reset_link_handler.dart';
import 'core/theme/app_theme.dart';
import 'data/seed_data.dart';
import 'firebase_options.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/accessibility_preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize global accessibility preferences (WCAG 2.2 AA)
  await AccessibilityPreferencesService.instance.init();

  // Sync authentic Sri Lankan routes and buses into Firestore
  try {
    final routes = await FirebaseFirestore.instance.collection('routes').get();
    final hasNewSlRoutes = routes.docs.any((d) => d.id == 'route_138_pettah_homagama');
    if (!hasNewSlRoutes) {
      await SeedData().seedAll();
    }
  } catch (e) {
    debugPrint('Database initialization warning: $e');
  }

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
    return ListenableBuilder(
      listenable: AccessibilityPreferencesService.instance,
      builder: (context, _) {
        final isHighContrast =
            AccessibilityPreferencesService.instance.isHighContrast;
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'AccessTransit',
          debugShowCheckedModeBanner: false,
          theme: isHighContrast
              ? AppTheme.highContrastTheme
              : AppTheme.lightTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}
