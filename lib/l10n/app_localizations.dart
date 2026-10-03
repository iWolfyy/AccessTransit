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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AccessTransit'**
  String get appTitle;

  /// No description provided for @selectLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguageTitle;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @sinhala.
  ///
  /// In en, this message translates to:
  /// **'Sinhala (සිංහල)'**
  String get sinhala;

  /// No description provided for @tamil.
  ///
  /// In en, this message translates to:
  /// **'Tamil (தமிழ்)'**
  String get tamil;

  /// No description provided for @reportConditionTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Route Condition'**
  String get reportConditionTitle;

  /// No description provided for @selectBusRouteLabel.
  ///
  /// In en, this message translates to:
  /// **'Bus Route'**
  String get selectBusRouteLabel;

  /// No description provided for @selectBusRouteHint.
  ///
  /// In en, this message translates to:
  /// **'Select your route (e.g., 138 Pettah - Homagama)'**
  String get selectBusRouteHint;

  /// No description provided for @errSelectBusRoute.
  ///
  /// In en, this message translates to:
  /// **'Please select a bus route'**
  String get errSelectBusRoute;

  /// No description provided for @targetLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Reporting Location'**
  String get targetLocationLabel;

  /// No description provided for @targetOnBus.
  ///
  /// In en, this message translates to:
  /// **'On the Bus'**
  String get targetOnBus;

  /// No description provided for @targetAtStation.
  ///
  /// In en, this message translates to:
  /// **'At Bus Stop / Station'**
  String get targetAtStation;

  /// No description provided for @crowdingLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Crowding Level'**
  String get crowdingLevelTitle;

  /// No description provided for @crowdingLow.
  ///
  /// In en, this message translates to:
  /// **'Low Crowd'**
  String get crowdingLow;

  /// No description provided for @crowdingLowDesc.
  ///
  /// In en, this message translates to:
  /// **'Plenty of room & wheelchair bay free'**
  String get crowdingLowDesc;

  /// No description provided for @crowdingModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get crowdingModerate;

  /// No description provided for @crowdingModerateDesc.
  ///
  /// In en, this message translates to:
  /// **'Seats full, standing room available'**
  String get crowdingModerateDesc;

  /// No description provided for @crowdingPacked.
  ///
  /// In en, this message translates to:
  /// **'Crowded / Packed'**
  String get crowdingPacked;

  /// No description provided for @crowdingPackedDesc.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair space or aisle blocked'**
  String get crowdingPackedDesc;

  /// No description provided for @additionalNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Additional Notes (Optional)'**
  String get additionalNotesLabel;

  /// No description provided for @additionalNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Describe accessibility barriers, broken ramps, etc.'**
  String get additionalNotesHint;

  /// No description provided for @errNoteTooShort.
  ///
  /// In en, this message translates to:
  /// **'Please enter at least 10 characters'**
  String get errNoteTooShort;

  /// No description provided for @submitReportBtn.
  ///
  /// In en, this message translates to:
  /// **'Submit Report (+10 Points)'**
  String get submitReportBtn;

  /// No description provided for @confirmSubmitTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit Accessibility Report?'**
  String get confirmSubmitTitle;

  /// No description provided for @confirmSubmitContent.
  ///
  /// In en, this message translates to:
  /// **'Your report helps passengers with visual or mobility impairments navigate Sri Lankan public transit safely.'**
  String get confirmSubmitContent;

  /// No description provided for @cancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelBtn;

  /// No description provided for @confirmBtn.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Send'**
  String get confirmBtn;

  /// No description provided for @successReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Report submitted successfully.'**
  String get successReportSubmitted;

  /// Notification message when community points are awarded
  ///
  /// In en, this message translates to:
  /// **'You earned {points} Community Points!'**
  String rewardPointsMessage(int points);

  /// No description provided for @communityScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Community Updates'**
  String get communityScreenTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navJourney.
  ///
  /// In en, this message translates to:
  /// **'Journey'**
  String get navJourney;

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;
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
