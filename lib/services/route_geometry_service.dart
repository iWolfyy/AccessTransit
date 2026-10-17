import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../logic/route_geometry.dart';
import '../logic/journey_fare.dart';
import 'admin_service.dart';
import 'sample_test_mode.dart';

import 'package:latlong2/latlong.dart';

class RouteGeometryService {
  Stream<ReviewedRouteGeometry?> watch(String routeId) async* {
    try {
      yield* FirebaseFirestore.instance
          .collection(SampleTestMode.collection('route_geometries'))
          .doc(routeId)
          .snapshots(includeMetadataChanges: true)
          .map((s) {
            if (!s.exists ||
                s.metadata.isFromCache ||
                s.metadata.hasPendingWrites) {
              return null;
            }
            try {
              final geometry = ReviewedRouteGeometry.parse(routeId, s.data()!);
              return geometry.synthetic == JourneyFare.prototypeEnabled
                  ? geometry
                  : null;
            } catch (_) {
              return null;
            }
          });
    } catch (_) {
      yield null;
    }
  }
}

class AdminRouteGeometryService {
  AdminRouteGeometryService(this.repository);
  final AdminRepository repository;
  Future<void> publish(ReviewedRouteGeometry geometry, String reason) async {
    if (reason.trim().length < 10 ||
        reason.trim().length > 2000 ||
        geometry.synthetic != JourneyFare.prototypeEnabled) {
      throw const FormatException('Review the geometry and enter a reason');
    }
    final route = (await repository.load('routes'))
        .where((r) => r.id == geometry.routeId)
        .firstOrNull;
    if (route == null ||
        route.data['deletionPending'] == true ||
        route.data['archived'] == true ||
        !listEquals(
          List<String>.from(route.data['stops'] ?? []),
          geometry.stops,
        ) ||
        (!JourneyFare.prototypeEnabled &&
            (route.data['catalogueSource'] != 'operator_catalogue' ||
                route.data['isDemo'] == true))) {
      throw StateError('Review the current directed route itinerary');
    }
    final prior = (await repository.load('route_geometries'))
        .where((r) => r.id == geometry.routeId)
        .firstOrNull;
    if (prior != null && prior.data['synthetic'] != geometry.synthetic) {
      throw StateError('Geometry belongs to another data mode');
    }
    if (prior?.text('version') == geometry.version) {
      throw StateError('Use a new reviewed version');
    }
    final guards = <AdminChange>[];
    final stations = await repository.load('stations');
    for (var i = 0; i < geometry.stops.length; i++) {
      final stop = stations
          .where(
            (s) =>
                s.id ==
                AdminService.stationIdFor(route.data, geometry.stops[i]),
          )
          .firstOrNull;
      final lat = stop?.data['lat'], lng = stop?.data['lng'];
      if (stop == null ||
          stop.data['deletionPending'] == true ||
          lat is! num ||
          lng is! num ||
          !lat.isFinite ||
          !lng.isFinite ||
          lat.abs() > 90 ||
          lng.abs() > 180 ||
          (lat == 0 && lng == 0) ||
          const Distance().as(
                LengthUnit.Meter,
                LatLng(lat.toDouble(), lng.toDouble()),
                geometry.points[geometry.vertices[i]],
              ) >
              100) {
        throw StateError('Review each stop coordinate and its road vertex');
      }
      guards.add(
        AdminChange('stations', stop.id, stop.data, stop.data, checkOnly: true),
      );
    }
    await repository.commit([
      ...guards,
      AdminChange('routes', route.id, route.data, route.data, checkOnly: true),
      AdminChange('route_geometries', geometry.routeId, prior?.data, {
        ...geometry.toMap(),
        'reviewReason': reason.trim(),
      }),
    ], 'route_geometry_publish');
  }

  Future<void> withdraw(String routeId, String reason) async {
    if (reason.trim().length < 10 || reason.trim().length > 2000) {
      throw const FormatException('Enter a review reason');
    }
    final prior = (await repository.load('route_geometries'))
        .where((r) => r.id == routeId)
        .firstOrNull;
    if (prior == null) throw StateError('No geometry to withdraw');
    if (prior.data['synthetic'] != JourneyFare.prototypeEnabled) {
      throw StateError('Geometry belongs to another data mode');
    }
    await repository.commit([
      AdminChange('route_geometries', routeId, prior.data, {
        ...prior.data,
        'reviewed': false,
        'reviewReason': reason.trim(),
      }),
    ], 'route_geometry_withdraw');
  }
}
