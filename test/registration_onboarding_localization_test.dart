import 'dart:async';

import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/models/enums/user_role.dart';
import 'package:access_transit/models/user_model.dart';
import 'package:access_transit/screens/auth/register_screen.dart';
import 'package:access_transit/screens/auth/login_screen.dart';
import 'package:access_transit/screens/operator/operator_dashboard_screen.dart';
import 'package:access_transit/screens/preferences/accessibility_preferences_screen.dart';
import 'package:access_transit/screens/onboarding/onboarding_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationFixture extends AuthService {
  final outcome = Completer<UserModel>();
  UserRole? submittedRole;
  String? submittedName;
  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    UserRole role = UserRole.passenger,
  }) {
    submittedRole = role;
    submittedName = name;
    return outcome.future;
  }
}

Widget host(String lang, Widget child) => MaterialApp(
  locale: Locale(lang),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (c, w) => MediaQuery(
    data: MediaQuery.of(
      c,
    ).copyWith(textScaler: const TextScaler.linear(2), disableAnimations: true),
    child: w!,
  ),
  home: child,
);
void narrow(WidgetTester t) {
  t.view.physicalSize = const Size(320, 1500);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

Future<void> press(WidgetTester t, String label) async {
  await t.ensureVisible(find.text(label).last);
  await t.pumpAndSettle();
  await t.tap(find.text(label).last);
  await t.pump();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init();
    await AccessibilityPreferencesService.instance.setHighContrast(false);
  });
  for (final lang in ['en', 'si', 'ta']) {
    testWidgets(
      'onboarding $lang skip remains usable on 320x800 with large text',
      (t) async {
        narrow(t);
        t.view.physicalSize = const Size(320, 800);
        final l = lookupAppLocalizations(Locale(lang));
        await AccessibilityPreferencesService.instance.setHighContrast(true);
        await t.pumpWidget(host(lang, const OnboardingScreen()));
        await t.pumpAndSettle();
        await t.tap(find.byTooltip(l.onboardingSkipTooltip));
        await t.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'reporter registration $lang routes from acknowledged role without approval',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        final f = RegistrationFixture();
        await t.pumpWidget(host(lang, RegisterScreen(authService: f)));
        await t.pumpAndSettle();
        final fields = find.byType(TextFormField);
        await t.enterText(fields.at(0), 'Original Name');
        await t.enterText(fields.at(1), 'original@example.com');
        await t.enterText(fields.at(2), 'ExamplePassword25!');
        await t.enterText(fields.at(3), 'ExamplePassword25!');
        await press(t, l.reporter);
        await t.pumpAndSettle();
        await press(t, l.registrationCreate);
        expect(f.submittedRole, UserRole.contributor);
        expect(find.byType(AccessibilityPreferencesScreen), findsNothing);
        f.outcome.complete(
          const UserModel(
            uid: 'fixture',
            name: 'Original Name',
            email: 'original@example.com',
            role: UserRole.contributor,
          ),
        );
        await t.pumpAndSettle();
        expect(find.byType(AccessibilityPreferencesScreen), findsOneWidget);
        expect(find.byType(OperatorDashboardScreen), findsNothing);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'registration $lang validates locally and preserves driver value on failed receipt',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        final f = RegistrationFixture();
        await t.pumpWidget(host(lang, RegisterScreen(authService: f)));
        await t.pumpAndSettle();
        await press(t, l.registrationCreate);
        await t.pumpAndSettle();
        expect(find.text(l.registrationNameRequired), findsOneWidget);
        expect(find.text(l.recoveryEmailRequired), findsOneWidget);
        expect(find.text(l.recoveryCreateRequired), findsOneWidget);
        expect(f.submittedRole, isNull);
        final fields = find.byType(TextFormField);
        await t.enterText(fields.at(0), 'Original Name');
        await t.enterText(fields.at(1), 'original@example.com');
        await t.enterText(fields.at(2), 'ExamplePassword25!');
        await t.enterText(fields.at(3), 'ExamplePassword25!');
        await press(t, l.driver);
        await t.pumpAndSettle();
        await press(t, l.registrationCreate);
        expect(f.submittedRole, UserRole.operator);
        expect(f.submittedName, 'Original Name');
        expect(find.byType(OperatorDashboardScreen), findsNothing);
        f.outcome.completeError(
          FirebaseAuthException(
            code: 'future-code',
            message: 'private provider detail',
          ),
        );
        await t.pumpAndSettle();
        expect(find.text(l.registrationFailed), findsOneWidget);
        expect(find.textContaining('private provider detail'), findsNothing);
        expect(find.byType(OperatorDashboardScreen), findsNothing);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'registration $lang social placeholders do not register an account',
      (t) async {
        narrow(t);
        await AccessibilityPreferencesService.instance.setHighContrast(true);
        final l = lookupAppLocalizations(Locale(lang));
        final f = RegistrationFixture();
        await t.pumpWidget(host(lang, RegisterScreen(authService: f)));
        await t.pumpAndSettle();
        await press(t, l.registrationGoogle);
        await t.pumpAndSettle();
        expect(
          find.text(l.profileComingSoon(l.registrationGoogleFeature)),
          findsOneWidget,
        );
        expect(f.submittedRole, isNull);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'onboarding $lang three pages preserve preview disclosures at 320dp/200%',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        await t.pumpWidget(host(lang, const OnboardingScreen()));
        await t.pumpAndSettle();
        expect(find.text(l.onboardingTailored), findsOneWidget);
        expect(find.text(l.onboardingNeedsHelp), findsOneWidget);
        await press(t, l.onboardingNext);
        await t.pumpAndSettle();
        expect(find.text(l.onboardingNavigate), findsOneWidget);
        expect(find.text(l.onboardingLiveHelp), findsOneWidget);
        await press(t, l.onboardingNext);
        await t.pumpAndSettle();
        expect(find.text(l.onboardingCommunity), findsOneWidget);
        expect(find.text(l.onboardingReportsHelp), findsOneWidget);
        await press(t, l.onboardingStart);
        await t.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }
}
