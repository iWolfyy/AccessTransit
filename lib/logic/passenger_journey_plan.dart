import '../core/utils/time_utils.dart';
import '../models/bus.dart';

/// A scheduled journey covering only the passenger's selected route segment.
class PassengerJourneyPlan {
  const PassengerJourneyPlan({
    required this.stops,
    required this.departure,
    required this.arrival,
  });

  final List<String> stops;
  final DateTime departure;
  final DateTime arrival;

  int get durationMinutes => arrival.difference(departure).inMinutes;

  /// Estimate only; uses travel time and stops inside the passenger's segment.
  int get estimatedPriceLkr {
    final intermediateCount = (stops.length - 2).clamp(0, stops.length);
    final price = 35 + durationMinutes * 2.2 + intermediateCount * 4;
    return ((price / 5).round() * 5).clamp(40, 450);
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
    final firstTime = TimeUtils.parseTimeStringToDateTime(
      bus.effectiveDepartureTime,
      base,
    );
    var departure = fromIndex < bus.scheduleTimes.length
        ? TimeUtils.parseTimeStringToDateTime(
            bus.scheduleTimes[fromIndex],
            base,
          )
        : firstTime.add(Duration(minutes: fromIndex * 6));
    // The requested date refers to boarding, including overnight routes.
    departure = DateTime(
      base.year,
      base.month,
      base.day,
      departure.hour,
      departure.minute,
    );
    if (departure.isBefore(notBefore)) {
      if (!rollToNextDay) return null;
      departure = DateTime(
        departure.year,
        departure.month,
        departure.day + 1,
        departure.hour,
        departure.minute,
      );
    }

    var arrival = departure;
    for (var index = fromIndex + 1; index <= toIndex; index++) {
      if (index < bus.scheduleTimes.length) {
        var next = TimeUtils.parseTimeStringToDateTime(
          bus.scheduleTimes[index],
          arrival,
        );
        if (next.isBefore(arrival)) {
          next = DateTime(
            next.year,
            next.month,
            next.day + 1,
            next.hour,
            next.minute,
          );
        }
        arrival = next.isAfter(arrival)
            ? next
            : arrival.add(const Duration(minutes: 6));
      } else {
        arrival = arrival.add(const Duration(minutes: 6));
      }
    }

    return PassengerJourneyPlan(
      stops: bus.stops.sublist(fromIndex, toIndex + 1),
      departure: departure,
      arrival: arrival,
    );
  }
}
