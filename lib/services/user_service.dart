import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_constants.dart';
import '../models/user_model.dart';

/// Provides access to the Firestore `users` collection (AC-48).
class UserService {
  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Reference to the `users` collection in Firestore.
  CollectionReference<Map<String, dynamic>> get usersCollection =>
      _firestore.collection(FirestoreConstants.usersCollection);

  /// Reference to a single user document by [uid].
  DocumentReference<Map<String, dynamic>> userDocument(String uid) {
    return usersCollection.doc(uid);
  }

  /// Reads a user profile from Firestore.
  Future<UserModel?> getUser(String uid) async {
    final snapshot = await userDocument(uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return UserModel.fromMap(snapshot.data()!);
  }

  /// Checks whether a user document already exists.
  Future<bool> userExists(String uid) async {
    final snapshot = await userDocument(uid).get();
    return snapshot.exists;
  }
}
