import 'package:flutter/material.dart';

import '../../core/utils/time_utils.dart';
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
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final departure = route.nextDepartureDateTime;
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Journey')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(route.title, style: Theme.of(context).textTheme.titleLarge),
          Text('Vehicle: ${route.busNo ?? route.busId}'),
          Text(
            'Boarding: ${route.origin} (${route.fromStationId ?? 'Unknown'})',
          ),
          Text(
            'Destination: ${route.destination} (${route.toStationId ?? 'Unknown'})',
          ),
          if (route.selectedDate != null)
            Text(
              'Selected date: ${TimeUtils.formatDateString(route.selectedDate!)}',
            ),
          Text(
            route.selectedTimeMinutes == null
                ? 'Selected time: First available service on selected date'
                : 'Selected time: ${(route.selectedTimeMinutes! ~/ 60).toString().padLeft(2, '0')}:${(route.selectedTimeMinutes! % 60).toString().padLeft(2, '0')}',
          ),
          Text(
            departure == null
                ? 'Departure: Unknown'
                : 'Timetable departure: ${TimeUtils.formatDateString(departure)}, ${TimeUtils.formatTimeString(departure)}',
          ),
          if (departure != null)
            Text(
              'Estimated arrival: ${TimeUtils.formatDateString(departure.add(Duration(minutes: route.durationMinutes)))}, ${TimeUtils.formatTimeString(departure.add(Duration(minutes: route.durationMinutes)))}',
            ),
          Text(
            'Estimated fare: LKR ${route.estimatedPriceLkr} - model estimate; confirm with the operator.',
          ),
          if (route.wheelchairAccessRequired)
            const Text('Travel requirement: Wheelchair access'),
          if (route.stepFreeOnly) const Text('Travel requirement: Step-free'),
          const SizedBox(height: 16),
          const Text(
            'Saving a journey does not book a seat or confirm that the bus is running. Review current condition evidence.',
          ),
          const SizedBox(height: 16),
          if (error != null) Text(error!),
          FilledButton(
            onPressed: saving ? null : confirm,
            child: Text(
              saving ? 'Saving journey...' : 'Confirm and save journey',
            ),
          ),
          const SizedBox(height: 16),
          LiveAccessibilityPanel(
            busId: route.busId,
            origin: route.origin,
            destination: route.destination,
            originId: route.fromStationId,
            destinationId: route.toStationId,
          ),
        ],
      ),
    );
  }
}
