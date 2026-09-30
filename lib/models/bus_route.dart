import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_constants.dart';

/// Represents a public transit bus route with route number, name, description,
/// and ordered stop identifiers.
///
/// Firestore path: `routes/{id}`
class BusRoute {
  const BusRoute({
    required this.id,
    required this.routeNo,
    required this.routeName,
    this.description = '',
    this.stops = const [],
  });

  /// Unique identifier of the route (e.g. `'route_138'`).
  final String id;

  /// Public route number (e.g. `'138'`, `'100'`).
  final String routeNo;

  /// Display name of the route (e.g. `'Pettah - Kottawa'`).
  final String routeName;

  /// Human-readable corridor description (e.g. `'Via High Level Road, Maradana, Nugegoda'`).
  final String description;

  /// Ordered list of station/stop IDs serving this route.
  final List<String> stops;

  /// Returns true if this route serves the specified [stopId].
  bool containsStop(String stopId) => stops.contains(stopId);

  /// Checks whether [fromStopId] appears strictly before [toStopId] along this route.
  bool isValidDirection(String fromStopId, String toStopId) {
    final fromIdx = stops.indexOf(fromStopId);
    final toIdx = stops.indexOf(toStopId);
    return fromIdx != -1 && toIdx != -1 && fromIdx < toIdx;
  }

  /// Factory to instantiate a [BusRoute] from a map and optional document [id].
  factory BusRoute.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawStops = map[FirestoreConstants.fieldStops] as List<dynamic>? ??
        map['stops'] as List<dynamic>? ??
        [];
    final parsedStops = rawStops.map((e) => e.toString()).toList();

    return BusRoute(
      id: id ?? map['id']?.toString() ?? '',
      routeNo: map[FirestoreConstants.fieldRouteNo]?.toString() ??
          map['routeNumber']?.toString() ??
          map['routeNo']?.toString() ??
          '',
      routeName: map[FirestoreConstants.fieldRouteName]?.toString() ??
          map['routeName']?.toString() ??
          map['name']?.toString() ??
          '',
      description: map[FirestoreConstants.fieldRouteDescription]?.toString() ??
          map['description']?.toString() ??
          '',
      stops: parsedStops,
    );
  }

  /// Factory to instantiate a [BusRoute] from a Firestore [DocumentSnapshot].
  factory BusRoute.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return BusRoute.fromMap(data, id: snapshot.id);
  }

  /// Converts the [BusRoute] into a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      FirestoreConstants.fieldRouteNo: routeNo,
      FirestoreConstants.fieldRouteName: routeName,
      FirestoreConstants.fieldRouteDescription: description,
      FirestoreConstants.fieldStops: stops,
    };
  }

  /// Alias for [toMap] to maintain cross-model consistency.
  Map<String, dynamic> toFirestore() => toMap();

  /// Creates a copy of this [BusRoute] with updated fields.
  BusRoute copyWith({
    String? id,
    String? routeNo,
    String? routeName,
    String? description,
    List<String>? stops,
  }) {
    return BusRoute(
      id: id ?? this.id,
      routeNo: routeNo ?? this.routeNo,
      routeName: routeName ?? this.routeName,
      description: description ?? this.description,
      stops: stops ?? List.from(this.stops),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusRoute &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          routeNo == other.routeNo &&
          routeName == other.routeName &&
          description == other.description &&
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
      routeName.hashCode ^
      description.hashCode ^
      Object.hashAll(stops);
}
