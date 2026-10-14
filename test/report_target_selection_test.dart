import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/bus_route.dart';
import 'package:access_transit/models/station.dart';
import 'package:access_transit/screens/journey/report_condition_screen.dart';
import 'package:access_transit/services/report_submission_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> show(
    WidgetTester tester, {
    String type = 'station',
    String id = '',
    String location = '',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReportConditionScreen(
          targetType: type,
          targetId: id,
          initialLocation: location,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  DropdownButton<T> dropdown<T>(WidgetTester tester) =>
      tester.widget(find.byType(DropdownButton<T>));
  Future<void> review(WidgetTester tester) async {
    final button = find.widgetWithText(
      FilledButton,
      'Review and submit report',
    );
    await tester.scrollUntilVisible(button, 500, maxScrolls: 30,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('generic form has no automatic route or station selection', (
    tester,
  ) async {
    await show(tester);
    expect(dropdown<BusRoute>(tester).value, isNull);
    expect(dropdown<Station>(tester).value, isNull);
    await review(tester);
    expect(
      find.text('Select the exact bus or stop you observed.'),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
    'specific bus opens on its actual route instead of the first route',
    (tester) async {
      await show(tester, type: 'bus', id: 'bus_101_ne3390');
      expect(dropdown<Bus>(tester).value!.id, 'bus_101_ne3390');
      expect(dropdown<BusRoute>(tester).value!.id, 'route_101_pettah_moratuwa');
    },
  );

  testWidgets('shared stop is preserved without guessing a route', (
    tester,
  ) async {
    await show(tester, id: 'st_moratuwa');
    expect(dropdown<Station>(tester).value!.id, 'st_moratuwa');
    expect(dropdown<BusRoute>(tester).value, isNull);
  });

  testWidgets(
    'unknown explicit target does not fall back to a matching location name',
    (tester) async {
      await show(tester, id: 'missing-stop', location: 'Moratuwa Bus Stand');
      expect(dropdown<Station>(tester).value, isNull);
    },
  );

  testWidgets('partial location name does not select a different stop', (
    tester,
  ) async {
    await show(tester, location: 'Colombo');
    expect(dropdown<Station>(tester).value, isNull);
  });

  testWidgets(
    'changing to an incompatible route clears the bus, without substituting another',
    (tester) async {
      await show(tester, type: 'bus', id: 'bus_101_ne3390');
      final routes = dropdown<BusRoute>(tester);
      routes.onChanged!(
        routes.items!
            .firstWhere((item) => item.value!.id == 'route_138_pettah_homagama')
            .value,
      );
      await tester.pumpAndSettle();
      expect(dropdown<Bus>(tester).value, isNull);
      expect(
        dropdown<Bus>(tester).items!.every(
          (item) => item.value!.routeId == 'route_138_pettah_homagama',
        ),
        true,
      );
    },
  );

  testWidgets('a valid target still requires an explicitly chosen condition', (
    tester,
  ) async {
    await show(tester, id: 'st_moratuwa');
    await review(tester);
    expect(find.text('Choose the condition you observed.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
    'review shows exact target and condition; cancelling does not create a submission',
    (tester) async {
      await show(tester, id: 'st_moratuwa');
      final option = find.text('Elevator Working');
      await tester.scrollUntilVisible(option, 250,
          scrollable: find.byType(Scrollable).first);
      tester.widget<InkWell>(find.ancestor(of: option,
          matching: find.byType(InkWell)).first).onTap!();
      await tester.pumpAndSettle();
      final before = ReportSubmissionService.instance.entries.length;
      await review(tester);
      expect(find.text('Confirm your observation'), findsOneWidget);
      expect(
        find.text('Location / Vehicle: Moratuwa Bus Stand'),
        findsOneWidget,
      );
      expect(find.text('Condition: Elevator Working'), findsOneWidget);
      await tester.tap(find.text('Edit report'));
      await tester.pumpAndSettle();
      expect(ReportSubmissionService.instance.entries.length, before);
    },
  );
}
