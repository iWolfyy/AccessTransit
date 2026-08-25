import 'package:flutter/material.dart';

import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_colors.dart';

/// Boarding Assistance request screen — ramp, extra time, boarding help.
class BoardingAssistanceScreen extends StatefulWidget {
  const BoardingAssistanceScreen({
    super.key,
    this.stopName = 'Main St & 4th Ave',
    this.busLabel = 'Bus 42',
    this.minutesAway = 3,
  });

  final String stopName;
  final String busLabel;
  final int minutesAway;

  @override
  State<BoardingAssistanceScreen> createState() =>
      _BoardingAssistanceScreenState();
}

class _BoardingAssistanceScreenState extends State<BoardingAssistanceScreen> {
  static const double _desktopBreakpoint = 768;

  bool _deployRamp = false;
  bool _extraTime = false;
  bool _boardingHelp = false;

  bool get _hasSelection => _deployRamp || _extraTime || _boardingHelp;

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _sendRequest() {
    if (!_hasSelection) {
      _showSnack('Please select at least one assistance option.');
      return;
    }

    final selected = <String>[
      if (_deployRamp) 'Deploy Ramp',
      if (_extraTime) 'Extra Time',
      if (_boardingHelp) 'Boarding Help',
    ];

    _showSnack(
      'Assistance request sent: ${selected.join(', ')}. Status: Pending',
    );

    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _TopBar(
            onBack: () => Navigator.of(context).maybePop(),
            onMenu: () => AppNavigation.openProfile(context),
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
                    constraints: const BoxConstraints(maxWidth: 672),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ArrivingSoonCard(
                          busLabel: widget.busLabel,
                          minutesAway: widget.minutesAway,
                          stopName: widget.stopName,
                        ),
                        const SizedBox(height: 16),
                        const _CommunityStatusBadge(),
                        const SizedBox(height: 24),
                        const Text(
                          'Request Assistance',
                          style: TextStyle(
                            fontSize: 18,
                            height: 24 / 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: AppColors.surfaceVariant),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 600;
                            final tiles = [
                              _AssistanceTile(
                                icon: Icons.accessible,
                                label: 'Deploy Ramp',
                                selected: _deployRamp,
                                onTap: () => setState(
                                  () => _deployRamp = !_deployRamp,
                                ),
                              ),
                              _AssistanceTile(
                                icon: Icons.schedule,
                                label: 'Extra Time',
                                selected: _extraTime,
                                onTap: () =>
                                    setState(() => _extraTime = !_extraTime),
                              ),
                              _AssistanceTile(
                                icon: Icons.waving_hand,
                                label: 'Boarding Help',
                                selected: _boardingHelp,
                                onTap: () => setState(
                                  () => _boardingHelp = !_boardingHelp,
                                ),
                              ),
                            ];

                            if (wide) {
                              return Row(
                                children: [
                                  for (var i = 0; i < tiles.length; i++) ...[
                                    if (i > 0) const SizedBox(width: 16),
                                    Expanded(child: tiles[i]),
                                  ],
                                ],
                              );
                            }

                            return Column(
                              children: [
                                for (var i = 0; i < tiles.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 16),
                                  tiles[i],
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        const Divider(height: 1, color: AppColors.surfaceVariant),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _sendRequest,
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
                            icon: const Icon(Icons.send, size: 20),
                            label: const Text('Send Request'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryContainer,
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
                            child: const Text('Cancel'),
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
          : _AssistanceBottomNav(
              onNavTap: (label) {
                if (label == 'Home') {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  return;
                }
                if (label == 'Live') {
                  Navigator.of(context).maybePop();
                  return;
                }
                if (label == 'Profile') {
                  AppNavigation.openProfile(context);
                  return;
                }
                _showSnack('$label will be available soon.');
              },
            ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    required this.onMenu,
  });

  final VoidCallback onBack;
  final VoidCallback onMenu;

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
                IconButton(
                  onPressed: onMenu,
                  icon: const Icon(Icons.person_outline),
                  color: AppColors.primary,
                  tooltip: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrivingSoonCard extends StatelessWidget {
  const _ArrivingSoonCard({
    required this.busLabel,
    required this.minutesAway,
    required this.stopName,
  });

  final String busLabel;
  final int minutesAway;
  final String stopName;

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
                  '$busLabel arriving in $minutesAway mins',
                  style: const TextStyle(
                    fontSize: 18,
                    height: 24 / 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 18,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stopName,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 64),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  '$minutesAway',
                  style: const TextStyle(
                    fontSize: 22,
                    height: 28 / 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
                const Text(
                  'MIN',
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onPrimaryContainer,
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

class _CommunityStatusBadge extends StatelessWidget {
  const _CommunityStatusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.onSecondary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ramp verified operational by 12 users today',
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w500,
                color: AppColors.onSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistanceTile extends StatelessWidget {
  const _AssistanceTile({
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
          ? AppColors.primaryContainer.withValues(alpha: 0.1)
          : AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 128,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.outlineVariant,
              width: selected ? 1.5 : 1,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: selected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w600,
                  color:
                      selected ? AppColors.primary : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistanceBottomNav extends StatelessWidget {
  const _AssistanceBottomNav({required this.onNavTap});

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
                icon: Icons.directions_bus_outlined,
                label: 'Plan',
                onTap: () => onNavTap('Plan'),
              ),
              _NavItem(
                icon: Icons.sensors,
                label: 'Live',
                selected: true,
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
