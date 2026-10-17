import 'accessible_tap_target.dart';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../l10n/localization_context.dart';
import '../l10n/driver_presentation.dart';

/// Edits a delay notice using stable reason values, regardless of UI language.
class DriverDelaySheet extends StatefulWidget {
  const DriverDelaySheet({
    super.key,
    this.currentReason,
    this.currentMinutes = 5,
    required this.onSubmit,
  });
  final String? currentReason;
  final int currentMinutes;
  final void Function(String reason, int minutes) onSubmit;
  @override
  State<DriverDelaySheet> createState() => _DriverDelaySheetState();
}

class _DriverDelaySheetState extends State<DriverDelaySheet> {
  late int selectedMinutes = widget.currentMinutes > 0
      ? widget.currentMinutes
      : 5;
  late String selectedReason = widget.currentReason ?? 'Traffic Congestion';
  final delayOptions = [5, 10, 15, 20, 30];
  final reasons = [
    {'label': 'Traffic Congestion', 'icon': Icons.traffic_rounded},
    {'label': 'Heavy Rain / Flooding', 'icon': Icons.water_drop_rounded},
    {'label': 'Accident Ahead', 'icon': Icons.car_crash_rounded},
    {'label': 'Road Construction', 'icon': Icons.construction_rounded},
    {'label': 'Mechanical Breakdown', 'icon': Icons.build_rounded},
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
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
                  color: context.isHighContrast
                      ? Colors.white
                      : Colors.orange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.traffic_rounded,
                  color: context.isHighContrast
                      ? Colors.black
                      : Colors.deepOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.driverDelayTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      context.l10n.driverDelayHelp,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.subtextColor,
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
          Text(
            context.l10n.driverDelayTime,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: delayOptions.map((mins) {
              final isSelected = selectedMinutes == mins;
              return AccessibleTapTarget(
                child: ChoiceChip(
                  label: Text(context.l10n.driverMinuteOption(mins)),
                  selected: isSelected,
                  selectedColor: context.isHighContrast
                      ? Colors.white
                      : Colors.orange.shade100,
                  labelStyle: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: context.isHighContrast
                        ? Colors.black
                        : isSelected
                        ? Colors.orange.shade900
                        : AppColors.onSurface,
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        selectedMinutes = mins;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.driverDelayReason,
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

              return AccessibleTapTarget(
                child: ChoiceChip(
                  avatar: Icon(
                    icon,
                    size: 16,
                    color: context.isHighContrast
                        ? Colors.black
                        : isSelected
                        ? Colors.orange.shade900
                        : AppColors.onSurfaceVariant,
                  ),
                  label: Text(context.driverText(label)),
                  selected: isSelected,
                  selectedColor: context.isHighContrast
                      ? Colors.white
                      : Colors.orange.shade100,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: context.isHighContrast
                        ? Colors.black
                        : isSelected
                        ? Colors.orange.shade900
                        : AppColors.onSurface,
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        selectedReason = label;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => widget.onSubmit(selectedReason, selectedMinutes),
            style: FilledButton.styleFrom(
              backgroundColor: context.isHighContrast
                  ? context.primaryColor
                  : const Color(0xFF9B2C00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.broadcast_on_personal_rounded),
            label: Text(
              context.l10n.driverBroadcastDelay(selectedMinutes),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  );
}
