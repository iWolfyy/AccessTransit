import 'package:access_transit/logic/passenger_journey_plan.dart';
import 'package:access_transit/models/bus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bus = Bus(
    id: 'long-route',
    routeNo: '138',
    hasRamp: true,
    lowFloor: true,
    rampOk: true,
    occupancy: 'low',
    stops: ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
    scheduleTimes: [
      '08:00',
      '08:12',
      '08:24',
      '08:36',
      '08:48',
      '09:00',
      '09:12',
      '09:24',
    ],
  );
  final day = DateTime(2026, 12, 15);

  PassengerJourneyPlan? plan({
    Bus vehicle = bus,
    String from = 'f',
    String to = 'g',
    DateTime? notBefore,
    bool roll = false,
  }) => PassengerJourneyPlan.forBus(
    bus: vehicle,
    fromId: from,
    toId: to,
    travelDate: day,
    notBefore: notBefore ?? day,
    rollToNextDay: roll,
  );

  test('future journeys use the requested boarding date', () {
    final result = plan()!;
    expect(result.departure, DateTime(2026, 12, 15, 9));
    expect(result.arrival, DateTime(2026, 12, 15, 9, 12));
  });

  test(
    'explicit time filters earlier departures without rolling to tomorrow',
    () {
      expect(plan(notBefore: DateTime(2026, 12, 15, 9, 1)), isNull);
      expect(plan(notBefore: DateTime(2026, 12, 15, 9)), isNotNull);
    },
  );

  test('depart-now may return the next daily service', () {
    final result = plan(notBefore: DateTime(2026, 12, 15, 10), roll: true)!;
    expect(result.departure, DateTime(2026, 12, 16, 9));
    expect(result.arrival, DateTime(2026, 12, 16, 9, 12));
  });

  test('nearby stops use their actual scheduled interval and segment fare', () {
    final short = plan()!;
    final full = plan(from: 'a', to: 'h')!;
    expect(short.stops, ['f', 'g']);
    expect(short.durationMinutes, 12);
    expect(short.estimatedPriceLkr, 60);
    expect(full.durationMinutes, 84);
    expect(short.estimatedPriceLkr, lessThan(full.estimatedPriceLkr));
  });

  test('missing schedules estimate only the travelled legs', () {
    final result = plan(
      vehicle: bus.copyWith(scheduleTimes: [], scheduledDeparture: '10:00 AM'),
    )!;
    expect(result.departure, DateTime(2026, 12, 15, 10, 30));
    expect(result.durationMinutes, 6);
  });

  test('arrival rolls over midnight without changing the boarding date', () {
    final result = plan(
      vehicle: bus.copyWith(
        scheduleTimes: [
          '22:00',
          '22:30',
          '23:00',
          '23:10',
          '23:20',
          '23:50',
          '00:10',
          '00:30',
        ],
      ),
    )!;
    expect(result.departure, DateTime(2026, 12, 15, 23, 50));
    expect(result.arrival, DateTime(2026, 12, 16, 0, 10));
    expect(result.durationMinutes, 20);
  });

  test('invalid or reversed stop selections are rejected', () {
    expect(plan(from: 'g', to: 'f'), isNull);
    expect(plan(from: 'missing'), isNull);
    expect(plan(from: 'g', to: 'g'), isNull);
  });
}
