import 'package:access_transit/firebase_options.dart';
import 'package:access_transit/services/moderation_client.dart';
import 'package:access_transit/services/moderation_mode.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

ModerationConfiguration mainConfiguration(ModerationConfiguration build) =>
    ModerationMode.mainAppConfiguration(
      build: build,
      android: true,
      explicitV2: false,
      explicitLocalApi: false,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() {
    ModerationMode.resetMainAppConfiguration();
    debugDefaultTargetPlatformOverride = null;
  });

  test('ordinary Android startup uses online Firebase without a local API', () {
    const plain = ModerationConfiguration(
      requested: false,
      localValidation: false,
      debug: true,
      origin: '',
    );
    final effective = mainConfiguration(plain);
    expect(effective, same(plain));
    expect(effective.enabled, false);
    expect(effective.sharedLocal, false);
    expect(effective.local, false);
    expect(DefaultFirebaseOptions.android.projectId, 'accesstransit-b615b');
    for (final port in [8787, 8788]) {
      expect(
        effective.acceptsOrigin(Uri.parse('http://10.0.2.2:$port')),
        false,
      );
    }
  });

  test('app startup rejects local flags even when v2 was not requested', () {
    for (final requested in [false, true]) {
      for (final localValidation in [false, true]) {
        for (final localApi in [false, true]) {
          if (!localValidation && !localApi) continue;
          expect(
            () => mainConfiguration(
              ModerationConfiguration(
                requested: requested,
                localValidation: localValidation,
                debug: true,
                origin: '',
                localApi: localApi,
              ),
            ),
            throwsStateError,
          );
        }
      }
    }
  });

  test('configured HTTPS API remains available in debug and release', () {
    for (final debug in [false, true]) {
      final build = ModerationConfiguration(
        requested: true,
        localValidation: false,
        debug: debug,
        origin: 'https://backend.example.org',
      );
      final effective = mainConfiguration(build);
      expect(effective.validate, returnsNormally);
      expect(effective.enabled, true);
      expect(effective.apiOrigin.toString(), 'https://backend.example.org');
      expect(effective.sharedLocal, false);
    }
  });

  test(
    'default startup never sends account requests to localhost',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      ModerationMode.initializeMainApp();
      var requests = 0;
      final client = ModerationClient(
        identity: () async => const ModerationIdentity('owner', 'token'),
        currentUid: () => 'owner',
        client: MockClient((_) async {
          requests++;
          throw StateError(
            'An unconfigured backend must not receive requests.',
          );
        }),
      );
      addTearDown(client.dispose);
      expect(client.isConfigured, false);
      await expectLater(
        client.accountStatus(),
        throwsA(
          isA<ModerationException>().having(
            (e) => e.code,
            'code',
            'backend-not-configured',
          ),
        ),
      );
      expect(requests, 0);
    },
    skip:
        const bool.hasEnvironment('MODERATION_V2') ||
        const bool.hasEnvironment('MODERATION_API_ORIGIN') ||
        const bool.hasEnvironment('LOCAL_API') ||
        const bool.hasEnvironment('LOCAL_VALIDATION'),
  );
}
