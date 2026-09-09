import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../models/bus_location_model.dart';
import '../../models/enums/bus_status.dart';
import '../../models/journey_model.dart';
import '../../services/journey_service.dart';
import '../../services/live_bus_service.dart';
import 'boarding_assistance_screen.dart';
import 'report_condition_screen.dart';
import 'route_results_screen.dart';

/// Live Journey / Live Navigation screen (Sprint 2–3 UI).
///
/// Resolves the correct [busId] in priority order:
/// 1. Real-time stream from `journeys/{passengerId}` Firestore document.
/// 2. [busId] constructor fallback (direct launch or unauthenticated).
class LiveJourneyScreen extends StatefulWidget {
  const LiveJourneyScreen({
    super.key,
    this.origin = 'Current Location',
    this.destination = 'City Library',
    this.busId = 'bus_42',
    this.passengerId = '',
    this.route,
  });

  final String origin;
  final String destination;

  /// Fallback bus ID used when [passengerId] is empty or has no active journey.
  final String busId;

  /// Firebase Auth UID of the passenger. When non-empty, the screen subscribes
  /// to `journeys` collection to resolve the real [busId] dynamically.
  final String passengerId;

  final RouteResultItem? route;

  static const double _desktopBreakpoint = 768;

  @override
  State<LiveJourneyScreen> createState() => _LiveJourneyScreenState();
}

class _LiveJourneyScreenState extends State<LiveJourneyScreen> {
  final LiveBusService _liveBusService = LiveBusService();
  final JourneyService _journeyService = JourneyService();
  final MapController _mapController = MapController();

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Shared body builder used by both journey-aware and fallback paths.
  // ---------------------------------------------------------------------------

  Widget _buildBody(
    BuildContext context, {
    required bool isDesktop,
    required String resolvedBusId,
    JourneyModel? journey,
  }) {
    return StreamBuilder<BusLocationModel?>(
      stream: _liveBusService.listenToLiveLocation(resolvedBusId),
      builder: (context, snapshot) {
        final liveBus = snapshot.data;
        final isStale =
            liveBus == null ? false : _liveBusService.isBusStale(liveBus);

        // ── State: bus not currently active (offline/stale/null) ─────────────
        final bool busIsInactive = liveBus == null ||
            !liveBus.isBroadcasting ||
            liveBus.status == BusStatus.offline ||
            liveBus.status == BusStatus.completed;

        final busName = liveBus != null && liveBus.routeNumber.isNotEmpty
            ? 'Bus ${liveBus.routeNumber}'
            : 'Bus ${resolvedBusId.replaceAll('bus_', '')}';
        final nextStop = liveBus?.nextStop ?? 'Central Station';
        final etaMins = liveBus?.etaMinutes ?? 2;
        final isBroadcasting =
            liveBus != null && liveBus.isBroadcasting && !isStale;
        final rampWorking = liveBus?.rampOperational ?? true;
        final elevatorWorking = liveBus?.elevatorWorking ?? true;

        return Column(
          children: [
            _TopBar(
              onClose: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              journeyInfo: journey != null
                  ? '${journey.routeTitle} · ${journey.destination}'
                  : null,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (busIsInactive)
                    _BusInactiveBanner(
                      busId: resolvedBusId,
                      routeTitle: journey?.routeTitle,
                    )
                  else
                    _MapSection(
                      busName: busName,
                      liveBus: liveBus,
                      isStale: isStale,
                      mapController: _mapController,
                      busId: resolvedBusId,
                    ),
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
                            isStale: isStale,
                            speed: liveBus?.speed ?? 0.0,
                            liveBus: liveBus,
                          ),
                          const SizedBox(height: 24),
                          _LiveAccessibilitySection(
                            rampOperational: rampWorking,
                            elevatorWorking: elevatorWorking,
                            occupancyLevel:
                                liveBus?.occupancyLevel ?? 'Moderate',
                          ),
                          const SizedBox(height: 24),
                          _AssistanceSection(
                            onRequest: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const BoardingAssistanceScreen(),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= LiveJourneyScreen._desktopBreakpoint;

    // ── Path A: passenger has authenticated UID → read from journeys collection
    if (widget.passengerId.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: StreamBuilder<JourneyModel?>(
          stream: _journeyService.watchActiveJourney(widget.passengerId),
          builder: (context, journeySnapshot) {
            final journey = journeySnapshot.data;
            final hasJourney =
                journey != null && journey.busId.isNotEmpty;

            // ── State: no active journey / no busId assigned ───────────────
            if (!hasJourney) {
              // Still loading first emission
              if (journeySnapshot.connectionState ==
                  ConnectionState.waiting) {
                return _LoadingBody(
                  isDesktop: isDesktop,
                  onClose: () => Navigator.of(context)
                      .popUntil((r) => r.isFirst),
                  onNavTap: (label) => AppNavigation.handleBottomNav(
                    context,
                    label,
                    currentTab: 'Live',
                    onUnsupported: (m) => _showSnack(context, m),
                  ),
                );
              }

              // No confirmed journey: show "Bus not assigned" state.
              return _NoJourneyBody(
                isDesktop: isDesktop,
                onClose: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                onNavTap: (label) => AppNavigation.handleBottomNav(
                  context,
                  label,
                  currentTab: 'Live',
                  onUnsupported: (m) => _showSnack(context, m),
                ),
              );
            }

            // ── State: journey found with busId → subscribe to live location
            return Scaffold(
              backgroundColor: AppColors.surface,
              body: _buildBody(
                context,
                isDesktop: isDesktop,
                resolvedBusId: journey.busId,
                journey: journey,
              ),
              bottomNavigationBar: isDesktop
                  ? null
                  : _LiveBottomNav(
                      onNavTap: (label) {
                        AppNavigation.handleBottomNav(
                          context,
                          label,
                          currentTab: 'Live',
                          onUnsupported: (m) => _showSnack(context, m),
                        );
                      },
                    ),
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
                    onUnsupported: (m) => _showSnack(context, m),
                  );
                },
              ),
      );
    }

    // ── Path B: no passengerId (direct nav / unauthenticated) → busId fallback
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _buildBody(
        context,
        isDesktop: isDesktop,
        resolvedBusId: widget.busId,
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

// ──────────────────────────────────────────────────────────────────────────────
// State widgets: loading, no journey, bus inactive
// ──────────────────────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({
    required this.isDesktop,
    required this.onClose,
    required this.onNavTap,
  });
  final bool isDesktop;
  final VoidCallback onClose;
  final ValueChanged<String> onNavTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopBar(onClose: onClose),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading your journey…',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NoJourneyBody extends StatelessWidget {
  const _NoJourneyBody({
    required this.isDesktop,
    required this.onClose,
    required this.onNavTap,
  });
  final bool isDesktop;
  final VoidCallback onClose;
  final ValueChanged<String> onNavTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopBar(onClose: onClose),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_bus_outlined,
                    size: 40,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bus has not been assigned yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your booking is confirmed. The operator will assign a bus before departure. Check back shortly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to Home'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primaryContainer),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BusInactiveBanner extends StatelessWidget {
  const _BusInactiveBanner({required this.busId, this.routeTitle});
  final String busId;
  final String? routeTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      width: double.infinity,
      color: AppColors.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sensors_off_rounded,
                size: 36,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bus is not currently active.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              routeTitle != null
                  ? '$routeTitle — waiting for operator to start trip.'
                  : 'The bus operator has not started this trip yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose, this.journeyInfo});

  final VoidCallback onClose;
  final String? journeyInfo;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 1,
      shadowColor: AppColors.onSurface.withValues(alpha: 0.08),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: journeyInfo != null ? 60 : 48,
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
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Live Navigation',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          height: 28 / 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      if (journeyInfo != null)
                        Text(
                          journeyInfo!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                    ],
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
    required this.liveBus,
    required this.isStale,
    required this.mapController,
    required this.busId,
  });

  final String busName;
  final BusLocationModel? liveBus;
  final bool isStale;
  final MapController mapController;
  final String busId;

  static const LatLng _defaultCenter = LatLng(6.9271, 79.8612);

  bool get _hasValidLocation =>
      liveBus != null &&
      (liveBus!.latitude != 0.0 || liveBus!.longitude != 0.0);

  LatLng get _busLatLng => _hasValidLocation
      ? LatLng(liveBus!.latitude, liveBus!.longitude)
      : _defaultCenter;

  @override
  Widget build(BuildContext context) {
    final centerLatLng = _busLatLng;

    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: centerLatLng,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.access_transit',
              ),
              if (_hasValidLocation)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: centerLatLng,
                      width: 60,
                      height: 60,
                      child: _LiveBusMarker(
                        heading: liveBus?.heading ?? 0.0,
                        routeNumber: liveBus?.routeNumber ?? '42',
                        isStale: isStale,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Stale / Missing telemetry overlay banner
          if (liveBus == null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Connecting to live stream for $busId...',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (isStale)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: AppColors.onErrorContainer,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Signal Lost / Stale Telemetry — Bus location may be delayed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Top right bus status badge
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onSurface.withValues(alpha: 0.12),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isStale ? AppColors.error : Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    busName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Re-center button
          if (_hasValidLocation)
            Positioned(
              top: 16,
              left: 16,
              child: FloatingActionButton.small(
                heroTag: 're_center_bus_btn',
                onPressed: () {
                  mapController.move(centerLatLng, 15.0);
                },
                backgroundColor: AppColors.surface.withValues(alpha: 0.95),
                foregroundColor: AppColors.primary,
                tooltip: 'Center on Bus',
                child: const Icon(Icons.my_location),
              ),
            ),
        ],
      ),
    );
  }
}

class _LiveBusMarker extends StatelessWidget {
  const _LiveBusMarker({
    required this.heading,
    required this.routeNumber,
    required this.isStale,
  });

  final double heading;
  final String routeNumber;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final statusColor = isStale ? AppColors.error : AppColors.primaryContainer;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse ring
        if (!isStale) const _PulseMarker(),

        // Rotated marker pin
        Transform.rotate(
          angle: heading * (3.141592653589793 / 180),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: statusColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.onSurface.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.directions_bus_filled,
                color: statusColor,
                size: 24,
              ),
            ),
          ),
        ),
      ],
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Transform.scale(
          scale: 0.9 + (t * 1.5),
          child: Opacity(
            opacity: (1 - t).clamp(0.0, 0.7),
            child: Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.nextStop,
    required this.etaMinutes,
    required this.isBroadcasting,
    required this.isStale,
    required this.speed,
    required this.liveBus,
  });

  final String nextStop;
  final int etaMinutes;
  final bool isBroadcasting;
  final bool isStale;
  final double speed;
  final BusLocationModel? liveBus;

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'No signal';
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 15) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final min = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    final updatedText = _formatTimestamp(liveBus?.timestamp ?? liveBus?.lastUpdated);

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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_outlined,
                          size: 14,
                          color: AppColors.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Last updated: $updatedText',
                          style: TextStyle(
                            fontSize: 12,
                            color: isStale
                                ? AppColors.error
                                : AppColors.onSurfaceVariant,
                            fontWeight:
                                isStale ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isBroadcasting
                      ? AppColors.surfaceContainer
                      : AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isBroadcasting ? 'Live GPS' : (isStale ? 'Stale' : 'Offline'),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            title: rampOperational
                ? 'Ramp Operational'
                : 'Ramp Out of Service',
            subtitle: rampOperational
                ? 'Verified on this vehicle'
                : 'Driver flagged maintenance needed',
            trailingIcon: Icons.accessible,
            isWorking: rampOperational,
          ),
          const SizedBox(height: 8),
          _A11yItem(
            title: elevatorWorking
                ? 'Elevator Working'
                : 'Elevator Under Maintenance',
            subtitle: elevatorWorking
                ? 'Verified at stop'
                : 'Alternative ramp available',
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
