import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/models/user_model.dart';
import 'package:access_transit/screens/profile/help_center_screen.dart';
import 'package:access_transit/screens/profile/profile_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'registration_onboarding_localization_test.dart' show host, narrow;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init();
    await AccessibilityPreferencesService.instance.setHighContrast(false);
  });
  for (final lang in ['en', 'si', 'ta']) {
    for (final contrast in [false, true]) {
      testWidgets('$lang help topics at 320dp/200% contrast=$contrast', (
        t,
      ) async {
        narrow(t);
        await AccessibilityPreferencesService.instance.setHighContrast(
          contrast,
        );
        await t.pumpWidget(host(lang, const HelpCenterScreen()));
        await t.pumpAndSettle();
        final l = AppLocalizations.of(
          t.element(find.byType(HelpCenterScreen)),
        )!;
        final topics = [
          (l.helpSearchTitle, l.helpSearchBody),
          (l.helpSaveTitle, l.helpSaveBody),
          (l.helpLocationTitle, l.helpLocationBody),
          (l.helpLiveTitle, l.helpLiveBody),
          (l.helpReportsTitle, l.helpReportsBody),
          (l.helpVotesTitle, l.helpVotesBody),
          (l.helpAssistanceTitle, l.helpAssistanceBody),
          (l.helpAccessTitle, l.helpAccessBody),
        ];
        for (final topic in topics) {
          await t.ensureVisible(find.text(topic.$1));
          await t.tap(find.text(topic.$1));
          await t.pumpAndSettle();
          expect(find.text(topic.$2), findsOneWidget);
          expect(t.takeException(), isNull);
          await t.ensureVisible(find.text(topic.$1));
          await t.tap(find.text(topic.$1));
          await t.pumpAndSettle();
          expect(find.text(topic.$2), findsNothing);
        }
        await t.pumpWidget(const SizedBox());
      });
    }
    testWidgets('$lang Profile opens help and back preserves profile', (
      t,
    ) async {
      narrow(t);
      final l = lookupAppLocalizations(Locale(lang));
      const user = UserModel(
        uid: 'help-fixture',
        name: 'Original Rider',
        email: 'rider@example.com',
      );
      await t.pumpWidget(host(lang, const ProfileScreen(initialUser: user)));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text(l.profileHelp));
      await t.pumpAndSettle();
      await t.tap(find.text(l.profileHelp));
      await t.pumpAndSettle();
      expect(find.byType(HelpCenterScreen), findsOneWidget);
      expect(find.text(l.profileComingSoon(l.profileHelp)), findsNothing);
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      expect(find.byType(HelpCenterScreen), findsNothing);
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }
}
