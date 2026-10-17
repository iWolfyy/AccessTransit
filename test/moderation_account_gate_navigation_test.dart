import 'dart:async';
import 'dart:convert';

import 'package:access_transit/services/moderation_client.dart';
import 'package:access_transit/widgets/moderation_account_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Workspace extends StatefulWidget {
  const _Workspace(this.started, this.disposed);
  final VoidCallback started, disposed;
  @override
  State<_Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<_Workspace> {
  @override
  void initState() {
    super.initState();
    widget.started();
  }

  @override
  void dispose() {
    widget.disposed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        const TextField(),
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  const Scaffold(body: Text('Selected bus details')),
            ),
          ),
          child: const Text('Open details'),
        ),
      ],
    ),
  );
}

http.Response status(String state) => http.Response(
  jsonEncode({
    'uid': 'reader',
    'scope': 'normal',
    'policyVersion': 2,
    'state': state,
    'serverTime': '2026-10-17T10:00:00Z',
    'suspendedUntil': null,
    'points': 10,
  }),
  200,
);

void main() {
  testWidgets('startup retries transient failure without flashing errors or duplicating checks', (t) async {
    final accounts = StreamController<String?>();
    final changes = StreamController<void>.broadcast();
    final response = Completer<http.Response>();
    var calls = 0;
    final client = ModerationClient(
      origin: Uri.parse('https://test.local'), sample: false,
      currentUid: () => 'reader',
      identity: () async => const ModerationIdentity('reader', 'test-token'),
      client: MockClient((_) {
        calls++;
        return calls == 1
          ? Future.value(http.Response('{"error":{"code":"service-unavailable"}}', 503))
          : response.future;
      }),
    );
    await t.pumpWidget(MaterialApp(home: ModerationAccountGate(
      client: client, accounts: accounts.stream, changes: (_) => changes.stream,
      child: const Text('Verified workspace'),
    )));
    accounts.add('reader');
    await t.pump();
    await t.pump();
    expect(find.text('Verified workspace'), findsNothing);
    expect(find.textContaining('could not be verified'), findsNothing);
    changes.add(null);
    changes.add(null);
    await t.pump(const Duration(milliseconds: 300));
    await t.pump();
    expect(calls, 2);
    expect(find.textContaining('could not be verified'), findsNothing);
    response.complete(status('active'));
    await t.pumpAndSettle();
    expect(find.text('Verified workspace'), findsOneWidget);
    expect(calls, 2);
    await t.pumpWidget(const SizedBox());
    unawaited(accounts.close());
    unawaited(changes.close());
    client.dispose();
  });
  for (final finalState in ['active', 'permanent', 'unavailable']) {
    testWidgets(
      'root account gate retains navigation during recheck, then handles $finalState',
      (t) async {
        final accounts = StreamController<String?>(),
            changes = StreamController<void>.broadcast();
        Future<http.Response>? pending;
        final client = ModerationClient(
          origin: Uri.parse('https://test.local'),
          sample: false,
          currentUid: () => 'reader',
          identity: () async =>
              const ModerationIdentity('reader', 'test-token'),
          client: MockClient((_) => pending ?? Future.value(status('active'))),
        );
        var started = 0, disposed = 0;
        await t.pumpWidget(
          MaterialApp(
            builder: (context, child) => ModerationAccountGate(
              client: client,
              accounts: accounts.stream,
              changes: (_) => changes.stream,
              child: child!,
            ),
            home: _Workspace(() => started++, () => disposed++),
          ),
        );
        accounts.add('reader');
        await t.pump();
        changes.add(null);
        await t.pumpAndSettle();
        await t.enterText(find.byType(TextField), 'Unsaved selection');
        await t.tap(find.text('Open details'));
        await t.pumpAndSettle();
        expect(find.text('Selected bus details'), findsOneWidget);
        final response = Completer<http.Response>();
        pending = response.future;
        // Resume/metadata events must not replace the selected screen with a
        // blocking account-check page once this account has been verified.
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        changes.add(null);
        await t.pump();
        await t.pump();
        expect(find.text('Selected bus details'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(disposed, 0);
        expect(started, 1);
        response.complete(
          finalState == 'unavailable'
              ? http.Response('{"error":{"code":"service-unavailable"}}', 503)
              : status(finalState),
        );
        await t.pumpAndSettle();
        if (finalState == 'unavailable') {
          await t.pump(const Duration(seconds: 1));
          await t.pumpAndSettle();
        }
        if (finalState == 'active') {
          expect(find.text('Selected bus details'), findsOneWidget);
          expect(disposed, 0);
          expect(started, 1);
          t.state<NavigatorState>(find.byType(Navigator).first).pop();
          await t.pumpAndSettle();
          expect(find.text('Unsaved selection'), findsOneWidget);
          final switchedResponse = Completer<http.Response>();
          pending = switchedResponse.future;
          accounts.add('different-reader');
          await t.pump();
          await t.pump();
          expect(find.text('Unsaved selection'), findsNothing);
          expect(disposed, 1);
          switchedResponse.complete(status('active'));
          await t.pumpAndSettle();
        } else {
          expect(find.text('Selected bus details'), findsNothing);
          expect(disposed, 1);
        }
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        unawaited(accounts.close());
        unawaited(changes.close());
        client.dispose();
      },
    );
  }
}
