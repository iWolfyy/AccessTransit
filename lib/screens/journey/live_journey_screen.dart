import 'package:flutter/material.dart';

import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../models/bus_location_model.dart';
import '../../services/bus_tracking_service.dart';
import 'boarding_assistance_screen.dart';
import 'report_condition_screen.dart';
import 'route_results_screen.dart';

/// Live Journey / Live Navigation screen (Sprint 2–3 UI).
class LiveJourneyScreen extends StatefulWidget {
  const LiveJourneyScreen({
    super.key,
    this.origin = 'Current Location',
    this.destination = 'City Library',
    this.busId = 'bus_42',
    this.route,
  });

  final String origin;
  final String destination;
  final String busId;
  final RouteResultItem? route;

  static const double _desktopBreakpoint = 768;

  @override
  State<LiveJourneyScreen> createState() => _LiveJourneyScreenState();
}

class _LiveJourneyScreenState extends State<LiveJourneyScreen> {
  final BusTrackingService _trackingService = BusTrackingService();

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= LiveJourneyScreen._desktopBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: StreamBuilder<BusLocationModel?>(
        stream: _trackingService.watchBusLocation(widget.busId),
        builder: (context, snapshot) {
          final liveBus = snapshot.data;
          final busName = liveBus != null ? 'Bus ${liveBus.routeNumber}' : 'Bus 42';
          final nextStop = liveBus?.nextStop ?? 'Central Station';
          final etaMins = liveBus?.etaMinutes ?? 2;
          final isBroadcasting = liveBus?.isBroadcasting ?? true;
          final rampWorking = liveBus?.rampOperational ?? true;
          final elevatorWorking = liveBus?.elevatorWorking ?? true;

          return Column(
            children: [
              _TopBar(
                onClose: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _MapSection(busName: busName, liveBus: liveBus),
                    Transform.translate(
                      offset: const Offset(0, -16),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _StatusCard(
                              nextStop: nextStop,
                              etaMinutes: etaMins,
                              isBroadcasting: isBroadcasting,
                              speed: liveBus?.speed ?? 24.0,
                            ),
                            const SizedBox(height: 24),
                            _LiveAccessibilitySection(
                              rampOperational: rampWorking,
                              elevatorWorking: elevatorWorking,
                              occupancyLevel: liveBus?.occupancyLevel ?? 'Moderate',
                            ),
                            const SizedBox(height: 24),
                            _AssistanceSection(
                              onRequest: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const BoardingAssistanceScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            _EmergencyActions(
                              onEmergency: () => _showSnack(
                                context,
                                'Emergency contacts will be available soon.',
                              ),
                              onReport: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ReportConditionScreen(
                                      initialLocation: widget.destination,
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: isDesktop ? 24 : 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: isDesktop
          ? null
          : _LiveBottomNav(
              onNavTap: (label) {
                AppNavigation.handleBottomNav(
                  context,
                  label,
                  currentTab: 'Live',
                  onUnsupported: (message) => _showSnack(context, message),
                );
              },
            ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 1,
      shadowColor: AppColors.onSurface.withValues(alpha: 0.08),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.onSurfaceVariant,
                  tooltip: 'Close Live Journey',
                ),
                const Expanded(
                  child: Text(
                    'Live Navigation',
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

class _MapSection extends StatelessWidget {
  const _MapSection({
    required this.busName,
    this.liveBus,
  });

  final String busName;
  final BusLocationModel? liveBus;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: AppColors.surfaceVariant,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined, size: 40, color: AppColors.outline),
                  const SizedBox(height: 8),
                  Text(
                    liveBus != null
                        ? 'Live GPS: ${liveBus!.latitude.toStringAsFixed(4)}, ${liveBus!.longitude.toStringAsFixed(4)}'
                        : 'Live map',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                busName,
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryContainer,
                ),
              ),
            ),
          ),
          const Center(child: _PulseMarker()),
        ],
      ),
    );
  }
}

class _PulseMarker extends StatefulWidget {
  const _PulseMarker();

  @override
  State<_PulseMarker> createState() => _PulseMarkerState();
}

class _PulseMarkerState extends State<_PulseMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;
              return Transform.scale(
                scale: 0.8 + (t * 1.7),
                child: Opacity(
                  opacity: (1 - t).clamp(0.0, 0.8),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.onSurface.withValues(alpha: 0.15),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.nextStop,
    required this.etaMinutes,
    required this.isBroadcasting,
    required this.speed,
  });

  final String nextStop;
  final int etaMinutes;
  final bool isBroadcasting;
  final double speed;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Stop: $nextStop',
                      style: const TextStyle(
                        fontSize: 18,
                        height: 24 / 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 16,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Arriving in $etaMinutes mins • ${speed.toStringAsFixed(0)} km/h',
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
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isBroadcasting
                      ? AppColors.surfaceContainer
                      : AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isBroadcasting ? 'Live GPS' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w700,
                    color: isBroadcasting
                        ? AppColors.primaryContainer
                        : AppColors.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _TimelineProgress(),
        ],
      ),
    );
  }
}

class _TimelineProgress extends StatelessWidget {
  const _TimelineProgress();

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 20,
                  bottom: 20,
                  child: Container(
                    width: 4,
                    color: AppColors.surfaceVariant,
                  ),
                ),
                Positioned(
                  top: 20,
                  child: Container(
                    width: 4,
                    height: 48,
                    color: AppColors.primaryContainer,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TimelineDot(
                      borderColor: AppColors.outlineVariant,
                      fillColor: AppColors.outlineVariant,
                      fillSize: 12,
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.onSurface.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_bus,
                        color: AppColors.primaryContainer,
                        size: 22,
                      ),
                    ),
                    _TimelineDot(
                      borderColor: AppColors.primaryContainer,
                      fillColor: AppColors.primaryContainer,
                      fillSize: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Main St & 4th Ave',
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        decoration: TextDecoration.lineThrough,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'You are here',
                      style: TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryContainer,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Central Station',
                      style: TextStyle(
                        fontSize: 18,
                        height: 24 / 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
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

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({
    required this.borderColor,
    required this.fillColor,
    required this.fillSize,
  });

  final Color borderColor;
  final Color fillColor;
  final double fillSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Center(
        child: Container(
          width: fillSize,
          height: fillSize,
          decoration: BoxDecoration(
            color: fillColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _LiveAccessibilitySection extends StatelessWidget {
  const _LiveAccessibilitySection({
    required this.rampOperational,
    required this.elevatorWorking,
    required this.occupancyLevel,
  });

  final bool rampOperational;
  final bool elevatorWorking;
  final String occupancyLevel;

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
          Row(
            children: [
              const Text(
                'Live Accessibility',
                style: TextStyle(
                  fontSize: 18,
                  height: 24 / 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Seats: $occupancyLevel',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _A11yItem(
            title: rampOperational ? 'Ramp Operational' : 'Ramp Out of Service',
            subtitle: rampOperational ? 'Verified on this vehicle' : 'Driver flagged maintenance needed',
            trailingIcon: Icons.accessible,
            isWorking: rampOperational,
          ),
          const SizedBox(height: 8),
          _A11yItem(
            title: elevatorWorking ? 'Elevator Working' : 'Elevator Under Maintenance',
            subtitle: elevatorWorking ? 'Verified at stop' : 'Alternative ramp available',
            trailingIcon: Icons.elevator_outlined,
            isWorking: elevatorWorking,
          ),
        ],
      ),
    );
  }
}

class _A11yItem extends StatelessWidget {
  const _A11yItem({
    required this.title,
    required this.subtitle,
    required this.trailingIcon,
    this.isWorking = true,
  });

  final String title;
  final String subtitle;
  final IconData trailingIcon;
  final bool isWorking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isWorking ? AppColors.secondary : AppColors.error,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isWorking ? Icons.check_circle : Icons.warning_amber_rounded,
              color: AppColors.onPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    color: isWorking ? AppColors.secondary : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          Icon(trailingIcon, color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _AssistanceSection extends StatelessWidget {
  const _AssistanceSection({required this.onRequest});

  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 56,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onRequest,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryContainer,
              side: const BorderSide(
                color: AppColors.primaryContainer,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: const Icon(Icons.waving_hand_outlined, size: 22),
            label: const Text('Request Stop Assistance'),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Notify driver you need extra time or ramp deployment at Central Station.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _EmergencyActions extends StatelessWidget {
  const _EmergencyActions({
    required this.onEmergency,
    required this.onReport,
  });

  final VoidCallback onEmergency;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: onEmergency,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(Icons.emergency, size: 20),
              label: const Text('Emergency'),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 56,
            child: OutlinedButton.icon(
              onPressed: onReport,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onSurface,
                side: const BorderSide(color: AppColors.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(Icons.report_outlined, size: 20),
              label: const Text('Report Issue'),
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveBottomNav extends StatelessWidget {
  const _LiveBottomNav({required this.onNavTap});

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
                icon: Icons.directions_bus_outlined,
                label: 'Plan',
                onTap: () => onNavTap('Plan'),
              ),
              _NavItem(
                icon: Icons.sensors,
                label: 'Live',
                selected: true,
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
                fontSize: 12,
                height: 16 / 12,
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
