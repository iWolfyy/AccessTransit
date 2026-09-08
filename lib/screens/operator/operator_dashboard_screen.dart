import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/bus_location_model.dart';
import '../../services/auth_service.dart';
import '../../services/bus_tracking_service.dart';

/// Screen for Bus Operators to broadcast real-time GPS telemetry and vehicle status.
class OperatorDashboardScreen extends StatefulWidget {
  const OperatorDashboardScreen({super.key});

  @override
  State<OperatorDashboardScreen> createState() =>
      _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState extends State<OperatorDashboardScreen> {
  final BusTrackingService _trackingService = BusTrackingService();
  final AuthService _authService = AuthService();

  String _selectedBusId = 'bus_42';
  String _selectedRouteNumber = '42';
  String _selectedRouteName = 'Express Downtown';
  String _nextStop = 'Central Station';

  bool _isBroadcasting = false;
  bool _rampOperational = true;
  bool _elevatorWorking = true;
  String _occupancyLevel = 'Moderate';

  double _currentLat = 6.9271;
  double _currentLng = 79.8612;
  double _speed = 24.5;
  int _etaMinutes = 3;

  Timer? _simulationTimer;
  int _simStep = 0;

  static const List<Map<String, String>> _routes = [
    {
      'busId': 'bus_42',
      'number': '42',
      'name': 'Express Downtown',
      'nextStop': 'Central Station',
    },
    {
      'busId': 'bus_101',
      'number': '101',
      'name': 'Coastal Route',
      'nextStop': 'South Terminal',
    },
    {
      'busId': 'bus_15',
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
    _simulationTimer?.cancel();
    super.dispose();
  }

  void _toggleBroadcasting() {
    setState(() {
      _isBroadcasting = !_isBroadcasting;
    });

    if (_isBroadcasting) {
      _startTelemetryBroadcast();
      _showSnack('Live GPS broadcasting STARTED for Bus $_selectedRouteNumber');
    } else {
      _simulationTimer?.cancel();
      _trackingService.stopBroadcasting(_selectedBusId);
      _showSnack('Live GPS broadcasting STOPPED');
    }
  }

  void _startTelemetryBroadcast() {
    _sendUpdate();
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_isBroadcasting) return;
      setState(() {
        _simStep++;
        _currentLat += 0.0005 * (_simStep % 2 == 0 ? 1 : 0.8);
        _currentLng += 0.0004 * (_simStep % 3 == 0 ? 0.9 : 1.1);
        _speed = 20.0 + (_simStep % 15);
        _etaMinutes = (5 - (_simStep % 5)).clamp(1, 12);
      });
      _sendUpdate();
    });
  }

  Future<void> _sendUpdate() async {
    final user = _authService.currentUser;
    final model = BusLocationModel(
      busId: _selectedBusId,
      routeNumber: _selectedRouteNumber,
      routeName: _selectedRouteName,
      operatorId: user?.uid ?? 'operator_dev',
      operatorName: user?.displayName ?? 'Operator Drive',
      latitude: _currentLat,
      longitude: _currentLng,
      speed: _speed,
      nextStop: _nextStop,
      etaMinutes: _etaMinutes,
      rampOperational: _rampOperational,
      elevatorWorking: _elevatorWorking,
      occupancyLevel: _occupancyLevel,
      isBroadcasting: true,
    );

    await _trackingService.updateBusTelemetry(model);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.primaryContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Operator Dashboard'),
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final nav = Navigator.of(context);
              if (_isBroadcasting) {
                await _trackingService.stopBroadcasting(_selectedBusId);
              }
              await _authService.logout();
              if (!mounted) return;
              nav.pop();
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
            _buildBroadcastStatusCard(),
            const SizedBox(height: 16),
            _buildRouteSelectorCard(),
            const SizedBox(height: 16),
            _buildAccessibilityControlsCard(),
            const SizedBox(height: 16),
            _buildTelemetryPreviewCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _isBroadcasting
          ? AppColors.primaryContainer
          : AppColors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              _isBroadcasting ? Icons.sensors : Icons.sensors_off,
              size: 48,
              color: _isBroadcasting
                  ? AppColors.onPrimary
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              _isBroadcasting
                  ? 'BROADCASTING LIVE TELEMETRY'
                  : 'GPS Broadcasting Offline',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _isBroadcasting
                    ? AppColors.onPrimary
                    : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isBroadcasting
                  ? 'Transmitting live GPS, speed, and accessibility updates to passengers.'
                  : 'Press button below to start sharing bus telemetry with commuters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _isBroadcasting
                    ? AppColors.onPrimary.withValues(alpha: 0.9)
                    : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _toggleBroadcasting,
                style: FilledButton.styleFrom(
                  backgroundColor: _isBroadcasting
                      ? AppColors.error
                      : AppColors.secondary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  _isBroadcasting ? Icons.stop_circle : Icons.play_circle_fill,
                ),
                label: Text(
                  _isBroadcasting
                      ? 'Stop Broadcasting'
                      : 'Start Live GPS Broadcasting',
                  style: const TextStyle(
                    fontSize: 16,
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
            const Text(
              'Select Assigned Vehicle Route',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
              onChanged: _isBroadcasting
                  ? null
                  : (val) {
                      if (val == null) return;
                      final route = _routes.firstWhere(
                        (r) => r['busId'] == val,
                      );
                      setState(() {
                        _selectedBusId = val;
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
              'Live Accessibility & Status Controls',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Wheelchair Ramp Operational'),
              subtitle: const Text('Confirm ramp mechanism is fully working'),
              value: _rampOperational,
              activeThumbColor: AppColors.primaryContainer,
              onChanged: (val) {
                setState(() => _rampOperational = val);
                if (_isBroadcasting) _sendUpdate();
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
                if (_isBroadcasting) _sendUpdate();
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
                      if (_isBroadcasting) _sendUpdate();
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

  Widget _buildTelemetryPreviewCard() {
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
              'Live Telemetry Data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('Latitude: ${_currentLat.toStringAsFixed(5)}'),
            Text('Longitude: ${_currentLng.toStringAsFixed(5)}'),
            Text('Speed: ${_speed.toStringAsFixed(1)} km/h'),
            Text('Next Stop: $_nextStop (ETA: $_etaMinutes mins)'),
          ],
        ),
      ),
    );
  }
}
