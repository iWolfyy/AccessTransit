import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_constants.dart';
import 'enums/user_role.dart';

/// User profile stored in Firestore at `users/{uid}` (AC-49).
class UserModel {
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.role = UserRole.passenger,
    this.createdAt,
    this.points = 0,
    this.reportsSubmitted = 0,
    this.verifiedCount = 0,
  });

  final String uid;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final DateTime? createdAt;
  final int points;
  final int reportsSubmitted;
  final int verifiedCount;

  /// Calculates badges earned (1 badge per 100 points).
  int get badges => points ~/ 100;

  /// Builds a profile from Firebase Auth registration data.
  factory UserModel.fromAuth({
    required String uid,
    required String name,
    required String email,
    String? phone,
    UserRole role = UserRole.passenger,
    int points = 0,
    int reportsSubmitted = 0,
    int verifiedCount = 0,
  }) {
    return UserModel(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
      role: role,
      points: points,
      reportsSubmitted: reportsSubmitted,
      verifiedCount: verifiedCount,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map[FirestoreConstants.fieldUid]?.toString() ?? '',
      name: map[FirestoreConstants.fieldName]?.toString() ?? '',
      email: map[FirestoreConstants.fieldEmail]?.toString() ?? '',
      phone: map[FirestoreConstants.fieldPhone]?.toString(),
      role: UserRole.fromString(map[FirestoreConstants.fieldRole]?.toString()),
      createdAt: _parseTimestamp(map[FirestoreConstants.fieldCreatedAt]),
      points: (map[FirestoreConstants.fieldPoints] as num?)?.toInt() ?? 0,
      reportsSubmitted: (map[FirestoreConstants.fieldReportsSubmitted] as num?)?.toInt() ?? 0,
      verifiedCount: (map[FirestoreConstants.fieldVerifiedCount] as num?)?.toInt() ?? 0,
    );
  }

  /// Converts this profile to a Firestore document map.
  ///
  /// Set [isCreate] to `true` when writing a new document so Firestore
  /// stores the server timestamp for [createdAt].
  Map<String, dynamic> toMap({bool isCreate = false}) {
    return {
      FirestoreConstants.fieldUid: uid,
      FirestoreConstants.fieldName: name,
      FirestoreConstants.fieldEmail: email,
      FirestoreConstants.fieldPhone: phone,
      FirestoreConstants.fieldRole: role.value,
      FirestoreConstants.fieldCreatedAt: isCreate
          ? FieldValue.serverTimestamp()
          : createdAt != null
              ? Timestamp.fromDate(createdAt!)
              : null,
      FirestoreConstants.fieldPoints: points,
      FirestoreConstants.fieldReportsSubmitted: reportsSubmitted,
      FirestoreConstants.fieldVerifiedCount: verifiedCount,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    DateTime? createdAt,
    int? points,
    int? reportsSubmitted,
    int? verifiedCount,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      points: points ?? this.points,
      reportsSubmitted: reportsSubmitted ?? this.reportsSubmitted,
      verifiedCount: verifiedCount ?? this.verifiedCount,
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}
