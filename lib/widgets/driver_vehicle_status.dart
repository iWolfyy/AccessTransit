import '../core/theme/app_theme.dart';
import 'accessible_dropdown.dart';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../l10n/localization_context.dart';
import '../l10n/driver_presentation.dart';

/// Shows observed coordinates and shared acknowledgement separately.
class DriverTelemetryCard extends StatelessWidget {
  const DriverTelemetryCard({
    super.key,
    this.latitude,
    this.longitude,
    required this.speed,
    required this.heading,
    this.lastPublishedAt,
    this.lastFixAt,
    required this.active,
    required this.publicationStatus,
    required this.now,
  });
  final double? latitude, longitude;
  final double speed, heading;
  final DateTime? lastPublishedAt, lastFixAt;
  final bool active;
  final String publicationStatus;
  final DateTime now;
  static String cardinalDirection(double heading) {
    if (heading < 0) return 'N/A';
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return directions[((heading + 22.5) / 45).floor() % 8];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.my_location_rounded, color: context.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.driverTelemetry,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (latitude == null || longitude == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  context.l10n.driverGpsInactive,
                  style: TextStyle(color: context.subtextColor),
                ),
              )
            else ...[
              _buildTelemetryRow(
                context,
                'Latitude:',
                latitude!.toStringAsFixed(6),
                Icons.pin_drop,
              ),
              _buildTelemetryRow(
                context,
                'Longitude:',
                longitude!.toStringAsFixed(6),
                Icons.map,
              ),
              _buildTelemetryRow(
                context,
                'Speed:',
                '${speed.toStringAsFixed(1)} km/h',
                Icons.speed,
              ),
              _buildTelemetryRow(
                context,
                'Heading:',
                '${heading.toStringAsFixed(0)}° (${cardinalDirection(heading)})',
                Icons.explore,
              ),
              Text(
                lastPublishedAt != null &&
                        now.difference(lastPublishedAt!) >
                            const Duration(minutes: 5) &&
                        active
                    ? context.l10n.driverGpsStale(
                        context.driverText(publicationStatus),
                      )
                    : context.driverText(publicationStatus),
                style: const TextStyle(fontSize: 12),
              ),
              if (lastPublishedAt != null)
                Text(
                  context.l10n.driverLastReceipt(
                    '${lastPublishedAt!.hour}:${lastPublishedAt!.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              if (lastFixAt != null)
                _buildTelemetryRow(
                  context,
                  'Local GPS fix:',
                  '${lastFixAt!.hour.toString().padLeft(2, '0')}:${lastFixAt!.minute.toString().padLeft(2, '0')}:${lastFixAt!.second.toString().padLeft(2, '0')}',
                  Icons.access_time,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.primaryColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              context.driverText(label),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
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
}

/// Only display labels are localized; callbacks receive stable observation values.
class DriverVehicleStatusCard extends StatelessWidget {
  const DriverVehicleStatusCard({
    super.key,
    required this.busId,
    required this.isAssignedDriver,
    required this.rampOperational,
    required this.liftWorking,
    required this.busy,
    required this.occupancy,
    required this.onRamp,
    required this.onOccupancy,
  });
  final String busId, occupancy;
  final bool isAssignedDriver, liftWorking, busy;
  final bool? rampOperational;
  final ValueChanged<bool> onRamp;
  final ValueChanged<String?> onOccupancy;
  static const occupancyOptions = ['Low', 'Medium', 'High'];
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  context.l10n.driverAccessibility,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (!isAssignedDriver)
                  Text(
                    context.l10n.driverReadOnly,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.errorColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<bool>(
              key: ValueKey('ramp-$busId-$rampOperational'),
              initialValue: rampOperational,
              isExpanded: true,
              itemHeight: null,
              decoration: InputDecoration(
                labelText: context.l10n.driverRampObservation,
              ),
              hint: Text(context.l10n.driverUnknownRamp),
              items: [
                AccessibleDropdownMenuItem(
                  value: true,
                  child: Text(context.l10n.driverWorkingObserved),
                ),
                AccessibleDropdownMenuItem(
                  value: false,
                  child: Text(context.l10n.driverBrokenObserved),
                ),
              ],
              onChanged: isAssignedDriver && !busy
                  ? (value) {
                      if (value != null) onRamp(value);
                    }
                  : null,
            ),
            const Divider(),
            SwitchListTile(
              title: Text(context.l10n.driverLift),
              subtitle: Text(context.l10n.driverStopLiftHelp),
              value: liftWorking,
              activeThumbColor: AppColors.primaryContainer,
              onChanged: null,
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.driverOccupancy,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  DropdownButton<String>(
                    isExpanded: true,
                    itemHeight: null,
                    value: occupancy,
                    items: occupancyOptions.map((opt) {
                      return AccessibleDropdownMenuItem(
                        value: opt,
                        child: Text(context.driverText(opt)),
                      );
                    }).toList(),
                    onChanged: isAssignedDriver && !busy ? onOccupancy : null,
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
