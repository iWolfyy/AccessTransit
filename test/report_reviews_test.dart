import 'dart:async';
import 'dart:convert';

import 'package:access_transit/screens/community/report_reviews_screen.dart';
import 'package:access_transit/services/moderation_client.dart';
import 'package:access_transit/widgets/moderation_account_gate.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class Fixture {
  bool appealed = false, reviewed = false, fail = false;
  final paths = <String>[];
  late final api = ModerationClient(
    origin: Uri.parse('https://test.local'),
    client: MockClient((request) async {
      paths.add(request.url.path);
      final data = jsonDecode(request.body);
      expect(data.containsKey('actorUid'), false);
      expect(data.containsKey('actorAdmin'), false);
      var result = <String, dynamic>{};
      final brief = {
        'reportId': 'report-1',
        'authorUid': 'author',
        'penalty': 20,
        'strikeCounted': !reviewed,
        'reviewStatus': reviewed
            ? 'overturned'
            : appealed
            ? 'pending'
            : 'unreviewed',
      };
      switch (request.url.path.split('/').last) {
        case 'list':
          result = {
            'items': [brief],
            'next': null,
          };
        case 'detail':
          result = {
            ...brief,
            'falseCount': 5,
            'targetName': 'Bus ABC',
            'summary': 'Ramp broken',
            'description': 'Observed broken ramp',
            'photoUrl': '',
            'observedAt': '2026-10-16T10:00:00Z',
            'appeal': appealed
                ? {
                    'reason': 'The ramp was broken',
                    'status': reviewed ? 'accepted' : 'pending',
                  }
                : null,
            'reviewReason': reviewed ? 'Photograph supports report' : null,
          };
        case 'evidence':
          result = {
            'items': [
              {
                'uid': 'reader',
                'value': 'false',
                'reason': 'The ramp was working',
              },
            ],
            'next': null,
          };
        case 'appeal':
          if (fail) {
            return http.Response(
              '{"error":{"code":"service-unavailable"}}',
              503,
            );
          }
          expect(data['reason'], 'The ramp was broken');
          appealed = true;
          result = {'duplicate': false, 'status': 'pending'};
        case 'decide':
          expect(data['outcome'], 'overturn');
          reviewed = true;
          result = {'duplicate': false, 'outcome': 'overturn'};
        case 'status':
          result = {
            'state': 'permanent',
            'serverTime': '2026-10-16T10:00:00Z',
            'suspendedUntil': null,
            'points': -10,
          };
      }
      return http.Response(
        jsonEncode({
          'policyVersion': 2,
          'uid': 'author',
          'scope': 'normal',
          ...result,
        }),
        200,
      );
    }),
    identity: () async => const ModerationIdentity('author', 'token'),
    currentUid: () => 'author',
  );
}

void main() {
  test('overturned report is visible with historical false votes and survives copies', () {
    final r = Report.fromMap({
      'policyVersion': 2,
      'moderationOverturned': true,
      'falseCount': 5,
      'status': 'active',
    }, id: 'r');
    expect(r.isDisputed, false);
    expect(r.copyWith(description: 'copy').isDisputed, false);
    expect(r.toMap()['moderationOverturned'], true);
    expect(
      Report.fromMap({...r.toMap(), 'status': 'hidden'}, id: 'r').isDisputed,
      true,
    );
  });
  testWidgets(
    'author sees penalty and can appeal only after acknowledged save',
    (tester) async {
      final f = Fixture();
      addTearDown(f.api.dispose);
      await tester.pumpWidget(
        MaterialApp(home: ReportReviewsScreen(client: f.api)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('report-1'));
      await tester.pumpAndSettle();
      expect(find.textContaining('20 points'), findsOneWidget);
      expect(find.textContaining('5 other users'), findsOneWidget);
      expect(find.text('Overturn decision'), findsNothing);
      await tester.enterText(find.byType(TextField), 'The ramp was broken');
      await tester.ensureVisible(find.text('Submit appeal'));
      f.fail = true;
      await tester.tap(find.text('Submit appeal'));
      await tester.pumpAndSettle();
      expect(f.appealed, false);
      expect(find.text('Appeal pending'), findsNothing);
      f.fail = false;
      await tester.tap(find.text('Submit appeal'));
      await tester.pumpAndSettle();
      expect(f.appealed, true);
      expect(find.text('Appeal pending'), findsNWidgets(2));
      expect(find.text('Submit appeal'), findsNothing);
      expect(f.paths.any((p) => p.endsWith('evidence')), false);
    },
  );
  testWidgets('admin reads vote reasons and overturns with a reason', (
    tester,
  ) async {
    final f = Fixture()..appealed = true;
    addTearDown(f.api.dispose);
    await tester.pumpWidget(
      MaterialApp(home: ReportReviewsScreen(client: f.api, admin: true)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('report-1'));
    await tester.pumpAndSettle();
    expect(find.text('The ramp was working'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'Photograph supports report',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Overturn decision'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Overturn decision'));
    await tester.pumpAndSettle();
    expect(f.reviewed, true);
    expect(find.text('Overturn decision'), findsNothing);
    expect(find.text('Photograph supports report'), findsOneWidget);
  });
  testWidgets(
    'suspended author can open private reviews while operations remain removed',
    (tester) async {
      final f = Fixture(),
          accounts = StreamController<String?>(),
          changes = StreamController<void>.broadcast();
      await tester.pumpWidget(
        MaterialApp(
          home: ModerationAccountGate(
            client: f.api,
            accounts: accounts.stream,
            changes: (_) => changes.stream,
            child: const Text('Operations'),
          ),
        ),
      );
      accounts.add('author');
      await tester.pump();
      changes.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Operations'), findsNothing);
      await tester.tap(find.text('My report reviews'));
      await tester.pumpAndSettle();
      expect(find.text('report-1'), findsOneWidget);
      expect(find.text('Operations'), findsNothing);
      accounts.add(null);
      await tester.pumpAndSettle();
      expect(find.text('report-1'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      unawaited(accounts.close());
      unawaited(changes.close());
      f.api.dispose();
    },
  );
  for (final lang in ['en', 'si', 'ta']) {
    testWidgets('review detail fits 320dp at 200 percent text: $lang', (
      tester,
    ) async {
      final f = Fixture();
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
          home: ReportReviewsScreen(client: f.api, admin: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('report-1'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -1700));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
