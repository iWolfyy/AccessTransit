import 'package:flutter/material.dart';

import '../logic/delay_eta_logic.dart';

import 'localization_context.dart';

/// Fixed driver UI labels only; persisted enums and rider/driver text stay data.
extension DriverPresentation on BuildContext {
  String driverText(String label) {
    final delayed = RegExp(r'^Delayed by (\d+) mins?(?: • (.*))?$')
        .firstMatch(label);
    if (delayed != null) {
      final translated = l10n.driverLateMinutes(int.parse(delayed[1]!));
      final reason = delayed[2];
      return reason == null
          ? translated
          : '$translated • ${driverText(reason)}';
    }
    final early = RegExp(r'^Running (\d+) mins? early$').firstMatch(label);
    if (early != null) return l10n.driverEarlyMinutes(int.parse(early[1]!));
    return switch (label) {
      'On Time' => l10n.sharedOnTime,
      "Operator Dashboard" => l10n.driverDashboard,
      "Operator" => l10n.driverFallback,
      "Add Station to Route" => l10n.driverAddStop,
      "No physical buses are available on your assigned route. Ask the administrator to add or review a bus." =>
        l10n.driverNoBuses,
      "No shared GPS update" => l10n.driverNoGps,
      "Selected bus unavailable; broadcasting stopped locally" =>
        l10n.driverBusUnavailable,
      "Bus assignment unavailable; broadcasting stopped locally" =>
        l10n.driverAssignmentUnavailable,
      "Connect to verify dated departures." => l10n.driverVerifyRuns,
      "Sign in as an approved operator first." => l10n.driverSignInFirst,
      "Only the assigned driver can update this bus." =>
        l10n.driverAssignedOnly,
      "Bus assignment was not confirmed. Refresh and retry." =>
        l10n.driverClaimFailed,
      "Ramp working observation saved" => l10n.driverRampWorkingSaved,
      "Ramp broken observation saved" => l10n.driverRampBrokenSaved,
      "Could not confirm all ramp updates. Refresh and retry." =>
        l10n.driverRampFailed,
      "Could not confirm all occupancy updates. Refresh and retry." =>
        l10n.driverOccupancyFailed,
      "Claim this bus before starting a trip." => l10n.driverClaimFirst,
      "Select an administrator-published dated departure." =>
        l10n.driverSelectRun,
      "Late start reason" => l10n.driverLateTitle,
      "At least 5 characters. Latest start is 30 minutes after departure." =>
        l10n.driverLateHelp,
      "Continue" => l10n.driverContinue,
      "Enter a late-start reason of at least 5 characters." =>
        l10n.driverLateRequired,
      "Shared GPS acknowledged" => l10n.driverGpsAcknowledged,
      "AccessTransit Live Bus Tracking" => l10n.driverTrackingTitle,
      "GPS unavailable; last shared fix may be stale" =>
        l10n.driverGpsUnavailable,
      "GPS updates unavailable. Check location access and retry." =>
        l10n.driverGpsStreamError,
      "Boarding session started. Record actual departure when leaving." =>
        l10n.driverBoardingStarted,
      "Active dated trip resumed. GPS broadcasting acknowledged." =>
        l10n.driverRunResumed,
      "Trip start was not confirmed. Refresh and retry." =>
        l10n.driverStartFailed,
      "Pending GPS upload; coordinates are local" => l10n.driverGpsPending,
      "GPS upload failed/offline; next fix retries" => l10n.driverGpsRetry,
      "Boarding cancelled; broadcast ended" => l10n.driverBoardingEnded,
      "Shared trip completion acknowledged" =>
        l10n.driverCompletionAcknowledged,
      "Boarding cancelled. Broadcasting ended." => l10n.driverBoardingCancelled,
      "Trip completion saved. Broadcasting ended." => l10n.driverTripCompleted,
      "GPS stopped locally; shared completion failed. Retry Stop." =>
        l10n.driverStopPending,
      "Shared trip completion was not confirmed. Retry Stop." =>
        l10n.driverStopFailed,
      "Dated departure" => l10n.driverDatedDeparture,
      "No dated departures published. Ask the administrator to schedule this bus." =>
        l10n.driverNoRuns,
      "Colombo service departure" => l10n.driverColomboDeparture,
      "Starting opens boarding. Record actual departure separately; late starts require a reason." =>
        l10n.driverBoardingHelp,
      "Actual departure confirmed by the server." => l10n.driverDepartureSaved,
      "Departure was not confirmed. Refresh and retry." =>
        l10n.driverDepartureFailed,
      "Record actual departure" => l10n.driverRecordDeparture,
      "TRIP IN PROGRESS" => l10n.driverActive,
      "TRIP INACTIVE" => l10n.driverInactive,
      "Start Trip" => l10n.driverStart,
      "Stop Trip" => l10n.driverStop,
      "Live Telemetry Data" => l10n.driverTelemetry,
      "GPS inactive. Press Start Trip to acquire live GPS location." =>
        l10n.driverGpsInactive,
      "Latitude:" => l10n.driverLatitude,
      "Longitude:" => l10n.driverLongitude,
      "Speed:" => l10n.driverSpeed,
      "Heading:" => l10n.driverHeading,
      "Local GPS fix:" => l10n.driverLocalFix,
      "Vehicle Accessibility Status" => l10n.driverAccessibility,
      "Read-only (Not assigned)" => l10n.driverReadOnly,
      "Wheelchair ramp observation" => l10n.driverRampObservation,
      "Unknown - check before selecting" => l10n.driverUnknownRamp,
      "Working observed" => l10n.driverWorkingObserved,
      "Broken observed" => l10n.driverBrokenObserved,
      "Low-Floor Elevator / Lift Working" => l10n.driverLift,
      "Stop lift observations are reported separately" =>
        l10n.driverStopLiftHelp,
      "Occupancy Level:" => l10n.driverOccupancy,
      "Low" => l10n.driverLow,
      "Medium" => l10n.driverMedium,
      "High" => l10n.driverHigh,
      "Operator access" => l10n.driverAccess,
      "Checking operator approval..." => l10n.driverChecking,
      "Sign in to check operator approval." => l10n.driverSignInApproval,
      "Operator approval required. Ask the project administrator to review your account. Selecting Operator at registration does not grant approval. A live connection is required to verify access." =>
        l10n.driverApprovalRequired,
      "Check again" => l10n.driverCheckAgain,
      "Return to sign in" => l10n.driverReturnSignIn,
      "Could not sign out. Please retry." => l10n.driverSignOutFailed,
      "Driver route assignment" => l10n.driverRouteAssignment,
      "An administrator must assign an available route before you can operate a bus. A live connection is required to verify the assignment." =>
        l10n.driverRouteRequired,
      "Check assignment" => l10n.driverCheckAssignment,
      "Scheduled" => l10n.driverScheduled,
      "Boarding" => l10n.driverBoarding,
      "In Progress" => l10n.driverInProgress,
      "Completed" => l10n.driverCompleted,
      "Cancelled" => l10n.driverCancelled,
      "State unavailable" => l10n.driverUnknownState,
      "Sign out" => l10n.profileSignOut,
      "Cancel" => l10n.profileCancel,
      "Trip Route Progress" => l10n.driverProgress,
      "No Active Trip" => l10n.driverNoActive,
      "No active run. Select a dated departure and start boarding above; record actual departure separately when leaving." =>
        l10n.driverNoActiveHelp,
      "Final Destination Reached" => l10n.driverFinalDestination,
      "Final arrival and trip completion acknowledged" =>
        l10n.driverFinalAcknowledged,
      "Arrival was not confirmed. Refresh and retry." =>
        l10n.driverArrivalFailed,
      "Next Stop Reached" => l10n.driverNextReached,
      "Final Stop Reached" => l10n.driverFinalReached,
      "End Trip" => l10n.driverEnd,
      "Unknown" => l10n.driverUnknown,
      "Not recorded" => l10n.driverNotRecorded,
      "ETAs follow actual departure and recorded arrivals. Missing timetable intervals use a 6-minute estimate; confirm timing with the operator." =>
        l10n.driverEtaHelp,
      "SCHEDULED ARRIVAL" => l10n.driverScheduledArrival,
      "Timetable Target" => l10n.driverTimetableTarget,
      "CURRENT ETA" => l10n.driverCurrentEta,
      "Delay notice removal saved." => l10n.driverDelayCleared,
      "Delay removal was not confirmed. Retry." => l10n.driverDelayClearFailed,
      "Clear" => l10n.driverClear,
      "Update Delay / Traffic Reason" => l10n.driverUpdateDelay,
      "Report Traffic / Delay (+5m, +10m)" => l10n.driverReportDelay,
      "Traffic Congestion" => l10n.driverTraffic,
      "Heavy Rain / Flooding" => l10n.driverRain,
      "Accident Ahead" => l10n.driverAccident,
      "Road Construction" => l10n.driverRoadworks,
      "Mechanical Breakdown" => l10n.driverBreakdown,
      "Report Delay / Incident" => l10n.driverDelayTitle,
      "Alerts all passenger screens and updates live ETAs." =>
        l10n.driverDelayHelp,
      "Estimated Delay Time" => l10n.driverDelayTime,
      "Delay Reason" => l10n.driverDelayReason,
      "Delay upload was not confirmed. Retry." => l10n.driverDelayFailed,
      "On Time (Departs Now)" => l10n.driverDepartsNow,
      "Origin" => l10n.driverOrigin,
      "Pre-Trip Schedule Check" => l10n.driverPreTrip,
      "On Time (±1 min)" => l10n.driverOnTimeMinute,
      "Running Early" => l10n.driverEarly,
      "On Time Target" => l10n.driverOnTimeTarget,
      "Delayed" => l10n.driverDelayed,
      "-5m" => l10n.driverMinusFive,
      "0 (On Schedule)" => l10n.driverZeroSchedule,
      "+15m" => l10n.driverPlusFifteen,
      "0 min" => l10n.driverZeroMinutes,
      "Select Bus Run" => l10n.driverSelectBus,
      "Assigned to You" => l10n.driverAssigned,
      "Assign to Me" => l10n.driverAssignMe,
      "Assigned to another operator" => l10n.driverAssignedOther,
      "Upcoming" => l10n.driverUpcoming,
      "Departed" => l10n.driverDeparted,
      "Shared request updates are unavailable. Displayed requests may be out of date." =>
        l10n.driverAssistanceUnavailable,
      "Boarding Assistance Requests" => l10n.driverAssistanceTitle,
      "No active assistance requests for this bus." =>
        l10n.driverAssistanceEmpty,
      "Getting off" => l10n.driverAlightingAt,
      _ => label,
    };
  }

  String driverRunStatus(String value) => switch (value) {
    'scheduled' => l10n.driverScheduled,
    'boarding' => l10n.driverBoarding,
    'in_progress' => l10n.driverInProgress,
    'completed' => l10n.driverCompleted,
    'cancelled' => l10n.driverCancelled,
    _ => l10n.driverUnknownState,
  };
  String driverArrivalTime(DateTime value, {DateTime? clock}) {
    final now = clock ?? DateTime.now();
    final time = MaterialLocalizations.of(this).formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(this),
    );
    if (value.year == now.year &&
        value.month == now.month &&
        value.day == now.day) {
      return time;
    }
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} $time';
  }

  /// Retains the existing calculator's unavailable/scheduled/live distinctions.
  /// Localizes its presentation without changing any arrival or delay estimate.
  String driverCountdown(BusArrivalEtaResult result) {
    final raw = result.countdownText;
    if (raw == 'ETA unavailable') return l10n.driverEtaUnavailable;
    if (raw == 'Scheduled time passed') return l10n.driverSchedulePassed;
    if (raw.startsWith('Scheduled for ')) {
      return l10n.driverScheduledFor(
        driverArrivalTime(result.scheduledArrival),
      );
    }
    final minutes = result.countdownMinutes;
    if (raw.startsWith('Tomorrow')) {
      final time = MaterialLocalizations.of(this).formatTimeOfDay(
        TimeOfDay.fromDateTime(result.estimatedArrival),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(this),
      );
      return minutes ~/ 60 >= 24
          ? l10n.driverTomorrowAt(time)
          : l10n.driverTomorrowIn(time, minutes ~/ 60, minutes % 60);
    }
    if (raw != 'Departed' &&
        !raw.startsWith('Departed ') &&
        raw != 'Arriving now' &&
        !raw.startsWith('Arriving in ')) {
      return l10n.driverEtaUnavailable;
    }
    if (minutes < -15) return l10n.driverDeparted;
    if (minutes < 0) return l10n.driverDepartedAgo(minutes.abs());
    if (minutes <= 1) return l10n.driverArrivingNow;
    if (minutes < 60) return l10n.driverArrivingMinutes(minutes);
    return l10n.driverArrivingHours(minutes ~/ 60, minutes % 60);
  }
}
