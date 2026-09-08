/// Firestore collection and field names for AccessTransit.
///
/// AC-48: Defines the `users` collection structure used across the app.
class FirestoreConstants {
  FirestoreConstants._();

  // --- Collections ---

  /// User profile documents keyed by Firebase Auth [uid].
  static const String usersCollection = 'users';

  /// Live bus tracking telemetry documents keyed by bus ID.
  static const String busesCollection = 'active_buses';

  // --- users/{userId} document fields ---

  static const String fieldUid = 'uid';
  static const String fieldName = 'name';
  static const String fieldEmail = 'email';
  static const String fieldPhone = 'phone';
  static const String fieldRole = 'role';
  static const String fieldCreatedAt = 'createdAt';

  // --- active_buses/{busId} document fields ---

  static const String fieldBusId = 'busId';
  static const String fieldRouteNumber = 'routeNumber';
  static const String fieldRouteName = 'routeName';
  static const String fieldOperatorId = 'operatorId';
  static const String fieldOperatorName = 'operatorName';
  static const String fieldLatitude = 'latitude';
  static const String fieldLongitude = 'longitude';
  static const String fieldHeading = 'heading';
  static const String fieldSpeed = 'speed';
  static const String fieldNextStop = 'nextStop';
  static const String fieldEtaMinutes = 'etaMinutes';
  static const String fieldRampOperational = 'rampOperational';
  static const String fieldElevatorWorking = 'elevatorWorking';
  static const String fieldOccupancyLevel = 'occupancyLevel';
  static const String fieldIsBroadcasting = 'isBroadcasting';
  static const String fieldLastUpdated = 'lastUpdated';
}
