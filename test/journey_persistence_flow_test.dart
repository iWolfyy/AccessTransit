import 'support/fixture_search_backend.dart';

import 'package:access_transit/services/transit_catalogue.dart';
import 'package:access_transit/widgets/live_accessibility_panel.dart';

import 'ramp_test_observations.dart';

import 'dart:async';

import 'package:access_transit/logic/journey_selection.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/journey_model.dart';
import 'package:access_transit/models/station.dart';
import 'package:access_transit/screens/journey/journey_confirmation_screen.dart';
import 'package:access_transit/screens/journey/journey_resume_screen.dart';
import 'package:access_transit/screens/journey/live_journey_screen.dart';
import 'package:access_transit/screens/journey/bus_details_screen.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:access_transit/services/journey_service.dart';
import 'package:access_transit/widgets/saved_journey_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const vehicle = Bus(
  id: 'bus_177',
  routeNo: '177',
  routeId: 'route_177',
  busNo: 'WP TEST-177',
  stops: ['a', 'b', 'c'],
  hasRamp: true,
  lowFloor: true,
  rampOk: true,
  occupancy: 'low',
);
const stops = [
  Station(
    id: 'b',
    name: 'Boarding',
    hasElevator: false,
    hasRamp: true,
    lat: 6.9,
    lng: 79.8,
  ),
  Station(
    id: 'c',
    name: 'Destination',
    hasElevator: false,
    hasRamp: true,
    lat: 6.91,
    lng: 79.81,
  ),
];
RouteResultItem selection({String from = 'b', String to = 'c'}) =>
    RouteResultItem(
      id: vehicle.id,
      title: 'Route 177',
      durationMinutes: 12,
      etaLabel: 'Timetable',
      transfers: 0,
      crowdLevel: 'Unknown',
      accessibilityStatus: AccessibilityStatus.unknown,
      accessibilityLabel: 'Unknown',
      safetyLabel: 'Check evidence',
      summary: 'Summary',
      busId: vehicle.id,
      rawBus: vehicle,
      busNo: vehicle.busNo,
      routeNo: vehicle.routeNo,
      origin: 'Boarding',
      destination: 'Destination',
      fromStationId: from,
      toStationId: to,
      nextDepartureDateTime: DateTime(2026, 10, 21, 9, 15),
      selectedDate: DateTime(2026, 10, 21),
      selectedTimeMinutes: 540,
      estimatedPriceLkr: 70,
      wheelchairAccessRequired: true,
      stepFreeOnly: true,
      journeyStations: {for (final s in stops) s.id: s},
    );
JourneyModel saved() =>
    JourneySelection.create(selection(), id: 'saved_id', passengerId: 'rider');

class ResumeCatalog extends FirestoreService {
  @override
  Future<Bus?> getBusById(String id) async => id == vehicle.id ? vehicle : null;
  @override
  Future<List<Station>> getStations() async => stops;
}

void main() {
  test('pending local writes cannot publish new journeys or prematurely hide acknowledged plans', () {
    final history = AcknowledgedJourneyHistory('rider');
    expect(history.accept([(saved(), true)], authoritative: false), isNull);
    expect(
      history.accept([(saved(), false)], authoritative: true)!.journeyId,
      'saved_id',
    );
    expect(
      history.accept([
        (saved().copyWith(status: JourneyStatus.cancelled), true),
      ], authoritative: false)!.status,
      JourneyStatus.confirmed,
    );
    expect(
      history.accept([
        (saved().copyWith(status: JourneyStatus.cancelled), false),
      ], authoritative: true),
      isNull,
    );
    expect(
      history.accept([
        (saved().copyWith(passengerId: 'other'), false),
      ], authoritative: true),
      isNull,
    );
    history.accept([(saved(), false)], authoritative: true);
    expect(history.accept([], authoritative: true), isNull);
  });
  setUp(() async {
    await recordWorkingRamps();
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init();
  });
  test('saved model round trip and reconstruction preserve exact selection after restart', () {
    final journey = saved();
    final restored = JourneyModel.fromMap(
      journey.toMap(),
      documentId: journey.journeyId,
    );
    final route = JourneySelection.restore(restored, vehicle, {
      for (final s in stops) s.id: s,
    });
    expect(restored.routeId, 'route_177');
    expect(route.busId, vehicle.id);
    expect(route.fromStationId, 'b');
    expect(route.toStationId, 'c');
    expect(route.selectedDate, DateTime.utc(2026, 10, 21));
    expect(route.selectedTimeMinutes, 540);
    expect(route.nextDepartureDateTime, DateTime(2026, 10, 21, 9, 15));
    expect(route.durationMinutes, 12);
    expect(route.estimatedPriceLkr, 70);
    expect(route.wheelchairAccessRequired, isTrue);
    expect(route.stepFreeOnly, isTrue);
    expect(route.timetableStatusLabel, 'Scheduled');
    expect(route.accessibilityStatus, AccessibilityStatus.unknown);
  });
  test(
    'invalid target ordering, missing owner and changed bus cannot fall back',
    () {
      expect(
        () => JourneySelection.create(
          selection(from: 'c', to: 'b'),
          id: 'id',
          passengerId: 'rider',
        ),
        throwsStateError,
      );
      expect(
        () => JourneySelection.create(
          selection(from: 'absent'),
          id: 'id',
          passengerId: 'rider',
        ),
        throwsStateError,
      );
      expect(
        () => JourneySelection.create(selection(), id: 'id', passengerId: ''),
        throwsStateError,
      );
      expect(
        () => JourneySelection.restore(
          saved().copyWith(busId: 'other'),
          vehicle,
          {},
        ),
        throwsStateError,
      );
    },
  );
  test(
    'legacy journey is readable but cannot invent missing selection on resume',
    () {
      final legacy = JourneyModel.fromMap({
        'journeyId': 'old',
        'passengerId': 'rider',
        'busId': vehicle.id,
        'origin': 'Boarding',
        'destination': 'Destination',
        'status': 'confirmed',
      });
      expect(legacy.fromStationId, isNull);
      expect(legacy.departureAt, isNull);
      expect(
        () => JourneySelection.restore(legacy, vehicle, {}),
        throwsStateError,
      );
    },
  );
  test('ownership and mismatched acknowledged selection are rejected by the save service', () async {
    var calls = 0;
    final service = JourneyService(
      currentPassengerId: () => 'other',
      writer: (j) async {
        calls++;
        return j;
      },
    );
    await expectLater(service.createJourney(saved()), throwsStateError);
    expect(calls, 0);
    final mismatch = JourneyService(
      currentPassengerId: () => 'rider',
      writer: (j) async => j.copyWith(busId: 'other'),
    );
    await expectLater(mismatch.createJourney(saved()), throwsStateError);
  });

  Future<void> confirmScreen(
    WidgetTester tester,
    JourneyService service,
    void Function(JourneyModel) callback,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: JourneyConfirmationScreen(
          origin: 'Boarding',
          destination: 'Destination',
          route: selection(),
          service: service,
          onSaved: callback,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Confirm and save journey'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'save failure stays on confirmation; retry uses the same ID and exact choice',
    (tester) async {
      var reject = true;
      final attempted = <JourneyModel>[];
      final completed = <JourneyModel>[];
      final service = JourneyService(
        currentPassengerId: () => 'rider',
        writer: (j) async {
          attempted.add(j);
          if (reject) throw StateError('Save rejected');
          return j;
        },
      );
      await confirmScreen(tester, service, completed.add);
      expect(find.text('09:00'), findsOneWidget);
      expect(find.textContaining('Verified'), findsNothing);
      await tester.tap(find.text('Confirm and save journey'));
      await tester.pumpAndSettle();
      expect(find.text('Save rejected'), findsOneWidget);
      expect(completed, isEmpty);
      reject = false;
      await tester.tap(find.text('Confirm and save journey'));
      await tester.pumpAndSettle();
      expect(attempted.length, 2);
      expect(attempted[0].journeyId, attempted[1].journeyId);
      expect(completed.single.fromStationId, 'b');
      expect(completed.single.toStationId, 'c');
      expect(completed.single.routeNumber, '177');
      expect(completed.single.departureAt, selection().nextDepartureDateTime);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'save waits for acknowledgement and disables repeated confirmation',
    (tester) async {
      final ack = Completer<JourneyModel>();
      JourneyModel? attempted;
      var calls = 0;
      var completed = false;
      final service = JourneyService(
        currentPassengerId: () => 'rider',
        writer: (j) {
          calls++;
          attempted = j;
          return ack.future;
        },
      );
      await confirmScreen(tester, service, (_) => completed = true);
      await tester.tap(find.text('Confirm and save journey'));
      await tester.pump();
      expect(find.text('Saving journey...'), findsOneWidget);
      expect(completed, isFalse);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Saving journey...'),
            )
            .onPressed,
        isNull,
      );
      ack.complete(attempted!);
      await tester.pumpAndSettle();
      expect(completed, isTrue);
      expect(calls, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'guest confirmation cannot save or navigate with a substitute identity',
    (tester) async {
      var calls = 0;
      final service = JourneyService(
        currentPassengerId: () => null,
        writer: (j) async {
          calls++;
          return j;
        },
      );
      await confirmScreen(tester, service, (_) => fail('Guest must not start'));
      await tester.tap(find.text('Confirm and save journey'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sign in to save'), findsOneWidget);
      expect(calls, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'account changing while save is pending cannot enter another account journey',
    (tester) async {
      String? actor = 'rider';
      final ack = Completer<JourneyModel>();
      JourneyModel? attempted;
      final service = JourneyService(
        currentPassengerId: () => actor,
        writer: (j) {
          attempted = j;
          return ack.future;
        },
      );
      await confirmScreen(tester, service, (_) => fail('Account changed'));
      await tester.tap(find.text('Confirm and save journey'));
      await tester.pump();
      actor = 'other';
      ack.complete(attempted!);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('ownership or status changed'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Home subscription receives newly saved journeys and resumes their exact identity',
    (tester) async {
      final updates = StreamController<JourneyModel?>();
      JourneyModel? resumed;
      final service = JourneyService(
        currentPassengerId: () => 'rider',
        activeReader: (_) => updates.stream,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SavedJourneyPanel(
              userId: 'rider',
              service: service,
              onResume: (j) => resumed = j,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Resume journey'), findsNothing);
      updates.add(saved());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Resume journey'));
      expect(resumed!.journeyId, 'saved_id');
      expect(resumed!.selectedTimeMinutes, 540);
      updates.add(saved().copyWith(status: JourneyStatus.completed));
      await tester.pumpAndSettle();
      expect(find.text('Resume journey'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      unawaited(updates.close());
    },
  );
  testWidgets(
    'failed cancellation keeps shared journey open with failure feedback',
    (tester) async {
      final service = JourneyService(
        currentPassengerId: () => 'rider',
        activeReader: (_) => Stream.value(saved()),
        statusWriter: (_, _) async => throw StateError('denied'),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SavedJourneyPanel(userId: 'rider', service: service),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel saved journey'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('status change is not confirmed'),
        findsOneWidget,
      );
      expect(find.text('Resume journey'), findsOneWidget);
    },
  );
  testWidgets('saved journey banner hides another account data', (
    tester,
  ) async {
    final service = JourneyService(
      currentPassengerId: () => 'other',
      activeReader: (_) => Stream.value(saved()),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavedJourneyPanel(userId: 'rider', service: service),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Resume journey'), findsNothing);
    expect(find.textContaining('Boarding'), findsNothing);
  });
  testWidgets(
    'restart/resume hydrates saved IDs and opens the specific saved document',
    (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final afterRestart = JourneyModel.fromMap(saved().toMap());
      String? watchedId;
      final service = JourneyService(
        currentPassengerId: () => 'rider',
        journeyReader: (id) {
          watchedId = id;
          return Stream.value(afterRestart);
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: JourneyResumeScreen(
            journey: afterRestart,
            service: service,
            repository: ResumeCatalog(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final screen = tester.widget<BusDetailsScreen>(
        find.byType(BusDetailsScreen),
      );
      expect(watchedId, 'saved_id');
      expect(screen.route.busId, vehicle.id);
      expect(screen.route.fromStationId, 'b');
      expect(screen.route.toStationId, 'c');
      expect(
        screen.route.nextDepartureDateTime,
        selection().nextDepartureDateTime,
      );
      expect(screen.route.selectedTimeMinutes, 540);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'normal result selection opens details without confirmation or automatic saving',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          // Colombo 23:30: tomorrow's fixture is inside the rolling horizon,
          // independent of the host clock/calendar at midnight.
          home: RouteResultsScreen(
            wheelchairAccessRequired: false,
            stepFreeOnly: false,
            searchBackend: FixtureSearchBackend(
              now: () => DateTime.utc(2026, 10, 17, 18),
            ),
            fromStationId: 'st_maharagama',
            toStationId: 'st_kottawa',
            origin: 'Maharagama',
            destination: 'Kottawa',
            selectedDate: DateTime(2026, 10, 18),
            selectedTime: const TimeOfDay(hour: 0, minute: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('138').first);
      await tester.pumpAndSettle();
      expect(find.byType(BusDetailsScreen), findsOneWidget);
      expect(find.byType(JourneyConfirmationScreen), findsNothing);
      expect(find.byType(LiveJourneyScreen), findsNothing);
      final details = tester.widget<BusDetailsScreen>(
        find.byType(BusDetailsScreen),
      );
      expect(details.route.fromStationId, 'st_maharagama');
      expect(details.route.toStationId, 'st_kottawa');
      expect(details.route.selectedTimeMinutes, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'excluded services can be inspected with temporary filters without changing Settings',
    (tester) async {
      final preferences = AccessibilityPreferencesService.instance;
      expect(preferences.isWheelchairOnly, isTrue);
      await tester.pumpWidget(
        MaterialApp(
          home: RouteResultsScreen(
            searchBackend: FixtureSearchBackend(
              now: () => DateTime.utc(2050, 1, 1, 18),
            ),
            fromStationId: 'st_maharagama',
            toStationId: 'st_kottawa',
            origin: 'Maharagama',
            destination: 'Kottawa',
            selectedDate: DateTime(2050, 1, 2),
            selectedTime: const TimeOfDay(hour: 0, minute: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final action = find.byKey(const ValueKey('show-without-access-filters'));
      await tester.scrollUntilVisible(
        action,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.text('138'), findsWidgets);
      expect(preferences.isWheelchairOnly, isTrue);
      await tester.tap(find.text('138').first);
      await tester.pumpAndSettle();
      final details = tester.widget<BusDetailsScreen>(
        find.byType(BusDetailsScreen),
      );
      expect(details.route.wheelchairAccessRequired, isFalse);
      expect(details.route.stepFreeOnly, isFalse);
      expect(preferences.isWheelchairOnly, isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('desktop saved journey resume fits its narrow side panel', (
    tester,
  ) async {
    final journey = JourneyModel.fromMap(saved().toMap());
    final service = JourneyService(
      currentPassengerId: () => 'rider',
      journeyReader: (_) => Stream.value(journey),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: JourneyResumeScreen(
          journey: journey,
          service: service,
          repository: ResumeCatalog(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(BusDetailsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'confirmation never turns an undated ramp capability into verification on save',
    (tester) async {
      TransitCatalogue.installFixtures({
        'buses': {
          vehicle.id: {
            ...vehicle.toMap(),
            'catalogueSource': 'operator_catalogue',
          },
        },
        'stations': {},
        'routes': {},
      });
      var savedCount = 0;
      final service = JourneyService(
        currentPassengerId: () => 'rider',
        writer: (j) async => j,
      );
      await confirmScreen(tester, service, (_) => savedCount++);
      final panel = tester.widget<LiveAccessibilityPanel>(
        find.byType(LiveAccessibilityPanel),
      );
      expect(panel.busId, vehicle.id);
      expect(panel.originId, 'b');
      expect(panel.destinationId, 'c');
      expect(find.text('Unknown - a new check is required'), findsOneWidget);
      expect(find.textContaining('Working observed'), findsNothing);
      expect(find.textContaining('Verified active'), findsNothing);
      await tester.tap(find.text('Confirm and save journey'));
      await tester.pumpAndSettle();
      expect(savedCount, 1);
      expect(find.text('Unknown - a new check is required'), findsOneWidget);
      expect(find.textContaining('Working observed'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
