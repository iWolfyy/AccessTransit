import 'package:flutter/material.dart';

import '../l10n/localization_context.dart';
import '../models/station.dart';
import '../services/nearby_stop_service.dart';

class NearbyStopsSheet extends StatefulWidget {
  const NearbyStopsSheet({
    super.key,
    required this.stations,
    required this.service,
  });
  final List<Station> stations;
  final NearbyStopService service;

  @override
  State<NearbyStopsSheet> createState() => _NearbyStopsSheetState();
}

class _NearbyStopsSheetState extends State<NearbyStopsSheet> {
  List<NearbyStop>? stops;
  NearbyStopFailure? error;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final found = await widget.service.find(widget.stations);
      if (mounted) setState(() => stops = found);
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is NearbyStopException
              ? e.reason
              : NearbyStopFailure.unavailable,
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> settings() async {
    try {
      final opened = error == NearbyStopFailure.disabled
          ? await widget.service.location.openLocationSettings()
          : await widget.service.location.openAppSettings();
      if (!opened && mounted) {
        setState(() => error = NearbyStopFailure.unavailable);
      }
    } catch (_) {
      if (mounted) setState(() => error = NearbyStopFailure.unavailable);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final message = switch (error) {
      NearbyStopFailure.disabled => l.nearbyLocationDisabled,
      NearbyStopFailure.denied => l.nearbyLocationDenied,
      NearbyStopFailure.deniedForever => l.nearbyLocationBlocked,
      _ => l.nearbyLocationUnavailable,
    };
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.nearbyStopsTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(l.nearbyStopsExplanation),
            const SizedBox(height: 16),
            if (loading) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              Text(l.nearbyLocating),
            ] else if (error != null) ...[
              Text(message, semanticsLabel: message),
              if (error == NearbyStopFailure.disabled ||
                  error == NearbyStopFailure.deniedForever)
                TextButton(
                  onPressed: settings,
                  child: Text(l.nearbyOpenSettings),
                ),
              TextButton(onPressed: load, child: Text(l.nearbyRetry)),
            ] else if (stops?.isEmpty == true) ...[
              Text(l.nearbyStopsEmpty),
            ] else
              for (final stop in stops ?? <NearbyStop>[])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.directions_bus_outlined),
                  title: Text(stop.station.name),
                  subtitle: Text(
                    l.nearbyDistance((stop.metres / 1000).toStringAsFixed(2)),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, stop.station),
                ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.nearbyChooseManually),
            ),
          ],
        ),
      ),
    );
  }
}
