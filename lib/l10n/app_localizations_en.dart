// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get authControlsTitle => 'Firebase account controls';

  @override
  String get authControlsExplanation =>
      'Manage sign-in and sessions. Enabling sign-in preserves separate manual and community restrictions. Auth changes require a server receipt.';

  @override
  String get authDeleteExplanation =>
      'Delete the Firebase sign-in account and anonymize its private profile. Shared reports, trips and audit references are retained. Disable sign-in and finish active-trip reconciliation first. This cannot be undone.';

  @override
  String get authCancel => 'Cancel';

  @override
  String get authConfirmRequired =>
      'Type the exact account UID to confirm deletion.';

  @override
  String get authDisableFirst => 'Disable sign-in before approving deletion.';

  @override
  String get authActiveTrip =>
      'An active operation must be reconciled before deletion.';

  @override
  String get authPending =>
      'Operation pending or requires review. Reload its receipt before another decision.';

  @override
  String get authNormalScope =>
      'Firebase Auth controls are available only in the normal account scope.';

  @override
  String get authReload => 'Reload account status';

  @override
  String get authDeleted =>
      'Account deleted; retained history remains available to authorized reviewers.';

  @override
  String get authDisabled => 'Firebase sign-in is disabled';

  @override
  String get authEnabled => 'Firebase sign-in is enabled';

  @override
  String get authCompleted => 'Last operation completed';

  @override
  String get authReconcile => 'Review and retry the same operation';

  @override
  String get authConfirmLabel => 'Account UID for deletion confirmation';

  @override
  String get authEnable => 'Enable sign-in';

  @override
  String get authDisable => 'Disable sign-in';

  @override
  String get authRevoke => 'Revoke existing sessions';

  @override
  String get authDeleteRequest => 'Request deletion review';

  @override
  String get authDeleteReject => 'Reject deletion';

  @override
  String get authDeleteApprove => 'Approve account deletion';

  @override
  String accountControlsUntil(String when) {
    return 'Until $when (Asia/Colombo)';
  }

  @override
  String get accountControlsTitle => 'Account access';

  @override
  String get accountControlsExplanation =>
      'Manage application access in this scope. Restoring manual access preserves community restrictions. Active driver operations are reconciled by the server.';

  @override
  String get accountControlsReasonRequired =>
      'Enter a reason between 5 and 2,000 characters.';

  @override
  String get accountControlsStale =>
      'Account access changed. Reload before deciding.';

  @override
  String get accountControlsProtected =>
      'Your account and administrator accounts are protected.';

  @override
  String get accountControlsUnavailable =>
      'Access could not be confirmed. Retry or reload.';

  @override
  String get accountControlsRestricted => 'Manual restriction is active';

  @override
  String get accountControlsClear => 'No active manual restriction';

  @override
  String get accountControlsCommunity =>
      'A separate community restriction remains in effect.';

  @override
  String get accountControlsIndefinite =>
      'Until an administrator restores access';

  @override
  String get accountControlsDuration =>
      'Otherwise suspend for 72 hours from server time.';

  @override
  String get accountControlsSuspend => 'Suspend access';

  @override
  String get accountControlsRestore => 'Restore manual access';

  @override
  String get accountControlsRetry => 'Retry';

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

  @override
  String get loopStopHelp =>
      'Add stops in order. The same physical stop may appear again; each visit keeps its own timetable and identity. Reordering moves that visit’s scheduled time with it.';

  @override
  String journeyVisitPositions(int boarding, int alighting) {
    return 'Board at route stop $boarding; alight at route stop $alighting.';
  }

  @override
  String get scheduleReschedule => 'Publish replacement';

  @override
  String get scheduleRescheduleHelp =>
      'Cancel the old departure and publish a linked replacement at the selected Colombo date/time. Existing saved trips keep their original selection. The reason below is public.';

  @override
  String get schedulePublicReason => 'Public change reason';

  @override
  String get scheduleReasonRequired => 'Enter at least five characters.';

  @override
  String get scheduleStatusUnavailable =>
      'Current run status unavailable. Saved times do not confirm that the bus will operate.';

  @override
  String get scheduleCancelled =>
      'This departure was cancelled. Your saved selection has not been moved to another trip.';

  @override
  String get scheduleChanged =>
      'The current timetable differs from the saved selection. Original saved times are shown; search again to review current options.';

  @override
  String get scheduleReplacement =>
      'A linked replacement was published. Search again to review its current availability.';

  @override
  String scheduleReplacementAt(String time) {
    return 'A replacement was published for $time. Search again to review its current availability.';
  }

  @override
  String get scheduleSavedRecord =>
      'Original saved timetable. The current vehicle or route is unavailable or changed. This record does not establish live location or current accessibility.';

  @override
  String get scheduleTimeUnknown => 'Saved intermediate time unavailable';

  @override
  String scheduleSavedFare(String fare) {
    return 'Saved fare: $fare';
  }

  @override
  String get manualAppealsTitle => 'Restriction appeals';

  @override
  String get manualAppealsExplanation =>
      'Appeal a manual account restriction. Submitting an appeal does not restore access. An accepted appeal changes only that manual restriction.';

  @override
  String get manualAppealReason => 'Explain your appeal';

  @override
  String get manualAppealSubmit => 'Submit appeal';

  @override
  String get manualAppealNoNew =>
      'No new appeal is available for the current restriction.';

  @override
  String get manualAppealRestore => 'Restore manual access';

  @override
  String get manualAppealUphold => 'Uphold restriction';

  @override
  String get manualAppealClose => 'Close review';

  @override
  String get manualAppealPending => 'Pending review';

  @override
  String get manualAppealAccepted => 'Appeal accepted';

  @override
  String get manualAppealRejected => 'Appeal rejected';

  @override
  String get manualAppealReview => 'Review appeal';

  @override
  String get manualAppealEmpty => 'No restriction appeals.';

  @override
  String get manualAppealFailed =>
      'Could not confirm this request. Reload the current restriction before a new decision. Retry an unconfirmed request with the same details.';

  @override
  String get adminLoadMore => 'Load more';

  @override
  String get adminSearchLoaded => 'Search loaded records';

  @override
  String get adminLoadedPages =>
      'Counts and search cover loaded pages. Load more to check additional records.';

  @override
  String manualAppealRevision(int revision) {
    return 'Restriction revision $revision';
  }

  @override
  String get adminConsole => 'Admin console';

  @override
  String get adminOverview => 'Overview';

  @override
  String get adminBuses => 'Buses';

  @override
  String get adminRoutes => 'Routes';

  @override
  String get adminStops => 'Bus stops';

  @override
  String get adminUsers => 'Users';

  @override
  String get adminDrivers => 'Drivers';

  @override
  String get adminActivity => 'Activity';

  @override
  String get adminRefresh => 'Refresh server data';

  @override
  String get adminSignOut => 'Sign out';

  @override
  String get adminSampleCatalogue => 'Sample/Test catalogue administration';

  @override
  String get adminUnavailable => 'Server data unavailable.';

  @override
  String get adminLoading => 'Loading verified server records...';

  @override
  String get adminNoMatches => 'No matching records.';

  @override
  String get adminReviewAccess => 'Review access';

  @override
  String get adminAssignRoute => 'Assign route';

  @override
  String get adminEditProfile => 'Edit profile';

  @override
  String get adminReviewDriver => 'Review driver';

  @override
  String get adminDatedDepartures => 'Dated departures';

  @override
  String get adminRestore => 'Restore';

  @override
  String get adminEdit => 'Edit';

  @override
  String get adminDelete => 'Delete';

  @override
  String get adminFinishDeletion => 'Finish deletion';

  @override
  String get adminCancel => 'Cancel';

  @override
  String get adminDeleteRecord => 'Delete record';

  @override
  String get adminEditUser => 'Edit user profile';

  @override
  String get adminName => 'Name';

  @override
  String get adminPhone => 'Phone';

  @override
  String get adminSaveProfile => 'Save profile';

  @override
  String get adminAssignedRoute => 'Assigned route';

  @override
  String get adminNoRoute => 'No route / remove assignment';

  @override
  String get adminAssignmentReason =>
      'Assignment reason (at least 10 characters)';

  @override
  String get adminSaveAssignment => 'Save assignment';

  @override
  String get adminDecision => 'Decision';

  @override
  String get adminApprove => 'Approve';

  @override
  String get adminReject => 'Reject';

  @override
  String get adminRevoke => 'Revoke access';

  @override
  String get adminReviewReason => 'Review evidence / reason';

  @override
  String get adminConfirmDecision => 'Confirm decision';

  @override
  String get adminApproved => 'Approved';

  @override
  String get adminRejected => 'Rejected';

  @override
  String get adminRevoked => 'Revoked';

  @override
  String get adminPending => 'Pending review';

  @override
  String get adminUnassigned => 'Unassigned';

  @override
  String get adminAdd => 'Add';

  @override
  String get adminBusStop => 'bus stop';

  @override
  String get adminBusTimetable => 'bus / timetable';

  @override
  String get adminRoute => 'route';

  @override
  String get adminRecordId => 'Record ID';

  @override
  String get adminStopName => 'Stop name';

  @override
  String get adminSourceUrl => 'Source URL';

  @override
  String get adminUnknown => 'Unknown / not assessed';

  @override
  String get adminEquipped => 'Equipped';

  @override
  String get adminNotEquipped => 'Not equipped';

  @override
  String get adminYesAssessed => 'Yes - assessed';

  @override
  String get adminNoAssessed => 'No - assessed';

  @override
  String get adminCatalogueType => 'Catalogue record type';

  @override
  String get adminPhysicalVehicle => 'Physical vehicle';

  @override
  String get adminPublishedTimetable => 'Published timetable';

  @override
  String get adminRouteField => 'Route';

  @override
  String get adminDriverField => 'Assigned driver';

  @override
  String get adminScheduledTime => 'Scheduled time (HH:mm)';

  @override
  String get adminAddStop => 'Add a stop';

  @override
  String get adminSaving => 'Saving...';

  @override
  String get adminSaveCatalogue => 'Save catalogue record';

  @override
  String get adminReloadReferences => 'Reload reference data';

  @override
  String get adminOpenPassenger => 'Open passenger app';

  @override
  String get adminTransit => 'Transit administration';

  @override
  String get adminChangeConfirmed => 'Change confirmed by the server.';

  @override
  String get adminSourceChecked =>
      'I reviewed the source and the entered catalogue details.';

  @override
  String get adminDeleteHelp =>
      'This removes the catalogue record. Referenced records and active buses cannot be deleted. This action cannot be undone.';

  @override
  String get adminDriverChecked =>
      'I checked this driver\'s identity and operating authority.';

  @override
  String get adminSourceLoadError =>
      'Could not load server records. Check your connection/access and retry.';

  @override
  String get adminLatitude => 'Latitude';

  @override
  String get adminLongitude => 'Longitude';

  @override
  String get adminRamp => 'Ramp capability';

  @override
  String get adminElevator => 'Elevator capability';

  @override
  String get adminStepFree => 'Assessed step-free path';

  @override
  String get adminRouteNumber => 'Route number';

  @override
  String get adminRouteName => 'Route name';

  @override
  String get adminDescription => 'Description';

  @override
  String get adminVehicleRegistration => 'Vehicle registration number';

  @override
  String get adminLowFloor => 'Low-floor capability';

  @override
  String get adminStableId =>
      'Stable identifier. Cannot be changed after creation.';

  @override
  String get adminSourceHelp =>
      'Authoritative timetable, stop or operator source. This is not a live-service verification.';

  @override
  String get adminOverviewHelp =>
      'Maintain sourced catalogue records and review operator access. All changes require server acknowledgement.';

  @override
  String get adminRegistrationHelp =>
      'Driver registration is an application for access. Review identity and operating authority before approval. Approval does not verify equipment or guarantee a service.';

  @override
  String get adminBusCountLabel => 'Buses & timetables (loaded)';

  @override
  String get adminRouteCountLabel => 'Routes (loaded)';

  @override
  String get adminStopCountLabel => 'Bus stops (loaded)';

  @override
  String get adminUserCountLabel => 'Users (loaded)';

  @override
  String get adminDriverCountLabel => 'Drivers awaiting review (loaded)';

  @override
  String get adminReferencesError =>
      'Reference records could not be loaded completely. Reload before saving.';

  @override
  String adminRouteFor(String name) {
    return 'Route for $name';
  }

  @override
  String adminReviewFor(String name) {
    return 'Review $name';
  }

  @override
  String adminDeleteFor(String name) {
    return 'Delete $name?';
  }

  @override
  String adminAssignedRouteFor(String name) {
    return 'Assigned route: $name';
  }

  @override
  String adminCurrentAccessFor(String name) {
    return 'Current access: $name';
  }

  @override
  String adminPreviousReviewFor(String name) {
    return 'Previous review: $name';
  }

  @override
  String get adminNoActiveRoute => 'No active route assignment';

  @override
  String get adminRequired => 'Required';

  @override
  String get adminReviewSource => 'Review the source before saving.';

  @override
  String get adminRouteFirst =>
      'Assign an approved driver to this route first, or release the previous assignment.';

  @override
  String get adminAuthProfileHelp =>
      'Login email, passwords and Auth account deletion are managed in Firebase Authentication.';

  @override
  String get adminReferenceWithdrawHelp =>
      'Access will be withdrawn and bus assignments released. Active trip/telemetry records remain for reconciliation; they are not marked completed.';

  @override
  String get adminCapabilityHelp =>
      'Capability is separate from a working-equipment observation. Operational checks are recorded by the assigned driver.';

  @override
  String get adminTimetableHelp =>
      'A published timetable has no verified physical vehicle, driver or equipment status.';

  @override
  String get adminOrderedStops => 'Stops in travel order';

  @override
  String get adminMoveUp => 'Move stop up';

  @override
  String get adminMoveDown => 'Move stop down';

  @override
  String get adminRemoveStop => 'Remove stop';

  @override
  String get adminChooseRoute => 'Choose a route';

  @override
  String get adminTimeFormat => 'Use 24-hour HH:mm';

  @override
  String get adminAssignmentHelp =>
      'Approval is separate from route assignment. End any active trip before changing or removing a route.';

  @override
  String get adminReviewChecksHelp =>
      'Record the identity and operating-authority checks or decision reason.';

  @override
  String get adminChangeUnconfirmed =>
      'Change was not confirmed. Check access/connection and reload before retrying.';

  @override
  String get adminSaveUnconfirmed =>
      'Save was not confirmed. Check connection/access and reload before retrying.';

  @override
  String get adminCursorChanged => 'Page cursor changed. Reload.';

  @override
  String get adminAccountReferenceChanged =>
      'Account changed. Reload references.';

  @override
  String get adminAccessRequired => 'Administrator access is required.';

  @override
  String get adminAccountSignInChanged => 'Account changed. Sign in again.';

  @override
  String get adminConnectionRequired =>
      'A server connection is required. Retry when online.';

  @override
  String get adminRecordChanged =>
      'This record changed. Reload it before saving.';

  @override
  String get adminTwoStops =>
      'Select at least two distinct stops in travel order.';

  @override
  String get adminOccurrenceStation =>
      'Every stop occurrence requires an unambiguous physical station.';

  @override
  String get adminSourceInvalid => 'Enter the catalogue source URL.';

  @override
  String get adminVehicleTypeInvalid =>
      'Choose vehicle or published timetable.';

  @override
  String get adminNoTimetableDriver =>
      'A timetable cannot have a driver assignment.';

  @override
  String get adminTimePerStop =>
      'Enter one HH:mm (24-hour) time per stop. Overnight times may roll over.';

  @override
  String get adminRecordIdInvalid =>
      'Use letters, numbers, underscores or hyphens for the record ID.';

  @override
  String get adminRestoreFirst => 'Restore this record before editing it.';

  @override
  String get adminReferenceDeleting =>
      'A referenced record is pending deletion. Restore it or choose another record.';

  @override
  String get adminStopMissing =>
      'A selected stop no longer exists. Reload the form.';

  @override
  String get adminDependentBuses =>
      'Update dependent buses before changing the route number or removing/reordering their stops.';

  @override
  String get adminOccurrenceRebind =>
      'Existing stop occurrences cannot be rebound to another station. Use new occurrence IDs.';

  @override
  String get adminRouteMismatch =>
      'Choose an existing route with the same route number.';

  @override
  String get adminStopOrderInvalid =>
      'Vehicle stops must follow the selected route order.';

  @override
  String get adminApprovedOnly => 'Only an approved operator may be assigned.';

  @override
  String get adminGrantFirst =>
      'Assign the approved driver to this route first.';

  @override
  String get adminBusActive =>
      'This bus has an active trip or broadcast. End it before changing assignment, route or stops.';

  @override
  String get adminNotDeleting => 'This record is not pending deletion.';

  @override
  String get adminReviewInputInvalid =>
      'Select an operator and enter a review/reason of 10-2000 characters.';

  @override
  String get adminGrantInputInvalid =>
      'Select a driver and enter a reason of 10-2000 characters.';

  @override
  String get adminApproveFirst =>
      'Approve the driver before assigning a route.';

  @override
  String get adminReviewedRoute => 'Choose an available reviewed route.';

  @override
  String get adminProfileInputInvalid =>
      'Enter a name (up to 100 characters) and phone (up to 40).';

  @override
  String adminFieldRequired(String field, int maximum) {
    return '$field is required (maximum $maximum characters).';
  }

  @override
  String adminCoordinateInvalid(String field) {
    return 'Enter valid $field coordinates.';
  }

  @override
  String adminDependencyDelete(String kind) {
    return 'Cannot delete: this record is referenced by $kind. Remove the dependency or retain it for history.';
  }

  @override
  String adminLoadKindsFailed(String kinds) {
    return 'Could not verify $kinds from the server. Actions are disabled. Use Refresh to retry.';
  }

  @override
  String adminBusSummary(String route, String kind, String driver) {
    return 'Route $route | $kind\nDriver: $driver';
  }

  @override
  String adminStopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ordered stops',
      one: '1 ordered stop',
    );
    return '$_temp0';
  }

  @override
  String adminAuditBy(String actor) {
    return 'By $actor';
  }

  @override
  String adminTimetableFor(String route) {
    return 'Route $route timetable';
  }

  @override
  String get adminRunHelp =>
      'Publish this bus timetable for a specific Colombo service date. Starting the run opens boarding; departure is recorded separately.';

  @override
  String get adminRunRescheduleHelp =>
      'To reschedule, cancel the previous scheduled run and publish its replacement. Stop intervals are retained; the bus timetable stays unchanged.';

  @override
  String get adminRunWindowHelp =>
      'Start window: 5 minutes before to 30 minutes after departure. Late starts require a reason.';

  @override
  String get adminRunPublish => 'Publish dated departure';

  @override
  String get adminRunReload => 'Reload departures';

  @override
  String get adminRunCancel => 'Cancel scheduled run';

  @override
  String get adminRunConfirmed => 'Dated departure change confirmed.';

  @override
  String get adminRunLoadFailed =>
      'Could not load dated departures. Retry when online.';

  @override
  String get adminRunChangeFailed =>
      'Change was not confirmed. Reload and retry.';

  @override
  String get adminRunReviewTimetable =>
      'Stored timetable needs administrator review.';

  @override
  String get adminRunEmpty => 'No dated departures for this bus.';

  @override
  String get adminRunScheduled => 'Scheduled';

  @override
  String get adminRunBoarding => 'Boarding';

  @override
  String get adminRunInProgress => 'In progress';

  @override
  String get adminRunCompleted => 'Completed';

  @override
  String get adminRunCancelled => 'Cancelled';

  @override
  String get adminRunUnknown => 'Status unavailable';

  @override
  String get adminCalendarDatesInvalid =>
      'Choose weekdays and a date range of at most 31 days.';

  @override
  String get adminCalendarReload => 'Reload the published calendar.';

  @override
  String get adminCalendarPublishedOnly =>
      'Only a published calendar can generate departures.';

  @override
  String get adminCalendarInvalid =>
      'Invalid calendar. Publish a reviewed replacement.';

  @override
  String get adminCalendarBusChanged =>
      'The bus timetable changed. Publish a reviewed replacement calendar.';

  @override
  String get adminColomboTimeInvalid =>
      'Choose a valid Colombo departure time.';

  @override
  String get adminPhysicalBusRequired => 'Choose an available physical bus.';

  @override
  String get adminCompleteTimetableRequired =>
      'A complete reviewed timetable is required for a dated run.';

  @override
  String get adminRouteUnavailable => 'Route unavailable.';

  @override
  String get adminRescheduleInputInvalid =>
      'Choose an unreplaced, not-started run and a public reason (5–300 characters).';

  @override
  String get adminReviewBusTimetable =>
      'Review the current physical bus timetable first.';

  @override
  String get adminDifferentDeparture => 'Choose a different departure time.';

  @override
  String get adminReviewScheduleVersion =>
      'Review the original schedule version.';

  @override
  String get adminReconcileFirst => 'Reconcile the active operation first.';

  @override
  String get adminCancelNotStartedOnly =>
      'Only a not-started run can be cancelled here.';

  @override
  String adminServiceDate(String date) {
    return 'Service date: $date';
  }

  @override
  String adminColomboDeparture(String time) {
    return 'Colombo departure: $time';
  }

  @override
  String adminLateReason(String reason) {
    return 'Late-start reason: $reason';
  }

  @override
  String adminPublishedStopTimes(String times) {
    return 'Published stop times: $times';
  }

  @override
  String adminColomboDateTime(String date, String time) {
    return '$date $time (Asia/Colombo)';
  }

  @override
  String get adminGeometryRouteId => 'Route ID';

  @override
  String get adminGeometryImportJson => 'Reviewed road geometry JSON';

  @override
  String get adminGeometryActionFailed =>
      'Geometry change was not confirmed. Check access, review reason and current route/stop data before retrying.';

  @override
  String get adminFareLoadFailed =>
      'Fare publications could not be loaded. Reload when connected; no empty catalogue has been confirmed.';

  @override
  String get adminFarePublished => 'Published';

  @override
  String get adminFareArchived => 'Archived';

  @override
  String get adminFarePublicationInvalid => 'Invalid fare publication';

  @override
  String get adminFareBusesRequired => 'Select reviewed buses';

  @override
  String get adminFareSplitRequired =>
      'Split this publication into smaller reviewed records';

  @override
  String get adminFareApplicabilityMismatch =>
      'Tariff/mapping applicability mismatch';

  @override
  String get adminFareReviewRequired =>
      'Review source, stages, class and effective dates; enter a review reason.';

  @override
  String get adminFareRouteUnavailable => 'Route is unavailable';

  @override
  String get adminFareItineraryMismatch =>
      'A bus itinerary or route does not match the reviewed mapping';

  @override
  String get adminFareArchiveReasonRequired => 'Enter an archive reason';

  @override
  String get adminFareTextInvalid => 'Invalid fare catalogue text';

  @override
  String get adminFareDateInvalid => 'Invalid fare effective date';

  @override
  String get adminFareSourceInvalid => 'Invalid tariff source';

  @override
  String get adminFareUnreviewed => 'Unreviewed or unsupported fare table';

  @override
  String get adminFareTableInvalid => 'Invalid fare table';

  @override
  String get adminFareMatrixInvalid => 'Invalid fare matrix';

  @override
  String get adminFareMinorInvalid => 'Invalid minor-unit fare';

  @override
  String get adminFareMappingInvalid => 'Unreviewed or invalid fare mapping';

  @override
  String get adminFareOccurrencesInvalid => 'Invalid fare occurrences';

  @override
  String get adminGeometryReviewRequired =>
      'Review the geometry and enter a reason';

  @override
  String get adminGeometryRouteChanged =>
      'Review the current directed route itinerary';

  @override
  String get adminGeometryModeMismatch =>
      'Geometry belongs to another data mode';

  @override
  String get adminGeometryVersionRequired => 'Use a new reviewed version';

  @override
  String get adminGeometryStopMismatch =>
      'Review each stop coordinate and its road vertex';

  @override
  String get adminGeometryReasonRequired => 'Enter a review reason';

  @override
  String get adminGeometryMissing => 'No geometry to withdraw';

  @override
  String get adminGeometryDataInvalid => 'Invalid reviewed route geometry';

  @override
  String get adminGeometryStopsInvalid => 'Invalid ordered geometry stops';

  @override
  String get adminGeometryCoordinatesInvalid => 'Invalid coordinates';

  @override
  String get adminGeometryVerticesInvalid => 'Stop vertices must increase';

  @override
  String get adminGeometryResolutionInvalid => 'Review road path resolution';

  @override
  String get adminGeometryTooLong => 'Route too long';

  @override
  String adminFarePreviewRoute(String route, String serviceClass) {
    return 'Route: $route · service class: $serviceClass';
  }

  @override
  String adminFarePreviewDates(String from, String until) {
    return 'Effective dates: $from – $until';
  }

  @override
  String adminImportSource(String source) {
    return 'Source: $source';
  }

  @override
  String adminFareVersions(String table, String mapping) {
    return 'Fare version: $table · mapping version: $mapping';
  }

  @override
  String adminFareBuses(String buses) {
    return 'Buses: $buses';
  }

  @override
  String adminFareCell(String from, String to, String amount) {
    return '$from → $to: $amount';
  }

  @override
  String adminGeometryVersion(String route, String version) {
    return 'Route: $route · version: $version';
  }

  @override
  String adminGeometryDistance(String stops, String distance) {
    return '$stops · $distance km';
  }

  @override
  String adminFareRowStatus(String status, String version) {
    return '$status · version: $version';
  }

  @override
  String get reviewAccessRequired =>
      'Administrator access is required to review this case.';

  @override
  String get reviewSelfForbidden =>
      'You cannot review a case concerning your own account.';

  @override
  String get reviewSignInRequired =>
      'Your session is no longer valid. Sign in again before continuing.';

  @override
  String get reviewAccountChanged =>
      'The signed-in account changed. Reopen this screen from the current account.';

  @override
  String get reviewRestricted =>
      'This account cannot perform administrative actions while restricted.';

  @override
  String get reviewAlreadyDecided =>
      'This review already has a decision. Refresh to inspect the recorded outcome.';

  @override
  String get reviewUnavailable =>
      'This review is unavailable. Refresh before taking another action.';

  @override
  String get reviewOperationUnavailable =>
      'This trip is no longer available for this operation. Refresh its current state.';

  @override
  String get reviewRetryConflict =>
      'This request conflicts with a recorded request. Refresh and inspect the outcome before a new action.';

  @override
  String get reviewVoteUnknown => 'Vote unavailable';

  @override
  String reviewRunDriver(String run, String driver) {
    return 'Run: $run\nDriver: $driver';
  }

  @override
  String reviewDriverId(String driver) {
    return 'Driver: $driver';
  }

  @override
  String reviewVoteEvidence(String user, String vote) {
    return '$user · $vote';
  }

  @override
  String get profileMissing => 'No profile found. Please sign in again.';

  @override
  String get profileLoadFailed => 'Unable to load profile from the database.';

  @override
  String get profileUnavailable => 'Profile unavailable.';

  @override
  String get profilePassenger => 'Passenger';

  @override
  String get profileContributor => 'Community Contributor';

  @override
  String get profileOperator => 'Transit Bus Operator';

  @override
  String get profileAdministrator => 'System Administrator';

  @override
  String get profileCommuter => 'Inclusive Commuter';

  @override
  String get profileEdit => 'Edit';

  @override
  String get profileEditTitle => 'Edit Profile';

  @override
  String get profileFullName => 'Full Name';

  @override
  String get profileEmail => 'Email Address';

  @override
  String get profilePhone => 'Phone Number';

  @override
  String get profileNameRequired => 'Please enter your name';

  @override
  String get profileSave => 'Save Changes';

  @override
  String get profileSaved => 'Profile updated successfully!';

  @override
  String get profileSaveFailed =>
      'Profile changes could not be confirmed. Please retry.';

  @override
  String get profileSignOutFailed =>
      'Could not clear private drafts or sign out. Please retry.';

  @override
  String get profileSignedOut => 'You have been signed out successfully.';

  @override
  String get profileSignOut => 'Sign Out';

  @override
  String get profileCancel => 'Cancel';

  @override
  String get profileRetry => 'Retry';

  @override
  String get profileLogoutQuestion =>
      'Sign out and remove pending report drafts and photos from this device? Requests already sent may still complete. Published reports remain available after signing back in.';

  @override
  String get profileSettings => 'SETTINGS';

  @override
  String get profileSupport => 'SUPPORT';

  @override
  String get profilePersonalInfo => 'PERSONAL INFORMATION';

  @override
  String get profileAdminConsole => 'Admin console';

  @override
  String get profileAccessibility => 'Accessibility Preferences';

  @override
  String get profilePush => 'Push Notifications';

  @override
  String get profilePassword => 'Change Password';

  @override
  String get profilePlaces => 'Saved Places';

  @override
  String get profileRate => 'Rate Us';

  @override
  String get profileHelp => 'Help Center';

  @override
  String get profileUpdates => 'Check for Updates';

  @override
  String get profileNotSet => 'Not set';

  @override
  String get profileReports => 'Reports';

  @override
  String get profileVerifications => 'Verifications';

  @override
  String get profileBadges => 'Badges';

  @override
  String get profileImpact => 'Community Impact Score';

  @override
  String get profileSeeAll => 'See All →';

  @override
  String get profileBadgeDetails => 'View earned badges';

  @override
  String get profileDelete => 'Delete Account';

  @override
  String get profileDeleteUnavailable =>
      'Self-service deletion is not available here yet';

  @override
  String profileComingSoon(String feature) {
    return '$feature will be available in a future update.';
  }

  @override
  String profileContributionSummary(int points, int reports, int badges) {
    return '$points Points • $reports reports • $badges badges';
  }

  @override
  String get driverDashboard => 'Operator Dashboard';

  @override
  String get driverFallback => 'Operator';

  @override
  String get driverAddStop => 'Add Station to Route';

  @override
  String get driverNoBuses =>
      'No physical buses are available on your assigned route. Ask the administrator to add or review a bus.';

  @override
  String get driverNoGps => 'No shared GPS update';

  @override
  String get driverBusUnavailable =>
      'Selected bus unavailable; broadcasting stopped locally';

  @override
  String get driverAssignmentUnavailable =>
      'Bus assignment unavailable; broadcasting stopped locally';

  @override
  String get driverVerifyRuns => 'Connect to verify dated departures.';

  @override
  String get driverSignInFirst => 'Sign in as an approved operator first.';

  @override
  String get driverAssignedOnly =>
      'Only the assigned driver can update this bus.';

  @override
  String get driverClaimFailed =>
      'Bus assignment was not confirmed. Refresh and retry.';

  @override
  String get driverRampWorkingSaved => 'Ramp working observation saved';

  @override
  String get driverRampBrokenSaved => 'Ramp broken observation saved';

  @override
  String get driverRampFailed =>
      'Could not confirm all ramp updates. Refresh and retry.';

  @override
  String get driverOccupancyFailed =>
      'Could not confirm all occupancy updates. Refresh and retry.';

  @override
  String get driverClaimFirst => 'Claim this bus before starting a trip.';

  @override
  String get driverSelectRun =>
      'Select an administrator-published dated departure.';

  @override
  String get driverLateTitle => 'Late start reason';

  @override
  String get driverLateHelp =>
      'At least 5 characters. Latest start is 30 minutes after departure.';

  @override
  String get driverContinue => 'Continue';

  @override
  String get driverLateRequired =>
      'Enter a late-start reason of at least 5 characters.';

  @override
  String get driverGpsAcknowledged => 'Shared GPS acknowledged';

  @override
  String get driverTrackingTitle => 'AccessTransit Live Bus Tracking';

  @override
  String get driverGpsUnavailable =>
      'GPS unavailable; last shared fix may be stale';

  @override
  String get driverGpsStreamError =>
      'GPS updates unavailable. Check location access and retry.';

  @override
  String get driverBoardingStarted =>
      'Boarding session started. Record actual departure when leaving.';

  @override
  String get driverRunResumed =>
      'Active dated trip resumed. GPS broadcasting acknowledged.';

  @override
  String get driverStartFailed =>
      'Trip start was not confirmed. Refresh and retry.';

  @override
  String get driverGpsPending => 'Pending GPS upload; coordinates are local';

  @override
  String get driverGpsRetry => 'GPS upload failed/offline; next fix retries';

  @override
  String get driverBoardingEnded => 'Boarding cancelled; broadcast ended';

  @override
  String get driverCompletionAcknowledged =>
      'Shared trip completion acknowledged';

  @override
  String get driverBoardingCancelled =>
      'Boarding cancelled. Broadcasting ended.';

  @override
  String get driverTripCompleted =>
      'Trip completion saved. Broadcasting ended.';

  @override
  String get driverStopPending =>
      'GPS stopped locally; shared completion failed. Retry Stop.';

  @override
  String get driverStopFailed =>
      'Shared trip completion was not confirmed. Retry Stop.';

  @override
  String get driverDatedDeparture => 'Dated departure';

  @override
  String get driverNoRuns =>
      'No dated departures published. Ask the administrator to schedule this bus.';

  @override
  String get driverColomboDeparture => 'Colombo service departure';

  @override
  String get driverBoardingHelp =>
      'Starting opens boarding. Record actual departure separately; late starts require a reason.';

  @override
  String get driverDepartureSaved =>
      'Actual departure confirmed by the server.';

  @override
  String get driverDepartureFailed =>
      'Departure was not confirmed. Refresh and retry.';

  @override
  String get driverRecordDeparture => 'Record actual departure';

  @override
  String get driverActive => 'TRIP IN PROGRESS';

  @override
  String get driverInactive => 'TRIP INACTIVE';

  @override
  String get driverStart => 'Start Trip';

  @override
  String get driverStop => 'Stop Trip';

  @override
  String get driverTelemetry => 'Live Telemetry Data';

  @override
  String get driverGpsInactive =>
      'GPS inactive. Press Start Trip to acquire live GPS location.';

  @override
  String get driverLatitude => 'Latitude:';

  @override
  String get driverLongitude => 'Longitude:';

  @override
  String get driverSpeed => 'Speed:';

  @override
  String get driverHeading => 'Heading:';

  @override
  String get driverLocalFix => 'Local GPS fix:';

  @override
  String get driverAccessibility => 'Vehicle Accessibility Status';

  @override
  String get driverReadOnly => 'Read-only (Not assigned)';

  @override
  String get driverRampObservation => 'Wheelchair ramp observation';

  @override
  String get driverUnknownRamp => 'Unknown - check before selecting';

  @override
  String get driverWorkingObserved => 'Working observed';

  @override
  String get driverBrokenObserved => 'Broken observed';

  @override
  String get driverLift => 'Low-Floor Elevator / Lift Working';

  @override
  String get driverStopLiftHelp =>
      'Stop lift observations are reported separately';

  @override
  String get driverOccupancy => 'Occupancy Level:';

  @override
  String get driverLow => 'Low';

  @override
  String get driverMedium => 'Medium';

  @override
  String get driverHigh => 'High';

  @override
  String get driverAccess => 'Operator access';

  @override
  String get driverChecking => 'Checking operator approval...';

  @override
  String get driverSignInApproval => 'Sign in to check operator approval.';

  @override
  String get driverApprovalRequired =>
      'Operator approval required. Ask the project administrator to review your account. Selecting Operator at registration does not grant approval. A live connection is required to verify access.';

  @override
  String get driverCheckAgain => 'Check again';

  @override
  String get driverReturnSignIn => 'Return to sign in';

  @override
  String get driverSignOutFailed => 'Could not sign out. Please retry.';

  @override
  String get driverRouteAssignment => 'Driver route assignment';

  @override
  String get driverRouteRequired =>
      'An administrator must assign an available route before you can operate a bus. A live connection is required to verify the assignment.';

  @override
  String get driverCheckAssignment => 'Check assignment';

  @override
  String get driverScheduled => 'Scheduled';

  @override
  String get driverBoarding => 'Boarding';

  @override
  String get driverInProgress => 'In Progress';

  @override
  String get driverCompleted => 'Completed';

  @override
  String get driverCancelled => 'Cancelled';

  @override
  String get driverUnknownState => 'State unavailable';

  @override
  String driverName(String name) {
    return 'Operator: $name';
  }

  @override
  String driverBusAssigned(String bus) {
    return 'Bus $bus is now assigned to you!';
  }

  @override
  String driverOccupancySaved(String level) {
    return 'Occupancy updated to $level';
  }

  @override
  String driverTrackingBody(String bus) {
    return 'GPS tracking for Bus $bus; shared delivery shown in app';
  }

  @override
  String driverRunWindow(String earliest, String latest) {
    return 'Start window: $earliest to $latest';
  }

  @override
  String driverRunOption(String time, String status) {
    return '$time · $status';
  }

  @override
  String driverActiveSummary(String status, String duration) {
    return '$status\nDuration: $duration';
  }

  @override
  String driverStartHelp(String bus) {
    return 'Press Start Trip to activate background GPS tracking for Bus $bus.';
  }

  @override
  String driverGpsStale(String status) {
    return 'Shared GPS stale; $status';
  }

  @override
  String driverLastReceipt(String time) {
    return 'Last shared receipt: $time';
  }

  @override
  String get driverProgress => 'Trip Route Progress';

  @override
  String get driverNoActive => 'No Active Trip';

  @override
  String get driverNoActiveHelp =>
      'No active run. Select a dated departure and start boarding above; record actual departure separately when leaving.';

  @override
  String get driverFinalDestination => 'Final Destination Reached';

  @override
  String get driverFinalAcknowledged =>
      'Final arrival and trip completion acknowledged';

  @override
  String get driverArrivalFailed =>
      'Arrival was not confirmed. Refresh and retry.';

  @override
  String get driverNextReached => 'Next Stop Reached';

  @override
  String get driverFinalReached => 'Final Stop Reached';

  @override
  String get driverEnd => 'End Trip';

  @override
  String get driverUnknown => 'Unknown';

  @override
  String get driverNotRecorded => 'Not recorded';

  @override
  String get driverEtaHelp =>
      'ETAs follow actual departure and recorded arrivals. Missing timetable intervals use a 6-minute estimate; confirm timing with the operator.';

  @override
  String get driverScheduledArrival => 'SCHEDULED ARRIVAL';

  @override
  String get driverTimetableTarget => 'Timetable Target';

  @override
  String get driverCurrentEta => 'CURRENT ETA';

  @override
  String get driverDelayCleared => 'Delay notice removal saved.';

  @override
  String get driverDelayClearFailed =>
      'Delay removal was not confirmed. Retry.';

  @override
  String get driverClear => 'Clear';

  @override
  String get driverUpdateDelay => 'Update Delay / Traffic Reason';

  @override
  String get driverReportDelay => 'Report Traffic / Delay (+5m, +10m)';

  @override
  String get driverTraffic => 'Traffic Congestion';

  @override
  String get driverRain => 'Heavy Rain / Flooding';

  @override
  String get driverAccident => 'Accident Ahead';

  @override
  String get driverRoadworks => 'Road Construction';

  @override
  String get driverBreakdown => 'Mechanical Breakdown';

  @override
  String get driverDelayTitle => 'Report Delay / Incident';

  @override
  String get driverDelayHelp =>
      'Alerts all passenger screens and updates live ETAs.';

  @override
  String get driverDelayTime => 'Estimated Delay Time';

  @override
  String get driverDelayReason => 'Delay Reason';

  @override
  String get driverDelayFailed => 'Delay upload was not confirmed. Retry.';

  @override
  String get driverDepartsNow => 'On Time (Departs Now)';

  @override
  String get driverOrigin => 'Origin';

  @override
  String get driverPreTrip => 'Pre-Trip Schedule Check';

  @override
  String get driverOnTimeMinute => 'On Time (±1 min)';

  @override
  String get driverEarly => 'Running Early';

  @override
  String get driverOnTimeTarget => 'On Time Target';

  @override
  String get driverDelayed => 'Delayed';

  @override
  String get driverMinusFive => '-5m';

  @override
  String get driverZeroSchedule => '0 (On Schedule)';

  @override
  String get driverPlusFifteen => '+15m';

  @override
  String get driverZeroMinutes => '0 min';

  @override
  String get driverSelectBus => 'Select Bus Run';

  @override
  String get driverAssigned => 'Assigned to You';

  @override
  String get driverAssignMe => 'Assign to Me';

  @override
  String get driverAssignedOther => 'Assigned to another operator';

  @override
  String get driverUpcoming => 'Upcoming';

  @override
  String get driverDeparted => 'Departed';

  @override
  String get driverAssistanceUnavailable =>
      'Shared request updates are unavailable. Displayed requests may be out of date.';

  @override
  String get driverAssistanceTitle => 'Boarding Assistance Requests';

  @override
  String get driverAssistanceEmpty =>
      'No active assistance requests for this bus.';

  @override
  String get driverBoardingAt => 'Boarding';

  @override
  String get driverAlightingAt => 'Getting off';

  @override
  String driverStopPosition(int index, int total) {
    return 'Current Position: Stop $index of $total';
  }

  @override
  String driverNextStop(String stop) {
    return 'Next Stop: $stop';
  }

  @override
  String driverArrivalSaved(String stop, String next) {
    return 'Arrival saved at $stop. Next: $next';
  }

  @override
  String driverFinalSaved(String stop) {
    return 'Final arrival saved at $stop. Trip completed.';
  }

  @override
  String driverTarget(String stop) {
    return 'Target: $stop';
  }

  @override
  String driverDestination(String stop) {
    return 'Destination: $stop';
  }

  @override
  String driverPlannedDeparture(String time) {
    return 'Planned departure (Colombo): $time';
  }

  @override
  String driverActualDeparture(String time) {
    return 'Actual departure (Colombo): $time';
  }

  @override
  String driverBroadcastReason(String reason) {
    return 'Broadcasted to Riders: $reason';
  }

  @override
  String driverAddedMinutes(int minutes) {
    return '+$minutes mins added to passenger arrival ETAs';
  }

  @override
  String driverMinuteOption(int minutes) {
    return '+$minutes mins';
  }

  @override
  String driverDelaySaved(String reason, int minutes) {
    return 'Delay notice saved: $reason (+$minutes mins)';
  }

  @override
  String driverBroadcastDelay(int minutes) {
    return 'Broadcast Delay (+$minutes mins)';
  }

  @override
  String driverDepartsIn(int minutes) {
    return 'Departs in $minutes mins';
  }

  @override
  String driverLateMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Delayed by $minutes mins',
      one: 'Delayed by 1 min',
    );
    return '$_temp0';
  }

  @override
  String driverScheduledDep(String time, String stop) {
    return 'Scheduled Dep: $time ($stop)';
  }

  @override
  String driverEarlyMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Running Early ($minutes mins)',
      one: 'Running Early (1 min)',
    );
    return '$_temp0';
  }

  @override
  String driverLateShort(int minutes) {
    return '+$minutes min late';
  }

  @override
  String driverEarlyShort(int minutes) {
    return '$minutes min early';
  }

  @override
  String driverBusOption(
    String bus,
    String time,
    String endpoints,
    String assigned,
  ) {
    return 'Bus $bus (Dep: $time)$endpoints$assigned';
  }

  @override
  String driverRouteName(String route) {
    return 'Route $route';
  }

  @override
  String driverDepartureTime(String time) {
    return 'Departure: $time';
  }

  @override
  String driverStopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops',
      one: '1 stop',
    );
    return '$_temp0';
  }

  @override
  String driverActiveRequests(int count) {
    return '$count Active';
  }

  @override
  String driverClosedRequests(int count) {
    return 'Closed requests ($count)';
  }

  @override
  String driverRequestSummary(String rider, String stop, String types) {
    return '$rider at $stop ($types)';
  }

  @override
  String driverAssistanceStop(String purpose, String stop) {
    return '$purpose at: $stop';
  }

  @override
  String get driverEtaUnavailable => 'ETA unavailable';

  @override
  String get driverSchedulePassed => 'Scheduled time passed';

  @override
  String get driverArrivingNow => 'Arriving now';

  @override
  String driverScheduledFor(String time) {
    return 'Scheduled for $time';
  }

  @override
  String driverTomorrowAt(String time) {
    return 'Tomorrow at $time';
  }

  @override
  String driverTomorrowIn(String time, int hours, int minutes) {
    return 'Tomorrow at $time (in ${hours}h ${minutes}m)';
  }

  @override
  String driverDepartedAgo(int minutes) {
    return 'Departed $minutes mins ago';
  }

  @override
  String driverArrivingMinutes(int minutes) {
    return 'Arriving in $minutes mins';
  }

  @override
  String driverArrivingHours(int hours, int minutes) {
    return 'Arriving in ${hours}h ${minutes}m';
  }

  @override
  String get recoveryTitle => 'Reset Password';

  @override
  String get recoveryCheckEmail => 'Check your email';

  @override
  String get recoveryInboxHelp =>
      'Please check your inbox and follow the link to create a new password.';

  @override
  String get recoveryBackLogin => 'Back to Login';

  @override
  String get recoveryResend => 'Resend email';

  @override
  String get recoveryForgot => 'Forgot your password?';

  @override
  String get recoveryEmailHelp =>
      'Enter the email address associated with your account and we\'ll send you instructions to reset your password.';

  @override
  String get recoveryEmail => 'Email Address';

  @override
  String get recoveryEmailHint => 'e.g., name@example.com';

  @override
  String get recoveryPrivacy => 'We will never share your email.';

  @override
  String get recoverySend => 'Send Reset Link';

  @override
  String get recoveryCreate => 'Create New Password';

  @override
  String get recoveryPasswordHelp =>
      'Please choose a strong password that you haven\'t used before.';

  @override
  String get recoveryNewPassword => 'New Password';

  @override
  String get recoveryPasswordHint => 'Enter your new password';

  @override
  String get recoveryConfirm => 'Confirm New Password';

  @override
  String get recoveryConfirmHint => 'Re-enter your new password';

  @override
  String get recoveryShow => 'Show password';

  @override
  String get recoveryHide => 'Hide password';

  @override
  String get recoverySecurity => 'Your security is our priority.';

  @override
  String get recoveryUpdated => 'Password Updated';

  @override
  String get recoverySuccess =>
      'Your password has been reset successfully. You can now sign in with your new password.';

  @override
  String get recoveryGoLogin => 'Go to Login';

  @override
  String get recoveryEmailRequired => 'Please enter your email address.';

  @override
  String get recoveryEmailInvalid => 'Please enter a valid email address.';

  @override
  String get recoveryAccountMissing =>
      'No account was found with this email address.';

  @override
  String get recoveryDisabled => 'This account has been disabled.';

  @override
  String get recoveryTooMany => 'Too many requests. Please try again later.';

  @override
  String get recoveryNetwork =>
      'Network error. Please check your internet connection.';

  @override
  String get recoverySendFailed => 'Unable to send password reset email.';

  @override
  String get recoveryResetFailed =>
      'Unable to reset password. Please try again.';

  @override
  String get recoveryLinkUnavailable =>
      'This reset link is invalid or has expired. Please request a new one.';

  @override
  String get recoveryExpired =>
      'This reset link has expired. Please request a new one.';

  @override
  String get recoveryInvalid =>
      'This reset link is invalid. Please request a new one.';

  @override
  String get recoveryWeak =>
      'Password is too weak. Please choose a stronger password.';

  @override
  String get recoveryCreateRequired => 'Please create a password.';

  @override
  String get recoveryEightCharacters =>
      'Password must be at least 8 characters.';

  @override
  String get recoveryLetterRequired =>
      'Password must include at least one letter.';

  @override
  String get recoveryNumberRequired =>
      'Password must include at least one number.';

  @override
  String get recoveryConfirmRequired => 'Please confirm your password.';

  @override
  String get recoveryMismatch => 'Passwords do not match.';

  @override
  String get recoveryStrength => 'Password strength';

  @override
  String get recoveryStrengthWeak => 'Weak — add more characters';

  @override
  String get recoveryStrengthFair => 'Fair — try adding numbers or symbols';

  @override
  String get recoveryStrengthGood => 'Good strength';

  @override
  String get recoveryStrengthStrong => 'Strong password';

  @override
  String recoveryInstructionsSent(String email) {
    return 'We sent password reset instructions to\n$email';
  }

  @override
  String get homeMorning => 'Good Morning';

  @override
  String get homeAfternoon => 'Good Afternoon';

  @override
  String get homeEvening => 'Good Evening';

  @override
  String get homeReady => 'Ready to ride?';

  @override
  String get homeWhere => 'Where are you going?';

  @override
  String get homePlanHint => 'Tap to plan your journey';

  @override
  String get homeMenu => 'Open menu';

  @override
  String get homeProfileAction => 'Open profile';

  @override
  String get homeTrack => 'Track\nBus';

  @override
  String get homePlanAction => 'Plan\nJourney';

  @override
  String get homePreferencesAction => 'Access\nPrefs';

  @override
  String get homeHome => 'Home';

  @override
  String get homePlan => 'Plan';

  @override
  String get homePlanJourney => 'Plan Journey';

  @override
  String get homeCommunity => 'Community';

  @override
  String get homeProfile => 'Profile';

  @override
  String get homeRewards => 'Rewards & Contributions';

  @override
  String get homeHelp => 'Help & Support';

  @override
  String get homeLogout => 'Log out';

  @override
  String get homeRecentReports => 'Recent Community Reports';

  @override
  String get homeNoReports => 'No recent community reports.';

  @override
  String get homeReportsUnavailable =>
      'Community reports are unavailable. Try again later.';

  @override
  String get homeReport => 'Report';

  @override
  String get homeRecentJourney => 'Recent Journey';

  @override
  String get homeNoJourney => 'No recorded journey';

  @override
  String get homeStartPlanning => 'Plan a journey to get started';

  @override
  String get homeJourneysLoading => 'Loading recent journey…';

  @override
  String get homeJourneysUnavailable => 'Recent journey unavailable';

  @override
  String get homeRetryLater => 'Try again later';

  @override
  String get homeOrigin => 'Origin';

  @override
  String get homeDestination => 'Destination';

  @override
  String get homeRecent => 'Recent';

  @override
  String get homeReplan => 'Re-plan';

  @override
  String get homeAssistance => 'Assistance';

  @override
  String get homeJustNow => 'Just now';

  @override
  String get homeUnknownAge => 'Observation time unavailable';

  @override
  String homeGreeting(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String homeTrueCount(int count) {
    return 'True: $count';
  }

  @override
  String homeFalseCount(int count, int threshold) {
    return 'False: $count/$threshold';
  }

  @override
  String homeJourneySegment(String origin, String destination) {
    return '$origin to $destination';
  }

  @override
  String homeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mins ago',
      one: '1 min ago',
    );
    return '$_temp0';
  }

  @override
  String homeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String homeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String homeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }

  @override
  String get registrationTitle => 'Register';

  @override
  String get registrationJoin => 'Join Access Transit';

  @override
  String get registrationIntro =>
      'Your journey to inclusive travel begins here.';

  @override
  String get registrationNameHint => 'Enter your full name';

  @override
  String get registrationEmailHint => 'Enter your email';

  @override
  String get registrationPassword => 'Password';

  @override
  String get registrationPasswordHint => 'Create a password';

  @override
  String get registrationConfirm => 'Confirm Password';

  @override
  String get registrationConfirmHint => 'Re-enter your password';

  @override
  String get registrationNeeds => 'I have specific accessibility needs';

  @override
  String get registrationNeedsExample =>
      '(e.g., wheelchair ramp, low floor bus)';

  @override
  String get registrationAccountType => 'Account Type';

  @override
  String get registrationCreate => 'Create Account';

  @override
  String get registrationOr => 'OR';

  @override
  String get registrationGoogle => 'Sign up with Google';

  @override
  String get registrationApple => 'Sign up with Apple';

  @override
  String get registrationGoogleFeature => 'Google sign-up';

  @override
  String get registrationAppleFeature => 'Apple sign-up';

  @override
  String get registrationAlready => 'Already have an account? ';

  @override
  String get registrationLogin => 'Log in';

  @override
  String get registrationExists => 'An account already exists with this email.';

  @override
  String get registrationNotEnabled =>
      'Email/password authentication is not enabled.';

  @override
  String get registrationRequiredFields =>
      'Please fill in all required fields properly.';

  @override
  String get registrationFailed =>
      'Registration failed. Please check your connection and try again.';

  @override
  String get registrationNameRequired => 'Please enter your full name.';

  @override
  String get registrationNameShort => 'Name must be at least 2 characters.';

  @override
  String get registrationNameLetters =>
      'Use letters, spaces, apostrophes, periods or hyphens in your name.';

  @override
  String get onboardingSkipTooltip => 'Skip onboarding';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingStart => 'Get Started';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingTailored => 'Tailored for You';

  @override
  String get onboardingNeedsHelp =>
      'Choose wheelchair and step-free needs, then review current evidence. Voice guidance is unavailable.';

  @override
  String get onboardingNavigate => 'Navigate with Confidence';

  @override
  String get onboardingLiveHelp =>
      'Preview only. Check shared GPS when available; assistance needs an operator response.';

  @override
  String get onboardingCommunity => 'Be the Eyes of the Community';

  @override
  String get onboardingReportsHelp =>
      'Share ramp and elevator observations. Reports are public after upload acknowledgement; rewards need review.';

  @override
  String get onboardingReportIssue => 'Report Issue';

  @override
  String get onboardingRamps => 'Ramps';

  @override
  String get onboardingLowFloor => 'Low-floor';

  @override
  String get onboardingExampleEta => 'Example ETA: 3 min';

  @override
  String get onboardingBoardingHelp => 'Boarding Help';

  @override
  String get onboardingAwaitingReply => 'Example: awaiting reply';

  @override
  String get loginFailed => 'Login failed. Please try again.';

  @override
  String get loginInvalidCredentials =>
      'Invalid email or password. Please check your details and try again.';

  @override
  String get loginDisabled =>
      'This account has been disabled. Please contact support.';

  @override
  String get loginTooMany =>
      'Too many login attempts. Please wait a moment and try again.';

  @override
  String get loginNetwork =>
      'Network error. Please check your connection and try again.';

  @override
  String get loginForgot => 'Forgot Password?';

  @override
  String get loginPasswordHint => 'Enter your password';

  @override
  String get loginPasswordRequired => 'Please enter your password.';

  @override
  String get loginPasswordShort => 'Password must be at least 6 characters.';

  @override
  String get loginOrContinue => 'Or continue with';

  @override
  String get loginBiometrics => 'Sign in with Biometrics';

  @override
  String get loginBiometricFeature => 'Biometric sign-in';

  @override
  String get loginGoogle => 'Sign in with Google';

  @override
  String get loginGoogleFeature => 'Google sign-in';

  @override
  String get loginNoAccount => 'Don\'t have an account?';

  @override
  String get loginSignUp => 'Sign up';

  @override
  String get settingsSaveFailed =>
      'Preferences could not be saved. Please retry.';

  @override
  String get settingsGuestSaved =>
      'Device settings saved. Guest travel needs last for this session.';

  @override
  String get settingsAccountSaved =>
      'Preferences saved for this account on this device.';

  @override
  String get settingsProfile => 'User profile';

  @override
  String get settingsPersonalized => 'Personalized Travel Experience';

  @override
  String get settingsScopeHelp =>
      'High contrast and tap targets apply to this device. Travel needs are saved separately for each signed-in account on this device. Guest needs last for this session. New accounts start with wheelchair access required; review your needs.';

  @override
  String get settingsMobility => 'Mobility & Physical Access';

  @override
  String get settingsWheelchair => 'Wheelchair access required';

  @override
  String get settingsRampHelp =>
      'Require current ramp evidence for matching buses';

  @override
  String get settingsStepFree => 'Step-free routes only';

  @override
  String get settingsStepFreeHelp =>
      'Avoid stops and terminals requiring stairs';

  @override
  String get settingsWalking => 'Minimize walking distance';

  @override
  String get settingsWalkingUnavailable =>
      'Not available yet — walking paths and distances have not been measured';

  @override
  String get settingsSensory => 'Sensory & Vision';

  @override
  String get settingsContrast => 'High contrast mode';

  @override
  String get settingsContrastHelp =>
      'Enhance text clarity and strong border lines (WCAG AAA)';

  @override
  String get settingsLargeTargets => 'Large tap targets (48dp+)';

  @override
  String get settingsTargetsHelp =>
      'Enforce minimum 48dp touch targets across buttons & controls';

  @override
  String get settingsTargetsEnabled => 'Large tap targets (48dp+) enabled';

  @override
  String get settingsTargetsStandard => 'Standard tap targets enabled';

  @override
  String get settingsVoice => 'Voice guidance for navigation';

  @override
  String get settingsVoiceUnavailable =>
      'Not available yet — use your phone screen reader for spoken interface labels';

  @override
  String get settingsHaptics => 'Haptic alerts for stops';

  @override
  String get settingsHapticsUnavailable =>
      'Not available yet — automatic vibration alerts are not supported';

  @override
  String get settingsAssistance => 'Assistance & Environment';

  @override
  String get settingsBoarding => 'Boarding assistance required';

  @override
  String get settingsBoardingUnavailable =>
      'Automatic requests are not available yet — request assistance from the journey screen';

  @override
  String get settingsQuiet => 'Show quiet routes';

  @override
  String get settingsQuietUnavailable =>
      'Not available yet — noise levels are unknown';

  @override
  String get settingsSave => 'Save Preferences';

  @override
  String get searchSwapped => '⇄ Boarding stop and Destination swapped';

  @override
  String get searchSelectBoarding => 'Select Boarding Point';

  @override
  String get searchSelectDestination => 'Select Destination Stop';

  @override
  String get searchTravelChoice => 'Choose Travel Time';

  @override
  String get searchLeaveNow => 'Leave Now';

  @override
  String get searchSpecificTime => 'Set Specific Time';

  @override
  String get searchChooseTime => 'Choose departure time';

  @override
  String get searchChangeDate => 'Change Travel Date';

  @override
  String get searchNeedsTitle => 'Accessibility Needs';

  @override
  String get searchTemporaryHelp =>
      'Customize for this trip only. Your permanent Accessibility Preferences in settings will not be affected.';

  @override
  String get searchWheelchairChip => '♿ Wheelchair';

  @override
  String get searchStepFreeChip => 'Step-free';

  @override
  String get searchResetHelp => 'Reset to saved accessibility preferences';

  @override
  String get searchReset => 'Reset';

  @override
  String get searchRamp => 'Wheelchair Ramp';

  @override
  String get searchRampHelp =>
      'Ensure buses have working motorized or fold-out ramps';

  @override
  String get searchStepFree => 'Step-Free Station Access';

  @override
  String get searchStepFreeHelp =>
      'Only board and exit at stations with elevators or flat paths';

  @override
  String get searchMinWalking => 'Minimize Walking Distance';

  @override
  String get searchWalkingUnknown =>
      'Not available yet — walking distance is unknown';

  @override
  String get searchApply => 'Apply to This Trip';

  @override
  String get searchEndpointsRequired =>
      'Please select origin and destination stations.';

  @override
  String get searchEndpointsDifferent =>
      'Origin and destination stations cannot be the same.';

  @override
  String get searchRampRequired => 'Ramp Required';

  @override
  String get searchStepFreeFilter => 'Step-Free';

  @override
  String get searchMinWalkFilter => 'Min Walk';

  @override
  String get searchFind => 'Find Buses';

  @override
  String get searchNoStops => 'No shared stops available. Connect and retry.';

  @override
  String get searchPlan => 'Plan Journey';

  @override
  String get searchSync => 'Refresh bus data';

  @override
  String get searchBoardingHeading => 'BOARDING POINT';

  @override
  String get searchChooseBoarding => 'Choose Boarding Point';

  @override
  String get searchRampAvailable => '♿ Wheelchair Ramp Available';

  @override
  String get searchStandardStop => 'Standard Stop';

  @override
  String get searchTapBoarding => 'Tap to select boarding station';

  @override
  String get searchSwap => 'Swap boarding point and destination';

  @override
  String get searchDestinationHeading => 'WHERE ARE YOU GOING?';

  @override
  String get searchChooseDestination => 'Choose Destination';

  @override
  String get searchAccessibleDestination => '♿ Accessible Destination';

  @override
  String get searchTapDestination => 'Tap to select destination station';

  @override
  String get searchMyLocation => 'My Location';

  @override
  String get searchBoardingSuggestions => 'Suggested boarding stops';

  @override
  String get searchDestinationSuggestions => 'Suggested destination stops';

  @override
  String get searchSuggestions => 'Show suggested stops';

  @override
  String get searchDepartNow => 'Depart Now';

  @override
  String get searchTravelHeading => 'TRAVEL TIME';

  @override
  String get searchChange => 'Change';

  @override
  String get searchOptions => 'Accessibility Options';

  @override
  String get searchConfigure => 'Configure';

  @override
  String get searchAllBusesHelp =>
      'All buses shown. Tap Configure to require ramps or step-free access.';

  @override
  String get searchStationHint =>
      'Type station or city (e.g. Pettah, Mount Lavinia)...';

  @override
  String get searchAllStops => 'All Stops';

  @override
  String get searchNoMatches =>
      'No matching stations found.\nTry a different spelling or clear filters.';

  @override
  String get searchRampBadge => 'Ramp  ';

  @override
  String get searchElevatorBadge => 'Elevator  ';

  @override
  String get searchSuggestionIcon => 'Suggested stops';

  @override
  String get searchSuggestedBoarding => 'Suggested Boarding Stops';

  @override
  String get searchSuggestedDestination => 'Suggested Destination Stops';

  @override
  String get searchVoiceUnavailable =>
      'Voice recognition is not available yet. Tap a suggested stop below:';

  @override
  String searchSelectedTime(String time) {
    return 'Selected: $time';
  }

  @override
  String searchTodayAt(String time) {
    return 'Today at $time';
  }

  @override
  String searchDateAt(String date, String time) {
    return '$date at $time';
  }

  @override
  String searchStopSelected(String name) {
    return 'Selected: $name';
  }

  @override
  String searchActiveNeeds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Active',
      one: '1 Active',
    );
    return '$_temp0';
  }

  @override
  String get resultsScheduled => 'Scheduled';

  @override
  String get resultsPastUnconfirmed =>
      'Scheduled time passed - departure unconfirmed';

  @override
  String get resultsNowUnconfirmed => 'Scheduled now - departure unconfirmed';

  @override
  String get resultsRampReady => 'Wheelchair Ramp Ready · Step-free entry';

  @override
  String get resultsRampEquipped => 'Ramp equipped · Check operator assistance';

  @override
  String get resultsStandardService => 'Standard bus service';

  @override
  String get resultsUnknown => 'Unknown';

  @override
  String get resultsLow => 'Low';

  @override
  String get resultsMedium => 'Medium';

  @override
  String get resultsHigh => 'High';

  @override
  String get resultsStarted => 'Started run';

  @override
  String get resultsDemoTimetable => 'Demo timetable';

  @override
  String get resultsPublishedTimetable => 'Published timetable';

  @override
  String get resultsWheelchairBus => 'Wheelchair Accessible Bus';

  @override
  String get resultsRampBus => 'Standard Ramp Bus';

  @override
  String get resultsStandardBus => 'Standard Bus';

  @override
  String get resultsEstimatedTimes =>
      'Some times are model estimates; confirm with the operator.';

  @override
  String get resultsWalkingUnknown =>
      'Walking distance is unavailable for this journey. Results are not ranked by walking distance.';

  @override
  String get resultsReviewNeeds => 'Review trip requirements';

  @override
  String get resultsReviewHelp =>
      'Changes apply only to this search. Turning a requirement off may show services with unknown access or reported barriers. Review the evidence before choosing a journey.';

  @override
  String get resultsKeepNeeds => 'Keep requirements';

  @override
  String get resultsApplyNeeds => 'Apply to this search';

  @override
  String get resultsNoAccessible => 'No Accessible Buses Found';

  @override
  String get resultsNoDirect => 'No Direct Buses Found';

  @override
  String get resultsNoAccessibleHelp =>
      'No scheduled journeys have known access matching these requirements. Stop access may be unknown or an active barrier may be reported. Review your accessibility filters.';

  @override
  String get resultsShowAll => 'Show all matching buses';

  @override
  String get resultsShowAllHelp =>
      'Shows options outside the Accessible tab, including unknown access or reported barriers. Your trip requirements stay applied.';

  @override
  String get resultsTitle => 'Available Buses';

  @override
  String get resultsChooseHelp => 'Select a bus to track live journey';

  @override
  String get resultsFastest => 'Fastest';

  @override
  String get resultsRoute => 'Route';

  @override
  String get resultsTimetableHelp =>
      'Timetable estimates - departure unconfirmed. Open route details for GPS status.';

  @override
  String get resultsDeparture => 'Departure';

  @override
  String get resultsArrival => 'Arrival';

  @override
  String get resultsRampAvailable => 'Ramp Available';

  @override
  String get resultsLowFloor => 'Low Floor';

  @override
  String get detailsAmbiguous =>
      'Departure identity is ambiguous. Refresh the selection.';

  @override
  String get detailsAccountChanged => 'Account changed. Return to Search.';

  @override
  String get detailsUnavailable => 'Service unavailable. Retry';

  @override
  String get detailsRunUnavailable => 'Run status unavailable';

  @override
  String get detailsRunUnverified => 'Scheduled · run not verified';

  @override
  String get detailsCompleted => 'Completed';

  @override
  String get detailsCancelled => 'Cancelled';

  @override
  String get detailsStale => 'Location unavailable or stale';

  @override
  String get detailsLive => 'LIVE GPS';

  @override
  String get detailsWheelchair => 'Wheelchair access';

  @override
  String get detailsSavedHelp =>
      'Saved selection · times and needs are preserved; review current conditions.';

  @override
  String get detailsDefaultsDiffer =>
      'Your current accessibility defaults differ from this saved selection.';

  @override
  String get detailsCatalogueUnavailable => 'Catalogue updates unavailable.';

  @override
  String get detailsStops => 'Stops on your journey';

  @override
  String get detailsIntermediateUnknown =>
      'Intermediate stop · time unavailable';

  @override
  String get detailsEvidence => 'Accessibility evidence';

  @override
  String get detailsAssistanceUnavailable => 'Driver assistance unavailable';

  @override
  String get detailsReport => 'Report a condition';

  @override
  String get detailsLoadingReports => 'Loading reports…';

  @override
  String get detailsRetry => 'Retry updates';

  @override
  String get detailsVerifySave =>
      'Connect to verify this departure before saving.';

  @override
  String get resultsSafe => 'Safe';

  @override
  String get resultsWarning => 'Warning';

  @override
  String get resultsNotAccessible => 'Not accessible';

  @override
  String get detailsResolved => 'Resolved';

  @override
  String get detailsRecheckUnknown =>
      'Unresolved barrier - observation time unknown; needs recheck';

  @override
  String get detailsObservationUnknown => 'Observation time unknown';

  @override
  String get detailsExpired => 'Expired or unavailable';

  @override
  String get detailsRecheck => 'Unresolved barrier — needs recheck';

  @override
  String get detailsRecent => 'Recent observation';

  @override
  String resultsRouteNumber(String number) {
    return 'Route $number';
  }

  @override
  String resultsScheduledDate(String date, String time) {
    return 'Scheduled $date, $time';
  }

  @override
  String resultsScheduledAt(String date, String time) {
    return 'Scheduled $date at $time';
  }

  @override
  String resultsTomorrow(String time) {
    return 'Scheduled tomorrow, $time';
  }

  @override
  String resultsTomorrowAt(String time) {
    return 'Scheduled tomorrow at $time';
  }

  @override
  String resultsToday(String time) {
    return 'Scheduled today, $time';
  }

  @override
  String resultsTodayAt(String time) {
    return 'Scheduled today at $time';
  }

  @override
  String resultsScheduledIn(int minutes, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Scheduled in $minutes mins - $time',
      one: 'Scheduled in 1 min - $time',
    );
    return '$_temp0';
  }

  @override
  String resultsBoardingEstimate(String time, String source) {
    return 'Boarding estimate $time · $source';
  }

  @override
  String resultsCountTitle(int count) {
    return 'Available Buses ($count)';
  }

  @override
  String resultsAvailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count buses available',
      one: '1 bus available',
    );
    return '$_temp0';
  }

  @override
  String resultsNoDirectHelp(String origin, String destination) {
    return 'There are currently no direct bus routes connecting $origin to $destination.';
  }

  @override
  String resultsAllTab(int count) {
    return 'All ($count)';
  }

  @override
  String resultsAccessibleTab(int count) {
    return 'Accessible ($count)';
  }

  @override
  String resultsDuration(int minutes) {
    return '~$minutes min';
  }

  @override
  String resultsCrowd(String level) {
    return '$level Crowd';
  }

  @override
  String resultsBoardingSource(String source) {
    return 'Boarding estimate · $source';
  }

  @override
  String detailsBoardingAt(String date, String time) {
    return 'Scheduled boarding: $date · $time';
  }

  @override
  String detailsArrivalAt(String date, String time) {
    return 'Scheduled arrival: $date · $time';
  }

  @override
  String detailsDuration(int minutes) {
    return '$minutes min · selected segment';
  }

  @override
  String detailsBoardHere(String time) {
    return 'Board here · $time';
  }

  @override
  String detailsAlightHere(String time) {
    return 'Alight here · $time';
  }

  @override
  String detailsScheduledStop(String time) {
    return 'Scheduled $time';
  }

  @override
  String detailsNextStop(String name) {
    return 'Next itinerary stop: $name';
  }

  @override
  String get resultsSourceDated => 'Dated timetable';

  @override
  String get resultsSourceRoad => 'Road progress + timetable (low confidence)';

  @override
  String get resultsSourceBoarding => 'GPS at boarding stop';

  @override
  String get resultsSourceInterval =>
      'Timetable interval from GPS-observed stop';

  @override
  String get evidenceRecheckSummary => 'Unresolved barrier - needs recheck';

  @override
  String get evidenceBarrierSummary =>
      'Barrier reported - review before travel';

  @override
  String get evidencePositiveSummary => 'Positive observation - view details';

  @override
  String get evidenceUnknownSummary => 'Unknown - no current observation';

  @override
  String get evidenceTimeUnknown => 'Unknown - observation time unavailable';

  @override
  String get evidenceExpired => 'Unknown — latest observation expired';

  @override
  String get evidenceRecheckUnknown =>
      'Unresolved barrier — needs recheck; current condition unknown';

  @override
  String get evidenceConditionUnknown =>
      'Unknown — condition could not be determined';

  @override
  String get evidenceBarrierConfirmed =>
      'Barrier — community-confirmed observation';

  @override
  String get evidencePositiveConfirmed =>
      'Positive — community-confirmed observation';

  @override
  String get evidenceBarrierUnverified =>
      'Barrier reported — verification unknown';

  @override
  String get evidencePositiveUnverified =>
      'Positive reported — verification unknown';

  @override
  String get evidenceNoConfirmationTime => 'Confirmation time: Unknown';

  @override
  String get evidenceVehicleSection => 'Vehicle ramp conditions';

  @override
  String get evidenceBoardingSection => 'Boarding stop conditions';

  @override
  String get evidenceDestinationSection => 'Destination stop conditions';

  @override
  String get evidenceAssistanceSection => 'Driver assistance observations';

  @override
  String get evidenceDisclosure =>
      'Community observations describe specific conditions; they do not verify the entire journey.';

  @override
  String get evidenceEmpty => 'Unknown — no observation available';

  @override
  String get evidenceMember => 'Community member';

  @override
  String get rampWorkingObserved => 'Working observed';

  @override
  String get rampBrokenUnresolved => 'Broken reported - unresolved warning';

  @override
  String get rampNewCheck => 'Unknown - a new check is required';

  @override
  String get rampEquipped => 'Equipped';

  @override
  String get rampNotListed => 'Not listed';

  @override
  String get rampTitle => 'Vehicle ramp';

  @override
  String get rampOperatorSource => 'Operator observation';

  @override
  String get rampBarrierDisclosure =>
      'A working observation does not resolve existing community barriers.';

  @override
  String get mapMissingCoordinates =>
      'Map unavailable · stop coordinates have not been reviewed. Use the stop list.';

  @override
  String get mapCurrentBus => 'Current bus location';

  @override
  String get mapNoRoadGeometry =>
      'Stop locations · road route geometry unavailable';

  @override
  String get mapTileRetry =>
      'Map tiles unavailable · retry or use the stop list';

  @override
  String get timetableUnassigned => 'Published timetable • vehicle unassigned';

  @override
  String get timetableUnknownDisclosure =>
      'Times may change. Vehicle registration, accessibility and live location are unknown. Driver assistance is unavailable until an authorized vehicle is connected.';

  @override
  String evidenceCheckedAt(String time) {
    return 'Last checked: $time';
  }

  @override
  String evidenceRecheckedAt(String time, String name) {
    return 'Last recheck: $time by $name. Unique confirmations unchanged.';
  }

  @override
  String evidenceDueAt(String time) {
    return 'Recheck due: $time';
  }

  @override
  String evidenceExpiresAt(String time) {
    return 'Observation expires: $time';
  }

  @override
  String evidenceReportedAt(String time) {
    return 'Reported at: $time';
  }

  @override
  String evidenceConfirmedAt(String time) {
    return 'Last confirmation recorded at: $time';
  }

  @override
  String evidenceReporter(String name) {
    return 'Reported by: $name';
  }

  @override
  String evidenceConfirmers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Confirmed by: $count community members',
      one: 'Confirmed by: 1 community member',
    );
    return '$_temp0';
  }

  @override
  String rampCapability(String capability) {
    return 'Ramp capability: $capability';
  }

  @override
  String rampCheckedAge(String age) {
    return 'Ramp last checked: $age';
  }

  @override
  String rampSource(String source) {
    return 'Ramp observation source: $source';
  }

  @override
  String rampRecordedAt(String time) {
    return 'Check recorded: $time';
  }

  @override
  String mapUpdatedAt(String time) {
    return 'Location updated: $time';
  }

  @override
  String timetableSource(String source) {
    return 'Source: $source';
  }

  @override
  String get reportSignInChange => 'Sign in before changing a shared report.';

  @override
  String get reportChangeUnconfirmed =>
      'Change is not confirmed. Check your connection and sign-in, then retry or refresh the shared report.';

  @override
  String get reportCopied => 'Alert text copied to clipboard!';

  @override
  String get reportCopyFailed => 'Could not copy the alert. Please retry.';

  @override
  String get reportImageUnavailable => 'Image preview unavailable';

  @override
  String get reportDetailsTitle => 'Report Details';

  @override
  String get reportRemoved =>
      'Shared report unavailable or removed. Reopen the feed to refresh.';

  @override
  String get reportShare => 'Share alert';

  @override
  String get reportStaleUpdates =>
      'Shared updates unavailable. Showing the last received observation; refresh before acting.';

  @override
  String get reportSignInActions =>
      'Sign in to confirm, flag or resolve shared reports.';

  @override
  String get reportResolutionDisclosure =>
      'Resolution is the author\'s recorded observation; it does not independently verify a repair.';

  @override
  String get reportResolutionUnknown => 'Resolution time: Unknown';

  @override
  String get reportResolvedTitle => 'Condition Resolved';

  @override
  String get reportResolvedHelp =>
      'The author recorded this condition as resolved.';

  @override
  String get reportObservationUnknown => 'Observation time unknown';

  @override
  String get reportUnknownHelp =>
      'The observation date is unavailable. Current condition cannot be confirmed.';

  @override
  String get reportConfirmedTitle => 'Community-confirmed observation';

  @override
  String get reportActiveTitle => 'Active Transit Alert';

  @override
  String get reportActiveHelp =>
      'Reported by a commuter. Review the observation time and current evidence.';

  @override
  String get reportExpiredTitle => 'Past Report (Expired)';

  @override
  String get reportExpiredHelp =>
      'This observation has expired; it does not establish the current condition.';

  @override
  String get reportYours => 'YOUR REPORT';

  @override
  String get reportBus => 'BUS';

  @override
  String get reportStation => 'STATION';

  @override
  String get reportHighSeverity => 'High Severity';

  @override
  String get reportMinorSeverity => 'Minor Issue';

  @override
  String get reportModerateSeverity => 'Moderate';

  @override
  String get reportConditionDetails => 'Reported Condition Details';

  @override
  String get reportRiderNote => 'Rider Note:';

  @override
  String get reportPhotoEvidence => 'Attached Photo Evidence';

  @override
  String get reportEnlarge => 'Tap to enlarge';

  @override
  String get reportPhotoUnavailable => 'Photo unavailable';

  @override
  String get reportMetrics => 'Community Trust & Verification Metrics';

  @override
  String get reportRecheckDisclosure =>
      'Rechecks are dated observations; unique confirmations are unchanged.';

  @override
  String get reportVoteHeading => 'Vote Report Accuracy';

  @override
  String get reportRecheckAction => 'Recheck condition';

  @override
  String get reportFixed => 'Condition Marked Fixed';

  @override
  String get reportResolveAction => 'Mark Condition as Fixed / Resolved';

  @override
  String get reportRampCategory => 'Ramp & Access';

  @override
  String get reportLiftCategory => 'Elevator / Lift';

  @override
  String get reportCrowdingCategory => 'Crowding';

  @override
  String get reportCleanCategory => 'Cleanliness';

  @override
  String get reportSafetyCategory => 'Safety Hazard';

  @override
  String get deliveryTitle => 'Report delivery';

  @override
  String get deliveryStatus => 'Publication status';

  @override
  String get deliveryDraftUnavailable => 'Draft unavailable';

  @override
  String get deliveryPublished => 'Published';

  @override
  String get deliveryPending => 'Pending upload';

  @override
  String get deliveryFailed => 'Failed';

  @override
  String get deliveryPublicHelp =>
      'Your report is available to other commuters.';

  @override
  String get deliveryRemovedHelp =>
      'This draft was removed, expired or belongs to another account. Publication has not been confirmed.';

  @override
  String get deliveryPendingHelp =>
      'Saved on this device. Publication has not been confirmed.';

  @override
  String get deliveryLocalUnavailable => 'Local draft unavailable';

  @override
  String get deliveryObservation => 'Your observation';

  @override
  String get deliveryTarget => 'Location / Vehicle';

  @override
  String get deliveryCondition => 'Condition reported';

  @override
  String get deliveryPhoto => 'Attached photo';

  @override
  String get deliveryPhotoUnavailable => 'Photo preview unavailable';

  @override
  String get deliveryUploading => 'Uploading…';

  @override
  String get deliveryRetry => 'Retry upload';

  @override
  String get deliveryRemoveDevice => 'Remove draft from this device';

  @override
  String get deliveryAboutDrafts => 'About local drafts';

  @override
  String get deliveryDraftExpiry =>
      'Drafts expire after 7 days and are removed on sign-out/account change.';

  @override
  String get deliveryViewFeed => 'View in Community Feed';

  @override
  String get deliveryHome => 'Back to Home';

  @override
  String get deliverySaveFailed =>
      'Could not save the upload status. Please retry.';

  @override
  String get deliveryRemoveQuestion => 'Remove local draft?';

  @override
  String get deliveryRemoveHelp =>
      'Stops future retries and removes the local note/photo. A request already sent may still complete. This does not delete a public report or an uploaded photo.';

  @override
  String get deliveryKeep => 'Keep draft';

  @override
  String get deliveryRemove => 'Remove draft';

  @override
  String get deliveryRemoveFailed =>
      'Local removal could not be saved. Please retry.';

  @override
  String get deliveryUnknownTime =>
      'Observation time unknown. Create a new report before uploading.';

  @override
  String get deliveryWaiting =>
      'Waiting for a connection. This report is not confirmed as published.';

  @override
  String get deliveryUploadFailed =>
      'Upload failed. Check your sign-in, photo and service access, then retry.';

  @override
  String get reportAlreadySaved => 'This action was already recorded.';

  @override
  String get reportWaitRecheck =>
      'Recheck not saved. Wait 30 minutes after the latest check, then retry.';

  @override
  String get reportChangeSaved =>
      'Change saved. Shared details will refresh when connected.';

  @override
  String get reportConfirmationSaved =>
      'Confirmation saved to the shared report.';

  @override
  String get reportRecheckSaved =>
      'Recheck saved. Unique confirmations and points are unchanged.';

  @override
  String get reportFlagSaved => 'Flag saved to the shared report.';

  @override
  String get reportFlagHiddenLegacy =>
      'Flag saved. Report hidden after three independent flags.';

  @override
  String get reportResolutionSaved => 'Resolution saved to the shared report.';

  @override
  String reportShareText(String title, String target) {
    return 'AccessTransit Alert: $title at $target. Check the observation in AccessTransit.';
  }

  @override
  String reportResolvedBy(String name) {
    return 'Resolved by: $name';
  }

  @override
  String reportResolvedAt(String date, String time) {
    return 'Resolved at: $date, $time';
  }

  @override
  String reportHiddenHelp(int threshold) {
    return 'This report is hidden after $threshold independent inaccuracy flags. This does not prove the condition was false.';
  }

  @override
  String reportRecheckAge(String age) {
    return 'Last checked $age. Current condition unknown; no repair recorded.';
  }

  @override
  String reportConfirmedRiders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Confirmed by $count fellow riders.',
      one: 'Confirmed by 1 fellow rider.',
    );
    return '$_temp0';
  }

  @override
  String reportTransitVehicle(String name) {
    return 'Transit Vehicle • $name';
  }

  @override
  String reportTransitStation(String name) {
    return 'Transit Station • $name';
  }

  @override
  String reportUniqueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Unique confirmations: $count riders',
      one: 'Unique confirmations: 1 rider',
    );
    return '$_temp0';
  }

  @override
  String reportFlagCount(int count, int threshold) {
    return 'Inaccuracy flags: $count / $threshold (Report hidden at $threshold independent flags)';
  }

  @override
  String reportOriginally(String age) {
    return 'Originally reported: $age';
  }

  @override
  String reportLastRecheck(String age, String name) {
    return 'Last recheck: $age by $name';
  }

  @override
  String reportLastConfirmed(String age) {
    return 'Last confirmed: $age';
  }

  @override
  String reportLegacyVoteHelp(int threshold) {
    return 'Confirm only what you observed. Previous confirmers can recheck the same condition 30 minutes after the latest check; unique votes and points do not increase. If the condition changed, submit a new report. $threshold independent flags hide a report.';
  }

  @override
  String reportTrueCount(int count) {
    return 'True Flag ($count)';
  }

  @override
  String reportFalseCount(int count, int threshold) {
    return 'False Flag ($count/$threshold)';
  }

  @override
  String reportFalseRecorded(int count, int threshold) {
    return 'False ($count/$threshold)';
  }

  @override
  String deliveryCooldownAt(String time) {
    return 'Same-issue cooldown. Retry after $time (UTC). Your draft is saved.';
  }

  @override
  String get formPhotoFailed =>
      'Could not attach the photo. Check permission and try again.';

  @override
  String get formSubmitFailed =>
      'Report submission is not confirmed. Check your sign-in and connection, then retry.';

  @override
  String get formSignIn => 'Please sign in before publishing a report.';

  @override
  String get formAccountChanged => 'Account changed. Review the report again.';

  @override
  String formReviewTarget(String target) {
    return 'Location / Vehicle: $target';
  }

  @override
  String formReviewCondition(String condition) {
    return 'Condition: $condition';
  }

  @override
  String formReviewCrowding(String level) {
    return 'Crowding: $level';
  }

  @override
  String formReviewNote(String note) {
    return 'Note: $note';
  }

  @override
  String formBusRoute(String number) {
    return 'Bus $number';
  }

  @override
  String formVehicleRoute(String vehicle, String number) {
    return '$vehicle (Route $number)';
  }

  @override
  String formBusRamp(String vehicle) {
    return '$vehicle ♿ (Ramp)';
  }

  @override
  String get formLowCrowd => 'Low Crowd';

  @override
  String get formPlentyOfRoomWheelchairBay =>
      'Plenty of room & wheelchair bay free';

  @override
  String get formModerate => 'Moderate';

  @override
  String get formSeatsFullStandingRoomAvailable =>
      'Seats full, standing room available';

  @override
  String get formCrowdedPacked => 'Crowded / Packed';

  @override
  String get formWheelchairSpaceOrAisleBlocked =>
      'Wheelchair space or aisle blocked';

  @override
  String get formRampBay => 'Ramp & Bay';

  @override
  String get formRampWorking => 'Ramp Working';

  @override
  String get formDriverAssistedDeployedRamp =>
      'Driver assisted & deployed ramp';

  @override
  String get formRampBroken => 'Ramp Broken';

  @override
  String get formMotorJammedOrRampBroken => 'Motor jammed or ramp broken';

  @override
  String get formRampDenied => 'Ramp Denied';

  @override
  String get formDriverDidNotLowerOr => 'Driver did not lower or deploy';

  @override
  String get formBayBlocked => 'Bay Blocked';

  @override
  String get formBlockedByBagsOrStanding => 'Blocked by bags or standing crowd';

  @override
  String get formSeats => 'Seats';

  @override
  String get formSeatsFree => 'Seats Free';

  @override
  String get formElderlyDisabledSeatsFree => 'Elderly / disabled seats free';

  @override
  String get formSeatsOccupied => 'Seats Occupied';

  @override
  String get formOthersNotGivingUpSeats => 'Others not giving up seats';

  @override
  String get formSeatBroken => 'Seat Broken';

  @override
  String get formDamagedOrLooseSeating => 'Damaged or loose seating';

  @override
  String get formSafetyClean => 'Safety & Clean';

  @override
  String get formCleanSafe => 'Clean & Safe';

  @override
  String get formVehicleWellMaintained => 'Vehicle well-maintained';

  @override
  String get formDirtyOdor => 'Dirty / Odor';

  @override
  String get formSpillOrUnpleasantSmell => 'Spill or unpleasant smell';

  @override
  String get formRailBroken => 'Rail Broken';

  @override
  String get formGrabRailsOrStrapsLoose => 'Grab rails or straps loose';

  @override
  String get formRecklessDriving => 'Reckless Driving';

  @override
  String get formSuddenJerksUnsafeRide => 'Sudden jerks, unsafe ride';

  @override
  String get formElevator => 'Elevator';

  @override
  String get formElevatorWorking => 'Elevator Working';

  @override
  String get formOperatingSmoothlyAccessible =>
      'Operating smoothly & accessible';

  @override
  String get formOutOfService => 'Out of Service';

  @override
  String get formElevatorShutDownOrRepair => 'Elevator shut down or repair';

  @override
  String get formDoorButtonFault => 'Door / Button Fault';

  @override
  String get formDoorsStuckOrButtonsBroken => 'Doors stuck or buttons broken';

  @override
  String get formRampPath => 'Ramp & Path';

  @override
  String get formRampClear => 'Ramp Clear';

  @override
  String get formSmoothWheelchairSlope => 'Smooth wheelchair slope';

  @override
  String get formPathBlocked => 'Path Blocked';

  @override
  String get formVendorsOrParkedVehicles => 'Vendors or parked vehicles';

  @override
  String get formDamagedSteep => 'Damaged / Steep';

  @override
  String get formPavementCrackedOrSteepSlope =>
      'Pavement cracked or steep slope';

  @override
  String get formTactileTiles => 'Tactile Tiles';

  @override
  String get formTilesIntact => 'Tiles Intact';

  @override
  String get formGuidedTactileTilesClear => 'Guided tactile tiles clear';

  @override
  String get formTilesBroken => 'Tiles Broken';

  @override
  String get formLooseTilesCausingTripHazard =>
      'Loose tiles causing trip hazard';

  @override
  String get formUnsafeEdgeGap => 'Unsafe Edge Gap';

  @override
  String get formExcessiveGapBetweenCurbBus =>
      'Excessive gap between curb & bus';

  @override
  String get formShelterLight => 'Shelter & Light';

  @override
  String get formShelterGood => 'Shelter Good';

  @override
  String get formRainProtectionSeatingIntact =>
      'Rain protection & seating intact';

  @override
  String get formRoofDamaged => 'Roof Damaged';

  @override
  String get formDamagedRoofOrBrokenBenches => 'Damaged roof or broken benches';

  @override
  String get formDarkUnsafe => 'Dark / Unsafe';

  @override
  String get formPoorNightLightingInWalkway => 'Poor night lighting in walkway';

  @override
  String get formPhotoAttachedSuccessfully => 'Photo attached successfully!';

  @override
  String get formAttachEvidencePhoto => 'Attach Evidence Photo';

  @override
  String get formHelpVerifyConditionForCommuters =>
      'Help commuters with disabilities understand the condition';

  @override
  String get formTakePhoto => 'Take Photo';

  @override
  String get formFromGallery => 'From Gallery';

  @override
  String get formSelectTheExactBusOr =>
      'Select the exact bus or stop you observed.';

  @override
  String get formChooseTheConditionAndCrowding =>
      'Choose the condition and crowding level you observed.';

  @override
  String get formChooseTheConditionYouObserved =>
      'Choose the condition you observed.';

  @override
  String get formConfirmYourObservation => 'Confirm your observation';

  @override
  String get formEvidence1PhotoAttached => 'Evidence: 1 photo attached';

  @override
  String get formYourObservationNoteAndAttached =>
      'Your observation, note and attached photo will be public after publication. Avoid faces, identifying details and sensitive personal information. Submit only photos you have permission to share.';

  @override
  String get formPendingDraftsStayOnThis =>
      'Pending drafts stay on this device for up to 7 days and are removed on sign-out/account change. You can remove them from Your uploads. Removing a draft cannot recall a request already sent or delete a public report/photo.';

  @override
  String get formAndroidDraftsUseEncryptedPrivate =>
      'Android drafts use encrypted private storage. On other platforms drafts last only for this app session.';

  @override
  String get formEditReport => 'Edit report';

  @override
  String get formConfirmAndSubmit => 'Confirm and submit';

  @override
  String get formCommunityReport => 'Community Report';

  @override
  String get formHelpAccessibleTransitCommutersIn =>
      'Share your observations with fellow commuters';

  @override
  String get formSelectBusRoute => 'Select Bus Route';

  @override
  String get formWhichRouteAreYouTraveling =>
      'Which route are you traveling on or waiting for?';

  @override
  String get formWhereIsTheIssue => 'Where is the Issue?';

  @override
  String get formChooseWhetherYouAreInside =>
      'Choose whether you are inside a vehicle or at a station';

  @override
  String get formVehicleAccessibilityCondition =>
      'Vehicle Accessibility Condition';

  @override
  String get formStationAccessibilityCondition =>
      'Station Accessibility Condition';

  @override
  String get formReportCrowdingLevelAndWheelchair =>
      'Report crowding level and wheelchair access inside the bus';

  @override
  String get formReportElevatorRampAndPlatform =>
      'Report elevator, ramp, and platform conditions at the stop';

  @override
  String get formEvidencePhotoOptional => 'Evidence Photo (Optional)';

  @override
  String get formTakeAPhotoOrUpload =>
      'Take a photo or choose one from the gallery to document the condition';

  @override
  String get formAdditionalNoteOptional => 'Additional Note (Optional)';

  @override
  String get formAddHelpfulDetailsForFellow =>
      'Add helpful details for fellow wheelchair or elderly riders';

  @override
  String get formEGRampWasLowered =>
      'e.g. Ramp was lowered but driver needed bystander help';

  @override
  String get formSubmittingReport => 'Submitting Report…';

  @override
  String get formReviewAndSubmitReport => 'Review and submit report';

  @override
  String get formSelectARouteOptional => 'Select a route (optional)';

  @override
  String get formOnABus => 'On a Bus';

  @override
  String get formInsideTheVehicle => 'Inside the vehicle';

  @override
  String get formAtABusStop => 'At a Bus Stop';

  @override
  String get formStationPlatform => 'Station & platform';

  @override
  String get formSelectSpecificBusLicensePlate =>
      'Select Specific Bus / License Plate';

  @override
  String get formSelectStopAlongThisRoute => 'Select Stop along this route';

  @override
  String get formCrowdingLevel => 'Crowding Level';

  @override
  String get formChooseTheCrowdingLevelYou =>
      'Choose the crowding level you observed.';

  @override
  String get formAccessibilityIssueCategory => 'Accessibility Issue Category';

  @override
  String get formStationFacilityCategory => 'Station Facility Category';

  @override
  String get formPhotoUploadsAreCurrentlyUnavailable =>
      'Photo uploads are currently unavailable. You can submit your report without a photo.';

  @override
  String get formPhotoAttached => 'Photo Attached';

  @override
  String get formWillBeUploadedWithReport => 'Will be uploaded with report';

  @override
  String get formRemovePhoto => 'Remove photo';

  @override
  String get formAddPhoto => 'Add Photo';

  @override
  String get formTapToTakePhotoOr => 'Tap to take photo or choose from device';

  @override
  String get formNotSelected => 'Not selected';

  @override
  String get formReportSummary => 'Report Summary';

  @override
  String get formLocationVehicle => 'Location / Vehicle';

  @override
  String get formAccessibilityStatus => 'Accessibility Status';

  @override
  String get formPhotoEvidence => 'Photo Evidence';

  @override
  String get form1PhotoAttached => '1 photo attached';

  @override
  String get communityHubTitle => 'Community Hub';

  @override
  String get communitySubtitle =>
      'Community accessibility observations from fellow riders';

  @override
  String get communityReportAction => 'Report Issue';

  @override
  String get communityPastReports => 'Resolved & Past Reports';

  @override
  String get communityNoOwnReports => 'No Reports Yet';

  @override
  String get communityEmptyTitle => 'No current reports';

  @override
  String get communityOwnEmptyHelp =>
      'Reports you submit about wheelchair access, crowding, or lifts will show up here.';

  @override
  String get communityEmptyHelp =>
      'No current reports are available in this feed. This does not establish that conditions are accessible or safe.';

  @override
  String get communitySubmitReport => 'Submit a Condition Report';

  @override
  String get communityUpdatesTab => 'Live Updates';

  @override
  String get communityMyReportsTab => 'My Reports';

  @override
  String get communityContributor => 'Community Contributor';

  @override
  String get communityPhoto => 'Photo';

  @override
  String get communityRecheckHelp =>
      'Recheck the same observed condition after 30 minutes since the latest check. No extra votes or points. Report changed conditions separately.';

  @override
  String get communityActiveBadge => 'Active';

  @override
  String get communityConfirmedBadge => 'Community confirmed';

  @override
  String get communityResolvedBadge => 'Resolved';

  @override
  String get communityPastBadge => 'Past';

  @override
  String get communityUnavailable =>
      'Community reports unavailable. Reconnect and retry.';

  @override
  String get communityRetry => 'Retry reports';

  @override
  String get communityOwnSignIn =>
      'Sign in to see your reports and local uploads.';

  @override
  String get outboxTitle => 'Your uploads';

  @override
  String get outboxHelp =>
      'Drafts expire after 7 days. Open an upload to retry or remove it. Sign-out removes local drafts.';

  @override
  String communityStationTarget(String id) {
    return 'Station $id';
  }

  @override
  String communityBusTarget(String id) {
    return 'Bus $id';
  }

  @override
  String communityRouteTarget(String number) {
    return 'Bus Route $number';
  }

  @override
  String communityContributionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count shared reports currently listed. Rewards are not calculated here.',
      one: '1 shared report currently listed. Rewards are not calculated here.',
    );
    return '$_temp0';
  }

  @override
  String communityChecked(String freshness, String age) {
    return '$freshness · Last checked: $age';
  }

  @override
  String communityTrueCount(int count) {
    return 'True: $count';
  }

  @override
  String communityFalseCount(int count, int threshold) {
    return 'False: $count/$threshold';
  }

  @override
  String get helpIntro => 'Using AccessTransit';

  @override
  String get helpSearchTitle => 'Searching for a bus';

  @override
  String get helpSearchBody =>
      'Choose your boarding stop, destination and boarding time within the next 24 hours. Search starts with your saved accessibility preferences. Changes made for a search apply only to that search; save account-wide defaults in Settings.';

  @override
  String get helpSaveTitle => 'What does Save Trip do?';

  @override
  String get helpSaveBody =>
      'Open a result to see Bus Details and the selected stop segment. Saving is optional. It bookmarks the selection so you can reopen its details from saved trips; it does not book a seat or start a journey. Check refreshed times and cancellation notices when reopening.';

  @override
  String get helpLocationTitle => 'Using My Location';

  @override
  String get helpLocationBody =>
      'Allow location access when requested to find nearby boarding stops. Check the selected stop and direction before searching. Nearby does not establish a step-free walking route. If location is unavailable or permission is denied, choose a stop manually.';

  @override
  String get helpLiveTitle => 'Timetable and live location';

  @override
  String get helpLiveBody =>
      'A timetable is a plan, not proof that a bus has started. Future or unstarted runs show timetable information. Live position requires a started matching run and fresh GPS. If location is stale or unavailable, check the last-update wording. Estimates and arrival times can change.';

  @override
  String get helpReportsTitle => 'Reports and pending uploads';

  @override
  String get helpReportsBody =>
      'Report the exact bus or stop and what you observed. A local draft is private and is not a published report. Open Your uploads under My Reports to retry or remove it. Drafts expire after 7 days and are removed on sign-out. Avoid private information in public notes and photos.';

  @override
  String get helpVotesTitle => 'Voting and community disputes';

  @override
  String get helpVotesBody =>
      'Authors cannot vote True or False on their own reports. Vote only from your observations and give a reason for False. Under policy v2, five eligible other users\' False votes hide a report and apply its recorded points penalty and strike. This is a community dispute, not proof of a false report. Authors can use the report review and appeal screens.';

  @override
  String get helpAssistanceTitle => 'Boarding assistance';

  @override
  String get helpAssistanceBody =>
      'Assistance is optional in Bus Details. Check the bus, run and boarding stop. Submitted means the request was recorded; accepted means the assigned driver accepted it. A saved trip or a sent request does not guarantee assistance. Check the latest request status, including decline, cancellation or expiry.';

  @override
  String get helpAccessTitle => 'Account access and review';

  @override
  String get helpAccessBody =>
      'If access is restricted, read the displayed reason and expiry and use the available appeal action. An appeal does not automatically lift a restriction. Permanent bans require administrator review. Self-service account deletion is not available in Profile; reviewed administrator deletion is a separate process.';

  @override
  String get rewardsTitle => 'Rewards & Contributions';

  @override
  String get rewardsMine => 'My Contributions';

  @override
  String get rewardsSettingsSoon => 'Settings will be available soon.';

  @override
  String get rewardsReports => 'Reports Submitted';

  @override
  String get rewardsConfirmations => 'Recorded Confirmations';

  @override
  String get rewardsViewCard => 'View Membership Card';

  @override
  String get rewardsTotal => 'Total Points';

  @override
  String get rewardsGold => 'Gold Contributor';

  @override
  String get rewardsSilver => 'Silver Contributor';

  @override
  String get rewardsBronze => 'Bronze Contributor';

  @override
  String get memberGold => 'Gold Member';

  @override
  String get memberSilver => 'Silver Member';

  @override
  String get memberBronze => 'Bronze Member';

  @override
  String get memberBack => 'Back to Rewards';

  @override
  String get memberTitle => 'Digital Membership Card';

  @override
  String get memberPointsLabel => 'Contribution points';

  @override
  String get memberNoCash => 'Points have no cash or voucher value';

  @override
  String get memberNoRedemption => 'Redemption unavailable';

  @override
  String get memberAvailability => 'Reward availability';

  @override
  String get memberNoVouchers =>
      'Partner discounts and vouchers are not available.';

  @override
  String get memberBenefits => 'Member Benefits';

  @override
  String get memberNoPriority =>
      'Membership does not include priority support or guaranteed access.';

  @override
  String get memberRecognition => 'Community Recognition';

  @override
  String get memberLedgerNotice =>
      'Contribution points follow the recorded reward policy. They do not verify accessibility.';

  @override
  String get rewardsLegacyNotice =>
      'Historical policy: points update after administrator review and may take time. Published report: 10 points; unique confirmation: 5 points. Removed votes and hidden/deleted reports reverse credits. Points do not verify accessibility and have no cash value.';

  @override
  String rewardsLevel(String level) {
    return 'Level: $level';
  }

  @override
  String memberPointCount(int count) {
    return '$count Points';
  }

  @override
  String memberIdentity(String id) {
    return 'ID: $id';
  }

  @override
  String get assistFormUnknown =>
      'The assistance bus or stop is unknown. Select a journey with an exact stop first.';

  @override
  String get assistFormSelect =>
      'Please select at least one assistance option.';

  @override
  String get assistFormTarget =>
      'Choose the exact bus and stop from your journey before requesting assistance.';

  @override
  String get assistFormWrongStop =>
      'This stop could not be verified on the selected bus. Return to your journey and choose the correct target.';

  @override
  String get assistFormConfirm => 'Confirm assistance target';

  @override
  String get assistFormEdit => 'Edit request';

  @override
  String get assistFormSendConfirm => 'Confirm and send';

  @override
  String get assistFormSignIn =>
      'Please sign in before sending an assistance request.';

  @override
  String get assistFormPrepareError =>
      'Could not prepare the request. Check your sign-in and device storage, then try again.';

  @override
  String get assistFormTitle => 'Request Assistance';

  @override
  String get assistFormRamp => 'Deploy Ramp';

  @override
  String get assistFormTime => 'Extra Time';

  @override
  String get assistFormBoarding => 'Boarding Help';

  @override
  String get assistFormAlighting => 'Getting Off Help';

  @override
  String get assistFormSend => 'Send Request';

  @override
  String get assistFormAckHelp =>
      'Assistance is confirmed only after the driver acknowledges your request.';

  @override
  String get assistFormEtaUnknown => 'ETA unknown';

  @override
  String get assistFormMinutes => 'MIN (est.)';

  @override
  String get assistFormAccountChanged =>
      'Your account changed during review. Review the request again before sending.';

  @override
  String assistFormBoardAt(String stop) {
    return 'Boarding at $stop';
  }

  @override
  String assistFormAlightAt(String stop) {
    return 'Getting off at $stop';
  }

  @override
  String assistFormBusRoute(String bus, String route) {
    return '$bus (Route $route)';
  }

  @override
  String assistFormArrival(String bus, int minutes) {
    return '$bus - estimated arrival in $minutes mins';
  }

  @override
  String get assistReceiptTitle => 'Assistance request';

  @override
  String get assistReceiptOwner =>
      'Sign in with the account that created this request to view its status.';

  @override
  String get assistReceiptSent => 'Sent to shared service';

  @override
  String get assistReceiptUnknown => 'Request status unknown';

  @override
  String get assistReceiptPendingHint =>
      'Saving the request does not mean the driver has accepted it.';

  @override
  String get assistReceiptAcceptedHint =>
      'The driver has acknowledged the request. Assistance has not been marked completed.';

  @override
  String get assistReceiptDelivery => 'Request delivery';

  @override
  String get assistReceiptOwn => 'Your assistance request';

  @override
  String get assistReceiptSupport => 'Support requested';

  @override
  String get assistReceiptUnspecified => 'Not specified';

  @override
  String get assistReceiptDriver => 'Driver response';

  @override
  String get assistReceiptUnconfirmed =>
      'Driver acknowledgement is not confirmed.';

  @override
  String get assistReceiptStale =>
      'Live status updates are unavailable. Displayed driver status is the last received status.';

  @override
  String get assistReceiptSending => 'Sending?';

  @override
  String get assistReceiptRetry => 'Retry upload';

  @override
  String get assistReceiptCancelling => 'Cancelling?';

  @override
  String get assistReceiptCancel => 'Cancel request';

  @override
  String get assistReceiptRetryError =>
      'Could not save the retry on this device. Please try again.';

  @override
  String get assistReceiptCancelError =>
      'Cancellation is not confirmed. Check your connection and try again.';

  @override
  String get assistReceiptPendingUpload => 'Pending upload';

  @override
  String get assistReceiptDeliverySent => 'Sent';

  @override
  String get assistReceiptFailed => 'Failed';

  @override
  String get assistReceiptExpired => 'Retry expired';

  @override
  String get assistReceiptOld =>
      'Automatic retries stopped because this request is old. Check the driver status; delivery may still be unconfirmed.';

  @override
  String get assistReceiptDeliveryError =>
      'Delivery is not confirmed. Retry when connected; keep checking the driver status.';

  @override
  String get assistReceiptSendError =>
      'The request could not be sent. Check your sign-in and target, then retry.';

  @override
  String get assistReceiptRestoreError =>
      'Some saved assistance requests could not be restored. Check your shared request history.';

  @override
  String get assistReceiptSaveError =>
      'The latest request status could not be saved on this device. Check the shared request history.';

  @override
  String get assistReceiptHistory => 'Your assistance requests';

  @override
  String get assistReceiptHistoryStale =>
      'Shared request updates are unavailable. Saved receipts may be out of date.';

  @override
  String get assistReceiptError =>
      'Request status is unavailable. Check your connection and account, then retry.';

  @override
  String assistReceiptRoute(String route) {
    return 'Route $route';
  }

  @override
  String assistReceiptSummary(String route, String stop) {
    return 'Route $route · $stop';
  }

  @override
  String get sharedCatalogueDemo =>
      'DEMONSTRATION: Sample transit data. Shared reporting, assistance and journeys are disabled.';

  @override
  String get sharedCatalogueSaved =>
      'Saved transit data. Refresh to check for updates; timetables and availability may have changed.';

  @override
  String get sharedCatalogueUnavailable =>
      'Transit data unavailable. Connect and retry; no sample services are substituted.';

  @override
  String get sharedCatalogueEmpty =>
      'No shared transit data available for this catalogue. Please retry later.';

  @override
  String get sharedRefresh => 'Refresh';

  @override
  String get sharedRefreshing => 'Refreshing…';

  @override
  String get sharedSavingStatus => 'Saving status…';

  @override
  String get sharedOperatorStatusError =>
      'Status update was not confirmed. Check your connection, operator approval and bus assignment, then retry.';

  @override
  String get sharedAdminAccess => 'Administrator access';

  @override
  String get sharedAdminChecking => 'Checking administrator access...';

  @override
  String get sharedAdminRequired =>
      'An administrator claim and an online connection are required. A profile role does not grant access.';

  @override
  String get sharedCheckAgain => 'Check again';

  @override
  String get sharedSignIn => 'Sign in';

  @override
  String get sharedSavedJourney => 'Saved journey';

  @override
  String get sharedJourneyUpdatesError =>
      'Saved journey updates unavailable. Check your connection and reopen Home to retry.';

  @override
  String get sharedJourneyChangeError =>
      'Journey status change is not confirmed. Retry when connected.';

  @override
  String get sharedResume => 'Resume journey';

  @override
  String get sharedComplete => 'Mark completed';

  @override
  String get sharedCancelJourney => 'Cancel saved journey';

  @override
  String get sharedSaveDisclosure =>
      'Saving keeps this selection. It does not book a seat or start a journey.';

  @override
  String get sharedSaveStatusError =>
      'Saved status unavailable. Retry to verify your bookmark.';

  @override
  String get sharedSaveError =>
      'Save change is not confirmed. Check your connection and retry.';

  @override
  String get sharedSaveOwner => 'Sign in with the account saving this trip.';

  @override
  String get sharedSaveMismatch => 'Saved trip acknowledgement did not match.';

  @override
  String get sharedSaveSignIn => 'Sign in to save this trip.';

  @override
  String get sharedSaving => 'Saving…';

  @override
  String get sharedStopAlert => 'Stop alert unavailable';

  @override
  String get sharedStopAlertHelp =>
      'Automatic stop alerts and background notifications are unavailable. Follow trip progress manually; the app will not notify you before your stop.';

  @override
  String get sharedSplashTagline =>
      'Your journey to inclusive travel begins here.';

  @override
  String get sharedLoading => 'Loading.';

  @override
  String get sharedStopsOrder => 'Stops in travel order';

  @override
  String get sharedDriverReviewHelp =>
      'Driver registration is an application for access. Review identity and operating authority before approval. Approval does not verify equipment or guarantee a service.';

  @override
  String get sharedAddStation => 'Add New Halt / Station';

  @override
  String get sharedStationName => 'Station Name';

  @override
  String get sharedStationExample => 'e.g. Bambalapitiya Junction';

  @override
  String get sharedStationId => 'Station ID (e.g. bambalapitiya_junc)';

  @override
  String get sharedTargetRoute => 'Target Bus Route';

  @override
  String get sharedInsertIndex => 'Insert Position Index (0-based)';

  @override
  String get sharedInsertHint => '1 (insert as 2nd stop)';

  @override
  String get sharedRequired => 'Required';

  @override
  String get sharedRamp => 'Ramp';

  @override
  String get sharedElevator => 'Elevator';

  @override
  String get sharedCancel => 'Cancel';

  @override
  String get sharedAddStationAction => 'Add Station';

  @override
  String get sharedStationError =>
      'Could not add the stop. Check your access and connection, then retry.';

  @override
  String get sharedLiveAccessibility => 'Live Accessibility';

  @override
  String get sharedEquipmentHelp =>
      'Equipment checks are separate from live GPS. A working report does not verify the whole journey.';

  @override
  String get sharedConditionsUnavailable =>
      'Condition updates unavailable. Working conditions are Unknown; earlier warnings are retained.';

  @override
  String get sharedRampWarning =>
      'Vehicle ramp telemetry reports a problem. Equipment-check time is Unknown; check before boarding.';

  @override
  String get sharedCommunityObservations => 'Community observations';

  @override
  String get sharedRampUnknown =>
      'Unknown — vehicle ramp warning needs checking';

  @override
  String get sharedDriverAssistance => 'Driver assistance';

  @override
  String get sharedPositiveAssistance => 'Positive assistance observation';

  @override
  String get sharedOperatorCheck => 'Operator vehicle check';

  @override
  String get sharedHideObservations => 'Hide observation details';

  @override
  String get sharedViewObservations => 'View observation details';

  @override
  String sharedVehicle(String vehicle) {
    return 'Vehicle: $vehicle';
  }

  @override
  String sharedTimetable(String time) {
    return 'Timetable: $time';
  }

  @override
  String sharedStationAdded(String name, String bus, String index) {
    return 'Stop \"$name\" added to $bus at position $index.';
  }

  @override
  String sharedBusOption(String route, String id) {
    return 'Bus $route ($id)';
  }

  @override
  String sharedBoardingElevator(String stop) {
    return 'Boarding stop elevator — $stop';
  }

  @override
  String sharedDestinationElevator(String stop) {
    return 'Destination stop elevator — $stop';
  }

  @override
  String get legacyUi0 => 'Working reported';

  @override
  String get legacyUi1 => 'Barrier reported';

  @override
  String get legacyUi2 => 'Sign in to save and resume your journey.';

  @override
  String get legacyUi3 =>
      'Journey ownership or status changed. Reopen your saved journeys.';

  @override
  String get legacyUi4 =>
      'Journey save is not confirmed. Check your connection and sign-in, then retry.';

  @override
  String get legacyUi5 => 'Vehicle not specified';

  @override
  String get legacyUi6 => 'Back';

  @override
  String get legacyUi7 => 'Confirm Journey';

  @override
  String get legacyUi8 => 'Travel schedule';

  @override
  String get legacyUi9 => 'Selected date';

  @override
  String get legacyUi10 => 'Selected time';

  @override
  String get legacyUi11 => 'First available service on selected date';

  @override
  String get legacyUi12 => 'Timetable departure';

  @override
  String get legacyUi13 => 'Estimated arrival';

  @override
  String get legacyUi14 =>
      'Some timetable intervals are missing. Times include model estimates; confirm them with the operator.';

  @override
  String get legacyUi15 => 'Estimated fare';

  @override
  String get legacyUi16 =>
      'Prototype estimate. Confirm the actual fare with the operator.';

  @override
  String get legacyUi17 => 'Fare details';

  @override
  String get legacyUi18 => 'Travel requirements';

  @override
  String get legacyUi19 =>
      'Saving a journey does not book a seat or confirm that the bus is running. Review current condition evidence.';

  @override
  String get legacyUi20 => 'Saving journey...';

  @override
  String get legacyUi21 => 'Confirm and save journey';

  @override
  String get legacyUi22 =>
      'Service unavailable. Select a shared service first.';

  @override
  String get legacyUi23 => 'This service is unavailable. Return to search.';

  @override
  String get legacyUi24 => 'Departure & Route Details';

  @override
  String get legacyUi25 =>
      'Saved location - live updates unavailable. This is not current bus movement.';

  @override
  String get legacyUi26 => 'SCHEDULE';

  @override
  String get legacyUi27 => 'SCHEDULED';

  @override
  String get legacyUi28 => 'EXPECTED ARRIVAL';

  @override
  String get legacyUi29 => 'Request Boarding Assistance';

  @override
  String get legacyUi30 => 'Route Stops Schedule & Live Progress';

  @override
  String get legacyUi31 => 'YOUR BOARDING STOP';

  @override
  String get legacyUi32 => 'BUS IS HERE NOW';

  @override
  String get legacyUi33 =>
      'Selected segment estimate; payment options unverified.';

  @override
  String get legacyUi34 => 'Unknown — no condition evidence available.';

  @override
  String get legacyUi35 => 'ACCESSIBLE VEHICLE FEATURES';

  @override
  String get legacyUi36 => 'ACCESSIBILITY WARNING';

  @override
  String get legacyUi37 => 'NOT ACCESSIBLE NOTICE';

  @override
  String get legacyUi38 => 'CONDITION UNKNOWN';

  @override
  String get legacyUi39 => 'Safety & Ride Conditions';

  @override
  String get legacyUi40 => 'Bus Crowd Level';

  @override
  String get legacyUi41 => 'Community Safety Reports';

  @override
  String get legacyUi42 => 'Review and confirm journey';

  @override
  String get legacyUi43 => 'Save to Trip Plan';

  @override
  String get legacyUi44 => 'Report Accessibility Condition';

  @override
  String get legacyUi45 => 'Unable to Load Journey';

  @override
  String get legacyUi46 => 'Loading live journey details from server';

  @override
  String get legacyUi47 => 'Loading your journey…';

  @override
  String get legacyUi48 => 'Bus has not been assigned yet.';

  @override
  String get legacyUi49 =>
      'A saved trip does not reserve a seat or guarantee bus assignment. Check the selected service status.';

  @override
  String get legacyUi50 => 'Return to Home screen';

  @override
  String get legacyUi51 => 'Close Live Navigation';

  @override
  String get legacyUi52 => 'Live Navigation';

  @override
  String get legacyUi53 => 'Back to Route Results';

  @override
  String get legacyUi54 => 'Live Tracking to';

  @override
  String get legacyUi55 => 'LIVE';

  @override
  String get legacyUi56 => 'SCHED';

  @override
  String get legacyUi57 => 'Real-time stop progression & ETA';

  @override
  String get legacyUi58 => 'Live Stops';

  @override
  String get legacyUi59 => 'YOUR STOP';

  @override
  String get legacyUi60 => 'Bus is currently here';

  @override
  String get legacyUi61 => 'Passed';

  @override
  String get legacyUi62 =>
      'Live GPS updates are unavailable. Equipment observations are shown separately below.';

  @override
  String get legacyUi63 => '● Ongoing';

  @override
  String get legacyUi64 => '● Scheduled';

  @override
  String get legacyUi65 =>
      'Tracking shows the current vehicle location; it does not confirm your scheduled run.';

  @override
  String get legacyUi66 => 'Detailed Vehicle Telemetry';

  @override
  String get legacyUi67 => 'Speed, GPS signals and raw trip data';

  @override
  String get legacyUi68 => 'Approaching';

  @override
  String get legacyUi69 => 'You Board Here';

  @override
  String get legacyUi70 => 'TIMETABLE';

  @override
  String get legacyUi71 => 'Collapse map';

  @override
  String get legacyUi72 => 'Expand map';

  @override
  String get legacyUi73 => 'Fit journey bounds';

  @override
  String get legacyUi74 => 'Focus on bus';

  @override
  String get legacyUi75 => 'Focus on my stop';

  @override
  String get legacyUi76 => 'Zoom in';

  @override
  String get legacyUi77 => 'Zoom out';

  @override
  String get legacyUi78 => 'No GPS signal';

  @override
  String get legacyUi79 => 'Signal Lost';

  @override
  String get legacyUi80 => 'En Route';

  @override
  String get legacyUi81 => 'Stopped';

  @override
  String get legacyUi82 => 'Trip Completed';

  @override
  String get legacyUi83 => 'Offline';

  @override
  String get legacyUi84 => 'Saved location - updates unavailable';

  @override
  String get legacyUi85 => 'Status: Live GPS updates receiving';

  @override
  String get legacyUi86 => 'Status: Location unavailable';

  @override
  String get legacyUi87 => 'Unavailable';

  @override
  String get legacyUi88 => 'Current Status';

  @override
  String get legacyUi89 => 'Last Updated';

  @override
  String get legacyUi90 => 'Next Stop';

  @override
  String get legacyUi91 => 'Your Destination';

  @override
  String get legacyUi92 => 'Next: ';

  @override
  String get legacyUi93 => 'Final: ';

  @override
  String get legacyUi94 => 'Request boarding or stop assistance from driver';

  @override
  String get legacyUi95 => 'Request Stop Assistance';

  @override
  String get legacyUi96 =>
      'Emergency calling unavailable. Use your phone to call for help.';

  @override
  String get legacyUi97 => 'Emergency';

  @override
  String get legacyUi98 => 'Report accessibility issue or vehicle condition';

  @override
  String get legacyUi99 =>
      'Emergency calling is unavailable in this app. Use your phone to call for help.';

  @override
  String get legacyUi100 => 'Live Per-Stop Timeline';

  @override
  String get legacyUi101 => 'Live Run';

  @override
  String get sharedCatalogueRefreshError =>
      'Could not refresh transit data. Saved data may be out of date; retry when connected.';

  @override
  String legacyFormat0(String p0) {
    return 'Bus $p0';
  }

  @override
  String legacyFormat1(String p0) {
    return 'Route $p0';
  }

  @override
  String legacyFormat2(String p0) {
    return 'Upcoming Stops ($p0)';
  }

  @override
  String legacyFormat3(String p0) {
    return 'Scheduled: $p0';
  }

  @override
  String legacyFormat4(String p0) {
    return 'Arriving in $p0 min';
  }

  @override
  String legacyFormat5(String p0) {
    return 'Destination: $p0';
  }

  @override
  String legacyFormat6(String p0, String p1) {
    return 'Live interactive map showing bus $p0 heading toward $p1';
  }

  @override
  String legacyFormat7(String p0) {
    return 'Next Stop: $p0';
  }

  @override
  String legacyFormat8(String p0, String p1, String p2, String p3) {
    return 'Bus status: $p0. Last updated: $p1. Next stop: $p2. Passenger stop: $p3.';
  }

  @override
  String legacyFormat9(String p0) {
    return 'at $p0';
  }

  @override
  String legacyFormat10(String p0) {
    return 'Scheduled: $p0';
  }

  @override
  String legacyFormat11(String p0) {
    return 'Expected: $p0';
  }

  @override
  String legacyFormat12(String p0, String p1) {
    return 'Driver Notice: $p0 (+$p1 mins)';
  }

  @override
  String legacyFormat13(String p0, String p1) {
    return 'Distance: $p0 km to $p1';
  }

  @override
  String legacyFormat14(String p0, String p1) {
    return 'Journey progress: Bus approaching next stop $p0 towards destination $p1';
  }

  @override
  String legacyFormat15(String p0) {
    return 'Notify driver you need extra time or ramp deployment at $p0.';
  }

  @override
  String legacyFormat16(String p0) {
    return 'Reached at $p0';
  }

  @override
  String legacyFormat17(String p0) {
    return 'Bus is here now (Confirmed $p0)';
  }

  @override
  String legacyFormat18(String p0, String p1) {
    return 'Est. $p0 (in about $p1 min)';
  }

  @override
  String legacyFormat19(String p0) {
    return 'Selected timetable departure: $p0 — current GPS does not confirm this scheduled run.';
  }

  @override
  String legacyFormat20(String p0) {
    return '+$p0 min late';
  }

  @override
  String legacyFormat21(String p0, String p1) {
    return 'Driver Alert: $p0 (+${p1}m)';
  }

  @override
  String legacyFormat22(String p0) {
    return 'at $p0';
  }

  @override
  String legacyFormat23(String p0) {
    return 'Passed at $p0';
  }

  @override
  String legacyFormat24(String p0, String p1) {
    return 'Sched: $p0 · Exp: $p1';
  }

  @override
  String legacyFormat25(String p0) {
    return '(+$p0 min late)';
  }

  @override
  String legacyFormat26(String p0) {
    return '$p0 crowding';
  }

  @override
  String get sharedOnTime => 'On Time';

  @override
  String get sharedSampleNotice =>
      'SAMPLE / TEST MODE — fictional vehicles, reports, equipment and GPS. Not for travel decisions.';

  @override
  String get sharedLocalNotice =>
      'LOCAL TEST ONLY - synthetic services, no real transit or Cloudinary uploads';

  @override
  String get legacyEtaNow => 'Bus arriving now';

  @override
  String legacyEtaApprox(String minutes) {
    return 'Bus arriving in approximately $minutes minutes';
  }

  @override
  String legacySpeedNext(String speed, String stop) {
    return '$speed km/h · Next: $stop';
  }

  @override
  String get formReviewPublicNotice =>
      'Your report and photo will be public. Avoid faces and personal information.';

  @override
  String get formReviewDetails => 'Privacy and saved drafts';

  @override
  String get formReviewCooldownShort =>
      'Wait 5 minutes before reporting the same issue here again.';

  @override
  String get deliveryServiceUnavailable =>
      'The report service cannot be reached. Your draft is saved. Retry when the service is available.';

  @override
  String get deliveryServiceConfiguration =>
      'This app is not connected to the report service. Open the configured main app and retry your saved draft.';

  @override
  String get deliveryPermissionDenied =>
      'Publication permission was denied. Check that you are using the configured main app and sign in again before retrying. Your draft is saved.';

  @override
  String get deliveryTargetIneligible =>
      'This bus or stop is not eligible for publication. An administrator must review its catalogue record. Your draft is saved.';

  @override
  String get deliveryInvalidReport =>
      'The report service could not accept these report details. Review the selected bus or stop and observation before trying again.';

  @override
  String get adminAccessibilityDetails => 'Accessibility details';

  @override
  String resultsOutsideNeeds(int count) {
    return '$count scheduled options do not meet your current accessibility requirements.';
  }

  @override
  String get resultsRemoveAccessFilters => 'Show without accessibility filters';

  @override
  String get resultsTemporaryFiltersHelp =>
      'Changes this search only. These services may have unknown access or barriers; your saved preferences stay unchanged.';
}
