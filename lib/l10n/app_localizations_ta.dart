// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'AccessTransit';

  @override
  String get selectLanguageTitle => 'மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get english => 'English';

  @override
  String get sinhala => 'සිංහල';

  @override
  String get tamil => 'தமிழ்';

  @override
  String get reportConditionTitle => 'பயண வழியின் நிலையை அறிவிக்கவும்';

  @override
  String get selectBusRouteLabel => 'பேருந்து பாதை';

  @override
  String get selectBusRouteHint =>
      'பேருந்து பாதையைத் தேர்ந்தெடுக்கவும் (எ.கா. 138 பிட்டகோட்டை - ஹோமாகம)';

  @override
  String get errSelectBusRoute =>
      'தயவுசெய்து ஒரு பேருந்து பாதையைத் தேர்ந்தெடுக்கவும்';

  @override
  String get targetLocationLabel => 'அறிவிக்கும் இடம்';

  @override
  String get targetOnBus => 'பேருந்திற்குள்';

  @override
  String get targetAtStation => 'பேருந்து நிறுத்தத்தில்';

  @override
  String get crowdingLevelTitle => 'கூட்ட நெரிசல் நிலை';

  @override
  String get crowdingLow => 'குறைந்த கூட்டம்';

  @override
  String get crowdingLowDesc =>
      'போதுமான இடம் மற்றும் சக்கர நாற்காலி இடம் காலியாக உள்ளது';

  @override
  String get crowdingModerate => 'மிதமான கூட்டம்';

  @override
  String get crowdingModerateDesc => 'ஆசனங்கள் நிரம்பியுள்ளன, நின்று செல்லலாம்';

  @override
  String get crowdingPacked => 'அதிக கூட்டம்';

  @override
  String get crowdingPackedDesc =>
      'சக்கர நாற்காலி இடம் அல்லது பாதை அடைக்கப்பட்டுள்ளது';

  @override
  String get additionalNotesLabel => 'கூடுதல் குறிப்புகள் (விருப்பத்தேர்வு)';

  @override
  String get additionalNotesHint =>
      'அணுகல் தடைகள், உடைந்த சரிவுகளை விவரிக்கவும்';

  @override
  String get errNoteTooShort =>
      'தயவுசெய்து குறைந்தது 10 எழுத்துக்களை உள்ளிடவும்';

  @override
  String get submitReportBtn => 'அறிக்கையைச் சமர்ப்பிக்கவும் (+10 புள்ளிகள்)';

  @override
  String get confirmSubmitTitle => 'அறிக்கையைச் சமர்ப்பிக்கவா?';

  @override
  String get confirmSubmitContent =>
      'உங்கள் அறிக்கை மாற்றுத்திறனாளி பயணிகள் பாதுகாப்பாகப் பயணிக்க உதவுகிறது.';

  @override
  String get cancelBtn => 'ரத்து செய்';

  @override
  String get confirmBtn => 'உறுதிப்படுத்தி அனுப்பு';

  @override
  String get successReportSubmitted =>
      'நன்றி! உங்கள் அறிக்கை வெற்றிகரமாகச் சமர்ப்பிக்கப்பட்டது.';

  @override
  String rewardPointsMessage(int points) {
    return 'நீங்கள் $points சமூகப் புள்ளிகளைப் பெற்றுள்ளீர்கள்!';
  }

  @override
  String get communityScreenTitle => 'சமூக செய்திகள்';

  @override
  String get navHome => 'முகப்பு';

  @override
  String get navJourney => 'பயணம்';

  @override
  String get navCommunity => 'சமூகம்';

  @override
  String get navProfile => 'சுயவிவரம்';
}
