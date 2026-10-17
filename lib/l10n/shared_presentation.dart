import 'package:flutter/widgets.dart';

import 'localization_context.dart';

/// Fixed application messages only. Never translate catalogue or authored data.
extension SharedPresentation on BuildContext {
  String sharedText(String value) => switch (value) {
    "DEMONSTRATION: Sample transit data. Shared reporting, assistance and journeys are disabled." =>
      l10n.sharedCatalogueDemo,
    "Saved transit data. Refresh to check for updates; timetables and availability may have changed." =>
      l10n.sharedCatalogueSaved,
    "Transit data unavailable. Connect and retry; no sample services are substituted." =>
      l10n.sharedCatalogueUnavailable,
    "No shared transit data available for this catalogue. Please retry later." =>
      l10n.sharedCatalogueEmpty,
    "Refresh" => l10n.sharedRefresh,
    "Refreshing…" => l10n.sharedRefreshing,
    "Saving status…" => l10n.sharedSavingStatus,
    "Status update was not confirmed. Check your connection, operator approval and bus assignment, then retry." =>
      l10n.sharedOperatorStatusError,
    "Administrator access" => l10n.sharedAdminAccess,
    "Checking administrator access..." => l10n.sharedAdminChecking,
    "An administrator claim and an online connection are required. A profile role does not grant access." =>
      l10n.sharedAdminRequired,
    "Check again" => l10n.sharedCheckAgain,
    "Sign in" => l10n.sharedSignIn,
    "Saved journey" => l10n.sharedSavedJourney,
    "Saved journey updates unavailable. Check your connection and reopen Home to retry." =>
      l10n.sharedJourneyUpdatesError,
    "Journey status change is not confirmed. Retry when connected." =>
      l10n.sharedJourneyChangeError,
    "Resume journey" => l10n.sharedResume,
    "Mark completed" => l10n.sharedComplete,
    "Cancel saved journey" => l10n.sharedCancelJourney,
    "Saving keeps this selection. It does not book a seat or start a journey." =>
      l10n.sharedSaveDisclosure,
    "Saved status unavailable. Retry to verify your bookmark." =>
      l10n.sharedSaveStatusError,
    "Save change is not confirmed. Check your connection and retry." =>
      l10n.sharedSaveError,
    "Sign in with the account saving this trip." => l10n.sharedSaveOwner,
    "Saved trip acknowledgement did not match." => l10n.sharedSaveMismatch,
    "Sign in to save this trip." => l10n.sharedSaveSignIn,
    "Saving…" => l10n.sharedSaving,
    "Stop alert unavailable" => l10n.sharedStopAlert,
    "Automatic stop alerts and background notifications are unavailable. Follow trip progress manually; the app will not notify you before your stop." =>
      l10n.sharedStopAlertHelp,
    "Your journey to inclusive travel begins here." => l10n.sharedSplashTagline,
    "Loading." => l10n.sharedLoading,
    "Stops in travel order" => l10n.sharedStopsOrder,
    "Driver registration is an application for access. Review identity and operating authority before approval. Approval does not verify equipment or guarantee a service." =>
      l10n.sharedDriverReviewHelp,
    "Add New Halt / Station" => l10n.sharedAddStation,
    "Station Name" => l10n.sharedStationName,
    "e.g. Bambalapitiya Junction" => l10n.sharedStationExample,
    "Station ID (e.g. bambalapitiya_junc)" => l10n.sharedStationId,
    "Target Bus Route" => l10n.sharedTargetRoute,
    "Insert Position Index (0-based)" => l10n.sharedInsertIndex,
    "1 (insert as 2nd stop)" => l10n.sharedInsertHint,
    "Required" => l10n.sharedRequired,
    "Ramp" => l10n.sharedRamp,
    "Elevator" => l10n.sharedElevator,
    "Cancel" => l10n.sharedCancel,
    "Add Station" => l10n.sharedAddStationAction,
    "Could not add the stop. Check your access and connection, then retry." =>
      l10n.sharedStationError,
    "Live Accessibility" => l10n.sharedLiveAccessibility,
    "Equipment checks are separate from live GPS. A working report does not verify the whole journey." =>
      l10n.sharedEquipmentHelp,
    "Condition updates unavailable. Working conditions are Unknown; earlier warnings are retained." =>
      l10n.sharedConditionsUnavailable,
    "Vehicle ramp telemetry reports a problem. Equipment-check time is Unknown; check before boarding." =>
      l10n.sharedRampWarning,
    "Community observations" => l10n.sharedCommunityObservations,
    "Unknown — vehicle ramp warning needs checking" => l10n.sharedRampUnknown,
    "Driver assistance" => l10n.sharedDriverAssistance,
    "Positive assistance observation" => l10n.sharedPositiveAssistance,
    "Operator vehicle check" => l10n.sharedOperatorCheck,
    "Hide observation details" => l10n.sharedHideObservations,
    "View observation details" => l10n.sharedViewObservations,
    _ => value,
  };
}
