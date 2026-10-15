import 'ordered_schedule.dart';
import 'journey_fare.dart';
import '../models/bus.dart';

/// A scheduled journey covering only the passenger's selected route segment.
class PassengerJourneyPlan {
  const PassengerJourneyPlan({
    required this.stops,
    required this.departure,
    required this.arrival,
    this.usesEstimatedTimes = false,
  });

  final List<String> stops;
  final DateTime departure;
  final DateTime arrival;
  final bool usesEstimatedTimes;

  int get durationMinutes => arrival.difference(departure).inMinutes;

  /// Estimate only; uses travel time and stops inside the passenger's segment.
  int get estimatedPriceLkr {
    final intermediateCount = (stops.length - 2).clamp(0, stops.length);
    return JourneyFare.estimate(
      durationMinutes: durationMinutes,
      intermediateStops: intermediateCount,
    );
  }

  static PassengerJourneyPlan? forBus({
    required Bus bus,
    required String fromId,
    required String toId,
    required DateTime travelDate,
    required DateTime notBefore,
    bool rollToNextDay = false,
  }) {
    final fromIndex = bus.stops.indexOf(fromId.trim());
    final toIndex = bus.stops.indexOf(toId.trim());
    if (fromIndex < 0 || toIndex <= fromIndex) return null;

    final base = DateTime(travelDate.year, travelDate.month, travelDate.day);
    final firstMinutes = OrderedSchedule.minutesOfDay(
      bus.effectiveDepartureTime,
    );
    if (firstMinutes == null) return null;
    var schedule = OrderedSchedule.build(
      stopCount: bus.stops.length,
      scheduleTimes: bus.scheduleTimes,
      serviceDate: base,
      fallbackDeparture: DateTime(
        base.year,
        base.month,
        base.day,
        firstMinutes ~/ 60,
        firstMinutes % 60,
      ),
    );
    if (schedule == null) return null;
    // The selected date refers to boarding, even when the run starts yesterday.
    schedule = schedule.onDateAt(fromIndex, base);
    if (schedule.times[fromIndex].isBefore(notBefore)) {
      if (!rollToNextDay) return null;
      schedule = schedule.onDateAt(
        fromIndex,
        DateTime(base.year, base.month, base.day + 1),
      );
      if (schedule.times[fromIndex].isBefore(notBefore)) return null;
    }
    final departure = schedule.times[fromIndex];
    final arrival = schedule.times[toIndex];

    return PassengerJourneyPlan(
      stops: bus.stops.sublist(fromIndex, toIndex + 1),
      departure: departure,
      arrival: arrival,
      usesEstimatedTimes: schedule.usesEstimates,
    );
  }
}
