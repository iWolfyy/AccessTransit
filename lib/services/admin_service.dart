import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'sample_test_mode.dart';
import 'server_snapshot_stream.dart';
import '../logic/ordered_schedule.dart';
import '../models/service_run.dart';

class AdminRecord {
  const AdminRecord(this.kind, this.id, this.data);
  final String kind;
  final String id;
  final Map<String, dynamic> data;
  String text(String field) => data[field]?.toString() ?? '';
}

class AdminChange {
  const AdminChange(
    this.kind,
    this.id,
    this.before,
    this.after, {
    this.checkOnly = false,
  });
  final String kind;
  final String id;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;
  final bool checkOnly;
}

extension AdminRepositoryPages on AdminRepository {
  /// Explicit editor reference loading; never truncates a selector to page one.
  Future<List<AdminRecord>> referencePages(String kind) async {
    if (this is FirestoreAdminRepository) {
      return (this as FirestoreAdminRepository).referencePages(kind);
    }
    final items = <AdminRecord>[];
    final ids = <String>{}, cursors = <String>{};
    String? after;
    do {
      final result = await page(kind, after: after);
      items.addAll(result.items.where((r) => ids.add(r.id)));
      after = result.next;
      if (after != null && !cursors.add(after)) {
        throw StateError('Page cursor changed. Reload.');
      }
    } while (after != null);
    return items;
  }

  Future<({List<AdminRecord> items, String? next})> page(
    String kind, {
    String? after,
  }) async {
    if (this is FirestoreAdminRepository) {
      return (this as FirestoreAdminRepository).page(kind, after: after);
    }
    final rows = (await load(kind))
      ..sort(
        (a, b) => kind == 'admin_audit'
            ? b.text('createdAt').compareTo(a.text('createdAt')) == 0
                  ? b.id.compareTo(a.id)
                  : b.text('createdAt').compareTo(a.text('createdAt'))
            : a.id.compareTo(b.id),
      );
    final start = after == null ? 0 : rows.indexWhere((r) => r.id == after) + 1;
    if (after != null && start == 0) {
      throw StateError('Page cursor changed. Reload.');
    }
    final values = rows.skip(start).take(21).toList();
    return (
      items: values.take(20).toList(),
      next: values.length > 20 ? values[19].id : null,
    );
  }
}

abstract class AdminRepository {
  Stream<List<AdminRecord>> watch(String kind);
  Future<List<AdminRecord>> load(String kind);
  Future<void> commit(List<AdminChange> changes, String action);
}

class FirestoreAdminRepository implements AdminRepository {
  Future<List<AdminRecord>> referencePages(String kind) async {
    final owner = await _authorize(), scope = SampleTestMode.collection(kind);
    final records = <AdminRecord>[], seen = <String>{};
    final cursors = <String>{};
    String? after;
    do {
      final result = await page(kind, after: after);
      if (FirebaseAuth.instance.currentUser?.uid != owner ||
          SampleTestMode.collection(kind) != scope) {
        throw StateError('Account changed. Reload references.');
      }
      records.addAll(result.items.where((r) => seen.add(r.id)));
      after = result.next;
      if (after != null && !cursors.add(after)) {
        throw StateError('Page cursor changed. Reload.');
      }
    } while (after != null);
    return records;
  }

  Future<({List<AdminRecord> items, String? next})> page(
    String kind, {
    String? after,
  }) async {
    await _authorize();
    Query<Map<String, dynamic>> query = kind == 'admin_audit'
        ? _collection(kind)
              .orderBy('createdAt', descending: true)
              .orderBy(FieldPath.documentId, descending: true)
              .limit(21)
        : _collection(kind).orderBy(FieldPath.documentId).limit(21);
    if (after != null) {
      if (kind == 'admin_audit') {
        final cursor = await _collection(kind)
            .doc(after)
            .get(const GetOptions(source: Source.server));
        if (!cursor.exists) throw StateError('Page cursor changed. Reload.');
        query = query.startAfterDocument(cursor);
      } else {
        query = query.startAfter([after]);
      }
    }
    final result = await query.get(const GetOptions(source: Source.server));
    return (
      items: result.docs
          .take(20)
          .map((d) => AdminRecord(kind, d.id, d.data()))
          .toList(),
      next: result.docs.length > 20 ? result.docs[19].id : null,
    );
  }

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> _collection(String kind) =>
      _db.collection(SampleTestMode.collection(kind));

  Future<String> _authorize() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null ||
        (await user.getIdTokenResult(true)).claims?['admin'] != true) {
      throw StateError('Administrator access is required.');
    }
    if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
      throw StateError('Account changed. Sign in again.');
    }
    return user.uid;
  }

  @override
  Stream<List<AdminRecord>> watch(String kind) async* {
    await _authorize();
    final Query<Map<String, dynamic>> query = kind == 'admin_audit'
        ? _collection(kind)
              .orderBy('createdAt', descending: true)
              .orderBy(FieldPath.documentId, descending: true)
              .limit(21)
        : ['users', 'buses', 'routes', 'stations'].contains(kind)
        ? _collection(kind).orderBy(FieldPath.documentId).limit(21)
        : _collection(kind);
    yield* serverSnapshotStream(
      query.snapshots(includeMetadataChanges: true),
      isVerified: (s) =>
          !s.metadata.isFromCache && !s.metadata.hasPendingWrites,
    ).map((s) {
      return s.docs.map((d) => AdminRecord(kind, d.id, d.data())).toList();
    });
  }

  @override
  Future<List<AdminRecord>> load(String kind) async {
    await _authorize();
    final result = await _collection(kind)
        .get(const GetOptions(source: Source.server));
    return result.docs.map((d) => AdminRecord(kind, d.id, d.data())).toList();
  }

  @override
  Future<void> commit(List<AdminChange> changes, String action) async {
    final actor = await _authorize();
    final audit = _collection('admin_audit').doc();
    await _db.runTransaction((tx) async {
      for (final change in changes) {
        final current = await tx.get(_collection(change.kind).doc(change.id));
        if (!adminDataEqual(current.data(), change.before)) {
          throw StateError('This record changed. Reload it before saving.');
        }
      }
      for (final change in changes) {
        if (change.checkOnly) continue;
        final ref = _collection(change.kind).doc(change.id);
        if (change.after == null) {
          tx.delete(ref);
        } else {
          tx.set(ref, {
            ...change.after!,
            if (change.kind == 'operator_access') 'reviewedBy': actor,
            'updatedBy': actor,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      tx.set(audit, {
        'actorId': actor,
        'action': action,
        'createdAt': FieldValue.serverTimestamp(),
        'targets': changes
            .where((c) => !c.checkOnly)
            .map((c) => '${c.kind}/${c.id}')
            .toList(),
      });
    });
  }
}

bool adminDataEqual(dynamic a, dynamic b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every((k) => b.containsKey(k) && adminDataEqual(a[k], b[k]));
  }
  if (a is List && b is List) {
    return a.length == b.length &&
        List.generate(
          a.length,
          (i) => i,
        ).every((i) => adminDataEqual(a[i], b[i]));
  }
  return a == b;
}

/// Stable presentation metadata; the inherited English message preserves
/// diagnostic/test compatibility without requiring UI string parsing.
class AdminValidationException extends FormatException {
  const AdminValidationException(
    this.code,
    String message, {
    this.field,
    this.maximum,
  }) : super(message);
  final String code;
  final String? field;
  final int? maximum;
}

class AdminDependencyException extends StateError {
  AdminDependencyException(this.kind)
    : super(
        'Cannot delete: this record is referenced by $kind. Remove the dependency or retain it for history.',
      );
  final String kind;
}

class AdminService {
  AdminService(this.repository);
  final AdminRepository repository;
  static const catalogueKinds = ['buses', 'routes', 'stations'];
  static String requiredText(
    Map<String, dynamic> d,
    String field, [
    int max = 200,
  ]) {
    final text = d[field]?.toString().trim() ?? '';
    if (text.isEmpty || text.length > max) {
      throw AdminValidationException(
        'required-field',
        '$field is required (maximum $max characters).',
        field: field,
        maximum: max,
      );
    }
    return text;
  }

  static List<String> orderedStops(Map<String, dynamic> d) {
    final stops =
        (d['stops'] as List?)?.map((v) => v.toString()).toList() ?? [];
    if (stops.length < 2 || stops.toSet().length != stops.length) {
      throw const FormatException(
        'Select at least two distinct stops in travel order.',
      );
    }
    final mapping = Map<String, String>.from(d['stopStationIds'] as Map? ?? {});
    if (mapping.isNotEmpty &&
        (mapping.length != stops.length ||
            stops.any(
              (s) =>
                  !mapping.containsKey(s) ||
                  mapping[s]!.isEmpty ||
                  mapping[s]!.contains('/'),
            ) ||
            mapping.entries.any(
              (e) => e.key != e.value && mapping.values.contains(e.key),
            ))) {
      throw const FormatException(
        'Every stop occurrence requires an unambiguous physical station.',
      );
    }
    return stops;
  }

  static String stationIdFor(Map<String, dynamic> data, String occurrence) =>
      (data['stopStationIds'] as Map?)?[occurrence]?.toString() ?? occurrence;

  static void validate(String kind, Map<String, dynamic> d) {
    if (!catalogueKinds.contains(kind)) {
      throw ArgumentError('Unsupported catalogue');
    }
    final source = Uri.tryParse(requiredText(d, 'sourceUrl', 2048));
    if (source == null ||
        !['http', 'https'].contains(source.scheme) ||
        source.host.isEmpty) {
      throw const FormatException('Enter the catalogue source URL.');
    }
    if (kind == 'stations') {
      requiredText(d, 'name');
      for (final (field, limit) in [('lat', 90), ('lng', 180)]) {
        final value = d[field];
        if (value is! num ||
            !value.isFinite ||
            value < -limit ||
            value > limit) {
          throw AdminValidationException(
            'coordinate-invalid',
            'Enter valid $field coordinates.',
            field: field,
          );
        }
      }
    } else {
      requiredText(d, 'routeNo', 30);
      orderedStops(d);
      if (kind == 'routes') requiredText(d, 'routeName');
      if (kind == 'buses') {
        requiredText(d, 'routeId', 128);
        if (![
          'vehicle',
          'published_timetable',
        ].contains(d['catalogueRecordType'])) {
          throw const FormatException('Choose vehicle or published timetable.');
        }
        if (d['catalogueRecordType'] == 'vehicle') requiredText(d, 'busNo', 40);
        if (d['catalogueRecordType'] == 'published_timetable' &&
            (d['driverId'] ?? '') != '') {
          throw const FormatException(
            'A timetable cannot have a driver assignment.',
          );
        }
        final times = d['scheduleTimes'] as List? ?? [];
        if (times.length != (d['stops'] as List).length ||
            times.any(
              (t) =>
                  !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(t.toString()),
            )) {
          throw const FormatException(
            'Enter one HH:mm (24-hour) time per stop. Overnight times may roll over.',
          );
        }
      }
    }
  }

  Future<void> saveCatalogue(
    String kind,
    String id,
    Map<String, dynamic> data, {
    AdminRecord? original,
  }) async {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id)) {
      throw const FormatException(
        'Use letters, numbers, underscores or hyphens for the record ID.',
      );
    }
    validate(kind, data);
    if (original?.data['deletionPending'] == true) {
      throw StateError('Restore this record before editing it.');
    }
    final guards = <AdminChange>[];
    void guard(AdminRecord record) {
      if (record.data['deletionPending'] == true) {
        throw StateError(
          'A referenced record is pending deletion. Restore it or choose another record.',
        );
      }
      guards.add(
        AdminChange(
          record.kind,
          record.id,
          record.data,
          record.data,
          checkOnly: true,
        ),
      );
    }

    if (kind != 'stations') {
      final stations = await repository.load('stations');
      if (orderedStops(data)
          .any((id) => !stations.any((s) => s.id == stationIdFor(data, id)))) {
        throw const FormatException(
          'A selected stop no longer exists. Reload the form.',
        );
      }
      for (final station in stations.where(
        (s) =>
            orderedStops(data)
                .map((id) => stationIdFor(data, id))
                .contains(s.id),
      )) {
        guard(station);
      }
    }
    if (kind == 'routes' && original != null) {
      final stops = orderedStops(data);
      for (final bus in await repository.load('buses')) {
        if (bus.text('routeId') != id) continue;
        var previous = -1;
        for (final stop in List<String>.from(bus.data['stops'] ?? [])) {
          final index = stops.indexOf(stop);
          if (index <= previous ||
              data['routeNo'] != bus.data['routeNo'] ||
              stationIdFor(data, stop) != stationIdFor(bus.data, stop)) {
            throw StateError(
              'Update dependent buses before changing the route number or removing/reordering their stops.',
            );
          }
          previous = index;
        }
        guard(bus);
      }
    }
    if (kind == 'buses') {
      if (original != null &&
          orderedStops(data).any(
            (key) =>
                (original.data['stops'] as List).contains(key) &&
                stationIdFor(original.data, key) != stationIdFor(data, key),
          )) {
        throw StateError(
          'Existing stop occurrences cannot be rebound to another station. Use new occurrence IDs.',
        );
      }
      final routes = await repository.load('routes');
      final route = routes.where((r) => r.id == data['routeId']).firstOrNull;
      if (route == null || route.text('routeNo') != data['routeNo']) {
        throw const FormatException(
          'Choose an existing route with the same route number.',
        );
      }
      guard(route);
      final routeStops = List<String>.from(route.data['stops'] ?? []);
      var previous = -1;
      for (final stop in orderedStops(data)) {
        final index = routeStops.indexOf(stop);
        if (index <= previous ||
            stationIdFor(data, stop) != stationIdFor(route.data, stop)) {
          throw const FormatException(
            'Vehicle stops must follow the selected route order.',
          );
        }
        previous = index;
      }
      final driver = data['driverId']?.toString() ?? '';
      if (driver.isNotEmpty) {
        final access = await repository.load('operator_access');
        final users = await repository.load('users');
        if (!access.any((a) => a.id == driver && a.data['approved'] == true) ||
            !users.any((u) => u.id == driver && u.text('role') == 'operator')) {
          throw const FormatException(
            'Only an approved operator may be assigned.',
          );
        }
        guard(access.firstWhere((a) => a.id == driver));
        final assignment = (await repository.load('driver_route_assignments'))
            .where((a) => a.id == driver)
            .firstOrNull;
        if (assignment == null ||
            assignment.data['active'] != true ||
            assignment.text('routeId') != data['routeId']) {
          throw const FormatException(
            'Assign the approved driver to this route first.',
          );
        }
        guard(assignment);
        guards.add(
          AdminChange('driver_route_assignments', driver, assignment.data, {
            ...assignment.data,
            'claimRevision':
                (assignment.data['claimRevision'] as int? ?? 0) + 1,
            'lastClaimedBusId': id,
          }),
        );
      }
      // Never reassign a bus while a trip/broadcast is active.
      if (original != null &&
          (original.data['driverId'] != data['driverId'] ||
              !listEquals(
                original.data['stops'] as List?,
                data['stops'] as List?,
              ) ||
              original.text('routeId') != data['routeId'])) {
        guards.add(await _requireStopped(id));
      }
    }
    await repository.commit([
      ...guards,
      AdminChange(kind, id, original?.data, {
        ...?original?.data,
        ...data,
        if (kind != 'stations')
          'physicalStopIds': orderedStops(data)
              .map((s) => stationIdFor(data, s))
              .toList(),
        'catalogueSource': 'operator_catalogue',
        'isDemo': false,
      }),
    ], original == null ? 'create_$kind' : 'update_$kind');
  }

  Future<AdminChange> _requireStopped(String busId) async {
    final trips = await repository.load('trips');
    final live = await repository.load('live_locations');
    if (trips.any(
          (t) => t.text('busId') == busId && t.text('status') == 'in_progress',
        ) ||
        live.any((l) => l.id == busId && l.data['isBroadcasting'] == true)) {
      throw StateError(
        'This bus has an active trip or broadcast. End it before changing assignment, route or stops.',
      );
    }
    final telemetry = live.where((l) => l.id == busId).firstOrNull;
    // Read this in the commit transaction too: a simultaneous acknowledged start
    // writes this document and must invalidate the stopped-state check.
    return AdminChange(
      'live_locations',
      busId,
      telemetry?.data,
      telemetry?.data,
      checkOnly: true,
    );
  }

  Future<void> _checkDeleteDependencies(AdminRecord record) async {
    final checks = switch (record.kind) {
      'stations' => [
        ('routes', 'stops'),
        ('routes', 'physicalStopIds'),
        ('buses', 'stops'),
        ('buses', 'physicalStopIds'),
        ('journeys', 'fromStationId'),
        ('journeys', 'toStationId'),
        ('boarding_requests', 'stationId'),
        ('reports', 'targetId'),
        ('service_runs', 'stops'),
        ('service_runs', 'physicalStopIds'),
        ('service_schedules', 'stops'),
        ('service_schedules', 'physicalStopIds'),
      ],
      'routes' => [
        ('buses', 'routeId'),
        ('journeys', 'routeId'),
        ('driver_route_assignments', 'routeId'),
        ('service_runs', 'routeId'),
        ('service_schedules', 'routeId'),
      ],
      'buses' => [
        ('journeys', 'busId'),
        ('trips', 'busId'),
        ('boarding_requests', 'busId'),
        ('reports', 'targetId'),
        ('service_runs', 'busId'),
        ('service_schedules', 'busId'),
      ],
      _ => throw ArgumentError('Unsupported catalogue'),
    };
    if (record.kind == 'buses') await _requireStopped(record.id);
    for (final (kind, field) in checks) {
      final records = await repository.load(kind);
      if (records.any(
        (r) => r.data[field] is List
            ? (r.data[field] as List).contains(record.id)
            : r.data[field] == record.id,
      )) {
        throw AdminDependencyException(kind);
      }
    }
  }

  Future<void> deleteCatalogue(AdminRecord record) async {
    await _checkDeleteDependencies(record);
    // Withdraw the target from new references before the final dependency read.
    // The matching backend rule rejects new passenger/operator references.
    if (record.data['deletionPending'] != true) {
      await repository.commit([
        AdminChange(record.kind, record.id, record.data, {
          ...record.data,
          'deletionPending': true,
        }),
      ], 'prepare_delete_${record.kind}');
    }
    final pending = (await repository.load(record.kind))
        .firstWhere((r) => r.id == record.id);
    await _checkDeleteDependencies(pending);
    await repository.commit([
      AdminChange(pending.kind, pending.id, pending.data, null),
    ], 'delete_${record.kind}');
  }

  Future<void> restoreCatalogue(AdminRecord record) async {
    if (!catalogueKinds.contains(record.kind) ||
        record.data['deletionPending'] != true) {
      throw StateError('This record is not pending deletion.');
    }
    await repository.commit([
      AdminChange(record.kind, record.id, record.data, {
        ...record.data,
        'deletionPending': false,
      }),
    ], 'restore_${record.kind}');
  }

  Future<void> reviewOperator(
    AdminRecord user,
    String decision,
    String note,
  ) async {
    if (user.text('role') != 'operator' ||
        !['approved', 'rejected', 'revoked'].contains(decision) ||
        note.trim().length < 10 ||
        note.length > 2000) {
      throw const FormatException(
        'Select an operator and enter a review/reason of 10-2000 characters.',
      );
    }
    final access = await repository.load('operator_access');
    final existing = access.where((a) => a.id == user.id).firstOrNull;
    final changes = <AdminChange>[];
    if (decision != 'approved') {
      final assignment = (await repository.load('driver_route_assignments'))
          .where((a) => a.id == user.id)
          .firstOrNull;
      if (assignment != null) {
        changes.add(
          AdminChange('driver_route_assignments', user.id, assignment.data, {
            ...assignment.data,
            'active': false,
          }),
        );
      }
      for (final bus in await repository.load('buses')) {
        if (bus.text('driverId') != user.id) continue;
        // Transfer an active operation before withdrawing its driver's authority.
        changes.add(await _requireStopped(bus.id));
        changes.add(
          AdminChange('buses', bus.id, bus.data, {...bus.data, 'driverId': ''}),
        );
      }
    }
    changes.add(AdminChange('users', user.id, user.data, user.data));
    changes.add(
      AdminChange('operator_access', user.id, existing?.data, {
        ...?existing?.data,
        'approved': decision == 'approved',
        'status': decision,
        'reviewNote': note.trim(),
        'reviewedAt': FieldValue.serverTimestamp(),
      }),
    );
    await repository.commit(changes, 'operator_$decision');
  }

  /// Route grants are independent from approval. Changing a grant withdraws old
  /// bus claims; active operations must be ended/reconciled first.
  Future<void> assignDriverRoute(
    AdminRecord user,
    String? routeId,
    String note,
  ) async {
    if (user.text('role') != 'operator' ||
        note.trim().length < 10 ||
        note.length > 2000) {
      throw const FormatException(
        'Select a driver and enter a reason of 10-2000 characters.',
      );
    }
    final approval = (await repository.load('operator_access'))
        .where((a) => a.id == user.id)
        .firstOrNull;
    if (routeId != null && approval?.data['approved'] != true) {
      throw StateError('Approve the driver before assigning a route.');
    }
    final existing = (await repository.load('driver_route_assignments'))
        .where((a) => a.id == user.id)
        .firstOrNull;
    final changes = <AdminChange>[
      AdminChange('users', user.id, user.data, user.data, checkOnly: true),
    ];
    if (approval != null) {
      changes.add(
        AdminChange(
          'operator_access',
          user.id,
          approval.data,
          approval.data,
          checkOnly: true,
        ),
      );
    }
    if (routeId != null) {
      final route = (await repository.load('routes'))
          .where((r) => r.id == routeId)
          .firstOrNull;
      if (route == null ||
          route.data['deletionPending'] == true ||
          route.data['isDemo'] == true ||
          route.text('catalogueSource') == 'demo') {
        throw StateError('Choose an available reviewed route.');
      }
      changes.add(
        AdminChange(
          'routes',
          route.id,
          route.data,
          route.data,
          checkOnly: true,
        ),
      );
    }
    if (existing?.text('routeId') != routeId ||
        existing?.data['active'] != (routeId != null)) {
      for (final bus in await repository.load('buses')) {
        if (bus.text('driverId') != user.id) continue;
        changes.add(await _requireStopped(bus.id));
        changes.add(
          AdminChange('buses', bus.id, bus.data, {...bus.data, 'driverId': ''}),
        );
      }
    }
    changes.add(
      AdminChange('driver_route_assignments', user.id, existing?.data, {
        ...?existing?.data,
        'driverId': user.id,
        'routeId': routeId ?? existing?.text('routeId') ?? '',
        'active': routeId != null,
        'assignmentNote': note.trim(),
      }),
    );
    await repository.commit(
      changes,
      routeId == null ? 'driver_route_removed' : 'driver_route_assigned',
    );
  }

  Future<void> scheduleServiceRun(
    AdminRecord bus,
    DateTime civilDate, {
    int? departureMinutes,
  }) async {
    await repository.commit(
      await _prepareServiceRun(
        bus,
        civilDate,
        departureMinutes: departureMinutes,
      ),
      'schedule_service_run',
    );
  }

  /// Immutable reviewed calendar. Replacements get a new ID; retiring one never
  /// cancels a run which passengers or drivers may already be using.
  Future<void> publishServiceSchedule(
    AdminRecord bus, {
    required DateTime from,
    required DateTime until,
    required Set<int> weekdays,
    required int departureMinutes,
  }) async {
    final start = DateTime.utc(from.year, from.month, from.day);
    final end = DateTime.utc(until.year, until.month, until.day);
    if (end.isBefore(start) ||
        end.difference(start).inDays > 30 ||
        weekdays.isEmpty ||
        weekdays.any((d) => d < 1 || d > 7)) {
      throw const FormatException(
        'Choose weekdays and a date range of at most 31 days.',
      );
    }
    final checks = await _prepareServiceRun(
      bus,
      start,
      departureMinutes: departureMinutes,
    );
    final id = 'calendar_${bus.id}_${DateTime.now().microsecondsSinceEpoch}';
    await repository.commit([
      ...checks.where((c) => c.checkOnly),
      AdminChange('service_schedules', id, null, {
        'schemaVersion': 1,
        'stops': orderedStops(bus.data),
        'physicalStopIds': orderedStops(bus.data)
            .map((s) => stationIdFor(bus.data, s))
            .toList(),
        'version': 1,
        'state': 'published',
        'busId': bus.id,
        'routeId': bus.text('routeId'),
        'from': Timestamp.fromDate(start),
        'until': Timestamp.fromDate(end),
        'weekdays': weekdays.toList()..sort(),
        'departureMinutes': departureMinutes,
        'timezone': 'Asia/Colombo',
        'busSnapshot': Map<String, dynamic>.from(bus.data),
      }),
    ], 'publish_service_schedule');
  }

  Future<void> retireServiceSchedule(AdminRecord calendar) async {
    if (calendar.kind != 'service_schedules' ||
        calendar.text('state') != 'published') {
      throw StateError('Reload the published calendar.');
    }
    await repository.commit([
      AdminChange(calendar.kind, calendar.id, calendar.data, {
        ...calendar.data,
        'state': 'retired',
      }),
    ], 'retire_service_schedule');
  }

  /// Explicit bounded materialization; repeated generation preserves every
  /// existing run, including cancelled/completed runs and one-off departures.
  Future<({int created, int preserved})> generateServiceSchedule(
    AdminRecord calendar,
  ) async {
    if (calendar.kind != 'service_schedules' ||
        calendar.text('state') != 'published') {
      throw StateError('Only a published calendar can generate departures.');
    }
    final d = calendar.data;
    final start = (d['from'] as Timestamp).toDate().toUtc();
    final end = (d['until'] as Timestamp).toDate().toUtc();
    final days = Set<int>.from(d['weekdays'] as List);
    if (end.isBefore(start) ||
        end.difference(start).inDays > 30 ||
        days.isEmpty ||
        days.any((v) => v < 1 || v > 7)) {
      throw const FormatException(
        'Invalid calendar. Publish a reviewed replacement.',
      );
    }
    final bus = (await repository.load('buses'))
        .where((b) => b.id == calendar.text('busId'))
        .firstOrNull;
    final snapshot = Map<String, dynamic>.from(d['busSnapshot'] as Map);
    if (bus == null ||
        [
          'routeId',
          'routeNo',
          'stops',
          'scheduleTimes',
          'stopStationIds',
          'catalogueRecordType',
        ].any((k) => !adminDataEqual(bus.data[k], snapshot[k]))) {
      throw StateError(
        'The bus timetable changed. Publish a reviewed replacement calendar.',
      );
    }
    final existing = {
      for (final r in await repository.load('service_runs')) r.id: r,
    };
    final changes = <AdminChange>[
      AdminChange(calendar.kind, calendar.id, d, d, checkOnly: true),
    ];
    var created = 0, preserved = 0;
    for (
      var date = start;
      !date.isAfter(end);
      date = date.add(const Duration(days: 1))
    ) {
      if (!days.contains(date.weekday)) continue;
      final prepared = await _prepareServiceRun(
        bus,
        date,
        departureMinutes: d['departureMinutes'] as int,
      );
      for (final c in prepared) {
        if (c.checkOnly) {
          if (!changes.any((v) => v.kind == c.kind && v.id == c.id)) {
            changes.add(c);
          }
        } else {
          final prior = existing[c.id];
          if (prior != null) {
            preserved++;
            changes.add(
              AdminChange(
                c.kind,
                c.id,
                prior.data,
                prior.data,
                checkOnly: true,
              ),
            );
          } else {
            created++;
            changes.add(
              AdminChange(c.kind, c.id, null, {
                ...c.after!,
                'scheduleId': calendar.id,
                'scheduleVersion': d['version'],
              }),
            );
          }
        }
      }
    }
    await repository.commit(changes, 'generate_service_schedule');
    return (created: created, preserved: preserved);
  }

  Future<List<AdminChange>> _prepareServiceRun(
    AdminRecord bus,
    DateTime civilDate, {
    int? departureMinutes,
  }) async {
    if (departureMinutes != null &&
        (departureMinutes < 0 || departureMinutes >= 1440)) {
      throw const FormatException('Choose a valid Colombo departure time.');
    }
    if (bus.kind != 'buses' ||
        bus.text('catalogueRecordType') != 'vehicle' ||
        bus.data['deletionPending'] == true ||
        bus.data['isDemo'] == true ||
        bus.text('catalogueSource') == 'demo') {
      throw const FormatException('Choose an available physical bus.');
    }
    final stops = orderedStops(bus.data);
    final date = DateTime.utc(civilDate.year, civilDate.month, civilDate.day);
    final schedule = OrderedSchedule.build(
      stopCount: stops.length,
      scheduleTimes: List<String>.from(
        bus.data['scheduleTimes'] as List? ?? [],
      ),
      serviceDate: date,
      fallbackDeparture: date,
      utcCivil: true,
    );
    if (schedule == null || schedule.usesEstimates) {
      throw const FormatException(
        'A complete reviewed timetable is required for a dated run.',
      );
    }
    final route = (await repository.load('routes'))
        .where((r) => r.id == bus.text('routeId'))
        .firstOrNull;
    if (route == null || route.data['deletionPending'] == true) {
      throw StateError('Route unavailable.');
    }
    final start = departureMinutes == null
        ? schedule.times.first
        : DateTime.utc(
            date.year,
            date.month,
            date.day,
            departureMinutes ~/ 60,
            departureMinutes % 60,
          );
    final shift = start.difference(schedule.times.first);
    final times = schedule.times
        .map((t) => ServiceRun.colomboCivilToUtc(t.add(shift)))
        .toList();
    final id = 'run_${bus.id}_${times.first.millisecondsSinceEpoch}';
    final serviceDate =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return [
      AdminChange('buses', bus.id, bus.data, bus.data, checkOnly: true),
      AdminChange('routes', route.id, route.data, route.data, checkOnly: true),
      AdminChange('service_runs', id, null, {
        'busId': bus.id,
        'routeId': route.id,
        'routeNo': bus.text('routeNo'),
        'serviceDate': serviceDate,
        'timezone': 'Asia/Colombo',
        'scheduleVersion': 1,
        'plannedDepartureAt': Timestamp.fromDate(times.first),
        'latestStartAt': Timestamp.fromDate(
          times.first.add(ServiceRun.maximumLateStart),
        ),
        'stops': stops,
        'physicalStopIds': stops.map((s) => stationIdFor(bus.data, s)).toList(),
        if (bus.data['stopStationIds'] != null)
          'stopStationIds': bus.data['stopStationIds'],
        'status': 'scheduled',
        'initialStopTimes': {
          for (var i = 0; i < stops.length; i++)
            stops[i]: {
              'estimatedArrival': Timestamp.fromDate(times[i]),
              'actualArrival': null,
            },
        },
      }),
    ];
  }

  /// Cancel and publish the linked replacement atomically. Started operations
  /// cannot be rescheduled here; exact snapshots reject concurrent starts.
  Future<void> rescheduleServiceRun(
    AdminRecord previous,
    DateTime date, {
    required int departureMinutes,
    required String publicReason,
  }) async {
    final reason = publicReason.trim();
    if (previous.kind != 'service_runs' ||
        !['scheduled', 'cancelled'].contains(previous.text('status')) ||
        previous.data['replacementRunId'] != null ||
        reason.length < 5 ||
        reason.length > 300) {
      throw StateError(
        'Choose an unreplaced, not-started run and a public reason (5–300 characters).',
      );
    }
    final bus = (await repository.load('buses'))
        .where((b) => b.id == previous.text('busId'))
        .firstOrNull;
    if (bus == null) {
      throw StateError('Review the current physical bus timetable first.');
    }
    final changes = await _prepareServiceRun(
      bus,
      date,
      departureMinutes: departureMinutes,
    );
    final replacement = changes.singleWhere((c) => !c.checkOnly);
    if (replacement.id == previous.id) {
      throw StateError('Choose a different departure time.');
    }
    final oldVersion = previous.data['scheduleVersion'] as int? ?? 1;
    if (oldVersion < 1) {
      throw StateError('Review the original schedule version.');
    }
    final trip = (await repository.load('trips'))
        .where((t) => t.id == previous.id)
        .firstOrNull;
    if (trip?.text('status') == 'in_progress') {
      throw StateError('Reconcile the active operation first.');
    }
    await repository.commit([
      ...changes.where((c) => c.checkOnly),
      AdminChange(
        'trips',
        previous.id,
        trip?.data,
        trip?.data,
        checkOnly: true,
      ),
      AdminChange(previous.kind, previous.id, previous.data, {
        ...previous.data,
        'status': 'cancelled',
        'replacementRunId': replacement.id,
        'replacementDepartureAt': replacement.after!['plannedDepartureAt'],
        'changeReason': reason,
      }),
      AdminChange(replacement.kind, replacement.id, null, {
        ...replacement.after!,
        'scheduleVersion': oldVersion + 1,
        'replacesRunId': previous.id,
        'changeReason': reason,
      }),
      AdminChange('service_run_changes', previous.id, null, {
        'previousRunId': previous.id,
        'replacementRunId': replacement.id,
        'previousDepartureAt': previous.data['plannedDepartureAt'],
        'replacementDepartureAt': replacement.after!['plannedDepartureAt'],
        'previousVersion': oldVersion,
        'replacementVersion': oldVersion + 1,
        'busId': bus.id,
        'reason': reason,
      }),
    ], 'reschedule_service_run');
  }

  Future<void> cancelScheduledRun(AdminRecord run) async {
    if (run.kind != 'service_runs' || run.text('status') != 'scheduled') {
      throw StateError('Only a not-started run can be cancelled here.');
    }
    await repository.commit([
      AdminChange(run.kind, run.id, run.data, {
        ...run.data,
        'status': 'cancelled',
      }),
    ], 'cancel_scheduled_run');
  }

  Future<void> updateUser(AdminRecord user, String name, String phone) async {
    if (name.trim().isEmpty || name.trim().length > 100 || phone.length > 40) {
      throw const FormatException(
        'Enter a name (up to 100 characters) and phone (up to 40).',
      );
    }
    await repository.commit([
      AdminChange('users', user.id, user.data, {
        ...user.data,
        'name': name.trim(),
        'phone': phone.trim(),
      }),
    ], 'update_user');
  }
}
