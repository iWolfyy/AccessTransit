import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../constants/firestore_constants.dart';
import '../models/user_model.dart';

/// Firestore access for the `users` collection (AC-48, AC-49).
///
/// Document path: `users/{uid}` where [uid] is the Firebase Auth user ID.
class UserService {
  UserService({FirebaseFirestore? firestore}) : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore? get _db {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      return null;
    }
  }

  /// In-memory user fallback cache mirroring FirestoreService's resilience pattern.
  static final Map<String, UserModel> _localUserFallback = {};

  /// Reference to the `users` collection in Firestore.
  CollectionReference<Map<String, dynamic>>? get usersCollection =>
      _db?.collection(FirestoreConstants.usersCollection);

  /// Reference to a single user document by [uid].
  DocumentReference<Map<String, dynamic>>? userDocument(String uid) {
    return usersCollection?.doc(uid);
  }

  /// Creates a missing profile, preserving and returning any existing profile.
  ///
  /// The transaction makes registration retries safe across devices. Firestore
  /// failures propagate so a failed read cannot be mistaken for a missing user.
  Future<UserModel> createUser(UserModel user) async {
    final db = _db;
    if (db == null) {
      return _localUserFallback.putIfAbsent(user.uid, () => user);
    }

    final doc = db.collection(FirestoreConstants.usersCollection).doc(user.uid);
    final profile = await db.runTransaction<UserModel>((transaction) async {
      final snapshot = await transaction.get(doc);
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.data()!);
        data[FirestoreConstants.fieldUid] = user.uid;
        return UserModel.fromMap(data);
      }

      transaction.set(doc, user.toMap(isCreate: true));
      return user;
    });

    _localUserFallback[user.uid] = profile;
    return profile;
  }

  /// Updates an existing user profile document in Firestore.
  Future<void> updateUser(UserModel user) async {
    _localUserFallback[user.uid] = user;
    try {
      final doc = userDocument(user.uid);
      if (doc != null) {
        await doc.set(user.toMap(), SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('UserService.updateUser fallback: $e');
    }
  }

  /// Reads a user profile from Firestore.
  Future<UserModel?> getUser(String uid) async {
    try {
      final data = await getUserData(uid);
      if (data != null) {
        // Ensure the document always exposes a uid for parsing.
        final mapped = Map<String, dynamic>.from(data);
        mapped.putIfAbsent(FirestoreConstants.fieldUid, () => uid);
        if (mapped[FirestoreConstants.fieldUid] == null ||
            mapped[FirestoreConstants.fieldUid].toString().isEmpty) {
          mapped[FirestoreConstants.fieldUid] = uid;
        }

        final user = UserModel.fromMap(mapped);
        _localUserFallback[uid] = user;
        return user;
      }
    } catch (e) {
      debugPrint('UserService.getUser fallback: $e');
    }

    return _localUserFallback[uid];
  }

  /// Reads raw user document data from Firestore.
  ///
  /// Returns `null` if the document does not exist.
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = userDocument(uid);
      if (doc != null) {
        final snapshot = await doc.get();
        if (snapshot.exists && snapshot.data() != null) {
          return snapshot.data();
        }
      }
    } catch (e) {
      debugPrint('UserService.getUserData fallback: $e');
    }
    return _localUserFallback[uid]?.toMap();
  }

  /// Listens to real-time updates for a user document.
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUser(String uid) {
    final doc = userDocument(uid);
    if (doc != null) {
      return doc.snapshots();
    }
    return const Stream.empty();
  }

  /// Checks whether a user document already exists.
  Future<bool> userExists(String uid) async {
    try {
      final doc = userDocument(uid);
      if (doc != null) {
        final snapshot = await doc.get();
        return snapshot.exists;
      }
    } catch (e) {
      debugPrint('UserService.userExists fallback: $e');
    }
    return _localUserFallback.containsKey(uid);
  }

  /// Atomically updates user points, reportsSubmitted, and verifiedCount stats.
  Future<void> updateUserStats(
    String uid, {
    int pointsDelta = 0,
    int reportsDelta = 0,
    int verificationsDelta = 0,
  }) async {
    if (uid.isEmpty) return;

    final user = await getUser(uid);
    if (user == null) {
      final newUser = UserModel(
        uid: uid,
        name: 'User',
        email: '',
        points: (pointsDelta).clamp(0, 999999),
        reportsSubmitted: (reportsDelta).clamp(0, 999999),
        verifiedCount: (verificationsDelta).clamp(0, 999999),
      );
      try {
        final doc = userDocument(uid);
        if (doc != null) {
          await doc.set(newUser.toMap(isCreate: true));
        }
      } catch (e) {
        debugPrint('UserService.updateUserStats fallback set: $e');
        return;
      }
      _localUserFallback[uid] = newUser;
      return;
    }

    final newPoints = (user.points + pointsDelta).clamp(0, 999999);
    final newReports = (user.reportsSubmitted + reportsDelta).clamp(0, 999999);
    final newVerifications = (user.verifiedCount + verificationsDelta).clamp(
      0,
      999999,
    );

    final updatedUser = user.copyWith(
      points: newPoints,
      reportsSubmitted: newReports,
      verifiedCount: newVerifications,
    );

    try {
      final doc = userDocument(uid);
      if (doc != null) {
        await doc.set({
          FirestoreConstants.fieldPoints: newPoints,
          FirestoreConstants.fieldReportsSubmitted: newReports,
          FirestoreConstants.fieldVerifiedCount: newVerifications,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('UserService.updateUserStats fallback update: $e');
      return;
    }
    // Rejected client counter writes must not manufacture rewards in memory.
    _localUserFallback[uid] = updatedUser;
  }
}
