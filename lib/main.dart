import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import 'l10n/app_localizations.dart';
import 'services/language_preferences_service.dart';

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
import 'services/moderation_mode.dart';
import 'widgets/moderation_account_gate.dart';
import 'services/driver_notifications.dart';
import 'services/firebase_driver_push.dart';
import 'services/moderation_client.dart';
import 'screens/operator/notification_request_screen.dart';
import 'l10n/localization_context.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ModerationMode.initializeMainApp();
  ModerationMode.validate();
  DriverPushConfiguration.validateBuild();

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
  if (DriverPushConfiguration.requested) {
    DriverPushConfiguration.validateProject();
  }

  await AccessibilityPreferencesService.instance.init(
    userId: FirebaseAuth.instance.currentUser?.uid,
  );
  AccessibilityPreferencesService.instance.startAuthSync();
  await LanguagePreferencesService.instance.init(
    userId: FirebaseAuth.instance.currentUser?.uid,
  );
  LanguagePreferencesService.instance.bindAccounts(
    FirebaseAuth.instance.authStateChanges().map((user) => user?.uid),
  );
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

class _AccessTransitAppState extends State<AccessTransitApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<User?>? _pushAccounts;
  DriverNotifications? _push;
  ModerationClient? _pushClient;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _pushSnack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
    if (DriverPushConfiguration.requested) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initPush());
    }
  }

  Future<void> _initPush() async {
    if (!mounted) return;
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    final channelName = context.l10n.pushTitle,
        channelDescription = context.l10n.pushChannelDescription;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final client = ModerationClient();
    if (!client.isConfigured) {
      client.dispose();
      throw StateError('Push requires a trusted v2 HTTPS endpoint.');
    }
    await FirebaseDriverPush.createChannel(channelName, channelDescription);
    if (!mounted) {
      client.dispose();
      return;
    }
    _pushClient = client;
    String key(String uid) =>
        'driver_push_${DriverPushConfiguration.reviewedTestProjectId}_${sha256.convert(utf8.encode(uid))}';
    final session = DriverNotifications(
      device: FirebaseDriverPush(),
      client: client,
      currentUid: () => FirebaseAuth.instance.currentUser?.uid,
      readEnabled: (uid) async => prefs.getBool(key(uid)) ?? false,
      saveEnabled: (uid, value) async {
        if (!await prefs.setBool(key(uid), value)) {
          throw StateError('save-failed');
        }
      },
      onOpen: (_, payload) => _showPushRequest(payload),
      onForeground: (payload) {
        final c = _navigatorKey.currentContext;
        if (!mounted || c == null) return;
        _pushSnack?.close();
        _pushSnack = ScaffoldMessenger.of(c).showSnackBar(
          SnackBar(
            content: Text(c.l10n.pushForeground),
            action: SnackBarAction(
              label: c.l10n.pushReview,
              onPressed: () => _showPushRequest(payload),
            ),
          ),
        );
      },
    );
    _push = session;
    DriverPushRuntime.session = session;
    LanguagePreferencesService.instance.addListener(_syncPush);
    _pushAccounts = FirebaseAuth.instance.authStateChanges().listen(
      (_) => _syncPush(),
    );
    _syncPush();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_push?.refreshPermission());
    }
  }

  void _syncPush() {
    _pushSnack?.close();
    final session = _push;
    if (session == null) return;
    unawaited(
      session
          .activate(
            FirebaseAuth.instance.currentUser?.uid,
            LanguagePreferencesService.instance.locale.languageCode,
          )
          .then((_) => session.initialMessage()),
    );
  }

  void _showPushRequest(Map<String, dynamic> payload) {
    final session = _push;
    if (!mounted || session == null || !session.enabled) return;
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) =>
            NotificationRequestScreen(session: session, payload: payload),
      ),
    );
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
    WidgetsBinding.instance.removeObserver(this);
    LanguagePreferencesService.instance.removeListener(_syncPush);
    _pushAccounts?.cancel();
    if (identical(DriverPushRuntime.session, _push)) {
      DriverPushRuntime.session = null;
    }
    _push?.dispose();
    _pushClient?.dispose();
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguagePreferencesService.instance,
      builder: (context, _) => MaterialApp(
        locale: LanguagePreferencesService.instance.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
              return Theme(
                data: AppTheme.forPreferences(
                  highContrast: isHighContrast,
                  largeTargets: hasLargeTargets,
                ),
                child: Column(
                  children: [
                    if (SampleTestMode.enabled)
                      SafeArea(
                        bottom: false,
                        child: Material(
                          color: Colors.amber,
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              context.l10n.sharedSampleNotice,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (LocalValidationBackend.enabled)
                      SafeArea(
                        bottom: false,
                        child: Material(
                          color: Colors.amber,
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              context.l10n.sharedLocalNotice,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const CatalogueNotice(),
                    Expanded(
                      child: ModerationMode.enabled
                          ? ModerationAccountGate(child: child!)
                          : child!,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
