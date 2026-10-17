import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/screens/journey/journey_search_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/services/nearby_stop_service.dart';
import 'package:access_transit/services/transit_catalogue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nearby_stops_test.dart' show FakeLocation, stop;
import 'registration_onboarding_localization_test.dart' show host, narrow;
import 'support/fixture_search_backend.dart';

Future<void> press(WidgetTester t, Finder finder) async {
  await t.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await t.pumpAndSettle();
  await t.tap(finder);
  await t.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init(userId: 'fixture');
    await AccessibilityPreferencesService.instance.setHighContrast(false);
    // ignore: invalid_use_of_visible_for_testing_member
    TransitCatalogue.installFixtures({
      'stations': {
        'a': stop('Original A', 6.91).toMap(),
        'b': stop('Original B', 6.901).toMap(),
      },
      'buses': {},
      'routes': {},
    });
  });
  tearDown(() {
    // ignore: invalid_use_of_visible_for_testing_member
    TransitCatalogue.resetMemoryForTesting();
  });
  for (final lang in ['en', 'si', 'ta']) {
    testWidgets(
      'search $lang preserves names and uses explicit nearby stop selection',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        final gps = FakeLocation();
        await t.pumpWidget(
          host(
            lang,
            JourneySearchScreen(
              searchBackend: FixtureSearchBackend(),
              nearbyStopService: NearbyStopService(location: gps),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.text(l.searchPlan), findsOneWidget);
        expect(find.text('Original A'), findsOneWidget);
        expect(find.text('Original B'), findsOneWidget);
        expect(gps.reads, 0);
        await press(t, find.text(l.searchMyLocation).first);
        expect(find.text(l.nearbyStopsTitle), findsOneWidget);
        await press(t, find.widgetWithText(ListTile, 'Original B'));
        expect(gps.reads, 1);
        expect(find.text('Original B'), findsNWidgets(2));
        expect(t.takeException(), isNull);
      },
    );

    testWidgets('search $lang temporary needs and reset never write Settings', (
      t,
    ) async {
      narrow(t);
      final l = lookupAppLocalizations(Locale(lang));
      final service = AccessibilityPreferencesService.instance;
      await service.setWheelchairOnly(false);
      await service.setHighContrast(true);
      await t.pumpWidget(
        host(lang, JourneySearchScreen(searchBackend: FixtureSearchBackend())),
      );
      await t.pumpAndSettle();
      await press(t, find.text(l.searchConfigure));
      expect(find.text(l.searchTemporaryHelp), findsOneWidget);
      await press(t, find.text(l.searchRamp));
      expect(service.isWheelchairOnly, isFalse);
      await press(t, find.text(l.searchApply));
      expect(find.text(l.searchRampRequired), findsOneWidget);
      expect(service.isWheelchairOnly, isFalse);
      await press(t, find.text(l.searchActiveNeeds(1)));
      await press(t, find.text(l.searchReset));
      await press(t, find.text(l.searchApply));
      expect(find.text(l.searchRampRequired), findsNothing);
      expect(service.isWheelchairOnly, isFalse);
      expect(t.takeException(), isNull);
    });

    testWidgets(
      'search $lang time sheet and suggestions make truthful localized claims',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        await t.pumpWidget(
          host(
            lang,
            JourneySearchScreen(searchBackend: FixtureSearchBackend()),
          ),
        );
        await t.pumpAndSettle();
        await press(t, find.text(l.searchDepartNow));
        expect(find.text(l.searchTravelChoice), findsOneWidget);
        expect(find.text(l.searchWindowNotice), findsOneWidget);
        await press(t, find.text(l.searchLeaveNow).last);
        await press(t, find.byTooltip(l.searchSuggestions).first);
        expect(find.text(l.searchVoiceUnavailable), findsOneWidget);
        expect(find.text('Listening...'), findsNothing);
        await press(t, find.widgetWithText(ActionChip, 'Original B'));
        expect(find.text(l.searchStopSelected('Original B')), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }
}
