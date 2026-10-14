import 'package:flutter/material.dart';

import '../../logic/journey_selection.dart';
import '../../models/journey_model.dart';
import '../../services/firestore_service.dart';
import '../../services/journey_service.dart';
import 'live_journey_screen.dart';
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
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
      route = null;
    });
    try {
      if (service.signedInPassenger != widget.journey.passengerId) {
        throw StateError('Sign in with the account that saved this journey.');
      }
      final bus = await repository.getBusById(widget.journey.busId);
      final stops = await repository.getStations();
      if (bus == null) {
        throw StateError('Saved vehicle unavailable. Replan your journey.');
      }
      final restored = JourneySelection.restore(widget.journey, bus, {
        for (final s in stops) s.id: s,
      });
      if (!mounted) return;
      if (service.signedInPassenger != widget.journey.passengerId) {
        throw StateError('The signed-in account changed.');
      }
      if (widget.onReady != null) widget.onReady!(restored);
      setState(() => route = restored);
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is StateError
              ? e.message.toString()
              : 'Saved journey unavailable. Check your connection and retry.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (route != null &&
        service.signedInPassenger == widget.journey.passengerId) {
      return LiveJourneyScreen(
        busId: widget.journey.busId,
        passengerId: widget.journey.passengerId,
        journeyId: widget.journey.journeyId,
        savedJourney: widget.journey,
        origin: widget.journey.origin,
        destination: widget.journey.destination,
        route: route,
        journeyService: service,
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Resume saved journey')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (loading) const CircularProgressIndicator(),
            if (error != null) Text(error!),
            if (!loading)
              FilledButton(onPressed: load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
