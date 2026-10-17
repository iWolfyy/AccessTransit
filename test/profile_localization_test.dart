import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/models/enums/user_role.dart';
import 'package:access_transit/models/user_model.dart';
import 'package:access_transit/screens/profile/profile_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/widgets/logout_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget host(String lang, Widget child) => MaterialApp(
  locale: Locale(lang),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (c, w) => MediaQuery(
    data: MediaQuery.of(c).copyWith(textScaler: const TextScaler.linear(2)),
    child: w!,
  ),
  home: child,
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init();
    await AccessibilityPreferencesService.instance.setHighContrast(false);
  });

  for (final lang in ['en', 'si', 'ta']) {
    testWidgets(
      'profile $lang high contrast labels and unavailable actions remain truthful',
      (t) async {
        t.view.physicalSize = const Size(320, 1500);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        await AccessibilityPreferencesService.instance.setHighContrast(true);
        final l = lookupAppLocalizations(Locale(lang));
        // A profile value identical to an English UI key must stay original.
        const user = UserModel(
          uid: 'fixture',
          name: 'Reports',
          email: '',
          role: UserRole.contributor,
          points: -10,
          reportsSubmitted: 2,
        );
        await t.pumpWidget(host(lang, const ProfileScreen(initialUser: user)));
        await t.pumpAndSettle();
        expect(find.text('Reports'), findsWidgets);
        expect(find.text(l.profileContributor), findsOneWidget);
        expect(find.text(l.profilePersonalInfo), findsOneWidget);
        expect(
          find.text(l.profileContributionSummary(-10, 2, 0)),
          findsOneWidget,
        );
        expect(find.text('+ 9 more badges'), findsNothing);
        await Scrollable.ensureVisible(
          t.element(find.text(l.profileDelete)),
          alignment: 0.5,
        );
        await t.pumpAndSettle();
        expect(find.text(l.profileDeleteUnavailable), findsOneWidget);
        await t.tap(find.text(l.profileDelete));
        await t.pumpAndSettle();
        expect(find.text(l.profileComingSoon(l.profileDelete)), findsOneWidget);
        expect(find.byType(ProfileScreen), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'profile $lang preserves values and failed edits at 320dp/200%',
      (t) async {
        t.view.physicalSize = const Size(320, 1500);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final l = lookupAppLocalizations(Locale(lang));
        const user = UserModel(
          uid: 'fixture',
          name: 'Original Name',
          email: 'rider@example.com',
          points: -10,
          reportsSubmitted: 2,
        );
        await t.pumpWidget(host(lang, const ProfileScreen(initialUser: user)));
        await t.pumpAndSettle();
        expect(find.text('Original Name'), findsWidgets);
        expect(find.text('rider@example.com'), findsWidgets);
        expect(find.text(l.profileCommuter), findsOneWidget);
        await t.tap(find.text(l.profileEdit));
        await t.pumpAndSettle();
        expect(find.text(l.profileEditTitle), findsOneWidget);
        await t.enterText(find.byType(TextFormField).first, '');
        await t.ensureVisible(find.text(l.profileSave));
        await t.tap(find.text(l.profileSave));
        await t.pumpAndSettle();
        expect(find.text(l.profileNameRequired), findsOneWidget);
        await t.enterText(find.byType(TextFormField).first, 'Changed Name');
        await t.ensureVisible(find.text(l.profileSave));
        await t.tap(find.text(l.profileSave));
        await t.pumpAndSettle();
        // No Firebase project is initialized: an unacknowledged write stays failed.
        expect(find.text(l.profileSaveFailed), findsOneWidget);
        expect(find.text('Changed Name'), findsNothing);
        expect(find.text(l.profileSaved), findsNothing);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'logout $lang keeps cancel/confirm and cleanup disclosure at 320dp/200%',
      (t) async {
        t.view.physicalSize = const Size(320, 1500);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final l = lookupAppLocalizations(Locale(lang));
        bool? result;
        await t.pumpWidget(
          host(
            lang,
            Scaffold(
              body: Builder(
                builder: (c) => TextButton(
                  onPressed: () async {
                    result = await showLogoutConfirmationDialog(c);
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await t.tap(find.text('open'));
        await t.pumpAndSettle();
        expect(find.text(l.profileLogoutQuestion), findsOneWidget);
        await t.tap(find.text(l.profileCancel));
        await t.pumpAndSettle();
        expect(result, isFalse);
        await t.tap(find.text('open'));
        await t.pumpAndSettle();
        await t.tap(find.widgetWithText(ElevatedButton, l.profileSignOut));
        await t.pumpAndSettle();
        expect(result, isTrue);
        final c = t.element(find.text('open'));
        showLogoutSuccessSnackBar(context: c);
        await t.pump();
        expect(find.text(l.profileSignedOut), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }
}
