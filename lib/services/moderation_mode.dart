import 'package:flutter/foundation.dart';

import 'local_validation_backend.dart';

/// Main builds use the configured HTTPS service and normal Firebase project.
/// The fixed emulator endpoint remains available only to explicit debug tests.
class ModerationConfiguration {
  const ModerationConfiguration({
    required this.requested,
    required this.localValidation,
    required this.debug,
    required this.origin,
    this.localApi = false,
  });
  final bool requested, localValidation, debug, localApi;
  final String origin;

  bool get local => requested && localValidation && debug;
  bool get sharedLocal => requested && localApi && !localValidation && debug;
  Uri? get apiOrigin => local
      ? Uri.parse('http://10.0.2.2:8787')
      : sharedLocal
      ? Uri.parse('http://10.0.2.2:8788')
      : Uri.tryParse(origin);

  bool acceptsOrigin(Uri? uri) =>
      isHttpsOrigin(uri) ||
      (local && !localApi && uri.toString() == 'http://10.0.2.2:8787') ||
      (sharedLocal && uri.toString() == 'http://10.0.2.2:8788');

  static bool isHttpsOrigin(Uri? uri) =>
      uri != null &&
      uri.scheme == 'https' &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty &&
      !uri.hasQuery &&
      !uri.hasFragment &&
      (uri.path.isEmpty || uri.path == '/');

  bool get enabled =>
      requested &&
      !(localValidation && localApi) &&
      (localValidation || localApi ? debug : isHttpsOrigin(apiOrigin));

  void validate() {
    if (!requested) return;
    if (localValidation && localApi) {
      throw StateError(
        'Select real Firebase localhost API or synthetic emulator tests, not both.',
      );
    }
    if ((localValidation || localApi) && !debug) {
      throw StateError(
        'Localhost API access requires an explicit debug build.',
      );
    }
    if (!localValidation && !localApi && !isHttpsOrigin(apiOrigin)) {
      throw StateError(
        'Moderation v2 requires MODERATION_API_ORIGIN with a trusted HTTPS origin.',
      );
    }
  }
}

abstract final class ModerationMode {
  static const requested = bool.fromEnvironment('MODERATION_V2');
  static const _buildConfiguration = ModerationConfiguration(
    requested: requested,
    localValidation: LocalValidationBackend.enabled,
    debug: kDebugMode,
    origin: String.fromEnvironment('MODERATION_API_ORIGIN'),
    localApi: bool.fromEnvironment('LOCAL_API'),
  );
  static ModerationConfiguration? _mainAppConfiguration;
  static ModerationConfiguration get configuration =>
      _mainAppConfiguration ?? _buildConfiguration;

  /// The app uses online Firebase only. Emulator configurations remain
  /// available to isolated tests, but cannot be selected by app startup.
  static ModerationConfiguration mainAppConfiguration({
    required ModerationConfiguration build,
    required bool android,
    required bool explicitV2,
    required bool explicitLocalApi,
  }) {
    if (build.localValidation || build.localApi) {
      throw StateError(
        'The app uses online Firebase. Remove LOCAL_VALIDATION and LOCAL_API; '
        'server operations require MODERATION_API_ORIGIN with an HTTPS origin.',
      );
    }
    return build;
  }

  static void initializeMainApp() {
    _mainAppConfiguration = mainAppConfiguration(
      build: _buildConfiguration,
      android: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
      explicitV2: const bool.hasEnvironment('MODERATION_V2'),
      explicitLocalApi: const bool.hasEnvironment('LOCAL_API'),
    );
  }

  @visibleForTesting
  static void resetMainAppConfiguration() => _mainAppConfiguration = null;
  static bool get enabled => configuration.enabled;
  static bool get local => configuration.local;
  static bool get sharedLocal => configuration.sharedLocal;
  static Uri? get apiOrigin => configuration.apiOrigin;
  static void validate() => configuration.validate();
}
