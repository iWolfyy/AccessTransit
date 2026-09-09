import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_colors.dart';
import '../../models/bus_location_model.dart';
import '../../models/enums/bus_status.dart';
import '../../services/auth_service.dart';
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

  StreamSubscription<Position>? _positionSubscription;
  Timer? _tripTimer;
  Duration _tripDuration = Duration.zero;

  bool _isTripActive = false;
  bool _isInitializing = false;

  String _selectedBusId = 'bus_42';
  String _selectedRouteId = 'route_42';
  String _selectedRouteNumber = '42';
  String _selectedRouteName = 'Express Downtown';
  String _nextStop = 'Central Station';

  bool _rampOperational = true;
  bool _elevatorWorking = true;
  String _occupancyLevel = 'Moderate';

  double? _currentLat;
  double? _currentLng;
  double _speed = 0.0; // km/h
  double _heading = 0.0;
  DateTime? _lastUpdateTimestamp;

  static const List<Map<String, String>> _routes = [
    {
      'busId': 'bus_01',
      'routeId': 'route_01',
      'number': '01',
      'name': 'Route 01: Colombo → Kandy',
      'nextStop': 'Kandy Bus Stand',
    },
    {
      'busId': 'bus_02',
      'routeId': 'route_02',
      'number': '02',
      'name': 'Route 02: Colombo → Galle',
      'nextStop': 'Galle Bus Stand',
    },
    {
      'busId': 'bus_87',
      'routeId': 'route_87',
      'number': '87',
      'name': 'Route 87: Colombo → Jaffna',
      'nextStop': 'Jaffna Station',
    },
    {
      'busId': 'bus_49',
      'routeId': 'route_49',
      'number': '49',
      'name': 'Route 49: Colombo → Trincomalee',
      'nextStop': 'Trincomalee Bus Stand',
    },
    {
      'busId': 'bus_99',
      'routeId': 'route_99',
      'number': '99',
      'name': 'Route 99: Colombo → Badulla',
      'nextStop': 'Badulla Main Terminal',
    },
    {
      'busId': 'bus_42',
      'routeId': 'route_42',
      'number': '42',
      'name': 'Express Downtown',
      'nextStop': 'Central Station',
    },
    {
      'busId': 'bus_101',
      'routeId': 'route_101',
      'number': '101',
      'name': 'Coastal Route',
      'nextStop': 'South Terminal',
    },
    {
      'busId': 'bus_15',
      'routeId': 'route_15',
      'number': '15',
      'name': 'Airport Link',
      'nextStop': 'City Hospital',
    },
  ];

  static const List<String> _occupancyOptions = [
    'Low',
    'Moderate',
    'High',
    'Full',
  ];

  @override
  void dispose() {
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
      final operatorName = (currentUser?.displayName != null &&
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

      _showSnack('Trip Started! Broadcasting live GPS for Bus $_selectedRouteNumber');
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
          backgroundColor:
              isError ? AppColors.error : AppColors.primaryContainer,
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
                  _isTripActive ? Icons.sensors_rounded : Icons.sensors_off_rounded,
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
                  _isTripActive
                      ? 'TRIP IN PROGRESS'
                      : 'TRIP INACTIVE',
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
                if (_isTripActive) ...[
                  const Spacer(),
                  const Chip(
                    label: Text('Locked during trip', style: TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedBusId,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              items: _routes.map((r) {
                return DropdownMenuItem<String>(
                  value: r['busId'],
                  child: Text('Bus ${r['number']} — ${r['name']}'),
                );
              }).toList(),
              onChanged: _isTripActive
                  ? null
                  : (val) {
                      if (val == null) return;
                      final route = _routes.firstWhere(
                        (r) => r['busId'] == val,
                      );
                      setState(() {
                        _selectedBusId = val;
                        _selectedRouteId = route['routeId']!;
                        _selectedRouteNumber = route['number']!;
                        _selectedRouteName = route['name']!;
                        _nextStop = route['nextStop']!;
                      });
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
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vehicle Accessibility Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Wheelchair Ramp Operational'),
              subtitle: const Text('Confirm ramp mechanism is fully functional'),
              value: _rampOperational,
              activeThumbColor: AppColors.primaryContainer,
              onChanged: (val) {
                setState(() => _rampOperational = val);
                _pushAccessibilityUpdate();
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Low-Floor Elevator / Lift Working'),
              subtitle: const Text('Boarding lift available at stops'),
              value: _elevatorWorking,
              activeThumbColor: AppColors.primaryContainer,
              onChanged: (val) {
                setState(() => _elevatorWorking = val);
                _pushAccessibilityUpdate();
              },
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
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => _occupancyLevel = val);
                      _pushAccessibilityUpdate();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
