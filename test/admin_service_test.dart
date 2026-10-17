import 'package:access_transit/services/admin_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_admin_repository.dart';

void main() {
  late MemoryAdminRepository repository;
  late AdminService service;
  setUp(() {
    repository = adminFixture();
    service = AdminService(repository);
  });
  tearDown(() => repository.dispose());
  test('route grants require approval, preserve it and reject wrong-route bus assignment', () async {
    final user = repository.get('users', 'driver');
    await expectLater(
      service.assignDriverRoute(user, 'r1', 'Route reviewed.'),
      throwsStateError,
    );
    await service.reviewOperator(user, 'approved', 'Driver authority checked.');
    await service.assignDriverRoute(user, 'r1', 'Route authority checked.');
    expect(
      repository.get('driver_route_assignments', 'driver').text('routeId'),
      'r1',
    );
    expect(
      repository.get('operator_access', 'driver').data['approved'],
      isTrue,
    );
    repository.seed('routes', 'r2', {...repository.get('routes', 'r1').data});
    final bus = repository.get('buses', 'b1');
    await expectLater(
      service.saveCatalogue('buses', 'b1', {
        ...bus.data,
        'routeId': 'r2',
        'driverId': 'driver',
      }, original: bus),
      throwsFormatException,
    );
  });

  test('route reassignment releases stopped buses and blocks active operation changes', () async {
    final user = repository.get('users', 'driver');
    await service.reviewOperator(user, 'approved', 'Driver authority checked.');
    await service.assignDriverRoute(user, 'r1', 'Route authority checked.');
    final bus = repository.get('buses', 'b1');
    await service.saveCatalogue('buses', 'b1', {
      ...bus.data,
      'driverId': 'driver',
    }, original: bus);
    repository.seed('routes', 'r2', {...repository.get('routes', 'r1').data});
    repository.seed('live_locations', 'b1', {'isBroadcasting': true});
    await expectLater(
      service.assignDriverRoute(user, 'r2', 'Route changed by admin.'),
      throwsStateError,
    );
    expect(repository.get('buses', 'b1').text('driverId'), 'driver');
    repository.seed('live_locations', 'b1', {'isBroadcasting': false});
    await service.assignDriverRoute(user, 'r2', 'Route changed by admin.');
    expect(repository.get('buses', 'b1').text('driverId'), isEmpty);
    expect(
      repository.get('driver_route_assignments', 'driver').text('routeId'),
      'r2',
    );
    await service.assignDriverRoute(user, null, 'Route permission withdrawn.');
    expect(
      repository.get('driver_route_assignments', 'driver').data['active'],
      isFalse,
    );
    expect(
      repository.get('operator_access', 'driver').data['approved'],
      isTrue,
    );
  });

  test('approval revocation also withdraws the route grant', () async {
    final user = repository.get('users', 'driver');
    await service.reviewOperator(user, 'approved', 'Driver authority checked.');
    await service.assignDriverRoute(user, 'r1', 'Route authority checked.');
    await service.reviewOperator(user, 'revoked', 'Authority was withdrawn.');
    expect(
      repository.get('driver_route_assignments', 'driver').data['active'],
      isFalse,
    );
  });

  test('concurrent GPS start and claim revision invalidate administrative route changes', () async {
    final user = repository.get('users', 'driver');
    await service.reviewOperator(user, 'approved', 'Driver authority checked.');
    await service.assignDriverRoute(user, 'r1', 'Route authority checked.');
    final bus = repository.get('buses', 'b1');
    await service.saveCatalogue('buses', 'b1', {
      ...bus.data,
      'driverId': 'driver',
    }, original: bus);
    repository.beforeCommit = (_, action) {
      if (action == 'driver_route_removed') {
        repository.seed('live_locations', 'b1', {'isBroadcasting': true});
      }
    };
    await expectLater(
      service.assignDriverRoute(user, null, 'Route permission withdrawn.'),
      throwsStateError,
    );
    expect(
      repository.get('driver_route_assignments', 'driver').data['active'],
      isTrue,
    );
    expect(repository.get('buses', 'b1').text('driverId'), 'driver');
    repository.seed('live_locations', 'b1', {'isBroadcasting': false});
    repository.beforeCommit = (_, action) {
      if (action == 'driver_route_removed') {
        repository.seed('driver_route_assignments', 'driver', {
          ...repository.get('driver_route_assignments', 'driver').data,
          'claimRevision': 99,
        });
      }
    };
    await expectLater(
      service.assignDriverRoute(user, null, 'Route permission withdrawn.'),
      throwsStateError,
    );
    expect(repository.get('buses', 'b1').text('driverId'), 'driver');
  });
  test('creates, updates and deletes an unreferenced stop with acknowledged writes', () async {
    final data = {
      'name': 'New Stop',
      'lat': 6.5,
      'lng': 80.5,
      'sourceUrl': 'https://example.test/stop',
    };
    await service.saveCatalogue('stations', 'new', data);
    final original = repository.get('stations', 'new');
    expect(original.data['catalogueSource'], 'operator_catalogue');
    await service.saveCatalogue('stations', 'new', {
      ...data,
      'name': 'Renamed',
    }, original: original);
    await service.deleteCatalogue(repository.get('stations', 'new'));
    expect(repository.data['stations']!.containsKey('new'), isFalse);
    expect(repository.actions, [
      'create_stations',
      'update_stations',
      'prepare_delete_stations',
      'delete_stations',
    ]);
  });
  test(
    'invalid coordinates, source URLs and stop order never commit',
    () async {
      for (final data in [
        {
          'name': 'Stop',
          'lat': 91,
          'lng': 80,
          'sourceUrl': 'https://example.test',
        },
        {
          'name': 'Stop',
          'lat': 7,
          'lng': double.nan,
          'sourceUrl': 'https://example.test',
        },
        {
          'name': 'Stop',
          'lat': 7,
          'lng': 80,
          'sourceUrl': 'javascript:alert(1)',
        },
      ]) {
        await expectLater(
          service.saveCatalogue('stations', 'new', data),
          throwsFormatException,
        );
      }
      final route = repository.get('routes', 'r1');
      await expectLater(
        service.saveCatalogue('routes', 'r2', {
          ...route.data,
          'stops': ['s1', 's1'],
        }),
        throwsFormatException,
      );
      await expectLater(
        service.saveCatalogue('routes', 'r2', {
          ...route.data,
          'stops': ['s1', 'missing'],
        }),
        throwsFormatException,
      );
      expect(repository.actions, isEmpty);
    },
  );
  test(
    'pending driver can be approved without a pre-created approval record',
    () async {
      await service.reviewOperator(
        repository.get('users', 'driver'),
        'approved',
        'Reviewed licence and operating authority.',
      );
      expect(
        repository.get('operator_access', 'driver').data['approved'],
        isTrue,
      );
      expect(repository.actions.single, 'operator_approved');
    },
  );
  test(
    'review requires operator role, a meaningful note and known decision',
    () async {
      await expectLater(
        service.reviewOperator(
          repository.get('users', 'rider'),
          'approved',
          'Checked documents',
        ),
        throwsFormatException,
      );
      await expectLater(
        service.reviewOperator(
          repository.get('users', 'driver'),
          'approved',
          'short',
        ),
        throwsFormatException,
      );
      await expectLater(
        service.reviewOperator(
          repository.get('users', 'driver'),
          'anything',
          'Checked documents',
        ),
        throwsFormatException,
      );
      expect(repository.actions, isEmpty);
    },
  );
  test(
    'assignment requires approved driver; timetable cannot gain assignment',
    () async {
      final bus = repository.get('buses', 'b1');
      await expectLater(
        service.saveCatalogue('buses', 'b1', {
          ...bus.data,
          'driverId': 'driver',
        }, original: bus),
        throwsFormatException,
      );
      await service.reviewOperator(
        repository.get('users', 'driver'),
        'approved',
        'Identity and authority reviewed.',
      );
      await service.assignDriverRoute(
        repository.get('users', 'driver'),
        'r1',
        'Route authority confirmed.',
      );
      await service.saveCatalogue('buses', 'b1', {
        ...bus.data,
        'driverId': 'driver',
      }, original: bus);
      expect(repository.get('buses', 'b1').text('driverId'), 'driver');
      final assigned = repository.get('buses', 'b1');
      await expectLater(
        service.saveCatalogue('buses', 'b1', {
          ...assigned.data,
          'catalogueRecordType': 'published_timetable',
        }, original: assigned),
        throwsFormatException,
      );
    },
  );
  test('active trip must be transferred or ended before driver approval withdrawal', () async {
    repository.seed('operator_access', 'driver', {'approved': true});
    final bus = repository.get('buses', 'b1');
    repository.seed('buses', 'b1', {...bus.data, 'driverId': 'driver'});
    repository.seed('trips', 'trip', {'busId': 'b1', 'status': 'in_progress'});
    await expectLater(
      service.reviewOperator(
        repository.get('users', 'driver'),
        'revoked',
        'Operating authority could not be confirmed.',
      ),
      throwsStateError,
    );
    expect(
      repository.get('operator_access', 'driver').data['approved'],
      isTrue,
    );
    expect(repository.get('buses', 'b1').text('driverId'), 'driver');
    expect(repository.get('trips', 'trip').text('status'), 'in_progress');
  });
  test('active trips block reassignment and deletion', () async {
    repository.seed('operator_access', 'driver', {'approved': true});
    repository.seed('driver_route_assignments', 'driver', {
      'routeId': 'r1',
      'active': true,
    });
    repository.seed('trips', 'trip', {'busId': 'b1', 'status': 'in_progress'});
    final bus = repository.get('buses', 'b1');
    await expectLater(
      service.saveCatalogue('buses', 'b1', {
        ...bus.data,
        'driverId': 'driver',
      }, original: bus),
      throwsStateError,
    );
    await expectLater(service.deleteCatalogue(bus), throwsStateError);
    expect(repository.actions, isEmpty);
  });
  test(
    'bus stops follow parent route and schedule covers every stop',
    () async {
      final bus = repository.get('buses', 'b1');
      for (final overrides in [
        {
          'stops': ['s2', 's1'],
        },
        {
          'scheduleTimes': ['23:50'],
        },
        {
          'scheduleTimes': ['23:50', '25:00'],
        },
      ]) {
        await expectLater(
          service.saveCatalogue('buses', 'b1', {
            ...bus.data,
            ...overrides,
          }, original: bus),
          throwsFormatException,
        );
      }
      await service.saveCatalogue('buses', 'b1', bus.data, original: bus);
      expect(repository.get('buses', 'b1').data['scheduleTimes'], [
        '23:50',
        '00:10',
      ]);
    },
  );
  test('referenced route/stop and historical bus cannot be deleted', () async {
    await expectLater(
      service.deleteCatalogue(repository.get('routes', 'r1')),
      throwsStateError,
    );
    await expectLater(
      service.deleteCatalogue(repository.get('stations', 's1')),
      throwsStateError,
    );
    repository.seed('journeys', 'j1', {'busId': 'b1'});
    await expectLater(
      service.deleteCatalogue(repository.get('buses', 'b1')),
      throwsStateError,
    );
    expect(repository.actions, isEmpty);
  });
  test('stale editors, denied writes and offline reference reads never claim success', () async {
    final original = repository.get('stations', 's1');
    repository.seed('stations', 's1', {
      ...original.data,
      'name': 'Changed elsewhere',
    });
    await expectLater(
      service.saveCatalogue(
        'stations',
        's1',
        original.data,
        original: original,
      ),
      throwsStateError,
    );
    repository.denyWrites = true;
    await expectLater(
      service.updateUser(repository.get('users', 'rider'), 'New Name', ''),
      throwsStateError,
    );
    repository.failReads = true;
    await expectLater(
      service.saveCatalogue('buses', 'new', repository.get('buses', 'b1').data),
      throwsStateError,
    );
    expect(repository.actions, isEmpty);
  });
  test('profile edit preserves identity, role and rewards', () async {
    final user = repository.get('users', 'rider');
    await service.updateUser(user, 'Updated Passenger', '0779999999');
    expect(repository.get('users', 'rider').text('email'), user.text('email'));
    expect(repository.get('users', 'rider').text('role'), 'passenger');
  });
  test(
    'deletion rechecks dependencies after withdrawal and supports restoration',
    () async {
      final bus = repository.get('buses', 'b1');
      repository.afterCommit = (action) {
        if (action == 'prepare_delete_buses') {
          repository.seed('journeys', 'racing', {'busId': bus.id});
        }
      };
      await expectLater(service.deleteCatalogue(bus), throwsStateError);
      final pending = repository.get('buses', 'b1');
      expect(pending.data['deletionPending'], isTrue);
      await expectLater(
        service.saveCatalogue('buses', 'b1', pending.data, original: pending),
        throwsStateError,
      );
      await service.restoreCatalogue(pending);
      expect(repository.get('buses', 'b1').data['deletionPending'], isFalse);
    },
  );
  test('a pending-delete stop cannot gain a new route; dependent route edits are guarded', () async {
    final route = repository.get('routes', 'r1');
    await expectLater(
      service.saveCatalogue('routes', 'r1', {
        ...route.data,
        'routeNo': '2',
      }, original: route),
      throwsStateError,
    );
    final stop = repository.get('stations', 's1');
    repository.seed('stations', 's1', {...stop.data, 'deletionPending': true});
    await expectLater(
      service.saveCatalogue('routes', 'new_route', route.data),
      throwsStateError,
    );
  });
}
