import 'dart:async';

import '../../services/fare_catalogue.dart';
import '../../services/eta_evaluation_store.dart';
import 'eta_diagnostics_screen.dart';
import 'segment_reports_screen.dart';
import '../../logic/route_geometry.dart';
import '../../services/route_geometry_service.dart';
import '../../widgets/route_progress_eta_text.dart';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_utils.dart';
import '../../logic/bus_details_state.dart';
import '../../logic/transit_time.dart';
import '../../services/transit_search_backend.dart';
import '../../l10n/localization_context.dart';
import '../../logic/status_logic.dart';
import '../../models/assistance_target.dart';
import '../../models/bus.dart';
import '../../models/bus_location_model.dart';
import '../../models/journey_model.dart';
import '../../models/report.dart';
import '../../models/service_run.dart';
import '../../models/station.dart';
import '../../models/trip_model.dart';
import '../../services/accessibility_preferences_service.dart';
import '../../services/bus_details_repository.dart';
import '../../services/journey_service.dart';
import '../../widgets/accessibility_evidence_card.dart';
import '../../widgets/bus_ramp_observation.dart';
import '../../widgets/evidence_refresh.dart';
import '../../widgets/fare_estimate_text.dart';
import '../../widgets/published_timetable_notice.dart';
import '../../widgets/save_trip_control.dart';
import '../../widgets/selected_segment_map.dart';
import '../community/report_details_screen.dart';
import 'boarding_assistance_screen.dart';
import '../../services/moderation_mode.dart';
import 'report_condition_screen.dart';
import 'route_results_screen.dart';

/// Passenger destination shared by search selection and saved-trip reopening.
class BusDetailsScreen extends StatefulWidget {
  const BusDetailsScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.route,
    this.bus,
    this.statusResult,
    this.savedJourney,
    this.repository,
    this.journeyService,
    this.searchClock,
    this.fareFeed,
    this.geometryFeed,
    this.evaluationStore,
  });
  final String origin, destination;
  final RouteResultItem route;
  final Bus? bus;
  final BusStatusResult? statusResult;
  final JourneyModel? savedJourney;
  final BusDetailsRepository? repository;
  final JourneyService? journeyService;
  final SearchTimeAnchor? searchClock;
  final Stream<List<FarePublication>> Function(String)? fareFeed;
  final Stream<ReviewedRouteGeometry?> Function(String)? geometryFeed;
  final EtaEvaluationStore? evaluationStore;
  @override
  State<BusDetailsScreen> createState() => _BusDetailsScreenState();
}

class _BusDetailsScreenState extends State<BusDetailsScreen>
    with WidgetsBindingObserver {
  late final repository = widget.repository ?? TransitSearchBackend();
  late final evaluation = widget.evaluationStore ?? EtaEvaluationStore.instance;
  late final clockBackend = repository is TransitSearchBackend
      ? repository as TransitSearchBackend
      : TransitSearchBackend();
  SearchTimeAnchor? clock;
  Timer? clockExpiry;
  int clockRevision = 0;
  late final journeys = widget.journeyService ?? JourneyService();
  late final owner = journeys.signedInPassenger;
  late Stream<Bus?> buses;
  late Stream<List<Report>> reports;
  late Future<List<Station>> stations;
  late Stream<ServiceRun?> runs;
  Stream<TripModel?>? tripUpdates;
  late Stream<BusLocationModel?> locations;
  bool resolved = false;
  String? pinnedRun;
  StreamSubscription<List<FarePublication>>? fareSubscription;
  List<FarePublication> fareValues = const [];
  StreamSubscription<ReviewedRouteGeometry?>? geometrySubscription;
  ReviewedRouteGeometry? geometry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    clock = widget.searchClock;
    if (clock?.isFresh == true) {
      clockExpiry = Timer(clock!.remaining, syncClock);
    } else {
      syncClock();
    }
    pinnedRun = widget.route.serviceRunId;
    refresh();
    evaluation.open(AccessibilityPreferencesService.instance.userId);
    final routeId = widget.bus?.routeId ?? widget.route.rawBus?.routeId;
    if (routeId != null && routeId.isNotEmpty) {
      geometrySubscription =
          (widget.geometryFeed ?? RouteGeometryService().watch)(routeId).listen(
            (v) {
              if (mounted) setState(() => geometry = v);
            },
            onError: (_) {
              if (mounted) setState(() => geometry = null);
            },
          );
    }
    fareSubscription =
        (widget.fareFeed ?? FareCatalogue().watchBus)(widget.route.busId)
            .listen(
              (v) {
                if (mounted) setState(() => fareValues = v);
              },
              onError: (_) {
                if (mounted) setState(() => fareValues = const []);
              },
            );
    AccessibilityPreferencesService.instance.addListener(accountChanged);
  }

  Future<void> syncClock() async {
    final revision = ++clockRevision;
    clockExpiry?.cancel();
    if (mounted) setState(() => clock = null);
    try {
      clockBackend.invalidateTime();
      final receipt = await clockBackend.synchronizeTime();
      if (!mounted || revision != clockRevision) return;
      setState(() => clock = receipt);
      clockExpiry = Timer(receipt.remaining, syncClock);
    } catch (_) {
      /* Live position remains unavailable until time is verified. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) syncClock();
  }

  void accountChanged() {
    evaluation.open(AccessibilityPreferencesService.instance.userId);
    if (mounted) setState(() {});
  }

  void refresh() {
    tripUpdates = null;
    buses = repository.bus(widget.route.busId);
    reports = repository.reports(
      busId: widget.route.busId,
      stopIds: BusDetailsState.segment(widget.route),
    );
    stations = repository.stations();
    locations = repository.location(widget.route.busId);
    // Legacy bookmarks have no authoritative run identity: retain static details.
    runs = widget.savedJourney != null && pinnedRun == null
        ? Stream.value(null)
        : repository.runs(widget.route.busId).map((list) {
            if (!resolved) {
              final candidates = list
                  .where((r) => BusDetailsState.matchesRun(r, widget.route))
                  .toList();
              if (candidates.length > 1) {
                throw StateError(
                  'Departure identity is ambiguous. Refresh the selection.',
                );
              }
              pinnedRun = candidates.singleOrNull?.id ?? pinnedRun;
              resolved = true;
            }
            final matching = list
                .where(
                  (r) =>
                      r.id == pinnedRun &&
                      BusDetailsState.matchesRun(r, widget.route),
                )
                .singleOrNull;
            if (matching != null && tripUpdates == null) {
              tripUpdates = repository.trip(matching.id);
            }
            return matching;
          });
  }

  @override
  void dispose() {
    fareSubscription?.cancel();
    geometrySubscription?.cancel();
    clockRevision++;
    clockExpiry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    AccessibilityPreferencesService.instance.removeListener(accountChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (journeys.signedInPassenger != owner) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.busDetails)),
        body: const Center(child: Text('Account changed. Return to Search.')),
      );
    }
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        title: Text(context.l10n.busDetails),
        actions: [
          if (evaluation.available)
            IconButton(
              tooltip: context.l10n.etaDiagnostics,
              icon: const Icon(Icons.query_stats),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EtaDiagnosticsScreen(store: evaluation),
                ),
              ),
            ),
        ],
        backgroundColor: context.surfaceColor,
      ),
      body: StreamBuilder<Bus?>(
        stream: buses,
        builder: (context, busSnapshot) {
          final fareBus = busSnapshot.data ?? widget.bus ?? widget.route.rawBus;
          final selected = widget.route;
          final currentFare =
              fareBus == null || selected.nextDepartureDateTime == null
              ? null
              : FarePublication.quote(
                  fareValues,
                  fareBus,
                  selected.fromStationId ?? '',
                  selected.toStationId ?? '',
                  selected.nextDepartureDateTime!,
                );
          final bus = busSnapshot.connectionState == ConnectionState.waiting
              ? widget.bus ?? widget.route.rawBus
              : busSnapshot.data;
          if (bus == null) {
            return Center(
              child: TextButton(
                onPressed: () => setState(refresh),
                child: const Text('Service unavailable. Retry'),
              ),
            );
          }
          return FutureBuilder<List<Station>>(
            future: stations,
            builder: (context, stationSnapshot) {
              final stops = {
                ...widget.route.journeyStations,
                for (final s in stationSnapshot.data ?? <Station>[]) s.id: s,
              };
              return StreamBuilder<ServiceRun?>(
                stream: runs,
                builder: (context, runSnapshot) {
                  final run = runSnapshot.hasError ? null : runSnapshot.data;
                  return StreamBuilder<TripModel?>(
                    stream: tripUpdates,
                    builder: (context, tripSnapshot) {
                      final trip = tripSnapshot.hasError
                          ? null
                          : tripSnapshot.data;
                      return StreamBuilder<BusLocationModel?>(
                        stream: locations,
                        builder: (context, gpsSnapshot) {
                          return StreamBuilder<List<Report>>(
                            stream: reports,
                            builder: (context, reportSnapshot) {
                              final observations = reportSnapshot.hasError
                                  ? <Report>[]
                                  : reportSnapshot.data ?? [];
                              return EvidenceRefresh(
                                now: () => clock?.now ?? DateTime.now().toUtc(),
                                reports: observations,
                                buses: [bus],
                                boundaries: [
                                  if (gpsSnapshot.data?.timestamp != null)
                                    gpsSnapshot.data!.timestamp!.add(
                                      const Duration(seconds: 30),
                                    ),
                                ],
                                builder: (context, now) {
                                  final gps = BusDetailsState.currentLocation(
                                    selection: widget.route,
                                    run: run,
                                    trip: trip,
                                    location:
                                        clock?.isFresh != true ||
                                            gpsSnapshot.hasError ||
                                            bus.driverId != trip?.driverId
                                        ? null
                                        : gpsSnapshot.data,
                                    now: now,
                                  );
                                  final relevant =
                                      BusDetailsState.relevantReports(
                                        observations,
                                        widget.route,
                                        now,
                                      );
                                  final road =
                                      geometry?.routeId == bus.routeId &&
                                          listEquals(geometry?.stops, bus.stops)
                                      ? geometry
                                      : null;
                                  final estimate =
                                      road == null ||
                                          run == null ||
                                          trip == null ||
                                          gps == null
                                      ? null
                                      : RouteProgressEta.estimate(
                                          geometry: road,
                                          run: run,
                                          trip: trip,
                                          gps: gps,
                                          target:
                                              widget.route.toStationId ?? '',
                                          now: now,
                                        );
                                  final segment = BusDetailsState.segment(
                                    // Diagnostic capture never changes operational selection or ETA.
                                    widget.route,
                                  );
                                  if (clock?.isFresh == true &&
                                      run != null &&
                                      trip != null) {
                                    evaluation.capture(
                                      uid: AccessibilityPreferencesService
                                          .instance
                                          .userId,
                                      bus: bus,
                                      run: run,
                                      trip: trip,
                                      now: now,
                                      gps: gps,
                                      geometry: road,
                                    );
                                  }
                                  final departure =
                                      widget.route.nextDepartureDateTime == null
                                      ? null
                                      : TransitTime.civil(
                                          widget.route.nextDepartureDateTime!,
                                        );
                                  final arrival = departure?.add(
                                    Duration(
                                      minutes: widget.route.durationMinutes,
                                    ),
                                  );
                                  final hasStarted =
                                      run != null &&
                                      const [
                                        'boarding',
                                        'in_progress',
                                      ].contains(run.status);
                                  final availability = runSnapshot.hasError
                                      ? 'Run status unavailable'
                                      : run == null
                                      ? 'Scheduled · run not verified'
                                      : run.status == 'completed'
                                      ? 'Completed'
                                      : run.status == 'cancelled'
                                      ? 'Cancelled'
                                      : hasStarted
                                      ? (gps == null
                                            ? 'Location unavailable or stale'
                                            : 'LIVE GPS')
                                      : 'Scheduled';
                                  return ListView(
                                    padding: const EdgeInsets.all(16),
                                    children: [
                                      Center(
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 768,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _card(
                                                context,
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      widget.route.title,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleLarge,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(availability),
                                                    if (estimate != null)
                                                      RouteProgressEtaText(
                                                        estimate: estimate,
                                                        target:
                                                            widget.destination,
                                                      ),
                                                    PublishedTimetableNotice(
                                                      bus: bus,
                                                    ),
                                                    Text(
                                                      '${widget.origin} → ${widget.destination}',
                                                    ),
                                                    if (departure != null)
                                                      Text(
                                                        'Scheduled boarding: ${TimeUtils.formatDateString(departure, clock: TransitTime.civil(now))} · ${TimeUtils.formatTimeString(departure)}',
                                                      ),
                                                    if (arrival != null)
                                                      Text(
                                                        'Scheduled arrival: ${TimeUtils.formatDateString(arrival, clock: TransitTime.civil(now))} · ${TimeUtils.formatTimeString(arrival)}',
                                                      ),
                                                    Text(
                                                      '${widget.route.durationMinutes} min · selected segment',
                                                    ),
                                                    Text(
                                                      [
                                                        if (widget
                                                            .route
                                                            .wheelchairAccessRequired)
                                                          'Wheelchair access',
                                                        if (widget
                                                            .route
                                                            .stepFreeOnly)
                                                          'Step-free',
                                                      ].join(' · '),
                                                    ),
                                                    if (widget.savedJourney !=
                                                        null)
                                                      const Text(
                                                        'Saved selection · times and needs are preserved; review current conditions.',
                                                      ),
                                                    if (widget.savedJourney !=
                                                            null &&
                                                        (widget
                                                                    .route
                                                                    .wheelchairAccessRequired !=
                                                                AccessibilityPreferencesService
                                                                    .instance
                                                                    .isWheelchairOnly ||
                                                            widget
                                                                    .route
                                                                    .stepFreeOnly !=
                                                                AccessibilityPreferencesService
                                                                    .instance
                                                                    .isStepFree))
                                                      const Text(
                                                        'Your current accessibility defaults differ from this saved selection.',
                                                      ),
                                                    if (busSnapshot.hasError)
                                                      const Text(
                                                        'Catalogue updates unavailable.',
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              SelectedSegmentMap(
                                                roadPath:
                                                    road?.segment(
                                                      widget
                                                              .route
                                                              .fromStationId ??
                                                          '',
                                                      widget
                                                              .route
                                                              .toStationId ??
                                                          '',
                                                    ) ??
                                                    const [],
                                                stations: [
                                                  for (final id in segment)
                                                    if (stops[id] != null)
                                                      stops[id]!,
                                                ],
                                                location: gps,
                                              ),
                                              _card(
                                                context,
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Stops on your journey',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium,
                                                    ),
                                                    for (
                                                      var i = 0;
                                                      i < segment.length;
                                                      i++
                                                    )
                                                      ListTile(
                                                        contentPadding:
                                                            EdgeInsets.zero,
                                                        leading: Icon(
                                                          i == 0
                                                              ? Icons
                                                                    .trip_origin
                                                              : i ==
                                                                    segment.length -
                                                                        1
                                                              ? Icons
                                                                    .location_on
                                                              : Icons
                                                                    .circle_outlined,
                                                          color:
                                                              AppColors.primary,
                                                        ),
                                                        title: Text(
                                                          stops[segment[i]]
                                                                  ?.name ??
                                                              segment[i],
                                                        ),
                                                        subtitle: Text(
                                                          i == 0
                                                              ? 'Board here · ${widget.route.departureTimeStr}'
                                                              : i ==
                                                                    segment.length -
                                                                        1
                                                              ? 'Alight here · ${widget.route.arrivalTimeStr}'
                                                              : run?.stopTimes[segment[i]] !=
                                                                    null
                                                              ? 'Scheduled ${TimeUtils.formatTimeString(TransitTime.civil(run!.stopTimes[segment[i]]!))}'
                                                              : 'Intermediate stop · time unavailable',
                                                        ),
                                                      ),
                                                    if (gps != null &&
                                                        trip != null &&
                                                        trip.actualDepartureTime !=
                                                            null &&
                                                        trip.currentStopIndex >=
                                                            0 &&
                                                        trip.currentStopIndex +
                                                                1 <
                                                            trip.stops.length)
                                                      Text(
                                                        'Next itinerary stop: ${stops[trip.stops[trip.currentStopIndex + 1]]?.name ?? trip.stops[trip.currentStopIndex + 1]}',
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              _card(
                                                context,
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    FareEstimateText(
                                                      quote: currentFare,
                                                      amount: widget
                                                          .route
                                                          .estimatedPriceLkr,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleLarge,
                                                    ),
                                                    FareDisclosureText(
                                                      quote: currentFare,
                                                    ),
                                                    if (widget
                                                                .route
                                                                .fareQuote !=
                                                            null &&
                                                        (currentFare == null ||
                                                            widget
                                                                    .route
                                                                    .fareQuote!
                                                                    .tariffId !=
                                                                currentFare
                                                                    .tariffId ||
                                                            widget
                                                                    .route
                                                                    .fareQuote!
                                                                    .tariffVersion !=
                                                                currentFare
                                                                    .tariffVersion ||
                                                            widget
                                                                    .route
                                                                    .fareQuote!
                                                                    .mappingVersion !=
                                                                currentFare
                                                                    .mappingVersion ||
                                                            widget
                                                                    .route
                                                                    .fareQuote!
                                                                    .amountMinor !=
                                                                currentFare
                                                                    .amountMinor))
                                                      Text(
                                                        context
                                                            .l10n
                                                            .fareChanged,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              _card(
                                                context,
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    BusRampObservation(
                                                      bus: bus,
                                                      currentTime: now,
                                                    ),
                                                    ExpansionTile(
                                                      tilePadding:
                                                          EdgeInsets.zero,
                                                      title: const Text(
                                                        'Accessibility evidence',
                                                      ),
                                                      children: [
                                                        AccessibilityEvidenceCard(
                                                          reports: observations,
                                                          currentTime: now,
                                                          busId: bus.id,
                                                          origin:
                                                              widget
                                                                  .route
                                                                  .fromStationId ??
                                                              '',
                                                          destination:
                                                              widget
                                                                  .route
                                                                  .toStationId ??
                                                              '',
                                                          strictStopIds: true,
                                                        ),
                                                        Text(
                                                          context
                                                              .l10n
                                                              .segmentReportsPreview,
                                                        ),
                                                      ],
                                                    ),
                                                    OutlinedButton.icon(
                                                      onPressed:
                                                          bus.isPublishedTimetable ||
                                                              (ModerationMode
                                                                      .enabled &&
                                                                  (pinnedRun ==
                                                                          null ||
                                                                      run ==
                                                                          null ||
                                                                      !const [
                                                                        'scheduled',
                                                                        'boarding',
                                                                        'in_progress',
                                                                      ].contains(
                                                                        run.status,
                                                                      ) ||
                                                                      bus.driverId ==
                                                                          null))
                                                          ? null
                                                          : () => openBoardingAssistance(
                                                              context,
                                                              target: AssistanceTarget.resolve(
                                                                serviceRunId:
                                                                    pinnedRun,
                                                                boardingStationId:
                                                                    widget
                                                                        .route
                                                                        .fromStationId,
                                                                alightingStationId:
                                                                    widget
                                                                        .route
                                                                        .toStationId,
                                                                busId: bus.id,
                                                                bus: bus,
                                                                stopName: widget
                                                                    .origin,
                                                                stationId: widget
                                                                    .route
                                                                    .fromStationId,
                                                                stations: stops,
                                                              ),
                                                            ),
                                                      icon: const Icon(
                                                        Icons.accessible,
                                                      ),
                                                      label: Text(
                                                        bus.isPublishedTimetable ||
                                                                (ModerationMode
                                                                        .enabled &&
                                                                    (pinnedRun ==
                                                                            null ||
                                                                        run ==
                                                                            null ||
                                                                        !const [
                                                                          'scheduled',
                                                                          'boarding',
                                                                          'in_progress',
                                                                        ].contains(
                                                                          run.status,
                                                                        ) ||
                                                                        bus.driverId ==
                                                                            null))
                                                            ? 'Driver assistance unavailable'
                                                            : context
                                                                  .l10n
                                                                  .requestBoardingAssistance,
                                                      ),
                                                    ),
                                                    TextButton.icon(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            context,
                                                          ).push(
                                                            MaterialPageRoute(
                                                              builder: (_) =>
                                                                  ReportConditionScreen(
                                                                    targetType:
                                                                        'bus',
                                                                    targetId:
                                                                        bus.id,
                                                                    initialLocation:
                                                                        bus.displayBusNo,
                                                                  ),
                                                            ),
                                                          ),
                                                      icon: const Icon(
                                                        Icons.edit_note,
                                                      ),
                                                      label: const Text(
                                                        'Report a condition',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              _card(
                                                context,
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    Text(
                                                      context
                                                          .l10n
                                                          .communityReports,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium,
                                                    ),
                                                    Text(
                                                      context
                                                          .l10n
                                                          .segmentReportsPreview,
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            context,
                                                          ).push(
                                                            MaterialPageRoute(
                                                              builder: (_) => SegmentReportsScreen(
                                                                busId: bus.id,
                                                                busName: bus
                                                                    .displayBusNo,
                                                                stops: {
                                                                  for (final id
                                                                      in segment)
                                                                    id:
                                                                        stops[id]
                                                                            ?.name ??
                                                                        id,
                                                                },
                                                                repository:
                                                                    repository,
                                                              ),
                                                            ),
                                                          ),
                                                      child: Text(
                                                        context
                                                            .l10n
                                                            .segmentReportsViewAll,
                                                      ),
                                                    ),
                                                    if (reportSnapshot.hasError)
                                                      TextButton(
                                                        onPressed: () => setState(
                                                          () => reports =
                                                              repository.reports(
                                                                busId: widget
                                                                    .route
                                                                    .busId,
                                                                stopIds:
                                                                    BusDetailsState.segment(
                                                                      widget
                                                                          .route,
                                                                    ),
                                                              ),
                                                        ),
                                                        child: Text(
                                                          context
                                                              .l10n
                                                              .segmentReportsUnavailable,
                                                        ),
                                                      )
                                                    else if (reportSnapshot
                                                            .connectionState ==
                                                        ConnectionState.waiting)
                                                      const Text(
                                                        'Loading reports…',
                                                      )
                                                    else if (relevant.isEmpty)
                                                      Text(
                                                        context
                                                            .l10n
                                                            .segmentReportsEmptyPreview,
                                                      )
                                                    else ...[
                                                      for (final report
                                                          in relevant.take(3))
                                                        ListTile(
                                                          contentPadding:
                                                              EdgeInsets.zero,
                                                          title: Text(
                                                            report.problemType,
                                                          ),
                                                          subtitle: Text(
                                                            '${report.targetType == 'bus' ? bus.displayBusNo : stops[report.targetId]?.name ?? report.targetName}\n${StatusLogic.freshnessLabel(report, currentTime: now)} · ${report.createdAt == null ? 'Time unknown' : TimeUtils.formatRelativeTime(report.createdAt, clock: now)}',
                                                          ),
                                                          trailing: const Icon(
                                                            Icons.chevron_right,
                                                          ),
                                                          onTap: () => Navigator.of(context).push(
                                                            MaterialPageRoute(
                                                              builder: (_) =>
                                                                  ReportDetailsScreen(
                                                                    report:
                                                                        report,
                                                                    targetTitle:
                                                                        report
                                                                            .targetName,
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                    if (clock?.isFresh !=
                                                            true &&
                                                        pinnedRun != null)
                                                      TextButton(
                                                        onPressed: syncClock,
                                                        child: Text(
                                                          context
                                                              .l10n
                                                              .retrySearchTime,
                                                        ),
                                                      ),
                                                    if (runSnapshot.hasError ||
                                                        reportSnapshot.hasError)
                                                      TextButton(
                                                        onPressed: () =>
                                                            setState(refresh),
                                                        child: const Text(
                                                          'Retry updates',
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              if (runSnapshot.connectionState !=
                                                      ConnectionState.waiting &&
                                                  !runSnapshot.hasError)
                                                SaveTripControl(
                                                  fareValidated: true,
                                                  fareQuote: currentFare,
                                                  key: ValueKey(
                                                    pinnedRun ?? 'timetable',
                                                  ),
                                                  route: widget.route,
                                                  runId: pinnedRun,
                                                  service: journeys,
                                                  existing: widget.savedJourney,
                                                )
                                              else
                                                const Text(
                                                  'Connect to verify this departure before saving.',
                                                ),
                                              const SizedBox(height: 24),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _card(BuildContext context, Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: context.isHighContrast ? Colors.black : AppColors.outlineVariant,
        width: context.isHighContrast ? 2 : 1,
      ),
    ),
    child: Material(type: MaterialType.transparency, child: child),
  );
}
