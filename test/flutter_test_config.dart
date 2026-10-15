import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:access_transit/services/firestore_service.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Test adapter only. Production Android uses the encrypted native channel.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('access_transit/report_outbox'),
        (call) async {
          final prefs = await SharedPreferences.getInstance();
          if (call.method == 'read') {
            return prefs.getString('private_outbox_test');
          }
          if (!await prefs.setString(
            'private_outbox_test',
            call.arguments as String,
          )) {
            throw StateError('Save failed');
          }
          return null;
        },
      );
  // Existing planning tests explicitly use fixtures, never runtime demo fallbacks.
  FirestoreService.installCatalogueFixtures();
  await testMain();
}
