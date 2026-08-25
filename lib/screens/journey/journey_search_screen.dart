import 'package:flutter/material.dart';

import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../community/community_screen.dart';
import 'route_results_screen.dart';

/// Journey Search screen — origin/destination, time, accessibility filters,
/// and recent destinations (Sprint 2 UI).
class JourneySearchScreen extends StatefulWidget {
  const JourneySearchScreen({super.key});

  @override
  State<JourneySearchScreen> createState() => _JourneySearchScreenState();
}

class _JourneySearchScreenState extends State<JourneySearchScreen> {
  static const double _desktopBreakpoint = 768;

  final TextEditingController _fromController =
      TextEditingController(text: 'Current Location');
  final TextEditingController _toController = TextEditingController();

  bool _wheelchairAccess = true;
  bool _stepFreeOnly = false;
  bool _minimizeWalking = true;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _swapLocations() {
    final from = _fromController.text;
    _fromController.text = _toController.text;
    _toController.text = from;
    setState(() {});
  }

  void _fillDestination(String title) {
    setState(() => _toController.text = title);
  }

  void _searchRoutes() {
    final origin = _fromController.text.trim().isEmpty
        ? 'Current Location'
        : _fromController.text.trim();
    final destination = _toController.text.trim();
    if (destination.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Please enter a destination.')),
        );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteResultsScreen(
          origin: origin,
          destination: destination,
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
                          fromController: _fromController,
                          toController: _toController,
                          onSwap: _swapLocations,
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
                        _RecentSavedSection(onSelect: _fillDestination),
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
                if (label == 'Home') {
                  Navigator.of(context).pop();
                  return;
                }
                if (label == 'Plan') return;
                if (label == 'Community') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CommunityScreen(),
                    ),
                  );
                  return;
                }
                if (label == 'Profile') {
                  AppNavigation.openProfile(context);
                  return;
                }
                _showComingSoon(label);
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
    required this.fromController,
    required this.toController,
    required this.onSwap,
  });

  final TextEditingController fromController;
  final TextEditingController toController;
  final VoidCallback onSwap;

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
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    Icon(
                      Icons.my_location,
                      size: 20,
                      color: AppColors.primaryContainer,
                    ),
                    SizedBox(
                      height: 32,
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
                    _LocationField(
                      controller: fromController,
                      hint: 'From',
                    ),
                    const SizedBox(height: 8),
                    _LocationField(
                      controller: toController,
                      hint: 'Where to?',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
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
                    width: 48,
                    height: 48,
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

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.controller,
    required this.hint,
  });

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        fontSize: 16,
        height: 24 / 16,
        color: AppColors.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.primaryContainer,
            width: 2,
          ),
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
  const _RecentSavedSection({required this.onSelect});

  final ValueChanged<String> onSelect;

  static const _items = [
    (Icons.home, 'Home', '123 Accessible Ave'),
    (Icons.work, 'City Library', 'Central Square'),
    (Icons.history, 'General Hospital', 'North Wing Clinic'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent & Saved',
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
                      color: i == 2
                          ? AppColors.onSurfaceVariant
                          : AppColors.primaryContainer,
                    ),
                  ),
                  title: Text(
                    _items[i].$2,
                    style: TextStyle(
                      fontSize: 16,
                      height: 24 / 16,
                      fontWeight:
                          i == 2 ? FontWeight.w500 : FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    _items[i].$3,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  onTap: () => onSelect(_items[i].$2),
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
