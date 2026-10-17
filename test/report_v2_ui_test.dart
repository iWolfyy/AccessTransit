import 'dart:async';
import 'dart:convert';

import 'package:access_transit/models/report.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:access_transit/services/moderation_client.dart';
import 'package:access_transit/widgets/report_v2_votes.dart';
import 'package:access_transit/widgets/moderation_account_gate.dart';
import 'package:access_transit/logic/status_logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Report report() => Report(
  id: 'r-v2-ui',
  policyVersion: 2,
  userId: 'author',
  targetType: 'bus',
  targetId: 'bus',
  problemType: 'Ramp broken',
  status: 'active',
  createdAt: DateTime.now(),
  falseCount: 4,
  confirmCount: 0,
);
ModerationClient client(http.Client transport, String Function() actor) =>
    ModerationClient(
      origin: Uri.parse('https://test.local'),
      client: transport,
      currentUid: actor,
      identity: () async => ModerationIdentity(actor(), 'test-token'),
    );

void main() {
  test(
    'v2 remains visible at four False votes; v1 keeps its historical threshold',
    () {
      final r = report();
      expect(StatusLogic.isReportActive(r), isTrue);
      expect(r.flagThreshold, 5);
      expect(StatusLogic.isReportActive(r.copyWith(policyVersion: 1)), isFalse);
      expect(
        StatusLogic.isReportActive(r.copyWith(falseCount: 5, status: 'hidden')),
        isFalse,
      );
      final restored = Report.fromMap(r.toMap(), id: r.id);
      expect(restored.policyVersion, 2);
    },
  );
  testWidgets(
    'False voting collects a reason and updates only after backend acknowledgement',
    (tester) async {
      var posted = false, hidden = false;
      final api = client(
        MockClient((request) async {
          final envelope = {
            'uid': 'reader',
            'policyVersion': 2,
            'scope': 'normal',
            'reportId': 'r-v2-ui',
          };
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
          final body = jsonDecode(request.body);
          expect(body['reason'], 'Ramp is working');
          expect(body.containsKey('actorUid'), isFalse);
          posted = true;
          hidden = true;
          return http.Response(
            jsonEncode({
              ...envelope,
              'hidden': true,
              'duplicate': false,
              'falseCount': 5,
              'confirmCount': 0,
            }),
            200,
          );
        }),
        () => 'reader',
      );
      final service = FirestoreService(
        moderation: api,
        reportActorId: () => 'reader',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportV2Votes(report: report(), service: service),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('False (4/5)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit vote'));
      await tester.pumpAndSettle();
      expect(find.text('Enter at least 5 characters.'), findsOneWidget);
      expect(posted, isFalse);
      await tester.enterText(find.byType(TextFormField), 'Ramp is working');
      await tester.tap(find.text('Submit vote'));
      await tester.pumpAndSettle();
      expect(posted, isTrue);
      expect(find.text('Vote acknowledged.'), findsOneWidget);
      expect(find.text('Voting is closed.'), findsOneWidget);
      api.dispose();
    },
  );
  testWidgets('author has neither vote control nor a private-state request', (
    tester,
  ) async {
    final api = client(
      MockClient((_) async => fail('author must not request voting controls')),
      () => 'author',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportV2Votes(
            report: report(),
            service: FirestoreService(
              moderation: api,
              reportActorId: () => 'author',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('You cannot vote on your own report.'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
    api.dispose();
  });
  testWidgets(
    'voting controls fit 320dp and 200 percent text with failed-state retry',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var failRequest = true;
      final api = client(
        MockClient(
          (_) async => failRequest
              ? http.Response('{}', 503)
              : http.Response(
                  jsonEncode({
                    'uid': 'reader',
                    'policyVersion': 2,
                    'scope': 'normal',
                    'reportId': 'r-v2-ui',
                    'userVote': null,
                    'isAuthor': false,
                    'status': 'active',
                    'falseCount': 4,
                    'confirmCount': 0,
                  }),
                  200,
                ),
        ),
        () => 'reader',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: ReportV2Votes(
                  report: report(),
                  service: FirestoreService(
                    moderation: api,
                    reportActorId: () => 'reader',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Retry vote status'), findsOneWidget);
      failRequest = false;
      await tester.tap(find.text('Retry vote status'));
      await tester.pumpAndSettle();
      expect(find.text('False (4/5)'), findsOneWidget);
      expect(tester.takeException(), isNull);
      api.dispose();
    },
  );
  testWidgets(
    'account restriction disposes operational workspace and cannot be bypassed by old session UI',
    (tester) async {
      final accounts = StreamController<String?>(),
          changes = StreamController<void>.broadcast();
      var blocked = false;
      final api = client(
        MockClient(
          (_) async => http.Response(
            jsonEncode({
              'uid': 'reader',
              'policyVersion': 2,
              'scope': 'normal',
              'state': blocked ? 'permanent' : 'active',
              'banReason': blocked
                  ? 'Reviewed repeated community disputes'
                  : null,
              'serverTime': '2026-10-16T10:00:00.000Z',
              'suspendedUntil': null,
              'points': -10,
            }),
            200,
          ),
        ),
        () => 'reader',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ModerationAccountGate(
            client: api,
            accounts: accounts.stream,
            changes: (_) => changes.stream,
            child: const Text('Operational workspace'),
          ),
        ),
      );
      accounts.add('reader');
      await tester.pump();
      changes.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Operational workspace'), findsOneWidget);
      blocked = true;
      changes.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Operational workspace'), findsNothing);
      expect(find.textContaining('Account suspended.'), findsOneWidget);
      expect(find.text('Reviewed repeated community disputes'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      unawaited(accounts.close());
      unawaited(changes.close());
      api.dispose();
    },
  );
}
