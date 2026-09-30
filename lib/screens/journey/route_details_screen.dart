import 'package:flutter/material.dart';

import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../data/seed_data.dart';
import '../../logic/status_logic.dart';
import '../../models/bus.dart';
import '../../models/report.dart';
import '../../models/station.dart';
import '../../models/trip_model.dart';
import '../../services/firestore_service.dart';
import '../../services/trip_service.dart';
import '../../core/utils/time_utils.dart';
import 'boarding_assistance_screen.dart';
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

                                // ACTION BUTTONS: Confirm Schedule
                                _ActionButtons(
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

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStops = bus?.stops.isNotEmpty == true
        ? bus!.stops
        : ['st_pettah', 'st_maradana', 'st_borella', 'st_kottawa'];

    final busNumber = bus?.routeNo ?? route?.title.replaceAll('Route ', '') ?? '138';
    final initialScheduledDeparture = bus?.getScheduledTimeForStop(0) ?? '08:00 AM';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: StreamBuilder<TripModel?>(
        stream: TripService().watchActiveTripForBus(busId),
        builder: (context, snapshot) {
          final trip = snapshot.data;
          final isInProgress = trip != null && trip.isInProgress;
          final stopsToRender =
              trip?.stops.isNotEmpty == true ? trip!.stops : effectiveStops;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Departure Header & Station Details
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.departure_board_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Route $busNumber Departure Details',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Boarding Station: $origin',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Final Destination: $destination',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Departure Time & Fleet Frequency Info Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryContainer.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_filled_rounded, color: AppColors.primary, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scheduled Departure: $initialScheduledDeparture',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Frequency: Every 15 min • 4 Buses Active',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isInProgress ? Colors.green.shade100 : AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isInProgress ? 'BUS DEPARTED' : 'ON TIME',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isInProgress ? Colors.green.shade900 : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Boarding Assistance Request Button
              OutlinedButton.icon(
                onPressed: () {
                  final effectiveRouteNo = route?.title ?? (bus != null ? 'Route ${bus!.routeNo}' : 'Route $busNumber');
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BoardingAssistanceScreen(
                        busId: busId,
                        busLabel: effectiveRouteNo,
                        stopName: origin,
                        stationId: route?.intermediateStops.isNotEmpty == true
                            ? route!.intermediateStops.first
                            : 'st_fort',
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryContainer,
                  side: const BorderSide(
                    color: AppColors.primaryContainer,
                    width: 2,
                  ),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: const Icon(Icons.assist_walker_rounded, size: 22),
                label: const Text('Request Boarding Assistance'),
              ),
              const SizedBox(height: 20),

              const Text(
                'Full Departure & Stop Schedule',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              // Stops Timetable List
              FutureBuilder<List<Station>>(
                future: FirestoreService().getStations(),
                builder: (context, stationsSnapshot) {
                  final stationsList =
                      stationsSnapshot.data ?? SeedData.colomboStations;
                  final stationsMap = {
                    for (final s in stationsList) s.id: s,
                  };

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stopsToRender.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final stopId = stopsToRender[index];
                      final rawStationName = stationsMap[stopId]?.name ??
                          stopId
                              .replaceAll('st_', '')
                              .replaceAll('_', ' ')
                              .toUpperCase();

                      String haltTag;
                      Color tagBgColor;
                      Color tagTextColor;

                      if (index == 0) {
                        haltTag = 'START STOP';
                        tagBgColor = Colors.blue.shade100;
                        tagTextColor = Colors.blue.shade900;
                      } else if (index == stopsToRender.length - 1) {
                        haltTag = 'FINAL STOP';
                        tagBgColor = Colors.purple.shade100;
                        tagTextColor = Colors.purple.shade900;
                      } else {
                        haltTag = 'HALT ${index + 1}';
                        tagBgColor = AppColors.surfaceContainer;
                        tagTextColor = AppColors.onSurfaceVariant;
                      }

                      final isConfirmedCurrent =
                          isInProgress && index == trip.currentStopIndex;
                      final isPassed =
                          isInProgress && index < trip.currentStopIndex;

                      final schedTime = bus?.getScheduledTimeForStop(index) ?? '08:00 AM';
                      final timing = trip?.stopTimes[stopId];
                      String timeSubtext = '';

                      if (isInProgress && timing != null) {
                        if (isPassed && timing.actualArrival != null) {
                          timeSubtext =
                              'Reached at ${_formatTime(timing.actualArrival!)} (Sched: $schedTime)';
                        } else if (isConfirmedCurrent) {
                          final timeStr = timing.actualArrival != null
                              ? _formatTime(timing.actualArrival!)
                              : schedTime;
                          timeSubtext = 'Arrived at $timeStr (Sched: $schedTime)';
                        } else {
                          timeSubtext = 'Scheduled Time: $schedTime';
                        }
                      } else {
                        timeSubtext = 'Scheduled Departure / Arrival: $schedTime';
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isConfirmedCurrent
                              ? AppColors.primaryContainer.withValues(alpha: 0.15)
                              : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isConfirmedCurrent
                                ? AppColors.primary
                                : AppColors.outlineVariant.withValues(alpha: 0.5),
                            width: isConfirmedCurrent ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isConfirmedCurrent
                                    ? AppColors.primary
                                    : (isPassed
                                        ? Colors.green
                                        : AppColors.surfaceVariant),
                              ),
                              child: Center(
                                child: isConfirmedCurrent
                                    ? const Icon(
                                        Icons.directions_bus,
                                        size: 18,
                                        color: Colors.white,
                                      )
                                    : (isPassed
                                        ? const Icon(
                                            Icons.check,
                                            size: 18,
                                            color: Colors.white,
                                          )
                                        : Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.onSurface,
                                            ),
                                          )),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: tagBgColor,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          haltTag,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: tagTextColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (isConfirmedCurrent)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'BUS IS HERE NOW',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    rawStationName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    timeSubtext,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isConfirmedCurrent
                                          ? AppColors.primary
                                          : AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
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
    required this.onConfirmSchedule,
    required this.onReport,
  });

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
            onPressed: onConfirmSchedule,
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
            icon: const Icon(Icons.check_circle_rounded, size: 22),
            label: const Text('Confirm Bus Schedule'),
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
                color: AppColors.primaryContainer,
                width: 2,
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
            label: const Text('Report a Condition'),
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
