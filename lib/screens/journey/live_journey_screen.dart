import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../data/seed_data.dart';
import '../../logic/delay_eta_logic.dart';
import '../../models/bus.dart';
import '../../models/bus_location_model.dart';
import '../../models/enums/bus_status.dart';
import '../../models/journey_model.dart';
import '../../models/station.dart';
import '../../models/trip_model.dart';
import '../../services/eta_service.dart';
import '../../services/firestore_service.dart';
import '../../services/journey_service.dart';
import '../../services/live_bus_service.dart';
import '../../services/trip_service.dart';
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
    this.busId = 'bus_01',
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

  bool _isAlertActive = false;

  void _toggleAlert(String destination) {
    setState(() {
      _isAlertActive = !_isAlertActive;
    });
    HapticFeedback.mediumImpact();
    _showSnack(
      context,
      _isAlertActive
          ? '🔔 Alert set: We will notify you 1 stop before $destination!'
          : '🔕 Stop alert cancelled.',
    );
  }

  void _handleClose(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
        if (snapshot.hasError) {
          return Column(
            children: [
              _TopBar(
                onClose: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  }
                },
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Telemetry Connection Error',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
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

        final liveBus = snapshot.data;
        final isStale =
            liveBus == null ? false : _liveBusService.isBusStale(liveBus);

        final busNumber = liveBus != null && liveBus.routeNumber.isNotEmpty
            ? liveBus.routeNumber
            : resolvedBusId.replaceAll('bus_', '');
        final busName = 'Bus $busNumber';
        final routeName = journey?.routeTitle.isNotEmpty == true
            ? journey!.routeTitle
            : (liveBus?.routeName.isNotEmpty == true
                ? liveBus!.routeName
                : 'Route $busNumber');
        final passengerStop = journey?.destination ?? widget.destination;
        final isBroadcasting =
            liveBus != null && liveBus.isBroadcasting && !isStale;
        final rampWorking = liveBus?.rampOperational ?? true;
        final elevatorWorking = liveBus?.elevatorWorking ?? true;

        final effectiveOrigin = widget.route?.origin ?? widget.origin;
        final effectiveDestination = passengerStop;

        Bus matchedBus = widget.route?.rawBus ??
            Bus(
              id: resolvedBusId,
              routeNo: busNumber,
              busNo: busNumber,
              hasRamp: rampWorking,
              lowFloor: true,
              rampOk: rampWorking,
              occupancy: liveBus?.occupancyLevel ?? 'Moderate',
              stops: [effectiveOrigin, effectiveDestination],
              scheduleTimes: const ['08:00 AM', '08:45 AM'],
            );

        final stationsMap = {
          for (final st in SeedData.colomboStations) st.id: st,
          for (final st in SeedData.colomboStations) st.name: st,
        };

        final etaResult = DelayEtaCalculator.calculateArrivalEta(
          bus: matchedBus,
          targetStopIdOrName: effectiveOrigin,
          liveBusLocation: liveBus,
          stationsMap: stationsMap,
        );

        final routeNumber = (widget.route?.routeNo?.isNotEmpty == true)
            ? widget.route!.routeNo!
            : busNumber;
        final busPlate = (widget.route?.busNo?.isNotEmpty == true)
            ? widget.route!.busNo!
            : 'WP $busNumber';
        final fareLkr = widget.route?.estimatedPriceLkr ?? 80;

        if (isDesktop) {
          return Row(
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _LiveMapTrackingView(
                        busId: resolvedBusId,
                        busName: busName,
                        liveBus: liveBus,
                        origin: effectiveOrigin,
                        destination: effectiveDestination,
                        route: widget.route,
                        matchedBus: matchedBus,
                        etaResult: etaResult,
                        isBroadcasting: isBroadcasting,
                        isStale: isStale,
                        isFullScreen: true,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _FloatingTopBar(
                        onClose: () => _handleClose(context),
                        routeNumber: routeNumber,
                        destination: effectiveDestination,
                        isLiveGps: isBroadcasting,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  color: AppColors.surface,
                  child: _DraggableJourneySheetContent(
                    busId: resolvedBusId,
                    busName: busName,
                    routeName: routeName,
                    routeNumber: routeNumber,
                    busPlate: busPlate,
                    fareLkr: fareLkr,
                    effectiveOrigin: effectiveOrigin,
                    effectiveDestination: effectiveDestination,
                    etaResult: etaResult,
                    isBroadcasting: isBroadcasting,
                    isStale: isStale,
                    rampWorking: rampWorking,
                    elevatorWorking: elevatorWorking,
                    occupancyLevel: liveBus?.occupancyLevel ?? 'Moderate',
                    isAlertActive: _isAlertActive,
                    onToggleAlert: () => _toggleAlert(effectiveDestination),
                    scrollController: null,
                    isDesktop: true,
                    speed: liveBus?.speed ?? 0.0,
                    liveBus: liveBus,
                    onShowSnack: (m) => _showSnack(context, m),
                  ),
                ),
              ),
            ],
          );
        }

        return Stack(
          children: [
            Positioned.fill(
              child: _LiveMapTrackingView(
                busId: resolvedBusId,
                busName: busName,
                liveBus: liveBus,
                origin: effectiveOrigin,
                destination: effectiveDestination,
                route: widget.route,
                matchedBus: matchedBus,
                etaResult: etaResult,
                isBroadcasting: isBroadcasting,
                isStale: isStale,
                isFullScreen: true,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _FloatingTopBar(
                onClose: () => _handleClose(context),
                routeNumber: routeNumber,
                destination: effectiveDestination,
                isLiveGps: isBroadcasting,
              ),
            ),
            DraggableScrollableSheet(
              initialChildSize: 0.38,
              minChildSize: 0.16,
              maxChildSize: 0.90,
              snap: true,
              snapSizes: const [0.16, 0.38, 0.90],
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: _DraggableJourneySheetContent(
                    busId: resolvedBusId,
                    busName: busName,
                    routeName: routeName,
                    routeNumber: routeNumber,
                    busPlate: busPlate,
                    fareLkr: fareLkr,
                    effectiveOrigin: effectiveOrigin,
                    effectiveDestination: effectiveDestination,
                    etaResult: etaResult,
                    isBroadcasting: isBroadcasting,
                    isStale: isStale,
                    rampWorking: rampWorking,
                    elevatorWorking: elevatorWorking,
                    occupancyLevel: liveBus?.occupancyLevel ?? 'Moderate',
                    isAlertActive: _isAlertActive,
                    onToggleAlert: () => _toggleAlert(effectiveDestination),
                    scrollController: scrollController,
                    isDesktop: false,
                    speed: liveBus?.speed ?? 0.0,
                    liveBus: liveBus,
                    onShowSnack: (m) => _showSnack(context, m),
                  ),
                );
              },
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
            if (journeySnapshot.hasError) {
              return _ErrorBody(
                error: journeySnapshot.error.toString(),
                onClose: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  }
                },
              );
            }

            final journey = journeySnapshot.data;
            final hasJourney =
                journey != null && journey.busId.isNotEmpty;

            // ── State: no active journey / no busId assigned ───────────────
            if (!hasJourney) {
              if (journeySnapshot.connectionState ==
                  ConnectionState.waiting) {
                return _LoadingBody(
                  onClose: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    }
                  },
                );
              }

              return _NoJourneyBody(
                onClose: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  }
                },
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
              bottomNavigationBar: null,
            );
          },
        ),
        bottomNavigationBar: null,
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
      bottomNavigationBar: null,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// State widgets: loading, error, no journey, bus inactive
// ──────────────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.error,
    required this.onClose,
  });

  final String error;
  final VoidCallback onClose;

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
                const Icon(
                  Icons.error_outline,
                  size: 56,
                  color: AppColors.error,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Unable to Load Journey',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
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
                    side: const BorderSide(
                      color: AppColors.primaryContainer,
                      width: 2,
                    ),
                    minimumSize: const Size(200, 48),
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

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({
    required this.onClose,
  });
  final VoidCallback onClose;

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
    required this.onClose,
  });
  final VoidCallback onClose;

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



class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 2,
      shadowColor: AppColors.onSurface.withValues(alpha: 0.1),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 52,
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
                  child: Center(
                    child: Semantics(
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

// ──────────────────────────────────────────────────────────────────────────────
// Phase 3: Floating Top Bar (LMT Go + AccessTransit)
// ──────────────────────────────────────────────────────────────────────────────

class _FloatingTopBar extends StatelessWidget {
  const _FloatingTopBar({
    required this.onClose,
    required this.routeNumber,
    required this.destination,
    required this.isLiveGps,
  });

  final VoidCallback onClose;
  final String routeNumber;
  final String destination;
  final bool isLiveGps;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: 'Back to Route Results',
                child: IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.arrow_back_rounded, size: 24),
                  color: AppColors.onSurface,
                  tooltip: 'Back',
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFC2185B), // LMT Go Crimson badge
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  routeNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Tracking to',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      destination,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isLiveGps
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLiveGps
                        ? const Color(0xFF81C784)
                        : const Color(0xFFFFB74D),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isLiveGps
                            ? const Color(0xFF2E7D32)
                            : Colors.orange.shade800,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isLiveGps ? 'LIVE' : 'SCHED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isLiveGps
                            ? const Color(0xFF1B5E20)
                            : Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Phase 3: Enhanced Stops Timeline (LMT Go per-stop ETA & progression)
// ──────────────────────────────────────────────────────────────────────────────

class _EnhancedStopsTimelineCard extends StatelessWidget {
  const _EnhancedStopsTimelineCard({
    required this.stopsTimeline,
    required this.targetStop,
  });

  final List<StopEtaInfo> stopsTimeline;
  final String targetStop;

  @override
  Widget build(BuildContext context) {
    if (stopsTimeline.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.alt_route_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upcoming Stops (${stopsTimeline.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const Text(
                    'Real-time stop progression & ETA',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF81C784)),
                ),
                child: const Text(
                  'Live Stops',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stopsTimeline.length,
            itemBuilder: (context, index) {
              final stop = stopsTimeline[index];
              final isFirst = index == 0;
              final isLast = index == stopsTimeline.length - 1;

              return _StopTimelineItem(
                stop: stop,
                isFirst: isFirst,
                isLast: isLast,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StopTimelineItem extends StatelessWidget {
  const _StopTimelineItem({
    required this.stop,
    required this.isFirst,
    required this.isLast,
  });

  final StopEtaInfo stop;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isPassed = stop.isPassed;
    final isCurrent = stop.isCurrent;
    final isTarget = stop.isTargetStop;

    final Color nodeColor;
    final Color borderColor;
    final Widget nodeIcon;

    if (isPassed) {
      nodeColor = const Color(0xFFE8F5E9);
      borderColor = const Color(0xFF4CAF50);
      nodeIcon = const Icon(Icons.check_rounded, size: 12, color: Color(0xFF2E7D32));
    } else if (isCurrent) {
      nodeColor = AppColors.primary;
      borderColor = AppColors.primary;
      nodeIcon = const Icon(Icons.directions_bus_rounded, size: 14, color: Colors.white);
    } else if (isTarget) {
      nodeColor = const Color(0xFFFF9800);
      borderColor = const Color(0xFFE65100);
      nodeIcon = const Icon(Icons.star_rounded, size: 14, color: Colors.white);
    } else {
      nodeColor = Colors.white;
      borderColor = AppColors.outlineVariant;
      nodeIcon = Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: AppColors.outlineVariant,
          shape: BoxShape.circle,
        ),
      );
    }

    final Color lineColor = isPassed
        ? const Color(0xFF81C784)
        : AppColors.outlineVariant.withValues(alpha: 0.5);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator column (Line - Node - Line)
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Expanded(
                  child: isFirst
                      ? const SizedBox.shrink()
                      : Container(width: 2.5, color: lineColor),
                ),
                Container(
                  width: isCurrent || isTarget ? 26 : 20,
                  height: isCurrent || isTarget ? 26 : 20,
                  decoration: BoxDecoration(
                    color: nodeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor, width: 2),
                    boxShadow: (isCurrent || isTarget)
                        ? [
                            BoxShadow(
                              color: (isCurrent ? AppColors.primary : Colors.orange)
                                  .withValues(alpha: 0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(child: nodeIcon),
                ),
                Expanded(
                  child: isLast
                      ? const SizedBox.shrink()
                      : Container(width: 2.5, color: lineColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Stop details and timing
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                stop.stopName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isCurrent || isTarget
                                      ? FontWeight.w800
                                      : (isPassed
                                          ? FontWeight.w500
                                          : FontWeight.w600),
                                  color: isPassed
                                      ? AppColors.onSurfaceVariant
                                      : AppColors.onSurface,
                                ),
                              ),
                            ),
                            if (isTarget) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFFFB74D),
                                  ),
                                ),
                                child: const Text(
                                  'YOUR STOP',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFE65100),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isCurrent
                              ? 'Bus is currently here'
                              : (isPassed
                                  ? 'Passed'
                                  : 'Scheduled: ${stop.scheduledTimeStr}'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal,
                            color: isCurrent
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        stop.estimatedTimeStr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent || isTarget
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isPassed
                              ? AppColors.onSurfaceVariant
                              : AppColors.onSurface,
                        ),
                      ),
                      if (stop.delayLabel.isNotEmpty &&
                          stop.delayType != DelayType.onTime &&
                          !isPassed) ...[
                        const SizedBox(height: 2),
                        Text(
                          stop.delayLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: stop.delayType == DelayType.delayed
                                ? const Color(0xFFD84315)
                                : const Color(0xFF0277BD),
                          ),
                        ),
                      ],
                    ],
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

// ──────────────────────────────────────────────────────────────────────────────
// Phase 3: Draggable Journey Sheet Content (LMT Go bottom sheet)
// ──────────────────────────────────────────────────────────────────────────────

class _DraggableJourneySheetContent extends StatelessWidget {
  const _DraggableJourneySheetContent({
    required this.busId,
    required this.busName,
    required this.routeName,
    required this.routeNumber,
    required this.busPlate,
    required this.fareLkr,
    required this.effectiveOrigin,
    required this.effectiveDestination,
    required this.etaResult,
    required this.isBroadcasting,
    required this.isStale,
    required this.rampWorking,
    required this.elevatorWorking,
    required this.occupancyLevel,
    required this.isAlertActive,
    required this.onToggleAlert,
    required this.scrollController,
    required this.isDesktop,
    required this.speed,
    required this.liveBus,
    required this.onShowSnack,
  });

  final String busId;
  final String busName;
  final String routeName;
  final String routeNumber;
  final String busPlate;
  final int fareLkr;
  final String effectiveOrigin;
  final String effectiveDestination;
  final BusArrivalEtaResult etaResult;
  final bool isBroadcasting;
  final bool isStale;
  final bool rampWorking;
  final bool elevatorWorking;
  final String occupancyLevel;
  final bool isAlertActive;
  final VoidCallback onToggleAlert;
  final ScrollController? scrollController;
  final bool isDesktop;
  final double speed;
  final BusLocationModel? liveBus;
  final void Function(String) onShowSnack;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (!isDesktop) ...[
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
        ],

        // LMT Go Header Bar: Route Crimson Pill + Plate + Live status + Price
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFC2185B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                routeNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              busPlate,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isBroadcasting
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isBroadcasting
                      ? const Color(0xFF81C784)
                      : const Color(0xFFFFB74D),
                ),
              ),
              child: Text(
                isBroadcasting ? '● Ongoing' : '● Scheduled',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isBroadcasting
                      ? const Color(0xFF1B5E20)
                      : Colors.orange.shade900,
                ),
              ),
            ),
            if (isBroadcasting && speed > 0) ...[
              const SizedBox(width: 6),
              Text(
                '${speed.toStringAsFixed(0)} km/h',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
            const Spacer(),
            Text(
              'LKR $fareLkr',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Hero Arrival & Delay Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      etaResult.countdownText.isNotEmpty
                          ? etaResult.countdownText
                          : 'Arriving in ${etaResult.countdownMinutes} min',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Destination: $effectiveDestination',
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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: etaResult.delayType == DelayType.delayed
                      ? const Color(0xFFFFECE0)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  etaResult.delayLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: etaResult.delayType == DelayType.delayed
                        ? const Color(0xFFD84315)
                        : const Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Quick Action Row: [Alert When Near] and [Request Assistance]
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onToggleAlert,
                icon: Icon(
                  isAlertActive
                      ? Icons.notifications_active_rounded
                      : Icons.add_alert_rounded,
                  size: 18,
                  color: isAlertActive ? Colors.white : const Color(0xFFE65100),
                ),
                label: Text(
                  isAlertActive ? 'Alert Active' : 'Alert When Near',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isAlertActive ? Colors.white : const Color(0xFFE65100),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAlertActive
                      ? const Color(0xFFE65100)
                      : const Color(0xFFFFF3E0),
                  elevation: isAlertActive ? 2 : 0,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFFFB74D)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BoardingAssistanceScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.accessible_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  'Assistance',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 1,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Stops Timeline (LMT Go style!)
        _EnhancedStopsTimelineCard(
          stopsTimeline: etaResult.stopsTimeline,
          targetStop: effectiveDestination,
        ),

        const SizedBox(height: 16),

        // Accessibility section
        _LiveAccessibilitySection(
          rampOperational: rampWorking,
          elevatorWorking: elevatorWorking,
          occupancyLevel: occupancyLevel,
        ),

        const SizedBox(height: 16),

        // Stop assistance section
        _AssistanceSection(
          destination: effectiveDestination,
          onRequest: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const BoardingAssistanceScreen(),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Emergency & reporting
        _EmergencyActions(
          onEmergency: () => onShowSnack('Emergency services contacted.'),
          onReport: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReportConditionScreen(
                  initialLocation: effectiveDestination,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
            title: const Text(
              'Detailed Vehicle Telemetry',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            subtitle: const Text(
              'Speed, GPS signals and raw trip data',
              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
            children: [
              _StatusCard(
                busName: busName,
                routeName: routeName,
                nextStop: liveBus?.nextStop ?? 'Approaching',
                passengerStop: effectiveDestination,
                isBroadcasting: isBroadcasting,
                isStale: isStale,
                speed: speed,
                liveBus: liveBus,
                arrivalEta: etaResult,
              ),
              const SizedBox(height: 16),
              _LiveStopTimelineCard(busId: busId),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Live Real-Time Interactive Map View
// ──────────────────────────────────────────────────────────────────────────────

class _LiveMapTrackingView extends StatefulWidget {
  const _LiveMapTrackingView({
    required this.busId,
    required this.busName,
    required this.liveBus,
    required this.origin,
    required this.destination,
    required this.route,
    required this.matchedBus,
    required this.etaResult,
    required this.isBroadcasting,
    required this.isStale,
    this.isFullScreen = false,
  });

  final String busId;
  final String busName;
  final BusLocationModel? liveBus;
  final String origin;
  final String destination;
  final RouteResultItem? route;
  final Bus? matchedBus;
  final BusArrivalEtaResult etaResult;
  final bool isBroadcasting;
  final bool isStale;
  final bool isFullScreen;

  @override
  State<_LiveMapTrackingView> createState() => _LiveMapTrackingViewState();
}

class _LiveMapTrackingViewState extends State<_LiveMapTrackingView> {
  late final MapController _mapController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng? _resolveStopCoordinates(String stopName) {
    if (stopName.trim().isEmpty) return null;
    final fromEta = EtaService.getStopCoordinates(stopName);
    if (fromEta != null) return fromEta;

    final q = stopName.trim().toLowerCase();
    for (final st in SeedData.colomboStations) {
      final sName = st.name.toLowerCase();
      if (sName == q || sName.contains(q) || q.contains(sName)) {
        return LatLng(st.lat, st.lng);
      }
    }
    return null;
  }

  /// Enriched stop record for full-route visualization.
  List<_RouteStopInfo> _buildRouteStops() {
    final List<String> stopNames = [];
    if (widget.matchedBus != null &&
        widget.matchedBus!.stops.isNotEmpty) {
      stopNames.addAll(widget.matchedBus!.stops);
    } else if (widget.route != null) {
      stopNames.add(widget.route!.origin);
      stopNames.addAll(widget.route!.intermediateStops);
      stopNames.add(widget.route!.destination);
    }

    final int currentIdx = widget.liveBus?.currentStopIndex ?? 0;
    final originQ = widget.origin.trim().toLowerCase();
    final destQ = widget.destination.trim().toLowerCase();

    final List<_RouteStopInfo> result = [];
    for (int i = 0; i < stopNames.length; i++) {
      final name = stopNames[i];
      final coord = _resolveStopCoordinates(name);
      if (coord == null) continue;

      // Determine display name from SeedData
      String displayName = name;
      for (final st in SeedData.colomboStations) {
        final sName = st.name.toLowerCase();
        final sId = st.id.toLowerCase();
        final q = name.trim().toLowerCase();
        if (sId == q || sName == q || sName.contains(q) || q.contains(sName)) {
          displayName = st.name
              .replaceAll(' Station', '')
              .replaceAll(' Bus Stand', '')
              .replaceAll(' Bus Stop', '')
              .replaceAll(' Stop', '')
              .replaceAll(' Central', '')
              .replaceAll(' Bus Complex', '')
              .replaceAll(' Highway Bus', '')
              .replaceAll(' Market', '')
              .replaceAll(' Junction', '')
              .replaceAll(' Terminal', '');
          break;
        }
      }

      // Determine progression status
      final nameQ = name.trim().toLowerCase();
      _StopStatus status;
      if (_fuzzyMatch(nameQ, originQ)) {
        status = _StopStatus.boarding;
      } else if (_fuzzyMatch(nameQ, destQ)) {
        status = _StopStatus.alighting;
      } else if (i < currentIdx) {
        status = _StopStatus.passed;
      } else if (i == currentIdx) {
        status = _StopStatus.current;
      } else {
        status = _StopStatus.upcoming;
      }

      result.add(_RouteStopInfo(
        name: displayName,
        fullName: name,
        coord: coord,
        index: i,
        status: status,
      ));
    }
    return result;
  }

  bool _fuzzyMatch(String a, String b) {
    if (a == b) return true;
    if (a.contains(b) || b.contains(a)) return true;
    // Check SeedData station IDs/names
    for (final st in SeedData.colomboStations) {
      final sName = st.name.toLowerCase();
      final sId = st.id.toLowerCase();
      if ((sId == a || sName.contains(a) || a.contains(sName)) &&
          (sId == b || sName.contains(b) || b.contains(sName))) {
        return true;
      }
    }
    return false;
  }

  List<LatLng> _buildRoutePolyline(
    LatLng busPos,
    LatLng passengerPos,
    LatLng? destPos,
  ) {
    final stops = _buildRouteStops();
    if (stops.length >= 2) {
      return stops.map((s) => s.coord).toList();
    }
    return [busPos, passengerPos, ?destPos];
  }

  String _formatDistance(LatLng busPos, LatLng passengerPos) {
    final meters = const Distance().distance(busPos, passengerPos);
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  void _fitJourney(LatLng busPos, LatLng passengerPos, LatLng? destPos) {
    final routeStops = _buildRouteStops();
    final pts = [
      busPos,
      passengerPos,
      ?destPos,
      ...routeStops.map((s) => s.coord),
    ];
    try {
      final bounds = LatLngBounds.fromPoints(pts);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(40),
        ),
      );
    } catch (_) {
      _mapController.move(passengerPos, 13.5);
    }
  }

  // ── Stop marker color helpers ──

  Color _stopLabelColor(_StopStatus status) {
    switch (status) {
      case _StopStatus.passed:
        return const Color(0xFFE0E0E0);
      case _StopStatus.current:
        return const Color(0xFF1565C0);
      case _StopStatus.boarding:
        return const Color(0xFFE65100);
      case _StopStatus.alighting:
        return const Color(0xFFC2185B);
      case _StopStatus.upcoming:
        return Colors.white.withValues(alpha: 0.95);
    }
  }

  Color _stopLabelTextColor(_StopStatus status) {
    switch (status) {
      case _StopStatus.passed:
        return const Color(0xFF757575);
      case _StopStatus.current:
        return Colors.white;
      case _StopStatus.boarding:
        return Colors.white;
      case _StopStatus.alighting:
        return Colors.white;
      case _StopStatus.upcoming:
        return const Color(0xFF424242);
    }
  }

  Color _stopDotColor(_StopStatus status) {
    switch (status) {
      case _StopStatus.passed:
        return const Color(0xFF66BB6A);
      case _StopStatus.current:
        return const Color(0xFF1E88E5);
      case _StopStatus.boarding:
        return const Color(0xFFFF9800);
      case _StopStatus.alighting:
        return const Color(0xFFE91E63);
      case _StopStatus.upcoming:
        return Colors.white;
    }
  }

  Color _stopDotBorderColor(_StopStatus status) {
    switch (status) {
      case _StopStatus.passed:
        return const Color(0xFF43A047);
      case _StopStatus.current:
        return Colors.white;
      case _StopStatus.boarding:
        return Colors.white;
      case _StopStatus.alighting:
        return Colors.white;
      case _StopStatus.upcoming:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Resolve positions
    LatLng? busPos;
    if (widget.liveBus != null &&
        widget.liveBus!.latitude != 0.0 &&
        widget.liveBus!.longitude != 0.0) {
      busPos = LatLng(widget.liveBus!.latitude, widget.liveBus!.longitude);
    } else if (widget.liveBus?.nextStop != null &&
        widget.liveBus!.nextStop.isNotEmpty) {
      busPos = _resolveStopCoordinates(widget.liveBus!.nextStop);
    }
    busPos ??= _resolveStopCoordinates(widget.origin) ??
        const LatLng(6.9360, 79.8527); // Pettah default

    final passengerPos = _resolveStopCoordinates(widget.origin) ??
        _resolveStopCoordinates('Colombo Fort') ??
        const LatLng(6.9333, 79.8500);

    final destPos = _resolveStopCoordinates(widget.destination);

    final routeStops = _buildRouteStops();
    final polylinePoints = _buildRoutePolyline(busPos, passengerPos, destPos);
    final distanceText = _formatDistance(busPos, passengerPos);

    // Split polyline into traveled and remaining segments for visual progression
    final int currentIdx = widget.liveBus?.currentStopIndex ?? 0;
    final List<LatLng> traveledPoints = [];
    final List<LatLng> remainingPoints = [];
    if (routeStops.length >= 2) {
      for (int i = 0; i < routeStops.length; i++) {
        if (i <= currentIdx) {
          traveledPoints.add(routeStops[i].coord);
        }
        if (i >= currentIdx) {
          remainingPoints.add(routeStops[i].coord);
        }
      }
    }

    final isLiveGps = widget.isBroadcasting && !widget.isStale;
    final delayText = widget.etaResult.delayLabel;
    final delayType = widget.etaResult.delayType;

    final Color delayBadgeColor;
    final Color delayBadgeTextColor;
    if (delayType == DelayType.delayed) {
      delayBadgeColor = const Color(0xFFFFECE0);
      delayBadgeTextColor = const Color(0xFFD84315);
    } else if (delayType == DelayType.early) {
      delayBadgeColor = const Color(0xFFE1F5FE);
      delayBadgeTextColor = const Color(0xFF0277BD);
    } else {
      delayBadgeColor = const Color(0xFFE8F5E9);
      delayBadgeTextColor = const Color(0xFF2E7D32);
    }

    final double mapHeight = widget.isFullScreen
        ? double.infinity
        : (_isExpanded ? 460.0 : 290.0);

    return Semantics(
      label:
          'Live interactive map showing bus ${widget.busName} heading toward ${widget.origin}',
      container: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: mapHeight,
        margin: widget.isFullScreen
            ? EdgeInsets.zero
            : const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: widget.isFullScreen
            ? const BoxDecoration()
            : BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onSurface.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
        clipBehavior: widget.isFullScreen ? Clip.none : Clip.antiAlias,
        child: Stack(
          children: [
            // ── OpenStreetMap Widget ──
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: passengerPos,
                initialZoom: 13.8,
                minZoom: 9.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.accesstransit.app',
                ),
                // ── Route Polyline: Traveled (dim) + Remaining (bright) ──
                PolylineLayer(
                  polylines: [
                    // Full route outer glow
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: 7.0,
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                    // Traveled segment (greyed out)
                    if (traveledPoints.length >= 2)
                      Polyline(
                        points: traveledPoints,
                        strokeWidth: 5.0,
                        color: const Color(0xFF9E9E9E).withValues(alpha: 0.6),
                        pattern: const StrokePattern.dotted(),
                      ),
                    // Remaining segment (bright primary)
                    if (remainingPoints.length >= 2)
                      Polyline(
                        points: remainingPoints,
                        strokeWidth: 5.0,
                        color: AppColors.primary,
                      ),
                    // Fallback: full route when no split data
                    if (traveledPoints.length < 2 && remainingPoints.length < 2)
                      Polyline(
                        points: polylinePoints,
                        strokeWidth: 4.5,
                        color: AppColors.primary,
                      ),
                  ],
                ),

                // ── All Route Stop Markers (labeled) ──
                MarkerLayer(
                  markers: [
                    // Route stop markers with labels and progression colors
                    for (final stop in routeStops)
                      if (stop.status != _StopStatus.boarding &&
                          stop.status != _StopStatus.alighting)
                        Marker(
                          point: stop.coord,
                          width: 90,
                          height: stop.status == _StopStatus.current ? 56 : 44,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Stop name label
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: _stopLabelColor(stop.status),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  stop.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _stopLabelTextColor(stop.status),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 1.5),
                              // Stop dot/circle
                              Container(
                                width: stop.status == _StopStatus.current
                                    ? 22
                                    : 16,
                                height: stop.status == _StopStatus.current
                                    ? 22
                                    : 16,
                                decoration: BoxDecoration(
                                  color: _stopDotColor(stop.status),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _stopDotBorderColor(stop.status),
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    if (stop.status == _StopStatus.current)
                                      BoxShadow(
                                        color: const Color(0xFF2196F3)
                                            .withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    const BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                child: stop.status == _StopStatus.passed
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 9,
                                        color: Colors.white,
                                      )
                                    : stop.status == _StopStatus.current
                                        ? const Icon(
                                            Icons.near_me_rounded,
                                            size: 12,
                                            color: Colors.white,
                                          )
                                        : null,
                              ),
                            ],
                          ),
                        ),

                    // Destination / Alighting Stop Marker
                    if (destPos != null)
                      Marker(
                        point: destPos,
                        width: 100,
                        height: 64,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC2185B),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.flag_rounded,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      widget.destination,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE91E63),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pink.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.flag_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Passenger's Boarding Stop Marker
                    Marker(
                      point: passengerPos,
                      width: 100,
                      height: 70,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE65100),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: const Text(
                              'You Board Here',
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.hail_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Live Bus Marker
                    Marker(
                      point: busPos,
                      width: 90,
                      height: 74,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isLiveGps
                                  ? const Color(0xFF1B5E20)
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: Text(
                              widget.liveBus?.routeNumber.isNotEmpty == true
                                  ? 'BUS ${widget.liveBus!.routeNumber}'
                                  : widget.busName,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isLiveGps
                                  ? const Color(0xFF00C853)
                                  : AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isLiveGps
                                          ? const Color(0xFF00C853)
                                          : AppColors.primary)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.directions_bus_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ── Top Floating Overlay: Live Status & Delay Pill ──
            if (!widget.isFullScreen)
              Positioned(
                top: 12,
                left: 12,
                right: 64, // Leaves space for control column
                child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isLiveGps
                            ? const Color(0xFF00C853)
                            : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                isLiveGps ? 'LIVE GPS' : 'TIMETABLE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: isLiveGps
                                      ? const Color(0xFF2E7D32)
                                      : Colors.orange.shade800,
                                ),
                              ),
                              const Text(' · ', style: TextStyle(color: Colors.grey)),
                              Text(
                                distanceText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            widget.etaResult.countdownText,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: delayBadgeColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            delayText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: delayBadgeTextColor,
                            ),
                          ),
                        ),
                        if (widget.etaResult.delayReason != null &&
                            widget.etaResult.delayReason!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFFFB74D),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 11,
                                  color: Color(0xFFD84315),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${widget.etaResult.delayReason} (+${widget.etaResult.addedDelayMinutes}m)',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD84315),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Floating Action Buttons (Right-side controls) ──
            Positioned(
              top: widget.isFullScreen ? 96 : 12,
              right: 12,
              child: Column(
                children: [
                  if (!widget.isFullScreen) ...[
                    _MapActionButton(
                      icon: _isExpanded
                          ? Icons.fullscreen_exit_rounded
                          : Icons.fullscreen_rounded,
                      tooltip: _isExpanded ? 'Collapse map' : 'Expand map',
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                  ],
                  _MapActionButton(
                    icon: Icons.crop_free_rounded,
                    tooltip: 'Fit journey bounds',
                    onTap: () => _fitJourney(busPos!, passengerPos, destPos),
                  ),
                  const SizedBox(height: 6),
                  _MapActionButton(
                    icon: Icons.directions_bus_rounded,
                    tooltip: 'Focus on bus',
                    onTap: () => _mapController.move(busPos!, 15.0),
                  ),
                  const SizedBox(height: 6),
                  _MapActionButton(
                    icon: Icons.person_pin_circle_rounded,
                    tooltip: 'Focus on my stop',
                    onTap: () => _mapController.move(passengerPos, 15.5),
                  ),
                  const SizedBox(height: 6),
                  _MapActionButton(
                    icon: Icons.add_rounded,
                    tooltip: 'Zoom in',
                    onTap: () {
                      final current = _mapController.camera.center;
                      final zoom = (_mapController.camera.zoom + 1.0)
                          .clamp(8.0, 18.0);
                      _mapController.move(current, zoom);
                    },
                  ),
                  const SizedBox(height: 6),
                  _MapActionButton(
                    icon: Icons.remove_rounded,
                    tooltip: 'Zoom out',
                    onTap: () {
                      final current = _mapController.camera.center;
                      final zoom = (_mapController.camera.zoom - 1.0)
                          .clamp(8.0, 18.0);
                      _mapController.move(current, zoom);
                    },
                  ),
                ],
              ),
            ),

            // ── Bottom Floating Pill: Telemetry info ──
            if (!widget.isFullScreen)
              Positioned(
                bottom: 10,
                left: 12,
                child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLiveGps
                          ? Icons.speed_rounded
                          : Icons.schedule_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isLiveGps
                          ? '${widget.liveBus?.speed.toStringAsFixed(0) ?? 0} km/h · Next: ${widget.liveBus?.nextStop ?? 'Approaching'}'
                          : 'Next Stop: ${widget.liveBus?.nextStop ?? widget.origin}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.95),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              icon,
              size: 20,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Status Card: Bus info, Live badge, Last updated, Next stop, Route name
// ──────────────────────────────────────────────────────────────────────────────






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
    this.arrivalEta,
  });

  final String busName;
  final String routeName;
  final String nextStop;
  final String passengerStop;
  final bool isBroadcasting;
  final bool isStale;
  final double speed;
  final BusLocationModel? liveBus;
  final BusArrivalEtaResult? arrivalEta;

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

          // ── Dynamic Bus ETA Banner Card ────────────────────────────────────
          _EtaBannerCard(
            etaResult: EtaService().calculateEta(
              liveBus: liveBus,
              stopName: passengerStop,
              isStale: isStale,
            ),
            targetStop: passengerStop,
            arrivalEta: arrivalEta,
          ),
          const SizedBox(height: 16),

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

class _EtaBannerCard extends StatelessWidget {
  const _EtaBannerCard({
    required this.etaResult,
    required this.targetStop,
    this.arrivalEta,
  });

  final EtaResult etaResult;
  final String targetStop;
  final BusArrivalEtaResult? arrivalEta;

  @override
  Widget build(BuildContext context) {
    if (arrivalEta != null) {
      final arrival = arrivalEta!;
      final Color badgeColor;
      final Color badgeTextColor;
      if (arrival.delayType == DelayType.delayed) {
        badgeColor = const Color(0xFFFFECE0);
        badgeTextColor = const Color(0xFFD84315);
      } else if (arrival.delayType == DelayType.early) {
        badgeColor = const Color(0xFFE1F5FE);
        badgeTextColor = const Color(0xFF0277BD);
      } else {
        badgeColor = const Color(0xFFE8F5E9);
        badgeTextColor = const Color(0xFF2E7D32);
      }

      return Semantics(
        liveRegion: true,
        label: '${arrival.countdownText}. ${arrival.delayLabel}',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryContainer.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      color: AppColors.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          arrival.countdownText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'at $targetStop',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      arrival.delayLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Scheduled: ${arrival.scheduledArrivalStr}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Expected: ${arrival.estimatedArrivalStr}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: arrival.delayType == DelayType.delayed
                            ? const Color(0xFFD84315)
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (arrival.delayReason != null &&
                  arrival.delayReason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFB74D)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Color(0xFFD84315),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Driver Notice: ${arrival.delayReason} (+${arrival.addedDelayMinutes} mins)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD84315),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    if (etaResult.isReliable) {
      final distanceKm = (etaResult.distanceMeters / 1000).toStringAsFixed(1);

      return Semantics(
        liveRegion: true,
        label: '${etaResult.displayText} to $targetStop',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primaryContainer.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      etaResult.displayText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Distance: $distanceKm km to $targetStop',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Unreliable / Stale fallback (Do not invent a fake ETA)
    return Semantics(
      liveRegion: true,
      label: etaResult.displayText,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.schedule_outlined,
              size: 22,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    etaResult.displayText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    etaResult.reason,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
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


class _LiveStopTimelineCard extends StatelessWidget {
  const _LiveStopTimelineCard({required this.busId});

  final String busId;

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TripModel?>(
      stream: TripService().watchActiveTripForBus(busId),
      builder: (context, snapshot) {
        final trip = snapshot.data;
        final isInProgress = trip != null && trip.isInProgress;

        if (!isInProgress) {
          return const SizedBox.shrink();
        }

        final stops = trip.stops;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: AppColors.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timeline_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Live Per-Stop Timeline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.shade600),
                      ),
                      child: Text(
                        'Live Run',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                      itemCount: stops.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final stopId = stops[index];
                        final stationName = stationsMap[stopId]?.name ??
                            stopId
                                .replaceAll('st_', '')
                                .replaceAll('_', ' ')
                                .toUpperCase();

                        final isConfirmedCurrent =
                            index == trip.currentStopIndex;
                        final isPassed = index < trip.currentStopIndex;
                        final timing = trip.stopTimes[stopId];

                        String subtext = '';
                        if (timing != null) {
                          if (isPassed && timing.actualArrival != null) {
                            subtext =
                                'Reached at ${_formatTime(timing.actualArrival!)}';
                          } else if (isConfirmedCurrent) {
                            final timeStr = timing.actualArrival != null
                                ? _formatTime(timing.actualArrival!)
                                : _formatTime(timing.estimatedArrival);
                            subtext = 'Bus is here now (Confirmed $timeStr)';
                          } else {
                            final diffMins = timing.estimatedArrival
                                .difference(DateTime.now())
                                .inMinutes
                                .clamp(1, 999);
                            subtext =
                                'Est. ${_formatTime(timing.estimatedArrival)} (in about $diffMins min)';
                          }
                        }

                        return Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
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
                                size: 10,
                                color: isConfirmedCurrent || isPassed
                                    ? Colors.white
                                    : AppColors.outline,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stationName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isConfirmedCurrent
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    subtext,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isConfirmedCurrent
                                          ? AppColors.primary
                                          : AppColors.onSurfaceVariant,
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
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Route Stop Progression Data
// ──────────────────────────────────────────────────────────────────────────────

/// Progression status of a stop along the bus route.
enum _StopStatus {
  /// Stop the passenger boards at.
  boarding,

  /// Stop the passenger alights at.
  alighting,

  /// Bus has already passed this stop.
  passed,

  /// Bus is currently at or approaching this stop.
  current,

  /// Bus has not yet reached this stop.
  upcoming,
}

/// Enriched data record for a single stop along the full route.
class _RouteStopInfo {
  const _RouteStopInfo({
    required this.name,
    required this.fullName,
    required this.coord,
    required this.index,
    required this.status,
  });

  /// Short display name (cleaned from SeedData).
  final String name;

  /// Raw stop identifier / full station name.
  final String fullName;

  /// Geographic coordinates of this stop.
  final LatLng coord;

  /// Index position in the route's stop list.
  final int index;

  /// Progression status relative to bus position and passenger journey.
  final _StopStatus status;
}
