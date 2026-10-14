import '../core/utils/time_utils.dart';
import '../models/bus.dart';
import '../models/journey_model.dart';
import '../models/station.dart';
import '../screens/journey/route_results_screen.dart';

abstract final class JourneySelection {
  static JourneyModel create(
    RouteResultItem route, {
    required String id,
    required String passengerId,
  }) {
    final bus = route.rawBus;
    final from = bus?.stops.indexOf(route.fromStationId ?? '') ?? -1;
    final to = bus?.stops.indexOf(route.toStationId ?? '') ?? -1;
    if (passengerId.isEmpty ||
        bus == null ||
        bus.id != route.busId ||
        from < 0 ||
        to <= from ||
        route.nextDepartureDateTime == null) {
      throw StateError(
        'The selected vehicle, stops or departure are missing. Choose a route again.',
      );
    }
    return JourneyModel(
      journeyId: id,
      passengerId: passengerId,
      routeId: bus.routeId ?? '',
      routeNumber: bus.routeNo,
      routeTitle: route.title,
      busId: bus.id,
      busNo: bus.displayBusNo,
      origin: route.origin,
      destination: route.destination,
      fromStationId: route.fromStationId,
      toStationId: route.toStationId,
      selectedDate:
          route.selectedDate ??
          DateTime(
            route.nextDepartureDateTime!.year,
            route.nextDepartureDateTime!.month,
            route.nextDepartureDateTime!.day,
          ),
      selectedTimeMinutes: route.selectedTimeMinutes,
      departureAt: route.nextDepartureDateTime,
      durationMinutes: route.durationMinutes,
      estimatedFareLkr: route.estimatedPriceLkr,
      wheelchairAccessRequired: route.wheelchairAccessRequired,
      stepFreeOnly: route.stepFreeOnly,
    );
  }

  static RouteResultItem restore(
    JourneyModel journey,
    Bus bus,
    Map<String, Station> stations,
  ) {
    final from = bus.stops.indexOf(journey.fromStationId ?? '');
    final to = bus.stops.indexOf(journey.toStationId ?? '');
    if (bus.id != journey.busId ||
        bus.routeNo != journey.routeNumber ||
        from < 0 ||
        to <= from ||
        journey.departureAt == null ||
        journey.durationMinutes == null ||
        journey.estimatedFareLkr == null) {
      throw StateError(
        'Saved journey details are incomplete or the bus no longer serves these stops. Replan your journey.',
      );
    }
    return RouteResultItem(
      id: journey.busId,
      busId: journey.busId,
      title: journey.routeTitle,
      durationMinutes: journey.durationMinutes!,
      etaLabel: 'Saved timetable estimate',
      transfers: 0,
      crowdLevel: 'Unknown',
      accessibilityStatus: AccessibilityStatus.unknown,
      accessibilityLabel: 'Unknown',
      safetyLabel: 'Check current evidence',
      summary: 'Saved journey',
      origin: journey.origin,
      destination: journey.destination,
      rawBus: bus,
      busNo: journey.busNo,
      routeNo: journey.routeNumber,
      fromStationId: journey.fromStationId,
      toStationId: journey.toStationId,
      nextDepartureDateTime: journey.departureAt,
      selectedDate: journey.selectedDate,
      selectedTimeMinutes: journey.selectedTimeMinutes,
      estimatedPriceLkr: journey.estimatedFareLkr!,
      departureTimeStr: TimeUtils.formatTimeString(journey.departureAt!),
      arrivalTimeStr: TimeUtils.formatTimeString(
        journey.departureAt!.add(Duration(minutes: journey.durationMinutes!)),
      ),
      wheelchairAccessRequired: journey.wheelchairAccessRequired,
      stepFreeOnly: journey.stepFreeOnly,
      journeyStations: stations,
      intermediateStops: bus.stops.sublist(from + 1, to),
    );
  }
}
