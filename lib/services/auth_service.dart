import 'package:firebase_auth/firebase_auth.dart';

import '../models/enums/user_role.dart';
import '../models/user_model.dart';
import 'user_service.dart';

/// Handles Firebase Authentication for AccessTransit.
class AuthService {
  AuthService({FirebaseAuth? auth, UserService? userService})
    : _auth = auth ?? FirebaseAuth.instance,
      _userService = userService ?? UserService();

  final FirebaseAuth _auth;
  final UserService _userService;

  /// Currently signed-in Firebase user.
  User? get currentUser => _auth.currentUser;

  /// Stream that emits whenever the authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Registers a new AccessTransit user.
  ///
  /// 1. Creates the Firebase Authentication account.
  /// 2. Creates the corresponding Firestore user profile.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    UserRole role = UserRole.passenger,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw Exception('Failed to create Firebase user.');
    }

    final user = UserModel.fromAuth(
      uid: firebaseUser.uid,
      name: name,
      email: email,
      phone: phone,
      role: role,
    );

    await _userService.createUser(user);

    return user;
  }

  /// Logs an existing user into Firebase Authentication.
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Logs out the currently authenticated user.
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Gets the Firestore profile of the currently authenticated user.
  Future<UserModel?> getCurrentUserProfile() async {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) {
      return null;
    }

    return _userService.getUser(firebaseUser.uid);
  }

  /// Sends a password reset email to the specified address.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
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
