import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:access_transit/services/driver_notifications.dart';
import 'package:access_transit/services/firebase_driver_push.dart';
import 'package:access_transit/services/moderation_client.dart';
import 'package:access_transit/screens/operator/notification_request_screen.dart';
import 'package:access_transit/widgets/driver_notification_settings.dart';
import 'package:access_transit/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'run_assistance_test.dart' show requestMap;

const payload = {
  'kind': 'boarding-assistance',
  'eventId': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
};

class Device implements DriverPushDevice {
  final tokenEvents = StreamController<String>.broadcast();
  final foregroundEvents = StreamController<Map<String, dynamic>>.broadcast();
  final openedEvents = StreamController<Map<String, dynamic>>.broadcast();
  bool granted = true, failDelete = false;
  int reads = 0, deletes = 0, prompts = 0;
  Completer<bool>? permissionPending;
  Map<String, dynamic>? initial;
  @override
  Stream<String> get tokens => tokenEvents.stream;
  @override
  Stream<Map<String, dynamic>> get foreground => foregroundEvents.stream;
  @override
  Stream<Map<String, dynamic>> get opened => openedEvents.stream;
  @override
  Future<bool> permission({required bool request}) async {
    if (request) prompts++;
    return permissionPending?.future ?? granted;
  }

  @override
  Future<String?> token() async {
    reads++;
    return 'token-original';
  }

  @override
  Future<void> deleteToken() async {
    deletes++;
    if (failDelete) throw StateError('offline');
  }

  @override
  Future<Map<String, dynamic>?> initialMessage() async => initial;
  Future<void> close() async {
    await tokenEvents.close();
    await foregroundEvents.close();
    await openedEvents.close();
  }
}

class Fixture {
  String uid = 'driver';
  bool authorized = true, failRegister = false, failRemove = false;
  final prefs = <String, bool>{};
  final posted = <({String path, Map<String, dynamic> body})>[];
  final device = Device();
  int opens = 0, hints = 0;
  Completer<void>? holdOpen;
  late final client = ModerationClient(
    origin: Uri.parse('https://test.local'),
    currentUid: () => uid,
    identity: () async => ModerationIdentity(uid, 'token'),
    client: MockClient((r) async {
      final body = Map<String, dynamic>.from(jsonDecode(r.body));
      posted.add((path: r.url.path, body: body));
      final owner = uid;
      Map<String, dynamic> data;
      if (r.url.path.endsWith('register')) {
        if (failRegister) {
          return http.Response('{"error":{"code":"service-unavailable"}}', 503);
        }
        data = {
          'deviceId': sha256.convert(utf8.encode(body['token'])).toString(),
          'generation': 1,
          'provider': 'fcm',
        };
      } else if (r.url.path.endsWith('remove')) {
        if (failRemove) {
          return http.Response('{"error":{"code":"service-unavailable"}}', 503);
        }
        data = {'removed': true};
      } else {
        if (holdOpen != null) await holdOpen!.future;
        if (!authorized || owner != 'driver') {
          return http.Response(
            '{"error":{"code":"notification-unavailable"}}',
            409,
          );
        }
        data = {'request': requestMap()};
      }
      return http.Response(
        jsonEncode({
          ...data,
          'policyVersion': 2,
          'uid': owner,
          'scope': 'normal',
        }),
        200,
      );
    }),
  );
  late final session = DriverNotifications(
    device: device,
    client: client,
    currentUid: () => uid,
    readEnabled: (u) async => prefs[u] ?? false,
    saveEnabled: (u, v) async {
      prefs[u] = v;
    },
    cleanupTimeout: const Duration(milliseconds: 30),
    onOpen: (_, _) => opens++,
    onForeground: (_) => hints++,
  );
  Future<void> start() async {
    await session.activate(uid, 'en');
    await session.enable();
  }

  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await session.activate(uid, 'en');
  }

  Future<void> close() async {
    session.dispose();
    client.dispose();
    await device.close();
  }
}

void main() {
  test(
    'revoked permission is checked on resume without another prompt',
    () async {
      final f = Fixture();
      addTearDown(f.close);
      await f.start();
      f.device.granted = false;
      await f.session.refreshPermission();
      expect(f.session.state, DriverPushState.denied);
      expect(f.device.prompts, 1);
      expect(f.session.enabled, false);
      expect(f.prefs['driver'], false);
      expect(f.posted.where((p) => p.path.endsWith('remove')).length, 1);
    },
  );
  test('native activation remains closed without a reviewed dedicated test project', () {
    expect(DriverPushConfiguration.reviewedTestProjectId, isEmpty);
    expect(DriverPushRuntime.session, isNull);
    expect(FirebaseDriverPush.new, throwsStateError);
    if (DriverPushConfiguration.requested) {
      expect(DriverPushConfiguration.validateBuild, throwsStateError);
    } else {
      DriverPushConfiguration.validateBuild();
    }
  });
  test(
    'no opt-in means no permission prompt, token read or registration',
    () async {
      final f = Fixture();
      addTearDown(f.close);
      await f.session.activate('driver', 'en');
      expect(f.device.reads, 0);
      expect(f.device.prompts, 0);
      expect(f.posted, isEmpty);
      f.device.openedEvents.add(payload);
      await f.settle();
      expect(f.opens, 0);
    },
  );
  test(
    'denied OS permission never registers and leaves the inbox usable',
    () async {
      final f = Fixture();
      addTearDown(f.close);
      f.device.granted = false;
      await f.start();
      expect(f.session.state, DriverPushState.denied);
      expect(f.device.reads, 0);
      expect(f.posted, isEmpty);
      expect(f.prefs['driver'], false);
    },
  );
  test(
    'explicit opt-in, token rotation and locale update replace the old binding',
    () async {
      final f = Fixture();
      addTearDown(f.close);
      await f.start();
      expect(f.session.state, DriverPushState.ready);
      f.device.tokenEvents.add('token-rotated');
      await f.settle();
      expect(f.posted.where((p) => p.path.endsWith('register')).length, 2);
      expect(f.posted.where((p) => p.path.endsWith('remove')).length, 1);
      await f.session.activate('driver', 'ta');
      expect(f.device.prompts, 1);
      expect(
        f.posted.where((p) => p.path.endsWith('register')).last.body['locale'],
        'ta',
      );
    },
  );
  test('foreground hints and opens deduplicate separately and reload authorization', () async {
    final f = Fixture();
    addTearDown(f.close);
    await f.start();
    f.device.foregroundEvents.add(payload);
    f.device.foregroundEvents.add(payload);
    f.device.openedEvents.add(payload);
    f.device.openedEvents.add(payload);
    await f.settle();
    expect(f.hints, 1);
    expect(f.opens, 1);
    f.authorized = false;
    f.device.openedEvents.add({...payload, 'eventId': 'b' * 64});
    await f.settle();
    expect(f.opens, 1);
  });
  test('terminated open requires a restored opted-in account and no device-local acceptance', () async {
    final f = Fixture();
    addTearDown(f.close);
    f.prefs['driver'] = true;
    f.device.initial = payload;
    await f.session.activate('driver', 'en');
    await f.session.initialMessage();
    await f.session.initialMessage();
    expect(f.device.prompts, 0);
    expect(f.opens, 1);
    expect(f.posted.any((p) => p.path.endsWith('/action')), false);
  });
  test(
    'account switch during an open clears the old result before navigation',
    () async {
      final f = Fixture();
      addTearDown(f.close);
      await f.start();
      f.holdOpen = Completer<void>();
      f.device.openedEvents.add(payload);
      await Future<void>.delayed(Duration.zero);
      f.uid = 'other';
      final next = f.session.activate('other', 'en');
      expect(f.session.enabled, false);
      f.holdOpen!.complete();
      await next;
      expect(f.opens, 0);
      expect(f.device.deletes, 1);
      expect(f.device.reads, 1);
    },
  );
  test('logout disables future hints despite offline deregistration', () async {
    final f = Fixture();
    addTearDown(f.close);
    await f.start();
    f.failRemove = true;
    f.device.failDelete = true;
    await f.session.disable();
    expect(f.session.enabled, false);
    expect(f.prefs['driver'], false);
    f.device.foregroundEvents.add(payload);
    await f.settle();
    expect(f.hints, 0);
  });
  test('logout is bounded while a permission dialog is pending', () async {
    final f = Fixture();
    addTearDown(f.close);
    await f.session.activate('driver', 'en');
    f.device.permissionPending = Completer<bool>();
    final enabling = f.session.enable();
    await Future<void>.delayed(Duration.zero);
    await f.session.disable();
    f.device.permissionPending!.complete(true);
    await enabling;
    expect(f.session.enabled, false);
    expect(f.device.reads, 0);
    expect(f.posted, isEmpty);
  });
  test(
    'failed registration remains retryable and never claims readiness',
    () async {
      final f = Fixture();
      addTearDown(f.close);
      f.failRegister = true;
      await f.start();
      expect(f.session.state, DriverPushState.unavailable);
      f.failRegister = false;
      await f.session.enable();
      expect(f.session.state, DriverPushState.ready);
    },
  );
  for (final locale in ['en', 'si', 'ta']) {
    testWidgets(
      'notification controls and authorized request $locale fit 320dp/200%',
      (tester) async {
        tester.view.physicalSize = const Size(320, 760);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final f = Fixture();
        addTearDown(f.close);
        await f.start();
        Widget app(Widget home) => MaterialApp(
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2),
              size: Size(320, 760),
            ),
            child: child!,
          ),
          home: home,
        );
        await tester.pumpWidget(
          app(
            Scaffold(
              body: ListView(
                children: [DriverNotificationSettings(session: f.session)],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          app(NotificationRequestScreen(session: f.session, payload: payload)),
        );
        await tester.pumpAndSettle();
        expect(find.text('Rider'), findsOneWidget);
        expect(tester.takeException(), isNull);
        f.uid = 'other';
        final switching = f.session.activate('other', 'en');
        await tester.pump();
        expect(find.text('Rider'), findsNothing);
        await switching;
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
