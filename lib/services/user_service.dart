import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_constants.dart';

/// Read access to the Firestore `users` collection (AC-48).
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
