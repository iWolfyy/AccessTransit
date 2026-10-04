import 'package:cloud_firestore/cloud_firestore.dart';

/// Information regarding estimated and actual arrival times for a specific stop in a trip.
class StopTimingInfo {
  const StopTimingInfo({
    required this.estimatedArrival,
    this.actualArrival,
  });

  final DateTime estimatedArrival;
  final DateTime? actualArrival;

  Map<String, dynamic> toMap() {
    return {
      'estimatedArrival': Timestamp.fromDate(estimatedArrival),
      'actualArrival': actualArrival != null ? Timestamp.fromDate(actualArrival!) : null,
    };
  }

  factory StopTimingInfo.fromMap(Map<String, dynamic> map) {
    DateTime parseTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    final est = parseTime(map['estimatedArrival']);
    final actRaw = map['actualArrival'];
    final act = actRaw != null ? parseTime(actRaw) : null;

    return StopTimingInfo(
      estimatedArrival: est,
      actualArrival: act,
    );
  }

  StopTimingInfo copyWith({
    DateTime? estimatedArrival,
    DateTime? actualArrival,
  }) {
    return StopTimingInfo(
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      actualArrival: actualArrival ?? this.actualArrival,
    );
  }
}

/// Represents an active or completed bus trip execution along a route.
///
/// Firestore path: `trips/{tripId}`
class TripModel {
  const TripModel({
    required this.tripId,
    required this.busId,
    required this.routeNo,
    required this.stops,
    required this.status, // 'not_started', 'in_progress', 'completed'
    this.scheduledDepartureTime,
    this.actualDepartureTime,
    required this.stopTimes, // Map of stationId -> StopTimingInfo
    this.currentStopIndex = 0,
    required this.driverId,
    required this.createdAt,
  });

  final String tripId;
  final String busId;
  final String routeNo;
  final List<String> stops;
  final String status;
  final DateTime? scheduledDepartureTime;
  final DateTime? actualDepartureTime;
  final Map<String, StopTimingInfo> stopTimes;
  final int currentStopIndex;
  final String driverId;
  final DateTime createdAt;

  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isNotStarted => status == 'not_started';

  factory TripModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime? parseNullableTime(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    final rawStops = map['stops'] as List<dynamic>? ?? [];
    final parsedStops = rawStops.map((e) => e.toString()).toList();

    final rawStopTimes = map['stopTimes'] as Map<String, dynamic>? ?? {};
    final parsedStopTimes = <String, StopTimingInfo>{};

    rawStopTimes.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        parsedStopTimes[key] = StopTimingInfo.fromMap(value);
      }
    });

    return TripModel(
      tripId: documentId ?? map['tripId']?.toString() ?? '',
      busId: map['busId']?.toString() ?? '',
      routeNo: map['routeNo']?.toString() ?? '',
      stops: parsedStops,
      status: map['status']?.toString() ?? 'not_started',
      scheduledDepartureTime: parseNullableTime(map['scheduledDepartureTime']),
      actualDepartureTime: parseNullableTime(map['actualDepartureTime']),
      stopTimes: parsedStopTimes,
      currentStopIndex: (map['currentStopIndex'] as num?)?.toInt() ?? 0,
      driverId: map['driverId']?.toString() ?? '',
      createdAt: parseNullableTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  factory TripModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return TripModel.fromMap(data, documentId: snapshot.id);
  }

  Map<String, dynamic> toMap({bool isServerTimestamp = false}) {
    final Map<String, dynamic> convertedStopTimes = {};
    stopTimes.forEach((key, value) {
      convertedStopTimes[key] = value.toMap();
    });

    return {
      'tripId': tripId,
      'busId': busId,
      'routeNo': routeNo,
      'stops': stops,
      'status': status,
      'scheduledDepartureTime': scheduledDepartureTime != null
          ? Timestamp.fromDate(scheduledDepartureTime!)
          : null,
      'actualDepartureTime': actualDepartureTime != null
          ? Timestamp.fromDate(actualDepartureTime!)
          : null,
      'stopTimes': convertedStopTimes,
      'currentStopIndex': currentStopIndex,
      'driverId': driverId,
      'createdAt': isServerTimestamp ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
    };
  }

  TripModel copyWith({
    String? tripId,
    String? busId,
    String? routeNo,
    List<String>? stops,
    String? status,
    DateTime? scheduledDepartureTime,
    DateTime? actualDepartureTime,
    Map<String, StopTimingInfo>? stopTimes,
    int? currentStopIndex,
    String? driverId,
    DateTime? createdAt,
  }) {
    return TripModel(
      tripId: tripId ?? this.tripId,
      busId: busId ?? this.busId,
      routeNo: routeNo ?? this.routeNo,
      stops: stops ?? List.from(this.stops),
      status: status ?? this.status,
      scheduledDepartureTime: scheduledDepartureTime ?? this.scheduledDepartureTime,
      actualDepartureTime: actualDepartureTime ?? this.actualDepartureTime,
      stopTimes: stopTimes ?? Map.from(this.stopTimes),
      currentStopIndex: currentStopIndex ?? this.currentStopIndex,
      driverId: driverId ?? this.driverId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
