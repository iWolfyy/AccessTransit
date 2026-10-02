import 'package:flutter/material.dart';

import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../main_shell.dart';

/// Modern Accessible Preferences Screen adhering to WCAG 2.2 Level AA (48dp+ tap targets).
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

  void _openProfile() {
    AppNavigation.openProfile(context, initialUser: widget.initialUser);
  }

  void _save() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Accessibility preferences saved!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

    if (widget.continueToHome) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainShell(initialUser: widget.initialUser),
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
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: const Text(
          'Accessibility Preferences',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.account_circle, color: AppColors.primary),
            onPressed: _openProfile,
            tooltip: 'User profile',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                isDesktop ? 20 : 12,
                16,
                isDesktop ? 32 : 40,
              ),
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary,
                        child: Icon(
                          Icons.accessibility_new_rounded,
                          color: AppColors.onPrimary,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personalized Travel Experience',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'These preferences prioritize ramps, step-free routes, and comfortable transit for your trips.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Category 1: Mobility
                _PreferenceCategory(
                  title: 'Mobility & Physical Access',
                  icon: Icons.accessible_rounded,
                  children: [
                    _PreferenceToggle(
                      icon: Icons.accessible,
                      label: 'Wheelchair access required',
                      subtitle: 'Only show buses with deployed ramps & designated spaces',
                      value: _wheelchairAccess,
                      onChanged: (v) => setState(() => _wheelchairAccess = v),
                    ),
                    const Divider(height: 1, indent: 64),
                    _PreferenceToggle(
                      icon: Icons.stairs,
                      label: 'Step-free routes only',
                      subtitle: 'Avoid stops and terminals requiring stairs',
                      value: _stepFree,
                      onChanged: (v) => setState(() => _stepFree = v),
                    ),
                    const Divider(height: 1, indent: 64),
                    _PreferenceToggle(
                      icon: Icons.directions_walk,
                      label: 'Minimize walking distance',
                      subtitle: 'Prioritize connections closest to entry points',
                      value: _minimizeWalking,
                      onChanged: (v) => setState(() => _minimizeWalking = v),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Category 2: Sensory & Vision
                _PreferenceCategory(
                  title: 'Sensory & Vision',
                  icon: Icons.visibility_rounded,
                  children: [
                    _PreferenceToggle(
                      icon: Icons.contrast,
                      label: 'High contrast mode',
                      subtitle: 'Enhance text clarity and strong border lines (WCAG AAA)',
                      value: _highContrast,
                      onChanged: (v) => setState(() => _highContrast = v),
                    ),
                    const Divider(height: 1, indent: 64),
                    _PreferenceToggle(
                      icon: Icons.volume_up,
                      label: 'Voice guidance for navigation',
                      subtitle: 'Spoken stop announcements and transfer cues',
                      value: _voiceGuidance,
                      onChanged: (v) => setState(() => _voiceGuidance = v),
                    ),
                    const Divider(height: 1, indent: 64),
                    _PreferenceToggle(
                      icon: Icons.vibration,
                      label: 'Haptic alerts for stops',
                      subtitle: 'Vibrate device when approaching destination',
                      value: _hapticAlerts,
                      onChanged: (v) => setState(() => _hapticAlerts = v),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Category 3: Passenger Assistance
                _PreferenceCategory(
                  title: 'Assistance & Environment',
                  icon: Icons.diversity_3,
                  children: [
                    _PreferenceToggle(
                      icon: Icons.front_hand_rounded,
                      label: 'Boarding assistance required',
                      subtitle: 'Notify driver in advance to assist with ramp deployment',
                      value: _boardingAssistance,
                      onChanged: (v) => setState(() => _boardingAssistance = v),
                    ),
                    const Divider(height: 1, indent: 64),
                    _PreferenceToggle(
                      icon: Icons.hearing_disabled,
                      label: 'Show quiet routes',
                      subtitle: 'Prioritize lower crowd levels and quieter transit options',
                      value: _quietRoutes,
                      onChanged: (v) => setState(() => _quietRoutes = v),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Save Preferences CTA Button (52dp height for easy tapping)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                    label: const Text(
                      'Save Preferences',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
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
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.outlineVariant),
          ...children,
        ],
      ),
    );
  }
}

/// Enforces 56dp minimum touch target size (WCAG 2.2 AA compliant, exceeds 48dp).
class _PreferenceToggle extends StatelessWidget {
  const _PreferenceToggle({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: value
                        ? AppColors.primaryContainer.withValues(alpha: 0.25)
                        : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: value ? AppColors.primary : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  label: label,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    activeThumbColor: AppColors.onPrimary,
                    activeTrackColor: AppColors.primary,
                    inactiveThumbColor: AppColors.onSurfaceVariant,
                    inactiveTrackColor: AppColors.surfaceVariant,
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
