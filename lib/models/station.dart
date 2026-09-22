import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_constants.dart';

/// Represents a transit station with accessibility facilities and geographic location.
///
/// Firestore path: `stations/{id}`
class Station {
  const Station({
    required this.id,
    required this.name,
    required this.hasElevator,
    required this.hasRamp,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String name;
  final bool hasElevator;
  final bool hasRamp;
  final double lat;
  final double lng;

  /// Factory to instantiate a [Station] from a Firestore map and optional document [id].
  factory Station.fromMap(Map<String, dynamic> map, {String? id}) {
    return Station(
      id: id ?? map['id']?.toString() ?? '',
      name: map[FirestoreConstants.fieldName]?.toString() ??
          map['name']?.toString() ??
          '',
      hasElevator: map[FirestoreConstants.fieldHasElevator] as bool? ?? false,
      hasRamp: map[FirestoreConstants.fieldHasRamp] as bool? ?? false,
      lat: (map[FirestoreConstants.fieldLat] as num?)?.toDouble() ??
          (map['latitude'] as num?)?.toDouble() ??
          0.0,
      lng: (map[FirestoreConstants.fieldLng] as num?)?.toDouble() ??
          (map['longitude'] as num?)?.toDouble() ??
          0.0,
    );
  }

  /// Factory to instantiate a [Station] from a Firestore [DocumentSnapshot].
  factory Station.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return Station.fromMap(data, id: snapshot.id);
  }

  /// Converts the [Station] instance into a Firestore map representation.
  Map<String, dynamic> toMap() {
    return {
      FirestoreConstants.fieldName: name,
      FirestoreConstants.fieldHasElevator: hasElevator,
      FirestoreConstants.fieldHasRamp: hasRamp,
      FirestoreConstants.fieldLat: lat,
      FirestoreConstants.fieldLng: lng,
    };
  }

  /// Alias for [toMap] to maintain cross-model consistency.
  Map<String, dynamic> toFirestore() => toMap();

  /// Creates a copy of this [Station] with updated fields.
  Station copyWith({
    String? id,
    String? name,
    bool? hasElevator,
    bool? hasRamp,
    double? lat,
    double? lng,
  }) {
    return Station(
      id: id ?? this.id,
      name: name ?? this.name,
      hasElevator: hasElevator ?? this.hasElevator,
      hasRamp: hasRamp ?? this.hasRamp,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Station &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          hasElevator == other.hasElevator &&
          hasRamp == other.hasRamp &&
          lat == other.lat &&
          lng == other.lng;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      hasElevator.hashCode ^
      hasRamp.hashCode ^
      lat.hashCode ^
      lng.hashCode;
}
