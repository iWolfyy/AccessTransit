import 'package:access_transit/services/local_validation_backend.dart';
import 'package:access_transit/services/report_photo_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:typed_data';

void main() {
  test('local backend is opt-in and bound to a Firebase demo project', () {
    expect(LocalValidationBackend.projectId, 'demo-accesstransit');
    expect(
      LocalValidationBackend.enabled,
      const bool.fromEnvironment('LOCAL_VALIDATION'),
    );
  });
  if (LocalValidationBackend.enabled) {
    test(
      'local validation cannot send photos to an external provider',
      () async {
        await expectLater(
          const ReportPhotoStorage().upload(
            Uint8List.fromList([255, 216, 255]),
          ),
          throwsStateError,
        );
      },
    );
  }
}
