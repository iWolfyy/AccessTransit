import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:access_transit/logic/route_geometry.dart';
import 'package:access_transit/logic/dated_boarding_matcher.dart';
import 'package:access_transit/logic/search_session.dart';
import 'package:access_transit/logic/journey_fare.dart';
import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/services/route_geometry_service.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/services/transit_catalogue.dart';
import 'package:access_transit/screens/admin/route_geometry_screen.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart';
import 'package:access_transit/widgets/route_progress_eta_text.dart';
import 'package:access_transit/widgets/selected_segment_map.dart';
import 'package:access_transit/screens/journey/bus_details_screen.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/station.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/models/service_run.dart';
import 'package:access_transit/logic/transit_time.dart';

import 'dated_search_test.dart' as f;
import 'support/memory_admin_repository.dart';

// Fictional road shape; not real route geometry.
Map<String, dynamic> geometryData() => {
  'reviewed': true,
  'routeId': 'route',
  'version': 'shape-v1',
  'synthetic': JourneyFare.prototypeEnabled,
  'source': 'https://authority.example/fictional-road',
  'stops': ['a', 'b', 'c'],
  'stopVertices': [0, 2, 3],
  'points': [
    [6.90, 79.80],
    [6.91, 79.80],
    [6.91, 79.81],
    [6.92, 79.82],
  ],
};
ReviewedRouteGeometry shape() =>
    ReviewedRouteGeometry.parse('route', geometryData());
MemoryAdminRepository repo() => MemoryAdminRepository()
  ..seed('routes', 'route', {
    'stops': f.bus.stops,
    'catalogueSource': 'operator_catalogue',
  })
  ..seed('stations', 'a', {'lat': 6.90, 'lng': 79.80})
  ..seed('stations', 'b', {'lat': 6.91, 'lng': 79.81})
  ..seed('stations', 'c', {'lat': 6.92, 'lng': 79.82});

class DetailsBackend extends f.ControlledSearch {
  @override
  Stream<Bus?> bus(String id) => Stream.value(f.bus);
  @override
  Future<List<Station>> stations() async => f.stations.values.toList();
  @override
  Stream<List<Report>> reports({
    required String busId,
    required List<String> stopIds,
  }) => Stream.value([]);
  @override
  Stream<List<ServiceRun>> runs(String id) => runEvents.stream;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init(userId: 'rider');
  });
  test('reviewed shape validates directed stop vertices, immutable coordinates and source', () {
    final d = geometryData(), g = ReviewedRouteGeometry.parse('route', d);
    (d['points'] as List)[0] = [1.0, 1.0];
    expect(g.points.first.latitude, 6.9);
    expect(
      ReviewedRouteGeometry.parse('route', g.toMap()).distances.last,
      g.distances.last,
    );
    expect(g.segment('a', 'b').length, 3);
    expect(g.segment('b', 'a'), isEmpty);
    expect(g.distances.last, greaterThan(3500));
    expect(() => g.points.clear(), throwsUnsupportedError);
    for (final change in [
      {'reviewed': false},
      {'source': 'http://example.test'},
      {'routeId': 'other'},
      {
        'stopVertices': [0, 0, 3],
      },
      {
        'stopVertices': [0, 2, 4],
      },
      {
        'points': [
          [double.nan, 79.8],
          [6.9, 79.8],
        ],
      },
      {
        'points': [
          [0, 0],
          [6.9, 79.8],
        ],
      },
    ]) {
      expect(
        () => ReviewedRouteGeometry.parse('route', {
          ...geometryData(),
          ...change,
        }),
        throwsA(anything),
      );
    }
  });
  test('moving ETA follows bent road distance and timetable intervals, with an honest range', () {
    final g = shape(),
        gps = f.gps().copyWith(latitude: 6.905, longitude: 79.80, speed: 25);
    final result = RouteProgressEta.estimate(
      geometry: g,
      run: f.run(status: 'in_progress'),
      trip: f.operation(),
      gps: gps,
      target: 'b',
      now: f.now,
    )!;
    expect(result.remainingMeters, inInclusiveRange(1600, 1750));
    expect(
      result.arrival.difference(f.now).inSeconds,
      inInclusiveRange(660, 690),
    );
    expect(result.earliest.isBefore(result.arrival), true);
    expect(result.latest.isAfter(result.arrival), true);
    expect(result.geometryVersion, 'shape-v1');
    final later = RouteProgressEta.estimate(
      geometry: g,
      run: f.run(status: 'in_progress'),
      trip: f.operation(),
      gps: gps.copyWith(latitude: 6.91, longitude: 79.805),
      target: 'b',
      now: f.now,
    )!;
    expect(later.remainingMeters, lessThan(result.remainingMeters));
    expect(later.arrival.isBefore(result.arrival), true);
  });
  test('stopped/off-route/stale/future/cached/other-run/implausible GPS never makes moving ETA', () {
    for (final gps in [
      f.gps(),
      f.gps().copyWith(latitude: 7.1, speed: 20),
      f.gps().copyWith(
        timestamp: f.now.subtract(const Duration(seconds: 31)),
        speed: 20,
      ),
      f.gps().copyWith(
        timestamp: f.now.add(const Duration(seconds: 1)),
        speed: 20,
      ),
      f.gps().copyWith(isCached: true, speed: 20),
      f.gps().copyWith(tripId: 'other', speed: 20),
      f.gps().copyWith(driverId: 'other', speed: 20),
      f.gps().copyWith(speed: 131),
      f.gps().copyWith(speed: double.nan),
      f.gps().copyWith(isBroadcasting: false, speed: 20),
    ]) {
      expect(
        RouteProgressEta.estimate(
          geometry: shape(),
          run: f.run(status: 'in_progress'),
          trip: f.operation(),
          gps: gps,
          target: 'b',
          now: f.now,
        ),
        isNull,
      );
    }
    expect(
      RouteProgressEta.estimate(
        geometry: shape(),
        run: f.run(),
        trip: f.operation(),
        gps: f.gps().copyWith(speed: 20),
        target: 'b',
        now: f.now,
      ),
      isNull,
    );
    expect(
      RouteProgressEta.estimate(
        geometry: shape(),
        run: f.run(status: 'in_progress'),
        trip: f.operation(index: 1),
        gps: f.gps(at: 'b').copyWith(speed: 20),
        target: 'b',
        now: f.now,
      ),
      isNull,
    );
  });
  test('ambiguous crossing does not jump to a different part of the road', () {
    final g = ReviewedRouteGeometry.parse('route', {
      ...geometryData(),
      'stops': ['a', 'b'],
      'stopVertices': [0, 4],
      'points': [
        [6.90, 79.80],
        [6.91, 79.81],
        [6.90, 79.81],
        [6.91, 79.80],
        [6.92, 79.80],
      ],
    });
    expect(
      g.project(
        f.gps().copyWith(latitude: 6.905, longitude: 79.805, speed: 20),
        0,
      ),
      isNull,
    );
  });
  test('active search offers moving boarding only with matching reviewed geometry and hides passed stops', () {
    List<dynamic> match(ReviewedRouteGeometry? g, {int index = 0}) =>
        DatedBoardingMatcher.forBus(
          bus: f.bus,
          from: 'b',
          to: 'c',
          window: BoardingSearchWindow.colombo(f.now),
          notBefore: f.now,
          runs: [f.run(status: 'in_progress')],
          trips: {'run': f.operation(index: index)},
          locations: {
            f.bus.id: f.gps().copyWith(
              latitude: 6.905,
              longitude: 79.80,
              speed: 25,
            ),
          },
          stations: f.stations,
          geometry: g,
        );
    expect(match(null), isEmpty);
    final option = match(shape()).single;
    expect(option.active, true);
    expect(option.progressEstimate, isNotNull);
    expect(option.source, contains('low confidence'));
    expect(match(shape(), index: 1), isEmpty);
    final other = ReviewedRouteGeometry.parse('other', {
      ...geometryData(),
      'routeId': 'other',
    });
    expect(match(other), isEmpty);
  });
  test(
    'admin publication guards route/stop data, versions and audited withdrawal',
    () async {
      final r = repo(), service = AdminRouteGeometryService(repo());
      await service.publish(shape(), 'Reviewed fictional road path');
      await expectLater(
        service.publish(shape(), 'Reviewed fictional road path'),
        throwsStateError,
      );
      await service.withdraw(
        'route',
        'Withdraw fictional road pending correction',
      );
      final repository = repo(),
          publisher = AdminRouteGeometryService(repository);
      repository.beforeCommit = (_, _) =>
          repository.seed('stations', 'b', {'lat': 7.0, 'lng': 79.8});
      await expectLater(
        publisher.publish(shape(), 'Reviewed fictional road path'),
        throwsStateError,
      );
      expect(repository.actions, isEmpty);
      final isolated = repo()
        ..seed('route_geometries', 'route', {
          ...shape().toMap(),
          'synthetic': !JourneyFare.prototypeEnabled,
          'version': 'other-mode',
        });
      await expectLater(
        AdminRouteGeometryService(isolated)
            .publish(shape(), 'Reviewed fictional road path'),
        throwsStateError,
      );
      await expectLater(
        AdminRouteGeometryService(isolated)
            .withdraw('route', 'Withdraw fictional road path'),
        throwsStateError,
      );
      r.seed('stations', 'b', {'lat': 7.0, 'lng': 79.8});
      await expectLater(
        AdminRouteGeometryService(r)
            .publish(shape(), 'Reviewed fictional road path'),
        throwsStateError,
      );
    },
  );
  testWidgets(
    'Results moving quote appears on geometry receipt and disappears on withdrawal',
    (tester) async {
      TransitCatalogue.installFixtures({
        'buses': {
          f.bus.id: {...f.bus.toMap(), 'catalogueSource': 'operator_catalogue'},
        },
        'routes': {},
        'stations': {},
      });
      addTearDown(TransitCatalogue.resetMemoryForTesting);
      final backend = f.ControlledSearch(),
          events = StreamController<ReviewedRouteGeometry?>.broadcast();
      addTearDown(backend.close);
      addTearDown(events.close);
      await tester.pumpWidget(
        MaterialApp(
          home: RouteResultsScreen(
            fromStationId: 'b',
            toStationId: 'c',
            origin: 'Boarding',
            destination: 'Destination',
            wheelchairAccessRequired: false,
            stepFreeOnly: false,
            searchBackend: backend,
            geometryFeed: (_) => events.stream,
          ),
        ),
      );
      await tester.pumpAndSettle();
      backend.runEvents.add([f.run(status: 'in_progress')]);
      await tester.pumpAndSettle();
      backend.tripEvents.add(f.operation());
      backend.gpsEvents.add(
        f.gps().copyWith(latitude: 6.905, longitude: 79.8, speed: 25),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RouteProgressEtaText), findsNothing);
      events.add(shape());
      await tester.pumpAndSettle();
      expect(find.byType(RouteProgressEtaText), findsOneWidget);
      events.add(null);
      await tester.pumpAndSettle();
      expect(find.byType(RouteProgressEtaText), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'Details shares reviewed segment path; future runs have no live ETA and withdrawal clears path',
    (tester) async {
      final backend = DetailsBackend(),
          events = StreamController<ReviewedRouteGeometry?>.broadcast();
      addTearDown(backend.close);
      addTearDown(events.close);
      final service = f.run(status: 'in_progress');
      final selection = RouteResultItem(
        id: f.bus.id,
        busId: f.bus.id,
        rawBus: f.bus,
        serviceRunId: 'run',
        title: 'Fictional route',
        origin: 'Boarding',
        destination: 'Destination',
        fromStationId: 'b',
        toStationId: 'c',
        nextDepartureDateTime: service.stopTimes['b'],
        durationMinutes: 30,
        departureTimeStr: '10:00',
        arrivalTimeStr: '10:30',
        etaLabel: 'Scheduled',
        transfers: 0,
        crowdLevel: 'Unknown',
        accessibilityStatus: AccessibilityStatus.unknown,
        accessibilityLabel: 'Unknown',
        safetyLabel: 'Unknown',
        summary: 'Selected segment',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: BusDetailsScreen(
            origin: 'Boarding',
            destination: 'Destination',
            route: selection,
            repository: backend,
            geometryFeed: (_) => events.stream,
            searchClock: SearchTimeAnchor(f.now, elapsed: () => Duration.zero),
          ),
        ),
      );
      await tester.pumpAndSettle();
      backend.runEvents.add([service]);
      await tester.pumpAndSettle();
      backend.tripEvents.add(f.operation());
      backend.gpsEvents.add(
        f.gps().copyWith(latitude: 6.905, longitude: 79.8, speed: 25),
      );
      events.add(shape());
      await tester.pumpAndSettle();
      expect(find.byType(RouteProgressEtaText), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byType(SelectedSegmentMap),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widget<SelectedSegmentMap>(find.byType(SelectedSegmentMap))
            .roadPath
            .length,
        2,
      );
      backend.runEvents.add([f.run()]);
      await tester.pumpAndSettle();
      expect(find.byType(RouteProgressEtaText), findsNothing);
      expect(
        tester
            .widget<SelectedSegmentMap>(find.byType(SelectedSegmentMap))
            .location,
        isNull,
      );
      events.add(null);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SelectedSegmentMap>(find.byType(SelectedSegmentMap))
            .roadPath,
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final locale in ['en', 'si', 'ta']) {
    testWidgets(
      'geometry admin preview $locale fits 320dp at 200 percent text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 760);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = repo();
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (_, child) => MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 760),
                textScaler: TextScaler.linear(2),
              ),
              child: child!,
            ),
            home: RouteGeometryScreen(repository: repository),
          ),
        );
        await tester.pumpAndSettle();
        final outer = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        Future<void> reveal(Finder target) async {
          outer.position.jumpTo(0);
          await tester.pump();
          for (var i = 0; i < 30 && target.evaluate().isEmpty; i++) {
            outer.position.jumpTo(
              (outer.position.pixels + 200).clamp(
                0,
                outer.position.maxScrollExtent,
              ),
            );
            await tester.pump();
          }
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
        }

        await reveal(find.byKey(const ValueKey('geometry-route')));
        await tester.enterText(
          find.byKey(const ValueKey('geometry-route')),
          'route',
        );
        await reveal(find.byKey(const ValueKey('geometry-json')));
        await tester.enterText(
          find.byKey(const ValueKey('geometry-json')),
          jsonEncode(geometryData()),
        );
        await tester.pumpAndSettle();
        await reveal(find.byType(OutlinedButton));
        await tester.tap(find.byType(OutlinedButton));
        await tester.pumpAndSettle();
        await reveal(find.byType(Checkbox));
        expect(find.byType(Checkbox), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (locale == 'en') {
          await tester.tap(find.byType(Checkbox));
          await tester.pump();
          await reveal(find.byKey(const ValueKey('geometry-reason')));
          await tester.enterText(
            find.byKey(const ValueKey('geometry-reason')),
            'Reviewed fictional road path',
          );
          await tester.pump();
          await reveal(find.byType(FilledButton));
          repository.denyWrites = true;
          await tester.tap(find.byType(FilledButton));
          await tester.pumpAndSettle();
          expect(repository.actions, isEmpty);
          expect(
            tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
            isNotNull,
          );
          repository.denyWrites = false;
          await tester.tap(find.byType(FilledButton));
          await tester.pumpAndSettle();
          expect(repository.actions, ['route_geometry_publish']);
          expect(
            repository.get('route_geometries', 'route').data['reviewed'],
            true,
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
