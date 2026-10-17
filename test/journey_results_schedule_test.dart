import 'package:access_transit/logic/journey_fare.dart';

import 'support/fixture_search_backend.dart';
import 'ramp_test_observations.dart';

import 'package:access_transit/screens/journey/route_results_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/widgets/evidence_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    await recordWorkingRamps();
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init();
  });

  testWidgets('custom time filters results and tab counts on the requested day', (
    tester,
  ) async {
    final date = DateTime(2026, 10, 16);
    await tester.pumpWidget(
      MaterialApp(
        home: EvidenceClock(
          now: () => date,
          child: RouteResultsScreen(
            searchBackend: FixtureSearchBackend(now: () => date),
            fromStationId: 'st_maharagama',
            toStationId: 'st_kottawa',
            origin: 'Maharagama',
            destination: 'Kottawa',
            selectedDate: date,
            selectedTime: const TimeOfDay(hour: 23, minute: 59),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('All (0)'), findsOneWidget);
    expect(find.text('Accessible (0)'), findsOneWidget);
    expect(find.text('0 buses available'), findsOneWidget);
    expect(
      find.textContaining(
        '${MaterialLocalizations.of(tester.element(find.byType(RouteResultsScreen))).formatMediumDate(date)} at',
      ),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'nearby-stop results display segment duration and estimated fare',
    (tester) async {
      final date = DateTime(2026, 10, 16);
      await tester.pumpWidget(
        MaterialApp(
          home: EvidenceClock(
            now: () => date,
            child: RouteResultsScreen(
              searchBackend: FixtureSearchBackend(now: () => date),
              fromStationId: 'st_maharagama',
              toStationId: 'st_kottawa',
              origin: 'Maharagama',
              destination: 'Kottawa',
              selectedDate: date,
              selectedTime: const TimeOfDay(hour: 0, minute: 0),
              wheelchairAccessRequired: false,
              stepFreeOnly: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Seeded Route 138 reaches these stops at 07:38 and 07:55.
      expect(find.text('~17 min'), findsAtLeastNWidgets(1));
      expect(find.text(JourneyFare.label(70)), findsAtLeastNWidgets(1));
      expect(find.text('Ongoing'), findsNothing);
      expect(find.text('Approaching'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
