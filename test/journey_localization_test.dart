import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart';
import 'package:access_transit/screens/journey/bus_details_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/services/journey_service.dart';
import 'package:access_transit/services/transit_catalogue.dart';
import 'package:access_transit/logic/transit_time.dart';
import 'package:access_transit/widgets/evidence_refresh.dart';
import 'package:access_transit/widgets/selected_segment_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bus_details_flow_test.dart' as details;
import 'results_timetable_provenance_test.dart' show bus;
import 'registration_onboarding_localization_test.dart' show host, narrow;
import 'support/fixture_search_backend.dart';

Future<void> press(WidgetTester t, Finder target) async {
  if (target.evaluate().isEmpty) {
    await t.scrollUntilVisible(
      target,
      200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
  }
  await Scrollable.ensureVisible(t.element(target), alignment: .5);
  await t.pumpAndSettle();
  await t.tap(target);
  await t.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init(userId: 'rider');
    await AccessibilityPreferencesService.instance.setHighContrast(false);
    await AccessibilityPreferencesService.instance.setWheelchairOnly(false);
    // ignore: invalid_use_of_visible_for_testing_member
    TransitCatalogue.installFixtures({
      'buses': {
        bus.id: {...bus.toMap(), 'catalogueSource': 'operator_catalogue'},
      },
      'routes': {},
      'stations': {},
    });
  });
  tearDown(() {
    // ignore: invalid_use_of_visible_for_testing_member
    TransitCatalogue.resetMemoryForTesting();
  });
  for (final lang in ['en', 'si', 'ta']) {
    testWidgets(
      'results $lang keep identity and temporary requirements with large text',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        final now = DateTime(2026, 10, 15, 9, 50);
        await t.pumpWidget(
          host(
            lang,
            EvidenceClock(
              now: () => now,
              child: RouteResultsScreen(
                searchBackend: FixtureSearchBackend(now: () => now),
                fromStationId: 'a',
                toStationId: 'b',
                origin: 'Original A',
                destination: 'Original B',
                wheelchairAccessRequired: false,
                stepFreeOnly: false,
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.text(l.resultsTitle), findsOneWidget);
        expect(find.text('WP TEST-22'), findsOneWidget);
        expect(find.text(l.resultsScheduled), findsOneWidget);
        expect(find.text(l.resultsTimetableHelp), findsOneWidget);
        expect(find.text(l.detailsLive), findsNothing);
        await press(t, find.text(l.resultsAccessibleTab(0)));
        await t.scrollUntilVisible(
          find.text(l.resultsNoAccessible),
          200,
          scrollable: find
              .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              )
              .first,
        );
        expect(find.text(l.resultsNoAccessible), findsOneWidget);
        await press(t, find.text(l.resultsReviewNeeds));
        expect(find.text(l.resultsReviewHelp), findsOneWidget);
        await press(t, find.text(l.resultsApplyNeeds));
        expect(
          AccessibilityPreferencesService.instance.isWheelchairOnly,
          isFalse,
        );
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'details $lang scoped reports and live status remain on selected segment',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        await AccessibilityPreferencesService.instance.setHighContrast(true);
        final repository = details.DetailsFixture();
        var writes = 0;
        final journeys = JourneyService(
          currentPassengerId: () => 'rider',
          journeyReader: (_) => Stream.value(null),
          writer: (j) async {
            writes++;
            return j;
          },
        );
        await t.pumpWidget(
          host(
            lang,
            EvidenceClock(
              now: () => details.clock,
              child: BusDetailsScreen(
                origin: 'Original Boarding',
                destination: 'Original Destination',
                route: details.selection,
                repository: repository,
                journeyService: journeys,
                searchClock: SearchTimeAnchor(details.clock),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        repository.runEvents.add([details.run('scheduled')]);
        repository.reportEvents.add([
          details.report('Original report text', 'station', 'c'),
          details.report('Outside report', 'station', 'a'),
        ]);
        await t.pumpAndSettle();
        expect(find.text(l.detailsLive), findsNothing);
        expect(
          t
              .widget<SelectedSegmentMap>(find.byType(SelectedSegmentMap))
              .location,
          isNull,
        );
        expect(writes, 0);
        repository.runEvents.add([details.run()]);
        await t.pumpAndSettle();
        expect(find.text(l.detailsLive), findsOneWidget);
        expect(
          t
              .widget<SelectedSegmentMap>(find.byType(SelectedSegmentMap))
              .location
              ?.tripId,
          'run-1',
        );
        await t.scrollUntilVisible(find.text('Original report text'), 300);
        expect(find.text('Outside report'), findsNothing);
        await t.scrollUntilVisible(find.text(l.saveTrip), 200);
        expect(
          t.getTopLeft(find.text('Original report text')).dy,
          lessThan(t.getTopLeft(find.text(l.saveTrip)).dy),
        );
        expect(writes, 0);
        repository.reportEvents.add([
          details
              .report('Original report text', 'station', 'c')
              .copyWith(falseCount: 5),
        ]);
        repository.runEvents.add([details.run('completed')]);
        await t.pumpAndSettle();
        expect(find.text('Original report text'), findsNothing);
        expect(find.text(l.detailsLive), findsNothing);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        repository.close();
        await t.pumpAndSettle();
      },
    );
  }
}
