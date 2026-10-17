import 'dart:convert';

import 'package:access_transit/services/moderation_client.dart';
import 'package:access_transit/services/moderation_mode.dart';
import 'package:access_transit/services/local_validation_backend.dart';
import 'package:access_transit/firebase_options.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('main app retains real Firebase and sends authenticated normal-scope requests to localhost', () async {
    ModerationMode.validate();
    expect(LocalValidationBackend.enabled, false);
    expect(DefaultFirebaseOptions.android.projectId, 'accesstransit-b615b');
    expect(ModerationMode.local, false);
    final client = ModerationClient(
      identity: () async => const ModerationIdentity('owner', 'signed-token'),
      currentUid: () => 'owner',
      client: MockClient((r) async {
        expect(r.url.toString(), 'http://10.0.2.2:8788/v2/account/status');
        expect(r.headers['authorization'], 'Bearer signed-token');
        expect(jsonDecode(r.body), {'scope': 'normal'});
        return http.Response(
          jsonEncode({
            'uid': 'owner',
            'scope': 'normal',
            'policyVersion': 2,
            'state': 'active',
            'serverTime': '2026-10-17T10:00:00Z',
            'suspendedUntil': null,
            'points': 0,
          }),
          200,
        );
      }),
    );
    addTearDown(client.dispose);
    expect(client.isConfigured, true);
    expect((await client.accountStatus()).isSuspended, false);
  }, skip: !ModerationMode.sharedLocal);

  test(
    'offline or unready localhost never returns an active-account receipt',
    () async {
      for (final offline in [false, true]) {
        final client = ModerationClient(
          identity: () async =>
              const ModerationIdentity('owner', 'signed-token'),
          currentUid: () => 'owner',
          client: MockClient((_) async {
            if (offline) throw http.ClientException('connection refused');
            return http.Response(
              '{"error":{"code":"service-unavailable"}}',
              503,
            );
          }),
        );
        addTearDown(client.dispose);
        await expectLater(
          client.accountStatus(),
          throwsA(
            isA<ModerationException>().having(
              (e) => e.code,
              'code',
              'service-unavailable',
            ),
          ),
        );
      }
      for (final origin in ['http://10.0.2.2:8787', 'http://other.test:8788']) {
        final client = ModerationClient(origin: Uri.parse(origin));
        expect(client.isConfigured, false);
        client.dispose();
      }
    },
    skip: !ModerationMode.sharedLocal,
  );
}
