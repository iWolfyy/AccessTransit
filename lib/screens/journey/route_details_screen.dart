import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/seed_data.dart';
import '../../logic/delay_eta_logic.dart';
import '../../logic/status_logic.dart';
import '../../models/bus.dart';
import '../../models/bus_location_model.dart';
import '../../models/report.dart';
import '../../models/station.dart';
import '../../models/trip_model.dart';
import '../../services/firestore_service.dart';
import '../../services/live_bus_service.dart';
import '../../services/trip_service.dart';
import 'boarding_assistance_screen.dart';
import 'live_journey_screen.dart';
import 'report_condition_screen.dart';
import 'route_results_screen.dart';

/// Route Details screen — single page showing Departure Details, Stops Schedule,
/// Accessibility Verified status, Ticket Price, and Safety.
class RouteDetailsScreen extends StatelessWidget {
  const RouteDetailsScreen({
    super.key,
    required this.origin,
    required this.destination,
    this.route,
    this.bus,
    this.statusResult,
  });

  final String origin;
  final String destination;
  final RouteResultItem? route;
  final Bus? bus;
  final BusStatusResult? statusResult;

  static const double _desktopBreakpoint = 768;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;
    final effectiveBusId = bus?.id ?? route?.busId ?? 'bus_138_outbound';
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: Column(
        children: [
          _TopBar(onBack: () => Navigator.of(context).maybePop()),
          Expanded(
            child: StreamBuilder<Bus?>(
              stream: firestoreService.streamBusById(effectiveBusId),
              builder: (context, busSnapshot) {
                final liveBus = busSnapshot.data ?? bus;

                return StreamBuilder<List<Report>>(
                  stream: firestoreService.streamReports(),
                  builder: (context, reportsSnapshot) {
                    final activeReports =
                        reportsSnapshot.data ?? SeedData.getSampleReports();

                    final liveStatusResult = liveBus != null
                        ? StatusLogic.getBusStatus(liveBus, activeReports)
                        : statusResult;

                    String liveCrowdLevel = route?.crowdLevel ?? 'Low';
                    if (liveBus != null) {
                      if (liveBus.occupancy.toLowerCase() == 'medium') {
                        liveCrowdLevel = 'Medium';
                      } else if (liveBus.occupancy.toLowerCase() == 'high') {
                        liveCrowdLevel = 'High';
                      } else if (liveBus.occupancy.toLowerCase() == 'low') {
                        liveCrowdLevel = 'Low';
                      }
                    }

                    return ListView(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        isDesktop ? 24 : 112,
                      ),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 768),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // SECTION 1: Departure Details & Stop Schedule
                                _DepartureAndStopsCard(
                                  origin: origin,
                                  destination: destination,
                                  bus: liveBus,
                                  busId: effectiveBusId,
                                  route: route,
                                ),
                                const SizedBox(height: 20),

                                // SECTION 2: Accessibility Verified Details
                                const _AccessibilityVerifiedCard(),
                                const SizedBox(height: 20),

                                // SECTION 3: Ticket Price
                                const _TicketPriceCard(
                                  priceRs: 250,
                                ),
                                const SizedBox(height: 20),

                                // SECTION 4: Safety & Crowd Status
                                _SafetyAndAccessibilityCard(
                                  statusResult: liveStatusResult,
                                  route: route,
                                  crowdLevel: liveCrowdLevel,
                                ),
                                const SizedBox(height: 24),

                                // ACTION BUTTONS: Track Live, Confirm Schedule, Report
                                _ActionButtons(
                                  onTrackLive: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => LiveJourneyScreen(
                                          origin: origin,
                                          destination: destination,
                                          busId: effectiveBusId,
                                          route: route,
                                        ),
                                      ),
                                    );
                                  },
                                  onConfirmSchedule: () {
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        const SnackBar(
                                          content: Text('Bus schedule saved to your trip plan.'),
                                        ),
                                      );
                                  },
                                  onReport: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ReportConditionScreen(
                                          initialLocation: destination,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: null,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;

    return Material(
      color: context.surfaceColor,
      elevation: isHC ? 0 : 1,
      shadowColor: AppColors.onSurface.withValues(alpha: 0.08),
      shape: isHC
          ? const Border(bottom: BorderSide(color: Colors.black, width: 2))
          : null,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 28),
                  color: isHC ? Colors.black : AppColors.primary,
                  tooltip: 'Back',
                ),
                Expanded(
                  child: Text(
                    'Departure & Route Details',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// SECTION 1: Departure Details & Stop Schedule Card
class _DepartureAndStopsCard extends StatelessWidget {
  const _DepartureAndStopsCard({
    required this.origin,
    required this.destination,
    required this.bus,
    required this.busId,
    this.route,
  });

  final String origin;
  final String destination;
  final Bus? bus;
  final String busId;
  final RouteResultItem? route;

  @override
  Widget build(BuildContext context) {
    final effectiveBus = bus ??
        const Bus(
          id: 'bus_138_nd4521',
          routeNo: '138',
          busNo: 'WP ND-4521',
          hasRamp: true,
          lowFloor: true,
          rampOk: true,
          occupancy: 'low',
        );

    final busNumber = effectiveBus.routeNo;
    final displayBusPlate = effectiveBus.displayBusNo;

    return StreamBuilder<TripModel?>(
      stream: TripService().watchActiveTripForBus(busId),
      builder: (context, tripSnapshot) {
        final trip = tripSnapshot.data;

        return StreamBuilder<BusLocationModel?>(
          stream: LiveBusService().listenToLiveLocation(busId),
          builder: (context, locationSnapshot) {
            final liveLocation = locationSnapshot.data;

            return FutureBuilder<List<Station>>(
              future: FirestoreService().getStations(),
              builder: (context, stationsSnapshot) {
                final stationsList =
                    stationsSnapshot.data ?? SeedData.colomboStations;
                final stationsMap = {
                  for (final s in stationsList) s.id: s,
                };

                // Calculate Arrival ETA, Schedule Delays, and Timeline Progression
                final etaResult = DelayEtaCalculator.calculateArrivalEta(
                  bus: effectiveBus,
                  targetStopIdOrName: origin,
                  liveBusLocation: liveLocation,
                  activeTrip: trip,
                  stationsMap: stationsMap,
                );

                final isHC = context.isHighContrast;

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isHC
                          ? Colors.black
                          : (etaResult.isDelayed
                              ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                              : AppColors.primary.withValues(alpha: 0.25)),
                      width: isHC ? 2 : 1.5,
                    ),
                    boxShadow: isHC
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.onSurface.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. ROUTE PILL & LIVE TELEMETRY STATUS
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isHC ? const Color(0xFF001F3F) : AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                              border: isHC ? Border.all(color: Colors.black, width: 1.5) : null,
                            ),
                            child: Text(
                              'Route $busNumber',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isHC ? Colors.white : AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(8),
                              border: isHC ? Border.all(color: Colors.black, width: 1.5) : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.directions_bus,
                                  size: 14,
                                  color: isHC ? Colors.black : AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  displayBusPlate,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: isHC ? Colors.black : AppColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isHC
                                  ? Colors.white
                                  : (etaResult.isLive
                                      ? const Color(0xFFDCFCE7)
                                      : AppColors.surfaceContainer),
                              borderRadius: BorderRadius.circular(20),
                              border: isHC
                                  ? Border.all(
                                      color: etaResult.isLive
                                          ? const Color(0xFF003833)
                                          : Colors.black,
                                      width: 1.5,
                                    )
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isHC
                                        ? (etaResult.isLive
                                            ? const Color(0xFF003833)
                                            : Colors.black)
                                        : (etaResult.isLive
                                            ? const Color(0xFF16A34A)
                                            : AppColors.onSurfaceVariant),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  etaResult.isLive ? 'LIVE GPS' : 'SCHEDULE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isHC
                                        ? (etaResult.isLive
                                            ? const Color(0xFF003833)
                                            : Colors.black)
                                        : (etaResult.isLive
                                            ? const Color(0xFF166534)
                                            : AppColors.onSurfaceVariant),
                                  ),
                                ),
                                if (etaResult.isLive &&
                                    liveLocation != null &&
                                    liveLocation.speed > 0) ...[
                                  const SizedBox(width: 5),
                                  Text(
                                    '${liveLocation.speed.toStringAsFixed(0)} km/h',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isHC
                                          ? const Color(0xFF003833)
                                          : const Color(0xFF166534),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 2. HERO ARRIVAL COUNTDOWN & DELAY CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isHC ? Colors.white : null,
                          gradient: isHC
                              ? null
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: etaResult.isDelayed
                                      ? [
                                          const Color(0xFFFEF2F2),
                                          const Color(0xFFFFF7ED),
                                        ]
                                      : [
                                          AppColors.primaryContainer.withValues(alpha: 0.12),
                                          AppColors.primaryContainer.withValues(alpha: 0.04),
                                        ],
                                ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isHC
                                ? (etaResult.isDelayed
                                    ? const Color(0xFF8B0000)
                                    : const Color(0xFF001F3F))
                                : (etaResult.isDelayed
                                    ? const Color(0xFFFCA5A5)
                                    : AppColors.primaryContainer.withValues(alpha: 0.3)),
                            width: isHC ? 2 : 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Punctuality Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(child: _buildDelayBadge(etaResult, context)),
                                if (etaResult.isDelayed) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isHC
                                          ? const Color(0xFF8B0000)
                                          : const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(6),
                                      border: isHC
                                          ? Border.all(color: Colors.black, width: 1)
                                          : null,
                                    ),
                                    child: Text(
                                      '+${etaResult.delayMinutes} min late',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (etaResult.delayReason != null &&
                                etaResult.delayReason!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isHC ? Colors.white : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isHC
                                        ? const Color(0xFF8B4500)
                                        : const Color(0xFFF59E0B).withValues(alpha: 0.5),
                                    width: isHC ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.traffic_rounded,
                                      size: 16,
                                      color: isHC
                                          ? const Color(0xFF8B4500)
                                          : const Color(0xFFB45309),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Driver Alert: ${etaResult.delayReason} (+${etaResult.addedDelayMinutes}m)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isHC
                                              ? const Color(0xFF8B4500)
                                              : const Color(0xFF92400E),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),

                            // Countdown text
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isHC
                                        ? Colors.white
                                        : (etaResult.isDelayed
                                            ? const Color(0xFFDC2626).withValues(alpha: 0.15)
                                            : AppColors.primaryContainer.withValues(alpha: 0.2)),
                                    shape: BoxShape.circle,
                                    border: isHC
                                        ? Border.all(
                                            color: etaResult.isDelayed
                                                ? const Color(0xFF8B0000)
                                                : const Color(0xFF001F3F),
                                            width: 1.5,
                                          )
                                        : null,
                                  ),
                                  child: Icon(
                                    Icons.access_alarm_rounded,
                                    color: isHC
                                        ? (etaResult.isDelayed
                                            ? const Color(0xFF8B0000)
                                            : const Color(0xFF001F3F))
                                        : (etaResult.isDelayed
                                            ? const Color(0xFFDC2626)
                                            : AppColors.primary),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        etaResult.countdownText,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: isHC
                                              ? (etaResult.isDelayed
                                                  ? const Color(0xFF8B0000)
                                                  : const Color(0xFF001F3F))
                                              : (etaResult.isDelayed
                                                  ? const Color(0xFF991B1B)
                                                  : AppColors.primary),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'at ${etaResult.targetStopName}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: context.subtextColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Divider(
                              height: 1,
                              color: isHC ? Colors.black : AppColors.outlineVariant,
                            ),
                            const SizedBox(height: 12),

                            // Comparison: Scheduled Time vs Expected Time
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SCHEDULED',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                          color: context.subtextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        etaResult.scheduledArrivalStr,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          decoration: etaResult.isDelayed
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                          color: etaResult.isDelayed
                                              ? context.subtextColor
                                              : context.textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: isHC ? Colors.black : AppColors.outlineVariant,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'EXPECTED ARRIVAL',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                          color: isHC ? const Color(0xFF001F3F) : AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        etaResult.estimatedArrivalStr,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: isHC
                                              ? (etaResult.isDelayed
                                                  ? const Color(0xFF8B0000)
                                                  : const Color(0xFF001F3F))
                                              : (etaResult.isDelayed
                                                  ? const Color(0xFFDC2626)
                                                  : AppColors.primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. BOARDING ASSISTANCE BUTTON
                      OutlinedButton.icon(
                        onPressed: () {
                          final effectiveRouteNo = route?.title ??
                              'Route $busNumber';
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BoardingAssistanceScreen(
                                busId: busId,
                                busLabel: effectiveRouteNo,
                                stopName: origin,
                                stationId: etaResult.targetStopId,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isHC ? const Color(0xFF001F3F) : null,
                          foregroundColor: isHC ? Colors.white : AppColors.primaryContainer,
                          side: BorderSide(
                            color: isHC ? Colors.black : AppColors.primaryContainer,
                            width: isHC ? 2 : 1.8,
                          ),
                          minimumSize: const Size(double.infinity, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        icon: const Icon(Icons.assist_walker_rounded, size: 20),
                        label: const Text('Request Boarding Assistance'),
                      ),
                      const SizedBox(height: 20),

                      // 4. TIMELINE HEADER
                      Row(
                        children: [
                          Icon(
                            Icons.route_rounded,
                            size: 20,
                            color: isHC ? Colors.black : AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Route Stops Schedule & Live Progress',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 5. STOPS TIMETABLE PROGRESSION
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: etaResult.stopsTimeline.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final stop = etaResult.stopsTimeline[index];
                          return _buildTimelineStopItem(stop, context);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDelayBadge(BusArrivalEtaResult eta, BuildContext context) {
    final isHC = context.isHighContrast;
    Color bg;
    Color border;
    Color text;
    IconData icon;

    if (isHC) {
      switch (eta.delayType) {
        case DelayType.delayed:
          bg = Colors.white;
          border = const Color(0xFF8B0000);
          text = const Color(0xFF8B0000);
          icon = Icons.warning_amber_rounded;
          break;
        case DelayType.onTime:
          bg = Colors.white;
          border = const Color(0xFF003833);
          text = const Color(0xFF003833);
          icon = Icons.check_circle_rounded;
          break;
        case DelayType.early:
          bg = Colors.white;
          border = const Color(0xFF001F3F);
          text = const Color(0xFF001F3F);
          icon = Icons.bolt_rounded;
          break;
        case DelayType.scheduled:
          bg = Colors.white;
          border = Colors.black;
          text = Colors.black;
          icon = Icons.schedule_rounded;
          break;
      }
    } else {
      switch (eta.delayType) {
        case DelayType.delayed:
          bg = const Color(0xFFFEE2E2);
          border = const Color(0xFFEF4444);
          text = const Color(0xFFDC2626);
          icon = Icons.warning_amber_rounded;
          break;
        case DelayType.onTime:
          bg = const Color(0xFFDCFCE7);
          border = const Color(0xFF22C55E);
          text = const Color(0xFF16A34A);
          icon = Icons.check_circle_rounded;
          break;
        case DelayType.early:
          bg = const Color(0xFFE0F2FE);
          border = const Color(0xFF0284C7);
          text = const Color(0xFF0284C7);
          icon = Icons.bolt_rounded;
          break;
        case DelayType.scheduled:
          bg = AppColors.surfaceContainer;
          border = AppColors.outlineVariant;
          text = AppColors.onSurfaceVariant;
          icon = Icons.schedule_rounded;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: isHC ? 2 : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: text),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              eta.delayLabel,
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStopItem(StopEtaInfo stop, BuildContext context) {
    final isHC = context.isHighContrast;
    Color nodeColor;
    Widget nodeIcon;

    if (isHC) {
      if (stop.isCurrent) {
        nodeColor = const Color(0xFF001F3F);
        nodeIcon = const Icon(Icons.directions_bus, size: 16, color: Colors.white);
      } else if (stop.isTargetStop) {
        nodeColor = const Color(0xFF8B4500);
        nodeIcon = const Icon(Icons.person_pin_circle, size: 18, color: Colors.white);
      } else if (stop.isPassed) {
        nodeColor = const Color(0xFF003833);
        nodeIcon = const Icon(Icons.check, size: 16, color: Colors.white);
      } else {
        nodeColor = Colors.white;
        nodeIcon = Text(
          '${stop.stopIndex + 1}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        );
      }
    } else {
      if (stop.isCurrent) {
        nodeColor = AppColors.primary;
        nodeIcon = const Icon(Icons.directions_bus, size: 16, color: Colors.white);
      } else if (stop.isTargetStop) {
        nodeColor = const Color(0xFFEAB308); // Gold/amber for passenger stop
        nodeIcon = const Icon(Icons.person_pin_circle, size: 18, color: Colors.white);
      } else if (stop.isPassed) {
        nodeColor = const Color(0xFF16A34A); // Green check
        nodeIcon = const Icon(Icons.check, size: 16, color: Colors.white);
      } else {
        nodeColor = AppColors.surfaceVariant;
        nodeIcon = Text(
          '${stop.stopIndex + 1}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        );
      }
    }

    final Color cardBg;
    final Border cardBorder;

    if (isHC) {
      cardBg = Colors.white;
      if (stop.isTargetStop) {
        cardBorder = Border.all(color: const Color(0xFF8B4500), width: 2);
      } else if (stop.isCurrent) {
        cardBorder = Border.all(color: const Color(0xFF001F3F), width: 2);
      } else {
        cardBorder = Border.all(color: Colors.black, width: 1.5);
      }
    } else {
      cardBg = stop.isTargetStop
          ? const Color(0xFFFEF9C3).withValues(alpha: 0.5)
          : (stop.isCurrent
              ? AppColors.primaryContainer.withValues(alpha: 0.12)
              : AppColors.surfaceContainerLow);
      cardBorder = Border.all(
        color: stop.isTargetStop
            ? const Color(0xFFEAB308)
            : (stop.isCurrent
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.4)),
        width: (stop.isTargetStop || stop.isCurrent) ? 1.8 : 1,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: cardBorder,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: nodeColor,
              border: (isHC && !stop.isCurrent && !stop.isTargetStop && !stop.isPassed)
                  ? Border.all(color: Colors.black, width: 1.5)
                  : null,
            ),
            child: Center(child: nodeIcon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (stop.isTargetStop) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isHC ? const Color(0xFF8B4500) : const Color(0xFFCA8A04),
                          borderRadius: BorderRadius.circular(4),
                          border: isHC ? Border.all(color: Colors.black, width: 1) : null,
                        ),
                        child: const Text(
                          'YOUR BOARDING STOP',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ] else if (stop.isCurrent) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isHC ? const Color(0xFF001F3F) : AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                          border: isHC ? Border.all(color: Colors.black, width: 1) : null,
                        ),
                        child: const Text(
                          'BUS IS HERE NOW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        stop.stopName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: stop.isTargetStop || stop.isCurrent
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: context.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      stop.isPassed
                          ? 'Passed at ${stop.estimatedTimeStr}'
                          : 'Sched: ${stop.scheduledTimeStr} · Exp: ${stop.estimatedTimeStr}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: stop.isPassed
                            ? (isHC ? const Color(0xFF003833) : const Color(0xFF16A34A))
                            : context.subtextColor,
                      ),
                    ),
                    if (!stop.isPassed && stop.delayType == DelayType.delayed) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(+${stop.delayMinutes} min late)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isHC ? const Color(0xFF8B0000) : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// SECTION 2: Accessibility Verified Card
class _AccessibilityVerifiedCard extends StatelessWidget {
  const _AccessibilityVerifiedCard();

  static const _items = [
    (
      Icons.accessible_rounded,
      'Wheelchair Accessible Vehicle',
      'Ramp & step-free boarding verified',
    ),
    (
      Icons.elevator_outlined,
      'Step-Free Entrance Path',
      'Easy low-floor entry for seniors',
    ),
    (
      Icons.verified_user_rounded,
      'Ramp & Driver Support',
      'Operational ramp verified by driver today',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHC
              ? const Color(0xFF003833)
              : Colors.green.shade600.withValues(alpha: 0.3),
          width: isHC ? 2 : 1.5,
        ),
        boxShadow: isHC
            ? null
            : [
                BoxShadow(
                  color: AppColors.onSurface.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isHC ? Colors.white : Colors.green.shade100,
                  shape: BoxShape.circle,
                  border: isHC
                      ? Border.all(color: const Color(0xFF003833), width: 1.5)
                      : null,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: isHC ? const Color(0xFF003833) : Colors.green.shade800,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Accessibility Verified',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              for (var i = 0; i < _items.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 16,
                    color: isHC
                        ? Colors.black
                        : AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isHC ? Colors.white : AppColors.secondaryContainer,
                        shape: BoxShape.circle,
                        border: isHC ? Border.all(color: Colors.black, width: 1.5) : null,
                      ),
                      child: Icon(
                        _items[i].$1,
                        color: isHC ? Colors.black : AppColors.onSecondaryContainer,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _items[i].$2,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _items[i].$3,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.check_circle,
                      color: isHC ? const Color(0xFF003833) : Colors.green.shade700,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// SECTION 3: Ticket Price Card
class _TicketPriceCard extends StatelessWidget {
  const _TicketPriceCard({
    this.priceRs = 250,
  });

  final int priceRs;

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHC
              ? Colors.black
              : AppColors.primaryContainer.withValues(alpha: 0.4),
          width: isHC ? 2 : 1.5,
        ),
        boxShadow: isHC
            ? null
            : [
                BoxShadow(
                  color: AppColors.onSurface.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isHC
                  ? Colors.white
                  : AppColors.primaryContainer.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: isHC ? Border.all(color: Colors.black, width: 1.5) : null,
            ),
            child: Icon(
              Icons.payments_outlined,
              size: 30,
              color: isHC ? Colors.black : AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ticket Price',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.subtextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rs. $priceRs',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isHC ? const Color(0xFF001F3F) : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Standard Single Journey Ticket • Cash or Digital Ticket',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.subtextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// SECTION 4: Safety & Crowd Status Card
class _SafetyAndAccessibilityCard extends StatelessWidget {
  const _SafetyAndAccessibilityCard({
    required this.statusResult,
    required this.route,
    required this.crowdLevel,
  });

  final BusStatusResult? statusResult;
  final RouteResultItem? route;
  final String crowdLevel;

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;
    final status = statusResult?.status ??
        route?.accessibilityStatus ??
        AccessibilityStatus.accessible;
    final reasons = statusResult?.reasons ??
        [route?.summary ?? 'Accessibility verified by passenger community.'];

    Color headerColor;
    Color bgColor;
    IconData statusIcon;
    String statusTitle;

    if (isHC) {
      switch (status) {
        case AccessibilityStatus.accessible:
          headerColor = const Color(0xFF003833);
          bgColor = Colors.white;
          statusIcon = Icons.check_circle_rounded;
          statusTitle = 'SAFE — Verified Accessible Bus';
          break;
        case AccessibilityStatus.partial:
          headerColor = const Color(0xFF8B4500);
          bgColor = Colors.white;
          statusIcon = Icons.warning_rounded;
          statusTitle = 'ACCESSIBILITY WARNING';
          break;
        case AccessibilityStatus.notAccessible:
          headerColor = const Color(0xFF8B0000);
          bgColor = Colors.white;
          statusIcon = Icons.cancel_rounded;
          statusTitle = 'NOT ACCESSIBLE NOTICE';
          break;
      }
    } else {
      switch (status) {
        case AccessibilityStatus.accessible:
          headerColor = Colors.green.shade800;
          bgColor = Colors.green.shade50;
          statusIcon = Icons.check_circle_rounded;
          statusTitle = 'SAFE — Verified Accessible Bus';
          break;
        case AccessibilityStatus.partial:
          headerColor = Colors.amber.shade900;
          bgColor = Colors.amber.shade50;
          statusIcon = Icons.warning_rounded;
          statusTitle = 'ACCESSIBILITY WARNING';
          break;
        case AccessibilityStatus.notAccessible:
          headerColor = AppColors.error;
          bgColor = AppColors.error.withValues(alpha: 0.08);
          statusIcon = Icons.cancel_rounded;
          statusTitle = 'NOT ACCESSIBLE NOTICE';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHC ? Colors.black : headerColor.withValues(alpha: 0.4),
          width: isHC ? 2 : 1.5,
        ),
        boxShadow: isHC
            ? null
            : [
                BoxShadow(
                  color: AppColors.onSurface.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: headerColor, width: isHC ? 2 : 1),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: headerColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusTitle,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: headerColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Safety & Ride Conditions',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 12),
          _SafetyBulletItem(
            icon: Icons.groups_rounded,
            title: 'Bus Crowd Level',
            subtitle: '$crowdLevel crowding • Reserved priority seats for seniors',
            iconColor: isHC ? Colors.black : AppColors.secondary,
          ),
          const SizedBox(height: 12),
          _SafetyBulletItem(
            icon: Icons.verified_user_rounded,
            title: 'Community Safety Reports',
            subtitle: reasons.isNotEmpty ? reasons.join(' · ') : 'Verified by community riders',
            iconColor: isHC ? Colors.black : Colors.blue.shade700,
          ),
        ],
      ),
    );
  }
}

class _SafetyBulletItem extends StatelessWidget {
  const _SafetyBulletItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: context.subtextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onTrackLive,
    required this.onConfirmSchedule,
    required this.onReport,
  });

  final VoidCallback onTrackLive;
  final VoidCallback onConfirmSchedule;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;

    return Column(
      children: [
        SizedBox(
          height: context.hasLargeTargets ? 60 : 54,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onTrackLive,
            style: FilledButton.styleFrom(
              backgroundColor: isHC ? const Color(0xFF001F3F) : AppColors.primaryContainer,
              foregroundColor: Colors.white,
              elevation: isHC ? 0 : null,
              side: isHC ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: TextStyle(
                fontSize: context.hasLargeTargets ? 17.5 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            icon: Icon(Icons.map_rounded, size: context.tapIconSize),
            label: const Text('Track Live on Map'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: context.buttonHeight,
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: onConfirmSchedule,
            style: FilledButton.styleFrom(
              backgroundColor: isHC ? Colors.white : null,
              foregroundColor: isHC ? Colors.black : AppColors.primary,
              side: isHC ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: TextStyle(
                fontSize: context.buttonFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: Icon(Icons.bookmark_add_outlined, size: context.tapIconSize),
            label: const Text('Save to Trip Plan'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: context.buttonHeight,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onReport,
            style: OutlinedButton.styleFrom(
              backgroundColor: isHC ? Colors.white : null,
              foregroundColor: isHC ? const Color(0xFF8B0000) : AppColors.primaryContainer,
              side: BorderSide(
                color: isHC ? const Color(0xFF8B0000) : AppColors.outlineVariant,
                width: isHC ? 2 : 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: TextStyle(
                fontSize: context.buttonFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: Icon(Icons.report_problem_outlined, size: context.tapIconSize),
            label: const Text('Report Accessibility Condition'),
          ),
        ),
      ],
    );
  }
}

