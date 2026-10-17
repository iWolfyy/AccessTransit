import 'dart:async';

import 'package:access_transit/models/boarding_request.dart';
import 'package:access_transit/screens/journey/assistance_request_status_screen.dart';
import 'package:access_transit/services/assistance_submission_service.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:access_transit/widgets/assistance_operator_actions.dart';
import 'package:access_transit/widgets/assistance_requests_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

BoardingRequest request(String id) => BoardingRequest(
  id: id,
  riderId: 'ui_rider',
  riderName: 'Rider',
  busId: 'ui_bus',
  routeNo: '138',
  stationId: 'ui_stop',
  stopName: 'Fort',
  assistanceTypes: const ['Deploy Ramp'],
  status: 'pending',
  createdAt: DateTime(2026, 10, 14),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'receipt separates pending delivery, Sent, driver acceptance and completion',
    (tester) async {
      final value = request('receipt_ui');
      final service = AssistanceSubmissionService(
        currentRiderId: () => 'ui_rider',
        publisher: (r) async => r,
      );
      await service.enqueue(value);
      final updates = StreamController<BoardingRequest?>();
      await tester.pumpWidget(
        MaterialApp(
          home: AssistanceRequestStatusScreen(
            request: value,
            service: service,
            requestUpdates: updates.stream,
          ),
        ),
      );
      expect(find.text('Pending upload'), findsOneWidget);
      expect(
        find.text('Driver acknowledgement is not confirmed.'),
        findsOneWidget,
      );
      await service.retry(value.id);
      await tester.pumpAndSettle();
      expect(find.text('Sent to shared service'), findsOneWidget);
      expect(find.text('Awaiting driver acknowledgement'), findsOneWidget);
      expect(find.textContaining('last received status'), findsOneWidget);
      updates.add(value.copyWith(status: 'acknowledged'));
      await tester.pumpAndSettle();
      expect(find.text('Driver acknowledged'), findsOneWidget);
      expect(
        find.textContaining('has not been marked completed'),
        findsOneWidget,
      );
      updates.add(value.copyWith(status: 'completed'));
      await tester.pumpAndSettle();
      expect(find.text('Driver marked completed'), findsOneWidget);
      expect(find.text('Cancel request'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      unawaited(updates.close());
      service.dispose();
    },
  );

  testWidgets('failed upload keeps retry available and never presents Sent', (
    tester,
  ) async {
    final value = request('failed_ui');
    final service = AssistanceSubmissionService(
      currentRiderId: () => 'ui_rider',
      publisher: (_) async => throw StateError('denied'),
    );
    await service.submit(value);
    await tester.pumpWidget(
      MaterialApp(
        home: AssistanceRequestStatusScreen(
          request: value,
          service: service,
          requestUpdates: Stream.value(null),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('Retry upload'), findsOneWidget);
    expect(find.text('Sent to shared service'), findsNothing);
    expect(find.text('Cancel request'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });

  testWidgets('receipt hides another account request', (tester) async {
    final service = AssistanceSubmissionService(currentRiderId: () => 'other');
    await tester.pumpWidget(
      MaterialApp(
        home: AssistanceRequestStatusScreen(
          request: request('private_ui'),
          service: service,
          requestUpdates: Stream.value(request('private_ui')),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Sign in with the account'), findsOneWidget);
    expect(find.textContaining('Fort'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });

  testWidgets('passenger cancellation failure does not claim Cancelled', (
    tester,
  ) async {
    final value = request('cancel_ui');
    final service = AssistanceSubmissionService(
      currentRiderId: () => 'ui_rider',
    );
    final repository = FirestoreService(
      boardingWriter: (r) async => r,
      boardingStatusWriter: (_, _) async =>
          throw StateError('permission denied'),
    );
    await repository.publishBoardingRequest(value);
    await tester.pumpWidget(
      MaterialApp(
        home: AssistanceRequestStatusScreen(
          request: value,
          service: service,
          repository: repository,
        ),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Cancel request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel request'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Cancellation is not confirmed'),
      findsOneWidget,
    );
    expect(find.text('Awaiting driver acknowledgement'), findsOneWidget);
    expect(find.text('Cancelled'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });

  testWidgets(
    'operator failure retains Pending; Complete appears only after confirmed acknowledgement',
    (tester) async {
      final value = request('operator_ui');
      var shouldFail = true;
      final repository = FirestoreService(
        boardingWriter: (r) async => r,
        boardingStatusWriter: (r, status) async {
          if (shouldFail) throw StateError('denied');
          return r.copyWith(status: status);
        },
      );
      await repository.publishBoardingRequest(value);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistanceOperatorActions(
              request: value,
              repository: repository,
            ),
          ),
        ),
      );
      expect(find.text('Complete'), findsNothing);
      await tester.tap(find.text('Acknowledge'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Status update was not confirmed'),
        findsOneWidget,
      );
      expect(find.text('Awaiting driver acknowledgement'), findsOneWidget);
      expect(find.text('Complete'), findsNothing);
      shouldFail = false;
      await tester.tap(find.text('Acknowledge'));
      await tester.pumpAndSettle();
      expect(find.text('Driver acknowledged'), findsOneWidget);
      expect(find.text('Complete'), findsOneWidget);
      await tester.tap(find.text('Complete'));
      await tester.pumpAndSettle();
      expect(find.text('Driver marked completed'), findsOneWidget);
    },
  );

  testWidgets(
    'home request history reopens saved pending request and hides it after account switch',
    (tester) async {
      String? actor = 'history_rider';
      final service = AssistanceSubmissionService(currentRiderId: () => actor);
      await service.enqueue(
        request('history_ui').copyWith(riderId: 'history_rider'),
      );
      final repository = FirestoreService();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistanceRequestsPanel(
              userId: 'history_rider',
              service: service,
              repository: repository,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Your assistance requests'), findsOneWidget);
      expect(find.text('Pending upload'), findsOneWidget);
      await tester.tap(find.textContaining('Fort'));
      await tester.pumpAndSettle();
      expect(find.text('Assistance request'), findsOneWidget);
      expect(find.text('Retry upload'), findsOneWidget);
      actor = 'other';
      // Rebuild the owning surface as happens on auth notification.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistanceRequestsPanel(
              userId: 'history_rider',
              service: service,
              repository: repository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Your assistance requests'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      service.dispose();
    },
  );
}
