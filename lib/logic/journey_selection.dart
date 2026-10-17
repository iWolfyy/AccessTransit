import '../core/utils/time_utils.dart';
import 'transit_time.dart';
import 'tariff_fare.dart';
import '../models/bus.dart';
import '../models/journey_model.dart';
import '../models/station.dart';
import '../screens/journey/route_results_screen.dart';

abstract final class JourneySelection {
  static JourneyModel create(
    RouteResultItem route, {
    required String id,
    required String passengerId,
    String? serviceRunId,
    TariffFareQuote? fareQuote,
    bool overrideFareQuote = false,
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
      serviceRunId: serviceRunId ?? route.serviceRunId,
      origin: route.origin,
      destination: route.destination,
      fromStationId: route.fromStationId,
      toStationId: route.toStationId,
      selectedDate: TransitTime.instant(
        TransitTime.day(
          route.selectedDate ?? TransitTime.civil(route.nextDepartureDateTime!),
        ),
      ),
      selectedTimeMinutes: route.selectedTimeMinutes,
      departureAt: route.nextDepartureDateTime,
      durationMinutes: route.durationMinutes,
      estimatedFareLkr: route.estimatedPriceLkr,
      fareQuote: overrideFareQuote ? fareQuote : route.fareQuote,
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
      serviceRunId: journey.serviceRunId,
      routeNo: journey.routeNumber,
      fromStationId: journey.fromStationId,
      toStationId: journey.toStationId,
      nextDepartureDateTime: journey.departureAt,
      selectedDate: journey.selectedDate == null
          ? null
          : TransitTime.day(TransitTime.civil(journey.selectedDate!)),
      selectedTimeMinutes: journey.selectedTimeMinutes,
      estimatedPriceLkr: journey.estimatedFareLkr!,
      fareQuote: journey.fareQuote,
      departureTimeStr: TimeUtils.formatTimeString(
        TransitTime.civil(journey.departureAt!),
      ),
      arrivalTimeStr: TimeUtils.formatTimeString(
        TransitTime.civil(
          journey.departureAt!.add(Duration(minutes: journey.durationMinutes!)),
        ),
      ),
      wheelchairAccessRequired: journey.wheelchairAccessRequired,
      stepFreeOnly: journey.stepFreeOnly,
      journeyStations: stations,
      intermediateStops: bus.stops.sublist(from + 1, to),
    );
  }
}
