import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_constants.dart';
import '../models/user_model.dart';

/// Firestore access for the `users` collection (AC-48, AC-49).
///
/// Document path: `users/{uid}` where [uid] is the Firebase Auth user ID.
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

  /// Creates a new user profile document in Firestore.
  Future<void> createUser(UserModel user) async {
    await userDocument(user.uid).set(user.toMap(isCreate: true));
  }

  /// Updates an existing user profile document in Firestore.
  Future<void> updateUser(UserModel user) async {
    await userDocument(user.uid).update(user.toMap());
  }

  /// Reads a user profile from Firestore.
  Future<UserModel?> getUser(String uid) async {
    final data = await getUserData(uid);
    if (data == null) {
      return null;
    }
    return UserModel.fromMap(data);
  }

  /// Reads raw user document data from Firestore.
  ///
  /// Returns `null` if the document does not exist.
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final snapshot = await userDocument(uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return snapshot.data();
  }

  /// Listens to real-time updates for a user document.
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUser(String uid) {
    return userDocument(uid).snapshots();
  }

  /// Checks whether a user document already exists.
  Future<bool> userExists(String uid) async {
    final snapshot = await userDocument(uid).get();
    return snapshot.exists;
  }
}
