import 'package:cloud_firestore/cloud_firestore.dart';

import 'bus.dart';
import 'station.dart';

/// Owner's original selected timetable. This never establishes current capability,
/// GPS, operation authority or the status of a replacement service.
class SavedScheduleSnapshot {
  SavedScheduleSnapshot({
    required List<String> stops,
    required Map<String, String> stationIds,
    required Map<String, String> names,
    required Map<String, DateTime?> times,
    this.runVersion,
  }) : stops = List.unmodifiable(stops),
       stationIds = Map.unmodifiable(stationIds),
       names = Map.unmodifiable(names),
       times = Map.unmodifiable(times);
  final List<String> stops;
  final Map<String, String> stationIds, names;
  final Map<String, DateTime?> times;
  final int? runVersion;

  factory SavedScheduleSnapshot.fromMap(Map<String, dynamic> d) {
    if (d['schemaVersion'] != 1) {
      throw const FormatException('Unknown saved timetable');
    }
    final stops = List<String>.from(d['stops'] as List);
    final ids = Map<String, String>.from(d['stationIds'] as Map);
    final names = Map<String, String>.from(d['names'] as Map);
    final raw = Map<String, dynamic>.from(d['times'] as Map);
    final version = d['runVersion'] as int?;
    if (stops.length < 2 ||
        stops.length > 300 ||
        stops.toSet().length != stops.length ||
        (version != null && version < 1) ||
        stops.any(
          (s) =>
              s.isEmpty ||
              s.contains('/') ||
              ids[s]?.isNotEmpty != true ||
              names[s]?.isNotEmpty != true ||
              names[s]!.length > 200 ||
              !raw.containsKey(s) ||
              (raw[s] != null && raw[s] is! Timestamp),
        )) {
      throw const FormatException('Invalid saved timetable');
    }
    return SavedScheduleSnapshot(
      stops: stops,
      stationIds: ids,
      names: names,
      times: {
        for (final s in stops) s: (raw[s] as Timestamp?)?.toDate().toUtc(),
      },
      runVersion: version,
    );
  }
  Map<String, dynamic> toMap() => {
    'schemaVersion': 1,
    'stops': stops,
    'stationIds': stationIds,
    'names': names,
    'times': {
      for (final e in times.entries)
        e.key: e.value == null ? null : Timestamp.fromDate(e.value!),
    },
    if (runVersion != null) 'runVersion': runVersion,
  };

  bool matches(Bus bus) {
    final first = bus.stops.indexOf(stops.first);
    return first >= 0 &&
        first + stops.length <= bus.stops.length &&
        List.generate(
          stops.length,
          (i) =>
              bus.stops[first + i] == stops[i] &&
              bus.stationIdFor(stops[i]) == stationIds[stops[i]],
        ).every((v) => v);
  }

  Bus historicalBus({
    required String id,
    required String routeId,
    required String routeNo,
    String? busNo,
  }) => Bus(
    id: id,
    routeId: routeId,
    routeNo: routeNo,
    busNo: busNo,
    stops: stops,
    stopStationIds: stationIds,
    hasRamp: false,
    lowFloor: false,
    occupancy: 'unknown',
  );
  Map<String, Station> historicalStations() => {
    for (final key in stops)
      key: Station(
        id: stationIds[key]!,
        name: names[key]!,
        lat: 0,
        lng: 0,
        hasElevator: false,
        hasRamp: false,
      ),
  };
}
