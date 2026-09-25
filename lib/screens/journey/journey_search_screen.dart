import 'package:flutter/material.dart';

import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../data/seed_data.dart';
import '../../models/station.dart';
import '../../services/firestore_service.dart';
import 'route_results_screen.dart';

/// Journey Search screen — origin/destination, time, accessibility filters,
/// and recent destinations (Sprint 3 Data Wired & Searchable Pickers).
class JourneySearchScreen extends StatefulWidget {
  const JourneySearchScreen({super.key});

  @override
  State<JourneySearchScreen> createState() => _JourneySearchScreenState();
}

class _JourneySearchScreenState extends State<JourneySearchScreen> {
  static const double _desktopBreakpoint = 768;
  final FirestoreService _firestoreService = FirestoreService();

  List<Station> _stations = [];
  Station? _selectedFromStation;
  Station? _selectedToStation;
  bool _isLoadingStations = true;

  bool _wheelchairAccess = true;
  bool _stepFreeOnly = false;
  bool _minimizeWalking = true;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    try {
      var fetched = await _firestoreService.getStations();
      if (fetched.isEmpty) {
        // Auto-seed Firestore if empty so realistic stations exist!
        await SeedData().seedAll();
        fetched = await _firestoreService.getStations();
      }
      final list = fetched.isNotEmpty ? fetched : SeedData.colomboStations;
      if (mounted) {
        setState(() {
          _stations = list;
          // Default: Pettah (st_pettah) to Mount Lavinia (st_mt_lavinia) for Route 100!
          _selectedFromStation = list.firstWhere(
            (s) => s.id == 'st_pettah',
            orElse: () => list.firstWhere((s) => s.id == 'st_fort', orElse: () => list.first),
          );
          _selectedToStation = list.firstWhere(
            (s) => s.id == 'st_mt_lavinia',
            orElse: () => list.firstWhere((s) => s.id == 'st_kottawa', orElse: () => list.last),
          );
          _isLoadingStations = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _stations = SeedData.colomboStations;
          _selectedFromStation = SeedData.colomboStations[1]; // st_pettah
          _selectedToStation = SeedData.colomboStations[7]; // st_mt_lavinia
          _isLoadingStations = false;
        });
      }
    }
  }

  void _swapLocations() {
    if (_selectedFromStation == null || _selectedToStation == null) return;
    setState(() {
      final temp = _selectedFromStation;
      _selectedFromStation = _selectedToStation;
      _selectedToStation = temp;
    });
  }

  void _selectDestinationById(String stationId) {
    if (_stations.isEmpty) return;
    final match = _stations.firstWhere(
      (s) => s.id == stationId,
      orElse: () => _stations.last,
    );
    setState(() => _selectedToStation = match);
  }

  void _showStationPicker(BuildContext context, bool isFrom) {
    if (_stations.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _StationSearchModal(
          title: isFrom ? 'Select Origin Station' : 'Select Destination Station',
          stations: _stations,
          selectedStationId: isFrom ? _selectedFromStation?.id : _selectedToStation?.id,
          onSelect: (station) {
            Navigator.of(context).pop();
            setState(() {
              if (isFrom) {
                _selectedFromStation = station;
              } else {
                _selectedToStation = station;
              }
            });
          },
        );
      },
    );
  }

  void _searchRoutes() {
    if (_selectedFromStation == null || _selectedToStation == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Please select origin and destination stations.')),
        );
      return;
    }

    if (_selectedFromStation!.id == _selectedToStation!.id) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Origin and destination stations cannot be the same.'),
            backgroundColor: AppColors.error,
          ),
        );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteResultsScreen(
          fromStationId: _selectedFromStation!.id,
          toStationId: _selectedToStation!.id,
          origin: _selectedFromStation!.name,
          destination: _selectedToStation!.name,
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$feature will be available soon.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _TopBar(
            isDesktop: isDesktop,
            onMenu: () => Navigator.of(context).maybePop(),
            onProfile: () => AppNavigation.openProfile(context),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                24,
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
                        _SearchInputsCard(
                          fromStation: _selectedFromStation,
                          toStation: _selectedToStation,
                          onTapFrom: () => _showStationPicker(context, true),
                          onTapTo: () => _showStationPicker(context, false),
                          onSwap: _swapLocations,
                          isLoading: _isLoadingStations,
                        ),
                        const SizedBox(height: 24),
                        _DepartNowCard(
                          onChange: () => _showComingSoon('Change departure time'),
                        ),
                        const SizedBox(height: 24),
                        _AccessibilityFiltersSection(
                          wheelchairAccess: _wheelchairAccess,
                          stepFreeOnly: _stepFreeOnly,
                          minimizeWalking: _minimizeWalking,
                          onWheelchairChanged: (v) =>
                              setState(() => _wheelchairAccess = v),
                          onStepFreeChanged: (v) =>
                              setState(() => _stepFreeOnly = v),
                          onMinimizeWalkingChanged: (v) =>
                              setState(() => _minimizeWalking = v),
                        ),
                        const SizedBox(height: 24),
                        _RecentSavedSection(
                          onSelectStation: _selectDestinationById,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 56,
                          child: FilledButton(
                            onPressed: _searchRoutes,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: AppColors.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                height: 24 / 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Search Routes'),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 24),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : _JourneyBottomNav(
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
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isDesktop,
    required this.onMenu,
    required this.onProfile,
  });

  final bool isDesktop;
  final VoidCallback onMenu;
  final VoidCallback onProfile;

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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: onMenu,
                  icon: Icon(
                    isDesktop ? Icons.menu : Icons.arrow_back_rounded,
                  ),
                  color: AppColors.primary,
                  tooltip: isDesktop ? 'Menu' : 'Back',
                ),
                const Expanded(
                  child: Text(
                    'Access Transit',
                    style: TextStyle(
                      fontSize: 22,
                      height: 28 / 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onProfile,
                  borderRadius: BorderRadius.circular(999),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.surfaceContainer,
                    child: const Icon(
                      Icons.person,
                      color: AppColors.primaryContainer,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchInputsCard extends StatelessWidget {
  const _SearchInputsCard({
    required this.fromStation,
    required this.toStation,
    required this.onTapFrom,
    required this.onTapTo,
    required this.onSwap,
    required this.isLoading,
  });

  final Station? fromStation;
  final Station? toStation;
  final VoidCallback onTapFrom;
  final VoidCallback onTapTo;
  final VoidCallback onSwap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
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
      child: isLoading
          ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          : Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 14),
                      child: Column(
                        children: [
                          Icon(
                            Icons.my_location,
                            size: 20,
                            color: AppColors.primaryContainer,
                          ),
                          SizedBox(
                            height: 38,
                            child: VerticalDivider(
                              width: 20,
                              thickness: 1,
                              color: AppColors.outlineVariant,
                            ),
                          ),
                          Icon(
                            Icons.location_on,
                            size: 20,
                            color: AppColors.error,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          _StationSelectButton(
                            label: fromStation?.name ?? 'Select Origin Station',
                            hint: 'From Station',
                            icon: Icons.my_location,
                            onTap: onTapFrom,
                          ),
                          const SizedBox(height: 12),
                          _StationSelectButton(
                            label: toStation?.name ?? 'Select Destination Station',
                            hint: 'Destination Station',
                            icon: Icons.location_on,
                            onTap: onTapTo,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: AppColors.surfaceContainer,
                      shape: const CircleBorder(
                        side: BorderSide(color: AppColors.surfaceVariant),
                      ),
                      elevation: 1,
                      shadowColor: AppColors.onSurface.withValues(alpha: 0.08),
                      child: InkWell(
                        onTap: onSwap,
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.swap_vert,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StationSelectButton extends StatelessWidget {
  const _StationSelectButton({
    required this.label,
    required this.hint,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _StationSearchModal extends StatefulWidget {
  const _StationSearchModal({
    required this.title,
    required this.stations,
    required this.selectedStationId,
    required this.onSelect,
  });

  final String title;
  final List<Station> stations;
  final String? selectedStationId;
  final ValueChanged<Station> onSelect;

  @override
  State<_StationSearchModal> createState() => _StationSearchModalState();
}

class _StationSearchModalState extends State<_StationSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.stations.where((s) {
      final q = _query.trim().toLowerCase();
      if (q.isEmpty) return true;
      return s.name.toLowerCase().contains(q) || s.id.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (val) => setState(() => _query = val),
              decoration: InputDecoration(
                hintText: 'Search Colombo station name or ID...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching stations found.',
                        style: TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final s = filtered[index];
                        final isSelected = s.id == widget.selectedStationId;

                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: AppColors.primaryContainer.withValues(alpha: 0.1),
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? AppColors.primaryContainer
                                : AppColors.surfaceContainer,
                            child: Icon(
                              Icons.location_on,
                              color: isSelected
                                  ? AppColors.onPrimary
                                  : AppColors.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            s.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              if (s.hasRamp) ...[
                                const Icon(Icons.accessible, size: 14, color: AppColors.secondary),
                                const SizedBox(width: 4),
                                const Text('Ramp  ', style: TextStyle(fontSize: 12)),
                              ],
                              if (s.hasElevator) ...[
                                const Icon(Icons.elevator_outlined, size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                const Text('Elevator', style: TextStyle(fontSize: 12)),
                              ],
                              if (!s.hasRamp && !s.hasElevator)
                                const Text('Standard Stop', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppColors.primaryContainer)
                              : null,
                          onTap: () => widget.onSelect(s),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DepartNowCard extends StatelessWidget {
  const _DepartNowCard({required this.onChange});

  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        children: [
          const Icon(Icons.schedule, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Depart Now',
              style: TextStyle(
                fontSize: 16,
                height: 24 / 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ),
          TextButton(
            onPressed: onChange,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: const Text(
              'Change',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessibilityFiltersSection extends StatelessWidget {
  const _AccessibilityFiltersSection({
    required this.wheelchairAccess,
    required this.stepFreeOnly,
    required this.minimizeWalking,
    required this.onWheelchairChanged,
    required this.onStepFreeChanged,
    required this.onMinimizeWalkingChanged,
  });

  final bool wheelchairAccess;
  final bool stepFreeOnly;
  final bool minimizeWalking;
  final ValueChanged<bool> onWheelchairChanged;
  final ValueChanged<bool> onStepFreeChanged;
  final ValueChanged<bool> onMinimizeWalkingChanged;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accessibility Requirements',
          style: TextStyle(
            fontSize: 16,
            height: 24 / 16,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: isWide ? 3 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: isWide ? 1.4 : 1.35,
          children: [
            _FilterTile(
              icon: Icons.accessible,
              label: 'Wheelchair\nAccess',
              selected: wheelchairAccess,
              onTap: () => onWheelchairChanged(!wheelchairAccess),
            ),
            _FilterTile(
              icon: Icons.elevator_outlined,
              label: 'Step-free\nOnly',
              selected: stepFreeOnly,
              onTap: () => onStepFreeChanged(!stepFreeOnly),
            ),
            _FilterTile(
              icon: Icons.directions_walk,
              label: 'Minimize\nWalking',
              selected: minimizeWalking,
              onTap: () => onMinimizeWalkingChanged(!minimizeWalking),
              wideOnMobile: true,
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Filters applied based on your saved profile.',
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

class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.wideOnMobile = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool wideOnMobile;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 768;
    final child = Material(
      color: selected
          ? AppColors.secondaryContainer
          : AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : AppColors.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 28,
                    color: selected
                        ? AppColors.onSecondaryContainer
                        : AppColors.onSurfaceVariant,
                  ),
                  const Spacer(),
                  if (selected)
                    const Icon(
                      Icons.check_circle,
                      size: 20,
                      color: AppColors.onSecondaryContainer,
                    ),
                ],
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? AppColors.onSecondaryContainer
                      : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!isWide && wideOnMobile) {
      return child;
    }
    return child;
  }
}

class _RecentSavedSection extends StatelessWidget {
  const _RecentSavedSection({required this.onSelectStation});

  final ValueChanged<String> onSelectStation;

  static const _items = [
    (Icons.directions_bus, 'st_mt_lavinia', 'Mount Lavinia Station', 'Route 100 • Galle Road Corridor (Safe)'),
    (Icons.directions_bus, 'st_kottawa', 'Kottawa Highway Station', 'Route 138 • High-Level Road Corridor (Safe)'),
    (Icons.directions_bus, 'st_dehiwala', 'Dehiwala Station', 'Route 101 • Coastal Route (Warning: Broken Ramp)'),
    (Icons.directions_bus, 'st_maharagama', 'Maharagama Bus Complex', 'Route 120 • Horana Route (Not Accessible)'),
    (Icons.directions_bus, 'st_bambalapitiya', 'Bambalapitiya Station', 'Route 154 • Cross-town Link'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular & Saved Corridors',
          style: TextStyle(
            fontSize: 16,
            height: 24 / 16,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
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
            children: [
              for (var i = 0; i < _items.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, color: AppColors.surfaceVariant),
                ListTile(
                  minVerticalPadding: 12,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surfaceContainer,
                    child: Icon(
                      _items[i].$1,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                  title: Text(
                    _items[i].$3,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 24 / 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    _items[i].$4,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  onTap: () => onSelectStation(_items[i].$2),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _JourneyBottomNav extends StatelessWidget {
  const _JourneyBottomNav({required this.onNavTap});

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
          mainAxisAlignment: Checkbox.width == 0 ? MainAxisAlignment.center : MainAxisAlignment.center,
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
