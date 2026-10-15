import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Explicit, debug-only backend for synthetic walkthroughs, never real services.
abstract final class LocalValidationBackend {
  static const enabled = bool.fromEnvironment('LOCAL_VALIDATION');
  static const projectId = 'demo-accesstransit';

  static Future<void> initialize() async {
    if (!kDebugMode ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      throw StateError('Local validation requires an Android debug build.');
    }
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'local-validation-key',
        appId: '1:1234567890:android:localvalidation',
        messagingSenderId: '1234567890',
        projectId: projectId,
      ),
    );
    if (Firebase.app().options.projectId != projectId) {
      throw StateError('Refusing validation with a non-demo Firebase project.');
    }
    // Android emulator alias for this development computer; never configurable
    // to a remote project/host. Connect before any application service starts.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8087);
    await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
  }
}
