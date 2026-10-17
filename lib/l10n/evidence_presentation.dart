import 'package:flutter/widgets.dart';

import 'localization_context.dart';
import 'home_presentation.dart';

/// Fixed evidence labels only; original observations and names remain data.
extension EvidencePresentation on BuildContext {
  String evidenceText(String value) => switch (value) {
    "Unresolved barrier - needs recheck" => l10n.evidenceRecheckSummary,
    "Barrier reported - review before travel" => l10n.evidenceBarrierSummary,
    "Positive observation - view details" => l10n.evidencePositiveSummary,
    "Unknown - no current observation" => l10n.evidenceUnknownSummary,
    "Unknown - observation time unavailable" => l10n.evidenceTimeUnknown,
    "Unknown — latest observation expired" => l10n.evidenceExpired,
    "Unresolved barrier — needs recheck; current condition unknown" =>
      l10n.evidenceRecheckUnknown,
    "Unknown — condition could not be determined" =>
      l10n.evidenceConditionUnknown,
    "Barrier — community-confirmed observation" =>
      l10n.evidenceBarrierConfirmed,
    "Positive — community-confirmed observation" =>
      l10n.evidencePositiveConfirmed,
    "Barrier reported — verification unknown" => l10n.evidenceBarrierUnverified,
    "Positive reported — verification unknown" =>
      l10n.evidencePositiveUnverified,
    "Confirmation time: Unknown" => l10n.evidenceNoConfirmationTime,
    "Vehicle ramp conditions" => l10n.evidenceVehicleSection,
    "Boarding stop conditions" => l10n.evidenceBoardingSection,
    "Destination stop conditions" => l10n.evidenceDestinationSection,
    "Driver assistance observations" => l10n.evidenceAssistanceSection,
    "Community observations describe specific conditions; they do not verify the entire journey." =>
      l10n.evidenceDisclosure,
    "Unknown — no observation available" => l10n.evidenceEmpty,
    "Community member" => l10n.evidenceMember,
    "Working observed" => l10n.rampWorkingObserved,
    "Broken reported - unresolved warning" => l10n.rampBrokenUnresolved,
    "Unknown - a new check is required" => l10n.rampNewCheck,
    "Equipped" => l10n.rampEquipped,
    "Not listed" => l10n.rampNotListed,
    "Vehicle ramp" => l10n.rampTitle,
    "Operator observation" => l10n.rampOperatorSource,
    "A working observation does not resolve existing community barriers." =>
      l10n.rampBarrierDisclosure,
    "Map unavailable · stop coordinates have not been reviewed. Use the stop list." =>
      l10n.mapMissingCoordinates,
    "Current bus location" => l10n.mapCurrentBus,
    "Stop locations · road route geometry unavailable" =>
      l10n.mapNoRoadGeometry,
    "Map tiles unavailable · retry or use the stop list" => l10n.mapTileRetry,
    "Published timetable • vehicle unassigned" => l10n.timetableUnassigned,
    "Times may change. Vehicle registration, accessibility and live location are unknown. Driver assistance is unavailable until an authorized vehicle is connected." =>
      l10n.timetableUnknownDisclosure,
    'Working reported' => l10n.legacyUi0,
    'Barrier reported' => l10n.legacyUi1,
    'Unknown' => l10n.resultsUnknown,
    _ => value,
  };
  String evidenceAge(DateTime? at, DateTime now) =>
      at == null ? l10n.resultsUnknown : homeAge(at, clock: now);
}
