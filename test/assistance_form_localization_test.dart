import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/models/assistance_target.dart';
import 'package:access_transit/models/boarding_request.dart';
import 'package:access_transit/screens/journey/boarding_assistance_screen.dart';
import 'package:access_transit/screens/journey/assistance_request_status_screen.dart';
import 'package:access_transit/services/auth_service.dart';
import 'package:access_transit/services/assistance_submission_service.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'registration_onboarding_localization_test.dart' show host, narrow;
import 'assistance_request_target_test.dart'
    show FixtureService, FixtureUser, fixtureStop;

class ReviewUser extends FixtureUser {
  ReviewUser(this.id);
  final String id;
  @override
  String get uid => id;
}

class ReviewAuth extends AuthService {
  String id = 'real-rider';
  @override
  User? get currentUser => ReviewUser(id);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init();
    await AccessibilityPreferencesService.instance.setHighContrast(false);
  });
  for (final lang in ['en', 'si', 'ta']) {
    for (final contrast in [false, true]) {
      testWidgets(
        '$lang assistance target review and stable payload 200% contrast=$contrast',
        (t) async {
          narrow(t);
          await AccessibilityPreferencesService.instance.setHighContrast(
            contrast,
          );
          final repository = FixtureService(), auth = ReviewAuth();
          final sent = <BoardingRequest>[];
          final submission = AssistanceSubmissionService(
            currentRiderId: () => auth.id,
            publisher: (r) async {
              sent.add(r);
              return r;
            },
          );
          addTearDown(submission.dispose);
          await t.pumpWidget(
            host(
              lang,
              BoardingAssistanceScreen(
                busId: 'bus_101',
                stationId: 'destination',
                stopName: fixtureStop.name,
                busLabel: 'Original bus label',
                purpose: AssistancePurpose.alighting,
                serviceRunId: 'selected-run',
                boardingStationId: 'boarding',
                alightingStationId: 'destination',
                firestoreService: repository,
                authService: auth,
                submissionService: submission,
              ),
            ),
          );
          await t.pumpAndSettle();
          final l = lookupAppLocalizations(Locale(lang));
          expect(find.text('Original bus label'), findsOneWidget);
          expect(find.text(l.assistFormEtaUnknown), findsOneWidget);
          await t.scrollUntilVisible(find.text(l.assistFormSend), 200);
          await t.pumpAndSettle();
          await t.tap(find.text(l.assistFormSend));
          await t.pumpAndSettle();
          expect(find.text(l.assistFormSelect), findsOneWidget);
          await t.pump(const Duration(seconds: 5));
          await t.pumpAndSettle();
          for (final label in [
            l.assistFormRamp,
            l.assistFormTime,
            l.assistFormAlighting,
          ]) {
            await t.scrollUntilVisible(find.text(label), -200);
            await t.pumpAndSettle();
            await t.tap(find.text(label));
            await t.pumpAndSettle();
          }
          await t.scrollUntilVisible(find.text(l.assistFormSend), 200);
          await t.pumpAndSettle();
          await t.tap(find.text(l.assistFormSend));
          await t.pumpAndSettle();
          expect(find.text(l.assistFormConfirm), findsOneWidget);
          expect(
            find.textContaining(l.assistFormAlightAt(fixtureStop.name)),
            findsWidgets,
          );
          expect(sent, isEmpty);
          await t.tap(find.text(l.assistFormEdit));
          await t.pumpAndSettle();
          await t.tap(find.text(l.assistFormSend));
          await t.pumpAndSettle();
          await t.tap(find.text(l.assistFormSendConfirm));
          await t.pumpAndSettle();
          expect(sent.single.assistanceTypes, [
            'Deploy Ramp',
            'Extra Time',
            'Alighting Help',
          ]);
          expect(sent.single.serviceRunId, 'selected-run');
          expect(sent.single.stationId, 'destination');
          expect(sent.single.stopName, fixtureStop.name);
          expect(sent.single.riderId, 'real-rider');
          expect(find.byType(AssistanceRequestStatusScreen), findsOneWidget);
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
        },
      );
    }
    testWidgets('$lang changing account during assistance review cannot send', (
      t,
    ) async {
      narrow(t);
      final auth = ReviewAuth(), repository = FixtureService();
      final sent = <BoardingRequest>[];
      final submission = AssistanceSubmissionService(
        currentRiderId: () => auth.id,
        publisher: (r) async {
          sent.add(r);
          return r;
        },
      );
      addTearDown(submission.dispose);
      await t.pumpWidget(
        host(
          lang,
          BoardingAssistanceScreen(
            busId: 'bus_101',
            stationId: 'destination',
            stopName: fixtureStop.name,
            busLabel: 'Original bus',
            firestoreService: repository,
            authService: auth,
            submissionService: submission,
            purpose: AssistancePurpose.boarding,
            serviceRunId: 'run',
            boardingStationId: 'boarding',
            alightingStationId: 'destination',
            minutesAway: 5,
          ),
        ),
      );
      await t.pumpAndSettle();
      final l = lookupAppLocalizations(Locale(lang));
      expect(find.text(l.assistFormArrival('Original bus', 5)), findsOneWidget);
      await t.scrollUntilVisible(find.text(l.assistFormBoarding), 200);
      await t.pumpAndSettle();
      await t.tap(find.text(l.assistFormBoarding));
      await t.scrollUntilVisible(find.text(l.assistFormSend), 200);
      await t.pumpAndSettle();
      await t.tap(find.text(l.assistFormSend));
      await t.pumpAndSettle();
      auth.id = 'other';
      await t.tap(find.text(l.assistFormSendConfirm));
      await t.pumpAndSettle();
      expect(find.text(l.assistFormAccountChanged), findsOneWidget);
      expect(sent, isEmpty);
      expect(find.byType(BoardingAssistanceScreen), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }
}
