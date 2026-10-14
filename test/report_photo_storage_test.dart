import 'dart:convert';
import 'dart:typed_data';

import 'package:access_transit/services/report_photo_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const storage = ReportPhotoStorage(
    cloudName: 'test-cloud',
    uploadPreset: 'test-preset',
  );
  final jpeg = Uint8List.fromList([255, 216, 255, 224]);

  test('unconfigured uploads fail before any network request', () async {
    expect(
      const ReportPhotoStorage(cloudName: '', uploadPreset: '').isConfigured,
      isFalse,
    );
    await expectLater(
      const ReportPhotoStorage(cloudName: '', uploadPreset: '').upload(jpeg),
      throwsStateError,
    );
  });

  test(
    'unsigned request sends image bytes and returns shared HTTPS URL',
    () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://api.cloudinary.com/v1_1/test-cloud/image/upload',
        );
        expect(request.method, 'POST');
        final fields = Uri.splitQueryString(request.body);
        expect(fields['upload_preset'], 'test-preset');
        expect(fields['file'], 'data:image/jpeg;base64,${base64Encode(jpeg)}');
        expect(fields.containsKey('api_secret'), isFalse);
        return http.Response(
          '{"secure_url":"https://res.cloudinary.com/test-cloud/image/upload/photo.jpg"}',
          200,
        );
      });
      expect(
        await storage.upload(jpeg, client: client),
        startsWith('https://res.cloudinary.com/'),
      );
      client.close();
    },
  );

  test('unsupported and oversized files do not reach the network', () async {
    final client = MockClient((_) async => throw StateError('must not send'));
    await expectLater(
      storage.upload(Uint8List.fromList([1, 2, 3]), client: client),
      throwsArgumentError,
    );
    await expectLater(
      storage.upload(Uint8List(2 * 1024 * 1024 + 1), client: client),
      throwsArgumentError,
    );
    client.close();
  });

  test('rejects insecure and unrelated returned URLs', () async {
    for (final url in [
      'http://res.cloudinary.com/image.jpg',
      'https://other.example/image.jpg',
    ]) {
      final client = MockClient(
        (_) async => http.Response(jsonEncode({'secure_url': url}), 200),
      );
      await expectLater(storage.upload(jpeg, client: client), throwsStateError);
      client.close();
    }
  });

  test('classifies service failures separately from preset errors', () async {
    for (final status in [400, 429, 503]) {
      final client = MockClient((_) async => http.Response('{}', status));
      await expectLater(
        storage.upload(jpeg, client: client),
        throwsA(
          isA<PhotoUploadException>().having(
            (error) => error.isTransient,
            'transient',
            status != 400,
          ),
        ),
      );
      client.close();
    }
  });
}
