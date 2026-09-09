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

/// Live Journey / Live Navigation screen with full Material 3 accessibility.
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

        // State: bus not currently active (offline/stale/null)
        final bool busIsInactive = liveBus == null ||
            !liveBus.isBroadcasting ||
            liveBus.status == BusStatus.offline ||
            liveBus.status == BusStatus.completed;

        final busNumber = liveBus != null && liveBus.routeNumber.isNotEmpty
            ? liveBus.routeNumber
            : resolvedBusId.replaceAll('bus_', '');
        final busName = 'Bus $busNumber';
        final routeName = journey?.routeTitle.isNotEmpty == true
            ? journey!.routeTitle
            : (liveBus?.routeName.isNotEmpty == true
                ? liveBus!.routeName
                : 'Route $busNumber');
        final nextStop = liveBus?.nextStop ?? 'Central Station';
        final passengerStop = journey?.destination ?? widget.destination;
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
              journeyInfo: '$routeName · Destination: $passengerStop',
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (busIsInactive)
                    _BusInactiveBanner(
                      busId: resolvedBusId,
                      routeTitle: routeName,
                    )
                  else
                    _MapSection(
                      busName: busName,
                      routeName: routeName,
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
                            busName: busName,
                            routeName: routeName,
                            nextStop: nextStop,
                            passengerStop: passengerStop,
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
                            destination: passengerStop,
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
                              'Emergency services contacted.',
                            ),
                            onReport: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ReportConditionScreen(
                                    initialLocation: passengerStop,
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
        Expanded(
          child: Center(
            child: Semantics(
              label: 'Loading live journey details from server',
              liveRegion: true,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading your journey…',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
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
            child: Semantics(
              container: true,
              label:
                  'Bus has not been assigned yet. Your booking is confirmed and waiting for bus assignment.',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_bus_outlined,
                      size: 44,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Bus has not been assigned yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your booking is confirmed. The operator will assign a bus before departure. Check back shortly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Semantics(
                    button: true,
                    label: 'Return to Home screen',
                    child: OutlinedButton.icon(
                      onPressed: onClose,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back to Home'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(
                          color: AppColors.primaryContainer,
                          width: 2,
                        ),
                        minimumSize: const Size(200, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
        child: Semantics(
          liveRegion: true,
          label:
              'Bus is not currently active. The bus operator has not started this trip yet.',
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
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
                  fontSize: 20,
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
                  fontSize: 15,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
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
      elevation: 2,
      shadowColor: AppColors.onSurface.withValues(alpha: 0.1),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: journeyInfo != null ? 64 : 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Close Live Navigation',
                  child: IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, size: 28),
                    color: AppColors.onSurface,
                    tooltip: 'Close Live Navigation',
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Semantics(
                        header: true,
                        child: const Text(
                          'Live Navigation',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            height: 28 / 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      if (journeyInfo != null)
                        Text(
                          journeyInfo!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
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
    required this.routeName,
    required this.liveBus,
    required this.isStale,
    required this.mapController,
    required this.busId,
  });

  final String busName;
  final String routeName;
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
      height: 270,
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
                      width: 64,
                      height: 64,
                      child: Semantics(
                        label: 'Current bus location marker for $busName',
                        child: _LiveBusMarker(
                          heading: liveBus?.heading ?? 0.0,
                          routeNumber: liveBus?.routeNumber ?? '42',
                          isStale: isStale,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── Stale / Missing telemetry overlay banner ────────────────────────
          if (liveBus == null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Semantics(
                liveRegion: true,
                label: 'Connecting to live GPS stream for $busName',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.onSurface.withValues(alpha: 0.1),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Connecting to live GPS for $busName...',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (isStale)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Semantics(
                liveRegion: true,
                label:
                    'Location unavailable. Signal lost or telemetry is stale.',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer.withValues(alpha: 0.98),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.onSurface.withValues(alpha: 0.15),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.sensors_off_rounded,
                        size: 22,
                        color: AppColors.onErrorContainer,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Location unavailable',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onErrorContainer,
                              ),
                            ),
                            Text(
                              'Signal lost — location updates delayed',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Top right bus status badge ──────────────────────────────────────
          Positioned(
            top: 16,
            right: 16,
            child: Semantics(
              label:
                  '$busName tracking status: ${isStale ? "Location unavailable" : "Live GPS active"}',
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isStale ? AppColors.error : AppColors.secondary,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.onSurface.withValues(alpha: 0.15),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isStale
                          ? Icons.sensors_off_rounded
                          : Icons.sensors_rounded,
                      size: 18,
                      color: isStale ? AppColors.error : AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      busName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Re-center button ────────────────────────────────────────────────
          if (_hasValidLocation)
            Positioned(
              top: 16,
              left: 16,
              child: Semantics(
                button: true,
                label: 'Re-center map on $busName current position',
                child: FloatingActionButton.small(
                  heroTag: 're_center_bus_btn',
                  onPressed: () {
                    mapController.move(centerLatLng, 15.0);
                  },
                  backgroundColor: AppColors.surface.withValues(alpha: 0.96),
                  foregroundColor: AppColors.primary,
                  tooltip: 'Center on Bus',
                  child: const Icon(Icons.my_location, size: 22),
                ),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: statusColor, width: 3.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.onSurface.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.directions_bus_filled_rounded,
                color: statusColor,
                size: 26,
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
              width: 58,
              height: 58,
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

// ──────────────────────────────────────────────────────────────────────────────
// Status Card: Bus info, Live badge, Last updated, Next stop, Route name
// ──────────────────────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.busName,
    required this.routeName,
    required this.nextStop,
    required this.passengerStop,
    required this.isBroadcasting,
    required this.isStale,
    required this.speed,
    required this.liveBus,
  });

  final String busName;
  final String routeName;
  final String nextStop;
  final String passengerStop;
  final bool isBroadcasting;
  final bool isStale;
  final double speed;
  final BusLocationModel? liveBus;

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'No GPS signal';
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 15) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final min = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $period';
  }

  String _getBusStatusText(BusStatus? status, bool isStale) {
    if (isStale) return 'Signal Lost';
    switch (status) {
      case BusStatus.active:
        return 'En Route';
      case BusStatus.stopped:
        return 'Stopped';
      case BusStatus.completed:
        return 'Trip Completed';
      case BusStatus.offline:
      case null:
        return 'Offline';
    }
  }

  IconData _getBusStatusIcon(BusStatus? status, bool isStale) {
    if (isStale) return Icons.warning_amber_rounded;
    switch (status) {
      case BusStatus.active:
        return Icons.navigation_rounded;
      case BusStatus.stopped:
        return Icons.pause_circle_filled_rounded;
      case BusStatus.completed:
        return Icons.task_alt_rounded;
      case BusStatus.offline:
      case null:
        return Icons.cloud_off_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final updatedText =
        _formatTimestamp(liveBus?.timestamp ?? liveBus?.lastUpdated);
    final busStatusText = _getBusStatusText(liveBus?.status, isStale);
    final busStatusIcon = _getBusStatusIcon(liveBus?.status, isStale);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row: Bus Name + Route + Live / Offline Indicator ──────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_bus_filled_rounded,
                  color: AppColors.onPrimaryContainer,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      busName,
                      style: const TextStyle(
                        fontSize: 22,
                        height: 28 / 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      routeName,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 20 / 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Live indicator pill (Icon + Text) ──────────────────────────
              Semantics(
                liveRegion: true,
                label: isBroadcasting
                    ? 'Status: Live GPS updates receiving'
                    : 'Status: Location unavailable',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isBroadcasting
                        ? AppColors.primaryContainer
                        : AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isBroadcasting
                            ? Icons.sensors_rounded
                            : Icons.sensors_off_rounded,
                        size: 16,
                        color: isBroadcasting
                            ? AppColors.onPrimaryContainer
                            : AppColors.onErrorContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isBroadcasting ? 'LIVE GPS' : 'Unavailable',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isBroadcasting
                              ? AppColors.onPrimaryContainer
                              : AppColors.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1),
          ),

          // ── Status & Telemetry details grid ────────────────────────────────
          Semantics(
            container: true,
            label:
                'Bus status: $busStatusText. Last updated: $updatedText. Next stop: $nextStop. Passenger stop: $passengerStop.',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: busStatusIcon,
                        iconColor: isStale
                            ? AppColors.error
                            : AppColors.primaryContainer,
                        label: 'Current Status',
                        value: busStatusText,
                        valueColor: isStale
                            ? AppColors.error
                            : AppColors.onSurface,
                      ),
                    ),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.access_time_rounded,
                        iconColor: isStale
                            ? AppColors.error
                            : AppColors.onSurfaceVariant,
                        label: 'Last Updated',
                        value: updatedText,
                        valueColor: isStale
                            ? AppColors.error
                            : AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.place_rounded,
                        iconColor: AppColors.primary,
                        label: 'Next Stop',
                        value: nextStop,
                        valueColor: AppColors.onSurface,
                      ),
                    ),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.flag_rounded,
                        iconColor: AppColors.secondary,
                        label: 'Your Destination',
                        value: passengerStop,
                        valueColor: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Visual Journey Timeline ────────────────────────────────────────
          _TimelineProgress(
            nextStop: nextStop,
            destination: passengerStop,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor = AppColors.onSurface,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineProgress extends StatelessWidget {
  const _TimelineProgress({
    required this.nextStop,
    required this.destination,
  });

  final String nextStop;
  final String destination;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Journey progress: Bus approaching next stop $nextStop towards destination $destination',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.route_rounded,
              color: AppColors.primaryContainer,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Next: ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          nextStop,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        'Final: ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          destination,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Live Accessibility Features Section
// ──────────────────────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
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
              const Text(
                'Live Accessibility',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const Spacer(),
              Semantics(
                label: 'Wheelchair seats occupancy level: $occupancyLevel',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Seats: $occupancyLevel',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _A11yItem(
            title: rampOperational
                ? 'Wheelchair Ramp Operational'
                : 'Ramp Out of Service',
            subtitle: rampOperational
                ? 'Verified active on this vehicle'
                : 'Driver reported maintenance required',
            icon: Icons.accessible_rounded,
            isWorking: rampOperational,
          ),
          const SizedBox(height: 10),
          _A11yItem(
            title: elevatorWorking
                ? 'Station Elevator Working'
                : 'Elevator Under Maintenance',
            subtitle: elevatorWorking
                ? 'Operational at stop'
                : 'Alternative ramp accessible at ground level',
            icon: Icons.elevator_outlined,
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
    required this.icon,
    this.isWorking = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isWorking;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title: $subtitle',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isWorking
                    ? AppColors.secondary
                    : AppColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isWorking
                    ? Icons.check_circle_rounded
                    : Icons.warning_amber_rounded,
                color: isWorking
                    ? AppColors.onPrimary
                    : AppColors.onErrorContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isWorking
                          ? AppColors.secondary
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, color: AppColors.onSurfaceVariant, size: 24),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Assistance Request & Emergency Actions
// ──────────────────────────────────────────────────────────────────────────────

class _AssistanceSection extends StatelessWidget {
  const _AssistanceSection({
    required this.onRequest,
    required this.destination,
  });

  final VoidCallback onRequest;
  final String destination;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          button: true,
          label: 'Request boarding or stop assistance from driver',
          child: SizedBox(
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
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.waving_hand_rounded, size: 24),
              label: const Text('Request Stop Assistance'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Notify driver you need extra time or ramp deployment at $destination.',
          textAlign: TextAlign.center,
          style: const TextStyle(
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
          child: Semantics(
            button: true,
            label: 'Emergency help button',
            child: SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: onEmergency,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.onError,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.emergency_rounded, size: 22),
                label: const Text('Emergency'),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Semantics(
            button: true,
            label: 'Report accessibility issue or vehicle condition',
            child: SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: onReport,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSurface,
                  side: const BorderSide(color: AppColors.outline, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.report_problem_outlined, size: 22),
                label: const Text('Report Issue'),
              ),
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
                icon: Icons.sensors_rounded,
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
    return Semantics(
      button: true,
      selected: selected,
      label: '$label tab',
      child: InkWell(
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
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
