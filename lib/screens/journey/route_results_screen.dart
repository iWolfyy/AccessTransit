import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_utils.dart';
import '../../data/seed_data.dart';
import '../../logic/bus_matcher.dart';
import '../../logic/passenger_journey_plan.dart';
import '../../logic/status_logic.dart';
import '../../models/bus.dart';
import '../../models/bus_route.dart';
import '../../models/report.dart';
import '../../models/station.dart';
import '../../models/trip_model.dart';
import '../../services/accessibility_preferences_service.dart';
import '../../services/firestore_service.dart';
import '../../services/trip_service.dart';
import 'route_details_screen.dart';

/// Route result item used for passenger route selection.
/// Enhanced in Phase 2 with LMT Go inspired fields: departure/arrival times,
/// price calculation, and real-time live status.
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
    this.estimatedPriceLkr = 95,
    this.liveStatusLabel = 'Scheduled',
    this.isLive = false,
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
  final String liveStatusLabel;
  final bool isLive;
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
}

enum AccessibilityStatus { accessible, partial, notAccessible, unknown }

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

  @override
  State<RouteResultsScreen> createState() => _RouteResultsScreenState();
}

class _RouteResultsScreenState extends State<RouteResultsScreen> {
  static const double _desktopBreakpoint = 768;
  final FirestoreService _firestoreService = FirestoreService();

  List<Bus> _allBuses = [];
  Map<String, BusRoute> _routesMap = {};
  Map<String, Station> _stationsMap = {};
  bool _isLoadingData = true;
  late String _selectedFilterTab; // 'All', 'Accessible', 'Fastest'
  late final bool _isWheelchair;
  late final bool _isStepFree;

  @override
  void initState() {
    super.initState();
    final prefs = AccessibilityPreferencesService.instance;
    _isWheelchair = widget.wheelchairAccessRequired ?? prefs.isWheelchairOnly;
    _isStepFree = widget.stepFreeOnly ?? prefs.isStepFree;
    _selectedFilterTab = _isWheelchair ? 'Accessible' : 'All';
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final fetchedBuses = await _firestoreService.getBuses();
      final fetchedStations = await _firestoreService.getStations();
      final fetchedRoutes = await _firestoreService.getRoutes();

      final buses = fetchedBuses.isNotEmpty
          ? fetchedBuses
          : SeedData.sampleBuses;
      final stationsList = fetchedStations.isNotEmpty
          ? fetchedStations
          : SeedData.colomboStations;
      final routesList = fetchedRoutes.isNotEmpty
          ? fetchedRoutes
          : SeedData.sampleRoutes;

      final stationsMap = {for (final s in stationsList) s.id: s};
      final routesMap = {for (final r in routesList) r.id: r};

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
          _allBuses = SeedData.sampleBuses;
          _stationsMap = {for (final s in SeedData.colomboStations) s.id: s};
          _routesMap = {for (final r in SeedData.sampleRoutes) r.id: r};
          _isLoadingData = false;
        });
      }
    }
  }

  void _onSelectRoute(RouteResultItem route) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteDetailsScreen(
          origin: route.origin,
          destination: route.destination,
          route: route,
          bus: route.rawBus,
          statusResult: route.statusResult,
        ),
      ),
    );
  }

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
  }) {
    final busesToMatch = (buses != null && buses.isNotEmpty)
        ? buses
        : _allBuses;

    // 1. Direct bus matching
    final matchedBuses = BusMatcher.findDirectBuses(
      busesToMatch,
      widget.fromStationId,
      widget.toStationId,
    );

    final now = DateTime.now();
    final travelDate = widget.selectedDate ?? now;
    final day = DateTime(travelDate.year, travelDate.month, travelDate.day);
    final departNow =
        widget.selectedTime == null && DateUtils.isSameDay(day, now);
    final notBefore = widget.selectedTime != null
        ? DateTime(
            day.year,
            day.month,
            day.day,
            widget.selectedTime!.hour,
            widget.selectedTime!.minute,
          )
        : departNow
        ? now.subtract(const Duration(minutes: 10))
        : day;

    // 2. Compute status & reasons
    final List<RouteResultItem> items = matchedBuses
        .map<RouteResultItem?>((bus) {
          final plan = PassengerJourneyPlan.forBus(
            bus: bus,
            fromId: widget.fromStationId,
            toId: widget.toStationId,
            travelDate: day,
            notBefore: notBefore,
            rollToNextDay: departNow,
          );
          if (plan == null) return null;
          final requestedStatus = StatusLogic.getBusStatus(
            bus,
            activeReports,
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
            stationsMap: _stationsMap,
            fromStationId: widget.fromStationId,
            toStationId: widget.toStationId,
            wheelchairAccessRequired: true,
            stepFreeOnly: _isStepFree,
          );
          final matchesAccessible =
              accessibleStatus.status == AccessibilityStatus.accessible;
          final statusResult = _selectedFilterTab == 'Accessible'
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
          final stopTimeStr = TimeUtils.formatTimeString(nextDepDateTime);
          final isToday = DateUtils.isSameDay(nextDepDateTime, now);
          final isTomorrow = DateUtils.isSameDay(
            nextDepDateTime,
            DateTime(now.year, now.month, now.day + 1),
          );

          final diffMins = nextDepDateTime.difference(now).inMinutes;

          final String scheduledDepartureDisplay;
          final String etaLabelDisplay;
          if (!isToday && !isTomorrow) {
            final dateLabel = TimeUtils.formatDateString(nextDepDateTime);
            scheduledDepartureDisplay = '$dateLabel, $stopTimeStr';
            etaLabelDisplay = '$dateLabel at $stopTimeStr';
          } else if (isTomorrow) {
            scheduledDepartureDisplay = 'Tomorrow, $stopTimeStr';
            etaLabelDisplay = 'Tomorrow at $stopTimeStr';
          } else {
            if (diffMins <= 1 && departNow) {
              scheduledDepartureDisplay = '$stopTimeStr (Now)';
              etaLabelDisplay = 'Arriving now • $stopTimeStr';
            } else if (diffMins >= 0 && diffMins < 60 && departNow) {
              scheduledDepartureDisplay = '$stopTimeStr (in ${diffMins}m)';
              etaLabelDisplay =
                  'Departs in $diffMins mins • Today, $stopTimeStr';
            } else {
              scheduledDepartureDisplay = 'Today, $stopTimeStr';
              etaLabelDisplay = 'Today at $stopTimeStr';
            }
          }

          final durationMinutes = plan.durationMinutes;
          final arrivalDateTime = plan.arrival;
          final departureTimeFormatted = TimeUtils.formatTimeString(
            nextDepDateTime,
          );
          final arrivalTimeFormatted = TimeUtils.formatTimeString(
            arrivalDateTime,
          );

          // Determine live operational status label
          final String liveStatus;
          final bool isBusLive;
          if (!departNow || !isToday) {
            liveStatus = 'Scheduled';
            isBusLive = false;
          } else if (diffMins <= 5 && diffMins >= -30) {
            liveStatus = 'Ongoing';
            isBusLive = true;
          } else if (diffMins < 20 && diffMins > 5) {
            liveStatus = 'Approaching';
            isBusLive = true;
          } else if (statusResult.reasons.any(
            (r) => r.toLowerCase().contains('delay'),
          )) {
            liveStatus = 'Delayed';
            isBusLive = false;
          } else {
            liveStatus = 'Scheduled';
            isBusLive = false;
          }

          final summaryText = statusResult.reasons.isNotEmpty
              ? statusResult.reasons.first
              : (bus.wheelchairAccessible
                    ? 'Wheelchair Ramp Ready · Step-free entry'
                    : (bus.hasRamp
                          ? 'Ramp equipped · Check operator assistance'
                          : 'Standard bus service'));

          String crowdLabel = 'Low';
          if (bus.occupancy.toLowerCase() == 'medium') crowdLabel = 'Medium';
          if (bus.occupancy.toLowerCase() == 'high') crowdLabel = 'High';

          final fromName =
              _stationsMap[widget.fromStationId]?.name ?? widget.origin;
          final toName =
              _stationsMap[widget.toStationId]?.name ?? widget.destination;

          final estimatedPrice = plan.estimatedPriceLkr;

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
            etaLabel: etaLabelDisplay,
            estimatedPriceLkr: estimatedPrice,
            liveStatusLabel: liveStatus,
            isLive: isBusLive,
            transfers: 0,
            crowdLevel: crowdLabel,
            accessibilityStatus: statusResult.status,
            accessibilityLabel: statusResult.statusLabel,
            safetyLabel: bus.wheelchairAccessible
                ? 'Wheelchair Accessible Bus'
                : (bus.hasRamp ? 'Standard Ramp Bus' : 'Standard Bus'),
            summary: '$routeName · $summaryText',
            busId: bus.id,
            origin: fromName,
            destination: toName,
            intermediateStops: plan.stops.sublist(1, plan.stops.length - 1),
            recommended: matchesAccessible,
            matchesAccessibleFilter: matchesAccessible,
            fromStationId: widget.fromStationId,
            toStationId: widget.toStationId,
            wheelchairAccessRequired:
                _isWheelchair || _selectedFilterTab == 'Accessible',
            stepFreeOnly: _isStepFree,
            journeyStations: {
              for (final id in [widget.fromStationId, widget.toStationId])
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
    if (applyTabFilter && _selectedFilterTab == 'Accessible') {
      filtered = filtered.where((r) => r.matchesAccessibleFilter).toList();
    }

    // 4. Sort
    filtered.sort((a, b) {
      if (_selectedFilterTab == 'Fastest') {
        return a.durationMinutes.compareTo(b.durationMinutes);
      }

      // Prioritize wheelchair accessible buses when wheelchair access is required
      // or when the Accessible tab is selected
      if (_isWheelchair || _selectedFilterTab == 'Accessible') {
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
      final timeA = a.nextDepartureDateTime ?? DateTime.now();
      final timeB = b.nextDepartureDateTime ?? DateTime.now();
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

                      return StreamBuilder<List<Report>>(
                        stream: _firestoreService.streamReports(),
                        builder: (context, snapshot) {
                          final reports = snapshot.data ?? const <Report>[];
                          final routes = _buildAndFilterRouteItems(
                            reports,
                            buses: buses,
                          );

                          final available = _buildAndFilterRouteItems(
                            reports,
                            buses: buses,
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
                                      ),
                                      const SizedBox(height: 14),
                                      if (widget.minimizeWalking == true)
                                        const Padding(
                                          padding: EdgeInsets.only(bottom: 14),
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
                                      if (routes.isEmpty) ...[
                                        _buildEmptyState(),
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
                  ),
          ),
        ],
      ),
      bottomNavigationBar: null,
    );
  }

  Widget _buildEmptyState() {
    final isHighContrast = context.isHighContrast;
    final isFiltered =
        _selectedFilterTab == 'Accessible' || _isWheelchair || _isStepFree;

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
            if (isFiltered && _selectedFilterTab == '♿ Accessible') ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => setState(() => _selectedFilterTab = 'All'),
                child: const Text('Show All Buses'),
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
  });

  final String origin;
  final String destination;
  final int matchedCount;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final dateStr = TimeUtils.formatDateString(selectedDate ?? DateTime.now());
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

  final String selectedTab;
  final int allCount;
  final int accessibleCount;
  final ValueChanged<String> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TabItem(
            label: 'All ($allCount)',
            isSelected: selectedTab == 'All',
            onTap: () => onTabSelected('All'),
          ),
          const SizedBox(width: 8),
          _TabItem(
            icon: Icons.accessible_rounded,
            label: 'Accessible ($accessibleCount)',
            isSelected: selectedTab == 'Accessible',
            onTap: () => onTabSelected('Accessible'),
          ),
          const SizedBox(width: 8),
          _TabItem(
            icon: Icons.flash_on_rounded,
            label: 'Fastest',
            isSelected: selectedTab == 'Fastest',
            onTap: () => onTabSelected('Fastest'),
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
    final hasRamp = rawBus?.wheelchairAccessible == true;
    final hasLowFloor = rawBus?.lowFloor == true;

    // LMT Go Status Pill Color (WCAG AA/AAA compliant contrast)
    final (statusBg, statusFg) = switch (route.liveStatusLabel.toLowerCase()) {
      'ongoing' => (
        isHighContrast ? const Color(0xFF003833) : const Color(0xFFE8F5E9),
        isHighContrast ? Colors.white : const Color(0xFF1B5E20),
      ),
      'approaching' => (
        isHighContrast ? const Color(0xFF001F3F) : const Color(0xFFE3F2FD),
        isHighContrast ? Colors.white : const Color(0xFF0D47A1),
      ),
      'delayed' => (
        isHighContrast ? const Color(0xFF8B0000) : const Color(0xFFFFEBEE),
        isHighContrast ? Colors.white : const Color(0xFFB71C1C),
      ),
      _ => (
        isHighContrast ? const Color(0xFF1A1A1A) : AppColors.surfaceContainer,
        isHighContrast ? Colors.white : AppColors.onSurfaceVariant,
      ),
    };

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

                        // Live Status Pill (Ongoing / Scheduled / Delayed)
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
                                route.liveStatusLabel,
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
                  Text(
                    'LKR ${route.estimatedPriceLkr}',
                    style: TextStyle(
                      fontSize: hasLargeTargets ? 19 : 17,
                      fontWeight: FontWeight.w800,
                      color: isHighContrast ? Colors.black : AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

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
                          'Departs at',
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
                          'Arrives at',
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
                    if (route.isLive) _LiveTripBadge(busId: route.busId),
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

class _LiveTripBadge extends StatelessWidget {
  const _LiveTripBadge({required this.busId});

  final String busId;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    return StreamBuilder<TripModel?>(
      stream: TripService().watchActiveTripForBus(busId),
      builder: (context, snapshot) {
        final trip = snapshot.data;
        if (trip == null || !trip.isInProgress) return const SizedBox.shrink();

        final depTime = trip.actualDepartureTime ?? trip.createdAt;
        final elapsedMinutes = DateTime.now()
            .difference(depTime)
            .inMinutes
            .clamp(0, 999);
        final label = elapsedMinutes == 0
            ? 'Departed now'
            : '$elapsedMinutes m ago';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isHighContrast
                ? Colors.white
                : Colors.green.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isHighContrast ? Colors.black : Colors.green.shade600,
              width: isHighContrast ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_bus_filled,
                size: 14,
                color: isHighContrast ? Colors.black : Colors.green.shade800,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isHighContrast ? Colors.black : Colors.green.shade900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
