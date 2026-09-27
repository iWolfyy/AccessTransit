import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_constants.dart';

/// Represents a passenger's request for boarding assistance (AC-86).
///
/// Stored in Firestore at `boarding_requests/{id}`.
class BoardingRequest {
  const BoardingRequest({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.busId,
    required this.routeNo,
    required this.stationId,
    required this.stopName,
    required this.assistanceTypes,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String riderId;
  final String riderName;
  final String busId;
  final String routeNo;
  final String stationId;
  final String stopName;
  final List<String> assistanceTypes;
  final String status; // 'pending', 'acknowledged', 'completed'
  final DateTime createdAt;

  /// Creates a [BoardingRequest] from a Firestore map.
  factory BoardingRequest.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawTypes = map[FirestoreConstants.fieldAssistanceTypes] as List<dynamic>? ??
        map['assistanceTypes'] as List<dynamic>? ??
        [];
    final parsedTypes = rawTypes.map((e) => e.toString()).toList();

    return BoardingRequest(
      id: id ?? map['id']?.toString() ?? '',
      riderId: map[FirestoreConstants.fieldRiderId]?.toString() ??
          map['riderId']?.toString() ??
          '',
      riderName: map[FirestoreConstants.fieldRiderName]?.toString() ??
          map['riderName']?.toString() ??
          'Rider',
      busId: map[FirestoreConstants.fieldBusId]?.toString() ??
          map['busId']?.toString() ??
          '',
      routeNo: map[FirestoreConstants.fieldRouteNo]?.toString() ??
          map['routeNo']?.toString() ??
          '',
      stationId: map[FirestoreConstants.fieldStationId]?.toString() ??
          map['stationId']?.toString() ??
          '',
      stopName: map[FirestoreConstants.fieldStopName]?.toString() ??
          map['stopName']?.toString() ??
          '',
      assistanceTypes: parsedTypes,
      status: map[FirestoreConstants.fieldRequestStatus]?.toString() ??
          map['status']?.toString() ??
          'pending',
      createdAt: _parseTimestamp(map[FirestoreConstants.fieldCreatedAt]) ??
          DateTime.now(),
    );
  }

  /// Creates a [BoardingRequest] from a Firestore [DocumentSnapshot].
  factory BoardingRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return BoardingRequest.fromMap(data, id: snapshot.id);
  }

  /// Converts this request into a Firestore map representation.
  Map<String, dynamic> toMap({bool isServerTimestamp = false}) {
    return {
      FirestoreConstants.fieldRiderId: riderId,
      FirestoreConstants.fieldRiderName: riderName,
      FirestoreConstants.fieldBusId: busId,
      FirestoreConstants.fieldRouteNo: routeNo,
      FirestoreConstants.fieldStationId: stationId,
      FirestoreConstants.fieldStopName: stopName,
      FirestoreConstants.fieldAssistanceTypes: assistanceTypes,
      FirestoreConstants.fieldRequestStatus: status,
      FirestoreConstants.fieldCreatedAt: isServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a copy of this request with updated fields.
  BoardingRequest copyWith({
    String? id,
    String? riderId,
    String? riderName,
    String? busId,
    String? routeNo,
    String? stationId,
    String? stopName,
    List<String>? assistanceTypes,
    String? status,
    DateTime? createdAt,
  }) {
    return BoardingRequest(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      busId: busId ?? this.busId,
      routeNo: routeNo ?? this.routeNo,
      stationId: stationId ?? this.stationId,
      stopName: stopName ?? this.stopName,
      assistanceTypes: assistanceTypes ?? List.from(this.assistanceTypes),
      status: status ?? this.status,
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
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
