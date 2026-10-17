import 'dart:async';

import 'package:flutter/foundation.dart';

import '../logic/search_session.dart';
import '../logic/transit_time.dart';
import '../models/bus_location_model.dart';
import '../models/service_run.dart';
import '../models/trip_model.dart';
import 'transit_search_backend.dart';

class DatedSearchState extends ChangeNotifier {
  DatedSearchState(this.backend);
  final TransitSearchBackend backend;
  SearchTimeAnchor? clock;
  String? clockError;
  final _runs = <String, List<ServiceRun>>{};
  final _errors = <String, String>{};
  final _runSubscriptions = <StreamSubscription>[];
  final _tripSubscriptions = <String, StreamSubscription>{};
  final _gpsSubscriptions = <String, StreamSubscription>{};
  final trips = <String, TripModel>{};
  final locations = <String, BusLocationModel>{};
  int _expected = 0, _revision = 0;
  bool _disposed = false;
  Timer? _expiry;

  List<ServiceRun> runsFor(String bus) => _runs[bus] ?? const [];
  bool get ready =>
      clock?.isFresh == true && _runs.length == _expected && _errors.isEmpty;
  String? get error =>
      clockError ??
      (_errors.isEmpty ? null : 'Dated departures unavailable. Retry.');
  BoardingSearchWindow? get window => !ready
      ? null
      : BoardingSearchWindow.colombo(clock!.now, end: clock!.windowEnd);

  Future<void> start(Iterable<String> physicalBusIds) async {
    final ids = physicalBusIds.toSet();
    _expected = ids.length;
    for (final id in ids) {
      _runSubscriptions.add(
        backend
            .searchRuns(id)
            .listen(
              (list) {
                if (_disposed) return;
                _errors.remove(id);
                _runs[id] = list;
                _watchOperations();
                notifyListeners();
              },
              onError: (Object _) {
                if (_disposed) return;
                _runs.remove(id);
                _errors[id] = 'Unavailable';
                _watchOperations();
                notifyListeners();
              },
            ),
      );
    }
    await synchronize();
  }

  Future<void> synchronize({bool force = false}) async {
    final revision = ++_revision;
    _expiry?.cancel();
    clock = null;
    clockError = null;
    if (force) backend.invalidateTime();
    if (!_disposed) notifyListeners();
    try {
      final receipt = await backend.synchronizeTime();
      if (_disposed || revision != _revision) return;
      if (!receipt.isFresh) throw StateError('Search time expired. Retry.');
      clock = receipt;
      // Recheck at the receipt boundary even without data/clock-change events.
      _expiry = Timer(
        receipt.remaining,
        () => unawaited(synchronize(force: true)),
      );
    } catch (_) {
      if (_disposed || revision != _revision) return;
      clockError = 'Search time unavailable. Connect and retry.';
    }
    if (!_disposed) notifyListeners();
  }

  void _watchOperations() {
    final active = _runs.values
        .expand((r) => r)
        .where((r) => const ['boarding', 'in_progress'].contains(r.status))
        .toList();
    final runIds = active.map((r) => r.id).toSet();
    final busIds = active.map((r) => r.busId).toSet();
    for (final id in _tripSubscriptions.keys.toList()) {
      if (!runIds.contains(id)) {
        unawaited(_tripSubscriptions.remove(id)!.cancel());
        trips.remove(id);
      }
    }
    for (final id in _gpsSubscriptions.keys.toList()) {
      if (!busIds.contains(id)) {
        unawaited(_gpsSubscriptions.remove(id)!.cancel());
        locations.remove(id);
      }
    }
    for (final id in runIds) {
      if (_tripSubscriptions.containsKey(id)) continue;
      _tripSubscriptions[id] = backend
          .trip(id)
          .listen(
            (trip) {
              if (_disposed || !activeRun(id)) return;
              if (trip == null) {
                trips.remove(id);
              } else {
                trips[id] = trip;
              }
              notifyListeners();
            },
            onError: (Object _) {
              if (!_disposed) {
                trips.remove(id);
                notifyListeners();
              }
            },
          );
    }
    for (final id in busIds) {
      if (_gpsSubscriptions.containsKey(id)) continue;
      _gpsSubscriptions[id] = backend
          .location(id)
          .listen(
            (gps) {
              if (_disposed || !_gpsSubscriptions.containsKey(id)) return;
              if (gps == null) {
                locations.remove(id);
              } else {
                locations[id] = gps;
              }
              notifyListeners();
            },
            onError: (Object _) {
              if (!_disposed) {
                locations.remove(id);
                notifyListeners();
              }
            },
          );
    }
  }

  bool activeRun(String id) => _runs.values
      .expand((r) => r)
      .any(
        (r) =>
            r.id == id && const ['boarding', 'in_progress'].contains(r.status),
      );

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    _expiry?.cancel();
    for (final subscription in [
      ..._runSubscriptions,
      ..._tripSubscriptions.values,
      ..._gpsSubscriptions.values,
    ]) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
