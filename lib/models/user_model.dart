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
  });

  final String uid;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final DateTime? createdAt;

  /// Builds a profile from Firebase Auth registration data.
  factory UserModel.fromAuth({
    required String uid,
    required String name,
    required String email,
    String? phone,
    UserRole role = UserRole.passenger,
  }) {
    return UserModel(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
      role: role,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map[FirestoreConstants.fieldUid] as String,
      name: map[FirestoreConstants.fieldName] as String? ?? '',
      email: map[FirestoreConstants.fieldEmail] as String? ?? '',
      phone: map[FirestoreConstants.fieldPhone] as String?,
      role: UserRole.fromString(map[FirestoreConstants.fieldRole] as String?),
      createdAt: _parseTimestamp(map[FirestoreConstants.fieldCreatedAt]),
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
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
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
