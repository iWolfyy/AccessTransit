import 'bus.dart';
import 'station.dart';
import 'bus_location_model.dart';
import 'enums/bus_status.dart';
import '../logic/delay_eta_logic.dart';

enum AssistancePurpose { boarding, alighting }

/// A journey's exact vehicle and stop, never a default or a partial name match.
class AssistanceTarget {
  const AssistanceTarget({
    required this.busId,
    required this.stationId,
    required this.stopName,
    required this.busLabel,
    this.purpose = AssistancePurpose.boarding,
    this.serviceRunId,
    this.boardingStationId,
    this.alightingStationId,
  });
  final String busId;
  final String? serviceRunId, boardingStationId, alightingStationId;
  final String stationId;
  final String stopName;
  final String busLabel;
  final AssistancePurpose purpose;

  int? minutesFrom(
    BusArrivalEtaResult? eta, {
    BusLocationModel? telemetry,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();
    final checkedAt = telemetry?.timestamp;
    if (telemetry == null ||
        telemetry.busId != busId ||
        (serviceRunId != null && telemetry.tripId != serviceRunId) ||
        !telemetry.isBroadcasting ||
        telemetry.status != BusStatus.active ||
        checkedAt == null ||
        checkedAt.isAfter(now) ||
        now.difference(checkedAt) > const Duration(minutes: 5)) {
      return null;
    }
    return eta != null &&
            eta.isLive &&
            eta.busId == busId &&
            eta.targetStopId == stationId &&
            eta.countdownMinutes >= 0
        ? eta.countdownMinutes
        : null;
  }

  static AssistanceTarget? resolve({
    required String busId,
    required Bus? bus,
    required String stopName,
    String? stationId,
    required Map<String, Station> stations,
    AssistancePurpose purpose = AssistancePurpose.boarding,
    String? serviceRunId,
    String? boardingStationId,
    String? alightingStationId,
  }) {
    if (bus == null ||
        bus.isPublishedTimetable ||
        bus.id != busId ||
        busId.trim().isEmpty) {
      return null;
    }
    final explicitId = stationId?.trim() ?? '';
    final candidates = bus.stops
        .where(
          (id) => explicitId.isNotEmpty
              ? id == explicitId
              : stations[bus.stationIdFor(id)]?.name.trim().toLowerCase() ==
                    stopName.trim().toLowerCase(),
        )
        .toList();
    if (candidates.length != 1) return null;
    final stop =
        stations[bus.stationIdFor(candidates.single)] ??
        stations[candidates.single];
    if (stop == null ||
        stop.id != bus.stationIdFor(candidates.single) ||
        stop.name.trim().isEmpty) {
      return null;
    }
    return AssistanceTarget(
      serviceRunId: serviceRunId,
      boardingStationId: boardingStationId,
      alightingStationId: alightingStationId,
      busId: bus.id,
      stationId: stop.id,
      stopName: stop.name,
      busLabel: '${bus.displayBusNo} (Route ${bus.routeNo})',
      purpose: purpose,
    );
  }
}
