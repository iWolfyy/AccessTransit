import 'package:flutter/material.dart';

import '../l10n/localization_context.dart';
import '../models/journey_model.dart';
import '../models/service_run.dart';
import '../screens/journey/route_results_screen.dart';
import '../services/journey_service.dart';
import 'save_trip_control.dart';
import 'schedule_change_notice.dart';

/// Historical timetable only. It deliberately has no current capability/GPS or
/// assistance controls when the selected catalogue itinerary is unavailable.
class SavedScheduleRecord extends StatelessWidget {
  const SavedScheduleRecord({
    super.key,
    required this.journey,
    required this.selection,
    required this.service,
    required this.runs,
    this.initialRun,
  });
  final JourneyModel journey;
  final RouteResultItem selection;
  final JourneyService service;
  final Stream<ServiceRun?> runs;
  final ServiceRun? initialRun;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n, snapshot = journey.scheduleSnapshot!;
    return StreamBuilder<ServiceRun?>(
      stream: runs,
      initialData: initialRun,
      builder: (context, state) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            journey.routeTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(l.scheduleSavedRecord),
          if (state.connectionState == ConnectionState.waiting)
            const Center(child: CircularProgressIndicator()),
          Text('${journey.origin} → ${journey.destination}'),
          ScheduleChangeNotice(
            saved: journey,
            run: state.hasError ? null : state.data,
            unavailable:
                state.connectionState != ConnectionState.waiting &&
                (state.hasError || state.data == null),
          ),
          if (journey.departureAt != null)
            Text(scheduleTime(context, journey.departureAt!)),
          if (journey.fareQuote != null)
            Text(
              l.scheduleSavedFare(
                '${journey.fareQuote!.currency} ${(journey.fareQuote!.amountMinor / 100).toStringAsFixed(2)}',
              ),
            ),
          for (final key in snapshot.stops)
            ListTile(
              title: Text(snapshot.names[key]!),
              subtitle: Text(
                snapshot.times[key] == null
                    ? l.scheduleTimeUnknown
                    : scheduleTime(context, snapshot.times[key]!),
              ),
            ),
          SaveTripControl(
            route: selection,
            service: service,
            runId: journey.serviceRunId,
            existing: journey,
          ),
        ],
      ),
    );
  }
}
