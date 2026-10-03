import 'package:flutter/material.dart';

import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/boarding_request.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

/// Boarding Assistance request screen — ramp, extra time, boarding help.
class BoardingAssistanceScreen extends StatefulWidget {
  const BoardingAssistanceScreen({
    super.key,
    this.busId = 'bus_138_outbound',
    this.stopName = 'Colombo Fort Station',
    this.stationId = 'st_fort',
    this.busLabel = 'Route 138',
    this.minutesAway = 3,
  });

  final String busId;
  final String stopName;
  final String stationId;
  final String busLabel;
  final int minutesAway;

  @override
  State<BoardingAssistanceScreen> createState() =>
      _BoardingAssistanceScreenState();
}

class _BoardingAssistanceScreenState extends State<BoardingAssistanceScreen> {
  static const double _desktopBreakpoint = 768;
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  bool _deployRamp = false;
  bool _extraTime = false;
  bool _boardingHelp = false;
  bool _isSubmitting = false;

  bool get _hasSelection => _deployRamp || _extraTime || _boardingHelp;

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendRequest() async {
    if (_isSubmitting) return;

    if (!_hasSelection) {
      _showSnack('Please select at least one assistance option.');
      return;
    }

    final selected = <String>[
      if (_deployRamp) 'Deploy Ramp',
      if (_extraTime) 'Extra Time',
      if (_boardingHelp) 'Boarding Help',
    ];

    setState(() => _isSubmitting = true);

    try {
      final user = _authService.currentUser;
      final riderId = user?.uid ?? 'guest_rider';
      final riderName = (user?.displayName != null && user!.displayName!.isNotEmpty)
          ? user.displayName!
          : (user?.email != null && user!.email!.isNotEmpty
              ? user.email!
              : 'Rider (${riderId.length > 6 ? riderId.substring(0, 6) : riderId})');

      final request = BoardingRequest(
        id: 'req_${DateTime.now().millisecondsSinceEpoch}',
        riderId: riderId,
        riderName: riderName,
        busId: widget.busId,
        routeNo: widget.busLabel,
        stationId: widget.stationId,
        stopName: widget.stopName,
        assistanceTypes: selected,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _firestoreService.createBoardingRequest(request);

      _showSnack(
        'Assistance request sent: ${selected.join(', ')}. Status: Pending',
      );

      if (mounted) {
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      _showSnack('Could not send assistance request: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;
    final isHC = context.isHighContrast;

    return Scaffold(
      backgroundColor: context.surfaceColor,
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
                        Text(
                          'Request Assistance',
                          style: TextStyle(
                            fontSize: 18,
                            height: 24 / 18,
                            fontWeight: FontWeight.w600,
                            color: context.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Divider(
                          height: 1,
                          color: isHC ? Colors.black : AppColors.surfaceVariant,
                        ),
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
                        Divider(
                          height: 1,
                          color: isHC ? Colors.black : AppColors.surfaceVariant,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _sendRequest,
                            style: FilledButton.styleFrom(
                              backgroundColor: isHC
                                  ? const Color(0xFF001F3F)
                                  : AppColors.primaryContainer,
                              foregroundColor: AppColors.onPrimary,
                              side: isHC
                                  ? const BorderSide(color: Colors.black, width: 2)
                                  : null,
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
                              backgroundColor: isHC ? Colors.white : null,
                              foregroundColor: isHC
                                  ? Colors.black
                                  : AppColors.primaryContainer,
                              side: BorderSide(
                                color: isHC
                                    ? Colors.black
                                    : AppColors.primaryContainer,
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
      bottomNavigationBar: null,
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
    final isHC = context.isHighContrast;

    return Material(
      color: isHC ? Colors.white : AppColors.surfaceContainerLow,
      elevation: isHC ? 0 : 1,
      shadowColor: isHC ? null : AppColors.onSurface.withValues(alpha: 0.08),
      shape: isHC
          ? const Border(bottom: BorderSide(color: Colors.black, width: 2))
          : null,
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
                  color: isHC ? Colors.black : AppColors.primary,
                  tooltip: 'Back',
                ),
                Expanded(
                  child: Text(
                    'Access Transit',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      height: 28 / 22,
                      fontWeight: FontWeight.w700,
                      color: isHC ? Colors.black : AppColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onMenu,
                  icon: const Icon(Icons.person_outline),
                  color: isHC ? Colors.black : AppColors.primary,
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
    final isHC = context.isHighContrast;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isHC
            ? Border.all(color: Colors.black, width: 2)
            : Border.all(color: AppColors.surfaceVariant),
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
                  '$busLabel arriving in $minutesAway mins',
                  style: TextStyle(
                    fontSize: 18,
                    height: 24 / 18,
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 18,
                      color: isHC ? Colors.black : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stopName,
                        style: TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          color: context.subtextColor,
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
              color: isHC ? Colors.white : AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
              border: isHC ? Border.all(color: Colors.black, width: 2) : null,
            ),
            child: Column(
              children: [
                Text(
                  '$minutesAway',
                  style: TextStyle(
                    fontSize: 22,
                    height: 28 / 22,
                    fontWeight: FontWeight.w700,
                    color: isHC
                        ? const Color(0xFF001F3F)
                        : AppColors.onPrimaryContainer,
                  ),
                ),
                Text(
                  'MIN',
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w600,
                    color: isHC ? Colors.black : AppColors.onPrimaryContainer,
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
    final isHC = context.isHighContrast;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isHC ? Colors.white : AppColors.secondary,
        borderRadius: BorderRadius.circular(8),
        border: isHC
            ? Border.all(color: const Color(0xFF003833), width: 2)
            : null,
        boxShadow: isHC
            ? null
            : [
                BoxShadow(
                  color: AppColors.onSurface.withValues(alpha: 0.06),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: isHC ? const Color(0xFF003833) : AppColors.onSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ramp verified operational by 12 users today',
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
                color: isHC ? const Color(0xFF003833) : AppColors.onSecondary,
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
    final isHC = context.isHighContrast;

    return Material(
      color: isHC
          ? Colors.white
          : (selected
              ? AppColors.primaryContainer.withValues(alpha: 0.1)
              : AppColors.surfaceContainerLowest),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 128,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isHC
                ? Border.all(
                    color: selected ? const Color(0xFF001F3F) : Colors.black,
                    width: selected ? 3 : 2,
                  )
                : Border.all(
                    color: selected ? AppColors.primary : AppColors.outlineVariant,
                    width: selected ? 1.5 : 1,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: isHC
                    ? (selected ? const Color(0xFF001F3F) : Colors.black)
                    : (selected
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: isHC
                      ? (selected ? const Color(0xFF001F3F) : Colors.black)
                      : (selected ? AppColors.primary : AppColors.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

