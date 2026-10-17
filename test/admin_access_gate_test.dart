import 'dart:async';

import 'package:access_transit/services/admin_access_service.dart';
import 'package:access_transit/widgets/admin_access_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAccess extends AdminAccessService {
  final changes = StreamController<String?>.broadcast();
  final checks = <String, Completer<bool>>{};
  @override
  Stream<String?> get userIds => changes.stream;
  @override
  Future<bool> check(String uid) =>
      checks.putIfAbsent(uid, Completer.new).future;
}

void main() {
  testWidgets(
    'admin gate denies direct access, account switches and stale verification',
    (tester) async {
      final service = FakeAccess();
      await tester.pumpWidget(
        MaterialApp(
          home: AdminAccessGate(
            service: service,
            child: const Scaffold(body: Text('Private admin content')),
          ),
        ),
      );
      service.changes.add('admin');
      await tester.pump();
      expect(find.text('Private admin content'), findsNothing);
      service.changes.add('passenger');
      await tester.pump();
      service.checks['admin']!.complete(true);
      await tester.pump();
      expect(find.text('Private admin content'), findsNothing);
      service.checks['passenger']!.complete(false);
      await tester.pumpAndSettle();
      expect(find.textContaining('administrator claim'), findsOneWidget);
      service.changes.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Private admin content'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await service.changes.close();
    },
  );
  testWidgets(
    'pause hides admin UI; resume rechecks and fails closed on error',
    (tester) async {
      final service = FakeAccess();
      await tester.pumpWidget(
        MaterialApp(
          home: AdminAccessGate(
            service: service,
            child: const Scaffold(body: Text('Private admin content')),
          ),
        ),
      );
      service.changes.add('admin');
      await tester.pump();
      service.checks['admin']!.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('Private admin content'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      service.checks['admin'] = Completer<bool>();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('Private admin content'), findsNothing);
      service.checks['admin']!.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text('Private admin content'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await service.changes.close();
    },
  );
}
