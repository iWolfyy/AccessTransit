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

  /// No description provided for @authControlsTitle.
  ///
  /// In en, this message translates to:
  /// **'Firebase account controls'**
  String get authControlsTitle;

  /// No description provided for @authControlsExplanation.
  ///
  /// In en, this message translates to:
  /// **'Manage sign-in and sessions. Enabling sign-in preserves separate manual and community restrictions. Auth changes require a server receipt.'**
  String get authControlsExplanation;

  /// No description provided for @authDeleteExplanation.
  ///
  /// In en, this message translates to:
  /// **'Delete the Firebase sign-in account and anonymize its private profile. Shared reports, trips and audit references are retained. Disable sign-in and finish active-trip reconciliation first. This cannot be undone.'**
  String get authDeleteExplanation;

  /// No description provided for @authCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get authCancel;

  /// No description provided for @authConfirmRequired.
  ///
  /// In en, this message translates to:
  /// **'Type the exact account UID to confirm deletion.'**
  String get authConfirmRequired;

  /// No description provided for @authDisableFirst.
  ///
  /// In en, this message translates to:
  /// **'Disable sign-in before approving deletion.'**
  String get authDisableFirst;

  /// No description provided for @authActiveTrip.
  ///
  /// In en, this message translates to:
  /// **'An active operation must be reconciled before deletion.'**
  String get authActiveTrip;

  /// No description provided for @authPending.
  ///
  /// In en, this message translates to:
  /// **'Operation pending or requires review. Reload its receipt before another decision.'**
  String get authPending;

  /// No description provided for @authNormalScope.
  ///
  /// In en, this message translates to:
  /// **'Firebase Auth controls are available only in the normal account scope.'**
  String get authNormalScope;

  /// No description provided for @authReload.
  ///
  /// In en, this message translates to:
  /// **'Reload account status'**
  String get authReload;

  /// No description provided for @authDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted; retained history remains available to authorized reviewers.'**
  String get authDeleted;

  /// No description provided for @authDisabled.
  ///
  /// In en, this message translates to:
  /// **'Firebase sign-in is disabled'**
  String get authDisabled;

  /// No description provided for @authEnabled.
  ///
  /// In en, this message translates to:
  /// **'Firebase sign-in is enabled'**
  String get authEnabled;

  /// No description provided for @authCompleted.
  ///
  /// In en, this message translates to:
  /// **'Last operation completed'**
  String get authCompleted;

  /// No description provided for @authReconcile.
  ///
  /// In en, this message translates to:
  /// **'Review and retry the same operation'**
  String get authReconcile;

  /// No description provided for @authConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Account UID for deletion confirmation'**
  String get authConfirmLabel;

  /// No description provided for @authEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable sign-in'**
  String get authEnable;

  /// No description provided for @authDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable sign-in'**
  String get authDisable;

  /// No description provided for @authRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke existing sessions'**
  String get authRevoke;

  /// No description provided for @authDeleteRequest.
  ///
  /// In en, this message translates to:
  /// **'Request deletion review'**
  String get authDeleteRequest;

  /// No description provided for @authDeleteReject.
  ///
  /// In en, this message translates to:
  /// **'Reject deletion'**
  String get authDeleteReject;

  /// No description provided for @authDeleteApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve account deletion'**
  String get authDeleteApprove;

  /// No description provided for @accountControlsUntil.
  ///
  /// In en, this message translates to:
  /// **'Until {when} (Asia/Colombo)'**
  String accountControlsUntil(String when);

  /// No description provided for @accountControlsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account access'**
  String get accountControlsTitle;

  /// No description provided for @accountControlsExplanation.
  ///
  /// In en, this message translates to:
  /// **'Manage application access in this scope. Restoring manual access preserves community restrictions. Active driver operations are reconciled by the server.'**
  String get accountControlsExplanation;

  /// No description provided for @accountControlsReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a reason between 5 and 2,000 characters.'**
  String get accountControlsReasonRequired;

  /// No description provided for @accountControlsStale.
  ///
  /// In en, this message translates to:
  /// **'Account access changed. Reload before deciding.'**
  String get accountControlsStale;

  /// No description provided for @accountControlsProtected.
  ///
  /// In en, this message translates to:
  /// **'Your account and administrator accounts are protected.'**
  String get accountControlsProtected;

  /// No description provided for @accountControlsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Access could not be confirmed. Retry or reload.'**
  String get accountControlsUnavailable;

  /// No description provided for @accountControlsRestricted.
  ///
  /// In en, this message translates to:
  /// **'Manual restriction is active'**
  String get accountControlsRestricted;

  /// No description provided for @accountControlsClear.
  ///
  /// In en, this message translates to:
  /// **'No active manual restriction'**
  String get accountControlsClear;

  /// No description provided for @accountControlsCommunity.
  ///
  /// In en, this message translates to:
  /// **'A separate community restriction remains in effect.'**
  String get accountControlsCommunity;

  /// No description provided for @accountControlsIndefinite.
  ///
  /// In en, this message translates to:
  /// **'Until an administrator restores access'**
  String get accountControlsIndefinite;

  /// No description provided for @accountControlsDuration.
  ///
  /// In en, this message translates to:
  /// **'Otherwise suspend for 72 hours from server time.'**
  String get accountControlsDuration;

  /// No description provided for @accountControlsSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend access'**
  String get accountControlsSuspend;

  /// No description provided for @accountControlsRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore manual access'**
  String get accountControlsRestore;

  /// No description provided for @accountControlsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get accountControlsRetry;

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

  /// No description provided for @loopStopHelp.
  ///
  /// In en, this message translates to:
  /// **'Add stops in order. The same physical stop may appear again; each visit keeps its own timetable and identity. Reordering moves that visit’s scheduled time with it.'**
  String get loopStopHelp;

  /// No description provided for @journeyVisitPositions.
  ///
  /// In en, this message translates to:
  /// **'Board at route stop {boarding}; alight at route stop {alighting}.'**
  String journeyVisitPositions(int boarding, int alighting);

  /// No description provided for @scheduleReschedule.
  ///
  /// In en, this message translates to:
  /// **'Publish replacement'**
  String get scheduleReschedule;

  /// No description provided for @scheduleRescheduleHelp.
  ///
  /// In en, this message translates to:
  /// **'Cancel the old departure and publish a linked replacement at the selected Colombo date/time. Existing saved trips keep their original selection. The reason below is public.'**
  String get scheduleRescheduleHelp;

  /// No description provided for @schedulePublicReason.
  ///
  /// In en, this message translates to:
  /// **'Public change reason'**
  String get schedulePublicReason;

  /// No description provided for @scheduleReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter at least five characters.'**
  String get scheduleReasonRequired;

  /// No description provided for @scheduleStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Current run status unavailable. Saved times do not confirm that the bus will operate.'**
  String get scheduleStatusUnavailable;

  /// No description provided for @scheduleCancelled.
  ///
  /// In en, this message translates to:
  /// **'This departure was cancelled. Your saved selection has not been moved to another trip.'**
  String get scheduleCancelled;

  /// No description provided for @scheduleChanged.
  ///
  /// In en, this message translates to:
  /// **'The current timetable differs from the saved selection. Original saved times are shown; search again to review current options.'**
  String get scheduleChanged;

  /// No description provided for @scheduleReplacement.
  ///
  /// In en, this message translates to:
  /// **'A linked replacement was published. Search again to review its current availability.'**
  String get scheduleReplacement;

  /// No description provided for @scheduleReplacementAt.
  ///
  /// In en, this message translates to:
  /// **'A replacement was published for {time}. Search again to review its current availability.'**
  String scheduleReplacementAt(String time);

  /// No description provided for @scheduleSavedRecord.
  ///
  /// In en, this message translates to:
  /// **'Original saved timetable. The current vehicle or route is unavailable or changed. This record does not establish live location or current accessibility.'**
  String get scheduleSavedRecord;

  /// No description provided for @scheduleTimeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Saved intermediate time unavailable'**
  String get scheduleTimeUnknown;

  /// No description provided for @scheduleSavedFare.
  ///
  /// In en, this message translates to:
  /// **'Saved fare: {fare}'**
  String scheduleSavedFare(String fare);

  /// No description provided for @manualAppealsTitle.
  ///
  /// In en, this message translates to:
  /// **'Restriction appeals'**
  String get manualAppealsTitle;

  /// No description provided for @manualAppealsExplanation.
  ///
  /// In en, this message translates to:
  /// **'Appeal a manual account restriction. Submitting an appeal does not restore access. An accepted appeal changes only that manual restriction.'**
  String get manualAppealsExplanation;

  /// No description provided for @manualAppealReason.
  ///
  /// In en, this message translates to:
  /// **'Explain your appeal'**
  String get manualAppealReason;

  /// No description provided for @manualAppealSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit appeal'**
  String get manualAppealSubmit;

  /// No description provided for @manualAppealNoNew.
  ///
  /// In en, this message translates to:
  /// **'No new appeal is available for the current restriction.'**
  String get manualAppealNoNew;

  /// No description provided for @manualAppealRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore manual access'**
  String get manualAppealRestore;

  /// No description provided for @manualAppealUphold.
  ///
  /// In en, this message translates to:
  /// **'Uphold restriction'**
  String get manualAppealUphold;

  /// No description provided for @manualAppealClose.
  ///
  /// In en, this message translates to:
  /// **'Close review'**
  String get manualAppealClose;

  /// No description provided for @manualAppealPending.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get manualAppealPending;

  /// No description provided for @manualAppealAccepted.
  ///
  /// In en, this message translates to:
  /// **'Appeal accepted'**
  String get manualAppealAccepted;

  /// No description provided for @manualAppealRejected.
  ///
  /// In en, this message translates to:
  /// **'Appeal rejected'**
  String get manualAppealRejected;

  /// No description provided for @manualAppealReview.
  ///
  /// In en, this message translates to:
  /// **'Review appeal'**
  String get manualAppealReview;

  /// No description provided for @manualAppealEmpty.
  ///
  /// In en, this message translates to:
  /// **'No restriction appeals.'**
  String get manualAppealEmpty;

  /// No description provided for @manualAppealFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm this request. Reload the current restriction before a new decision. Retry an unconfirmed request with the same details.'**
  String get manualAppealFailed;

  /// No description provided for @adminLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get adminLoadMore;

  /// No description provided for @adminSearchLoaded.
  ///
  /// In en, this message translates to:
  /// **'Search loaded records'**
  String get adminSearchLoaded;

  /// No description provided for @adminLoadedPages.
  ///
  /// In en, this message translates to:
  /// **'Counts and search cover loaded pages. Load more to check additional records.'**
  String get adminLoadedPages;

  /// No description provided for @manualAppealRevision.
  ///
  /// In en, this message translates to:
  /// **'Restriction revision {revision}'**
  String manualAppealRevision(int revision);

  /// No description provided for @adminConsole.
  ///
  /// In en, this message translates to:
  /// **'Admin console'**
  String get adminConsole;

  /// No description provided for @adminOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get adminOverview;

  /// No description provided for @adminBuses.
  ///
  /// In en, this message translates to:
  /// **'Buses'**
  String get adminBuses;

  /// No description provided for @adminRoutes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get adminRoutes;

  /// No description provided for @adminStops.
  ///
  /// In en, this message translates to:
  /// **'Bus stops'**
  String get adminStops;

  /// No description provided for @adminUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminUsers;

  /// No description provided for @adminDrivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get adminDrivers;

  /// No description provided for @adminActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get adminActivity;

  /// No description provided for @adminRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh server data'**
  String get adminRefresh;

  /// No description provided for @adminSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get adminSignOut;

  /// No description provided for @adminSampleCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Sample/Test catalogue administration'**
  String get adminSampleCatalogue;

  /// No description provided for @adminUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Server data unavailable.'**
  String get adminUnavailable;

  /// No description provided for @adminLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading verified server records...'**
  String get adminLoading;

  /// No description provided for @adminNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching records.'**
  String get adminNoMatches;

  /// No description provided for @adminReviewAccess.
  ///
  /// In en, this message translates to:
  /// **'Review access'**
  String get adminReviewAccess;

  /// No description provided for @adminAssignRoute.
  ///
  /// In en, this message translates to:
  /// **'Assign route'**
  String get adminAssignRoute;

  /// No description provided for @adminEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get adminEditProfile;

  /// No description provided for @adminReviewDriver.
  ///
  /// In en, this message translates to:
  /// **'Review driver'**
  String get adminReviewDriver;

  /// No description provided for @adminDatedDepartures.
  ///
  /// In en, this message translates to:
  /// **'Dated departures'**
  String get adminDatedDepartures;

  /// No description provided for @adminRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get adminRestore;

  /// No description provided for @adminEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get adminEdit;

  /// No description provided for @adminDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get adminDelete;

  /// No description provided for @adminFinishDeletion.
  ///
  /// In en, this message translates to:
  /// **'Finish deletion'**
  String get adminFinishDeletion;

  /// No description provided for @adminCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get adminCancel;

  /// No description provided for @adminDeleteRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete record'**
  String get adminDeleteRecord;

  /// No description provided for @adminEditUser.
  ///
  /// In en, this message translates to:
  /// **'Edit user profile'**
  String get adminEditUser;

  /// No description provided for @adminName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get adminName;

  /// No description provided for @adminPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get adminPhone;

  /// No description provided for @adminSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get adminSaveProfile;

  /// No description provided for @adminAssignedRoute.
  ///
  /// In en, this message translates to:
  /// **'Assigned route'**
  String get adminAssignedRoute;

  /// No description provided for @adminNoRoute.
  ///
  /// In en, this message translates to:
  /// **'No route / remove assignment'**
  String get adminNoRoute;

  /// No description provided for @adminAssignmentReason.
  ///
  /// In en, this message translates to:
  /// **'Assignment reason (at least 10 characters)'**
  String get adminAssignmentReason;

  /// No description provided for @adminSaveAssignment.
  ///
  /// In en, this message translates to:
  /// **'Save assignment'**
  String get adminSaveAssignment;

  /// No description provided for @adminDecision.
  ///
  /// In en, this message translates to:
  /// **'Decision'**
  String get adminDecision;

  /// No description provided for @adminApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminApprove;

  /// No description provided for @adminReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adminReject;

  /// No description provided for @adminRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke access'**
  String get adminRevoke;

  /// No description provided for @adminReviewReason.
  ///
  /// In en, this message translates to:
  /// **'Review evidence / reason'**
  String get adminReviewReason;

  /// No description provided for @adminConfirmDecision.
  ///
  /// In en, this message translates to:
  /// **'Confirm decision'**
  String get adminConfirmDecision;

  /// No description provided for @adminApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get adminApproved;

  /// No description provided for @adminRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get adminRejected;

  /// No description provided for @adminRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get adminRevoked;

  /// No description provided for @adminPending.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get adminPending;

  /// No description provided for @adminUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get adminUnassigned;

  /// No description provided for @adminAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get adminAdd;

  /// No description provided for @adminBusStop.
  ///
  /// In en, this message translates to:
  /// **'bus stop'**
  String get adminBusStop;

  /// No description provided for @adminBusTimetable.
  ///
  /// In en, this message translates to:
  /// **'bus / timetable'**
  String get adminBusTimetable;

  /// No description provided for @adminRoute.
  ///
  /// In en, this message translates to:
  /// **'route'**
  String get adminRoute;

  /// No description provided for @adminRecordId.
  ///
  /// In en, this message translates to:
  /// **'Record ID'**
  String get adminRecordId;

  /// No description provided for @adminStopName.
  ///
  /// In en, this message translates to:
  /// **'Stop name'**
  String get adminStopName;

  /// No description provided for @adminSourceUrl.
  ///
  /// In en, this message translates to:
  /// **'Source URL'**
  String get adminSourceUrl;

  /// No description provided for @adminUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown / not assessed'**
  String get adminUnknown;

  /// No description provided for @adminEquipped.
  ///
  /// In en, this message translates to:
  /// **'Equipped'**
  String get adminEquipped;

  /// No description provided for @adminNotEquipped.
  ///
  /// In en, this message translates to:
  /// **'Not equipped'**
  String get adminNotEquipped;

  /// No description provided for @adminYesAssessed.
  ///
  /// In en, this message translates to:
  /// **'Yes - assessed'**
  String get adminYesAssessed;

  /// No description provided for @adminNoAssessed.
  ///
  /// In en, this message translates to:
  /// **'No - assessed'**
  String get adminNoAssessed;

  /// No description provided for @adminCatalogueType.
  ///
  /// In en, this message translates to:
  /// **'Catalogue record type'**
  String get adminCatalogueType;

  /// No description provided for @adminPhysicalVehicle.
  ///
  /// In en, this message translates to:
  /// **'Physical vehicle'**
  String get adminPhysicalVehicle;

  /// No description provided for @adminPublishedTimetable.
  ///
  /// In en, this message translates to:
  /// **'Published timetable'**
  String get adminPublishedTimetable;

  /// No description provided for @adminRouteField.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get adminRouteField;

  /// No description provided for @adminDriverField.
  ///
  /// In en, this message translates to:
  /// **'Assigned driver'**
  String get adminDriverField;

  /// No description provided for @adminScheduledTime.
  ///
  /// In en, this message translates to:
  /// **'Scheduled time (HH:mm)'**
  String get adminScheduledTime;

  /// No description provided for @adminAddStop.
  ///
  /// In en, this message translates to:
  /// **'Add a stop'**
  String get adminAddStop;

  /// No description provided for @adminSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get adminSaving;

  /// No description provided for @adminSaveCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Save catalogue record'**
  String get adminSaveCatalogue;

  /// No description provided for @adminReloadReferences.
  ///
  /// In en, this message translates to:
  /// **'Reload reference data'**
  String get adminReloadReferences;

  /// No description provided for @adminOpenPassenger.
  ///
  /// In en, this message translates to:
  /// **'Open passenger app'**
  String get adminOpenPassenger;

  /// No description provided for @adminTransit.
  ///
  /// In en, this message translates to:
  /// **'Transit administration'**
  String get adminTransit;

  /// No description provided for @adminChangeConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Change confirmed by the server.'**
  String get adminChangeConfirmed;

  /// No description provided for @adminSourceChecked.
  ///
  /// In en, this message translates to:
  /// **'I reviewed the source and the entered catalogue details.'**
  String get adminSourceChecked;

  /// No description provided for @adminDeleteHelp.
  ///
  /// In en, this message translates to:
  /// **'This removes the catalogue record. Referenced records and active buses cannot be deleted. This action cannot be undone.'**
  String get adminDeleteHelp;

  /// No description provided for @adminDriverChecked.
  ///
  /// In en, this message translates to:
  /// **'I checked this driver\'s identity and operating authority.'**
  String get adminDriverChecked;

  /// No description provided for @adminSourceLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load server records. Check your connection/access and retry.'**
  String get adminSourceLoadError;

  /// No description provided for @adminLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get adminLatitude;

  /// No description provided for @adminLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get adminLongitude;

  /// No description provided for @adminRamp.
  ///
  /// In en, this message translates to:
  /// **'Ramp capability'**
  String get adminRamp;

  /// No description provided for @adminElevator.
  ///
  /// In en, this message translates to:
  /// **'Elevator capability'**
  String get adminElevator;

  /// No description provided for @adminStepFree.
  ///
  /// In en, this message translates to:
  /// **'Assessed step-free path'**
  String get adminStepFree;

  /// No description provided for @adminRouteNumber.
  ///
  /// In en, this message translates to:
  /// **'Route number'**
  String get adminRouteNumber;

  /// No description provided for @adminRouteName.
  ///
  /// In en, this message translates to:
  /// **'Route name'**
  String get adminRouteName;

  /// No description provided for @adminDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get adminDescription;

  /// No description provided for @adminVehicleRegistration.
  ///
  /// In en, this message translates to:
  /// **'Vehicle registration number'**
  String get adminVehicleRegistration;

  /// No description provided for @adminLowFloor.
  ///
  /// In en, this message translates to:
  /// **'Low-floor capability'**
  String get adminLowFloor;

  /// No description provided for @adminStableId.
  ///
  /// In en, this message translates to:
  /// **'Stable identifier. Cannot be changed after creation.'**
  String get adminStableId;

  /// No description provided for @adminSourceHelp.
  ///
  /// In en, this message translates to:
  /// **'Authoritative timetable, stop or operator source. This is not a live-service verification.'**
  String get adminSourceHelp;

  /// No description provided for @adminOverviewHelp.
  ///
  /// In en, this message translates to:
  /// **'Maintain sourced catalogue records and review operator access. All changes require server acknowledgement.'**
  String get adminOverviewHelp;

  /// No description provided for @adminRegistrationHelp.
  ///
  /// In en, this message translates to:
  /// **'Driver registration is an application for access. Review identity and operating authority before approval. Approval does not verify equipment or guarantee a service.'**
  String get adminRegistrationHelp;

  /// No description provided for @adminBusCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Buses & timetables (loaded)'**
  String get adminBusCountLabel;

  /// No description provided for @adminRouteCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Routes (loaded)'**
  String get adminRouteCountLabel;

  /// No description provided for @adminStopCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Bus stops (loaded)'**
  String get adminStopCountLabel;

  /// No description provided for @adminUserCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Users (loaded)'**
  String get adminUserCountLabel;

  /// No description provided for @adminDriverCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Drivers awaiting review (loaded)'**
  String get adminDriverCountLabel;

  /// No description provided for @adminReferencesError.
  ///
  /// In en, this message translates to:
  /// **'Reference records could not be loaded completely. Reload before saving.'**
  String get adminReferencesError;

  /// No description provided for @adminRouteFor.
  ///
  /// In en, this message translates to:
  /// **'Route for {name}'**
  String adminRouteFor(String name);

  /// No description provided for @adminReviewFor.
  ///
  /// In en, this message translates to:
  /// **'Review {name}'**
  String adminReviewFor(String name);

  /// No description provided for @adminDeleteFor.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String adminDeleteFor(String name);

  /// No description provided for @adminAssignedRouteFor.
  ///
  /// In en, this message translates to:
  /// **'Assigned route: {name}'**
  String adminAssignedRouteFor(String name);

  /// No description provided for @adminCurrentAccessFor.
  ///
  /// In en, this message translates to:
  /// **'Current access: {name}'**
  String adminCurrentAccessFor(String name);

  /// No description provided for @adminPreviousReviewFor.
  ///
  /// In en, this message translates to:
  /// **'Previous review: {name}'**
  String adminPreviousReviewFor(String name);

  /// No description provided for @adminNoActiveRoute.
  ///
  /// In en, this message translates to:
  /// **'No active route assignment'**
  String get adminNoActiveRoute;

  /// No description provided for @adminRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get adminRequired;

  /// No description provided for @adminReviewSource.
  ///
  /// In en, this message translates to:
  /// **'Review the source before saving.'**
  String get adminReviewSource;

  /// No description provided for @adminRouteFirst.
  ///
  /// In en, this message translates to:
  /// **'Assign an approved driver to this route first, or release the previous assignment.'**
  String get adminRouteFirst;

  /// No description provided for @adminAuthProfileHelp.
  ///
  /// In en, this message translates to:
  /// **'Login email, passwords and Auth account deletion are managed in Firebase Authentication.'**
  String get adminAuthProfileHelp;

  /// No description provided for @adminReferenceWithdrawHelp.
  ///
  /// In en, this message translates to:
  /// **'Access will be withdrawn and bus assignments released. Active trip/telemetry records remain for reconciliation; they are not marked completed.'**
  String get adminReferenceWithdrawHelp;

  /// No description provided for @adminCapabilityHelp.
  ///
  /// In en, this message translates to:
  /// **'Capability is separate from a working-equipment observation. Operational checks are recorded by the assigned driver.'**
  String get adminCapabilityHelp;

  /// No description provided for @adminTimetableHelp.
  ///
  /// In en, this message translates to:
  /// **'A published timetable has no verified physical vehicle, driver or equipment status.'**
  String get adminTimetableHelp;

  /// No description provided for @adminOrderedStops.
  ///
  /// In en, this message translates to:
  /// **'Stops in travel order'**
  String get adminOrderedStops;

  /// No description provided for @adminMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move stop up'**
  String get adminMoveUp;

  /// No description provided for @adminMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move stop down'**
  String get adminMoveDown;

  /// No description provided for @adminRemoveStop.
  ///
  /// In en, this message translates to:
  /// **'Remove stop'**
  String get adminRemoveStop;

  /// No description provided for @adminChooseRoute.
  ///
  /// In en, this message translates to:
  /// **'Choose a route'**
  String get adminChooseRoute;

  /// No description provided for @adminTimeFormat.
  ///
  /// In en, this message translates to:
  /// **'Use 24-hour HH:mm'**
  String get adminTimeFormat;

  /// No description provided for @adminAssignmentHelp.
  ///
  /// In en, this message translates to:
  /// **'Approval is separate from route assignment. End any active trip before changing or removing a route.'**
  String get adminAssignmentHelp;

  /// No description provided for @adminReviewChecksHelp.
  ///
  /// In en, this message translates to:
  /// **'Record the identity and operating-authority checks or decision reason.'**
  String get adminReviewChecksHelp;

  /// No description provided for @adminChangeUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Change was not confirmed. Check access/connection and reload before retrying.'**
  String get adminChangeUnconfirmed;

  /// No description provided for @adminSaveUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Save was not confirmed. Check connection/access and reload before retrying.'**
  String get adminSaveUnconfirmed;

  /// No description provided for @adminCursorChanged.
  ///
  /// In en, this message translates to:
  /// **'Page cursor changed. Reload.'**
  String get adminCursorChanged;

  /// No description provided for @adminAccountReferenceChanged.
  ///
  /// In en, this message translates to:
  /// **'Account changed. Reload references.'**
  String get adminAccountReferenceChanged;

  /// No description provided for @adminAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Administrator access is required.'**
  String get adminAccessRequired;

  /// No description provided for @adminAccountSignInChanged.
  ///
  /// In en, this message translates to:
  /// **'Account changed. Sign in again.'**
  String get adminAccountSignInChanged;

  /// No description provided for @adminConnectionRequired.
  ///
  /// In en, this message translates to:
  /// **'A server connection is required. Retry when online.'**
  String get adminConnectionRequired;

  /// No description provided for @adminRecordChanged.
  ///
  /// In en, this message translates to:
  /// **'This record changed. Reload it before saving.'**
  String get adminRecordChanged;

  /// No description provided for @adminTwoStops.
  ///
  /// In en, this message translates to:
  /// **'Select at least two distinct stops in travel order.'**
  String get adminTwoStops;

  /// No description provided for @adminOccurrenceStation.
  ///
  /// In en, this message translates to:
  /// **'Every stop occurrence requires an unambiguous physical station.'**
  String get adminOccurrenceStation;

  /// No description provided for @adminSourceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the catalogue source URL.'**
  String get adminSourceInvalid;

  /// No description provided for @adminVehicleTypeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Choose vehicle or published timetable.'**
  String get adminVehicleTypeInvalid;

  /// No description provided for @adminNoTimetableDriver.
  ///
  /// In en, this message translates to:
  /// **'A timetable cannot have a driver assignment.'**
  String get adminNoTimetableDriver;

  /// No description provided for @adminTimePerStop.
  ///
  /// In en, this message translates to:
  /// **'Enter one HH:mm (24-hour) time per stop. Overnight times may roll over.'**
  String get adminTimePerStop;

  /// No description provided for @adminRecordIdInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use letters, numbers, underscores or hyphens for the record ID.'**
  String get adminRecordIdInvalid;

  /// No description provided for @adminRestoreFirst.
  ///
  /// In en, this message translates to:
  /// **'Restore this record before editing it.'**
  String get adminRestoreFirst;

  /// No description provided for @adminReferenceDeleting.
  ///
  /// In en, this message translates to:
  /// **'A referenced record is pending deletion. Restore it or choose another record.'**
  String get adminReferenceDeleting;

  /// No description provided for @adminStopMissing.
  ///
  /// In en, this message translates to:
  /// **'A selected stop no longer exists. Reload the form.'**
  String get adminStopMissing;

  /// No description provided for @adminDependentBuses.
  ///
  /// In en, this message translates to:
  /// **'Update dependent buses before changing the route number or removing/reordering their stops.'**
  String get adminDependentBuses;

  /// No description provided for @adminOccurrenceRebind.
  ///
  /// In en, this message translates to:
  /// **'Existing stop occurrences cannot be rebound to another station. Use new occurrence IDs.'**
  String get adminOccurrenceRebind;

  /// No description provided for @adminRouteMismatch.
  ///
  /// In en, this message translates to:
  /// **'Choose an existing route with the same route number.'**
  String get adminRouteMismatch;

  /// No description provided for @adminStopOrderInvalid.
  ///
  /// In en, this message translates to:
  /// **'Vehicle stops must follow the selected route order.'**
  String get adminStopOrderInvalid;

  /// No description provided for @adminApprovedOnly.
  ///
  /// In en, this message translates to:
  /// **'Only an approved operator may be assigned.'**
  String get adminApprovedOnly;

  /// No description provided for @adminGrantFirst.
  ///
  /// In en, this message translates to:
  /// **'Assign the approved driver to this route first.'**
  String get adminGrantFirst;

  /// No description provided for @adminBusActive.
  ///
  /// In en, this message translates to:
  /// **'This bus has an active trip or broadcast. End it before changing assignment, route or stops.'**
  String get adminBusActive;

  /// No description provided for @adminNotDeleting.
  ///
  /// In en, this message translates to:
  /// **'This record is not pending deletion.'**
  String get adminNotDeleting;

  /// No description provided for @adminReviewInputInvalid.
  ///
  /// In en, this message translates to:
  /// **'Select an operator and enter a review/reason of 10-2000 characters.'**
  String get adminReviewInputInvalid;

  /// No description provided for @adminGrantInputInvalid.
  ///
  /// In en, this message translates to:
  /// **'Select a driver and enter a reason of 10-2000 characters.'**
  String get adminGrantInputInvalid;

  /// No description provided for @adminApproveFirst.
  ///
  /// In en, this message translates to:
  /// **'Approve the driver before assigning a route.'**
  String get adminApproveFirst;

  /// No description provided for @adminReviewedRoute.
  ///
  /// In en, this message translates to:
  /// **'Choose an available reviewed route.'**
  String get adminReviewedRoute;

  /// No description provided for @adminProfileInputInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a name (up to 100 characters) and phone (up to 40).'**
  String get adminProfileInputInvalid;

  /// No description provided for @adminFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required (maximum {maximum} characters).'**
  String adminFieldRequired(String field, int maximum);

  /// No description provided for @adminCoordinateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter valid {field} coordinates.'**
  String adminCoordinateInvalid(String field);

  /// No description provided for @adminDependencyDelete.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete: this record is referenced by {kind}. Remove the dependency or retain it for history.'**
  String adminDependencyDelete(String kind);

  /// No description provided for @adminLoadKindsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not verify {kinds} from the server. Actions are disabled. Use Refresh to retry.'**
  String adminLoadKindsFailed(String kinds);

  /// No description provided for @adminBusSummary.
  ///
  /// In en, this message translates to:
  /// **'Route {route} | {kind}\nDriver: {driver}'**
  String adminBusSummary(String route, String kind, String driver);

  /// No description provided for @adminStopCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ordered stop} other{{count} ordered stops}}'**
  String adminStopCount(int count);

  /// No description provided for @adminAuditBy.
  ///
  /// In en, this message translates to:
  /// **'By {actor}'**
  String adminAuditBy(String actor);

  /// No description provided for @adminTimetableFor.
  ///
  /// In en, this message translates to:
  /// **'Route {route} timetable'**
  String adminTimetableFor(String route);

  /// No description provided for @adminRunHelp.
  ///
  /// In en, this message translates to:
  /// **'Publish this bus timetable for a specific Colombo service date. Starting the run opens boarding; departure is recorded separately.'**
  String get adminRunHelp;

  /// No description provided for @adminRunRescheduleHelp.
  ///
  /// In en, this message translates to:
  /// **'To reschedule, cancel the previous scheduled run and publish its replacement. Stop intervals are retained; the bus timetable stays unchanged.'**
  String get adminRunRescheduleHelp;

  /// No description provided for @adminRunWindowHelp.
  ///
  /// In en, this message translates to:
  /// **'Start window: 5 minutes before to 30 minutes after departure. Late starts require a reason.'**
  String get adminRunWindowHelp;

  /// No description provided for @adminRunPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish dated departure'**
  String get adminRunPublish;

  /// No description provided for @adminRunReload.
  ///
  /// In en, this message translates to:
  /// **'Reload departures'**
  String get adminRunReload;

  /// No description provided for @adminRunCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel scheduled run'**
  String get adminRunCancel;

  /// No description provided for @adminRunConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Dated departure change confirmed.'**
  String get adminRunConfirmed;

  /// No description provided for @adminRunLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load dated departures. Retry when online.'**
  String get adminRunLoadFailed;

  /// No description provided for @adminRunChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Change was not confirmed. Reload and retry.'**
  String get adminRunChangeFailed;

  /// No description provided for @adminRunReviewTimetable.
  ///
  /// In en, this message translates to:
  /// **'Stored timetable needs administrator review.'**
  String get adminRunReviewTimetable;

  /// No description provided for @adminRunEmpty.
  ///
  /// In en, this message translates to:
  /// **'No dated departures for this bus.'**
  String get adminRunEmpty;

  /// No description provided for @adminRunScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get adminRunScheduled;

  /// No description provided for @adminRunBoarding.
  ///
  /// In en, this message translates to:
  /// **'Boarding'**
  String get adminRunBoarding;

  /// No description provided for @adminRunInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get adminRunInProgress;

  /// No description provided for @adminRunCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get adminRunCompleted;

  /// No description provided for @adminRunCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get adminRunCancelled;

  /// No description provided for @adminRunUnknown.
  ///
  /// In en, this message translates to:
  /// **'Status unavailable'**
  String get adminRunUnknown;

  /// No description provided for @adminCalendarDatesInvalid.
  ///
  /// In en, this message translates to:
  /// **'Choose weekdays and a date range of at most 31 days.'**
  String get adminCalendarDatesInvalid;

  /// No description provided for @adminCalendarReload.
  ///
  /// In en, this message translates to:
  /// **'Reload the published calendar.'**
  String get adminCalendarReload;

  /// No description provided for @adminCalendarPublishedOnly.
  ///
  /// In en, this message translates to:
  /// **'Only a published calendar can generate departures.'**
  String get adminCalendarPublishedOnly;

  /// No description provided for @adminCalendarInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid calendar. Publish a reviewed replacement.'**
  String get adminCalendarInvalid;

  /// No description provided for @adminCalendarBusChanged.
  ///
  /// In en, this message translates to:
  /// **'The bus timetable changed. Publish a reviewed replacement calendar.'**
  String get adminCalendarBusChanged;

  /// No description provided for @adminColomboTimeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Choose a valid Colombo departure time.'**
  String get adminColomboTimeInvalid;

  /// No description provided for @adminPhysicalBusRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose an available physical bus.'**
  String get adminPhysicalBusRequired;

  /// No description provided for @adminCompleteTimetableRequired.
  ///
  /// In en, this message translates to:
  /// **'A complete reviewed timetable is required for a dated run.'**
  String get adminCompleteTimetableRequired;

  /// No description provided for @adminRouteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Route unavailable.'**
  String get adminRouteUnavailable;

  /// No description provided for @adminRescheduleInputInvalid.
  ///
  /// In en, this message translates to:
  /// **'Choose an unreplaced, not-started run and a public reason (5–300 characters).'**
  String get adminRescheduleInputInvalid;

  /// No description provided for @adminReviewBusTimetable.
  ///
  /// In en, this message translates to:
  /// **'Review the current physical bus timetable first.'**
  String get adminReviewBusTimetable;

  /// No description provided for @adminDifferentDeparture.
  ///
  /// In en, this message translates to:
  /// **'Choose a different departure time.'**
  String get adminDifferentDeparture;

  /// No description provided for @adminReviewScheduleVersion.
  ///
  /// In en, this message translates to:
  /// **'Review the original schedule version.'**
  String get adminReviewScheduleVersion;

  /// No description provided for @adminReconcileFirst.
  ///
  /// In en, this message translates to:
  /// **'Reconcile the active operation first.'**
  String get adminReconcileFirst;

  /// No description provided for @adminCancelNotStartedOnly.
  ///
  /// In en, this message translates to:
  /// **'Only a not-started run can be cancelled here.'**
  String get adminCancelNotStartedOnly;

  /// No description provided for @adminServiceDate.
  ///
  /// In en, this message translates to:
  /// **'Service date: {date}'**
  String adminServiceDate(String date);

  /// No description provided for @adminColomboDeparture.
  ///
  /// In en, this message translates to:
  /// **'Colombo departure: {time}'**
  String adminColomboDeparture(String time);

  /// No description provided for @adminLateReason.
  ///
  /// In en, this message translates to:
  /// **'Late-start reason: {reason}'**
  String adminLateReason(String reason);

  /// No description provided for @adminPublishedStopTimes.
  ///
  /// In en, this message translates to:
  /// **'Published stop times: {times}'**
  String adminPublishedStopTimes(String times);

  /// No description provided for @adminColomboDateTime.
  ///
  /// In en, this message translates to:
  /// **'{date} {time} (Asia/Colombo)'**
  String adminColomboDateTime(String date, String time);

  /// No description provided for @adminGeometryRouteId.
  ///
  /// In en, this message translates to:
  /// **'Route ID'**
  String get adminGeometryRouteId;

  /// No description provided for @adminGeometryImportJson.
  ///
  /// In en, this message translates to:
  /// **'Reviewed road geometry JSON'**
  String get adminGeometryImportJson;

  /// No description provided for @adminGeometryActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Geometry change was not confirmed. Check access, review reason and current route/stop data before retrying.'**
  String get adminGeometryActionFailed;

  /// No description provided for @adminFareLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Fare publications could not be loaded. Reload when connected; no empty catalogue has been confirmed.'**
  String get adminFareLoadFailed;

  /// No description provided for @adminFarePublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get adminFarePublished;

  /// No description provided for @adminFareArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get adminFareArchived;

  /// No description provided for @adminFarePublicationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid fare publication'**
  String get adminFarePublicationInvalid;

  /// No description provided for @adminFareBusesRequired.
  ///
  /// In en, this message translates to:
  /// **'Select reviewed buses'**
  String get adminFareBusesRequired;

  /// No description provided for @adminFareSplitRequired.
  ///
  /// In en, this message translates to:
  /// **'Split this publication into smaller reviewed records'**
  String get adminFareSplitRequired;

  /// No description provided for @adminFareApplicabilityMismatch.
  ///
  /// In en, this message translates to:
  /// **'Tariff/mapping applicability mismatch'**
  String get adminFareApplicabilityMismatch;

  /// No description provided for @adminFareReviewRequired.
  ///
  /// In en, this message translates to:
  /// **'Review source, stages, class and effective dates; enter a review reason.'**
  String get adminFareReviewRequired;

  /// No description provided for @adminFareRouteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Route is unavailable'**
  String get adminFareRouteUnavailable;

  /// No description provided for @adminFareItineraryMismatch.
  ///
  /// In en, this message translates to:
  /// **'A bus itinerary or route does not match the reviewed mapping'**
  String get adminFareItineraryMismatch;

  /// No description provided for @adminFareArchiveReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an archive reason'**
  String get adminFareArchiveReasonRequired;

  /// No description provided for @adminFareTextInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid fare catalogue text'**
  String get adminFareTextInvalid;

  /// No description provided for @adminFareDateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid fare effective date'**
  String get adminFareDateInvalid;

  /// No description provided for @adminFareSourceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid tariff source'**
  String get adminFareSourceInvalid;

  /// No description provided for @adminFareUnreviewed.
  ///
  /// In en, this message translates to:
  /// **'Unreviewed or unsupported fare table'**
  String get adminFareUnreviewed;

  /// No description provided for @adminFareTableInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid fare table'**
  String get adminFareTableInvalid;

  /// No description provided for @adminFareMatrixInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid fare matrix'**
  String get adminFareMatrixInvalid;

  /// No description provided for @adminFareMinorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid minor-unit fare'**
  String get adminFareMinorInvalid;

  /// No description provided for @adminFareMappingInvalid.
  ///
  /// In en, this message translates to:
  /// **'Unreviewed or invalid fare mapping'**
  String get adminFareMappingInvalid;

  /// No description provided for @adminFareOccurrencesInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid fare occurrences'**
  String get adminFareOccurrencesInvalid;

  /// No description provided for @adminGeometryReviewRequired.
  ///
  /// In en, this message translates to:
  /// **'Review the geometry and enter a reason'**
  String get adminGeometryReviewRequired;

  /// No description provided for @adminGeometryRouteChanged.
  ///
  /// In en, this message translates to:
  /// **'Review the current directed route itinerary'**
  String get adminGeometryRouteChanged;

  /// No description provided for @adminGeometryModeMismatch.
  ///
  /// In en, this message translates to:
  /// **'Geometry belongs to another data mode'**
  String get adminGeometryModeMismatch;

  /// No description provided for @adminGeometryVersionRequired.
  ///
  /// In en, this message translates to:
  /// **'Use a new reviewed version'**
  String get adminGeometryVersionRequired;

  /// No description provided for @adminGeometryStopMismatch.
  ///
  /// In en, this message translates to:
  /// **'Review each stop coordinate and its road vertex'**
  String get adminGeometryStopMismatch;

  /// No description provided for @adminGeometryReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a review reason'**
  String get adminGeometryReasonRequired;

  /// No description provided for @adminGeometryMissing.
  ///
  /// In en, this message translates to:
  /// **'No geometry to withdraw'**
  String get adminGeometryMissing;

  /// No description provided for @adminGeometryDataInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid reviewed route geometry'**
  String get adminGeometryDataInvalid;

  /// No description provided for @adminGeometryStopsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid ordered geometry stops'**
  String get adminGeometryStopsInvalid;

  /// No description provided for @adminGeometryCoordinatesInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid coordinates'**
  String get adminGeometryCoordinatesInvalid;

  /// No description provided for @adminGeometryVerticesInvalid.
  ///
  /// In en, this message translates to:
  /// **'Stop vertices must increase'**
  String get adminGeometryVerticesInvalid;

  /// No description provided for @adminGeometryResolutionInvalid.
  ///
  /// In en, this message translates to:
  /// **'Review road path resolution'**
  String get adminGeometryResolutionInvalid;

  /// No description provided for @adminGeometryTooLong.
  ///
  /// In en, this message translates to:
  /// **'Route too long'**
  String get adminGeometryTooLong;

  /// No description provided for @adminFarePreviewRoute.
  ///
  /// In en, this message translates to:
  /// **'Route: {route} · service class: {serviceClass}'**
  String adminFarePreviewRoute(String route, String serviceClass);

  /// No description provided for @adminFarePreviewDates.
  ///
  /// In en, this message translates to:
  /// **'Effective dates: {from} – {until}'**
  String adminFarePreviewDates(String from, String until);

  /// No description provided for @adminImportSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String adminImportSource(String source);

  /// No description provided for @adminFareVersions.
  ///
  /// In en, this message translates to:
  /// **'Fare version: {table} · mapping version: {mapping}'**
  String adminFareVersions(String table, String mapping);

  /// No description provided for @adminFareBuses.
  ///
  /// In en, this message translates to:
  /// **'Buses: {buses}'**
  String adminFareBuses(String buses);

  /// No description provided for @adminFareCell.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}: {amount}'**
  String adminFareCell(String from, String to, String amount);

  /// No description provided for @adminGeometryVersion.
  ///
  /// In en, this message translates to:
  /// **'Route: {route} · version: {version}'**
  String adminGeometryVersion(String route, String version);

  /// No description provided for @adminGeometryDistance.
  ///
  /// In en, this message translates to:
  /// **'{stops} · {distance} km'**
  String adminGeometryDistance(String stops, String distance);

  /// No description provided for @adminFareRowStatus.
  ///
  /// In en, this message translates to:
  /// **'{status} · version: {version}'**
  String adminFareRowStatus(String status, String version);

  /// No description provided for @reviewAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Administrator access is required to review this case.'**
  String get reviewAccessRequired;

  /// No description provided for @reviewSelfForbidden.
  ///
  /// In en, this message translates to:
  /// **'You cannot review a case concerning your own account.'**
  String get reviewSelfForbidden;

  /// No description provided for @reviewSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Your session is no longer valid. Sign in again before continuing.'**
  String get reviewSignInRequired;

  /// No description provided for @reviewAccountChanged.
  ///
  /// In en, this message translates to:
  /// **'The signed-in account changed. Reopen this screen from the current account.'**
  String get reviewAccountChanged;

  /// No description provided for @reviewRestricted.
  ///
  /// In en, this message translates to:
  /// **'This account cannot perform administrative actions while restricted.'**
  String get reviewRestricted;

  /// No description provided for @reviewAlreadyDecided.
  ///
  /// In en, this message translates to:
  /// **'This review already has a decision. Refresh to inspect the recorded outcome.'**
  String get reviewAlreadyDecided;

  /// No description provided for @reviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This review is unavailable. Refresh before taking another action.'**
  String get reviewUnavailable;

  /// No description provided for @reviewOperationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This trip is no longer available for this operation. Refresh its current state.'**
  String get reviewOperationUnavailable;

  /// No description provided for @reviewRetryConflict.
  ///
  /// In en, this message translates to:
  /// **'This request conflicts with a recorded request. Refresh and inspect the outcome before a new action.'**
  String get reviewRetryConflict;

  /// No description provided for @reviewVoteUnknown.
  ///
  /// In en, this message translates to:
  /// **'Vote unavailable'**
  String get reviewVoteUnknown;

  /// No description provided for @reviewRunDriver.
  ///
  /// In en, this message translates to:
  /// **'Run: {run}\nDriver: {driver}'**
  String reviewRunDriver(String run, String driver);

  /// No description provided for @reviewDriverId.
  ///
  /// In en, this message translates to:
  /// **'Driver: {driver}'**
  String reviewDriverId(String driver);

  /// No description provided for @reviewVoteEvidence.
  ///
  /// In en, this message translates to:
  /// **'{user} · {vote}'**
  String reviewVoteEvidence(String user, String vote);

  /// No description provided for @profileMissing.
  ///
  /// In en, this message translates to:
  /// **'No profile found. Please sign in again.'**
  String get profileMissing;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load profile from the database.'**
  String get profileLoadFailed;

  /// No description provided for @profileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Profile unavailable.'**
  String get profileUnavailable;

  /// No description provided for @profilePassenger.
  ///
  /// In en, this message translates to:
  /// **'Passenger'**
  String get profilePassenger;

  /// No description provided for @profileContributor.
  ///
  /// In en, this message translates to:
  /// **'Community Contributor'**
  String get profileContributor;

  /// No description provided for @profileOperator.
  ///
  /// In en, this message translates to:
  /// **'Transit Bus Operator'**
  String get profileOperator;

  /// No description provided for @profileAdministrator.
  ///
  /// In en, this message translates to:
  /// **'System Administrator'**
  String get profileAdministrator;

  /// No description provided for @profileCommuter.
  ///
  /// In en, this message translates to:
  /// **'Inclusive Commuter'**
  String get profileCommuter;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get profileEdit;

  /// No description provided for @profileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditTitle;

  /// No description provided for @profileFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get profileFullName;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get profileEmail;

  /// No description provided for @profilePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get profilePhone;

  /// No description provided for @profileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get profileNameRequired;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get profileSave;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileSaved;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Profile changes could not be confirmed. Please retry.'**
  String get profileSaveFailed;

  /// No description provided for @profileSignOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not clear private drafts or sign out. Please retry.'**
  String get profileSignOutFailed;

  /// No description provided for @profileSignedOut.
  ///
  /// In en, this message translates to:
  /// **'You have been signed out successfully.'**
  String get profileSignedOut;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profileSignOut;

  /// No description provided for @profileCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileCancel;

  /// No description provided for @profileRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get profileRetry;

  /// No description provided for @profileLogoutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Sign out and remove pending report drafts and photos from this device? Requests already sent may still complete. Published reports remain available after signing back in.'**
  String get profileLogoutQuestion;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get profileSettings;

  /// No description provided for @profileSupport.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT'**
  String get profileSupport;

  /// No description provided for @profilePersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'PERSONAL INFORMATION'**
  String get profilePersonalInfo;

  /// No description provided for @profileAdminConsole.
  ///
  /// In en, this message translates to:
  /// **'Admin console'**
  String get profileAdminConsole;

  /// No description provided for @profileAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility Preferences'**
  String get profileAccessibility;

  /// No description provided for @profilePush.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get profilePush;

  /// No description provided for @profilePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get profilePassword;

  /// No description provided for @profilePlaces.
  ///
  /// In en, this message translates to:
  /// **'Saved Places'**
  String get profilePlaces;

  /// No description provided for @profileRate.
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get profileRate;

  /// No description provided for @profileHelp.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get profileHelp;

  /// No description provided for @profileUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get profileUpdates;

  /// No description provided for @profileNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get profileNotSet;

  /// No description provided for @profileReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get profileReports;

  /// No description provided for @profileVerifications.
  ///
  /// In en, this message translates to:
  /// **'Verifications'**
  String get profileVerifications;

  /// No description provided for @profileBadges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get profileBadges;

  /// No description provided for @profileImpact.
  ///
  /// In en, this message translates to:
  /// **'Community Impact Score'**
  String get profileImpact;

  /// No description provided for @profileSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See All →'**
  String get profileSeeAll;

  /// No description provided for @profileBadgeDetails.
  ///
  /// In en, this message translates to:
  /// **'View earned badges'**
  String get profileBadgeDetails;

  /// No description provided for @profileDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get profileDelete;

  /// No description provided for @profileDeleteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Self-service deletion is not available here yet'**
  String get profileDeleteUnavailable;

  /// No description provided for @profileComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{feature} will be available in a future update.'**
  String profileComingSoon(String feature);

  /// No description provided for @profileContributionSummary.
  ///
  /// In en, this message translates to:
  /// **'{points} Points • {reports} reports • {badges} badges'**
  String profileContributionSummary(int points, int reports, int badges);

  /// No description provided for @driverDashboard.
  ///
  /// In en, this message translates to:
  /// **'Operator Dashboard'**
  String get driverDashboard;

  /// No description provided for @driverFallback.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get driverFallback;

  /// No description provided for @driverAddStop.
  ///
  /// In en, this message translates to:
  /// **'Add Station to Route'**
  String get driverAddStop;

  /// No description provided for @driverNoBuses.
  ///
  /// In en, this message translates to:
  /// **'No physical buses are available on your assigned route. Ask the administrator to add or review a bus.'**
  String get driverNoBuses;

  /// No description provided for @driverNoGps.
  ///
  /// In en, this message translates to:
  /// **'No shared GPS update'**
  String get driverNoGps;

  /// No description provided for @driverBusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Selected bus unavailable; broadcasting stopped locally'**
  String get driverBusUnavailable;

  /// No description provided for @driverAssignmentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Bus assignment unavailable; broadcasting stopped locally'**
  String get driverAssignmentUnavailable;

  /// No description provided for @driverVerifyRuns.
  ///
  /// In en, this message translates to:
  /// **'Connect to verify dated departures.'**
  String get driverVerifyRuns;

  /// No description provided for @driverSignInFirst.
  ///
  /// In en, this message translates to:
  /// **'Sign in as an approved operator first.'**
  String get driverSignInFirst;

  /// No description provided for @driverAssignedOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the assigned driver can update this bus.'**
  String get driverAssignedOnly;

  /// No description provided for @driverClaimFailed.
  ///
  /// In en, this message translates to:
  /// **'Bus assignment was not confirmed. Refresh and retry.'**
  String get driverClaimFailed;

  /// No description provided for @driverRampWorkingSaved.
  ///
  /// In en, this message translates to:
  /// **'Ramp working observation saved'**
  String get driverRampWorkingSaved;

  /// No description provided for @driverRampBrokenSaved.
  ///
  /// In en, this message translates to:
  /// **'Ramp broken observation saved'**
  String get driverRampBrokenSaved;

  /// No description provided for @driverRampFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm all ramp updates. Refresh and retry.'**
  String get driverRampFailed;

  /// No description provided for @driverOccupancyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm all occupancy updates. Refresh and retry.'**
  String get driverOccupancyFailed;

  /// No description provided for @driverClaimFirst.
  ///
  /// In en, this message translates to:
  /// **'Claim this bus before starting a trip.'**
  String get driverClaimFirst;

  /// No description provided for @driverSelectRun.
  ///
  /// In en, this message translates to:
  /// **'Select an administrator-published dated departure.'**
  String get driverSelectRun;

  /// No description provided for @driverLateTitle.
  ///
  /// In en, this message translates to:
  /// **'Late start reason'**
  String get driverLateTitle;

  /// No description provided for @driverLateHelp.
  ///
  /// In en, this message translates to:
  /// **'At least 5 characters. Latest start is 30 minutes after departure.'**
  String get driverLateHelp;

  /// No description provided for @driverContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get driverContinue;

  /// No description provided for @driverLateRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a late-start reason of at least 5 characters.'**
  String get driverLateRequired;

  /// No description provided for @driverGpsAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Shared GPS acknowledged'**
  String get driverGpsAcknowledged;

  /// No description provided for @driverTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'AccessTransit Live Bus Tracking'**
  String get driverTrackingTitle;

  /// No description provided for @driverGpsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'GPS unavailable; last shared fix may be stale'**
  String get driverGpsUnavailable;

  /// No description provided for @driverGpsStreamError.
  ///
  /// In en, this message translates to:
  /// **'GPS updates unavailable. Check location access and retry.'**
  String get driverGpsStreamError;

  /// No description provided for @driverBoardingStarted.
  ///
  /// In en, this message translates to:
  /// **'Boarding session started. Record actual departure when leaving.'**
  String get driverBoardingStarted;

  /// No description provided for @driverRunResumed.
  ///
  /// In en, this message translates to:
  /// **'Active dated trip resumed. GPS broadcasting acknowledged.'**
  String get driverRunResumed;

  /// No description provided for @driverStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Trip start was not confirmed. Refresh and retry.'**
  String get driverStartFailed;

  /// No description provided for @driverGpsPending.
  ///
  /// In en, this message translates to:
  /// **'Pending GPS upload; coordinates are local'**
  String get driverGpsPending;

  /// No description provided for @driverGpsRetry.
  ///
  /// In en, this message translates to:
  /// **'GPS upload failed/offline; next fix retries'**
  String get driverGpsRetry;

  /// No description provided for @driverBoardingEnded.
  ///
  /// In en, this message translates to:
  /// **'Boarding cancelled; broadcast ended'**
  String get driverBoardingEnded;

  /// No description provided for @driverCompletionAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Shared trip completion acknowledged'**
  String get driverCompletionAcknowledged;

  /// No description provided for @driverBoardingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Boarding cancelled. Broadcasting ended.'**
  String get driverBoardingCancelled;

  /// No description provided for @driverTripCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trip completion saved. Broadcasting ended.'**
  String get driverTripCompleted;

  /// No description provided for @driverStopPending.
  ///
  /// In en, this message translates to:
  /// **'GPS stopped locally; shared completion failed. Retry Stop.'**
  String get driverStopPending;

  /// No description provided for @driverStopFailed.
  ///
  /// In en, this message translates to:
  /// **'Shared trip completion was not confirmed. Retry Stop.'**
  String get driverStopFailed;

  /// No description provided for @driverDatedDeparture.
  ///
  /// In en, this message translates to:
  /// **'Dated departure'**
  String get driverDatedDeparture;

  /// No description provided for @driverNoRuns.
  ///
  /// In en, this message translates to:
  /// **'No dated departures published. Ask the administrator to schedule this bus.'**
  String get driverNoRuns;

  /// No description provided for @driverColomboDeparture.
  ///
  /// In en, this message translates to:
  /// **'Colombo service departure'**
  String get driverColomboDeparture;

  /// No description provided for @driverBoardingHelp.
  ///
  /// In en, this message translates to:
  /// **'Starting opens boarding. Record actual departure separately; late starts require a reason.'**
  String get driverBoardingHelp;

  /// No description provided for @driverDepartureSaved.
  ///
  /// In en, this message translates to:
  /// **'Actual departure confirmed by the server.'**
  String get driverDepartureSaved;

  /// No description provided for @driverDepartureFailed.
  ///
  /// In en, this message translates to:
  /// **'Departure was not confirmed. Refresh and retry.'**
  String get driverDepartureFailed;

  /// No description provided for @driverRecordDeparture.
  ///
  /// In en, this message translates to:
  /// **'Record actual departure'**
  String get driverRecordDeparture;

  /// No description provided for @driverActive.
  ///
  /// In en, this message translates to:
  /// **'TRIP IN PROGRESS'**
  String get driverActive;

  /// No description provided for @driverInactive.
  ///
  /// In en, this message translates to:
  /// **'TRIP INACTIVE'**
  String get driverInactive;

  /// No description provided for @driverStart.
  ///
  /// In en, this message translates to:
  /// **'Start Trip'**
  String get driverStart;

  /// No description provided for @driverStop.
  ///
  /// In en, this message translates to:
  /// **'Stop Trip'**
  String get driverStop;

  /// No description provided for @driverTelemetry.
  ///
  /// In en, this message translates to:
  /// **'Live Telemetry Data'**
  String get driverTelemetry;

  /// No description provided for @driverGpsInactive.
  ///
  /// In en, this message translates to:
  /// **'GPS inactive. Press Start Trip to acquire live GPS location.'**
  String get driverGpsInactive;

  /// No description provided for @driverLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude:'**
  String get driverLatitude;

  /// No description provided for @driverLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude:'**
  String get driverLongitude;

  /// No description provided for @driverSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed:'**
  String get driverSpeed;

  /// No description provided for @driverHeading.
  ///
  /// In en, this message translates to:
  /// **'Heading:'**
  String get driverHeading;

  /// No description provided for @driverLocalFix.
  ///
  /// In en, this message translates to:
  /// **'Local GPS fix:'**
  String get driverLocalFix;

  /// No description provided for @driverAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Accessibility Status'**
  String get driverAccessibility;

  /// No description provided for @driverReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-only (Not assigned)'**
  String get driverReadOnly;

  /// No description provided for @driverRampObservation.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair ramp observation'**
  String get driverRampObservation;

  /// No description provided for @driverUnknownRamp.
  ///
  /// In en, this message translates to:
  /// **'Unknown - check before selecting'**
  String get driverUnknownRamp;

  /// No description provided for @driverWorkingObserved.
  ///
  /// In en, this message translates to:
  /// **'Working observed'**
  String get driverWorkingObserved;

  /// No description provided for @driverBrokenObserved.
  ///
  /// In en, this message translates to:
  /// **'Broken observed'**
  String get driverBrokenObserved;

  /// No description provided for @driverLift.
  ///
  /// In en, this message translates to:
  /// **'Low-Floor Elevator / Lift Working'**
  String get driverLift;

  /// No description provided for @driverStopLiftHelp.
  ///
  /// In en, this message translates to:
  /// **'Stop lift observations are reported separately'**
  String get driverStopLiftHelp;

  /// No description provided for @driverOccupancy.
  ///
  /// In en, this message translates to:
  /// **'Occupancy Level:'**
  String get driverOccupancy;

  /// No description provided for @driverLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get driverLow;

  /// No description provided for @driverMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get driverMedium;

  /// No description provided for @driverHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get driverHigh;

  /// No description provided for @driverAccess.
  ///
  /// In en, this message translates to:
  /// **'Operator access'**
  String get driverAccess;

  /// No description provided for @driverChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking operator approval...'**
  String get driverChecking;

  /// No description provided for @driverSignInApproval.
  ///
  /// In en, this message translates to:
  /// **'Sign in to check operator approval.'**
  String get driverSignInApproval;

  /// No description provided for @driverApprovalRequired.
  ///
  /// In en, this message translates to:
  /// **'Operator approval required. Ask the project administrator to review your account. Selecting Operator at registration does not grant approval. A live connection is required to verify access.'**
  String get driverApprovalRequired;

  /// No description provided for @driverCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get driverCheckAgain;

  /// No description provided for @driverReturnSignIn.
  ///
  /// In en, this message translates to:
  /// **'Return to sign in'**
  String get driverReturnSignIn;

  /// No description provided for @driverSignOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign out. Please retry.'**
  String get driverSignOutFailed;

  /// No description provided for @driverRouteAssignment.
  ///
  /// In en, this message translates to:
  /// **'Driver route assignment'**
  String get driverRouteAssignment;

  /// No description provided for @driverRouteRequired.
  ///
  /// In en, this message translates to:
  /// **'An administrator must assign an available route before you can operate a bus. A live connection is required to verify the assignment.'**
  String get driverRouteRequired;

  /// No description provided for @driverCheckAssignment.
  ///
  /// In en, this message translates to:
  /// **'Check assignment'**
  String get driverCheckAssignment;

  /// No description provided for @driverScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get driverScheduled;

  /// No description provided for @driverBoarding.
  ///
  /// In en, this message translates to:
  /// **'Boarding'**
  String get driverBoarding;

  /// No description provided for @driverInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get driverInProgress;

  /// No description provided for @driverCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get driverCompleted;

  /// No description provided for @driverCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get driverCancelled;

  /// No description provided for @driverUnknownState.
  ///
  /// In en, this message translates to:
  /// **'State unavailable'**
  String get driverUnknownState;

  /// No description provided for @driverName.
  ///
  /// In en, this message translates to:
  /// **'Operator: {name}'**
  String driverName(String name);

  /// No description provided for @driverBusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Bus {bus} is now assigned to you!'**
  String driverBusAssigned(String bus);

  /// No description provided for @driverOccupancySaved.
  ///
  /// In en, this message translates to:
  /// **'Occupancy updated to {level}'**
  String driverOccupancySaved(String level);

  /// No description provided for @driverTrackingBody.
  ///
  /// In en, this message translates to:
  /// **'GPS tracking for Bus {bus}; shared delivery shown in app'**
  String driverTrackingBody(String bus);

  /// No description provided for @driverRunWindow.
  ///
  /// In en, this message translates to:
  /// **'Start window: {earliest} to {latest}'**
  String driverRunWindow(String earliest, String latest);

  /// No description provided for @driverRunOption.
  ///
  /// In en, this message translates to:
  /// **'{time} · {status}'**
  String driverRunOption(String time, String status);

  /// No description provided for @driverActiveSummary.
  ///
  /// In en, this message translates to:
  /// **'{status}\nDuration: {duration}'**
  String driverActiveSummary(String status, String duration);

  /// No description provided for @driverStartHelp.
  ///
  /// In en, this message translates to:
  /// **'Press Start Trip to activate background GPS tracking for Bus {bus}.'**
  String driverStartHelp(String bus);

  /// No description provided for @driverGpsStale.
  ///
  /// In en, this message translates to:
  /// **'Shared GPS stale; {status}'**
  String driverGpsStale(String status);

  /// No description provided for @driverLastReceipt.
  ///
  /// In en, this message translates to:
  /// **'Last shared receipt: {time}'**
  String driverLastReceipt(String time);

  /// No description provided for @driverProgress.
  ///
  /// In en, this message translates to:
  /// **'Trip Route Progress'**
  String get driverProgress;

  /// No description provided for @driverNoActive.
  ///
  /// In en, this message translates to:
  /// **'No Active Trip'**
  String get driverNoActive;

  /// No description provided for @driverNoActiveHelp.
  ///
  /// In en, this message translates to:
  /// **'No active run. Select a dated departure and start boarding above; record actual departure separately when leaving.'**
  String get driverNoActiveHelp;

  /// No description provided for @driverFinalDestination.
  ///
  /// In en, this message translates to:
  /// **'Final Destination Reached'**
  String get driverFinalDestination;

  /// No description provided for @driverFinalAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Final arrival and trip completion acknowledged'**
  String get driverFinalAcknowledged;

  /// No description provided for @driverArrivalFailed.
  ///
  /// In en, this message translates to:
  /// **'Arrival was not confirmed. Refresh and retry.'**
  String get driverArrivalFailed;

  /// No description provided for @driverNextReached.
  ///
  /// In en, this message translates to:
  /// **'Next Stop Reached'**
  String get driverNextReached;

  /// No description provided for @driverFinalReached.
  ///
  /// In en, this message translates to:
  /// **'Final Stop Reached'**
  String get driverFinalReached;

  /// No description provided for @driverEnd.
  ///
  /// In en, this message translates to:
  /// **'End Trip'**
  String get driverEnd;

  /// No description provided for @driverUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get driverUnknown;

  /// No description provided for @driverNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'Not recorded'**
  String get driverNotRecorded;

  /// No description provided for @driverEtaHelp.
  ///
  /// In en, this message translates to:
  /// **'ETAs follow actual departure and recorded arrivals. Missing timetable intervals use a 6-minute estimate; confirm timing with the operator.'**
  String get driverEtaHelp;

  /// No description provided for @driverScheduledArrival.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULED ARRIVAL'**
  String get driverScheduledArrival;

  /// No description provided for @driverTimetableTarget.
  ///
  /// In en, this message translates to:
  /// **'Timetable Target'**
  String get driverTimetableTarget;

  /// No description provided for @driverCurrentEta.
  ///
  /// In en, this message translates to:
  /// **'CURRENT ETA'**
  String get driverCurrentEta;

  /// No description provided for @driverDelayCleared.
  ///
  /// In en, this message translates to:
  /// **'Delay notice removal saved.'**
  String get driverDelayCleared;

  /// No description provided for @driverDelayClearFailed.
  ///
  /// In en, this message translates to:
  /// **'Delay removal was not confirmed. Retry.'**
  String get driverDelayClearFailed;

  /// No description provided for @driverClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get driverClear;

  /// No description provided for @driverUpdateDelay.
  ///
  /// In en, this message translates to:
  /// **'Update Delay / Traffic Reason'**
  String get driverUpdateDelay;

  /// No description provided for @driverReportDelay.
  ///
  /// In en, this message translates to:
  /// **'Report Traffic / Delay (+5m, +10m)'**
  String get driverReportDelay;

  /// No description provided for @driverTraffic.
  ///
  /// In en, this message translates to:
  /// **'Traffic Congestion'**
  String get driverTraffic;

  /// No description provided for @driverRain.
  ///
  /// In en, this message translates to:
  /// **'Heavy Rain / Flooding'**
  String get driverRain;

  /// No description provided for @driverAccident.
  ///
  /// In en, this message translates to:
  /// **'Accident Ahead'**
  String get driverAccident;

  /// No description provided for @driverRoadworks.
  ///
  /// In en, this message translates to:
  /// **'Road Construction'**
  String get driverRoadworks;

  /// No description provided for @driverBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Mechanical Breakdown'**
  String get driverBreakdown;

  /// No description provided for @driverDelayTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Delay / Incident'**
  String get driverDelayTitle;

  /// No description provided for @driverDelayHelp.
  ///
  /// In en, this message translates to:
  /// **'Alerts all passenger screens and updates live ETAs.'**
  String get driverDelayHelp;

  /// No description provided for @driverDelayTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated Delay Time'**
  String get driverDelayTime;

  /// No description provided for @driverDelayReason.
  ///
  /// In en, this message translates to:
  /// **'Delay Reason'**
  String get driverDelayReason;

  /// No description provided for @driverDelayFailed.
  ///
  /// In en, this message translates to:
  /// **'Delay upload was not confirmed. Retry.'**
  String get driverDelayFailed;

  /// No description provided for @driverDepartsNow.
  ///
  /// In en, this message translates to:
  /// **'On Time (Departs Now)'**
  String get driverDepartsNow;

  /// No description provided for @driverOrigin.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get driverOrigin;

  /// No description provided for @driverPreTrip.
  ///
  /// In en, this message translates to:
  /// **'Pre-Trip Schedule Check'**
  String get driverPreTrip;

  /// No description provided for @driverOnTimeMinute.
  ///
  /// In en, this message translates to:
  /// **'On Time (±1 min)'**
  String get driverOnTimeMinute;

  /// No description provided for @driverEarly.
  ///
  /// In en, this message translates to:
  /// **'Running Early'**
  String get driverEarly;

  /// No description provided for @driverOnTimeTarget.
  ///
  /// In en, this message translates to:
  /// **'On Time Target'**
  String get driverOnTimeTarget;

  /// No description provided for @driverDelayed.
  ///
  /// In en, this message translates to:
  /// **'Delayed'**
  String get driverDelayed;

  /// No description provided for @driverMinusFive.
  ///
  /// In en, this message translates to:
  /// **'-5m'**
  String get driverMinusFive;

  /// No description provided for @driverZeroSchedule.
  ///
  /// In en, this message translates to:
  /// **'0 (On Schedule)'**
  String get driverZeroSchedule;

  /// No description provided for @driverPlusFifteen.
  ///
  /// In en, this message translates to:
  /// **'+15m'**
  String get driverPlusFifteen;

  /// No description provided for @driverZeroMinutes.
  ///
  /// In en, this message translates to:
  /// **'0 min'**
  String get driverZeroMinutes;

  /// No description provided for @driverSelectBus.
  ///
  /// In en, this message translates to:
  /// **'Select Bus Run'**
  String get driverSelectBus;

  /// No description provided for @driverAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned to You'**
  String get driverAssigned;

  /// No description provided for @driverAssignMe.
  ///
  /// In en, this message translates to:
  /// **'Assign to Me'**
  String get driverAssignMe;

  /// No description provided for @driverAssignedOther.
  ///
  /// In en, this message translates to:
  /// **'Assigned to another operator'**
  String get driverAssignedOther;

  /// No description provided for @driverUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get driverUpcoming;

  /// No description provided for @driverDeparted.
  ///
  /// In en, this message translates to:
  /// **'Departed'**
  String get driverDeparted;

  /// No description provided for @driverAssistanceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Shared request updates are unavailable. Displayed requests may be out of date.'**
  String get driverAssistanceUnavailable;

  /// No description provided for @driverAssistanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Boarding Assistance Requests'**
  String get driverAssistanceTitle;

  /// No description provided for @driverAssistanceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active assistance requests for this bus.'**
  String get driverAssistanceEmpty;

  /// No description provided for @driverBoardingAt.
  ///
  /// In en, this message translates to:
  /// **'Boarding'**
  String get driverBoardingAt;

  /// No description provided for @driverAlightingAt.
  ///
  /// In en, this message translates to:
  /// **'Getting off'**
  String get driverAlightingAt;

  /// No description provided for @driverStopPosition.
  ///
  /// In en, this message translates to:
  /// **'Current Position: Stop {index} of {total}'**
  String driverStopPosition(int index, int total);

  /// No description provided for @driverNextStop.
  ///
  /// In en, this message translates to:
  /// **'Next Stop: {stop}'**
  String driverNextStop(String stop);

  /// No description provided for @driverArrivalSaved.
  ///
  /// In en, this message translates to:
  /// **'Arrival saved at {stop}. Next: {next}'**
  String driverArrivalSaved(String stop, String next);

  /// No description provided for @driverFinalSaved.
  ///
  /// In en, this message translates to:
  /// **'Final arrival saved at {stop}. Trip completed.'**
  String driverFinalSaved(String stop);

  /// No description provided for @driverTarget.
  ///
  /// In en, this message translates to:
  /// **'Target: {stop}'**
  String driverTarget(String stop);

  /// No description provided for @driverDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination: {stop}'**
  String driverDestination(String stop);

  /// No description provided for @driverPlannedDeparture.
  ///
  /// In en, this message translates to:
  /// **'Planned departure (Colombo): {time}'**
  String driverPlannedDeparture(String time);

  /// No description provided for @driverActualDeparture.
  ///
  /// In en, this message translates to:
  /// **'Actual departure (Colombo): {time}'**
  String driverActualDeparture(String time);

  /// No description provided for @driverBroadcastReason.
  ///
  /// In en, this message translates to:
  /// **'Broadcasted to Riders: {reason}'**
  String driverBroadcastReason(String reason);

  /// No description provided for @driverAddedMinutes.
  ///
  /// In en, this message translates to:
  /// **'+{minutes} mins added to passenger arrival ETAs'**
  String driverAddedMinutes(int minutes);

  /// No description provided for @driverMinuteOption.
  ///
  /// In en, this message translates to:
  /// **'+{minutes} mins'**
  String driverMinuteOption(int minutes);

  /// No description provided for @driverDelaySaved.
  ///
  /// In en, this message translates to:
  /// **'Delay notice saved: {reason} (+{minutes} mins)'**
  String driverDelaySaved(String reason, int minutes);

  /// No description provided for @driverBroadcastDelay.
  ///
  /// In en, this message translates to:
  /// **'Broadcast Delay (+{minutes} mins)'**
  String driverBroadcastDelay(int minutes);

  /// No description provided for @driverDepartsIn.
  ///
  /// In en, this message translates to:
  /// **'Departs in {minutes} mins'**
  String driverDepartsIn(int minutes);

  /// No description provided for @driverLateMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{Delayed by 1 min} other{Delayed by {minutes} mins}}'**
  String driverLateMinutes(int minutes);

  /// No description provided for @driverScheduledDep.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Dep: {time} ({stop})'**
  String driverScheduledDep(String time, String stop);

  /// No description provided for @driverEarlyMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{Running Early (1 min)} other{Running Early ({minutes} mins)}}'**
  String driverEarlyMinutes(int minutes);

  /// No description provided for @driverLateShort.
  ///
  /// In en, this message translates to:
  /// **'+{minutes} min late'**
  String driverLateShort(int minutes);

  /// No description provided for @driverEarlyShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min early'**
  String driverEarlyShort(int minutes);

  /// No description provided for @driverBusOption.
  ///
  /// In en, this message translates to:
  /// **'Bus {bus} (Dep: {time}){endpoints}{assigned}'**
  String driverBusOption(
    String bus,
    String time,
    String endpoints,
    String assigned,
  );

  /// No description provided for @driverRouteName.
  ///
  /// In en, this message translates to:
  /// **'Route {route}'**
  String driverRouteName(String route);

  /// No description provided for @driverDepartureTime.
  ///
  /// In en, this message translates to:
  /// **'Departure: {time}'**
  String driverDepartureTime(String time);

  /// No description provided for @driverStopCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 stop} other{{count} stops}}'**
  String driverStopCount(int count);

  /// No description provided for @driverActiveRequests.
  ///
  /// In en, this message translates to:
  /// **'{count} Active'**
  String driverActiveRequests(int count);

  /// No description provided for @driverClosedRequests.
  ///
  /// In en, this message translates to:
  /// **'Closed requests ({count})'**
  String driverClosedRequests(int count);

  /// No description provided for @driverRequestSummary.
  ///
  /// In en, this message translates to:
  /// **'{rider} at {stop} ({types})'**
  String driverRequestSummary(String rider, String stop, String types);

  /// No description provided for @driverAssistanceStop.
  ///
  /// In en, this message translates to:
  /// **'{purpose} at: {stop}'**
  String driverAssistanceStop(String purpose, String stop);

  /// No description provided for @driverEtaUnavailable.
  ///
  /// In en, this message translates to:
  /// **'ETA unavailable'**
  String get driverEtaUnavailable;

  /// No description provided for @driverSchedulePassed.
  ///
  /// In en, this message translates to:
  /// **'Scheduled time passed'**
  String get driverSchedulePassed;

  /// No description provided for @driverArrivingNow.
  ///
  /// In en, this message translates to:
  /// **'Arriving now'**
  String get driverArrivingNow;

  /// No description provided for @driverScheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for {time}'**
  String driverScheduledFor(String time);

  /// No description provided for @driverTomorrowAt.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow at {time}'**
  String driverTomorrowAt(String time);

  /// No description provided for @driverTomorrowIn.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow at {time} (in {hours}h {minutes}m)'**
  String driverTomorrowIn(String time, int hours, int minutes);

  /// No description provided for @driverDepartedAgo.
  ///
  /// In en, this message translates to:
  /// **'Departed {minutes} mins ago'**
  String driverDepartedAgo(int minutes);

  /// No description provided for @driverArrivingMinutes.
  ///
  /// In en, this message translates to:
  /// **'Arriving in {minutes} mins'**
  String driverArrivingMinutes(int minutes);

  /// No description provided for @driverArrivingHours.
  ///
  /// In en, this message translates to:
  /// **'Arriving in {hours}h {minutes}m'**
  String driverArrivingHours(int hours, int minutes);

  /// No description provided for @recoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get recoveryTitle;

  /// No description provided for @recoveryCheckEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get recoveryCheckEmail;

  /// No description provided for @recoveryInboxHelp.
  ///
  /// In en, this message translates to:
  /// **'Please check your inbox and follow the link to create a new password.'**
  String get recoveryInboxHelp;

  /// No description provided for @recoveryBackLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get recoveryBackLogin;

  /// No description provided for @recoveryResend.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get recoveryResend;

  /// No description provided for @recoveryForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get recoveryForgot;

  /// No description provided for @recoveryEmailHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter the email address associated with your account and we\'ll send you instructions to reset your password.'**
  String get recoveryEmailHelp;

  /// No description provided for @recoveryEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get recoveryEmail;

  /// No description provided for @recoveryEmailHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., name@example.com'**
  String get recoveryEmailHint;

  /// No description provided for @recoveryPrivacy.
  ///
  /// In en, this message translates to:
  /// **'We will never share your email.'**
  String get recoveryPrivacy;

  /// No description provided for @recoverySend.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get recoverySend;

  /// No description provided for @recoveryCreate.
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get recoveryCreate;

  /// No description provided for @recoveryPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Please choose a strong password that you haven\'t used before.'**
  String get recoveryPasswordHelp;

  /// No description provided for @recoveryNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get recoveryNewPassword;

  /// No description provided for @recoveryPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password'**
  String get recoveryPasswordHint;

  /// No description provided for @recoveryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get recoveryConfirm;

  /// No description provided for @recoveryConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your new password'**
  String get recoveryConfirmHint;

  /// No description provided for @recoveryShow.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get recoveryShow;

  /// No description provided for @recoveryHide.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get recoveryHide;

  /// No description provided for @recoverySecurity.
  ///
  /// In en, this message translates to:
  /// **'Your security is our priority.'**
  String get recoverySecurity;

  /// No description provided for @recoveryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password Updated'**
  String get recoveryUpdated;

  /// No description provided for @recoverySuccess.
  ///
  /// In en, this message translates to:
  /// **'Your password has been reset successfully. You can now sign in with your new password.'**
  String get recoverySuccess;

  /// No description provided for @recoveryGoLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get recoveryGoLogin;

  /// No description provided for @recoveryEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address.'**
  String get recoveryEmailRequired;

  /// No description provided for @recoveryEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get recoveryEmailInvalid;

  /// No description provided for @recoveryAccountMissing.
  ///
  /// In en, this message translates to:
  /// **'No account was found with this email address.'**
  String get recoveryAccountMissing;

  /// No description provided for @recoveryDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get recoveryDisabled;

  /// No description provided for @recoveryTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again later.'**
  String get recoveryTooMany;

  /// No description provided for @recoveryNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your internet connection.'**
  String get recoveryNetwork;

  /// No description provided for @recoverySendFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to send password reset email.'**
  String get recoverySendFailed;

  /// No description provided for @recoveryResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to reset password. Please try again.'**
  String get recoveryResetFailed;

  /// No description provided for @recoveryLinkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This reset link is invalid or has expired. Please request a new one.'**
  String get recoveryLinkUnavailable;

  /// No description provided for @recoveryExpired.
  ///
  /// In en, this message translates to:
  /// **'This reset link has expired. Please request a new one.'**
  String get recoveryExpired;

  /// No description provided for @recoveryInvalid.
  ///
  /// In en, this message translates to:
  /// **'This reset link is invalid. Please request a new one.'**
  String get recoveryInvalid;

  /// No description provided for @recoveryWeak.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Please choose a stronger password.'**
  String get recoveryWeak;

  /// No description provided for @recoveryCreateRequired.
  ///
  /// In en, this message translates to:
  /// **'Please create a password.'**
  String get recoveryCreateRequired;

  /// No description provided for @recoveryEightCharacters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get recoveryEightCharacters;

  /// No description provided for @recoveryLetterRequired.
  ///
  /// In en, this message translates to:
  /// **'Password must include at least one letter.'**
  String get recoveryLetterRequired;

  /// No description provided for @recoveryNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Password must include at least one number.'**
  String get recoveryNumberRequired;

  /// No description provided for @recoveryConfirmRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password.'**
  String get recoveryConfirmRequired;

  /// No description provided for @recoveryMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get recoveryMismatch;

  /// No description provided for @recoveryStrength.
  ///
  /// In en, this message translates to:
  /// **'Password strength'**
  String get recoveryStrength;

  /// No description provided for @recoveryStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak — add more characters'**
  String get recoveryStrengthWeak;

  /// No description provided for @recoveryStrengthFair.
  ///
  /// In en, this message translates to:
  /// **'Fair — try adding numbers or symbols'**
  String get recoveryStrengthFair;

  /// No description provided for @recoveryStrengthGood.
  ///
  /// In en, this message translates to:
  /// **'Good strength'**
  String get recoveryStrengthGood;

  /// No description provided for @recoveryStrengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong password'**
  String get recoveryStrengthStrong;

  /// No description provided for @recoveryInstructionsSent.
  ///
  /// In en, this message translates to:
  /// **'We sent password reset instructions to\n{email}'**
  String recoveryInstructionsSent(String email);

  /// No description provided for @homeMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get homeMorning;

  /// No description provided for @homeAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get homeAfternoon;

  /// No description provided for @homeEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get homeEvening;

  /// No description provided for @homeReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to ride?'**
  String get homeReady;

  /// No description provided for @homeWhere.
  ///
  /// In en, this message translates to:
  /// **'Where are you going?'**
  String get homeWhere;

  /// No description provided for @homePlanHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to plan your journey'**
  String get homePlanHint;

  /// No description provided for @homeMenu.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get homeMenu;

  /// No description provided for @homeProfileAction.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get homeProfileAction;

  /// No description provided for @homeTrack.
  ///
  /// In en, this message translates to:
  /// **'Track\nBus'**
  String get homeTrack;

  /// No description provided for @homePlanAction.
  ///
  /// In en, this message translates to:
  /// **'Plan\nJourney'**
  String get homePlanAction;

  /// No description provided for @homePreferencesAction.
  ///
  /// In en, this message translates to:
  /// **'Access\nPrefs'**
  String get homePreferencesAction;

  /// No description provided for @homeHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeHome;

  /// No description provided for @homePlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get homePlan;

  /// No description provided for @homePlanJourney.
  ///
  /// In en, this message translates to:
  /// **'Plan Journey'**
  String get homePlanJourney;

  /// No description provided for @homeCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get homeCommunity;

  /// No description provided for @homeProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get homeProfile;

  /// No description provided for @homeRewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards & Contributions'**
  String get homeRewards;

  /// No description provided for @homeHelp.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get homeHelp;

  /// No description provided for @homeLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get homeLogout;

  /// No description provided for @homeRecentReports.
  ///
  /// In en, this message translates to:
  /// **'Recent Community Reports'**
  String get homeRecentReports;

  /// No description provided for @homeNoReports.
  ///
  /// In en, this message translates to:
  /// **'No recent community reports.'**
  String get homeNoReports;

  /// No description provided for @homeReportsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Community reports are unavailable. Try again later.'**
  String get homeReportsUnavailable;

  /// No description provided for @homeReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get homeReport;

  /// No description provided for @homeRecentJourney.
  ///
  /// In en, this message translates to:
  /// **'Recent Journey'**
  String get homeRecentJourney;

  /// No description provided for @homeNoJourney.
  ///
  /// In en, this message translates to:
  /// **'No recorded journey'**
  String get homeNoJourney;

  /// No description provided for @homeStartPlanning.
  ///
  /// In en, this message translates to:
  /// **'Plan a journey to get started'**
  String get homeStartPlanning;

  /// No description provided for @homeJourneysLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading recent journey…'**
  String get homeJourneysLoading;

  /// No description provided for @homeJourneysUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Recent journey unavailable'**
  String get homeJourneysUnavailable;

  /// No description provided for @homeRetryLater.
  ///
  /// In en, this message translates to:
  /// **'Try again later'**
  String get homeRetryLater;

  /// No description provided for @homeOrigin.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get homeOrigin;

  /// No description provided for @homeDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get homeDestination;

  /// No description provided for @homeRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get homeRecent;

  /// No description provided for @homeReplan.
  ///
  /// In en, this message translates to:
  /// **'Re-plan'**
  String get homeReplan;

  /// No description provided for @homeAssistance.
  ///
  /// In en, this message translates to:
  /// **'Assistance'**
  String get homeAssistance;

  /// No description provided for @homeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get homeJustNow;

  /// No description provided for @homeUnknownAge.
  ///
  /// In en, this message translates to:
  /// **'Observation time unavailable'**
  String get homeUnknownAge;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}'**
  String homeGreeting(String greeting, String name);

  /// No description provided for @homeTrueCount.
  ///
  /// In en, this message translates to:
  /// **'True: {count}'**
  String homeTrueCount(int count);

  /// No description provided for @homeFalseCount.
  ///
  /// In en, this message translates to:
  /// **'False: {count}/{threshold}'**
  String homeFalseCount(int count, int threshold);

  /// No description provided for @homeJourneySegment.
  ///
  /// In en, this message translates to:
  /// **'{origin} to {destination}'**
  String homeJourneySegment(String origin, String destination);

  /// No description provided for @homeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 min ago} other{{count} mins ago}}'**
  String homeMinutesAgo(int count);

  /// No description provided for @homeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String homeHoursAgo(int count);

  /// No description provided for @homeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String homeDaysAgo(int count);

  /// No description provided for @homeMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month ago} other{{count} months ago}}'**
  String homeMonthsAgo(int count);

  /// No description provided for @registrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registrationTitle;

  /// No description provided for @registrationJoin.
  ///
  /// In en, this message translates to:
  /// **'Join Access Transit'**
  String get registrationJoin;

  /// No description provided for @registrationIntro.
  ///
  /// In en, this message translates to:
  /// **'Your journey to inclusive travel begins here.'**
  String get registrationIntro;

  /// No description provided for @registrationNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get registrationNameHint;

  /// No description provided for @registrationEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get registrationEmailHint;

  /// No description provided for @registrationPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get registrationPassword;

  /// No description provided for @registrationPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get registrationPasswordHint;

  /// No description provided for @registrationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get registrationConfirm;

  /// No description provided for @registrationConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get registrationConfirmHint;

  /// No description provided for @registrationNeeds.
  ///
  /// In en, this message translates to:
  /// **'I have specific accessibility needs'**
  String get registrationNeeds;

  /// No description provided for @registrationNeedsExample.
  ///
  /// In en, this message translates to:
  /// **'(e.g., wheelchair ramp, low floor bus)'**
  String get registrationNeedsExample;

  /// No description provided for @registrationAccountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get registrationAccountType;

  /// No description provided for @registrationCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registrationCreate;

  /// No description provided for @registrationOr.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get registrationOr;

  /// No description provided for @registrationGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get registrationGoogle;

  /// No description provided for @registrationApple.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Apple'**
  String get registrationApple;

  /// No description provided for @registrationGoogleFeature.
  ///
  /// In en, this message translates to:
  /// **'Google sign-up'**
  String get registrationGoogleFeature;

  /// No description provided for @registrationAppleFeature.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-up'**
  String get registrationAppleFeature;

  /// No description provided for @registrationAlready.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get registrationAlready;

  /// No description provided for @registrationLogin.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get registrationLogin;

  /// No description provided for @registrationExists.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email.'**
  String get registrationExists;

  /// No description provided for @registrationNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Email/password authentication is not enabled.'**
  String get registrationNotEnabled;

  /// No description provided for @registrationRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields properly.'**
  String get registrationRequiredFields;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please check your connection and try again.'**
  String get registrationFailed;

  /// No description provided for @registrationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name.'**
  String get registrationNameRequired;

  /// No description provided for @registrationNameShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters.'**
  String get registrationNameShort;

  /// No description provided for @registrationNameLetters.
  ///
  /// In en, this message translates to:
  /// **'Use letters, spaces, apostrophes, periods or hyphens in your name.'**
  String get registrationNameLetters;

  /// No description provided for @onboardingSkipTooltip.
  ///
  /// In en, this message translates to:
  /// **'Skip onboarding'**
  String get onboardingSkipTooltip;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingStart;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingTailored.
  ///
  /// In en, this message translates to:
  /// **'Tailored for You'**
  String get onboardingTailored;

  /// No description provided for @onboardingNeedsHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose wheelchair and step-free needs, then review current evidence. Voice guidance is unavailable.'**
  String get onboardingNeedsHelp;

  /// No description provided for @onboardingNavigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate with Confidence'**
  String get onboardingNavigate;

  /// No description provided for @onboardingLiveHelp.
  ///
  /// In en, this message translates to:
  /// **'Preview only. Check shared GPS when available; assistance needs an operator response.'**
  String get onboardingLiveHelp;

  /// No description provided for @onboardingCommunity.
  ///
  /// In en, this message translates to:
  /// **'Be the Eyes of the Community'**
  String get onboardingCommunity;

  /// No description provided for @onboardingReportsHelp.
  ///
  /// In en, this message translates to:
  /// **'Share ramp and elevator observations. Reports are public after upload acknowledgement; rewards need review.'**
  String get onboardingReportsHelp;

  /// No description provided for @onboardingReportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get onboardingReportIssue;

  /// No description provided for @onboardingRamps.
  ///
  /// In en, this message translates to:
  /// **'Ramps'**
  String get onboardingRamps;

  /// No description provided for @onboardingLowFloor.
  ///
  /// In en, this message translates to:
  /// **'Low-floor'**
  String get onboardingLowFloor;

  /// No description provided for @onboardingExampleEta.
  ///
  /// In en, this message translates to:
  /// **'Example ETA: 3 min'**
  String get onboardingExampleEta;

  /// No description provided for @onboardingBoardingHelp.
  ///
  /// In en, this message translates to:
  /// **'Boarding Help'**
  String get onboardingBoardingHelp;

  /// No description provided for @onboardingAwaitingReply.
  ///
  /// In en, this message translates to:
  /// **'Example: awaiting reply'**
  String get onboardingAwaitingReply;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get loginFailed;

  /// No description provided for @loginInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password. Please check your details and try again.'**
  String get loginInvalidCredentials;

  /// No description provided for @loginDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled. Please contact support.'**
  String get loginDisabled;

  /// No description provided for @loginTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many login attempts. Please wait a moment and try again.'**
  String get loginTooMany;

  /// No description provided for @loginNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection and try again.'**
  String get loginNetwork;

  /// No description provided for @loginForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get loginForgot;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get loginPasswordHint;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password.'**
  String get loginPasswordRequired;

  /// No description provided for @loginPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get loginPasswordShort;

  /// No description provided for @loginOrContinue.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get loginOrContinue;

  /// No description provided for @loginBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Biometrics'**
  String get loginBiometrics;

  /// No description provided for @loginBiometricFeature.
  ///
  /// In en, this message translates to:
  /// **'Biometric sign-in'**
  String get loginBiometricFeature;

  /// No description provided for @loginGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get loginGoogle;

  /// No description provided for @loginGoogleFeature.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in'**
  String get loginGoogleFeature;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get loginNoAccount;

  /// No description provided for @loginSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get loginSignUp;

  /// No description provided for @settingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Preferences could not be saved. Please retry.'**
  String get settingsSaveFailed;

  /// No description provided for @settingsGuestSaved.
  ///
  /// In en, this message translates to:
  /// **'Device settings saved. Guest travel needs last for this session.'**
  String get settingsGuestSaved;

  /// No description provided for @settingsAccountSaved.
  ///
  /// In en, this message translates to:
  /// **'Preferences saved for this account on this device.'**
  String get settingsAccountSaved;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'User profile'**
  String get settingsProfile;

  /// No description provided for @settingsPersonalized.
  ///
  /// In en, this message translates to:
  /// **'Personalized Travel Experience'**
  String get settingsPersonalized;

  /// No description provided for @settingsScopeHelp.
  ///
  /// In en, this message translates to:
  /// **'High contrast and tap targets apply to this device. Travel needs are saved separately for each signed-in account on this device. Guest needs last for this session. New accounts start with wheelchair access required; review your needs.'**
  String get settingsScopeHelp;

  /// No description provided for @settingsMobility.
  ///
  /// In en, this message translates to:
  /// **'Mobility & Physical Access'**
  String get settingsMobility;

  /// No description provided for @settingsWheelchair.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair access required'**
  String get settingsWheelchair;

  /// No description provided for @settingsRampHelp.
  ///
  /// In en, this message translates to:
  /// **'Require current ramp evidence for matching buses'**
  String get settingsRampHelp;

  /// No description provided for @settingsStepFree.
  ///
  /// In en, this message translates to:
  /// **'Step-free routes only'**
  String get settingsStepFree;

  /// No description provided for @settingsStepFreeHelp.
  ///
  /// In en, this message translates to:
  /// **'Avoid stops and terminals requiring stairs'**
  String get settingsStepFreeHelp;

  /// No description provided for @settingsWalking.
  ///
  /// In en, this message translates to:
  /// **'Minimize walking distance'**
  String get settingsWalking;

  /// No description provided for @settingsWalkingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available yet — walking paths and distances have not been measured'**
  String get settingsWalkingUnavailable;

  /// No description provided for @settingsSensory.
  ///
  /// In en, this message translates to:
  /// **'Sensory & Vision'**
  String get settingsSensory;

  /// No description provided for @settingsContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast mode'**
  String get settingsContrast;

  /// No description provided for @settingsContrastHelp.
  ///
  /// In en, this message translates to:
  /// **'Enhance text clarity and strong border lines (WCAG AAA)'**
  String get settingsContrastHelp;

  /// No description provided for @settingsLargeTargets.
  ///
  /// In en, this message translates to:
  /// **'Large tap targets (48dp+)'**
  String get settingsLargeTargets;

  /// No description provided for @settingsTargetsHelp.
  ///
  /// In en, this message translates to:
  /// **'Enforce minimum 48dp touch targets across buttons & controls'**
  String get settingsTargetsHelp;

  /// No description provided for @settingsTargetsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Large tap targets (48dp+) enabled'**
  String get settingsTargetsEnabled;

  /// No description provided for @settingsTargetsStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard tap targets enabled'**
  String get settingsTargetsStandard;

  /// No description provided for @settingsVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice guidance for navigation'**
  String get settingsVoice;

  /// No description provided for @settingsVoiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available yet — use your phone screen reader for spoken interface labels'**
  String get settingsVoiceUnavailable;

  /// No description provided for @settingsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Haptic alerts for stops'**
  String get settingsHaptics;

  /// No description provided for @settingsHapticsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available yet — automatic vibration alerts are not supported'**
  String get settingsHapticsUnavailable;

  /// No description provided for @settingsAssistance.
  ///
  /// In en, this message translates to:
  /// **'Assistance & Environment'**
  String get settingsAssistance;

  /// No description provided for @settingsBoarding.
  ///
  /// In en, this message translates to:
  /// **'Boarding assistance required'**
  String get settingsBoarding;

  /// No description provided for @settingsBoardingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Automatic requests are not available yet — request assistance from the journey screen'**
  String get settingsBoardingUnavailable;

  /// No description provided for @settingsQuiet.
  ///
  /// In en, this message translates to:
  /// **'Show quiet routes'**
  String get settingsQuiet;

  /// No description provided for @settingsQuietUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available yet — noise levels are unknown'**
  String get settingsQuietUnavailable;

  /// No description provided for @settingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save Preferences'**
  String get settingsSave;

  /// No description provided for @searchSwapped.
  ///
  /// In en, this message translates to:
  /// **'⇄ Boarding stop and Destination swapped'**
  String get searchSwapped;

  /// No description provided for @searchSelectBoarding.
  ///
  /// In en, this message translates to:
  /// **'Select Boarding Point'**
  String get searchSelectBoarding;

  /// No description provided for @searchSelectDestination.
  ///
  /// In en, this message translates to:
  /// **'Select Destination Stop'**
  String get searchSelectDestination;

  /// No description provided for @searchTravelChoice.
  ///
  /// In en, this message translates to:
  /// **'Choose Travel Time'**
  String get searchTravelChoice;

  /// No description provided for @searchLeaveNow.
  ///
  /// In en, this message translates to:
  /// **'Leave Now'**
  String get searchLeaveNow;

  /// No description provided for @searchSpecificTime.
  ///
  /// In en, this message translates to:
  /// **'Set Specific Time'**
  String get searchSpecificTime;

  /// No description provided for @searchChooseTime.
  ///
  /// In en, this message translates to:
  /// **'Choose departure time'**
  String get searchChooseTime;

  /// No description provided for @searchChangeDate.
  ///
  /// In en, this message translates to:
  /// **'Change Travel Date'**
  String get searchChangeDate;

  /// No description provided for @searchNeedsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accessibility Needs'**
  String get searchNeedsTitle;

  /// No description provided for @searchTemporaryHelp.
  ///
  /// In en, this message translates to:
  /// **'Customize for this trip only. Your permanent Accessibility Preferences in settings will not be affected.'**
  String get searchTemporaryHelp;

  /// No description provided for @searchWheelchairChip.
  ///
  /// In en, this message translates to:
  /// **'♿ Wheelchair'**
  String get searchWheelchairChip;

  /// No description provided for @searchStepFreeChip.
  ///
  /// In en, this message translates to:
  /// **'Step-free'**
  String get searchStepFreeChip;

  /// No description provided for @searchResetHelp.
  ///
  /// In en, this message translates to:
  /// **'Reset to saved accessibility preferences'**
  String get searchResetHelp;

  /// No description provided for @searchReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get searchReset;

  /// No description provided for @searchRamp.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair Ramp'**
  String get searchRamp;

  /// No description provided for @searchRampHelp.
  ///
  /// In en, this message translates to:
  /// **'Ensure buses have working motorized or fold-out ramps'**
  String get searchRampHelp;

  /// No description provided for @searchStepFree.
  ///
  /// In en, this message translates to:
  /// **'Step-Free Station Access'**
  String get searchStepFree;

  /// No description provided for @searchStepFreeHelp.
  ///
  /// In en, this message translates to:
  /// **'Only board and exit at stations with elevators or flat paths'**
  String get searchStepFreeHelp;

  /// No description provided for @searchMinWalking.
  ///
  /// In en, this message translates to:
  /// **'Minimize Walking Distance'**
  String get searchMinWalking;

  /// No description provided for @searchWalkingUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not available yet — walking distance is unknown'**
  String get searchWalkingUnknown;

  /// No description provided for @searchApply.
  ///
  /// In en, this message translates to:
  /// **'Apply to This Trip'**
  String get searchApply;

  /// No description provided for @searchEndpointsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select origin and destination stations.'**
  String get searchEndpointsRequired;

  /// No description provided for @searchEndpointsDifferent.
  ///
  /// In en, this message translates to:
  /// **'Origin and destination stations cannot be the same.'**
  String get searchEndpointsDifferent;

  /// No description provided for @searchRampRequired.
  ///
  /// In en, this message translates to:
  /// **'Ramp Required'**
  String get searchRampRequired;

  /// No description provided for @searchStepFreeFilter.
  ///
  /// In en, this message translates to:
  /// **'Step-Free'**
  String get searchStepFreeFilter;

  /// No description provided for @searchMinWalkFilter.
  ///
  /// In en, this message translates to:
  /// **'Min Walk'**
  String get searchMinWalkFilter;

  /// No description provided for @searchFind.
  ///
  /// In en, this message translates to:
  /// **'Find Buses'**
  String get searchFind;

  /// No description provided for @searchNoStops.
  ///
  /// In en, this message translates to:
  /// **'No shared stops available. Connect and retry.'**
  String get searchNoStops;

  /// No description provided for @searchPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan Journey'**
  String get searchPlan;

  /// No description provided for @searchSync.
  ///
  /// In en, this message translates to:
  /// **'Refresh bus data'**
  String get searchSync;

  /// No description provided for @searchBoardingHeading.
  ///
  /// In en, this message translates to:
  /// **'BOARDING POINT'**
  String get searchBoardingHeading;

  /// No description provided for @searchChooseBoarding.
  ///
  /// In en, this message translates to:
  /// **'Choose Boarding Point'**
  String get searchChooseBoarding;

  /// No description provided for @searchRampAvailable.
  ///
  /// In en, this message translates to:
  /// **'♿ Wheelchair Ramp Available'**
  String get searchRampAvailable;

  /// No description provided for @searchStandardStop.
  ///
  /// In en, this message translates to:
  /// **'Standard Stop'**
  String get searchStandardStop;

  /// No description provided for @searchTapBoarding.
  ///
  /// In en, this message translates to:
  /// **'Tap to select boarding station'**
  String get searchTapBoarding;

  /// No description provided for @searchSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap boarding point and destination'**
  String get searchSwap;

  /// No description provided for @searchDestinationHeading.
  ///
  /// In en, this message translates to:
  /// **'WHERE ARE YOU GOING?'**
  String get searchDestinationHeading;

  /// No description provided for @searchChooseDestination.
  ///
  /// In en, this message translates to:
  /// **'Choose Destination'**
  String get searchChooseDestination;

  /// No description provided for @searchAccessibleDestination.
  ///
  /// In en, this message translates to:
  /// **'♿ Accessible Destination'**
  String get searchAccessibleDestination;

  /// No description provided for @searchTapDestination.
  ///
  /// In en, this message translates to:
  /// **'Tap to select destination station'**
  String get searchTapDestination;

  /// No description provided for @searchMyLocation.
  ///
  /// In en, this message translates to:
  /// **'My Location'**
  String get searchMyLocation;

  /// No description provided for @searchBoardingSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggested boarding stops'**
  String get searchBoardingSuggestions;

  /// No description provided for @searchDestinationSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggested destination stops'**
  String get searchDestinationSuggestions;

  /// No description provided for @searchSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Show suggested stops'**
  String get searchSuggestions;

  /// No description provided for @searchDepartNow.
  ///
  /// In en, this message translates to:
  /// **'Depart Now'**
  String get searchDepartNow;

  /// No description provided for @searchTravelHeading.
  ///
  /// In en, this message translates to:
  /// **'TRAVEL TIME'**
  String get searchTravelHeading;

  /// No description provided for @searchChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get searchChange;

  /// No description provided for @searchOptions.
  ///
  /// In en, this message translates to:
  /// **'Accessibility Options'**
  String get searchOptions;

  /// No description provided for @searchConfigure.
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get searchConfigure;

  /// No description provided for @searchAllBusesHelp.
  ///
  /// In en, this message translates to:
  /// **'All buses shown. Tap Configure to require ramps or step-free access.'**
  String get searchAllBusesHelp;

  /// No description provided for @searchStationHint.
  ///
  /// In en, this message translates to:
  /// **'Type station or city (e.g. Pettah, Mount Lavinia)...'**
  String get searchStationHint;

  /// No description provided for @searchAllStops.
  ///
  /// In en, this message translates to:
  /// **'All Stops'**
  String get searchAllStops;

  /// No description provided for @searchNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching stations found.\nTry a different spelling or clear filters.'**
  String get searchNoMatches;

  /// No description provided for @searchRampBadge.
  ///
  /// In en, this message translates to:
  /// **'Ramp  '**
  String get searchRampBadge;

  /// No description provided for @searchElevatorBadge.
  ///
  /// In en, this message translates to:
  /// **'Elevator  '**
  String get searchElevatorBadge;

  /// No description provided for @searchSuggestionIcon.
  ///
  /// In en, this message translates to:
  /// **'Suggested stops'**
  String get searchSuggestionIcon;

  /// No description provided for @searchSuggestedBoarding.
  ///
  /// In en, this message translates to:
  /// **'Suggested Boarding Stops'**
  String get searchSuggestedBoarding;

  /// No description provided for @searchSuggestedDestination.
  ///
  /// In en, this message translates to:
  /// **'Suggested Destination Stops'**
  String get searchSuggestedDestination;

  /// No description provided for @searchVoiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice recognition is not available yet. Tap a suggested stop below:'**
  String get searchVoiceUnavailable;

  /// No description provided for @searchSelectedTime.
  ///
  /// In en, this message translates to:
  /// **'Selected: {time}'**
  String searchSelectedTime(String time);

  /// No description provided for @searchTodayAt.
  ///
  /// In en, this message translates to:
  /// **'Today at {time}'**
  String searchTodayAt(String time);

  /// No description provided for @searchDateAt.
  ///
  /// In en, this message translates to:
  /// **'{date} at {time}'**
  String searchDateAt(String date, String time);

  /// No description provided for @searchStopSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected: {name}'**
  String searchStopSelected(String name);

  /// No description provided for @searchActiveNeeds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Active} other{{count} Active}}'**
  String searchActiveNeeds(int count);

  /// No description provided for @resultsScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get resultsScheduled;

  /// No description provided for @resultsPastUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Scheduled time passed - departure unconfirmed'**
  String get resultsPastUnconfirmed;

  /// No description provided for @resultsNowUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Scheduled now - departure unconfirmed'**
  String get resultsNowUnconfirmed;

  /// No description provided for @resultsRampReady.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair Ramp Ready · Step-free entry'**
  String get resultsRampReady;

  /// No description provided for @resultsRampEquipped.
  ///
  /// In en, this message translates to:
  /// **'Ramp equipped · Check operator assistance'**
  String get resultsRampEquipped;

  /// No description provided for @resultsStandardService.
  ///
  /// In en, this message translates to:
  /// **'Standard bus service'**
  String get resultsStandardService;

  /// No description provided for @resultsUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get resultsUnknown;

  /// No description provided for @resultsLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get resultsLow;

  /// No description provided for @resultsMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get resultsMedium;

  /// No description provided for @resultsHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get resultsHigh;

  /// No description provided for @resultsStarted.
  ///
  /// In en, this message translates to:
  /// **'Started run'**
  String get resultsStarted;

  /// No description provided for @resultsDemoTimetable.
  ///
  /// In en, this message translates to:
  /// **'Demo timetable'**
  String get resultsDemoTimetable;

  /// No description provided for @resultsPublishedTimetable.
  ///
  /// In en, this message translates to:
  /// **'Published timetable'**
  String get resultsPublishedTimetable;

  /// No description provided for @resultsWheelchairBus.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair Accessible Bus'**
  String get resultsWheelchairBus;

  /// No description provided for @resultsRampBus.
  ///
  /// In en, this message translates to:
  /// **'Standard Ramp Bus'**
  String get resultsRampBus;

  /// No description provided for @resultsStandardBus.
  ///
  /// In en, this message translates to:
  /// **'Standard Bus'**
  String get resultsStandardBus;

  /// No description provided for @resultsEstimatedTimes.
  ///
  /// In en, this message translates to:
  /// **'Some times are model estimates; confirm with the operator.'**
  String get resultsEstimatedTimes;

  /// No description provided for @resultsWalkingUnknown.
  ///
  /// In en, this message translates to:
  /// **'Walking distance is unavailable for this journey. Results are not ranked by walking distance.'**
  String get resultsWalkingUnknown;

  /// No description provided for @resultsReviewNeeds.
  ///
  /// In en, this message translates to:
  /// **'Review trip requirements'**
  String get resultsReviewNeeds;

  /// No description provided for @resultsReviewHelp.
  ///
  /// In en, this message translates to:
  /// **'Changes apply only to this search. Turning a requirement off may show services with unknown access or reported barriers. Review the evidence before choosing a journey.'**
  String get resultsReviewHelp;

  /// No description provided for @resultsKeepNeeds.
  ///
  /// In en, this message translates to:
  /// **'Keep requirements'**
  String get resultsKeepNeeds;

  /// No description provided for @resultsApplyNeeds.
  ///
  /// In en, this message translates to:
  /// **'Apply to this search'**
  String get resultsApplyNeeds;

  /// No description provided for @resultsNoAccessible.
  ///
  /// In en, this message translates to:
  /// **'No Accessible Buses Found'**
  String get resultsNoAccessible;

  /// No description provided for @resultsNoDirect.
  ///
  /// In en, this message translates to:
  /// **'No Direct Buses Found'**
  String get resultsNoDirect;

  /// No description provided for @resultsNoAccessibleHelp.
  ///
  /// In en, this message translates to:
  /// **'No scheduled journeys have known access matching these requirements. Stop access may be unknown or an active barrier may be reported. Review your accessibility filters.'**
  String get resultsNoAccessibleHelp;

  /// No description provided for @resultsShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all matching buses'**
  String get resultsShowAll;

  /// No description provided for @resultsShowAllHelp.
  ///
  /// In en, this message translates to:
  /// **'Shows options outside the Accessible tab, including unknown access or reported barriers. Your trip requirements stay applied.'**
  String get resultsShowAllHelp;

  /// No description provided for @resultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Available Buses'**
  String get resultsTitle;

  /// No description provided for @resultsChooseHelp.
  ///
  /// In en, this message translates to:
  /// **'Select a bus to track live journey'**
  String get resultsChooseHelp;

  /// No description provided for @resultsFastest.
  ///
  /// In en, this message translates to:
  /// **'Fastest'**
  String get resultsFastest;

  /// No description provided for @resultsRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get resultsRoute;

  /// No description provided for @resultsTimetableHelp.
  ///
  /// In en, this message translates to:
  /// **'Timetable estimates - departure unconfirmed. Open route details for GPS status.'**
  String get resultsTimetableHelp;

  /// No description provided for @resultsDeparture.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get resultsDeparture;

  /// No description provided for @resultsArrival.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get resultsArrival;

  /// No description provided for @resultsRampAvailable.
  ///
  /// In en, this message translates to:
  /// **'Ramp Available'**
  String get resultsRampAvailable;

  /// No description provided for @resultsLowFloor.
  ///
  /// In en, this message translates to:
  /// **'Low Floor'**
  String get resultsLowFloor;

  /// No description provided for @detailsAmbiguous.
  ///
  /// In en, this message translates to:
  /// **'Departure identity is ambiguous. Refresh the selection.'**
  String get detailsAmbiguous;

  /// No description provided for @detailsAccountChanged.
  ///
  /// In en, this message translates to:
  /// **'Account changed. Return to Search.'**
  String get detailsAccountChanged;

  /// No description provided for @detailsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Service unavailable. Retry'**
  String get detailsUnavailable;

  /// No description provided for @detailsRunUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Run status unavailable'**
  String get detailsRunUnavailable;

  /// No description provided for @detailsRunUnverified.
  ///
  /// In en, this message translates to:
  /// **'Scheduled · run not verified'**
  String get detailsRunUnverified;

  /// No description provided for @detailsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get detailsCompleted;

  /// No description provided for @detailsCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get detailsCancelled;

  /// No description provided for @detailsStale.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable or stale'**
  String get detailsStale;

  /// No description provided for @detailsLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE GPS'**
  String get detailsLive;

  /// No description provided for @detailsWheelchair.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair access'**
  String get detailsWheelchair;

  /// No description provided for @detailsSavedHelp.
  ///
  /// In en, this message translates to:
  /// **'Saved selection · times and needs are preserved; review current conditions.'**
  String get detailsSavedHelp;

  /// No description provided for @detailsDefaultsDiffer.
  ///
  /// In en, this message translates to:
  /// **'Your current accessibility defaults differ from this saved selection.'**
  String get detailsDefaultsDiffer;

  /// No description provided for @detailsCatalogueUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Catalogue updates unavailable.'**
  String get detailsCatalogueUnavailable;

  /// No description provided for @detailsStops.
  ///
  /// In en, this message translates to:
  /// **'Stops on your journey'**
  String get detailsStops;

  /// No description provided for @detailsIntermediateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Intermediate stop · time unavailable'**
  String get detailsIntermediateUnknown;

  /// No description provided for @detailsEvidence.
  ///
  /// In en, this message translates to:
  /// **'Accessibility evidence'**
  String get detailsEvidence;

  /// No description provided for @detailsAssistanceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Driver assistance unavailable'**
  String get detailsAssistanceUnavailable;

  /// No description provided for @detailsReport.
  ///
  /// In en, this message translates to:
  /// **'Report a condition'**
  String get detailsReport;

  /// No description provided for @detailsLoadingReports.
  ///
  /// In en, this message translates to:
  /// **'Loading reports…'**
  String get detailsLoadingReports;

  /// No description provided for @detailsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry updates'**
  String get detailsRetry;

  /// No description provided for @detailsVerifySave.
  ///
  /// In en, this message translates to:
  /// **'Connect to verify this departure before saving.'**
  String get detailsVerifySave;

  /// No description provided for @resultsSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get resultsSafe;

  /// No description provided for @resultsWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get resultsWarning;

  /// No description provided for @resultsNotAccessible.
  ///
  /// In en, this message translates to:
  /// **'Not accessible'**
  String get resultsNotAccessible;

  /// No description provided for @detailsResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get detailsResolved;

  /// No description provided for @detailsRecheckUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unresolved barrier - observation time unknown; needs recheck'**
  String get detailsRecheckUnknown;

  /// No description provided for @detailsObservationUnknown.
  ///
  /// In en, this message translates to:
  /// **'Observation time unknown'**
  String get detailsObservationUnknown;

  /// No description provided for @detailsExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired or unavailable'**
  String get detailsExpired;

  /// No description provided for @detailsRecheck.
  ///
  /// In en, this message translates to:
  /// **'Unresolved barrier — needs recheck'**
  String get detailsRecheck;

  /// No description provided for @detailsRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent observation'**
  String get detailsRecent;

  /// No description provided for @resultsRouteNumber.
  ///
  /// In en, this message translates to:
  /// **'Route {number}'**
  String resultsRouteNumber(String number);

  /// No description provided for @resultsScheduledDate.
  ///
  /// In en, this message translates to:
  /// **'Scheduled {date}, {time}'**
  String resultsScheduledDate(String date, String time);

  /// No description provided for @resultsScheduledAt.
  ///
  /// In en, this message translates to:
  /// **'Scheduled {date} at {time}'**
  String resultsScheduledAt(String date, String time);

  /// No description provided for @resultsTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Scheduled tomorrow, {time}'**
  String resultsTomorrow(String time);

  /// No description provided for @resultsTomorrowAt.
  ///
  /// In en, this message translates to:
  /// **'Scheduled tomorrow at {time}'**
  String resultsTomorrowAt(String time);

  /// No description provided for @resultsToday.
  ///
  /// In en, this message translates to:
  /// **'Scheduled today, {time}'**
  String resultsToday(String time);

  /// No description provided for @resultsTodayAt.
  ///
  /// In en, this message translates to:
  /// **'Scheduled today at {time}'**
  String resultsTodayAt(String time);

  /// No description provided for @resultsScheduledIn.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{Scheduled in 1 min - {time}} other{Scheduled in {minutes} mins - {time}}}'**
  String resultsScheduledIn(int minutes, String time);

  /// No description provided for @resultsBoardingEstimate.
  ///
  /// In en, this message translates to:
  /// **'Boarding estimate {time} · {source}'**
  String resultsBoardingEstimate(String time, String source);

  /// No description provided for @resultsCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Available Buses ({count})'**
  String resultsCountTitle(int count);

  /// No description provided for @resultsAvailableCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bus available} other{{count} buses available}}'**
  String resultsAvailableCount(int count);

  /// No description provided for @resultsNoDirectHelp.
  ///
  /// In en, this message translates to:
  /// **'There are currently no direct bus routes connecting {origin} to {destination}.'**
  String resultsNoDirectHelp(String origin, String destination);

  /// No description provided for @resultsAllTab.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String resultsAllTab(int count);

  /// No description provided for @resultsAccessibleTab.
  ///
  /// In en, this message translates to:
  /// **'Accessible ({count})'**
  String resultsAccessibleTab(int count);

  /// No description provided for @resultsDuration.
  ///
  /// In en, this message translates to:
  /// **'~{minutes} min'**
  String resultsDuration(int minutes);

  /// No description provided for @resultsCrowd.
  ///
  /// In en, this message translates to:
  /// **'{level} Crowd'**
  String resultsCrowd(String level);

  /// No description provided for @resultsBoardingSource.
  ///
  /// In en, this message translates to:
  /// **'Boarding estimate · {source}'**
  String resultsBoardingSource(String source);

  /// No description provided for @detailsBoardingAt.
  ///
  /// In en, this message translates to:
  /// **'Scheduled boarding: {date} · {time}'**
  String detailsBoardingAt(String date, String time);

  /// No description provided for @detailsArrivalAt.
  ///
  /// In en, this message translates to:
  /// **'Scheduled arrival: {date} · {time}'**
  String detailsArrivalAt(String date, String time);

  /// No description provided for @detailsDuration.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min · selected segment'**
  String detailsDuration(int minutes);

  /// No description provided for @detailsBoardHere.
  ///
  /// In en, this message translates to:
  /// **'Board here · {time}'**
  String detailsBoardHere(String time);

  /// No description provided for @detailsAlightHere.
  ///
  /// In en, this message translates to:
  /// **'Alight here · {time}'**
  String detailsAlightHere(String time);

  /// No description provided for @detailsScheduledStop.
  ///
  /// In en, this message translates to:
  /// **'Scheduled {time}'**
  String detailsScheduledStop(String time);

  /// No description provided for @detailsNextStop.
  ///
  /// In en, this message translates to:
  /// **'Next itinerary stop: {name}'**
  String detailsNextStop(String name);

  /// No description provided for @resultsSourceDated.
  ///
  /// In en, this message translates to:
  /// **'Dated timetable'**
  String get resultsSourceDated;

  /// No description provided for @resultsSourceRoad.
  ///
  /// In en, this message translates to:
  /// **'Road progress + timetable (low confidence)'**
  String get resultsSourceRoad;

  /// No description provided for @resultsSourceBoarding.
  ///
  /// In en, this message translates to:
  /// **'GPS at boarding stop'**
  String get resultsSourceBoarding;

  /// No description provided for @resultsSourceInterval.
  ///
  /// In en, this message translates to:
  /// **'Timetable interval from GPS-observed stop'**
  String get resultsSourceInterval;

  /// No description provided for @evidenceRecheckSummary.
  ///
  /// In en, this message translates to:
  /// **'Unresolved barrier - needs recheck'**
  String get evidenceRecheckSummary;

  /// No description provided for @evidenceBarrierSummary.
  ///
  /// In en, this message translates to:
  /// **'Barrier reported - review before travel'**
  String get evidenceBarrierSummary;

  /// No description provided for @evidencePositiveSummary.
  ///
  /// In en, this message translates to:
  /// **'Positive observation - view details'**
  String get evidencePositiveSummary;

  /// No description provided for @evidenceUnknownSummary.
  ///
  /// In en, this message translates to:
  /// **'Unknown - no current observation'**
  String get evidenceUnknownSummary;

  /// No description provided for @evidenceTimeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown - observation time unavailable'**
  String get evidenceTimeUnknown;

  /// No description provided for @evidenceExpired.
  ///
  /// In en, this message translates to:
  /// **'Unknown — latest observation expired'**
  String get evidenceExpired;

  /// No description provided for @evidenceRecheckUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unresolved barrier — needs recheck; current condition unknown'**
  String get evidenceRecheckUnknown;

  /// No description provided for @evidenceConditionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown — condition could not be determined'**
  String get evidenceConditionUnknown;

  /// No description provided for @evidenceBarrierConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Barrier — community-confirmed observation'**
  String get evidenceBarrierConfirmed;

  /// No description provided for @evidencePositiveConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Positive — community-confirmed observation'**
  String get evidencePositiveConfirmed;

  /// No description provided for @evidenceBarrierUnverified.
  ///
  /// In en, this message translates to:
  /// **'Barrier reported — verification unknown'**
  String get evidenceBarrierUnverified;

  /// No description provided for @evidencePositiveUnverified.
  ///
  /// In en, this message translates to:
  /// **'Positive reported — verification unknown'**
  String get evidencePositiveUnverified;

  /// No description provided for @evidenceNoConfirmationTime.
  ///
  /// In en, this message translates to:
  /// **'Confirmation time: Unknown'**
  String get evidenceNoConfirmationTime;

  /// No description provided for @evidenceVehicleSection.
  ///
  /// In en, this message translates to:
  /// **'Vehicle ramp conditions'**
  String get evidenceVehicleSection;

  /// No description provided for @evidenceBoardingSection.
  ///
  /// In en, this message translates to:
  /// **'Boarding stop conditions'**
  String get evidenceBoardingSection;

  /// No description provided for @evidenceDestinationSection.
  ///
  /// In en, this message translates to:
  /// **'Destination stop conditions'**
  String get evidenceDestinationSection;

  /// No description provided for @evidenceAssistanceSection.
  ///
  /// In en, this message translates to:
  /// **'Driver assistance observations'**
  String get evidenceAssistanceSection;

  /// No description provided for @evidenceDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Community observations describe specific conditions; they do not verify the entire journey.'**
  String get evidenceDisclosure;

  /// No description provided for @evidenceEmpty.
  ///
  /// In en, this message translates to:
  /// **'Unknown — no observation available'**
  String get evidenceEmpty;

  /// No description provided for @evidenceMember.
  ///
  /// In en, this message translates to:
  /// **'Community member'**
  String get evidenceMember;

  /// No description provided for @rampWorkingObserved.
  ///
  /// In en, this message translates to:
  /// **'Working observed'**
  String get rampWorkingObserved;

  /// No description provided for @rampBrokenUnresolved.
  ///
  /// In en, this message translates to:
  /// **'Broken reported - unresolved warning'**
  String get rampBrokenUnresolved;

  /// No description provided for @rampNewCheck.
  ///
  /// In en, this message translates to:
  /// **'Unknown - a new check is required'**
  String get rampNewCheck;

  /// No description provided for @rampEquipped.
  ///
  /// In en, this message translates to:
  /// **'Equipped'**
  String get rampEquipped;

  /// No description provided for @rampNotListed.
  ///
  /// In en, this message translates to:
  /// **'Not listed'**
  String get rampNotListed;

  /// No description provided for @rampTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle ramp'**
  String get rampTitle;

  /// No description provided for @rampOperatorSource.
  ///
  /// In en, this message translates to:
  /// **'Operator observation'**
  String get rampOperatorSource;

  /// No description provided for @rampBarrierDisclosure.
  ///
  /// In en, this message translates to:
  /// **'A working observation does not resolve existing community barriers.'**
  String get rampBarrierDisclosure;

  /// No description provided for @mapMissingCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Map unavailable · stop coordinates have not been reviewed. Use the stop list.'**
  String get mapMissingCoordinates;

  /// No description provided for @mapCurrentBus.
  ///
  /// In en, this message translates to:
  /// **'Current bus location'**
  String get mapCurrentBus;

  /// No description provided for @mapNoRoadGeometry.
  ///
  /// In en, this message translates to:
  /// **'Stop locations · road route geometry unavailable'**
  String get mapNoRoadGeometry;

  /// No description provided for @mapTileRetry.
  ///
  /// In en, this message translates to:
  /// **'Map tiles unavailable · retry or use the stop list'**
  String get mapTileRetry;

  /// No description provided for @timetableUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Published timetable • vehicle unassigned'**
  String get timetableUnassigned;

  /// No description provided for @timetableUnknownDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Times may change. Vehicle registration, accessibility and live location are unknown. Driver assistance is unavailable until an authorized vehicle is connected.'**
  String get timetableUnknownDisclosure;

  /// No description provided for @evidenceCheckedAt.
  ///
  /// In en, this message translates to:
  /// **'Last checked: {time}'**
  String evidenceCheckedAt(String time);

  /// No description provided for @evidenceRecheckedAt.
  ///
  /// In en, this message translates to:
  /// **'Last recheck: {time} by {name}. Unique confirmations unchanged.'**
  String evidenceRecheckedAt(String time, String name);

  /// No description provided for @evidenceDueAt.
  ///
  /// In en, this message translates to:
  /// **'Recheck due: {time}'**
  String evidenceDueAt(String time);

  /// No description provided for @evidenceExpiresAt.
  ///
  /// In en, this message translates to:
  /// **'Observation expires: {time}'**
  String evidenceExpiresAt(String time);

  /// No description provided for @evidenceReportedAt.
  ///
  /// In en, this message translates to:
  /// **'Reported at: {time}'**
  String evidenceReportedAt(String time);

  /// No description provided for @evidenceConfirmedAt.
  ///
  /// In en, this message translates to:
  /// **'Last confirmation recorded at: {time}'**
  String evidenceConfirmedAt(String time);

  /// No description provided for @evidenceReporter.
  ///
  /// In en, this message translates to:
  /// **'Reported by: {name}'**
  String evidenceReporter(String name);

  /// No description provided for @evidenceConfirmers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Confirmed by: 1 community member} other{Confirmed by: {count} community members}}'**
  String evidenceConfirmers(int count);

  /// No description provided for @rampCapability.
  ///
  /// In en, this message translates to:
  /// **'Ramp capability: {capability}'**
  String rampCapability(String capability);

  /// No description provided for @rampCheckedAge.
  ///
  /// In en, this message translates to:
  /// **'Ramp last checked: {age}'**
  String rampCheckedAge(String age);

  /// No description provided for @rampSource.
  ///
  /// In en, this message translates to:
  /// **'Ramp observation source: {source}'**
  String rampSource(String source);

  /// No description provided for @rampRecordedAt.
  ///
  /// In en, this message translates to:
  /// **'Check recorded: {time}'**
  String rampRecordedAt(String time);

  /// No description provided for @mapUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Location updated: {time}'**
  String mapUpdatedAt(String time);

  /// No description provided for @timetableSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String timetableSource(String source);

  /// No description provided for @reportSignInChange.
  ///
  /// In en, this message translates to:
  /// **'Sign in before changing a shared report.'**
  String get reportSignInChange;

  /// No description provided for @reportChangeUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Change is not confirmed. Check your connection and sign-in, then retry or refresh the shared report.'**
  String get reportChangeUnconfirmed;

  /// No description provided for @reportCopied.
  ///
  /// In en, this message translates to:
  /// **'Alert text copied to clipboard!'**
  String get reportCopied;

  /// No description provided for @reportCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not copy the alert. Please retry.'**
  String get reportCopyFailed;

  /// No description provided for @reportImageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image preview unavailable'**
  String get reportImageUnavailable;

  /// No description provided for @reportDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Details'**
  String get reportDetailsTitle;

  /// No description provided for @reportRemoved.
  ///
  /// In en, this message translates to:
  /// **'Shared report unavailable or removed. Reopen the feed to refresh.'**
  String get reportRemoved;

  /// No description provided for @reportShare.
  ///
  /// In en, this message translates to:
  /// **'Share alert'**
  String get reportShare;

  /// No description provided for @reportStaleUpdates.
  ///
  /// In en, this message translates to:
  /// **'Shared updates unavailable. Showing the last received observation; refresh before acting.'**
  String get reportStaleUpdates;

  /// No description provided for @reportSignInActions.
  ///
  /// In en, this message translates to:
  /// **'Sign in to confirm, flag or resolve shared reports.'**
  String get reportSignInActions;

  /// No description provided for @reportResolutionDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Resolution is the author\'s recorded observation; it does not independently verify a repair.'**
  String get reportResolutionDisclosure;

  /// No description provided for @reportResolutionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Resolution time: Unknown'**
  String get reportResolutionUnknown;

  /// No description provided for @reportResolvedTitle.
  ///
  /// In en, this message translates to:
  /// **'Condition Resolved'**
  String get reportResolvedTitle;

  /// No description provided for @reportResolvedHelp.
  ///
  /// In en, this message translates to:
  /// **'The author recorded this condition as resolved.'**
  String get reportResolvedHelp;

  /// No description provided for @reportObservationUnknown.
  ///
  /// In en, this message translates to:
  /// **'Observation time unknown'**
  String get reportObservationUnknown;

  /// No description provided for @reportUnknownHelp.
  ///
  /// In en, this message translates to:
  /// **'The observation date is unavailable. Current condition cannot be confirmed.'**
  String get reportUnknownHelp;

  /// No description provided for @reportConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Community-confirmed observation'**
  String get reportConfirmedTitle;

  /// No description provided for @reportActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Transit Alert'**
  String get reportActiveTitle;

  /// No description provided for @reportActiveHelp.
  ///
  /// In en, this message translates to:
  /// **'Reported by a commuter. Review the observation time and current evidence.'**
  String get reportActiveHelp;

  /// No description provided for @reportExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Past Report (Expired)'**
  String get reportExpiredTitle;

  /// No description provided for @reportExpiredHelp.
  ///
  /// In en, this message translates to:
  /// **'This observation has expired; it does not establish the current condition.'**
  String get reportExpiredHelp;

  /// No description provided for @reportYours.
  ///
  /// In en, this message translates to:
  /// **'YOUR REPORT'**
  String get reportYours;

  /// No description provided for @reportBus.
  ///
  /// In en, this message translates to:
  /// **'BUS'**
  String get reportBus;

  /// No description provided for @reportStation.
  ///
  /// In en, this message translates to:
  /// **'STATION'**
  String get reportStation;

  /// No description provided for @reportHighSeverity.
  ///
  /// In en, this message translates to:
  /// **'High Severity'**
  String get reportHighSeverity;

  /// No description provided for @reportMinorSeverity.
  ///
  /// In en, this message translates to:
  /// **'Minor Issue'**
  String get reportMinorSeverity;

  /// No description provided for @reportModerateSeverity.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get reportModerateSeverity;

  /// No description provided for @reportConditionDetails.
  ///
  /// In en, this message translates to:
  /// **'Reported Condition Details'**
  String get reportConditionDetails;

  /// No description provided for @reportRiderNote.
  ///
  /// In en, this message translates to:
  /// **'Rider Note:'**
  String get reportRiderNote;

  /// No description provided for @reportPhotoEvidence.
  ///
  /// In en, this message translates to:
  /// **'Attached Photo Evidence'**
  String get reportPhotoEvidence;

  /// No description provided for @reportEnlarge.
  ///
  /// In en, this message translates to:
  /// **'Tap to enlarge'**
  String get reportEnlarge;

  /// No description provided for @reportPhotoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo unavailable'**
  String get reportPhotoUnavailable;

  /// No description provided for @reportMetrics.
  ///
  /// In en, this message translates to:
  /// **'Community Trust & Verification Metrics'**
  String get reportMetrics;

  /// No description provided for @reportRecheckDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Rechecks are dated observations; unique confirmations are unchanged.'**
  String get reportRecheckDisclosure;

  /// No description provided for @reportVoteHeading.
  ///
  /// In en, this message translates to:
  /// **'Vote Report Accuracy'**
  String get reportVoteHeading;

  /// No description provided for @reportRecheckAction.
  ///
  /// In en, this message translates to:
  /// **'Recheck condition'**
  String get reportRecheckAction;

  /// No description provided for @reportFixed.
  ///
  /// In en, this message translates to:
  /// **'Condition Marked Fixed'**
  String get reportFixed;

  /// No description provided for @reportResolveAction.
  ///
  /// In en, this message translates to:
  /// **'Mark Condition as Fixed / Resolved'**
  String get reportResolveAction;

  /// No description provided for @reportRampCategory.
  ///
  /// In en, this message translates to:
  /// **'Ramp & Access'**
  String get reportRampCategory;

  /// No description provided for @reportLiftCategory.
  ///
  /// In en, this message translates to:
  /// **'Elevator / Lift'**
  String get reportLiftCategory;

  /// No description provided for @reportCrowdingCategory.
  ///
  /// In en, this message translates to:
  /// **'Crowding'**
  String get reportCrowdingCategory;

  /// No description provided for @reportCleanCategory.
  ///
  /// In en, this message translates to:
  /// **'Cleanliness'**
  String get reportCleanCategory;

  /// No description provided for @reportSafetyCategory.
  ///
  /// In en, this message translates to:
  /// **'Safety Hazard'**
  String get reportSafetyCategory;

  /// No description provided for @deliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Report delivery'**
  String get deliveryTitle;

  /// No description provided for @deliveryStatus.
  ///
  /// In en, this message translates to:
  /// **'Publication status'**
  String get deliveryStatus;

  /// No description provided for @deliveryDraftUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Draft unavailable'**
  String get deliveryDraftUnavailable;

  /// No description provided for @deliveryPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get deliveryPublished;

  /// No description provided for @deliveryPending.
  ///
  /// In en, this message translates to:
  /// **'Pending upload'**
  String get deliveryPending;

  /// No description provided for @deliveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get deliveryFailed;

  /// No description provided for @deliveryPublicHelp.
  ///
  /// In en, this message translates to:
  /// **'Your report is available to other commuters.'**
  String get deliveryPublicHelp;

  /// No description provided for @deliveryRemovedHelp.
  ///
  /// In en, this message translates to:
  /// **'This draft was removed, expired or belongs to another account. Publication has not been confirmed.'**
  String get deliveryRemovedHelp;

  /// No description provided for @deliveryPendingHelp.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device. Publication has not been confirmed.'**
  String get deliveryPendingHelp;

  /// No description provided for @deliveryLocalUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Local draft unavailable'**
  String get deliveryLocalUnavailable;

  /// No description provided for @deliveryObservation.
  ///
  /// In en, this message translates to:
  /// **'Your observation'**
  String get deliveryObservation;

  /// No description provided for @deliveryTarget.
  ///
  /// In en, this message translates to:
  /// **'Location / Vehicle'**
  String get deliveryTarget;

  /// No description provided for @deliveryCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition reported'**
  String get deliveryCondition;

  /// No description provided for @deliveryPhoto.
  ///
  /// In en, this message translates to:
  /// **'Attached photo'**
  String get deliveryPhoto;

  /// No description provided for @deliveryPhotoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo preview unavailable'**
  String get deliveryPhotoUnavailable;

  /// No description provided for @deliveryUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get deliveryUploading;

  /// No description provided for @deliveryRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry upload'**
  String get deliveryRetry;

  /// No description provided for @deliveryRemoveDevice.
  ///
  /// In en, this message translates to:
  /// **'Remove draft from this device'**
  String get deliveryRemoveDevice;

  /// No description provided for @deliveryAboutDrafts.
  ///
  /// In en, this message translates to:
  /// **'About local drafts'**
  String get deliveryAboutDrafts;

  /// No description provided for @deliveryDraftExpiry.
  ///
  /// In en, this message translates to:
  /// **'Drafts expire after 7 days and are removed on sign-out/account change.'**
  String get deliveryDraftExpiry;

  /// No description provided for @deliveryViewFeed.
  ///
  /// In en, this message translates to:
  /// **'View in Community Feed'**
  String get deliveryViewFeed;

  /// No description provided for @deliveryHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get deliveryHome;

  /// No description provided for @deliverySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the upload status. Please retry.'**
  String get deliverySaveFailed;

  /// No description provided for @deliveryRemoveQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove local draft?'**
  String get deliveryRemoveQuestion;

  /// No description provided for @deliveryRemoveHelp.
  ///
  /// In en, this message translates to:
  /// **'Stops future retries and removes the local note/photo. A request already sent may still complete. This does not delete a public report or an uploaded photo.'**
  String get deliveryRemoveHelp;

  /// No description provided for @deliveryKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep draft'**
  String get deliveryKeep;

  /// No description provided for @deliveryRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove draft'**
  String get deliveryRemove;

  /// No description provided for @deliveryRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Local removal could not be saved. Please retry.'**
  String get deliveryRemoveFailed;

  /// No description provided for @deliveryUnknownTime.
  ///
  /// In en, this message translates to:
  /// **'Observation time unknown. Create a new report before uploading.'**
  String get deliveryUnknownTime;

  /// No description provided for @deliveryWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a connection. This report is not confirmed as published.'**
  String get deliveryWaiting;

  /// No description provided for @deliveryUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Check your sign-in, photo and service access, then retry.'**
  String get deliveryUploadFailed;

  /// No description provided for @reportAlreadySaved.
  ///
  /// In en, this message translates to:
  /// **'This action was already recorded.'**
  String get reportAlreadySaved;

  /// No description provided for @reportWaitRecheck.
  ///
  /// In en, this message translates to:
  /// **'Recheck not saved. Wait 30 minutes after the latest check, then retry.'**
  String get reportWaitRecheck;

  /// No description provided for @reportChangeSaved.
  ///
  /// In en, this message translates to:
  /// **'Change saved. Shared details will refresh when connected.'**
  String get reportChangeSaved;

  /// No description provided for @reportConfirmationSaved.
  ///
  /// In en, this message translates to:
  /// **'Confirmation saved to the shared report.'**
  String get reportConfirmationSaved;

  /// No description provided for @reportRecheckSaved.
  ///
  /// In en, this message translates to:
  /// **'Recheck saved. Unique confirmations and points are unchanged.'**
  String get reportRecheckSaved;

  /// No description provided for @reportFlagSaved.
  ///
  /// In en, this message translates to:
  /// **'Flag saved to the shared report.'**
  String get reportFlagSaved;

  /// No description provided for @reportFlagHiddenLegacy.
  ///
  /// In en, this message translates to:
  /// **'Flag saved. Report hidden after three independent flags.'**
  String get reportFlagHiddenLegacy;

  /// No description provided for @reportResolutionSaved.
  ///
  /// In en, this message translates to:
  /// **'Resolution saved to the shared report.'**
  String get reportResolutionSaved;

  /// No description provided for @reportShareText.
  ///
  /// In en, this message translates to:
  /// **'AccessTransit Alert: {title} at {target}. Check the observation in AccessTransit.'**
  String reportShareText(String title, String target);

  /// No description provided for @reportResolvedBy.
  ///
  /// In en, this message translates to:
  /// **'Resolved by: {name}'**
  String reportResolvedBy(String name);

  /// No description provided for @reportResolvedAt.
  ///
  /// In en, this message translates to:
  /// **'Resolved at: {date}, {time}'**
  String reportResolvedAt(String date, String time);

  /// No description provided for @reportHiddenHelp.
  ///
  /// In en, this message translates to:
  /// **'This report is hidden after {threshold} independent inaccuracy flags. This does not prove the condition was false.'**
  String reportHiddenHelp(int threshold);

  /// No description provided for @reportRecheckAge.
  ///
  /// In en, this message translates to:
  /// **'Last checked {age}. Current condition unknown; no repair recorded.'**
  String reportRecheckAge(String age);

  /// No description provided for @reportConfirmedRiders.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Confirmed by 1 fellow rider.} other{Confirmed by {count} fellow riders.}}'**
  String reportConfirmedRiders(int count);

  /// No description provided for @reportTransitVehicle.
  ///
  /// In en, this message translates to:
  /// **'Transit Vehicle • {name}'**
  String reportTransitVehicle(String name);

  /// No description provided for @reportTransitStation.
  ///
  /// In en, this message translates to:
  /// **'Transit Station • {name}'**
  String reportTransitStation(String name);

  /// No description provided for @reportUniqueCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Unique confirmations: 1 rider} other{Unique confirmations: {count} riders}}'**
  String reportUniqueCount(int count);

  /// No description provided for @reportFlagCount.
  ///
  /// In en, this message translates to:
  /// **'Inaccuracy flags: {count} / {threshold} (Report hidden at {threshold} independent flags)'**
  String reportFlagCount(int count, int threshold);

  /// No description provided for @reportOriginally.
  ///
  /// In en, this message translates to:
  /// **'Originally reported: {age}'**
  String reportOriginally(String age);

  /// No description provided for @reportLastRecheck.
  ///
  /// In en, this message translates to:
  /// **'Last recheck: {age} by {name}'**
  String reportLastRecheck(String age, String name);

  /// No description provided for @reportLastConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Last confirmed: {age}'**
  String reportLastConfirmed(String age);

  /// No description provided for @reportLegacyVoteHelp.
  ///
  /// In en, this message translates to:
  /// **'Confirm only what you observed. Previous confirmers can recheck the same condition 30 minutes after the latest check; unique votes and points do not increase. If the condition changed, submit a new report. {threshold} independent flags hide a report.'**
  String reportLegacyVoteHelp(int threshold);

  /// No description provided for @reportTrueCount.
  ///
  /// In en, this message translates to:
  /// **'True Flag ({count})'**
  String reportTrueCount(int count);

  /// No description provided for @reportFalseCount.
  ///
  /// In en, this message translates to:
  /// **'False Flag ({count}/{threshold})'**
  String reportFalseCount(int count, int threshold);

  /// No description provided for @reportFalseRecorded.
  ///
  /// In en, this message translates to:
  /// **'False ({count}/{threshold})'**
  String reportFalseRecorded(int count, int threshold);

  /// No description provided for @deliveryCooldownAt.
  ///
  /// In en, this message translates to:
  /// **'Same-issue cooldown. Retry after {time} (UTC). Your draft is saved.'**
  String deliveryCooldownAt(String time);

  /// No description provided for @formPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not attach the photo. Check permission and try again.'**
  String get formPhotoFailed;

  /// No description provided for @formSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Report submission is not confirmed. Check your sign-in and connection, then retry.'**
  String get formSubmitFailed;

  /// No description provided for @formSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please sign in before publishing a report.'**
  String get formSignIn;

  /// No description provided for @formAccountChanged.
  ///
  /// In en, this message translates to:
  /// **'Account changed. Review the report again.'**
  String get formAccountChanged;

  /// No description provided for @formReviewTarget.
  ///
  /// In en, this message translates to:
  /// **'Location / Vehicle: {target}'**
  String formReviewTarget(String target);

  /// No description provided for @formReviewCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition: {condition}'**
  String formReviewCondition(String condition);

  /// No description provided for @formReviewCrowding.
  ///
  /// In en, this message translates to:
  /// **'Crowding: {level}'**
  String formReviewCrowding(String level);

  /// No description provided for @formReviewNote.
  ///
  /// In en, this message translates to:
  /// **'Note: {note}'**
  String formReviewNote(String note);

  /// No description provided for @formBusRoute.
  ///
  /// In en, this message translates to:
  /// **'Bus {number}'**
  String formBusRoute(String number);

  /// No description provided for @formVehicleRoute.
  ///
  /// In en, this message translates to:
  /// **'{vehicle} (Route {number})'**
  String formVehicleRoute(String vehicle, String number);

  /// No description provided for @formBusRamp.
  ///
  /// In en, this message translates to:
  /// **'{vehicle} ♿ (Ramp)'**
  String formBusRamp(String vehicle);

  /// No description provided for @formLowCrowd.
  ///
  /// In en, this message translates to:
  /// **'Low Crowd'**
  String get formLowCrowd;

  /// No description provided for @formPlentyOfRoomWheelchairBay.
  ///
  /// In en, this message translates to:
  /// **'Plenty of room & wheelchair bay free'**
  String get formPlentyOfRoomWheelchairBay;

  /// No description provided for @formModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get formModerate;

  /// No description provided for @formSeatsFullStandingRoomAvailable.
  ///
  /// In en, this message translates to:
  /// **'Seats full, standing room available'**
  String get formSeatsFullStandingRoomAvailable;

  /// No description provided for @formCrowdedPacked.
  ///
  /// In en, this message translates to:
  /// **'Crowded / Packed'**
  String get formCrowdedPacked;

  /// No description provided for @formWheelchairSpaceOrAisleBlocked.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair space or aisle blocked'**
  String get formWheelchairSpaceOrAisleBlocked;

  /// No description provided for @formRampBay.
  ///
  /// In en, this message translates to:
  /// **'Ramp & Bay'**
  String get formRampBay;

  /// No description provided for @formRampWorking.
  ///
  /// In en, this message translates to:
  /// **'Ramp Working'**
  String get formRampWorking;

  /// No description provided for @formDriverAssistedDeployedRamp.
  ///
  /// In en, this message translates to:
  /// **'Driver assisted & deployed ramp'**
  String get formDriverAssistedDeployedRamp;

  /// No description provided for @formRampBroken.
  ///
  /// In en, this message translates to:
  /// **'Ramp Broken'**
  String get formRampBroken;

  /// No description provided for @formMotorJammedOrRampBroken.
  ///
  /// In en, this message translates to:
  /// **'Motor jammed or ramp broken'**
  String get formMotorJammedOrRampBroken;

  /// No description provided for @formRampDenied.
  ///
  /// In en, this message translates to:
  /// **'Ramp Denied'**
  String get formRampDenied;

  /// No description provided for @formDriverDidNotLowerOr.
  ///
  /// In en, this message translates to:
  /// **'Driver did not lower or deploy'**
  String get formDriverDidNotLowerOr;

  /// No description provided for @formBayBlocked.
  ///
  /// In en, this message translates to:
  /// **'Bay Blocked'**
  String get formBayBlocked;

  /// No description provided for @formBlockedByBagsOrStanding.
  ///
  /// In en, this message translates to:
  /// **'Blocked by bags or standing crowd'**
  String get formBlockedByBagsOrStanding;

  /// No description provided for @formSeats.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get formSeats;

  /// No description provided for @formSeatsFree.
  ///
  /// In en, this message translates to:
  /// **'Seats Free'**
  String get formSeatsFree;

  /// No description provided for @formElderlyDisabledSeatsFree.
  ///
  /// In en, this message translates to:
  /// **'Elderly / disabled seats free'**
  String get formElderlyDisabledSeatsFree;

  /// No description provided for @formSeatsOccupied.
  ///
  /// In en, this message translates to:
  /// **'Seats Occupied'**
  String get formSeatsOccupied;

  /// No description provided for @formOthersNotGivingUpSeats.
  ///
  /// In en, this message translates to:
  /// **'Others not giving up seats'**
  String get formOthersNotGivingUpSeats;

  /// No description provided for @formSeatBroken.
  ///
  /// In en, this message translates to:
  /// **'Seat Broken'**
  String get formSeatBroken;

  /// No description provided for @formDamagedOrLooseSeating.
  ///
  /// In en, this message translates to:
  /// **'Damaged or loose seating'**
  String get formDamagedOrLooseSeating;

  /// No description provided for @formSafetyClean.
  ///
  /// In en, this message translates to:
  /// **'Safety & Clean'**
  String get formSafetyClean;

  /// No description provided for @formCleanSafe.
  ///
  /// In en, this message translates to:
  /// **'Clean & Safe'**
  String get formCleanSafe;

  /// No description provided for @formVehicleWellMaintained.
  ///
  /// In en, this message translates to:
  /// **'Vehicle well-maintained'**
  String get formVehicleWellMaintained;

  /// No description provided for @formDirtyOdor.
  ///
  /// In en, this message translates to:
  /// **'Dirty / Odor'**
  String get formDirtyOdor;

  /// No description provided for @formSpillOrUnpleasantSmell.
  ///
  /// In en, this message translates to:
  /// **'Spill or unpleasant smell'**
  String get formSpillOrUnpleasantSmell;

  /// No description provided for @formRailBroken.
  ///
  /// In en, this message translates to:
  /// **'Rail Broken'**
  String get formRailBroken;

  /// No description provided for @formGrabRailsOrStrapsLoose.
  ///
  /// In en, this message translates to:
  /// **'Grab rails or straps loose'**
  String get formGrabRailsOrStrapsLoose;

  /// No description provided for @formRecklessDriving.
  ///
  /// In en, this message translates to:
  /// **'Reckless Driving'**
  String get formRecklessDriving;

  /// No description provided for @formSuddenJerksUnsafeRide.
  ///
  /// In en, this message translates to:
  /// **'Sudden jerks, unsafe ride'**
  String get formSuddenJerksUnsafeRide;

  /// No description provided for @formElevator.
  ///
  /// In en, this message translates to:
  /// **'Elevator'**
  String get formElevator;

  /// No description provided for @formElevatorWorking.
  ///
  /// In en, this message translates to:
  /// **'Elevator Working'**
  String get formElevatorWorking;

  /// No description provided for @formOperatingSmoothlyAccessible.
  ///
  /// In en, this message translates to:
  /// **'Operating smoothly & accessible'**
  String get formOperatingSmoothlyAccessible;

  /// No description provided for @formOutOfService.
  ///
  /// In en, this message translates to:
  /// **'Out of Service'**
  String get formOutOfService;

  /// No description provided for @formElevatorShutDownOrRepair.
  ///
  /// In en, this message translates to:
  /// **'Elevator shut down or repair'**
  String get formElevatorShutDownOrRepair;

  /// No description provided for @formDoorButtonFault.
  ///
  /// In en, this message translates to:
  /// **'Door / Button Fault'**
  String get formDoorButtonFault;

  /// No description provided for @formDoorsStuckOrButtonsBroken.
  ///
  /// In en, this message translates to:
  /// **'Doors stuck or buttons broken'**
  String get formDoorsStuckOrButtonsBroken;

  /// No description provided for @formRampPath.
  ///
  /// In en, this message translates to:
  /// **'Ramp & Path'**
  String get formRampPath;

  /// No description provided for @formRampClear.
  ///
  /// In en, this message translates to:
  /// **'Ramp Clear'**
  String get formRampClear;

  /// No description provided for @formSmoothWheelchairSlope.
  ///
  /// In en, this message translates to:
  /// **'Smooth wheelchair slope'**
  String get formSmoothWheelchairSlope;

  /// No description provided for @formPathBlocked.
  ///
  /// In en, this message translates to:
  /// **'Path Blocked'**
  String get formPathBlocked;

  /// No description provided for @formVendorsOrParkedVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vendors or parked vehicles'**
  String get formVendorsOrParkedVehicles;

  /// No description provided for @formDamagedSteep.
  ///
  /// In en, this message translates to:
  /// **'Damaged / Steep'**
  String get formDamagedSteep;

  /// No description provided for @formPavementCrackedOrSteepSlope.
  ///
  /// In en, this message translates to:
  /// **'Pavement cracked or steep slope'**
  String get formPavementCrackedOrSteepSlope;

  /// No description provided for @formTactileTiles.
  ///
  /// In en, this message translates to:
  /// **'Tactile Tiles'**
  String get formTactileTiles;

  /// No description provided for @formTilesIntact.
  ///
  /// In en, this message translates to:
  /// **'Tiles Intact'**
  String get formTilesIntact;

  /// No description provided for @formGuidedTactileTilesClear.
  ///
  /// In en, this message translates to:
  /// **'Guided tactile tiles clear'**
  String get formGuidedTactileTilesClear;

  /// No description provided for @formTilesBroken.
  ///
  /// In en, this message translates to:
  /// **'Tiles Broken'**
  String get formTilesBroken;

  /// No description provided for @formLooseTilesCausingTripHazard.
  ///
  /// In en, this message translates to:
  /// **'Loose tiles causing trip hazard'**
  String get formLooseTilesCausingTripHazard;

  /// No description provided for @formUnsafeEdgeGap.
  ///
  /// In en, this message translates to:
  /// **'Unsafe Edge Gap'**
  String get formUnsafeEdgeGap;

  /// No description provided for @formExcessiveGapBetweenCurbBus.
  ///
  /// In en, this message translates to:
  /// **'Excessive gap between curb & bus'**
  String get formExcessiveGapBetweenCurbBus;

  /// No description provided for @formShelterLight.
  ///
  /// In en, this message translates to:
  /// **'Shelter & Light'**
  String get formShelterLight;

  /// No description provided for @formShelterGood.
  ///
  /// In en, this message translates to:
  /// **'Shelter Good'**
  String get formShelterGood;

  /// No description provided for @formRainProtectionSeatingIntact.
  ///
  /// In en, this message translates to:
  /// **'Rain protection & seating intact'**
  String get formRainProtectionSeatingIntact;

  /// No description provided for @formRoofDamaged.
  ///
  /// In en, this message translates to:
  /// **'Roof Damaged'**
  String get formRoofDamaged;

  /// No description provided for @formDamagedRoofOrBrokenBenches.
  ///
  /// In en, this message translates to:
  /// **'Damaged roof or broken benches'**
  String get formDamagedRoofOrBrokenBenches;

  /// No description provided for @formDarkUnsafe.
  ///
  /// In en, this message translates to:
  /// **'Dark / Unsafe'**
  String get formDarkUnsafe;

  /// No description provided for @formPoorNightLightingInWalkway.
  ///
  /// In en, this message translates to:
  /// **'Poor night lighting in walkway'**
  String get formPoorNightLightingInWalkway;

  /// No description provided for @formPhotoAttachedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Photo attached successfully!'**
  String get formPhotoAttachedSuccessfully;

  /// No description provided for @formAttachEvidencePhoto.
  ///
  /// In en, this message translates to:
  /// **'Attach Evidence Photo'**
  String get formAttachEvidencePhoto;

  /// No description provided for @formHelpVerifyConditionForCommuters.
  ///
  /// In en, this message translates to:
  /// **'Help commuters with disabilities understand the condition'**
  String get formHelpVerifyConditionForCommuters;

  /// No description provided for @formTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get formTakePhoto;

  /// No description provided for @formFromGallery.
  ///
  /// In en, this message translates to:
  /// **'From Gallery'**
  String get formFromGallery;

  /// No description provided for @formSelectTheExactBusOr.
  ///
  /// In en, this message translates to:
  /// **'Select the exact bus or stop you observed.'**
  String get formSelectTheExactBusOr;

  /// No description provided for @formChooseTheConditionAndCrowding.
  ///
  /// In en, this message translates to:
  /// **'Choose the condition and crowding level you observed.'**
  String get formChooseTheConditionAndCrowding;

  /// No description provided for @formChooseTheConditionYouObserved.
  ///
  /// In en, this message translates to:
  /// **'Choose the condition you observed.'**
  String get formChooseTheConditionYouObserved;

  /// No description provided for @formConfirmYourObservation.
  ///
  /// In en, this message translates to:
  /// **'Confirm your observation'**
  String get formConfirmYourObservation;

  /// No description provided for @formEvidence1PhotoAttached.
  ///
  /// In en, this message translates to:
  /// **'Evidence: 1 photo attached'**
  String get formEvidence1PhotoAttached;

  /// No description provided for @formYourObservationNoteAndAttached.
  ///
  /// In en, this message translates to:
  /// **'Your observation, note and attached photo will be public after publication. Avoid faces, identifying details and sensitive personal information. Submit only photos you have permission to share.'**
  String get formYourObservationNoteAndAttached;

  /// No description provided for @formPendingDraftsStayOnThis.
  ///
  /// In en, this message translates to:
  /// **'Pending drafts stay on this device for up to 7 days and are removed on sign-out/account change. You can remove them from Your uploads. Removing a draft cannot recall a request already sent or delete a public report/photo.'**
  String get formPendingDraftsStayOnThis;

  /// No description provided for @formAndroidDraftsUseEncryptedPrivate.
  ///
  /// In en, this message translates to:
  /// **'Android drafts use encrypted private storage. On other platforms drafts last only for this app session.'**
  String get formAndroidDraftsUseEncryptedPrivate;

  /// No description provided for @formEditReport.
  ///
  /// In en, this message translates to:
  /// **'Edit report'**
  String get formEditReport;

  /// No description provided for @formConfirmAndSubmit.
  ///
  /// In en, this message translates to:
  /// **'Confirm and submit'**
  String get formConfirmAndSubmit;

  /// No description provided for @formCommunityReport.
  ///
  /// In en, this message translates to:
  /// **'Community Report'**
  String get formCommunityReport;

  /// No description provided for @formHelpAccessibleTransitCommutersIn.
  ///
  /// In en, this message translates to:
  /// **'Share your observations with fellow commuters'**
  String get formHelpAccessibleTransitCommutersIn;

  /// No description provided for @formSelectBusRoute.
  ///
  /// In en, this message translates to:
  /// **'Select Bus Route'**
  String get formSelectBusRoute;

  /// No description provided for @formWhichRouteAreYouTraveling.
  ///
  /// In en, this message translates to:
  /// **'Which route are you traveling on or waiting for?'**
  String get formWhichRouteAreYouTraveling;

  /// No description provided for @formWhereIsTheIssue.
  ///
  /// In en, this message translates to:
  /// **'Where is the Issue?'**
  String get formWhereIsTheIssue;

  /// No description provided for @formChooseWhetherYouAreInside.
  ///
  /// In en, this message translates to:
  /// **'Choose whether you are inside a vehicle or at a station'**
  String get formChooseWhetherYouAreInside;

  /// No description provided for @formVehicleAccessibilityCondition.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Accessibility Condition'**
  String get formVehicleAccessibilityCondition;

  /// No description provided for @formStationAccessibilityCondition.
  ///
  /// In en, this message translates to:
  /// **'Station Accessibility Condition'**
  String get formStationAccessibilityCondition;

  /// No description provided for @formReportCrowdingLevelAndWheelchair.
  ///
  /// In en, this message translates to:
  /// **'Report crowding level and wheelchair access inside the bus'**
  String get formReportCrowdingLevelAndWheelchair;

  /// No description provided for @formReportElevatorRampAndPlatform.
  ///
  /// In en, this message translates to:
  /// **'Report elevator, ramp, and platform conditions at the stop'**
  String get formReportElevatorRampAndPlatform;

  /// No description provided for @formEvidencePhotoOptional.
  ///
  /// In en, this message translates to:
  /// **'Evidence Photo (Optional)'**
  String get formEvidencePhotoOptional;

  /// No description provided for @formTakeAPhotoOrUpload.
  ///
  /// In en, this message translates to:
  /// **'Take a photo or choose one from the gallery to document the condition'**
  String get formTakeAPhotoOrUpload;

  /// No description provided for @formAdditionalNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional Note (Optional)'**
  String get formAdditionalNoteOptional;

  /// No description provided for @formAddHelpfulDetailsForFellow.
  ///
  /// In en, this message translates to:
  /// **'Add helpful details for fellow wheelchair or elderly riders'**
  String get formAddHelpfulDetailsForFellow;

  /// No description provided for @formEGRampWasLowered.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ramp was lowered but driver needed bystander help'**
  String get formEGRampWasLowered;

  /// No description provided for @formSubmittingReport.
  ///
  /// In en, this message translates to:
  /// **'Submitting Report…'**
  String get formSubmittingReport;

  /// No description provided for @formReviewAndSubmitReport.
  ///
  /// In en, this message translates to:
  /// **'Review and submit report'**
  String get formReviewAndSubmitReport;

  /// No description provided for @formSelectARouteOptional.
  ///
  /// In en, this message translates to:
  /// **'Select a route (optional)'**
  String get formSelectARouteOptional;

  /// No description provided for @formOnABus.
  ///
  /// In en, this message translates to:
  /// **'On a Bus'**
  String get formOnABus;

  /// No description provided for @formInsideTheVehicle.
  ///
  /// In en, this message translates to:
  /// **'Inside the vehicle'**
  String get formInsideTheVehicle;

  /// No description provided for @formAtABusStop.
  ///
  /// In en, this message translates to:
  /// **'At a Bus Stop'**
  String get formAtABusStop;

  /// No description provided for @formStationPlatform.
  ///
  /// In en, this message translates to:
  /// **'Station & platform'**
  String get formStationPlatform;

  /// No description provided for @formSelectSpecificBusLicensePlate.
  ///
  /// In en, this message translates to:
  /// **'Select Specific Bus / License Plate'**
  String get formSelectSpecificBusLicensePlate;

  /// No description provided for @formSelectStopAlongThisRoute.
  ///
  /// In en, this message translates to:
  /// **'Select Stop along this route'**
  String get formSelectStopAlongThisRoute;

  /// No description provided for @formCrowdingLevel.
  ///
  /// In en, this message translates to:
  /// **'Crowding Level'**
  String get formCrowdingLevel;

  /// No description provided for @formChooseTheCrowdingLevelYou.
  ///
  /// In en, this message translates to:
  /// **'Choose the crowding level you observed.'**
  String get formChooseTheCrowdingLevelYou;

  /// No description provided for @formAccessibilityIssueCategory.
  ///
  /// In en, this message translates to:
  /// **'Accessibility Issue Category'**
  String get formAccessibilityIssueCategory;

  /// No description provided for @formStationFacilityCategory.
  ///
  /// In en, this message translates to:
  /// **'Station Facility Category'**
  String get formStationFacilityCategory;

  /// No description provided for @formPhotoUploadsAreCurrentlyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo uploads are currently unavailable. You can submit your report without a photo.'**
  String get formPhotoUploadsAreCurrentlyUnavailable;

  /// No description provided for @formPhotoAttached.
  ///
  /// In en, this message translates to:
  /// **'Photo Attached'**
  String get formPhotoAttached;

  /// No description provided for @formWillBeUploadedWithReport.
  ///
  /// In en, this message translates to:
  /// **'Will be uploaded with report'**
  String get formWillBeUploadedWithReport;

  /// No description provided for @formRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get formRemovePhoto;

  /// No description provided for @formAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get formAddPhoto;

  /// No description provided for @formTapToTakePhotoOr.
  ///
  /// In en, this message translates to:
  /// **'Tap to take photo or choose from device'**
  String get formTapToTakePhotoOr;

  /// No description provided for @formNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get formNotSelected;

  /// No description provided for @formReportSummary.
  ///
  /// In en, this message translates to:
  /// **'Report Summary'**
  String get formReportSummary;

  /// No description provided for @formLocationVehicle.
  ///
  /// In en, this message translates to:
  /// **'Location / Vehicle'**
  String get formLocationVehicle;

  /// No description provided for @formAccessibilityStatus.
  ///
  /// In en, this message translates to:
  /// **'Accessibility Status'**
  String get formAccessibilityStatus;

  /// No description provided for @formPhotoEvidence.
  ///
  /// In en, this message translates to:
  /// **'Photo Evidence'**
  String get formPhotoEvidence;

  /// No description provided for @form1PhotoAttached.
  ///
  /// In en, this message translates to:
  /// **'1 photo attached'**
  String get form1PhotoAttached;

  /// No description provided for @communityHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Community Hub'**
  String get communityHubTitle;

  /// No description provided for @communitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Community accessibility observations from fellow riders'**
  String get communitySubtitle;

  /// No description provided for @communityReportAction.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get communityReportAction;

  /// No description provided for @communityPastReports.
  ///
  /// In en, this message translates to:
  /// **'Resolved & Past Reports'**
  String get communityPastReports;

  /// No description provided for @communityNoOwnReports.
  ///
  /// In en, this message translates to:
  /// **'No Reports Yet'**
  String get communityNoOwnReports;

  /// No description provided for @communityEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No current reports'**
  String get communityEmptyTitle;

  /// No description provided for @communityOwnEmptyHelp.
  ///
  /// In en, this message translates to:
  /// **'Reports you submit about wheelchair access, crowding, or lifts will show up here.'**
  String get communityOwnEmptyHelp;

  /// No description provided for @communityEmptyHelp.
  ///
  /// In en, this message translates to:
  /// **'No current reports are available in this feed. This does not establish that conditions are accessible or safe.'**
  String get communityEmptyHelp;

  /// No description provided for @communitySubmitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit a Condition Report'**
  String get communitySubmitReport;

  /// No description provided for @communityUpdatesTab.
  ///
  /// In en, this message translates to:
  /// **'Live Updates'**
  String get communityUpdatesTab;

  /// No description provided for @communityMyReportsTab.
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get communityMyReportsTab;

  /// No description provided for @communityContributor.
  ///
  /// In en, this message translates to:
  /// **'Community Contributor'**
  String get communityContributor;

  /// No description provided for @communityPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get communityPhoto;

  /// No description provided for @communityRecheckHelp.
  ///
  /// In en, this message translates to:
  /// **'Recheck the same observed condition after 30 minutes since the latest check. No extra votes or points. Report changed conditions separately.'**
  String get communityRecheckHelp;

  /// No description provided for @communityActiveBadge.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get communityActiveBadge;

  /// No description provided for @communityConfirmedBadge.
  ///
  /// In en, this message translates to:
  /// **'Community confirmed'**
  String get communityConfirmedBadge;

  /// No description provided for @communityResolvedBadge.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get communityResolvedBadge;

  /// No description provided for @communityPastBadge.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get communityPastBadge;

  /// No description provided for @communityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Community reports unavailable. Reconnect and retry.'**
  String get communityUnavailable;

  /// No description provided for @communityRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry reports'**
  String get communityRetry;

  /// No description provided for @communityOwnSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your reports and local uploads.'**
  String get communityOwnSignIn;

  /// No description provided for @outboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Your uploads'**
  String get outboxTitle;

  /// No description provided for @outboxHelp.
  ///
  /// In en, this message translates to:
  /// **'Drafts expire after 7 days. Open an upload to retry or remove it. Sign-out removes local drafts.'**
  String get outboxHelp;

  /// No description provided for @communityStationTarget.
  ///
  /// In en, this message translates to:
  /// **'Station {id}'**
  String communityStationTarget(String id);

  /// No description provided for @communityBusTarget.
  ///
  /// In en, this message translates to:
  /// **'Bus {id}'**
  String communityBusTarget(String id);

  /// No description provided for @communityRouteTarget.
  ///
  /// In en, this message translates to:
  /// **'Bus Route {number}'**
  String communityRouteTarget(String number);

  /// No description provided for @communityContributionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 shared report currently listed. Rewards are not calculated here.} other{{count} shared reports currently listed. Rewards are not calculated here.}}'**
  String communityContributionCount(int count);

  /// No description provided for @communityChecked.
  ///
  /// In en, this message translates to:
  /// **'{freshness} · Last checked: {age}'**
  String communityChecked(String freshness, String age);

  /// No description provided for @communityTrueCount.
  ///
  /// In en, this message translates to:
  /// **'True: {count}'**
  String communityTrueCount(int count);

  /// No description provided for @communityFalseCount.
  ///
  /// In en, this message translates to:
  /// **'False: {count}/{threshold}'**
  String communityFalseCount(int count, int threshold);

  /// No description provided for @helpIntro.
  ///
  /// In en, this message translates to:
  /// **'Using AccessTransit'**
  String get helpIntro;

  /// No description provided for @helpSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Searching for a bus'**
  String get helpSearchTitle;

  /// No description provided for @helpSearchBody.
  ///
  /// In en, this message translates to:
  /// **'Choose your boarding stop, destination and boarding time within the next 24 hours. Search starts with your saved accessibility preferences. Changes made for a search apply only to that search; save account-wide defaults in Settings.'**
  String get helpSearchBody;

  /// No description provided for @helpSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'What does Save Trip do?'**
  String get helpSaveTitle;

  /// No description provided for @helpSaveBody.
  ///
  /// In en, this message translates to:
  /// **'Open a result to see Bus Details and the selected stop segment. Saving is optional. It bookmarks the selection so you can reopen its details from saved trips; it does not book a seat or start a journey. Check refreshed times and cancellation notices when reopening.'**
  String get helpSaveBody;

  /// No description provided for @helpLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Using My Location'**
  String get helpLocationTitle;

  /// No description provided for @helpLocationBody.
  ///
  /// In en, this message translates to:
  /// **'Allow location access when requested to find nearby boarding stops. Check the selected stop and direction before searching. Nearby does not establish a step-free walking route. If location is unavailable or permission is denied, choose a stop manually.'**
  String get helpLocationBody;

  /// No description provided for @helpLiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Timetable and live location'**
  String get helpLiveTitle;

  /// No description provided for @helpLiveBody.
  ///
  /// In en, this message translates to:
  /// **'A timetable is a plan, not proof that a bus has started. Future or unstarted runs show timetable information. Live position requires a started matching run and fresh GPS. If location is stale or unavailable, check the last-update wording. Estimates and arrival times can change.'**
  String get helpLiveBody;

  /// No description provided for @helpReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports and pending uploads'**
  String get helpReportsTitle;

  /// No description provided for @helpReportsBody.
  ///
  /// In en, this message translates to:
  /// **'Report the exact bus or stop and what you observed. A local draft is private and is not a published report. Open Your uploads under My Reports to retry or remove it. Drafts expire after 7 days and are removed on sign-out. Avoid private information in public notes and photos.'**
  String get helpReportsBody;

  /// No description provided for @helpVotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Voting and community disputes'**
  String get helpVotesTitle;

  /// No description provided for @helpVotesBody.
  ///
  /// In en, this message translates to:
  /// **'Authors cannot vote True or False on their own reports. Vote only from your observations and give a reason for False. Under policy v2, five eligible other users\' False votes hide a report and apply its recorded points penalty and strike. This is a community dispute, not proof of a false report. Authors can use the report review and appeal screens.'**
  String get helpVotesBody;

  /// No description provided for @helpAssistanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Boarding assistance'**
  String get helpAssistanceTitle;

  /// No description provided for @helpAssistanceBody.
  ///
  /// In en, this message translates to:
  /// **'Assistance is optional in Bus Details. Check the bus, run and boarding stop. Submitted means the request was recorded; accepted means the assigned driver accepted it. A saved trip or a sent request does not guarantee assistance. Check the latest request status, including decline, cancellation or expiry.'**
  String get helpAssistanceBody;

  /// No description provided for @helpAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Account access and review'**
  String get helpAccessTitle;

  /// No description provided for @helpAccessBody.
  ///
  /// In en, this message translates to:
  /// **'If access is restricted, read the displayed reason and expiry and use the available appeal action. An appeal does not automatically lift a restriction. Permanent bans require administrator review. Self-service account deletion is not available in Profile; reviewed administrator deletion is a separate process.'**
  String get helpAccessBody;

  /// No description provided for @rewardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rewards & Contributions'**
  String get rewardsTitle;

  /// No description provided for @rewardsMine.
  ///
  /// In en, this message translates to:
  /// **'My Contributions'**
  String get rewardsMine;

  /// No description provided for @rewardsSettingsSoon.
  ///
  /// In en, this message translates to:
  /// **'Settings will be available soon.'**
  String get rewardsSettingsSoon;

  /// No description provided for @rewardsReports.
  ///
  /// In en, this message translates to:
  /// **'Reports Submitted'**
  String get rewardsReports;

  /// No description provided for @rewardsConfirmations.
  ///
  /// In en, this message translates to:
  /// **'Recorded Confirmations'**
  String get rewardsConfirmations;

  /// No description provided for @rewardsViewCard.
  ///
  /// In en, this message translates to:
  /// **'View Membership Card'**
  String get rewardsViewCard;

  /// No description provided for @rewardsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total Points'**
  String get rewardsTotal;

  /// No description provided for @rewardsGold.
  ///
  /// In en, this message translates to:
  /// **'Gold Contributor'**
  String get rewardsGold;

  /// No description provided for @rewardsSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver Contributor'**
  String get rewardsSilver;

  /// No description provided for @rewardsBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze Contributor'**
  String get rewardsBronze;

  /// No description provided for @memberGold.
  ///
  /// In en, this message translates to:
  /// **'Gold Member'**
  String get memberGold;

  /// No description provided for @memberSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver Member'**
  String get memberSilver;

  /// No description provided for @memberBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze Member'**
  String get memberBronze;

  /// No description provided for @memberBack.
  ///
  /// In en, this message translates to:
  /// **'Back to Rewards'**
  String get memberBack;

  /// No description provided for @memberTitle.
  ///
  /// In en, this message translates to:
  /// **'Digital Membership Card'**
  String get memberTitle;

  /// No description provided for @memberPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Contribution points'**
  String get memberPointsLabel;

  /// No description provided for @memberNoCash.
  ///
  /// In en, this message translates to:
  /// **'Points have no cash or voucher value'**
  String get memberNoCash;

  /// No description provided for @memberNoRedemption.
  ///
  /// In en, this message translates to:
  /// **'Redemption unavailable'**
  String get memberNoRedemption;

  /// No description provided for @memberAvailability.
  ///
  /// In en, this message translates to:
  /// **'Reward availability'**
  String get memberAvailability;

  /// No description provided for @memberNoVouchers.
  ///
  /// In en, this message translates to:
  /// **'Partner discounts and vouchers are not available.'**
  String get memberNoVouchers;

  /// No description provided for @memberBenefits.
  ///
  /// In en, this message translates to:
  /// **'Member Benefits'**
  String get memberBenefits;

  /// No description provided for @memberNoPriority.
  ///
  /// In en, this message translates to:
  /// **'Membership does not include priority support or guaranteed access.'**
  String get memberNoPriority;

  /// No description provided for @memberRecognition.
  ///
  /// In en, this message translates to:
  /// **'Community Recognition'**
  String get memberRecognition;

  /// No description provided for @memberLedgerNotice.
  ///
  /// In en, this message translates to:
  /// **'Contribution points follow the recorded reward policy. They do not verify accessibility.'**
  String get memberLedgerNotice;

  /// No description provided for @rewardsLegacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Historical policy: points update after administrator review and may take time. Published report: 10 points; unique confirmation: 5 points. Removed votes and hidden/deleted reports reverse credits. Points do not verify accessibility and have no cash value.'**
  String get rewardsLegacyNotice;

  /// No description provided for @rewardsLevel.
  ///
  /// In en, this message translates to:
  /// **'Level: {level}'**
  String rewardsLevel(String level);

  /// No description provided for @memberPointCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Points'**
  String memberPointCount(int count);

  /// No description provided for @memberIdentity.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String memberIdentity(String id);

  /// No description provided for @assistFormUnknown.
  ///
  /// In en, this message translates to:
  /// **'The assistance bus or stop is unknown. Select a journey with an exact stop first.'**
  String get assistFormUnknown;

  /// No description provided for @assistFormSelect.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one assistance option.'**
  String get assistFormSelect;

  /// No description provided for @assistFormTarget.
  ///
  /// In en, this message translates to:
  /// **'Choose the exact bus and stop from your journey before requesting assistance.'**
  String get assistFormTarget;

  /// No description provided for @assistFormWrongStop.
  ///
  /// In en, this message translates to:
  /// **'This stop could not be verified on the selected bus. Return to your journey and choose the correct target.'**
  String get assistFormWrongStop;

  /// No description provided for @assistFormConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm assistance target'**
  String get assistFormConfirm;

  /// No description provided for @assistFormEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit request'**
  String get assistFormEdit;

  /// No description provided for @assistFormSendConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm and send'**
  String get assistFormSendConfirm;

  /// No description provided for @assistFormSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please sign in before sending an assistance request.'**
  String get assistFormSignIn;

  /// No description provided for @assistFormPrepareError.
  ///
  /// In en, this message translates to:
  /// **'Could not prepare the request. Check your sign-in and device storage, then try again.'**
  String get assistFormPrepareError;

  /// No description provided for @assistFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Assistance'**
  String get assistFormTitle;

  /// No description provided for @assistFormRamp.
  ///
  /// In en, this message translates to:
  /// **'Deploy Ramp'**
  String get assistFormRamp;

  /// No description provided for @assistFormTime.
  ///
  /// In en, this message translates to:
  /// **'Extra Time'**
  String get assistFormTime;

  /// No description provided for @assistFormBoarding.
  ///
  /// In en, this message translates to:
  /// **'Boarding Help'**
  String get assistFormBoarding;

  /// No description provided for @assistFormAlighting.
  ///
  /// In en, this message translates to:
  /// **'Getting Off Help'**
  String get assistFormAlighting;

  /// No description provided for @assistFormSend.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get assistFormSend;

  /// No description provided for @assistFormAckHelp.
  ///
  /// In en, this message translates to:
  /// **'Assistance is confirmed only after the driver acknowledges your request.'**
  String get assistFormAckHelp;

  /// No description provided for @assistFormEtaUnknown.
  ///
  /// In en, this message translates to:
  /// **'ETA unknown'**
  String get assistFormEtaUnknown;

  /// No description provided for @assistFormMinutes.
  ///
  /// In en, this message translates to:
  /// **'MIN (est.)'**
  String get assistFormMinutes;

  /// No description provided for @assistFormAccountChanged.
  ///
  /// In en, this message translates to:
  /// **'Your account changed during review. Review the request again before sending.'**
  String get assistFormAccountChanged;

  /// No description provided for @assistFormBoardAt.
  ///
  /// In en, this message translates to:
  /// **'Boarding at {stop}'**
  String assistFormBoardAt(String stop);

  /// No description provided for @assistFormAlightAt.
  ///
  /// In en, this message translates to:
  /// **'Getting off at {stop}'**
  String assistFormAlightAt(String stop);

  /// No description provided for @assistFormBusRoute.
  ///
  /// In en, this message translates to:
  /// **'{bus} (Route {route})'**
  String assistFormBusRoute(String bus, String route);

  /// No description provided for @assistFormArrival.
  ///
  /// In en, this message translates to:
  /// **'{bus} - estimated arrival in {minutes} mins'**
  String assistFormArrival(String bus, int minutes);

  /// No description provided for @assistReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Assistance request'**
  String get assistReceiptTitle;

  /// No description provided for @assistReceiptOwner.
  ///
  /// In en, this message translates to:
  /// **'Sign in with the account that created this request to view its status.'**
  String get assistReceiptOwner;

  /// No description provided for @assistReceiptSent.
  ///
  /// In en, this message translates to:
  /// **'Sent to shared service'**
  String get assistReceiptSent;

  /// No description provided for @assistReceiptUnknown.
  ///
  /// In en, this message translates to:
  /// **'Request status unknown'**
  String get assistReceiptUnknown;

  /// No description provided for @assistReceiptPendingHint.
  ///
  /// In en, this message translates to:
  /// **'Saving the request does not mean the driver has accepted it.'**
  String get assistReceiptPendingHint;

  /// No description provided for @assistReceiptAcceptedHint.
  ///
  /// In en, this message translates to:
  /// **'The driver has acknowledged the request. Assistance has not been marked completed.'**
  String get assistReceiptAcceptedHint;

  /// No description provided for @assistReceiptDelivery.
  ///
  /// In en, this message translates to:
  /// **'Request delivery'**
  String get assistReceiptDelivery;

  /// No description provided for @assistReceiptOwn.
  ///
  /// In en, this message translates to:
  /// **'Your assistance request'**
  String get assistReceiptOwn;

  /// No description provided for @assistReceiptSupport.
  ///
  /// In en, this message translates to:
  /// **'Support requested'**
  String get assistReceiptSupport;

  /// No description provided for @assistReceiptUnspecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get assistReceiptUnspecified;

  /// No description provided for @assistReceiptDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver response'**
  String get assistReceiptDriver;

  /// No description provided for @assistReceiptUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Driver acknowledgement is not confirmed.'**
  String get assistReceiptUnconfirmed;

  /// No description provided for @assistReceiptStale.
  ///
  /// In en, this message translates to:
  /// **'Live status updates are unavailable. Displayed driver status is the last received status.'**
  String get assistReceiptStale;

  /// No description provided for @assistReceiptSending.
  ///
  /// In en, this message translates to:
  /// **'Sending?'**
  String get assistReceiptSending;

  /// No description provided for @assistReceiptRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry upload'**
  String get assistReceiptRetry;

  /// No description provided for @assistReceiptCancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling?'**
  String get assistReceiptCancelling;

  /// No description provided for @assistReceiptCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get assistReceiptCancel;

  /// No description provided for @assistReceiptRetryError.
  ///
  /// In en, this message translates to:
  /// **'Could not save the retry on this device. Please try again.'**
  String get assistReceiptRetryError;

  /// No description provided for @assistReceiptCancelError.
  ///
  /// In en, this message translates to:
  /// **'Cancellation is not confirmed. Check your connection and try again.'**
  String get assistReceiptCancelError;

  /// No description provided for @assistReceiptPendingUpload.
  ///
  /// In en, this message translates to:
  /// **'Pending upload'**
  String get assistReceiptPendingUpload;

  /// No description provided for @assistReceiptDeliverySent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get assistReceiptDeliverySent;

  /// No description provided for @assistReceiptFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get assistReceiptFailed;

  /// No description provided for @assistReceiptExpired.
  ///
  /// In en, this message translates to:
  /// **'Retry expired'**
  String get assistReceiptExpired;

  /// No description provided for @assistReceiptOld.
  ///
  /// In en, this message translates to:
  /// **'Automatic retries stopped because this request is old. Check the driver status; delivery may still be unconfirmed.'**
  String get assistReceiptOld;

  /// No description provided for @assistReceiptDeliveryError.
  ///
  /// In en, this message translates to:
  /// **'Delivery is not confirmed. Retry when connected; keep checking the driver status.'**
  String get assistReceiptDeliveryError;

  /// No description provided for @assistReceiptSendError.
  ///
  /// In en, this message translates to:
  /// **'The request could not be sent. Check your sign-in and target, then retry.'**
  String get assistReceiptSendError;

  /// No description provided for @assistReceiptRestoreError.
  ///
  /// In en, this message translates to:
  /// **'Some saved assistance requests could not be restored. Check your shared request history.'**
  String get assistReceiptRestoreError;

  /// No description provided for @assistReceiptSaveError.
  ///
  /// In en, this message translates to:
  /// **'The latest request status could not be saved on this device. Check the shared request history.'**
  String get assistReceiptSaveError;

  /// No description provided for @assistReceiptHistory.
  ///
  /// In en, this message translates to:
  /// **'Your assistance requests'**
  String get assistReceiptHistory;

  /// No description provided for @assistReceiptHistoryStale.
  ///
  /// In en, this message translates to:
  /// **'Shared request updates are unavailable. Saved receipts may be out of date.'**
  String get assistReceiptHistoryStale;

  /// No description provided for @assistReceiptError.
  ///
  /// In en, this message translates to:
  /// **'Request status is unavailable. Check your connection and account, then retry.'**
  String get assistReceiptError;

  /// No description provided for @assistReceiptRoute.
  ///
  /// In en, this message translates to:
  /// **'Route {route}'**
  String assistReceiptRoute(String route);

  /// No description provided for @assistReceiptSummary.
  ///
  /// In en, this message translates to:
  /// **'Route {route} · {stop}'**
  String assistReceiptSummary(String route, String stop);

  /// No description provided for @sharedCatalogueDemo.
  ///
  /// In en, this message translates to:
  /// **'DEMONSTRATION: Sample transit data. Shared reporting, assistance and journeys are disabled.'**
  String get sharedCatalogueDemo;

  /// No description provided for @sharedCatalogueSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved transit data. Refresh to check for updates; timetables and availability may have changed.'**
  String get sharedCatalogueSaved;

  /// No description provided for @sharedCatalogueUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Transit data unavailable. Connect and retry; no sample services are substituted.'**
  String get sharedCatalogueUnavailable;

  /// No description provided for @sharedCatalogueEmpty.
  ///
  /// In en, this message translates to:
  /// **'No shared transit data available for this catalogue. Please retry later.'**
  String get sharedCatalogueEmpty;

  /// No description provided for @sharedRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get sharedRefresh;

  /// No description provided for @sharedRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing…'**
  String get sharedRefreshing;

  /// No description provided for @sharedSavingStatus.
  ///
  /// In en, this message translates to:
  /// **'Saving status…'**
  String get sharedSavingStatus;

  /// No description provided for @sharedOperatorStatusError.
  ///
  /// In en, this message translates to:
  /// **'Status update was not confirmed. Check your connection, operator approval and bus assignment, then retry.'**
  String get sharedOperatorStatusError;

  /// No description provided for @sharedAdminAccess.
  ///
  /// In en, this message translates to:
  /// **'Administrator access'**
  String get sharedAdminAccess;

  /// No description provided for @sharedAdminChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking administrator access...'**
  String get sharedAdminChecking;

  /// No description provided for @sharedAdminRequired.
  ///
  /// In en, this message translates to:
  /// **'An administrator claim and an online connection are required. A profile role does not grant access.'**
  String get sharedAdminRequired;

  /// No description provided for @sharedCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get sharedCheckAgain;

  /// No description provided for @sharedSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get sharedSignIn;

  /// No description provided for @sharedSavedJourney.
  ///
  /// In en, this message translates to:
  /// **'Saved journey'**
  String get sharedSavedJourney;

  /// No description provided for @sharedJourneyUpdatesError.
  ///
  /// In en, this message translates to:
  /// **'Saved journey updates unavailable. Check your connection and reopen Home to retry.'**
  String get sharedJourneyUpdatesError;

  /// No description provided for @sharedJourneyChangeError.
  ///
  /// In en, this message translates to:
  /// **'Journey status change is not confirmed. Retry when connected.'**
  String get sharedJourneyChangeError;

  /// No description provided for @sharedResume.
  ///
  /// In en, this message translates to:
  /// **'Resume journey'**
  String get sharedResume;

  /// No description provided for @sharedComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark completed'**
  String get sharedComplete;

  /// No description provided for @sharedCancelJourney.
  ///
  /// In en, this message translates to:
  /// **'Cancel saved journey'**
  String get sharedCancelJourney;

  /// No description provided for @sharedSaveDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Saving keeps this selection. It does not book a seat or start a journey.'**
  String get sharedSaveDisclosure;

  /// No description provided for @sharedSaveStatusError.
  ///
  /// In en, this message translates to:
  /// **'Saved status unavailable. Retry to verify your bookmark.'**
  String get sharedSaveStatusError;

  /// No description provided for @sharedSaveError.
  ///
  /// In en, this message translates to:
  /// **'Save change is not confirmed. Check your connection and retry.'**
  String get sharedSaveError;

  /// No description provided for @sharedSaveOwner.
  ///
  /// In en, this message translates to:
  /// **'Sign in with the account saving this trip.'**
  String get sharedSaveOwner;

  /// No description provided for @sharedSaveMismatch.
  ///
  /// In en, this message translates to:
  /// **'Saved trip acknowledgement did not match.'**
  String get sharedSaveMismatch;

  /// No description provided for @sharedSaveSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save this trip.'**
  String get sharedSaveSignIn;

  /// No description provided for @sharedSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get sharedSaving;

  /// No description provided for @sharedStopAlert.
  ///
  /// In en, this message translates to:
  /// **'Stop alert unavailable'**
  String get sharedStopAlert;

  /// No description provided for @sharedStopAlertHelp.
  ///
  /// In en, this message translates to:
  /// **'Automatic stop alerts and background notifications are unavailable. Follow trip progress manually; the app will not notify you before your stop.'**
  String get sharedStopAlertHelp;

  /// No description provided for @sharedSplashTagline.
  ///
  /// In en, this message translates to:
  /// **'Your journey to inclusive travel begins here.'**
  String get sharedSplashTagline;

  /// No description provided for @sharedLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading.'**
  String get sharedLoading;

  /// No description provided for @sharedStopsOrder.
  ///
  /// In en, this message translates to:
  /// **'Stops in travel order'**
  String get sharedStopsOrder;

  /// No description provided for @sharedDriverReviewHelp.
  ///
  /// In en, this message translates to:
  /// **'Driver registration is an application for access. Review identity and operating authority before approval. Approval does not verify equipment or guarantee a service.'**
  String get sharedDriverReviewHelp;

  /// No description provided for @sharedAddStation.
  ///
  /// In en, this message translates to:
  /// **'Add New Halt / Station'**
  String get sharedAddStation;

  /// No description provided for @sharedStationName.
  ///
  /// In en, this message translates to:
  /// **'Station Name'**
  String get sharedStationName;

  /// No description provided for @sharedStationExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bambalapitiya Junction'**
  String get sharedStationExample;

  /// No description provided for @sharedStationId.
  ///
  /// In en, this message translates to:
  /// **'Station ID (e.g. bambalapitiya_junc)'**
  String get sharedStationId;

  /// No description provided for @sharedTargetRoute.
  ///
  /// In en, this message translates to:
  /// **'Target Bus Route'**
  String get sharedTargetRoute;

  /// No description provided for @sharedInsertIndex.
  ///
  /// In en, this message translates to:
  /// **'Insert Position Index (0-based)'**
  String get sharedInsertIndex;

  /// No description provided for @sharedInsertHint.
  ///
  /// In en, this message translates to:
  /// **'1 (insert as 2nd stop)'**
  String get sharedInsertHint;

  /// No description provided for @sharedRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get sharedRequired;

  /// No description provided for @sharedRamp.
  ///
  /// In en, this message translates to:
  /// **'Ramp'**
  String get sharedRamp;

  /// No description provided for @sharedElevator.
  ///
  /// In en, this message translates to:
  /// **'Elevator'**
  String get sharedElevator;

  /// No description provided for @sharedCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get sharedCancel;

  /// No description provided for @sharedAddStationAction.
  ///
  /// In en, this message translates to:
  /// **'Add Station'**
  String get sharedAddStationAction;

  /// No description provided for @sharedStationError.
  ///
  /// In en, this message translates to:
  /// **'Could not add the stop. Check your access and connection, then retry.'**
  String get sharedStationError;

  /// No description provided for @sharedLiveAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Live Accessibility'**
  String get sharedLiveAccessibility;

  /// No description provided for @sharedEquipmentHelp.
  ///
  /// In en, this message translates to:
  /// **'Equipment checks are separate from live GPS. A working report does not verify the whole journey.'**
  String get sharedEquipmentHelp;

  /// No description provided for @sharedConditionsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Condition updates unavailable. Working conditions are Unknown; earlier warnings are retained.'**
  String get sharedConditionsUnavailable;

  /// No description provided for @sharedRampWarning.
  ///
  /// In en, this message translates to:
  /// **'Vehicle ramp telemetry reports a problem. Equipment-check time is Unknown; check before boarding.'**
  String get sharedRampWarning;

  /// No description provided for @sharedCommunityObservations.
  ///
  /// In en, this message translates to:
  /// **'Community observations'**
  String get sharedCommunityObservations;

  /// No description provided for @sharedRampUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown — vehicle ramp warning needs checking'**
  String get sharedRampUnknown;

  /// No description provided for @sharedDriverAssistance.
  ///
  /// In en, this message translates to:
  /// **'Driver assistance'**
  String get sharedDriverAssistance;

  /// No description provided for @sharedPositiveAssistance.
  ///
  /// In en, this message translates to:
  /// **'Positive assistance observation'**
  String get sharedPositiveAssistance;

  /// No description provided for @sharedOperatorCheck.
  ///
  /// In en, this message translates to:
  /// **'Operator vehicle check'**
  String get sharedOperatorCheck;

  /// No description provided for @sharedHideObservations.
  ///
  /// In en, this message translates to:
  /// **'Hide observation details'**
  String get sharedHideObservations;

  /// No description provided for @sharedViewObservations.
  ///
  /// In en, this message translates to:
  /// **'View observation details'**
  String get sharedViewObservations;

  /// No description provided for @sharedVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle: {vehicle}'**
  String sharedVehicle(String vehicle);

  /// No description provided for @sharedTimetable.
  ///
  /// In en, this message translates to:
  /// **'Timetable: {time}'**
  String sharedTimetable(String time);

  /// No description provided for @sharedStationAdded.
  ///
  /// In en, this message translates to:
  /// **'Stop \"{name}\" added to {bus} at position {index}.'**
  String sharedStationAdded(String name, String bus, String index);

  /// No description provided for @sharedBusOption.
  ///
  /// In en, this message translates to:
  /// **'Bus {route} ({id})'**
  String sharedBusOption(String route, String id);

  /// No description provided for @sharedBoardingElevator.
  ///
  /// In en, this message translates to:
  /// **'Boarding stop elevator — {stop}'**
  String sharedBoardingElevator(String stop);

  /// No description provided for @sharedDestinationElevator.
  ///
  /// In en, this message translates to:
  /// **'Destination stop elevator — {stop}'**
  String sharedDestinationElevator(String stop);

  /// No description provided for @legacyUi0.
  ///
  /// In en, this message translates to:
  /// **'Working reported'**
  String get legacyUi0;

  /// No description provided for @legacyUi1.
  ///
  /// In en, this message translates to:
  /// **'Barrier reported'**
  String get legacyUi1;

  /// No description provided for @legacyUi2.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save and resume your journey.'**
  String get legacyUi2;

  /// No description provided for @legacyUi3.
  ///
  /// In en, this message translates to:
  /// **'Journey ownership or status changed. Reopen your saved journeys.'**
  String get legacyUi3;

  /// No description provided for @legacyUi4.
  ///
  /// In en, this message translates to:
  /// **'Journey save is not confirmed. Check your connection and sign-in, then retry.'**
  String get legacyUi4;

  /// No description provided for @legacyUi5.
  ///
  /// In en, this message translates to:
  /// **'Vehicle not specified'**
  String get legacyUi5;

  /// No description provided for @legacyUi6.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get legacyUi6;

  /// No description provided for @legacyUi7.
  ///
  /// In en, this message translates to:
  /// **'Confirm Journey'**
  String get legacyUi7;

  /// No description provided for @legacyUi8.
  ///
  /// In en, this message translates to:
  /// **'Travel schedule'**
  String get legacyUi8;

  /// No description provided for @legacyUi9.
  ///
  /// In en, this message translates to:
  /// **'Selected date'**
  String get legacyUi9;

  /// No description provided for @legacyUi10.
  ///
  /// In en, this message translates to:
  /// **'Selected time'**
  String get legacyUi10;

  /// No description provided for @legacyUi11.
  ///
  /// In en, this message translates to:
  /// **'First available service on selected date'**
  String get legacyUi11;

  /// No description provided for @legacyUi12.
  ///
  /// In en, this message translates to:
  /// **'Timetable departure'**
  String get legacyUi12;

  /// No description provided for @legacyUi13.
  ///
  /// In en, this message translates to:
  /// **'Estimated arrival'**
  String get legacyUi13;

  /// No description provided for @legacyUi14.
  ///
  /// In en, this message translates to:
  /// **'Some timetable intervals are missing. Times include model estimates; confirm them with the operator.'**
  String get legacyUi14;

  /// No description provided for @legacyUi15.
  ///
  /// In en, this message translates to:
  /// **'Estimated fare'**
  String get legacyUi15;

  /// No description provided for @legacyUi16.
  ///
  /// In en, this message translates to:
  /// **'Prototype estimate. Confirm the actual fare with the operator.'**
  String get legacyUi16;

  /// No description provided for @legacyUi17.
  ///
  /// In en, this message translates to:
  /// **'Fare details'**
  String get legacyUi17;

  /// No description provided for @legacyUi18.
  ///
  /// In en, this message translates to:
  /// **'Travel requirements'**
  String get legacyUi18;

  /// No description provided for @legacyUi19.
  ///
  /// In en, this message translates to:
  /// **'Saving a journey does not book a seat or confirm that the bus is running. Review current condition evidence.'**
  String get legacyUi19;

  /// No description provided for @legacyUi20.
  ///
  /// In en, this message translates to:
  /// **'Saving journey...'**
  String get legacyUi20;

  /// No description provided for @legacyUi21.
  ///
  /// In en, this message translates to:
  /// **'Confirm and save journey'**
  String get legacyUi21;

  /// No description provided for @legacyUi22.
  ///
  /// In en, this message translates to:
  /// **'Service unavailable. Select a shared service first.'**
  String get legacyUi22;

  /// No description provided for @legacyUi23.
  ///
  /// In en, this message translates to:
  /// **'This service is unavailable. Return to search.'**
  String get legacyUi23;

  /// No description provided for @legacyUi24.
  ///
  /// In en, this message translates to:
  /// **'Departure & Route Details'**
  String get legacyUi24;

  /// No description provided for @legacyUi25.
  ///
  /// In en, this message translates to:
  /// **'Saved location - live updates unavailable. This is not current bus movement.'**
  String get legacyUi25;

  /// No description provided for @legacyUi26.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULE'**
  String get legacyUi26;

  /// No description provided for @legacyUi27.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULED'**
  String get legacyUi27;

  /// No description provided for @legacyUi28.
  ///
  /// In en, this message translates to:
  /// **'EXPECTED ARRIVAL'**
  String get legacyUi28;

  /// No description provided for @legacyUi29.
  ///
  /// In en, this message translates to:
  /// **'Request Boarding Assistance'**
  String get legacyUi29;

  /// No description provided for @legacyUi30.
  ///
  /// In en, this message translates to:
  /// **'Route Stops Schedule & Live Progress'**
  String get legacyUi30;

  /// No description provided for @legacyUi31.
  ///
  /// In en, this message translates to:
  /// **'YOUR BOARDING STOP'**
  String get legacyUi31;

  /// No description provided for @legacyUi32.
  ///
  /// In en, this message translates to:
  /// **'BUS IS HERE NOW'**
  String get legacyUi32;

  /// No description provided for @legacyUi33.
  ///
  /// In en, this message translates to:
  /// **'Selected segment estimate; payment options unverified.'**
  String get legacyUi33;

  /// No description provided for @legacyUi34.
  ///
  /// In en, this message translates to:
  /// **'Unknown — no condition evidence available.'**
  String get legacyUi34;

  /// No description provided for @legacyUi35.
  ///
  /// In en, this message translates to:
  /// **'ACCESSIBLE VEHICLE FEATURES'**
  String get legacyUi35;

  /// No description provided for @legacyUi36.
  ///
  /// In en, this message translates to:
  /// **'ACCESSIBILITY WARNING'**
  String get legacyUi36;

  /// No description provided for @legacyUi37.
  ///
  /// In en, this message translates to:
  /// **'NOT ACCESSIBLE NOTICE'**
  String get legacyUi37;

  /// No description provided for @legacyUi38.
  ///
  /// In en, this message translates to:
  /// **'CONDITION UNKNOWN'**
  String get legacyUi38;

  /// No description provided for @legacyUi39.
  ///
  /// In en, this message translates to:
  /// **'Safety & Ride Conditions'**
  String get legacyUi39;

  /// No description provided for @legacyUi40.
  ///
  /// In en, this message translates to:
  /// **'Bus Crowd Level'**
  String get legacyUi40;

  /// No description provided for @legacyUi41.
  ///
  /// In en, this message translates to:
  /// **'Community Safety Reports'**
  String get legacyUi41;

  /// No description provided for @legacyUi42.
  ///
  /// In en, this message translates to:
  /// **'Review and confirm journey'**
  String get legacyUi42;

  /// No description provided for @legacyUi43.
  ///
  /// In en, this message translates to:
  /// **'Save to Trip Plan'**
  String get legacyUi43;

  /// No description provided for @legacyUi44.
  ///
  /// In en, this message translates to:
  /// **'Report Accessibility Condition'**
  String get legacyUi44;

  /// No description provided for @legacyUi45.
  ///
  /// In en, this message translates to:
  /// **'Unable to Load Journey'**
  String get legacyUi45;

  /// No description provided for @legacyUi46.
  ///
  /// In en, this message translates to:
  /// **'Loading live journey details from server'**
  String get legacyUi46;

  /// No description provided for @legacyUi47.
  ///
  /// In en, this message translates to:
  /// **'Loading your journey…'**
  String get legacyUi47;

  /// No description provided for @legacyUi48.
  ///
  /// In en, this message translates to:
  /// **'Bus has not been assigned yet.'**
  String get legacyUi48;

  /// No description provided for @legacyUi49.
  ///
  /// In en, this message translates to:
  /// **'A saved trip does not reserve a seat or guarantee bus assignment. Check the selected service status.'**
  String get legacyUi49;

  /// No description provided for @legacyUi50.
  ///
  /// In en, this message translates to:
  /// **'Return to Home screen'**
  String get legacyUi50;

  /// No description provided for @legacyUi51.
  ///
  /// In en, this message translates to:
  /// **'Close Live Navigation'**
  String get legacyUi51;

  /// No description provided for @legacyUi52.
  ///
  /// In en, this message translates to:
  /// **'Live Navigation'**
  String get legacyUi52;

  /// No description provided for @legacyUi53.
  ///
  /// In en, this message translates to:
  /// **'Back to Route Results'**
  String get legacyUi53;

  /// No description provided for @legacyUi54.
  ///
  /// In en, this message translates to:
  /// **'Live Tracking to'**
  String get legacyUi54;

  /// No description provided for @legacyUi55.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get legacyUi55;

  /// No description provided for @legacyUi56.
  ///
  /// In en, this message translates to:
  /// **'SCHED'**
  String get legacyUi56;

  /// No description provided for @legacyUi57.
  ///
  /// In en, this message translates to:
  /// **'Real-time stop progression & ETA'**
  String get legacyUi57;

  /// No description provided for @legacyUi58.
  ///
  /// In en, this message translates to:
  /// **'Live Stops'**
  String get legacyUi58;

  /// No description provided for @legacyUi59.
  ///
  /// In en, this message translates to:
  /// **'YOUR STOP'**
  String get legacyUi59;

  /// No description provided for @legacyUi60.
  ///
  /// In en, this message translates to:
  /// **'Bus is currently here'**
  String get legacyUi60;

  /// No description provided for @legacyUi61.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get legacyUi61;

  /// No description provided for @legacyUi62.
  ///
  /// In en, this message translates to:
  /// **'Live GPS updates are unavailable. Equipment observations are shown separately below.'**
  String get legacyUi62;

  /// No description provided for @legacyUi63.
  ///
  /// In en, this message translates to:
  /// **'● Ongoing'**
  String get legacyUi63;

  /// No description provided for @legacyUi64.
  ///
  /// In en, this message translates to:
  /// **'● Scheduled'**
  String get legacyUi64;

  /// No description provided for @legacyUi65.
  ///
  /// In en, this message translates to:
  /// **'Tracking shows the current vehicle location; it does not confirm your scheduled run.'**
  String get legacyUi65;

  /// No description provided for @legacyUi66.
  ///
  /// In en, this message translates to:
  /// **'Detailed Vehicle Telemetry'**
  String get legacyUi66;

  /// No description provided for @legacyUi67.
  ///
  /// In en, this message translates to:
  /// **'Speed, GPS signals and raw trip data'**
  String get legacyUi67;

  /// No description provided for @legacyUi68.
  ///
  /// In en, this message translates to:
  /// **'Approaching'**
  String get legacyUi68;

  /// No description provided for @legacyUi69.
  ///
  /// In en, this message translates to:
  /// **'You Board Here'**
  String get legacyUi69;

  /// No description provided for @legacyUi70.
  ///
  /// In en, this message translates to:
  /// **'TIMETABLE'**
  String get legacyUi70;

  /// No description provided for @legacyUi71.
  ///
  /// In en, this message translates to:
  /// **'Collapse map'**
  String get legacyUi71;

  /// No description provided for @legacyUi72.
  ///
  /// In en, this message translates to:
  /// **'Expand map'**
  String get legacyUi72;

  /// No description provided for @legacyUi73.
  ///
  /// In en, this message translates to:
  /// **'Fit journey bounds'**
  String get legacyUi73;

  /// No description provided for @legacyUi74.
  ///
  /// In en, this message translates to:
  /// **'Focus on bus'**
  String get legacyUi74;

  /// No description provided for @legacyUi75.
  ///
  /// In en, this message translates to:
  /// **'Focus on my stop'**
  String get legacyUi75;

  /// No description provided for @legacyUi76.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get legacyUi76;

  /// No description provided for @legacyUi77.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get legacyUi77;

  /// No description provided for @legacyUi78.
  ///
  /// In en, this message translates to:
  /// **'No GPS signal'**
  String get legacyUi78;

  /// No description provided for @legacyUi79.
  ///
  /// In en, this message translates to:
  /// **'Signal Lost'**
  String get legacyUi79;

  /// No description provided for @legacyUi80.
  ///
  /// In en, this message translates to:
  /// **'En Route'**
  String get legacyUi80;

  /// No description provided for @legacyUi81.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get legacyUi81;

  /// No description provided for @legacyUi82.
  ///
  /// In en, this message translates to:
  /// **'Trip Completed'**
  String get legacyUi82;

  /// No description provided for @legacyUi83.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get legacyUi83;

  /// No description provided for @legacyUi84.
  ///
  /// In en, this message translates to:
  /// **'Saved location - updates unavailable'**
  String get legacyUi84;

  /// No description provided for @legacyUi85.
  ///
  /// In en, this message translates to:
  /// **'Status: Live GPS updates receiving'**
  String get legacyUi85;

  /// No description provided for @legacyUi86.
  ///
  /// In en, this message translates to:
  /// **'Status: Location unavailable'**
  String get legacyUi86;

  /// No description provided for @legacyUi87.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get legacyUi87;

  /// No description provided for @legacyUi88.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get legacyUi88;

  /// No description provided for @legacyUi89.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get legacyUi89;

  /// No description provided for @legacyUi90.
  ///
  /// In en, this message translates to:
  /// **'Next Stop'**
  String get legacyUi90;

  /// No description provided for @legacyUi91.
  ///
  /// In en, this message translates to:
  /// **'Your Destination'**
  String get legacyUi91;

  /// No description provided for @legacyUi92.
  ///
  /// In en, this message translates to:
  /// **'Next: '**
  String get legacyUi92;

  /// No description provided for @legacyUi93.
  ///
  /// In en, this message translates to:
  /// **'Final: '**
  String get legacyUi93;

  /// No description provided for @legacyUi94.
  ///
  /// In en, this message translates to:
  /// **'Request boarding or stop assistance from driver'**
  String get legacyUi94;

  /// No description provided for @legacyUi95.
  ///
  /// In en, this message translates to:
  /// **'Request Stop Assistance'**
  String get legacyUi95;

  /// No description provided for @legacyUi96.
  ///
  /// In en, this message translates to:
  /// **'Emergency calling unavailable. Use your phone to call for help.'**
  String get legacyUi96;

  /// No description provided for @legacyUi97.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get legacyUi97;

  /// No description provided for @legacyUi98.
  ///
  /// In en, this message translates to:
  /// **'Report accessibility issue or vehicle condition'**
  String get legacyUi98;

  /// No description provided for @legacyUi99.
  ///
  /// In en, this message translates to:
  /// **'Emergency calling is unavailable in this app. Use your phone to call for help.'**
  String get legacyUi99;

  /// No description provided for @legacyUi100.
  ///
  /// In en, this message translates to:
  /// **'Live Per-Stop Timeline'**
  String get legacyUi100;

  /// No description provided for @legacyUi101.
  ///
  /// In en, this message translates to:
  /// **'Live Run'**
  String get legacyUi101;

  /// No description provided for @sharedCatalogueRefreshError.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh transit data. Saved data may be out of date; retry when connected.'**
  String get sharedCatalogueRefreshError;

  /// No description provided for @legacyFormat0.
  ///
  /// In en, this message translates to:
  /// **'Bus {p0}'**
  String legacyFormat0(String p0);

  /// No description provided for @legacyFormat1.
  ///
  /// In en, this message translates to:
  /// **'Route {p0}'**
  String legacyFormat1(String p0);

  /// No description provided for @legacyFormat2.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Stops ({p0})'**
  String legacyFormat2(String p0);

  /// No description provided for @legacyFormat3.
  ///
  /// In en, this message translates to:
  /// **'Scheduled: {p0}'**
  String legacyFormat3(String p0);

  /// No description provided for @legacyFormat4.
  ///
  /// In en, this message translates to:
  /// **'Arriving in {p0} min'**
  String legacyFormat4(String p0);

  /// No description provided for @legacyFormat5.
  ///
  /// In en, this message translates to:
  /// **'Destination: {p0}'**
  String legacyFormat5(String p0);

  /// No description provided for @legacyFormat6.
  ///
  /// In en, this message translates to:
  /// **'Live interactive map showing bus {p0} heading toward {p1}'**
  String legacyFormat6(String p0, String p1);

  /// No description provided for @legacyFormat7.
  ///
  /// In en, this message translates to:
  /// **'Next Stop: {p0}'**
  String legacyFormat7(String p0);

  /// No description provided for @legacyFormat8.
  ///
  /// In en, this message translates to:
  /// **'Bus status: {p0}. Last updated: {p1}. Next stop: {p2}. Passenger stop: {p3}.'**
  String legacyFormat8(String p0, String p1, String p2, String p3);

  /// No description provided for @legacyFormat9.
  ///
  /// In en, this message translates to:
  /// **'at {p0}'**
  String legacyFormat9(String p0);

  /// No description provided for @legacyFormat10.
  ///
  /// In en, this message translates to:
  /// **'Scheduled: {p0}'**
  String legacyFormat10(String p0);

  /// No description provided for @legacyFormat11.
  ///
  /// In en, this message translates to:
  /// **'Expected: {p0}'**
  String legacyFormat11(String p0);

  /// No description provided for @legacyFormat12.
  ///
  /// In en, this message translates to:
  /// **'Driver Notice: {p0} (+{p1} mins)'**
  String legacyFormat12(String p0, String p1);

  /// No description provided for @legacyFormat13.
  ///
  /// In en, this message translates to:
  /// **'Distance: {p0} km to {p1}'**
  String legacyFormat13(String p0, String p1);

  /// No description provided for @legacyFormat14.
  ///
  /// In en, this message translates to:
  /// **'Journey progress: Bus approaching next stop {p0} towards destination {p1}'**
  String legacyFormat14(String p0, String p1);

  /// No description provided for @legacyFormat15.
  ///
  /// In en, this message translates to:
  /// **'Notify driver you need extra time or ramp deployment at {p0}.'**
  String legacyFormat15(String p0);

  /// No description provided for @legacyFormat16.
  ///
  /// In en, this message translates to:
  /// **'Reached at {p0}'**
  String legacyFormat16(String p0);

  /// No description provided for @legacyFormat17.
  ///
  /// In en, this message translates to:
  /// **'Bus is here now (Confirmed {p0})'**
  String legacyFormat17(String p0);

  /// No description provided for @legacyFormat18.
  ///
  /// In en, this message translates to:
  /// **'Est. {p0} (in about {p1} min)'**
  String legacyFormat18(String p0, String p1);

  /// No description provided for @legacyFormat19.
  ///
  /// In en, this message translates to:
  /// **'Selected timetable departure: {p0} — current GPS does not confirm this scheduled run.'**
  String legacyFormat19(String p0);

  /// No description provided for @legacyFormat20.
  ///
  /// In en, this message translates to:
  /// **'+{p0} min late'**
  String legacyFormat20(String p0);

  /// No description provided for @legacyFormat21.
  ///
  /// In en, this message translates to:
  /// **'Driver Alert: {p0} (+{p1}m)'**
  String legacyFormat21(String p0, String p1);

  /// No description provided for @legacyFormat22.
  ///
  /// In en, this message translates to:
  /// **'at {p0}'**
  String legacyFormat22(String p0);

  /// No description provided for @legacyFormat23.
  ///
  /// In en, this message translates to:
  /// **'Passed at {p0}'**
  String legacyFormat23(String p0);

  /// No description provided for @legacyFormat24.
  ///
  /// In en, this message translates to:
  /// **'Sched: {p0} · Exp: {p1}'**
  String legacyFormat24(String p0, String p1);

  /// No description provided for @legacyFormat25.
  ///
  /// In en, this message translates to:
  /// **'(+{p0} min late)'**
  String legacyFormat25(String p0);

  /// No description provided for @legacyFormat26.
  ///
  /// In en, this message translates to:
  /// **'{p0} crowding'**
  String legacyFormat26(String p0);

  /// No description provided for @sharedOnTime.
  ///
  /// In en, this message translates to:
  /// **'On Time'**
  String get sharedOnTime;

  /// No description provided for @sharedSampleNotice.
  ///
  /// In en, this message translates to:
  /// **'SAMPLE / TEST MODE — fictional vehicles, reports, equipment and GPS. Not for travel decisions.'**
  String get sharedSampleNotice;

  /// No description provided for @sharedLocalNotice.
  ///
  /// In en, this message translates to:
  /// **'LOCAL TEST ONLY - synthetic services, no real transit or Cloudinary uploads'**
  String get sharedLocalNotice;

  /// No description provided for @legacyEtaNow.
  ///
  /// In en, this message translates to:
  /// **'Bus arriving now'**
  String get legacyEtaNow;

  /// No description provided for @legacyEtaApprox.
  ///
  /// In en, this message translates to:
  /// **'Bus arriving in approximately {minutes} minutes'**
  String legacyEtaApprox(String minutes);

  /// No description provided for @legacySpeedNext.
  ///
  /// In en, this message translates to:
  /// **'{speed} km/h · Next: {stop}'**
  String legacySpeedNext(String speed, String stop);

  /// No description provided for @formReviewPublicNotice.
  ///
  /// In en, this message translates to:
  /// **'Your report and photo will be public. Avoid faces and personal information.'**
  String get formReviewPublicNotice;

  /// No description provided for @formReviewDetails.
  ///
  /// In en, this message translates to:
  /// **'Privacy and saved drafts'**
  String get formReviewDetails;

  /// No description provided for @formReviewCooldownShort.
  ///
  /// In en, this message translates to:
  /// **'Wait 5 minutes before reporting the same issue here again.'**
  String get formReviewCooldownShort;

  /// No description provided for @deliveryServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The report service cannot be reached. Your draft is saved. Retry when the service is available.'**
  String get deliveryServiceUnavailable;

  /// No description provided for @deliveryServiceConfiguration.
  ///
  /// In en, this message translates to:
  /// **'This app is not connected to the report service. Open the configured main app and retry your saved draft.'**
  String get deliveryServiceConfiguration;

  /// No description provided for @deliveryPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Publication permission was denied. Check that you are using the configured main app and sign in again before retrying. Your draft is saved.'**
  String get deliveryPermissionDenied;

  /// No description provided for @deliveryTargetIneligible.
  ///
  /// In en, this message translates to:
  /// **'This bus or stop is not eligible for publication. An administrator must review its catalogue record. Your draft is saved.'**
  String get deliveryTargetIneligible;

  /// No description provided for @deliveryInvalidReport.
  ///
  /// In en, this message translates to:
  /// **'The report service could not accept these report details. Review the selected bus or stop and observation before trying again.'**
  String get deliveryInvalidReport;

  /// No description provided for @adminAccessibilityDetails.
  ///
  /// In en, this message translates to:
  /// **'Accessibility details'**
  String get adminAccessibilityDetails;

  /// No description provided for @resultsOutsideNeeds.
  ///
  /// In en, this message translates to:
  /// **'{count} scheduled options do not meet your current accessibility requirements.'**
  String resultsOutsideNeeds(int count);

  /// No description provided for @resultsRemoveAccessFilters.
  ///
  /// In en, this message translates to:
  /// **'Show without accessibility filters'**
  String get resultsRemoveAccessFilters;

  /// No description provided for @resultsTemporaryFiltersHelp.
  ///
  /// In en, this message translates to:
  /// **'Changes this search only. These services may have unknown access or barriers; your saved preferences stay unchanged.'**
  String get resultsTemporaryFiltersHelp;
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
