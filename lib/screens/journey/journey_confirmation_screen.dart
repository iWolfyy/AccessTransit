import '../../widgets/fare_estimate_text.dart';
import '../../services/transit_catalogue.dart';

import 'package:flutter/material.dart';

import '../../core/utils/time_utils.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/journey_selection.dart';
import '../../models/journey_model.dart';
import '../../services/journey_service.dart';
import '../../widgets/live_accessibility_panel.dart';
import 'live_journey_screen.dart';
import 'route_results_screen.dart';

/// Explicit acknowledged save. Passenger confirmation never creates GPS.
class JourneyConfirmationScreen extends StatefulWidget {
  const JourneyConfirmationScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.route,
    this.service,
    this.onSaved,
  });
  final String origin;
  final String destination;
  final RouteResultItem route;
  final JourneyService? service;
  final void Function(JourneyModel)? onSaved;
  @override
  State<JourneyConfirmationScreen> createState() =>
      _JourneyConfirmationScreenState();
}

class _JourneyConfirmationScreenState extends State<JourneyConfirmationScreen> {
  late final JourneyService service;
  late final String id;
  bool saving = false;
  String? error;
  final _errorKey = GlobalKey();
  @override
  void initState() {
    super.initState();
    service = widget.service ?? JourneyService();
    id = service.newJourneyId();
  }

  Future<void> confirm() async {
    if (saving) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final passenger = service.signedInPassenger;
      if (passenger == null || passenger.isEmpty) {
        throw StateError('Sign in to save and resume your journey.');
      }
      final selected = JourneySelection.create(
        widget.route,
        id: id,
        passengerId: passenger,
      );
      final saved = await service
          .createJourney(selected)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (service.signedInPassenger != passenger ||
          saved.passengerId != passenger ||
          saved.journeyId != id ||
          !saved.isOpen) {
        throw StateError(
          'Journey ownership or status changed. Reopen your saved journeys.',
        );
      }
      if (widget.onSaved != null) {
        widget.onSaved!(saved);
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LiveJourneyScreen(
            origin: saved.origin,
            destination: saved.destination,
            route: widget.route,
            busId: saved.busId,
            passengerId: saved.passengerId,
            journeyId: saved.journeyId,
            savedJourney: saved,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is StateError ? e.message.toString() : 'Journey save is not confirmed. Check your connection and sign-in, then retry.',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final errorContext = _errorKey.currentContext;
          if (mounted && errorContext != null) {
            Scrollable.ensureVisible(errorContext, alignment: 0.3);
          }
        });
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final departure = route.nextDepartureDateTime;
    final arrival = departure?.add(Duration(minutes: route.durationMinutes));
    final vehicle =
        route.busNo?.trim().isNotEmpty == true &&
            route.busNo?.trim() != route.busId
        ? route.busNo!
        : 'Vehicle not specified';
    final requirements = [
      if (route.wheelchairAccessRequired) 'Wheelchair access',
      if (route.stepFreeOnly) 'Step-free',
    ];
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: context.isHighContrast ? 0 : 1,
        centerTitle: true,
        toolbarHeight: MediaQuery.textScalerOf(context).scale(22) > 33
            ? 96
            : 56,
        shape: context.isHighContrast
            ? const Border(bottom: BorderSide(color: Colors.black, width: 2))
            : null,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: context.primaryColor,
            size: 28,
          ),
        ),
        title: Text(
          'Confirm Journey',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: context.textColor,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ConfirmationCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          route.title == route.busId ||
                                  route.busNo?.trim() == route.busId
                              ? 'Route ${route.routeNo ?? route.rawBus?.routeNo ?? 'Unknown'}'
                              : route.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: context.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          vehicle,
                          style: TextStyle(
                            fontSize: 14,
                            color: context.subtextColor,
                          ),
                        ),
                        const Divider(height: 28),
                        _detail(
                          'Boarding',
                          route.origin,
                          icon: Icons.trip_origin_rounded,
                        ),
                        const SizedBox(height: 16),
                        _detail(
                          'Destination',
                          route.destination,
                          icon: Icons.location_on_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ConfirmationCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _heading('Travel schedule'),
                        const SizedBox(height: 16),
                        _detail(
                          'Selected date',
                          route.selectedDate == null
                              ? 'Unknown'
                              : TimeUtils.formatDateString(route.selectedDate!),
                        ),
                        const SizedBox(height: 12),
                        _detail(
                          'Selected time',
                          route.selectedTimeMinutes == null
                              ? 'First available service on selected date'
                              : '${(route.selectedTimeMinutes! ~/ 60).toString().padLeft(2, '0')}:${(route.selectedTimeMinutes! % 60).toString().padLeft(2, '0')}',
                        ),
                        const Divider(height: 28),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final start = _detail(
                              'Timetable departure',
                              _dateTime(departure),
                              icon: Icons.schedule_rounded,
                            );
                            final end = _detail(
                              'Estimated arrival',
                              _dateTime(arrival),
                              icon: Icons.flag_outlined,
                            );
                            if (constraints.maxWidth < 300 ||
                                MediaQuery.textScalerOf(context).scale(14) >
                                    21) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  start,
                                  const SizedBox(height: 16),
                                  end,
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: start),
                                const SizedBox(width: 16),
                                Expanded(child: end),
                              ],
                            );
                          },
                        ),
                        if (route.usesEstimatedTimes) ...[
                          const SizedBox(height: 16),
                          _notice(
                            'Some timetable intervals are missing. Times include model estimates; confirm them with the operator.',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ConfirmationCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _heading('Estimated fare'),
                        const SizedBox(height: 12),
                        FareEstimateText(
                          amount: route.estimatedPriceLkr,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: context.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Prototype estimate. Confirm the actual fare with the operator.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: context.subtextColor,
                          ),
                        ),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(bottom: 8),
                          shape: const Border(),
                          collapsedShape: const Border(),
                          title: Text(
                            'Fare details',
                            style: TextStyle(
                              fontSize: 14,
                              color: context.primaryColor,
                            ),
                          ),
                          children: [
                            FareDisclosureText(
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: context.subtextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (requirements.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _ConfirmationCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _heading('Travel requirements'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: requirements
                                .map(
                                  (value) => Chip(
                                    label: Text(value),
                                    avatar: Icon(
                                      Icons.accessibility_new_rounded,
                                      size: 18,
                                      color: context.primaryColor,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _notice(
                    'Saving a journey does not book a seat or confirm that the bus is running. Review current condition evidence.',
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      key: _errorKey,
                      liveRegion: true,
                      child: _notice(error!, failed: true),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: saving || TransitCatalogue.demo ? null : confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: Size(48, context.buttonHeight),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      saving ? 'Saving journey...' : 'Confirm and save journey',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  LiveAccessibilityPanel(
                    busId: route.busId,
                    origin: route.origin,
                    destination: route.destination,
                    originId: route.fromStationId,
                    destinationId: route.toStationId,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dateTime(DateTime? value) => value == null
      ? 'Unknown'
      : '${TimeUtils.formatDateString(value)}, ${TimeUtils.formatTimeString(value)}';

  Widget _heading(String value) => Semantics(
    header: true,
    child: Text(
      value,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: context.textColor,
      ),
    ),
  );

  Widget _detail(String label, String value, {IconData? icon}) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (icon != null) ...[
        Icon(icon, size: 20, color: context.primaryColor),
        const SizedBox(width: 12),
      ],
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: context.subtextColor),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: context.textColor,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _notice(String value, {bool failed = false}) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        failed ? Icons.error_outline_rounded : Icons.info_outline_rounded,
        size: 20,
        color: failed && !context.isHighContrast
            ? AppColors.error
            : context.primaryColor,
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          value,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: failed && !context.isHighContrast
                ? AppColors.error
                : context.subtextColor,
          ),
        ),
      ),
    ],
  );
}

/// Uses the existing app card colors and geometry; no global theme override.
class _ConfirmationCard extends StatelessWidget {
  const _ConfirmationCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
    color: context.cardColor,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: context.isHighContrast
            ? Colors.black
            : AppColors.outlineVariant.withValues(alpha: .6),
        width: context.isHighContrast ? 2 : 1,
      ),
    ),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}
