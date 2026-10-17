import 'package:flutter/material.dart';

import '../logic/transit_time.dart';
import '../l10n/shared_presentation.dart';
import '../models/journey_model.dart';
import '../services/journey_service.dart';
import '../screens/journey/journey_resume_screen.dart';
import '../screens/journey/saved_trips_screen.dart';
import '../l10n/localization_context.dart';

/// Owner-scoped shared recovery; listens while Home remains mounted.
class SavedJourneyPanel extends StatefulWidget {
  const SavedJourneyPanel({
    super.key,
    required this.userId,
    this.service,
    this.onResume,
  });
  final String? userId;
  final JourneyService? service;
  final void Function(JourneyModel)? onResume;
  @override
  State<SavedJourneyPanel> createState() => _SavedJourneyPanelState();
}

class _SavedJourneyPanelState extends State<SavedJourneyPanel> {
  late final JourneyService service = widget.service ?? JourneyService();
  late Stream<JourneyModel?> updates;
  bool saving = false;
  int revision = 0;
  String? error;
  void reset() {
    revision++;
    saving = false;
    error = null;
    updates = widget.userId == null
        ? Stream.value(null)
        : service.watchActiveJourney(widget.userId!);
  }

  @override
  void initState() {
    super.initState();
    reset();
  }

  @override
  void didUpdateWidget(covariant SavedJourneyPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) reset();
  }

  Future<void> finish(JourneyModel journey, bool completed) async {
    if (saving || service.signedInPassenger != journey.passengerId) return;
    final generation = revision;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await (completed
              ? service.completeJourney(journey.journeyId)
              : service.cancelJourney(journey.journeyId))
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      if (mounted &&
          generation == revision &&
          service.signedInPassenger == widget.userId) {
        setState(
          () => error =
              'Journey status change is not confirmed. Retry when connected.',
        );
      }
    } finally {
      if (mounted && generation == revision) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId == null || service.signedInPassenger != widget.userId) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StreamBuilder<JourneyModel?>(
          stream: updates,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(context.l10n.sharedJourneyUpdatesError),
              );
            }
            final journey = snapshot.data;
            if (journey == null ||
                !journey.isOpen ||
                journey.passengerId != widget.userId) {
              return const SizedBox.shrink();
            }
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.sharedSavedJourney,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text('${journey.origin} → ${journey.destination}'),
                    Text(
                      context.l10n.sharedVehicle(
                        journey.busNo ?? journey.busId,
                      ),
                    ),
                    if (journey.departureAt != null)
                      Text(
                        context.l10n.sharedTimetable(
                          '${MaterialLocalizations.of(context).formatMediumDate(TransitTime.civil(journey.departureAt!))}, ${TimeOfDay.fromDateTime(TransitTime.civil(journey.departureAt!)).format(context)}',
                        ),
                      ),
                    if (error != null) Text(context.sharedText(error!)),
                    FilledButton(
                      onPressed: saving
                          ? null
                          : () {
                              if (widget.onResume != null) {
                                widget.onResume!(journey);
                                return;
                              }
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => JourneyResumeScreen(
                                    journey: journey,
                                    service: service,
                                  ),
                                ),
                              );
                            },
                      child: Text(context.l10n.sharedResume),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: saving
                              ? null
                              : () => finish(journey, true),
                          child: Text(context.l10n.sharedComplete),
                        ),
                        TextButton(
                          onPressed: saving
                              ? null
                              : () => finish(journey, false),
                          child: Text(context.l10n.sharedCancelJourney),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        TextButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SavedTripsScreen(service: service),
            ),
          ),
          icon: const Icon(Icons.bookmarks_outlined),
          label: Text(context.l10n.savedTripsViewAll),
        ),
      ],
    );
  }
}
