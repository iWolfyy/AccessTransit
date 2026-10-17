import 'dart:convert';

import 'package:access_transit/services/moderation_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'run_assistance_test.dart' show requestMap;

const eventId =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const payload = {'kind': 'boarding-assistance', 'eventId': eventId};
Matcher code(String value) =>
    throwsA(isA<ModerationException>().having((e) => e.code, 'code', value));
ModerationClient client(
  Future<http.Response> Function(http.Request) send, {
  String Function()? uid,
}) => ModerationClient(
  origin: Uri.parse('https://test.local'),
  currentUid: uid ?? () => 'driver',
  identity: () async => ModerationIdentity(uid?.call() ?? 'driver', 'token'),
  client: MockClient(send),
);
http.Response response(Map<String, dynamic> data) => http.Response(
  jsonEncode({'policyVersion': 2, 'uid': 'driver', 'scope': 'normal', ...data}),
  200,
);
void main() {
  test('notification device registration and removal use authenticated account and validated receipts', () async {
    final posted = <Map<String, dynamic>>[];
    final c = client((r) async {
      final body = Map<String, dynamic>.from(jsonDecode(r.body));
      posted.add(body);
      expect(body.containsKey('uid'), false);
      expect(body.containsKey('provider'), false);
      return response(
        r.url.path.endsWith('register')
            ? {'deviceId': eventId, 'generation': 1, 'provider': 'local'}
            : {'removed': true},
      );
    });
    addTearDown(c.dispose);
    expect(
      await c.registerNotificationDevice(
        token: 'local-token',
        locale: 'si',
        accountId: 'driver',
      ),
      eventId,
    );
    await c.removeNotificationDevice(eventId, accountId: 'driver');
    expect(posted.first['locale'], 'si');
    expect(posted.first['platform'], 'android');
    await expectLater(
      c.registerNotificationDevice(
        token: 'local-token',
        locale: 'en',
        accountId: 'old-user',
      ),
      code('account-changed'),
    );
    expect(posted.length, 2);
  });
  test('notification payload is only a hint and requires an authorized server request', () async {
    final c = client((r) async {
      expect(jsonDecode(r.body), {'scope': 'normal', 'eventId': eventId});
      return response({'request': requestMap()});
    });
    addTearDown(c.dispose);
    final request = await c.openAssistanceNotification(payload);
    expect(request.id, 'help');
    expect(request.driverId, 'driver');
    expect(request.status, 'pending');
  });
  test(
    'forged payload data, another driver and terminal request cannot be opened',
    () async {
      var calls = 0;
      var raw = requestMap();
      final c = client((r) async {
        calls++;
        return response({'request': raw});
      });
      addTearDown(c.dispose);
      for (final input in [
        {...payload, 'riderName': 'forged'},
        {'kind': 'other', 'eventId': eventId},
        {...payload, 'eventId': '../secret'},
      ]) {
        await expectLater(
          c.openAssistanceNotification(input),
          code('invalid-request'),
        );
      }
      expect(calls, 0);
      raw = {...requestMap(), 'driverId': 'old-driver'};
      await expectLater(
        c.openAssistanceNotification(payload),
        code('invalid-response'),
      );
      raw = requestMap(status: 'cancelled');
      await expectLater(
        c.openAssistanceNotification(payload),
        code('invalid-response'),
      );
    },
  );
  test(
    'account switching while notification opens cannot return private details',
    () async {
      var uid = 'driver';
      final c = client((r) async {
        uid = 'other';
        return response({'request': requestMap()});
      }, uid: () => uid);
      addTearDown(c.dispose);
      await expectLater(
        c.openAssistanceNotification(payload),
        code('account-changed'),
      );
    },
  );
}
