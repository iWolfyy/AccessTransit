import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../models/journey_model.dart';
import '../../services/journey_service.dart';
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

  /// Creates the journey document then navigates to [LiveJourneyScreen].
  Future<void> _confirmAndStart(BuildContext context) async {
    final navigator = Navigator.of(context);
    final passengerId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final busId = route?.busId ?? 'bus_42';

    // Write journey to Firestore if user is authenticated.
    if (passengerId.isNotEmpty) {
      try {
        final busNum = route?.busId.replaceAll('bus_', '') ?? '42';
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
      backgroundColor: AppColors.surface,
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
      bottomNavigationBar: isDesktop
          ? null
          : _ConfirmBottomNav(
              onNavTap: (label) {
                AppNavigation.handleBottomNav(
                  context,
                  label,
                  currentTab: 'Plan',
                  onUnsupported: (message) => _showSnack(context, message),
                );
              },
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
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.primary,
                  tooltip: 'Back',
                ),
                const Expanded(
                  child: Text(
                    'Confirm Journey',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      height: 28 / 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
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
    return Container(
      height: 192,
      width: double.infinity,
      color: AppColors.surfaceContainer,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: AppColors.surfaceVariant.withValues(alpha: 0.6),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 40, color: AppColors.outline),
                  SizedBox(height: 8),
                  Text(
                    'Route map preview',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
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
                    AppColors.surface.withValues(alpha: 0),
                    AppColors.surface,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
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
                const Text(
                  'DESTINATION',
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  destination,
                  style: const TextStyle(
                    fontSize: 22,
                    height: 28 / 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$durationMinutes min',
                  style: const TextStyle(
                    fontSize: 22,
                    height: 28 / 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  arrivalLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    color: AppColors.onSurfaceVariant,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Accessibility Verified',
            style: TextStyle(
              fontSize: 18,
              height: 24 / 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
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
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.secondaryContainer,
                        child: Icon(
                          _items[i].$1,
                          color: AppColors.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _items[i].$2,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 24 / 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              _items[i].$3,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 20 / 14,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.secondary,
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
    final busTitle = route?.title ?? 'Bus 42';
    final etaLabel = route?.etaLabel ?? 'In 4 mins';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Departure Details',
            style: TextStyle(
              fontSize: 18,
              height: 24 / 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
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
                      color: AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surfaceContainerLowest,
                        width: 4,
                      ),
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Start from',
                            style: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            origin,
                            style: const TextStyle(
                              fontSize: 18,
                              height: 24 / 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
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
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surfaceContainerLowest,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.onSurface.withValues(alpha: 0.08),
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
                                  style: const TextStyle(
                                    fontSize: 18,
                                    height: 24 / 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.errorContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  etaLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 16 / 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Stop A • Towards North Station',
                            style: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              color: AppColors.onSurfaceVariant,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 48,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onConfirm,
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
            icon: const Icon(Icons.navigation, size: 20),
            label: const Text('Confirm & Start Navigation'),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: onSetAlert,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.primaryContainer,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: const Icon(Icons.notifications_active, size: 20),
                  label: const Text('Set Alert'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 48,
                child: TextButton.icon(
                  onPressed: onShare,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: const Icon(Icons.share, size: 20),
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

class _ConfirmBottomNav extends StatelessWidget {
  const _ConfirmBottomNav({required this.onNavTap});

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
