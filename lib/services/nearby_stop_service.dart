import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/station.dart';
import 'location_service.dart';

enum NearbyStopFailure { disabled, denied, deniedForever, unavailable }

class NearbyStopException implements Exception {
  const NearbyStopException(this.reason);
  final NearbyStopFailure reason;
}

class NearbyStop {
  const NearbyStop(this.station, this.metres);
  final Station station;
  final double metres;
}

/// One foreground fix only. Coordinates are neither persisted nor broadcast.
class NearbyStopService {
  NearbyStopService({LocationService? location})
    : location = location ?? LocationService();
  final LocationService location;

  Future<List<NearbyStop>> find(List<Station> stations) async {
    if (!await location.isLocationServiceEnabled()) {
      throw const NearbyStopException(NearbyStopFailure.disabled);
    }
    var permission = await location.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await location.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const NearbyStopException(NearbyStopFailure.deniedForever);
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw const NearbyStopException(NearbyStopFailure.denied);
    }
    final fix = await location
        .getCurrentPosition(timeLimit: const Duration(seconds: 15))
        .timeout(const Duration(seconds: 20));
    if (!validCoordinates(fix.latitude, fix.longitude) ||
        !fix.accuracy.isFinite ||
        fix.accuracy < 0 ||
        fix.accuracy > 1000) {
      throw const NearbyStopException(NearbyStopFailure.unavailable);
    }
    final ranked =
        stations
            .where((s) => s.id.isNotEmpty && validCoordinates(s.lat, s.lng))
            .map(
              (s) => NearbyStop(
                s,
                const Distance().as(
                  LengthUnit.Meter,
                  LatLng(fix.latitude, fix.longitude),
                  LatLng(s.lat, s.lng),
                ),
              ),
            )
            .toList()
          ..sort((a, b) {
            final byDistance = a.metres.compareTo(b.metres);
            return byDistance != 0
                ? byDistance
                : a.station.id.compareTo(b.station.id);
          });
    return ranked.take(5).toList();
  }

  static bool validCoordinates(double lat, double lng) =>
      lat.isFinite &&
      lng.isFinite &&
      lat.abs() <= 90 &&
      lng.abs() <= 180 &&
      (lat != 0 || lng != 0);
}
