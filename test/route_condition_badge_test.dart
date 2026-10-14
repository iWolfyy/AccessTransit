import 'package:access_transit/models/enums/report_condition.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'route card shows positive, unknown and barrier observations distinctly',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await AccessibilityPreferencesService.instance.init();
      final service = FirestoreService(reportWriter: (_) async {});
      final positive = Report(
        id: 'condition-badge-report',
        targetType: 'bus',
        targetId: 'bus_138_nd4521',
        problemType: 'Ramp Working',
        condition: ReportCondition.positive,
        status: 'active',
        createdAt: DateTime.now(),
        userId: '',
      );
      await service.createReport(positive);
      await tester.pumpWidget(
        MaterialApp(
          home: RouteResultsScreen(
            fromStationId: 'st_maharagama',
            toStationId: 'st_kottawa',
            origin: 'Maharagama',
            destination: 'Kottawa',
            wheelchairAccessRequired: false,
            selectedDate: DateTime.now().add(const Duration(days: 7)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final card = find
          .ancestor(
            of: find.text('WP ND-4521'),
            matching: find.byType(Material),
          )
          .first;
      Finder badge(String label) =>
          find.descendant(of: card, matching: find.text(label));
      expect(badge('Safe'), findsOneWidget);
      expect(badge('Warning'), findsNothing);

      await service.createReport(
        positive.copyWith(
          condition: ReportCondition.unknown,
          problemType: 'Unable to check access',
        ),
      );
      await tester.pumpAndSettle();
      expect(badge('Unknown'), findsOneWidget);
      expect(badge('Safe'), findsNothing);

      await service.createReport(
        positive.copyWith(
          condition: ReportCondition.barrier,
          problemType: 'Ramp Broken',
        ),
      );
      await tester.pumpAndSettle();
      expect(badge('Warning'), findsOneWidget);
      expect(badge('Unknown'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
