import 'package:access_transit/logic/journey_selection.dart';
import 'package:access_transit/logic/journey_fare.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/journey_model.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart';
import 'package:access_transit/screens/journey/route_details_screen.dart';
import 'package:access_transit/screens/journey/journey_confirmation_screen.dart';
import 'package:access_transit/screens/journey/live_journey_screen.dart';
import 'package:access_transit/services/transit_catalogue.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/widgets/fare_estimate_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bus = Bus(
  id: 'fare24',
  routeNo: '24',
  busNo: 'WP FARE-24',
  stops: ['a', 'b', 'c', 'd'],
  scheduleTimes: ['08:00', '08:10', '08:25', '08:50'],
  hasRamp: false,
  lowFloor: false,
  occupancy: 'low',
);
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init();
    TransitCatalogue.installFixtures({
      'buses': {
        bus.id: {...bus.toMap(), 'catalogueSource': 'operator_catalogue'},
      },
      'stations': {},
      'routes': {},
    });
  });
  void expectDisclosure() {
    expect(find.text('Est. LKR 70'), findsOneWidget);
    expect(find.text(JourneyFare.disclosure), findsOneWidget);
    expect(find.text('LKR 70'), findsNothing);
    expect(find.text('Rs. 250'), findsNothing);
    expect(find.textContaining('Cash or Digital Ticket'), findsNothing);
  }

  testWidgets(
    'one selected segment estimate survives results, details, confirmation, save/restore and live',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RouteResultsScreen(
            fromStationId: 'b',
            toStationId: 'c',
            origin: 'B',
            destination: 'C',
            wheelchairAccessRequired: false,
            selectedDate: DateTime.now().add(const Duration(days: 7)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expectDisclosure();
      await tester.tap(find.text('WP FARE-24'));
      await tester.pumpAndSettle();
      final route = tester
          .widget<RouteDetailsScreen>(find.byType(RouteDetailsScreen))
          .route!;
      expect(route.durationMinutes, 15);
      expect(route.estimatedPriceLkr, 70);
      await tester.scrollUntilVisible(
        find.byType(FareEstimateText).hitTestable(),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expectDisclosure();
      await tester.scrollUntilVisible(
        find.text('Review and confirm journey').hitTestable(),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Review and confirm journey'));
      await tester.pumpAndSettle();
      expect(find.byType(JourneyConfirmationScreen), findsOneWidget);
      expectDisclosure();
      final saved = JourneySelection.create(
        route,
        id: 'saved',
        passengerId: 'rider',
      );
      final restored = JourneySelection.restore(
        JourneyModel.fromMap(saved.toMap()),
        bus,
        {},
      );
      expect(restored.estimatedPriceLkr, 70);
      await tester.pumpWidget(
        MaterialApp(
          home: LiveJourneyScreen(
            busId: bus.id,
            route: restored,
            origin: 'B',
            destination: 'C',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expectDisclosure();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'direct details and live launches show unknown instead of invented fallback fares',
    (tester) async {
      for (final screen in <Widget>[
        const RouteDetailsScreen(origin: 'B', destination: 'C', bus: bus),
        LiveJourneyScreen(busId: bus.id, origin: 'B', destination: 'C'),
      ]) {
        await tester.pumpWidget(MaterialApp(home: screen));
        await tester.pumpAndSettle();
        if (screen is RouteDetailsScreen) {
          await tester.scrollUntilVisible(
            find.byType(FareEstimateText).hitTestable(),
            300,
            scrollable: find.byType(Scrollable).first,
          );
        }
        expect(find.text('Fare unknown'), findsOneWidget);
        expect(find.text('Est. LKR 80'), findsNothing);
        expect(find.text('Rs. 0'), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );
  testWidgets('another vehicle cannot inherit the selected segment fare', (
    tester,
  ) async {
    const route = RouteResultItem(
      id: 'old',
      busId: 'old',
      title: 'Old route',
      durationMinutes: 15,
      etaLabel: 'Schedule',
      transfers: 0,
      crowdLevel: 'Unknown',
      accessibilityStatus: AccessibilityStatus.unknown,
      accessibilityLabel: 'Unknown',
      safetyLabel: 'Unknown',
      summary: '',
      origin: 'B',
      destination: 'C',
      estimatedPriceLkr: 70,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: LiveJourneyScreen(
          busId: bus.id,
          route: route,
          origin: 'B',
          destination: 'C',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fare unknown'), findsOneWidget);
    expect(find.text('Est. LKR 70'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('fare semantics identify the estimate and its prototype source', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FareEstimateText(amount: 70))),
    );
    expect(
      find.bySemanticsLabel('Est. LKR 70. ${JourneyFare.disclosure}'),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
