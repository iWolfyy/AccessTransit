// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AccessTransit';

  @override
  String get selectLanguageTitle => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get sinhala => 'Sinhala (සිංහල)';

  @override
  String get tamil => 'Tamil (தமிழ்)';

  @override
  String get reportConditionTitle => 'Report Route Condition';

  @override
  String get selectBusRouteLabel => 'Bus Route';

  @override
  String get selectBusRouteHint =>
      'Select your route (e.g., 138 Pettah - Homagama)';

  @override
  String get errSelectBusRoute => 'Please select a bus route';

  @override
  String get targetLocationLabel => 'Reporting Location';

  @override
  String get targetOnBus => 'On the Bus';

  @override
  String get targetAtStation => 'At Bus Stop / Station';

  @override
  String get crowdingLevelTitle => 'Crowding Level';

  @override
  String get crowdingLow => 'Low Crowd';

  @override
  String get crowdingLowDesc => 'Plenty of room & wheelchair bay free';

  @override
  String get crowdingModerate => 'Moderate';

  @override
  String get crowdingModerateDesc => 'Seats full, standing room available';

  @override
  String get crowdingPacked => 'Crowded / Packed';

  @override
  String get crowdingPackedDesc => 'Wheelchair space or aisle blocked';

  @override
  String get additionalNotesLabel => 'Additional Notes (Optional)';

  @override
  String get additionalNotesHint =>
      'Describe accessibility barriers, broken ramps, etc.';

  @override
  String get errNoteTooShort => 'Please enter at least 10 characters';

  @override
  String get submitReportBtn => 'Submit Report (+10 Points)';

  @override
  String get confirmSubmitTitle => 'Submit Accessibility Report?';

  @override
  String get confirmSubmitContent =>
      'Your report helps passengers with visual or mobility impairments navigate Sri Lankan public transit safely.';

  @override
  String get cancelBtn => 'Cancel';

  @override
  String get confirmBtn => 'Confirm & Send';

  @override
  String get successReportSubmitted =>
      'Thank you! Report submitted successfully.';

  @override
  String rewardPointsMessage(int points) {
    return 'You earned $points Community Points!';
  }

  @override
  String get communityScreenTitle => 'Community Updates';

  @override
  String get navHome => 'Home';

  @override
  String get navJourney => 'Journey';

  @override
  String get navCommunity => 'Community';

  @override
  String get navProfile => 'Profile';
}
