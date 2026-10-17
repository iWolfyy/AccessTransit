import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/eta_evaluation.dart';
import '../logic/route_geometry.dart';
import '../models/bus.dart';
import '../models/bus_location_model.dart';
import '../models/service_run.dart';
import '../models/trip_model.dart';

class EtaEvaluationStore extends ChangeNotifier {
  EtaEvaluationStore({
    required this.available,
    Future<SharedPreferences> Function()? preferences,
    this.write,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;
  static final instance = EtaEvaluationStore(
    available: kDebugMode && const bool.fromEnvironment('LOCAL_VALIDATION'),
  );
  final bool available;
  final Future<SharedPreferences> Function() _preferences;
  final Future<bool> Function(String, String)? write;
  EtaEvaluationLedger ledger = EtaEvaluationLedger();
  bool enabled = false, ready = false;
  String? owner, error;
  int _revision = 0;
  bool _scheduled = false;
  Future<void> _writes = Future.value();
  Future<void>? _opening;
  String get _key =>
      'local_eta_diagnostics_v1_${base64Url.encode(utf8.encode(owner!))}';

  Future<void> open(String? uid) async {
    if (!available) return;
    if (owner == uid && _opening != null) return _opening!;
    if (owner == uid && ready) return;
    owner = uid;
    ready = false;
    enabled = false;
    error = null;
    ledger = EtaEvaluationLedger();
    final revision = ++_revision;
    scheduleMicrotask(() {
      if (revision == _revision && !ready) notifyListeners();
    });
    final future = _load(uid, revision);
    _opening = future;
    try {
      await future;
    } finally {
      if (revision == _revision) _opening = null;
    }
  }

  Future<void> _load(String? uid, int revision) async {
    if (uid == null) {
      notifyListeners();
      return;
    }
    final key = _key;
    try {
      final prefs = await _preferences();
      final raw = prefs.getString(key);
      final restored = EtaEvaluationLedger();
      var active = false;
      if (raw != null) {
        if (raw.length > 700000) throw const FormatException();
        final d = jsonDecode(raw);
        if (d['enabled'] is! bool) throw const FormatException();
        active = d['enabled'];
        restored.restore(jsonEncode(d['ledger']));
      }
      if (revision != _revision) return;
      ledger = restored;
      enabled = active;
      ready = true;
    } catch (_) {
      if (revision == _revision) {
        ready = true;
        error = 'storage';
      }
    }
    if (revision == _revision) notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (!available || !ready || owner == null) return;
    final previous = enabled, revision = _revision;
    enabled = value;
    try {
      await _persist();
      if (revision == _revision) error = null;
    } catch (_) {
      if (revision == _revision) {
        enabled = previous;
        error = 'storage';
      }
    }
    if (revision == _revision) notifyListeners();
  }

  void capture({
    required String? uid,
    required Bus bus,
    required ServiceRun run,
    required TripModel trip,
    required DateTime now,
    BusLocationModel? gps,
    ReviewedRouteGeometry? geometry,
  }) {
    if (!available || !ready || !enabled || uid == null || uid != owner) return;
    final before = jsonEncode(ledger.records);
    ledger.observe(
      bus: bus,
      run: run,
      trip: trip,
      now: now,
      gps: gps,
      geometry: geometry,
    );
    if (before == jsonEncode(ledger.records) || _scheduled) return;
    _scheduled = true;
    final revision = _revision;
    scheduleMicrotask(() async {
      _scheduled = false;
      if (revision != _revision) return;
      try {
        await _persist();
        if (revision == _revision) error = null;
      } catch (_) {
        if (revision == _revision) error = 'storage';
      }
      if (revision == _revision) notifyListeners();
    });
  }

  Future<void> clear() async {
    if (!available || !ready || owner == null) return;
    final previous = ledger, revision = _revision;
    ledger = EtaEvaluationLedger();
    try {
      await _persist();
      if (revision == _revision) error = null;
    } catch (_) {
      if (revision == _revision) {
        ledger = previous;
        error = 'storage';
      }
    }
    if (revision == _revision) notifyListeners();
  }

  Future<void> _persist() {
    final key = _key,
        data = jsonEncode({'enabled': enabled, 'ledger': ledger.export()});
    final task = _writes.then((_) async {
      final prefs = await _preferences();
      if (!await (write?.call(key, data) ?? prefs.setString(key, data))) {
        throw StateError('Local diagnostic save unconfirmed');
      }
    });
    _writes = task.catchError((_) {});
    return task;
  }

  String exportJson() =>
      const JsonEncoder.withIndent('  ').convert(ledger.export());
}
