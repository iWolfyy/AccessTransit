import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../home/home_screen.dart';

class AccessibilityPreferencesScreen extends StatefulWidget {
  const AccessibilityPreferencesScreen({
    super.key,
    this.initialUser,
    this.continueToHome = false,
  });

  final UserModel? initialUser;

  /// When true (post-login), Save opens Home. Otherwise Save pops back.
  final bool continueToHome;

  @override
  State<AccessibilityPreferencesScreen> createState() =>
      _AccessibilityPreferencesScreenState();
}

class _AccessibilityPreferencesScreenState
    extends State<AccessibilityPreferencesScreen> {
  bool _wheelchairAccess = true;
  bool _stepFree = false;
  bool _minimizeWalking = false;
  bool _highContrast = false;
  bool _voiceGuidance = true;
  bool _hapticAlerts = false;
  bool _boardingAssistance = false;
  bool _quietRoutes = false;

  void _save() {
    if (widget.continueToHome) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(initialUser: widget.initialUser),
        ),
      );
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          if (isDesktop) const _DesktopTopBar() else const _MobileTopBar(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 24 : 16,
                24,
                isDesktop ? 24 : 16,
                isDesktop ? 24 : 112,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Accessibility Preferences',
                          style: TextStyle(
                            fontSize: 32,
                            height: 40 / 32,
                            letterSpacing: -0.64,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Personalize your travel experience. These settings will help us find the best routes for you.',
                          style: TextStyle(
                            fontSize: 16,
                            height: 24 / 16,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _PreferenceCategory(
                          title: 'Mobility',
                          children: [
                            _PreferenceToggle(
                              icon: Icons.accessible,
                              label: 'Wheelchair access required',
                              value: _wheelchairAccess,
                              onChanged: (v) =>
                                  setState(() => _wheelchairAccess = v),
                            ),
                            _PreferenceToggle(
                              icon: Icons.stairs,
                              label: 'Step-free routes only',
                              value: _stepFree,
                              onChanged: (v) => setState(() => _stepFree = v),
                            ),
                            _PreferenceToggle(
                              icon: Icons.directions_walk,
                              label: 'Minimize walking distance',
                              value: _minimizeWalking,
                              onChanged: (v) =>
                                  setState(() => _minimizeWalking = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _PreferenceCategory(
                          title: 'Sensory',
                          children: [
                            _PreferenceToggle(
                              icon: Icons.contrast,
                              label: 'High contrast mode',
                              value: _highContrast,
                              onChanged: (v) =>
                                  setState(() => _highContrast = v),
                            ),
                            _PreferenceToggle(
                              icon: Icons.volume_up,
                              label: 'Voice guidance for navigation',
                              value: _voiceGuidance,
                              onChanged: (v) =>
                                  setState(() => _voiceGuidance = v),
                            ),
                            _PreferenceToggle(
                              icon: Icons.vibration,
                              label: 'Haptic alerts for stops',
                              value: _hapticAlerts,
                              onChanged: (v) =>
                                  setState(() => _hapticAlerts = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _PreferenceCategory(
                          title: 'Assistance',
                          children: [
                            _PreferenceToggle(
                              icon: Icons.diversity_3,
                              label: 'Boarding assistance required',
                              value: _boardingAssistance,
                              onChanged: (v) =>
                                  setState(() => _boardingAssistance = v),
                            ),
                            _PreferenceToggle(
                              icon: Icons.hearing_disabled,
                              label: 'Show quiet routes (lower crowd levels)',
                              value: _quietRoutes,
                              onChanged: (v) =>
                                  setState(() => _quietRoutes = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: AppColors.onPrimary,
                              shape: const StadiumBorder(),
                            ),
                            child: const Text(
                              'Save Preferences',
                              style: TextStyle(
                                fontSize: 14,
                                height: 20 / 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                              ),
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
          : _BottomNav(
              onHomeTap: widget.continueToHome
                  ? () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) =>
                              HomeScreen(initialUser: widget.initialUser),
                        ),
                      );
                    }
                  : () => Navigator.of(context).pop(),
              onProfileTap: widget.continueToHome
                  ? null
                  : () => Navigator.of(context).pop(),
            ),
    );
  }
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 1,
      shadowColor: Colors.black26,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.menu, color: AppColors.primary),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Access Transit',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      height: 28 / 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.account_circle, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 1,
      shadowColor: Colors.black26,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Access Transit',
                style: TextStyle(
                  fontSize: 24,
                  height: 32 / 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreferenceCategory extends StatelessWidget {
  const _PreferenceCategory({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              height: 24 / 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          const Divider(color: AppColors.surfaceVariant, height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _PreferenceToggle extends StatelessWidget {
  const _PreferenceToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(icon, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 24 / 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: AppColors.onPrimary,
                  activeTrackColor: AppColors.primary,
                  inactiveThumbColor: AppColors.onSurfaceVariant,
                  inactiveTrackColor: AppColors.surfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.onHomeTap,
    this.onProfileTap,
  });

  final VoidCallback onHomeTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 4,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  onTap: onHomeTap,
                ),
              ),
              const Expanded(
                child: _NavItem(
                  icon: Icons.directions_bus,
                  label: 'Plan',
                ),
              ),
              const Expanded(
                child: _NavItem(
                  icon: Icons.sensors,
                  label: 'Live',
                ),
              ),
              const Expanded(
                child: _NavItem(
                  icon: Icons.group_outlined,
                  label: 'Community',
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.person,
                  label: 'Profile',
                  selected: true,
                  onTap: onProfileTap,
                ),
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
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: selected
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 4)
          : const EdgeInsets.all(8),
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
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? AppColors.onPrimaryContainer
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    if (selected) {
      return Center(
        child: Material(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: content),
        ),
      );
    }

    return InkWell(onTap: onTap, child: content);
  }
}
