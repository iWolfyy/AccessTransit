import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sample_test_mode.dart';

/// Android stores the bounded payload encrypted in app-private no-backup files.
/// Other platforms keep drafts in memory until a private persistent adapter exists.
class ReportOutboxStorage {
  static const channel = MethodChannel('access_transit/report_outbox');
  String? _memory;

  bool get _native =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  Future<String?> read() async {
    return _native
        ? await channel.invokeMethod<String>(
            SampleTestMode.enabled ? 'readSample' : 'read',
          )
        : _memory;
  }

  Future<void> write(String value) async {
    if (_native) {
      await channel.invokeMethod<void>(
        SampleTestMode.enabled ? 'writeSample' : 'write',
        value,
      );
    } else {
      _memory = value;
    }
  }
}
