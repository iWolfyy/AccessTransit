import 'package:flutter/foundation.dart';

import 'dart:async';

import '../../logic/tariff_fare.dart';
import '../../services/fare_catalogue.dart';
import '../../logic/route_geometry.dart';
import '../../services/route_geometry_service.dart';
import '../../widgets/route_progress_eta_text.dart';

import '../../widgets/fare_estimate_text.dart';
import '../../widgets/evidence_refresh.dart';
import '../../services/transit_catalogue.dart';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_utils.dart';

import '../../logic/bus_matcher.dart';
import '../../logic/dated_boarding_matcher.dart';
import '../../logic/transit_time.dart';
import '../../services/dated_search_state.dart';
import '../../services/transit_search_backend.dart';
import '../../logic/search_session.dart';
import '../../l10n/localization_context.dart';
import '../../logic/status_logic.dart';
import '../../models/bus.dart';
import '../../models/bus_route.dart';
import '../../models/report.dart';
import '../../models/station.dart';
import '../../services/accessibility_preferences_service.dart';
import '../../services/firestore_service.dart';
import 'bus_details_screen.dart';

/// Route result item used for passenger route selection.
/// Timetable planning data; live GPS is evaluated separately in route details.
class RouteResultItem {
  const RouteResultItem({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.etaLabel,
    required this.transfers,
    required this.crowdLevel,
    required this.accessibilityStatus,
    required this.accessibilityLabel,
    required this.safetyLabel,
    required this.summary,
    this.busId = 'bus_01',
    this.busNo,
    this.routeNo,
    this.routeName,
    this.scheduledDeparture,
    this.departureTimeStr = '08:30 AM',
    this.arrivalTimeStr = '09:05 AM',
    this.estimatedPriceLkr = 0,
    this.timetableStatusLabel = 'Scheduled',
    this.usesEstimatedTimes = false,
    this.origin = 'Colombo',
    this.destination = 'Kandy',
    this.intermediateStops = const [],
    this.recommended = false,
    this.rawBus,
    this.statusResult,
    this.nextDepartureDateTime,
    this.matchesAccessibleFilter = false,
    this.fromStationId,
    this.toStationId,
    this.wheelchairAccessRequired = false,
    this.stepFreeOnly = false,
    this.journeyStations = const {},
    this.selectedDate,
    this.selectedTimeMinutes,
    this.serviceRunId,
    this.boardingEstimateAt,
    this.boardingEstimateSource,
    this.progressEstimate,
    this.fareQuote,
  });

  final String id;
  final String title;
  final int durationMinutes;
  final String etaLabel;
  final int transfers;
  final String crowdLevel;
  final AccessibilityStatus accessibilityStatus;
  final String accessibilityLabel;
  final String safetyLabel;
  final String summary;
  final String busId;
  final String? busNo;
  final String? routeNo;
  final String? routeName;
  final String? scheduledDeparture;
  final String departureTimeStr;
  final String arrivalTimeStr;
  final int estimatedPriceLkr;
  final TariffFareQuote? fareQuote;
  final String timetableStatusLabel;
  final bool usesEstimatedTimes;
  final String origin;
  final String destination;
  final List<String> intermediateStops;
  final bool recommended;
  final Bus? rawBus;
  final BusStatusResult? statusResult;
  final DateTime? nextDepartureDateTime;
  final bool matchesAccessibleFilter;
  final String? fromStationId;
  final String? toStationId;
  final bool wheelchairAccessRequired;
  final bool stepFreeOnly;
  final Map<String, Station> journeyStations;
  final DateTime? selectedDate;
  final int? selectedTimeMinutes;
  final String? serviceRunId;
  final DateTime? boardingEstimateAt;
  final String? boardingEstimateSource;
  final RouteProgressEstimate? progressEstimate;
}

enum AccessibilityStatus { accessible, partial, notAccessible, unknown }

enum RouteFilterTab { all, accessible, fastest }

/// Route Results screen — LMT Go styled available bus cards with accessibility-first enhancements.
class RouteResultsScreen extends StatefulWidget {
  const RouteResultsScreen({
    super.key,
    this.fromStationId = 'st_fort',
    this.toStationId = 'st_kottawa',
    this.origin = 'Colombo Fort Station',
    this.destination = 'Kottawa Highway Bus Station',
    this.selectedDate,
    this.selectedTime,
    this.wheelchairAccessRequired,
    this.stepFreeOnly,
    this.minimizeWalking,
    this.needsDraft,
    this.searchBackend,
    this.fareFeed,
    this.geometryFeed,
  });

  final String fromStationId;
  final String toStationId;
  final String origin;
  final String destination;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final bool? wheelchairAccessRequired;
  final bool? stepFreeOnly;
  final bool? minimizeWalking;
  final SearchNeedsDraft? needsDraft;
  final TransitSearchBackend? searchBackend;
  final Stream<List<FarePublication>> Function(String)? fareFeed;
  final Stream<ReviewedRouteGeometry?> Function(String)? geometryFeed;

  @override
  State<RouteResultsScreen> createState() => _RouteResultsScreenState();
}

class _RouteResultsScreenState extends State<RouteResultsScreen>
    with WidgetsBindingObserver {
  static const double _desktopBreakpoint = 768;
  final FirestoreService _firestoreService = FirestoreService();

  List<Bus> _allBuses = [];
  Map<String, BusRoute> _routesMap = {};
  Map<String, Station> _stationsMap = {};
  bool _isLoadingData = true;
  late RouteFilterTab _selectedFilterTab;
  late bool _isWheelchair;
  late bool _isStepFree;
  late final SearchNeedsDraft _needs;
  late final int _accountRevision;
  late DatedSearchState _search;
  bool _searchDisposed = false;
  bool _scopePending = false;
  List<String> _scope = const [];
  final _fareSubscriptions =
      <String, StreamSubscription<List<FarePublication>>>{};
  final _fares = <String, List<FarePublication>>{};
  final _geometrySubscriptions =
      <String, StreamSubscription<ReviewedRouteGeometry?>>{};
  final _geometries = <String, ReviewedRouteGeometry>{};
  void _watchFares(List<String> ids) {
    for (final id in _fareSubscriptions.keys.toList()) {
      if (!ids.contains(id)) {
        _fareSubscriptions.remove(id)?.cancel();
        _fares.remove(id);
      }
    }
    for (final id in ids) {
      if (!_geometrySubscriptions.containsKey(id)) {
        final route = _allBuses.where((b) => b.id == id).firstOrNull?.routeId;
        if (route != null && route.isNotEmpty) {
          _geometrySubscriptions[id] =
              (widget.geometryFeed ?? RouteGeometryService().watch)(route)
                  .listen(
                    (g) {
                      if (!mounted || _searchDisposed) return;
                      setState(() {
                        if (g == null) {
                          _geometries.remove(id);
                        } else {
                          _geometries[id] = g;
                        }
                      });
                    },
                    onError: (_) {
                      if (mounted && !_searchDisposed) {
                        setState(() => _geometries.remove(id));
                      }
                    },
                  );
        }
      }
      if (_fareSubscriptions.containsKey(id)) continue;
      _fareSubscriptions[id] = (widget.fareFeed ?? FareCatalogue().watchBus)(id)
          .listen(
            (values) {
              if (mounted && !_searchDisposed) {
                setState(() => _fares[id] = values);
              }
            },
            onError: (_) {
              if (mounted && !_searchDisposed) {
                setState(() => _fares.remove(id));
              }
            },
          );
    }
  }

  List<String> _busScope(List<Bus> buses) => BusMatcher.findDirectBuses(
    buses,
    widget.fromStationId,
    widget.toStationId,
  ).where((b) => !b.isPublishedTimetable).map((b) => b.id).toList()..sort();

  void _checkScope(List<Bus> buses) {
    if (_searchDisposed ||
        _scopePending ||
        listEquals(_busScope(buses), _scope)) {
      return;
    }
    _scopePending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scopePending = false;
      if (!mounted || _searchDisposed) return;
      _allBuses = List.of(buses);
      _retrySearch();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _search = DatedSearchState(widget.searchBackend ?? TransitSearchBackend())
      ..addListener(_onSearchChanged);
    final prefs = AccessibilityPreferencesService.instance;
    _needs = widget.needsDraft ?? SearchNeedsDraft(prefs);
    if (widget.needsDraft == null) {
      if (widget.wheelchairAccessRequired != null) {
        _needs.setWheelchair(widget.wheelchairAccessRequired!);
      }
      if (widget.stepFreeOnly != null) _needs.setStepFree(widget.stepFreeOnly!);
    }
    _accountRevision = _needs.accountRevision;
    _isWheelchair = _needs.wheelchair;
    _isStepFree = _needs.stepFree;
    _needs.addListener(_onNeedsChanged);
    _selectedFilterTab = _isWheelchair
        ? RouteFilterTab.accessible
        : RouteFilterTab.all;
    _loadInitialData();
  }

  void _onNeedsChanged() {
    if (!mounted) return;
    setState(() {
      final changedWheelchair = _isWheelchair != _needs.wheelchair;
      _isWheelchair = _needs.wheelchair;
      _isStepFree = _needs.stepFree;
      if (_accountRevision != _needs.accountRevision) _stopSearch();
      if (changedWheelchair) {
        _selectedFilterTab = _isWheelchair
            ? RouteFilterTab.accessible
            : RouteFilterTab.all;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopSearch();
    _needs.removeListener(_onNeedsChanged);
    if (widget.needsDraft == null) _needs.dispose();
    super.dispose();
  }

  void _stopSearch() {
    for (final s in _geometrySubscriptions.values) {
      s.cancel();
    }
    _geometrySubscriptions.clear();
    _geometries.clear();
    for (final s in _fareSubscriptions.values) {
      s.cancel();
    }
    _fareSubscriptions.clear();
    _fares.clear();
    if (_searchDisposed) return;
    _searchDisposed = true;
    _search.removeListener(_onSearchChanged);
    _search.dispose();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_searchDisposed) {
      _search.synchronize(force: true);
    }
  }

  void _retrySearch() {
    if (_accountRevision != _needs.accountRevision) return;
    final backend = _search.backend;
    _stopSearch();
    _searchDisposed = false;
    _search = DatedSearchState(backend)..addListener(_onSearchChanged);
    final ids = _busScope(_allBuses);
    _watchFares(ids);
    _scope = List.of(ids);
    _search.start(ids);
    setState(() {});
  }

  Future<void> _loadInitialData() async {
    try {
      final fetchedBuses = await _firestoreService.getBuses();
      final fetchedStations = await _firestoreService.getStations();
      final fetchedRoutes = await _firestoreService.getRoutes();

      final buses = fetchedBuses;
      final stationsList = fetchedStations;
      final routesList = fetchedRoutes;

      final stationsMap = {for (final s in stationsList) s.id: s};
      final routesMap = {for (final r in routesList) r.id: r};
      if (!mounted || _searchDisposed) return;
      final ids = _busScope(buses);
      _allBuses = buses;
      _watchFares(ids);
      _scope = List.of(ids);
      _search.start(ids);

      if (mounted) {
        setState(() {
          _allBuses = buses;
          _stationsMap = stationsMap;
          _routesMap = routesMap;
          _isLoadingData = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _allBuses = [];
          _stationsMap = {for (final s in <Station>[]) s.id: s};
          _routesMap = {for (final r in []) r.id: r};
          _isLoadingData = false;
        });
      }
    }
  }

  void _onSelectRoute(RouteResultItem route) {
    final window = _search.window;
    // A card may have crossed its boarding boundary since its last rebuild.
    if (_needs.accountRevision != _accountRevision ||
        window == null ||
        route.nextDepartureDateTime == null ||
        window.lowerBound(
              date: widget.selectedDate,
              minutes: widget.selectedTime == null
                  ? null
                  : widget.selectedTime!.hour * 60 +
                        widget.selectedTime!.minute,
            ) ==
            null ||
        !_stillBoardable(route, window)) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.searchSelectionExpired)),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusDetailsScreen(
          origin: route.origin,
          destination: route.destination,
          route: route,
          bus: route.rawBus,
          statusResult: route.statusResult,
          repository: _search.backend,
          searchClock: _search.clock,
          fareFeed: widget.fareFeed,
          geometryFeed: widget.geometryFeed,
        ),
      ),
    );
  }

  bool _stillBoardable(RouteResultItem route, BoardingSearchWindow window) =>
      route.rawBus != null &&
      DatedBoardingMatcher.forBus(
        bus: route.rawBus!,
        from: widget.fromStationId,
        to: widget.toStationId,
        window: window,
        notBefore:
            window.lowerBound(
              date: widget.selectedDate,
              minutes: widget.selectedTime == null
                  ? null
                  : widget.selectedTime!.hour * 60 +
                        widget.selectedTime!.minute,
            ) ??
            window.end,
        selectedDate: widget.selectedDate,
        runs: _search.runsFor(route.busId),
        trips: _search.trips,
        locations: _search.locations,
        stations: _stationsMap,
        geometry: _geometries[route.busId],
      ).any(
        (o) =>
            o.runId == route.serviceRunId &&
            o.plan.departure == route.nextDepartureDateTime,
      );

  int _statusRank(AccessibilityStatus status) {
    switch (status) {
      case AccessibilityStatus.accessible:
        return 0; // Safe first
      case AccessibilityStatus.partial:
        return 1; // Warning second
      case AccessibilityStatus.notAccessible:
        return 3;
      case AccessibilityStatus.unknown:
        return 2;
    }
  }

  List<RouteResultItem> _buildAndFilterRouteItems(
    List<Report> activeReports, {
    List<Bus>? buses,
    bool applyTabFilter = true,
    DateTime? currentTime,
  }) {
    final busesToMatch = buses ?? _allBuses;

    // 1. Direct bus matching
    final matchedBuses = BusMatcher.findDirectBuses(
      busesToMatch,
      widget.fromStationId,
      widget.toStationId,
    );

    final window = _search.window;
    if (window == null) return [];
    final now = window.now;
    if (!_needs.isReady || _needs.accountRevision != _accountRevision) {
      return [];
    }
    final travelDate = widget.selectedDate ?? TransitTime.civil(now);
    final day = TransitTime.day(travelDate);
    final departNow =
        widget.selectedTime == null &&
        DateUtils.isSameDay(day, TransitTime.civil(now));
    final notBefore = window.lowerBound(
      date: widget.selectedDate,
      minutes: widget.selectedTime == null
          ? null
          : widget.selectedTime!.hour * 60 + widget.selectedTime!.minute,
    );
    if (notBefore == null) return [];

    // 2. Compute status & reasons
    final candidates = [
      for (final bus in matchedBuses)
        for (final option in DatedBoardingMatcher.forBus(
          bus: bus,
          from: widget.fromStationId,
          to: widget.toStationId,
          window: window,
          notBefore: notBefore,
          selectedDate: widget.selectedDate,
          runs: _search.runsFor(bus.id),
          trips: _search.trips,
          locations: _search.locations,
          stations: _stationsMap,
          geometry: _geometries[bus.id],
        ))
          (bus: bus, option: option),
    ];
    final List<RouteResultItem> items = candidates
        .map<RouteResultItem?>((candidate) {
          final bus = candidate.bus, option = candidate.option;
          final plan = option.plan;
          final requestedStatus = StatusLogic.getBusStatus(
            bus,
            activeReports,
            currentTime: now,
            stationsMap: _stationsMap,
            fromStationId: widget.fromStationId,
            toStationId: widget.toStationId,
            wheelchairAccessRequired: _isWheelchair,
            stepFreeOnly: _isStepFree,
          );
          if ((_isWheelchair || _isStepFree) &&
              requestedStatus.status != AccessibilityStatus.accessible) {
            return null;
          }
          final accessibleStatus = StatusLogic.getBusStatus(
            bus,
            activeReports,
            currentTime: now,
            stationsMap: _stationsMap,
            fromStationId: widget.fromStationId,
            toStationId: widget.toStationId,
            wheelchairAccessRequired: true,
            stepFreeOnly: _isStepFree,
          );
          final matchesAccessible =
              accessibleStatus.status == AccessibilityStatus.accessible;
          final statusResult = _selectedFilterTab == RouteFilterTab.accessible
              ? accessibleStatus
              : requestedStatus;

          final routeObj =
              _routesMap[bus.routeId] ??
              _routesMap.values.cast<BusRoute?>().firstWhere(
                (r) => r?.routeNo == bus.routeNo,
                orElse: () => null,
              );

          final routeName = routeObj?.routeName ?? 'Route ${bus.routeNo}';
          final displayBusNo = bus.displayBusNo;

          // Determine scheduled departure at the passenger's boarding station
          final nextDepDateTime = plan.departure;
          final civilDeparture = TransitTime.civil(nextDepDateTime);
          final civilNow = TransitTime.civil(now);
          final stopTimeStr = TimeUtils.formatTimeString(civilDeparture);
          final isToday = DateUtils.isSameDay(civilDeparture, civilNow);
          final isTomorrow = DateUtils.isSameDay(
            civilDeparture,
            DateTime.utc(civilNow.year, civilNow.month, civilNow.day + 1),
          );

          final diffMins = nextDepDateTime.difference(now).inMinutes;

          final String scheduledDepartureDisplay;
          final String etaLabelDisplay;
          if (!isToday && !isTomorrow) {
            final dateLabel = TimeUtils.formatDateString(civilDeparture);
            scheduledDepartureDisplay = 'Scheduled $dateLabel, $stopTimeStr';
            etaLabelDisplay = 'Scheduled $dateLabel at $stopTimeStr';
          } else if (isTomorrow) {
            scheduledDepartureDisplay = 'Scheduled tomorrow, $stopTimeStr';
            etaLabelDisplay = 'Scheduled tomorrow at $stopTimeStr';
          } else {
            scheduledDepartureDisplay = 'Scheduled today, $stopTimeStr';
            if (nextDepDateTime.isBefore(now) && departNow) {
              etaLabelDisplay = 'Scheduled time passed - departure unconfirmed';
            } else if (diffMins <= 1 && departNow) {
              etaLabelDisplay = 'Scheduled now - departure unconfirmed';
            } else if (diffMins < 60 && departNow) {
              etaLabelDisplay = 'Scheduled in $diffMins mins - $stopTimeStr';
            } else {
              etaLabelDisplay = 'Scheduled today at $stopTimeStr';
            }
          }

          final durationMinutes = plan.durationMinutes;
          final arrivalDateTime = plan.arrival;
          final departureTimeFormatted = TimeUtils.formatTimeString(
            civilDeparture,
          );
          final arrivalTimeFormatted = TimeUtils.formatTimeString(
            TransitTime.civil(arrivalDateTime),
          );

          final summaryText = statusResult.reasons.isNotEmpty
              ? statusResult.reasons.first
              : (statusResult.rampWorking
                    ? 'Wheelchair Ramp Ready · Step-free entry'
                    : (bus.hasRamp
                          ? 'Ramp equipped · Check operator assistance'
                          : 'Standard bus service'));

          String crowdLabel = 'Unknown';
          if (bus.occupancy.toLowerCase() == 'low') crowdLabel = 'Low';
          if (bus.occupancy.toLowerCase() == 'medium') crowdLabel = 'Medium';
          if (bus.occupancy.toLowerCase() == 'high') crowdLabel = 'High';

          final fromName =
              _stationsMap[widget.fromStationId]?.name ?? widget.origin;
          final toName =
              _stationsMap[widget.toStationId]?.name ?? widget.destination;

          final estimatedPrice = plan.estimatedPriceLkr;
          final fareQuote = FarePublication.quote(
            _fares[bus.id] ?? const [],
            bus,
            widget.fromStationId,
            widget.toStationId,
            plan.departure,
          );

          return RouteResultItem(
            id: bus.id,
            title: 'Route ${bus.routeNo} • $displayBusNo',
            busNo: displayBusNo,
            routeNo: bus.routeNo,
            routeName: routeName,
            scheduledDeparture: scheduledDepartureDisplay,
            departureTimeStr: departureTimeFormatted,
            arrivalTimeStr: arrivalTimeFormatted,
            durationMinutes: durationMinutes,
            etaLabel: option.active
                ? 'Boarding estimate ${TimeUtils.formatTimeString(TransitTime.civil(option.boardingAt))} · ${option.source}'
                : etaLabelDisplay,
            serviceRunId: option.runId,
            boardingEstimateAt: option.active ? option.boardingAt : null,
            boardingEstimateSource: option.active ? option.source : null,
            progressEstimate: option.progressEstimate,
            estimatedPriceLkr: estimatedPrice,
            fareQuote: fareQuote,
            timetableStatusLabel: option.active
                ? 'Started run'
                : TransitCatalogue.demo
                ? 'Demo timetable'
                : bus.isPublishedTimetable
                ? 'Published timetable'
                : 'Scheduled',
            usesEstimatedTimes: plan.usesEstimatedTimes,
            transfers: 0,
            crowdLevel: crowdLabel,
            accessibilityStatus: statusResult.status,
            accessibilityLabel: statusResult.statusLabel,
            safetyLabel: statusResult.rampWorking
                ? 'Wheelchair Accessible Bus'
                : (bus.hasRamp ? 'Standard Ramp Bus' : 'Standard Bus'),
            summary:
                '$routeName · $summaryText${plan.usesEstimatedTimes ? ' · Some times are model estimates; confirm with the operator.' : ''}',
            busId: bus.id,
            origin: fromName,
            destination: toName,
            intermediateStops: plan.stops.sublist(1, plan.stops.length - 1),
            recommended: matchesAccessible,
            matchesAccessibleFilter: matchesAccessible,
            fromStationId: widget.fromStationId,
            toStationId: widget.toStationId,
            wheelchairAccessRequired:
                _isWheelchair ||
                _selectedFilterTab == RouteFilterTab.accessible,
            stepFreeOnly: _isStepFree,
            journeyStations: {
              for (final id in plan.stops)
                if (_stationsMap.containsKey(id)) id: _stationsMap[id]!,
            },
            rawBus: bus,
            statusResult: statusResult,
            nextDepartureDateTime: nextDepDateTime,
            selectedDate: day,
            selectedTimeMinutes: widget.selectedTime == null
                ? null
                : widget.selectedTime!.hour * 60 + widget.selectedTime!.minute,
          );
        })
        .whereType<RouteResultItem>()
        .toList();

    // 3. Filter by Tab ('All', 'Accessible', 'Fastest')
    var filtered = items;
    if (applyTabFilter && _selectedFilterTab == RouteFilterTab.accessible) {
      filtered = filtered.where((r) => r.matchesAccessibleFilter).toList();
    }

    // 4. Sort
    filtered.sort((a, b) {
      if (_selectedFilterTab == RouteFilterTab.fastest) {
        return a.durationMinutes.compareTo(b.durationMinutes);
      }

      // Prioritize wheelchair accessible buses when wheelchair access is required
      // or when the Accessible tab is selected
      if (_isWheelchair || _selectedFilterTab == RouteFilterTab.accessible) {
        final aAcc = a.matchesAccessibleFilter;
        final bAcc = b.matchesAccessibleFilter;
        if (aAcc != bAcc) {
          return aAcc ? -1 : 1; // Accessible buses first
        }

        final rankA = _statusRank(a.accessibilityStatus);
        final rankB = _statusRank(b.accessibilityStatus);
        if (rankA != rankB) {
          return rankA.compareTo(rankB); // Verified accessible status first
        }
      }

      // Default: Earliest upcoming bus first
      final timeA = a.boardingEstimateAt ?? a.nextDepartureDateTime ?? now;
      final timeB = b.boardingEstimateAt ?? b.nextDepartureDateTime ?? now;
      final timeComp = timeA.compareTo(timeB);
      if (timeComp != 0) {
        return timeComp;
      }

      final rankA = _statusRank(a.accessibilityStatus);
      final rankB = _statusRank(b.accessibilityStatus);
      return rankA.compareTo(rankB);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;
    final isHighContrast = context.isHighContrast;

    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: Column(
        children: [
          _TopBar(onBack: () => Navigator.of(context).maybePop()),
          Expanded(
            child: _isLoadingData
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<Bus>>(
                    stream: _firestoreService.streamBuses(),
                    builder: (context, busSnapshot) {
                      final buses = busSnapshot.data ?? _allBuses;
                      _checkScope(buses);

                      return StreamBuilder<List<Report>>(
                        stream: _firestoreService.streamReports(),
                        builder: (context, snapshot) {
                          final reports = snapshot.data ?? const <Report>[];
                          return EvidenceRefresh(
                            reports: reports,
                            buses: buses,
                            now: () =>
                                _search.clock?.now ?? DateTime.now().toUtc(),
                            boundaries: [
                              for (final bus in buses)
                                for (final run in _search.runsFor(bus.id)) ...[
                                  run.latestStartAt,
                                  if (run.stopTimes[widget.fromStationId] !=
                                      null)
                                    run.stopTimes[widget.fromStationId]!,
                                ],
                              for (final gps in _search.locations.values)
                                if (gps.timestamp != null)
                                  gps.timestamp!.add(
                                    const Duration(seconds: 30),
                                  ),
                            ],
                            builder: (context, now) {
                              final routes = _buildAndFilterRouteItems(
                                reports,
                                buses: buses,
                                currentTime: now,
                              );

                              final available = _buildAndFilterRouteItems(
                                reports,
                                buses: buses,
                                currentTime: now,
                                applyTabFilter: false,
                              );
                              final totalAvailable = available.length;
                              final accessibleCount = available
                                  .where((r) => r.matchesAccessibleFilter)
                                  .length;

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
                                      constraints: const BoxConstraints(
                                        maxWidth: 768,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // Clean Trip Corridor Header
                                          _TripSummaryCard(
                                            origin: widget.origin,
                                            destination: widget.destination,
                                            matchedCount: routes.length,
                                            selectedDate: widget.selectedDate,
                                            selectedTime: widget.selectedTime,
                                            currentTime: TransitTime.civil(now),
                                          ),
                                          const SizedBox(height: 14),
                                          if (_search.error != null)
                                            TextButton(
                                              onPressed: _retrySearch,
                                              child: Text(
                                                context.l10n.retrySearch,
                                              ),
                                            ),
                                          Text(
                                            _needs.accountRevision !=
                                                    _accountRevision
                                                ? context
                                                      .l10n
                                                      .searchAccountChanged
                                                : _search.window == null
                                                ? (_search.error == null
                                                      ? context
                                                            .l10n
                                                            .verifyingDatedSearch
                                                      : _search.clockError !=
                                                            null
                                                      ? context
                                                            .l10n
                                                            .searchTimeUnavailable
                                                      : context
                                                            .l10n
                                                            .datedSearchUnavailable)
                                                : _search.window!.lowerBound(
                                                        date:
                                                            widget.selectedDate,
                                                        minutes:
                                                            widget.selectedTime ==
                                                                null
                                                            ? null
                                                            : widget.selectedTime!.hour *
                                                                      60 +
                                                                  widget
                                                                      .selectedTime!
                                                                      .minute,
                                                      ) ==
                                                      null
                                                ? context
                                                      .l10n
                                                      .searchWindowInvalid
                                                : context
                                                      .l10n
                                                      .searchWindowNotice,
                                          ),
                                          const SizedBox(height: 14),
                                          if (widget.minimizeWalking == true)
                                            const Padding(
                                              padding: EdgeInsets.only(
                                                bottom: 14,
                                              ),
                                              child: Text(
                                                'Walking distance is unavailable for this journey. Results are not ranked by walking distance.',
                                              ),
                                            ),

                                          // LMT Go Style Accessible Filter Tabs
                                          _LmtGoFilterTabs(
                                            selectedTab: _selectedFilterTab,
                                            allCount: totalAvailable,
                                            accessibleCount: accessibleCount,
                                            onTabSelected: (tab) {
                                              setState(
                                                () => _selectedFilterTab = tab,
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 16),

                                          // Route Results Cards or Empty State
                                          if (routes.isEmpty &&
                                              _search.window != null) ...[
                                            _buildEmptyState(
                                              allCount: totalAvailable,
                                            ),
                                          ] else ...[
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.directions_bus_rounded,
                                                  size: 18,
                                                  color: isHighContrast
                                                      ? Colors.black
                                                      : AppColors.primary,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Available Buses (${routes.length})',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: isHighContrast
                                                        ? Colors.black
                                                        : AppColors.onSurface,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            ...routes.map(
                                              (route) => Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 14,
                                                ),
                                                child: _LmtGoRouteCard(
                                                  route: route,
                                                  onTap: () =>
                                                      _onSelectRoute(route),
                                                ),
                                              ),
                                            ),
                                          ],
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
                  ),
          ),
        ],
      ),
      bottomNavigationBar: null,
    );
  }

  Future<void> _reviewTripRequirements() async {
    final accountRevision = _needs.accountRevision;
    var wheelchair =
        _isWheelchair || _selectedFilterTab == RouteFilterTab.accessible;
    var stepFree = _isStepFree;
    final apply = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Review trip requirements'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Changes apply only to this search. Turning a requirement off may show services with unknown access or reported barriers. Review the evidence before choosing a journey.',
                ),
                SwitchListTile(
                  title: const Text('Wheelchair access required'),
                  value: wheelchair,
                  onChanged: (value) => update(() => wheelchair = value),
                ),
                SwitchListTile(
                  title: const Text('Step-free routes only'),
                  value: stepFree,
                  onChanged: (value) => update(() => stepFree = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep requirements'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Apply to this search'),
            ),
          ],
        ),
      ),
    );
    if (!mounted ||
        apply != true ||
        accountRevision != _needs.accountRevision ||
        _accountRevision != _needs.accountRevision) {
      return;
    }
    _needs.setWheelchair(wheelchair);
    _needs.setStepFree(stepFree);
    setState(() {
      _isWheelchair = wheelchair;
      _isStepFree = stepFree;
      _selectedFilterTab = wheelchair
          ? RouteFilterTab.accessible
          : RouteFilterTab.all;
    });
  }

  Widget _buildEmptyState({required int allCount}) {
    final isHighContrast = context.isHighContrast;
    final isFiltered =
        _selectedFilterTab == RouteFilterTab.accessible ||
        _isWheelchair ||
        _isStepFree;

    final emptyTitle = isFiltered
        ? 'No Accessible Buses Found'
        : 'No Direct Buses Found';

    final emptyDesc = isFiltered
        ? 'No scheduled journeys have known access matching these requirements. Stop access may be unknown or an active barrier may be reported. Review your accessibility filters.'
        : 'There are currently no direct bus routes connecting ${widget.origin} to ${widget.destination}.';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isHighContrast
            ? const BorderSide(color: Colors.black, width: 2.0)
            : BorderSide.none,
      ),
      color: isHighContrast ? Colors.white : AppColors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Icon(
              isFiltered
                  ? Icons.accessible_forward
                  : Icons.directions_bus_outlined,
              size: 56,
              color: isHighContrast ? Colors.black : AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              emptyTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isHighContrast ? Colors.black : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emptyDesc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isHighContrast
                    ? const Color(0xFF1A1A1A)
                    : AppColors.onSurfaceVariant,
                fontWeight: isHighContrast
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
            if (_selectedFilterTab == RouteFilterTab.accessible &&
                allCount > 0) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () =>
                    setState(() => _selectedFilterTab = RouteFilterTab.all),
                child: const Text('Show all matching buses'),
              ),
              const Text(
                'Shows options outside the Accessible tab, including unknown access or reported barriers. Your trip requirements stay applied.',
              ),
            ],
            if (isFiltered) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _reviewTripRequirements,
                child: const Text('Review trip requirements'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;

    return Material(
      color: context.surfaceColor,
      elevation: isHighContrast ? 0 : 1,
      shadowColor: AppColors.onSurface.withValues(alpha: 0.08),
      child: Container(
        decoration: BoxDecoration(
          border: isHighContrast
              ? const Border(
                  bottom: BorderSide(color: Colors.black, width: 2.0),
                )
              : null,
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: isHighContrast ? Colors.black : AppColors.primary,
                    tooltip: 'Back',
                    iconSize: context.navIconSize,
                    constraints: context.appBarActionConstraints,
                  ),
                  const SizedBox(width: 6),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Buses',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isHighContrast
                              ? Colors.black
                              : AppColors.primary,
                        ),
                      ),
                      Text(
                        'Select a bus to track live journey',
                        style: TextStyle(
                          fontSize: 12,
                          color: isHighContrast
                              ? const Color(0xFF1A1A1A)
                              : AppColors.onSurfaceVariant,
                          fontWeight: isHighContrast
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Trip Summary Corridor Header
class _TripSummaryCard extends StatelessWidget {
  const _TripSummaryCard({
    required this.origin,
    required this.destination,
    required this.matchedCount,
    this.selectedDate,
    this.selectedTime,
    this.currentTime,
  });

  final String origin;
  final String destination;
  final int matchedCount;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final DateTime? currentTime;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final dateStr = TimeUtils.formatDateString(
      selectedDate ?? currentTime ?? TransitTime.civil(DateTime.now()),
      clock: currentTime,
    );
    final travelLabel = selectedTime == null
        ? dateStr
        : '$dateStr at ${selectedTime!.format(context)}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.white : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: isHighContrast
            ? Border.all(color: Colors.black, width: 2.0)
            : Border.all(color: AppColors.surfaceVariant),
        boxShadow: isHighContrast
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
          // Origin to Destination Row
          Row(
            children: [
              Icon(
                Icons.trip_origin_rounded,
                size: 16,
                color: isHighContrast ? Colors.black : AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  origin,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isHighContrast ? Colors.black : AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: isHighContrast ? Colors.black : AppColors.primary,
                ),
              ),
              Icon(
                Icons.location_on_rounded,
                size: 16,
                color: isHighContrast
                    ? const Color(0xFF8B0000)
                    : AppColors.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  destination,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isHighContrast ? Colors.black : AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: isHighContrast ? Colors.black : AppColors.surfaceVariant,
          ),
          const SizedBox(height: 8),
          // Info row: Date & status
          Row(
            children: [
              Icon(
                Icons.event_note_rounded,
                size: 15,
                color: isHighContrast
                    ? Colors.black
                    : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  travelLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: isHighContrast
                        ? const Color(0xFF1A1A1A)
                        : AppColors.onSurfaceVariant,
                    fontWeight: isHighContrast
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isHighContrast ? Colors.white : AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(6),
                  border: isHighContrast
                      ? Border.all(color: Colors.black, width: 1.5)
                      : null,
                ),
                child: Text(
                  '$matchedCount buses available',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isHighContrast ? Colors.black : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// LMT Go Filter Tabs (All / ♿ Accessible / Fastest)
class _LmtGoFilterTabs extends StatelessWidget {
  const _LmtGoFilterTabs({
    required this.selectedTab,
    required this.allCount,
    required this.accessibleCount,
    required this.onTabSelected,
  });

  final RouteFilterTab selectedTab;
  final int allCount;
  final int accessibleCount;
  final ValueChanged<RouteFilterTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TabItem(
            label: 'All ($allCount)',
            isSelected: selectedTab == RouteFilterTab.all,
            onTap: () => onTabSelected(RouteFilterTab.all),
          ),
          const SizedBox(width: 8),
          _TabItem(
            icon: Icons.accessible_rounded,
            label: 'Accessible ($accessibleCount)',
            isSelected: selectedTab == RouteFilterTab.accessible,
            onTap: () => onTabSelected(RouteFilterTab.accessible),
          ),
          const SizedBox(width: 8),
          _TabItem(
            icon: Icons.flash_on_rounded,
            label: 'Fastest',
            isSelected: selectedTab == RouteFilterTab.fastest,
            onTap: () => onTabSelected(RouteFilterTab.fastest),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final Color bgColor;
    final Color borderColor;
    final Color contentColor;

    if (isHighContrast) {
      bgColor = isSelected ? const Color(0xFF001F3F) : Colors.white;
      borderColor = Colors.black;
      contentColor = isSelected ? Colors.white : Colors.black;
    } else {
      bgColor = isSelected
          ? AppColors.primaryContainer
          : AppColors.surfaceContainerLowest;
      borderColor = isSelected
          ? AppColors.primaryContainer
          : AppColors.outlineVariant;
      contentColor = isSelected ? AppColors.onPrimary : AppColors.onSurface;
    }

    final hasLargeTargets = context.hasLargeTargets;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        constraints: BoxConstraints(
          minHeight: context.chipHeight,
          minWidth: context.chipHeight,
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: hasLargeTargets ? 20 : 16,
          vertical: hasLargeTargets ? 14 : 10,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: borderColor,
            width: isHighContrast ? 2.0 : (isSelected ? 1.5 : 1.0),
          ),
          boxShadow: (isSelected && !isHighContrast)
              ? [
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: hasLargeTargets ? 20 : 16,
                color: isHighContrast
                    ? contentColor
                    : (isSelected
                          ? AppColors.onPrimary
                          : AppColors.onSurfaceVariant),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: hasLargeTargets ? 16 : 14,
                fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w700,
                color: contentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// LMT Go Style Available Bus Card
class _LmtGoRouteCard extends StatelessWidget {
  const _LmtGoRouteCard({required this.route, required this.onTap});

  final RouteResultItem route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final hasLargeTargets = context.hasLargeTargets;
    final rawBus = route.rawBus;
    final hasRamp =
        rawBus?.hasRamp == true &&
        route.accessibilityStatus == AccessibilityStatus.accessible;
    final hasLowFloor = rawBus?.lowFloor == true;

    final statusBg = isHighContrast
        ? const Color(0xFF1A1A1A)
        : AppColors.surfaceContainer;
    final statusFg = isHighContrast ? Colors.white : AppColors.onSurfaceVariant;

    return Material(
      color: isHighContrast ? Colors.white : AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      elevation: isHighContrast ? 0 : 1,
      shadowColor: AppColors.onSurface.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: hasLargeTargets ? 16 : 14,
            vertical: hasLargeTargets ? 18 : 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighContrast
                  ? Colors.black
                  : (route.recommended
                        ? AppColors.secondary
                        : AppColors.surfaceVariant),
              width: isHighContrast ? 2.0 : (route.recommended ? 1.5 : 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Row: Route Badge, Bus Number, Status Pill, and Bold Price
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Prominent Route Code Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: hasLargeTargets ? 10 : 8,
                            vertical: hasLargeTargets ? 6 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: isHighContrast
                                ? const Color(0xFF8B0000)
                                : const Color(0xFFC62828),
                            borderRadius: BorderRadius.circular(8),
                            border: isHighContrast
                                ? Border.all(color: Colors.black, width: 1.5)
                                : null,
                          ),
                          child: Text(
                            route.routeNo ?? 'Route',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: hasLargeTargets ? 14 : 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        // Bus Plate Number
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: hasLargeTargets ? 8 : 6,
                            vertical: hasLargeTargets ? 5 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: isHighContrast
                                ? Colors.white
                                : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isHighContrast
                                  ? Colors.black
                                  : AppColors.outlineVariant.withValues(
                                      alpha: 0.5,
                                    ),
                              width: isHighContrast ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.directions_bus,
                                size: hasLargeTargets ? 15 : 13,
                                color: isHighContrast
                                    ? Colors.black
                                    : AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                route.busNo ?? route.busId,
                                style: TextStyle(
                                  fontSize: hasLargeTargets ? 13 : 12,
                                  fontWeight: FontWeight.w700,
                                  color: isHighContrast
                                      ? Colors.black
                                      : AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Timetable provenance; never infer vehicle movement from a clock.
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: hasLargeTargets ? 8 : 6,
                            vertical: hasLargeTargets ? 5 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(999),
                            border: isHighContrast
                                ? Border.all(color: Colors.black, width: 1.5)
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isHighContrast
                                      ? Colors.white
                                      : statusFg,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                route.timetableStatusLabel,
                                style: TextStyle(
                                  fontSize: hasLargeTargets ? 11 : 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: statusFg,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Estimated Price in LKR (Right-aligned, bold)
                  FareEstimateText(
                    quote: route.fareQuote,
                    amount: route.estimatedPriceLkr,
                    style: TextStyle(
                      fontSize: hasLargeTargets ? 19 : 17,
                      fontWeight: FontWeight.w800,
                      color: isHighContrast ? Colors.black : AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (route.progressEstimate != null)
                RouteProgressEtaText(
                  estimate: route.progressEstimate!,
                  target: route.origin,
                )
              else
                Text(
                  route.boardingEstimateAt == null
                      ? 'Timetable estimates - departure unconfirmed. Open route details for GPS status.'
                      : 'Boarding estimate · ${route.boardingEstimateSource}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isHighContrast
                        ? Colors.black
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 8),
              FareDisclosureText(
                quote: route.fareQuote,
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              // 2. FROM ➔ TO Corridor Title
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${route.origin} ➔ ${route.destination}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isHighContrast
                            ? Colors.black
                            : AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Middle Timeline Row: "Departs at" ── [Duration] ──> "Arrives at"
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isHighContrast
                      ? Colors.white
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: isHighContrast
                      ? Border.all(color: Colors.black, width: 1.5)
                      : null,
                ),
                child: Row(
                  children: [
                    // Departs at
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Departure',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isHighContrast
                                ? const Color(0xFF2B2B2B)
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          route.departureTimeStr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isHighContrast
                                ? Colors.black
                                : AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),

                    // Visual Journey Indicator with Duration
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            Text(
                              '~${route.durationMinutes} min',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isHighContrast
                                    ? Colors.black
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isHighContrast
                                        ? Colors.black
                                        : AppColors.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    thickness: 1.5,
                                    color: isHighContrast
                                        ? Colors.black
                                        : AppColors.outlineVariant,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: isHighContrast
                                      ? Colors.black
                                      : AppColors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Arrives at
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Arrival',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isHighContrast
                                ? const Color(0xFF2B2B2B)
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          route.arrivalTimeStr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isHighContrast
                                ? Colors.black
                                : AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4. Accessibility Badges (Visual at a glance)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _MiniFeatureBadge(
                      icon:
                          route.accessibilityStatus ==
                              AccessibilityStatus.unknown
                          ? Icons.help_outline
                          : Icons.info_outline,
                      label: route.accessibilityLabel,
                      color: isHighContrast
                          ? Colors.black
                          : AppColors.onSurface,
                      bgColor: isHighContrast
                          ? Colors.white
                          : AppColors.surfaceContainer,
                    ),
                    const SizedBox(width: 6),
                    if (hasRamp) ...[
                      _MiniFeatureBadge(
                        icon: Icons.accessible_rounded,
                        label: 'Ramp Available',
                        color: isHighContrast
                            ? Colors.black
                            : AppColors.secondary,
                        bgColor: isHighContrast
                            ? Colors.white
                            : AppColors.secondaryContainer.withValues(
                                alpha: 0.4,
                              ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (hasLowFloor) ...[
                      _MiniFeatureBadge(
                        icon: Icons.elevator_outlined,
                        label: 'Low Floor',
                        color: isHighContrast
                            ? Colors.black
                            : AppColors.primary,
                        bgColor: isHighContrast
                            ? Colors.white
                            : AppColors.primaryFixed,
                      ),
                      const SizedBox(width: 6),
                    ],
                    _MiniFeatureBadge(
                      icon: Icons.people_outline_rounded,
                      label: '${route.crowdLevel} Crowd',
                      color: isHighContrast
                          ? Colors.black
                          : AppColors.onSurfaceVariant,
                      bgColor: isHighContrast
                          ? Colors.white
                          : AppColors.surfaceContainer,
                    ),
                    const SizedBox(width: 6),
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

class _MiniFeatureBadge extends StatelessWidget {
  const _MiniFeatureBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.white : bgColor,
        borderRadius: BorderRadius.circular(8),
        border: isHighContrast
            ? Border.all(color: Colors.black, width: 1.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isHighContrast ? Colors.black : color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w700,
              color: isHighContrast ? Colors.black : color,
            ),
          ),
        ],
      ),
    );
  }
}
