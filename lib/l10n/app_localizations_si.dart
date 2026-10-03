// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Sinhala Sinhalese (`si`).
class AppLocalizationsSi extends AppLocalizations {
  AppLocalizationsSi([String locale = 'si']) : super(locale);

  @override
  String get appTitle => 'AccessTransit';

  @override
  String get selectLanguageTitle => 'භාෂාව තෝරන්න';

  @override
  String get english => 'English';

  @override
  String get sinhala => 'සිංහල';

  @override
  String get tamil => 'தமிழ்';

  @override
  String get reportConditionTitle => 'ගමන් මාර්ග තත්ත්වය වාර්තා කරන්න';

  @override
  String get selectBusRouteLabel => 'බස් මාර්ගය';

  @override
  String get selectBusRouteHint =>
      'බස් මාර්ගය තෝරන්න (උදා: 138 පිටකොටුව - හෝමාගම)';

  @override
  String get errSelectBusRoute => 'කරුණාකර බස් මාර්ගයක් තෝරන්න';

  @override
  String get targetLocationLabel => 'වාර්තා කරන ස්ථානය';

  @override
  String get targetOnBus => 'බස් රථය තුළ';

  @override
  String get targetAtStation => 'බස් නැවතුම්පොළේදී';

  @override
  String get crowdingLevelTitle => 'සෙනඟ ප්‍රමාණය';

  @override
  String get crowdingLow => 'අඩු සෙනඟ';

  @override
  String get crowdingLowDesc => 'ප්‍රමාණවත් ඉඩකඩ සහ රෝද පුටු ඉඩ නොමිලේ';

  @override
  String get crowdingModerate => 'සාමාන්‍ය සෙනඟ';

  @override
  String get crowdingModerateDesc => 'ආසන පිරී ඇත, සිටගෙන යා හැක';

  @override
  String get crowdingPacked => 'අධික සෙනඟ';

  @override
  String get crowdingPackedDesc => 'රෝද පුටු ඉඩ හෝ තීරුව අවහිර වී ඇත';

  @override
  String get additionalNotesLabel => 'අමතර සටහන් (අත්‍යවශ්‍ය නොවේ)';

  @override
  String get additionalNotesHint =>
      'ප්‍රවේශවීමේ බාධා, කැඩුණු රැම්ප් ආදිය විස්තර කරන්න';

  @override
  String get errNoteTooShort => 'කරුණාකර අවම වශයෙන් අකුරු 10 ක් ඇතුළත් කරන්න';

  @override
  String get submitReportBtn => 'වාර්තාව යොමු කරන්න (+10 ප්‍රසාද ලකුණු)';

  @override
  String get confirmSubmitTitle => 'තත්ත්ව වාර්තාව යොමු කරන්නද?';

  @override
  String get confirmSubmitContent =>
      'ඔබගේ වාර්තාව විශේෂ අවශ්‍යතා සහිත මගීන්ට ශ්‍රී ලංකාවේ පොදු ප්‍රවාහනය ආරක්ෂිතව භාවිතා කිරීමට උපකාරී වේ.';

  @override
  String get cancelBtn => 'අවසාන කරන්න';

  @override
  String get confirmBtn => 'තහවුරු කර යවන්න';

  @override
  String get successReportSubmitted =>
      'ස්තූතියි! ඔබගේ වාර්තාව සාර්ථකව යොමු කෙරිණි.';

  @override
  String rewardPointsMessage(int points) {
    return 'ඔබ ප්‍රජා ප්‍රසාද ලකුණු $points ක් දිනා ගත්තා!';
  }

  @override
  String get communityScreenTitle => 'ප්‍රජා තොරතුරු';

  @override
  String get navHome => 'මුල් පිටුව';

  @override
  String get navJourney => 'ගමන';

  @override
  String get navCommunity => 'ප්‍රජාව';

  @override
  String get navProfile => 'ගිණුම';
}
