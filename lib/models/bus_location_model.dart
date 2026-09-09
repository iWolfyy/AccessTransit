import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_constants.dart';
import 'enums/bus_status.dart';

/// Telemetry model representing a real-time bus location in Firestore.
class BusLocationModel {
  BusLocationModel({
    required this.busId,
    String? routeId,
    String? routeNumber,
    this.routeName = '',
    String? driverId,
    String? operatorId,
    this.operatorName = 'Transit Operator',
    required this.latitude,
    required this.longitude,
    this.speed = 0.0,
    this.heading = 0.0,
    DateTime? timestamp,
    DateTime? lastUpdated,
    BusStatus? status,
    this.nextStop = 'Central Station',
    this.etaMinutes = 2,
    this.rampOperational = true,
    this.elevatorWorking = true,
    this.occupancyLevel = 'Moderate',
    bool? isBroadcasting,
  })  : routeId = routeId ?? routeNumber ?? '',
        routeNumber = routeNumber ?? routeId ?? '',
        driverId = (driverId != null && driverId.isNotEmpty)
            ? driverId
            : (operatorId ?? ''),
        timestamp = timestamp ?? lastUpdated,
        status = status ??
            ((isBroadcasting ?? true) ? BusStatus.active : BusStatus.offline),
        isBroadcasting = isBroadcasting ??
            (status == null || status != BusStatus.offline);

  final String busId;
  final String routeId;
  final String routeNumber;
  final String routeName;
  final String driverId;
  final String operatorName;
  final double latitude;
  final double longitude;
  final double speed;
  final double heading;
  final DateTime? timestamp;
  final BusStatus status;

  final String nextStop;
  final int etaMinutes;
  final bool rampOperational;
  final bool elevatorWorking;
  final String occupancyLevel;
  final bool isBroadcasting;

  /// Alias for [driverId] to maintain operator terminology compatibility.
  String get operatorId => driverId;

  /// Alias for [timestamp] to maintain compatibility with legacy telemetry.
  DateTime? get lastUpdated => timestamp;

  /// Factory constructor to deserialize Firestore map data.
  factory BusLocationModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    final parsedBusId =
        map[FirestoreConstants.fieldBusId]?.toString() ?? documentId ?? '';
    final parsedRouteId = map[FirestoreConstants.fieldRouteId]?.toString() ??
        map[FirestoreConstants.fieldRouteNumber]?.toString() ??
        '';
    final parsedRouteNumber =
        map[FirestoreConstants.fieldRouteNumber]?.toString() ?? parsedRouteId;
    final parsedDriverId = map[FirestoreConstants.fieldDriverId]?.toString() ??
        map[FirestoreConstants.fieldOperatorId]?.toString() ??
        '';

    final parsedTimestamp =
        _parseTimestamp(map[FirestoreConstants.fieldTimestamp]) ??
            _parseTimestamp(map[FirestoreConstants.fieldLastUpdated]);

    final rawStatus = map[FirestoreConstants.fieldStatus]?.toString();
    final bool? rawBroadcasting =
        map[FirestoreConstants.fieldIsBroadcasting] as bool?;

    BusStatus parsedStatus;
    if (rawStatus != null && rawStatus.isNotEmpty) {
      parsedStatus = BusStatus.fromString(rawStatus);
    } else if (rawBroadcasting != null) {
      parsedStatus =
          rawBroadcasting ? BusStatus.active : BusStatus.offline;
    } else {
      parsedStatus = BusStatus.active;
    }

    return BusLocationModel(
      busId: parsedBusId,
      routeId: parsedRouteId,
      routeNumber: parsedRouteNumber,
      routeName:
          map[FirestoreConstants.fieldRouteName]?.toString() ?? '',
      driverId: parsedDriverId,
      operatorName:
          map[FirestoreConstants.fieldOperatorName]?.toString() ??
          'Transit Operator',
      latitude:
          (map[FirestoreConstants.fieldLatitude] as num?)?.toDouble() ?? 0.0,
      longitude:
          (map[FirestoreConstants.fieldLongitude] as num?)?.toDouble() ?? 0.0,
      heading:
          (map[FirestoreConstants.fieldHeading] as num?)?.toDouble() ?? 0.0,
      speed: (map[FirestoreConstants.fieldSpeed] as num?)?.toDouble() ?? 0.0,
      timestamp: parsedTimestamp,
      status: parsedStatus,
      nextStop:
          map[FirestoreConstants.fieldNextStop]?.toString() ??
          'Central Station',
      etaMinutes:
          (map[FirestoreConstants.fieldEtaMinutes] as num?)?.toInt() ?? 2,
      rampOperational:
          map[FirestoreConstants.fieldRampOperational] as bool? ?? true,
      elevatorWorking:
          map[FirestoreConstants.fieldElevatorWorking] as bool? ?? true,
      occupancyLevel:
          map[FirestoreConstants.fieldOccupancyLevel]?.toString() ?? 'Moderate',
      isBroadcasting: rawBroadcasting ?? (parsedStatus != BusStatus.offline),
    );
  }

  /// Factory constructor to deserialize from a Firestore document snapshot.
  factory BusLocationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return BusLocationModel.fromMap(data, documentId: snapshot.id);
  }

  /// Converts the model instance into a Firestore document map.
  Map<String, dynamic> toMap({bool isServerTimestamp = true}) {
    final tsValue = isServerTimestamp
        ? FieldValue.serverTimestamp()
        : timestamp != null
            ? Timestamp.fromDate(timestamp!)
            : null;

    return {
      FirestoreConstants.fieldBusId: busId,
      FirestoreConstants.fieldRouteId: routeId,
      FirestoreConstants.fieldRouteNumber: routeNumber,
      FirestoreConstants.fieldRouteName: routeName,
      FirestoreConstants.fieldDriverId: driverId,
      FirestoreConstants.fieldOperatorId: driverId,
      FirestoreConstants.fieldOperatorName: operatorName,
      FirestoreConstants.fieldLatitude: latitude,
      FirestoreConstants.fieldLongitude: longitude,
      FirestoreConstants.fieldHeading: heading,
      FirestoreConstants.fieldSpeed: speed,
      FirestoreConstants.fieldStatus: status.value,
      FirestoreConstants.fieldTimestamp: tsValue,
      FirestoreConstants.fieldNextStop: nextStop,
      FirestoreConstants.fieldEtaMinutes: etaMinutes,
      FirestoreConstants.fieldRampOperational: rampOperational,
      FirestoreConstants.fieldElevatorWorking: elevatorWorking,
      FirestoreConstants.fieldOccupancyLevel: occupancyLevel,
      FirestoreConstants.fieldIsBroadcasting: isBroadcasting,
      FirestoreConstants.fieldLastUpdated: tsValue,
    };
  }

  /// Alias method for [toMap] to maintain naming consistency across Firestore models.
  Map<String, dynamic> toFirestore({bool isServerTimestamp = true}) {
    return toMap(isServerTimestamp: isServerTimestamp);
  }

  BusLocationModel copyWith({
    String? busId,
    String? routeId,
    String? routeNumber,
    String? routeName,
    String? driverId,
    String? operatorId,
    String? operatorName,
    double? latitude,
    double? longitude,
    double? heading,
    double? speed,
    DateTime? timestamp,
    DateTime? lastUpdated,
    BusStatus? status,
    String? nextStop,
    int? etaMinutes,
    bool? rampOperational,
    bool? elevatorWorking,
    String? occupancyLevel,
    bool? isBroadcasting,
  }) {
    return BusLocationModel(
      busId: busId ?? this.busId,
      routeId: routeId ?? this.routeId,
      routeNumber: routeNumber ?? this.routeNumber,
      routeName: routeName ?? this.routeName,
      driverId: driverId ?? operatorId ?? this.driverId,
      operatorName: operatorName ?? this.operatorName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? lastUpdated ?? this.timestamp,
      status: status ?? this.status,
      nextStop: nextStop ?? this.nextStop,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      rampOperational: rampOperational ?? this.rampOperational,
      elevatorWorking: elevatorWorking ?? this.elevatorWorking,
      occupancyLevel: occupancyLevel ?? this.occupancyLevel,
      isBroadcasting: isBroadcasting ?? this.isBroadcasting,
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
