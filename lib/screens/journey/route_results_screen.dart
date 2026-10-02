import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/time_utils.dart';
import '../../data/seed_data.dart';
import '../../logic/bus_matcher.dart';
import '../../logic/status_logic.dart';
import '../../models/bus.dart';
import '../../models/bus_route.dart';
import '../../models/report.dart';
import '../../models/station.dart';
import '../../models/trip_model.dart';
import '../../services/firestore_service.dart';
import '../../services/trip_service.dart';
import 'live_journey_screen.dart';

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
}

enum AccessibilityStatus { accessible, partial, notAccessible }

/// Route Results screen — LMT Go styled available bus cards with accessibility-first enhancements.
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
  String _selectedFilterTab = 'All'; // 'All', 'Accessible', 'Fastest'

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

  void _onSelectRoute(RouteResultItem route) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveJourneyScreen(
          origin: widget.origin,
          destination: widget.destination,
          route: route,
          busId: route.busId,
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

  int _calculateEstimatedPrice(int durationMinutes, int stopsCount) {
    // Authentic Sri Lankan bus transit fare calculation:
    // Base fare: LKR 35 + ~LKR 2.2 per minute + ~LKR 5 per intermediate stop
    final price = 35 + (durationMinutes * 2.2) + (stopsCount * 4);
    // Round to nearest 5 or 10 LKR
    return ((price / 5).round() * 5).clamp(40, 450);
  }

  List<RouteResultItem> _buildAndFilterRouteItems(
    List<Report> activeReports, {
    List<Bus>? buses,
  }) {
    final busesToMatch = (buses != null && buses.isNotEmpty) ? buses : _allBuses;

    // 1. Direct bus matching
    var matchedBuses = BusMatcher.findDirectBuses(
      busesToMatch,
      widget.fromStationId,
      widget.toStationId,
    );

    // Filter by user's initial search query requirements
    if (widget.wheelchairAccessRequired) {
      matchedBuses = matchedBuses.where((bus) => bus.wheelchairAccessible).toList();
    }
    if (widget.stepFreeOnly) {
      matchedBuses = matchedBuses.where((bus) => bus.lowFloor).toList();
    }

    final now = DateTime.now();
    final todayBase = DateTime(now.year, now.month, now.day);

    // 2. Compute status & reasons
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

      // Determine scheduled departure at the passenger's boarding station
      final fromIdx = bus.stops.indexWhere((s) =>
          s.toLowerCase() == widget.fromStationId.toLowerCase() ||
          (_stationsMap[s]?.name.toLowerCase() == widget.fromStationId.toLowerCase()) ||
          (_stationsMap[s]?.name.toLowerCase() == widget.origin.toLowerCase()));
      final targetIdx = fromIdx != -1 ? fromIdx : 0;
      final stopTimeStr = bus.getScheduledTimeForStop(targetIdx);

      var nextDepDateTime = TimeUtils.parseTimeStringToDateTime(stopTimeStr, todayBase);
      bool isTomorrow = false;
      if (nextDepDateTime.isBefore(now.subtract(const Duration(minutes: 10)))) {
        nextDepDateTime = nextDepDateTime.add(const Duration(days: 1));
        isTomorrow = true;
      }

      final diffMins = nextDepDateTime.difference(now).inMinutes;

      final String scheduledDepartureDisplay;
      final String etaLabelDisplay;
      if (isTomorrow) {
        scheduledDepartureDisplay = 'Tomorrow, $stopTimeStr';
        etaLabelDisplay = 'Tomorrow at $stopTimeStr';
      } else {
        if (diffMins <= 1 && diffMins >= 0) {
          scheduledDepartureDisplay = '$stopTimeStr (Now)';
          etaLabelDisplay = 'Arriving now • $stopTimeStr';
        } else if (diffMins < 60) {
          scheduledDepartureDisplay = '$stopTimeStr (in ${diffMins}m)';
          etaLabelDisplay = 'Departs in $diffMins mins • Today, $stopTimeStr';
        } else {
          scheduledDepartureDisplay = 'Today, $stopTimeStr';
          etaLabelDisplay = 'Today at $stopTimeStr';
        }
      }

      final durationMinutes = (bus.stops.length * 6).clamp(12, 110);
      final arrivalDateTime = nextDepDateTime.add(Duration(minutes: durationMinutes));
      final departureTimeFormatted = TimeUtils.formatTimeString(nextDepDateTime);
      final arrivalTimeFormatted = TimeUtils.formatTimeString(arrivalDateTime);

      // Determine live operational status label
      final String liveStatus;
      final bool isBusLive;
      if (diffMins <= 5 && diffMins >= -30) {
        liveStatus = 'Ongoing';
        isBusLive = true;
      } else if (diffMins < 20 && diffMins > 5) {
        liveStatus = 'Approaching';
        isBusLive = true;
      } else if (statusResult.status == AccessibilityStatus.partial ||
          statusResult.reasons.any((r) => r.toLowerCase().contains('delay'))) {
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

      final fromName = _stationsMap[widget.fromStationId]?.name ?? widget.origin;
      final toName = _stationsMap[widget.toStationId]?.name ?? widget.destination;

      final estimatedPrice = _calculateEstimatedPrice(durationMinutes, bus.stops.length);

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
        intermediateStops: bus.stops,
        recommended: statusResult.status == AccessibilityStatus.accessible && bus.wheelchairAccessible,
        rawBus: bus,
        statusResult: statusResult,
        nextDepartureDateTime: nextDepDateTime,
      );
    }).toList();

    // 3. Filter by Tab ('All', 'Accessible', 'Fastest')
    var filtered = items;
    if (_selectedFilterTab == 'Accessible') {
      filtered = filtered
          .where((r) => r.rawBus?.wheelchairAccessible == true || r.rawBus?.hasRamp == true)
          .toList();
    }

    // 4. Sort
    filtered.sort((a, b) {
      if (_selectedFilterTab == 'Fastest') {
        return a.durationMinutes.compareTo(b.durationMinutes);
      }

      // Default: Earliest upcoming bus first
      final timeA = a.nextDepartureDateTime ?? DateTime.now();
      final timeB = b.nextDepartureDateTime ?? DateTime.now();
      final timeComp = timeA.compareTo(timeB);
      if (timeComp != 0) {
        return timeComp;
      }

      // Secondary: Accessibility priority
      final rankA = _statusRank(a.accessibilityStatus);
      final rankB = _statusRank(b.accessibilityStatus);
      return rankA.compareTo(rankB);
    });

    return filtered;
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
                          final reports = snapshot.data ?? SeedData.getSampleReports();
                          final routes = _buildAndFilterRouteItems(
                            reports,
                            buses: buses,
                          );

                          final totalAvailable = BusMatcher.findDirectBuses(
                            buses,
                            widget.fromStationId,
                            widget.toStationId,
                          ).length;

                          final accessibleCount = BusMatcher.findDirectBuses(
                            buses,
                            widget.fromStationId,
                            widget.toStationId,
                          ).where((b) => b.wheelchairAccessible || b.hasRamp).length;

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
                                      // Clean Trip Corridor Header
                                      _TripSummaryCard(
                                        origin: widget.origin,
                                        destination: widget.destination,
                                        matchedCount: routes.length,
                                        selectedDate: widget.selectedDate,
                                      ),
                                      const SizedBox(height: 14),

                                      // LMT Go Style Accessible Filter Tabs
                                      _LmtGoFilterTabs(
                                        selectedTab: _selectedFilterTab,
                                        allCount: totalAvailable,
                                        accessibleCount: accessibleCount,
                                        onTabSelected: (tab) {
                                          setState(() => _selectedFilterTab = tab);
                                        },
                                      ),
                                      const SizedBox(height: 16),

                                      // Route Results Cards or Empty State
                                      if (routes.isEmpty) ...[
                                        _buildEmptyState(),
                                      ] else ...[
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.directions_bus_rounded,
                                              size: 18,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Available Buses (${routes.length})',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        ...routes.map(
                                          (route) => Padding(
                                            padding: const EdgeInsets.only(bottom: 14),
                                            child: _LmtGoRouteCard(
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
      bottomNavigationBar: null,
    );
  }

  Widget _buildEmptyState() {
    final isFiltered = _selectedFilterTab == 'Accessible' ||
        widget.wheelchairAccessRequired ||
        widget.stepFreeOnly;

    final emptyTitle = isFiltered
        ? 'No Accessible Buses Found'
        : 'No Direct Buses Found';

    final emptyDesc = isFiltered
        ? 'No buses with wheelchair ramps or step-free entries are available for this corridor right now. Try selecting the "All Buses" tab.'
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
    return Material(
      color: AppColors.surfaceContainerLow,
      elevation: 1,
      shadowColor: AppColors.onSurface.withValues(alpha: 0.08),
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
                  color: AppColors.primary,
                  tooltip: 'Back',
                  iconSize: 26,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
                const SizedBox(width: 6),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Buses',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Select a bus to track live journey',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
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
  });

  final String origin;
  final String destination;
  final int matchedCount;
  final DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    final dateStr = TimeUtils.formatDateString(selectedDate ?? DateTime.now());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
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
          // Origin to Destination Row
          Row(
            children: [
              const Icon(Icons.trip_origin_rounded, size: 16, color: AppColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  origin,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
              ),
              const Icon(Icons.location_on_rounded, size: 16, color: AppColors.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  destination,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.surfaceVariant),
          const SizedBox(height: 8),
          // Info row: Date & status
          Row(
            children: [
              const Icon(Icons.event_note_rounded, size: 15, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$matchedCount buses available',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.primaryContainer : AppColors.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
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
                size: 16,
                color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
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
  const _LmtGoRouteCard({
    required this.route,
    required this.onTap,
  });

  final RouteResultItem route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rawBus = route.rawBus;
    final hasRamp = rawBus?.wheelchairAccessible == true || rawBus?.hasRamp == true;
    final hasLowFloor = rawBus?.lowFloor == true;

    // LMT Go Status Pill Color (WCAG AA/AAA compliant contrast)
    final (statusBg, statusFg) = switch (route.liveStatusLabel.toLowerCase()) {
      'ongoing' => (const Color(0xFFE8F5E9), const Color(0xFF1B5E20)), // 6.7:1 on #E8F5E9
      'approaching' => (const Color(0xFFE3F2FD), const Color(0xFF0D47A1)), // 8.2:1 on #E3F2FD
      'delayed' => (const Color(0xFFFFEBEE), const Color(0xFFB71C1C)), // 7.0:1 on #FFEBEE
      _ => (AppColors.surfaceContainer, AppColors.onSurfaceVariant),
    };

    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: AppColors.onSurface.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: route.recommended ? AppColors.secondary : AppColors.surfaceVariant,
              width: route.recommended ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Row: Route Badge (like LMT Go's red "CM01"), Bus Number, Status Pill, and Bold Price
              Row(
                children: [
                  // Prominent Route Code Badge (LMT Go style red badge)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC62828), // High-visibility crimson
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      route.routeNo ?? 'Route',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Bus Plate Number
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.directions_bus, size: 14, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          route.busNo ?? route.busId,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Live Status Pill (Ongoing / Scheduled / Delayed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusFg,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          route.liveStatusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: statusFg,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Estimated Price in LKR (Right-aligned, bold)
                  Text(
                    'LKR ${route.estimatedPriceLkr}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Departs at
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Departs at',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          route.departureTimeStr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
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
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(
                                    thickness: 1.5,
                                    color: AppColors.outlineVariant,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: AppColors.primary,
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
                        const Text(
                          'Arrives at',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          route.arrivalTimeStr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
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
                    if (hasRamp) ...[
                      _MiniFeatureBadge(
                        icon: Icons.accessible_rounded,
                        label: 'Ramp Available',
                        color: AppColors.secondary,
                        bgColor: AppColors.secondaryContainer.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (hasLowFloor) ...[
                      const _MiniFeatureBadge(
                        icon: Icons.elevator_outlined,
                        label: 'Low Floor',
                        color: AppColors.primary,
                        bgColor: AppColors.primaryFixed,
                      ),
                      const SizedBox(width: 6),
                    ],
                    _MiniFeatureBadge(
                      icon: Icons.people_outline_rounded,
                      label: '${route.crowdLevel} Crowd',
                      color: AppColors.onSurfaceVariant,
                      bgColor: AppColors.surfaceContainer,
                    ),
                    const SizedBox(width: 6),
                    if (route.isLive)
                      _LiveTripBadge(busId: route.busId),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
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
    return StreamBuilder<TripModel?>(
      stream: TripService().watchActiveTripForBus(busId),
      builder: (context, snapshot) {
        final trip = snapshot.data;
        if (trip == null || !trip.isInProgress) return const SizedBox.shrink();

        final depTime = trip.actualDepartureTime ?? trip.createdAt;
        final elapsedMinutes = DateTime.now().difference(depTime).inMinutes.clamp(0, 999);
        final label = elapsedMinutes == 0 ? 'Departed now' : '$elapsedMinutes m ago';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade600, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_bus_filled, size: 14, color: Colors.green.shade800),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
