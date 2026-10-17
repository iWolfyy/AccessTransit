import 'package:access_transit/logic/ordered_schedule.dart';
import 'package:access_transit/logic/passenger_journey_plan.dart';
import 'package:access_transit/logic/delay_eta_logic.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/trip_model.dart';
import 'package:access_transit/services/trip_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin civil-clock mode retains nominal clocks without host DST normalization', () {
    final ordered = OrderedSchedule.build(
      stopCount: 3,
      scheduleTimes: ['01:50', '02:10', '00:10'],
      serviceDate: DateTime.utc(2026, 3, 29),
      fallbackDeparture: DateTime.utc(2026, 3, 29),
      utcCivil: true,
    )!;
    expect(ordered.times.every((time) => time.isUtc), isTrue);
    expect(ordered.times[1], DateTime.utc(2026, 3, 29, 2, 10));
    expect(
      ordered.times[1].difference(ordered.times[0]),
      const Duration(minutes: 20),
    );
    expect(ordered.times[2], DateTime.utc(2026, 3, 30, 0, 10));
  });

  final day = DateTime(2026, 12, 31);
  const clocks = ['23:50', '00:10', '00:25'];
  const bus = Bus(
    id: 'night',
    routeNo: '1',
    stops: ['a', 'b', 'c'],
    scheduleTimes: clocks,
    hasRamp: true,
    lowFloor: true,
    occupancy: 'low',
  );
  final service = TripService(tripWriter: (_, _) async {});
  Future<TripModel> start(
    String id,
    DateTime actual, {
    DateTime? date,
    List<String> times = clocks,
  }) => service.startTrip(
    busId: id,
    routeNo: '1',
    stops: bus.stops,
    scheduleTimes: times,
    driverId: 'operator',
    departureTime: actual,
    serviceDate: date,
  );

  test('strict 12/24-hour parser handles noon and midnight without normalizing bad clocks', () {
    expect(OrderedSchedule.minutesOfDay('12:00 AM'), 0);
    expect(OrderedSchedule.minutesOfDay('12:00 PM'), 720);
    expect(OrderedSchedule.minutesOfDay(' 11:50 pm '), 1430);
    expect(OrderedSchedule.minutesOfDay('00:10'), 10);
    for (final text in [
      '24:00',
      '08:60',
      '13:20 PM',
      '00:10 AM',
      'no time',
      '8:30junk',
    ]) {
      expect(OrderedSchedule.minutesOfDay(text), isNull, reason: text);
    }
  });

  test('ordered rollover preserves year boundaries, multiple midnights and equal clocks', () {
    final schedule = OrderedSchedule.build(
      stopCount: 5,
      scheduleTimes: ['23:50', '00:10', '00:10', '23:55', '00:05'],
      serviceDate: day,
      fallbackDeparture: day,
    )!;
    expect(schedule.times, [
      DateTime(2026, 12, 31, 23, 50),
      DateTime(2027, 1, 1, 0, 10),
      DateTime(2027, 1, 1, 0, 10),
      DateTime(2027, 1, 1, 23, 55),
      DateTime(2027, 1, 2, 0, 5),
    ]);
  });

  test(
    'downstream passenger boards on the selected calendar date after midnight',
    () {
      final plan = PassengerJourneyPlan.forBus(
        bus: bus,
        fromId: 'b',
        toId: 'c',
        travelDate: day,
        notBefore: day,
      )!;
      expect(plan.departure, DateTime(2026, 12, 31, 0, 10));
      expect(plan.arrival, DateTime(2026, 12, 31, 0, 25));
      expect(plan.durationMinutes, 15);
    },
  );

  test('late midnight start retains previous service day and shifts all estimates equally', () async {
    final actual = DateTime(2027, 1, 1, 0, 5);
    final trip = await start('late-night', actual);
    expect(trip.scheduledDepartureTime, DateTime(2026, 12, 31, 23, 50));
    expect(trip.actualDepartureTime, actual);
    expect(trip.stopTimes['a']!.actualArrival, actual);
    expect(trip.stopTimes['a']!.estimatedArrival, actual);
    expect(trip.stopTimes['b']!.estimatedArrival, DateTime(2027, 1, 1, 0, 25));
    expect(trip.stopTimes['c']!.estimatedArrival, DateTime(2027, 1, 1, 0, 40));
    final restored = TripModel.fromMap(trip.toMap());
    expect(restored.scheduledDepartureTime, trip.scheduledDepartureTime);
    expect(restored.actualDepartureTime, actual);
  });

  test(
    'early start before midnight infers the next daily planned departure',
    () async {
      final actual = DateTime(2026, 12, 31, 23, 55);
      final trip = await start(
        'early-night',
        actual,
        times: ['00:10', '00:30', '00:45'],
      );
      expect(trip.scheduledDepartureTime, DateTime(2027, 1, 1, 0, 10));
      expect(
        trip.stopTimes['b']!.estimatedArrival,
        DateTime(2027, 1, 1, 0, 15),
      );
      expect(
        trip.stopTimes['c']!.estimatedArrival,
        DateTime(2027, 1, 1, 0, 30),
      );
    },
  );

  test('explicit service day overrides nearest-daily inference for an unusually late run', () async {
    final trip = await start(
      'explicit-night',
      DateTime(2027, 1, 2, 0, 5),
      date: day,
    );
    expect(trip.scheduledDepartureTime, DateTime(2026, 12, 31, 23, 50));
    expect(trip.stopTimes['b']!.estimatedArrival, DateTime(2027, 1, 2, 0, 25));
  });

  test('missing timetable uses the same six-minute intervals and does not invent planned departure', () async {
    final actual = DateTime(2026, 12, 31, 23, 58);
    final trip = await start('missing-night', actual, times: []);
    expect(trip.scheduledDepartureTime, isNull);
    expect(trip.stopTimes['b']!.estimatedArrival, DateTime(2027, 1, 1, 0, 4));
    expect(trip.stopTimes['c']!.estimatedArrival, DateTime(2027, 1, 1, 0, 10));
    final plan = PassengerJourneyPlan.forBus(
      bus: bus.copyWith(scheduleTimes: [], scheduledDeparture: '23:58'),
      fromId: 'a',
      toId: 'c',
      travelDate: day,
      notBefore: day,
    )!;
    expect(plan.arrival, trip.stopTimes['c']!.estimatedArrival);
    expect(plan.durationMinutes, 12);
    expect(plan.usesEstimatedTimes, isTrue);
    final eta = DelayEtaCalculator.calculateArrivalEta(
      bus: bus.copyWith(scheduleTimes: ['23:58']),
      targetStopIdOrName: 'b',
      currentTime: actual,
    );
    expect(eta.scheduledArrivalStr, 'Unknown');
    expect(eta.countdownText, 'ETA unavailable');
    expect(eta.stopsTimeline.first.scheduledTimeStr, isNot('Unknown'));
    expect(eta.stopsTimeline[1].scheduledTimeStr, 'Unknown');
  });

  test('invalid schedules and interior gaps reject without publishing a trip or passenger option', () async {
    var writes = 0;
    final writer = TripService(
      tripWriter: (_, _) async {
        writes++;
      },
    );
    for (final times in [
      ['23:50', '25:10'],
      ['23:50', '', '00:00'],
    ]) {
      await expectLater(
        writer.startTrip(
          busId: 'invalid-clock',
          routeNo: '1',
          stops: bus.stops,
          driverId: 'operator',
          departureTime: day,
          scheduleTimes: times,
        ),
        throwsStateError,
      );
      expect(
        PassengerJourneyPlan.forBus(
          bus: bus.copyWith(scheduleTimes: times),
          fromId: 'a',
          toId: 'c',
          travelDate: day,
          notBefore: day,
        ),
        isNull,
      );
    }
    expect(writes, 0);
    expect(await TripService().getActiveTrip('invalid-clock'), isNull);
  });

  test('live ETA uses the same overnight baseline and reports real departure offset', () async {
    final trip = await start('eta-night', DateTime(2027, 1, 1, 0, 5));
    final result = DelayEtaCalculator.calculateArrivalEta(
      bus: bus,
      targetStopIdOrName: 'b',
      activeTrip: trip,
      currentTime: DateTime(2027, 1, 1, 0, 6),
    );
    expect(result.scheduledArrival, DateTime(2027, 1, 1, 0, 10));
    expect(result.estimatedArrival, DateTime(2027, 1, 1, 0, 25));
    expect(result.delayMinutes, 15);
    expect(result.delayType, DelayType.delayed);
    expect(result.stopsTimeline.map((s) => s.scheduledTime), [
      DateTime(2026, 12, 31, 23, 50),
      DateTime(2027, 1, 1, 0, 10),
      DateTime(2027, 1, 1, 0, 25),
    ]);
  });

  test('offline overnight ETA shows tomorrow only for the stops actually crossing midnight', () {
    final before = DelayEtaCalculator.calculateArrivalEta(
      bus: bus,
      targetStopIdOrName: 'b',
      currentTime: DateTime(2026, 12, 31, 23, 55),
    );
    expect(before.scheduledArrival, DateTime(2027, 1, 1, 0, 10));
    expect(before.scheduledArrivalStr, 'Tomorrow, 12:10 AM');
    expect(
      before.stopsTimeline.first.scheduledTime,
      DateTime(2026, 12, 31, 23, 50),
    );
    expect(before.stopsTimeline[1].scheduledTimeStr, 'Tomorrow, 12:10 AM');
    final after = DelayEtaCalculator.calculateArrivalEta(
      bus: bus,
      targetStopIdOrName: 'b',
      currentTime: DateTime(2027, 1, 1, 0, 5),
    );
    expect(after.scheduledArrival, DateTime(2027, 1, 1, 0, 10));
    expect(after.scheduledArrivalStr, '12:10 AM');
    expect(
      after.stopsTimeline.first.scheduledTime,
      DateTime(2026, 12, 31, 23, 50),
    );
  });
}
