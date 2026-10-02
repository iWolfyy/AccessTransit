import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/seed_data.dart';
import '../../models/bus.dart';
import '../../models/bus_route.dart';
import '../../models/report.dart';
import '../../models/station.dart';
import '../../services/firestore_service.dart';
import 'report_submitted_screen.dart';

/// Target category for the report: either on a bus or at a bus stop / station.
enum ReportTargetType { bus, station }

/// Crowding level options tailored for accessible transit passengers.
enum CrowdingLevel {
  low('Low Crowd', 'Plenty of room & wheelchair bay free', Icons.sentiment_satisfied_alt_rounded, AppColors.success),
  medium('Moderate', 'Seats full, standing room available', Icons.sentiment_neutral_rounded, Color(0xFFF57F17)),
  high('Crowded / Packed', 'Wheelchair space or aisle blocked', Icons.sentiment_very_dissatisfied_rounded, AppColors.error);

  const CrowdingLevel(this.label, this.subtitle, this.icon, this.color);
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
}

/// A specific accessibility issue or condition option represented as a visual card.
class ReportIssueOption {
  const ReportIssueOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.category,
    required this.severity,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String category;
  final String severity;
}

/// A category grouping related accessibility issue options.
class ReportCategoryDef {
  const ReportCategoryDef({
    required this.id,
    required this.title,
    required this.icon,
    required this.options,
  });

  final String id;
  final String title;
  final IconData icon;
  final List<ReportIssueOption> options;
}

/// Accessible Community Report screen matching LMT Go guidelines.
///
/// Organized cleanly with:
/// 1. Bus Route selection
/// 2. Target Choice (On a Bus vs At a Bus Stop)
/// 3. Context-aware Crowding Level + Category Tabs & Sub-Card Grid
/// 4. Optional note and 1-tap submission (+10 Community Points)
class ReportConditionScreen extends StatefulWidget {
  const ReportConditionScreen({
    super.key,
    this.targetType = 'station',
    this.targetId = '',
    this.initialLocation = '',
  });

  final String targetType;
  final String targetId;
  final String initialLocation;

  @override
  State<ReportConditionScreen> createState() => _ReportConditionScreenState();
}

class _ReportConditionScreenState extends State<ReportConditionScreen> {
  static const double _desktopBreakpoint = 768;
  static String? _cachedGuestUserId;

  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _noteController = TextEditingController();

  // Data loaded from Firestore / SeedData
  List<BusRoute> _allRoutes = [];
  List<Station> _allStations = [];
  List<Bus> _allBuses = [];
  bool _isLoadingData = true;

  // Selection states
  BusRoute? _selectedRoute;
  ReportTargetType _targetType = ReportTargetType.bus;
  Bus? _selectedBus;
  Station? _selectedStation;

  // Crowding level (for Bus)
  CrowdingLevel _selectedCrowding = CrowdingLevel.medium;

  // Active Category indices
  int _activeBusCategoryIndex = 0;
  int _activeStationCategoryIndex = 0;

  // Selected Option
  late ReportIssueOption _selectedOption;

  // Submission state
  bool _isSubmitting = false;

  // ── BUS CATEGORIES & SUB-CARDS ─────────────────────────────────────────────
  static final List<ReportCategoryDef> _busCategories = [
    const ReportCategoryDef(
      id: 'ramp_bay',
      title: 'Ramp & Bay',
      icon: Icons.accessible_rounded,
      options: [
        ReportIssueOption(
          id: 'ramp_working',
          title: 'Ramp Working',
          subtitle: 'Driver assisted & deployed ramp',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          category: 'rampAccess',
          severity: 'minor',
        ),
        ReportIssueOption(
          id: 'ramp_broken',
          title: 'Ramp Broken',
          subtitle: 'Motor jammed or ramp broken',
          icon: Icons.error_rounded,
          color: AppColors.error,
          category: 'rampAccess',
          severity: 'major',
        ),
        ReportIssueOption(
          id: 'driver_refused',
          title: 'Ramp Denied',
          subtitle: 'Driver did not lower or deploy',
          icon: Icons.cancel_rounded,
          color: AppColors.error,
          category: 'driverAssistanceDenied',
          severity: 'major',
        ),
        ReportIssueOption(
          id: 'bay_blocked',
          title: 'Bay Blocked',
          subtitle: 'Blocked by bags or passengers',
          icon: Icons.block_rounded,
          color: Color(0xFFF57F17),
          category: 'crowding',
          severity: 'moderate',
        ),
      ],
    ),
    const ReportCategoryDef(
      id: 'priority_seats',
      title: 'Priority Seats',
      icon: Icons.airline_seat_recline_normal_rounded,
      options: [
        ReportIssueOption(
          id: 'seats_available',
          title: 'Seats Free',
          subtitle: 'Elderly / disabled seats free',
          icon: Icons.event_seat_rounded,
          color: AppColors.success,
          category: 'crowding',
          severity: 'minor',
        ),
        ReportIssueOption(
          id: 'seats_occupied',
          title: 'Seats Occupied',
          subtitle: 'Others not giving up seats',
          icon: Icons.person_off_rounded,
          color: Color(0xFFF57F17),
          category: 'crowding',
          severity: 'moderate',
        ),
        ReportIssueOption(
          id: 'seat_broken',
          title: 'Seat Broken',
          subtitle: 'Damaged or loose seating',
          icon: Icons.warning_rounded,
          color: AppColors.error,
          category: 'safetyHazard',
          severity: 'major',
        ),
      ],
    ),
    const ReportCategoryDef(
      id: 'safety_hygiene',
      title: 'Safety & Clean',
      icon: Icons.security_rounded,
      options: [
        ReportIssueOption(
          id: 'clean_vehicle',
          title: 'Clean & Safe',
          subtitle: 'Vehicle well-maintained',
          icon: Icons.verified_rounded,
          color: AppColors.success,
          category: 'cleanliness',
          severity: 'minor',
        ),
        ReportIssueOption(
          id: 'dirty_vehicle',
          title: 'Dirty / Odor',
          subtitle: 'Spill or unpleasant smell',
          icon: Icons.cleaning_services_rounded,
          color: Color(0xFFF57F17),
          category: 'cleanliness',
          severity: 'minor',
        ),
        ReportIssueOption(
          id: 'broken_grab_rail',
          title: 'Rail Broken',
          subtitle: 'Grab rails or straps loose',
          icon: Icons.handyman_rounded,
          color: AppColors.error,
          category: 'safetyHazard',
          severity: 'major',
        ),
        ReportIssueOption(
          id: 'reckless_driving',
          title: 'Reckless Driving',
          subtitle: 'Sudden jerks, unsafe ride',
          icon: Icons.speed_rounded,
          color: AppColors.error,
          category: 'safetyHazard',
          severity: 'major',
        ),
      ],
    ),
  ];

  // ── STATION / STOP CATEGORIES & SUB-CARDS ──────────────────────────────────
  static final List<ReportCategoryDef> _stationCategories = [
    const ReportCategoryDef(
      id: 'elevator_lift',
      title: 'Elevator',
      icon: Icons.elevator_rounded,
      options: [
        ReportIssueOption(
          id: 'elevator_ok',
          title: 'Elevator Working',
          subtitle: 'Operating smoothly & accessible',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          category: 'elevatorOut',
          severity: 'minor',
        ),
        ReportIssueOption(
          id: 'elevator_out',
          title: 'Out of Service',
          subtitle: 'Elevator shut down or repair',
          icon: Icons.error_rounded,
          color: AppColors.error,
          category: 'elevatorOut',
          severity: 'major',
        ),
        ReportIssueOption(
          id: 'elevator_doors',
          title: 'Door / Button Fault',
          subtitle: 'Doors stuck or buttons broken',
          icon: Icons.warning_rounded,
          color: Color(0xFFF57F17),
          category: 'elevatorOut',
          severity: 'moderate',
        ),
      ],
    ),
    const ReportCategoryDef(
      id: 'ramp_pathway',
      title: 'Ramp & Path',
      icon: Icons.accessible_rounded,
      options: [
        ReportIssueOption(
          id: 'ramp_ok',
          title: 'Ramp Clear',
          subtitle: 'Smooth wheelchair slope',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          category: 'rampAccess',
          severity: 'minor',
        ),
        ReportIssueOption(
          id: 'ramp_blocked',
          title: 'Path Blocked',
          subtitle: 'Vendors or parked vehicles',
          icon: Icons.block_rounded,
          color: Color(0xFFF57F17),
          category: 'rampAccess',
          severity: 'moderate',
        ),
        ReportIssueOption(
          id: 'ramp_damaged',
          title: 'Damaged / Steep',
          subtitle: 'Pavement cracked or steep slope',
          icon: Icons.report_problem_rounded,
          color: AppColors.error,
          category: 'rampAccess',
          severity: 'major',
        ),
      ],
    ),
    const ReportCategoryDef(
      id: 'tactile_platform',
      title: 'Tactile Tiles',
      icon: Icons.blind_rounded,
      options: [
        ReportIssueOption(
          id: 'tactile_ok',
          title: 'Tiles Intact',
          subtitle: 'Guided tactile tiles clear',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          category: 'tactilePavingBlocked',
          severity: 'minor',
        ),
        ReportIssueOption(
          id: 'tactile_missing',
          title: 'Tiles Broken',
          subtitle: 'Loose tiles causing trip hazard',
          icon: Icons.warning_rounded,
          color: Color(0xFFF57F17),
          category: 'tactilePavingBlocked',
          severity: 'moderate',
        ),
        ReportIssueOption(
          id: 'unsafe_gap',
          title: 'Unsafe Edge Gap',
          subtitle: 'Excessive gap between curb & bus',
          icon: Icons.dangerous_rounded,
          color: AppColors.error,
          category: 'safetyHazard',
          severity: 'major',
        ),
      ],
    ),
    const ReportCategoryDef(
      id: 'shelter_lighting',
      title: 'Shelter & Light',
      icon: Icons.roofing_rounded,
      options: [
        ReportIssueOption(
          id: 'shelter_ok',
          title: 'Shelter Good',
          subtitle: 'Rain protection & seating intact',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          category: 'safetyHazard',
          severity: 'minor',
        ),
        ReportIssueOption(
          id: 'shelter_broken',
          title: 'Roof Damaged',
          subtitle: 'Damaged roof or broken benches',
          icon: Icons.umbrella_rounded,
          color: Color(0xFFF57F17),
          category: 'safetyHazard',
          severity: 'minor',
        ),
        ReportIssueOption(
          id: 'poor_lighting',
          title: 'Dark / Unsafe',
          subtitle: 'Poor night lighting in walkway',
          icon: Icons.lightbulb_outline_rounded,
          color: AppColors.error,
          category: 'safetyHazard',
          severity: 'major',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedOption = _busCategories[0].options[0];
    _loadInitialData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final routes = await _firestoreService.getRoutes();
      final stations = await _firestoreService.getStations();
      final buses = await _firestoreService.getBuses();

      if (!mounted) return;

      setState(() {
        _allRoutes = routes.isNotEmpty ? routes : SeedData.sampleRoutes;
        _allStations = stations.isNotEmpty ? stations : SeedData.colomboStations;
        _allBuses = buses.isNotEmpty ? buses : SeedData.sampleBuses;

        _setupInitialSelection();
        _isLoadingData = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _allRoutes = SeedData.sampleRoutes;
          _allStations = SeedData.colomboStations;
          _allBuses = SeedData.sampleBuses;
          _setupInitialSelection();
          _isLoadingData = false;
        });
      }
    }
  }

  void _setupInitialSelection() {
    if (_allRoutes.isNotEmpty) {
      _selectedRoute = _allRoutes.first;
    }

    if (widget.targetType.toLowerCase() == 'bus') {
      _targetType = ReportTargetType.bus;
      _selectedOption = _busCategories[0].options[0];
      if (widget.targetId.isNotEmpty) {
        _selectedBus = _allBuses.cast<Bus?>().firstWhere(
          (b) => b?.id == widget.targetId,
          orElse: () => null,
        );
      }
    } else {
      _targetType = ReportTargetType.station;
      _selectedOption = _stationCategories[0].options[0];
      if (widget.targetId.isNotEmpty || widget.initialLocation.isNotEmpty) {
        _selectedStation = _allStations.cast<Station?>().firstWhere(
          (s) =>
              s?.id == widget.targetId ||
              (widget.initialLocation.isNotEmpty &&
                  (s?.name.toLowerCase().contains(widget.initialLocation.toLowerCase()) ?? false)),
          orElse: () => null,
        );
      }
    }

    _refreshTargetsForRoute();
  }

  void _refreshTargetsForRoute() {
    if (_selectedRoute == null) return;

    final routeBuses = _getBusesForSelectedRoute();
    if (_selectedBus == null || !routeBuses.contains(_selectedBus)) {
      _selectedBus = routeBuses.isNotEmpty ? routeBuses.first : null;
    }

    final routeStations = _getStationsForSelectedRoute();
    if (_selectedStation == null || !routeStations.contains(_selectedStation)) {
      _selectedStation = routeStations.isNotEmpty ? routeStations.first : null;
    }
  }

  List<Bus> _getBusesForSelectedRoute() {
    if (_selectedRoute == null) return _allBuses;
    final filtered = _allBuses.where((b) {
      return b.routeId == _selectedRoute!.id || b.routeNo == _selectedRoute!.routeNo;
    }).toList();
    return filtered.isNotEmpty ? filtered : _allBuses;
  }

  List<Station> _getStationsForSelectedRoute() {
    if (_selectedRoute == null) return _allStations;
    if (_selectedRoute!.stops.isEmpty) return _allStations;
    final stopSet = _selectedRoute!.stops.toSet();
    final matched = _allStations.where((s) => stopSet.contains(s.id)).toList();
    return matched.isNotEmpty ? matched : _allStations;
  }

  String _getOrCreateUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid.isNotEmpty) {
      return user.uid;
    }
    _cachedGuestUserId ??= 'guest_user_${DateTime.now().millisecondsSinceEpoch}';
    return _cachedGuestUserId!;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitReport() async {
    final isBus = _targetType == ReportTargetType.bus;
    final targetId = isBus
        ? (_selectedBus?.id ?? 'bus_generic')
        : (_selectedStation?.id ?? 'station_generic');
    final targetName = isBus
        ? (_selectedBus != null
            ? '${_selectedBus!.busNo} (Route ${_selectedRoute?.routeNo ?? _selectedBus!.routeNo})'
            : 'Bus Route ${_selectedRoute?.routeNo ?? ""}')
        : (_selectedStation?.name ?? 'Station on Route ${_selectedRoute?.routeNo ?? ""}');

    setState(() => _isSubmitting = true);

    try {
      final userId = _getOrCreateUserId();

      // Rate limit check: 15-minute window
      final isRateLimited = await _firestoreService.checkRateLimit(
        userId,
        targetId,
        thresholdMinutes: 15,
      );

      if (isRateLimited && mounted) {
        _showSnack(
          'You already submitted a report for this target recently. Please wait a few minutes.',
        );
        setState(() => _isSubmitting = false);
        return;
      }

      String problemType;
      if (isBus) {
        problemType = 'Crowding: ${_selectedCrowding.label} • ${_selectedOption.title}';
      } else {
        problemType = _selectedOption.title;
      }

      final report = Report(
        id: '',
        targetType: isBus ? 'bus' : 'station',
        targetId: targetId,
        targetName: targetName,
        problemType: problemType,
        subCategory: _selectedOption.title,
        category: _selectedOption.category,
        severity: _selectedOption.severity,
        description: _noteController.text.trim(),
        status: 'active',
        createdAt: DateTime.now(),
        lastConfirmedAt: DateTime.now(),
        confirmCount: 0,
        falseCount: 0,
        userId: userId,
        confirmedBy: const [],
        flaggedBy: const [],
      );

      await _firestoreService.createReport(report);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ReportSubmittedScreen(
              report: report,
              targetName: targetName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Unable to submit report: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community Report',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              'Help accessible transit commuters in real-time',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: isDesktop ? 24 : 16,
                    ),
                    children: [
                      // Step 1: Select Route
                      _buildSectionHeader(
                        step: '1',
                        title: 'Select Bus Route',
                        subtitle: 'Which route are you traveling on or waiting for?',
                      ),
                      const SizedBox(height: 12),
                      _buildRouteSelector(),
                      const SizedBox(height: 28),

                      // Step 2: Target Type (Bus vs Bus Stop)
                      _buildSectionHeader(
                        step: '2',
                        title: 'Where is the Issue?',
                        subtitle: 'Choose whether you are inside a vehicle or at a station',
                      ),
                      const SizedBox(height: 12),
                      _buildTargetTypeCards(),
                      const SizedBox(height: 16),
                      _buildSpecificTargetDropdown(),
                      const SizedBox(height: 28),

                      // Step 3: Context-Aware Condition Report
                      _buildSectionHeader(
                        step: '3',
                        title: _targetType == ReportTargetType.bus
                            ? 'Vehicle Accessibility Condition'
                            : 'Station Accessibility Condition',
                        subtitle: _targetType == ReportTargetType.bus
                            ? 'Report crowding level and wheelchair access inside the bus'
                            : 'Report elevator, ramp, and platform conditions at the stop',
                      ),
                      const SizedBox(height: 16),

                      if (_targetType == ReportTargetType.bus) ...[
                        // Crowding Level Selector
                        _buildCrowdingSelector(),
                        const SizedBox(height: 24),
                        // Bus Categories and Sub-Cards
                        _buildCategorySection(
                          categories: _busCategories,
                          activeIndex: _activeBusCategoryIndex,
                          onCategoryChanged: (idx) {
                            setState(() {
                              _activeBusCategoryIndex = idx;
                              _selectedOption = _busCategories[idx].options[0];
                            });
                          },
                        ),
                      ] else ...[
                        // Station Categories and Sub-Cards
                        _buildCategorySection(
                          categories: _stationCategories,
                          activeIndex: _activeStationCategoryIndex,
                          onCategoryChanged: (idx) {
                            setState(() {
                              _activeStationCategoryIndex = idx;
                              _selectedOption = _stationCategories[idx].options[0];
                            });
                          },
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Step 4: Optional Short Note
                      _buildSectionHeader(
                        step: '4',
                        title: 'Additional Note (Optional)',
                        subtitle: 'Add helpful details for fellow wheelchair or elderly riders',
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _noteController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'e.g. Ramp is usable but driver assistance was needed',
                          hintStyle: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceContainerLowest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Step 5: Large Accessible Submit Button
                      SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: _isSubmitting ? null : _submitReport,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 22),
                          label: Text(
                            _isSubmitting
                                ? 'Submitting Report…'
                                : 'Submit Accessibility Report (+10 Pts)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader({
    required String step,
    required String title,
    required String subtitle,
  }) {
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
          alignment: Alignment.center,
          child: Text(
            step,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRouteSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BusRoute>(
          isExpanded: true,
          value: _selectedRoute,
          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 30),
          items: _allRoutes.map((r) {
            return DropdownMenuItem<BusRoute>(
              value: r,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Bus ${r.routeNo}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r.routeName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (newRoute) {
            if (newRoute != null) {
              setState(() {
                _selectedRoute = newRoute;
                _refreshTargetsForRoute();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildTargetTypeCards() {
    final isBus = _targetType == ReportTargetType.bus;

    return Row(
      children: [
        Expanded(
          child: _TargetChoiceCard(
            title: 'On a Bus',
            subtitle: 'Inside the vehicle',
            icon: Icons.directions_bus_rounded,
            isSelected: isBus,
            onTap: () {
              setState(() {
                _targetType = ReportTargetType.bus;
                _selectedOption = _busCategories[_activeBusCategoryIndex].options[0];
                _refreshTargetsForRoute();
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TargetChoiceCard(
            title: 'At a Bus Stop',
            subtitle: 'Station & platform',
            icon: Icons.store_mall_directory_rounded,
            isSelected: !isBus,
            onTap: () {
              setState(() {
                _targetType = ReportTargetType.station;
                _selectedOption = _stationCategories[_activeStationCategoryIndex].options[0];
                _refreshTargetsForRoute();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpecificTargetDropdown() {
    final isBus = _targetType == ReportTargetType.bus;

    if (isBus) {
      final buses = _getBusesForSelectedRoute();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Bus>(
            isExpanded: true,
            hint: const Text('Select Specific Bus / License Plate'),
            value: buses.contains(_selectedBus) ? _selectedBus : null,
            items: buses.map((b) {
              return DropdownMenuItem<Bus>(
                value: b,
                child: Row(
                  children: [
                    const Icon(Icons.tag_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${b.busNo} ${b.hasRamp ? "♿ (Ramp)" : ""}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (bus) {
              if (bus != null) {
                setState(() => _selectedBus = bus);
              }
            },
          ),
        ),
      );
    } else {
      final stations = _getStationsForSelectedRoute();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Station>(
            isExpanded: true,
            hint: const Text('Select Stop along this route'),
            value: stations.contains(_selectedStation) ? _selectedStation : null,
            items: stations.map((s) {
              return DropdownMenuItem<Station>(
                value: s,
                child: Row(
                  children: [
                    const Icon(Icons.place_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${s.name} ${s.hasElevator ? "🛗" : ""} ${s.hasRamp ? "♿" : ""}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (st) {
              if (st != null) {
                setState(() => _selectedStation = st);
              }
            },
          ),
        ),
      );
    }
  }

  Widget _buildCrowdingSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Crowding Level (තදබදය)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: CrowdingLevel.values.map((lvl) {
            final isSelected = _selectedCrowding == lvl;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => setState(() => _selectedCrowding = lvl),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 74),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? lvl.color.withValues(alpha: 0.15)
                          : AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? lvl.color : AppColors.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(lvl.icon, color: lvl.color, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          lvl.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? lvl.color : AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Text(
            _selectedCrowding.subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _selectedCrowding.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection({
    required List<ReportCategoryDef> categories,
    required int activeIndex,
    required ValueChanged<int> onCategoryChanged,
  }) {
    final activeCategory = categories[activeIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accessibility Issue Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 10),

        // Horizontal Category Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(categories.length, (idx) {
              final cat = categories[idx];
              final isCatSelected = idx == activeIndex;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => onCategoryChanged(idx),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCatSelected
                          ? AppColors.primary
                          : AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCatSelected ? AppColors.primary : AppColors.outlineVariant,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat.icon,
                          size: 18,
                          color: isCatSelected ? AppColors.onPrimary : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isCatSelected ? AppColors.onPrimary : AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 16),

        // Sub-Category Cards (2 Columns)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activeCategory.options.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, optIdx) {
            final opt = activeCategory.options[optIdx];
            final isOptSelected = _selectedOption.id == opt.id;

            return InkWell(
              onTap: () => setState(() => _selectedOption = opt),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isOptSelected
                      ? opt.color.withValues(alpha: 0.12)
                      : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isOptSelected ? opt.color : AppColors.outlineVariant,
                    width: isOptSelected ? 2 : 1,
                  ),
                  boxShadow: isOptSelected
                      ? [
                          BoxShadow(
                            color: opt.color.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(opt.icon, color: opt.color, size: 22),
                        const Spacer(),
                        if (isOptSelected)
                          Icon(Icons.check_circle_rounded, color: opt.color, size: 16),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      opt.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isOptSelected ? opt.color : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      opt.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        // Selected Status Summary Badge
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _selectedOption.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _selectedOption.color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(_selectedOption.icon, size: 18, color: _selectedOption.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Selected: ${_selectedOption.title} — ${_selectedOption.subtitle}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _selectedOption.color,
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

/// Large interactive touch card to choose between Bus vs Station
class _TargetChoiceCard extends StatelessWidget {
  const _TargetChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 96),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? AppColors.onPrimaryContainer : AppColors.primary,
                ),
                const Spacer(),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.onPrimaryContainer : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? AppColors.onPrimaryContainer.withValues(alpha: 0.8)
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
