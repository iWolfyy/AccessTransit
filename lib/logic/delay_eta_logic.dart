import '../core/utils/time_utils.dart';
import '../models/bus.dart';
import '../models/bus_location_model.dart';
import '../models/station.dart';
import '../models/trip_model.dart';

/// Classification of bus arrival punctuality relative to schedule.
enum DelayType {
  /// Bus is running on time (within 1 minute of schedule).
  onTime,

  /// Bus is delayed behind schedule (> 1 minute late).
  delayed,

  /// Bus is running ahead of schedule (> 1 minute early).
  early,

  /// No live driver telemetry available; relying on timetable schedule.
  scheduled,
}

/// Detailed arrival, delay, and progression status for a single bus stop along a route.
class StopEtaInfo {
  const StopEtaInfo({
    required this.stopId,
    required this.stopName,
    required this.stopIndex,
    required this.scheduledTimeStr,
    required this.scheduledTime,
    required this.estimatedTime,
    required this.estimatedTimeStr,
    required this.delayMinutes,
    required this.delayType,
    required this.delayLabel,
    required this.isPassed,
    required this.isCurrent,
    required this.isTargetStop,
  });

  final String stopId;
  final String stopName;
  final int stopIndex;
  final String scheduledTimeStr;
  final DateTime scheduledTime;
  final DateTime estimatedTime;
  final String estimatedTimeStr;
  final int delayMinutes;
  final DelayType delayType;
  final String delayLabel;
  final bool isPassed;
  final bool isCurrent;
  final bool isTargetStop;
}

/// Result object holding computed arrival countdown, delay comparison, and timeline progression.
class BusArrivalEtaResult {
  const BusArrivalEtaResult({
    required this.busId,
    required this.routeNo,
    required this.targetStopId,
    required this.targetStopName,
    required this.scheduledArrival,
    required this.scheduledArrivalStr,
    required this.estimatedArrival,
    required this.estimatedArrivalStr,
    required this.delayMinutes,
    required this.delayType,
    required this.delayLabel,
    required this.countdownMinutes,
    required this.countdownText,
    required this.isLive,
    required this.liveStatusDescription,
    required this.stopsTimeline,
  });

  final String busId;
  final String routeNo;
  final String targetStopId;
  final String targetStopName;
  final DateTime scheduledArrival;
  final String scheduledArrivalStr;
  final DateTime estimatedArrival;
  final String estimatedArrivalStr;
  final int delayMinutes;
  final DelayType delayType;
  final String delayLabel;
  final int countdownMinutes;
  final String countdownText;
  final bool isLive;
  final String liveStatusDescription;
  final List<StopEtaInfo> stopsTimeline;

  /// True if the bus is running late compared to schedule.
  bool get isDelayed => delayType == DelayType.delayed;

  /// True if the bus is running on schedule.
  bool get isOnTime => delayType == DelayType.onTime;
}

/// Pure logic utility for calculating countdown ETA, delay minutes, and stops timeline progression.
class DelayEtaCalculator {
  const DelayEtaCalculator._();

  /// Calculates dynamic arrival ETA, schedule delay, and stops progression.
  ///
  /// [bus]: The selected bus vehicle (includes stops & timetable).
  /// [targetStopIdOrName]: The passenger's boarding station ID (e.g. `'st_pettah'`) or name.
  /// [liveBusLocation]: Real-time driver telemetry from `active_buses/{busId}` (optional).
  /// [activeTrip]: Active trip document from `trips/{tripId}` (optional).
  /// [stationsMap]: Map of station IDs to [Station] objects for resolving display names.
  /// [currentTime]: Reference clock time (defaults to `DateTime.now()`).
  static BusArrivalEtaResult calculateArrivalEta({
    required Bus bus,
    required String targetStopIdOrName,
    BusLocationModel? liveBusLocation,
    TripModel? activeTrip,
    Map<String, Station>? stationsMap,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();
    final todayBase = DateTime(now.year, now.month, now.day);

    // 1. Resolve target stop index in the bus stops list
    final cleanTarget = targetStopIdOrName.trim();
    int targetIndex = bus.stops.indexWhere((s) => s.toLowerCase() == cleanTarget.toLowerCase());

    // Fallback: match by station display name in stationsMap
    if (targetIndex == -1 && stationsMap != null) {
      for (int i = 0; i < bus.stops.length; i++) {
        final stopId = bus.stops[i];
        final station = stationsMap[stopId];
        if (station != null && station.name.trim().toLowerCase() == cleanTarget.toLowerCase()) {
          targetIndex = i;
          break;
        }
      }
    }

    // Default to first stop if not resolved
    if (targetIndex == -1) {
      targetIndex = 0;
    }

    final targetStopId = bus.stops.isNotEmpty ? bus.stops[targetIndex] : cleanTarget;
    final targetStopName = stationsMap?[targetStopId]?.name ?? targetStopId;

    // 2. Check live driver broadcasting status
    final bool isLiveDriver = (liveBusLocation != null &&
            liveBusLocation.isBroadcasting &&
            liveBusLocation.status.name.toLowerCase() != 'offline') ||
        (activeTrip != null && activeTrip.isInProgress);

    // 3. Compute baseline scheduled arrival time for the target stop
    final scheduledTimeStr = bus.getScheduledTimeForStop(targetIndex);
    DateTime scheduledArrival = TimeUtils.parseTimeStringToDateTime(scheduledTimeStr, todayBase);

    // If driver is offline and today's scheduled departure has already elapsed by > 15 mins,
    // the next service instance is on the next day (tomorrow)
    bool isTomorrow = false;
    if (!isLiveDriver && activeTrip == null && scheduledArrival.isBefore(now.subtract(const Duration(minutes: 15)))) {
      scheduledArrival = scheduledArrival.add(const Duration(days: 1));
      isTomorrow = true;
    }

    // 4. Compute estimated arrival time based on live driver telemetry or active trip
    DateTime estimatedArrival;
    int tripDelayOffsetMinutes = 0;

    if (activeTrip != null && activeTrip.stopTimes.containsKey(targetStopId)) {
      final stopTiming = activeTrip.stopTimes[targetStopId]!;
      // If actual arrival already logged, use it; otherwise use estimated
      estimatedArrival = stopTiming.actualArrival ?? stopTiming.estimatedArrival;
      tripDelayOffsetMinutes = estimatedArrival.difference(scheduledArrival).inMinutes;
    } else if (liveBusLocation != null && isLiveDriver) {
      // Driver telemetry provides etaMinutes to current/next stop
      final nextStop = liveBusLocation.nextStop;
      final nextStopIndex = bus.stops.indexWhere(
        (s) => s.toLowerCase() == nextStop.toLowerCase() ||
               (stationsMap?[s]?.name.toLowerCase() == nextStop.toLowerCase()),
      );

      final currentBusIndex = nextStopIndex != -1 ? nextStopIndex : 0;
      final stopsRemaining = targetIndex - currentBusIndex;

      if (stopsRemaining <= 0) {
        // Bus is already at or past the target stop
        final liveMins = liveBusLocation.etaMinutes;
        estimatedArrival = now.add(Duration(minutes: liveMins));
      } else {
        // Average 5-6 minutes per intermediate transit stop in Colombo
        final totalEstimatedMinutes = liveBusLocation.etaMinutes + ((stopsRemaining - 1) * 5);
        estimatedArrival = now.add(Duration(minutes: totalEstimatedMinutes));
      }

      tripDelayOffsetMinutes = estimatedArrival.difference(scheduledArrival).inMinutes;
    } else {
      // Offline fallback: estimated time equals scheduled timetable
      estimatedArrival = scheduledArrival;
      tripDelayOffsetMinutes = 0;
    }

    // 5. Calculate delay metrics
    final delayMinutes = tripDelayOffsetMinutes;
    final delayType = isTomorrow
        ? DelayType.scheduled
        : getDelayType(delayMinutes, isLive: isLiveDriver);
    final delayLabel = isTomorrow
        ? 'Scheduled for tomorrow'
        : formatDelayLabel(delayMinutes, isLive: isLiveDriver);

    // 6. Calculate countdown ETA to target stop
    final countdownMinutes = estimatedArrival.difference(now).inMinutes;
    final countdownText = formatCountdown(
      countdownMinutes,
      isTomorrow: isTomorrow,
      scheduledTimeStr: scheduledTimeStr,
    );

    final scheduledArrivalStr = isTomorrow
        ? 'Tomorrow, $scheduledTimeStr'
        : scheduledTimeStr;
    final estimatedArrivalStr = isTomorrow
        ? 'Tomorrow, ${TimeUtils.formatTimeString(estimatedArrival)}'
        : TimeUtils.formatTimeString(estimatedArrival);

    final liveStatusDescription = isLiveDriver
        ? 'Live GPS tracking active · Telemetry from driver'
        : (isTomorrow
            ? 'Timetable schedule · Next departure tomorrow'
            : 'Timetable schedule · Driver offline');

    // 7. Build stops timeline progression
    final List<StopEtaInfo> timeline = [];
    final currentDriverStopIndex = activeTrip?.currentStopIndex ??
        (liveBusLocation != null
            ? bus.stops.indexWhere((s) => s.toLowerCase() == liveBusLocation.nextStop.toLowerCase())
            : -1);

    final effectiveBase = isTomorrow ? todayBase.add(const Duration(days: 1)) : todayBase;
    for (int i = 0; i < bus.stops.length; i++) {
      final stopId = bus.stops[i];
      final stopName = stationsMap?[stopId]?.name ?? stopId;
      final stopScheduledStr = bus.getScheduledTimeForStop(i);
      final stopScheduledTime = TimeUtils.parseTimeStringToDateTime(stopScheduledStr, effectiveBase);

      DateTime stopEstTime;
      if (activeTrip != null && activeTrip.stopTimes.containsKey(stopId)) {
        final timing = activeTrip.stopTimes[stopId]!;
        stopEstTime = timing.actualArrival ?? timing.estimatedArrival;
      } else if (isLiveDriver) {
        // Apply cumulative delay offset to each stop
        stopEstTime = stopScheduledTime.add(Duration(minutes: delayMinutes));
      } else {
        stopEstTime = stopScheduledTime;
      }

      final stopDelay = stopEstTime.difference(stopScheduledTime).inMinutes;
      final stopDelayType = getDelayType(stopDelay, isLive: isLiveDriver);
      final stopDelayLabel = formatDelayLabel(stopDelay, isLive: isLiveDriver);

      final bool isPassed = activeTrip?.stopTimes[stopId]?.actualArrival != null ||
          (currentDriverStopIndex != -1 && i < currentDriverStopIndex);
      final bool isCurrent = currentDriverStopIndex != -1 && i == currentDriverStopIndex;
      final bool isTarget = (i == targetIndex);

      timeline.add(
        StopEtaInfo(
          stopId: stopId,
          stopName: stopName,
          stopIndex: i,
          scheduledTimeStr: stopScheduledStr,
          scheduledTime: stopScheduledTime,
          estimatedTime: stopEstTime,
          estimatedTimeStr: TimeUtils.formatTimeString(stopEstTime),
          delayMinutes: stopDelay,
          delayType: stopDelayType,
          delayLabel: stopDelayLabel,
          isPassed: isPassed,
          isCurrent: isCurrent,
          isTargetStop: isTarget,
        ),
      );
    }

    return BusArrivalEtaResult(
      busId: bus.id,
      routeNo: bus.routeNo,
      targetStopId: targetStopId,
      targetStopName: targetStopName,
      scheduledArrival: scheduledArrival,
      scheduledArrivalStr: scheduledArrivalStr,
      estimatedArrival: estimatedArrival,
      estimatedArrivalStr: estimatedArrivalStr,
      delayMinutes: delayMinutes,
      delayType: delayType,
      delayLabel: delayLabel,
      countdownMinutes: countdownMinutes,
      countdownText: countdownText,
      isLive: isLiveDriver,
      liveStatusDescription: liveStatusDescription,
      stopsTimeline: timeline,
    );
  }

  /// Categorizes delay minutes into a [DelayType].
  static DelayType getDelayType(int delayMinutes, {bool isLive = true}) {
    if (!isLive) {
      return DelayType.scheduled;
    }
    if (delayMinutes > 1) {
      return DelayType.delayed;
    }
    if (delayMinutes < -1) {
      return DelayType.early;
    }
    return DelayType.onTime;
  }

  /// Formats user-facing delay badge string.
  ///
  /// Examples:
  /// - `3` -> "Delayed by 3 mins"
  /// - `0` -> "On Time"
  /// - `-2` -> "Running 2 mins early"
  static String formatDelayLabel(int delayMinutes, {bool isLive = true}) {
    if (!isLive) {
      return 'Scheduled';
    }
    if (delayMinutes > 1) {
      return 'Delayed by $delayMinutes min${delayMinutes == 1 ? '' : 's'}';
    }
    if (delayMinutes < -1) {
      final absMins = delayMinutes.abs();
      return 'Running $absMins min${absMins == 1 ? '' : 's'} early';
    }
    return 'On Time';
  }

  /// Formats countdown string.
  ///
  /// Examples:
  /// - `isTomorrow` -> "Tomorrow at 09:00 AM (in 9h 54m)"
  /// - `0..1` -> "Arriving now"
  /// - `12` -> "Arriving in 12 mins"
  /// - `125` -> "Arriving in 2h 5m"
  /// - `< 0` -> "Departed"
  static String formatCountdown(
    int countdownMinutes, {
    bool isTomorrow = false,
    String? scheduledTimeStr,
  }) {
    if (isTomorrow) {
      final hours = countdownMinutes ~/ 60;
      final mins = countdownMinutes % 60;
      final timeSuffix = scheduledTimeStr != null && scheduledTimeStr.isNotEmpty
          ? ' at $scheduledTimeStr'
          : '';
      if (hours < 24) {
        if (mins == 0) {
          return 'Tomorrow$timeSuffix (in ${hours}h)';
        }
        return 'Tomorrow$timeSuffix (in ${hours}h ${mins}m)';
      }
      return 'Tomorrow$timeSuffix';
    }

    if (countdownMinutes < -15) {
      return 'Departed';
    }
    if (countdownMinutes < 0) {
      final absMins = countdownMinutes.abs();
      return 'Departed $absMins min${absMins == 1 ? '' : 's'} ago';
    }
    if (countdownMinutes <= 1) {
      return 'Arriving now';
    }
    if (countdownMinutes < 60) {
      return 'Arriving in $countdownMinutes min${countdownMinutes == 1 ? '' : 's'}';
    }
    final hours = countdownMinutes ~/ 60;
    final mins = countdownMinutes % 60;
    if (mins == 0) {
      return 'Arriving in $hours hr${hours == 1 ? '' : 's'}';
    }
    return 'Arriving in ${hours}h ${mins}m';
  }
}
