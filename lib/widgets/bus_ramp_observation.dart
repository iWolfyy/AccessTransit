import '../l10n/evidence_presentation.dart';
import '../l10n/localization_context.dart';
import 'evidence_refresh.dart';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../models/bus.dart';
import '../core/utils/time_utils.dart';

/// Vehicle capability and an attributed operational observation are separate facts.
class BusRampObservation extends StatelessWidget {
  const BusRampObservation({super.key, this.bus, this.currentTime});
  final Bus? bus;
  final DateTime? currentTime;

  @override
  Widget build(BuildContext context) => currentTime != null
      ? _buildAtTime(context, currentTime!)
      : EvidenceRefresh(buses: [?bus], builder: _buildAtTime);

  Widget _buildAtTime(BuildContext context, DateTime now) {
    final checkedAt = bus?.rampCheckedAt;
    final displayCheck = checkedAt != null && !checkedAt.isAfter(now)
        ? checkedAt
        : null;
    final condition = bus?.rampCondition(currentTime: now);
    final label = condition == true
        ? context.l10n.rampWorkingObserved
        : condition == false
        ? context.l10n.rampBrokenUnresolved
        : context.l10n.rampNewCheck;
    final capability = bus == null
        ? context.l10n.resultsUnknown
        : bus!.hasRamp
        ? context.l10n.rampEquipped
        : context.l10n.rampNotListed;
    final hasSource = bus?.rampCheckedBy?.trim().isNotEmpty == true;
    final stateColor = context.isHighContrast
        ? Colors.black
        : condition == false
        ? AppColors.error
        : condition == true
        ? AppColors.secondary
        : context.subtextColor;
    return Material(
      color: context.cardColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.isHighContrast
              ? Colors.black
              : AppColors.outlineVariant.withValues(alpha: 0.6),
          width: context.isHighContrast ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            tilePadding: const EdgeInsets.all(16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            leading: Icon(
              condition == false
                  ? Icons.warning_amber_rounded
                  : condition == true
                  ? Icons.accessible_rounded
                  : Icons.help_outline_rounded,
              color: stateColor,
            ),
            title: Text(
              context.l10n.rampTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textColor,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: stateColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.rampCapability(capability),
                    style: TextStyle(fontSize: 12, color: context.subtextColor),
                  ),
                  Text(
                    context.l10n.rampCheckedAge(
                      context.evidenceAge(displayCheck, now),
                    ),
                    style: TextStyle(fontSize: 12, color: context.subtextColor),
                  ),
                ],
              ),
            ),
            children: [
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                context.l10n.rampSource(
                  hasSource
                      ? context.l10n.rampOperatorSource
                      : context.l10n.resultsUnknown,
                ),
                style: TextStyle(fontSize: 14, color: context.textColor),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.rampRecordedAt(
                  displayCheck == null
                      ? context.l10n.resultsUnknown
                      : _formatCheck(displayCheck),
                ),
                style: TextStyle(fontSize: 14, color: context.subtextColor),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              context.l10n.rampBarrierDisclosure,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: context.subtextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCheck(DateTime checkedAt) {
    final local = checkedAt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${TimeUtils.formatTimeString(local)}';
  }
}
