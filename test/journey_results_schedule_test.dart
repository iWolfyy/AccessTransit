import 'package:access_transit/core/utils/time_utils.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init();
  });

  testWidgets(
    'custom time filters results and tab counts on the requested day',
    (tester) async {
      final date = DateTime.now().add(const Duration(days: 7));
      await tester.pumpWidget(
        MaterialApp(
          home: RouteResultsScreen(
            fromStationId: 'st_maharagama',
            toStationId: 'st_kottawa',
            origin: 'Maharagama',
            destination: 'Kottawa',
            selectedDate: date,
            selectedTime: const TimeOfDay(hour: 23, minute: 59),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All (0)'), findsOneWidget);
      expect(find.text('Accessible (0)'), findsOneWidget);
      expect(find.text('0 buses available'), findsOneWidget);
      expect(
        find.textContaining('${TimeUtils.formatDateString(date)} at'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'nearby-stop results display segment duration and estimated fare',
    (tester) async {
      final date = DateTime.now().add(const Duration(days: 7));
      await tester.pumpWidget(
        MaterialApp(
          home: RouteResultsScreen(
            fromStationId: 'st_maharagama',
            toStationId: 'st_kottawa',
            origin: 'Maharagama',
            destination: 'Kottawa',
            selectedDate: date,
            selectedTime: const TimeOfDay(hour: 0, minute: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Seeded Route 138 reaches these stops at 07:38 and 07:55.
      expect(find.text('~17 min'), findsAtLeastNWidgets(1));
      expect(find.text('LKR 70'), findsAtLeastNWidgets(1));
      expect(find.text('Ongoing'), findsNothing);
      expect(find.text('Approaching'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
