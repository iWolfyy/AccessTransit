import 'accessible_dropdown.dart';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../l10n/localization_context.dart';
import '../l10n/driver_presentation.dart';
import '../models/service_run.dart';

/// Collects the driver's private reason; validation and publication stay outside.
class DriverLateStartDialog extends StatelessWidget {
  const DriverLateStartDialog({super.key, required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text(context.l10n.driverLateTitle),
    content: TextField(
      controller: controller,
      maxLength: 2000,
      minLines: 2,
      maxLines: 4,
      decoration: InputDecoration(
        helperText: context.l10n.driverLateHelp,
        helperMaxLines: 8,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.profileCancel),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, controller.text.trim()),
        child: Text(context.l10n.driverContinue),
      ),
    ],
  );
}

/// Presentation of dated runs; authorization and acknowledged writes stay in services.
class DriverDatedDepartureCard extends StatelessWidget {
  const DriverDatedDepartureCard({
    super.key,
    required this.runs,
    required this.busId,
    required this.selectedRunId,
    required this.active,
    required this.initializing,
    required this.onSelected,
    this.error,
    this.departureAction,
  });
  final List<ServiceRun> runs;
  final String busId;
  final String? selectedRunId, error;
  final bool active, initializing;
  final ValueChanged<String?> onSelected;
  final Widget? departureAction;
  ServiceRun? get selectedRun =>
      runs.where((r) => r.id == selectedRunId).firstOrNull;
  static String formatTime(DateTime time) {
    final c = ServiceRun.colomboClock(time);
    return '${c.year}-${c.month.toString().padLeft(2, '0')}-${c.day.toString().padLeft(2, '0')} ${c.hour.toString().padLeft(2, '0')}:${c.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.driverDatedDeparture,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (error != null)
            Text(context.driverText(error!))
          else if (runs.isEmpty)
            Text(context.l10n.driverNoRuns)
          else
            DropdownButtonFormField<String>(
              itemHeight: null,
              key: ValueKey('run-$busId-$selectedRunId'),
              initialValue: selectedRunId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: context.l10n.driverColomboDeparture,
              ),
              items: [
                for (final run in runs)
                  AccessibleDropdownMenuItem(
                    value: run.id,
                    child: Text(
                      context.l10n.driverRunOption(
                        formatTime(run.plannedDepartureAt),
                        context.driverRunStatus(run.status),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: active || initializing ? null : onSelected,
            ),
          if (selectedRun != null) ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.driverRunWindow(
                formatTime(selectedRun!.earliestStartAt),
                formatTime(selectedRun!.latestStartAt),
              ),
            ),
            Text(context.l10n.driverBoardingHelp),
          ],
          ?departureAction,
        ],
      ),
    ),
  );
}

/// Mirrors the start window for UI; the backend remains authoritative.
class DriverTripControlCard extends StatelessWidget {
  const DriverTripControlCard({
    super.key,
    required this.active,
    required this.initializing,
    required this.busy,
    required this.selectedRun,
    required this.error,
    required this.publicationStatus,
    required this.duration,
    required this.routeNumber,
    required this.now,
    required this.onStart,
    required this.onStop,
  });
  final bool active, initializing, busy;
  final ServiceRun? selectedRun;
  final String? error;
  final String publicationStatus, routeNumber;
  final Duration duration;
  final DateTime now;
  final VoidCallback onStart, onStop;
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: active
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
                  active ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                  size: 36,
                  color: active
                      ? AppColors.onPrimary
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                if (active) ...[
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
                Flexible(
                  child: Text(
                    active
                        ? context.l10n.driverActive
                        : context.l10n.driverInactive,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: active ? AppColors.onPrimary : AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              active
                  ? context.l10n.driverActiveSummary(
                      context.driverText(publicationStatus),
                      formatDuration(duration),
                    )
                  : context.l10n.driverStartHelp(routeNumber),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: active
                    ? AppColors.onPrimary.withValues(alpha: 0.95)
                    : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: context.buttonHeight,
                minWidth: double.infinity,
              ),
              child: initializing
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton.icon(
                      onPressed:
                          busy ||
                              initializing ||
                              (!active &&
                                  (error != null ||
                                      selectedRun == null ||
                                      (selectedRun!.status == 'scheduled' &&
                                          !selectedRun!.canStartAt(
                                            now.toUtc(),
                                          ))))
                          ? null
                          : (active ? onStop : onStart),
                      style: FilledButton.styleFrom(
                        backgroundColor: active
                            ? AppColors.error
                            : AppColors.secondary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        active
                            ? Icons.stop_circle_rounded
                            : Icons.play_circle_fill_rounded,
                        size: 26,
                      ),
                      label: Text(
                        active
                            ? context.l10n.driverStop
                            : selectedRun?.handoverPending == true
                            ? context.l10n.operationsResume
                            : context.l10n.driverStart,
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
}
