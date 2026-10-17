import '../logic/report_mutation.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../logic/status_logic.dart';
import '../models/bus.dart';
import '../models/report.dart';

/// Optional shared clock, including deterministic device/lifecycle tests.
class EvidenceClock extends InheritedWidget {
  const EvidenceClock({super.key, required this.now, required super.child});
  final DateTime Function() now;

  static DateTime read(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EvidenceClock>()?.now() ??
      DateTime.now();

  @override
  bool updateShouldNotify(EvidenceClock oldWidget) => oldWidget.now != now;
}

/// Re-evaluates saved evidence without requiring another backend event.
/// One clock reading is shared by all calculations in [builder].
class EvidenceRefresh extends StatefulWidget {
  const EvidenceRefresh({
    super.key,
    this.reports = const [],
    this.buses = const [],
    this.now,
    this.boundaries = const [],
    required this.builder,
  });

  final List<Report> reports;
  final List<Bus> buses;
  final DateTime Function()? now;
  final List<DateTime> boundaries;
  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  State<EvidenceRefresh> createState() => _EvidenceRefreshState();
}

class _EvidenceRefreshState extends State<EvidenceRefresh>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _paused = state != null && state != AppLifecycleState.resumed;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _paused = state != AppLifecycleState.resumed;
    _timer?.cancel();
    if (!_paused && mounted) setState(() {});
  }

  void _schedule(DateTime now) {
    _timer?.cancel();
    if (_paused) return;
    // Also refresh relative-time labels and recover from wall-clock changes.
    var next = now.add(const Duration(minutes: 1));
    void consider(DateTime? boundary, {bool inclusiveEnd = false}) {
      if (boundary == null) return;
      final instant = inclusiveEnd
          ? boundary.add(const Duration(microseconds: 1))
          : boundary;
      if (instant.isAfter(now) && instant.isBefore(next)) next = instant;
    }

    for (final boundary in widget.boundaries) {
      consider(boundary, inclusiveEnd: true);
    }
    for (final report in widget.reports) {
      consider(report.createdAt);
      consider(report.lastConfirmedAt);
      consider(report.lastRecheckedAt);
      consider(ReportRecheck.availableAt(report));
      consider(
        StatusLogic.freshUntil(report, currentTime: now),
        inclusiveEnd: true,
      );
      final checked = StatusLogic.lastCheckedAt(report, currentTime: now);
      consider(checked?.add(const Duration(minutes: 30)), inclusiveEnd: true);
    }
    for (final bus in widget.buses) {
      consider(bus.rampCheckedAt);
      consider(
        bus.rampCheckedAt?.add(const Duration(hours: 24)),
        inclusiveEnd: true,
      );
    }
    _timer = Timer(next.difference(now), () {
      if (mounted && !_paused) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = widget.now?.call() ?? EvidenceClock.read(context);
    _schedule(now);
    return widget.builder(context, now);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
