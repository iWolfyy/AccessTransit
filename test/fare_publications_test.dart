import 'dart:async';
import 'dart:convert';

import 'package:access_transit/logic/journey_fare.dart';
import 'package:access_transit/logic/journey_selection.dart';
import 'package:access_transit/models/journey_model.dart';
import 'package:access_transit/services/fare_catalogue.dart';
import 'package:access_transit/services/journey_service.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/services/transit_catalogue.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart';
import 'package:access_transit/screens/admin/fare_publications_screen.dart';
import 'package:access_transit/screens/journey/bus_details_screen.dart';
import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/logic/transit_time.dart';
import 'package:access_transit/widgets/save_trip_control.dart';
import 'package:access_transit/widgets/fare_estimate_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/memory_admin_repository.dart';
import 'support/fixture_search_backend.dart';
import 'bus_details_flow_test.dart' as fixture;

// Fictional software fixtures only. Never a real fare import.
Map<String, dynamic> publication({String id = 'fare-v1', int amount = 12345}) =>
    {
      'schemaVersion': 1,
      'synthetic': JourneyFare.prototypeEnabled,
      'busIds': ['physical'],
      'table': {
        'reviewed': true,
        'currency': 'LKR',
        'version': 'table-v1',
        'routePatternId': 'route',
        'serviceClass': 'normal',
        'effectiveFrom': '2026-10-01',
        'effectiveUntil': '2026-10-31',
        'source': 'https://authority.example/fictional',
        'amounts': {
          'B': {'D': amount},
        },
      },
      'mapping': {
        'reviewed': true,
        'version': 'map-v1',
        'tariffId': id,
        'routePatternId': 'route',
        'serviceClass': 'normal',
        'effectiveFrom': '2026-10-01',
        'effectiveUntil': '2026-10-31',
        'occurrences': ['a', 'b', 'c', 'd', 'e'],
        'stageByOccurrence': {'a': 'A', 'b': 'B', 'c': 'C', 'd': 'D', 'e': 'E'},
      },
    };
MemoryAdminRepository repository() {
  final r = MemoryAdminRepository();
  r.seed('routes', 'route', {
    'stops': fixture.vehicle.stops,
    'catalogueSource': 'operator_catalogue',
  });
  r.seed('buses', 'physical', {
    ...fixture.vehicle.toMap(),
    'catalogueSource': 'operator_catalogue',
  });
  return r;
}

void main() {
  testWidgets(
    'Results carries the exact reviewed segment quote into Bus Details without saving',
    (tester) async {
      final p = FarePublication.parse('fare-v1', publication());
      final current = DateTime.utc(
        2026,
        10,
        16,
        2,
        30,
      ); // Colombo 08:00 before 10:00 boarding.
      TransitCatalogue.installFixtures({
        'buses': {
          'physical': {
            ...fixture.vehicle.toMap(),
            'catalogueSource': 'operator_catalogue',
          },
        },
        'routes': {},
        'stations': {},
      });
      await tester.pumpWidget(
        MaterialApp(
          home: RouteResultsScreen(
            fromStationId: 'b',
            toStationId: 'd',
            origin: 'B',
            destination: 'D',
            wheelchairAccessRequired: false,
            stepFreeOnly: false,
            searchBackend: FixtureSearchBackend(now: () => current),
            fareFeed: (_) => Stream.value([p]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          JourneyFare.prototypeEnabled
              ? 'Sample tariff LKR 123.45'
              : 'LKR 123.45',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('TEST-17'));
      await tester.pumpAndSettle();
      final screen = tester.widget<BusDetailsScreen>(
        find.byType(BusDetailsScreen),
      );
      expect(screen.route.fareQuote!.amountMinor, 12345);
      expect(screen.route.fareQuote!.mappingVersion, 'map-v1');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init(userId: 'rider');
  });
  test('publication validates bus scope, mode and applicability and makes exact cents quote', () {
    final p = FarePublication.parse('fare-v1', publication());
    final q = FarePublication.quote(
      [p],
      fixture.vehicle,
      'b',
      'd',
      fixture.clock,
    )!;
    expect(q.amountMinor, 12345);
    expect(q.tariffId, 'fare-v1');
    expect(
      FarePublication.quote([p, p], fixture.vehicle, 'b', 'd', fixture.clock),
      isNull,
    );
    expect(
      FarePublication.quote([p], fixture.vehicle, 'a', 'd', fixture.clock),
      isNull,
    );
    expect(
      FarePublication.quote(
        [p],
        fixture.vehicle.copyWith(stops: ['a', 'b', 'd', 'c', 'e']),
        'b',
        'd',
        fixture.clock,
      ),
      isNull,
    );
    final other = publication()..['synthetic'] = !JourneyFare.prototypeEnabled;
    expect(
      FarePublication.quote(
        [FarePublication.parse('fare-v1', other)],
        fixture.vehicle,
        'b',
        'd',
        fixture.clock,
      ),
      isNull,
    );
  });
  test('immutable publication creates audited dependency-checked data; stale saves cannot overwrite', () async {
    final r = repository(),
        service = AdminFareService(r),
        p = FarePublication.parse('fare-v1', publication());
    await service.publish(p, 'Source and stages reviewed.');
    expect(r.actions, ['fare_publish']);
    expect(r.get('fare_publications', 'fare-v1').text('state'), 'published');
    await expectLater(
      service.publish(p, 'Source and stages reviewed.'),
      throwsStateError,
    );
    await service.archive(
      r.get('fare_publications', 'fare-v1'),
      'Replaced with a newer tariff.',
    );
    expect(r.get('fare_publications', 'fare-v1').text('state'), 'archived');
    await expectLater(
      service.archive(
        r.get('fare_publications', 'fare-v1'),
        'Already archived.',
      ),
      throwsFormatException,
    );
  });
  test('admin review rejects wrong itinerary, timetable vehicles, short reasons and concurrent route edits', () async {
    final r = repository(),
        service = AdminFareService(r),
        p = FarePublication.parse('fare-v1', publication());
    await expectLater(service.publish(p, 'short'), throwsFormatException);
    final bus = r.get('buses', 'physical').data;
    r.seed('buses', 'physical', {
      ...bus,
      'catalogueRecordType': 'published_timetable',
    });
    await expectLater(
      service.publish(p, 'Source reviewed carefully.'),
      throwsStateError,
    );
    r.seed('buses', 'physical', bus);
    r.beforeCommit = (_, _) => r.seed('routes', 'route', {
      'stops': ['changed'],
    });
    await expectLater(
      service.publish(p, 'Source reviewed carefully.'),
      throwsStateError,
    );
    expect(r.data['fare_publications'], isNull);
  });
  test('quote snapshot survives save serialization, copy and idempotent acknowledged writer', () async {
    final p = FarePublication.parse('fare-v1', publication());
    final q = FarePublication.quote(
      [p],
      fixture.vehicle,
      'b',
      'd',
      fixture.clock,
    )!;
    final saved = JourneySelection.create(
      fixture.selection,
      id: 'saved',
      passengerId: 'rider',
      overrideFareQuote: true,
      fareQuote: q,
    );
    final service = JourneyService(
      currentPassengerId: () => 'rider',
      writer: (j) async => JourneyModel.fromMap(j.toMap()),
    );
    final acknowledged = await service.createJourney(saved);
    final restored = JourneySelection.restore(
      acknowledged.copyWith(),
      fixture.vehicle,
      {},
    );
    expect(restored.fareQuote!.toMap(), q.toMap());
    final bad = saved.toMap()
      ..['fareQuote'] = {'currency': 'LKR', 'amountMinor': 'forged'};
    expect(JourneyModel.fromMap(bad).fareQuote, isNull);
  });
  testWidgets(
    'details displays refreshed quote, saves its version and removes an archived amount',
    (tester) async {
      final repo = fixture.DetailsFixture(),
          events = StreamController<List<FarePublication>>();
      addTearDown(repo.close);
      addTearDown(events.close);
      final p = FarePublication.parse('fare-v1', publication());
      JourneyModel? saved;
      final service = JourneyService(
        currentPassengerId: () => 'rider',
        journeyReader: (_) => Stream.value(null),
        writer: (j) async {
          saved = JourneyModel.fromMap(j.toMap());
          return saved!;
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: BusDetailsScreen(
            origin: 'B',
            destination: 'D',
            route: fixture.selection,
            repository: repo,
            journeyService: service,
            fareFeed: (_) => events.stream,
            searchClock: SearchTimeAnchor(
              fixture.clock,
              elapsed: () => Duration.zero,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      repo.runEvents.add([fixture.run('scheduled')]);
      repo.reportEvents.add([]);
      events.add([p]);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(FareEstimateText),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text(
          JourneyFare.prototypeEnabled
              ? 'Sample tariff LKR 123.45'
              : 'LKR 123.45',
        ),
        findsOneWidget,
      );
      final control = tester.widget<SaveTripControl>(
        find.byType(SaveTripControl),
      );
      expect(control.fareQuote!.amountMinor, 12345);
      expect(control.fareValidated, true);
      await service.createJourney(
        JourneySelection.create(
          control.route,
          id: 'save',
          passengerId: 'rider',
          fareQuote: control.fareQuote,
          overrideFareQuote: true,
        ),
      );
      expect(saved!.fareQuote!.tariffVersion, 'table-v1');
      events.add([]);
      await tester.pumpAndSettle();
      expect(find.textContaining('123.45'), findsNothing);
      expect(
        tester.widget<SaveTripControl>(find.byType(SaveTripControl)).fareQuote,
        isNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final locale in ['en', 'si', 'ta']) {
    testWidgets('admin import/preview $locale at 320dp and 200 percent text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final r = repository();
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2),
              size: Size(320, 760),
            ),
            child: child!,
          ),
          home: FarePublicationsScreen(repository: r),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('fare-id')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(find.byKey(const ValueKey('fare-id')), 'fare-v1');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('fare-json')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.byKey(const ValueKey('fare-json')),
        jsonEncode(publication()),
      );
      await tester.pumpAndSettle();
      final outer = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      for (
        var i = 0;
        i < 20 && find.byType(OutlinedButton).evaluate().isEmpty;
        i++
      ) {
        outer.position.jumpTo(
          (outer.position.pixels + 200).clamp(
            0,
            outer.position.maxScrollExtent,
          ),
        );
        await tester.pump();
      }
      await tester.ensureVisible(find.byType(OutlinedButton));
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(CheckboxListTile),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(CheckboxListTile), findsOneWidget);
      expect(r.actions, isEmpty);
      if (locale == 'en') {
        await tester.ensureVisible(find.byType(Checkbox));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Checkbox));
        await tester.pump();
        for (
          var i = 0;
          i < 20 &&
              find.byKey(const ValueKey('fare-reason')).evaluate().isEmpty;
          i++
        ) {
          outer.position.jumpTo(
            (outer.position.pixels + 200).clamp(
              0,
              outer.position.maxScrollExtent,
            ),
          );
          await tester.pump();
        }
        await tester.ensureVisible(find.byKey(const ValueKey('fare-reason')));
        await tester.enterText(
          find.byKey(const ValueKey('fare-reason')),
          'Reviewed fictional software fixture',
        );
        await tester.pump();
        await tester.ensureVisible(find.byType(FilledButton));
        await tester.pumpAndSettle();
        r.denyWrites = true;
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        expect(r.actions, isEmpty);
        expect(r.data['fare_publications'], isNull);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull,
        );
        r.denyWrites = false;
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        expect(r.actions, ['fare_publish']);
        expect(
          r.get('fare_publications', 'fare-v1').text('state'),
          'published',
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
