// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get busDetails => 'Bus Details';

  @override
  String get communityReports => 'Community reports';

  @override
  String get saveTrip => 'Save Trip';

  @override
  String get removeSavedTrip => 'Remove saved trip';

  @override
  String get savedTrip => 'Saved trip';

  @override
  String get noRecentReports => 'No recent reports';

  @override
  String get loadingReports => 'Loading reports…';

  @override
  String get requestBoardingAssistance => 'Request boarding assistance';

  @override
  String get reportCondition => 'Report a condition';

  @override
  String get language => 'Language';

  @override
  String get languageSaveFailed =>
      'Could not save the language. Please try again.';

  @override
  String get searchWindowInvalid =>
      'Choose a boarding time within the next 24 hours.';

  @override
  String get searchSelectionExpired =>
      'This selection has expired. Review the current results.';

  @override
  String get searchAccountChanged =>
      'Account changed. Return to Search to start a new search.';

  @override
  String get searchWindowNotice =>
      'Boarding within the next 24 hours. Timetable times do not confirm a running bus.';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signIn => 'Sign In';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'Enter your email address';

  @override
  String get passenger => 'Passenger';

  @override
  String get passengerDescription => 'Plan accessible journeys';

  @override
  String get reporter => 'Reporter';

  @override
  String get reporterDescription => 'Report bus and stop conditions';

  @override
  String get driver => 'Bus Driver';

  @override
  String get driverDescription => 'Administrator approval required';

  @override
  String get operatorApprovalRequired =>
      'Account created. Administrator approval is required for driver access.';

  @override
  String accountReady(String name) {
    return 'Welcome, $name! Your account is ready.';
  }

  @override
  String get verifyingSearchTime => 'Verifying search time...';

  @override
  String get searchTimeUnavailable =>
      'Search time unavailable. Connect and retry.';

  @override
  String get retrySearchTime => 'Retry search time';

  @override
  String get retrySearch => 'Retry search';

  @override
  String get verifyingDatedSearch =>
      'Verifying search time and dated departures...';

  @override
  String get datedSearchUnavailable =>
      'Dated departures unavailable. Connect and retry.';

  @override
  String get nearbyStopsTitle => 'Nearby boarding stops';

  @override
  String get nearbyStopsExplanation =>
      'Choose your boarding stop. Distances are approximate straight-line distances, not walking routes or travel times. Check the stop\'s direction and side of the road.';

  @override
  String get nearbyLocating => 'Finding your location...';

  @override
  String get nearbyLocationDisabled => 'Turn on device location, then retry.';

  @override
  String get nearbyLocationDenied =>
      'Location permission was denied. You can choose a stop manually.';

  @override
  String get nearbyLocationBlocked =>
      'Allow location access in app settings, then retry.';

  @override
  String get nearbyLocationUnavailable =>
      'Could not get a usable location. Retry or choose a stop manually.';

  @override
  String get nearbyOpenSettings => 'Open settings';

  @override
  String get nearbyRetry => 'Retry location';

  @override
  String get nearbyChooseManually => 'Choose a stop manually';

  @override
  String get nearbyStopsEmpty =>
      'No stops with valid coordinates are available.';

  @override
  String nearbyDistance(String km) {
    return 'About $km km away';
  }

  @override
  String get reportCooldownNotice =>
      'You can report different issues without a daily limit. Wait 5 minutes before reporting the same issue category on the same bus or stop again.';

  @override
  String get falseVoteReason => 'Why is this report inaccurate?';

  @override
  String get falseVoteReasonMinimum => 'Enter at least 5 characters.';

  @override
  String get voteCancel => 'Cancel';

  @override
  String get voteSubmit => 'Submit vote';

  @override
  String get voteAcknowledged => 'Vote acknowledged.';

  @override
  String get voteUnavailable =>
      'Vote was not confirmed. Check your connection and retry.';

  @override
  String get voteSignIn => 'Sign in to vote.';

  @override
  String get authorVoteDisabled => 'You cannot vote on your own report.';

  @override
  String get voteRetry => 'Retry vote status';

  @override
  String get votingClosed => 'Voting is closed.';

  @override
  String get voteNoPoints =>
      'Votes earn no points. Five False votes hide the report.';

  @override
  String get voteTrue => 'True';

  @override
  String get voteFalse => 'False';

  @override
  String get accountStatusChecking => 'Checking account access...';

  @override
  String get accountStatusUnavailable =>
      'Account access could not be verified. Connect and retry.';

  @override
  String get accountSuspended =>
      'Account suspended. Administrator review is required.';

  @override
  String accountTemporaryUntil(String until) {
    return 'Account temporarily suspended until $until (UTC).';
  }

  @override
  String get accountStatusRetry => 'Retry account status';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get v2PointsNotice =>
      'Published report: 10 points; votes earn no points. Five False votes deduct twice the award. Points have no cash value.';

  @override
  String get refreshV2Points => 'Refresh v2 points';

  @override
  String get reviewsTitle => 'My report reviews';

  @override
  String get reviewsAdminTitle => 'Report moderation';

  @override
  String get reviewsError =>
      'Unable to verify reviews. Check your connection and retry.';

  @override
  String get reviewsReasonRequired =>
      'Enter a reason between 5 and 2,000 characters.';

  @override
  String get reviewsPending => 'Appeal pending';

  @override
  String get reviewsUpheld => 'Decision upheld';

  @override
  String get reviewsOverturned => 'Decision overturned; penalty restored';

  @override
  String get reviewsUnreviewed => 'Awaiting review';

  @override
  String get reviewsEmpty => 'No community-disputed reports.';

  @override
  String get reviewsMore => 'Load more';

  @override
  String reviewsPenalty(int points, int strikes) {
    return 'Penalty: $points points. Counted strikes: $strikes.';
  }

  @override
  String reviewsHiddenReason(int count) {
    return '$count other users marked this report False. It was hidden automatically.';
  }

  @override
  String get reviewsAppealLabel => 'Your appeal';

  @override
  String get reviewsDecisionReason => 'Admin decision reason';

  @override
  String get reviewsVotes => 'Community vote evidence';

  @override
  String get reviewsReason => 'Reason';

  @override
  String get reviewsDecisionExplanation =>
      'Overturn restores the deducted points and removes this strike once. Other account restrictions remain.';

  @override
  String get reviewsUphold => 'Uphold decision';

  @override
  String get reviewsOverturn => 'Overturn decision';

  @override
  String get reviewsSubmit => 'Submit appeal';

  @override
  String get reviewsAcknowledged => 'Change confirmed by the server.';

  @override
  String get reviewsPhoto => 'Report photo';

  @override
  String get reviewsPhotoUnavailable => 'Report photo unavailable.';

  @override
  String get bansTitle => 'Permanent-ban reviews';

  @override
  String get bansApproved => 'Permanent ban approved';

  @override
  String get bansRejected => 'Permanent ban rejected';

  @override
  String get bansWithdrawn => 'Review withdrawn';

  @override
  String get bansPending => 'Admin review pending';

  @override
  String get bansEmpty => 'No permanent-ban review cases.';

  @override
  String bansStrikes(int count) {
    return 'Current strikes: $count';
  }

  @override
  String get bansAppealsPending =>
      'Resolve pending report appeals before approving a permanent ban.';

  @override
  String get bansStale =>
      'Evidence changed. Refresh this case before deciding.';

  @override
  String get bansAdminProtected =>
      'Administrator accounts are protected from this workflow.';

  @override
  String get bansEvidence => 'Contributing reports and appeals';

  @override
  String get bansCounted => 'Strike counted';

  @override
  String get bansRemoved => 'Strike removed';

  @override
  String get bansExplanation =>
      'Ten strikes request a review. Only an explicit approval imposes a permanent restriction. Rejection does not extend a temporary ban.';

  @override
  String get bansReject => 'Reject permanent ban';

  @override
  String get bansApprove => 'Approve permanent ban';

  @override
  String get assistanceInbox => 'Run assistance requests';

  @override
  String get assistanceChooseRun =>
      'Choose a dated trip with an assigned driver from Bus Details.';

  @override
  String get assistanceUnavailable =>
      'Assistance is unavailable. Check the trip, assignment and connection, then retry.';

  @override
  String get assistanceEmpty => 'No assistance requests for this run.';

  @override
  String get assistanceRetargeted =>
      'Driver changed. Awaiting the current driver acknowledgement.';

  @override
  String get assistancePending => 'Awaiting driver acknowledgement';

  @override
  String get assistanceAccepted => 'Driver acknowledged';

  @override
  String get assistanceDeclined => 'Driver declined';

  @override
  String get assistanceCompleted => 'Driver marked completed';

  @override
  String get assistanceCancelled => 'Cancelled';

  @override
  String get assistanceExpired => 'Request expired';

  @override
  String get assistanceAcknowledge => 'Acknowledge';

  @override
  String get assistanceDecline => 'Decline';

  @override
  String get assistanceComplete => 'Complete';

  @override
  String get assistanceInAppOnly =>
      'Available in the assigned driver\'s in-app inbox. Background push notifications are not enabled in local testing.';

  @override
  String assistanceExpiry(String time) {
    return 'Request expiry (UTC): $time';
  }

  @override
  String get assistanceRunEnded => 'This trip has ended or was cancelled.';

  @override
  String get assistanceStopPassed =>
      'The bus has already passed the requested boarding opportunity.';

  @override
  String get assistanceDriverUnavailable =>
      'The assigned driver is no longer available.';

  @override
  String get assistanceRamp => 'Deploy ramp';

  @override
  String get assistanceExtraTime => 'Extra time';

  @override
  String get assistanceBoardingHelp => 'Boarding help';

  @override
  String get assistanceAlightingHelp => 'Alighting help';

  @override
  String get operationsTitle => 'Active trips';

  @override
  String get operationsRefresh => 'Refresh from server';

  @override
  String get operationsEmpty => 'No active dated trips.';

  @override
  String get operationsMore => 'Load more';

  @override
  String get operationsExplanation =>
      'Transfer this trip to an approved driver assigned to the same route. Progress and recorded times stay unchanged. GPS pauses until the new driver resumes with a fresh location. Assistance requests require the new driver’s acceptance.';

  @override
  String get operationsDone =>
      'Transfer acknowledged. GPS is paused until the new driver resumes. Assistance reassignment continues in the background; previous acceptance does not carry over.';

  @override
  String get operationsNoDrivers =>
      'No eligible driver on this page. Approve and assign an available driver to this route first.';

  @override
  String get operationsReason => 'Transfer reason (5–2000 characters)';

  @override
  String get operationsTransfer => 'Transfer trip';

  @override
  String get operationsSaving => 'Transferring…';

  @override
  String get operationsError =>
      'Unable to confirm this operation. Retry the same request or refresh to inspect its current state.';

  @override
  String get operationsStale =>
      'The trip or driver eligibility changed. Refresh before transferring.';

  @override
  String get operationsResume => 'Accept and resume GPS';

  @override
  String get operationsGpsError =>
      'Wait for a fresh GPS fix with accuracy within 100 metres, then accept and resume again.';

  @override
  String get pushTitle => 'Assistance notifications';

  @override
  String get pushChannelDescription =>
      'Notifications about passenger assistance requests';

  @override
  String get pushOff =>
      'Notifications are off. The driver inbox remains available.';

  @override
  String get pushConnecting => 'Connecting notifications…';

  @override
  String get pushDenied =>
      'Notification permission is denied. You can allow it in Android app settings.';

  @override
  String get pushReady =>
      'This device is registered. A notification does not confirm that assistance was accepted.';

  @override
  String get pushUnavailable =>
      'Notification setup was not confirmed. Retry or use the driver inbox.';

  @override
  String get pushEnable => 'Enable notifications';

  @override
  String get pushDisable => 'Turn off';

  @override
  String get pushOpenUnavailable =>
      'This request is unavailable or no longer assigned to your account.';

  @override
  String get pushForeground => 'A passenger has requested assistance.';

  @override
  String get pushReview => 'Review request';

  @override
  String get fareUnavailable => 'Fare unavailable';

  @override
  String get fareUnavailableDisclosure =>
      'A reviewed tariff and fare-stage mapping are not available for this selection. Confirm the fare with the operator.';

  @override
  String get fareSampleDisclosure =>
      'Sample/Test estimate only. This duration/stop model is not an official fare. Confirm the actual fare with the operator.';

  @override
  String fareSampleAmount(int amount) {
    return 'Sample est. LKR $amount';
  }

  @override
  String fareReviewedSource(String source, String tariff, String mapping) {
    return 'Reviewed source: $source. Tariff $tariff; mapping $mapping.';
  }

  @override
  String fareReviewedAmount(String amount) {
    return 'LKR $amount';
  }

  @override
  String fareSampleReviewed(String amount) {
    return 'Sample tariff LKR $amount';
  }

  @override
  String get fareChanged =>
      'The fare version changed or is unavailable. The saved selection is preserved; review the current fare before travelling.';

  @override
  String get fareAdminTitle => 'Fare publications';

  @override
  String get fareImportHelp =>
      'Import a reviewed fare table, ordered stop-stage mapping and explicit bus IDs. Amounts use minor units (LKR 1 = 100). Preview every cell, source, class and effective date before publishing. Published versions are immutable; archive and create a new ID to replace one.';

  @override
  String get farePublicationId => 'New publication ID';

  @override
  String get fareImportJson => 'Reviewed import JSON';

  @override
  String get farePreview => 'Validate and preview';

  @override
  String get fareReviewCheck =>
      'I reviewed the source, vehicle class, direction, stop-stage mapping and dates.';

  @override
  String get fareReviewReason => 'Review/archive reason (10–2000 characters)';

  @override
  String get farePublish => 'Publish reviewed version';

  @override
  String get fareArchive => 'Archive version';

  @override
  String get fareCancel => 'Cancel';

  @override
  String get fareInvalidImport =>
      'Invalid import. Check the documented schema, IDs, integer amounts, source and date/mapping applicability.';

  @override
  String get fareAdminError =>
      'Operation unconfirmed. Check connection, admin access, review reason and current bus/route data. Reload before retrying a changed publication.';

  @override
  String get fareNoPublications =>
      'No fare publications. Missing fares remain unavailable.';

  @override
  String get geometryTitle => 'Route geometry';

  @override
  String get geometryHelp =>
      'Import a reviewed directed road path and ordered stop vertices. Match the current route and stop coordinates; use a new version for corrections. This does not supply real-time traffic.';

  @override
  String get geometryReview =>
      'I reviewed the road path, direction, stop vertices and source.';

  @override
  String get geometryInvalid =>
      'Invalid geometry. Check the JSON, route ID, coordinates, source and ordered stop vertices.';

  @override
  String get geometrySaved => 'Reviewed route geometry published.';

  @override
  String get geometryWithdraw => 'Withdraw current geometry';

  @override
  String get geometryMap => 'Reviewed road path · selected segment';

  @override
  String geometryEta(String target, String start, String end) {
    return '$target: estimated $start–$end · road progress + timetable, low confidence.';
  }

  @override
  String get geometryWithdrawn => 'Route geometry withdrawn.';

  @override
  String get etaDiagnostics => 'Local ETA diagnostics';

  @override
  String get etaDiagnosticsUnavailable =>
      'Local Test diagnostics requires a loaded signed-in account.';

  @override
  String get etaDiagnosticsHelp =>
      'LOCAL TEST ONLY. Opt in to capture forecasts while Bus Details is open. Arrivals are acknowledged driver-reported timestamps, not independent GPS ground truth. No production accuracy claim. Records stay on this device/account (500 maximum, seven-day retention applied during capture). No coordinates, emails or driver IDs are stored.';

  @override
  String get etaCapture => 'Capture local forecasts';

  @override
  String etaCounts(int captured, int pending, int excluded) {
    return 'Captured: $captured · pending: $pending · excluded: $excluded';
  }

  @override
  String etaMetrics(int count, String median, String p90) {
    return 'Matched samples: $count · median error: ${median}s · P90 error: ${p90}s';
  }

  @override
  String get etaStorageError =>
      'Local save/read unconfirmed. Export may contain unsaved diagnostic records; retry your action.';

  @override
  String get etaNoMatchedSamples =>
      'No matched arrivals yet. Pending/excluded forecasts are not counted as zero error.';

  @override
  String get etaSmallSample =>
      'Small synthetic sample; this does not establish real-world accuracy.';

  @override
  String get etaCopied => 'Local diagnostic JSON copied.';

  @override
  String get etaExport => 'Copy diagnostic JSON';

  @override
  String get etaClear => 'Clear this account’s local measurements';

  @override
  String get savedTripsTitle => 'Saved trips';

  @override
  String get savedTripsViewAll => 'View all saved trips';

  @override
  String get savedTripsHelp =>
      'Your saved selections, including past records. Saving does not book a seat or start tracking. Open details to refresh the selected run’s current status.';

  @override
  String get savedTripsRefresh => 'Refresh saved trips';

  @override
  String get savedTripsAccountChanged =>
      'Account changed. Return Home and open your saved trips again.';

  @override
  String get savedTripsRemoveError =>
      'Removal is not confirmed. The saved record is retained; reconnect and retry.';

  @override
  String get savedTripsOpenError =>
      'Saved details could not be verified. Reconnect and retry.';

  @override
  String get savedTripsLoadError =>
      'Saved trips unavailable. Check your connection and account access, then retry.';

  @override
  String get savedTripsRetry => 'Retry';

  @override
  String get savedTripsEmpty =>
      'No saved trips yet. Save a trip from Bus Details.';

  @override
  String get savedTripsEmptyPage =>
      'No saved records on this page. Refresh or return to the previous page.';

  @override
  String get savedTripsCompletedRecord => 'Completed saved record';

  @override
  String get savedTripsCancelledRecord => 'Cancelled saved record';

  @override
  String get savedTripsOpen => 'Open bus details';

  @override
  String get savedTripsPrevious => 'Previous page';

  @override
  String get savedTripsNext => 'Next page';

  @override
  String get savedTripsVehicleUnavailable =>
      'Saved vehicle unavailable. Review the saved record or search again.';

  @override
  String get segmentReportsPreview =>
      'Limited report preview; open scoped pages for more evidence. Missing reports do not establish accessibility.';

  @override
  String get segmentReportsHelp =>
      'Choose this bus or a stop in your selected segment. Pages use stable record order, not observation time. Expired/hidden reports are excluded; an empty page does not mean there are no older relevant reports.';

  @override
  String get segmentReportsUnavailable =>
      'Reports unavailable. Reconnect and refresh.';

  @override
  String get segmentReportsEmptyPage =>
      'No current visible reports on this page. Check the next page when available.';

  @override
  String get segmentReportsEmptyPreview =>
      'No current reports in this preview.';

  @override
  String get segmentReportsViewAll => 'View all relevant reports';

  @override
  String get calendarTitle => 'Service calendar';

  @override
  String get calendarHelp =>
      'Publish reviewed weekdays, Colombo departure time and up to 31 service dates. Then generate departures explicitly. Existing runs are preserved. Retiring a calendar stops generation; cancel future runs separately.';

  @override
  String get calendarDates => 'Choose service dates';

  @override
  String get calendarTime => 'Choose Colombo departure time';

  @override
  String get calendarPublish => 'Publish calendar';

  @override
  String get calendarGenerate => 'Generate dated departures';

  @override
  String get calendarRetire => 'Retire calendar';

  @override
  String get calendarFailed =>
      'Change or load not confirmed. Reconnect and reload. Use selected weekdays and at most 31 days; changed timetables need a replacement calendar.';

  @override
  String get calendarConfirmed => 'Calendar change confirmed.';

  @override
  String calendarGenerated(int created, int preserved) {
    return 'Created $created; preserved $preserved existing departures.';
  }

  @override
  String get calendarPublished => 'Published calendar';

  @override
  String get calendarRetired => 'Retired calendar';

  @override
  String get calendarEmpty => 'No calendars for this bus.';
}
