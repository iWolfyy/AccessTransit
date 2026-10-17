import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_constants.dart';
import '../logic/tariff_fare.dart';
import 'saved_schedule_snapshot.dart';

/// Status of a passenger journey/booking.
enum JourneyStatus {
  confirmed('confirmed'),
  active('active'),
  completed('completed'),
  cancelled('cancelled');

  const JourneyStatus(this.value);

  final String value;

  static JourneyStatus fromString(String? value) {
    if (value == null || value.trim().isEmpty) return JourneyStatus.confirmed;
    final normalized = value.trim().toLowerCase();
    return JourneyStatus.values.firstWhere(
      (s) => s.value == normalized,
      orElse: () => JourneyStatus.confirmed,
    );
  }

  @override
  String toString() => value;
}

/// Represents a passenger's confirmed journey/booking stored in Firestore
/// at `journeys/{journeyId}`.
///
/// This is the connecting link between the passenger's booking and the
/// live bus location stream at `live_locations/{busId}`.
class JourneyModel {
  const JourneyModel({
    required this.journeyId,
    required this.passengerId,
    required this.routeId,
    required this.routeNumber,
    required this.routeTitle,
    required this.busId,
    required this.origin,
    required this.destination,
    this.status = JourneyStatus.confirmed,
    this.createdAt,
    this.fromStationId,
    this.toStationId,
    this.selectedDate,
    this.selectedTimeMinutes,
    this.departureAt,
    this.durationMinutes,
    this.estimatedFareLkr,
    this.fareQuote,
    this.busNo,
    this.serviceRunId,
    this.scheduleSnapshot,
    this.wheelchairAccessRequired = false,
    this.stepFreeOnly = false,
  });

  final String journeyId;

  /// Firebase Auth UID of the passenger.
  final String passengerId;

  /// Route identifier (e.g. `route_138`).
  final String routeId;

  /// Human-readable route number (e.g. `138`).
  final String routeNumber;

  /// Full route title (e.g. `Bus 138 → Bus 177`).
  final String routeTitle;

  /// Bus identifier used to subscribe to `live_locations/{busId}`.
  final String busId;

  final String origin;
  final String destination;
  final JourneyStatus status;
  final DateTime? createdAt;
  final String? fromStationId;
  final String? toStationId;
  final DateTime? selectedDate;
  final int? selectedTimeMinutes;
  final DateTime? departureAt;
  final int? durationMinutes;
  final int? estimatedFareLkr;
  final TariffFareQuote? fareQuote;
  final String? busNo;
  final String? serviceRunId;
  final SavedScheduleSnapshot? scheduleSnapshot;
  final bool wheelchairAccessRequired;
  final bool stepFreeOnly;
  bool get isOpen =>
      status == JourneyStatus.confirmed || status == JourneyStatus.active;

  factory JourneyModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return JourneyModel(
      journeyId:
          map[FirestoreConstants.fieldJourneyId]?.toString() ??
          documentId ??
          '',
      passengerId: map[FirestoreConstants.fieldPassengerId]?.toString() ?? '',
      routeId: map[FirestoreConstants.fieldRouteId]?.toString() ?? '',
      routeNumber: map[FirestoreConstants.fieldRouteNumber]?.toString() ?? '',
      routeTitle: map[FirestoreConstants.fieldRouteTitle]?.toString() ?? '',
      busId: map[FirestoreConstants.fieldBusId]?.toString() ?? '',
      origin: map[FirestoreConstants.fieldOrigin]?.toString() ?? '',
      destination: map[FirestoreConstants.fieldDestination]?.toString() ?? '',
      status: JourneyStatus.fromString(
        map[FirestoreConstants.fieldJourneyStatus]?.toString(),
      ),
      createdAt: _parseTimestamp(map[FirestoreConstants.fieldJourneyCreatedAt]),
      fromStationId: map['fromStationId'] as String?,
      toStationId: map['toStationId'] as String?,
      selectedDate: _parseTimestamp(map['selectedDate']),
      selectedTimeMinutes: (map['selectedTimeMinutes'] as num?)?.toInt(),
      departureAt: _parseTimestamp(map['departureAt']),
      durationMinutes: (map['durationMinutes'] as num?)?.toInt(),
      estimatedFareLkr: (map['estimatedFareLkr'] as num?)?.toInt(),
      fareQuote: map['fareQuote'] is Map
          ? _readFare(Map<String, dynamic>.from(map['fareQuote']))
          : null,
      busNo: map['busNo'] as String?,
      serviceRunId: map['serviceRunId'] as String?,
      scheduleSnapshot: _readSnapshot(map['scheduleSnapshot']),
      wheelchairAccessRequired: map['wheelchairAccessRequired'] == true,
      stepFreeOnly: map['stepFreeOnly'] == true,
    );
  }

  Map<String, dynamic> toMap({bool isCreate = false}) {
    return {
      FirestoreConstants.fieldJourneyId: journeyId,
      FirestoreConstants.fieldPassengerId: passengerId,
      FirestoreConstants.fieldRouteId: routeId,
      FirestoreConstants.fieldRouteNumber: routeNumber,
      FirestoreConstants.fieldRouteTitle: routeTitle,
      FirestoreConstants.fieldBusId: busId,
      FirestoreConstants.fieldOrigin: origin,
      FirestoreConstants.fieldDestination: destination,
      FirestoreConstants.fieldJourneyStatus: status.value,
      FirestoreConstants.fieldJourneyCreatedAt: isCreate
          ? FieldValue.serverTimestamp()
          : createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : null,
      if (fromStationId != null) 'fromStationId': fromStationId,
      if (toStationId != null) 'toStationId': toStationId,
      if (selectedDate != null)
        'selectedDate': Timestamp.fromDate(selectedDate!),
      if (selectedTimeMinutes != null)
        'selectedTimeMinutes': selectedTimeMinutes,
      if (departureAt != null) 'departureAt': Timestamp.fromDate(departureAt!),
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (estimatedFareLkr != null) 'estimatedFareLkr': estimatedFareLkr,
      if (fareQuote != null) 'fareQuote': fareQuote!.toMap(),
      if (busNo != null) 'busNo': busNo,
      if (serviceRunId != null) 'serviceRunId': serviceRunId,
      if (scheduleSnapshot != null)
        'scheduleSnapshot': scheduleSnapshot!.toMap(),
      'wheelchairAccessRequired': wheelchairAccessRequired,
      'stepFreeOnly': stepFreeOnly,
    };
  }

  JourneyModel copyWith({
    String? journeyId,
    String? passengerId,
    String? routeId,
    String? routeNumber,
    String? routeTitle,
    String? busId,
    String? origin,
    String? destination,
    JourneyStatus? status,
    DateTime? createdAt,
  }) {
    return JourneyModel(
      journeyId: journeyId ?? this.journeyId,
      passengerId: passengerId ?? this.passengerId,
      routeId: routeId ?? this.routeId,
      routeNumber: routeNumber ?? this.routeNumber,
      routeTitle: routeTitle ?? this.routeTitle,
      busId: busId ?? this.busId,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      fromStationId: fromStationId,
      toStationId: toStationId,
      selectedDate: selectedDate,
      selectedTimeMinutes: selectedTimeMinutes,
      departureAt: departureAt,
      durationMinutes: durationMinutes,
      estimatedFareLkr: estimatedFareLkr,
      fareQuote: fareQuote,
      busNo: busNo,
      serviceRunId: serviceRunId,
      scheduleSnapshot: scheduleSnapshot,
      wheelchairAccessRequired: wheelchairAccessRequired,
      stepFreeOnly: stepFreeOnly,
    );
  }

  static SavedScheduleSnapshot? _readSnapshot(dynamic raw) {
    try {
      return raw is Map
          ? SavedScheduleSnapshot.fromMap(Map<String, dynamic>.from(raw))
          : null;
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static TariffFareQuote? _readFare(Map<String, dynamic> value) {
    try {
      return TariffFareQuote.fromMap(value);
    } catch (_) {
      return null;
    }
  }
}
