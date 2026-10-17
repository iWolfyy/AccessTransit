import 'package:access_transit/logic/search_session.dart';
import 'package:access_transit/logic/passenger_journey_plan.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('24 hour boarding bounds are inclusive and do not limit arrival', () {
    final now = DateTime(2026, 10, 16, 14);
    final window = BoardingSearchWindow(now);
    expect(window.contains(now), isTrue);
    expect(
      window.contains(now.subtract(const Duration(microseconds: 1))),
      isFalse,
    );
    expect(window.contains(DateTime(2026, 10, 17, 14)), isTrue);
    expect(window.contains(DateTime(2026, 10, 17, 14, 0, 1)), isFalse);
    const bus = Bus(
      id: 'b',
      routeNo: '1',
      stops: ['a', 'b', 'c'],
      scheduleTimes: ['13:00', '14:00', '16:00'],
      hasRamp: false,
      lowFloor: false,
      occupancy: 'unknown',
    );
    final plan = PassengerJourneyPlan.forBus(
      bus: bus,
      fromId: 'b',
      toId: 'c',
      travelDate: DateTime(2026, 10, 17),
      notBefore: now,
    )!;
    expect(window.contains(plan.departure), isTrue);
    expect(plan.arrival.isAfter(window.end), isTrue);
  });

  test('date or time cannot shift horizon; midnight and expired searches', () {
    final window = BoardingSearchWindow(DateTime(2026, 10, 16, 23, 30));
    expect(
      window.lowerBound(date: DateTime(2026, 10, 17), minutes: 1410),
      window.end,
    );
    expect(
      window.lowerBound(date: DateTime(2026, 10, 17), minutes: 1411),
      isNull,
    );
    expect(window.lowerBound(date: DateTime(2026, 10, 23)), isNull);
    expect(window.lowerBound(date: DateTime(2026, 10, 15)), isNull);
    expect(
      window.lowerBound(date: DateTime(2026, 10, 16), minutes: 1409),
      isNull,
    );
    expect(window.lowerBound(date: DateTime(2026, 10, 16)), window.now);
    expect(window.lowerBound(minutes: -1), isNull);
    expect(window.lowerBound(minutes: 1440), isNull);
  });

  late AccessibilityPreferencesService preferences;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = AccessibilityPreferencesService();
    await preferences.init(userId: 'a');
  });
  tearDown(() => preferences.dispose());

  test(
    'defaults refresh unedited fields and preserve explicit search overrides',
    () async {
      final draft = SearchNeedsDraft(preferences);
      expect(draft.wheelchair, isTrue);
      expect(draft.stepFree, isFalse);
      // Even an override equal to today's default remains explicit.
      draft.setWheelchair(true);
      await preferences.savePreferences(
        isWheelchairOnly: false,
        isStepFree: true,
      );
      expect(draft.wheelchair, isTrue);
      expect(draft.stepFree, isTrue);
      draft.reset();
      expect(draft.hasOverrides, isFalse);
      expect(draft.wheelchair, isFalse);
      draft.dispose();
    },
  );

  test(
    'draft never writes settings; a new search starts from saved defaults',
    () async {
      final before = (await SharedPreferences.getInstance()).getKeys();
      final draft = SearchNeedsDraft(preferences)
        ..setWheelchair(false)
        ..setStepFree(true);
      expect(preferences.isWheelchairOnly, isTrue);
      expect(preferences.isStepFree, isFalse);
      expect((await SharedPreferences.getInstance()).getKeys(), before);
      final next = SearchNeedsDraft(preferences);
      expect(next.wheelchair, isTrue);
      expect(next.stepFree, isFalse);
      draft.dispose();
      next.dispose();
    },
  );

  test(
    'account switch clears overrides, including when switching back',
    () async {
      final draft = SearchNeedsDraft(preferences)..setStepFree(true);
      await preferences.activateAccount('b');
      expect(draft.accountRevision, 1);
      expect(draft.hasOverrides, isFalse);
      expect(draft.stepFree, isFalse);
      await preferences.activateAccount('a');
      expect(draft.accountRevision, 2);
      expect(draft.stepFree, isFalse);
      draft.dispose();
    },
  );
}
