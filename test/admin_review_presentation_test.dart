import 'dart:convert';

import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/l10n/moderation_presentation.dart';
import 'package:access_transit/screens/admin/active_operations_screen.dart';
import 'package:access_transit/screens/admin/ban_reviews_screen.dart';
import 'package:access_transit/screens/community/report_reviews_screen.dart';
import 'package:access_transit/services/moderation_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'ban_reviews_test.dart' as bans;
import 'report_reviews_test.dart' as reports;

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
  for (final lang in ['en', 'si', 'ta']) {
    testWidgets(
      'ban unknown status $lang never claims pending or allows approval',
      (t) async {
        t.view.physicalSize = const Size(320, 1500);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final f = bans.BanFixture()..status = 'future-state';
        addTearDown(f.api.dispose);
        final l = lookupAppLocalizations(Locale(lang));
        await t.pumpWidget(host(lang, BanReviewsScreen(client: f.api)));
        await t.pumpAndSettle();
        expect(find.textContaining(l.adminRunUnknown), findsOneWidget);
        expect(find.textContaining(l.bansPending), findsNothing);
        await t.tap(find.text('author'));
        await t.pumpAndSettle();
        expect(find.text(l.bansApprove), findsNothing);
        expect(f.decisions, 0);
        expect(t.takeException(), isNull);
      },
    );
    testWidgets(
      'community evidence and specific review messages $lang use localized labels',
      (t) async {
        t.view.physicalSize = const Size(320, 1500);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final f = reports.Fixture();
        addTearDown(f.api.dispose);
        final l = lookupAppLocalizations(Locale(lang));
        await t.pumpWidget(
          host(
            lang,
            ReportReviewsScreen(
              client: f.api,
              admin: true,
              initialReportId: 'report-1',
            ),
          ),
        );
        await t.pumpAndSettle();
        await t.scrollUntilVisible(
          find.text(l.reviewVoteEvidence('reader', l.voteFalse)),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          find.text(l.reviewVoteEvidence('reader', l.voteFalse)),
          findsOneWidget,
        );
        expect(find.text('reader • false'), findsNothing);
        expect(t.takeException(), isNull);
        await t.pumpWidget(
          host(
            lang,
            Builder(
              builder: (c) => Scaffold(
                body: Text(c.reviewFailure('self-review-forbidden')!),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.text(l.reviewSelfForbidden), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets('unknown report review status keeps decision controls closed', (
    t,
  ) async {
    final client = ModerationClient(
      origin: Uri.parse('https://test.local'),
      identity: () async => const ModerationIdentity('admin', 'signed'),
      currentUid: () => 'admin',
      client: MockClient(
        (r) async => http.Response(
          jsonEncode({
            'policyVersion': 2,
            'uid': 'admin',
            'scope': 'normal',
            if (r.url.path.endsWith('/detail')) ...{
              'reportId': 'report',
              'reviewStatus': 'future-state',
              'penalty': 20,
              'strikeCounted': true,
              'falseCount': 5,
              'targetName': 'Bus',
              'summary': 'Original issue',
              'description': 'Original description',
              'appeal': null,
            } else ...{
              'items': [],
              'next': null,
            },
          }),
          200,
        ),
      ),
    );
    addTearDown(client.dispose);
    final l = lookupAppLocalizations(const Locale('en'));
    await t.pumpWidget(
      host(
        'en',
        ReportReviewsScreen(
          client: client,
          admin: true,
          initialReportId: 'report',
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text(l.adminRunUnknown), findsOneWidget);
    expect(find.text(l.reviewsUnreviewed), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.text(l.reviewsOverturn), findsNothing);
  });
  testWidgets('unavailable operations list never claims no active trips', (
    t,
  ) async {
    final client = ModerationClient(
      origin: Uri.parse('https://test.local'),
      identity: () async => const ModerationIdentity('admin', 'signed'),
      currentUid: () => 'admin',
      client: MockClient(
        (r) async =>
            http.Response('{"error":{"code":"service-unavailable"}}', 503),
      ),
    );
    addTearDown(client.dispose);
    final l = lookupAppLocalizations(const Locale('en'));
    await t.pumpWidget(host('en', ActiveOperationsScreen(client: client)));
    await t.pumpAndSettle();
    expect(find.text(l.operationsError), findsOneWidget);
    expect(find.text(l.operationsEmpty), findsNothing);
  });
}
