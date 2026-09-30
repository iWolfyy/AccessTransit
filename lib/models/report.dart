import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_constants.dart';

/// Represents a community accessibility condition report for a station or bus.
///
/// Firestore path: `reports/{id}`
class Report {
  const Report({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.problemType,
    required this.status,
    required this.createdAt,
    this.lastConfirmedAt,
    this.confirmCount = 0,
    this.falseCount = 0,
    required this.userId,
    this.confirmedBy = const [],
    this.flaggedBy = const [],
  });

  final String id;
  final String targetType; // 'station' or 'bus'
  final String targetId;
  final String problemType;
  final String status; // 'active' or 'resolved'
  final DateTime createdAt;
  final DateTime? lastConfirmedAt;
  final int confirmCount;
  final int falseCount;
  final String userId;
  final List<String> confirmedBy;
  final List<String> flaggedBy;

  /// Factory to instantiate a [Report] from a Firestore map and optional document [id].
  factory Report.fromMap(Map<String, dynamic> map, {String? id}) {
    final parsedCreatedAt =
        _parseTimestamp(map[FirestoreConstants.fieldCreatedAt]) ??
            _parseTimestamp(map['createdAt']) ??
            DateTime.now();

    final parsedLastConfirmedAt =
        _parseTimestamp(map[FirestoreConstants.fieldLastConfirmedAt]) ??
            _parseTimestamp(map['lastConfirmedAt']);

    final rawConfirmedBy =
        map[FirestoreConstants.fieldConfirmedBy] as List<dynamic>? ??
            map['confirmedBy'] as List<dynamic>? ??
            [];
    final parsedConfirmedBy = rawConfirmedBy.map((e) => e.toString()).toList();

    final rawFlaggedBy =
        map[FirestoreConstants.fieldFlaggedBy] as List<dynamic>? ??
            map['flaggedBy'] as List<dynamic>? ??
            [];
    final parsedFlaggedBy = rawFlaggedBy.map((e) => e.toString()).toList();

    return Report(
      id: id ?? map['id']?.toString() ?? '',
      targetType: map[FirestoreConstants.fieldTargetType]?.toString() ??
          map['targetType']?.toString() ??
          'station',
      targetId: map[FirestoreConstants.fieldTargetId]?.toString() ??
          map['targetId']?.toString() ??
          '',
      problemType: map[FirestoreConstants.fieldProblemType]?.toString() ??
          map['problemType']?.toString() ??
          '',
      status: map[FirestoreConstants.fieldStatus]?.toString() ??
          map['status']?.toString() ??
          'active',
      createdAt: parsedCreatedAt,
      lastConfirmedAt: parsedLastConfirmedAt,
      confirmCount:
          (map[FirestoreConstants.fieldConfirmCount] as num?)?.toInt() ??
              (map['confirmCount'] as num?)?.toInt() ??
              0,
      falseCount:
          (map[FirestoreConstants.fieldFalseCount] as num?)?.toInt() ??
              (map['falseCount'] as num?)?.toInt() ??
              0,
      userId: map[FirestoreConstants.fieldUserId]?.toString() ??
          map['userId']?.toString() ??
          '',
      confirmedBy: parsedConfirmedBy,
      flaggedBy: parsedFlaggedBy,
    );
  }

  /// Factory to instantiate a [Report] from a Firestore [DocumentSnapshot].
  factory Report.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return Report.fromMap(data, id: snapshot.id);
  }

  /// Converts the [Report] instance into a Firestore map representation.
  Map<String, dynamic> toMap({bool isServerTimestamp = false}) {
    return {
      FirestoreConstants.fieldTargetType: targetType,
      FirestoreConstants.fieldTargetId: targetId,
      FirestoreConstants.fieldProblemType: problemType,
      FirestoreConstants.fieldStatus: status,
      FirestoreConstants.fieldCreatedAt: isServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
      FirestoreConstants.fieldLastConfirmedAt: lastConfirmedAt != null
          ? Timestamp.fromDate(lastConfirmedAt!)
          : null,
      FirestoreConstants.fieldConfirmCount: confirmCount,
      FirestoreConstants.fieldFalseCount: falseCount,
      FirestoreConstants.fieldUserId: userId,
      FirestoreConstants.fieldConfirmedBy: confirmedBy,
      FirestoreConstants.fieldFlaggedBy: flaggedBy,
    };
  }

  /// Alias for [toMap] to maintain cross-model consistency.
  Map<String, dynamic> toFirestore({bool isServerTimestamp = false}) =>
      toMap(isServerTimestamp: isServerTimestamp);

  /// Creates a copy of this [Report] with updated fields.
  Report copyWith({
    String? id,
    String? targetType,
    String? targetId,
    String? problemType,
    String? status,
    DateTime? createdAt,
    DateTime? lastConfirmedAt,
    int? confirmCount,
    int? falseCount,
    String? userId,
    List<String>? confirmedBy,
    List<String>? flaggedBy,
  }) {
    return Report(
      id: id ?? this.id,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      problemType: problemType ?? this.problemType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastConfirmedAt: lastConfirmedAt ?? this.lastConfirmedAt,
      confirmCount: confirmCount ?? this.confirmCount,
      falseCount: falseCount ?? this.falseCount,
      userId: userId ?? this.userId,
      confirmedBy: confirmedBy ?? List.from(this.confirmedBy),
      flaggedBy: flaggedBy ?? List.from(this.flaggedBy),
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
