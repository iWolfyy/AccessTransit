import 'dart:convert';

import 'package:access_transit/screens/admin/active_operations_screen.dart';
import 'package:access_transit/services/moderation_client.dart';
import 'package:access_transit/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class Fixture {
  bool fail = false;
  final requests = <Map<String, dynamic>>[];
  late final client = ModerationClient(
    origin: Uri.parse('https://local.test'),
    identity: () async => const ModerationIdentity('admin', 'token'),
    currentUid: () => 'admin',
    client: MockClient((r) async {
      final body = Map<String, dynamic>.from(jsonDecode(r.body));
      expect(body.containsKey('actorAdmin'), false);
      final Map<String, dynamic> data;
      switch (r.url.path.split('/').last) {
        case 'list':
          data = {
            'items': [
              {
                'runId': 'run1',
                'busId': 'b',
                'routeNo': '1',
                'driverId': 'old',
              },
            ],
            'next': null,
          };
        case 'detail':
          data = {
            'runId': 'run1',
            'busId': 'b',
            'routeNo': '1',
            'driverId': 'old',
            'handoverVersion': 3,
            'currentStopIndex': 2,
          };
        case 'candidates':
          data = {
            'items': [
              {'driverId': 'new', 'name': 'New driver'},
            ],
            'next': null,
          };
        case 'handover':
          requests.add(body);
          if (fail) {
            return http.Response(
              jsonEncode({
                'error': {'code': 'operation-stale'},
              }),
              409,
            );
          }
          data = {
            'runId': 'run1',
            'operationId': body['operationId'],
            'handoverVersion': 4,
          };
        default:
          throw StateError(r.url.path);
      }
      return http.Response(
        jsonEncode({
          ...data,
          'policyVersion': 2,
          'uid': 'admin',
          'scope': 'normal',
        }),
        200,
      );
    }),
  );
}

void main() {
  testWidgets(
    'handover validates reason, retains failed operation ID and confirms acknowledged transfer',
    (tester) async {
      final f = Fixture()..fail = true;
      addTearDown(f.client.dispose);
      await tester.pumpWidget(
        MaterialApp(home: ActiveOperationsScreen(client: f.client)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 · b'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New driver'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Driver shift changed');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Transfer trip'));
      await tester.tap(find.text('Transfer trip'));
      await tester.pumpAndSettle();
      expect(f.requests.length, 1);
      await tester.drag(find.byType(ListView), const Offset(0, 1500));
      await tester.pumpAndSettle();
      expect(find.textContaining('eligibility changed'), findsOneWidget);
      expect(f.requests.single['expectedVersion'], 3);
      f.fail = false;
      await tester.scrollUntilVisible(
        find.text('Transfer trip'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Transfer trip'));
      await tester.pumpAndSettle();
      expect(f.requests[1], f.requests[0]);
      await tester.scrollUntilVisible(
        find.textContaining('Transfer acknowledged.'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Transfer acknowledged.'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    },
  );
  for (final locale in ['en', 'si', 'ta']) {
    testWidgets('handover $locale wraps at 320dp and 200 percent text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final f = Fixture();
      addTearDown(f.client.dispose);
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 760),
              textScaler: TextScaler.linear(2),
            ),
            child: child!,
          ),
          home: ActiveOperationsScreen(client: f.client),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 · b'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('New driver'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('New driver'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
