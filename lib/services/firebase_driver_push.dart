import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'driver_notifications.dart';
import 'local_validation_backend.dart';
import 'sample_test_mode.dart';
import 'transit_catalogue.dart';

abstract final class DriverPushConfiguration {
  static const requested = bool.fromEnvironment('PUSH_NOTIFICATIONS');
  // Remains empty until a dedicated test project and trusted v2 HTTPS host have
  // been configured and reviewed together. A flag alone cannot activate FCM.
  static const reviewedTestProjectId = '';
  static void validateBuild() {
    if (!requested) return;
    if (reviewedTestProjectId.isEmpty ||
        reviewedTestProjectId == 'accesstransit-b615b' ||
        !kDebugMode ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        LocalValidationBackend.enabled ||
        SampleTestMode.enabled ||
        TransitCatalogue.demo) {
      throw StateError(
        'Push requires a reviewed dedicated Android test project and v2 HTTPS host; local/demo/shared activation is disabled.',
      );
    }
  }

  static void validateProject() {
    validateBuild();
    if (!requested ||
        Firebase.app().options.projectId != reviewedTestProjectId) {
      throw StateError(
        'The active Firebase project is not the reviewed push test project.',
      );
    }
  }
}

@pragma('vm:entry-point')
Future<void> driverPushBackground(RemoteMessage message) async {
  // Android displays the generic notification payload. Never acknowledge a
  // request, access passenger data, navigate or log message/token data here.
}

class FirebaseDriverPush implements DriverPushDevice {
  FirebaseDriverPush() {
    DriverPushConfiguration.validateProject();
    FirebaseMessaging.onBackgroundMessage(driverPushBackground);
  }
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  @override
  Stream<String> get tokens => _messaging.onTokenRefresh;
  @override
  Stream<Map<String, dynamic>> get foreground =>
      FirebaseMessaging.onMessage.map((m) => m.data);
  @override
  Stream<Map<String, dynamic>> get opened =>
      FirebaseMessaging.onMessageOpenedApp.map((m) => m.data);
  @override
  Future<bool> permission({required bool request}) async {
    await _messaging.setAutoInitEnabled(false);
    final settings = request
        ? await _messaging.requestPermission()
        : await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  @override
  Future<String?> token() => _messaging.getToken();
  @override
  Future<void> deleteToken() async {
    await _messaging.setAutoInitEnabled(false);
    await _messaging.deleteToken();
  }

  @override
  Future<Map<String, dynamic>?> initialMessage() async =>
      (await _messaging.getInitialMessage())?.data;
  static Future<void> createChannel(String name, String description) =>
      const MethodChannel('access_transit/notification_channels')
          .invokeMethod<void>('create', {
            'name': name,
            'description': description,
          });
}

/// Empty in all current normal/local/demo builds. Used by profile/logout hooks
/// only after the reviewed staging gate has constructed the controller.
abstract final class DriverPushRuntime {
  static final changes = ValueNotifier<DriverNotifications?>(null);
  static DriverNotifications? get session => changes.value;
  static set session(DriverNotifications? value) => changes.value = value;
}
