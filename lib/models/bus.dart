import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_constants.dart';

/// Represents a bus vehicle operating on a route, including its vehicle registration number,
/// scheduled times, route reference, and accessibility attributes.
///
/// Firestore path: `buses/{id}`
class Bus {
  const Bus({
    required this.id,
    required this.routeNo,
    this.busNo,
    this.routeId,
    this.scheduledDeparture,
    this.stops = const [],
    this.scheduleTimes = const [],
    required this.hasRamp,
    required this.lowFloor,
    this.rampOk,
    this.rampCheckedAt,
    this.rampCheckedBy,
    required this.occupancy,
    this.driverId,
    this.catalogueRecordType = 'vehicle',
    this.sourceUrl,
  });

  /// Unique document ID in Firestore (e.g. `'bus_138_01'`).
  final String id;

  /// Assigned bus route number (e.g. `'138'`).
  final String routeNo;

  /// Vehicle license plate or registration number (e.g. `'WP NA-4521'`).
  /// Falls back to [id] if not explicitly specified.
  final String? busNo;

  /// Reference to the parent [BusRoute] ID (e.g. `'route_138'`).
  final String? routeId;

  /// Primary scheduled departure time string (e.g. `'08:00 AM'`).
  final String? scheduledDeparture;

  /// Ordered stops served by this bus run.
  final List<String> stops;

  /// Ordered scheduled time strings aligned with stops (e.g. `["08:00 AM", "08:12 AM"]`).
  final List<String> scheduleTimes;

  /// True if vehicle is equipped with a wheelchair ramp.
  final bool hasRamp;

  /// True if bus has low-floor step-free entry.
  final bool lowFloor;

  /// Raw observation; operational use additionally requires time/source/freshness.
  final bool? rampOk;
  final DateTime? rampCheckedAt;
  final String? rampCheckedBy;

  /// Current passenger crowding level: `'low'`, `'medium'`, or `'high'`.
  final String occupancy;

  /// Assigned driver or operator user identifier.
  final String? driverId;
  final String catalogueRecordType;
  final String? sourceUrl;
  bool get isPublishedTimetable => catalogueRecordType == 'published_timetable';

  /// Display string for the bus registration number.
  String get displayBusNo => isPublishedTimetable
      ? 'Vehicle unassigned'
      : busNo != null && busNo!.isNotEmpty
      ? busNo!
      : id;

  /// Whether dated vehicle evidence satisfies the operational ramp criterion.
  bool get wheelchairAccessible => hasRamp && rampCondition() == true;

  /// Negative observations remain unresolved; working checks expire after 24h.
  bool? rampCondition({DateTime? currentTime}) {
    if (rampOk != true) return rampOk;
    final now = currentTime ?? DateTime.now();
    final checked = rampCheckedAt;
    if (checked == null ||
        rampCheckedBy?.trim().isNotEmpty != true ||
        checked.isAfter(now) ||
        now.difference(checked) > const Duration(hours: 24)) {
      return null;
    }
    return true;
  }

  static DateTime? _parseCheckTime(dynamic value) {
    try {
      DateTime? parsed;
      if (value is Timestamp) parsed = value.toDate();
      if (value is DateTime) parsed = value;
      if (value is int) parsed = DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) {
        final date = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:T| |$)')
            .firstMatch(value);
        if (date == null) return null;
        final year = int.parse(date[1]!);
        final month = int.parse(date[2]!);
        final day = int.parse(date[3]!);
        final calendar = DateTime.utc(year, month, day);
        if (calendar.year != year ||
            calendar.month != month ||
            calendar.day != day) {
          return null;
        }
        final time = RegExp(r'[T ](\d{2}):?(\d{2})(?::?(\d{2}))?')
            .firstMatch(value);
        if (time != null &&
            (int.parse(time[1]!) > 23 ||
                int.parse(time[2]!) > 59 ||
                int.parse(time[3] ?? '0') > 59)) {
          return null;
        }
        parsed = DateTime.tryParse(value);
      }
      return parsed != null && parsed.year >= 1 && parsed.year <= 9999
          ? parsed
          : null;
    } on ArgumentError {
      return null;
    }
  }

  /// Effective primary departure time.
  String get effectiveDepartureTime {
    if (scheduledDeparture != null && scheduledDeparture!.isNotEmpty) {
      return scheduledDeparture!;
    }
    if (scheduleTimes.isNotEmpty) {
      return scheduleTimes.first;
    }
    return '08:00 AM';
  }

  /// Helper to get or generate fallback schedule time for a stop index if missing.
  String getScheduledTimeForStop(int index) {
    if (index >= 0 && index < scheduleTimes.length) {
      return scheduleTimes[index];
    }
    // Default fallback calculation starting at 08:00 AM with +12 mins per stop
    final startMinutes = 8 * 60 + (index * 12);
    final hour = (startMinutes ~/ 60) % 24;
    final minute = startMinutes % 60;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Factory to instantiate a [Bus] from a Firestore map and optional document [id].
  factory Bus.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawStops =
        map[FirestoreConstants.fieldStops] as List<dynamic>? ??
        map['stops'] as List<dynamic>? ??
        [];
    final parsedStops = rawStops.map((e) => e.toString()).toList();

    final rawTimes = map['scheduleTimes'] as List<dynamic>? ?? [];
    final parsedTimes = rawTimes.map((e) => e.toString()).toList();

    return Bus(
      id: id ?? map['id']?.toString() ?? '',
      routeNo:
          map[FirestoreConstants.fieldRouteNo]?.toString() ??
          map['routeNo']?.toString() ??
          '',
      busNo:
          map[FirestoreConstants.fieldBusNo]?.toString() ??
          map['busNo']?.toString(),
      routeId: map['routeId']?.toString(),
      scheduledDeparture:
          map[FirestoreConstants.fieldScheduledDeparture]?.toString() ??
          map['scheduledDeparture']?.toString() ??
          (parsedTimes.isNotEmpty ? parsedTimes.first : null),
      stops: parsedStops,
      scheduleTimes: parsedTimes,
      hasRamp: map[FirestoreConstants.fieldHasRamp] as bool? ?? false,
      lowFloor: map[FirestoreConstants.fieldLowFloor] as bool? ?? false,
      rampOk: map[FirestoreConstants.fieldRampOk] is bool
          ? map[FirestoreConstants.fieldRampOk] as bool
          : null,
      rampCheckedAt: _parseCheckTime(map['rampCheckedAt']),
      rampCheckedBy: map['rampCheckedBy'] is String
          ? map['rampCheckedBy'] as String
          : null,
      occupancy: map[FirestoreConstants.fieldOccupancy]?.toString() ?? 'medium',
      driverId:
          map[FirestoreConstants.fieldDriverId]?.toString() ??
          map['driverId']?.toString() ??
          map['assignedOperatorId']?.toString(),
      catalogueRecordType: map['catalogueRecordType']?.toString() ?? 'vehicle',
      sourceUrl: map['sourceUrl']?.toString(),
    );
  }

  /// Factory to instantiate a [Bus] from a Firestore [DocumentSnapshot].
  factory Bus.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return Bus.fromMap(data, id: snapshot.id);
  }

  /// Converts the [Bus] instance into a Firestore map representation.
  Map<String, dynamic> toMap() {
    return {
      FirestoreConstants.fieldRouteNo: routeNo,
      if (busNo != null) FirestoreConstants.fieldBusNo: busNo,
      if (routeId != null) 'routeId': routeId,
      if (scheduledDeparture != null)
        FirestoreConstants.fieldScheduledDeparture: scheduledDeparture,
      FirestoreConstants.fieldStops: stops,
      FirestoreConstants.fieldScheduleTimes: scheduleTimes,
      FirestoreConstants.fieldHasRamp: hasRamp,
      FirestoreConstants.fieldLowFloor: lowFloor,
      FirestoreConstants.fieldRampOk: rampOk,
      if (rampCheckedAt != null)
        'rampCheckedAt': Timestamp.fromDate(rampCheckedAt!),
      if (rampCheckedBy != null) 'rampCheckedBy': rampCheckedBy,
      FirestoreConstants.fieldOccupancy: occupancy,
      if (driverId != null) FirestoreConstants.fieldDriverId: driverId,
      if (isPublishedTimetable) 'catalogueRecordType': catalogueRecordType,
      if (sourceUrl != null) 'sourceUrl': sourceUrl,
    };
  }

  /// Alias for [toMap] to maintain cross-model consistency.
  Map<String, dynamic> toFirestore() => toMap();

  /// Creates a copy of this [Bus] with updated fields.
  Bus copyWith({
    String? id,
    String? routeNo,
    String? busNo,
    String? routeId,
    String? scheduledDeparture,
    List<String>? stops,
    List<String>? scheduleTimes,
    bool? hasRamp,
    bool? lowFloor,
    bool? rampOk,
    DateTime? rampCheckedAt,
    String? rampCheckedBy,
    bool clearRampCheck = false,
    String? occupancy,
    String? driverId,
  }) {
    return Bus(
      id: id ?? this.id,
      routeNo: routeNo ?? this.routeNo,
      busNo: busNo ?? this.busNo,
      routeId: routeId ?? this.routeId,
      scheduledDeparture: scheduledDeparture ?? this.scheduledDeparture,
      stops: stops ?? List.from(this.stops),
      scheduleTimes: scheduleTimes ?? List.from(this.scheduleTimes),
      hasRamp: hasRamp ?? this.hasRamp,
      lowFloor: lowFloor ?? this.lowFloor,
      rampOk: rampOk ?? this.rampOk,
      rampCheckedAt: clearRampCheck || (rampOk != null && rampOk != this.rampOk)
          ? rampCheckedAt
          : rampCheckedAt ?? this.rampCheckedAt,
      rampCheckedBy: clearRampCheck || (rampOk != null && rampOk != this.rampOk)
          ? rampCheckedBy
          : rampCheckedBy ?? this.rampCheckedBy,
      occupancy: occupancy ?? this.occupancy,
      driverId: driverId ?? this.driverId,
      catalogueRecordType: catalogueRecordType,
      sourceUrl: sourceUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bus &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          routeNo == other.routeNo &&
          busNo == other.busNo &&
          routeId == other.routeId &&
          scheduledDeparture == other.scheduledDeparture &&
          hasRamp == other.hasRamp &&
          lowFloor == other.lowFloor &&
          rampOk == other.rampOk &&
          rampCheckedAt == other.rampCheckedAt &&
          rampCheckedBy == other.rampCheckedBy &&
          occupancy == other.occupancy &&
          driverId == other.driverId &&
          catalogueRecordType == other.catalogueRecordType &&
          sourceUrl == other.sourceUrl &&
          _listEquals(stops, other.stops) &&
          _listEquals(scheduleTimes, other.scheduleTimes);

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      routeNo.hashCode ^
      (busNo?.hashCode ?? 0) ^
      (routeId?.hashCode ?? 0) ^
      (scheduledDeparture?.hashCode ?? 0) ^
      hasRamp.hashCode ^
      lowFloor.hashCode ^
      rampOk.hashCode ^
      rampCheckedAt.hashCode ^
      rampCheckedBy.hashCode ^
      occupancy.hashCode ^
      driverId.hashCode ^
      catalogueRecordType.hashCode ^
      sourceUrl.hashCode ^
      Object.hashAll(stops) ^
      Object.hashAll(scheduleTimes);
}
