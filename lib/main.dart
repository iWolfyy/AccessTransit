import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'core/routing/password_reset_link_handler.dart';
import 'core/theme/app_theme.dart';
import 'widgets/catalogue_notice.dart';
import 'firebase_options.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/accessibility_preferences_service.dart';
import 'services/report_submission_service.dart';
import 'services/assistance_submission_service.dart';
import 'services/local_validation_backend.dart';
import 'services/sample_test_mode.dart';
import 'services/transit_catalogue.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SampleTestMode.enabled &&
      (LocalValidationBackend.enabled || TransitCatalogue.demo)) {
    throw StateError(
      'Select only one of SAMPLE_TEST, LOCAL_VALIDATION or TRANSIT_DEMO.',
    );
  }

  if (LocalValidationBackend.enabled) {
    await LocalValidationBackend.initialize();
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await AccessibilityPreferencesService.instance.init(
    userId: FirebaseAuth.instance.currentUser?.uid,
  );
  AccessibilityPreferencesService.instance.startAuthSync();
  await ReportSubmissionService.instance.activateAccount(
    FirebaseAuth.instance.currentUser?.uid,
  );
  ReportSubmissionService.instance.startAutoRetry();
  await AssistanceSubmissionService.instance.init();
  AssistanceSubmissionService.instance.startAutoRetry();

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
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      builder: (context, child) {
        return ListenableBuilder(
          listenable: AccessibilityPreferencesService.instance,
          builder: (context, _) {
            final prefs = AccessibilityPreferencesService.instance;
            final isHighContrast = prefs.isHighContrast;
            final hasLargeTargets = prefs.hasLargeTargets;
            final baseTheme = isHighContrast
                ? AppTheme.highContrastTheme
                : AppTheme.lightTheme;
            return Theme(
              data: baseTheme.copyWith(
                extensions: [
                  AccessibilityTokens(
                    hasLargeTargets: hasLargeTargets,
                    isHighContrast: isHighContrast,
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (SampleTestMode.enabled)
                    const SafeArea(
                      bottom: false,
                      child: Material(
                        color: Colors.amber,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            SampleTestMode.notice,
                            style: TextStyle(color: Colors.black, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  if (LocalValidationBackend.enabled)
                    const SafeArea(
                      bottom: false,
                      child: Material(
                        color: Colors.amber,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'LOCAL TEST ONLY - synthetic services, no real transit or Cloudinary uploads',
                            style: TextStyle(color: Colors.black, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  const CatalogueNotice(),
                  Expanded(child: child!),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
