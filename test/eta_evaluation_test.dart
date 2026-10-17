import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:access_transit/logic/eta_evaluation.dart';
import 'package:access_transit/models/trip_model.dart';
import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/services/eta_evaluation_store.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/screens/journey/eta_diagnostics_screen.dart';
import 'package:access_transit/screens/journey/bus_details_screen.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart';
import 'package:access_transit/logic/transit_time.dart';

import 'dated_search_test.dart' as f;
import 'route_geometry_test.dart' as g;

void capture(EtaEvaluationLedger ledger, {DateTime? at}) => ledger.observe(
  bus: f.bus,
  run: f.run(status: 'in_progress'),
  trip: f.operation(),
  now: at ?? f.now,
  gps: f.gps().copyWith(
    latitude: 6.905,
    longitude: 79.8,
    speed: 25,
    timestamp: at ?? f.now,
  ),
  geometry: g.shape(),
);
void arrival(
  EtaEvaluationLedger ledger, {
  DateTime? reported,
  DateTime? seen,
  String status = 'in_progress',
}) => ledger.observe(
  bus: f.bus,
  run: f.run(status: status),
  trip: f
      .operation(index: 1, status: status)
      .copyWith(
        stopTimes: {
          'b': StopTimingInfo(
            estimatedArrival: f.run().stopTimes['b']!,
            actualArrival: reported ?? f.now.add(const Duration(minutes: 12)),
          ),
        },
      ),
  now: seen ?? f.now.add(const Duration(minutes: 13)),
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init(userId: 'rider');
  });
  test('forecasts freeze before arrival; timetable and geometry score separately and retries do not duplicate', () {
    final ledger = EtaEvaluationLedger();
    capture(ledger);
    capture(ledger);
    expect(ledger.records.length, 4);
    expect(ledger.summaries(), isEmpty);
    final originals = jsonEncode(ledger.records);
    arrival(ledger);
    arrival(ledger);
    final scores = ledger.summaries();
    expect(scores.length, 2);
    expect(
      scores.singleWhere(
        (r) => r['source'] == 'timetable',
      )['medianAbsoluteErrorSeconds'],
      120,
    );
    final live = scores.singleWhere((r) => r['source'] == 'geometry-timetable');
    expect(live['medianAbsoluteErrorSeconds'], inInclusiveRange(30, 60));
    expect(live['intervalCovered'], 1);
    expect(live['smallSample'], true);
    expect((ledger.export()['counts'] as Map)['pending'], 2);
    final restored = EtaEvaluationLedger()
      ..restore(jsonEncode(ledger.export()));
    expect(restored.summaries(), scores);
    expect(originals, contains('road-timetable-v1'));
    expect(ledger.export().toString(), isNot(contains('79.8')));
    expect(ledger.export().toString(), isNot(contains('driverId')));
  });
  test('lead buckets select first forecast; repeated rebuilds do not overweight a stop', () {
    final ledger = EtaEvaluationLedger();
    capture(ledger);
    capture(ledger, at: f.now.add(const Duration(minutes: 1)));
    expect(ledger.records.length, 8);
    arrival(ledger);
    expect(ledger.scored().length, 2);
    expect(
      ledger.scored().every((r) => r['observedAt'] == f.now.toIso8601String()),
      true,
    );
    expect(ledger.scored().every((r) => r['leadBucket'] == '5-15m'), true);
  });
  test('cancelled, future, earlier and corrected driver arrivals remain excluded, never zero-error matches', () {
    for (final reported in [
      f.now.subtract(const Duration(seconds: 1)),
      f.now.add(const Duration(hours: 1)),
    ]) {
      final ledger = EtaEvaluationLedger();
      capture(ledger);
      arrival(ledger, reported: reported);
      expect(ledger.summaries(), isEmpty);
      expect(ledger.records.where((r) => r['excluded'] != null).length, 2);
    }
    final ledger = EtaEvaluationLedger();
    capture(ledger);
    arrival(ledger);
    arrival(ledger, reported: f.now.add(const Duration(minutes: 11)));
    expect(ledger.summaries(), isEmpty);
    expect(
      ledger.records.where((r) => r['excluded'] == 'arrival-corrected').length,
      2,
    );
    final cancelled = EtaEvaluationLedger();
    capture(cancelled);
    cancelled.observe(
      bus: f.bus,
      run: f.run(status: 'cancelled'),
      trip: f.operation(status: 'cancelled'),
      now: f.now.add(const Duration(minutes: 1)),
    );
    expect(cancelled.records.every((r) => r['excluded'] == 'cancelled'), true);
  });
  test('other runs, stale GPS and known arrivals cannot manufacture retrospective forecasts', () {
    final ledger = EtaEvaluationLedger();
    ledger.observe(
      bus: f.bus,
      run: f.run(status: 'in_progress'),
      trip: f.operation().copyWith(tripId: 'other'),
      now: f.now,
      gps: f.gps(),
      geometry: g.shape(),
    );
    ledger.observe(
      bus: f.bus,
      run: f.run(status: 'in_progress'),
      trip: f.operation(),
      now: f.now.add(const Duration(minutes: 1)),
      gps: f.gps(),
      geometry: g.shape(),
    );
    expect(ledger.records, isEmpty);
    arrival(ledger);
    expect(ledger.records, isEmpty);
  });
  test('retention/capacity are bounded and malformed persisted data fails without partial restore', () {
    final ledger = EtaEvaluationLedger();
    for (var i = 0; i < 150; i++) {
      capture(ledger, at: f.now.add(Duration(minutes: i)));
    }
    expect(ledger.records.length, EtaEvaluationLedger.maxRecords);
    expect(ledger.dropped, 100);
    final old = ledger.export();
    final broken = jsonDecode(jsonEncode(old));
    broken['records'][0]['observedAt'] = null;
    expect(() => ledger.restore(jsonEncode(broken)), throwsFormatException);
    expect(ledger.records.length, 500);
    final noncausal = jsonDecode(jsonEncode(old));
    for (final r in noncausal['records']) {
      r['actualArrival'] = r['observedAt'];
    }
    final excluded = EtaEvaluationLedger()..restore(jsonEncode(noncausal));
    expect(excluded.summaries(), isEmpty);
    capture(ledger, at: f.now.add(const Duration(days: 8)));
    expect(ledger.records.length, 4);
  });
  test('median and nearest-rank P90 use actual errors, not pending cases or a fabricated accuracy percentage', () {
    final ledger = EtaEvaluationLedger();
    capture(ledger);
    arrival(ledger);
    final template = ledger.scored().singleWhere(
      (r) => r['source'] == 'timetable',
    );
    ledger.records.clear();
    final actual = DateTime.parse(template['actualArrival']);
    for (var i = 1; i <= 20; i++) {
      ledger.records.add({
        ...template,
        'id': 'sample-$i',
        'runId': 'run-$i',
        'predictedArrival': actual.add(Duration(seconds: i)).toIso8601String(),
      });
    }
    final summary = ledger.summaries().single;
    expect(summary['count'], 20);
    expect(summary['medianAbsoluteErrorSeconds'], 10.5);
    expect(summary['p90AbsoluteErrorSeconds'], 18);
    expect(summary['smallSample'], false);
  });
  test('store is opt-in, account-scoped, retained on reload and inactive in normal mode', () async {
    final store = EtaEvaluationStore(available: true);
    await store.open('one');
    void record(String uid) => store.capture(
      uid: uid,
      bus: f.bus,
      run: f.run(status: 'in_progress'),
      trip: f.operation(),
      now: f.now,
      gps: f.gps().copyWith(speed: 25, latitude: 6.905, longitude: 79.8),
      geometry: g.shape(),
    );
    record('one');
    expect(store.ledger.records, isEmpty);
    await store.setEnabled(true);
    record('one');
    await Future<void>.delayed(Duration.zero);
    await store.setEnabled(true);
    expect(store.ledger.records.length, 4);
    await store.open('two');
    expect(store.enabled, false);
    expect(store.ledger.records, isEmpty);
    record('one');
    expect(store.ledger.records, isEmpty);
    await store.open('one');
    expect(store.enabled, true);
    expect(store.ledger.records.length, 4);
    await store.clear();
    expect(store.ledger.records, isEmpty);
    final normal = EtaEvaluationStore(available: false);
    await normal.open('one');
    await normal.setEnabled(true);
    expect(normal.ready, false);
    expect(normal.enabled, false);
    store.dispose();
    normal.dispose();
  });
  test(
    'delayed old account loads cannot overwrite new account measurements',
    () async {
      final gate = Completer<SharedPreferences>(),
          prefs = await SharedPreferences.getInstance();
      var calls = 0;
      final store = EtaEvaluationStore(
        available: true,
        preferences: () => ++calls == 1 ? gate.future : Future.value(prefs),
      );
      final old = store.open('old');
      await store.open('new');
      gate.complete(prefs);
      await old;
      expect(store.owner, 'new');
      expect(store.enabled, false);
      expect(store.ledger.records, isEmpty);
      store.dispose();
    },
  );
  test('failed local saves retain measurements and expose an error; retry clears the error', () async {
    var reject = true;
    final store = EtaEvaluationStore(
      available: true,
      write: (_, _) async => !reject,
    );
    await store.open('rider');
    await store.setEnabled(true);
    expect(store.enabled, false);
    expect(store.error, 'storage');
    reject = false;
    await store.setEnabled(true);
    expect(store.enabled, true);
    expect(store.error, isNull);
    capture(store.ledger);
    reject = true;
    await store.clear();
    expect(store.ledger.records.length, 4);
    expect(store.error, 'storage');
    reject = false;
    await store.clear();
    expect(store.ledger.records, isEmpty);
    expect(store.error, isNull);
    store.dispose();
  });
  testWidgets(
    'Bus Details captures immutable forecasts and matches an acknowledged later arrival automatically',
    (tester) async {
      final store = EtaEvaluationStore(available: true);
      await store.open('rider');
      await store.setEnabled(true);
      final backend = g.DetailsBackend();
      addTearDown(backend.close);
      var now = f.now;
      final run = f.run(status: 'in_progress');
      final selection = RouteResultItem(
        id: f.bus.id,
        busId: f.bus.id,
        rawBus: f.bus,
        serviceRunId: 'run',
        title: 'Fictional',
        origin: 'Boarding',
        destination: 'Destination',
        fromStationId: 'b',
        toStationId: 'c',
        nextDepartureDateTime: run.stopTimes['b'],
        durationMinutes: 30,
        departureTimeStr: '10:00',
        arrivalTimeStr: '10:30',
        etaLabel: 'Scheduled',
        transfers: 0,
        crowdLevel: 'Unknown',
        accessibilityStatus: AccessibilityStatus.unknown,
        accessibilityLabel: 'Unknown',
        safetyLabel: 'Unknown',
        summary: 'Segment',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: BusDetailsScreen(
            origin: 'Boarding',
            destination: 'Destination',
            route: selection,
            repository: backend,
            evaluationStore: store,
            geometryFeed: (_) => Stream.value(g.shape()),
            searchClock: SearchTimeAnchor(
              f.now,
              elapsed: () => now.difference(f.now),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      backend.runEvents.add([run]);
      await tester.pumpAndSettle();
      backend.tripEvents.add(f.operation());
      backend.gpsEvents.add(
        f.gps().copyWith(speed: 25, latitude: 6.905, longitude: 79.8),
      );
      await tester.pumpAndSettle();
      expect(store.ledger.records.length, 4);
      now = f.now.add(const Duration(minutes: 2));
      backend.tripEvents.add(
        f
            .operation(index: 1)
            .copyWith(
              stopTimes: {
                'b': StopTimingInfo(
                  estimatedArrival: run.stopTimes['b']!,
                  actualArrival: f.now.add(const Duration(minutes: 1)),
                ),
              },
            ),
      );
      await tester.pumpAndSettle();
      expect(store.ledger.scored().length, 2);
      expect(store.ledger.summaries().map((r) => r['source']).toSet(), {
        'timetable',
        'geometry-timetable',
      });
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    },
  );
  for (final locale in ['en', 'si', 'ta']) {
    testWidgets(
      'diagnostic labels and empty state fit $locale at 320dp/200 percent',
      (tester) async {
        final store = EtaEvaluationStore(available: true);
        await store.open('rider');
        tester.view.physicalSize = const Size(320, 760);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
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
            home: EtaDiagnosticsScreen(store: store),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byType(SwitchListTile),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.byType(Switch));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(store.enabled, true);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        store.dispose();
      },
    );
  }
}
