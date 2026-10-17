import 'package:flutter/foundation.dart';

import '../models/bus_location_model.dart';
import '../models/report.dart';
import '../models/service_run.dart';
import '../models/trip_model.dart';
import '../screens/journey/route_results_screen.dart';
import 'status_logic.dart';

abstract final class BusDetailsState {
  static List<String> segment(RouteResultItem selection) => [
    if (selection.fromStationId != null) selection.fromStationId!,
    ...selection.intermediateStops,
    if (selection.toStationId != null) selection.toStationId!,
  ];

  static List<String> physicalSegment(RouteResultItem selection) =>
      segment(selection)
          .map((s) => selection.rawBus?.stationIdFor(s) ?? s)
          .toSet()
          .toList();

  static bool matchesRun(ServiceRun run, RouteResultItem selection) {
    final stops = run.stopTimes.keys.toList();
    final from = stops.indexOf(selection.fromStationId ?? '');
    final to = stops.indexOf(selection.toStationId ?? '');
    return run.busId == selection.busId &&
        run.routeId == (selection.rawBus?.routeId ?? '') &&
        stops.every(
          (s) =>
              run.stationIdFor(s) == (selection.rawBus?.stationIdFor(s) ?? s),
        ) &&
        (selection.serviceRunId == null || selection.serviceRunId == run.id) &&
        from >= 0 &&
        to > from &&
        listEquals(stops.sublist(from, to + 1), segment(selection)) &&
        run.stopTimes[selection.fromStationId] ==
            selection.nextDepartureDateTime?.toUtc() &&
        run.stopTimes[selection.toStationId] ==
            selection.nextDepartureDateTime
                ?.add(Duration(minutes: selection.durationMinutes))
                .toUtc();
  }

  static BusLocationModel? currentLocation({
    required RouteResultItem selection,
    required ServiceRun? run,
    required TripModel? trip,
    required BusLocationModel? location,
    required DateTime now,
  }) {
    if (run == null ||
        trip == null ||
        location == null ||
        !matchesRun(run, selection) ||
        !const ['boarding', 'in_progress'].contains(run.status) ||
        !trip.isInProgress ||
        trip.tripId != run.id ||
        trip.serviceRunId != run.id ||
        trip.busId != run.busId ||
        trip.scheduledDepartureTime?.toUtc() != run.plannedDepartureAt ||
        !listEquals(trip.stops, run.stopTimes.keys.toList()) ||
        location.busId != run.busId ||
        location.tripId != run.id ||
        location.driverId != trip.driverId ||
        location.isCached ||
        !location.isBroadcasting ||
        !const ['active', 'stopped'].contains(location.status.value) ||
        location.timestamp == null ||
        !location.latitude.isFinite ||
        !location.longitude.isFinite ||
        location.latitude.abs() > 90 ||
        location.longitude.abs() > 180 ||
        (location.latitude == 0 && location.longitude == 0)) {
      return null;
    }
    final age = now.difference(location.timestamp!);
    return age >= Duration.zero && age <= const Duration(seconds: 30)
        ? location
        : null;
  }

  static List<Report> relevantReports(
    List<Report> reports,
    RouteResultItem selection,
    DateTime now,
  ) {
    final stops = physicalSegment(selection).toSet();
    return reports
        .where(
          (r) =>
              StatusLogic.isReportActive(r, currentTime: now) &&
              ((r.targetType == 'bus' && r.targetId == selection.busId) ||
                  (r.targetType == 'station' && stops.contains(r.targetId))),
        )
        .toList()
      ..sort(
        (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
          a.createdAt ?? DateTime(1970),
        ),
      );
  }
}
