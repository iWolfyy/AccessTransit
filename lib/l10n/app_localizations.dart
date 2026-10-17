import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
    Locale('ta'),
  ];

  /// No description provided for @busDetails.
  ///
  /// In en, this message translates to:
  /// **'Bus Details'**
  String get busDetails;

  /// No description provided for @communityReports.
  ///
  /// In en, this message translates to:
  /// **'Community reports'**
  String get communityReports;

  /// No description provided for @saveTrip.
  ///
  /// In en, this message translates to:
  /// **'Save Trip'**
  String get saveTrip;

  /// No description provided for @removeSavedTrip.
  ///
  /// In en, this message translates to:
  /// **'Remove saved trip'**
  String get removeSavedTrip;

  /// No description provided for @savedTrip.
  ///
  /// In en, this message translates to:
  /// **'Saved trip'**
  String get savedTrip;

  /// No description provided for @noRecentReports.
  ///
  /// In en, this message translates to:
  /// **'No recent reports'**
  String get noRecentReports;

  /// No description provided for @loadingReports.
  ///
  /// In en, this message translates to:
  /// **'Loading reports…'**
  String get loadingReports;

  /// No description provided for @requestBoardingAssistance.
  ///
  /// In en, this message translates to:
  /// **'Request boarding assistance'**
  String get requestBoardingAssistance;

  /// No description provided for @reportCondition.
  ///
  /// In en, this message translates to:
  /// **'Report a condition'**
  String get reportCondition;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the language. Please try again.'**
  String get languageSaveFailed;

  /// No description provided for @searchWindowInvalid.
  ///
  /// In en, this message translates to:
  /// **'Choose a boarding time within the next 24 hours.'**
  String get searchWindowInvalid;

  /// No description provided for @searchSelectionExpired.
  ///
  /// In en, this message translates to:
  /// **'This selection has expired. Review the current results.'**
  String get searchSelectionExpired;

  /// No description provided for @searchAccountChanged.
  ///
  /// In en, this message translates to:
  /// **'Account changed. Return to Search to start a new search.'**
  String get searchAccountChanged;

  /// No description provided for @searchWindowNotice.
  ///
  /// In en, this message translates to:
  /// **'Boarding within the next 24 hours. Timetable times do not confirm a running bus.'**
  String get searchWindowNotice;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get emailHint;

  /// No description provided for @passenger.
  ///
  /// In en, this message translates to:
  /// **'Passenger'**
  String get passenger;

  /// No description provided for @passengerDescription.
  ///
  /// In en, this message translates to:
  /// **'Plan accessible journeys'**
  String get passengerDescription;

  /// No description provided for @reporter.
  ///
  /// In en, this message translates to:
  /// **'Reporter'**
  String get reporter;

  /// No description provided for @reporterDescription.
  ///
  /// In en, this message translates to:
  /// **'Report bus and stop conditions'**
  String get reporterDescription;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Bus Driver'**
  String get driver;

  /// No description provided for @driverDescription.
  ///
  /// In en, this message translates to:
  /// **'Administrator approval required'**
  String get driverDescription;

  /// No description provided for @operatorApprovalRequired.
  ///
  /// In en, this message translates to:
  /// **'Account created. Administrator approval is required for driver access.'**
  String get operatorApprovalRequired;

  /// No description provided for @accountReady.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}! Your account is ready.'**
  String accountReady(String name);

  /// No description provided for @verifyingSearchTime.
  ///
  /// In en, this message translates to:
  /// **'Verifying search time...'**
  String get verifyingSearchTime;

  /// No description provided for @searchTimeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Search time unavailable. Connect and retry.'**
  String get searchTimeUnavailable;

  /// No description provided for @retrySearchTime.
  ///
  /// In en, this message translates to:
  /// **'Retry search time'**
  String get retrySearchTime;

  /// No description provided for @retrySearch.
  ///
  /// In en, this message translates to:
  /// **'Retry search'**
  String get retrySearch;

  /// No description provided for @verifyingDatedSearch.
  ///
  /// In en, this message translates to:
  /// **'Verifying search time and dated departures...'**
  String get verifyingDatedSearch;

  /// No description provided for @datedSearchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Dated departures unavailable. Connect and retry.'**
  String get datedSearchUnavailable;

  /// No description provided for @nearbyStopsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby boarding stops'**
  String get nearbyStopsTitle;

  /// No description provided for @nearbyStopsExplanation.
  ///
  /// In en, this message translates to:
  /// **'Choose your boarding stop. Distances are approximate straight-line distances, not walking routes or travel times. Check the stop\'s direction and side of the road.'**
  String get nearbyStopsExplanation;

  /// No description provided for @nearbyLocating.
  ///
  /// In en, this message translates to:
  /// **'Finding your location...'**
  String get nearbyLocating;

  /// No description provided for @nearbyLocationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Turn on device location, then retry.'**
  String get nearbyLocationDisabled;

  /// No description provided for @nearbyLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied. You can choose a stop manually.'**
  String get nearbyLocationDenied;

  /// No description provided for @nearbyLocationBlocked.
  ///
  /// In en, this message translates to:
  /// **'Allow location access in app settings, then retry.'**
  String get nearbyLocationBlocked;

  /// No description provided for @nearbyLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not get a usable location. Retry or choose a stop manually.'**
  String get nearbyLocationUnavailable;

  /// No description provided for @nearbyOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get nearbyOpenSettings;

  /// No description provided for @nearbyRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry location'**
  String get nearbyRetry;

  /// No description provided for @nearbyChooseManually.
  ///
  /// In en, this message translates to:
  /// **'Choose a stop manually'**
  String get nearbyChooseManually;

  /// No description provided for @nearbyStopsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No stops with valid coordinates are available.'**
  String get nearbyStopsEmpty;

  /// No description provided for @nearbyDistance.
  ///
  /// In en, this message translates to:
  /// **'About {km} km away'**
  String nearbyDistance(String km);

  /// No description provided for @reportCooldownNotice.
  ///
  /// In en, this message translates to:
  /// **'You can report different issues without a daily limit. Wait 5 minutes before reporting the same issue category on the same bus or stop again.'**
  String get reportCooldownNotice;

  /// No description provided for @falseVoteReason.
  ///
  /// In en, this message translates to:
  /// **'Why is this report inaccurate?'**
  String get falseVoteReason;

  /// No description provided for @falseVoteReasonMinimum.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 5 characters.'**
  String get falseVoteReasonMinimum;

  /// No description provided for @voteCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get voteCancel;

  /// No description provided for @voteSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit vote'**
  String get voteSubmit;

  /// No description provided for @voteAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Vote acknowledged.'**
  String get voteAcknowledged;

  /// No description provided for @voteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Vote was not confirmed. Check your connection and retry.'**
  String get voteUnavailable;

  /// No description provided for @voteSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to vote.'**
  String get voteSignIn;

  /// No description provided for @authorVoteDisabled.
  ///
  /// In en, this message translates to:
  /// **'You cannot vote on your own report.'**
  String get authorVoteDisabled;

  /// No description provided for @voteRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry vote status'**
  String get voteRetry;

  /// No description provided for @votingClosed.
  ///
  /// In en, this message translates to:
  /// **'Voting is closed.'**
  String get votingClosed;

  /// No description provided for @voteNoPoints.
  ///
  /// In en, this message translates to:
  /// **'Votes earn no points. Five False votes hide the report.'**
  String get voteNoPoints;

  /// No description provided for @voteTrue.
  ///
  /// In en, this message translates to:
  /// **'True'**
  String get voteTrue;

  /// No description provided for @voteFalse.
  ///
  /// In en, this message translates to:
  /// **'False'**
  String get voteFalse;

  /// No description provided for @accountStatusChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking account access...'**
  String get accountStatusChecking;

  /// No description provided for @accountStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Account access could not be verified. Connect and retry.'**
  String get accountStatusUnavailable;

  /// No description provided for @accountSuspended.
  ///
  /// In en, this message translates to:
  /// **'Account suspended. Administrator review is required.'**
  String get accountSuspended;

  /// No description provided for @accountTemporaryUntil.
  ///
  /// In en, this message translates to:
  /// **'Account temporarily suspended until {until} (UTC).'**
  String accountTemporaryUntil(String until);

  /// No description provided for @accountStatusRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry account status'**
  String get accountStatusRetry;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @v2PointsNotice.
  ///
  /// In en, this message translates to:
  /// **'Published report: 10 points; votes earn no points. Five False votes deduct twice the award. Points have no cash value.'**
  String get v2PointsNotice;

  /// No description provided for @refreshV2Points.
  ///
  /// In en, this message translates to:
  /// **'Refresh v2 points'**
  String get refreshV2Points;

  /// No description provided for @reviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'My report reviews'**
  String get reviewsTitle;

  /// No description provided for @reviewsAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Report moderation'**
  String get reviewsAdminTitle;

  /// No description provided for @reviewsError.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify reviews. Check your connection and retry.'**
  String get reviewsError;

  /// No description provided for @reviewsReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a reason between 5 and 2,000 characters.'**
  String get reviewsReasonRequired;

  /// No description provided for @reviewsPending.
  ///
  /// In en, this message translates to:
  /// **'Appeal pending'**
  String get reviewsPending;

  /// No description provided for @reviewsUpheld.
  ///
  /// In en, this message translates to:
  /// **'Decision upheld'**
  String get reviewsUpheld;

  /// No description provided for @reviewsOverturned.
  ///
  /// In en, this message translates to:
  /// **'Decision overturned; penalty restored'**
  String get reviewsOverturned;

  /// No description provided for @reviewsUnreviewed.
  ///
  /// In en, this message translates to:
  /// **'Awaiting review'**
  String get reviewsUnreviewed;

  /// No description provided for @reviewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No community-disputed reports.'**
  String get reviewsEmpty;

  /// No description provided for @reviewsMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get reviewsMore;

  /// No description provided for @reviewsPenalty.
  ///
  /// In en, this message translates to:
  /// **'Penalty: {points} points. Counted strikes: {strikes}.'**
  String reviewsPenalty(int points, int strikes);

  /// No description provided for @reviewsHiddenReason.
  ///
  /// In en, this message translates to:
  /// **'{count} other users marked this report False. It was hidden automatically.'**
  String reviewsHiddenReason(int count);

  /// No description provided for @reviewsAppealLabel.
  ///
  /// In en, this message translates to:
  /// **'Your appeal'**
  String get reviewsAppealLabel;

  /// No description provided for @reviewsDecisionReason.
  ///
  /// In en, this message translates to:
  /// **'Admin decision reason'**
  String get reviewsDecisionReason;

  /// No description provided for @reviewsVotes.
  ///
  /// In en, this message translates to:
  /// **'Community vote evidence'**
  String get reviewsVotes;

  /// No description provided for @reviewsReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reviewsReason;

  /// No description provided for @reviewsDecisionExplanation.
  ///
  /// In en, this message translates to:
  /// **'Overturn restores the deducted points and removes this strike once. Other account restrictions remain.'**
  String get reviewsDecisionExplanation;

  /// No description provided for @reviewsUphold.
  ///
  /// In en, this message translates to:
  /// **'Uphold decision'**
  String get reviewsUphold;

  /// No description provided for @reviewsOverturn.
  ///
  /// In en, this message translates to:
  /// **'Overturn decision'**
  String get reviewsOverturn;

  /// No description provided for @reviewsSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit appeal'**
  String get reviewsSubmit;

  /// No description provided for @reviewsAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Change confirmed by the server.'**
  String get reviewsAcknowledged;

  /// No description provided for @reviewsPhoto.
  ///
  /// In en, this message translates to:
  /// **'Report photo'**
  String get reviewsPhoto;

  /// No description provided for @reviewsPhotoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Report photo unavailable.'**
  String get reviewsPhotoUnavailable;

  /// No description provided for @bansTitle.
  ///
  /// In en, this message translates to:
  /// **'Permanent-ban reviews'**
  String get bansTitle;

  /// No description provided for @bansApproved.
  ///
  /// In en, this message translates to:
  /// **'Permanent ban approved'**
  String get bansApproved;

  /// No description provided for @bansRejected.
  ///
  /// In en, this message translates to:
  /// **'Permanent ban rejected'**
  String get bansRejected;

  /// No description provided for @bansWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Review withdrawn'**
  String get bansWithdrawn;

  /// No description provided for @bansPending.
  ///
  /// In en, this message translates to:
  /// **'Admin review pending'**
  String get bansPending;

  /// No description provided for @bansEmpty.
  ///
  /// In en, this message translates to:
  /// **'No permanent-ban review cases.'**
  String get bansEmpty;

  /// No description provided for @bansStrikes.
  ///
  /// In en, this message translates to:
  /// **'Current strikes: {count}'**
  String bansStrikes(int count);

  /// No description provided for @bansAppealsPending.
  ///
  /// In en, this message translates to:
  /// **'Resolve pending report appeals before approving a permanent ban.'**
  String get bansAppealsPending;

  /// No description provided for @bansStale.
  ///
  /// In en, this message translates to:
  /// **'Evidence changed. Refresh this case before deciding.'**
  String get bansStale;

  /// No description provided for @bansAdminProtected.
  ///
  /// In en, this message translates to:
  /// **'Administrator accounts are protected from this workflow.'**
  String get bansAdminProtected;

  /// No description provided for @bansEvidence.
  ///
  /// In en, this message translates to:
  /// **'Contributing reports and appeals'**
  String get bansEvidence;

  /// No description provided for @bansCounted.
  ///
  /// In en, this message translates to:
  /// **'Strike counted'**
  String get bansCounted;

  /// No description provided for @bansRemoved.
  ///
  /// In en, this message translates to:
  /// **'Strike removed'**
  String get bansRemoved;

  /// No description provided for @bansExplanation.
  ///
  /// In en, this message translates to:
  /// **'Ten strikes request a review. Only an explicit approval imposes a permanent restriction. Rejection does not extend a temporary ban.'**
  String get bansExplanation;

  /// No description provided for @bansReject.
  ///
  /// In en, this message translates to:
  /// **'Reject permanent ban'**
  String get bansReject;

  /// No description provided for @bansApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve permanent ban'**
  String get bansApprove;

  /// No description provided for @assistanceInbox.
  ///
  /// In en, this message translates to:
  /// **'Run assistance requests'**
  String get assistanceInbox;

  /// No description provided for @assistanceChooseRun.
  ///
  /// In en, this message translates to:
  /// **'Choose a dated trip with an assigned driver from Bus Details.'**
  String get assistanceChooseRun;

  /// No description provided for @assistanceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Assistance is unavailable. Check the trip, assignment and connection, then retry.'**
  String get assistanceUnavailable;

  /// No description provided for @assistanceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No assistance requests for this run.'**
  String get assistanceEmpty;

  /// No description provided for @assistanceRetargeted.
  ///
  /// In en, this message translates to:
  /// **'Driver changed. Awaiting the current driver acknowledgement.'**
  String get assistanceRetargeted;

  /// No description provided for @assistancePending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting driver acknowledgement'**
  String get assistancePending;

  /// No description provided for @assistanceAccepted.
  ///
  /// In en, this message translates to:
  /// **'Driver acknowledged'**
  String get assistanceAccepted;

  /// No description provided for @assistanceDeclined.
  ///
  /// In en, this message translates to:
  /// **'Driver declined'**
  String get assistanceDeclined;

  /// No description provided for @assistanceCompleted.
  ///
  /// In en, this message translates to:
  /// **'Driver marked completed'**
  String get assistanceCompleted;

  /// No description provided for @assistanceCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get assistanceCancelled;

  /// No description provided for @assistanceExpired.
  ///
  /// In en, this message translates to:
  /// **'Request expired'**
  String get assistanceExpired;

  /// No description provided for @assistanceAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge'**
  String get assistanceAcknowledge;

  /// No description provided for @assistanceDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get assistanceDecline;

  /// No description provided for @assistanceComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get assistanceComplete;

  /// No description provided for @assistanceInAppOnly.
  ///
  /// In en, this message translates to:
  /// **'Available in the assigned driver\'s in-app inbox. Background push notifications are not enabled in local testing.'**
  String get assistanceInAppOnly;

  /// No description provided for @assistanceExpiry.
  ///
  /// In en, this message translates to:
  /// **'Request expiry (UTC): {time}'**
  String assistanceExpiry(String time);

  /// No description provided for @assistanceRunEnded.
  ///
  /// In en, this message translates to:
  /// **'This trip has ended or was cancelled.'**
  String get assistanceRunEnded;

  /// No description provided for @assistanceStopPassed.
  ///
  /// In en, this message translates to:
  /// **'The bus has already passed the requested boarding opportunity.'**
  String get assistanceStopPassed;

  /// No description provided for @assistanceDriverUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The assigned driver is no longer available.'**
  String get assistanceDriverUnavailable;

  /// No description provided for @assistanceRamp.
  ///
  /// In en, this message translates to:
  /// **'Deploy ramp'**
  String get assistanceRamp;

  /// No description provided for @assistanceExtraTime.
  ///
  /// In en, this message translates to:
  /// **'Extra time'**
  String get assistanceExtraTime;

  /// No description provided for @assistanceBoardingHelp.
  ///
  /// In en, this message translates to:
  /// **'Boarding help'**
  String get assistanceBoardingHelp;

  /// No description provided for @assistanceAlightingHelp.
  ///
  /// In en, this message translates to:
  /// **'Alighting help'**
  String get assistanceAlightingHelp;

  /// No description provided for @operationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Active trips'**
  String get operationsTitle;

  /// No description provided for @operationsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh from server'**
  String get operationsRefresh;

  /// No description provided for @operationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active dated trips.'**
  String get operationsEmpty;

  /// No description provided for @operationsMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get operationsMore;

  /// No description provided for @operationsExplanation.
  ///
  /// In en, this message translates to:
  /// **'Transfer this trip to an approved driver assigned to the same route. Progress and recorded times stay unchanged. GPS pauses until the new driver resumes with a fresh location. Assistance requests require the new driver’s acceptance.'**
  String get operationsExplanation;

  /// No description provided for @operationsDone.
  ///
  /// In en, this message translates to:
  /// **'Transfer acknowledged. GPS is paused until the new driver resumes. Assistance reassignment continues in the background; previous acceptance does not carry over.'**
  String get operationsDone;

  /// No description provided for @operationsNoDrivers.
  ///
  /// In en, this message translates to:
  /// **'No eligible driver on this page. Approve and assign an available driver to this route first.'**
  String get operationsNoDrivers;

  /// No description provided for @operationsReason.
  ///
  /// In en, this message translates to:
  /// **'Transfer reason (5–2000 characters)'**
  String get operationsReason;

  /// No description provided for @operationsTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer trip'**
  String get operationsTransfer;

  /// No description provided for @operationsSaving.
  ///
  /// In en, this message translates to:
  /// **'Transferring…'**
  String get operationsSaving;

  /// No description provided for @operationsError.
  ///
  /// In en, this message translates to:
  /// **'Unable to confirm this operation. Retry the same request or refresh to inspect its current state.'**
  String get operationsError;

  /// No description provided for @operationsStale.
  ///
  /// In en, this message translates to:
  /// **'The trip or driver eligibility changed. Refresh before transferring.'**
  String get operationsStale;

  /// No description provided for @operationsResume.
  ///
  /// In en, this message translates to:
  /// **'Accept and resume GPS'**
  String get operationsResume;

  /// No description provided for @operationsGpsError.
  ///
  /// In en, this message translates to:
  /// **'Wait for a fresh GPS fix with accuracy within 100 metres, then accept and resume again.'**
  String get operationsGpsError;

  /// No description provided for @pushTitle.
  ///
  /// In en, this message translates to:
  /// **'Assistance notifications'**
  String get pushTitle;

  /// No description provided for @pushChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Notifications about passenger assistance requests'**
  String get pushChannelDescription;

  /// No description provided for @pushOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. The driver inbox remains available.'**
  String get pushOff;

  /// No description provided for @pushConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting notifications…'**
  String get pushConnecting;

  /// No description provided for @pushDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is denied. You can allow it in Android app settings.'**
  String get pushDenied;

  /// No description provided for @pushReady.
  ///
  /// In en, this message translates to:
  /// **'This device is registered. A notification does not confirm that assistance was accepted.'**
  String get pushReady;

  /// No description provided for @pushUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Notification setup was not confirmed. Retry or use the driver inbox.'**
  String get pushUnavailable;

  /// No description provided for @pushEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get pushEnable;

  /// No description provided for @pushDisable.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get pushDisable;

  /// No description provided for @pushOpenUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This request is unavailable or no longer assigned to your account.'**
  String get pushOpenUnavailable;

  /// No description provided for @pushForeground.
  ///
  /// In en, this message translates to:
  /// **'A passenger has requested assistance.'**
  String get pushForeground;

  /// No description provided for @pushReview.
  ///
  /// In en, this message translates to:
  /// **'Review request'**
  String get pushReview;

  /// No description provided for @fareUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Fare unavailable'**
  String get fareUnavailable;

  /// No description provided for @fareUnavailableDisclosure.
  ///
  /// In en, this message translates to:
  /// **'A reviewed tariff and fare-stage mapping are not available for this selection. Confirm the fare with the operator.'**
  String get fareUnavailableDisclosure;

  /// No description provided for @fareSampleDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Sample/Test estimate only. This duration/stop model is not an official fare. Confirm the actual fare with the operator.'**
  String get fareSampleDisclosure;

  /// No description provided for @fareSampleAmount.
  ///
  /// In en, this message translates to:
  /// **'Sample est. LKR {amount}'**
  String fareSampleAmount(int amount);

  /// No description provided for @fareReviewedSource.
  ///
  /// In en, this message translates to:
  /// **'Reviewed source: {source}. Tariff {tariff}; mapping {mapping}.'**
  String fareReviewedSource(String source, String tariff, String mapping);

  /// No description provided for @fareReviewedAmount.
  ///
  /// In en, this message translates to:
  /// **'LKR {amount}'**
  String fareReviewedAmount(String amount);

  /// No description provided for @fareSampleReviewed.
  ///
  /// In en, this message translates to:
  /// **'Sample tariff LKR {amount}'**
  String fareSampleReviewed(String amount);

  /// No description provided for @fareChanged.
  ///
  /// In en, this message translates to:
  /// **'The fare version changed or is unavailable. The saved selection is preserved; review the current fare before travelling.'**
  String get fareChanged;

  /// No description provided for @fareAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Fare publications'**
  String get fareAdminTitle;

  /// No description provided for @fareImportHelp.
  ///
  /// In en, this message translates to:
  /// **'Import a reviewed fare table, ordered stop-stage mapping and explicit bus IDs. Amounts use minor units (LKR 1 = 100). Preview every cell, source, class and effective date before publishing. Published versions are immutable; archive and create a new ID to replace one.'**
  String get fareImportHelp;

  /// No description provided for @farePublicationId.
  ///
  /// In en, this message translates to:
  /// **'New publication ID'**
  String get farePublicationId;

  /// No description provided for @fareImportJson.
  ///
  /// In en, this message translates to:
  /// **'Reviewed import JSON'**
  String get fareImportJson;

  /// No description provided for @farePreview.
  ///
  /// In en, this message translates to:
  /// **'Validate and preview'**
  String get farePreview;

  /// No description provided for @fareReviewCheck.
  ///
  /// In en, this message translates to:
  /// **'I reviewed the source, vehicle class, direction, stop-stage mapping and dates.'**
  String get fareReviewCheck;

  /// No description provided for @fareReviewReason.
  ///
  /// In en, this message translates to:
  /// **'Review/archive reason (10–2000 characters)'**
  String get fareReviewReason;

  /// No description provided for @farePublish.
  ///
  /// In en, this message translates to:
  /// **'Publish reviewed version'**
  String get farePublish;

  /// No description provided for @fareArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive version'**
  String get fareArchive;

  /// No description provided for @fareCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get fareCancel;

  /// No description provided for @fareInvalidImport.
  ///
  /// In en, this message translates to:
  /// **'Invalid import. Check the documented schema, IDs, integer amounts, source and date/mapping applicability.'**
  String get fareInvalidImport;

  /// No description provided for @fareAdminError.
  ///
  /// In en, this message translates to:
  /// **'Operation unconfirmed. Check connection, admin access, review reason and current bus/route data. Reload before retrying a changed publication.'**
  String get fareAdminError;

  /// No description provided for @fareNoPublications.
  ///
  /// In en, this message translates to:
  /// **'No fare publications. Missing fares remain unavailable.'**
  String get fareNoPublications;

  /// No description provided for @geometryTitle.
  ///
  /// In en, this message translates to:
  /// **'Route geometry'**
  String get geometryTitle;

  /// No description provided for @geometryHelp.
  ///
  /// In en, this message translates to:
  /// **'Import a reviewed directed road path and ordered stop vertices. Match the current route and stop coordinates; use a new version for corrections. This does not supply real-time traffic.'**
  String get geometryHelp;

  /// No description provided for @geometryReview.
  ///
  /// In en, this message translates to:
  /// **'I reviewed the road path, direction, stop vertices and source.'**
  String get geometryReview;

  /// No description provided for @geometryInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid geometry. Check the JSON, route ID, coordinates, source and ordered stop vertices.'**
  String get geometryInvalid;

  /// No description provided for @geometrySaved.
  ///
  /// In en, this message translates to:
  /// **'Reviewed route geometry published.'**
  String get geometrySaved;

  /// No description provided for @geometryWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw current geometry'**
  String get geometryWithdraw;

  /// No description provided for @geometryMap.
  ///
  /// In en, this message translates to:
  /// **'Reviewed road path · selected segment'**
  String get geometryMap;

  /// No description provided for @geometryEta.
  ///
  /// In en, this message translates to:
  /// **'{target}: estimated {start}–{end} · road progress + timetable, low confidence.'**
  String geometryEta(String target, String start, String end);

  /// No description provided for @geometryWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Route geometry withdrawn.'**
  String get geometryWithdrawn;

  /// No description provided for @etaDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Local ETA diagnostics'**
  String get etaDiagnostics;

  /// No description provided for @etaDiagnosticsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Local Test diagnostics requires a loaded signed-in account.'**
  String get etaDiagnosticsUnavailable;

  /// No description provided for @etaDiagnosticsHelp.
  ///
  /// In en, this message translates to:
  /// **'LOCAL TEST ONLY. Opt in to capture forecasts while Bus Details is open. Arrivals are acknowledged driver-reported timestamps, not independent GPS ground truth. No production accuracy claim. Records stay on this device/account (500 maximum, seven-day retention applied during capture). No coordinates, emails or driver IDs are stored.'**
  String get etaDiagnosticsHelp;

  /// No description provided for @etaCapture.
  ///
  /// In en, this message translates to:
  /// **'Capture local forecasts'**
  String get etaCapture;

  /// No description provided for @etaCounts.
  ///
  /// In en, this message translates to:
  /// **'Captured: {captured} · pending: {pending} · excluded: {excluded}'**
  String etaCounts(int captured, int pending, int excluded);

  /// No description provided for @etaMetrics.
  ///
  /// In en, this message translates to:
  /// **'Matched samples: {count} · median error: {median}s · P90 error: {p90}s'**
  String etaMetrics(int count, String median, String p90);

  /// No description provided for @etaStorageError.
  ///
  /// In en, this message translates to:
  /// **'Local save/read unconfirmed. Export may contain unsaved diagnostic records; retry your action.'**
  String get etaStorageError;

  /// No description provided for @etaNoMatchedSamples.
  ///
  /// In en, this message translates to:
  /// **'No matched arrivals yet. Pending/excluded forecasts are not counted as zero error.'**
  String get etaNoMatchedSamples;

  /// No description provided for @etaSmallSample.
  ///
  /// In en, this message translates to:
  /// **'Small synthetic sample; this does not establish real-world accuracy.'**
  String get etaSmallSample;

  /// No description provided for @etaCopied.
  ///
  /// In en, this message translates to:
  /// **'Local diagnostic JSON copied.'**
  String get etaCopied;

  /// No description provided for @etaExport.
  ///
  /// In en, this message translates to:
  /// **'Copy diagnostic JSON'**
  String get etaExport;

  /// No description provided for @etaClear.
  ///
  /// In en, this message translates to:
  /// **'Clear this account’s local measurements'**
  String get etaClear;

  /// No description provided for @savedTripsTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved trips'**
  String get savedTripsTitle;

  /// No description provided for @savedTripsViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all saved trips'**
  String get savedTripsViewAll;

  /// No description provided for @savedTripsHelp.
  ///
  /// In en, this message translates to:
  /// **'Your saved selections, including past records. Saving does not book a seat or start tracking. Open details to refresh the selected run’s current status.'**
  String get savedTripsHelp;

  /// No description provided for @savedTripsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh saved trips'**
  String get savedTripsRefresh;

  /// No description provided for @savedTripsAccountChanged.
  ///
  /// In en, this message translates to:
  /// **'Account changed. Return Home and open your saved trips again.'**
  String get savedTripsAccountChanged;

  /// No description provided for @savedTripsRemoveError.
  ///
  /// In en, this message translates to:
  /// **'Removal is not confirmed. The saved record is retained; reconnect and retry.'**
  String get savedTripsRemoveError;

  /// No description provided for @savedTripsOpenError.
  ///
  /// In en, this message translates to:
  /// **'Saved details could not be verified. Reconnect and retry.'**
  String get savedTripsOpenError;

  /// No description provided for @savedTripsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Saved trips unavailable. Check your connection and account access, then retry.'**
  String get savedTripsLoadError;

  /// No description provided for @savedTripsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get savedTripsRetry;

  /// No description provided for @savedTripsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved trips yet. Save a trip from Bus Details.'**
  String get savedTripsEmpty;

  /// No description provided for @savedTripsEmptyPage.
  ///
  /// In en, this message translates to:
  /// **'No saved records on this page. Refresh or return to the previous page.'**
  String get savedTripsEmptyPage;

  /// No description provided for @savedTripsCompletedRecord.
  ///
  /// In en, this message translates to:
  /// **'Completed saved record'**
  String get savedTripsCompletedRecord;

  /// No description provided for @savedTripsCancelledRecord.
  ///
  /// In en, this message translates to:
  /// **'Cancelled saved record'**
  String get savedTripsCancelledRecord;

  /// No description provided for @savedTripsOpen.
  ///
  /// In en, this message translates to:
  /// **'Open bus details'**
  String get savedTripsOpen;

  /// No description provided for @savedTripsPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get savedTripsPrevious;

  /// No description provided for @savedTripsNext.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get savedTripsNext;

  /// No description provided for @savedTripsVehicleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Saved vehicle unavailable. Review the saved record or search again.'**
  String get savedTripsVehicleUnavailable;

  /// No description provided for @segmentReportsPreview.
  ///
  /// In en, this message translates to:
  /// **'Limited report preview; open scoped pages for more evidence. Missing reports do not establish accessibility.'**
  String get segmentReportsPreview;

  /// No description provided for @segmentReportsHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose this bus or a stop in your selected segment. Pages use stable record order, not observation time. Expired/hidden reports are excluded; an empty page does not mean there are no older relevant reports.'**
  String get segmentReportsHelp;

  /// No description provided for @segmentReportsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Reports unavailable. Reconnect and refresh.'**
  String get segmentReportsUnavailable;

  /// No description provided for @segmentReportsEmptyPage.
  ///
  /// In en, this message translates to:
  /// **'No current visible reports on this page. Check the next page when available.'**
  String get segmentReportsEmptyPage;

  /// No description provided for @segmentReportsEmptyPreview.
  ///
  /// In en, this message translates to:
  /// **'No current reports in this preview.'**
  String get segmentReportsEmptyPreview;

  /// No description provided for @segmentReportsViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all relevant reports'**
  String get segmentReportsViewAll;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Service calendar'**
  String get calendarTitle;

  /// No description provided for @calendarHelp.
  ///
  /// In en, this message translates to:
  /// **'Publish reviewed weekdays, Colombo departure time and up to 31 service dates. Then generate departures explicitly. Existing runs are preserved. Retiring a calendar stops generation; cancel future runs separately.'**
  String get calendarHelp;

  /// No description provided for @calendarDates.
  ///
  /// In en, this message translates to:
  /// **'Choose service dates'**
  String get calendarDates;

  /// No description provided for @calendarTime.
  ///
  /// In en, this message translates to:
  /// **'Choose Colombo departure time'**
  String get calendarTime;

  /// No description provided for @calendarPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish calendar'**
  String get calendarPublish;

  /// No description provided for @calendarGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate dated departures'**
  String get calendarGenerate;

  /// No description provided for @calendarRetire.
  ///
  /// In en, this message translates to:
  /// **'Retire calendar'**
  String get calendarRetire;

  /// No description provided for @calendarFailed.
  ///
  /// In en, this message translates to:
  /// **'Change or load not confirmed. Reconnect and reload. Use selected weekdays and at most 31 days; changed timetables need a replacement calendar.'**
  String get calendarFailed;

  /// No description provided for @calendarConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Calendar change confirmed.'**
  String get calendarConfirmed;

  /// No description provided for @calendarGenerated.
  ///
  /// In en, this message translates to:
  /// **'Created {created}; preserved {preserved} existing departures.'**
  String calendarGenerated(int created, int preserved);

  /// No description provided for @calendarPublished.
  ///
  /// In en, this message translates to:
  /// **'Published calendar'**
  String get calendarPublished;

  /// No description provided for @calendarRetired.
  ///
  /// In en, this message translates to:
  /// **'Retired calendar'**
  String get calendarRetired;

  /// No description provided for @calendarEmpty.
  ///
  /// In en, this message translates to:
  /// **'No calendars for this bus.'**
  String get calendarEmpty;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
