import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/bus.dart';
import '../models/bus_location_model.dart';
import '../models/service_run.dart';
import '../models/trip_model.dart';
import 'route_geometry.dart';

/// Local diagnostics only. References are acknowledged driver-reported arrivals,
/// not independently observed physical arrival or server-confirmation timestamps.
class EtaEvaluationLedger {
  static const maxRecords = 500;
  static const retention = Duration(days: 7);
  final records = <Map<String, dynamic>>[];
  int dropped = 0;
  void observe({
    required Bus bus,
    required ServiceRun run,
    required TripModel trip,
    required DateTime now,
    BusLocationModel? gps,
    ReviewedRouteGeometry? geometry,
  }) {
    if (run.busId != bus.id ||
        run.routeId != bus.routeId ||
        trip.tripId != run.id ||
        trip.serviceRunId != run.id ||
        trip.busId != bus.id ||
        trip.driverId != bus.driverId ||
        trip.scheduledDepartureTime?.toUtc() !=
            run.plannedDepartureAt.toUtc() ||
        !listEquals(trip.stops, bus.stops) ||
        !listEquals(run.stopTimes.keys.toList(), bus.stops)) {
      return;
    }
    records.removeWhere(
      (r) => now.difference(DateTime.parse(r['observedAt'])) > retention,
    );
    for (final r in records.where(
      (r) => r['runId'] == run.id && r['busId'] == bus.id,
    )) {
      final actual = trip.stopTimes[r['stopId']]?.actualArrival?.toUtc();
      if (actual != null) {
        final observed = DateTime.parse(r['observedAt']);
        if (r['actualArrival'] != null &&
            r['actualArrival'] != actual.toIso8601String()) {
          r['excluded'] = 'arrival-corrected';
        } else if (actual.isAfter(now)) {
          r['excluded'] = 'future-driver-arrival';
        } else if (!actual.isAfter(observed)) {
          r['excluded'] = 'arrival-not-after-prediction';
        } else if (r['excluded'] == null) {
          r['actualArrival'] = actual.toIso8601String();
          r['matchedAt'] ??= now.toUtc().toIso8601String();
        }
      } else if (r['actualArrival'] != null) {
        r['excluded'] = 'arrival-removed';
      } else if (run.status == 'cancelled' || trip.status == 'cancelled') {
        r['excluded'] ??= 'cancelled';
      } else if (run.status == 'completed' || trip.status == 'completed') {
        if (r['actualArrival'] == null) {
          r['excluded'] ??= 'missing-terminal-arrival';
        }
      }
    }
    if (run.status != 'in_progress' ||
        !trip.isInProgress ||
        trip.actualDepartureTime == null ||
        trip.actualDepartureTime!.isAfter(now) ||
        trip.currentStopIndex < 0 ||
        trip.currentStopIndex >= bus.stops.length - 1 ||
        gps == null ||
        gps.busId != bus.id ||
        gps.tripId != run.id ||
        gps.driverId != trip.driverId ||
        gps.isCached ||
        !gps.isBroadcasting ||
        !['active', 'stopped'].contains(gps.status.value) ||
        gps.timestamp == null ||
        now.difference(gps.timestamp!) < Duration.zero ||
        now.difference(gps.timestamp!) > const Duration(seconds: 30) ||
        !gps.latitude.isFinite ||
        !gps.longitude.isFinite ||
        gps.latitude.abs() > 90 ||
        gps.longitude.abs() > 180 ||
        (gps.latitude == 0 && gps.longitude == 0) ||
        !gps.speed.isFinite ||
        gps.speed < 0 ||
        gps.speed > 130) {
      return;
    }
    final minute = now.toUtc().millisecondsSinceEpoch ~/ 60000;
    for (final target in bus.stops.skip(trip.currentStopIndex + 1)) {
      if (trip.stopTimes[target]?.actualArrival != null) continue;
      final estimate = geometry == null
          ? null
          : RouteProgressEta.estimate(
              geometry: geometry,
              run: run,
              trip: trip,
              gps: gps,
              target: target,
              now: now,
            );
      for (final source in [
        'timetable',
        if (estimate != null) 'geometry-timetable',
      ]) {
        final id = jsonEncode([run.id, target, source, minute]);
        if (records.any((r) => r['id'] == id)) continue;
        final live = source == 'geometry-timetable';
        records.add({
          'id': id,
          'runId': run.id,
          'busId': bus.id,
          'routeId': run.routeId,
          'serviceDate': run.serviceDate,
          'stopId': target,
          'source': source,
          'algorithmVersion': live ? 'road-timetable-v1' : 'dated-timetable-v1',
          'geometryVersion': live ? estimate!.geometryVersion : null,
          'observedAt': now.toUtc().toIso8601String(),
          'predictedArrival':
              (live ? estimate!.arrival : run.stopTimes[target]!)
                  .toUtc()
                  .toIso8601String(),
          'earliest': live
              ? estimate!.earliest.toUtc().toIso8601String()
              : null,
          'latest': live ? estimate!.latest.toUtc().toIso8601String() : null,
          'reference': 'acknowledged-driver-reported-arrival',
          'synthetic': true,
        });
        if (records.length > maxRecords) {
          records.removeAt(0);
          dropped++;
        }
      }
    }
  }

  /// Balance observations: first forecast per run/stop/source/actual lead bucket,
  /// rather than weighting a bus more because its screen was rebuilt more often.
  List<Map<String, dynamic>> scored() {
    final chosen = <String, Map<String, dynamic>>{};
    final ordered =
        records
            .where((r) => r['actualArrival'] != null && r['excluded'] == null)
            .toList()
          ..sort((a, b) => a['observedAt'].compareTo(b['observedAt']));
    for (final r in ordered) {
      final lead = DateTime.parse(r['actualArrival'])
          .difference(DateTime.parse(r['observedAt']))
          .inSeconds;
      final bucket = lead <= 300
          ? '0-5m'
          : lead <= 900
          ? '5-15m'
          : lead <= 1800
          ? '15-30m'
          : '30m+';
      chosen.putIfAbsent(
        jsonEncode([r['runId'], r['stopId'], r['source'], bucket]),
        () => {...r, 'leadBucket': bucket},
      );
    }
    return chosen.values.toList();
  }

  List<Map<String, dynamic>> summaries() {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final r in scored()) {
      final key = jsonEncode([
        r['source'],
        r['algorithmVersion'],
        r['geometryVersion'],
        r['routeId'],
        r['leadBucket'],
      ]);
      groups.putIfAbsent(key, () => []).add(r);
    }
    return groups.values.map((rows) {
      final errors = rows
          .map(
            (r) =>
                DateTime.parse(r['predictedArrival'])
                    .difference(DateTime.parse(r['actualArrival']))
                    .inMilliseconds /
                1000,
          )
          .toList();
      final absolute = errors.map((e) => e.abs()).toList()..sort();
      final n = absolute.length, mid = n ~/ 2;
      final intervals = rows
          .where((r) => r['earliest'] != null && r['latest'] != null)
          .toList();
      final covered = intervals.where((r) {
        final at = DateTime.parse(r['actualArrival']);
        return !at.isBefore(DateTime.parse(r['earliest'])) &&
            !at.isAfter(DateTime.parse(r['latest']));
      }).length;
      return <String, dynamic>{
        for (final k in [
          'source',
          'algorithmVersion',
          'geometryVersion',
          'routeId',
          'leadBucket',
        ])
          k: rows.first[k],
        'count': n,
        'distinctRuns': rows.map((r) => r['runId']).toSet().length,
        'medianAbsoluteErrorSeconds': n.isOdd
            ? absolute[mid]
            : (absolute[mid - 1] + absolute[mid]) / 2,
        'p90AbsoluteErrorSeconds': absolute[math.max(0, (n * 0.9).ceil() - 1)],
        'meanSignedErrorSeconds': errors.reduce((a, b) => a + b) / n,
        'intervalCount': intervals.length,
        'intervalCovered': covered,
        'smallSample': n < 20,
      };
    }).toList();
  }

  Map<String, dynamic> export() => {
    'schemaVersion': 1,
    'synthetic': true,
    'reference':
        'acknowledged-driver-reported-arrival; not independent ground truth',
    'sampling': 'first observation per run/stop/source/actual-lead bucket; at most one capture per minute',
    'counts': {
      'captured': records.length,
      'pending': records
          .where((r) => r['actualArrival'] == null && r['excluded'] == null)
          .length,
      'excluded': records.where((r) => r['excluded'] != null).length,
      'droppedAtCapacity': dropped,
    },
    'summaries': summaries(),
    'records': records,
  };

  void restore(String raw) {
    final d = jsonDecode(raw);
    if (d is! Map ||
        d['schemaVersion'] != 1 ||
        d['synthetic'] != true ||
        d['records'] is! List ||
        (d['records'] as List).length > maxRecords) {
      throw const FormatException();
    }
    final restored = <Map<String, dynamic>>[];
    for (final value in d['records']) {
      final r = Map<String, dynamic>.from(value);
      for (final key in [
        'id',
        'runId',
        'busId',
        'routeId',
        'stopId',
        'source',
        'algorithmVersion',
      ]) {
        if (r[key] is! String ||
            (r[key] as String).isEmpty ||
            (r[key] as String).length > 1024) {
          throw const FormatException();
        }
      }
      if (!['timetable', 'geometry-timetable'].contains(r['source']) ||
          r['synthetic'] != true) {
        throw const FormatException();
      }
      if (r['observedAt'] is! String ||
          r['predictedArrival'] is! String ||
          (r['earliest'] == null) != (r['latest'] == null)) {
        throw const FormatException();
      }
      for (final key in [
        'observedAt',
        'predictedArrival',
        'actualArrival',
        'earliest',
        'latest',
        'matchedAt',
      ]) {
        if (r[key] != null && !DateTime.parse(r[key]).isUtc) {
          throw const FormatException('Use timestamp offsets or UTC');
        }
      }
      if (r['earliest'] != null &&
          DateTime.parse(r['earliest']).isAfter(DateTime.parse(r['latest']))) {
        throw const FormatException('Invalid prediction interval');
      }
      if (r['actualArrival'] != null) {
        final actual = DateTime.parse(r['actualArrival']);
        if (!actual.isAfter(DateTime.parse(r['observedAt']))) {
          r['excluded'] ??= 'arrival-not-after-prediction';
        } else if (r['matchedAt'] != null &&
            actual.isAfter(DateTime.parse(r['matchedAt']))) {
          r['excluded'] ??= 'future-driver-arrival';
        }
      }
      restored.add(r);
    }
    if (restored.map((r) => r['id']).toSet().length != restored.length) {
      throw const FormatException();
    }
    records
      ..clear()
      ..addAll(restored);
    dropped = d['counts']?['droppedAtCapacity'] is int
        ? d['counts']['droppedAtCapacity']
        : 0;
  }
}
