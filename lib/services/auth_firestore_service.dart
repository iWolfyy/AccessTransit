import '../models/enums/user_role.dart';
import '../models/user_model.dart';
import 'user_service.dart';

/// Links Firebase Authentication with Firestore user profiles (AC-50).
///
/// This service does not perform Auth operations. After Wijesooriya (IT)
/// completes registration or login with `firebase_auth`, call the methods
/// below to read or write the matching Firestore profile at `users/{uid}`.
///
/// Example registration handoff:
/// ```dart
/// final credential = await FirebaseAuth.instance
///     .createUserWithEmailAndPassword(email: email, password: password);
///
/// await AuthFirestoreService().saveUserAfterRegistration(
///   uid: credential.user!.uid,
///   name: name,
///   email: email,
///   phone: phone,
/// );
/// ```
class AuthFirestoreService {
  AuthFirestoreService({UserService? userService})
      : _userService = userService ?? UserService();

  final UserService _userService;

  /// Creates the Firestore profile after a successful Auth registration.
  ///
  /// Safe to call more than once for the same [uid]; existing profiles are
  /// left unchanged.
  Future<void> saveUserAfterRegistration({
    required String uid,
    required String name,
    required String email,
    String? phone,
    UserRole role = UserRole.passenger,
  }) async {
    if (await _userService.userExists(uid)) {
      return;
    }

    final user = UserModel.fromAuth(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
      role: role,
    );

    await _userService.createUser(user);
  }

  /// Loads the Firestore profile for the currently signed-in Auth user.
  Future<UserModel?> loadUserProfile(String uid) async {
    return _userService.getUser(uid);
  }

  /// Updates editable profile fields after registration details change.
  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String email,
    String? phone,
    UserRole? role,
  }) async {
    final existingUser = await _userService.getUser(uid);
    if (existingUser == null) {
      throw StateError('Cannot update profile because user $uid does not exist.');
    }

    final updatedUser = existingUser.copyWith(
      name: name,
      email: email,
      phone: phone,
      role: role,
    );

    await _userService.updateUser(updatedUser);
  }
}
