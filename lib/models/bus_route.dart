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
    this.stopStationIds = const {},
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

  /// Unique visit IDs in `stops`; this map resolves each visit to its physical stop.
  /// Legacy catalogues use the station ID itself as their single visit ID.
  final Map<String, String> stopStationIds;
  String stationIdFor(String occurrence) =>
      stopStationIds[occurrence] ?? occurrence;
  List<String> occurrencesAt(String stationId) =>
      stops.where((s) => stationIdFor(s) == stationId).toList();

  /// Returns true if this route serves the specified [stopId].
  bool containsStop(String stopId) => occurrencesAt(stopId).isNotEmpty;

  /// Checks whether [fromStopId] appears strictly before [toStopId] along this route.
  bool isValidDirection(String fromStopId, String toStopId) {
    return occurrencesAt(fromStopId).any(
      (a) =>
          occurrencesAt(toStopId)
              .any((b) => stops.indexOf(a) < stops.indexOf(b)),
    );
  }

  /// Factory to instantiate a [BusRoute] from a map and optional document [id].
  factory BusRoute.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawStops =
        map[FirestoreConstants.fieldStops] as List<dynamic>? ??
        map['stops'] as List<dynamic>? ??
        [];
    final parsedStops = rawStops.map((e) => e.toString()).toList();

    return BusRoute(
      id: id ?? map['id']?.toString() ?? '',
      routeNo:
          map[FirestoreConstants.fieldRouteNo]?.toString() ??
          map['routeNumber']?.toString() ??
          map['routeNo']?.toString() ??
          '',
      routeName:
          map[FirestoreConstants.fieldRouteName]?.toString() ??
          map['routeName']?.toString() ??
          map['name']?.toString() ??
          '',
      description:
          map[FirestoreConstants.fieldRouteDescription]?.toString() ??
          map['description']?.toString() ??
          '',
      stops: parsedStops,
      stopStationIds: Map<String, String>.from(
        map['stopStationIds'] as Map? ?? {},
      ),
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
      if (stopStationIds.isNotEmpty) 'stopStationIds': stopStationIds,
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
    Map<String, String>? stopStationIds,
  }) {
    return BusRoute(
      id: id ?? this.id,
      routeNo: routeNo ?? this.routeNo,
      routeName: routeName ?? this.routeName,
      description: description ?? this.description,
      stops: stops ?? List.from(this.stops),
      stopStationIds: stopStationIds ?? Map.of(this.stopStationIds),
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
          _listEquals(stops, other.stops) &&
          stopStationIds.length == other.stopStationIds.length &&
          stopStationIds.entries.every(
            (e) => other.stopStationIds[e.key] == e.value,
          );

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
      Object.hashAllUnordered(
        stopStationIds.entries.map((e) => Object.hash(e.key, e.value)),
      ) ^
      Object.hashAll(stops);
}
