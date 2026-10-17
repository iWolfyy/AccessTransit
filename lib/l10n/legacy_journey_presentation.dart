import '../services/eta_service.dart';

import 'package:flutter/widgets.dart';

import 'localization_context.dart';

/// Presentation for retained compatibility screens; stored data stays original.
extension LegacyJourneyPresentation on BuildContext {
  String legacyEta(EtaResult result) {
    if (!result.isReliable || result.etaMinutes == null) {
      return l10n.driverEtaUnavailable;
    }
    if (result.etaMinutes! <= 0) return l10n.legacyEtaNow;
    return l10n.legacyEtaApprox('${result.etaMinutes}');
  }

  String legacyText(String value) => switch (value) {
    "Boarding" => l10n.driverBoardingAt,
    "Low" => l10n.resultsLow,
    "Medium" => l10n.resultsMedium,
    "High" => l10n.resultsHigh,
    "Unknown" => l10n.resultsUnknown,
    "Destination" => l10n.homeDestination,
    "Assistance" => l10n.homeAssistance,
    "Just now" => l10n.homeJustNow,
    "Report Issue" => l10n.communityReportAction,
    "Step-free" => l10n.searchStepFreeChip,
    "LIVE GPS" => l10n.detailsLive,
    "Wheelchair access" => l10n.detailsWheelchair,
    "Driver assistance unavailable" => l10n.detailsAssistanceUnavailable,
    "Back to Home" => l10n.deliveryHome,
    "Sign in to save and resume your journey." => l10n.legacyUi2,
    "Journey ownership or status changed. Reopen your saved journeys." =>
      l10n.legacyUi3,
    "Journey save is not confirmed. Check your connection and sign-in, then retry." =>
      l10n.legacyUi4,
    "Vehicle not specified" => l10n.legacyUi5,
    "Back" => l10n.legacyUi6,
    "Confirm Journey" => l10n.legacyUi7,
    "Travel schedule" => l10n.legacyUi8,
    "Selected date" => l10n.legacyUi9,
    "Selected time" => l10n.legacyUi10,
    "First available service on selected date" => l10n.legacyUi11,
    "Timetable departure" => l10n.legacyUi12,
    "Estimated arrival" => l10n.legacyUi13,
    "Some timetable intervals are missing. Times include model estimates; confirm them with the operator." =>
      l10n.legacyUi14,
    "Estimated fare" => l10n.legacyUi15,
    "Prototype estimate. Confirm the actual fare with the operator." =>
      l10n.legacyUi16,
    "Fare details" => l10n.legacyUi17,
    "Travel requirements" => l10n.legacyUi18,
    "Saving a journey does not book a seat or confirm that the bus is running. Review current condition evidence." =>
      l10n.legacyUi19,
    "Saving journey..." => l10n.legacyUi20,
    "Confirm and save journey" => l10n.legacyUi21,
    "Service unavailable. Select a shared service first." => l10n.legacyUi22,
    "This service is unavailable. Return to search." => l10n.legacyUi23,
    "Departure & Route Details" => l10n.legacyUi24,
    "Saved location - live updates unavailable. This is not current bus movement." =>
      l10n.legacyUi25,
    "SCHEDULE" => l10n.legacyUi26,
    "SCHEDULED" => l10n.legacyUi27,
    "EXPECTED ARRIVAL" => l10n.legacyUi28,
    "Request Boarding Assistance" => l10n.legacyUi29,
    "Route Stops Schedule & Live Progress" => l10n.legacyUi30,
    "YOUR BOARDING STOP" => l10n.legacyUi31,
    "BUS IS HERE NOW" => l10n.legacyUi32,
    "Selected segment estimate; payment options unverified." => l10n.legacyUi33,
    "Unknown — no condition evidence available." => l10n.legacyUi34,
    "ACCESSIBLE VEHICLE FEATURES" => l10n.legacyUi35,
    "ACCESSIBILITY WARNING" => l10n.legacyUi36,
    "NOT ACCESSIBLE NOTICE" => l10n.legacyUi37,
    "CONDITION UNKNOWN" => l10n.legacyUi38,
    "Safety & Ride Conditions" => l10n.legacyUi39,
    "Bus Crowd Level" => l10n.legacyUi40,
    "Community Safety Reports" => l10n.legacyUi41,
    "Review and confirm journey" => l10n.legacyUi42,
    "Save to Trip Plan" => l10n.legacyUi43,
    "Report Accessibility Condition" => l10n.legacyUi44,
    "Unable to Load Journey" => l10n.legacyUi45,
    "Loading live journey details from server" => l10n.legacyUi46,
    "Loading your journey…" => l10n.legacyUi47,
    "Bus has not been assigned yet." => l10n.legacyUi48,
    "A saved trip does not reserve a seat or guarantee bus assignment. Check the selected service status." =>
      l10n.legacyUi49,
    "Return to Home screen" => l10n.legacyUi50,
    "Close Live Navigation" => l10n.legacyUi51,
    "Live Navigation" => l10n.legacyUi52,
    "Back to Route Results" => l10n.legacyUi53,
    "Live Tracking to" => l10n.legacyUi54,
    "LIVE" => l10n.legacyUi55,
    "SCHED" => l10n.legacyUi56,
    "Real-time stop progression & ETA" => l10n.legacyUi57,
    "Live Stops" => l10n.legacyUi58,
    "YOUR STOP" => l10n.legacyUi59,
    "Bus is currently here" => l10n.legacyUi60,
    "Passed" => l10n.legacyUi61,
    "Live GPS updates are unavailable. Equipment observations are shown separately below." =>
      l10n.legacyUi62,
    "● Ongoing" => l10n.legacyUi63,
    "● Scheduled" => l10n.legacyUi64,
    "Tracking shows the current vehicle location; it does not confirm your scheduled run." =>
      l10n.legacyUi65,
    "Detailed Vehicle Telemetry" => l10n.legacyUi66,
    "Speed, GPS signals and raw trip data" => l10n.legacyUi67,
    "Approaching" => l10n.legacyUi68,
    "You Board Here" => l10n.legacyUi69,
    "TIMETABLE" => l10n.legacyUi70,
    "Collapse map" => l10n.legacyUi71,
    "Expand map" => l10n.legacyUi72,
    "Fit journey bounds" => l10n.legacyUi73,
    "Focus on bus" => l10n.legacyUi74,
    "Focus on my stop" => l10n.legacyUi75,
    "Zoom in" => l10n.legacyUi76,
    "Zoom out" => l10n.legacyUi77,
    "No GPS signal" => l10n.legacyUi78,
    "Signal Lost" => l10n.legacyUi79,
    "En Route" => l10n.legacyUi80,
    "Stopped" => l10n.legacyUi81,
    "Trip Completed" => l10n.legacyUi82,
    "Offline" => l10n.legacyUi83,
    "Saved location - updates unavailable" => l10n.legacyUi84,
    "Status: Live GPS updates receiving" => l10n.legacyUi85,
    "Status: Location unavailable" => l10n.legacyUi86,
    "Unavailable" => l10n.legacyUi87,
    "Current Status" => l10n.legacyUi88,
    "Last Updated" => l10n.legacyUi89,
    "Next Stop" => l10n.legacyUi90,
    "Your Destination" => l10n.legacyUi91,
    "Next: " => l10n.legacyUi92,
    "Final: " => l10n.legacyUi93,
    "Request boarding or stop assistance from driver" => l10n.legacyUi94,
    "Request Stop Assistance" => l10n.legacyUi95,
    "Emergency calling unavailable. Use your phone to call for help." =>
      l10n.legacyUi96,
    "Emergency" => l10n.legacyUi97,
    "Report accessibility issue or vehicle condition" => l10n.legacyUi98,
    "Emergency calling is unavailable in this app. Use your phone to call for help." =>
      l10n.legacyUi99,
    "Live Per-Stop Timeline" => l10n.legacyUi100,
    "Live Run" => l10n.legacyUi101,
    _ => value,
  };
}
