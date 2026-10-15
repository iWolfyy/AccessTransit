import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'local_validation_backend.dart';
import 'sample_test_mode.dart';

/// Cloudinary unsigned uploads: no API secret or billing account in the app.
class ReportPhotoStorage {
  const ReportPhotoStorage({
    this.cloudName = const String.fromEnvironment(
      'CLOUDINARY_CLOUD_NAME',
      defaultValue: 'dyrynkuh3',
    ),
    this.uploadPreset = const String.fromEnvironment(
      'CLOUDINARY_UPLOAD_PRESET',
      defaultValue: 'access_transit_reports',
    ),
  });

  static const configured = ReportPhotoStorage();
  final String cloudName;
  final String uploadPreset;
  bool get isConfigured =>
      !SampleTestMode.enabled &&
      cloudName.trim().isNotEmpty &&
      uploadPreset.trim().isNotEmpty;

  Future<String> upload(Uint8List bytes, {http.Client? client}) async {
    if (LocalValidationBackend.enabled || SampleTestMode.enabled) {
      throw StateError(
        'External photo uploads are disabled in test mode. Use text-only sample reports.',
      );
    }
    if (!isConfigured) throw StateError('Photo uploads are not configured.');
    if (bytes.isEmpty || bytes.length > 2 * 1024 * 1024) {
      throw ArgumentError('Photo must be at most 2 MB.');
    }
    final png =
        bytes.length >= 8 &&
        bytes.take(8).join(',') == '137,80,78,71,13,10,26,10';
    final jpeg =
        bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255;
    final webp =
        bytes.length >= 12 &&
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP';
    if (!png && !jpeg && !webp) {
      throw ArgumentError('Unsupported photo format.');
    }
    final mime = png
        ? 'image/png'
        : jpeg
        ? 'image/jpeg'
        : 'image/webp';
    final transport = client ?? http.Client();
    try {
      final response = await transport
          .post(
            Uri.https(
              'api.cloudinary.com',
              '/v1_1/${cloudName.trim()}/image/upload',
            ),
            body: {
              'upload_preset': uploadPreset.trim(),
              'file': 'data:$mime;base64,${base64Encode(bytes)}',
            },
          )
          .timeout(const Duration(seconds: 18));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw PhotoUploadException(response.statusCode);
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final url = data['secure_url'];
      final uri = url is String ? Uri.tryParse(url) : null;
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host != 'res.cloudinary.com') {
        throw StateError(
          'Photo upload did not return a shared Cloudinary URL.',
        );
      }
      return url as String;
    } finally {
      if (client == null) transport.close();
    }
  }
}

class PhotoUploadException implements Exception {
  const PhotoUploadException(this.statusCode);
  final int statusCode;
  bool get isTransient =>
      statusCode == 408 || statusCode == 429 || statusCode >= 500;
}
