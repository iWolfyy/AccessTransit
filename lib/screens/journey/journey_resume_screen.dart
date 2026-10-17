import 'package:flutter/material.dart';

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../l10n/localization_context.dart';
import '../../services/accessibility_preferences_service.dart';

import '../../logic/journey_selection.dart';
import '../../models/journey_model.dart';
import '../../models/bus.dart';
import '../../models/station.dart';
import '../../services/firestore_service.dart';
import '../../services/journey_service.dart';
import 'bus_details_screen.dart';
import 'route_results_screen.dart';

class JourneyResumeScreen extends StatefulWidget {
  const JourneyResumeScreen({
    super.key,
    required this.journey,
    this.service,
    this.repository,
    this.onReady,
  });
  final JourneyModel journey;
  final JourneyService? service;
  final FirestoreService? repository;
  final void Function(RouteResultItem)? onReady;
  @override
  State<JourneyResumeScreen> createState() => _JourneyResumeScreenState();
}

class _JourneyResumeScreenState extends State<JourneyResumeScreen> {
  late final JourneyService service = widget.service ?? JourneyService();
  late final FirestoreService repository =
      widget.repository ?? FirestoreService();
  bool loading = true;
  String? error;
  RouteResultItem? route;
  int revision = 0;
  bool invalidated = false;
  StreamSubscription<User?>? auth;
  late final savedUpdates = service.watchJourney(widget.journey.journeyId);
  @override
  void initState() {
    super.initState();
    AccessibilityPreferencesService.instance.addListener(accountChanged);
    try {
      auth = FirebaseAuth.instance.authStateChanges().listen((u) {
        if (u?.uid != widget.journey.passengerId) invalidate();
      });
    } catch (_) {}
    load();
  }

  void accountChanged() {
    if (service.signedInPassenger != widget.journey.passengerId ||
        AccessibilityPreferencesService.instance.userId !=
            widget.journey.passengerId) {
      invalidate();
    }
  }

  void invalidate() {
    if (!mounted || invalidated) return;
    revision++;
    setState(() {
      invalidated = true;
      route = null;
      loading = false;
      error = 'account';
    });
  }

  @override
  void dispose() {
    revision++;
    auth?.cancel();
    AccessibilityPreferencesService.instance.removeListener(accountChanged);
    super.dispose();
  }

  Future<void> load() async {
    if (invalidated) return;
    final generation = ++revision;
    setState(() {
      loading = true;
      error = null;
      route = null;
    });
    try {
      if (service.signedInPassenger != widget.journey.passengerId) {
        throw StateError('Sign in with the account that saved this journey.');
      }
      Bus? bus;
      List<Station> stops = [];
      try {
        bus = await repository.getBusById(widget.journey.busId);
      } catch (_) {
        if (widget.journey.scheduleSnapshot == null) rethrow;
      }
      try {
        stops = await repository.getStations();
      } catch (_) {
        if (widget.journey.scheduleSnapshot == null) rethrow;
      }
      if (bus == null) {
        final snapshot = widget.journey.scheduleSnapshot;
        if (snapshot == null) throw StateError('vehicle');
        bus = snapshot.historicalBus(
          id: widget.journey.busId,
          routeId: widget.journey.routeId,
          routeNo: widget.journey.routeNumber,
          busNo: widget.journey.busNo,
        );
      }
      final restored = JourneySelection.restore(widget.journey, bus, {
        for (final s in stops) s.id: s,
      });
      if (!mounted || generation != revision || invalidated) return;
      if (service.signedInPassenger != widget.journey.passengerId) {
        throw StateError('The signed-in account changed.');
      }
      if (widget.onReady != null) widget.onReady!(restored);
      setState(() => route = restored);
    } catch (e) {
      if (mounted && generation == revision && !invalidated) {
        setState(
          () => error = e is StateError && e.message == 'vehicle'
              ? 'vehicle'
              : 'load',
        );
      }
    } finally {
      if (mounted && generation == revision) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (invalidated ||
        service.signedInPassenger != widget.journey.passengerId) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.savedTripsTitle)),
        body: Center(child: Text(context.l10n.savedTripsAccountChanged)),
      );
    }
    if (route != null &&
        service.signedInPassenger == widget.journey.passengerId) {
      return StreamBuilder<JourneyModel?>(
        stream: savedUpdates,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError ||
              snapshot.data == null ||
              snapshot.data!.passengerId != service.signedInPassenger) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.busDetails)),
              body: Center(child: Text(context.l10n.savedTripsOpenError)),
            );
          }
          return BusDetailsScreen(
            savedJourney: widget.journey,
            origin: widget.journey.origin,
            destination: widget.journey.destination,
            route: route!,
            bus: route!.rawBus,
            journeyService: service,
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.busDetails)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (loading) const CircularProgressIndicator(),
            if (error != null)
              Text(
                error == 'vehicle'
                    ? context.l10n.savedTripsVehicleUnavailable
                    : context.l10n.savedTripsOpenError,
              ),
            if (!loading)
              FilledButton(
                onPressed: load,
                child: Text(context.l10n.savedTripsRetry),
              ),
          ],
        ),
      ),
    );
  }
}
