import 'package:access_transit/constants/firestore_constants.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/services/assistance_submission_service.dart';
import 'package:access_transit/services/report_outbox_storage.dart';
import 'package:access_transit/services/report_submission_service.dart';
import 'package:access_transit/services/report_photo_storage.dart';
import 'package:access_transit/services/auth_service.dart';
import 'package:access_transit/services/sample_test_mode.dart';
import 'package:access_transit/services/transit_catalogue.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'sample mode explains unavailable external uploads and registration',
    () async {
      if (!SampleTestMode.enabled) return;
      expect(ReportPhotoStorage.configured.isConfigured, isFalse);
      await expectLater(
        ReportPhotoStorage.configured.upload(Uint8List.fromList([1, 2, 3])),
        throwsStateError,
      );
      await expectLater(
        AuthService().register(
          name: 'Sample',
          email: 'sample@example.test',
          password: 'unused',
        ),
        throwsStateError,
      );
    },
  );
  test(
    'mode partitions catalogue, users, operations and durable owner data',
    () {
      const prefix = SampleTestMode.enabled ? 'sample_test/shared/' : '';
      expect(FirestoreConstants.staticBusesCollection, '${prefix}buses');
      expect(FirestoreConstants.routesCollection, '${prefix}routes');
      expect(FirestoreConstants.stationsCollection, '${prefix}stations');
      expect(FirestoreConstants.reportsCollection, '${prefix}reports');
      expect(FirestoreConstants.journeysCollection, '${prefix}journeys');
      expect(FirestoreConstants.usersCollection, '${prefix}users');
      expect(
        FirestoreConstants.liveLocationsCollection,
        '${prefix}live_locations',
      );
      expect(
        FirestoreConstants.boardingRequestsCollection,
        '${prefix}boarding_requests',
      );
      expect(
        SampleTestMode.collection('operator_access'),
        '${prefix}operator_access',
      );
      expect(SampleTestMode.collection('trips'), '${prefix}trips');
      final keys = [
        TransitCatalogue.storageKey,
        ReportSubmissionService.storageKey,
        AssistanceSubmissionService.storageKey,
        AccessibilityPreferencesService.accountKey('rider'),
      ];
      for (final key in keys) {
        expect(key.startsWith('sample_test_'), SampleTestMode.enabled);
      }
    },
  );

  test(
    'encrypted Android drafts use a different file channel in sample mode',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ReportOutboxStorage.channel, (call) async {
            calls.add(call.method);
            return call.method.startsWith('read') ? 'fixture draft' : null;
          });
      try {
        final storage = ReportOutboxStorage();
        expect(await storage.read(), 'fixture draft');
        await storage.write('sample');
        expect(
          calls,
          SampleTestMode.enabled
              ? ['readSample', 'writeSample']
              : ['read', 'write'],
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
