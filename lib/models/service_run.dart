import 'package:cloud_firestore/cloud_firestore.dart';

/// A reviewed, dated departure. Times are UTC; service date is Colombo civil time.
class ServiceRun {
  const ServiceRun({
    required this.id,
    required this.busId,
    required this.routeId,
    required this.routeNo,
    required this.serviceDate,
    required this.plannedDepartureAt,
    required this.latestStartAt,
    required this.stopTimes,
    this.status = 'scheduled',
    this.handoverPending = false,
  });
  final String id, busId, routeId, routeNo, serviceDate, status;
  final DateTime plannedDepartureAt, latestStartAt;
  final Map<String, DateTime> stopTimes;
  final bool handoverPending;
  static const maximumLateStart = Duration(minutes: 30);
  DateTime get earliestStartAt =>
      plannedDepartureAt.subtract(const Duration(minutes: 5));
  bool canStartAt(DateTime now) =>
      status == 'scheduled' &&
      !now.isBefore(earliestStartAt) &&
      !now.isAfter(latestStartAt);

  factory ServiceRun.fromMap(String id, Map<String, dynamic> d) {
    DateTime time(dynamic v) {
      if (v is! Timestamp) {
        throw const FormatException('Invalid dated run time');
      }
      return v.toDate().toUtc();
    }

    final stops = List<String>.from(d['stops'] as List? ?? []);
    final initial = Map<String, dynamic>.from(
      d['initialStopTimes'] as Map? ?? {},
    );
    if (stops.length < 2 ||
        stops.toSet().length != stops.length ||
        stops.any((s) => initial[s] is! Map)) {
      throw const FormatException('Invalid dated run itinerary');
    }
    final times = <String, DateTime>{
      for (final stop in stops) stop: time(initial[stop]['estimatedArrival']),
    };
    final planned = time(d['plannedDepartureAt']);
    final latest = time(d['latestStartAt']);
    final ordered = times.values.toList();
    if (ordered.first != planned ||
        latest != planned.add(maximumLateStart) ||
        List.generate(
          ordered.length - 1,
          (i) => ordered[i + 1].isBefore(ordered[i]),
        ).any((v) => v)) {
      throw const FormatException('Invalid ordered run schedule');
    }
    return ServiceRun(
      id: id,
      busId: d['busId'] as String,
      routeId: d['routeId'] as String,
      routeNo: d['routeNo'] as String,
      serviceDate: d['serviceDate'] as String,
      status: d['status'] as String,
      handoverPending: d['handoverPending'] == true,
      plannedDepartureAt: planned,
      latestStartAt: latest,
      stopTimes: Map.unmodifiable(times),
    );
  }

  static const colomboOffset = Duration(hours: 5, minutes: 30);
  static DateTime colomboCivilToUtc(DateTime civil) => DateTime.utc(
    civil.year,
    civil.month,
    civil.day,
    civil.hour,
    civil.minute,
    civil.second,
  ).subtract(colomboOffset);
  static DateTime colomboClock(DateTime instant) =>
      instant.toUtc().add(colomboOffset);
}
