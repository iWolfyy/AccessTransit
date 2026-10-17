// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Sinhala Sinhalese (`si`).
class AppLocalizationsSi extends AppLocalizations {
  AppLocalizationsSi([String locale = 'si']) : super(locale);

  @override
  String get busDetails => 'බස් රථ විස්තර';

  @override
  String get communityReports => 'ප්‍රජා වාර්තා';

  @override
  String get saveTrip => 'ගමන සුරකින්න';

  @override
  String get removeSavedTrip => 'සුරැකි ගමන ඉවත් කරන්න';

  @override
  String get savedTrip => 'සුරැකි ගමන';

  @override
  String get noRecentReports => 'මෑත වාර්තා නැත';

  @override
  String get loadingReports => 'වාර්තා පූරණය වෙමින්…';

  @override
  String get requestBoardingAssistance => 'ගොඩවීමේ සහාය ඉල්ලන්න';

  @override
  String get reportCondition => 'තත්ත්වය වාර්තා කරන්න';

  @override
  String get language => 'භාෂාව';

  @override
  String get languageSaveFailed =>
      'භාෂාව සුරැකීමට නොහැකි විය. නැවත උත්සාහ කරන්න.';

  @override
  String get searchWindowInvalid =>
      'ඉදිරි පැය 24 තුළ බස් රථයට ගොඩවන වේලාවක් තෝරන්න.';

  @override
  String get searchSelectionExpired =>
      'මෙම තේරීම කල් ඉකුත් වී ඇත. වත්මන් ප්‍රතිඵල නැවත බලන්න.';

  @override
  String get searchAccountChanged =>
      'ගිණුම වෙනස් වී ඇත. නව සෙවීමක් සඳහා සෙවුම් පිටුවට ආපසු යන්න.';

  @override
  String get searchWindowNotice =>
      'ඉදිරි පැය 24 තුළ ගොඩවිය හැකි සේවා. කාලසටහනෙන් බස් රථය ධාවනය වන බව තහවුරු නොවේ.';

  @override
  String get welcomeBack => 'නැවත සාදරයෙන් පිළිගනිමු';

  @override
  String get signIn => 'පිවිසෙන්න';

  @override
  String get email => 'ඊමේල් ලිපිනය';

  @override
  String get emailHint => 'ඔබගේ ඊමේල් ලිපිනය ඇතුළත් කරන්න';

  @override
  String get passenger => 'මගියා';

  @override
  String get passengerDescription => 'ප්‍රවේශ පහසුකම් සහිත ගමන් සැලසුම් කරන්න';

  @override
  String get reporter => 'වාර්තාකරු';

  @override
  String get reporterDescription => 'බස් සහ නැවතුම්පොළ තත්ත්වයන් වාර්තා කරන්න';

  @override
  String get driver => 'බස් රියදුරු';

  @override
  String get driverDescription => 'පරිපාලක අනුමැතිය අවශ්‍යයි';

  @override
  String get operatorApprovalRequired =>
      'ගිණුම සාදන ලදී. රියදුරු ප්‍රවේශය සඳහා පරිපාලක අනුමැතිය අවශ්‍යයි.';

  @override
  String accountReady(String name) {
    return 'ආයුබෝවන් $name! ඔබගේ ගිණුම සූදානම්.';
  }

  @override
  String get verifyingSearchTime => 'සෙවුම් වේලාව තහවුරු කරමින්…';

  @override
  String get searchTimeUnavailable =>
      'සෙවුම් වේලාව ලබාගත නොහැක. සම්බන්ධ වී නැවත උත්සාහ කරන්න.';

  @override
  String get retrySearchTime => 'වේලාව නැවත තහවුරු කරන්න';

  @override
  String get retrySearch => 'නැවත සොයන්න';

  @override
  String get verifyingDatedSearch =>
      'සෙවුම් වේලාව සහ දින නියමිත ගමන් තහවුරු කරමින්…';

  @override
  String get datedSearchUnavailable =>
      'දින නියමිත ගමන් ලබාගත නොහැක. සම්බන්ධ වී නැවත උත්සාහ කරන්න.';

  @override
  String get nearbyStopsTitle => 'ළඟ ඇති නැගීමේ නැවතුම්';

  @override
  String get nearbyStopsExplanation =>
      'නැගීමට අවශ්‍ය නැවතුම තෝරන්න. දුර ආසන්න සරල රේඛීය දුරකි; ඇවිදින මාර්ගය හෝ ගමන් කාලය නොවේ. නැවතුමේ දිශාව සහ පාරේ පැත්ත බලන්න.';

  @override
  String get nearbyLocating => 'ඔබගේ පිහිටීම සොයමින්...';

  @override
  String get nearbyLocationDisabled =>
      'උපාංගයේ Location සක්‍රිය කර නැවත උත්සාහ කරන්න.';

  @override
  String get nearbyLocationDenied =>
      'පිහිටීම ලබාගැනීමට අවසර නොලැබුණි. නැවතුමක් අතින් තෝරාගත හැක.';

  @override
  String get nearbyLocationBlocked =>
      'App settings තුළ Location අවසර ලබාදී නැවත උත්සාහ කරන්න.';

  @override
  String get nearbyLocationUnavailable =>
      'භාවිත කළ හැකි පිහිටීමක් නොලැබුණි. නැවත උත්සාහ කරන්න හෝ නැවතුමක් අතින් තෝරන්න.';

  @override
  String get nearbyOpenSettings => 'Settings විවෘත කරන්න';

  @override
  String get nearbyRetry => 'පිහිටීම නැවත සොයන්න';

  @override
  String get nearbyChooseManually => 'නැවතුමක් අතින් තෝරන්න';

  @override
  String get nearbyStopsEmpty => 'නිවැරදි ඛණ්ඩාංක සහිත නැවතුම් නොමැත.';

  @override
  String nearbyDistance(String km) {
    return 'කි.මී. $km පමණ දුරින්';
  }

  @override
  String get reportCooldownNotice =>
      'දිනකට වාර්තා සීමාවක් නැත. එකම බස් රථයේ හෝ නැවතුමේ එකම ගැටලු කාණ්ඩය නැවත වාර්තා කිරීමට විනාඩි 5ක් රැඳී සිටින්න.';

  @override
  String get falseVoteReason => 'මෙම වාර්තාව වැරදි ඇයි?';

  @override
  String get falseVoteReasonMinimum => 'අවම වශයෙන් අක්ෂර 5ක් ඇතුළත් කරන්න.';

  @override
  String get voteCancel => 'අවලංගු කරන්න';

  @override
  String get voteSubmit => 'මතය යවන්න';

  @override
  String get voteAcknowledged => 'ඔබගේ මතය සටහන් විය.';

  @override
  String get voteUnavailable =>
      'මතය තහවුරු නොවීය. සම්බන්ධතාව පරීක්ෂා කර නැවත උත්සාහ කරන්න.';

  @override
  String get voteSignIn => 'මතයක් දැක්වීමට පිවිසෙන්න.';

  @override
  String get authorVoteDisabled => 'ඔබගේ වාර්තාවට ඔබටම මතයක් දැක්විය නොහැක.';

  @override
  String get voteRetry => 'මතයේ තත්ත්වය නැවත බලන්න';

  @override
  String get votingClosed => 'මත දැක්වීම අවසන්ය.';

  @override
  String get voteNoPoints =>
      'මත දැක්වීමට ලකුණු නොලැබේ. වැරදියි මත 5කින් වාර්තාව සඟවයි.';

  @override
  String get voteTrue => 'නිවැරදියි';

  @override
  String get voteFalse => 'වැරදියි';

  @override
  String get accountStatusChecking => 'ගිණුම් ප්‍රවේශය පරීක්ෂා කරමින්...';

  @override
  String get accountStatusUnavailable =>
      'ගිණුම් ප්‍රවේශය තහවුරු කළ නොහැක. සම්බන්ධ වී නැවත උත්සාහ කරන්න.';

  @override
  String get accountSuspended =>
      'ගිණුම අත්හිටුවා ඇත. පරිපාලක සමාලෝචනය අවශ්‍යයි.';

  @override
  String accountTemporaryUntil(String until) {
    return 'ගිණුම $until (UTC) දක්වා තාවකාලිකව අත්හිටුවා ඇත.';
  }

  @override
  String get accountStatusRetry => 'ගිණුම් තත්ත්වය නැවත බලන්න';

  @override
  String get accountSignOut => 'ඉවත් වන්න';

  @override
  String get v2PointsNotice =>
      'ප්‍රකාශිත වාර්තාවකට ලකුණු 10යි; මත සඳහා ලකුණු නැත. වැරදියි මත 5කදී ලැබුණු ලකුණු මෙන් දෙගුණයක් අඩු වේ. ලකුණුවලට මුදල් වටිනාකමක් නැත.';

  @override
  String get refreshV2Points => 'v2 ලකුණු නැවත බලන්න';

  @override
  String get reviewsTitle => 'මගේ වාර්තා සමාලෝචන';

  @override
  String get reviewsAdminTitle => 'වාර්තා සමාලෝචනය';

  @override
  String get reviewsError =>
      'සමාලෝචන තහවුරු කළ නොහැක. සම්බන්ධතාව පරීක්ෂා කර නැවත උත්සාහ කරන්න.';

  @override
  String get reviewsReasonRequired =>
      'අක්ෂර 5ත් 2,000ත් අතර හේතුවක් ඇතුළත් කරන්න.';

  @override
  String get reviewsPending => 'අභියාචනය සමාලෝචනයට යොමු කර ඇත';

  @override
  String get reviewsUpheld => 'තීරණය තහවුරු කර ඇත';

  @override
  String get reviewsOverturned => 'තීරණය අවලංගු කර අඩු කළ ලකුණු ආපසු ලබා දී ඇත';

  @override
  String get reviewsUnreviewed => 'සමාලෝචනය බලාපොරොත්තුවෙන්';

  @override
  String get reviewsEmpty => 'ප්‍රජාව විසින් විවාදිත වාර්තා නැත.';

  @override
  String get reviewsMore => 'තවත් පෙන්වන්න';

  @override
  String reviewsPenalty(int points, int strikes) {
    return 'අඩු කළ ලකුණු: $points. ගණන් කළ වැරදි වාර්තා: $strikes.';
  }

  @override
  String reviewsHiddenReason(int count) {
    return 'වෙනත් පරිශීලකයන් $count දෙනෙකු මෙම වාර්තාව වැරදි ලෙස සලකුණු කළ නිසා එය ස්වයංක්‍රීයව සඟවා ඇත.';
  }

  @override
  String get reviewsAppealLabel => 'ඔබගේ අභියාචනය';

  @override
  String get reviewsDecisionReason => 'පරිපාලක තීරණයට හේතුව';

  @override
  String get reviewsVotes => 'ප්‍රජා ඡන්ද සාක්ෂි';

  @override
  String get reviewsReason => 'හේතුව';

  @override
  String get reviewsDecisionExplanation =>
      'තීරණය අවලංගු කළ විට අඩු කළ ලකුණු සහ මෙම වැරදි වාර්තා ගණනය එක් වරක් ආපසු සකස් වේ. වෙනත් ගිණුම් සීමා පවතී.';

  @override
  String get reviewsUphold => 'තීරණය තහවුරු කරන්න';

  @override
  String get reviewsOverturn => 'තීරණය අවලංගු කරන්න';

  @override
  String get reviewsSubmit => 'අභියාචනය යවන්න';

  @override
  String get reviewsAcknowledged => 'වෙනස සේවාදායකය තහවුරු කළා.';

  @override
  String get reviewsPhoto => 'වාර්තා ඡායාරූපය';

  @override
  String get reviewsPhotoUnavailable => 'වාර්තා ඡායාරූපය ලබාගත නොහැක.';

  @override
  String get bansTitle => 'ස්ථිර තහනම් සමාලෝචන';

  @override
  String get bansApproved => 'ස්ථිර තහනම අනුමත කර ඇත';

  @override
  String get bansRejected => 'ස්ථිර තහනම ප්‍රතික්ෂේප කර ඇත';

  @override
  String get bansWithdrawn => 'සමාලෝචනය ඉවත් කර ඇත';

  @override
  String get bansPending => 'පරිපාලක සමාලෝචනය බලාපොරොත්තුවෙන්';

  @override
  String get bansEmpty => 'ස්ථිර තහනම් සමාලෝචන නැත.';

  @override
  String bansStrikes(int count) {
    return 'දැනට ගණන් වන වැරදි වාර්තා: $count';
  }

  @override
  String get bansAppealsPending =>
      'ස්ථිර තහනම අනුමත කිරීමට පෙර ඉතිරි වාර්තා අභියාචන විසඳන්න.';

  @override
  String get bansStale =>
      'සාක්ෂි වෙනස් වී ඇත. තීරණයට පෙර සමාලෝචනය නැවත ලබාගන්න.';

  @override
  String get bansAdminProtected =>
      'මෙම ක්‍රියාවලියෙන් පරිපාලක ගිණුම් තහනම් කළ නොහැක.';

  @override
  String get bansEvidence => 'අදාළ වාර්තා සහ අභියාචන';

  @override
  String get bansCounted => 'වැරදි වාර්තාව ගණන් වේ';

  @override
  String get bansRemoved => 'වැරදි වාර්තා ගණනය ඉවත් කර ඇත';

  @override
  String get bansExplanation =>
      'වැරදි වාර්තා දහයකින් සමාලෝචනයක් විවෘත වේ. ස්ථිර තහනමක් පැනවෙන්නේ පැහැදිලි අනුමැතියෙන් පමණි. ප්‍රතික්ෂේප කිරීමෙන් තාවකාලික තහනම දිගු නොවේ.';

  @override
  String get bansReject => 'ස්ථිර තහනම ප්‍රතික්ෂේප කරන්න';

  @override
  String get bansApprove => 'ස්ථිර තහනම අනුමත කරන්න';

  @override
  String get assistanceInbox => 'මෙම ගමනේ සහාය ඉල්ලීම්';

  @override
  String get assistanceChooseRun =>
      'Bus Details වෙතින් රියදුරෙකු පවරා ඇති දින සහිත ගමනක් තෝරන්න.';

  @override
  String get assistanceUnavailable =>
      'සහාය ලබාගත නොහැක. ගමන, රියදුරු පැවරුම සහ සම්බන්ධතාව පරීක්ෂා කර නැවත උත්සාහ කරන්න.';

  @override
  String get assistanceEmpty => 'මෙම ගමනට සහාය ඉල්ලීම් නැත.';

  @override
  String get assistanceRetargeted =>
      'රියදුරු වෙනස් වී ඇත. නව රියදුරුගේ පිළිගැනීම බලාපොරොත්තුවෙන්.';

  @override
  String get assistancePending => 'රියදුරුගේ පිළිගැනීම බලාපොරොත්තුවෙන්';

  @override
  String get assistanceAccepted => 'රියදුරු පිළිගෙන ඇත';

  @override
  String get assistanceDeclined => 'රියදුරු ප්‍රතික්ෂේප කළා';

  @override
  String get assistanceCompleted => 'රියදුරු සහාය අවසන් බව සලකුණු කළා';

  @override
  String get assistanceCancelled => 'අවලංගු කර ඇත';

  @override
  String get assistanceExpired => 'ඉල්ලීම කල් ඉකුත් වී ඇත';

  @override
  String get assistanceAcknowledge => 'පිළිගන්න';

  @override
  String get assistanceDecline => 'ප්‍රතික්ෂේප කරන්න';

  @override
  String get assistanceComplete => 'අවසන් කරන්න';

  @override
  String get assistanceInAppOnly =>
      'යෙදුමේ ඉල්ලීම් ලැයිස්තුවට යවා ඇත. Local පරීක්ෂණයේ background push දැනුම්දීම් සක්‍රීය නැත.';

  @override
  String assistanceExpiry(String time) {
    return 'ඉල්ලීම කල් ඉකුත් වන වේලාව (UTC): $time';
  }

  @override
  String get assistanceRunEnded => 'මෙම ගමන අවසන් වී හෝ අවලංගු කර ඇත.';

  @override
  String get assistanceStopPassed => 'බසය ඉල්ලා සිටි නැගීමේ අවස්ථාව පසු කර ඇත.';

  @override
  String get assistanceDriverUnavailable =>
      'පවරා ඇති රියදුරු දැන් ලබාගත නොහැක.';

  @override
  String get assistanceRamp => 'බෑවුම යොදන්න';

  @override
  String get assistanceExtraTime => 'අමතර කාලය';

  @override
  String get assistanceBoardingHelp => 'බසයට නැගීමට සහාය';

  @override
  String get assistanceAlightingHelp => 'බසයෙන් බැසීමට සහාය';

  @override
  String get operationsTitle => 'ක්‍රියාත්මක ගමන්';

  @override
  String get operationsRefresh => 'සේවාදායකයෙන් යාවත්කාලීන කරන්න';

  @override
  String get operationsEmpty => 'ක්‍රියාත්මක දින නියමිත ගමන් නැත.';

  @override
  String get operationsMore => 'තවත් පෙන්වන්න';

  @override
  String get operationsExplanation =>
      'එම මාර්ගයට අනුමත වෙනත් රියදුරෙකුට ගමන පවරන්න. ගමන් ප්‍රගතිය හා සටහන් කළ වෙලාවන් රැඳේ. නව රියදුරු අලුත් ස්ථාන දත්ත සමඟ භාරගන්නා තෙක් GPS නවතී. සහාය ඉල්ලීම් නව රියදුරු නැවත පිළිගත යුතුය.';

  @override
  String get operationsDone =>
      'පැවරීම තහවුරු විය. නව රියදුරු භාරගන්නා තෙක් GPS නවතා ඇත. සහාය ඉල්ලීම් පසුබිමේ නැවත යොමු වේ; කලින් පිළිගැනීම බල නොපැවැත්වේ.';

  @override
  String get operationsNoDrivers =>
      'මෙම පිටුවේ සුදුසු රියදුරෙකු නැත. පළමුව ලබාගත හැකි රියදුරෙකු අනුමත කර මෙම මාර්ගයට පවරන්න.';

  @override
  String get operationsReason => 'පැවරීමේ හේතුව (අක්ෂර 5–2000)';

  @override
  String get operationsTransfer => 'ගමන පවරන්න';

  @override
  String get operationsSaving => 'පවරමින්…';

  @override
  String get operationsError =>
      'මෙම ක්‍රියාව තහවුරු කළ නොහැක. එම ඉල්ලීම නැවත උත්සාහ කරන්න හෝ වත්මන් තත්ත්වය යාවත්කාලීන කර බලන්න.';

  @override
  String get operationsStale =>
      'ගමන හෝ රියදුරුගේ සුදුසුකම වෙනස් වී ඇත. පැවරීමට පෙර යාවත්කාලීන කරන්න.';

  @override
  String get operationsResume => 'භාරගෙන GPS අරඹන්න';

  @override
  String get operationsGpsError =>
      'මීටර් 100ක් ඇතුළත නිරවද්‍යතාවක් ඇති අලුත් GPS ස්ථානයක් ලැබෙන තෙක් රැඳී සිට නැවත භාරගන්න.';

  @override
  String get pushTitle => 'සහාය ඉල්ලීම් දැනුම්දීම්';

  @override
  String get pushChannelDescription => 'මගී සහාය ඉල්ලීම් පිළිබඳ දැනුම්දීම්';

  @override
  String get pushOff =>
      'දැනුම්දීම් අක්‍රියයි. රියදුරුගේ ඉල්ලීම් ලැයිස්තුව භාවිත කළ හැකියි.';

  @override
  String get pushConnecting => 'දැනුම්දීම් සම්බන්ධ කරමින්…';

  @override
  String get pushDenied =>
      'දැනුම්දීම් අවසරය ලබා දී නැත. Android යෙදුම් සැකසුම් වලින් අවසර ලබා දිය හැකියි.';

  @override
  String get pushReady =>
      'මෙම උපාංගය ලියාපදිංචියි. දැනුම්දීමක් ලැබීම සහාය ඉල්ලීම පිළිගත් බවක් නොවේ.';

  @override
  String get pushUnavailable =>
      'දැනුම්දීම් සැකසුම තහවුරු කළ නොහැක. නැවත උත්සාහ කරන්න හෝ ඉල්ලීම් ලැයිස්තුව භාවිත කරන්න.';

  @override
  String get pushEnable => 'දැනුම්දීම් සක්‍රිය කරන්න';

  @override
  String get pushDisable => 'අක්‍රිය කරන්න';

  @override
  String get pushOpenUnavailable =>
      'මෙම ඉල්ලීම ලබාගත නොහැක හෝ තවදුරටත් ඔබට පවරා නැත.';

  @override
  String get pushForeground => 'මගියෙකු සහාය ඉල්ලා ඇත.';

  @override
  String get pushReview => 'ඉල්ලීම බලන්න';

  @override
  String get fareUnavailable => 'ගාස්තුව ලබාගත නොහැක';

  @override
  String get fareUnavailableDisclosure =>
      'මෙම ගමන සඳහා සමාලෝචිත ගාස්තු වගුවක් හා ගාස්තු අදියර සම්බන්ධතාවක් නැත. රියදුරු හෝ කොන්දොස්තර සමඟ ගාස්තුව තහවුරු කරන්න.';

  @override
  String get fareSampleDisclosure =>
      'Sample/Test අනුමානයක් පමණි. ගමන් කාලය හා නැවතුම් මත ඇති මෙම ගණනය නිල ගාස්තුවක් නොවේ. සැබෑ ගාස්තුව කොන්දොස්තර සමඟ තහවුරු කරන්න.';

  @override
  String fareSampleAmount(int amount) {
    return 'Sample අනුමාන ගාස්තුව LKR $amount';
  }

  @override
  String fareReviewedSource(String source, String tariff, String mapping) {
    return 'සමාලෝචිත මූලාශ්‍රය: $source. ගාස්තු වගුව $tariff; සම්බන්ධතාව $mapping.';
  }

  @override
  String fareReviewedAmount(String amount) {
    return 'LKR $amount';
  }

  @override
  String fareSampleReviewed(String amount) {
    return 'Sample ගාස්තුව LKR $amount';
  }

  @override
  String get fareChanged =>
      'ගාස්තු අනුවාදය වෙනස් වී ඇත හෝ ලබාගත නොහැක. සුරැකි තේරීම පවතී; ගමනට පෙර වත්මන් ගාස්තුව පරීක්ෂා කරන්න.';

  @override
  String get fareAdminTitle => 'ගාස්තු ප්‍රකාශන';

  @override
  String get fareImportHelp =>
      'සමාලෝචිත ගාස්තු වගුව, පිළිවෙළට ඇති නැවතුම්-අදියර සම්බන්ධතාව හා bus IDs ඇතුළත් කරන්න. LKR 1 = සුළු ඒකක 100කි. ප්‍රකාශ කිරීමට පෙර අගයන්, මූලාශ්‍රය, පන්තිය හා දින පරීක්ෂා කරන්න. ප්‍රකාශිත අනුවාද වෙනස් කළ නොහැක; archive කර අලුත් ID එකක් සාදන්න.';

  @override
  String get farePublicationId => 'නව ප්‍රකාශන ID';

  @override
  String get fareImportJson => 'සමාලෝචිත import JSON';

  @override
  String get farePreview => 'පරීක්ෂා කර පෙරදසුන බලන්න';

  @override
  String get fareReviewCheck =>
      'මූලාශ්‍රය, වාහන පන්තිය, දිශාව, නැවතුම්-අදියර සම්බන්ධතාව හා දින පරීක්ෂා කළෙමි.';

  @override
  String get fareReviewReason => 'සමාලෝචන/archive හේතුව (අක්ෂර 10–2000)';

  @override
  String get farePublish => 'සමාලෝචිත අනුවාදය ප්‍රකාශ කරන්න';

  @override
  String get fareArchive => 'අනුවාදය archive කරන්න';

  @override
  String get fareCancel => 'අවලංගු කරන්න';

  @override
  String get fareInvalidImport =>
      'ඇතුළත් දත්ත වලංගු නැත. ලේඛනගත ආකෘතිය, IDs, පූර්ණ සංඛ්‍යා අගයන්, මූලාශ්‍රය හා දින/සම්බන්ධතා පරීක්ෂා කරන්න.';

  @override
  String get fareAdminError =>
      'ක්‍රියාව තහවුරු කළ නොහැක. සම්බන්ධතාව, admin අවසරය, හේතුව හා වත්මන් bus/route දත්ත පරීක්ෂා කරන්න. වෙනස් වූ ප්‍රකාශනයක් නැවත load කරන්න.';

  @override
  String get fareNoPublications =>
      'ගාස්තු ප්‍රකාශන නැත. නොමැති ගාස්තු ලබාගත නොහැකි ලෙස පෙන්වයි.';

  @override
  String get geometryTitle => 'මාර්ගයේ භූගෝලීය දත්ත';

  @override
  String get geometryHelp =>
      'සමාලෝචිත මාර්ග හැඩය සහ පිළිවෙළින් නැවතුම් ලක්ෂ්‍ය ඇතුළත් කරන්න. වත්මන් මාර්ගය හා නැවතුම් ඛණ්ඩාංක ගැළපිය යුතුයි. නිවැරදි කිරීම් සඳහා නව අනුවාදයක් භාවිත කරන්න. මෙය සජීවී රථවාහන දත්ත ලබා නොදෙයි.';

  @override
  String get geometryReview =>
      'මාර්ග හැඩය, දිශාව, නැවතුම් ලක්ෂ්‍ය හා මූලාශ්‍රය සමාලෝචනය කළෙමි.';

  @override
  String get geometryInvalid =>
      'දත්ත වලංගු නැත. JSON, route ID, ඛණ්ඩාංක, මූලාශ්‍රය හා නැවතුම් පිළිවෙළ පරීක්ෂා කරන්න.';

  @override
  String get geometrySaved => 'සමාලෝචිත මාර්ග දත්ත ප්‍රකාශයට පත් කළා.';

  @override
  String get geometryWithdraw => 'වත්මන් මාර්ග දත්ත ඉවත් කරන්න';

  @override
  String get geometryMap => 'සමාලෝචිත මාර්ග හැඩය · තෝරාගත් කොටස';

  @override
  String geometryEta(String target, String start, String end) {
    return '$target: ඇස්තමේන්තුව $start–$end · මාර්ග ප්‍රගතිය සහ කාලසටහන අනුව; අඩු විශ්වාසයක් සහිතයි.';
  }

  @override
  String get geometryWithdrawn => 'මාර්ග දත්ත ඉවත් කළා.';

  @override
  String get etaDiagnostics => 'Local ETA පරීක්ෂණ';

  @override
  String get etaDiagnosticsUnavailable =>
      'Local Test පරීක්ෂණ සඳහා පිවිසි ගිණුම load විය යුතුයි.';

  @override
  String get etaDiagnosticsHelp =>
      'LOCAL TEST ONLY. Bus Details විවෘතව ඇති විට ඇස්තමේන්තු සටහන් කිරීමට සක්‍රීය කරන්න. පැමිණීම් driver තහවුරු කළ timestamps වන අතර ස්වාධීන GPS මිනුම් නොවේ. සැබෑ accuracy claim එකක් නැත. දත්ත මේ device/account එකේ පමණයි (උපරිම 500; capture කිරීමේදී දින 7ක සීමාව යෙදේ). ඛණ්ඩාංක, emails හෝ driver IDs සුරැකෙන්නේ නැත.';

  @override
  String get etaCapture => 'Local ඇස්තමේන්තු සටහන් කරන්න';

  @override
  String etaCounts(int captured, int pending, int excluded) {
    return 'සටහන්: $captured · බලාපොරොත්තු: $pending · ඉවත් කළ: $excluded';
  }

  @override
  String etaMetrics(int count, String median, String p90) {
    return 'ගැළපුණු samples: $count · මධ්‍යස්ථ දෝෂය: ${median}s · P90 දෝෂය: ${p90}s';
  }

  @override
  String get etaStorageError =>
      'Local දත්ත save/read තහවුරු නැත. Export එකේ save නොවූ records තිබිය හැක; නැවත උත්සාහ කරන්න.';

  @override
  String get etaNoMatchedSamples =>
      'තවම ගැළපුණු පැමිණීම් නැත. Pending/excluded forecasts දෝෂය බිංදුව ලෙස ගණන් නොගනී.';

  @override
  String get etaSmallSample =>
      'කුඩා synthetic sample එකක්; මෙයින් සැබෑ accuracy තහවුරු නොවේ.';

  @override
  String get etaCopied => 'Local diagnostic JSON copy කළා.';

  @override
  String get etaExport => 'Diagnostic JSON copy කරන්න';

  @override
  String get etaClear => 'මෙම ගිණුමේ local මිනුම් මකන්න';

  @override
  String get savedTripsTitle => 'සුරැකි ගමන්';

  @override
  String get savedTripsViewAll => 'සුරැකි සියලු ගමන් බලන්න';

  @override
  String get savedTripsHelp =>
      'පසුගිය records ඇතුළු ඔබේ සුරැකි තේරීම්. Save කිරීම seat booking හෝ tracking ආරම්භ කිරීමක් නොවේ. තෝරාගත් ගමනේ වත්මන් තත්ත්වය බැලීමට විස්තර විවෘත කරන්න.';

  @override
  String get savedTripsRefresh => 'සුරැකි ගමන් නැවත ලබාගන්න';

  @override
  String get savedTripsAccountChanged =>
      'ගිණුම වෙනස් වී ඇත. Home වෙත ගොස් සුරැකි ගමන් නැවත විවෘත කරන්න.';

  @override
  String get savedTripsRemoveError =>
      'ඉවත් කිරීම තහවුරු නැත. සුරැකි record එක තවම ඇත; සම්බන්ධ වී නැවත උත්සාහ කරන්න.';

  @override
  String get savedTripsOpenError =>
      'සුරැකි විස්තර තහවුරු කළ නොහැක. සම්බන්ධ වී නැවත උත්සාහ කරන්න.';

  @override
  String get savedTripsLoadError =>
      'සුරැකි ගමන් ලබාගත නොහැක. සම්බන්ධතාව හා ගිණුමේ අවසර පරීක්ෂා කර නැවත උත්සාහ කරන්න.';

  @override
  String get savedTripsRetry => 'නැවත උත්සාහ කරන්න';

  @override
  String get savedTripsEmpty =>
      'තවම සුරැකි ගමන් නැත. Bus Details වෙතින් ගමනක් සුරකින්න.';

  @override
  String get savedTripsEmptyPage =>
      'මෙම පිටුවේ සුරැකි records නැත. නැවත ලබාගන්න හෝ පෙර පිටුවට යන්න.';

  @override
  String get savedTripsCompletedRecord => 'සම්පූර්ණ කළ සුරැකි record එක';

  @override
  String get savedTripsCancelledRecord => 'අවලංගු කළ සුරැකි record එක';

  @override
  String get savedTripsOpen => 'බස් විස්තර බලන්න';

  @override
  String get savedTripsPrevious => 'පෙර පිටුව';

  @override
  String get savedTripsNext => 'ඊළඟ පිටුව';

  @override
  String get savedTripsVehicleUnavailable =>
      'සුරැකි බස් රථය ලබාගත නොහැක. සුරැකි record එක බලන්න හෝ නැවත search කරන්න.';

  @override
  String get segmentReportsPreview =>
      'සීමිත වාර්තා පෙරදසුනකි; තවත් සාක්ෂි සඳහා අදාළ පිටු විවෘත කරන්න. වාර්තා නොමැති වීමෙන් ප්‍රවේශ පහසුකම් තහවුරු නොවේ.';

  @override
  String get segmentReportsHelp =>
      'මෙම බස් රථය හෝ තෝරාගත් කොටසේ නැවතුමක් තෝරන්න. පිටු නිරීක්ෂණ වේලාවට නොව ස්ථාවර record පිළිවෙළට ඇත. කල් ඉකුත්/සැඟවූ වාර්තා ඉවත් වේ; හිස් පිටුවක් යනු පැරණි අදාළ වාර්තා නැත යන්න නොවේ.';

  @override
  String get segmentReportsUnavailable =>
      'වාර්තා ලබාගත නොහැක. සම්බන්ධ වී නැවත ලබාගන්න.';

  @override
  String get segmentReportsEmptyPage =>
      'මෙම පිටුවේ වත්මන් දෘශ්‍ය වාර්තා නැත. තිබේ නම් ඊළඟ පිටුව බලන්න.';

  @override
  String get segmentReportsEmptyPreview => 'මෙම පෙරදසුනේ වත්මන් වාර්තා නැත.';

  @override
  String get segmentReportsViewAll => 'අදාළ සියලු වාර්තා බලන්න';

  @override
  String get calendarTitle => '???? ??? ??????';

  @override
  String get calendarHelp =>
      '???????? ???? ???, ???? ??????? ????? ?? ????? ??? 31?? ?????? ?????. ?????? ????????? ??????. ????? ???? ????? ????. ??? ?????? ???????? ?????????? ????? ???? ?????? ????.';

  @override
  String get calendarDates => '???? ??? ??????';

  @override
  String get calendarTime => '???? ??????? ????? ??????';

  @override
  String get calendarPublish => '??? ?????? ??????? ?????';

  @override
  String get calendarGenerate => '??? ???? ????????? ??????';

  @override
  String get calendarRetire => '??? ?????? ???????? ???????';

  @override
  String get calendarFailed =>
      '???? ?? ???? ???????? ?????? ?????. ??????? ?? ???? ????? ?????. ??????? ????? ??? ?? ????? ??? 31?? ????? ?????. ????? ?? ????????? ?? ??? ???????? ????????.';

  @override
  String get calendarConfirmed => '??? ????? ???? ?????? ???.';

  @override
  String calendarGenerated(int created, int preserved) {
    return '????????? $created?? ??????; ????? $preserved?? ??????.';
  }

  @override
  String get calendarPublished => '????????? ??? ??????';

  @override
  String get calendarRetired => '???????? ?????? ??? ??????';

  @override
  String get calendarEmpty => '??? ??? ???? ??? ????? ?????.';
}
