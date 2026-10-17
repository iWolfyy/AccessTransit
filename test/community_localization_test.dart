import 'dart:async';

import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/station.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/screens/community/community_screen.dart';
import 'package:access_transit/screens/journey/report_submitted_screen.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/services/report_submission_service.dart';
import 'package:access_transit/widgets/report_outbox_list.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'registration_onboarding_localization_test.dart' show host, narrow;
import 'report_delivery_layout_test.dart' show MemoryStorage;
import 'report_v2_ui_test.dart' show report;

class FeedFixture extends FirestoreService {
  FeedFixture({String? actor = 'author', String? Function()? identity})
    : super(reportActorId: identity ?? () => actor);
  final updates = StreamController<List<Report>>.broadcast();
  bool surfaced = false;
  @override
  Future<List<Bus>> getBuses() async => [];
  @override
  Future<List<Station>> getStations() async => [];
  @override
  Stream<List<Report>> streamReports({
    String? status,
    String? userId,
    bool surfaceErrors = false,
  }) {
    surfaced = surfaceErrors;
    return updates.stream;
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init(userId: 'author');
    await AccessibilityPreferencesService.instance.setHighContrast(false);
  });
  for (final lang in ['en', 'si', 'ta']) {
    for (final contrast in [false, true]) {
      testWidgets(
        '$lang contrast=$contrast feed distinguishes failure, empty and hidden at 200%',
        (t) async {
          narrow(t);
          await AccessibilityPreferencesService.instance.setHighContrast(
            contrast,
          );
          final service = FeedFixture();
          addTearDown(service.updates.close);
          await t.pumpWidget(host(lang, CommunityScreen(service: service)));
          await t.pump();
          final l = AppLocalizations.of(
            t.element(find.byType(CommunityScreen)),
          )!;
          expect(service.surfaced, isTrue);
          service.updates.addError(StateError('fixture offline'));
          await t.pump();
          expect(find.text(l.communityUnavailable), findsOneWidget);
          expect(find.text(l.communityEmptyTitle), findsNothing);
          await t.tap(find.text(l.communityRetry));
          await t.pump();
          service.updates.add([
            report().copyWith(
              targetName: 'Original place',
              description: 'Original rider words',
              confirmCount: 1,
            ),
          ]);
          await t.pumpAndSettle();
          expect(find.text('Original place'), findsOneWidget);
          expect(find.textContaining('Original rider words'), findsOneWidget);
          expect(find.text(l.communityConfirmedBadge), findsOneWidget);
          expect(t.takeException(), isNull);
          service.updates.add([
            report().copyWith(status: 'hidden', falseCount: 5),
          ]);
          await t.pumpAndSettle();
          expect(find.text('Original place'), findsNothing);
          expect(find.text(l.communityEmptyTitle), findsOneWidget);
          expect(find.text(l.communityEmptyHelp), findsOneWidget);
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
        },
      );
    }

    testWidgets('$lang My Reports filters stale account snapshot', (t) async {
      narrow(t);
      var actor = 'author';
      final service = FeedFixture(identity: () => actor);
      addTearDown(service.updates.close);
      Widget screen() => host(lang, CommunityScreen(service: service));
      await t.pumpWidget(screen());
      await t.pump();
      final l = AppLocalizations.of(t.element(find.byType(CommunityScreen)))!;
      await t.tap(find.text(l.communityMyReportsTab));
      await t.pump();
      service.updates.add([
        report().copyWith(problemType: 'Old account report'),
      ]);
      await t.pumpAndSettle();
      expect(find.text('Old account report'), findsOneWidget);
      actor = 'other';
      await t.pumpWidget(screen());
      await t.pumpAndSettle();
      expect(find.text('Old account report'), findsNothing);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('$lang guest My Reports explains sign in', (t) async {
      narrow(t);
      final service = FeedFixture(actor: null);
      addTearDown(service.updates.close);
      await t.pumpWidget(host(lang, CommunityScreen(service: service)));
      await t.pump();
      final l = AppLocalizations.of(t.element(find.byType(CommunityScreen)))!;
      await t.tap(find.text(l.communityMyReportsTab));
      await t.pumpAndSettle();
      expect(find.text(l.communityOwnSignIn), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets(
      '$lang outbox remains private, opens delivery and clears on switch',
      (t) async {
        narrow(t);
        final service = ReportSubmissionService(
          storage: MemoryStorage(),
          publisher: (_) async {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'unavailable',
            );
          },
        );
        addTearDown(service.dispose);
        await service.activateAccount('author');
        await service.submit(
          report().copyWith(
            problemType: 'Original private issue',
            description: 'Private words',
          ),
        );
        await t.pumpWidget(
          host(
            lang,
            Scaffold(
              body: SingleChildScrollView(
                child: ReportOutboxList(
                  userId: 'author',
                  submissionService: service,
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        final l = AppLocalizations.of(
          t.element(find.byType(ReportOutboxList)),
        )!;
        expect(find.text(l.outboxTitle), findsOneWidget);
        expect(find.text(l.outboxHelp), findsOneWidget);
        expect(find.text('Original private issue'), findsOneWidget);
        expect(find.text('Failed to publish'), findsNothing);
        await t.tap(find.text('Original private issue'));
        await t.pumpAndSettle();
        expect(find.byType(ReportSubmittedScreen), findsOneWidget);
        expect(service.entries.single.report.description, 'Private words');
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await service.activateAccount('other');
        await t.pumpWidget(
          host(
            lang,
            Scaffold(
              body: ReportOutboxList(
                userId: 'other',
                submissionService: service,
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.text('Original private issue'), findsNothing);
        expect(find.text(l.outboxTitle), findsNothing);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
}
