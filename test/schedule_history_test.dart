import 'package:access_transit/logic/journey_selection.dart';
import 'package:access_transit/models/service_run.dart';
import 'package:access_transit/models/journey_model.dart';
import 'package:access_transit/services/admin_service.dart';
import 'package:access_transit/services/bus_details_repository.dart';
import 'package:access_transit/services/journey_service.dart';
import 'package:access_transit/screens/admin/service_runs_screen.dart';
import 'package:access_transit/screens/journey/bus_details_screen.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/bus_location_model.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/models/station.dart';
import 'package:access_transit/widgets/saved_schedule_record.dart';
import 'package:access_transit/widgets/selected_segment_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_admin_repository.dart';
import 'bus_details_flow_test.dart' as f;

class MissingCatalogue extends BusDetailsRepository {
  @override
  Stream<Bus?> bus(String id) => Stream.value(null);
  @override
  Future<List<Station>> stations() async => [];
  @override
  Stream<List<Report>> reports({
    required String busId,
    required List<String> stopIds,
  }) => Stream.value([]);
  @override
  Stream<BusLocationModel?> location(String id) => Stream.value(null);
  @override
  Stream<List<ServiceRun>> runs(String id) => Stream.value([cancelled()]);
}

ServiceRun cancelled() => ServiceRun(
  id: 'run-1',
  busId: f.vehicle.id,
  routeId: 'route',
  routeNo: '17',
  serviceDate: '2026-10-16',
  plannedDepartureAt: f.run().plannedDepartureAt,
  latestStartAt: f.run().latestStartAt,
  stopTimes: f.run().stopTimes,
  status: 'cancelled',
  replacementRunId: 'replacement',
  replacementDepartureAt: f.clock.toUtc().add(const Duration(hours: 2)),
  changeReason: 'Public operator timetable change',
);

void main() {
  Future<AdminRecord> seed(MemoryAdminRepository repo) async {
    await AdminService(repo)
        .scheduleServiceRun(repo.get('buses', 'b1'), DateTime(2026, 10, 17));
    return repo.data['service_runs']!.values.single;
  }

  test('atomic replacement retains original timeline, increments versions and prevents forks', () async {
    final repo = adminFixture();
    addTearDown(repo.dispose);
    final service = AdminService(repo), old = await seed(repo);
    repo.seed('journeys', 'untouched', {
      'serviceRunId': old.id,
      'departureAt': old.data['plannedDepartureAt'],
    });
    await service.rescheduleServiceRun(
      old,
      DateTime(2026, 10, 18),
      departureMinutes: 15,
      publicReason: 'Reviewed timetable change',
    );
    final before = repo.get('service_runs', old.id),
        next = repo.get('service_runs', before.text('replacementRunId'));
    expect(before.text('status'), 'cancelled');
    expect(before.data['initialStopTimes'], old.data['initialStopTimes']);
    expect(next.text('replacesRunId'), old.id);
    expect(next.data['scheduleVersion'], 2);
    expect(repo.data['service_run_changes']!.length, 1);
    expect(repo.get('journeys', 'untouched').text('serviceRunId'), old.id);
    await expectLater(
      service.rescheduleServiceRun(
        old,
        DateTime(2026, 10, 19),
        departureMinutes: 30,
        publicReason: 'Another change',
      ),
      throwsStateError,
    );
    await service.rescheduleServiceRun(
      next,
      DateTime(2026, 10, 19),
      departureMinutes: 30,
      publicReason: 'Another reviewed change',
    );
    expect(repo.data['service_run_changes']!.length, 2);
    expect(
      repo
          .get(
            'service_runs',
            repo.get('service_runs', next.id).text('replacementRunId'),
          )
          .data['scheduleVersion'],
      3,
    );
  });
  test('simultaneous start, failed commit and occupied replacement cannot partly cancel old run', () async {
    final repo = adminFixture();
    addTearDown(repo.dispose);
    final old = await seed(repo), s = AdminService(repo);
    repo.denyWrites = true;
    await expectLater(
      s.rescheduleServiceRun(
        old,
        DateTime(2026, 10, 18),
        departureMinutes: 0,
        publicReason: 'Reviewed change',
      ),
      throwsStateError,
    );
    expect(repo.get('service_runs', old.id).text('status'), 'scheduled');
    expect(repo.data['service_run_changes'], isNull);
    repo.denyWrites = false;
    repo.beforeCommit = (_, action) {
        if (action == 'reschedule_service_run') {
        repo.seed('trips', old.id, {'status': 'in_progress'});
        }
    };
    await expectLater(
      s.rescheduleServiceRun(
        old,
        DateTime(2026, 10, 18),
        departureMinutes: 0,
        publicReason: 'Reviewed change',
      ),
      throwsStateError,
    );
    expect(repo.data['service_runs']!.length, 1);
    expect(repo.get('service_runs', old.id).text('status'), 'scheduled');
    repo.beforeCommit = null;
    await expectLater(
      s.rescheduleServiceRun(
        old,
        DateTime(2026, 10, 18),
        departureMinutes: 0,
        publicReason: 'Reviewed change',
      ),
      throwsStateError,
    );
  });
  test('snapshot persists exact original segment and can restore after catalogue changes', () {
    final saved = JourneySelection.create(
      f.selection,
      id: 'snapshot',
      passengerId: 'owner',
      run: f.run(),
    );
    final decoded = JourneyModel.fromMap(saved.toMap());
    expect(decoded.scheduleSnapshot!.stops, ['b', 'c', 'd']);
    expect(decoded.scheduleSnapshot!.times['c'], f.run().stopTimes['c']);
    expect(decoded.scheduleSnapshot!.runVersion, 1);
    final changed = f.vehicle.copyWith(stops: ['a', 'b', 'd', 'e']);
    expect(decoded.scheduleSnapshot!.matches(changed), isFalse);
    final restored = JourneySelection.restore(decoded, changed, {});
    expect(restored.intermediateStops, ['c']);
    expect(restored.nextDepartureDateTime, f.selection.nextDepartureDateTime);
    expect(
      restored.rawBus!.hasRamp,
      isFalse,
    ); // Historical data never certifies current equipment.
    final raw = decoded.toMap();
    raw['scheduleSnapshot'] = {'schemaVersion': 999};
    expect(JourneyModel.fromMap(raw).scheduleSnapshot, isNull);
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'historical saved details retain cancellation/replacement without GPS at $scale',
      (tester) async {
        final saved = JourneySelection.create(
          f.selection,
          id: 'snapshot',
          passengerId: 'owner',
          serviceRunId: 'run-1',
          run: f.run(),
        );
        final service = JourneyService(
          currentPassengerId: () => 'owner',
          journeyReader: (_) => Stream.value(saved),
        );
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: BusDetailsScreen(
                origin: saved.origin,
                destination: saved.destination,
                route: f.selection,
                savedJourney: saved,
                journeyService: service,
                repository: MissingCatalogue(),
                fareFeed: (_) => Stream.value([]),
                geometryFeed: (_) => Stream.value(null),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SavedScheduleRecord), findsOneWidget);
        expect(find.byType(SelectedSegmentMap), findsNothing);
        await tester.scrollUntilVisible(
          find.textContaining('This departure was cancelled'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          find.textContaining('This departure was cancelled'),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(
          find.textContaining('A replacement was published'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          find.textContaining('A replacement was published'),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(
          find.text('Public operator timetable change'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Public operator timetable change'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'admin replacement dialog publishes linked change, without changing saved records',
    (tester) async {
      final repo = adminFixture();
      addTearDown(repo.dispose);
      await AdminService(repo)
          .scheduleServiceRun(repo.get('buses', 'b1'), DateTime(2025, 1, 1));
      final old = repo.data['service_runs']!.values.single;
      await tester.pumpWidget(
        MaterialApp(
          home: ServiceRunsScreen(
            bus: repo.get('buses', 'b1'),
            service: AdminService(repo),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final action = find.text('Publish replacement');
      await tester.scrollUntilVisible(
        action,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('reschedule-reason')),
        'Public timetable review',
      );
      await tester.tap(
        find.widgetWithText(FilledButton, 'Publish replacement'),
      );
      await tester.pumpAndSettle();
      expect(repo.get('service_runs', old.id).text('status'), 'cancelled');
      expect(repo.data['service_run_changes']!.length, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
