import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/bus.dart';
import '../models/bus_location_model.dart';
import '../models/service_run.dart';
import '../models/station.dart';
import '../models/trip_model.dart';
import 'ordered_schedule.dart';
import 'passenger_journey_plan.dart';
import 'search_session.dart';
import 'transit_time.dart';
import 'route_geometry.dart';

class DatedBoardingOption {
  const DatedBoardingOption({
    required this.plan,
    required this.boardingAt,
    this.runId,
    this.active = false,
    this.source = 'Timetable',
    this.progressEstimate,
  });
  final PassengerJourneyPlan plan;
  final DateTime boardingAt;
  final String? runId;
  final bool active;
  final String source;
  final RouteProgressEstimate? progressEstimate;
}

abstract final class DatedBoardingMatcher {
  static List<DatedBoardingOption> forBus({
    required Bus bus,
    required String from,
    required String to,
    required BoardingSearchWindow window,
    required DateTime notBefore,
    DateTime? selectedDate,
    required List<ServiceRun> runs,
    Map<String, TripModel> trips = const {},
    Map<String, BusLocationModel> locations = const {},
    Map<String, Station> stations = const {},
    ReviewedRouteGeometry? geometry,
  }) {
    final options = <DatedBoardingOption>[];
    bool eligible(DateTime at) =>
        window.contains(at) &&
        !at.isBefore(notBefore) &&
        (selectedDate == null ||
            TransitTime.day(TransitTime.civil(at)) ==
                TransitTime.day(selectedDate));
    if (bus.isPublishedTimetable) {
      // A published timetable is a catalogue service, never an operating vehicle.
      for (final date in [
        TransitTime.day(TransitTime.civil(window.now)),
        TransitTime.day(TransitTime.civil(window.end)),
      ]) {
        final plan = publishedPlan(bus, from, to, date);
        if (plan != null &&
            eligible(plan.departure) &&
            !options.any((o) => o.plan.departure == plan.departure)) {
          options.add(
            DatedBoardingOption(plan: plan, boardingAt: plan.departure),
          );
        }
      }
      return options;
    }
    for (final run in runs) {
      if (run.busId != bus.id ||
          run.routeId != (bus.routeId ?? '') ||
          run.serviceDate != TransitTime.serviceDate(run.plannedDepartureAt) ||
          !listEquals(run.stopTimes.keys.toList(), bus.stops) ||
          !const [
            'scheduled',
            'boarding',
            'in_progress',
          ].contains(run.status)) {
        continue;
      }
      final stops = run.stopTimes.keys.toList();
      final board = stops.indexOf(from), alight = stops.indexOf(to);
      if (board < 0 || alight <= board) continue;
      final departure = run.stopTimes[from]!, arrival = run.stopTimes[to]!;
      if (!arrival.isAfter(departure)) continue;
      var boarding = departure;
      final active = run.status != 'scheduled';
      if (!active && window.now.isAfter(run.latestStartAt)) continue;
      var source = 'Dated timetable';
      RouteProgressEstimate? progressEstimate;
      if (active) {
        final trip = trips[run.id], gps = locations[bus.id];
        if (trip == null ||
            gps == null ||
            !trip.isInProgress ||
            trip.tripId != run.id ||
            trip.serviceRunId != run.id ||
            trip.busId != bus.id ||
            bus.driverId != trip.driverId ||
            trip.scheduledDepartureTime?.toUtc() != run.plannedDepartureAt ||
            !listEquals(trip.stops, stops) ||
            trip.currentStopIndex < 0 ||
            trip.currentStopIndex > board ||
            trip.stopTimes.entries.any(
              (e) =>
                  stops.indexOf(e.key) > board && e.value.actualArrival != null,
            ) ||
            gps.tripId != run.id ||
            gps.busId != bus.id ||
            gps.driverId != trip.driverId ||
            gps.isCached ||
            !gps.isBroadcasting ||
            gps.timestamp == null ||
            !const ['active', 'stopped'].contains(gps.status.value) ||
            window.now.difference(gps.timestamp!) < Duration.zero ||
            window.now.difference(gps.timestamp!) >
                const Duration(seconds: 30) ||
            !gps.latitude.isFinite ||
            !gps.longitude.isFinite ||
            gps.latitude.abs() > 90 ||
            gps.longitude.abs() > 180 ||
            (gps.latitude == 0 && gps.longitude == 0) ||
            !gps.speed.isFinite ||
            gps.speed < 0 ||
            gps.speed > 130) {
          continue;
        }
        if (gps.speed >= 3) {
          if (geometry == null) continue;
          progressEstimate = RouteProgressEta.estimate(
            geometry: geometry,
            run: run,
            trip: trip,
            gps: gps,
            target: from,
            now: window.now,
          );
          if (progressEstimate == null) continue;
          boarding = progressEstimate.arrival;
          source = 'Road progress + timetable (low confidence)';
        } else {
          // Without reviewed road geometry, only a stationary GPS fix at the
          // recorded stop supports a timetable-interval boarding estimate.
          final anchorId = stops[trip.currentStopIndex];
          final anchor = stations[anchorId];
          if (anchor == null ||
              !anchor.lat.isFinite ||
              !anchor.lng.isFinite ||
              anchor.lat.abs() > 90 ||
              anchor.lng.abs() > 180 ||
              (anchor.lat == 0 && anchor.lng == 0) ||
              const Distance().as(
                    LengthUnit.Meter,
                    LatLng(gps.latitude, gps.longitude),
                    LatLng(anchor.lat, anchor.lng),
                  ) >
                  100) {
            continue;
          }
          final anchorTime =
              run.status == 'boarding' &&
                  trip.currentStopIndex == 0 &&
                  window.now.isBefore(run.plannedDepartureAt)
              ? run.plannedDepartureAt
              : window.now;
          boarding = anchorTime.add(
            departure.difference(run.stopTimes[anchorId]!),
          );
          source = board == trip.currentStopIndex
              ? 'GPS at boarding stop'
              : 'Timetable interval from GPS-observed stop';
        }
      }
      if (eligible(boarding)) {
        options.add(
          DatedBoardingOption(
            plan: PassengerJourneyPlan(
              stops: stops.sublist(board, alight + 1),
              departure: departure,
              arrival: arrival,
            ),
            boardingAt: boarding,
            runId: run.id,
            active: active,
            source: source,
            progressEstimate: progressEstimate,
          ),
        );
      }
    }
    return options;
  }

  static PassengerJourneyPlan? publishedPlan(
    Bus bus,
    String from,
    String to,
    DateTime boardingDay,
  ) {
    final board = bus.stops.indexOf(from), alight = bus.stops.indexOf(to);
    if (board < 0 || alight <= board) return null;
    final first = OrderedSchedule.minutesOfDay(bus.effectiveDepartureTime);
    if (first == null || bus.scheduleTimes.length > bus.stops.length) {
      return null;
    }
    final times = <DateTime>[];
    var estimated = false;
    for (var i = 0; i < bus.stops.length; i++) {
      final raw = i < bus.scheduleTimes.length
          ? bus.scheduleTimes[i].trim()
          : '';
      final minute = raw.isEmpty ? null : OrderedSchedule.minutesOfDay(raw);
      if (minute == null && raw.isNotEmpty) return null;
      if (minute == null) {
        if (bus.scheduleTimes.skip(i + 1).any((s) => s.trim().isNotEmpty)) {
          return null;
        }
        estimated = true;
        times.add(
          times.isEmpty
              ? TransitTime.day(boardingDay).add(Duration(minutes: first))
              : times.last.add(OrderedSchedule.estimatedLeg),
        );
      } else {
        final day = times.isEmpty
            ? TransitTime.day(boardingDay)
            : TransitTime.day(times.last);
        var next = day.add(Duration(minutes: minute));
        if (times.isNotEmpty && next.isBefore(times.last)) {
          next = next.add(const Duration(days: 1));
        }
        times.add(next);
      }
    }
    final shift = TransitTime.day(boardingDay)
        .difference(TransitTime.day(times[board]));
    return PassengerJourneyPlan(
      stops: bus.stops.sublist(board, alight + 1),
      departure: TransitTime.instant(times[board].add(shift)),
      arrival: TransitTime.instant(times[alight].add(shift)),
      usesEstimatedTimes: estimated,
    );
  }
}
