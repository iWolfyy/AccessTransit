import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/models/user_model.dart';
import 'package:access_transit/screens/profile/rewards_contributions_screen.dart';
import 'package:access_transit/screens/profile/membership_card_screen.dart';
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
      testWidgets(
        '$lang negative rewards and membership at 200% contrast=$contrast',
        (t) async {
          narrow(t);
          await AccessibilityPreferencesService.instance.setHighContrast(
            contrast,
          );
          const user = UserModel(
            uid: 'original-uid',
            name: 'Original Name',
            email: '',
            points: -10,
            reportsSubmitted: 3,
          );
          await t.pumpWidget(
            host(lang, const RewardsContributionsScreen(user: user)),
          );
          await t.pumpAndSettle();
          final l = lookupAppLocalizations(Locale(lang));
          expect(find.text(l.rewardsLegacyNotice), findsOneWidget);
          await t.scrollUntilVisible(find.text('-10'), 200);
          await t.pumpAndSettle();
          expect(find.text('-10'), findsOneWidget);
          expect(find.text(l.rewardsLevel(l.rewardsBronze)), findsOneWidget);
          await t.scrollUntilVisible(find.text(l.rewardsViewCard), 200);
          await t.pumpAndSettle();
          await t.tap(find.text(l.rewardsViewCard));
          await t.pumpAndSettle();
          expect(find.byType(MembershipCardScreen), findsOneWidget);
          expect(find.text(l.memberBronze), findsOneWidget);
          expect(find.text('ORIGINAL NAME'), findsOneWidget);
          expect(find.text(l.memberPointCount(-10)), findsOneWidget);
          await t.ensureVisible(find.text(l.memberNoRedemption));
          await t.pumpAndSettle();
          final redeem = find.widgetWithText(
            FilledButton,
            l.memberNoRedemption,
          );
          expect(t.widget<FilledButton>(redeem).onPressed, isNull);
          expect(find.text(l.memberNoCash), findsOneWidget);
          expect(find.text(l.memberNoPriority), findsOneWidget);
          expect(t.takeException(), isNull);
          await t.ensureVisible(find.text(l.memberBack));
          await t.pumpAndSettle();
          await t.tap(find.text(l.memberBack));
          await t.pumpAndSettle();
          expect(find.byType(RewardsContributionsScreen), findsOneWidget);
          await t.scrollUntilVisible(find.text('-10'), -200);
          await t.pumpAndSettle();
          expect(find.text('-10'), findsOneWidget);
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
        },
      );
    }
    testWidgets(
      '$lang custom tier and identity stay original; gold label translates',
      (t) async {
        narrow(t);
        await t.pumpWidget(
          host(
            lang,
            const MembershipCardScreen(
              memberName: 'Custom Name',
              memberId: 'ID-123',
              memberTier: 'Custom tier',
              roleLabel: 'Original role',
              points: 300,
            ),
          ),
        );
        await t.pumpAndSettle();
        final l = lookupAppLocalizations(Locale(lang));
        expect(find.text('Custom tier'), findsOneWidget);
        expect(find.text('Original role'), findsOneWidget);
        expect(find.text(l.memberIdentity('ID-123')), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await t.pumpWidget(
          host(
            lang,
            const MembershipCardScreen(memberName: 'Rider', points: 300),
          ),
        );
        await t.pumpAndSettle();
        expect(find.text(l.memberGold), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
}
