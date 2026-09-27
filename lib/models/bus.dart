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
    required this.hasRamp,
    required this.lowFloor,
    required this.rampOk,
    required this.occupancy,
  });

  final String id;
  final String routeNo;
  final List<String> stops;
  final bool hasRamp;
  final bool lowFloor;
  final bool rampOk;
  final String occupancy; // 'low', 'medium', or 'high'

  /// Factory to instantiate a [Bus] from a Firestore map and optional document [id].
  factory Bus.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawStops = map[FirestoreConstants.fieldStops] as List<dynamic>? ??
        map['stops'] as List<dynamic>? ??
        [];
    final parsedStops = rawStops.map((e) => e.toString()).toList();

    return Bus(
      id: id ?? map['id']?.toString() ?? '',
      routeNo: map[FirestoreConstants.fieldRouteNo]?.toString() ??
          map['routeNo']?.toString() ??
          '',
      stops: parsedStops,
      hasRamp: map[FirestoreConstants.fieldHasRamp] as bool? ?? false,
      lowFloor: map[FirestoreConstants.fieldLowFloor] as bool? ?? false,
      rampOk: map[FirestoreConstants.fieldRampOk] as bool? ?? true,
      occupancy: map[FirestoreConstants.fieldOccupancy]?.toString() ?? 'medium',
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
      FirestoreConstants.fieldHasRamp: hasRamp,
      FirestoreConstants.fieldLowFloor: lowFloor,
      FirestoreConstants.fieldRampOk: rampOk,
      FirestoreConstants.fieldOccupancy: occupancy,
    };
  }

  /// Alias for [toMap] to maintain cross-model consistency.
  Map<String, dynamic> toFirestore() => toMap();

  /// Creates a copy of this [Bus] with updated fields.
  Bus copyWith({
    String? id,
    String? routeNo,
    List<String>? stops,
    bool? hasRamp,
    bool? lowFloor,
    bool? rampOk,
    String? occupancy,
  }) {
    return Bus(
      id: id ?? this.id,
      routeNo: routeNo ?? this.routeNo,
      stops: stops ?? List.from(this.stops),
      hasRamp: hasRamp ?? this.hasRamp,
      lowFloor: lowFloor ?? this.lowFloor,
      rampOk: rampOk ?? this.rampOk,
      occupancy: occupancy ?? this.occupancy,
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
      Object.hashAll(stops);
}
