import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Shared bottom navigation bar used by the [MainShell].
///
/// Displays four tabs: Home, Plan, Community, Profile.
/// The [currentTab] string determines which tab is visually selected.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  /// Label of the currently active tab.
  /// Must be one of `'Home'`, `'Plan'`, `'Community'`, or `'Profile'`.
  final String currentTab;

  /// Called when the user taps a tab.
  final ValueChanged<String> onTabSelected;

  static const List<_TabDef> _tabs = [
    _TabDef(icon: Icons.home, activeIcon: Icons.home, label: 'Home'),
    _TabDef(
      icon: Icons.directions_bus_outlined,
      activeIcon: Icons.directions_bus,
      label: 'Plan',
    ),
    _TabDef(
      icon: Icons.group_outlined,
      activeIcon: Icons.groups,
      label: 'Community',
    ),
    _TabDef(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;

    return Container(
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.white : AppColors.surface,
        border: isHighContrast
            ? const Border(top: BorderSide(color: Colors.black, width: 2.0))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        elevation: isHighContrast ? 0 : 8,
        shadowColor: AppColors.onSurface.withValues(alpha: 0.12),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                for (final tab in _tabs)
                  Expanded(
                    child: _NavItem(
                      icon: currentTab == tab.label ? tab.activeIcon : tab.icon,
                      label: tab.label,
                      selected: currentTab == tab.label,
                      isHighContrast: isHighContrast,
                      onTap: () => onTabSelected(tab.label),
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

class _TabDef {
  const _TabDef({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.isHighContrast = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool isHighContrast;

  @override
  Widget build(BuildContext context) {
    final activeBg = isHighContrast
        ? const Color(0xFF001F3F)
        : AppColors.primaryContainer;
    final activeFg = Colors.white;
    final inactiveFg = isHighContrast
        ? Colors.black
        : AppColors.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: selected
            ? BoxDecoration(
                color: activeBg,
                borderRadius: BorderRadius.circular(12),
                border: isHighContrast
                    ? Border.all(color: Colors.black, width: 2.0)
                    : null,
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? activeFg : inactiveFg,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 14 / 11,
                fontWeight: selected ? FontWeight.w800 : (isHighContrast ? FontWeight.w700 : FontWeight.w600),
                color: selected ? activeFg : inactiveFg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
