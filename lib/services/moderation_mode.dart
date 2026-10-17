import 'package:flutter/foundation.dart';

import 'local_validation_backend.dart';

abstract final class ModerationMode {
  static const requested = bool.fromEnvironment('MODERATION_V2');
  static bool get enabled =>
      requested && LocalValidationBackend.enabled && kDebugMode;
  static void validate() {
    if (requested && !enabled) {
      throw StateError(
        'Moderation v2 activation currently requires LOCAL_VALIDATION debug mode.',
      );
    }
  }
}
