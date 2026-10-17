import 'dart:convert';

import 'package:access_transit/services/local_validation_backend.dart';
import 'package:access_transit/services/moderation_client.dart';
import 'package:access_transit/services/moderation_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'configured main app sends authenticated v2 requests to HTTPS, never emulator HTTP',
    () async {
      expect(LocalValidationBackend.enabled, false);
      expect(ModerationMode.enabled, true);
      expect(ModerationMode.local, false);
      ModerationMode.validate();
      final client = ModerationClient(
        identity: () async => const ModerationIdentity('user', 'token'),
        currentUid: () => 'user',
        client: MockClient((r) async {
          expect(r.url.origin, ModerationMode.apiOrigin!.origin);
          expect(r.url.scheme, 'https');
          expect(r.url.path, '/v2/account/status');
          expect(r.headers['authorization'], 'Bearer token');
          expect(jsonDecode(r.body), {'scope': 'normal'});
          return http.Response(
            jsonEncode({
              'policyVersion': 2,
              'uid': 'user',
              'scope': 'normal',
              'state': 'active',
              'serverTime': '2026-10-17T10:00:00Z',
              'suspendedUntil': null,
              'points': 10,
            }),
            200,
          );
        }),
      );
      addTearDown(client.dispose);
      expect(client.isConfigured, true);
      expect((await client.accountStatus()).isSuspended, false);
    },
    skip:
        !ModerationMode.enabled ||
        ModerationMode.local ||
        ModerationMode.sharedLocal,
  );

  test(
    'main v2 activation cannot grant the emulator HTTP transport exception',
    () {
      final client = ModerationClient(
        origin: Uri.parse('http://10.0.2.2:8787'),
      );
      addTearDown(client.dispose);
      expect(client.isConfigured, false);
    },
    skip:
        !ModerationMode.enabled ||
        ModerationMode.local ||
        ModerationMode.sharedLocal,
  );
}
