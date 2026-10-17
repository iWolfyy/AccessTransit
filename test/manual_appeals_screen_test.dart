import 'dart:convert';

import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/screens/community/manual_appeals_screen.dart';
import 'package:access_transit/services/moderation_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class AppealFixture {
  String uid = 'rider';
  bool fail = false, stale = false;
  String? status;
  final requests = <Map<String, dynamic>>[];
  Map<String, dynamic> row() => {
    'appealId': 'appeal',
    'accountId': 'rider',
    'restrictionRevision': 3,
    'restrictionReason': 'Operating restriction',
    'reason': 'Please review evidence',
    'status': status ?? 'pending',
  };
  late final client = ModerationClient(
    origin: Uri.parse('https://test.local'),
    identity: () async => ModerationIdentity(uid, 'signed'),
    currentUid: () => uid,
    client: MockClient((r) async {
      final b = jsonDecode(r.body) as Map<String, dynamic>;
      final envelope = {'uid': uid, 'scope': 'normal', 'policyVersion': 2};
      if (r.url.path.endsWith('/list')) {
        return http.Response(
          jsonEncode({
            ...envelope,
            'items': status == null && uid != 'admin' ? [] : [row()],
            'next': null,
          }),
          200,
        );
      }
      if (r.url.path.endsWith('/current')) {
        return http.Response(
          jsonEncode({
            ...envelope,
            'accountId': uid,
            'revision': 3,
            'manualActive': true,
            'reason': 'Operating restriction',
            'appeal': status == null ? null : row(),
          }),
          200,
        );
      }
      requests.add(b);
      if (fail) {
        return http.Response('{"error":{"code":"service-unavailable"}}', 503);
      }
      if (stale) return http.Response('{"error":{"code":"review-stale"}}', 409);
      status = r.url.path.endsWith('/review') ? 'accepted' : 'pending';
      return http.Response(
        jsonEncode({
          ...envelope,
          'appealId': 'appeal',
          'status': status,
          'duplicate': false,
        }),
        200,
      );
    }),
  );
}

Future<void> host(
  WidgetTester t,
  AppealFixture f, {
  bool admin = false,
  String locale = 'en',
}) async {
  await t.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: ManualAppealsScreen(client: f.client, admin: admin),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    'restricted rider sends appeal with current revision; failure retry preserves payload',
    (t) async {
      final f = AppealFixture()..fail = true;
      addTearDown(f.client.dispose);
      await host(t, f);
      await t.tap(find.text('Submit appeal'));
      await t.pumpAndSettle();
      expect(f.requests, isEmpty);
      await t.enterText(find.byType(TextField), 'Please review evidence');
      await t.tap(find.text('Submit appeal'));
      await t.pumpAndSettle();
      expect(f.requests.single['expectedRevision'], 3);
      expect(f.requests.single.containsKey('accountId'), false);
      f.fail = false;
      await t.tap(find.widgetWithText(FilledButton, 'Retry account status'));
      await t.pumpAndSettle();
      expect(f.requests[1], f.requests[0]);
      expect(find.text('Pending review'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    },
  );
  testWidgets(
    'admin stale review clears decision and reloads without claiming success',
    (t) async {
      final f = AppealFixture()
        ..uid = 'admin'
        ..stale = true;
      addTearDown(f.client.dispose);
      await host(t, f, admin: true);
      await t.tap(find.text('Review appeal'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'Reviewed supporting evidence');
      await t.tap(find.text('Restore manual access'));
      await t.pumpAndSettle();
      expect(f.requests.single['outcome'], 'restore');
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Appeal accepted'), findsNothing);
    },
  );
  testWidgets('switching accounts prevents a captured appeal submission', (
    t,
  ) async {
    final f = AppealFixture();
    addTearDown(f.client.dispose);
    await host(t, f);
    await t.enterText(find.byType(TextField), 'Please review evidence');
    f.uid = 'other';
    await t.tap(find.text('Submit appeal'));
    await t.pumpAndSettle();
    expect(f.requests, isEmpty);
    expect(find.byType(TextField), findsNothing);
  });
  for (final locale in ['en', 'si', 'ta']) {
    testWidgets('manual appeal $locale wraps at 320dp/200 percent', (t) async {
      t.view.physicalSize = const Size(320, 1400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final f = AppealFixture();
      addTearDown(f.client.dispose);
      await t.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (c, child) => MediaQuery(
            data: MediaQuery.of(c)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: ManualAppealsScreen(client: f.client),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  }
}
