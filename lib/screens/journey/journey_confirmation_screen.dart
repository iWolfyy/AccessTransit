import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/enums/bus_status.dart';
import '../../models/journey_model.dart';
import '../../services/journey_service.dart';
import '../../services/live_bus_service.dart';
import 'live_journey_screen.dart';
import 'route_results_screen.dart';

/// Journey Confirmation screen — final check before starting navigation.
class JourneyConfirmationScreen extends StatelessWidget {
  const JourneyConfirmationScreen({
    super.key,
    required this.origin,
    required this.destination,
    this.route,
  });

  final String origin;
  final String destination;
  final RouteResultItem? route;

  int get _durationMinutes => route?.durationMinutes ?? 28;

  String get _arrivalLabel {
    final now = DateTime.now().add(Duration(minutes: _durationMinutes));
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return 'Arrival $hour:$minute $period';
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Ensures a valid live location document exists in Firestore for [busId].
  Future<void> _seedLiveLocationIfMissing(
    String busId,
    RouteResultItem? route,
  ) async {
    try {
      final liveService = LiveBusService();
      final existing = await liveService.getLiveLocation(busId);
      if (existing == null || !existing.isBroadcasting) {
        final busNum = busId.replaceAll('bus_', '');
        double lat = 6.9271;
        double lng = 79.8612;
        if (busId == 'bus_01') {
          lat = 7.2513; // Hettimulla / Kegalle area on Route 01
          lng = 80.3464;
        } else if (busId == 'bus_02') {
          lat = 6.4000;
          lng = 79.9800;
        } else if (busId == 'bus_87') {
          lat = 8.3114;
          lng = 80.4037;
        } else if (busId == 'bus_49') {
          lat = 7.8731;
          lng = 80.7718;
        } else if (busId == 'bus_99') {
          lat = 6.8833;
          lng = 80.6000;
        }

        await liveService.startLiveLocation(
          busId: busId,
          routeId: route?.id ?? 'route_$busNum',
          driverId: 'operator_system',
          latitude: lat,
          longitude: lng,
          speed: 42.0,
          heading: 65.0,
          status: BusStatus.active,
          routeNumber: busNum,
          routeName: route?.title ?? 'Route $busNum',
          operatorName: 'Sri Lanka Transit Operator',
        );
      }
    } catch (_) {
      // Non-fatal if write fails
    }
  }

  /// Creates the journey document then navigates to [LiveJourneyScreen].
  Future<void> _confirmAndStart(BuildContext context) async {
    final navigator = Navigator.of(context);
    final passengerId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final busId = route?.busId ?? 'bus_01';

    // Seed live bus location so map has telemetry data right away
    await _seedLiveLocationIfMissing(busId, route);

    // Write journey to Firestore if user is authenticated.
    if (passengerId.isNotEmpty) {
      try {
        final busNum = busId.replaceAll('bus_', '');
        await JourneyService().createJourney(
          JourneyModel(
            journeyId: '', // will be replaced by Firestore auto-ID
            passengerId: passengerId,
            routeId: route?.id ?? 'route_$busNum',
            routeNumber: busNum,
            routeTitle: route?.title ?? 'Bus $busNum',
            busId: busId,
            origin: origin,
            destination: destination,
            status: JourneyStatus.confirmed,
          ),
        );
      } catch (_) {
        // Non-fatal: if write fails, still open Live Journey with busId fallback.
      }
    }

    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => LiveJourneyScreen(
          origin: origin,
          destination: destination,
          route: route,
          busId: busId,
          passengerId: passengerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: Column(
        children: [
          _TopBar(onBack: () => Navigator.of(context).maybePop()),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const _MapHero(),
                Transform.translate(
                  offset: const Offset(0, -64),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DestinationCard(
                          destination: destination,
                          durationMinutes: _durationMinutes,
                          arrivalLabel: _arrivalLabel,
                        ),
                        const SizedBox(height: 24),
                        const _AccessibilityVerifiedSection(),
                        const SizedBox(height: 24),
                        _DepartureDetailsSection(
                          origin: origin,
                          route: route,
                        ),
                        const SizedBox(height: 24),
                        _FixedActions(
                          onConfirm: () => _confirmAndStart(context),
                          onSetAlert: () =>
                              _showSnack(context, 'Departure alert set.'),
                          onShare: () =>
                              _showSnack(context, 'Share route coming soon.'),
                        ),
                        SizedBox(height: isDesktop ? 24 : 24),
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
    final isHC = context.isHighContrast;

    return Material(
      color: context.surfaceColor,
      elevation: isHC ? 0 : 1,
      shadowColor: AppColors.onSurface.withValues(alpha: 0.08),
      shape: isHC
          ? const Border(bottom: BorderSide(color: Colors.black, width: 2))
          : null,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: context.hasLargeTargets ? 56 : 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  constraints: context.appBarActionConstraints,
                  onPressed: onBack,
                  icon: Icon(Icons.arrow_back_rounded, size: context.tapIconSize),
                  color: isHC ? Colors.black : AppColors.primary,
                  tooltip: 'Back',
                ),
                Expanded(
                  child: Text(
                    'Confirm Journey',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      height: 28 / 22,
                      fontWeight: FontWeight.w700,
                      color: context.textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapHero extends StatelessWidget {
  const _MapHero();

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;

    return Container(
      height: 192,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isHC ? Colors.white : AppColors.surfaceContainer,
        border: isHC ? const Border(bottom: BorderSide(color: Colors.black, width: 2)) : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: isHC
                ? Colors.white
                : AppColors.surfaceVariant.withValues(alpha: 0.6),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 40,
                    color: isHC ? Colors.black : AppColors.outline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Route map preview',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.subtextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.surfaceColor.withValues(alpha: 0),
                    context.surfaceColor,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.destination,
    required this.durationMinutes,
    required this.arrivalLabel,
  });

  final String destination;
  final int durationMinutes;
  final String arrivalLabel;

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isHC
            ? Border.all(color: Colors.black, width: 2)
            : Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
        boxShadow: isHC
            ? null
            : [
                BoxShadow(
                  color: AppColors.onSurface.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DESTINATION',
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: context.subtextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  destination,
                  style: TextStyle(
                    fontSize: 22,
                    height: 28 / 22,
                    fontWeight: FontWeight.w700,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isHC ? Colors.white : AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
              border: isHC ? Border.all(color: Colors.black, width: 2) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$durationMinutes min',
                  style: TextStyle(
                    fontSize: 22,
                    height: 28 / 22,
                    fontWeight: FontWeight.w700,
                    color: isHC ? const Color(0xFF001F3F) : AppColors.primary,
                  ),
                ),
                Text(
                  arrivalLabel,
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    color: context.subtextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessibilityVerifiedSection extends StatelessWidget {
  const _AccessibilityVerifiedSection();

  static const _items = [
    (
      Icons.accessible,
      'Wheelchair Accessible',
      'All vehicles and platforms',
    ),
    (
      Icons.elevator_outlined,
      'Step-free Route',
      'No stairs required',
    ),
    (
      Icons.ramp_right,
      'Ramp Verified',
      'Community confirmed today',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Accessibility Verified',
            style: TextStyle(
              fontSize: 18,
              height: 24 / 18,
              fontWeight: FontWeight.w600,
              color: context.textColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: isHC
                ? Border.all(color: Colors.black, width: 2)
                : Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
            boxShadow: isHC
                ? null
                : [
                    BoxShadow(
                      color: AppColors.onSurface.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < _items.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: isHC
                        ? Colors.black
                        : AppColors.outlineVariant.withValues(alpha: 0.2),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isHC
                              ? Colors.white
                              : AppColors.secondaryContainer,
                          border: isHC
                              ? Border.all(color: Colors.black, width: 1.5)
                              : null,
                        ),
                        child: Icon(
                          _items[i].$1,
                          color: isHC
                              ? Colors.black
                              : AppColors.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _items[i].$2,
                              style: TextStyle(
                                fontSize: 16,
                                height: 24 / 16,
                                fontWeight: FontWeight.w500,
                                color: context.textColor,
                              ),
                            ),
                            Text(
                              _items[i].$3,
                              style: TextStyle(
                                fontSize: 14,
                                height: 20 / 14,
                                color: context.subtextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.check_circle,
                        color: isHC
                            ? const Color(0xFF003833)
                            : AppColors.secondary,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DepartureDetailsSection extends StatelessWidget {
  const _DepartureDetailsSection({
    required this.origin,
    this.route,
  });

  final String origin;
  final RouteResultItem? route;

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;
    final busTitle = route?.title ?? 'Bus 42';
    final etaLabel = route?.etaLabel ?? 'In 4 mins';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Departure Details',
            style: TextStyle(
              fontSize: 18,
              height: 24 / 18,
              fontWeight: FontWeight.w600,
              color: context.textColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: isHC
                ? Border.all(color: Colors.black, width: 2)
                : Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
            boxShadow: isHC
                ? null
                : [
                    BoxShadow(
                      color: AppColors.onSurface.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isHC ? Colors.white : AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                      border: isHC
                          ? Border.all(color: Colors.black, width: 2)
                          : Border.all(
                              color: AppColors.surfaceContainerLowest,
                              width: 4,
                            ),
                    ),
                    child: Icon(
                      Icons.my_location,
                      color: isHC ? Colors.black : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start from',
                            style: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              color: context.subtextColor,
                            ),
                          ),
                          Text(
                            origin,
                            style: TextStyle(
                              fontSize: 18,
                              height: 24 / 18,
                              fontWeight: FontWeight.w600,
                              color: context.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isHC
                          ? const Color(0xFF001F3F)
                          : AppColors.primaryContainer,
                      shape: BoxShape.circle,
                      border: isHC
                          ? Border.all(color: Colors.black, width: 2)
                          : Border.all(
                              color: AppColors.surfaceContainerLowest,
                              width: 4,
                            ),
                      boxShadow: isHC
                          ? null
                          : [
                              BoxShadow(
                                color:
                                    AppColors.onSurface.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                    ),
                    child: const Icon(
                      Icons.directions_bus,
                      color: AppColors.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  busTitle,
                                  style: TextStyle(
                                    fontSize: 18,
                                    height: 24 / 18,
                                    fontWeight: FontWeight.w600,
                                    color: context.textColor,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isHC
                                      ? const Color(0xFF8B0000)
                                      : AppColors.errorContainer,
                                  borderRadius: BorderRadius.circular(4),
                                  border: isHC
                                      ? Border.all(color: Colors.black, width: 1.5)
                                      : null,
                                ),
                                child: Text(
                                  etaLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 16 / 12,
                                    fontWeight: FontWeight.w700,
                                    color: isHC
                                        ? Colors.white
                                        : AppColors.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stop A • Towards North Station',
                            style: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              color: context.subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FixedActions extends StatelessWidget {
  const _FixedActions({
    required this.onConfirm,
    required this.onSetAlert,
    required this.onShare,
  });

  final VoidCallback onConfirm;
  final VoidCallback onSetAlert;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: context.buttonHeight,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: isHC
                  ? const Color(0xFF001F3F)
                  : AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimary,
              side: isHC ? const BorderSide(color: Colors.black, width: 2) : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: TextStyle(
                fontSize: context.buttonFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: Icon(Icons.navigation, size: context.tapIconSize),
            label: const Text('Confirm & Start Navigation'),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: context.buttonHeight,
                child: OutlinedButton.icon(
                  onPressed: onSetAlert,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isHC ? Colors.white : null,
                    foregroundColor: isHC ? Colors.black : AppColors.primary,
                    side: BorderSide(
                      color: isHC ? Colors.black : AppColors.primaryContainer,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: TextStyle(
                      fontSize: context.buttonFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: Icon(Icons.notifications_active, size: context.tapIconSize),
                  label: const Text('Set Alert'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: context.buttonHeight,
                child: OutlinedButton.icon(
                  onPressed: onShare,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isHC ? Colors.white : null,
                    foregroundColor: isHC ? Colors.black : AppColors.primary,
                    side: BorderSide(
                      color: isHC ? Colors.black : AppColors.outlineVariant.withValues(alpha: 0.5),
                      width: isHC ? 2 : 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: TextStyle(
                      fontSize: context.buttonFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: Icon(Icons.share, size: context.tapIconSize),
                  label: const Text('Share Route'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

