import '../../widgets/accessible_tap_target.dart';

import 'package:flutter/material.dart';

import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

import '../../models/station.dart';
import '../../services/nearby_stop_service.dart';
import '../../widgets/nearby_stops_sheet.dart';
import '../../logic/search_session.dart';
import '../../logic/transit_time.dart';
import '../../services/transit_search_backend.dart';
import '../../l10n/localization_context.dart';
import '../../services/accessibility_preferences_service.dart';
import '../../services/firestore_service.dart';
import 'route_results_screen.dart';

/// Journey Search screen — simplified, accessible origin/destination search,
/// streamlined travel time, accessibility-first filters, and popular corridors.
/// Phase 1: High accessibility UX enhancement inspired by LMT Go.
class JourneySearchScreen extends StatefulWidget {
  const JourneySearchScreen({
    super.key,
    this.service,
    this.searchBackend,
    this.nearbyStopService,
  });
  final FirestoreService? service;
  final TransitSearchBackend? searchBackend;
  final NearbyStopService? nearbyStopService;

  @override
  State<JourneySearchScreen> createState() => _JourneySearchScreenState();
}

class _JourneySearchScreenState extends State<JourneySearchScreen>
    with WidgetsBindingObserver {
  static const double _desktopBreakpoint = 768;
  late final FirestoreService _firestoreService =
      widget.service ?? FirestoreService();

  List<Station> _stations = [];
  Station? _selectedFromStation;
  Station? _selectedToStation;
  DateTime _selectedDate = TransitTime.civil(DateTime.now());
  TimeOfDay? _selectedTime;
  bool _isLoadingStations = true;

  // Accessibility requirements loaded from user preferences
  late final SearchNeedsDraft _needs;
  int _accountRevision = 0;
  bool get _wheelchairAccess => _needs.wheelchair;
  set _wheelchairAccess(bool value) => _needs.setWheelchair(value);
  bool get _stepFreeOnly => _needs.stepFree;
  set _stepFreeOnly(bool value) => _needs.setStepFree(value);
  bool _minimizeWalking = false;
  late final _backend = widget.searchBackend ?? TransitSearchBackend();
  SearchTimeAnchor? _clock;
  bool _dateEdited = false;
  int _clockRevision = 0;
  String? _clockError;
  DateTime get _now => TransitTime.civil(_clock?.now ?? DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _needs = SearchNeedsDraft(AccessibilityPreferencesService.instance);
    _needs.addListener(_onPreferencesChanged);
    _loadStations();
    _synchronizeClock();
  }

  Future<void> _synchronizeClock({bool force = false}) async {
    final revision = ++_clockRevision;
    final account = _needs.accountRevision;
    if (force) _backend.invalidateTime();
    setState(() {
      _clock = null;
      _clockError = null;
    });
    try {
      final receipt = await _backend.synchronizeTime();
      if (!mounted ||
          revision != _clockRevision ||
          account != _needs.accountRevision) {
        return;
      }
      setState(() {
        _clock = receipt;
        if (!_dateEdited) _selectedDate = TransitTime.civil(receipt.now);
      });
    } catch (_) {
      if (mounted &&
          revision == _clockRevision &&
          account == _needs.accountRevision) {
        setState(() => _clockError = 'Connect to verify search time.');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _synchronizeClock(force: true);
  }

  void _onPreferencesChanged() {
    if (mounted) {
      setState(() {
        if (_accountRevision != _needs.accountRevision) {
          _accountRevision = _needs.accountRevision;
          _selectedDate = _now;
          _selectedTime = null;
          _selectedFromStation = null;
          _selectedToStation = null;
          _dateEdited = false;
          _synchronizeClock(force: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _clockRevision++;
    WidgetsBinding.instance.removeObserver(this);
    _needs.removeListener(_onPreferencesChanged);
    _needs.dispose();
    super.dispose();
  }

  Future<void> _loadStations() async {
    try {
      await _firestoreService.refreshCatalogue();
      final list = FirestoreService.cachedStations;
      if (mounted) {
        setState(() {
          _stations = list;
          if (list.isEmpty) {
            _selectedFromStation = null;
            _selectedToStation = null;
            _isLoadingStations = false;
            return;
          }
          // Default: Pettah (st_pettah) to Mount Lavinia (st_mt_lavinia) for Route 100!
          _selectedFromStation = list.firstWhere(
            (s) => s.id == 'st_pettah',
            orElse: () => list.firstWhere(
              (s) => s.id == 'st_fort',
              orElse: () => list.first,
            ),
          );
          _selectedToStation = list.firstWhere(
            (s) => s.id == 'st_mt_lavinia',
            orElse: () => list.firstWhere(
              (s) => s.id == 'st_kottawa',
              orElse: () => list.last,
            ),
          );
          _isLoadingStations = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _stations = [];
          _selectedFromStation = null;
          _selectedToStation = null;
          _isLoadingStations = false;
        });
      }
    }
  }

  Future<void> _resyncDatabase() async {
    setState(() => _isLoadingStations = true);
    await _loadStations();
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
        SnackBar(
          content: Text(context.l10n.searchSwapped),
          duration: Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _useMyLocation() async {
    final account = _needs.accountRevision;
    final chosen = await showModalBottomSheet<Station>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      builder: (_) => NearbyStopsSheet(
        stations: List.of(_stations),
        service: widget.nearbyStopService ?? NearbyStopService(),
      ),
    );
    if (!mounted || account != _needs.accountRevision || chosen == null) return;
    final current = _stations.where((s) => s.id == chosen.id).firstOrNull;
    if (current != null) setState(() => _selectedFromStation = current);
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
        side: isHighContrast
            ? const BorderSide(color: Colors.black, width: 2)
            : BorderSide.none,
      ),
      builder: (context) {
        return _StationSearchModal(
          title: isFrom
              ? context.l10n.searchSelectBoarding
              : context.l10n.searchSelectDestination,
          isFrom: isFrom,
          stations: _stations,
          selectedStationId: isFrom
              ? _selectedFromStation?.id
              : _selectedToStation?.id,
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

  void _showStopSuggestionsDialog(bool isFrom) {
    final isHighContrast = context.isHighContrast;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: isHighContrast
            ? const BorderSide(color: Colors.black, width: 2)
            : BorderSide.none,
      ),
      builder: (context) {
        return _SuggestedStopsModal(
          isFrom: isFrom,
          stations: _stations,
          onStationSelected: (station) {
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
                  content: Text(context.l10n.searchStopSelected(station.name)),
                  backgroundColor: isHighContrast
                      ? const Color(0xFF001F3F)
                      : AppColors.primary,
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
        side: isHighContrast
            ? const BorderSide(color: Colors.black, width: 2)
            : BorderSide.none,
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
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
                    Expanded(
                      child: Text(
                        context.l10n.searchTravelChoice,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isHighContrast
                              ? Colors.black
                              : AppColors.onSurface,
                        ),
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.close),
                      iconSize: 26,
                      tooltip: MaterialLocalizations.of(context)
                          .closeButtonTooltip,
                      color: isHighContrast ? Colors.black : null,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isHighContrast
                          ? Colors.black
                          : (_selectedTime == null &&
                                    DateUtils.isSameDay(_selectedDate, _now)
                                ? AppColors.primary
                                : AppColors.outlineVariant),
                      width: isHighContrast ? 2.0 : 1.5,
                    ),
                  ),
                  tileColor: isHighContrast
                      ? (_selectedTime == null &&
                                DateUtils.isSameDay(_selectedDate, _now)
                            ? const Color(0xFF001F3F).withValues(alpha: 0.12)
                            : Colors.white)
                      : (_selectedTime == null &&
                                DateUtils.isSameDay(_selectedDate, _now)
                            ? AppColors.primaryFixed.withValues(alpha: 0.3)
                            : AppColors.surfaceContainerLowest),
                  leading: CircleAvatar(
                    backgroundColor: isHighContrast
                        ? const Color(0xFF001F3F)
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.bolt_rounded, size: 24),
                  ),
                  title: Text(
                    context.l10n.searchLeaveNow,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: isHighContrast ? Colors.black : null,
                    ),
                  ),
                  subtitle: Text(
                    context.l10n.searchWindowNotice,
                    style: TextStyle(
                      fontSize: 14,
                      color: isHighContrast ? const Color(0xFF1A1A1A) : null,
                      fontWeight: isHighContrast
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  trailing:
                      _selectedTime == null &&
                          DateUtils.isSameDay(_selectedDate, _now)
                      ? Icon(
                          Icons.check_circle,
                          color: isHighContrast
                              ? const Color(0xFF001F3F)
                              : AppColors.primary,
                          size: 26,
                        )
                      : null,
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedDate = _now;
                      _dateEdited = false;
                      _selectedTime = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isHighContrast
                          ? Colors.black
                          : AppColors.outlineVariant,
                      width: isHighContrast ? 2.0 : 1.0,
                    ),
                  ),
                  tileColor: isHighContrast
                      ? Colors.white
                      : AppColors.surfaceContainerLowest,
                  leading: CircleAvatar(
                    backgroundColor: isHighContrast
                        ? const Color(0xFF001F3F)
                        : AppColors.surfaceContainer,
                    child: Icon(
                      Icons.access_time_filled_rounded,
                      color: isHighContrast ? Colors.white : AppColors.primary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    context.l10n.searchSpecificTime,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: isHighContrast ? Colors.black : null,
                    ),
                  ),
                  subtitle: Text(
                    _selectedTime != null
                        ? context.l10n.searchSelectedTime(
                            _selectedTime!.format(context),
                          )
                        : context.l10n.searchChooseTime,
                    style: TextStyle(
                      fontSize: 14,
                      color: isHighContrast ? const Color(0xFF1A1A1A) : null,
                      fontWeight: isHighContrast
                          ? FontWeight.w600
                          : FontWeight.normal,
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isHighContrast
                          ? Colors.black
                          : AppColors.outlineVariant,
                      width: isHighContrast ? 2.0 : 1.0,
                    ),
                  ),
                  tileColor: isHighContrast
                      ? Colors.white
                      : AppColors.surfaceContainerLowest,
                  leading: CircleAvatar(
                    backgroundColor: isHighContrast
                        ? const Color(0xFF001F3F)
                        : AppColors.surfaceContainer,
                    child: Icon(
                      Icons.calendar_today_rounded,
                      color: isHighContrast ? Colors.white : AppColors.primary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    context.l10n.searchChangeDate,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: isHighContrast ? Colors.black : null,
                    ),
                  ),
                  subtitle: Text(
                    MaterialLocalizations.of(context)
                        .formatMediumDate(_selectedDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: isHighContrast ? const Color(0xFF1A1A1A) : null,
                      fontWeight: isHighContrast
                          ? FontWeight.w600
                          : FontWeight.normal,
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
        side: isHighContrast
            ? const BorderSide(color: Colors.black, width: 2)
            : BorderSide.none,
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.accessibility_new_rounded,
                          color: isHighContrast
                              ? Colors.black
                              : AppColors.secondary,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.l10n.searchNeedsTitle,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isHighContrast
                                  ? Colors.black
                                  : AppColors.onSurface,
                            ),
                          ),
                        ),

                        IconButton(
                          icon: const Icon(Icons.close),
                          iconSize: 26,
                          tooltip: MaterialLocalizations.of(context)
                              .closeButtonTooltip,
                          color: isHighContrast ? Colors.black : null,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.searchTemporaryHelp,
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
                    const SizedBox(height: 16),
                    // Quick Accessibility Presets
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(
                              context.buttonHeight,
                              context.buttonHeight,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: isHighContrast
                                  ? Colors.black
                                  : (_wheelchairAccess && _stepFreeOnly
                                        ? AppColors.secondary
                                        : AppColors.outlineVariant),
                              width:
                                  (_wheelchairAccess && _stepFreeOnly ||
                                      isHighContrast)
                                  ? 2
                                  : 1,
                            ),
                            backgroundColor: _wheelchairAccess && _stepFreeOnly
                                ? (isHighContrast
                                      ? const Color(0xFF001F3F)
                                            .withValues(alpha: 0.15)
                                      : AppColors.secondaryContainer.withValues(
                                          alpha: 0.3,
                                        ))
                                : null,
                          ),
                          onPressed: () {
                            setSheetState(() {
                              _wheelchairAccess = true;
                              _stepFreeOnly = true;
                              _minimizeWalking = false;
                            });
                            setState(() {});
                          },
                          child: Text(
                            context.l10n.searchWheelchairChip,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isHighContrast ? Colors.black : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(
                              context.buttonHeight,
                              context.buttonHeight,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: isHighContrast
                                  ? Colors.black
                                  : (!_wheelchairAccess && _stepFreeOnly
                                        ? AppColors.secondary
                                        : AppColors.outlineVariant),
                              width:
                                  (!_wheelchairAccess && _stepFreeOnly ||
                                      isHighContrast)
                                  ? 2
                                  : 1,
                            ),
                            backgroundColor: !_wheelchairAccess && _stepFreeOnly
                                ? (isHighContrast
                                      ? const Color(0xFF001F3F)
                                            .withValues(alpha: 0.15)
                                      : AppColors.secondaryContainer.withValues(
                                          alpha: 0.3,
                                        ))
                                : null,
                          ),
                          onPressed: () {
                            setSheetState(() {
                              _wheelchairAccess = false;
                              _stepFreeOnly = true;
                              _minimizeWalking = false;
                            });
                            setState(() {});
                          },
                          child: Text(
                            context.l10n.searchStepFreeChip,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isHighContrast ? Colors.black : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: context.l10n.searchResetHelp,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(54, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: isHighContrast
                                  ? const BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            onPressed: () {
                              setSheetState(() {
                                _needs.reset();
                                _minimizeWalking = false;
                              });
                              setState(() {});
                            },
                            child: Text(
                              context.l10n.searchReset,
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
                      title: context.l10n.searchRamp,
                      subtitle: context.l10n.searchRampHelp,
                      value: _wheelchairAccess,
                      onChanged: (val) {
                        setSheetState(() => _wheelchairAccess = val);
                        setState(() => _wheelchairAccess = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    _AccessibilitySwitchTile(
                      icon: Icons.elevator_outlined,
                      title: context.l10n.searchStepFree,
                      subtitle: context.l10n.searchStepFreeHelp,
                      value: _stepFreeOnly,
                      onChanged: (val) {
                        setSheetState(() => _stepFreeOnly = val);
                        setState(() => _stepFreeOnly = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    _AccessibilitySwitchTile(
                      icon: Icons.directions_walk_rounded,
                      title: context.l10n.searchMinWalking,
                      subtitle: context.l10n.searchWalkingUnknown,
                      value: false,
                      onChanged: null,
                    ),
                    const SizedBox(height: 24),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: isHighContrast
                              ? const Color(0xFF001F3F)
                              : AppColors.primaryContainer,
                          foregroundColor: Colors.white,
                          side: isHighContrast
                              ? const BorderSide(color: Colors.black, width: 2)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          context.l10n.searchApply,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
    final accountRevision = _needs.accountRevision;
    if (_clock?.isFresh != true) {
      await _synchronizeClock();
    }
    if (!mounted ||
        accountRevision != _needs.accountRevision ||
        _clock?.isFresh != true) {
      return;
    }
    final now = _now;
    final last = TransitTime.civil(_clock!.windowEnd);
    final firstDate = DateUtils.dateOnly(now);
    final lastDate = DateUtils.dateOnly(last);
    final selected = DateUtils.dateOnly(_selectedDate);
    final initial = selected.isBefore(firstDate)
        ? firstDate
        : selected.isAfter(lastDate)
        ? lastDate
        : selected;
    final picked = await showDatePicker(
      initialEntryMode:
          context.hasLargeTargets && MediaQuery.sizeOf(context).width < 420
          ? DatePickerEntryMode.inputOnly
          : DatePickerEntryMode.calendar,
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (!mounted || accountRevision != _needs.accountRevision) return;
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateEdited = true;
      });
    }
  }

  Future<void> _pickTime() async {
    final accountRevision = _needs.accountRevision;
    if (_clock?.isFresh != true) {
      await _synchronizeClock();
    }
    if (!mounted ||
        accountRevision != _needs.accountRevision ||
        _clock?.isFresh != true) {
      return;
    }
    final picked = await showTimePicker(
      initialEntryMode:
          context.hasLargeTargets && MediaQuery.sizeOf(context).width < 420
          ? TimePickerEntryMode.inputOnly
          : TimePickerEntryMode.dial,
      context: context,
      initialTime:
          _selectedTime ?? TimeOfDay(hour: _now.hour, minute: _now.minute),
    );
    if (picked != null) {
      if (!mounted ||
          accountRevision != _needs.accountRevision ||
          _clock?.isFresh != true) {
        return;
      }
      if (BoardingSearchWindow.colombo(
            _clock!.now,
            end: _clock!.windowEnd,
          ).lowerBound(
            date: _selectedDate,
            minutes: picked.hour * 60 + picked.minute,
          ) ==
          null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.searchWindowInvalid)),
        );
        return;
      }
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _searchRoutes() async {
    final accountRevision = _needs.accountRevision;
    if (!_needs.isReady) return;
    if (_clock?.isFresh != true) await _synchronizeClock();
    if (!mounted ||
        accountRevision != _needs.accountRevision ||
        !_needs.isReady ||
        _clock?.isFresh != true) {
      return;
    }
    final window = BoardingSearchWindow.colombo(
      _clock!.now,
      end: _clock!.windowEnd,
    );
    if (window.lowerBound(
          date: _selectedDate,
          minutes: _selectedTime == null
              ? null
              : _selectedTime!.hour * 60 + _selectedTime!.minute,
        ) ==
        null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.searchWindowInvalid)));
      return;
    }
    if (_selectedFromStation == null || _selectedToStation == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.searchEndpointsRequired)),
        );
      return;
    }

    if (_selectedFromStation!.id == _selectedToStation!.id) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(context.l10n.searchEndpointsDifferent),
            backgroundColor: context.errorColor,
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
          selectedDate: !_dateEdited && _selectedTime == null
              ? null
              : _selectedDate,
          selectedTime: _selectedTime,
          needsDraft: _needs,
          searchBackend: _backend,
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
            onProfile: () => AppNavigation.openProfile(context),
            onSync: _resyncDatabase,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, isDesktop ? 24 : 24),
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
                          onVoiceSearchFrom: () =>
                              _showStopSuggestionsDialog(true),
                          onVoiceSearchTo: () =>
                              _showStopSuggestionsDialog(false),
                          isLoading: _isLoadingStations,
                        ),
                        const SizedBox(height: 14),

                        // Travel Time Row (Clean, single row, defaults to Depart Now)
                        _TravelTimeCard(
                          selectedDate: _selectedDate,
                          currentTime: _now,
                          selectedTime: _selectedTime,
                          onTap: _showTravelTimeOptions,
                        ),
                        const SizedBox(height: 14),

                        // Single Accessibility Filter Chip / Row (Phase 1 clean design)
                        if (_clock == null) ...[
                          Text(
                            _clockError == null
                                ? context.l10n.verifyingSearchTime
                                : context.l10n.searchTimeUnavailable,
                          ),
                          if (_clockError != null)
                            TextButton(
                              onPressed: () => _synchronizeClock(force: true),
                              child: Text(context.l10n.retrySearchTime),
                            ),
                          const SizedBox(height: 8),
                        ],
                        _AccessibilityFilterRow(
                          activeFilters: activeFilters,
                          onTap: _showAccessibilityFilterSheet,
                          onClearFilter: (filter) {
                            setState(() {
                              if (filter == 'Ramp Required') {
                                _wheelchairAccess = false;
                              }
                              if (filter == 'Step-Free') _stepFreeOnly = false;
                              if (filter == 'Min Walk') {
                                _minimizeWalking = false;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // Full-width prominent "Find Buses" action button
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: context.hasLargeTargets ? 64 : 56,
                          ),
                          child: FilledButton(
                            onPressed: _needs.isReady && _clock != null
                                ? _searchRoutes
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: isHighContrast
                                  ? const Color(0xFF001F3F)
                                  : AppColors.primaryContainer,
                              foregroundColor: Colors.white,
                              side: isHighContrast
                                  ? const BorderSide(
                                      color: Colors.black,
                                      width: 2.0,
                                    )
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_bus_rounded, size: 26),
                                SizedBox(width: 12),
                                Flexible(child: Text(context.l10n.searchFind)),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward_rounded, size: 22),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Popular Corridors & Quick Trips (One-tap selection)
                        if (_stations.isEmpty) Text(context.l10n.searchNoStops),
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
  const _TopBar({required this.onProfile, this.onSync});

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
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.searchPlan,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isHighContrast
                            ? Colors.black
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  if (onSync != null)
                    IconButton(
                      onPressed: onSync,
                      icon: const Icon(Icons.cloud_sync_outlined),
                      color: isHighContrast ? Colors.black : AppColors.primary,
                      tooltip: context.l10n.searchSync,
                      iconSize: 26,
                    ),
                  const SizedBox(width: 4),
                  AccessibleTapTarget(
                    child: InkWell(
                      onTap: onProfile,
                      borderRadius: BorderRadius.circular(999),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: isHighContrast
                            ? const Color(0xFF001F3F)
                            : AppColors.surfaceContainer,
                        child: Icon(
                          Icons.person,
                          color: isHighContrast
                              ? Colors.white
                              : AppColors.primaryContainer,
                          size: 22,
                        ),
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
                  headerLabel: context.l10n.searchBoardingHeading,
                  headerColor: AppColors.secondary,
                  stationName:
                      fromStation?.name ?? context.l10n.searchChooseBoarding,
                  subtitle: fromStation != null
                      ? (fromStation!.hasRamp
                            ? context.l10n.searchRampAvailable
                            : context.l10n.searchStandardStop)
                      : context.l10n.searchTapBoarding,
                  onTap: onTapFrom,
                  onSuggestionsTap: onVoiceSearchFrom,
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
                          color: isHighContrast
                              ? Colors.black
                              : AppColors.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Divider(
                          height: 1,
                          color: isHighContrast
                              ? Colors.black
                              : AppColors.surfaceVariant,
                          thickness: isHighContrast ? 1.5 : 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        button: true,
                        label: context.l10n.searchSwap,
                        child: Material(
                          color: isHighContrast
                              ? Colors.white
                              : AppColors.surfaceContainerLow,
                          shape: CircleBorder(
                            side: isHighContrast
                                ? const BorderSide(
                                    color: Colors.black,
                                    width: 2.0,
                                  )
                                : BorderSide.none,
                          ),
                          elevation: isHighContrast ? 0 : 1.5,
                          child: AccessibleTapTarget(
                            child: InkWell(
                              onTap: onSwap,
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: context.minTapHeight,
                                height: context.minTapHeight,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.swap_vert_rounded,
                                  color: isHighContrast
                                      ? Colors.black
                                      : AppColors.primary,
                                  size: context.tapIconSize + 2,
                                ),
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
                  headerLabel: context.l10n.searchDestinationHeading,
                  headerColor: AppColors.error,
                  stationName:
                      toStation?.name ?? context.l10n.searchChooseDestination,
                  subtitle: toStation != null
                      ? (toStation!.hasRamp
                            ? context.l10n.searchAccessibleDestination
                            : context.l10n.searchStandardStop)
                      : context.l10n.searchTapDestination,
                  onTap: onTapTo,
                  onSuggestionsTap: onVoiceSearchTo,
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
    required this.onSuggestionsTap,
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
  final VoidCallback onSuggestionsTap;
  final VoidCallback? onUseMyLocation;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final hasLargeTargets = context.hasLargeTargets;
    final effectiveHeaderColor = isHighContrast ? Colors.black : headerColor;
    final effectiveIconColor = isHighContrast ? Colors.black : iconColor;

    return Semantics(
      button: true,
      label: '$headerLabel: $stationName',
      child: AccessibleTapTarget(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: hasLargeTargets ? 14 : 12,
              vertical: hasLargeTargets ? 18 : 12,
            ),
            decoration: BoxDecoration(
              color: isHighContrast
                  ? Colors.white
                  : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: isHighContrast
                  ? Border.all(color: Colors.black, width: 2.0)
                  : Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.6),
                    ),
            ),
            child: Row(
              children: [
                // Indicator Dot / Icon
                Container(
                  width: hasLargeTargets ? 46 : 36,
                  height: hasLargeTargets ? 46 : 36,
                  decoration: BoxDecoration(
                    color: isHighContrast
                        ? const Color(0xFFE5E5E5)
                        : iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: isHighContrast
                        ? Border.all(color: Colors.black, width: 1.5)
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: effectiveIconColor,
                    size: hasLargeTargets ? 24 : 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Text contents
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headerLabel,
                            style: TextStyle(
                              fontSize: hasLargeTargets ? 12 : 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: effectiveHeaderColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        stationName,
                        style: TextStyle(
                          fontSize: hasLargeTargets ? 19 : 17,
                          fontWeight: FontWeight.w700,
                          color: isHighContrast
                              ? Colors.black
                              : AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: hasLargeTargets ? 13.5 : 12,
                          fontWeight: isHighContrast
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isHighContrast
                              ? const Color(0xFF1A1A1A)
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                      if (isFrom && onUseMyLocation != null) ...[
                        const SizedBox(height: 8),
                        AccessibleTapTarget(
                          child: InkWell(
                            onTap: onUseMyLocation,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isHighContrast
                                    ? const Color(0xFF001F3F)
                                    : AppColors.primaryFixed,
                                borderRadius: BorderRadius.circular(6),
                                border: isHighContrast
                                    ? Border.all(
                                        color: Colors.black,
                                        width: 1.0,
                                      )
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.my_location,
                                    size: 16,
                                    color: isHighContrast
                                        ? Colors.white
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      context.l10n.searchMyLocation,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isHighContrast
                                            ? Colors.white
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Suggested-stop control
                Semantics(
                  button: true,
                  label: isFrom
                      ? context.l10n.searchBoardingSuggestions
                      : context.l10n.searchDestinationSuggestions,
                  child: IconButton(
                    onPressed: onSuggestionsTap,
                    icon: Icon(
                      Icons.list_alt_rounded,
                      color: isHighContrast ? Colors.black : AppColors.primary,
                    ),
                    iconSize: context.tapIconSize,
                    tooltip: context.l10n.searchSuggestions,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: hasLargeTargets ? 48 : 38,
                      minHeight: hasLargeTargets ? 48 : 38,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: isHighContrast
                      ? Colors.black
                      : AppColors.onSurfaceVariant,
                  size: hasLargeTargets ? 28 : 22,
                ),
              ],
            ),
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
    this.currentTime,
  });

  final DateTime selectedDate;
  final TimeOfDay? selectedTime;
  final DateTime? currentTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final isToday = DateUtils.isSameDay(
      selectedDate,
      currentTime ?? TransitTime.civil(DateTime.now()),
    );
    final String timeLabel;
    final bool isDepartNow = selectedTime == null && isToday;

    if (isDepartNow) {
      timeLabel = context.l10n.searchDepartNow;
    } else if (selectedTime != null && isToday) {
      timeLabel = context.l10n.searchTodayAt(selectedTime!.format(context));
    } else if (selectedTime != null) {
      timeLabel = context.l10n.searchDateAt(
        MaterialLocalizations.of(context).formatMediumDate(selectedDate),
        selectedTime!.format(context),
      );
    } else {
      timeLabel = MaterialLocalizations.of(context)
          .formatMediumDate(selectedDate);
    }

    return AccessibleTapTarget(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isHighContrast
                ? Colors.white
                : AppColors.surfaceContainerLowest,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isHighContrast
                        ? const Color(0xFFE5E5E5)
                        : (isDepartNow
                              ? AppColors.primaryFixed
                              : AppColors.surfaceContainer),
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
                          context.l10n.searchTravelHeading,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isHighContrast
                                ? Colors.black
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeLabel,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: isHighContrast
                                ? Colors.black
                                : AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isHighContrast
                        ? const Color(0xFF001F3F)
                        : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: isHighContrast
                        ? Border.all(color: Colors.black, width: 1.5)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          context.l10n.searchChange,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isHighContrast
                                ? Colors.white
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.expand_more,
                        size: 16,
                        color: isHighContrast
                            ? Colors.white
                            : AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.accessibility_new_rounded,
                size: 22,
                color: isHighContrast ? Colors.black : AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.searchOptions,

                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isHighContrast ? Colors.black : AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              // Accessible filter trigger chip
              AccessibleTapTarget(
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 48,
                      minWidth: 48,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isHighContrast
                          ? const Color(0xFF001F3F)
                          : AppColors.secondaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isHighContrast
                            ? Colors.black
                            : AppColors.secondary.withValues(alpha: 0.5),
                        width: isHighContrast ? 2.0 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 16,
                          color: isHighContrast
                              ? Colors.white
                              : AppColors.onSecondaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            activeFilters.isNotEmpty
                                ? context.l10n.searchActiveNeeds(
                                    activeFilters.length,
                                  )
                                : context.l10n.searchConfigure,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isHighContrast
                                  ? Colors.white
                                  : AppColors.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                  avatar: Icon(
                    Icons.check,
                    size: 14,
                    color: isHighContrast ? Colors.black : AppColors.secondary,
                  ),
                  label: Text(
                    switch (f) {
                      'Ramp Required' => context.l10n.searchRampRequired,
                      'Step-Free' => context.l10n.searchStepFreeFilter,
                      _ => context.l10n.searchMinWalkFilter,
                    },
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isHighContrast
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isHighContrast
                          ? Colors.black
                          : AppColors.onSurface,
                    ),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => onClearFilter(f),
                  backgroundColor: isHighContrast
                      ? Colors.white
                      : AppColors.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isHighContrast
                          ? Colors.black
                          : AppColors.outlineVariant,
                      width: isHighContrast ? 1.5 : 1.0,
                    ),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                );
              }).toList(),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              context.l10n.searchAllBusesHelp,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighContrast
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: isHighContrast
                    ? const Color(0xFF1A1A1A)
                    : AppColors.onSurfaceVariant,
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
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;

    return Container(
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.white : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighContrast
              ? Colors.black
              : (value ? AppColors.secondary : AppColors.outlineVariant),
          width: isHighContrast ? 2.0 : (value ? 1.5 : 1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),
          secondary: CircleAvatar(
            backgroundColor: isHighContrast
                ? (value ? const Color(0xFF001F3F) : const Color(0xFFE5E5E5))
                : (value
                      ? AppColors.secondaryContainer
                      : AppColors.surfaceContainer),
            child: Icon(
              icon,
              color: isHighContrast
                  ? (value ? Colors.white : Colors.black)
                  : (value
                        ? AppColors.onSecondaryContainer
                        : AppColors.onSurfaceVariant),
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
              color: isHighContrast
                  ? const Color(0xFF1A1A1A)
                  : AppColors.onSurfaceVariant,
              fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          value: value,
          activeThumbColor: isHighContrast ? Colors.white : AppColors.secondary,
          activeTrackColor: isHighContrast ? const Color(0xFF001F3F) : null,
          onChanged: onChanged,
        ),
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
                      color: isHighContrast
                          ? Colors.black
                          : AppColors.onSurface,
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
                fontWeight: isHighContrast
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
              decoration: InputDecoration(
                hintText: context.l10n.searchStationHint,
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
                        icon: Icon(
                          Icons.clear,
                          color: isHighContrast ? Colors.black : null,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isHighContrast
                    ? Colors.white
                    : AppColors.surfaceContainerLowest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isHighContrast
                        ? Colors.black
                        : AppColors.outlineVariant,
                    width: isHighContrast ? 2.0 : 1.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isHighContrast
                        ? Colors.black
                        : AppColors.outlineVariant,
                    width: isHighContrast ? 2.0 : 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isHighContrast
                        ? const Color(0xFF001F3F)
                        : AppColors.primary,
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
                    AccessibleTapTarget(
                      child: ActionChip(
                        avatar: Icon(
                          Icons.my_location,
                          size: 16,
                          color: isHighContrast
                              ? Colors.black
                              : AppColors.primary,
                        ),
                        label: Text(
                          context.l10n.searchMyLocation,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isHighContrast
                                ? Colors.black
                                : AppColors.primary,
                          ),
                        ),
                        backgroundColor: isHighContrast
                            ? Colors.white
                            : AppColors.primaryFixed.withValues(alpha: 0.6),
                        side: BorderSide(
                          color: isHighContrast
                              ? Colors.black
                              : AppColors.primaryFixedDim,
                          width: isHighContrast ? 2.0 : 1.0,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onUseMyLocation!();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  AccessibleTapTarget(
                    child: FilterChip(
                      label: Text(
                        context.l10n.searchAllStops,
                        style: TextStyle(
                          color: isHighContrast ? Colors.black : null,
                          fontWeight: isHighContrast ? FontWeight.w700 : null,
                        ),
                      ),
                      selected: !_filterWheelchairOnly,
                      onSelected: (val) =>
                          setState(() => _filterWheelchairOnly = false),
                      selectedColor: isHighContrast
                          ? const Color(0xFF001F3F).withValues(alpha: 0.2)
                          : AppColors.primaryFixed,
                      side: isHighContrast
                          ? const BorderSide(color: Colors.black, width: 2.0)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AccessibleTapTarget(
                    child: FilterChip(
                      avatar: Icon(
                        Icons.accessible,
                        size: 16,
                        color: isHighContrast ? Colors.black : null,
                      ),
                      label: Text(
                        context.l10n.searchRamp,
                        style: TextStyle(
                          color: isHighContrast ? Colors.black : null,
                          fontWeight: isHighContrast ? FontWeight.w700 : null,
                        ),
                      ),
                      selected: _filterWheelchairOnly,
                      onSelected: (val) =>
                          setState(() => _filterWheelchairOnly = val),
                      selectedColor: isHighContrast
                          ? const Color(0xFF001F3F).withValues(alpha: 0.2)
                          : AppColors.secondaryContainer,
                      side: isHighContrast
                          ? const BorderSide(color: Colors.black, width: 2.0)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        context.l10n.searchNoMatches,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isHighContrast
                              ? const Color(0xFF1A1A1A)
                              : AppColors.onSurfaceVariant,
                          fontSize: 16,
                          fontWeight: isHighContrast
                              ? FontWeight.w600
                              : FontWeight.normal,
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          selected: isSelected,
                          selectedTileColor: isHighContrast
                              ? const Color(0xFF001F3F).withValues(alpha: 0.15)
                              : AppColors.primaryContainer.withValues(
                                  alpha: 0.08,
                                ),
                          leading: CircleAvatar(
                            backgroundColor: isHighContrast
                                ? (isSelected
                                      ? const Color(0xFF001F3F)
                                      : const Color(0xFFE5E5E5))
                                : (isSelected
                                      ? AppColors.primaryContainer
                                      : AppColors.surfaceContainer),
                            child: Icon(
                              widget.isFrom
                                  ? Icons.trip_origin_rounded
                                  : Icons.location_on_rounded,
                              color: isHighContrast
                                  ? (isSelected ? Colors.white : Colors.black)
                                  : (isSelected
                                        ? AppColors.onPrimary
                                        : (widget.isFrom
                                              ? AppColors.secondary
                                              : AppColors.error)),
                              size: 22,
                            ),
                          ),
                          title: Text(
                            s.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isHighContrast
                                  ? Colors.black
                                  : AppColors.onSurface,
                            ),
                          ),
                          subtitle: Wrap(
                            children: [
                              if (s.hasRamp) ...[
                                Icon(
                                  Icons.accessible,
                                  size: 14,
                                  color: isHighContrast
                                      ? Colors.black
                                      : AppColors.secondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  context.l10n.searchRampBadge,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isHighContrast
                                        ? Colors.black
                                        : AppColors.secondary,
                                    fontWeight: isHighContrast
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (s.hasElevator) ...[
                                Icon(
                                  Icons.elevator_outlined,
                                  size: 14,
                                  color: isHighContrast
                                      ? Colors.black
                                      : AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  context.l10n.searchElevatorBadge,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isHighContrast
                                        ? Colors.black
                                        : AppColors.primary,
                                    fontWeight: isHighContrast
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (!s.hasRamp && !s.hasElevator)
                                Text(
                                  context.l10n.searchStandardStop,
                                  style: TextStyle(
                                    fontSize: 13,
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
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: isHighContrast
                                      ? const Color(0xFF001F3F)
                                      : AppColors.primaryContainer,
                                  size: 26,
                                )
                              : Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: isHighContrast
                                      ? Colors.black
                                      : AppColors.onSurfaceVariant,
                                ),
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

/// Manual stop suggestions; speech recognition is not available.
class _SuggestedStopsModal extends StatelessWidget {
  const _SuggestedStopsModal({
    required this.isFrom,
    required this.stations,
    required this.onStationSelected,
  });

  final bool isFrom;
  final List<Station> stations;
  final ValueChanged<Station> onStationSelected;

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
                    color: isHighContrast
                        ? Colors.black
                        : AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Semantics(
                label: context.l10n.searchSuggestionIcon,
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: isHighContrast
                      ? const Color(0xFF001F3F)
                      : AppColors.primaryFixed,
                  child: Icon(
                    Icons.list_alt_rounded,
                    size: 40,
                    color: isHighContrast ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isFrom
                    ? context.l10n.searchSuggestedBoarding
                    : context.l10n.searchSuggestedDestination,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isHighContrast ? Colors.black : AppColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.searchVoiceUnavailable,
                style: TextStyle(
                  fontSize: 14,
                  color: isHighContrast
                      ? const Color(0xFF1A1A1A)
                      : AppColors.onSurfaceVariant,
                  fontWeight: isHighContrast
                      ? FontWeight.w600
                      : FontWeight.normal,
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
                    AccessibleTapTarget(
                      child: ActionChip(
                        avatar: Icon(
                          Icons.location_on,
                          size: 16,
                          color: isHighContrast ? Colors.black : null,
                        ),
                        label: Text(
                          s.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isHighContrast
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isHighContrast ? Colors.black : null,
                          ),
                        ),
                        backgroundColor: isHighContrast ? Colors.white : null,
                        side: isHighContrast
                            ? const BorderSide(color: Colors.black, width: 2.0)
                            : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        onPressed: () => onStationSelected(s),
                      ),
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
