import 'package:flutter/widgets.dart';

import 'localization_context.dart';

/// Translate fixed presentation labels only; catalogue names remain data.
extension JourneyPresentation on BuildContext {
  String journeyText(String value) => switch (value) {
    "Scheduled" => l10n.resultsScheduled,
    "Scheduled time passed - departure unconfirmed" =>
      l10n.resultsPastUnconfirmed,
    "Scheduled now - departure unconfirmed" => l10n.resultsNowUnconfirmed,
    "Wheelchair Ramp Ready · Step-free entry" => l10n.resultsRampReady,
    "Ramp equipped · Check operator assistance" => l10n.resultsRampEquipped,
    "Standard bus service" => l10n.resultsStandardService,
    "Unknown" => l10n.resultsUnknown,
    "Low" => l10n.resultsLow,
    "Medium" => l10n.resultsMedium,
    "High" => l10n.resultsHigh,
    "Started run" => l10n.resultsStarted,
    "Demo timetable" => l10n.resultsDemoTimetable,
    "Published timetable" => l10n.resultsPublishedTimetable,
    "Wheelchair Accessible Bus" => l10n.resultsWheelchairBus,
    "Standard Ramp Bus" => l10n.resultsRampBus,
    "Standard Bus" => l10n.resultsStandardBus,
    "Some times are model estimates; confirm with the operator." =>
      l10n.resultsEstimatedTimes,
    "Walking distance is unavailable for this journey. Results are not ranked by walking distance." =>
      l10n.resultsWalkingUnknown,
    "Review trip requirements" => l10n.resultsReviewNeeds,
    "Changes apply only to this search. Turning a requirement off may show services with unknown access or reported barriers. Review the evidence before choosing a journey." =>
      l10n.resultsReviewHelp,
    "Keep requirements" => l10n.resultsKeepNeeds,
    "Apply to this search" => l10n.resultsApplyNeeds,
    "No Accessible Buses Found" => l10n.resultsNoAccessible,
    "No Direct Buses Found" => l10n.resultsNoDirect,
    "No scheduled journeys have known access matching these requirements. Stop access may be unknown or an active barrier may be reported. Review your accessibility filters." =>
      l10n.resultsNoAccessibleHelp,
    "Show all matching buses" => l10n.resultsShowAll,
    "Shows options outside the Accessible tab, including unknown access or reported barriers. Your trip requirements stay applied." =>
      l10n.resultsShowAllHelp,
    "Available Buses" => l10n.resultsTitle,
    "Select a bus to track live journey" => l10n.resultsChooseHelp,
    "Fastest" => l10n.resultsFastest,
    "Route" => l10n.resultsRoute,
    "Timetable estimates - departure unconfirmed. Open route details for GPS status." =>
      l10n.resultsTimetableHelp,
    "Departure" => l10n.resultsDeparture,
    "Arrival" => l10n.resultsArrival,
    "Ramp Available" => l10n.resultsRampAvailable,
    "Low Floor" => l10n.resultsLowFloor,
    "Departure identity is ambiguous. Refresh the selection." =>
      l10n.detailsAmbiguous,
    "Account changed. Return to Search." => l10n.detailsAccountChanged,
    "Service unavailable. Retry" => l10n.detailsUnavailable,
    "Run status unavailable" => l10n.detailsRunUnavailable,
    "Scheduled · run not verified" => l10n.detailsRunUnverified,
    "Completed" => l10n.detailsCompleted,
    "Cancelled" => l10n.detailsCancelled,
    "Location unavailable or stale" => l10n.detailsStale,
    "LIVE GPS" => l10n.detailsLive,
    "Wheelchair access" => l10n.detailsWheelchair,
    "Saved selection · times and needs are preserved; review current conditions." =>
      l10n.detailsSavedHelp,
    "Your current accessibility defaults differ from this saved selection." =>
      l10n.detailsDefaultsDiffer,
    "Catalogue updates unavailable." => l10n.detailsCatalogueUnavailable,
    "Stops on your journey" => l10n.detailsStops,
    "Intermediate stop · time unavailable" => l10n.detailsIntermediateUnknown,
    "Accessibility evidence" => l10n.detailsEvidence,
    "Driver assistance unavailable" => l10n.detailsAssistanceUnavailable,
    "Report a condition" => l10n.detailsReport,
    "Loading reports…" => l10n.detailsLoadingReports,
    "Retry updates" => l10n.detailsRetry,
    "Connect to verify this departure before saving." => l10n.detailsVerifySave,
    "Safe" => l10n.resultsSafe,
    "Warning" => l10n.resultsWarning,
    "Not accessible" => l10n.resultsNotAccessible,
    "Resolved" => l10n.detailsResolved,
    "Unresolved barrier - observation time unknown; needs recheck" =>
      l10n.detailsRecheckUnknown,
    "Observation time unknown" => l10n.detailsObservationUnknown,
    "Expired or unavailable" => l10n.detailsExpired,
    "Unresolved barrier — needs recheck" => l10n.detailsRecheck,
    "Recent observation" => l10n.detailsRecent,
    "Dated timetable" => l10n.resultsSourceDated,
    "Road progress + timetable (low confidence)" => l10n.resultsSourceRoad,
    "GPS at boarding stop" => l10n.resultsSourceBoarding,
    "Timetable interval from GPS-observed stop" => l10n.resultsSourceInterval,
    _ => value,
  };
}
