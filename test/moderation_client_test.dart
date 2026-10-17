import 'dart:async';
import 'dart:convert';

import 'package:access_transit/services/moderation_client.dart';
import 'package:access_transit/models/report.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> receipt({String uid = 'user', String scope = 'normal'}) =>
    {
      'policyVersion': 2,
      'uid': uid,
      'scope': scope,
      'reportId': 'r',
      'duplicate': false,
      'hidden': true,
      'falseCount': 5,
      'confirmCount': 2,
    };
Matcher code(String value) =>
    isA<ModerationException>().having((e) => e.code, 'code', value);

ModerationClient make(
  http.Client client, {
  String? Function()? uid,
  Future<ModerationIdentity?> Function()? identity,
  bool sample = false,
  Uri? origin,
  Duration timeout = const Duration(seconds: 1),
}) => ModerationClient(
  origin: origin ?? Uri.parse('https://service.test'),
  client: client,
  currentUid: uid ?? () => 'user',
  identity:
      identity ?? () async => const ModerationIdentity('user', 'id-token'),
  sample: sample,
  timeout: timeout,
);

void main() {
  test(
    'handover acceptance binds the originating driver before sending GPS',
    () async {
      var requests = 0;
      final client = make(
        MockClient((_) async {
          requests++;
          return http.Response('{}', 200);
        }),
      );
      await expectLater(
        client.acceptOperation('run', 1, {}, driverId: 'another-account'),
        throwsA(code('authentication-required')),
      );
      expect(requests, 0);
      client.dispose();
    },
  );
  test('handover acceptance rejects a mismatched server receipt', () async {
    final client = make(
      MockClient((r) async {
        expect(jsonDecode(r.body)['gps']['accuracy'], 5);
        return http.Response(
          jsonEncode({
            ...receipt(),
            'runId': 'other',
            'handoverVersion': 1,
            'accepted': true,
          }),
          200,
        );
      }),
    );
    await expectLater(
      client.acceptOperation('run', 1, {'accuracy': 5}, driverId: 'user'),
      throwsA(code('invalid-response')),
    );
    client.dispose();
  });
  test('publication transports only observation fields and validates acknowledged award', () async {
    final client = make(
      MockClient((request) async {
        expect(request.url.path, '/v2/reports/publish');
        final body = jsonDecode(request.body);
        expect(body['report']['userId'], isNull);
        expect(body['report']['points'], isNull);
        expect(body['report']['observedAt'], '2026-10-16T10:00:00.000Z');
        return http.Response(
          jsonEncode({
            'policyVersion': 2,
            'uid': 'user',
            'scope': 'normal',
            'reportId': 'r',
            'awardedPoints': 10,
            'duplicate': false,
          }),
          200,
        );
      }),
    );
    await client.publishReport(
      Report(
        id: 'r',
        targetType: 'bus',
        targetId: 'b',
        problemType: 'Ramp broken',
        status: 'active',
        createdAt: DateTime.utc(2026, 10, 16, 10),
        userId: 'user',
      ),
    );
  });
  test('vote uses bearer token, omits UID/points and accepts acknowledged scoped receipt', () async {
    final client = make(
      MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer id-token');
        expect(request.followRedirects, isFalse);
        expect(request.url.path, '/v2/reports/vote');
        expect(jsonDecode(request.body), {
          'reportId': 'r',
          'value': 'false',
          'reason': 'Ramp works',
          'scope': 'normal',
        });
        return http.Response(jsonEncode(receipt()), 200);
      }),
    );
    final result = await client.voteReport(
      reportId: 'r',
      isTrue: false,
      reason: ' Ramp works ',
    );
    expect(result.hidden, isTrue);
    expect(result.falseCount, 5);
    expect(result.confirmCount, 2);
    client.dispose();
  });

  test('unconfigured or insecure origins cannot receive an ID token', () async {
    for (final origin in [
      '',
      'http://service.test',
      'https://user:password@service.test',
      'https://service.test?secret=x',
      'https://service.test/api',
    ]) {
      var sent = false;
      final client = make(
        MockClient((_) async {
          sent = true;
          return http.Response('{}', 200);
        }),
        origin: Uri.parse(origin),
      );
      await expectLater(
        client.accountStatus(),
        throwsA(code('backend-not-configured')),
      );
      expect(sent, isFalse);
      client.dispose();
    }
  });

  test('guest and missing session never send votes', () async {
    final transport = MockClient((_) async => fail('must not send'));
    final guest = make(transport, uid: () => null);
    await expectLater(
      guest.voteReport(reportId: 'r', isTrue: true),
      throwsA(code('authentication-required')),
    );
    final missing = make(transport, identity: () async => null);
    await expectLater(
      missing.accountStatus(),
      throwsA(code('authentication-required')),
    );
  });

  test(
    'False reason and stable report identity are checked before transport',
    () async {
      final client = make(MockClient((_) async => fail('must not send')));
      await expectLater(
        client.voteReport(reportId: 'r', isTrue: false),
        throwsA(code('false-reason-required')),
      );
      await expectLater(
        client.voteReport(reportId: 'r/forged', isTrue: true),
        throwsA(code('invalid-id')),
      );
    },
  );

  test(
    'invalid or unrelated successful replies cannot appear as a saved vote',
    () async {
      for (final changes in [
        {'uid': 'another'},
        {'scope': 'sample'},
        {'reportId': 'other'},
        {'policyVersion': 1},
        {'falseCount': 3},
        {'confirmCount': -1},
        {'duplicate': 'yes'},
      ]) {
        final client = make(
          MockClient(
            (_) async =>
                http.Response(jsonEncode({...receipt(), ...changes}), 200),
          ),
        );
        await expectLater(
          client.voteReport(reportId: 'r', isTrue: true),
          throwsA(code('invalid-response')),
        );
        client.dispose();
      }
    },
  );

  test('sample transport remains explicitly scoped', () async {
    final client = make(
      MockClient((request) async {
        expect(jsonDecode(request.body)['scope'], 'sample');
        return http.Response(jsonEncode(receipt(scope: 'sample')), 200);
      }),
      sample: true,
    );
    expect(
      (await client.voteReport(reportId: 'r', isTrue: true)).hidden,
      isTrue,
    );
  });

  test(
    'account changes during token retrieval do not send old account requests',
    () async {
      var uid = 'user';
      final token = Completer<ModerationIdentity?>();
      final client = make(
        MockClient((_) async => fail('must not send')),
        uid: () => uid,
        identity: () => token.future,
      );
      final result = client.accountStatus();
      uid = 'another';
      token.complete(const ModerationIdentity('user', 'token'));
      await expectLater(result, throwsA(code('account-changed')));
    },
  );

  test('late vote responses cannot apply after account switch', () async {
    var uid = 'user';
    final response = Completer<http.Response>(), started = Completer<void>();
    final client = make(
      MockClient((_) {
        started.complete();
        return response.future;
      }),
      uid: () => uid,
    );
    final result = client.voteReport(reportId: 'r', isTrue: true);
    await started.future;
    uid = 'another';
    response.complete(http.Response(jsonEncode(receipt()), 200));
    await expectLater(result, throwsA(code('account-changed')));
  });

  test(
    'server error codes are preserved without raw payload leakage or fallback',
    () async {
      for (final error in [
        'account-suspended',
        'authentication-required',
        'voting-closed',
        'private-secret',
      ]) {
        final client = make(
          MockClient(
            (_) async => http.Response(
              jsonEncode({
                'error': {'code': error, 'details': 'private database path'},
              }),
              403,
            ),
          ),
        );
        await expectLater(
          client.voteReport(reportId: 'r', isTrue: true),
          throwsA(
            code(error == 'private-secret' ? 'service-unavailable' : error),
          ),
        );
      }
    },
  );

  test(
    'account status keeps signed points and uses authoritative state/expiry',
    () async {
      final client = make(
        MockClient((request) async {
          expect(request.url.path, '/v2/account/status');
          return http.Response(
            jsonEncode({
              'policyVersion': 2,
              'uid': 'user',
              'scope': 'normal',
              'state': 'temporary',
              'serverTime': '2026-10-16T10:00:00.000Z',
              'suspendedUntil': '2026-10-19T10:00:00.000Z',
              'points': -20,
            }),
            200,
          );
        }),
      );
      final status = await client.accountStatus();
      expect(status.points, -20);
      expect(status.isSuspended, isTrue);
      expect(status.suspendedUntil, DateTime.utc(2026, 10, 19, 10));
    },
  );

  test(
    'invalid status and expired restriction responses are rejected',
    () async {
      for (final state in ['unknown', 'temporary']) {
        final client = make(
          MockClient(
            (_) async => http.Response(
              jsonEncode({
                'policyVersion': 2,
                'uid': 'user',
                'scope': 'normal',
                'state': state,
                'serverTime': '2026-10-19T10:00:00.000Z',
                'suspendedUntil': '2026-10-16T10:00:00.000Z',
                'points': 0,
              }),
              200,
            ),
          ),
        );
        await expectLater(
          client.accountStatus(),
          throwsA(code('invalid-response')),
        );
      }
    },
  );

  test('timeouts, malformed replies, redirects and disposed clients never claim success', () async {
    final timeout = make(
      MockClient((_) => Completer<http.Response>().future),
      timeout: const Duration(milliseconds: 10),
    );
    await expectLater(
      timeout.voteReport(reportId: 'r', isTrue: true),
      throwsA(code('service-unavailable')),
    );
    final malformed = make(
      MockClient((_) async => http.Response('not json', 200)),
    );
    await expectLater(
      malformed.accountStatus(),
      throwsA(code('invalid-response')),
    );
    final redirect = make(MockClient((_) async => http.Response('{}', 302)));
    await expectLater(
      redirect.accountStatus(),
      throwsA(code('service-unavailable')),
    );
    redirect.dispose();
    await expectLater(redirect.accountStatus(), throwsA(code('disposed')));
  });
}
