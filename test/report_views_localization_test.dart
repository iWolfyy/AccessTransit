import 'dart:async';
import 'dart:convert';

import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/l10n/report_view_presentation.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/screens/community/report_details_screen.dart';
import 'package:access_transit/screens/journey/report_submitted_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:access_transit/services/report_submission_service.dart';
import 'package:access_transit/widgets/report_v2_votes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'registration_onboarding_localization_test.dart' show host, narrow;
import 'report_delivery_layout_test.dart' show MemoryStorage;
import 'report_v2_ui_test.dart' as votes;

Future<void> press(WidgetTester t, String label, {bool settle = true}) async {
  final target = find.text(label);
  if (target.evaluate().isEmpty) {
    await t.scrollUntilVisible(
      target,
      250,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .last,
    );
  }
  await Scrollable.ensureVisible(t.element(target), alignment: .5);
  await t.pumpAndSettle();
  await t.tap(target);
  if (settle) {
    await t.pumpAndSettle();
  } else {
    await t.pump();
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init(userId: 'author');
    await AccessibilityPreferencesService.instance.setHighContrast(true);
  });
  for (final lang in ['en', 'si', 'ta']) {
    testWidgets(
      'report details $lang preserves original content and v2 author/five-vote policy',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        final r = votes.report().copyWith(
          problemType: 'Original condition',
          description: 'Original rider note',
          targetName: 'Original target',
        );
        final changes = StreamController<Report?>();
        final api = votes.client(
          MockClient((_) async => fail('Authors cannot load voting controls')),
          () => 'author',
        );
        final service = FirestoreService(
          moderation: api,
          reportActorId: () => 'author',
        );
        await t.pumpWidget(
          host(
            lang,
            ReportDetailsScreen(
              report: r,
              reportUpdates: changes.stream,
              service: service,
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.text(l.reportDetailsTitle), findsOneWidget);
        await press(t, 'Original condition');
        expect(find.text('Original condition'), findsOneWidget);
        await press(t, l.authorVoteDisabled);
        expect(find.textContaining('Original rider note'), findsOneWidget);
        expect(find.text(l.voteNoPoints), findsNothing);
        changes.add(r.copyWith(status: 'hidden', falseCount: 5));
        await t.pumpAndSettle();
        await press(t, l.reportHiddenHelp(5));
        expect(find.text(l.reportHiddenHelp(3)), findsNothing);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        unawaited(changes.close());
        api.dispose();
      },
    );

    testWidgets(
      'v2 False vote $lang validates and waits for receipt before hiding',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        final receipt = Completer<http.Response>();
        var hidden = false;
        final envelope = {
          'uid': 'reader',
          'policyVersion': 2,
          'scope': 'normal',
          'reportId': 'r-v2-ui',
        };
        final api = votes.client(
          MockClient((request) async {
            if (request.url.path.endsWith('vote-status')) {
              return http.Response(
                jsonEncode({
                  ...envelope,
                  'userVote': hidden ? 'false' : null,
                  'isAuthor': false,
                  'status': hidden ? 'hidden' : 'active',
                  'falseCount': hidden ? 5 : 4,
                  'confirmCount': 0,
                }),
                200,
              );
            }
            expect(jsonDecode(request.body)['reason'], 'Original reason');
            return receipt.future;
          }),
          () => 'reader',
        );
        await t.pumpWidget(
          host(
            lang,
            Scaffold(
              body: SingleChildScrollView(
                child: ReportV2Votes(
                  report: votes.report(),
                  service: FirestoreService(
                    moderation: api,
                    reportActorId: () => 'reader',
                  ),
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        await press(t, '${l.voteFalse} (4/5)');
        await press(t, l.voteSubmit);
        expect(find.text(l.falseVoteReasonMinimum), findsOneWidget);
        await t.enterText(find.byType(TextFormField), 'Original reason');
        t.testTextInput.hide();
        await press(t, l.voteSubmit, settle: false);
        expect(find.text(l.voteAcknowledged), findsNothing);
        hidden = true;
        receipt.complete(
          http.Response(
            jsonEncode({
              ...envelope,
              'hidden': true,
              'duplicate': false,
              'falseCount': 5,
              'confirmCount': 0,
            }),
            200,
          ),
        );
        await t.pumpAndSettle();
        expect(find.text(l.voteAcknowledged), findsOneWidget);
        expect(find.text(l.votingClosed), findsOneWidget);
        expect(t.takeException(), isNull);
        api.dispose();
      },
    );

    testWidgets('delivery $lang publishes only after retry acknowledgement', (
      t,
    ) async {
      narrow(t);
      final l = lookupAppLocalizations(Locale(lang));
      final receipt = Completer<void>();
      var first = true;
      final service = ReportSubmissionService(
        storage: MemoryStorage(),
        publisher: (_) async {
          if (first) {
            first = false;
            throw FirebaseException(plugin: 'fixture', code: 'unavailable');
          }
          await receipt.future;
        },
      );
      final entry = await service.submit(
        votes.report().copyWith(
          problemType: 'Original condition',
          targetName: 'Original stop',
        ),
      );
      await t.pumpWidget(
        host(
          lang,
          ReportSubmittedScreen(
            report: entry.report,
            targetName: 'Original stop',
            submissionService: service,
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text(l.deliveryPending), findsOneWidget);
      expect(find.text(l.deliveryWaiting), findsOneWidget);
      await press(t, l.deliveryRetry, settle: false);
      expect(find.text(l.deliveryPublished), findsNothing);
      expect(find.text(l.deliveryUploading), findsOneWidget);
      receipt.complete();
      await t.pumpAndSettle();
      expect(find.text(l.deliveryPublished), findsOneWidget);
      expect(find.text(l.deliveryPublicHelp), findsOneWidget);
      expect(find.text('Original condition'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      service.dispose();
    });

    testWidgets('delivery $lang account switch hides local observation', (
      t,
    ) async {
      narrow(t);
      final l = lookupAppLocalizations(Locale(lang));
      final service = ReportSubmissionService(
        storage: MemoryStorage(),
        publisher: (_) async =>
            throw FirebaseException(plugin: 'fixture', code: 'unavailable'),
      );
      await service.activateAccount('author');
      final entry = await service.submit(
        votes.report().copyWith(problemType: 'Original private draft'),
      );
      await t.pumpWidget(
        host(
          lang,
          ReportSubmittedScreen(
            report: entry.report,
            submissionService: service,
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Original private draft'), findsOneWidget);
      await service.activateAccount('other');
      await t.pumpAndSettle();
      expect(find.text('Original private draft'), findsNothing);
      expect(find.text(l.deliveryRemovedHelp), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      service.dispose();
    });

    testWidgets(
      'share $lang waits for clipboard acknowledgement and preserves original text',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        final copied = Completer<void>();
        String? shared;
        t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              shared = (call.arguments as Map)['text'] as String;
              await copied.future;
            }
            return null;
          },
        );
        addTearDown(
          () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        final r = votes.report().copyWith(
          problemType: 'Original condition',
          targetName: 'Original target',
        );
        await t.pumpWidget(
          host(
            lang,
            ReportDetailsScreen(
              report: r,
              reportUpdates: Stream.value(r),
              service: FirestoreService(reportActorId: () => 'author'),
            ),
          ),
        );
        await t.pumpAndSettle();
        await t.tap(find.byTooltip(l.reportShare));
        await t.pump();
        expect(
          shared,
          l.reportShareText('Original condition', 'Original target'),
        );
        expect(find.text(l.reportCopied), findsNothing);
        copied.complete();
        await t.pumpAndSettle();
        expect(find.text(l.reportCopied), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'report photo failure $lang remains readable at 200 percent text',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        final r = votes.report().copyWith(
          photoUrl: 'https://example.invalid/report-photo.png',
        );
        await t.pumpWidget(
          host(
            lang,
            ReportDetailsScreen(
              report: r,
              reportUpdates: Stream.value(r),
              service: FirestoreService(reportActorId: () => 'author'),
            ),
          ),
        );
        await t.pumpAndSettle();
        await press(t, l.reportPhotoEvidence);
        await t.pumpAndSettle();
        expect(find.text(l.reportPhotoUnavailable), findsOneWidget);
        expect(find.text(l.reportEnlarge), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'delivery $lang translates known failures/cooldown and hides raw errors',
      (t) async {
        final l = lookupAppLocalizations(Locale(lang));
        await t.pumpWidget(
          host(
            lang,
            Builder(
              builder: (c) {
                expect(
                  c.deliveryError('PRIVATE PROVIDER DETAIL'),
                  l.deliveryUploadFailed,
                );
                expect(c.deliveryError(null), l.deliveryPendingHelp);
                expect(
                  c.deliveryError(
                    'Same-issue cooldown. Retry after 2026-10-17T12:30:00.000Z (UTC). Your draft is saved.',
                  ),
                  l.deliveryCooldownAt('2026-10-17T12:30:00.000Z'),
                );
                expect(
                  c.deliveryError(
                    'Same-issue cooldown. Retry after 5 minutes (UTC). Your draft is saved.',
                  ),
                  l.reportCooldownNotice,
                );
                return const SizedBox();
              },
            ),
          ),
        );
      },
    );
  }
}
