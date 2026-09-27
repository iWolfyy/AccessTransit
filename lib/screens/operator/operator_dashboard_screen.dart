import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/time_utils.dart';
import '../../data/seed_data.dart';
import '../../models/boarding_request.dart';
import '../../models/bus.dart';
import '../../models/bus_location_model.dart';
import '../../models/enums/bus_status.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/live_bus_service.dart';
import '../../services/location_service.dart';
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

  String _selectedBusId = 'bus_138_outbound';
  String _selectedRouteId = 'route_138';
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
    _subscribeToBuses();
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
          final myBus = list.cast<Bus?>().firstWhere(
                (b) => b?.driverId != null && b?.driverId == currentUserId,
                orElse: () => null,
              );
          if (myBus != null) {
            _selectedBusId = myBus.id;
          } else if (!_availableBuses.any((b) => b.id == _selectedBusId)) {
            _selectedBusId = _availableBuses.first.id;
          }
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
          _nextStop = bus.stops.last;
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
        nextStop: _nextStop,
        rampOperational: _rampOperational,
        elevatorWorking: _elevatorWorking,
        occupancyLevel: _occupancyLevel,
        isBroadcasting: true,
      );

      await _liveBusService.startOrUpdateLiveLocation(initialBusModel);

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
        'Trip Started! Broadcasting live GPS for Bus $_selectedRouteNumber',
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

    // 2. Update Firestore status to completed and turn off broadcasting flag
    try {
      await _liveBusService.stopTrip(
        _selectedBusId,
        endStatus: BusStatus.completed,
      );
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

  Widget _buildRouteSelectorCard() {
    final currentUserId = _authService.currentUser?.uid ?? 'operator_dev';
    final isAssignedToMe =
        _currentBus != null && _currentBus!.driverId == currentUserId;
    final isUnassigned = _currentBus == null ||
        _currentBus!.driverId == null ||
        _currentBus!.driverId!.isEmpty;

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
                const Text(
                  'Assigned Bus & Route',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
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
              initialValue: _availableBuses.any((b) => b.id == _selectedBusId)
                  ? _selectedBusId
                  : (_availableBuses.isNotEmpty
                      ? _availableBuses.first.id
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
              items: _availableBuses.map((b) {
                final isMyBus = b.driverId == currentUserId;
                final cleanName =
                    b.id.replaceAll('bus_', '').replaceAll('_', ' ');
                return DropdownMenuItem<String>(
                  value: b.id,
                  child: Text(
                    'Bus ${b.routeNo} — $cleanName${isMyBus ? ' ★ (My Bus)' : ''}',
                    overflow: TextOverflow.ellipsis,
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
          ],
        ),
      ),
    );
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
