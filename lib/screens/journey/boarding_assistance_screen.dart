import '../../widgets/accessible_tap_target.dart';
import '../../widgets/assistance_labels.dart';

import 'package:flutter/material.dart';

import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/boarding_request.dart';
import '../../models/assistance_target.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/assistance_submission_service.dart';
import 'assistance_request_status_screen.dart';
import '../../l10n/localization_context.dart';

/// Every entry point carries an exact resolved target; missing context stays unknown.
void openBoardingAssistance(
  BuildContext context, {
  required AssistanceTarget? target,
  int? minutesAway,
}) {
  if (target == null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.assistFormUnknown)));
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BoardingAssistanceScreen(
        busId: target.busId,
        stationId: target.stationId,
        stopName: target.stopName,
        busLabel: target.busLabel,
        purpose: target.purpose,
        serviceRunId: target.serviceRunId,
        boardingStationId: target.boardingStationId,
        alightingStationId: target.alightingStationId,
        minutesAway: minutesAway != null && minutesAway >= 0
            ? minutesAway
            : null,
      ),
    ),
  );
}

/// Boarding Assistance request screen — ramp, extra time, boarding help.
class BoardingAssistanceScreen extends StatefulWidget {
  const BoardingAssistanceScreen({
    super.key,
    required this.busId,
    required this.stopName,
    required this.stationId,
    required this.busLabel,
    this.minutesAway,
    this.purpose = AssistancePurpose.boarding,
    this.firestoreService,
    this.authService,
    this.submissionService,
    this.serviceRunId,
    this.boardingStationId,
    this.alightingStationId,
  });

  final String busId;
  final String? serviceRunId, boardingStationId, alightingStationId;
  final String stopName;
  final String stationId;
  final String busLabel;
  final int? minutesAway;
  final AssistancePurpose purpose;
  final FirestoreService? firestoreService;
  final AuthService? authService;
  final AssistanceSubmissionService? submissionService;

  @override
  State<BoardingAssistanceScreen> createState() =>
      _BoardingAssistanceScreenState();
}

class _BoardingAssistanceScreenState extends State<BoardingAssistanceScreen> {
  static const double _desktopBreakpoint = 768;
  FirestoreService get _firestoreService =>
      widget.firestoreService ?? FirestoreService();
  AuthService get _authService => widget.authService ?? AuthService();

  bool _deployRamp = false;
  bool _extraTime = false;
  bool _boardingHelp = false;
  bool _isSubmitting = false;

  bool get _hasSelection => _deployRamp || _extraTime || _boardingHelp;

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendRequest() async {
    if (_isSubmitting) return;
    if (_firestoreService.runAssistanceEnabled &&
        [
          widget.serviceRunId,
          widget.boardingStationId,
          widget.alightingStationId,
        ].any((v) => v == null || v.isEmpty)) {
      _showSnack(context.l10n.assistanceChooseRun);
      return;
    }

    if (!_hasSelection) {
      _showSnack(context.l10n.assistFormSelect);
      return;
    }

    if ([
      widget.busId,
      widget.stationId,
      widget.stopName,
      widget.busLabel,
    ].any((value) => value.trim().isEmpty)) {
      _showSnack(context.l10n.assistFormTarget);
      return;
    }

    final selected = <String>[
      if (_deployRamp) 'Deploy Ramp',
      if (_extraTime) 'Extra Time',
      if (_boardingHelp)
        widget.purpose == AssistancePurpose.alighting
            ? 'Alighting Help'
            : 'Boarding Help',
    ];

    final reviewOwner = _authService.currentUser?.uid;
    setState(() => _isSubmitting = true);

    try {
      final bus = await _firestoreService.getBusById(widget.busId);
      final station = await _firestoreService.getStationById(widget.stationId);
      if (!mounted) return;
      if (bus == null ||
          bus.id != widget.busId ||
          station == null ||
          station.id != widget.stationId ||
          !bus.stops.contains(station.id)) {
        _showSnack(context.l10n.assistFormWrongStop);
        return;
      }
      final approved = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.assistFormConfirm),
          content: Text(
            '${context.l10n.assistFormBusRoute(bus.displayBusNo, bus.routeNo)}\n'
            '${widget.purpose == AssistancePurpose.alighting ? context.l10n.assistFormAlightAt(station.name) : context.l10n.assistFormBoardAt(station.name)}\n'
            '${selected.map((value) => assistanceType(context, value)).join(', ')}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.assistFormEdit),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.assistFormSendConfirm),
            ),
          ],
        ),
      );
      if (!mounted || approved != true) return;
      final user = _authService.currentUser;
      if (user == null || user.uid.isEmpty) {
        _showSnack(context.l10n.assistFormSignIn);
        return;
      }
      if (user.uid != reviewOwner) {
        _showSnack(context.l10n.assistFormAccountChanged);
        return;
      }
      final riderId = user.uid;
      final riderName =
          (user.displayName != null && user.displayName!.isNotEmpty)
          ? user.displayName!
          : (user.email != null && user.email!.isNotEmpty
                ? user.email!
                : 'Rider (${riderId.length > 6 ? riderId.substring(0, 6) : riderId})');

      final request = BoardingRequest(
        serviceRunId: widget.serviceRunId,
        boardingStationId: widget.boardingStationId,
        alightingStationId: widget.alightingStationId,
        id: '',
        riderId: riderId,
        riderName: riderName,
        busId: bus.id,
        routeNo: bus.routeNo,
        stationId: station.id,
        stopName: station.name,
        purpose: widget.purpose.name,
        assistanceTypes: selected,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final service =
          widget.submissionService ?? AssistanceSubmissionService.instance;
      final entry = await service.enqueue(request);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AssistanceRequestStatusScreen(
            request: entry.request,
            service: service,
            repository: _firestoreService,
            startUpload: true,
          ),
        ),
      );
    } catch (e) {
      _showSnack(context.l10n.assistFormPrepareError);
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
              padding: EdgeInsets.fromLTRB(16, 16, 16, isDesktop ? 24 : 24),
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
                          stopName:
                              widget.purpose == AssistancePurpose.alighting
                              ? context.l10n.assistFormAlightAt(widget.stopName)
                              : context.l10n.assistFormBoardAt(widget.stopName),
                        ),
                        const SizedBox(height: 16),
                        const _CommunityStatusBadge(),
                        const SizedBox(height: 24),
                        Text(
                          context.l10n.assistFormTitle,
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
                                label: context.l10n.assistFormRamp,
                                selected: _deployRamp,
                                onTap: () =>
                                    setState(() => _deployRamp = !_deployRamp),
                              ),
                              _AssistanceTile(
                                icon: Icons.schedule,
                                label: context.l10n.assistFormTime,
                                selected: _extraTime,
                                onTap: () =>
                                    setState(() => _extraTime = !_extraTime),
                              ),
                              _AssistanceTile(
                                icon: Icons.waving_hand,
                                label:
                                    widget.purpose ==
                                        AssistancePurpose.alighting
                                    ? context.l10n.assistFormAlighting
                                    : context.l10n.assistFormBoarding,
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
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: context.buttonHeight,
                          ),
                          child: FilledButton.icon(
                            onPressed: _isSubmitting ? null : _sendRequest,
                            style: FilledButton.styleFrom(
                              backgroundColor: isHC
                                  ? const Color(0xFF001F3F)
                                  : AppColors.primaryContainer,
                              foregroundColor: AppColors.onPrimary,
                              side: isHC
                                  ? const BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    )
                                  : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              textStyle: TextStyle(
                                fontSize: context.buttonFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            icon: Icon(Icons.send, size: context.tapIconSize),
                            label: Text(context.l10n.assistFormSend),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: context.buttonHeight,
                          ),
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
                              textStyle: TextStyle(
                                fontSize: context.buttonFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: Text(context.l10n.profileCancel),
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
  const _TopBar({required this.onBack, required this.onMenu});

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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: context.hasLargeTargets ? 56 : 48,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  constraints: context.appBarActionConstraints,
                  onPressed: onBack,
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    size: context.tapIconSize,
                  ),
                  color: isHC ? Colors.black : AppColors.primary,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
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
                  constraints: context.appBarActionConstraints,
                  onPressed: onMenu,
                  icon: Icon(Icons.person_outline, size: context.tapIconSize),
                  color: isHC ? Colors.black : AppColors.primary,
                  tooltip: context.l10n.homeProfile,
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
  final int? minutesAway;
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
      child: _ArrivingHeader(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  minutesAway == null
                      ? busLabel
                      : context.l10n.assistFormArrival(busLabel, minutesAway!),
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
                  minutesAway?.toString() ?? '—',
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
                  minutesAway == null
                      ? context.l10n.assistFormEtaUnknown
                      : context.l10n.assistFormMinutes,
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
              context.l10n.assistFormAckHelp,
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
      child: AccessibleTapTarget(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 128),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isHC
                  ? Border.all(
                      color: selected ? const Color(0xFF001F3F) : Colors.black,
                      width: selected ? 3 : 2,
                    )
                  : Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.outlineVariant,
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
      ),
    );
  }
}

class _ArrivingHeader extends StatelessWidget {
  const _ArrivingHeader({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 380 ||
          MediaQuery.textScalerOf(context).scale(14) > 20) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final child in children)
              if (child is Expanded) child.child else child,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );
    },
  );
}
