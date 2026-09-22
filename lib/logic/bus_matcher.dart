import '../models/bus.dart';

/// Pure logic utility for finding direct bus routes between origin and destination stations.
class BusMatcher {
  const BusMatcher._();

  /// Finds all direct buses serving [fromId] to [toId] in correct directional order.
  ///
  /// Criteria (AC-72):
  /// 1. Both [fromId] and [toId] must exist in the bus's ordered [Bus.stops] list.
  /// 2. The index of [fromId] must be strictly smaller than the index of [toId] ([fromIndex] < [toIndex]).
  /// 3. Returns an empty list if [fromId] == [toId] or if either station ID is empty.
  static List<Bus> findDirectBuses(
    List<Bus> buses,
    String fromId,
    String toId,
  ) {
    if (fromId.trim().isEmpty ||
        toId.trim().isEmpty ||
        fromId.trim() == toId.trim()) {
      return const [];
    }

    final cleanFromId = fromId.trim();
    final cleanToId = toId.trim();

    return buses.where((bus) {
      final fromIndex = bus.stops.indexOf(cleanFromId);
      final toIndex = bus.stops.indexOf(cleanToId);

      // Both stations must exist in the route's stops list
      if (fromIndex == -1 || toIndex == -1) {
        return false;
      }

      // Direction check: from station must come BEFORE to station
      return fromIndex < toIndex;
    }).toList();
  }
}
