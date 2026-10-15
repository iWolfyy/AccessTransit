import 'dart:async';

import 'package:access_transit/services/operator_access_service.dart';
import 'package:access_transit/widgets/operator_access_gate.dart';
import 'package:access_transit/screens/operator/operator_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Access extends OperatorAccessService {
  final accounts = StreamController<String?>.broadcast();
  final approvals = <String, StreamController<bool>>{};
  @override
  Stream<String?> get userIds => accounts.stream;
  @override
  Stream<bool> watchApproval(String uid) => approvals
      .putIfAbsent(uid, () => StreamController<bool>.broadcast())
      .stream;
  Future<void> close() async {
    await accounts.close();
    for (final stream in approvals.values) {
      await stream.close();
    }
  }
}

void main() {
  testWidgets(
    'direct dashboard navigation without sign-in cannot load operator controls',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OperatorDashboardScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sign in to check operator approval.'), findsOneWidget);
      expect(find.text('Assign to Me'), findsNothing);
    },
  );

  testWidgets(
    'approval required, revocation and account switching withdraw the dashboard',
    (tester) async {
      final service = _Access();
      await tester.pumpWidget(
        MaterialApp(
          home: OperatorAccessGate(
            service: service,
            builder: (_) => const Scaffold(body: Text('Operator controls')),
          ),
        ),
      );
      service.accounts.add('first');
      await tester.pumpAndSettle();
      service.approvals['first']!.add(false);
      await tester.pumpAndSettle();
      expect(find.text('Operator controls'), findsNothing);
      service.approvals['first']!.add(true);
      await tester.pumpAndSettle();
      expect(find.text('Operator controls'), findsOneWidget);
      service.approvals['first']!.add(false);
      await tester.pumpAndSettle();
      expect(find.text('Operator controls'), findsNothing);
      service.approvals['first']!.add(true);
      await tester.pumpAndSettle();
      service.accounts.add('second');
      await tester.pumpAndSettle();
      expect(find.text('Operator controls'), findsNothing);
      service.approvals['first']!.add(true);
      await tester.pumpAndSettle();
      expect(find.text('Operator controls'), findsNothing);
      service.approvals['second']!.add(true);
      await tester.pumpAndSettle();
      service.approvals['second']!.addError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text('Operator controls'), findsNothing);
      service.accounts.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Sign in to check operator approval.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await service.close();
    },
  );

  testWidgets('resume requires a new approval receipt', (tester) async {
    final service = _Access();
    await tester.pumpWidget(
      MaterialApp(
        home: OperatorAccessGate(
          service: service,
          builder: (_) => const Scaffold(body: Text('Operator controls')),
        ),
      ),
    );
    service.accounts.add('operator');
    await tester.pumpAndSettle();
    service.approvals['operator']!.add(true);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    service.accounts.add('operator');
    await tester.pumpAndSettle();
    expect(find.text('Operator controls'), findsNothing);
    service.approvals['operator']!.add(true);
    await tester.pumpAndSettle();
    expect(find.text('Operator controls'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await service.close();
  });
}
