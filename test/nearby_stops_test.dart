import 'dart:async';

import 'package:access_transit/models/station.dart';
import 'package:access_transit/services/location_service.dart';
import 'package:access_transit/services/nearby_stop_service.dart';
import 'package:access_transit/widgets/nearby_stops_sheet.dart';
import 'package:access_transit/screens/journey/journey_search_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/services/transit_catalogue.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fixture_search_backend.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

Station stop(String id, double lat) => Station(
  id: id,
  name: id,
  lat: lat,
  lng: 79.8,
  hasElevator: false,
  hasRamp: false,
);

class FakeLocation extends LocationService {
  bool enabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  LocationPermission requested = LocationPermission.denied;
  int reads = 0, prompts = 0, opened = 0;
  double accuracy = 10;
  Object? failure;
  @override
  Future<bool> isLocationServiceEnabled() async => enabled;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async {
    prompts++;
    return requested;
  }

  @override
  Future<bool> openAppSettings() async {
    opened++;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    opened++;
    return true;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration? timeLimit,
  }) async {
    reads++;
    if (failure != null) throw failure!;
    return Position(
      latitude: 6.9,
      longitude: 79.8,
      timestamp: DateTime.now(),
      accuracy: this.accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

void main() {
  testWidgets('My Location updates only the explicitly chosen boarding stop', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init();
    // ignore: invalid_use_of_visible_for_testing_member
    TransitCatalogue.installFixtures({
      'stations': {
        'Far stop': stop('Far stop', 6.91).toMap(),
        'Near stop': stop('Near stop', 6.901).toMap(),
      },
      'buses': {},
      'routes': {},
    });
    // ignore: invalid_use_of_visible_for_testing_member
    addTearDown(TransitCatalogue.resetMemoryForTesting);
    final gps = FakeLocation();
    await tester.pumpWidget(
      MaterialApp(
        home: JourneySearchScreen(
          searchBackend: FixtureSearchBackend(),
          nearbyStopService: NearbyStopService(location: gps),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Near stop'), findsOneWidget);
    await tester.tap(find.text('My Location').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Near stop'));
    await tester.pumpAndSettle();
    expect(find.text('Near stop'), findsNWidgets(2));
    expect(gps.reads, 1);
    await tester.pumpWidget(const SizedBox());
  });
  test('one foreground fix ranks the nearest five valid stops without mutating input', () async {
    final gps = FakeLocation();
    final stops = [
      for (var i = 7; i > 0; i--) stop('stop$i', 6.9 + i * .001),
      stop('invalid', double.nan),
      stop('range', 100),
    ];
    final found = await NearbyStopService(location: gps).find(stops);
    expect(found.map((s) => s.station.id), [
      'stop1',
      'stop2',
      'stop3',
      'stop4',
      'stop5',
    ]);
    expect(found.first.metres, closeTo(111, 2));
    expect(stops.first.id, 'stop7');
    expect(gps.reads, 1);
    expect(gps.prompts, 0);
  });

  test(
    'disabled, denied and permanently denied location never request a GPS fix',
    () async {
      for (final failure in [
        NearbyStopFailure.disabled,
        NearbyStopFailure.denied,
        NearbyStopFailure.deniedForever,
      ]) {
        final gps = FakeLocation();
        if (failure == NearbyStopFailure.disabled) gps.enabled = false;
        if (failure == NearbyStopFailure.denied) {
          gps.permission = LocationPermission.denied;
        }
        if (failure == NearbyStopFailure.deniedForever) {
          gps.permission = LocationPermission.deniedForever;
        }
        await expectLater(
          NearbyStopService(location: gps).find([stop('a', 6.9)]),
          throwsA(
            isA<NearbyStopException>().having(
              (e) => e.reason,
              'reason',
              failure,
            ),
          ),
        );
        expect(gps.reads, 0);
        expect(gps.prompts, failure == NearbyStopFailure.denied ? 1 : 0);
      }
    },
  );

  test(
    'a newly granted permission works and poor accuracy is rejected',
    () async {
      final gps = FakeLocation()
        ..permission = LocationPermission.denied
        ..requested = LocationPermission.whileInUse;
      expect(
        await NearbyStopService(location: gps).find([stop('a', 6.9)]),
        hasLength(1),
      );
      gps.accuracy = 1001;
      await expectLater(
        NearbyStopService(location: gps).find([stop('a', 6.9)]),
        throwsA(isA<NearbyStopException>()),
      );
    },
  );

  testWidgets('nearby selection is explicit and returns the chosen station', (
    tester,
  ) async {
    final gps = FakeLocation();
    Station? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                chosen = await showModalBottomSheet<Station>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => NearbyStopsSheet(
                    stations: [
                      stop('Far stop', 6.91),
                      stop('Near stop', 6.901),
                    ],
                    service: NearbyStopService(location: gps),
                  ),
                );
              },
              child: const Text('Locate'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Locate'));
    await tester.pumpAndSettle();
    expect(chosen, isNull);
    expect(find.text('About 0.11 km away'), findsOneWidget);
    await tester.tap(find.text('Far stop'));
    await tester.pumpAndSettle();
    expect(chosen?.id, 'Far stop');
    expect(gps.reads, 1);
  });

  testWidgets(
    'blocked permission offers settings, retry and manual dismissal at large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gps = FakeLocation()..permission = LocationPermission.deniedForever;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: NearbyStopsSheet(
                stations: [stop('A', 6.9)],
                service: NearbyStopService(location: gps),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Open settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open settings'));
      await tester.pumpAndSettle();
      expect(gps.opened, 1);
      gps.permission = LocationPermission.whileInUse;
      await tester.ensureVisible(find.text('Retry location'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry location'));
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('GPS failure retries without claiming a stop was selected', (
    tester,
  ) async {
    final gps = FakeLocation()..failure = TimeoutException('GPS');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NearbyStopsSheet(
            stations: [stop('A', 6.9)],
            service: NearbyStopService(location: gps),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Could not get a usable location. Retry or choose a stop manually.',
      ),
      findsOneWidget,
    );
    expect(find.text('A'), findsNothing);
    gps.failure = null;
    await tester.tap(find.text('Retry location'));
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
    expect(gps.reads, 2);
  });
}
