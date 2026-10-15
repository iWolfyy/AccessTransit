import 'evidence_refresh.dart';

import 'package:flutter/material.dart';

import '../models/bus.dart';
import '../core/utils/time_utils.dart';

/// Vehicle capability and an attributed operational observation are separate facts.
class BusRampObservation extends StatelessWidget {
  const BusRampObservation({super.key, this.bus, this.currentTime});
  final Bus? bus;
  final DateTime? currentTime;

  @override
  Widget build(BuildContext context) => currentTime != null
      ? _buildAtTime(context, currentTime!)
      : EvidenceRefresh(buses: [?bus], builder: _buildAtTime);

  Widget _buildAtTime(BuildContext context, DateTime now) {
    final checkedAt = bus?.rampCheckedAt;
    final displayCheck = checkedAt != null && !checkedAt.isAfter(now)
        ? checkedAt
        : null;
    final condition = bus?.rampCondition(currentTime: now);
    final label = condition == true
        ? 'Working observed'
        : condition == false
        ? 'Broken reported - unresolved warning'
        : 'Unknown - a new check is required';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ramp capability: ${bus == null
              ? 'Unknown'
              : bus!.hasRamp
              ? 'Equipped'
              : 'Not listed'}',
        ),
        Text('Ramp operational condition: $label'),
        Text(
          'Ramp last checked: ${TimeUtils.formatRelativeTime(displayCheck, clock: now)}',
        ),
        Text(
          'Ramp observation source: ${bus?.rampCheckedBy?.trim().isNotEmpty == true ? bus!.rampCheckedBy : 'Unknown'}',
        ),
        const Text(
          'A working observation does not resolve existing community barriers.',
        ),
      ],
    );
  }
}
