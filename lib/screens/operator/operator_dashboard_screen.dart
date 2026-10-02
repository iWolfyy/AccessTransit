import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/time_utils.dart';
import '../../data/seed_data.dart';
import '../../logic/delay_eta_logic.dart';
import '../../models/bus_route.dart';
import '../../models/boarding_request.dart';
import '../../models/bus.dart';
import '../../models/bus_location_model.dart';
import '../../models/enums/bus_status.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/live_bus_service.dart';
import '../../services/location_service.dart';
import '../../services/trip_service.dart';
import '../../models/trip_model.dart';
import '../../models/station.dart';
import '../../widgets/add_station_dialog.dart';
import '../auth/login_screen.dart';



/// Screen for Bus Operators to start/stop trips and broadcast real-time GPS telemetry to Firestore.
class OperatorDashboardScreen extends StatefulWidget {
  const OperatorDashboardScreen({super.key});

  @override
  State<OperatorDashboardScreen> createState() =>
      _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState extends State<OperatorDashboardScreen> {
  final LiveBusService _liveBusService = LiveBusService();
  final LocationService _locationService = LocationService();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<List<Bus>>? _busesSubscription;
  StreamSubscription<Bus?>? _busDocSubscription;

  Timer? _tripTimer;
  Duration _tripDuration = Duration.zero;

  bool _isTripActive = false;
  bool _isInitializing = false;
  bool _userManuallySelectedBus = false;

  List<Bus> _availableBuses = SeedData.sampleBuses;
  Bus? _currentBus;
  Map<String, BusRoute> _routesMap = {};

  String _selectedBusId = 'bus_138_nd4521';
  String _selectedRouteId = 'route_138_pettah_homagama';
  String _selectedRouteNumber = '138';
  String _selectedRouteName = 'Route 138: Pettah → Kottawa';
  String _nextStop = 'Kottawa Highway Bus Station';

  bool _rampOperational = true;
  bool _elevatorWorking = true;
  String _occupancyLevel = 'Medium';

  double? _currentLat;
  double? _currentLng;
  double _speed = 0.0; // km/h
  double _heading = 0.0;
  DateTime? _lastUpdateTimestamp;

  static const List<String> _occupancyOptions = [
    'Low',
    'Medium',
    'High',
  ];

  @override
  void initState() {
    super.initState();
    _loadRoutes();
    _subscribeToBuses();
  }

  Future<void> _loadRoutes() async {
    try {
      final routes = await _firestoreService.getRoutes();
      final list = routes.isNotEmpty ? routes : SeedData.sampleRoutes;
      if (mounted) {
        setState(() {
          _routesMap = {for (final r in list) r.id: r};
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _routesMap = {for (final r in SeedData.sampleRoutes) r.id: r};
        });
      }
    }
  }

  /// Finds the nearest upcoming bus run (departure within the next 24 hours)
  /// and returns its ID. Prioritises: assigned-to-me > nearest upcoming > first bus.
  String _autoSelectNearestUpcomingBus(List<Bus> buses, String? currentUserId) {
    // Priority 1: Bus already assigned to this driver
    final myBus = buses.cast<Bus?>().firstWhere(
          (b) => b?.driverId != null && b?.driverId == currentUserId,
          orElse: () => null,
        );
    if (myBus != null) return myBus.id;

    // Priority 2: Nearest upcoming departure (scheduled departure >= now)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    Bus? bestUpcoming;
    Duration bestDelta = const Duration(days: 2);

    for (final bus in buses) {
      final depStr = bus.effectiveDepartureTime;
      final depTime = TimeUtils.parseTimeStringToDateTime(depStr, today);

      final delta = depTime.difference(now);
      // Upcoming = departure is in the future (or within 15 min past to allow late starts)
      if (delta.inMinutes >= -15 && delta < bestDelta) {
        bestDelta = delta;
        bestUpcoming = bus;
      }
    }

    if (bestUpcoming != null) return bestUpcoming.id;

    // Fallback: keep current selection if still valid, otherwise first bus
    if (buses.any((b) => b.id == _selectedBusId)) return _selectedBusId;
    return buses.isNotEmpty ? buses.first.id : _selectedBusId;
  }

  /// Returns a human-readable run status for a bus based on its departure time.
  static _BusRunStatus _getBusRunStatus(Bus bus, {DateTime? clock}) {
    final now = clock ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final depStr = bus.effectiveDepartureTime;
    final depTime = TimeUtils.parseTimeStringToDateTime(depStr, today);

    // Compute last-stop arrival time from scheduleTimes
    final lastIndex = bus.stops.isNotEmpty ? bus.stops.length - 1 : 0;
    final lastStopStr = bus.getScheduledTimeForStop(lastIndex);
    final lastStopTime = TimeUtils.parseTimeStringToDateTime(lastStopStr, today);

    final minsToDep = depTime.difference(now).inMinutes;
    final minsToEnd = lastStopTime.difference(now).inMinutes;

    if (minsToDep > 0) {
      // Departure is in the future
      return _BusRunStatus(
        label: 'Upcoming',
        color: Colors.blue,
        icon: Icons.schedule,
        sortKey: 0 + minsToDep, // upcoming sorted by proximity
      );
    } else if (minsToEnd >= -5) {
      // Between departure and final stop (+ 5 min buffer)
      return _BusRunStatus(
        label: 'In Progress',
        color: Colors.green,
        icon: Icons.directions_bus,
        sortKey: -1000, // in-progress always on top
      );
    } else {
      // Past the final scheduled stop
      return _BusRunStatus(
        label: 'Departed',
        color: const Color(0xFF5D616B), // WCAG AA 6.1:1 on white (was Colors.grey 2.8:1)
        icon: Icons.check_circle_outline,
        sortKey: 2000 + minsToEnd.abs(), // departed at the bottom
      );
    }
  }

  void _subscribeToBuses() {
    _busesSubscription?.cancel();
    _busesSubscription = _firestoreService.streamBuses().listen((buses) {
      if (!mounted) return;
      final currentUserId = _authService.currentUser?.uid;
      final list = buses.isNotEmpty ? buses : SeedData.sampleBuses;

      setState(() {
        _availableBuses = list;
        if (!_userManuallySelectedBus) {
          _selectedBusId = _autoSelectNearestUpcomingBus(list, currentUserId);
        }
      });
      _listenToSelectedBus(_selectedBusId);
    });
  }

  void _listenToSelectedBus(String busId) {
    _busDocSubscription?.cancel();
    _busDocSubscription = _firestoreService.streamBusById(busId).listen((bus) {
      if (!mounted || bus == null) return;
      setState(() {
        _currentBus = bus;
        _rampOperational = bus.rampOk;
        final occ = bus.occupancy.toLowerCase();
        if (occ == 'low') {
          _occupancyLevel = 'Low';
        } else if (occ == 'high') {
          _occupancyLevel = 'High';
        } else {
          _occupancyLevel = 'Medium';
        }

        _selectedRouteNumber = bus.routeNo;
        _selectedRouteId = 'route_${bus.routeNo}';
        _selectedRouteName = 'Route ${bus.routeNo}';
        if (bus.stops.isNotEmpty) {
          final targetIndex = bus.stops.length > 1 ? 1 : 0;
          _nextStop = _resolveStopName(bus.stops[targetIndex]);
        }
      });
    });
  }

  Future<void> _claimBusAssignment() async {
    final currentUserId = _authService.currentUser?.uid ?? 'operator_dev';
    try {
      await _firestoreService.assignBusDriver(_selectedBusId, currentUserId);
      _showSnack('Bus $_selectedRouteNumber is now assigned to you!');
    } catch (e) {
      _showSnack('Failed to assign bus: $e', isError: true);
    }
  }

  Future<void> _onRampToggled(bool val) async {
    final currentUserId = _authService.currentUser?.uid ?? 'operator_dev';
    final isAssignedDriver = _currentBus == null ||
        _currentBus?.driverId == null ||
        _currentBus?.driverId == currentUserId;

    if (!isAssignedDriver) {
      _showSnack(
        'Only the assigned driver can update this bus.',
        isError: true,
      );
      return;
    }

    setState(() => _rampOperational = val);
    try {
      await _firestoreService.updateBusAccessibility(
        _selectedBusId,
        rampOk: val,
        driverId: currentUserId,
      );
      _pushAccessibilityUpdate();
      _showSnack(
        val
            ? 'Ramp marked Working (Riders will see Safe)'
            : 'Ramp marked Broken (Riders will see Warning)',
      );
    } catch (e) {
      _showSnack('Failed to update ramp status: $e', isError: true);
    }
  }

  Future<void> _onOccupancyChanged(String? val) async {
    if (val == null) return;
    final currentUserId = _authService.currentUser?.uid ?? 'operator_dev';
    final isAssignedDriver = _currentBus == null ||
        _currentBus?.driverId == null ||
        _currentBus?.driverId == currentUserId;

    if (!isAssignedDriver) {
      _showSnack(
        'Only the assigned driver can update this bus.',
        isError: true,
      );
      return;
    }

    setState(() => _occupancyLevel = val);
    try {
      await _firestoreService.updateBusAccessibility(
        _selectedBusId,
        occupancy: val.toLowerCase(),
        driverId: currentUserId,
      );
      _pushAccessibilityUpdate();
      _showSnack('Occupancy updated to $val');
    } catch (e) {
      _showSnack('Failed to update occupancy: $e', isError: true);
    }
  }

  @override
  void dispose() {
    _busesSubscription?.cancel();
    _busDocSubscription?.cancel();
    _positionSubscription?.cancel();
    _tripTimer?.cancel();
    if (_isTripActive) {
      _liveBusService.stopTrip(_selectedBusId, endStatus: BusStatus.offline);
    }
    super.dispose();
  }

  /// Starts live trip by verifying GPS permissions, capturing initial fix,
  /// creating active document in Firestore (`live_locations/{busId}`), and streaming position updates.
  Future<void> _startTrip() async {
    if (_isTripActive || _isInitializing) return;

    setState(() {
      _isInitializing = true;
    });

    try {
      // 1. Verify location service and permissions
      await _locationService.verifyPermission();

      // 2. Fetch initial GPS location fix
      final initialPosition = await _locationService.getCurrentPosition();

      final currentUser = _authService.currentUser;
      final driverId = currentUser?.uid ?? 'operator_dev';
      final operatorName =
          (currentUser?.displayName != null &&
              currentUser!.displayName!.isNotEmpty)
          ? currentUser.displayName!
          : (currentUser?.email ?? 'Transit Operator');

      final lat = initialPosition.latitude;
      final lng = initialPosition.longitude;
      final speedKmH = (initialPosition.speed * 3.6).clamp(0.0, 200.0);
      final headingDeg = initialPosition.heading;
      final now = DateTime.now();

      setState(() {
        _currentLat = lat;
        _currentLng = lng;
        _speed = speedKmH;
        _heading = headingDeg;
        _lastUpdateTimestamp = now;
      });

      final initialNextStop = (_currentBus != null && _currentBus!.stops.length > 1)
          ? _resolveStopName(_currentBus!.stops[1])
          : _nextStop;
      _nextStop = initialNextStop;

      // 3. Create/update live_locations/{busId} document with status = active
      final initialBusModel = BusLocationModel(
        busId: _selectedBusId,
        routeId: _selectedRouteId,
        routeNumber: _selectedRouteNumber,
        routeName: _selectedRouteName,
        driverId: driverId,
        operatorName: operatorName,
        latitude: lat,
        longitude: lng,
        speed: speedKmH,
        heading: headingDeg,
        status: BusStatus.active,
        nextStop: initialNextStop,
        currentStopIndex: 0,
        rampOperational: _rampOperational,
        elevatorWorking: _elevatorWorking,
        occupancyLevel: _occupancyLevel,
        isBroadcasting: true,
      );

      await _liveBusService.startOrUpdateLiveLocation(initialBusModel);

      // Create new trip document in trips/{tripId} with actualDepartureTime = now
      final stops = _currentBus?.stops.isNotEmpty == true
          ? _currentBus!.stops
          : ['st_pettah', 'st_maradana', 'st_borella', 'st_kottawa'];

      await TripService().startTrip(
        busId: _selectedBusId,
        routeNo: _selectedRouteNumber,
        stops: stops,
        driverId: driverId,
        scheduleTimes: _currentBus?.scheduleTimes,
        departureTime: now,
      );

      // 4. Listen to live GPS location stream with background tracking enabled
      await _positionSubscription?.cancel();
      _positionSubscription = _locationService
          .getPositionStream(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
            enableBackground: true,
            notificationTitle: 'AccessTransit Live Bus Tracking',
            notificationText:
                'Broadcasting live location for Bus $_selectedRouteNumber to passengers',
          )
          .listen(
            _onLocationUpdate,
            onError: (dynamic error) {
              _showSnack('GPS Stream Error: $error', isError: true);
            },
          );

      // 5. Start duration timer
      _tripDuration = Duration.zero;
      _tripTimer?.cancel();
      _tripTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _tripDuration += const Duration(seconds: 1);
        });
      });

      setState(() {
        _isTripActive = true;
        _isInitializing = false;
      });

      _showSnack(
        'Trip Started! Broadcasting live GPS & per-stop timeline for Bus $_selectedRouteNumber',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
      });
      _showSnack(
        'Could not start trip: ${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
      );
    }
  }

  /// Handles real-time location stream events from GPS sensor.
  Future<void> _onLocationUpdate(Position position) async {
    if (!_isTripActive || !mounted) return;

    final speedKmH = (position.speed * 3.6).clamp(0.0, 200.0);
    final now = DateTime.now();

    setState(() {
      _currentLat = position.latitude;
      _currentLng = position.longitude;
      _speed = speedKmH;
      _heading = position.heading;
      _lastUpdateTimestamp = now;
    });

    try {
      await _liveBusService.updateLocationOnly(
        busId: _selectedBusId,
        latitude: position.latitude,
        longitude: position.longitude,
        speed: speedKmH,
        heading: position.heading,
      );
    } catch (e) {
      // Ignore intermittent update errors to keep stream uninterrupted
    }
  }

  /// Stops current trip, cancels GPS subscription, and sets status to `completed` in Firestore.
  Future<void> _stopTrip() async {
    if (!_isTripActive && _positionSubscription == null) return;

    // 1. Cancel location stream and timer immediately
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    _tripTimer?.cancel();
    _tripTimer = null;

    // 2. Update Firestore status to completed
    try {
      await _liveBusService.stopTrip(
        _selectedBusId,
        endStatus: BusStatus.completed,
      );
      await TripService().completeTrip(_selectedBusId);
    } catch (e) {
      _showSnack('Notice: Updated status to completed ($e)', isError: true);
    }

    if (!mounted) return;

    setState(() {
      _isTripActive = false;
    });

    _showSnack('Trip Completed. GPS broadcasting stopped.');
  }

  /// Pushes status/accessibility updates to Firestore during an active trip.
  Future<void> _pushAccessibilityUpdate() async {
    if (!_isTripActive) return;
    try {
      if (_currentLat != null && _currentLng != null) {
        final busModel = BusLocationModel(
          busId: _selectedBusId,
          routeId: _selectedRouteId,
          routeNumber: _selectedRouteNumber,
          routeName: _selectedRouteName,
          driverId: _authService.currentUser?.uid ?? 'operator_dev',
          latitude: _currentLat!,
          longitude: _currentLng!,
          speed: _speed,
          heading: _heading,
          status: BusStatus.active,
          nextStop: _nextStop,
          rampOperational: _rampOperational,
          elevatorWorking: _elevatorWorking,
          occupancyLevel: _occupancyLevel,
          isBroadcasting: true,
        );
        await _liveBusService.startOrUpdateLiveLocation(busModel);
      }
    } catch (e) {
      // Ignore minor network update errors
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? AppColors.error
              : AppColors.primaryContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      final hoursStr = hours.toString().padLeft(2, '0');
      return '$hoursStr:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String _getCardinalDirection(double heading) {
    if (heading < 0) return 'N/A';
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((heading + 22.5) % 360 / 45).floor();
    return directions[index % 8];
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final operatorName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : (user?.email ?? 'Operator');

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Operator Dashboard'),
            Text(
              'Operator: $operatorName',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.onPrimary.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: 'Add Station to Route',
            onPressed: () {
              AddStationDialog.show(
                context,
                buses: _availableBuses,
                defaultBusId: _selectedBusId,
              );
            },
          ),
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.cloud_upload_outlined),
              tooltip: 'Seed Firestore Data (Debug)',
              onPressed: () async {
                try {
                  await SeedData().seedAll();
                  _showSnack(
                    'Successfully seeded 15 stations, 10 buses, and 3 reports!',
                  );
                } catch (e) {
                  _showSnack('Seeding failed: $e', isError: true);
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final nav = Navigator.of(context);
              if (_isTripActive) {
                await _stopTrip();
              }
              await _authService.logout();
              if (!mounted) return;
              nav.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTripControlCard(),
            const SizedBox(height: 16),
            _buildTripProgressCard(),
            const SizedBox(height: 16),
            _buildRouteSelectorCard(),
            const SizedBox(height: 16),
            _buildLiveTelemetryCard(),
            const SizedBox(height: 16),
            _buildAccessibilityControlsCard(),
            const SizedBox(height: 16),
            _buildBoardingRequestsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTripControlCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _isTripActive
          ? AppColors.primaryContainer
          : AppColors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isTripActive
                      ? Icons.sensors_rounded
                      : Icons.sensors_off_rounded,
                  size: 36,
                  color: _isTripActive
                      ? AppColors.onPrimary
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                if (_isTripActive) ...[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  _isTripActive ? 'TRIP IN PROGRESS' : 'TRIP INACTIVE',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _isTripActive
                        ? AppColors.onPrimary
                        : AppColors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isTripActive
                  ? 'Background GPS tracking active. System notification visible in status bar.\nDuration: ${_formatDuration(_tripDuration)}'
                  : 'Press Start Trip to activate background GPS tracking for Bus $_selectedRouteNumber.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _isTripActive
                    ? AppColors.onPrimary.withValues(alpha: 0.95)
                    : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: _isInitializing
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton.icon(
                      onPressed: _isTripActive ? _stopTrip : _startTrip,
                      style: FilledButton.styleFrom(
                        backgroundColor: _isTripActive
                            ? AppColors.error
                            : AppColors.secondary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        _isTripActive
                            ? Icons.stop_circle_rounded
                            : Icons.play_circle_fill_rounded,
                        size: 26,
                      ),
                      label: Text(
                        _isTripActive ? 'Stop Trip' : 'Start Trip',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripProgressCard() {
    return StreamBuilder<TripModel?>(
      stream: TripService().watchActiveTripForBus(_selectedBusId),
      builder: (context, snapshot) {
        final trip = snapshot.data;
        final isInProgress = trip != null && trip.isInProgress;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: isInProgress ? AppColors.surfaceContainerLowest : AppColors.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timeline, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Trip Route Progress',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isInProgress
                            ? Colors.green.withValues(alpha: 0.15)
                            : AppColors.outlineVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isInProgress ? 'In Progress' : 'No Active Trip',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isInProgress ? Colors.green.shade800 : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!isInProgress) ...[
                  const Text(
                    'No active trip run. Tap Start Trip above to record actual departure time and activate the rider per-stop timeline.',
                    style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  _buildPreTripPunctualityCard(),
                ] else ...[
                  FutureBuilder<List<Station>>(
                    future: _firestoreService.getStations(),
                    builder: (context, stationsSnapshot) {
                      final stationsList = stationsSnapshot.data ?? SeedData.colomboStations;
                      final stationsMap = {for (final s in stationsList) s.id: s};

                      final safeIndex = trip.currentStopIndex.clamp(0, trip.stops.length - 1);
                      final currentStopId = trip.stops[safeIndex];
                      final currentStopName = stationsMap[currentStopId]?.name ?? currentStopId;

                      final hasNextStop = trip.currentStopIndex + 1 < trip.stops.length;
                      final nextStopId = hasNextStop ? trip.stops[trip.currentStopIndex + 1] : null;
                      final nextStopName = nextStopId != null ? (stationsMap[nextStopId]?.name ?? nextStopId) : 'Final Destination Reached';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Position: Stop ${trip.currentStopIndex + 1} of ${trip.stops.length}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.outline),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentStopName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Next Stop: $nextStopName',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                                ),
                              ),
                            ],
                          ),

                          // --- Step 2: Driver Punctuality & Schedule Comparison Card (Delay Meter) ---
                          _buildDelayMeterCard(trip, stationsMap),

                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: FilledButton.icon(
                                    onPressed: hasNextStop
                                        ? () async {
                                            final updated = await TripService().confirmNextStopArrival(_selectedBusId);
                                            if (updated != null) {
                                              final safeIdx = updated.currentStopIndex.clamp(0, updated.stops.length - 1);
                                              final arrivedStopId = updated.stops[safeIdx];
                                              final arrivedStopName = stationsMap[arrivedStopId]?.name ?? arrivedStopId;

                                              final hasUpcoming = updated.currentStopIndex + 1 < updated.stops.length;
                                              final upcomingStopId = hasUpcoming
                                                  ? updated.stops[updated.currentStopIndex + 1]
                                                  : arrivedStopId;
                                              final upcomingStopName = stationsMap[upcomingStopId]?.name ?? upcomingStopId;

                                              if (mounted) {
                                                setState(() {
                                                  _nextStop = upcomingStopName;
                                                });
                                              }

                                              // Calculate ETA countdown to upcoming stop
                                              int etaMinutes = 4;
                                              if (_currentBus != null) {
                                                final etaCalc = DelayEtaCalculator.calculateArrivalEta(
                                                  bus: _currentBus!,
                                                  targetStopIdOrName: upcomingStopId,
                                                  activeTrip: updated,
                                                  stationsMap: stationsMap,
                                                  currentTime: DateTime.now(),
                                                );
                                                etaMinutes = etaCalc.countdownMinutes.clamp(1, 120);
                                              }

                                              // Instantly sync LiveBusService with human-readable stop name for Passenger screen
                                              await _liveBusService.updateNextStop(
                                                busId: _selectedBusId,
                                                nextStop: upcomingStopName,
                                                currentStopIndex: updated.currentStopIndex,
                                                etaMinutes: hasUpcoming ? etaMinutes : 0,
                                              );

                                              _showSnack('Arrival confirmed at $arrivedStopName! Next: $upcomingStopName');
                                            }
                                          }
                                        : null,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primaryContainer,
                                      foregroundColor: AppColors.onPrimary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                                    label: Text(hasNextStop ? 'Next Stop Reached' : 'Final Stop Reached'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: () => _stopTrip(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(color: AppColors.error),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.flag_rounded, size: 18),
                                  label: const Text('End Trip'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Step 2: Builds the real-time Driver Punctuality & Schedule Comparison Card (Delay Meter).
  Widget _buildDelayMeterCard(TripModel trip, Map<String, Station> stationsMap) {
    if (_currentBus == null) return const SizedBox.shrink();

    final hasNextStop = trip.currentStopIndex + 1 < trip.stops.length;
    final targetStopIndex = hasNextStop ? trip.currentStopIndex + 1 : trip.currentStopIndex;
    final targetStopId = trip.stops[targetStopIndex];
    final targetStopName = stationsMap[targetStopId]?.name ?? targetStopId;

    final etaResult = DelayEtaCalculator.calculateArrivalEta(
      bus: _currentBus!,
      targetStopIdOrName: targetStopId,
      activeTrip: trip,
      stationsMap: stationsMap,
      currentTime: DateTime.now(),
    );

    final delayColor = _getDelayColor(etaResult.delayType);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: delayColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Target Stop & Punctuality Badge
          Row(
            children: [
              Icon(Icons.speed_rounded, size: 20, color: delayColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hasNextStop ? 'Target: $targetStopName' : 'Destination: $targetStopName',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              _buildPunctualityBadge(etaResult.delayType, etaResult.delayMinutes),
            ],
          ),
          const SizedBox(height: 12),

          // Schedule vs Current ETA Comparison Grid
          Row(
            children: [
              Expanded(
                child: _buildTimeComparisonBox(
                  label: 'SCHEDULED ARRIVAL',
                  time: etaResult.scheduledArrivalStr,
                  subtitle: 'Timetable Target',
                  icon: Icons.calendar_today_rounded,
                  color: AppColors.primary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    Icon(
                      Icons.compare_arrows_rounded,
                      size: 20,
                      color: delayColor,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: delayColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatVariance(etaResult.delayMinutes),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: delayColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildTimeComparisonBox(
                  label: 'CURRENT ETA',
                  time: etaResult.estimatedArrivalStr,
                  subtitle: etaResult.countdownText,
                  icon: Icons.timelapse_rounded,
                  color: delayColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Visual Delay Meter Gauge
          _buildDelayMeterGauge(etaResult.delayMinutes),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: 10),

          // Quick Delay Reporting Section (Step 4)
          StreamBuilder<BusLocationModel?>(
            stream: _liveBusService.listenToLiveLocation(_selectedBusId),
            builder: (context, locSnapshot) {
              final loc = locSnapshot.data;
              final hasActiveDelay =
                  loc?.delayReason != null && loc!.delayReason!.isNotEmpty;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasActiveDelay) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade400),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 20,
                            color: Colors.orange.shade900,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Broadcasted to Riders: ${loc.delayReason}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                                Text(
                                  '+${loc.addedDelayMinutes} mins added to passenger arrival ETAs',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await _liveBusService.clearDelay(_selectedBusId);
                              _showSnack(
                                'Delay notice cleared. Normal schedule resumed.',
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text(
                              'Clear',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () => _showReportDelayBottomSheet(
                        currentReason: loc?.delayReason,
                        currentMinutes: loc?.addedDelayMinutes ?? 5,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade900,
                        side: BorderSide(color: Colors.orange.shade700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.traffic_rounded, size: 18),
                      label: Text(
                        hasActiveDelay
                            ? 'Update Delay / Traffic Reason'
                            : 'Report Traffic / Delay (+5m, +10m)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Step 4: Displays the quick delay / traffic reason reporting modal sheet.
  void _showReportDelayBottomSheet({
    String? currentReason,
    int currentMinutes = 5,
  }) {
    int selectedMinutes = currentMinutes > 0 ? currentMinutes : 5;
    String selectedReason = currentReason ?? 'Traffic Congestion';

    final delayOptions = [5, 10, 15, 20, 30];
    final reasons = [
      {'label': 'Traffic Congestion', 'icon': Icons.traffic_rounded},
      {'label': 'Heavy Rain / Flooding', 'icon': Icons.water_drop_rounded},
      {'label': 'Accident Ahead', 'icon': Icons.car_crash_rounded},
      {'label': 'Road Construction', 'icon': Icons.construction_rounded},
      {'label': 'Mechanical Breakdown', 'icon': Icons.build_rounded},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.traffic_rounded,
                          color: Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Report Delay / Incident',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Alerts all passenger screens and updates live ETAs.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Estimated Delay Time',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: delayOptions.map((mins) {
                      final isSelected = selectedMinutes == mins;
                      return ChoiceChip(
                        label: Text('+$mins mins'),
                        selected: isSelected,
                        selectedColor: Colors.orange.shade100,
                        labelStyle: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Colors.orange.shade900
                              : AppColors.onSurface,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setModalState(() {
                              selectedMinutes = mins;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Delay Reason',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: reasons.map((r) {
                      final label = r['label'] as String;
                      final icon = r['icon'] as IconData;
                      final isSelected = selectedReason == label;

                      return ChoiceChip(
                        avatar: Icon(
                          icon,
                          size: 16,
                          color: isSelected
                              ? Colors.orange.shade900
                              : AppColors.onSurfaceVariant,
                        ),
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: Colors.orange.shade100,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Colors.orange.shade900
                              : AppColors.onSurface,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setModalState(() {
                              selectedReason = label;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _liveBusService.reportDelay(
                        busId: _selectedBusId,
                        reason: selectedReason,
                        delayMinutes: selectedMinutes,
                      );
                      _showSnack(
                        'Delay notice broadcasted: $selectedReason (+$selectedMinutes mins)',
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.broadcast_on_personal_rounded),
                    label: Text(
                      'Broadcast Delay (+$selectedMinutes mins)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  /// Builds a pre-trip punctuality badge and departure timetable check.
  Widget _buildPreTripPunctualityCard() {
    if (_currentBus == null) return const SizedBox.shrink();

    final bus = _currentBus!;
    final depStr = bus.effectiveDepartureTime;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final depTime = TimeUtils.parseTimeStringToDateTime(depStr, today);
    final minsDiff = depTime.difference(now).inMinutes;

    final String statusBadgeText;
    final Color badgeColor;
    final IconData badgeIcon;

    if (minsDiff > 1) {
      statusBadgeText = 'Departs in $minsDiff mins';
      badgeColor = Colors.blue.shade700;
      badgeIcon = Icons.schedule_rounded;
    } else if (minsDiff >= -1 && minsDiff <= 1) {
      statusBadgeText = 'On Time (Departs Now)';
      badgeColor = Colors.green.shade700;
      badgeIcon = Icons.check_circle_rounded;
    } else {
      final lateMins = minsDiff.abs();
      statusBadgeText = 'Delayed by $lateMins mins';
      badgeColor = Colors.orange.shade800;
      badgeIcon = Icons.warning_amber_rounded;
    }

    final firstStopName = bus.stops.isNotEmpty ? _resolveStopName(bus.stops.first) : 'Origin';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.departure_board_rounded, size: 16, color: badgeColor),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Pre-Trip Schedule Check',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 12, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      statusBadgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Scheduled Dep: $depStr ($firstStopName)',
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the Punctuality Status Badge (🟢 On Time (±1 min) | 🟠 Delayed by X mins | 🔵 Running Early).
  Widget _buildPunctualityBadge(DelayType type, int delayMinutes) {
    final Color bg;
    final Color fg;
    final Border border;
    final IconData icon;
    final String label;

    switch (type) {
      case DelayType.onTime:
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green.shade800;
        border = Border.all(color: Colors.green.shade400);
        icon = Icons.check_circle_rounded;
        label = 'On Time (±1 min)';
        break;
      case DelayType.delayed:
        bg = Colors.orange.withValues(alpha: 0.15);
        fg = Colors.orange.shade900;
        border = Border.all(color: Colors.orange.shade400);
        icon = Icons.warning_amber_rounded;
        label = 'Delayed by $delayMinutes min${delayMinutes == 1 ? '' : 's'}';
        break;
      case DelayType.early:
        final absMins = delayMinutes.abs();
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue.shade800;
        border = Border.all(color: Colors.blue.shade400);
        icon = Icons.fast_forward_rounded;
        label = 'Running Early ($absMins min${absMins == 1 ? '' : 's'})';
        break;
      case DelayType.scheduled:
        bg = AppColors.outlineVariant.withValues(alpha: 0.2);
        fg = AppColors.onSurfaceVariant;
        border = Border.all(color: AppColors.outlineVariant);
        icon = Icons.schedule_rounded;
        label = 'Scheduled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a metric comparison box displaying scheduled vs ETA times.
  Widget _buildTimeComparisonBox({
    required String label,
    required String time,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Visual horizontal Delay Meter gauge with 3 color-coded zones and a needle pointer.
  Widget _buildDelayMeterGauge(int delayMinutes) {
    const minMins = -5.0;
    const maxMins = 15.0;
    final clamped = delayMinutes.clamp(minMins.toInt(), maxMins.toInt()).toDouble();
    final fraction = (clamped - minMins) / (maxMins - minMins);

    final delayColor = _getDelayColor(DelayEtaCalculator.getDelayType(delayMinutes));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Running Early',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
            ),
            Text(
              'On Time Target',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700),
            ),
            Text(
              'Delayed',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            final pointerLeft = (fraction * trackWidth).clamp(8.0, trackWidth - 8.0) - 8.0;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // 3-zone gradient track
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: const LinearGradient(
                      stops: [0.0, 0.2, 0.35, 0.45, 0.6, 1.0],
                      colors: [
                        Colors.blue,
                        Colors.lightBlueAccent,
                        Colors.green,
                        Colors.green,
                        Colors.orange,
                        Colors.deepOrange,
                      ],
                    ),
                  ),
                ),
                // Current variance pointer marker
                Positioned(
                  left: pointerLeft,
                  top: -4,
                  child: Container(
                    width: 16,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: delayColor,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('-5m', style: TextStyle(fontSize: 9, color: AppColors.onSurfaceVariant.withValues(alpha: 0.7))),
            Text('0 (On Schedule)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.green.shade800)),
            Text('+15m', style: TextStyle(fontSize: 9, color: AppColors.onSurfaceVariant.withValues(alpha: 0.7))),
          ],
        ),
      ],
    );
  }

  static Color _getDelayColor(DelayType type) {
    switch (type) {
      case DelayType.onTime:
        return Colors.green.shade700;
      case DelayType.delayed:
        return Colors.orange.shade800;
      case DelayType.early:
        return Colors.blue.shade700;
      case DelayType.scheduled:
        return AppColors.outline;
    }
  }

  static String _formatVariance(int delayMinutes) {
    if (delayMinutes == 0) return '0 min';
    if (delayMinutes > 0) return '+$delayMinutes min late';
    return '$delayMinutes min early';
  }

  Widget _buildRouteSelectorCard() {
    final currentUserId = _authService.currentUser?.uid ?? 'operator_dev';
    final isAssignedToMe =
        _currentBus != null && _currentBus!.driverId == currentUserId;
    final isUnassigned = _currentBus == null ||
        _currentBus!.driverId == null ||
        _currentBus!.driverId!.isEmpty;

    // Sort buses: In Progress first, then Upcoming (nearest first), then Departed
    final sortedBuses = List<Bus>.from(_availableBuses);
    sortedBuses.sort((a, b) {
      final statusA = _getBusRunStatus(a);
      final statusB = _getBusRunStatus(b);
      return statusA.sortKey.compareTo(statusB.sortKey);
    });

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_bus, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Select Bus Run',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (isAssignedToMe)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.shade600),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified,
                            size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Assigned to You',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isUnassigned)
                  TextButton.icon(
                    onPressed: _claimBusAssignment,
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Assign to Me',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                  )
                else
                  TextButton.icon(
                    onPressed: _claimBusAssignment,
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: Text(
                      'Reassign to Me',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.amber.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_selectedBusId),
              initialValue: sortedBuses.any((b) => b.id == _selectedBusId)
                  ? _selectedBusId
                  : (sortedBuses.isNotEmpty
                      ? sortedBuses.first.id
                      : null),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              isExpanded: true,
              items: sortedBuses.map((b) {
                final isMyBus = b.driverId == currentUserId;
                final status = _getBusRunStatus(b);
                final depTime = b.effectiveDepartureTime;
                final origin = b.stops.isNotEmpty ? _resolveStopName(b.stops.first) : '';
                final dest = b.stops.length > 1 ? _resolveStopName(b.stops.last) : '';
                final routeEndpoints = (origin.isNotEmpty && dest.isNotEmpty)
                    ? ' — $origin → $dest'
                    : '';

                return DropdownMenuItem<String>(
                  value: b.id,
                  child: Row(
                    children: [
                      // Status dot
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: status.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      // Route + departure + endpoints
                      Expanded(
                        child: Text(
                          'Bus ${b.routeNo} (Dep: $depTime)$routeEndpoints${isMyBus ? ' ★' : ''}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isMyBus ? FontWeight.bold : FontWeight.normal,
                            color: status.label == 'Departed'
                                ? AppColors.onSurfaceVariant
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: status.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: status.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _isTripActive
                  ? null
                  : (val) {
                      if (val == null) return;
                      _userManuallySelectedBus = true;
                      setState(() {
                        _selectedBusId = val;
                      });
                      _listenToSelectedBus(val);
                    },
            ),
            // Show selected bus route details below the dropdown
            if (_currentBus != null) ...[
              const SizedBox(height: 12),
              _buildSelectedBusInfo(_currentBus!, currentUserId),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds an info row below the dropdown showing the selected bus's route, departure, and status.
  Widget _buildSelectedBusInfo(Bus bus, String currentUserId) {
    final status = _getBusRunStatus(bus);
    final route = _routesMap[bus.routeId];
    final routeName = route?.routeName ?? 'Route ${bus.routeNo}';
    final depTime = bus.effectiveDepartureTime;
    final firstStop = bus.stops.isNotEmpty ? bus.stops.first : '—';
    final lastStop = bus.stops.length > 1 ? bus.stops.last : '—';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: status.color.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(status.icon, size: 18, color: status.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  routeName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.icon, size: 12, color: status.color),
                    const SizedBox(width: 4),
                    Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: status.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                'Departure: $depTime',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.straighten, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '${bus.stops.length} stops',
                style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.trip_origin, size: 12, color: Colors.green),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _resolveStopName(firstStop),
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_forward, size: 12, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              const Icon(Icons.flag, size: 12, color: Colors.red),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _resolveStopName(lastStop),
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Resolves a stop ID to a human-readable station name from the seed data.
  String _resolveStopName(String stopId) {
    final station = SeedData.colomboStations.cast<Station?>().firstWhere(
          (s) => s?.id == stopId,
          orElse: () => null,
        );
    return station?.name ?? stopId.replaceAll('st_', '').replaceAll('_', ' ');
  }

  Widget _buildLiveTelemetryCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.my_location_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Live Telemetry Data',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_currentLat == null || _currentLng == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'GPS inactive. Press Start Trip to acquire live GPS location.',
                  style: TextStyle(color: AppColors.onSurfaceVariant),
                ),
              )
            else ...[
              _buildTelemetryRow(
                'Latitude:',
                _currentLat!.toStringAsFixed(6),
                Icons.pin_drop,
              ),
              _buildTelemetryRow(
                'Longitude:',
                _currentLng!.toStringAsFixed(6),
                Icons.map,
              ),
              _buildTelemetryRow(
                'Speed:',
                '${_speed.toStringAsFixed(1)} km/h',
                Icons.speed,
              ),
              _buildTelemetryRow(
                'Heading:',
                '${_heading.toStringAsFixed(0)}° (${_getCardinalDirection(_heading)})',
                Icons.explore,
              ),
              if (_lastUpdateTimestamp != null)
                _buildTelemetryRow(
                  'Last Updated:',
                  '${_lastUpdateTimestamp!.hour.toString().padLeft(2, '0')}:${_lastUpdateTimestamp!.minute.toString().padLeft(2, '0')}:${_lastUpdateTimestamp!.second.toString().padLeft(2, '0')}',
                  Icons.access_time,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilityControlsCard() {
    final currentUserId = _authService.currentUser?.uid ?? 'operator_dev';
    final isAssignedDriver = _currentBus == null ||
        _currentBus!.driverId == null ||
        _currentBus!.driverId == currentUserId;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Vehicle Accessibility Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (!isAssignedDriver)
                  const Text(
                    'Read-only (Not assigned)',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Wheelchair Ramp Operational'),
              subtitle: Text(
                _rampOperational
                    ? 'Ramp operational & verified (Rider status: Safe)'
                    : 'Ramp reported broken (Rider status: Warning)',
              ),
              value: _rampOperational,
              activeThumbColor: AppColors.primaryContainer,
              onChanged: isAssignedDriver ? _onRampToggled : null,
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Low-Floor Elevator / Lift Working'),
              subtitle: const Text('Boarding lift available at stops'),
              value: _elevatorWorking,
              activeThumbColor: AppColors.primaryContainer,
              onChanged: isAssignedDriver
                  ? (val) {
                      setState(() => _elevatorWorking = val);
                      _pushAccessibilityUpdate();
                    }
                  : null,
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Occupancy Level:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  DropdownButton<String>(
                    value: _occupancyLevel,
                    items: _occupancyOptions.map((opt) {
                      return DropdownMenuItem(value: opt, child: Text(opt));
                    }).toList(),
                    onChanged: isAssignedDriver ? _onOccupancyChanged : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardingRequestsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<BoardingRequest>>(
          stream:
              _firestoreService.streamBoardingRequestsForBus(_selectedBusId),
          builder: (context, snapshot) {
            final allRequests = snapshot.data ?? [];
            final pendingRequests = allRequests
                .where((r) => r.status.toLowerCase() == 'pending')
                .toList();
            final completedRequests = allRequests
                .where((r) => r.status.toLowerCase() != 'pending')
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assist_walker_rounded,
                        color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Boarding Assistance Requests',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: pendingRequests.isNotEmpty
                            ? AppColors.primaryContainer
                            : AppColors.outlineVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${pendingRequests.length} Pending',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: pendingRequests.isNotEmpty
                              ? AppColors.onPrimary
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (pendingRequests.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 36,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No pending boarding requests for this bus.',
                            style: TextStyle(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pendingRequests.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final req = pendingRequests[index];
                      return _buildRequestItem(req);
                    },
                  ),
                if (completedRequests.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        'Completed / Acknowledged (${completedRequests.length})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      children: completedRequests.map((req) {
                        final isCompleted =
                            req.status.toLowerCase() == 'completed';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                isCompleted ? Icons.task_alt : Icons.done,
                                size: 16,
                                color: isCompleted
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${req.riderName} at ${req.stopName} (${req.assistanceTypes.join(', ')})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? Colors.green.withValues(alpha: 0.15)
                                      : Colors.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  req.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isCompleted
                                        ? Colors.green.shade800
                                        : Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRequestItem(BoardingRequest req) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                req.riderName,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              Text(
                TimeUtils.formatRelativeTime(req.createdAt),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on,
                  size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Stop: ${req.stopName}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: req.assistanceTypes.map((type) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  type,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () async {
                  await _firestoreService.updateBoardingRequestStatus(
                    req.id,
                    'acknowledged',
                  );
                  _showSnack('Request acknowledged');
                },
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Acknowledge'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () async {
                  await _firestoreService.updateBoardingRequestStatus(
                    req.id,
                    'completed',
                  );
                  _showSnack('Request marked completed');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Complete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lightweight data holder for a bus run's status classification.
class _BusRunStatus {
  const _BusRunStatus({
    required this.label,
    required this.color,
    required this.icon,
    required this.sortKey,
  });

  /// Display label: 'Upcoming', 'In Progress', or 'Departed'.
  final String label;

  /// Colour used for the status dot and badge.
  final Color color;

  /// Icon representing the status.
  final IconData icon;

  /// Numeric sort key (lower = higher in the dropdown).
  final int sortKey;
}
