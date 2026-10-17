import '../models/service_run.dart';

/// Civil values are floating UTC calendar fields, not transport timestamps.
abstract final class TransitTime {
  static DateTime civil(DateTime instant) => ServiceRun.colomboClock(instant);
  static DateTime instant(DateTime civil) =>
      ServiceRun.colomboCivilToUtc(civil);
  static DateTime day(DateTime civil) =>
      DateTime.utc(civil.year, civil.month, civil.day);
  static String serviceDate(DateTime instant) {
    final c = civil(instant);
    return '${c.year}-${c.month.toString().padLeft(2, '0')}-${c.day.toString().padLeft(2, '0')}';
  }
}

/// A short-lived server receipt advanced only by a monotonic elapsed clock.
class SearchTimeAnchor {
  SearchTimeAnchor(
    DateTime serverTime, {
    Duration Function()? elapsed,
    this.uncertainty = Duration.zero,
  }) : _serverTime = serverTime.toUtc(),
       _elapsed = elapsed ?? (Stopwatch()..start()).elapsedDuration;

  final DateTime _serverTime;
  final Duration Function() _elapsed;
  final Duration uncertainty;
  static const lifetime = Duration(minutes: 5);
  DateTime get lowerNow => _serverTime.add(_elapsed());
  DateTime get now => lowerNow.add(uncertainty);
  DateTime get windowEnd => lowerNow.add(const Duration(hours: 24));
  Duration get remaining => lifetime - _elapsed();
  bool get isFresh => _elapsed() >= Duration.zero && _elapsed() < lifetime;
}

extension on Stopwatch {
  Duration elapsedDuration() => elapsed;
}
