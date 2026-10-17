import 'dart:convert';

import 'package:access_transit/models/boarding_request.dart';
import 'package:access_transit/services/moderation_client.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:access_transit/services/assistance_submission_service.dart';
import 'package:access_transit/widgets/run_assistance_inbox.dart';
import 'package:access_transit/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> requestMap({String status = 'pending', int version = 1}) =>
    {
      'id': 'help',
      'policyVersion': 2,
      'serviceRunId': 'run',
      'busId': 'bus',
      'stationId': 'a',
      'boardingStationId': 'a',
      'alightingStationId': 'b',
      'riderId': 'rider',
      'riderName': 'Rider',
      'driverId': 'driver',
      'assignmentVersion': version,
      'routeNo': '1',
      'stopName': 'Stop A',
      'purpose': 'boarding',
      'assistanceTypes': ['Deploy Ramp'],
      'status': status,
      'createdAt': '2026-10-16T10:00:00Z',
      'expiresAt': '2026-10-16T10:30:00Z',
    };

class Fixture {
  String uid = 'rider', status = 'pending';
  bool unavailable = false;
  final posted = <Map<String, dynamic>>[];
  late final client = ModerationClient(
    origin: Uri.parse('https://local.test'),
    currentUid: () => uid,
    identity: () async => ModerationIdentity(uid, 'token'),
    client: MockClient((r) async {
      final input = jsonDecode(r.body) as Map<String, dynamic>;
      posted.add(input);
      expect(input.containsKey('driverId'), false);
      expect(input.containsKey('riderId'), false);
      if (unavailable) {
        return http.Response('{"error":{"code":"service-unavailable"}}', 503);
      }
      if (r.url.path.endsWith('/action')) status = input['status'];
      final value = requestMap(status: status);
      return http.Response(
        jsonEncode({
          'policyVersion': 2,
          'scope': 'normal',
          'uid': uid,
          ...r.url.path.endsWith('/list')
              ? {
                  'items': [value],
                  'next': null,
                }
              : {'request': value},
        }),
        200,
      );
    }),
  );
  late final repo = FirestoreService(
    v2Assistance: true,
    moderation: client,
    boardingViewerId: () => uid,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'previous account outbox cannot publish under the newly signed-in rider',
    () async {
      final f = Fixture()..uid = 'another-rider';
      addTearDown(f.client.dispose);
      await expectLater(
        f.repo.publishBoardingRequest(
          BoardingRequest.fromMap(requestMap(), id: 'help'),
        ),
        throwsA(isA<ModerationException>()),
      );
      expect(f.posted, isEmpty);
    },
  );
  test('run and selected endpoints survive model/outbox persistence and mismatched retry is rejected', () async {
    final r = BoardingRequest.fromMap(requestMap(), id: 'help');
    expect(r.copyWith(status: 'acknowledged').serviceRunId, 'run');
    expect(
      BoardingRequest.fromMap(r.toMap(), id: 'help').expiresAt,
      r.expiresAt,
    );
    final outbox = AssistanceSubmissionService(currentRiderId: () => 'rider');
    await outbox.enqueue(r);
    final restored = AssistanceSubmissionService(currentRiderId: () => 'rider');
    await restored.init();
    expect(restored.find('help')!.request.alightingStationId, 'b');
    expect(restored.find('help')!.request.serviceRunId, 'run');
    final changed = BoardingRequest.fromMap({
      ...requestMap(),
      'serviceRunId': 'another',
    }, id: 'help');
    await expectLater(outbox.enqueue(changed), throwsStateError);
    outbox.dispose();
    restored.dispose();
  });
  test('trusted publish keeps same run and unavailable response has retryable durable state', () async {
    final f = Fixture();
    addTearDown(f.client.dispose);
    final outbox = AssistanceSubmissionService(
      currentRiderId: () => f.uid,
      publisher: f.repo.publishBoardingRequest,
    );
    addTearDown(outbox.dispose);
    f.unavailable = true;
    final pending = await outbox.submit(
      BoardingRequest.fromMap(requestMap(), id: 'help'),
    );
    expect(pending.delivery, AssistanceDeliveryState.pendingUpload);
    f.unavailable = false;
    f.status = 'acknowledged';
    final saved = await outbox.retry('help');
    expect(saved.delivery, AssistanceDeliveryState.sent);
    expect(saved.request.status, 'acknowledged');
    expect(saved.request.serviceRunId, 'run');
    expect(f.posted.every((r) => r['requestId'] == 'help'), true);
  });
  testWidgets(
    'run inbox actions wait for server response; failed load removes stale private rows',
    (tester) async {
      final f = Fixture()..uid = 'driver';
      addTearDown(f.client.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RunAssistanceInbox(runId: 'run', repository: f.repo),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rider • Stop A'), findsOneWidget);
      expect(find.text('Awaiting driver acknowledgement'), findsOneWidget);
      await tester.tap(find.text('Acknowledge'));
      await tester.pumpAndSettle();
      expect(find.text('Driver acknowledged'), findsOneWidget);
      f.unavailable = true;
      await tester.tap(find.text('Retry account status'));
      await tester.pumpAndSettle();
      expect(find.text('Rider • Stop A'), findsNothing);
      expect(find.text('Driver acknowledged'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('missing selected run never substitutes another bus operation', (
    tester,
  ) async {
    final f = Fixture()..uid = 'driver';
    addTearDown(f.client.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RunAssistanceInbox(runId: null, repository: f.repo),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(f.posted, isEmpty);
    expect(find.textContaining('Choose a dated trip'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  for (final lang in ['en', 'si', 'ta']) {
    testWidgets('run inbox $lang fits 320dp at 200 percent text', (
      tester,
    ) async {
      final f = Fixture()..uid = 'driver';
      addTearDown(f.client.dispose);
      tester.view.physicalSize = const Size(320, 800);
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
          home: Scaffold(
            body: SingleChildScrollView(
              child: RunAssistanceInbox(runId: 'run', repository: f.repo),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
