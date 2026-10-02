import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../models/bus.dart';
import '../../models/report.dart';
import '../../models/station.dart';
import '../../services/firestore_service.dart';
import 'report_submitted_screen.dart';

enum ReportCategory {
  rampAccess,
  elevatorOut,
  audioVisualIssue,
  tactilePavingBlocked,
  driverAssistanceDenied,
  crowding,
  cleanliness,
  safetyHazard,
  other,
}

enum ReportSeverity { minor, moderate, major }

/// Community accessibility condition reporting screen — target selector, category, severity, photo, details.
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
  final ImagePicker _picker = ImagePicker();

  static const Map<ReportCategory, List<String>> _subCategoryOptions = {
    ReportCategory.rampAccess: [
      'Ramp broken / deployment motor jammed',
      'Ramp gradient too steep or uneven',
      'Pathway to ramp blocked by obstacles',
      'Non-slip ramp surface damaged or slippery',
      'Ramp safety guardrail missing or damaged',
    ],
    ReportCategory.elevatorOut: [
      'Elevator completely out of service',
      'Elevator doors failing to open / jammed',
      'Elevator floor level misaligned with platform',
      'Braille / Audio button feedback broken',
      'Emergency call button non-responsive',
    ],
    ReportCategory.audioVisualIssue: [
      'Bus stop display screen turned off or frozen',
      'Next-stop audio announcements silent',
      'Visual route display showing wrong destination',
      'Braille / tactile station sign missing',
      'PA announcement system distorted',
    ],
    ReportCategory.tactilePavingBlocked: [
      'Tactile paving tiles cracked, broken, or missing',
      'Tactile pathway blocked by vehicles or luggage',
      'Loose tiles causing trip hazard',
      'Tactile path ends abruptly without warning tile',
    ],
    ReportCategory.driverAssistanceDenied: [
      'Driver refused to deploy ramp upon request',
      'Driver did not allow enough time to sit down',
      'Vehicle parked too far from platform curb',
      'Wheelchair securement straps not fastened',
    ],
    ReportCategory.crowding: [
      'Priority seating occupied by non-priority riders',
      'Wheelchair / stroller bay blocked by heavy bags',
      'Vehicle overcrowded - unable to board safely',
      'Platform queue area dangerously congested',
    ],
    ReportCategory.cleanliness: [
      'Spills or litter in priority seating area',
      'Dirty handrails or seating upholstery',
      'Vandalism / graffiti obstructing accessibility info',
      'Strong unpleasant or toxic odor',
    ],
    ReportCategory.safetyHazard: [
      'Slippery floor / uncleaned liquid spill',
      'Broken seat / loose handrail or grab bar',
      'Trip hazard on platform edge or stairs',
      'Inadequate lighting in walkway',
      'Wide gap between bus/train and platform',
    ],
    ReportCategory.other: [
      'General accessibility concern',
      'Station staff unavailable or unhelpful',
      'Wide ticket gate for wheelchairs locked',
      'Other accessibility issue',
    ],
  };

  late final TextEditingController _locationController;
  late final TextEditingController _detailsController;
  final FirestoreService _firestoreService = FirestoreService();

  late String _targetType;
  ReportCategory _category = ReportCategory.rampAccess;
  String? _selectedSubCategory;
  String? _selectedPhotoUrl;
  ReportSeverity _severity = ReportSeverity.moderate;
  bool _isSubmitting = false;

  List<Station> _availableStations = [];
  List<Bus> _availableBuses = [];
  Station? _selectedStation;
  Bus? _selectedBus;

  @override
  void initState() {
    super.initState();
    _targetType = widget.targetType.isNotEmpty ? widget.targetType : 'station';
    _locationController = TextEditingController(text: widget.initialLocation);
    _detailsController = TextEditingController();
    _selectedSubCategory = _subCategoryOptions[_category]!.first;
    _loadTargetMetadata();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  String _getBusTitle(Bus b) {
    if (b.busNo != null && b.busNo!.isNotEmpty) {
      return 'Bus Route ${b.routeNo} (${b.busNo})';
    }
    return 'Bus Route ${b.routeNo}';
  }

  Future<void> _loadTargetMetadata() async {
    try {
      final stations = await _firestoreService.getStations();
      final buses = await _firestoreService.getBuses();

      if (mounted) {
        setState(() {
          _availableStations = stations;
          _availableBuses = buses;

          if (widget.targetId.isNotEmpty) {
            if (_targetType == 'station') {
              try {
                _selectedStation = stations.firstWhere(
                  (s) => s.id == widget.targetId,
                );
                _locationController.text = _selectedStation!.name;
              } catch (_) {}
            } else {
              try {
                _selectedBus = buses.firstWhere((b) => b.id == widget.targetId);
                _locationController.text = _getBusTitle(_selectedBus!);
              } catch (_) {}
            }
          } else if (_locationController.text.isEmpty && stations.isNotEmpty) {
            _selectedStation = stations.first;
            _locationController.text = stations.first.name;
          }
        });
      }
    } catch (_) {}
  }

  String _getOrCreateUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid.isNotEmpty) {
      return user.uid;
    }
    _cachedGuestUserId ??=
        'guest_user_${DateTime.now().millisecondsSinceEpoch}';
    return _cachedGuestUserId!;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (pickedFile != null && mounted) {
        setState(() {
          _selectedPhotoUrl = pickedFile.path;
        });
        _showSnack(
          source == ImageSource.camera
              ? 'Photo captured successfully!'
              : 'Photo selected from device gallery!',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Unable to access device photo: ${e.toString()}');
      }
    }
  }

  void _showPhotoPickerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Attach Condition Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(
                    Icons.camera_alt,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
                title: const Text(
                  'Take Photo with Camera',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Capture live evidence photo using device camera',
                ),
                onTap: () {
                  Navigator.of(modalContext).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(
                    Icons.photo_library,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
                title: const Text(
                  'Choose from Device Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Select an existing photo saved on your device',
                ),
                onTap: () {
                  Navigator.of(modalContext).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return Image.network(
        pathOrUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.surfaceContainer,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 40, color: AppColors.outline),
              SizedBox(height: 8),
              Text(
                'Photo preview unavailable',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    try {
      final file = File(pathOrUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.surfaceContainer,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 40, color: AppColors.outline),
                SizedBox(height: 8),
                Text(
                  'Photo preview unavailable',
                  style: TextStyle(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      }
    } catch (_) {}

    return Image.network(
      pathOrUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.surfaceContainer,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 40, color: AppColors.outline),
            SizedBox(height: 8),
            Text(
              'Photo preview unavailable',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final locationName = _locationController.text.trim();
    if (locationName.isEmpty) {
      _showSnack('Please select or enter a location or vehicle.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = _getOrCreateUserId();

      String derivedTargetId = '';
      if (_targetType == 'station') {
        derivedTargetId =
            _selectedStation?.id ??
            (widget.targetId.isNotEmpty
                ? widget.targetId
                : 'st_${locationName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}');
      } else {
        derivedTargetId =
            _selectedBus?.id ??
            (widget.targetId.isNotEmpty
                ? widget.targetId
                : 'bus_${locationName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}');
      }

      // Rate limit check: 15 minutes window (AC-77)
      final isRateLimited = await _firestoreService.checkRateLimit(
        userId,
        derivedTargetId,
        thresholdMinutes: 15,
      );

      if (isRateLimited && mounted) {
        _showSnack(
          'You already submitted a report for this target recently. Please wait 15 minutes before reporting again.',
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final subCategoryText =
          _selectedSubCategory ?? _subCategoryOptions[_category]!.first;

      final report = Report(
        id: '',
        targetType: _targetType,
        targetId: derivedTargetId,
        targetName: locationName,
        problemType: subCategoryText,
        subCategory: subCategoryText,
        photoUrl: _selectedPhotoUrl ?? '',
        severity: _severity.name,
        category: _category.name,
        description: _detailsController.text.trim(),
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
            builder: (_) =>
                ReportSubmittedScreen(report: report, targetName: locationName),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error submitting report: ${e.toString()}');
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
      body: Column(
        children: [
          _TopBar(onBack: () => Navigator.of(context).maybePop()),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 24, 16, isDesktop ? 32 : 24),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 768),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Target Type & Location',
                          style: TextStyle(
                            fontSize: 18,
                            height: 24 / 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(
                                  child: Text('Station / Stop'),
                                ),
                                selected: _targetType == 'station',
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() {
                                      _targetType = 'station';
                                      _selectedBus = null;
                                      if (_availableStations.isNotEmpty) {
                                        _selectedStation =
                                            _availableStations.first;
                                        _locationController.text =
                                            _selectedStation!.name;
                                      }
                                    });
                                  }
                                },
                                selectedColor: AppColors.primaryContainer,
                                labelStyle: TextStyle(
                                  color: _targetType == 'station'
                                      ? AppColors.onPrimary
                                      : AppColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(
                                  child: Text('Bus Route / Vehicle'),
                                ),
                                selected: _targetType == 'bus',
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() {
                                      _targetType = 'bus';
                                      _selectedStation = null;
                                      if (_availableBuses.isNotEmpty) {
                                        _selectedBus = _availableBuses.first;
                                        _locationController.text =
                                            _getBusTitle(_selectedBus!);
                                      }
                                    });
                                  }
                                },
                                selectedColor: AppColors.primaryContainer,
                                labelStyle: TextStyle(
                                  color: _targetType == 'bus'
                                      ? AppColors.onPrimary
                                      : AppColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_targetType == 'station' &&
                            _availableStations.isNotEmpty) ...[
                          DropdownButtonFormField<Station>(
                            initialValue: _selectedStation,
                            decoration: InputDecoration(
                              labelText: 'Select Station',
                              prefixIcon: const Icon(
                                Icons.location_city,
                                color: AppColors.primary,
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceContainerLowest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: _availableStations.map((s) {
                              return DropdownMenuItem<Station>(
                                value: s,
                                child: Text(s.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedStation = val;
                                  _locationController.text = val.name;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                        ] else if (_targetType == 'bus' &&
                            _availableBuses.isNotEmpty) ...[
                          DropdownButtonFormField<Bus>(
                            initialValue: _selectedBus,
                            decoration: InputDecoration(
                              labelText: 'Select Bus Route / Vehicle',
                              prefixIcon: const Icon(
                                Icons.directions_bus,
                                color: AppColors.primary,
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceContainerLowest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: _availableBuses.map((b) {
                              return DropdownMenuItem<Bus>(
                                value: b,
                                child: Text(_getBusTitle(b)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedBus = val;
                                  _locationController.text = _getBusTitle(val);
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          controller: _locationController,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 24 / 16,
                            color: AppColors.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g., Central Station - Main Entrance',
                            labelText: 'Location / Vehicle Name',
                            hintStyle: const TextStyle(
                              color: AppColors.onSurfaceVariant,
                            ),
                            prefixIcon: const Icon(
                              Icons.location_on,
                              color: AppColors.onSurfaceVariant,
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceContainerLowest,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.outline,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          "What's the issue?",
                          style: TextStyle(
                            fontSize: 18,
                            height: 24 / 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth >= 600
                                ? 3
                                : 2;
                            const spacing = 16.0;
                            final tileWidth =
                                (constraints.maxWidth -
                                    spacing * (crossAxisCount - 1)) /
                                crossAxisCount;

                            final categories = [
                              (
                                ReportCategory.rampAccess,
                                Icons.accessible,
                                'Ramp/Access',
                              ),
                              (
                                ReportCategory.elevatorOut,
                                Icons.elevator,
                                'Elevator Out',
                              ),
                              (
                                ReportCategory.audioVisualIssue,
                                Icons.volume_off,
                                'Audio/Display',
                              ),
                              (
                                ReportCategory.tactilePavingBlocked,
                                Icons.blind,
                                'Tactile Path',
                              ),
                              (
                                ReportCategory.driverAssistanceDenied,
                                Icons.person_off,
                                'Driver Support',
                              ),
                              (
                                ReportCategory.crowding,
                                Icons.groups,
                                'Crowding',
                              ),
                              (
                                ReportCategory.cleanliness,
                                Icons.cleaning_services,
                                'Cleanliness',
                              ),
                              (
                                ReportCategory.safetyHazard,
                                Icons.warning_amber_rounded,
                                'Safety Hazard',
                              ),
                              (
                                ReportCategory.other,
                                Icons.help_outline,
                                'Other',
                              ),
                            ];

                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: [
                                for (final item in categories)
                                  SizedBox(
                                    width: tileWidth,
                                    height: 100,
                                    child: _CategoryTile(
                                      icon: item.$2,
                                      label: item.$3,
                                      selected: _category == item.$1,
                                      onTap: () => setState(() {
                                        _category = item.$1;
                                        _selectedSubCategory =
                                            _subCategoryOptions[_category]!
                                                .first;
                                      }),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Specific Issue Details',
                          style: TextStyle(
                            fontSize: 18,
                            height: 24 / 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value:
                              _selectedSubCategory ??
                              _subCategoryOptions[_category]!.first,
                          decoration: InputDecoration(
                            labelText: 'Detailed Condition Issue',
                            prefixIcon: const Icon(
                              Icons.tune,
                              color: AppColors.primary,
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceContainerLowest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.outline,
                              ),
                            ),
                          ),
                          isExpanded: true,
                          items:
                              (_subCategoryOptions[_category] ?? []).map((opt) {
                                return DropdownMenuItem<String>(
                                  value: opt,
                                  child: Text(
                                    opt,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedSubCategory = val);
                            }
                          },
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.outlineVariant.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Severity',
                                style: TextStyle(
                                  fontSize: 18,
                                  height: 24 / 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 16),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final stacked = constraints.maxWidth < 420;
                                  final tiles = [
                                    _SeverityTile(
                                      label: 'Minor',
                                      selected:
                                          _severity == ReportSeverity.minor,
                                      onTap: () => setState(
                                        () => _severity = ReportSeverity.minor,
                                      ),
                                    ),
                                    _SeverityTile(
                                      label: 'Moderate',
                                      selected:
                                          _severity == ReportSeverity.moderate,
                                      onTap: () => setState(
                                        () =>
                                            _severity = ReportSeverity.moderate,
                                      ),
                                    ),
                                    _SeverityTile(
                                      label: 'Major',
                                      selected:
                                          _severity == ReportSeverity.major,
                                      emphasizeError: true,
                                      onTap: () => setState(
                                        () => _severity = ReportSeverity.major,
                                      ),
                                    ),
                                  ];

                                  if (stacked) {
                                    return Column(
                                      children: [
                                        for (
                                          var i = 0;
                                          i < tiles.length;
                                          i++
                                        ) ...[
                                          if (i > 0) const SizedBox(height: 8),
                                          tiles[i],
                                        ],
                                      ],
                                    );
                                  }

                                  return Row(
                                    children: [
                                      for (
                                        var i = 0;
                                        i < tiles.length;
                                        i++
                                      ) ...[
                                        if (i > 0) const SizedBox(width: 8),
                                        Expanded(child: tiles[i]),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            const Text(
                              'Add Photo',
                              style: TextStyle(
                                fontSize: 18,
                                height: 24 / 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '(Optional)',
                              style: TextStyle(
                                fontSize: 14,
                                height: 20 / 14,
                                color: AppColors.onSurfaceVariant.withValues(
                                  alpha: 0.9,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_selectedPhotoUrl != null &&
                            _selectedPhotoUrl!.isNotEmpty) ...[
                          Container(
                            height: 170,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _buildImageWidget(_selectedPhotoUrl!),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black.withValues(
                                        alpha: 0.7,
                                      ),
                                      radius: 18,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(
                                          Icons.close,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          setState(
                                            () => _selectedPhotoUrl = null,
                                          );
                                          _showSnack('Photo removed');
                                        },
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.75,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: AppColors.success,
                                            size: 14,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Photo Attached',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
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
                          ),
                        ] else ...[
                          Material(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: _showPhotoPickerDialog,
                              borderRadius: BorderRadius.circular(12),
                              child: CustomPaint(
                                painter: _DashedBorderPainter(
                                  color: AppColors.outlineVariant,
                                  radius: 12,
                                ),
                                child: const SizedBox(
                                  height: 120,
                                  width: double.infinity,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_outlined,
                                        size: 32,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Tap to upload or select a photo',
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 20 / 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        const Text(
                          'Additional Details',
                          style: TextStyle(
                            fontSize: 18,
                            height: 24 / 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _detailsController,
                          maxLines: 4,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 24 / 16,
                            color: AppColors.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Please describe the issue in more detail...',
                            hintStyle: const TextStyle(
                              color: AppColors.onSurfaceVariant,
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceContainerLowest,
                            contentPadding: const EdgeInsets.all(16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.outline,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 56,
                          child: FilledButton.icon(
                            onPressed: _isSubmitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: AppColors.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.onPrimary,
                                    ),
                                  )
                                : const Icon(Icons.send, size: 20),
                            label: Text(
                              _isSubmitting ? 'Submitting...' : 'Submit Report',
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
      bottomNavigationBar: null,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
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
                  tooltip: 'Go back',
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Report a Condition',
                    style: TextStyle(
                      fontSize: 22,
                      height: 28 / 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.surfaceContainer
          : AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primaryContainer
                  : AppColors.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: selected
                    ? AppColors.primaryContainer
                    : AppColors.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w500,
                  color: selected
                      ? AppColors.primaryContainer
                      : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeverityTile extends StatelessWidget {
  const _SeverityTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.emphasizeError = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool emphasizeError;

  @override
  Widget build(BuildContext context) {
    final Color textColor;
    if (selected) {
      textColor = AppColors.onPrimary;
    } else if (emphasizeError) {
      textColor = AppColors.error;
    } else {
      textColor = AppColors.onSurface;
    }

    return Material(
      color: selected
          ? AppColors.primaryContainer
          : AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? AppColors.primaryContainer
                  : AppColors.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
          Radius.circular(radius),
        ),
      );

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
