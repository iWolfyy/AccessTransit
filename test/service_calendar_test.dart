import 'package:access_transit/services/admin_service.dart';
import 'package:access_transit/models/service_run.dart';
import 'package:access_transit/screens/admin/service_calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_admin_repository.dart';

void main() {
  Future<AdminRecord> publish(MemoryAdminRepository repo) async {
    await AdminService(repo).publishServiceSchedule(
      repo.get('buses', 'b1'),
      from: DateTime(2026, 10, 19),
      until: DateTime(2026, 10, 26),
      weekdays: {1, 3, 5},
      departureMinutes: 1430,
    );
    return repo.data['service_schedules']!.values.single;
  }

  test('weekday generation is Colombo dated, overnight and idempotent across terminal states', () async {
    final repo = adminFixture();
    addTearDown(repo.dispose);
    final calendar = await publish(repo), service = AdminService(repo);
    final first = await service.generateServiceSchedule(calendar);
    expect(first, (created: 4, preserved: 0));
    final runs = repo.data['service_runs']!.values.toList();
    final run = ServiceRun.fromMap(runs.first.id, runs.first.data);
    expect(run.plannedDepartureAt, DateTime.utc(2026, 10, 19, 18, 20));
    expect(
      run.stopTimes.values.last.difference(run.plannedDepartureAt),
      const Duration(minutes: 20),
    );
    for (var i = 0; i < runs.length; i++) {
      repo.seed('service_runs', runs[i].id, {
        ...runs[i].data,
        'status': ['boarding', 'in_progress', 'completed', 'cancelled'][i],
      });
    }
    expect(await service.generateServiceSchedule(calendar), (
      created: 0,
      preserved: 4,
    ));
    expect(repo.data['service_runs']!.values.map((r) => r.text('status')), [
      'boarding',
      'in_progress',
      'completed',
      'cancelled',
    ]);
  });

  test('retirement blocks stale generation and leaves runs intact', () async {
    final repo = adminFixture();
    addTearDown(repo.dispose);
    final c = await publish(repo), service = AdminService(repo);
    await service.generateServiceSchedule(c);
    await service.retireServiceSchedule(c);
    await expectLater(service.generateServiceSchedule(c), throwsStateError);
    expect(repo.data['service_runs']!.length, 4);
    expect(
      repo.data['service_runs']!.values.every(
        (r) => r.text('status') == 'scheduled',
      ),
      isTrue,
    );
  });

  test('changed timetable and concurrent calendar retirement reject all generation', () async {
    final repo = adminFixture();
    addTearDown(repo.dispose);
    final c = await publish(repo), service = AdminService(repo);
    repo.beforeCommit = (_, action) {
      if (action == 'generate_service_schedule') {
        repo.seed('service_schedules', c.id, {...c.data, 'state': 'retired'});
      }
    };
    await expectLater(service.generateServiceSchedule(c), throwsStateError);
    expect(repo.data['service_runs'], isNull);
    repo.beforeCommit = null;
    final bus = repo.get('buses', 'b1');
    repo.seed('buses', 'b1', {
      ...bus.data,
      'scheduleTimes': ['12:00', '12:20'],
    });
    await expectLater(service.generateServiceSchedule(c), throwsStateError);
  });

  test(
    'reject invalid calendars, no weekdays and unreviewed timetable',
    () async {
      final repo = adminFixture();
      addTearDown(repo.dispose);
      final service = AdminService(repo), bus = repo.get('buses', 'b1');
      for (final days in [
        <int>{},
        {0},
        {8},
      ]) {
        await expectLater(
          service.publishServiceSchedule(
            bus,
            from: DateTime(2026),
            until: DateTime(2026, 1, 2),
            weekdays: days,
            departureMinutes: 0,
          ),
          throwsFormatException,
        );
      }
      await expectLater(
        service.publishServiceSchedule(
          bus,
          from: DateTime(2026),
          until: DateTime(2026, 2, 1),
          weekdays: {1},
          departureMinutes: 0,
        ),
        throwsFormatException,
      );
      await expectLater(
        service.publishServiceSchedule(
          AdminRecord('buses', bus.id, {...bus.data, 'scheduleTimes': []}),
          from: DateTime(2026),
          until: DateTime(2026),
          weekdays: {1},
          departureMinutes: 0,
        ),
        throwsFormatException,
      );
    },
  );

  test('one-off slots are preserved and competing publication rolls back generation', () async {
    final repo = adminFixture();
    addTearDown(repo.dispose);
    final c = await publish(repo), service = AdminService(repo);
    await service.scheduleServiceRun(
      repo.get('buses', 'b1'),
      DateTime(2026, 10, 19),
      departureMinutes: 1430,
    );
    final oneOff = repo.data['service_runs']!.values.single;
    expect(await service.generateServiceSchedule(c), (
      created: 3,
      preserved: 1,
    ));
    expect(repo.get('service_runs', oneOff.id).data, oneOff.data);
    expect(
      repo.get('service_runs', oneOff.id).data.containsKey('scheduleId'),
      isFalse,
    );
    final other = adminFixture();
    addTearDown(other.dispose);
    final calendar = await publish(other);
    other.beforeCommit = (changes, action) {
      if (action != 'generate_service_schedule') return;
      final run = changes.firstWhere((c) => c.kind == 'service_runs');
      other.seed(run.kind, run.id, run.after!);
    };
    await expectLater(
      AdminService(other).generateServiceSchedule(calendar),
      throwsStateError,
    );
    expect(other.data['service_runs']!.length, 1);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('calendar generates and retires at 320dp / $scale', (
      tester,
    ) async {
      final repo = adminFixture();
      addTearDown(repo.dispose);
      await publish(repo);
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: ServiceCalendarScreen(
              bus: repo.get('buses', 'b1'),
              service: AdminService(repo),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Generate dated departures'),
        200,
      );
      await tester.ensureVisible(find.text('Generate dated departures'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Generate dated departures'));
      await tester.pumpAndSettle();
      expect(repo.data['service_runs']!.length, 4);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Retire calendar'), 150);
      await tester.ensureVisible(find.text('Retire calendar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retire calendar'));
      await tester.pumpAndSettle();
      expect(
        repo.data['service_schedules']!.values.single.text('state'),
        'retired',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
