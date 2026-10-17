import 'dart:convert';

import 'package:access_transit/models/report.dart';
import 'package:access_transit/models/enums/report_publication_state.dart';
import 'package:access_transit/services/moderation_client.dart';
import 'package:access_transit/services/moderation_mode.dart';
import 'package:access_transit/services/report_submission_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() {
    ModerationMode.resetMainAppConfiguration();
    debugDefaultTargetPlatformOverride = null;
  });

  test('ordinary Android debug startup selects localhost but explicit/release settings stay intact', () {
    const plain = ModerationConfiguration(
      requested: false,
      localValidation: false,
      debug: true,
      origin: '',
    );
    final effective = ModerationMode.mainAppConfiguration(
      build: plain,
      android: true,
      explicitV2: false,
      explicitLocalApi: false,
    );
    expect(effective.enabled, true);
    expect(effective.sharedLocal, true);
    expect(effective.apiOrigin.toString(), 'http://10.0.2.2:8788');
    for (final flags in [(true, false), (false, true)]) {
      expect(
        ModerationMode.mainAppConfiguration(
          build: plain,
          android: true,
          explicitV2: flags.$1,
          explicitLocalApi: flags.$2,
        ),
        same(plain),
      );
    }
    expect(
      ModerationMode.mainAppConfiguration(
        build: plain,
        android: false,
        explicitV2: false,
        explicitLocalApi: false,
      ),
      same(plain),
    );
    for (final build in [
      const ModerationConfiguration(
        requested: false,
        localValidation: false,
        debug: false,
        origin: '',
      ),
      const ModerationConfiguration(
        requested: true,
        localValidation: true,
        debug: true,
        origin: '',
      ),
      const ModerationConfiguration(
        requested: true,
        localValidation: false,
        debug: true,
        origin: 'https://backend.example.org',
      ),
    ]) {
      expect(
        ModerationMode.mainAppConfiguration(
          build: build,
          android: true,
          explicitV2: false,
          explicitLocalApi: false,
        ),
        same(build),
      );
    }
  });

  test(
    'pre-startup client publishes successive NEW reports and photo after ordinary startup',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      SharedPreferences.setMockInitialValues({});
      final requests = <Map<String, dynamic>>[];
      final client = ModerationClient(
        identity: () async => const ModerationIdentity('owner', 'mock-token'),
        currentUid: () => 'owner',
        sample: false,
        client: MockClient((request) async {
          expect(
            request.url.toString(),
            'http://10.0.2.2:8788/v2/reports/publish',
          );
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['scope'], 'normal');
          requests.add(body);
          return http.Response(
            jsonEncode({
              'uid': 'owner',
              'scope': 'normal',
              'policyVersion': 2,
              'reportId': body['reportId'],
              'awardedPoints': 10,
              'duplicate': false,
            }),
            200,
          );
        }),
      );
      addTearDown(client.dispose);
      expect(client.isConfigured, false);
      ModerationMode.initializeMainApp();
      expect(client.isConfigured, true);
      var uploads = 0;
      final submissions = ReportSubmissionService(
        publisher: client.publishReport,
        photoUploader: (_, _) async {
          uploads++;
          return 'https://res.cloudinary.com/sample/image/upload/photo.jpg';
        },
      );
      addTearDown(submissions.dispose);
      await submissions.init(prefs: await SharedPreferences.getInstance());
      for (var i = 0; i < 2; i++) {
        final result = await submissions.submit(
          Report(
            id: '',
            targetType: 'station',
            targetId: 'stop-$i',
            targetName: 'Stop $i',
            problemType: 'Out of Service',
            userId: 'owner',
            status: 'active',
            createdAt: DateTime.now(),
          ),
          photoBytes: i == 1 ? Uint8List.fromList([1, 2, 3]) : null,
        );
        expect(
          result.report.publicationState,
          ReportPublicationState.published,
        );
        expect(submissions.isAcknowledged(result.report.id), true);
        expect(submissions.entries, isEmpty);
      }
      expect(requests, hasLength(2));
      expect(requests.map((r) => r['reportId']).toSet(), hasLength(2));
      expect(
        requests.last['report']['photoUrl'],
        startsWith('https://res.cloudinary.com/'),
      );
      expect(uploads, 1);
    },
    skip:
        const bool.hasEnvironment('MODERATION_V2') ||
        const bool.hasEnvironment('LOCAL_API'),
  );
}
