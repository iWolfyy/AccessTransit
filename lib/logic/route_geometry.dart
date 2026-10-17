import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/bus_location_model.dart';
import '../models/service_run.dart';
import '../models/trip_model.dart';

/// Administrator-reviewed directed road path. Stop vertices identify occurrences,
/// rather than projecting stop names or joining stations with straight lines.
class ReviewedRouteGeometry {
  ReviewedRouteGeometry._(
    this.routeId,
    this.version,
    this.source,
    this.synthetic,
    this.stops,
    this.vertices,
    this.points,
    this.distances,
  );
  final String routeId, version, source;
  final bool synthetic;
  final List<String> stops;
  final List<int> vertices;
  final List<LatLng> points;
  final List<double> distances;

  factory ReviewedRouteGeometry.parse(String routeId, Map<String, dynamic> d) {
    final source = Uri.tryParse(d['source']?.toString() ?? '');
    if (d['reviewed'] != true ||
        d['synthetic'] is! bool ||
        d['routeId'] != routeId ||
        routeId.isEmpty ||
        routeId.contains('/') ||
        d['version'] is! String ||
        (d['version'] as String).trim().isEmpty ||
        (d['version'] as String).length > 128 ||
        source?.scheme != 'https' ||
        source!.host.isEmpty ||
        d['stops'] is! List ||
        d['stopVertices'] is! List ||
        d['points'] is! List) {
      throw const FormatException('Invalid reviewed route geometry');
    }
    final stops = List<String>.from(d['stops']);
    final vertices = List<int>.from(d['stopVertices']);
    final raw = d['points'] as List;
    if (stops.length < 2 ||
        stops.length > 300 ||
        stops.toSet().length != stops.length ||
        stops.any((s) => s.isEmpty || s.contains('/')) ||
        vertices.length != stops.length ||
        raw.length < 2 ||
        raw.length > 5000 ||
        vertices.first != 0 ||
        vertices.last != raw.length - 1) {
      throw const FormatException('Invalid ordered geometry stops');
    }
    final points = <LatLng>[];
    for (final item in raw) {
      final p = item is Map ? [item['lat'], item['lng']] : item;
      if (p is! List || p.length != 2 || p[0] is! num || p[1] is! num) {
        throw const FormatException('Invalid coordinates');
      }
      final lat = (p[0] as num).toDouble(), lng = (p[1] as num).toDouble();
      if (!lat.isFinite ||
          !lng.isFinite ||
          lat.abs() > 90 ||
          lng.abs() > 180 ||
          (lat == 0 && lng == 0)) {
        throw const FormatException('Invalid coordinates');
      }
      points.add(LatLng(lat, lng));
    }
    for (var i = 1; i < vertices.length; i++) {
      if (vertices[i] <= vertices[i - 1] || vertices[i] >= points.length) {
        throw const FormatException('Stop vertices must increase');
      }
    }
    final distances = <double>[0];
    for (var i = 1; i < points.length; i++) {
      final leg = const Distance().as(
        LengthUnit.Meter,
        points[i - 1],
        points[i],
      );
      if (leg < 0.1 || leg > 10000) {
        throw const FormatException('Review road path resolution');
      }
      distances.add(distances.last + leg);
    }
    if (distances.last > 1000000) throw const FormatException('Route too long');
    return ReviewedRouteGeometry._(
      routeId,
      d['version'],
      source.toString(),
      d['synthetic'],
      List.unmodifiable(stops),
      List.unmodifiable(vertices),
      List.unmodifiable(points),
      List.unmodifiable(distances),
    );
  }

  Map<String, dynamic> toMap() => {
    'reviewed': true,
    'routeId': routeId,
    'version': version,
    'source': source,
    'synthetic': synthetic,
    'stops': stops,
    'stopVertices': vertices,
    'points': [
      for (final p in points) {'lat': p.latitude, 'lng': p.longitude},
    ],
  };

  List<LatLng> segment(String from, String to) {
    final a = stops.indexOf(from), b = stops.indexOf(to);
    return a < 0 || b <= a
        ? const []
        : points.sublist(vertices[a], vertices[b] + 1);
  }

  /// Restrict projection to the driver's recorded current leg. Ambiguous crossings
  /// and fixes >100m from that leg fail closed rather than jumping around a loop.
  double? project(BusLocationModel gps, int stopIndex) {
    if (stopIndex < 0 || stopIndex >= stops.length - 1) return null;
    final candidates = <(double, double)>[];
    for (var i = vertices[stopIndex]; i < vertices[stopIndex + 1]; i++) {
      final a = points[i], b = points[i + 1];
      final scale = 111195 * math.cos(gps.latitude * math.pi / 180);
      final ax = (a.longitude - gps.longitude) * scale,
          ay = (a.latitude - gps.latitude) * 111195;
      final dx = (b.longitude - a.longitude) * scale,
          dy = (b.latitude - a.latitude) * 111195;
      final square = dx * dx + dy * dy;
      if (square <= 0) continue;
      final t = (-(ax * dx + ay * dy) / square).clamp(0.0, 1.0);
      final error = math.sqrt(
        math.pow(ax + t * dx, 2) + math.pow(ay + t * dy, 2),
      );
      candidates.add((
        error,
        distances[i] + t * (distances[i + 1] - distances[i]),
      ));
    }
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => a.$1.compareTo(b.$1));
    final best = candidates.first;
    if (best.$1 > 100 ||
        candidates.any(
          (p) => p.$1 <= best.$1 + 20 && (p.$2 - best.$2).abs() > 150,
        )) {
      return null;
    }
    return best.$2;
  }
}

class RouteProgressEstimate {
  const RouteProgressEstimate(
    this.arrival,
    this.earliest,
    this.latest,
    this.remainingMeters,
    this.geometryVersion,
  );
  final DateTime arrival, earliest, latest;
  final double remainingMeters;
  final String geometryVersion;
}

abstract final class RouteProgressEta {
  /// Timetable-paced road progress; not traffic-aware, measured historical ETA or
  /// an extrapolation of an instantaneous speed. Range is a heuristic allowance.
  static RouteProgressEstimate? estimate({
    required ReviewedRouteGeometry geometry,
    required ServiceRun run,
    required TripModel trip,
    required BusLocationModel gps,
    required String target,
    required DateTime now,
  }) {
    final stops = run.stopTimes.keys.toList(),
        i = trip.currentStopIndex,
        end = stops.indexOf(target);
    final age = gps.timestamp == null ? null : now.difference(gps.timestamp!);
    if (run.status != 'in_progress' ||
        !trip.isInProgress ||
        trip.actualDepartureTime == null ||
        trip.actualDepartureTime!.isAfter(now) ||
        trip.tripId != run.id ||
        trip.serviceRunId != run.id ||
        trip.busId != run.busId ||
        trip.scheduledDepartureTime?.toUtc() !=
            run.plannedDepartureAt.toUtc() ||
        gps.tripId != run.id ||
        gps.busId != run.busId ||
        gps.driverId != trip.driverId ||
        geometry.routeId != run.routeId ||
        !listEquals(geometry.stops, stops) ||
        !listEquals(trip.stops, stops) ||
        gps.isCached ||
        !gps.isBroadcasting ||
        !['active', 'stopped'].contains(gps.status.value) ||
        age == null ||
        age < Duration.zero ||
        age > const Duration(seconds: 30) ||
        !gps.latitude.isFinite ||
        !gps.longitude.isFinite ||
        gps.latitude.abs() > 90 ||
        gps.longitude.abs() > 180 ||
        (gps.latitude == 0 && gps.longitude == 0) ||
        !gps.speed.isFinite ||
        gps.speed < 0 ||
        gps.speed > 130 ||
        i < 0 ||
        i >= stops.length - 1 ||
        end <= i ||
        trip.stopTimes.entries.any(
          (e) => stops.indexOf(e.key) >= end && e.value.actualArrival != null,
        )) {
      return null;
    }
    final progress = geometry.project(gps, i);
    if (progress == null) return null;
    // A stopped bus between stops has no supported departure pace. Do not invent
    // a fallback speed or call the estimate reliable while stationary.
    if (gps.speed < 3) return null;
    final start = geometry.distances[geometry.vertices[i]],
        next = geometry.distances[geometry.vertices[i + 1]];
    final interval = run.stopTimes[stops[i + 1]]!
        .difference(run.stopTimes[stops[i]]!)
        .inSeconds;
    if (interval <= 0) return null;
    final seconds =
        interval * ((next - progress) / (next - start)).clamp(0.0, 1.0) +
        run.stopTimes[target]!
            .difference(run.stopTimes[stops[i + 1]]!)
            .inSeconds;
    final arrival = now.add(Duration(seconds: seconds.ceil()));
    final allowance = math.max(60, (seconds * 0.3).ceil());
    final earliest = arrival.subtract(Duration(seconds: allowance));
    return RouteProgressEstimate(
      arrival,
      earliest.isBefore(now) ? now : earliest,
      arrival.add(Duration(seconds: allowance)),
      geometry.distances[geometry.vertices[end]] - progress,
      geometry.version,
    );
  }
}
