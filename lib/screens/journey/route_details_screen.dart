import 'package:flutter/material.dart';

import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../data/seed_data.dart';
import '../../logic/delay_eta_logic.dart';
import '../../logic/status_logic.dart';
import '../../models/bus.dart';
import '../../models/bus_location_model.dart';
import '../../models/report.dart';
import '../../models/station.dart';
import '../../models/trip_model.dart';
import '../../services/bus_tracking_service.dart';
import '../../services/firestore_service.dart';
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
      backgroundColor: AppColors.surface,
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
      bottomNavigationBar: isDesktop
          ? null
          : _DetailsBottomNav(
              onNavTap: (label) {
                AppNavigation.handleBottomNav(
                  context,
                  label,
                  currentTab: 'Plan',
                  onUnsupported: (message) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(message)));
                  },
                );
              },
            ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 1,
      shadowColor: AppColors.onSurface.withValues(alpha: 0.08),
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
                  color: AppColors.primary,
                  tooltip: 'Back',
                ),
                const Expanded(
                  child: Text(
                    'Departure & Route Details',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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
          stream: BusTrackingService().watchBusLocation(busId),
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

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: etaResult.isDelayed
                          ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                          : AppColors.primary.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
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
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Route $busNumber',
                              style: const TextStyle(
                                color: AppColors.onPrimary,
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
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.directions_bus,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  displayBusPlate,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: AppColors.onSurface,
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
                              color: etaResult.isLive
                                  ? const Color(0xFFDCFCE7)
                                  : AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: etaResult.isLive
                                        ? const Color(0xFF16A34A)
                                        : AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  etaResult.isLive ? 'LIVE GPS' : 'SCHEDULE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: etaResult.isLive
                                        ? const Color(0xFF166534)
                                        : AppColors.onSurfaceVariant,
                                  ),
                                ),
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
                          gradient: LinearGradient(
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
                            color: etaResult.isDelayed
                                ? const Color(0xFFFCA5A5)
                                : AppColors.primaryContainer.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Punctuality Badge
                            Row(
                              children: [
                                _buildDelayBadge(etaResult),
                                const Spacer(),
                                if (etaResult.isDelayed)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(6),
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
                            ),
                            const SizedBox(height: 12),

                            // Countdown text
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: etaResult.isDelayed
                                        ? const Color(0xFFDC2626).withValues(alpha: 0.15)
                                        : AppColors.primaryContainer.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.access_alarm_rounded,
                                    color: etaResult.isDelayed
                                        ? const Color(0xFFDC2626)
                                        : AppColors.primary,
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
                                          color: etaResult.isDelayed
                                              ? const Color(0xFF991B1B)
                                              : AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'at ${etaResult.targetStopName}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.onSurfaceVariant,
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
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            // Comparison: Scheduled Time vs Expected Time
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'SCHEDULED',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                          color: AppColors.onSurfaceVariant,
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
                                              ? AppColors.onSurfaceVariant
                                              : AppColors.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: AppColors.outlineVariant,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'EXPECTED ARRIVAL',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        etaResult.estimatedArrivalStr,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: etaResult.isDelayed
                                              ? const Color(0xFFDC2626)
                                              : AppColors.primary,
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
                          foregroundColor: AppColors.primaryContainer,
                          side: const BorderSide(
                            color: AppColors.primaryContainer,
                            width: 1.8,
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
                      const Row(
                        children: [
                          Icon(
                            Icons.route_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Route Stops Schedule & Live Progress',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
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
                          return _buildTimelineStopItem(stop);
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

  Widget _buildDelayBadge(BusArrivalEtaResult eta) {
    Color bg;
    Color border;
    Color text;
    IconData icon;

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: text),
          const SizedBox(width: 6),
          Text(
            eta.delayLabel,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStopItem(StopEtaInfo stop) {
    Color nodeColor;
    Widget nodeIcon;

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: stop.isTargetStop
            ? const Color(0xFFFEF9C3).withValues(alpha: 0.5)
            : (stop.isCurrent
                ? AppColors.primaryContainer.withValues(alpha: 0.12)
                : AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stop.isTargetStop
              ? const Color(0xFFEAB308)
              : (stop.isCurrent
                  ? AppColors.primary
                  : AppColors.outlineVariant.withValues(alpha: 0.4)),
          width: (stop.isTargetStop || stop.isCurrent) ? 1.8 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: nodeColor,
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
                          color: const Color(0xFFCA8A04),
                          borderRadius: BorderRadius.circular(4),
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
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
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
                          color: AppColors.onSurface,
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
                            ? const Color(0xFF16A34A)
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    if (!stop.isPassed && stop.delayType == DelayType.delayed) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(+${stop.delayMinutes} min late)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.shade600.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
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
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade800,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Accessibility Verified',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
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
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.secondaryContainer,
                      child: Icon(
                        _items[i].$1,
                        color: AppColors.onSecondaryContainer,
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
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _items[i].$3,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryContainer.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
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
              color: AppColors.primaryContainer.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payments_outlined,
              size: 30,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ticket Price',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rs. $priceRs',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Standard Single Journey Ticket • Cash or Digital Ticket',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
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
    final status = statusResult?.status ??
        route?.accessibilityStatus ??
        AccessibilityStatus.accessible;
    final reasons = statusResult?.reasons ??
        [route?.summary ?? 'Accessibility verified by passenger community.'];

    Color headerColor;
    Color bgColor;
    IconData statusIcon;
    String statusTitle;

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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: headerColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
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
              border: Border.all(color: headerColor.withValues(alpha: 0.3)),
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
          const Text(
            'Safety & Ride Conditions',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _SafetyBulletItem(
            icon: Icons.groups_rounded,
            title: 'Bus Crowd Level',
            subtitle: '$crowdLevel crowding • Reserved priority seats for seniors',
            iconColor: AppColors.secondary,
          ),
          const SizedBox(height: 12),
          _SafetyBulletItem(
            icon: Icons.verified_user_rounded,
            title: 'Community Safety Reports',
            subtitle: reasons.isNotEmpty ? reasons.join(' · ') : 'Verified by community riders',
            iconColor: Colors.blue.shade700,
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
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
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
    return Column(
      children: [
        SizedBox(
          height: 54,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onTrackLive,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            icon: const Icon(Icons.map_rounded, size: 22),
            label: const Text('Track Live on Map'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: onConfirmSchedule,
            style: FilledButton.styleFrom(
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: const Icon(Icons.bookmark_add_outlined, size: 20),
            label: const Text('Save to Trip Plan'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onReport,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryContainer,
              side: const BorderSide(
                color: AppColors.outlineVariant,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: const Icon(Icons.report_problem_outlined, size: 20),
            label: const Text('Report Accessibility Condition'),
          ),
        ),
      ],
    );
  }
}

class _DetailsBottomNav extends StatelessWidget {
  const _DetailsBottomNav({required this.onNavTap});

  final ValueChanged<String> onNavTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: AppColors.onSurface.withValues(alpha: 0.12),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                onTap: () => onNavTap('Home'),
              ),
              _NavItem(
                icon: Icons.directions_bus,
                label: 'Plan',
                selected: true,
                onTap: () => onNavTap('Plan'),
              ),
              _NavItem(
                icon: Icons.sensors,
                label: 'Live',
                onTap: () => onNavTap('Live'),
              ),
              _NavItem(
                icon: Icons.group_outlined,
                label: 'Community',
                onTap: () => onNavTap('Community'),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                onTap: () => onNavTap('Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: selected
            ? BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected
                  ? AppColors.onPrimaryContainer
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                height: 16 / 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.onPrimaryContainer
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
