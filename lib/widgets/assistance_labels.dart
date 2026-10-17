import 'package:flutter/widgets.dart';

import '../l10n/localization_context.dart';
import '../models/boarding_request.dart';
import '../l10n/assistance_receipt_presentation.dart';

String assistanceType(BuildContext c, String type) => switch (type) {
  'Deploy Ramp' => c.l10n.assistanceRamp,
  'Extra Time' => c.l10n.assistanceExtraTime,
  'Boarding Help' => c.l10n.assistanceBoardingHelp,
  'Alighting Help' => c.l10n.assistanceAlightingHelp,
  _ => type,
};
String? assistanceEndReason(BuildContext c, String? reason) => switch (reason) {
  'run-ended' => c.l10n.assistanceRunEnded,
  'stop-passed' => c.l10n.assistanceStopPassed,
  'driver-unavailable' ||
  'driver-suspended' => c.l10n.assistanceDriverUnavailable,
  _ => null,
};

String assistanceStatus(BuildContext context, BoardingRequest r) =>
    r.policyVersion != 2
    ? switch (r.driverStatusLabel) {
        "Awaiting driver acknowledgement" => context.l10n.assistancePending,
        "Driver acknowledged" => context.l10n.assistanceAccepted,
        "Driver marked completed" => context.l10n.assistanceCompleted,
        "Driver declined" => context.l10n.assistanceDeclined,
        "Cancelled" => context.l10n.assistanceCancelled,
        "Request expired" => context.l10n.assistanceExpired,
        _ => context.assistanceReceiptText(r.driverStatusLabel),
      }
    : switch (r.status) {
        'pending' => context.l10n.assistancePending,
        'acknowledged' => context.l10n.assistanceAccepted,
        'rejected' => context.l10n.assistanceDeclined,
        'completed' => context.l10n.assistanceCompleted,
        'cancelled' => context.l10n.assistanceCancelled,
        'expired' => context.l10n.assistanceExpired,
        _ => context.l10n.assistanceUnavailable,
      };
