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

  /// Live bus locations documents keyed by bus ID.
  static const String liveLocationsCollection = 'live_locations';

  /// Passenger journey/booking documents keyed by auto-generated ID.
  static const String journeysCollection = 'journeys';

  /// Station documents keyed by station ID (`stations/{id}`).
  static const String stationsCollection = 'stations';

  /// Static bus route & accessibility documents keyed by bus ID (`buses/{id}`).
  static const String staticBusesCollection = 'buses';

  /// Accessibility condition reports keyed by report ID (`reports/{id}`).
  static const String reportsCollection = 'reports';

  // --- users/{userId} document fields ---

  static const String fieldUid = 'uid';
  static const String fieldName = 'name';
  static const String fieldEmail = 'email';
  static const String fieldPhone = 'phone';
  static const String fieldRole = 'role';
  static const String fieldCreatedAt = 'createdAt';

  // --- stations/{stationId} document fields ---

  static const String fieldHasElevator = 'hasElevator';
  static const String fieldHasRamp = 'hasRamp';
  static const String fieldLat = 'lat';
  static const String fieldLng = 'lng';

  // --- buses/{busId} static document fields ---

  static const String fieldRouteNo = 'routeNo';
  static const String fieldStops = 'stops';
  static const String fieldLowFloor = 'lowFloor';
  static const String fieldRampOk = 'rampOk';
  static const String fieldOccupancy = 'occupancy';

  // --- reports/{reportId} document fields ---

  static const String fieldTargetType = 'targetType';
  static const String fieldTargetId = 'targetId';
  static const String fieldProblemType = 'problemType';
  static const String fieldLastConfirmedAt = 'lastConfirmedAt';
  static const String fieldConfirmCount = 'confirmCount';
  static const String fieldFalseCount = 'falseCount';
  static const String fieldUserId = 'userId';
  static const String fieldConfirmedBy = 'confirmedBy';
  static const String fieldFlaggedBy = 'flaggedBy';

  // --- active_buses/{busId} document fields ---

  static const String fieldBusId = 'busId';
  static const String fieldRouteId = 'routeId';
  static const String fieldRouteNumber = 'routeNumber';
  static const String fieldRouteName = 'routeName';
  static const String fieldDriverId = 'driverId';
  static const String fieldOperatorId = 'operatorId';
  static const String fieldOperatorName = 'operatorName';
  static const String fieldLatitude = 'latitude';
  static const String fieldLongitude = 'longitude';
  static const String fieldHeading = 'heading';
  static const String fieldSpeed = 'speed';
  static const String fieldTimestamp = 'timestamp';
  static const String fieldStatus = 'status';
  static const String fieldNextStop = 'nextStop';
  static const String fieldEtaMinutes = 'etaMinutes';
  static const String fieldRampOperational = 'rampOperational';
  static const String fieldElevatorWorking = 'elevatorWorking';
  static const String fieldOccupancyLevel = 'occupancyLevel';
  static const String fieldIsBroadcasting = 'isBroadcasting';
  static const String fieldLastUpdated = 'lastUpdated';

  // --- journeys/{journeyId} document fields ---

  static const String fieldJourneyId = 'journeyId';
  static const String fieldPassengerId = 'passengerId';
  static const String fieldOrigin = 'origin';
  static const String fieldDestination = 'destination';
  static const String fieldRouteTitle = 'routeTitle';
  static const String fieldJourneyStatus = 'status';
  static const String fieldJourneyCreatedAt = 'createdAt';
}
