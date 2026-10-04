import 'package:flutter/material.dart';

import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/accessibility_preferences_service.dart';
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
  late bool _wheelchairAccess;
  late bool _stepFree;
  late bool _minimizeWalking;
  late bool _highContrast;
  late bool _voiceGuidance;
  late bool _hapticAlerts;
  late bool _boardingAssistance;
  late bool _quietRoutes;
  late bool _hasLargeTargets;

  @override
  void initState() {
    super.initState();
    final prefs = AccessibilityPreferencesService.instance;
    _wheelchairAccess = prefs.isWheelchairOnly;
    _stepFree = prefs.isStepFree;
    _minimizeWalking = prefs.minimizeWalking;
    _highContrast = prefs.isHighContrast;
    _voiceGuidance = prefs.voiceGuidance;
    _hapticAlerts = prefs.hapticAlerts;
    _boardingAssistance = prefs.boardingAssistance;
    _quietRoutes = prefs.quietRoutes;
    _hasLargeTargets = prefs.hasLargeTargets;
  }

  void _openProfile() {
    AppNavigation.openProfile(context, initialUser: widget.initialUser);
  }

  Future<void> _save() async {
    await AccessibilityPreferencesService.instance.savePreferences(
      isWheelchairOnly: _wheelchairAccess,
      isStepFree: _stepFree,
      minimizeWalking: _minimizeWalking,
      isHighContrast: _highContrast,
      voiceGuidance: _voiceGuidance,
      hapticAlerts: _hapticAlerts,
      boardingAssistance: _boardingAssistance,
      quietRoutes: _quietRoutes,
      hasLargeTargets: _hasLargeTargets,
    );

    if (!mounted) return;

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
    final isHighContrast =
        Theme.of(context).colorScheme.outline == const Color(0xFF000000) ||
        AccessibilityPreferencesService.instance.isHighContrast;

    return Scaffold(
      backgroundColor: isHighContrast ? Colors.white : AppColors.surface,
      appBar: AppBar(
        backgroundColor: isHighContrast ? Colors.white : AppColors.surface,
        elevation: isHighContrast ? 1 : 0,
        leading: IconButton(
          constraints: BoxConstraints(
            minWidth: context.minTapHeight,
            minHeight: context.minTapHeight,
          ),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isHighContrast ? Colors.black : AppColors.primary,
            size: context.tapIconSize,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Accessibility Preferences',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isHighContrast ? Colors.black : AppColors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            constraints: BoxConstraints(
              minWidth: context.minTapHeight,
              minHeight: context.minTapHeight,
            ),
            icon: Icon(
              Icons.account_circle,
              color: isHighContrast ? Colors.black : AppColors.primary,
              size: context.tapIconSize,
            ),
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
                    color: isHighContrast
                        ? Colors.white
                        : AppColors.primaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isHighContrast
                          ? Colors.black
                          : AppColors.primary.withValues(alpha: 0.25),
                      width: isHighContrast ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: isHighContrast
                            ? const Color(0xFF001F3F)
                            : AppColors.primary,
                        child: const Icon(
                          Icons.accessibility_new_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personalized Travel Experience',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isHighContrast
                                    ? Colors.black
                                    : AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'These preferences prioritize ramps, step-free routes, and comfortable transit for your trips.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isHighContrast
                                    ? const Color(0xFF1A1A1A)
                                    : AppColors.onSurfaceVariant,
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

                // Category 1: Mobility & Physical Access
                _PreferenceCategory(
                  title: 'Mobility & Physical Access',
                  icon: Icons.accessible_rounded,
                  hasLargeTargets: _hasLargeTargets,
                  children: [
                    _PreferenceToggle(
                      icon: Icons.accessible,
                      label: 'Wheelchair access required',
                      subtitle: 'Only show buses with deployed ramps & designated spaces',
                      value: _wheelchairAccess,
                      hasLargeTargets: _hasLargeTargets,
                      onChanged: (v) {
                        setState(() => _wheelchairAccess = v);
                        AccessibilityPreferencesService.instance.setWheelchairOnly(v);
                      },
                    ),
                    const Divider(height: 1, indent: 64),
                    _PreferenceToggle(
                      icon: Icons.stairs,
                      label: 'Step-free routes only',
                      subtitle: 'Avoid stops and terminals requiring stairs',
                      value: _stepFree,
                      hasLargeTargets: _hasLargeTargets,
                      onChanged: (v) {
                        setState(() => _stepFree = v);
                        AccessibilityPreferencesService.instance.setStepFree(v);
                      },
                    ),
                    const Divider(height: 1, indent: 64),
                    _PreferenceToggle(
                      icon: Icons.directions_walk,
                      label: 'Minimize walking distance',
                      subtitle: 'Prioritize connections closest to entry points',
                      value: _minimizeWalking,
                      hasLargeTargets: _hasLargeTargets,
                      onChanged: (v) {
                        setState(() => _minimizeWalking = v);
                        AccessibilityPreferencesService.instance.setMinimizeWalking(v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Category 2: Sensory & Vision
                _PreferenceCategory(
                  title: 'Sensory & Vision',
                  icon: Icons.visibility_rounded,
                  hasLargeTargets: _hasLargeTargets,
                  children: [
                    _PreferenceToggle(
                      icon: Icons.contrast,
                      label: 'High contrast mode',
                      subtitle: 'Enhance text clarity and strong border lines (WCAG AAA)',
                      value: _highContrast,
                      hasLargeTargets: _hasLargeTargets,
                      onChanged: (v) {
                        setState(() => _highContrast = v);
                        AccessibilityPreferencesService.instance.setHighContrast(v);
                      },
                    ),
                    const Divider(height: 1, indent: 64),
                    _PreferenceToggle(
                      icon: Icons.touch_app_rounded,
                      label: 'Large tap targets (48dp+)',
                      subtitle: 'Enforce minimum 48dp touch targets across buttons & controls',
                      value: _hasLargeTargets,
                      hasLargeTargets: _hasLargeTargets,
                      onChanged: (v) {
                        setState(() => _hasLargeTargets = v);
                        AccessibilityPreferencesService.instance.setLargeTargets(v);
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(
                                    v
                                        ? Icons.touch_app_rounded
                                        : Icons.compress_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    v
                                        ? 'Large tap targets (48dp+) enabled'
                                        : 'Standard tap targets enabled',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              duration: const Duration(milliseconds: 1400),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: isHighContrast
                                  ? const Color(0xFF001F3F)
                                  : AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                      },
                    ),
                    const Divider(height: 1, indent: 64),
                    _PreferenceToggle(
                      icon: Icons.volume_up,
                      label: 'Voice guidance for navigation',
                      subtitle: 'Spoken stop announcements and transfer cues',
                      value: _voiceGuidance,
                      hasLargeTargets: _hasLargeTargets,
                      onChanged: (v) {
                        setState(() => _voiceGuidance = v);
                        AccessibilityPreferencesService.instance.setVoiceGuidance(v);
                      },
                    ),
                    const Divider(height: 1, indent: 64),
                    _PreferenceToggle(
                      icon: Icons.vibration,
                      label: 'Haptic alerts for stops',
                      subtitle: 'Vibrate device when approaching destination',
                      value: _hapticAlerts,
                      hasLargeTargets: _hasLargeTargets,
                      onChanged: (v) {
                        setState(() => _hapticAlerts = v);
                        AccessibilityPreferencesService.instance.setHapticAlerts(v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Category 3: Passenger Assistance
                _PreferenceCategory(
                  title: 'Assistance & Environment',
                  icon: Icons.diversity_3,
                  hasLargeTargets: _hasLargeTargets,
                  children: [
                    _PreferenceToggle(
                      icon: Icons.front_hand_rounded,
                      label: 'Boarding assistance required',
                      subtitle: 'Notify driver in advance to assist with ramp deployment',
                      value: _boardingAssistance,
                      hasLargeTargets: _hasLargeTargets,
                      onChanged: (v) {
                        setState(() => _boardingAssistance = v);
                        AccessibilityPreferencesService.instance.setBoardingAssistance(v);
                      },
                    ),
                    const Divider(height: 1, indent: 64),
                    _PreferenceToggle(
                      icon: Icons.hearing_disabled,
                      label: 'Show quiet routes',
                      subtitle: 'Prioritize lower crowd levels and quieter transit options',
                      value: _quietRoutes,
                      hasLargeTargets: _hasLargeTargets,
                      onChanged: (v) {
                        setState(() => _quietRoutes = v);
                        AccessibilityPreferencesService.instance.setQuietRoutes(v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Save Preferences CTA Button (Dynamic height responding to large tap targets)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  width: double.infinity,
                  height: context.buttonHeight,
                  child: FilledButton.icon(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: isHighContrast
                          ? const Color(0xFF001F3F)
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      side: isHighContrast
                          ? const BorderSide(color: Colors.black, width: 2)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: isHighContrast ? 0 : 2,
                    ),
                    icon: Icon(
                      Icons.check_circle_outline_rounded,
                      size: context.tapIconSize,
                    ),
                    label: Text(
                      'Save Preferences',
                      style: TextStyle(
                        fontSize: context.buttonFontSize,
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
    this.hasLargeTargets = true,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool hasLargeTargets;

  @override
  Widget build(BuildContext context) {
    final isHighContrast =
        Theme.of(context).colorScheme.outline == const Color(0xFF000000) ||
        AccessibilityPreferencesService.instance.isHighContrast;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.white : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighContrast ? Colors.black : AppColors.outlineVariant,
          width: isHighContrast ? 2.0 : 1.0,
        ),
        boxShadow: isHighContrast
            ? null
            : [
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
          AnimatedPadding(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.fromLTRB(
              16,
              hasLargeTargets ? 16 : 12,
              16,
              hasLargeTargets ? 12 : 8,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: hasLargeTargets ? 22 : 19,
                  color: isHighContrast ? Colors.black : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: hasLargeTargets ? 16.5 : 15.0,
                    fontWeight: FontWeight.w700,
                    color: isHighContrast ? Colors.black : AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isHighContrast ? Colors.black : AppColors.outlineVariant,
            thickness: isHighContrast ? 1.5 : 1.0,
          ),
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
    this.hasLargeTargets = true,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool hasLargeTargets;

  @override
  Widget build(BuildContext context) {
    final isHighContrast =
        Theme.of(context).colorScheme.outline == const Color(0xFF000000) ||
        AccessibilityPreferencesService.instance.isHighContrast;

    final targetMinHeight = hasLargeTargets ? 64.0 : 48.0;
    final verticalPadding = hasLargeTargets ? 12.0 : 6.0;
    final iconBoxSize = hasLargeTargets ? 46.0 : 38.0;
    final iconSize = hasLargeTargets ? 24.0 : 20.0;
    final labelFontSize = hasLargeTargets ? 15.5 : 14.0;
    final subtitleFontSize = hasLargeTargets ? 12.5 : 11.5;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          constraints: BoxConstraints(minHeight: targetMinHeight),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: verticalPadding),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: iconBoxSize,
                height: iconBoxSize,
                decoration: BoxDecoration(
                  color: isHighContrast
                      ? (value ? const Color(0xFF001F3F) : const Color(0xFFE5E5E5))
                      : (value
                          ? AppColors.primaryContainer.withValues(alpha: 0.25)
                          : AppColors.surfaceContainer),
                  borderRadius: BorderRadius.circular(10),
                  border: isHighContrast
                      ? Border.all(color: Colors.black, width: 1.5)
                      : null,
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: isHighContrast
                      ? (value ? Colors.white : Colors.black)
                      : (value ? AppColors.primary : AppColors.onSurfaceVariant),
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
                      style: TextStyle(
                        fontSize: labelFontSize,
                        fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w600,
                        color: isHighContrast ? Colors.black : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        color: isHighContrast
                            ? const Color(0xFF1A1A1A)
                            : AppColors.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                label: label,
                child: AnimatedScale(
                  scale: hasLargeTargets ? 1.05 : 0.9,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    activeThumbColor: Colors.white,
                    activeTrackColor: isHighContrast
                        ? const Color(0xFF001F3F)
                        : AppColors.primary,
                    inactiveThumbColor: isHighContrast
                        ? Colors.black
                        : AppColors.onSurfaceVariant,
                    inactiveTrackColor: isHighContrast
                        ? const Color(0xFFE5E5E5)
                        : AppColors.surfaceVariant,
                    trackOutlineColor: isHighContrast
                        ? const WidgetStatePropertyAll(Colors.black)
                        : null,
                    trackOutlineWidth: isHighContrast
                        ? const WidgetStatePropertyAll(2.0)
                        : null,
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
