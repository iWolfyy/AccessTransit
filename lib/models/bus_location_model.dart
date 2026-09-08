import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_constants.dart';

/// Telemetry model representing a real-time active bus in Firestore.
class BusLocationModel {
  const BusLocationModel({
    required this.busId,
    required this.routeNumber,
    required this.routeName,
    required this.operatorId,
    this.operatorName = 'Transit Operator',
    required this.latitude,
    required this.longitude,
    this.heading = 0.0,
    this.speed = 0.0,
    this.nextStop = 'Central Station',
    this.etaMinutes = 2,
    this.rampOperational = true,
    this.elevatorWorking = true,
    this.occupancyLevel = 'Moderate',
    this.isBroadcasting = true,
    this.lastUpdated,
  });

  final String busId;
  final String routeNumber;
  final String routeName;
  final String operatorId;
  final String operatorName;
  final double latitude;
  final double longitude;
  final double heading;
  final double speed;
  final String nextStop;
  final int etaMinutes;
  final bool rampOperational;
  final bool elevatorWorking;
  final String occupancyLevel;
  final bool isBroadcasting;
  final DateTime? lastUpdated;

  factory BusLocationModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return BusLocationModel(
      busId:
          map[FirestoreConstants.fieldBusId]?.toString() ??
          documentId ??
          'bus_42',
      routeNumber: map[FirestoreConstants.fieldRouteNumber]?.toString() ?? '42',
      routeName:
          map[FirestoreConstants.fieldRouteName]?.toString() ??
          'Express Downtown',
      operatorId: map[FirestoreConstants.fieldOperatorId]?.toString() ?? '',
      operatorName:
          map[FirestoreConstants.fieldOperatorName]?.toString() ??
          'Transit Operator',
      latitude:
          (map[FirestoreConstants.fieldLatitude] as num?)?.toDouble() ?? 6.9271,
      longitude:
          (map[FirestoreConstants.fieldLongitude] as num?)?.toDouble() ??
          79.8612,
      heading:
          (map[FirestoreConstants.fieldHeading] as num?)?.toDouble() ?? 0.0,
      speed: (map[FirestoreConstants.fieldSpeed] as num?)?.toDouble() ?? 0.0,
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
      isBroadcasting:
          map[FirestoreConstants.fieldIsBroadcasting] as bool? ?? true,
      lastUpdated: _parseTimestamp(map[FirestoreConstants.fieldLastUpdated]),
    );
  }

  Map<String, dynamic> toMap({bool isServerTimestamp = true}) {
    return {
      FirestoreConstants.fieldBusId: busId,
      FirestoreConstants.fieldRouteNumber: routeNumber,
      FirestoreConstants.fieldRouteName: routeName,
      FirestoreConstants.fieldOperatorId: operatorId,
      FirestoreConstants.fieldOperatorName: operatorName,
      FirestoreConstants.fieldLatitude: latitude,
      FirestoreConstants.fieldLongitude: longitude,
      FirestoreConstants.fieldHeading: heading,
      FirestoreConstants.fieldSpeed: speed,
      FirestoreConstants.fieldNextStop: nextStop,
      FirestoreConstants.fieldEtaMinutes: etaMinutes,
      FirestoreConstants.fieldRampOperational: rampOperational,
      FirestoreConstants.fieldElevatorWorking: elevatorWorking,
      FirestoreConstants.fieldOccupancyLevel: occupancyLevel,
      FirestoreConstants.fieldIsBroadcasting: isBroadcasting,
      FirestoreConstants.fieldLastUpdated: isServerTimestamp
          ? FieldValue.serverTimestamp()
          : lastUpdated != null
          ? Timestamp.fromDate(lastUpdated!)
          : null,
    };
  }

  BusLocationModel copyWith({
    String? busId,
    String? routeNumber,
    String? routeName,
    String? operatorId,
    String? operatorName,
    double? latitude,
    double? longitude,
    double? heading,
    double? speed,
    String? nextStop,
    int? etaMinutes,
    bool? rampOperational,
    bool? elevatorWorking,
    String? occupancyLevel,
    bool? isBroadcasting,
    DateTime? lastUpdated,
  }) {
    return BusLocationModel(
      busId: busId ?? this.busId,
      routeNumber: routeNumber ?? this.routeNumber,
      routeName: routeName ?? this.routeName,
      operatorId: operatorId ?? this.operatorId,
      operatorName: operatorName ?? this.operatorName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      nextStop: nextStop ?? this.nextStop,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      rampOperational: rampOperational ?? this.rampOperational,
      elevatorWorking: elevatorWorking ?? this.elevatorWorking,
      occupancyLevel: occupancyLevel ?? this.occupancyLevel,
      isBroadcasting: isBroadcasting ?? this.isBroadcasting,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
