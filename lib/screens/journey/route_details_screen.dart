import 'package:flutter/material.dart';

import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../data/seed_data.dart';
import '../../logic/status_logic.dart';
import '../../models/bus.dart';
import '../../models/report.dart';
import '../../models/station.dart';
import '../../models/trip_model.dart';
import '../../services/eta_service.dart';
import '../../services/firestore_service.dart';
import '../../services/trip_service.dart';
import '../../core/utils/time_utils.dart';
import 'boarding_assistance_screen.dart';

import 'journey_confirmation_screen.dart';
import 'report_condition_screen.dart';
import 'route_results_screen.dart';

/// Route Details screen — journey steps, accessibility confirmation, actions.
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

  int get _durationMinutes => route?.durationMinutes ?? 28;

  String get _arriveLabel {
    final now = DateTime.now().add(Duration(minutes: _durationMinutes));
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return 'Arrive $hour:$minute $period • LKR 250';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;
    final effectiveBusId = bus?.id ?? route?.busId ?? 'bus_138_outbound';
    final firestoreService = FirestoreService();

    // ETA Service integration (AC-76)
    final etaResult = EtaService().calculateEta(
      liveBus: null,
      stopName: destination,
    );

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
                                _SummaryCard(
                                  origin: origin,
                                  destination: destination,
                                  durationMinutes: _durationMinutes,
                                  arriveLabel: _arriveLabel,
                                  etaDisplayText: etaResult.displayText,
                                ),
                                const SizedBox(height: 24),
                                _JourneyStepsCard(
                                  destination: destination,
                                  origin: origin,
                                  route: route,
                                  bus: liveBus,
                                  crowdLevel: liveCrowdLevel,
                                  wheelchairAvailable:
                                      (liveStatusResult?.status ??
                                              route?.accessibilityStatus) !=
                                          AccessibilityStatus.notAccessible,
                                ),
                                const SizedBox(height: 24),
                                _DepartureAndStopsTimelineCard(
                                  bus: liveBus,
                                  busId: effectiveBusId,
                                ),
                                const SizedBox(height: 24),
                                const SizedBox(height: 24),
                                _AccessibilityStatusNoticeCard(
                                  statusResult: liveStatusResult,
                                  route: route,
                                ),
                                const SizedBox(height: 24),
                                _ActionButtons(
                                  onStartNavigation: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            JourneyConfirmationScreen(
                                          origin: origin,
                                          destination: destination,
                                          route: route,
                                        ),
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
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.primary,
                  tooltip: 'Back',
                ),
                const Expanded(
                  child: Text(
                    'Route Details',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      height: 28 / 22,
                      fontWeight: FontWeight.w700,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.origin,
    required this.destination,
    required this.durationMinutes,
    required this.arriveLabel,
    this.etaDisplayText = '',
  });

  final String origin;
  final String destination;
  final int durationMinutes;
  final String arriveLabel;
  final String etaDisplayText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To $destination',
                      style: const TextStyle(
                        fontSize: 18,
                        height: 24 / 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'From $origin',
                      style: const TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$durationMinutes min',
                    style: const TextStyle(
                      fontSize: 22,
                      height: 28 / 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    arriveLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (etaDisplayText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      etaDisplayText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            height: 128,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 36, color: AppColors.outline),
                  SizedBox(height: 8),
                  Text(
                    'Map preview',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyStepsCard extends StatelessWidget {
  const _JourneyStepsCard({
    required this.destination,
    required this.crowdLevel,
    required this.wheelchairAvailable,
    this.route,
    this.bus,
    this.origin = 'Colombo Fort Station',
  });

  final String destination;
  final String crowdLevel;
  final bool wheelchairAvailable;
  final RouteResultItem? route;
  final Bus? bus;
  final String origin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Journey Steps',
            style: TextStyle(
              fontSize: 18,
              height: 24 / 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Positioned(
                left: 11,
                top: 8,
                bottom: 24,
                child: Container(
                  width: 2,
                  color: AppColors.surfaceVariant,
                ),
              ),
              Column(
                children: [
                  _WalkStep(),
                  const SizedBox(height: 24),
                  _BoardStep(
                    route: route,
                    bus: bus,
                    origin: origin,
                  ),
                  const SizedBox(height: 24),
                  _OnBoardStep(
                    crowdLevel: crowdLevel,
                    wheelchairAvailable: wheelchairAvailable,
                  ),
                  const SizedBox(height: 24),
                  _ArriveStep(destination: destination),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalkStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.outline, width: 2),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.outline,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.directions_walk, color: AppColors.outline, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Walk to Station',
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '5 min walk (300m) - Step-free path',
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BoardStep extends StatelessWidget {
  const _BoardStep({
    this.route,
    this.bus,
    this.origin = 'Colombo Fort Station',
  });

  final RouteResultItem? route;
  final Bus? bus;
  final String origin;

  @override
  Widget build(BuildContext context) {
    final busNum = route?.busId.replaceAll('bus_', '') ?? '42';
    final busTitle = route?.title ?? 'Bus $busNum';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.directions_bus,
            size: 16,
            color: AppColors.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      busNum,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          busTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Board at Stop B',
                          style: TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  final effectiveBusId = bus?.id ?? route?.busId ?? 'bus_138_outbound';
                  final effectiveRouteNo = route?.title ?? (bus != null ? 'Route ${bus!.routeNo}' : 'Route 138');
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BoardingAssistanceScreen(
                        busId: effectiveBusId,
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
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(Icons.assist_walker, size: 20),
                label: const Text('Request Boarding Assistance'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnBoardStep extends StatelessWidget {
  const _OnBoardStep({
    required this.crowdLevel,
    required this.wheelchairAvailable,
  });

  final String crowdLevel;
  final bool wheelchairAvailable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.primary, width: 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '6 stops (12 min)',
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(
                  icon: Icons.groups,
                  label: '$crowdLevel crowding',
                ),
                if (wheelchairAvailable)
                  const _Pill(
                    icon: Icons.accessible,
                    label: 'Wheelchair space available',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ArriveStep extends StatelessWidget {
  const _ArriveStep({required this.destination});

  final String destination;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Arrive at $destination',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessibilityStatusNoticeCard extends StatelessWidget {
  const _AccessibilityStatusNoticeCard({
    required this.statusResult,
    required this.route,
  });

  final BusStatusResult? statusResult;
  final RouteResultItem? route;

  @override
  Widget build(BuildContext context) {
    final status = statusResult?.status ??
        route?.accessibilityStatus ??
        AccessibilityStatus.accessible;
    final reasons = statusResult?.reasons ??
        [route?.summary ?? 'Accessibility information verified.'];

    if (status == AccessibilityStatus.accessible) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.onSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Safe — Community Verified Accessible',
                    style: TextStyle(
                      fontSize: 17,
                      height: 22 / 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reasons.isNotEmpty
                        ? reasons.join(' · ')
                        : 'Step-free boarding & operational wheelchair ramp.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
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

    final isNotAcc = status == AccessibilityStatus.notAccessible;
    final headerColor = isNotAcc ? AppColors.error : Colors.amber.shade900;
    final bgColor = isNotAcc
        ? AppColors.error.withValues(alpha: 0.1)
        : Colors.amber.shade50;
    final iconData =
        isNotAcc ? Icons.cancel_outlined : Icons.warning_amber_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: headerColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconData, color: headerColor, size: 26),
              const SizedBox(width: 10),
              Text(
                isNotAcc
                    ? 'Not Accessible Notice'
                    : 'Accessibility Warning Notice',
                style: TextStyle(
                  fontSize: 17,
                  height: 22 / 17,
                  fontWeight: FontWeight.bold,
                  color: headerColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...reasons.map(
            (reason) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: headerColor,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      reason,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onStartNavigation,
    required this.onReport,
  });

  final VoidCallback onStartNavigation;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 48,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onStartNavigation,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: const Icon(Icons.navigation, size: 20),
            label: const Text('Start Navigation'),
          ),
        ),
        const SizedBox(height: 16),
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

class _DepartureAndStopsTimelineCard extends StatelessWidget {
  const _DepartureAndStopsTimelineCard({
    required this.bus,
    required this.busId,
  });

  final Bus? bus;
  final String busId;

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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 4,
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
              Row(
                children: [
                  const Icon(Icons.departure_board, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Departure & Stops Timeline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isInProgress
                          ? Colors.green.withValues(alpha: 0.15)
                          : AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isInProgress
                            ? Colors.green.shade600
                            : AppColors.outlineVariant,
                      ),
                    ),
                    child: Text(
                      isInProgress ? 'Trip Active' : 'Not yet departed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isInProgress
                            ? Colors.green.shade800
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isInProgress && trip.actualDepartureTime != null
                    ? 'Departed start station at ${_formatTime(trip.actualDepartureTime!)} (${TimeUtils.formatRelativeTime(trip.actualDepartureTime!)})'
                    : 'Bus has not departed the main stand yet.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
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
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final stopId = stopsToRender[index];
                      final stationName = stationsMap[stopId]?.name ??
                          stopId
                              .replaceAll('st_', '')
                              .replaceAll('_', ' ')
                              .toUpperCase();
                      final isConfirmedCurrent =
                          isInProgress && index == trip.currentStopIndex;
                      final isPassed =
                          isInProgress && index < trip.currentStopIndex;

                      final timing = trip?.stopTimes[stopId];
                      String timeSubtext = '';

                      if (isInProgress && timing != null) {
                        if (isPassed && timing.actualArrival != null) {
                          timeSubtext =
                              'Reached at ${_formatTime(timing.actualArrival!)}';
                        } else if (isConfirmedCurrent) {
                          final timeStr = timing.actualArrival != null
                              ? _formatTime(timing.actualArrival!)
                              : _formatTime(timing.estimatedArrival);
                          timeSubtext = 'Confirmed here at $timeStr';
                        } else {
                          final diffMins = timing.estimatedArrival
                              .difference(DateTime.now())
                              .inMinutes
                              .clamp(1, 999);
                          timeSubtext =
                              'Est. ${_formatTime(timing.estimatedArrival)} (in about $diffMins min)';
                        }
                      } else {
                        timeSubtext = 'Scheduled stop';
                      }

                      return Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isConfirmedCurrent
                                  ? AppColors.primaryContainer
                                  : (isPassed
                                      ? Colors.green
                                      : AppColors.surfaceContainer),
                              border: Border.all(
                                color: isConfirmedCurrent
                                    ? AppColors.primary
                                    : (isPassed
                                        ? Colors.green
                                        : AppColors.outlineVariant),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              isConfirmedCurrent
                                  ? Icons.directions_bus
                                  : (isPassed ? Icons.check : Icons.circle),
                              size: 12,
                              color: isConfirmedCurrent || isPassed
                                  ? Colors.white
                                  : AppColors.outline,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        stationName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isConfirmedCurrent
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                    ),
                                    if (isConfirmedCurrent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Bus is here now',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.onPrimary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  timeSubtext,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isConfirmedCurrent
                                        ? AppColors.primary
                                        : AppColors.onSurfaceVariant,
                                    fontWeight: isConfirmedCurrent
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

