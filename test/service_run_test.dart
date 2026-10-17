import 'package:access_transit/models/service_run.dart';
import 'package:access_transit/services/admin_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_admin_repository.dart';

void main() {
  test('one-off rescheduling shifts intervals and cancellation detects a concurrent start', () async {
    final repo = adminFixture();
    addTearDown(repo.dispose);
    final service = AdminService(repo);
    final bus = repo.get('buses', 'b1');
    await service.scheduleServiceRun(
      bus,
      DateTime(2026, 10, 16),
      departureMinutes: 10,
    );
    final record = repo.data['service_runs']!.values.single;
    final run = ServiceRun.fromMap(record.id, record.data);
    expect(run.plannedDepartureAt, DateTime.utc(2026, 10, 15, 18, 40));
    expect(run.stopTimes['s2'], DateTime.utc(2026, 10, 15, 19));
    expect(repo.get('buses', 'b1').data['scheduleTimes'], ['23:50', '00:10']);
    repo.beforeCommit = (_, action) {
      if (action == 'cancel_scheduled_run') {
        repo.seed('service_runs', record.id, {
          ...record.data,
          'status': 'boarding',
        });
      }
    };
    await expectLater(service.cancelScheduledRun(record), throwsStateError);
    expect(repo.get('service_runs', record.id).text('status'), 'boarding');
  });
  test('start boundaries are inclusive at -5 and +30 minutes', () {
    final planned = DateTime.utc(2026, 10, 16, 4, 30);
    final run = ServiceRun(
      id: 'run',
      busId: 'bus',
      routeId: 'route',
      routeNo: '1',
      serviceDate: '2026-10-16',
      plannedDepartureAt: planned,
      latestStartAt: planned.add(ServiceRun.maximumLateStart),
      stopTimes: {},
    );
    expect(
      run.canStartAt(
        planned.subtract(const Duration(minutes: 5, microseconds: 1)),
      ),
      isFalse,
    );
    expect(
      run.canStartAt(planned.subtract(const Duration(minutes: 5))),
      isTrue,
    );
    expect(run.canStartAt(planned.add(const Duration(minutes: 30))), isTrue);
    expect(
      run.canStartAt(planned.add(const Duration(minutes: 30, microseconds: 1))),
      isFalse,
    );
  });
  test('admin publishes an immutable Colombo dated itinerary with overnight rollover', () async {
    final repo = adminFixture();
    addTearDown(repo.dispose);
    final service = AdminService(repo);
    await service.scheduleServiceRun(
      repo.get('buses', 'b1'),
      DateTime(2026, 10, 16),
    );
    final record = repo.data['service_runs']!.values.single;
    final run = ServiceRun.fromMap(record.id, record.data);
    expect(run.plannedDepartureAt, DateTime.utc(2026, 10, 16, 18, 20));
    expect(run.stopTimes['s2'], DateTime.utc(2026, 10, 16, 18, 40));
    expect(run.latestStartAt, DateTime.utc(2026, 10, 16, 18, 50));
    expect(run.serviceDate, '2026-10-16');
    await expectLater(
      service.scheduleServiceRun(
        repo.get('buses', 'b1'),
        DateTime(2026, 10, 16),
      ),
      throwsStateError,
    );
    await service.cancelScheduledRun(record);
    expect(repo.get('service_runs', record.id).text('status'), 'cancelled');
    await expectLater(
      service.cancelScheduledRun(repo.get('service_runs', record.id)),
      throwsStateError,
    );
  });
  test('timetable estimates, published services and stale bus snapshots cannot publish runs', () async {
    final repo = adminFixture();
    addTearDown(repo.dispose);
    final service = AdminService(repo);
    final bus = repo.get('buses', 'b1');
    await expectLater(
      service.scheduleServiceRun(
        AdminRecord('buses', 'b1', {
          ...bus.data,
          'scheduleTimes': ['23:50'],
        }),
        DateTime(2026, 10, 16),
      ),
      throwsFormatException,
    );
    await expectLater(
      service.scheduleServiceRun(
        AdminRecord('buses', 'b1', {
          ...bus.data,
          'catalogueRecordType': 'published_timetable',
        }),
        DateTime(2026, 10, 16),
      ),
      throwsFormatException,
    );
    repo.seed('buses', 'b1', {...bus.data, 'busNo': 'Changed'});
    await expectLater(
      service.scheduleServiceRun(bus, DateTime(2026, 10, 16)),
      throwsStateError,
    );
  });
}
