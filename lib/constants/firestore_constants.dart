/// Firestore collection and field names for AccessTransit.
///
/// AC-48: Defines the `users` collection structure used across the app.
class FirestoreConstants {
  FirestoreConstants._();

  // --- Collections ---

  /// User profile documents keyed by Firebase Auth [uid].
  static const String usersCollection = 'users';

  // --- users/{userId} document fields ---

  static const String fieldUid = 'uid';
  static const String fieldName = 'name';
  static const String fieldEmail = 'email';
  static const String fieldPhone = 'phone';
  static const String fieldRole = 'role';
  static const String fieldCreatedAt = 'createdAt';
}
