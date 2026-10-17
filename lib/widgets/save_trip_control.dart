import 'dart:convert';

import '../logic/tariff_fare.dart';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../logic/journey_selection.dart';
import '../l10n/localization_context.dart';
import '../models/journey_model.dart';
import '../models/service_run.dart';
import '../screens/journey/route_results_screen.dart';
import '../services/journey_service.dart';

/// Optional, acknowledged bookmark. Opening details never performs a write.
class SaveTripControl extends StatefulWidget {
  const SaveTripControl({
    super.key,
    required this.route,
    required this.service,
    this.runId,
    this.run,
    this.existing,
    this.fareQuote,
    this.fareValidated = false,
  });
  final RouteResultItem route;
  final JourneyService service;
  final String? runId;
  final ServiceRun? run;
  final JourneyModel? existing;
  final TariffFareQuote? fareQuote;
  final bool fareValidated;

  static String selectionId(RouteResultItem r, String owner, String? runId) =>
      'saved_${sha256.convert(utf8.encode(jsonEncode([owner, r.busId, runId, r.fromStationId, r.toStationId, r.nextDepartureDateTime?.toUtc().toIso8601String(), r.selectedDate?.toIso8601String(), r.selectedTimeMinutes, r.wheelchairAccessRequired, r.stepFreeOnly])))}';

  @override
  State<SaveTripControl> createState() => _SaveTripControlState();
}

class _SaveTripControlState extends State<SaveTripControl> {
  late final String? owner = widget.service.signedInPassenger;
  late final String id =
      widget.existing?.journeyId ??
      SaveTripControl.selectionId(widget.route, owner ?? '', widget.runId);
  late Stream<JourneyModel?> updates = owner == null
      ? Stream.value(null)
      : widget.service.watchJourney(id);
  JourneyModel? acknowledged;
  bool busy = false;
  String? error;

  Future<void> change(bool remove) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (owner == null || owner != widget.service.signedInPassenger) {
        throw StateError('Sign in with the account saving this trip.');
      }
      if (remove) {
        await widget.service
            .removeJourney(id)
            .timeout(const Duration(seconds: 15));
      } else {
        final saved = await widget.service
            .createJourney(
              JourneySelection.create(
                widget.route,
                id: id,
                passengerId: owner!,
                serviceRunId: widget.runId,
                run: widget.run,
                fareQuote: widget.fareQuote,
                overrideFareQuote: widget.fareValidated,
              ),
            )
            .timeout(const Duration(seconds: 15));
        if (saved.passengerId != owner || saved.journeyId != id) {
          throw StateError('Saved trip acknowledgement did not match.');
        }
        acknowledged = saved;
      }
      if (!mounted || widget.service.signedInPassenger != owner) {
        return;
      }
      setState(() {
        if (remove) acknowledged = null;
        updates = widget.service.watchJourney(id);
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is StateError ? e.message.toString() : 'Save change is not confirmed. Check your connection and retry.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<JourneyModel?>(
    stream: updates,
    builder: (context, snapshot) {
      final record =
          snapshot.connectionState == ConnectionState.waiting ||
              snapshot.hasError
          ? acknowledged ?? widget.existing
          : snapshot.data;
      final saved = record != null && record.passengerId == owner;
      final sameOwner =
          owner != null && owner == widget.service.signedInPassenger;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (saved) Text(context.l10n.savedTrip),
          Text(context.l10n.sharedSaveDisclosure),
          const SizedBox(height: 8),
          if (error != null)
            Text(switch (error) {
              'Sign in with the account saving this trip.' =>
                context.l10n.sharedSaveOwner,
              'Saved trip acknowledgement did not match.' =>
                context.l10n.sharedSaveMismatch,
              _ => context.l10n.sharedSaveError,
            }),
          if (snapshot.hasError && error == null)
            Text(context.l10n.sharedSaveStatusError),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: Size(context.buttonHeight, context.buttonHeight),
            ),
            onPressed: busy || !sameOwner ? null : () => change(saved),
            icon: Icon(
              saved
                  ? Icons.bookmark_remove_outlined
                  : Icons.bookmark_add_outlined,
            ),
            label: Text(
              busy
                  ? context.l10n.sharedSaving
                  : saved
                  ? context.l10n.removeSavedTrip
                  : context.l10n.saveTrip,
            ),
          ),
          if (!sameOwner) Text(context.l10n.sharedSaveSignIn),
        ],
      );
    },
  );
}
