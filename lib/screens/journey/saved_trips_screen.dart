import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../l10n/localization_context.dart';
import '../../logic/transit_time.dart';
import '../../models/journey_model.dart';
import '../../services/journey_service.dart';
import '../../services/accessibility_preferences_service.dart';
import '../../services/firestore_service.dart';
import 'journey_resume_screen.dart';

class SavedTripsScreen extends StatefulWidget {
  const SavedTripsScreen({
    super.key,
    this.service,
    this.onOpen,
    this.repository,
  });
  final JourneyService? service;
  final void Function(JourneyModel)? onOpen;
  final FirestoreService? repository;
  @override
  State<SavedTripsScreen> createState() => _SavedTripsScreenState();
}

class _SavedTripsScreenState extends State<SavedTripsScreen> {
  late final service = widget.service ?? JourneyService();
  late final owner = service.signedInPassenger;
  final boundaries = <SavedJourneyCursor?>[null];
  SavedJourneyPage? page;
  bool loading = false, invalidated = false;
  String? error, busyId;
  int revision = 0;
  StreamSubscription<User?>? auth;
  @override
  void initState() {
    super.initState();
    AccessibilityPreferencesService.instance.addListener(accountChanged);
    try {
      auth = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user?.uid != owner) invalidate();
      });
    } catch (_) {}
    load(reset: true);
  }

  void accountChanged() {
    if (service.signedInPassenger != owner ||
        AccessibilityPreferencesService.instance.userId != owner) {
      invalidate();
    }
  }

  void invalidate() {
    if (!mounted || invalidated) return;
    revision++;
    setState(() {
      invalidated = true;
      page = null;
      error = null;
      busyId = null;
      loading = false;
      boundaries
        ..clear()
        ..add(null);
    });
  }

  @override
  void dispose() {
    revision++;
    auth?.cancel();
    AccessibilityPreferencesService.instance.removeListener(accountChanged);
    super.dispose();
  }

  Future<void> load({
    bool reset = false,
    SavedJourneyCursor? next,
    bool previous = false,
  }) async {
    if (invalidated || owner == null || service.signedInPassenger != owner) {
      invalidate();
      return;
    }
    if (loading && !reset) return;
    final target = reset
        ? <SavedJourneyCursor?>[null]
        : List<SavedJourneyCursor?>.of(boundaries);
    if (previous && target.length > 1) target.removeLast();
    if (next != null) target.add(next);
    final generation = ++revision;
    setState(() {
      loading = true;
      error = null;
      page = null;
      boundaries
        ..clear()
        ..addAll(target);
    });
    try {
      final result = await service.pageSavedJourneys(
        owner!,
        after: target.last,
      );
      if (!mounted || generation != revision || invalidated) return;
      if (service.signedInPassenger != owner) {
        invalidate();
        return;
      }
      setState(() {
        page = result;
        boundaries
          ..clear()
          ..addAll(target);
      });
    } catch (_) {
      if (mounted && generation == revision && !invalidated) {
        setState(() => error = 'load');
      }
    } finally {
      if (mounted && generation == revision) setState(() => loading = false);
    }
  }

  Future<void> open(JourneyModel row) async {
    if (busyId != null || invalidated || service.signedInPassenger != owner) {
      return;
    }
    final generation = revision;
    setState(() {
      busyId = row.journeyId;
      error = null;
    });
    try {
      final fresh = await service
          .getSavedJourney(row.journeyId, owner!)
          .timeout(const Duration(seconds: 15));
      if (!mounted || generation != revision || invalidated) return;
      if (service.signedInPassenger != owner) {
        invalidate();
        return;
      }
      if (fresh == null) {
        await load();
        return;
      }
      if (widget.onOpen != null) {
        widget.onOpen!(fresh);
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => JourneyResumeScreen(
              journey: fresh,
              service: service,
              repository: widget.repository,
            ),
          ),
        );
      }
      if (mounted && !invalidated && generation == revision) {
        await load();
      }
    } catch (_) {
      if (mounted && generation == revision && !invalidated) {
        setState(() => error = 'open');
      }
    } finally {
      if (mounted && busyId == row.journeyId) setState(() => busyId = null);
    }
  }

  Future<void> remove(JourneyModel row) async {
    if (busyId != null || invalidated || service.signedInPassenger != owner) {
      return;
    }
    final generation = revision;
    setState(() {
      busyId = row.journeyId;
      error = null;
    });
    try {
      await service
          .removeJourney(row.journeyId)
          .timeout(const Duration(seconds: 15));
      if (!mounted || generation != revision || invalidated) return;
      if (service.signedInPassenger != owner) {
        invalidate();
        return;
      }
      setState(
        () => page = SavedJourneyPage(
          page!.items.where((j) => j.journeyId != row.journeyId).toList(),
          next: page!.next,
        ),
      );
    } catch (_) {
      if (mounted && generation == revision && !invalidated) {
        setState(() => error = 'remove');
      }
    } finally {
      if (mounted && busyId == row.journeyId) setState(() => busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final denied =
        invalidated || owner == null || service.signedInPassenger != owner;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.savedTripsTitle),
        actions: [
          IconButton(
            tooltip: l.savedTripsRefresh,
            onPressed: denied || busyId != null
                ? null
                : () => load(reset: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: denied
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l.savedTripsAccountChanged),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l.savedTripsHelp),
                if (loading) const Center(child: CircularProgressIndicator()),
                if (error != null)
                  Text(
                    error == 'remove'
                        ? l.savedTripsRemoveError
                        : error == 'open'
                        ? l.savedTripsOpenError
                        : l.savedTripsLoadError,
                  ),
                if (error == 'load')
                  FilledButton(
                    onPressed: () => load(),
                    child: Text(l.savedTripsRetry),
                  ),
                if (!loading && page != null && page!.items.isEmpty)
                  Text(
                    boundaries.length == 1 && page!.next == null
                        ? l.savedTripsEmpty
                        : l.savedTripsEmptyPage,
                  ),
                for (final row in page?.items ?? <JourneyModel>[])
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${row.origin} → ${row.destination}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(row.busNo ?? row.busId),
                          if (row.departureAt != null)
                            Text(
                              '${MaterialLocalizations.of(context).formatMediumDate(TransitTime.civil(row.departureAt!))} · ${TimeOfDay.fromDateTime(TransitTime.civil(row.departureAt!)).format(context)}',
                            ),
                          Text(
                            row.isOpen
                                ? l.savedTrip
                                : row.status == JourneyStatus.completed
                                ? l.savedTripsCompletedRecord
                                : l.savedTripsCancelledRecord,
                          ),
                          if (busyId == row.journeyId)
                            const LinearProgressIndicator(),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton(
                                onPressed: busyId != null || loading
                                    ? null
                                    : () => open(row),
                                child: Text(l.savedTripsOpen),
                              ),
                              TextButton(
                                onPressed: busyId != null || loading
                                    ? null
                                    : () => remove(row),
                                child: Text(l.removeSavedTrip),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!loading)
                  Wrap(
                    spacing: 8,
                    children: [
                      if (boundaries.length > 1)
                        OutlinedButton(
                          onPressed: busyId != null
                              ? null
                              : () => load(previous: true),
                          child: Text(l.savedTripsPrevious),
                        ),
                      if (page?.next != null)
                        OutlinedButton(
                          onPressed: busyId != null
                              ? null
                              : () => load(next: page!.next),
                          child: Text(l.savedTripsNext),
                        ),
                    ],
                  ),
              ],
            ),
    );
  }
}
