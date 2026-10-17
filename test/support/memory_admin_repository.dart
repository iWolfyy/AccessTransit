import 'dart:async';

import 'package:access_transit/services/admin_service.dart';

class MemoryAdminRepository implements AdminRepository {
  final data = <String, Map<String, AdminRecord>>{};
  final _updates = <String, StreamController<List<AdminRecord>>>{};
  bool denyWrites = false;
  bool failReads = false;
  final actions = <String>[];
  void Function(String action)? afterCommit;
  void Function(List<AdminChange> changes, String action)? beforeCommit;
  void seed(String kind, String id, Map<String, dynamic> value) {
    data.putIfAbsent(kind, () => {})[id] = AdminRecord(kind, id, Map.of(value));
    _updates[kind]?.add(data[kind]!.values.toList());
  }

  AdminRecord get(String kind, String id) => data[kind]![id]!;
  @override
  Future<List<AdminRecord>> load(String kind) async {
    if (failReads) throw StateError('offline');
    return data[kind]?.values.toList() ?? [];
  }

  @override
  Stream<List<AdminRecord>> watch(String kind) async* {
    yield await load(kind);
    yield* _updates
        .putIfAbsent(kind, () => StreamController.broadcast())
        .stream;
  }

  void failStream(String kind) =>
      _updates[kind]?.addError(StateError('permission denied'));
  @override
  Future<void> commit(List<AdminChange> changes, String action) async {
    if (denyWrites) throw StateError('permission denied');
    beforeCommit?.call(changes, action);
    for (final change in changes) {
      if (!adminDataEqual(data[change.kind]?[change.id]?.data, change.before)) {
        throw StateError('This record changed. Reload it before saving.');
      }
    }
    for (final change in changes) {
      if (change.checkOnly) continue;
      if (change.after == null) {
        data[change.kind]?.remove(change.id);
        _updates[change.kind]?.add(data[change.kind]?.values.toList() ?? []);
      } else {
        seed(change.kind, change.id, change.after!);
      }
    }
    actions.add(action);
    afterCommit?.call(action);
  }

  Future<void> dispose() async {
    for (final stream in _updates.values) {
      await stream.close();
    }
  }
}

MemoryAdminRepository adminFixture() => MemoryAdminRepository()
  ..seed('stations', 's1', {
    'name': 'Fort Main Boarding Stop',
    'lat': 6.9,
    'lng': 79.8,
    'sourceUrl': 'https://example.test/stops',
  })
  ..seed('stations', 's2', {
    'name': 'Kandy Central Boarding Stop',
    'lat': 7.2,
    'lng': 80.6,
    'sourceUrl': 'https://example.test/stops',
  })
  ..seed('routes', 'r1', {
    'routeNo': '1',
    'routeName': 'Fort to Kandy',
    'stops': ['s1', 's2'],
    'sourceUrl': 'https://example.test/routes',
  })
  ..seed('buses', 'b1', {
    'routeNo': '1',
    'routeId': 'r1',
    'busNo': 'WP NA-1234',
    'stops': ['s1', 's2'],
    'scheduleTimes': ['23:50', '00:10'],
    'driverId': '',
    'catalogueRecordType': 'vehicle',
    'sourceUrl': 'https://example.test/buses',
  })
  ..seed('users', 'driver', {
    'name': 'Pending Driver',
    'email': 'driver@example.test',
    'role': 'operator',
    'phone': '0771234567',
  })
  ..seed('users', 'rider', {
    'name': 'Passenger',
    'email': 'rider@example.test',
    'role': 'passenger',
  });
