import 'package:flutter/material.dart';

import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_utils.dart';
import '../../data/seed_data.dart';
import '../../models/station.dart';
import '../../services/accessibility_preferences_service.dart';
import '../../services/firestore_service.dart';
import 'route_results_screen.dart';

/// Journey Search screen — simplified, accessible origin/destination search,
/// streamlined travel time, accessibility-first filters, and popular corridors.
/// Phase 1: High accessibility UX enhancement inspired by LMT Go.
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
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  bool _isLoadingStations = true;

  // Accessibility requirements loaded from user preferences
  late bool _wheelchairAccess;
  late bool _stepFreeOnly;
  late bool _minimizeWalking;

  @override
  void initState() {
    super.initState();
    _applyUserPreferences();
    AccessibilityPreferencesService.instance.addListener(_onPreferencesChanged);
    _loadStations();
  }

  void _applyUserPreferences() {
    final prefs = AccessibilityPreferencesService.instance;
    _wheelchairAccess = prefs.isWheelchairOnly;
    _stepFreeOnly = prefs.isStepFree;
    _minimizeWalking = prefs.minimizeWalking;
  }

  void _onPreferencesChanged() {
    if (mounted) {
      setState(() {
        _applyUserPreferences();
      });
    }
  }

  @override
  void dispose() {
    AccessibilityPreferencesService.instance.removeListener(_onPreferencesChanged);
    super.dispose();
  }

  Future<void> _loadStations() async {
    try {
      final routes = await _firestoreService.getRoutes();
      final hasNewSlRoutes = routes.any((r) => r.id == 'route_138_pettah_homagama');
      if (!hasNewSlRoutes) {
        await SeedData().seedAll();
      }
      var fetched = await _firestoreService.getStations();
      if (fetched.isEmpty) {
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

  Future<void> _resyncDatabase() async {
    setState(() => _isLoadingStations = true);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Updating Sri Lankan transit database...')),
      );
    try {
      await SeedData().seedAll();
      await _loadStations();
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Database updated with authentic Sri Lankan routes & buses!'),
              backgroundColor: AppColors.primaryContainer,
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Error updating database: $e'),
              backgroundColor: AppColors.error,
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingStations = false);
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('⇄ Boarding stop and Destination swapped'),
          duration: Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _useMyLocation() {
    if (_stations.isEmpty) return;
    final myHub = _stations.firstWhere(
      (s) => s.id == 'st_pettah',
      orElse: () => _stations.firstWhere((s) => s.id == 'st_fort', orElse: () => _stations.first),
    );
    setState(() => _selectedFromStation = myHub);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('📍 Boarding stop set to nearest stop: ${myHub.name}'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _selectCorridor(String fromId, String toId) {
    if (_stations.isEmpty) return;
    final from = _stations.firstWhere((s) => s.id == fromId, orElse: () => _stations.first);
    final to = _stations.firstWhere((s) => s.id == toId, orElse: () => _stations.last);
    setState(() {
      _selectedFromStation = from;
      _selectedToStation = to;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Route selected: ${from.name} ➔ ${to.name}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _showStationPicker(BuildContext context, bool isFrom) {
    if (_stations.isEmpty) return;
    final isHighContrast = context.isHighContrast;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: isHighContrast ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
      ),
      builder: (context) {
        return _StationSearchModal(
          title: isFrom ? 'Select Boarding Point' : 'Select Destination Stop',
          isFrom: isFrom,
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
          onUseMyLocation: isFrom ? _useMyLocation : null,
        );
      },
    );
  }

  void _showVoiceSearchDialog(bool isFrom) {
    final isHighContrast = context.isHighContrast;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: isHighContrast ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
      ),
      builder: (context) {
        return _VoiceSearchModal(
          isFrom: isFrom,
          stations: _stations,
          onStationRecognized: (station) {
            Navigator.of(context).pop();
            setState(() {
              if (isFrom) {
                _selectedFromStation = station;
              } else {
                _selectedToStation = station;
              }
            });
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text('🎙️ Recognized: ${station.name}'),
                  backgroundColor: isHighContrast ? const Color(0xFF001F3F) : AppColors.primary,
                  duration: const Duration(seconds: 2),
                ),
              );
          },
        );
      },
    );
  }

  void _showTravelTimeOptions() {
    final isHighContrast = context.isHighContrast;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: isHighContrast ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: isHighContrast ? Colors.black : AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Choose Travel Time',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isHighContrast ? Colors.black : AppColors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      iconSize: 26,
                      tooltip: 'Close',
                      color: isHighContrast ? Colors.black : null,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isHighContrast
                          ? Colors.black
                          : (_selectedTime == null && DateUtils.isSameDay(_selectedDate, DateTime.now())
                              ? AppColors.primary
                              : AppColors.outlineVariant),
                      width: isHighContrast ? 2.0 : 1.5,
                    ),
                  ),
                  tileColor: isHighContrast
                      ? (_selectedTime == null && DateUtils.isSameDay(_selectedDate, DateTime.now())
                          ? const Color(0xFF001F3F).withValues(alpha: 0.12)
                          : Colors.white)
                      : (_selectedTime == null && DateUtils.isSameDay(_selectedDate, DateTime.now())
                          ? AppColors.primaryFixed.withValues(alpha: 0.3)
                          : AppColors.surfaceContainerLowest),
                  leading: CircleAvatar(
                    backgroundColor: isHighContrast ? const Color(0xFF001F3F) : AppColors.primary,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.bolt_rounded, size: 24),
                  ),
                  title: Text(
                    'Leave Now',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: isHighContrast ? Colors.black : null,
                    ),
                  ),
                  subtitle: Text(
                    'Get the very next arriving buses in real-time',
                    style: TextStyle(
                      fontSize: 14,
                      color: isHighContrast ? const Color(0xFF1A1A1A) : null,
                      fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: _selectedTime == null && DateUtils.isSameDay(_selectedDate, DateTime.now())
                      ? Icon(
                          Icons.check_circle,
                          color: isHighContrast ? const Color(0xFF001F3F) : AppColors.primary,
                          size: 26,
                        )
                      : null,
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedDate = DateTime.now();
                      _selectedTime = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isHighContrast ? Colors.black : AppColors.outlineVariant,
                      width: isHighContrast ? 2.0 : 1.0,
                    ),
                  ),
                  tileColor: isHighContrast ? Colors.white : AppColors.surfaceContainerLowest,
                  leading: CircleAvatar(
                    backgroundColor: isHighContrast ? const Color(0xFF001F3F) : AppColors.surfaceContainer,
                    child: Icon(
                      Icons.access_time_filled_rounded,
                      color: isHighContrast ? Colors.white : AppColors.primary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Set Specific Time',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: isHighContrast ? Colors.black : null,
                    ),
                  ),
                  subtitle: Text(
                    _selectedTime != null
                        ? 'Selected: ${_selectedTime!.format(context)}'
                        : 'Choose departure time today',
                    style: TextStyle(
                      fontSize: 14,
                      color: isHighContrast ? const Color(0xFF1A1A1A) : null,
                      fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 28,
                    color: isHighContrast ? Colors.black : null,
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _pickTime();
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isHighContrast ? Colors.black : AppColors.outlineVariant,
                      width: isHighContrast ? 2.0 : 1.0,
                    ),
                  ),
                  tileColor: isHighContrast ? Colors.white : AppColors.surfaceContainerLowest,
                  leading: CircleAvatar(
                    backgroundColor: isHighContrast ? const Color(0xFF001F3F) : AppColors.surfaceContainer,
                    child: Icon(
                      Icons.calendar_today_rounded,
                      color: isHighContrast ? Colors.white : AppColors.primary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Change Travel Date',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: isHighContrast ? Colors.black : null,
                    ),
                  ),
                  subtitle: Text(
                    TimeUtils.formatDateString(_selectedDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: isHighContrast ? const Color(0xFF1A1A1A) : null,
                      fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 28,
                    color: isHighContrast ? Colors.black : null,
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _pickDate();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAccessibilityFilterSheet() {
    final isHighContrast = context.isHighContrast;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: isHighContrast ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.accessibility_new_rounded,
                          color: isHighContrast ? Colors.black : AppColors.secondary,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Accessibility Needs',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isHighContrast ? Colors.black : AppColors.onSurface,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          iconSize: 26,
                          tooltip: 'Close',
                          color: isHighContrast ? Colors.black : null,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customize for this trip only. Your permanent Accessibility Preferences in settings will not be affected.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isHighContrast ? const Color(0xFF1A1A1A) : AppColors.onSurfaceVariant,
                        fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Quick Accessibility Presets
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(
                                color: isHighContrast
                                    ? Colors.black
                                    : (_wheelchairAccess && _stepFreeOnly ? AppColors.secondary : AppColors.outlineVariant),
                                width: (_wheelchairAccess && _stepFreeOnly || isHighContrast) ? 2 : 1,
                              ),
                              backgroundColor: _wheelchairAccess && _stepFreeOnly
                                  ? (isHighContrast ? const Color(0xFF001F3F).withValues(alpha: 0.15) : AppColors.secondaryContainer.withValues(alpha: 0.3))
                                  : null,
                            ),
                            onPressed: () {
                              setSheetState(() {
                                _wheelchairAccess = true;
                                _stepFreeOnly = true;
                                _minimizeWalking = true;
                              });
                              setState(() {});
                            },
                            child: Text(
                              '♿ Wheelchair',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isHighContrast ? Colors.black : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(
                                color: isHighContrast
                                    ? Colors.black
                                    : (!_wheelchairAccess && _stepFreeOnly ? AppColors.secondary : AppColors.outlineVariant),
                                width: (!_wheelchairAccess && _stepFreeOnly || isHighContrast) ? 2 : 1,
                              ),
                              backgroundColor: !_wheelchairAccess && _stepFreeOnly
                                  ? (isHighContrast ? const Color(0xFF001F3F).withValues(alpha: 0.15) : AppColors.secondaryContainer.withValues(alpha: 0.3))
                                  : null,
                            ),
                            onPressed: () {
                              setSheetState(() {
                                _wheelchairAccess = false;
                                _stepFreeOnly = true;
                                _minimizeWalking = true;
                              });
                              setState(() {});
                            },
                            child: Text(
                              '🧓 Elderly / Gentle',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isHighContrast ? Colors.black : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Reset to saved accessibility preferences',
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(54, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: isHighContrast ? const BorderSide(color: Colors.black, width: 2) : null,
                            ),
                            onPressed: () {
                              setSheetState(() {
                                final prefs = AccessibilityPreferencesService.instance;
                                _wheelchairAccess = prefs.isWheelchairOnly;
                                _stepFreeOnly = prefs.isStepFree;
                                _minimizeWalking = prefs.minimizeWalking;
                              });
                              setState(() {});
                            },
                            child: Text(
                              'Reset',
                              style: TextStyle(
                                fontSize: 14,
                                color: isHighContrast ? Colors.black : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Switches with minimum 56dp touch targets
                    _AccessibilitySwitchTile(
                      icon: Icons.accessible_rounded,
                      title: 'Wheelchair Ramp',
                      subtitle: 'Ensure buses have working motorized or fold-out ramps',
                      value: _wheelchairAccess,
                      onChanged: (val) {
                        setSheetState(() => _wheelchairAccess = val);
                        setState(() => _wheelchairAccess = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    _AccessibilitySwitchTile(
                      icon: Icons.elevator_outlined,
                      title: 'Step-Free Station Access',
                      subtitle: 'Only board and exit at stations with elevators or flat paths',
                      value: _stepFreeOnly,
                      onChanged: (val) {
                        setSheetState(() => _stepFreeOnly = val);
                        setState(() => _stepFreeOnly = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    _AccessibilitySwitchTile(
                      icon: Icons.directions_walk_rounded,
                      title: 'Minimize Walking Distance',
                      subtitle: 'Prefer direct connections closest to entrance points',
                      value: _minimizeWalking,
                      onChanged: (val) {
                        setSheetState(() => _minimizeWalking = val);
                        setState(() => _minimizeWalking = val);
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: isHighContrast ? const Color(0xFF001F3F) : AppColors.primaryContainer,
                          foregroundColor: Colors.white,
                          side: isHighContrast ? const BorderSide(color: Colors.black, width: 2) : null,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Apply to This Trip',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
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
          selectedDate: _selectedDate,
          wheelchairAccessRequired: _wheelchairAccess,
          stepFreeOnly: _stepFreeOnly,
          minimizeWalking: _minimizeWalking,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;
    final isHighContrast = context.isHighContrast;

    // Build accessibility active filters list
    final List<String> activeFilters = [];
    if (_wheelchairAccess) activeFilters.add('Ramp Required');
    if (_stepFreeOnly) activeFilters.add('Step-Free');
    if (_minimizeWalking) activeFilters.add('Min Walk');

    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: Column(
        children: [
          _TopBar(
            isDesktop: isDesktop,
            onMenu: () => Navigator.of(context).maybePop(),
            onProfile: () => AppNavigation.openProfile(context),
            onSync: _resyncDatabase,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                isDesktop ? 24 : 24,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 768),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Main Search Inputs Card (Clean LMT Go style with high accessibility)
                        _SearchInputsCard(
                          fromStation: _selectedFromStation,
                          toStation: _selectedToStation,
                          onTapFrom: () => _showStationPicker(context, true),
                          onTapTo: () => _showStationPicker(context, false),
                          onSwap: _swapLocations,
                          onUseMyLocation: _useMyLocation,
                          onVoiceSearchFrom: () => _showVoiceSearchDialog(true),
                          onVoiceSearchTo: () => _showVoiceSearchDialog(false),
                          isLoading: _isLoadingStations,
                        ),
                        const SizedBox(height: 14),

                        // Travel Time Row (Clean, single row, defaults to Depart Now)
                        _TravelTimeCard(
                          selectedDate: _selectedDate,
                          selectedTime: _selectedTime,
                          onTap: _showTravelTimeOptions,
                        ),
                        const SizedBox(height: 14),

                        // Single Accessibility Filter Chip / Row (Phase 1 clean design)
                        _AccessibilityFilterRow(
                          activeFilters: activeFilters,
                          onTap: _showAccessibilityFilterSheet,
                          onClearFilter: (filter) {
                            setState(() {
                              if (filter == 'Ramp Required') _wheelchairAccess = false;
                              if (filter == 'Step-Free') _stepFreeOnly = false;
                              if (filter == 'Min Walk') _minimizeWalking = false;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // Full-width prominent "Find Buses" action button (56dp height)
                        SizedBox(
                          height: 56,
                          child: FilledButton(
                            onPressed: _searchRoutes,
                            style: FilledButton.styleFrom(
                              backgroundColor: isHighContrast
                                  ? const Color(0xFF001F3F)
                                  : AppColors.primaryContainer,
                              foregroundColor: Colors.white,
                              side: isHighContrast
                                  ? const BorderSide(color: Colors.black, width: 2.0)
                                  : null,
                              elevation: isHighContrast ? 0 : 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_bus_rounded, size: 26),
                                SizedBox(width: 12),
                                Text('Find Buses'),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward_rounded, size: 22),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Popular Corridors & Quick Trips (One-tap selection)
                        _RecentSavedSection(
                          onSelectCorridor: _selectCorridor,
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
      bottomNavigationBar: null,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isDesktop,
    required this.onMenu,
    required this.onProfile,
    this.onSync,
  });

  final bool isDesktop;
  final VoidCallback onMenu;
  final VoidCallback onProfile;
  final VoidCallback? onSync;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;

    return Container(
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.white : AppColors.surfaceContainerLow,
        border: isHighContrast
            ? const Border(bottom: BorderSide(color: Colors.black, width: 2.0))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        elevation: isHighContrast ? 0 : 1,
        shadowColor: AppColors.onSurface.withValues(alpha: 0.08),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onMenu,
                    icon: Icon(
                      isDesktop ? Icons.menu : Icons.arrow_back_rounded,
                    ),
                    color: isHighContrast ? Colors.black : AppColors.primary,
                    tooltip: isDesktop ? 'Menu' : 'Back',
                    iconSize: 26,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Plan Journey',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isHighContrast ? Colors.black : AppColors.primary,
                      ),
                    ),
                  ),
                  if (onSync != null)
                    IconButton(
                      onPressed: onSync,
                      icon: const Icon(Icons.cloud_sync_outlined),
                      color: isHighContrast ? Colors.black : AppColors.primary,
                      tooltip: 'Reset & Sync Sri Lankan Bus Data',
                      iconSize: 26,
                    ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: onProfile,
                    borderRadius: BorderRadius.circular(999),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: isHighContrast ? const Color(0xFF001F3F) : AppColors.surfaceContainer,
                      child: Icon(
                        Icons.person,
                        color: isHighContrast ? Colors.white : AppColors.primaryContainer,
                        size: 22,
                      ),
                    ),
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

/// LMT Go styled Clean Search Card with High Accessibility
class _SearchInputsCard extends StatelessWidget {
  const _SearchInputsCard({
    required this.fromStation,
    required this.toStation,
    required this.onTapFrom,
    required this.onTapTo,
    required this.onSwap,
    required this.onUseMyLocation,
    required this.onVoiceSearchFrom,
    required this.onVoiceSearchTo,
    required this.isLoading,
  });

  final Station? fromStation;
  final Station? toStation;
  final VoidCallback onTapFrom;
  final VoidCallback onTapTo;
  final VoidCallback onSwap;
  final VoidCallback onUseMyLocation;
  final VoidCallback onVoiceSearchFrom;
  final VoidCallback onVoiceSearchTo;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.white : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: isHighContrast
            ? Border.all(color: Colors.black, width: 2.0)
            : Border.all(color: AppColors.surfaceVariant),
        boxShadow: isHighContrast
            ? null
            : [
                BoxShadow(
                  color: AppColors.onSurface.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: isLoading
          ? const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Origin (Boarding Point) Input
                _LocationInputField(
                  isFrom: true,
                  icon: Icons.trip_origin_rounded,
                  iconColor: AppColors.secondary,
                  headerLabel: 'BOARDING POINT',
                  headerColor: AppColors.secondary,
                  stationName: fromStation?.name ?? 'Choose Boarding Point',
                  subtitle: fromStation != null
                      ? (fromStation!.hasRamp ? '♿ Wheelchair Ramp Available' : 'Standard Stop')
                      : 'Tap to select boarding station',
                  onTap: onTapFrom,
                  onVoiceTap: onVoiceSearchFrom,
                  onUseMyLocation: onUseMyLocation,
                ),

                // Connecting Line + Swap Button (≥48dp touch target)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 24),
                      // Vertical dashed/solid line
                      Container(
                        width: 2.5,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isHighContrast ? Colors.black : AppColors.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Divider(
                          height: 1,
                          color: isHighContrast ? Colors.black : AppColors.surfaceVariant,
                          thickness: isHighContrast ? 1.5 : 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        button: true,
                        label: 'Swap boarding point and destination',
                        child: Material(
                          color: isHighContrast ? Colors.white : AppColors.surfaceContainerLow,
                          shape: CircleBorder(
                            side: isHighContrast ? const BorderSide(color: Colors.black, width: 2.0) : BorderSide.none,
                          ),
                          elevation: isHighContrast ? 0 : 1.5,
                          child: InkWell(
                            onTap: onSwap,
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.swap_vert_rounded,
                                color: isHighContrast ? Colors.black : AppColors.primary,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),

                // Destination Input
                _LocationInputField(
                  isFrom: false,
                  icon: Icons.location_on_rounded,
                  iconColor: AppColors.error,
                  headerLabel: 'WHERE ARE YOU GOING?',
                  headerColor: AppColors.error,
                  stationName: toStation?.name ?? 'Choose Destination',
                  subtitle: toStation != null
                      ? (toStation!.hasRamp ? '♿ Accessible Destination' : 'Standard Stop')
                      : 'Tap to select destination station',
                  onTap: onTapTo,
                  onVoiceTap: onVoiceSearchTo,
                ),
              ],
            ),
    );
  }
}

class _LocationInputField extends StatelessWidget {
  const _LocationInputField({
    required this.isFrom,
    required this.icon,
    required this.iconColor,
    required this.headerLabel,
    required this.headerColor,
    required this.stationName,
    required this.subtitle,
    required this.onTap,
    required this.onVoiceTap,
    this.onUseMyLocation,
  });

  final bool isFrom;
  final IconData icon;
  final Color iconColor;
  final String headerLabel;
  final Color headerColor;
  final String stationName;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onVoiceTap;
  final VoidCallback? onUseMyLocation;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final effectiveHeaderColor = isHighContrast ? Colors.black : headerColor;
    final effectiveIconColor = isHighContrast ? Colors.black : iconColor;

    return Semantics(
      button: true,
      label: '$headerLabel: $stationName',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isHighContrast ? Colors.white : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: isHighContrast
                ? Border.all(color: Colors.black, width: 2.0)
                : Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              // Indicator Dot / Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isHighContrast
                      ? const Color(0xFFE5E5E5)
                      : iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: isHighContrast
                      ? Border.all(color: Colors.black, width: 1.5)
                      : null,
                ),
                child: Icon(icon, color: effectiveIconColor, size: 20),
              ),
              const SizedBox(width: 12),
              // Text contents
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            headerLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: effectiveHeaderColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isFrom && onUseMyLocation != null) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: onUseMyLocation,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isHighContrast ? const Color(0xFF001F3F) : AppColors.primaryFixed,
                                borderRadius: BorderRadius.circular(6),
                                border: isHighContrast ? Border.all(color: Colors.black, width: 1.0) : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.my_location, size: 11, color: isHighContrast ? Colors.white : AppColors.primary),
                                  const SizedBox(width: 3),
                                  Text(
                                    'My Location',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isHighContrast ? Colors.white : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stationName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isHighContrast ? Colors.black : AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
                        color: isHighContrast ? const Color(0xFF1A1A1A) : AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Voice Input button
              Semantics(
                button: true,
                label: isFrom ? 'Voice search for boarding point' : 'Voice search for destination',
                child: IconButton(
                  onPressed: onVoiceTap,
                  icon: Icon(Icons.mic, color: isHighContrast ? Colors.black : AppColors.primary),
                  iconSize: 22,
                  tooltip: 'Speak stop name',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                ),
              ),
              Icon(Icons.arrow_drop_down, color: isHighContrast ? Colors.black : AppColors.onSurfaceVariant, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single Row Travel Time Card (Defaults to Leave Now)
class _TravelTimeCard extends StatelessWidget {
  const _TravelTimeCard({
    required this.selectedDate,
    required this.onTap,
    this.selectedTime,
  });

  final DateTime selectedDate;
  final TimeOfDay? selectedTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());
    final String timeLabel;
    final bool isDepartNow = selectedTime == null && isToday;

    if (isDepartNow) {
      timeLabel = 'Depart Now';
    } else if (selectedTime != null && isToday) {
      timeLabel = 'Today at ${selectedTime!.format(context)}';
    } else if (selectedTime != null) {
      timeLabel = '${TimeUtils.formatDateString(selectedDate)} at ${selectedTime!.format(context)}';
    } else {
      timeLabel = TimeUtils.formatDateString(selectedDate);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isHighContrast
                  ? const Color(0xFFE5E5E5)
                  : (isDepartNow ? AppColors.primaryFixed : AppColors.surfaceContainer),
              child: Icon(
                isDepartNow ? Icons.bolt_rounded : Icons.schedule_rounded,
                color: isHighContrast ? Colors.black : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRAVEL TIME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isHighContrast ? Colors.black : AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeLabel,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isHighContrast ? Colors.black : AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isHighContrast ? const Color(0xFF001F3F) : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
                border: isHighContrast ? Border.all(color: Colors.black, width: 1.5) : null,
              ),
              child: Row(
                children: [
                  Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isHighContrast ? Colors.white : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.expand_more, size: 16, color: isHighContrast ? Colors.white : AppColors.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Phase 1 Streamlined Accessibility Filter Row
class _AccessibilityFilterRow extends StatelessWidget {
  const _AccessibilityFilterRow({
    required this.activeFilters,
    required this.onTap,
    required this.onClearFilter,
  });

  final List<String> activeFilters;
  final VoidCallback onTap;
  final ValueChanged<String> onClearFilter;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;

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
          Row(
            children: [
              Icon(Icons.accessibility_new_rounded, size: 22, color: isHighContrast ? Colors.black : AppColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Accessibility Options',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isHighContrast ? Colors.black : AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Accessible filter trigger chip
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isHighContrast ? const Color(0xFF001F3F) : AppColors.secondaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isHighContrast ? Colors.black : AppColors.secondary.withValues(alpha: 0.5), width: isHighContrast ? 2.0 : 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 16, color: isHighContrast ? Colors.white : AppColors.onSecondaryContainer),
                      const SizedBox(width: 4),
                      Text(
                        activeFilters.isNotEmpty ? '${activeFilters.length} Active' : 'Configure',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isHighContrast ? Colors.white : AppColors.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (activeFilters.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: activeFilters.map((f) {
                return Chip(
                  avatar: Icon(Icons.check, size: 14, color: isHighContrast ? Colors.black : AppColors.secondary),
                  label: Text(
                    f,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w600,
                      color: isHighContrast ? Colors.black : AppColors.onSurface,
                    ),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => onClearFilter(f),
                  backgroundColor: isHighContrast ? Colors.white : AppColors.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: isHighContrast ? Colors.black : AppColors.outlineVariant, width: isHighContrast ? 1.5 : 1.0),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                );
              }).toList(),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              'All buses shown. Tap Configure to require ramps or step-free access.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
                color: isHighContrast ? const Color(0xFF1A1A1A) : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccessibilitySwitchTile extends StatelessWidget {
  const _AccessibilitySwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;

    return Container(
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.white : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighContrast ? Colors.black : (value ? AppColors.secondary : AppColors.outlineVariant),
          width: isHighContrast ? 2.0 : (value ? 1.5 : 1),
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        secondary: CircleAvatar(
          backgroundColor: isHighContrast
              ? (value ? const Color(0xFF001F3F) : const Color(0xFFE5E5E5))
              : (value ? AppColors.secondaryContainer : AppColors.surfaceContainer),
          child: Icon(
            icon,
            color: isHighContrast
                ? (value ? Colors.white : Colors.black)
                : (value ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant),
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w700,
            color: isHighContrast ? Colors.black : AppColors.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isHighContrast ? const Color(0xFF1A1A1A) : AppColors.onSurfaceVariant,
            fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        value: value,
        activeThumbColor: isHighContrast ? Colors.white : AppColors.secondary,
        activeTrackColor: isHighContrast ? const Color(0xFF001F3F) : null,
        onChanged: onChanged,
      ),
    );
  }
}

/// Search Modal with Auto-complete and Quick Location Option
class _StationSearchModal extends StatefulWidget {
  const _StationSearchModal({
    required this.title,
    required this.isFrom,
    required this.stations,
    required this.selectedStationId,
    required this.onSelect,
    this.onUseMyLocation,
  });

  final String title;
  final bool isFrom;
  final List<Station> stations;
  final String? selectedStationId;
  final ValueChanged<Station> onSelect;
  final VoidCallback? onUseMyLocation;

  @override
  State<_StationSearchModal> createState() => _StationSearchModalState();
}

class _StationSearchModalState extends State<_StationSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _filterWheelchairOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final filtered = widget.stations.where((s) {
      if (_filterWheelchairOnly && !s.hasRamp) return false;
      final q = _query.trim().toLowerCase();
      if (q.isEmpty) return true;
      return s.name.toLowerCase().contains(q) || s.id.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isHighContrast ? Colors.black : AppColors.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  iconSize: 26,
                  color: isHighContrast ? Colors.black : null,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (val) => setState(() => _query = val),
              style: TextStyle(
                fontSize: 17,
                color: isHighContrast ? Colors.black : null,
                fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
              ),
              decoration: InputDecoration(
                hintText: 'Type station or city (e.g. Pettah, Mount Lavinia)...',
                hintStyle: TextStyle(
                  color: isHighContrast ? const Color(0xFF4A4A4A) : null,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isHighContrast ? Colors.black : AppColors.primary,
                  size: 24,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: isHighContrast ? Colors.black : null),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isHighContrast ? Colors.white : AppColors.surfaceContainerLowest,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isHighContrast ? Colors.black : AppColors.outlineVariant,
                    width: isHighContrast ? 2.0 : 1.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isHighContrast ? Colors.black : AppColors.outlineVariant,
                    width: isHighContrast ? 2.0 : 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isHighContrast ? const Color(0xFF001F3F) : AppColors.primary,
                    width: 2.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Horizontally Scrollable Quick Filter Row (Prevents overflow on all screens)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (widget.isFrom && widget.onUseMyLocation != null) ...[
                    ActionChip(
                      avatar: Icon(Icons.my_location, size: 16, color: isHighContrast ? Colors.black : AppColors.primary),
                      label: Text(
                        'My Location',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isHighContrast ? Colors.black : AppColors.primary,
                        ),
                      ),
                      backgroundColor: isHighContrast ? Colors.white : AppColors.primaryFixed.withValues(alpha: 0.6),
                      side: BorderSide(
                        color: isHighContrast ? Colors.black : AppColors.primaryFixedDim,
                        width: isHighContrast ? 2.0 : 1.0,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onUseMyLocation!();
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  FilterChip(
                    label: Text(
                      'All Stops',
                      style: TextStyle(
                        color: isHighContrast ? Colors.black : null,
                        fontWeight: isHighContrast ? FontWeight.w700 : null,
                      ),
                    ),
                    selected: !_filterWheelchairOnly,
                    onSelected: (val) => setState(() => _filterWheelchairOnly = false),
                    selectedColor: isHighContrast ? const Color(0xFF001F3F).withValues(alpha: 0.2) : AppColors.primaryFixed,
                    side: isHighContrast ? const BorderSide(color: Colors.black, width: 2.0) : null,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    avatar: Icon(Icons.accessible, size: 16, color: isHighContrast ? Colors.black : null),
                    label: Text(
                      'Wheelchair Ramp',
                      style: TextStyle(
                        color: isHighContrast ? Colors.black : null,
                        fontWeight: isHighContrast ? FontWeight.w700 : null,
                      ),
                    ),
                    selected: _filterWheelchairOnly,
                    onSelected: (val) => setState(() => _filterWheelchairOnly = val),
                    selectedColor: isHighContrast ? const Color(0xFF001F3F).withValues(alpha: 0.2) : AppColors.secondaryContainer,
                    side: isHighContrast ? const BorderSide(color: Colors.black, width: 2.0) : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No matching stations found.\nTry a different spelling or clear filters.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isHighContrast ? const Color(0xFF1A1A1A) : AppColors.onSurfaceVariant,
                          fontSize: 16,
                          fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: isHighContrast ? Colors.black : null,
                      ),
                      itemBuilder: (context, index) {
                        final s = filtered[index];
                        final isSelected = s.id == widget.selectedStationId;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          selected: isSelected,
                          selectedTileColor: isHighContrast
                              ? const Color(0xFF001F3F).withValues(alpha: 0.15)
                              : AppColors.primaryContainer.withValues(alpha: 0.08),
                          leading: CircleAvatar(
                            backgroundColor: isHighContrast
                                ? (isSelected ? const Color(0xFF001F3F) : const Color(0xFFE5E5E5))
                                : (isSelected
                                    ? AppColors.primaryContainer
                                    : AppColors.surfaceContainer),
                            child: Icon(
                              widget.isFrom ? Icons.trip_origin_rounded : Icons.location_on_rounded,
                              color: isHighContrast
                                  ? (isSelected ? Colors.white : Colors.black)
                                  : (isSelected
                                      ? AppColors.onPrimary
                                      : (widget.isFrom ? AppColors.secondary : AppColors.error)),
                              size: 22,
                            ),
                          ),
                          title: Text(
                            s.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isHighContrast ? Colors.black : AppColors.onSurface,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              if (s.hasRamp) ...[
                                Icon(Icons.accessible, size: 14, color: isHighContrast ? Colors.black : AppColors.secondary),
                                const SizedBox(width: 4),
                                Text(
                                  'Ramp  ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isHighContrast ? Colors.black : AppColors.secondary,
                                    fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (s.hasElevator) ...[
                                Icon(Icons.elevator_outlined, size: 14, color: isHighContrast ? Colors.black : AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Elevator  ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isHighContrast ? Colors.black : AppColors.primary,
                                    fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (!s.hasRamp && !s.hasElevator)
                                Text(
                                  'Standard Stop',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isHighContrast ? const Color(0xFF1A1A1A) : AppColors.onSurfaceVariant,
                                    fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                            ],
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: isHighContrast ? const Color(0xFF001F3F) : AppColors.primaryContainer, size: 26)
                              : Icon(Icons.arrow_forward_ios, size: 14, color: isHighContrast ? Colors.black : AppColors.onSurfaceVariant),
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

/// Voice Search Dialog with High Accessibility Cues
class _VoiceSearchModal extends StatelessWidget {
  const _VoiceSearchModal({
    required this.isFrom,
    required this.stations,
    required this.onStationRecognized,
  });

  final bool isFrom;
  final List<Station> stations;
  final ValueChanged<Station> onStationRecognized;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final quickSuggestions = stations.take(6).toList();

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isHighContrast ? Colors.black : AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Semantics(
                label: 'Voice microphone listening animation',
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: isHighContrast ? const Color(0xFF001F3F) : AppColors.primaryFixed,
                  child: Icon(Icons.mic, size: 40, color: isHighContrast ? Colors.white : AppColors.primary),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isFrom ? 'Speak Boarding Stop' : 'Speak Destination Stop',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isHighContrast ? Colors.black : AppColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Listening... or tap a suggested stop below:',
                style: TextStyle(
                  fontSize: 14,
                  color: isHighContrast ? const Color(0xFF1A1A1A) : AppColors.onSurfaceVariant,
                  fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final s in quickSuggestions)
                    ActionChip(
                      avatar: Icon(Icons.location_on, size: 16, color: isHighContrast ? Colors.black : null),
                      label: Text(
                        s.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isHighContrast ? FontWeight.w700 : FontWeight.w600,
                          color: isHighContrast ? Colors.black : null,
                        ),
                      ),
                      backgroundColor: isHighContrast ? Colors.white : null,
                      side: isHighContrast ? const BorderSide(color: Colors.black, width: 2.0) : null,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      onPressed: () => onStationRecognized(s),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Popular Sri Lankan Transit Corridors (Sets both From & To in 1 Tap)
class _RecentSavedSection extends StatelessWidget {
  const _RecentSavedSection({required this.onSelectCorridor});

  final void Function(String fromId, String toId) onSelectCorridor;

  static const _corridors = [
    (
      'Route 100 • Galle Road Corridor',
      'st_pettah',
      'st_mt_lavinia',
      'Pettah ⇄ Mount Lavinia',
      'Low-floor buses with hydraulic wheelchair ramp',
      Icons.directions_bus_rounded,
    ),
    (
      'Route 138 • High-Level Road Corridor',
      'st_pettah',
      'st_kottawa',
      'Pettah ⇄ Kottawa Highway Hub',
      'Frequent express line with step-free stations',
      Icons.directions_bus_rounded,
    ),
    (
      'Route 120 • Horana Corridor',
      'st_pettah',
      'st_maharagama',
      'Pettah ⇄ Maharagama Bus Complex',
      'High-capacity central trunk service',
      Icons.directions_bus_rounded,
    ),
    (
      'Route 154 • Cross-town Link',
      'st_bambalapitiya',
      'st_pettah',
      'Bambalapitiya ⇄ Pettah Hub',
      'Direct coastal transfer route',
      Icons.directions_bus_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star_rounded, size: 22, color: isHighContrast ? Colors.black : AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Popular Accessible Routes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isHighContrast ? Colors.black : AppColors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Material(
          color: isHighContrast ? Colors.white : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          elevation: isHighContrast ? 0 : 1,
          shadowColor: AppColors.onSurface.withValues(alpha: 0.04),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: isHighContrast
                  ? Border.all(color: Colors.black, width: 2.0)
                  : Border.all(color: AppColors.surfaceVariant),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _corridors.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: isHighContrast ? Colors.black : AppColors.surfaceVariant),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isHighContrast ? const Color(0xFF001F3F) : AppColors.surfaceContainer,
                      child: Icon(
                        _corridors[i].$6,
                        color: isHighContrast ? Colors.white : AppColors.primaryContainer,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      _corridors[i].$4,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isHighContrast ? Colors.black : AppColors.onSurface,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          _corridors[i].$1,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isHighContrast ? Colors.black : AppColors.primary,
                          ),
                        ),
                        Text(
                          _corridors[i].$5,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
                            color: isHighContrast ? const Color(0xFF1A1A1A) : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_rounded, size: 18, color: isHighContrast ? Colors.black : AppColors.primary),
                    onTap: () => onSelectCorridor(_corridors[i].$2, _corridors[i].$3),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

