import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Reusable GPS Location Service for AccessTransit using geolocator.
class LocationService {
  LocationService();

  /// Checks if location services are enabled on the device.
  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  /// Checks current location permission status.
  Future<LocationPermission> checkPermission() async {
    return Geolocator.checkPermission();
  }

  /// Requests location permissions from the user.
  Future<LocationPermission> requestPermission() async {
    return Geolocator.requestPermission();
  }

  /// Verifies location services and permissions before accessing GPS.
  ///
  /// Throws descriptive exceptions for service disabled, denied,
  /// or permanently denied states so UI components can handle them safely.
  Future<void> verifyPermission() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied by user.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied in system settings. '
        'Please enable location permissions from device settings.',
      );
    }
  }

  /// Retrieves the current high-accuracy GPS position of the device.
  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration? timeLimit,
  }) async {
    await verifyPermission();
    return Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        timeLimit: timeLimit,
      ),
    );
  }

  /// Provides a continuous real-time location stream for live tracking.
  ///
  /// [accuracy] defaults to high for precise vehicle/user positioning.
  /// [distanceFilter] specifies minimum displacement (in meters) before emitting updates.
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 5,
  }) async* {
    await verifyPermission();

    final locationSettings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );

    yield* Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Opens system app settings for user to manually grant permissions if permanently denied.
  Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }

  /// Opens system location settings if location service is turned off.
  Future<bool> openLocationSettings() async {
    return Geolocator.openLocationSettings();
  }
}
