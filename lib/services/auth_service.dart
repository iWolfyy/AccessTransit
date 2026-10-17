import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/enums/user_role.dart';
import '../models/user_model.dart';
import 'user_service.dart';
import 'sample_test_mode.dart';
import 'report_submission_service.dart';
import 'accessibility_preferences_service.dart';
import 'firebase_driver_push.dart';

/// Handles Firebase Authentication for AccessTransit.
class AuthService {
  AuthService({FirebaseAuth? auth, UserService? userService})
    : _customAuth = auth,
      _userService = userService ?? UserService();

  final FirebaseAuth? _customAuth;
  final UserService _userService;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;

  /// Currently signed-in Firebase user.
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Stream that emits whenever the authentication state changes.
  Future<bool> hasAdminAccess() async {
    try {
      return (await currentUser?.getIdTokenResult(true))?.claims?['admin'] ==
          true;
    } catch (_) {
      return false;
    }
  }

  /// Stream that emits whenever the authentication state changes.
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Registers a new AccessTransit user.
  ///
  /// 1. Creates the Firebase Authentication account (or resumes if previous attempt was interrupted).
  /// 2. Creates a missing Firestore profile or preserves an existing profile.
  /// 3. Syncs the user's displayName from the preserved profile.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    UserRole role = UserRole.passenger,
  }) async {
    if (!role.canSelfRegister) {
      throw ArgumentError.value(
        role,
        'role',
        'Administrator registration is not allowed',
      );
    }
    if (SampleTestMode.enabled) {
      throw StateError(
        'Sample/Test mode uses the eight existing test accounts. Registration is available in normal mode.',
      );
    }
    User? firebaseUser;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      firebaseUser = credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // If an earlier attempt created the Auth user but was interrupted before completion,
        // attempt to authenticate with the provided credentials to complete registration.
        try {
          final loginCred = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          firebaseUser = loginCred.user;
        } catch (_) {
          // If sign-in fails, the email belongs to an existing different account
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    if (firebaseUser == null) {
      throw Exception('Failed to obtain authenticated Firebase user.');
    }

    await AccessibilityPreferencesService.instance.activateAccount(
      firebaseUser.uid,
    );

    final proposedUser = UserModel.fromAuth(
      uid: firebaseUser.uid,
      name: name,
      email: email,
      phone: phone,
      role: role,
    );

    final user = await _userService.createUser(proposedUser);

    try {
      await firebaseUser.updateDisplayName(user.name);
    } catch (e) {
      debugPrint('AuthService.register: updateDisplayName warning: $e');
    }

    return user;
  }

  /// Logs an existing user into Firebase Authentication.
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await AccessibilityPreferencesService.instance.activateAccount(
      credential.user?.uid,
    );
    return credential;
  }

  /// Logs out the currently authenticated user.
  Future<void> logout() async {
    try {
      await DriverPushRuntime.session?.disable();
      await AccessibilityPreferencesService.instance.activateAccount(null);
      await ReportSubmissionService.instance.activateAccount(null);
      await _auth.signOut();
    } catch (_) {
      await AccessibilityPreferencesService.instance.activateAccount(
        currentUser?.uid,
      );
      rethrow;
    }
  }

  /// Gets the Firestore profile of the currently authenticated user.
  ///
  /// Falls back to Firebase Auth account fields when the Firestore document
  /// is missing so the profile screen can still show identity details.
  Future<UserModel?> getCurrentUserProfile() async {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) {
      return null;
    }

    try {
      final profile = await _userService.getUser(firebaseUser.uid);
      if (profile != null) {
        final mergedName = profile.name.trim().isNotEmpty
            ? profile.name.trim()
            : (firebaseUser.displayName?.trim().isNotEmpty == true
                  ? firebaseUser.displayName!.trim()
                  : (firebaseUser.email?.split('@').first.isNotEmpty == true
                        ? firebaseUser.email!.split('@').first
                        : 'Passenger'));
        final mergedEmail = profile.email.trim().isNotEmpty
            ? profile.email.trim()
            : (firebaseUser.email ?? '');

        return profile.copyWith(name: mergedName, email: mergedEmail);
      }
    } catch (_) {
      // Fall through to Auth-based profile below.
    }

    final authName = firebaseUser.displayName?.trim().isNotEmpty == true
        ? firebaseUser.displayName!.trim()
        : (firebaseUser.email?.split('@').first.isNotEmpty == true
              ? firebaseUser.email!.split('@').first
              : 'Passenger');

    return UserModel(
      uid: firebaseUser.uid,
      name: authName,
      email: firebaseUser.email ?? '',
      phone: firebaseUser.phoneNumber,
    );
  }

  /// Sends a password reset email that opens the in-app reset flow.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
      actionCodeSettings: ActionCodeSettings(
        url: 'https://accesstransit-b615b.firebaseapp.com',
        handleCodeInApp: true,
        androidPackageName: 'com.accesstransit.access_transit',
        androidInstallApp: true,
        androidMinimumVersion: '1',
      ),
    );
  }

  /// Verifies a password reset code from the email link.
  Future<String> verifyPasswordResetCode(String code) async {
    return _auth.verifyPasswordResetCode(code);
  }

  /// Confirms a new password using the reset code from the email link.
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
  }

  /// Changes the password of the currently signed-in user.
  Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'No user is currently signed in.',
      );
    }

    await user.updatePassword(newPassword);
  }
}
