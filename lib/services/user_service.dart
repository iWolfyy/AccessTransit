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
    final initial = user.copyWith(
      points: 0,
      reportsSubmitted: 0,
      verifiedCount: 0,
    );
    final db = _db;
    if (db == null) {
      return _localUserFallback.putIfAbsent(user.uid, () => initial);
    }

    final doc = db.collection(FirestoreConstants.usersCollection).doc(user.uid);
    final profile = await db.runTransaction<UserModel>((transaction) async {
      final snapshot = await transaction.get(doc);
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.data()!);
        data[FirestoreConstants.fieldUid] = user.uid;
        return UserModel.fromMap(data);
      }

      transaction.set(doc, initial.toMap(isCreate: true));
      return initial;
    });

    _localUserFallback[user.uid] = profile;
    return profile;
  }

  /// Updates an existing user profile document in Firestore.
  Future<UserModel> updateUser(UserModel user) async {
    final db = _db;
    if (db == null) {
      throw StateError('Profile updates require a shared connection.');
    }
    final doc = db.collection(FirestoreConstants.usersCollection).doc(user.uid);
    final acknowledged = await db.runTransaction<UserModel>((tx) async {
      final snapshot = await tx.get(doc);
      if (!snapshot.exists) throw StateError('Profile no longer exists.');
      final existing = UserModel.fromMap({
        ...snapshot.data()!,
        'uid': user.uid,
      });
      tx.update(doc, {
        'name': user.name,
        'phone': user.phone,
        'email': user.email,
      });
      return existing.copyWith(
        name: user.name,
        phone: user.phone,
        email: user.email,
      );
    });
    _localUserFallback[user.uid] = acknowledged;
    return acknowledged;
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
        if (!snapshot.metadata.hasPendingWrites &&
            snapshot.exists &&
            snapshot.data() != null) {
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
      return doc
          .snapshots(includeMetadataChanges: true)
          .where((snapshot) => !snapshot.metadata.hasPendingWrites);
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

  /// Clients cannot mutate trusted reward totals, including offline.
  Future<void> updateUserStats(
    String uid, {
    int pointsDelta = 0,
    int reportsDelta = 0,
    int verificationsDelta = 0,
  }) async {
    throw UnsupportedError(
      'Reward counters require trusted administrator reconciliation.',
    );
  }
}
