import 'package:access_transit/models/enums/report_condition.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init();
    await FirestoreService(busWriter: (_, _) async {})
        .updateBusAccessibility('bus_138_nd4521', rampOk: true);
  });
  Future<void> show(WidgetTester tester, {bool wheelchair = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RouteResultsScreen(
          fromStationId: 'st_maharagama',
          toStationId: 'st_kottawa',
          origin: 'Maharagama',
          destination: 'Kottawa',
          selectedDate: DateTime.now().add(const Duration(days: 7)),
          wheelchairAccessRequired: wheelchair,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Accessible tab excludes a broken ramp while All displays the alternative',
    (tester) async {
      await FirestoreService(busWriter: (_, _) async {})
          .updateBusAccessibility('bus_138_nd4521', rampOk: false);
      await show(tester);
      expect(find.text('WP ND-4521'), findsOneWidget);
      await tester.tap(find.textContaining('Accessible ('));
      await tester.pumpAndSettle();
      expect(find.text('WP ND-4521'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'wheelchair requirement excludes a broken ramp even after selecting All',
    (tester) async {
      await FirestoreService(busWriter: (_, _) async {})
          .updateBusAccessibility('bus_138_nd4521', rampOk: false);
      await show(tester, wheelchair: true);
      expect(find.text('WP ND-4521'), findsNothing);
      await tester.tap(find.textContaining('All ('));
      await tester.pumpAndSettle();
      expect(find.text('WP ND-4521'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'issue at an unused stop does not remove a matching accessible journey',
    (tester) async {
      await FirestoreService(reportWriter: (_) async {}).createReport(
        Report(
          id: 'unused-stop-barrier',
          targetType: 'station',
          targetId: 'st_pettah',
          problemType: 'Path Blocked',
          condition: ReportCondition.barrier,
          status: 'active',
          createdAt: DateTime.now(),
          userId: '',
        ),
      );
      await show(tester, wheelchair: true);
      expect(find.text('WP ND-4521'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
