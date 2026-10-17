import 'package:access_transit/l10n/app_localizations.dart';

import 'dart:convert';

import 'package:access_transit/screens/admin/account_controls_screen.dart';
import 'package:access_transit/services/moderation_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class Fixture {
  bool manual = false, fail = false, stale = false;
  int revision = 0;
  String uid = 'admin';
  final changes = <Map<String, dynamic>>[];
  late final client = ModerationClient(
    origin: Uri.parse('https://test.local'),
    identity: () async => ModerationIdentity(uid, 'token'),
    currentUid: () => uid,
    client: MockClient((r) async {
      final b = jsonDecode(r.body) as Map<String, dynamic>;
      expect(b.containsKey('actorUid'), false);
      final envelope = {'policyVersion': 2, 'uid': uid, 'scope': 'normal'};
      if (r.url.path.endsWith('/detail')) {
        return http.Response(
          jsonEncode({
            ...envelope,
            'accountId': 'rider',
            'revision': revision,
            'manualActive': manual,
            'restricted': true,
            'communityRestricted': true,
            'manualUntil': null,
            'manualReason': null,
          }),
          200,
        );
      }
      changes.add(b);
      if (fail || stale) {
        return http.Response(
          jsonEncode({
            'error': {'code': stale ? 'review-stale' : 'service-unavailable'},
          }),
          409,
        );
      }
      manual = b['action'] == 'suspend';
      revision++;
      return http.Response(
        jsonEncode({
          ...envelope,
          'accountId': 'rider',
          'operationId': b['operationId'],
          'revision': revision,
          'duplicate': false,
        }),
        200,
      );
    }),
  );
}

Future<void> open(WidgetTester t, Fixture f) async {
  await t.pumpWidget(
    MaterialApp(
      home: AccountControlsScreen(accountId: 'rider', client: f.client),
    ),
  );
  await t.pumpAndSettle();
}

Future<void> press(WidgetTester t, String label) async {
  final button = find.text(label);
  await t.scrollUntilVisible(
    button,
    150,
    scrollable: find.byType(Scrollable).first,
  );
  await t.ensureVisible(button);
  await t.tap(button);
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    '72-hour manual restriction and restore preserve separate community status',
    (t) async {
      final f = Fixture();
      addTearDown(f.client.dispose);
      await open(t, f);
      await press(t, 'Suspend access');
      expect(f.changes, isEmpty);
      await t.enterText(find.byType(TextField), 'Reviewed conduct issue');
      await press(t, 'Suspend access');
      expect(f.changes.single['durationHours'], 72);
      expect(f.changes.single['expectedRevision'], 0);
      expect(find.text('Manual restriction is active'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'Appeal reviewed carefully');
      await press(t, 'Restore manual access');
      expect(f.changes.last.containsKey('durationHours'), false);
      expect(f.changes.last['expectedRevision'], 1);
      expect(find.text('No active manual restriction'), findsOneWidget);
      expect(
        find.text('A separate community restriction remains in effect.'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'ambiguous retry keeps its operation and payload; stale response requires reload',
    (t) async {
      final f = Fixture()..fail = true;
      addTearDown(f.client.dispose);
      await open(t, f);
      await t.enterText(find.byType(TextField), 'Reviewed conduct issue');
      await press(t, 'Suspend access');
      expect(t.widget<TextField>(find.byType(TextField)).enabled, false);
      f.fail = false;
      await press(t, 'Retry');
      expect(f.changes.length, 2);
      expect(f.changes[0], f.changes[1]);
      f.stale = true;
      await t.enterText(find.byType(TextField), 'Appeal reviewed carefully');
      await press(t, 'Restore manual access');
      expect(
        find.text('Account access changed. Reload before deciding.'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
    },
  );
  testWidgets('a switched account cannot submit captured controls', (t) async {
    final f = Fixture();
    addTearDown(f.client.dispose);
    await open(t, f);
    await t.enterText(find.byType(TextField), 'Reviewed conduct issue');
    f.uid = 'another-admin';
    await press(t, 'Suspend access');
    expect(f.changes, isEmpty);
    expect(find.byType(TextField), findsNothing);
  });
  for (final locale in ['en', 'si', 'ta']) {
    testWidgets('controls $locale wrap at 320dp and 200 percent text', (
      t,
    ) async {
      t.view.physicalSize = const Size(320, 1700);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final f = Fixture();
      addTearDown(f.client.dispose);
      await t.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (c, child) => MediaQuery(
            data: MediaQuery.of(c)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: AccountControlsScreen(accountId: 'rider', client: f.client),
        ),
      );
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text(
          lookupAppLocalizations(Locale(locale)).accountControlsSuspend,
        ),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(t.takeException(), isNull);
    });
  }
}
