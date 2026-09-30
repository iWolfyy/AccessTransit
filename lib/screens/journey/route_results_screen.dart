import 'package:flutter/material.dart';

import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../data/seed_data.dart';
import '../../logic/bus_matcher.dart';
import '../../logic/status_logic.dart';
import '../../models/bus.dart';
import '../../models/bus_location_model.dart';
import '../../models/bus_route.dart';
import '../../models/enums/bus_status.dart';
import '../../models/report.dart';
import '../../models/station.dart';
import '../../services/firestore_service.dart';
import '../../services/live_bus_service.dart';
import '../../services/trip_service.dart';
import '../../models/trip_model.dart';
import '../../core/utils/time_utils.dart';
import 'route_details_screen.dart';


/// Route result item used for passenger route selection.
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
    this.origin = 'Colombo',
    this.destination = 'Kandy',
    this.intermediateStops = const [],
    this.recommended = false,
    this.rawBus,
    this.statusResult,
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
  final String origin;
  final String destination;
  final List<String> intermediateStops;
  final bool recommended;
  final Bus? rawBus;
  final BusStatusResult? statusResult;
}

enum AccessibilityStatus { accessible, partial, notAccessible }

/// Route Results screen — list of routes with ETA, crowd, accessibility, safety.
class RouteResultsScreen extends StatefulWidget {
  const RouteResultsScreen({
    super.key,
    this.fromStationId = 'st_fort',
    this.toStationId = 'st_kottawa',
    this.origin = 'Colombo Fort Station',
    this.destination = 'Kottawa Highway Bus Station',
    this.selectedDate,
    this.wheelchairAccessRequired = false,
    this.stepFreeOnly = false,
    this.minimizeWalking = false,
  });

  final String fromStationId;
  final String toStationId;
  final String origin;
  final String destination;
  final DateTime? selectedDate;
  final bool wheelchairAccessRequired;
  final bool stepFreeOnly;
  final bool minimizeWalking;

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
  String _sortBy = 'Best';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final fetchedBuses = await _firestoreService.getBuses();
      final fetchedStations = await _firestoreService.getStations();
      final fetchedRoutes = await _firestoreService.getRoutes();

      final buses = fetchedBuses.isNotEmpty ? fetchedBuses : SeedData.sampleBuses;
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

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$feature will be available soon.')),
      );
  }

  void _onSelectRoute(RouteResultItem route) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteDetailsScreen(
          origin: widget.origin,
          destination: widget.destination,
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
        return 2; // Not accessible third
    }
  }

  int _crowdRank(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return 0;
      case 'medium':
        return 1;
      default:
        return 2;
    }
  }

  List<RouteResultItem> _buildAndSortRouteItems(
    List<Report> activeReports, {
    List<Bus>? buses,
  }) {
    final busesToMatch = (buses != null && buses.isNotEmpty) ? buses : _allBuses;

    // 1. Direct bus matching (AC-72)
    var matchedBuses = BusMatcher.findDirectBuses(
      busesToMatch,
      widget.fromStationId,
      widget.toStationId,
    );

    // 2. Filter by user's accessibility requirements
    if (widget.wheelchairAccessRequired) {
      matchedBuses = matchedBuses.where((bus) => bus.wheelchairAccessible).toList();
    }
    if (widget.stepFreeOnly) {
      matchedBuses = matchedBuses.where((bus) => bus.lowFloor).toList();
    }

    // 3. Compute status & reasons (AC-74)
    final List<RouteResultItem> items = matchedBuses.map((bus) {
      final statusResult = StatusLogic.getBusStatus(
        bus,
        activeReports,
        stationsMap: _stationsMap,
      );

      final routeObj = _routesMap[bus.routeId] ??
          _routesMap.values.cast<BusRoute?>().firstWhere(
                (r) => r?.routeNo == bus.routeNo,
                orElse: () => null,
              );

      final routeName = routeObj?.routeName ?? 'Route ${bus.routeNo}';
      final displayBusNo = bus.displayBusNo;
      final departureTime = bus.effectiveDepartureTime;

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

      final fromName = _stationsMap[widget.fromStationId]?.name ?? widget.origin;
      final toName = _stationsMap[widget.toStationId]?.name ?? widget.destination;

      return RouteResultItem(
        id: bus.id,
        title: 'Route ${bus.routeNo} • $displayBusNo',
        busNo: displayBusNo,
        routeNo: bus.routeNo,
        routeName: routeName,
        scheduledDeparture: departureTime,
        durationMinutes: (bus.stops.length * 6).clamp(10, 120),
        etaLabel: 'Departs at $departureTime',
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
        intermediateStops: bus.stops,
        recommended: statusResult.status == AccessibilityStatus.accessible && bus.wheelchairAccessible,
        rawBus: bus,
        statusResult: statusResult,
      );
    }).toList();

    // 4. Sort: Safe first, then Warning, then Not accessible (AC-73)
    items.sort((a, b) {
      final rankA = _statusRank(a.accessibilityStatus);
      final rankB = _statusRank(b.accessibilityStatus);
      if (rankA != rankB) {
        return rankA.compareTo(rankB);
      }

      switch (_sortBy) {
        case 'Fastest':
          return a.durationMinutes.compareTo(b.durationMinutes);
        case 'Least crowded':
          return _crowdRank(a.crowdLevel).compareTo(_crowdRank(b.crowdLevel));
        case 'Best':
        default:
          return a.durationMinutes.compareTo(b.durationMinutes);
      }
    });

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _TopBar(
            onBack: () => Navigator.of(context).maybePop(),
            onFilter: () => _showComingSoon('Filters'),
          ),
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
                          final reports =
                              snapshot.data ?? SeedData.getSampleReports();
                          final routes = _buildAndSortRouteItems(
                            reports,
                            buses: buses,
                          );

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
                                  _TripSummaryCard(
                                    origin: widget.origin,
                                    destination: widget.destination,
                                    matchedCount: routes.length,
                                    totalCount: routes.length,
                                    selectedDate: widget.selectedDate,
                                    wheelchairRequired: widget.wheelchairAccessRequired,
                                    stepFreeOnly: widget.stepFreeOnly,
                                  ),
                                  const SizedBox(height: 16),
                                  _SortChips(
                                    selected: _sortBy,
                                    onSelected: (value) =>
                                        setState(() => _sortBy = value),
                                  ),
                                  const SizedBox(height: 16),

                                  if (routes.isEmpty) ...[
                                    _buildEmptyState(),
                                  ] else ...[
                                    _SectionLabel(
                                      label:
                                          'Direct Routes Found (${routes.length})',
                                      icon: Icons.check_circle_outline,
                                      color: AppColors.secondary,
                                    ),
                                    const SizedBox(height: 8),
                                    ...routes.map(
                                      (route) => Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: _RouteCard(
                                          route: route,
                                          onTap: () => _onSelectRoute(route),
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
      bottomNavigationBar: isDesktop
          ? null
          : _ResultsBottomNav(
              onNavTap: (label) {
                AppNavigation.handleBottomNav(
                  context,
                  label,
                  currentTab: 'Plan',
                  onUnsupported: _showComingSoon,
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    final isFiltered = widget.wheelchairAccessRequired || widget.stepFreeOnly;
    final emptyTitle = isFiltered
        ? 'No Accessible Buses Found'
        : 'No Direct Buses Found';
    final emptyDesc = isFiltered
        ? 'No buses matching your active accessibility criteria (e.g. wheelchair ramp) were found connecting ${widget.origin} to ${widget.destination}. Try loosening your filters or selecting a different departure time.'
        : 'There are currently no direct bus routes connecting ${widget.origin} to ${widget.destination}.';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Icon(
              isFiltered ? Icons.accessible_forward : Icons.directions_bus_outlined,
              size: 56,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              emptyTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emptyDesc,
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
  const _TopBar({required this.onBack, required this.onFilter});

  final VoidCallback onBack;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLow,
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
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.primary,
                  tooltip: 'Back',
                ),
                const Expanded(
                  child: Text(
                    'Route Results',
                    style: TextStyle(
                      fontSize: 22,
                      height: 28 / 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onFilter,
                  icon: const Icon(Icons.tune_rounded),
                  color: AppColors.primary,
                  tooltip: 'Filters',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TripSummaryCard extends StatelessWidget {
  const _TripSummaryCard({
    required this.origin,
    required this.destination,
    required this.matchedCount,
    required this.totalCount,
    this.selectedDate,
    this.wheelchairRequired = false,
    this.stepFreeOnly = false,
  });

  final String origin;
  final String destination;
  final int matchedCount;
  final int totalCount;
  final DateTime? selectedDate;
  final bool wheelchairRequired;
  final bool stepFreeOnly;

  @override
  Widget build(BuildContext context) {
    final summaryText = matchedCount > 0
        ? '$matchedCount bus${matchedCount == 1 ? '' : 'es'} matching your criteria'
        : 'No matching buses found';

    final dateStr = TimeUtils.formatDateString(selectedDate ?? DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.onSecondaryContainer),
                    const SizedBox(width: 6),
                    Text(
                      'Date: $dateStr',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              if (wheelchairRequired)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.accessible, size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Wheelchair Access Required',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              if (stepFreeOnly)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stairs, size: 14, color: AppColors.tertiary),
                      SizedBox(width: 6),
                      Text(
                        'Step-Free Only',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tertiary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.my_location,
                size: 18,
                color: AppColors.primaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  origin,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: SizedBox(
              height: 12,
              child: VerticalDivider(
                width: 18,
                thickness: 1,
                color: AppColors.outlineVariant,
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  destination,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 24 / 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summaryText,
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              color: matchedCount > 0
                  ? AppColors.secondary
                  : AppColors.onSurfaceVariant,
              fontWeight:
                  matchedCount > 0 ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _SortChips extends StatelessWidget {
  const _SortChips({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  static const _options = ['Best', 'Fastest', 'Least crowded'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in _options) ...[
            FilterChip(
              label: Text(option),
              selected: selected == option,
              onSelected: (_) => onSelected(option),
              selectedColor: AppColors.primaryFixed,
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected == option
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
              side: BorderSide(
                color: selected == option
                    ? AppColors.primaryContainer
                    : AppColors.outlineVariant,
              ),
              backgroundColor: AppColors.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            height: 20 / 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.onTap,
  }) : dimmed = false;

  final RouteResultItem route;
  final VoidCallback onTap;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: route.recommended
                  ? AppColors.secondary
                  : AppColors.surfaceVariant,
              width: route.recommended ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Route Number & Bus Plate Number Pills
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Route ${route.routeNo ?? route.rawBus?.routeNo ?? ""}',
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.directions_bus, size: 14, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          route.busNo ?? route.rawBus?.displayBusNo ?? route.busId,
                          style: const TextStyle(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (route.recommended) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Recommended',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // 2. Title & Departure Time Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.routeName ?? route.title,
                          style: const TextStyle(
                            fontSize: 17,
                            height: 22 / 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          route.summary,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 18 / 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            route.scheduledDeparture ?? '${route.durationMinutes} min',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '~${route.durationMinutes} min trip',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3. Accessibility & Telemetry Badges
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (route.rawBus?.wheelchairAccessible == true)
                    const _InfoChip(
                      icon: Icons.accessible,
                      label: 'Wheelchair Ready',
                    ),
                  if (route.rawBus?.lowFloor == true)
                    const _InfoChip(
                      icon: Icons.stairs,
                      label: 'Low-Floor Entry',
                    ),
                  _AccessibilityChip(
                    status: route.accessibilityStatus,
                    label: route.accessibilityLabel,
                  ),
                  _InfoChip(
                    icon: Icons.groups_outlined,
                    label: 'Crowd: ${route.crowdLevel}',
                  ),
                  _LiveTripBadge(busId: route.busId),
                  _LiveTrackingBadge(busId: route.busId),
                ],
              ),
              const SizedBox(height: 12),

              // 4. Action Button
              Row(
                children: [
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: onTap,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text(
                      'Select Bus',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return dimmed ? Opacity(opacity: 0.55, child: card) : card;
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessibilityChip extends StatelessWidget {
  const _AccessibilityChip({required this.status, required this.label});

  final AccessibilityStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = switch (status) {
      AccessibilityStatus.accessible => (
        Icons.check_circle,
        AppColors.secondaryContainer,
        AppColors.onSecondaryContainer,
      ),
      AccessibilityStatus.partial => (
        Icons.warning_amber_rounded,
        const Color(0xFFFFDBCA),
        AppColors.tertiary,
      ),
      AccessibilityStatus.notAccessible => (
        Icons.cancel,
        AppColors.errorContainer,
        AppColors.onErrorContainer,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsBottomNav extends StatelessWidget {
  const _ResultsBottomNav({required this.onNavTap});

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

class _LiveTrackingBadge extends StatelessWidget {
  const _LiveTrackingBadge({required this.busId});

  final String busId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BusLocationModel?>(
      stream: LiveBusService().listenToLiveLocation(busId),
      builder: (context, snapshot) {
        final bus = snapshot.data;
        final isBroadcasting =
            bus != null && bus.isBroadcasting && bus.status == BusStatus.active;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isBroadcasting
                ? AppColors.secondaryContainer
                : AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isBroadcasting ? Icons.sensors_rounded : Icons.schedule_rounded,
                size: 16,
                color: isBroadcasting
                    ? AppColors.onSecondaryContainer
                    : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                isBroadcasting ? 'Live GPS Active' : 'Scheduled',
                style: TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w600,
                  color: isBroadcasting
                      ? AppColors.onSecondaryContainer
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LiveTripBadge extends StatelessWidget {
  const _LiveTripBadge({required this.busId});

  final String busId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TripModel?>(
      stream: TripService().watchActiveTripForBus(busId),
      builder: (context, snapshot) {
        final trip = snapshot.data;
        if (trip == null || !trip.isInProgress) return const SizedBox.shrink();

        final depTime = trip.actualDepartureTime ?? trip.createdAt;
        final elapsedMinutes = DateTime.now().difference(depTime).inMinutes.clamp(0, 999);
        final label = elapsedMinutes == 0 ? 'Departed just now' : 'Departed $elapsedMinutes min ago';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.green.shade600, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_bus_filled, size: 16, color: Colors.green.shade700),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

