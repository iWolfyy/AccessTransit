import 'dart:convert';

import 'package:access_transit/screens/admin/ban_reviews_screen.dart';
import 'package:access_transit/services/moderation_client.dart';
import 'package:access_transit/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class BanFixture {
  bool pendingAppeals = false, stale = false, fail = false;
  String status = 'pending';
  int decisions = 0;
  late final api = ModerationClient(
    origin: Uri.parse('https://test.local'),
    identity: () async => const ModerationIdentity('admin', 'token'),
    currentUid: () => 'admin',
    client: MockClient((r) async {
      final body = jsonDecode(r.body);
      expect(body.containsKey('actorAdmin'), false);
      expect(body.containsKey('actorUid'), false);
      final envelope = {'policyVersion': 2, 'uid': 'admin', 'scope': 'normal'};
      final item = {'accountId': 'author', 'strikeCount': 10, 'status': status};
      Map<String, dynamic> data;
      switch (r.url.path.split('/').last) {
        case 'list':
          data = {
            'items': [item],
            'next': null,
          };
        case 'detail':
          data = {
            ...item,
            'currentStrikes': 10,
            'revision': 14,
            'pendingAppeals': pendingAppeals,
            'name': 'Report Author',
            'email': 'author@local.test',
            'reason': status == 'pending' ? null : 'Reviewed all evidence',
          };
        case 'evidence':
          data = {
            'items': [
              {
                'reportId': 'report-1',
                'strikeCounted': true,
                'reviewStatus': 'unreviewed',
              },
            ],
            'next': null,
          };
        case 'decide':
          expect(body['expectedRevision'], 14);
          expect(body['reason'], 'Reviewed all evidence');
          if (stale || fail) {
            return http.Response(
              jsonEncode({
                'error': {
                  'code': stale ? 'review-stale' : 'service-unavailable',
                },
              }),
              409,
            );
          }
          decisions++;
          status = body['outcome'] == 'approve' ? 'approved' : 'rejected';
          data = {'outcome': body['outcome'], 'duplicate': false};
        default:
          throw StateError('Unexpected route');
      }
      return http.Response(jsonEncode({...envelope, ...data}), 200);
    }),
  );
}

Future<void> open(WidgetTester tester, BanFixture f) async {
  await tester.pumpWidget(MaterialApp(home: BanReviewsScreen(client: f.api)));
  await tester.pumpAndSettle();
  await tester.tap(find.text('author'));
  await tester.pumpAndSettle();
}

Future<void> reason(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'Reviewed all evidence');
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
}

void main() {
  for (final outcome in ['approve', 'reject']) {
    testWidgets(
      'admin $outcome is acknowledged with evidence revision and reason',
      (tester) async {
        final f = BanFixture();
        addTearDown(f.api.dispose);
        await open(tester, f);
        expect(find.text('Current strikes: 10'), findsOneWidget);
        expect(find.text('report-1'), findsOneWidget);
        await reason(tester);
        final button = find.text(
          outcome == 'approve'
              ? 'Approve permanent ban'
              : 'Reject permanent ban',
        );
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(f.decisions, 1);
        expect(
          find.text(
            outcome == 'approve'
                ? 'Permanent ban approved'
                : 'Permanent ban rejected',
          ),
          findsOneWidget,
        );
        expect(find.byType(TextField), findsNothing);
      },
    );
  }
  testWidgets(
    'pending appeal disables approval and stale decision requires refreshed evidence',
    (tester) async {
      final f = BanFixture()..pendingAppeals = true;
      addTearDown(f.api.dispose);
      await open(tester, f);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Approve permanent ban'),
            )
            .onPressed,
        isNull,
      );
      f.pendingAppeals = false;
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();
      await reason(tester);
      f.stale = true;
      await tester.ensureVisible(find.text('Approve permanent ban'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approve permanent ban'));
      await tester.pumpAndSettle();
      expect(f.decisions, 0);
      expect(
        find.text('Evidence changed. Refresh this case before deciding.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Approve permanent ban'),
            )
            .onPressed,
        isNull,
      );
    },
  );
  testWidgets('failed decision retains form and never claims success', (
    tester,
  ) async {
    final f = BanFixture()..fail = true;
    addTearDown(f.api.dispose);
    await open(tester, f);
    await reason(tester);
    await tester.ensureVisible(find.text('Approve permanent ban'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approve permanent ban'));
    await tester.pumpAndSettle();
    expect(f.decisions, 0);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Permanent ban approved'), findsNothing);
  });
  for (final lang in ['en', 'si', 'ta']) {
    testWidgets('ban review fits $lang at 320dp and 200 percent text', (
      tester,
    ) async {
      final f = BanFixture();
      addTearDown(f.api.dispose);
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(lang),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: BanReviewsScreen(client: f.api),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('author'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -1400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
