import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_constants.dart';

/// Represents a bus route with ordered stops and physical accessibility attributes.
///
/// Firestore path: `buses/{id}`
class Bus {
  const Bus({
    required this.id,
    required this.routeNo,
    required this.stops,
    this.scheduleTimes = const [],
    required this.hasRamp,
    required this.lowFloor,
    required this.rampOk,
    required this.occupancy,
    this.driverId,
  });

  final String id;
  final String routeNo;
  final List<String> stops;
  final List<String> scheduleTimes; // Ordered scheduled time strings aligned with stops (e.g. ["08:00 AM", "08:12 AM"])
  final bool hasRamp;
  final bool lowFloor;
  final bool rampOk;
  final String occupancy; // 'low', 'medium', or 'high'
  final String? driverId;

  /// Helper to get or generate fallback schedule time for a stop index if missing
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
    final rawStops = map[FirestoreConstants.fieldStops] as List<dynamic>? ??
        map['stops'] as List<dynamic>? ??
        [];
    final parsedStops = rawStops.map((e) => e.toString()).toList();

    final rawTimes = map['scheduleTimes'] as List<dynamic>? ?? [];
    final parsedTimes = rawTimes.map((e) => e.toString()).toList();

    return Bus(
      id: id ?? map['id']?.toString() ?? '',
      routeNo: map[FirestoreConstants.fieldRouteNo]?.toString() ??
          map['routeNo']?.toString() ??
          '',
      stops: parsedStops,
      scheduleTimes: parsedTimes,
      hasRamp: map[FirestoreConstants.fieldHasRamp] as bool? ?? false,
      lowFloor: map[FirestoreConstants.fieldLowFloor] as bool? ?? false,
      rampOk: map[FirestoreConstants.fieldRampOk] as bool? ?? true,
      occupancy: map[FirestoreConstants.fieldOccupancy]?.toString() ?? 'medium',
      driverId: map[FirestoreConstants.fieldDriverId]?.toString() ??
          map['driverId']?.toString() ??
          map['assignedOperatorId']?.toString(),
    );
  }

  /// Factory to instantiate a [Bus] from a Firestore [DocumentSnapshot].
  factory Bus.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return Bus.fromMap(data, id: snapshot.id);
  }

  /// Converts the [Bus] instance into a Firestore map representation.
  Map<String, dynamic> toMap() {
    return {
      FirestoreConstants.fieldRouteNo: routeNo,
      FirestoreConstants.fieldStops: stops,
      'scheduleTimes': scheduleTimes,
      FirestoreConstants.fieldHasRamp: hasRamp,
      FirestoreConstants.fieldLowFloor: lowFloor,
      FirestoreConstants.fieldRampOk: rampOk,
      FirestoreConstants.fieldOccupancy: occupancy,
      if (driverId != null) FirestoreConstants.fieldDriverId: driverId,
    };
  }

  /// Alias for [toMap] to maintain cross-model consistency.
  Map<String, dynamic> toFirestore() => toMap();

  /// Creates a copy of this [Bus] with updated fields.
  Bus copyWith({
    String? id,
    String? routeNo,
    List<String>? stops,
    List<String>? scheduleTimes,
    bool? hasRamp,
    bool? lowFloor,
    bool? rampOk,
    String? occupancy,
    String? driverId,
  }) {
    return Bus(
      id: id ?? this.id,
      routeNo: routeNo ?? this.routeNo,
      stops: stops ?? List.from(this.stops),
      scheduleTimes: scheduleTimes ?? List.from(this.scheduleTimes),
      hasRamp: hasRamp ?? this.hasRamp,
      lowFloor: lowFloor ?? this.lowFloor,
      rampOk: rampOk ?? this.rampOk,
      occupancy: occupancy ?? this.occupancy,
      driverId: driverId ?? this.driverId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bus &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          routeNo == other.routeNo &&
          hasRamp == other.hasRamp &&
          lowFloor == other.lowFloor &&
          rampOk == other.rampOk &&
          occupancy == other.occupancy &&
          driverId == other.driverId &&
          _listEquals(stops, other.stops);

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
      hasRamp.hashCode ^
      lowFloor.hashCode ^
      rampOk.hashCode ^
      occupancy.hashCode ^
      driverId.hashCode ^
      Object.hashAll(stops);
}
