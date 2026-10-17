import 'dart:convert';

import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/screens/admin/auth_account_screen.dart';
import 'package:access_transit/services/moderation_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class Fixture {
  String uid = 'admin';
  bool disabled = false, fail = false, reviewRequired = false;
  String review = 'none';
  int revision = 0;
  Map<String, dynamic>? job;
  final changes = <Map<String, dynamic>>[];
  Map<String, dynamic> detail() => {
    'accountId': 'rider',
    'revision': revision,
    'authExists': true,
    'authDisabled': disabled,
    'authBlocked': disabled,
    'deleted': false,
    'protected': false,
    'activeOperation': false,
    'reviewStatus': review,
    'lastOperation': job,
  };
  late final client = ModerationClient(
    origin: Uri.parse('https://test.local'),
    identity: () async => ModerationIdentity(uid, 'signed'),
    currentUid: () => uid,
    client: MockClient((r) async {
      final b = jsonDecode(r.body) as Map<String, dynamic>;
      expect(b.containsKey('actorUid'), false);
      expect(b.containsKey('actorAdmin'), false);
      final envelope = {'uid': uid, 'scope': 'normal', 'policyVersion': 2};
      if (r.url.path.endsWith('/detail')) {
        return http.Response(jsonEncode({...envelope, ...detail()}), 200);
      }
      if (r.url.path.endsWith('/retry')) {
        job!['status'] = 'completed';
        return http.Response(jsonEncode({...envelope, ...detail()}), 200);
      }
      changes.add(b);
      if (fail) {
        return http.Response('{"error":{"code":"service-unavailable"}}', 503);
      }
      revision++;
      if (b['action'] == 'disable') disabled = true;
      if (b['action'] == 'enable') disabled = false;
      if (b['action'] == 'request-delete') review = 'pending';
      job = {
        'operationId': b['operationId'],
        'action': b['action'],
        'revision': revision,
        'status': reviewRequired ? 'review-required' : 'completed',
      };
      return http.Response(
        jsonEncode({
          ...envelope,
          ...job!,
          'accountId': 'rider',
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
      home: AuthAccountScreen(accountId: 'rider', client: f.client),
    ),
  );
  await t.pumpAndSettle();
}

Future<void> press(WidgetTester t, String label) async {
  final target = find.text(label);
  await t.scrollUntilVisible(
    target,
    150,
    scrollable: find.byType(Scrollable).first,
  );
  await t.ensureVisible(target);
  await t.tap(target);
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    'disable/enable/revoke require reasons and refresh acknowledged state',
    (t) async {
      final f = Fixture();
      addTearDown(f.client.dispose);
      await open(t, f);
      await press(t, 'Disable sign-in');
      expect(f.changes, isEmpty);
      await t.enterText(find.byType(TextField), 'Reviewed conduct issue');
      await press(t, 'Disable sign-in');
      expect(f.changes.single['expectedRevision'], 0);
      expect(find.text('Firebase sign-in is disabled'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'Reviewed appeal accepted');
      await press(t, 'Enable sign-in');
      expect(f.changes.last['expectedRevision'], 1);
      expect(find.text('Firebase sign-in is enabled'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'Reviewed session security');
      await press(t, 'Revoke existing sessions');
      expect(f.changes.last['action'], 'revoke');
    },
  );
  testWidgets(
    'ambiguous request retry keeps ID and reason; review-required is not completed',
    (t) async {
      final f = Fixture()..fail = true;
      addTearDown(f.client.dispose);
      await open(t, f);
      await t.enterText(find.byType(TextField), 'Reviewed conduct issue');
      await press(t, 'Disable sign-in');
      expect(t.widget<TextField>(find.byType(TextField)).enabled, false);
      f.fail = false;
      f.reviewRequired = true;
      await press(t, 'Retry');
      expect(f.changes[0], f.changes[1]);
      expect(find.text('Last operation completed'), findsNothing);
      await press(t, 'Review and retry the same operation');
      expect(find.text('Last operation completed'), findsOneWidget);
    },
  );
  testWidgets(
    'deletion approval requires exact UID and an explicit final review',
    (t) async {
      final f = Fixture()
        ..disabled = true
        ..review = 'pending';
      addTearDown(f.client.dispose);
      await open(t, f);
      await t.enterText(
        find.byType(TextField).first,
        'Reviewed deletion evidence',
      );
      await press(t, 'Approve account deletion');
      expect(f.changes, isEmpty);
      expect(
        find.text('Type the exact account UID to confirm deletion.'),
        findsOneWidget,
      );
      await t.enterText(find.byType(TextField).last, 'rider');
      await press(t, 'Approve account deletion');
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(f.changes, isEmpty);
      await t.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Approve account deletion'),
        ),
      );
      await t.pumpAndSettle();
      expect(f.changes.single['confirmAccountId'], 'rider');
      expect(f.changes.single['action'], 'approve-delete');
    },
  );
  testWidgets('account switches cannot submit captured Auth controls', (
    t,
  ) async {
    final f = Fixture();
    addTearDown(f.client.dispose);
    await open(t, f);
    await t.enterText(find.byType(TextField), 'Reviewed reason');
    f.uid = 'other';
    await press(t, 'Disable sign-in');
    expect(f.changes, isEmpty);
    expect(find.byType(TextField), findsNothing);
  });
  for (final locale in ['en', 'si', 'ta']) {
    testWidgets('Auth controls $locale fit 320dp at 200 percent text', (
      t,
    ) async {
      t.view.physicalSize = const Size(320, 1800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final f = Fixture()
        ..review = 'pending'
        ..disabled = true;
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
          home: AuthAccountScreen(accountId: 'rider', client: f.client),
        ),
      );
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text(lookupAppLocalizations(Locale(locale)).authDeleteApprove),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(t.takeException(), isNull);
    });
  }
}
