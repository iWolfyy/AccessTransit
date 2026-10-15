/// Ordered local timetable, with calendar rollover whenever the clock decreases.
/// Missing trailing entries use an explicit six-minute model interval; invalid entries
/// reject the timetable rather than silently becoming midnight/current time.
class OrderedSchedule {
  const OrderedSchedule(this.times, this.usesEstimates);
  final List<DateTime> times;
  final bool usesEstimates;
  static const estimatedLeg = Duration(minutes: 6);

  static int? minutesOfDay(String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return null;
    var hour = int.parse(match[1]!);
    final minute = int.parse(match[2]!);
    final period = match[3]?.toUpperCase();
    if (minute > 59 || (period == null ? hour > 23 : hour < 1 || hour > 12)) {
      return null;
    }
    if (period != null) hour = hour % 12 + (period == 'PM' ? 12 : 0);
    return hour * 60 + minute;
  }

  static OrderedSchedule? build({
    required int stopCount,
    required List<String> scheduleTimes,
    required DateTime serviceDate,
    required DateTime fallbackDeparture,
  }) {
    if (stopCount <= 0 || scheduleTimes.length > stopCount) return null;
    final times = <DateTime>[];
    var estimated = false;
    for (var i = 0; i < stopCount; i++) {
      final raw = i < scheduleTimes.length ? scheduleTimes[i].trim() : '';
      DateTime next;
      if (raw.isEmpty) {
        // Do not let an invented intermediate duration push a later supplied
        // time into another day. Such a gap needs a reviewed timetable.
        if (scheduleTimes.skip(i + 1).any((s) => s.trim().isNotEmpty)) {
          return null;
        }
        estimated = true;
        next = times.isEmpty ? fallbackDeparture : times.last.add(estimatedLeg);
      } else {
        final minutes = minutesOfDay(raw);
        if (minutes == null) return null;
        final base = times.isEmpty ? serviceDate : times.last;
        next = DateTime(
          base.year,
          base.month,
          base.day,
          minutes ~/ 60,
          minutes % 60,
        );
        if (times.isNotEmpty && next.isBefore(times.last)) {
          next = DateTime(
            base.year,
            base.month,
            base.day + 1,
            minutes ~/ 60,
            minutes % 60,
          );
        }
      }
      times.add(next);
    }
    return OrderedSchedule(List.unmodifiable(times), estimated);
  }

  /// Move a complete itinerary by calendar days, retaining every midnight crossing.
  OrderedSchedule onDateAt(int index, DateTime date) {
    final anchor = times[index];
    final days = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime.utc(anchor.year, anchor.month, anchor.day)).inDays;
    return OrderedSchedule([
      for (final time in times)
        DateTime(
          time.year,
          time.month,
          time.day + days,
          time.hour,
          time.minute,
          time.second,
          time.millisecond,
          time.microsecond,
        ),
    ], usesEstimates);
  }

  /// Default run inference chooses the daily departure nearest the actual start.
  /// A caller with an explicit service date should use that date instead.
  OrderedSchedule nearestDepartureTo(DateTime actual) {
    final difference = times.first.difference(actual);
    final shift = difference > const Duration(hours: 12)
        ? -1
        : difference < const Duration(hours: -12)
        ? 1
        : 0;
    return onDateAt(
      0,
      DateTime(times.first.year, times.first.month, times.first.day + shift),
    );
  }
}
