// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Sinhala Sinhalese (`si`).
class AppLocalizationsSi extends AppLocalizations {
  AppLocalizationsSi([String locale = 'si']) : super(locale);

  @override
  String get authControlsTitle => 'Firebase ගිණුම් පාලනය';

  @override
  String get authControlsExplanation =>
      'පිවිසීම සහ සැසි කළමනාකරණය කරන්න. පිවිසීම යළි සක්‍රිය කළත් වෙනම පරිපාලක හා ප්‍රජා සීමා පවතී. වෙනස්කම් සේවාදායකයෙන් තහවුරු විය යුතුයි.';

  @override
  String get authDeleteExplanation =>
      'Firebase පිවිසුම් ගිණුම මකා පෞද්ගලික profile එකේ අනන්‍යතා තොරතුරු ඉවත් කරයි. පොදු වාර්තා, ගමන් සහ විගණන යොමු රැකේ. මුලින් පිවිසීම අක්‍රිය කර ක්‍රියාත්මක ගමන් නිරාකරණය කරන්න. මෙය ආපසු හැරවිය නොහැක.';

  @override
  String get authCancel => 'අවලංගු කරන්න';

  @override
  String get authConfirmRequired =>
      'මකාදැමීම තහවුරු කිරීමට නිවැරදි ගිණුම් UID එක ටයිප් කරන්න.';

  @override
  String get authDisableFirst =>
      'මකාදැමීම අනුමත කිරීමට පෙර පිවිසීම අක්‍රිය කරන්න.';

  @override
  String get authActiveTrip =>
      'මකාදැමීමට පෙර ක්‍රියාත්මක ගමන නිරාකරණය කළ යුතුයි.';

  @override
  String get authPending =>
      'ක්‍රියාව තවම තහවුරු වී නැත හෝ සමාලෝචනය අවශ්‍යයි. ඊළඟ තීරණයට පෙර ප්‍රතිඵලය නැවත ලබාගන්න.';

  @override
  String get authNormalScope =>
      'Firebase Auth පාලන සාමාන්‍ය ගිණුම් පරිසරයට පමණයි.';

  @override
  String get authReload => 'ගිණුම් තත්ත්වය නැවත ලබාගන්න';

  @override
  String get authDeleted => 'ගිණුම මකා ඇත; අවසර ලත් සමාලෝචකයන්ට ඉතිහාසය පවතී.';

  @override
  String get authDisabled => 'Firebase පිවිසීම අක්‍රියයි';

  @override
  String get authEnabled => 'Firebase පිවිසීම සක්‍රියයි';

  @override
  String get authCompleted => 'අවසන් ක්‍රියාව සම්පූර්ණයි';

  @override
  String get authReconcile => 'එම ක්‍රියාව සමාලෝචනය කර නැවත උත්සාහ කරන්න';

  @override
  String get authConfirmLabel => 'මකාදැමීම තහවුරු කරන ගිණුම් UID';

  @override
  String get authEnable => 'පිවිසීම සක්‍රිය කරන්න';

  @override
  String get authDisable => 'පිවිසීම අක්‍රිය කරන්න';

  @override
  String get authRevoke => 'පවතින සැසි අවලංගු කරන්න';

  @override
  String get authDeleteRequest => 'මකාදැමීමේ සමාලෝචනය ඉල්ලන්න';

  @override
  String get authDeleteReject => 'මකාදැමීම ප්‍රතික්ෂේප කරන්න';

  @override
  String get authDeleteApprove => 'ගිණුම මකාදැමීම අනුමත කරන්න';

  @override
  String accountControlsUntil(String when) {
    return '$when දක්වා (Asia/Colombo)';
  }

  @override
  String get accountControlsTitle => 'ගිණුම් ප්‍රවේශය';

  @override
  String get accountControlsExplanation =>
      'මෙම පරිසරයේ යෙදුම් ප්‍රවේශය කළමනාකරණය කරන්න. අතින් දැමූ සීමාව ඉවත් කළත් ප්‍රජා සීමා පවතී. ක්‍රියාත්මක රියදුරු ගමන් සේවාදායකයෙන් සමාලෝචනය කරයි.';

  @override
  String get accountControlsReasonRequired =>
      'අක්ෂර 5 සිට 2,000 දක්වා හේතුවක් ඇතුළත් කරන්න.';

  @override
  String get accountControlsStale =>
      'ගිණුම් ප්‍රවේශය වෙනස් වී ඇත. තීරණයට පෙර නැවත ලබාගන්න.';

  @override
  String get accountControlsProtected =>
      'ඔබගේ ගිණුම සහ පරිපාලක ගිණුම් ආරක්ෂිතයි.';

  @override
  String get accountControlsUnavailable =>
      'ප්‍රවේශය තහවුරු කළ නොහැක. නැවත උත්සාහ කරන්න.';

  @override
  String get accountControlsRestricted => 'පරිපාලක සීමාව ක්‍රියාත්මකයි';

  @override
  String get accountControlsClear => 'ක්‍රියාත්මක පරිපාලක සීමාවක් නැත';

  @override
  String get accountControlsCommunity =>
      'වෙනම ප්‍රජා සීමාවක් තවමත් ක්‍රියාත්මකයි.';

  @override
  String get accountControlsIndefinite => 'පරිපාලක ප්‍රවේශය යළි දෙන තෙක්';

  @override
  String get accountControlsDuration =>
      'එසේ නැත්නම් සේවාදායක වේලාවෙන් පැය 72කට අත්හිටුවයි.';

  @override
  String get accountControlsSuspend => 'ප්‍රවේශය අත්හිටුවන්න';

  @override
  String get accountControlsRestore => 'පරිපාලක සීමාව ඉවත් කරන්න';

  @override
  String get accountControlsRetry => 'නැවත උත්සාහ කරන්න';

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
  String get calendarTitle => 'සේවා දින දර්ශනය';

  @override
  String get calendarHelp =>
      'ධාවන දින, කොළඹ පිටත්වන වේලාව සහ උපරිම දින 31ක් සමාලෝචනය කර ප්‍රකාශ කරන්න. ඉන්පසු පිටත්වීම් සාදන්න. පවතින ගමන් වෙනස් නොවේ. දින දර්ශනය විශ්‍රාම ගැන්වීමෙන් පවතින ගමන් අවලංගු නොවේ.';

  @override
  String get calendarDates => 'සේවා දින තෝරන්න';

  @override
  String get calendarTime => 'කොළඹ පිටත්වන වේලාව තෝරන්න';

  @override
  String get calendarPublish => 'දින දර්ශනය ප්‍රකාශ කරන්න';

  @override
  String get calendarGenerate => 'දින අනුව පිටත්වීම් සාදන්න';

  @override
  String get calendarRetire => 'දින දර්ශනය විශ්‍රාම ගන්වන්න';

  @override
  String get calendarFailed =>
      'වෙනස හෝ දත්ත ලබාගැනීම තහවුරු නොවීය. සම්බන්ධ වී නැවත පූරණය කරන්න. සතියේ දින සහ උපරිම දින 31ක් තෝරන්න. වෙනස් වූ කාලසටහනකට නව දින දර්ශනයක් අවශ්‍යයි.';

  @override
  String get calendarConfirmed => 'දින දර්ශන වෙනස තහවුරු විය.';

  @override
  String calendarGenerated(int created, int preserved) {
    return 'පිටත්වීම් $createdක් සෑදිණි; පවතින $preservedක් රැකිණි.';
  }

  @override
  String get calendarPublished => 'ප්‍රකාශිත දින දර්ශනය';

  @override
  String get calendarRetired => 'විශ්‍රාම ගැන්වූ දින දර්ශනය';

  @override
  String get calendarEmpty => 'මෙම බස් රථයට දින දර්ශන නොමැත.';

  @override
  String get loopStopHelp =>
      'නැවතුම් අනුපිළිවෙළින් එක් කරන්න. එකම නැවතුම නැවත එක් කළ හැකියි. සෑම පැමිණීමකටම වෙනම වේලාවක් සහ අනන්‍යතාවක් ඇත. අනුපිළිවෙළ මාරු කළ විට එම වේලාවද මාරු වේ.';

  @override
  String journeyVisitPositions(int boarding, int alighting) {
    return 'මාර්ගයේ $boarding වන නැවතුමෙන් නැඟී $alighting වන නැවතුමෙන් බසින්න.';
  }

  @override
  String get scheduleReschedule => 'වෙනත් පිටත්වීමක් ප්‍රකාශ කරන්න';

  @override
  String get scheduleRescheduleHelp =>
      'පැරණි පිටත්වීම අවලංගු කර තෝරාගත් කොළඹ දිනය සහ වේලාවට සම්බන්ධිත නව පිටත්වීමක් ප්‍රකාශ කරන්න. සුරැකි ගමන්වල මුල් තේරීම රැකේ. පහත හේතුව සැමට පෙනේ.';

  @override
  String get schedulePublicReason => 'සැමට පෙනෙන වෙනස්කම් හේතුව';

  @override
  String get scheduleReasonRequired => 'අවම වශයෙන් අක්ෂර පහක් ඇතුළත් කරන්න.';

  @override
  String get scheduleStatusUnavailable =>
      'වත්මන් ගමන් තත්ත්වය ලබාගත නොහැක. සුරැකි වේලාවන් බස් රථය ධාවනය වන බව තහවුරු නොකරයි.';

  @override
  String get scheduleCancelled =>
      'මෙම පිටත්වීම අවලංගු කර ඇත. ඔබගේ සුරැකි තේරීම වෙනත් ගමනකට මාරු කර නැත.';

  @override
  String get scheduleChanged =>
      'වත්මන් කාලසටහන සුරැකි තේරීමට වඩා වෙනස්ය. මුල් සුරැකි වේලාවන් පෙන්වයි. වත්මන් විකල්ප බැලීමට නැවත සොයන්න.';

  @override
  String get scheduleReplacement =>
      'සම්බන්ධිත වෙනත් පිටත්වීමක් ප්‍රකාශ කර ඇත. එහි වත්මන් තත්ත්වය බැලීමට නැවත සොයන්න.';

  @override
  String scheduleReplacementAt(String time) {
    return '$time සඳහා වෙනත් පිටත්වීමක් ප්‍රකාශ කර ඇත. එහි වත්මන් තත්ත්වය බැලීමට නැවත සොයන්න.';
  }

  @override
  String get scheduleSavedRecord =>
      'මුල් සුරැකි කාලසටහනයි. වත්මන් බස් රථය හෝ මාර්ගය ලබාගත නොහැක හෝ වෙනස් වී ඇත. මෙය සජීවී ස්ථානය හෝ වත්මන් ප්‍රවේශ පහසුකම් තහවුරු නොකරයි.';

  @override
  String get scheduleTimeUnknown => 'සුරැකි අතරමැදි වේලාව නොමැත';

  @override
  String scheduleSavedFare(String fare) {
    return 'සුරැකි ගාස්තුව: $fare';
  }

  @override
  String get manualAppealsTitle => 'සීමා කිරීම් පිළිබඳ අභියාචනා';

  @override
  String get manualAppealsExplanation =>
      'ගිණුමට පනවා ඇති පරිපාලන සීමාවකට අභියාචනයක් යවන්න. යැවීමෙන් ප්‍රවේශය නැවත ලැබෙන්නේ නැත. පිළිගත් අභියාචනය අදාළ පරිපාලන සීමාව පමණක් ඉවත් කරයි.';

  @override
  String get manualAppealReason => 'අභියාචනය පැහැදිලි කරන්න';

  @override
  String get manualAppealSubmit => 'අභියාචනය යවන්න';

  @override
  String get manualAppealNoNew =>
      'වත්මන් සීමාව සඳහා අලුත් අභියාචනයක් යැවිය නොහැක.';

  @override
  String get manualAppealRestore => 'පරිපාලන සීමාව ඉවත් කරන්න';

  @override
  String get manualAppealUphold => 'සීමාව තහවුරු කරන්න';

  @override
  String get manualAppealClose => 'සමාලෝචනය වසන්න';

  @override
  String get manualAppealPending => 'සමාලෝචනය බලාපොරොත්තුවෙන්';

  @override
  String get manualAppealAccepted => 'අභියාචනය පිළිගෙන ඇත';

  @override
  String get manualAppealRejected => 'අභියාචනය ප්‍රතික්ෂේප කර ඇත';

  @override
  String get manualAppealReview => 'අභියාචනය සමාලෝචනය කරන්න';

  @override
  String get manualAppealEmpty => 'සීමා කිරීම් පිළිබඳ අභියාචනා නැත.';

  @override
  String get manualAppealFailed =>
      'ඉල්ලීම තහවුරු කළ නොහැකි විය. නව තීරණයකට පෙර වත්මන් සීමාව නැවත පූරණය කරන්න. තහවුරු නොවූ ඉල්ලීම එම විස්තර සමඟම නැවත යවන්න.';

  @override
  String get adminLoadMore => 'තවත් පූරණය කරන්න';

  @override
  String get adminSearchLoaded => 'පූරණය කළ වාර්තා සොයන්න';

  @override
  String get adminLoadedPages =>
      'ගණන් සහ සෙවීම පූරණය කළ පිටුවලට අදාළ වේ. තවත් වාර්තා බැලීමට තවත් පූරණය කරන්න.';

  @override
  String manualAppealRevision(int revision) {
    return 'සීමාවේ අනුවාදය $revision';
  }

  @override
  String get adminConsole => 'පරිපාලක පුවරුව';

  @override
  String get adminOverview => 'දළ විස්තර';

  @override
  String get adminBuses => 'බස් රථ';

  @override
  String get adminRoutes => 'මාර්ග';

  @override
  String get adminStops => 'බස් නැවතුම්';

  @override
  String get adminUsers => 'පරිශීලකයන්';

  @override
  String get adminDrivers => 'රියදුරන්';

  @override
  String get adminActivity => 'ක්‍රියාකාරකම්';

  @override
  String get adminRefresh => 'සේවාදායක දත්ත නැවත පූරණය කරන්න';

  @override
  String get adminSignOut => 'ඉවත් වන්න';

  @override
  String get adminSampleCatalogue => 'ආදර්ශ/පරීක්ෂණ නාමාවලි පරිපාලනය';

  @override
  String get adminUnavailable => 'සේවාදායක දත්ත ලබාගත නොහැක.';

  @override
  String get adminLoading => 'සේවාදායක වාර්තා පූරණය වෙමින්...';

  @override
  String get adminNoMatches => 'ගැළපෙන වාර්තා නැත.';

  @override
  String get adminReviewAccess => 'ප්‍රවේශය සමාලෝචනය කරන්න';

  @override
  String get adminAssignRoute => 'මාර්ගයක් පවරන්න';

  @override
  String get adminEditProfile => 'පැතිකඩ සංස්කරණය කරන්න';

  @override
  String get adminReviewDriver => 'රියදුරු සමාලෝචනය කරන්න';

  @override
  String get adminDatedDepartures => 'දින නියමිත පිටත්වීම්';

  @override
  String get adminRestore => 'ප්‍රතිස්ථාපනය කරන්න';

  @override
  String get adminEdit => 'සංස්කරණය කරන්න';

  @override
  String get adminDelete => 'මකන්න';

  @override
  String get adminFinishDeletion => 'මකා දැමීම අවසන් කරන්න';

  @override
  String get adminCancel => 'අවලංගු කරන්න';

  @override
  String get adminDeleteRecord => 'වාර්තාව මකන්න';

  @override
  String get adminEditUser => 'පරිශීලක පැතිකඩ සංස්කරණය කරන්න';

  @override
  String get adminName => 'නම';

  @override
  String get adminPhone => 'දුරකථනය';

  @override
  String get adminSaveProfile => 'පැතිකඩ සුරකින්න';

  @override
  String get adminAssignedRoute => 'පවරා ඇති මාර්ගය';

  @override
  String get adminNoRoute => 'මාර්ගයක් නැත / පැවරීම ඉවත් කරන්න';

  @override
  String get adminAssignmentReason => 'පැවරීමේ හේතුව (අවම අක්ෂර 10)';

  @override
  String get adminSaveAssignment => 'පැවරීම සුරකින්න';

  @override
  String get adminDecision => 'තීරණය';

  @override
  String get adminApprove => 'අනුමත කරන්න';

  @override
  String get adminReject => 'ප්‍රතික්ෂේප කරන්න';

  @override
  String get adminRevoke => 'ප්‍රවේශය ඉවත් කරන්න';

  @override
  String get adminReviewReason => 'සමාලෝචන සාක්ෂි / හේතුව';

  @override
  String get adminConfirmDecision => 'තීරණය තහවුරු කරන්න';

  @override
  String get adminApproved => 'අනුමතයි';

  @override
  String get adminRejected => 'ප්‍රතික්ෂේපිතයි';

  @override
  String get adminRevoked => 'ඉවත් කර ඇත';

  @override
  String get adminPending => 'සමාලෝචනය බලාපොරොත්තුවෙන්';

  @override
  String get adminUnassigned => 'පවරා නැත';

  @override
  String get adminAdd => 'එක් කරන්න';

  @override
  String get adminBusStop => 'බස් නැවතුම';

  @override
  String get adminBusTimetable => 'බස් රථය / කාලසටහන';

  @override
  String get adminRoute => 'මාර්ගය';

  @override
  String get adminRecordId => 'වාර්තා හැඳුනුම';

  @override
  String get adminStopName => 'නැවතුමේ නම';

  @override
  String get adminSourceUrl => 'මූලාශ්‍ර සබැඳිය';

  @override
  String get adminUnknown => 'නොදනී / ඇගයීමට ලක් කර නැත';

  @override
  String get adminEquipped => 'උපකරණ ඇත';

  @override
  String get adminNotEquipped => 'උපකරණ නැත';

  @override
  String get adminYesAssessed => 'ඔව් - ඇගයීමට ලක් කර ඇත';

  @override
  String get adminNoAssessed => 'නැත - ඇගයීමට ලක් කර ඇත';

  @override
  String get adminCatalogueType => 'නාමාවලි වාර්තා වර්ගය';

  @override
  String get adminPhysicalVehicle => 'සැබෑ වාහනය';

  @override
  String get adminPublishedTimetable => 'ප්‍රකාශිත කාලසටහන';

  @override
  String get adminRouteField => 'මාර්ගය';

  @override
  String get adminDriverField => 'පවරා ඇති රියදුරු';

  @override
  String get adminScheduledTime => 'නියමිත වේලාව (HH:mm)';

  @override
  String get adminAddStop => 'නැවතුමක් එක් කරන්න';

  @override
  String get adminSaving => 'සුරකිමින්...';

  @override
  String get adminSaveCatalogue => 'නාමාවලි වාර්තාව සුරකින්න';

  @override
  String get adminReloadReferences => 'යොමු දත්ත නැවත පූරණය කරන්න';

  @override
  String get adminOpenPassenger => 'මගී යෙදුම විවෘත කරන්න';

  @override
  String get adminTransit => 'ප්‍රවාහන පරිපාලනය';

  @override
  String get adminChangeConfirmed => 'වෙනස සේවාදායකය තහවුරු කළා.';

  @override
  String get adminSourceChecked =>
      'මූලාශ්‍රය සහ ඇතුළත් නාමාවලි විස්තර සමාලෝචනය කළෙමි.';

  @override
  String get adminDeleteHelp =>
      'මෙය නාමාවලි වාර්තාව ඉවත් කරයි. යොමු ඇති වාර්තා සහ ධාවනය වන බස් මකා දැමිය නොහැක. මෙය ආපසු හැරවිය නොහැක.';

  @override
  String get adminDriverChecked =>
      'මෙම රියදුරුගේ අනන්‍යතාව සහ ධාවන බලය පරීක්ෂා කළෙමි.';

  @override
  String get adminSourceLoadError =>
      'සේවාදායක වාර්තා පූරණය කළ නොහැක. සම්බන්ධතාව/ප්‍රවේශය පරීක්ෂා කර නැවත උත්සාහ කරන්න.';

  @override
  String get adminLatitude => 'අක්ෂාංශය';

  @override
  String get adminLongitude => 'දේශාංශය';

  @override
  String get adminRamp => 'බෑවුම් ප්‍රවේශ පහසුකම';

  @override
  String get adminElevator => 'සෝපාන පහසුකම';

  @override
  String get adminStepFree => 'ඇගයූ පඩි රහිත මාර්ගය';

  @override
  String get adminRouteNumber => 'මාර්ග අංකය';

  @override
  String get adminRouteName => 'මාර්ගයේ නම';

  @override
  String get adminDescription => 'විස්තරය';

  @override
  String get adminVehicleRegistration => 'වාහන ලියාපදිංචි අංකය';

  @override
  String get adminLowFloor => 'පහත් බිම් මට්ටම් පහසුකම';

  @override
  String get adminStableId =>
      'ස්ථාවර හැඳුනුමකි. නිර්මාණයෙන් පසු වෙනස් කළ නොහැක.';

  @override
  String get adminSourceHelp =>
      'බලයලත් කාලසටහන්, නැවතුම් හෝ ක්‍රියාකරු මූලාශ්‍රයකි. මෙය සජීවී සේවා තහවුරු කිරීමක් නොවේ.';

  @override
  String get adminOverviewHelp =>
      'මූලාශ්‍ර සහිත නාමාවලිය පවත්වා ක්‍රියාකරු ප්‍රවේශය සමාලෝචනය කරන්න. සියලු වෙනස්කම් සේවාදායකයෙන් තහවුරු විය යුතුය.';

  @override
  String get adminRegistrationHelp =>
      'රියදුරු ලියාපදිංචිය ප්‍රවේශ අයදුමකි. අනුමැතියට පෙර අනන්‍යතාව සහ ධාවන බලය සමාලෝචනය කරන්න. අනුමැතිය උපකරණ හෝ සේවාවක් සහතික නොකරයි.';

  @override
  String get adminBusCountLabel => 'බස් සහ කාලසටහන් (පූරණය කළ)';

  @override
  String get adminRouteCountLabel => 'මාර්ග (පූරණය කළ)';

  @override
  String get adminStopCountLabel => 'බස් නැවතුම් (පූරණය කළ)';

  @override
  String get adminUserCountLabel => 'පරිශීලකයන් (පූරණය කළ)';

  @override
  String get adminDriverCountLabel => 'සමාලෝචනය අපේක්ෂිත රියදුරන් (පූරණය කළ)';

  @override
  String get adminReferencesError =>
      'යොමු වාර්තා සම්පූර්ණයෙන් පූරණය කළ නොහැක. සුරැකීමට පෙර නැවත පූරණය කරන්න.';

  @override
  String adminRouteFor(String name) {
    return '$name සඳහා මාර්ගය';
  }

  @override
  String adminReviewFor(String name) {
    return '$name සමාලෝචනය';
  }

  @override
  String adminDeleteFor(String name) {
    return '$name මකන්නද?';
  }

  @override
  String adminAssignedRouteFor(String name) {
    return 'පවරා ඇති මාර්ගය: $name';
  }

  @override
  String adminCurrentAccessFor(String name) {
    return 'වත්මන් ප්‍රවේශය: $name';
  }

  @override
  String adminPreviousReviewFor(String name) {
    return 'පෙර සමාලෝචනය: $name';
  }

  @override
  String get adminNoActiveRoute => 'සක්‍රිය මාර්ග පැවරීමක් නැත';

  @override
  String get adminRequired => 'අවශ්‍යයි';

  @override
  String get adminReviewSource => 'සුරැකීමට පෙර මූලාශ්‍රය සමාලෝචනය කරන්න.';

  @override
  String get adminRouteFirst =>
      'පළමුව අනුමත රියදුරෙකු මෙම මාර්ගයට පවරන්න හෝ පෙර පැවරීම ඉවත් කරන්න.';

  @override
  String get adminAuthProfileHelp =>
      'පිවිසුම් ඊමේල්, මුරපද සහ Auth ගිණුම් මකා දැමීම Firebase Authentication හරහා කළමනාකරණය වේ.';

  @override
  String get adminReferenceWithdrawHelp =>
      'ප්‍රවේශය සහ බස් පැවරීම් ඉවත් කෙරේ. සක්‍රිය ගමන්/ස්ථාන වාර්තා සංහිඳියාව සඳහා රැඳේ; ඒවා අවසන් ලෙස නොසලකයි.';

  @override
  String get adminCapabilityHelp =>
      'පහසුකම තිබීම සහ එය ක්‍රියා කිරීම වෙන වෙනම සලකන්න. ක්‍රියාකාරී පරීක්ෂා පවරා ඇති රියදුරු සටහන් කරයි.';

  @override
  String get adminTimetableHelp =>
      'ප්‍රකාශිත කාලසටහනක සැබෑ වාහනය, රියදුරු හෝ උපකරණ තත්ත්වය තහවුරු කර නැත.';

  @override
  String get adminOrderedStops => 'ගමන් අනුපිළිවෙළට නැවතුම්';

  @override
  String get adminMoveUp => 'නැවතුම ඉහළට ගෙනයන්න';

  @override
  String get adminMoveDown => 'නැවතුම පහළට ගෙනයන්න';

  @override
  String get adminRemoveStop => 'නැවතුම ඉවත් කරන්න';

  @override
  String get adminChooseRoute => 'මාර්ගයක් තෝරන්න';

  @override
  String get adminTimeFormat => 'පැය 24 HH:mm ආකෘතිය භාවිත කරන්න';

  @override
  String get adminAssignmentHelp =>
      'අනුමැතිය සහ මාර්ග පැවරීම වෙන වෙනම සිදු වේ. මාර්ගය වෙනස් කිරීමට හෝ ඉවත් කිරීමට පෙර සක්‍රිය ගමන අවසන් කරන්න.';

  @override
  String get adminReviewChecksHelp =>
      'අනන්‍යතා සහ ධාවන බල පරීක්ෂා හෝ තීරණයට හේතුව සටහන් කරන්න.';

  @override
  String get adminChangeUnconfirmed =>
      'වෙනස තහවුරු නොවීය. ප්‍රවේශය/සම්බන්ධතාව පරීක්ෂා කර නැවත උත්සාහ කිරීමට පෙර දත්ත පූරණය කරන්න.';

  @override
  String get adminSaveUnconfirmed =>
      'සුරැකීම තහවුරු නොවීය. සම්බන්ධතාව/ප්‍රවේශය පරීක්ෂා කර නැවත උත්සාහ කිරීමට පෙර දත්ත පූරණය කරන්න.';

  @override
  String get adminCursorChanged => 'පිටු දත්ත වෙනස් වී ඇත. නැවත පූරණය කරන්න.';

  @override
  String get adminAccountReferenceChanged =>
      'ගිණුම වෙනස් වී ඇත. යොමු දත්ත නැවත පූරණය කරන්න.';

  @override
  String get adminAccessRequired => 'පරිපාලක ප්‍රවේශය අවශ්‍යයි.';

  @override
  String get adminAccountSignInChanged => 'ගිණුම වෙනස් වී ඇත. නැවත පිවිසෙන්න.';

  @override
  String get adminConnectionRequired =>
      'සේවාදායක සම්බන්ධතාවක් අවශ්‍යයි. සම්බන්ධ වූ පසු නැවත උත්සාහ කරන්න.';

  @override
  String get adminRecordChanged =>
      'මෙම වාර්තාව වෙනස් වී ඇත. සුරැකීමට පෙර නැවත පූරණය කරන්න.';

  @override
  String get adminTwoStops =>
      'ගමන් අනුපිළිවෙළට අවම වශයෙන් වෙනස් නැවතුම් දෙකක් තෝරන්න.';

  @override
  String get adminOccurrenceStation =>
      'සෑම නැවතුම් අවස්ථාවක්ම පැහැදිලිව හඳුනාගත් සැබෑ නැවතුමකට සම්බන්ධ විය යුතුය.';

  @override
  String get adminSourceInvalid => 'නාමාවලියේ මූලාශ්‍ර සබැඳිය ඇතුළත් කරන්න.';

  @override
  String get adminVehicleTypeInvalid =>
      'වාහනයක් හෝ ප්‍රකාශිත කාලසටහනක් තෝරන්න.';

  @override
  String get adminNoTimetableDriver => 'කාලසටහනකට රියදුරෙකු පැවරිය නොහැක.';

  @override
  String get adminTimePerStop =>
      'සෑම නැවතුමකටම පැය 24 HH:mm වේලාවක් ඇතුළත් කරන්න. මධ්‍යම රාත්‍රියෙන් පසු වේලාව ඊළඟ දිනයට යා හැක.';

  @override
  String get adminRecordIdInvalid =>
      'වාර්තා හැඳුනුම සඳහා අකුරු, අංක, යටිකුරු හෝ ඉරිකුරු භාවිත කරන්න.';

  @override
  String get adminRestoreFirst =>
      'සංස්කරණයට පෙර මෙම වාර්තාව ප්‍රතිස්ථාපනය කරන්න.';

  @override
  String get adminReferenceDeleting =>
      'යොමු වාර්තාවක් මකා දැමීමට නියමිතයි. එය ප්‍රතිස්ථාපනය කරන්න හෝ වෙනත් වාර්තාවක් තෝරන්න.';

  @override
  String get adminStopMissing =>
      'තෝරාගත් නැවතුමක් දැන් නොමැත. පෝරමය නැවත පූරණය කරන්න.';

  @override
  String get adminDependentBuses =>
      'මාර්ග අංකය හෝ නැවතුම් අනුපිළිවෙළ වෙනස් කිරීමට පෙර ඒවා භාවිත කරන බස් යාවත්කාලීන කරන්න.';

  @override
  String get adminOccurrenceRebind =>
      'පවතින නැවතුම් අවස්ථා වෙනත් නැවතුමකට යළි සම්බන්ධ කළ නොහැක. අලුත් අවස්ථා හැඳුනුම් භාවිත කරන්න.';

  @override
  String get adminRouteMismatch => 'එම මාර්ග අංකයම ඇති පවතින මාර්ගයක් තෝරන්න.';

  @override
  String get adminStopOrderInvalid =>
      'වාහනයේ නැවතුම් තෝරාගත් මාර්ගයේ අනුපිළිවෙළ අනුගමනය කළ යුතුය.';

  @override
  String get adminApprovedOnly => 'අනුමත ක්‍රියාකරුවෙකු පමණක් පැවරිය හැක.';

  @override
  String get adminGrantFirst => 'පළමුව අනුමත රියදුරු මෙම මාර්ගයට පවරන්න.';

  @override
  String get adminBusActive =>
      'මෙම බස් රථයේ සක්‍රිය ගමනක් හෝ ස්ථාන විකාශයක් ඇත. පැවරීම, මාර්ගය හෝ නැවතුම් වෙනස් කිරීමට පෙර එය අවසන් කරන්න.';

  @override
  String get adminNotDeleting => 'මෙම වාර්තාව මකා දැමීමට නියමිත නැත.';

  @override
  String get adminReviewInputInvalid =>
      'ක්‍රියාකරුවෙකු තෝරා අක්ෂර 10–2000ක සමාලෝචනයක්/හේතුවක් ඇතුළත් කරන්න.';

  @override
  String get adminGrantInputInvalid =>
      'රියදුරෙකු තෝරා අක්ෂර 10–2000ක හේතුවක් ඇතුළත් කරන්න.';

  @override
  String get adminApproveFirst => 'මාර්ගයක් පැවරීමට පෙර රියදුරු අනුමත කරන්න.';

  @override
  String get adminReviewedRoute => 'ලබාගත හැකි සමාලෝචිත මාර්ගයක් තෝරන්න.';

  @override
  String get adminProfileInputInvalid =>
      'නම (අක්ෂර 100 දක්වා) සහ දුරකථනය (අක්ෂර 40 දක්වා) ඇතුළත් කරන්න.';

  @override
  String adminFieldRequired(String field, int maximum) {
    return '$field අවශ්‍යයි (උපරිම අක්ෂර $maximum).';
  }

  @override
  String adminCoordinateInvalid(String field) {
    return 'වලංගු $field ඛණ්ඩාංක ඇතුළත් කරන්න.';
  }

  @override
  String adminDependencyDelete(String kind) {
    return 'මකා දැමිය නොහැක: $kind මෙම වාර්තාවට යොමු වේ. සම්බන්ධය ඉවත් කරන්න හෝ ඉතිහාසය සඳහා රඳවාගන්න.';
  }

  @override
  String adminLoadKindsFailed(String kinds) {
    return 'සේවාදායකයෙන් $kinds තහවුරු කළ නොහැක. ක්‍රියා අක්‍රියයි. නැවත පූරණය කර උත්සාහ කරන්න.';
  }

  @override
  String adminBusSummary(String route, String kind, String driver) {
    return 'මාර්ගය $route | $kind\nරියදුරු: $driver';
  }

  @override
  String adminStopCount(int count) {
    return 'අනුපිළිවෙළේ නැවතුම් $count';
  }

  @override
  String adminAuditBy(String actor) {
    return 'සිදු කළේ $actor';
  }

  @override
  String adminTimetableFor(String route) {
    return 'මාර්ග $route කාලසටහන';
  }

  @override
  String get adminRunHelp =>
      'මෙම බස් කාලසටහන කොළඹ වේලා කලාපයේ නිශ්චිත සේවා දිනයකට ප්‍රකාශ කරන්න. ගමන ආරම්භ කිරීමෙන් මගීන් නැගීම විවෘත වේ; පිටත්වීම වෙනම සටහන් වේ.';

  @override
  String get adminRunRescheduleHelp =>
      'නැවත කාල නියම කිරීමට පෙර නියමිත ගමන අවලංගු කර ඒ වෙනුවට අලුත් ගමනක් ප්‍රකාශ කරන්න. නැවතුම් අතර කාල පරතර සහ බස් කාලසටහන රඳවා ගනී.';

  @override
  String get adminRunWindowHelp =>
      'ආරම්භ කළ හැකි කාලය: පිටත්වීමට විනාඩි 5කට පෙර සිට විනාඩි 30කට පසු දක්වා. ප්‍රමාද ආරම්භ සඳහා හේතුවක් අවශ්‍යයි.';

  @override
  String get adminRunPublish => 'දින නියමිත පිටත්වීම ප්‍රකාශ කරන්න';

  @override
  String get adminRunReload => 'පිටත්වීම් නැවත පූරණය කරන්න';

  @override
  String get adminRunCancel => 'නියමිත ගමන අවලංගු කරන්න';

  @override
  String get adminRunConfirmed => 'දින නියමිත පිටත්වීමේ වෙනස තහවුරුයි.';

  @override
  String get adminRunLoadFailed =>
      'දින නියමිත පිටත්වීම් පූරණය කළ නොහැක. සම්බන්ධ වූ පසු නැවත උත්සාහ කරන්න.';

  @override
  String get adminRunChangeFailed =>
      'වෙනස තහවුරු නොවීය. නැවත පූරණය කර උත්සාහ කරන්න.';

  @override
  String get adminRunReviewTimetable =>
      'සුරැකි කාලසටහන පරිපාලක සමාලෝචනයට ලක් කළ යුතුය.';

  @override
  String get adminRunEmpty => 'මෙම බස් රථයට දින නියමිත පිටත්වීම් නැත.';

  @override
  String get adminRunScheduled => 'නියමිතයි';

  @override
  String get adminRunBoarding => 'මගීන් නගිමින්';

  @override
  String get adminRunInProgress => 'ධාවනය වෙමින්';

  @override
  String get adminRunCompleted => 'අවසන්';

  @override
  String get adminRunCancelled => 'අවලංගුයි';

  @override
  String get adminRunUnknown => 'තත්ත්වය ලබාගත නොහැක';

  @override
  String get adminCalendarDatesInvalid =>
      'සතියේ දින සහ උපරිම දින 31ක කාල පරාසයක් තෝරන්න.';

  @override
  String get adminCalendarReload => 'ප්‍රකාශිත දින දර්ශනය නැවත පූරණය කරන්න.';

  @override
  String get adminCalendarPublishedOnly =>
      'පිටත්වීම් ජනනය කළ හැක්කේ ප්‍රකාශිත දින දර්ශනයකින් පමණි.';

  @override
  String get adminCalendarInvalid =>
      'දින දර්ශනය වලංගු නැත. සමාලෝචිත ආදේශකයක් ප්‍රකාශ කරන්න.';

  @override
  String get adminCalendarBusChanged =>
      'බස් කාලසටහන වෙනස් වී ඇත. සමාලෝචිත ආදේශක දින දර්ශනයක් ප්‍රකාශ කරන්න.';

  @override
  String get adminColomboTimeInvalid =>
      'වලංගු කොළඹ වේලා කලාපයේ පිටත්වීමේ වේලාවක් තෝරන්න.';

  @override
  String get adminPhysicalBusRequired => 'ලබාගත හැකි සැබෑ බස් රථයක් තෝරන්න.';

  @override
  String get adminCompleteTimetableRequired =>
      'දින නියමිත ගමනකට සම්පූර්ණ සමාලෝචිත කාලසටහනක් අවශ්‍යයි.';

  @override
  String get adminRouteUnavailable => 'මාර්ගය ලබාගත නොහැක.';

  @override
  String get adminRescheduleInputInvalid =>
      'ආදේශ නොකළ, ආරම්භ නොවූ ගමනක් තෝරා ප්‍රසිද්ධ හේතුවක් (අක්ෂර 5–300) ඇතුළත් කරන්න.';

  @override
  String get adminReviewBusTimetable =>
      'පළමුව සැබෑ බස් රථයේ වත්මන් කාලසටහන සමාලෝචනය කරන්න.';

  @override
  String get adminDifferentDeparture => 'වෙනත් පිටත්වීමේ වේලාවක් තෝරන්න.';

  @override
  String get adminReviewScheduleVersion =>
      'මුල් කාලසටහන් අනුවාදය සමාලෝචනය කරන්න.';

  @override
  String get adminReconcileFirst =>
      'පළමුව සක්‍රිය ධාවන කටයුත්ත නිරාකරණය කරන්න.';

  @override
  String get adminCancelNotStartedOnly =>
      'මෙහි අවලංගු කළ හැක්කේ ආරම්භ නොවූ ගමනක් පමණි.';

  @override
  String adminServiceDate(String date) {
    return 'සේවා දිනය: $date';
  }

  @override
  String adminColomboDeparture(String time) {
    return 'කොළඹ වේලා කලාපයේ පිටත්වීම: $time';
  }

  @override
  String adminLateReason(String reason) {
    return 'ප්‍රමාද ආරම්භයට හේතුව: $reason';
  }

  @override
  String adminPublishedStopTimes(String times) {
    return 'ප්‍රකාශිත නැවතුම් වේලා: $times';
  }

  @override
  String adminColomboDateTime(String date, String time) {
    return '$date $time (Asia/Colombo)';
  }

  @override
  String get adminGeometryRouteId => 'මාර්ග හැඳුනුම';

  @override
  String get adminGeometryImportJson => 'සමාලෝචිත මාර්ග හැඩ දත්ත JSON';

  @override
  String get adminGeometryActionFailed =>
      'මාර්ග හැඩ දත්ත වෙනස තහවුරු නොවීය. නැවත උත්සාහ කිරීමට පෙර ප්‍රවේශය, හේතුව සහ වත්මන් මාර්ග/නැවතුම් දත්ත පරීක්ෂා කරන්න.';

  @override
  String get adminFareLoadFailed =>
      'ගාස්තු ප්‍රකාශන පූරණය කළ නොහැක. සම්බන්ධ වූ පසු නැවත පූරණය කරන්න; නාමාවලිය හිස් බව තහවුරු කර නැත.';

  @override
  String get adminFarePublished => 'ප්‍රකාශිතයි';

  @override
  String get adminFareArchived => 'සංරක්ෂිතයි';

  @override
  String get adminFarePublicationInvalid => 'ගාස්තු ප්‍රකාශනය වලංගු නැත';

  @override
  String get adminFareBusesRequired => 'සමාලෝචිත බස් තෝරන්න';

  @override
  String get adminFareSplitRequired =>
      'මෙම ප්‍රකාශනය කුඩා සමාලෝචිත වාර්තාවලට වෙන් කරන්න';

  @override
  String get adminFareApplicabilityMismatch =>
      'ගාස්තු වගුව සහ නැවතුම් ගැළපීම අදාළ වන පරාස නොගැළපේ';

  @override
  String get adminFareReviewRequired =>
      'මූලාශ්‍රය, ගාස්තු අදියර, සේවා පන්තිය සහ වලංගු දින සමාලෝචනය කර හේතුවක් ඇතුළත් කරන්න.';

  @override
  String get adminFareRouteUnavailable => 'මාර්ගය ලබාගත නොහැක';

  @override
  String get adminFareItineraryMismatch =>
      'බස් ගමන් සැලැස්මක් හෝ මාර්ගයක් සමාලෝචිත ගැළපීමට නොගැළපේ';

  @override
  String get adminFareArchiveReasonRequired => 'සංරක්ෂණයට හේතුවක් ඇතුළත් කරන්න';

  @override
  String get adminFareTextInvalid => 'ගාස්තු නාමාවලි පාඨය වලංගු නැත';

  @override
  String get adminFareDateInvalid => 'ගාස්තුව අදාළ වන දිනය වලංගු නැත';

  @override
  String get adminFareSourceInvalid => 'ගාස්තු මූලාශ්‍රය වලංගු නැත';

  @override
  String get adminFareUnreviewed =>
      'සමාලෝචනය නොකළ හෝ සහාය නොදක්වන ගාස්තු වගුවකි';

  @override
  String get adminFareTableInvalid => 'ගාස්තු වගුව වලංගු නැත';

  @override
  String get adminFareMatrixInvalid => 'ගාස්තු අගයන්ගේ වගුව වලංගු නැත';

  @override
  String get adminFareMinorInvalid => 'සුළු මුදල් ඒකකවල ගාස්තු අගය වලංගු නැත';

  @override
  String get adminFareMappingInvalid =>
      'ගාස්තු ගැළපීම සමාලෝචනය කර නැත හෝ වලංගු නැත';

  @override
  String get adminFareOccurrencesInvalid => 'ගාස්තු නැවතුම් අවස්ථා වලංගු නැත';

  @override
  String get adminGeometryReviewRequired =>
      'මාර්ග හැඩ දත්ත සමාලෝචනය කර හේතුවක් ඇතුළත් කරන්න';

  @override
  String get adminGeometryRouteChanged =>
      'වත්මන් දිශානුගත මාර්ග ගමන් සැලැස්ම සමාලෝචනය කරන්න';

  @override
  String get adminGeometryModeMismatch =>
      'මාර්ග හැඩ දත්ත වෙනත් දත්ත ආකාරයකට අයත් වේ';

  @override
  String get adminGeometryVersionRequired =>
      'අලුත් සමාලෝචිත අනුවාදයක් භාවිත කරන්න';

  @override
  String get adminGeometryStopMismatch =>
      'සෑම නැවතුම් ඛණ්ඩාංකයක් සහ එහි මාර්ග ලක්ෂ්‍යය සමාලෝචනය කරන්න';

  @override
  String get adminGeometryReasonRequired => 'සමාලෝචන හේතුවක් ඇතුළත් කරන්න';

  @override
  String get adminGeometryMissing => 'ඉවත් කිරීමට මාර්ග හැඩ දත්ත නැත';

  @override
  String get adminGeometryDataInvalid => 'සමාලෝචිත මාර්ග හැඩ දත්ත වලංගු නැත';

  @override
  String get adminGeometryStopsInvalid =>
      'මාර්ග හැඩයේ නැවතුම් අනුපිළිවෙළ වලංගු නැත';

  @override
  String get adminGeometryCoordinatesInvalid => 'ඛණ්ඩාංක වලංගු නැත';

  @override
  String get adminGeometryVerticesInvalid =>
      'නැවතුම් මාර්ග ලක්ෂ්‍ය අනුක්‍රමයෙන් වැඩි විය යුතුය';

  @override
  String get adminGeometryResolutionInvalid =>
      'මාර්ග හැඩයේ විස්තර මට්ටම සමාලෝචනය කරන්න';

  @override
  String get adminGeometryTooLong => 'මාර්ගය දිග වැඩියි';

  @override
  String adminFarePreviewRoute(String route, String serviceClass) {
    return 'මාර්ගය: $route · සේවා පන්තිය: $serviceClass';
  }

  @override
  String adminFarePreviewDates(String from, String until) {
    return 'අදාළ දින: $from – $until';
  }

  @override
  String adminImportSource(String source) {
    return 'මූලාශ්‍රය: $source';
  }

  @override
  String adminFareVersions(String table, String mapping) {
    return 'ගාස්තු අනුවාදය: $table · ගැළපුම් අනුවාදය: $mapping';
  }

  @override
  String adminFareBuses(String buses) {
    return 'බස් රථ: $buses';
  }

  @override
  String adminFareCell(String from, String to, String amount) {
    return '$from → $to: $amount';
  }

  @override
  String adminGeometryVersion(String route, String version) {
    return 'මාර්ගය: $route · අනුවාදය: $version';
  }

  @override
  String adminGeometryDistance(String stops, String distance) {
    return '$stops · කි.මී. $distance';
  }

  @override
  String adminFareRowStatus(String status, String version) {
    return '$status · අනුවාදය: $version';
  }

  @override
  String get reviewAccessRequired =>
      'මෙම සිද්ධිය සමාලෝචනය කිරීමට පරිපාලක ප්‍රවේශය අවශ්‍යයි.';

  @override
  String get reviewSelfForbidden =>
      'ඔබේම ගිණුමට අදාළ සිද්ධියක් ඔබට සමාලෝචනය කළ නොහැක.';

  @override
  String get reviewSignInRequired =>
      'ඔබේ සැසිය දැන් වලංගු නැත. ඉදිරියට යාමට පෙර නැවත පිවිසෙන්න.';

  @override
  String get reviewAccountChanged =>
      'පිවිසි ගිණුම වෙනස් වී ඇත. වත්මන් ගිණුමෙන් මෙම තිරය නැවත විවෘත කරන්න.';

  @override
  String get reviewRestricted =>
      'සීමා කර ඇති විට මෙම ගිණුමට පරිපාලන ක්‍රියා කළ නොහැක.';

  @override
  String get reviewAlreadyDecided =>
      'මෙම සමාලෝචනයට දැනටමත් තීරණයක් ඇත. සටහන් කළ ප්‍රතිඵලය බැලීමට නැවත පූරණය කරන්න.';

  @override
  String get reviewUnavailable =>
      'මෙම සමාලෝචනය ලබාගත නොහැක. වෙනත් ක්‍රියාවකට පෙර නැවත පූරණය කරන්න.';

  @override
  String get reviewOperationUnavailable =>
      'මෙම ක්‍රියාව සඳහා මෙම ගමන දැන් ලබාගත නොහැක. වත්මන් තත්ත්වය නැවත පූරණය කරන්න.';

  @override
  String get reviewRetryConflict =>
      'මෙම ඉල්ලීම සටහන් කළ ඉල්ලීමකට නොගැළපේ. අලුත් ක්‍රියාවකට පෙර නැවත පූරණය කර ප්‍රතිඵලය පරීක්ෂා කරන්න.';

  @override
  String get reviewVoteUnknown => 'ඡන්දය ලබාගත නොහැක';

  @override
  String reviewRunDriver(String run, String driver) {
    return 'ගමන: $run\nරියදුරු: $driver';
  }

  @override
  String reviewDriverId(String driver) {
    return 'රියදුරු: $driver';
  }

  @override
  String reviewVoteEvidence(String user, String vote) {
    return '$user · $vote';
  }

  @override
  String get profileMissing => 'පැතිකඩ හමු නොවීය. නැවත පිවිසෙන්න.';

  @override
  String get profileLoadFailed => 'දත්ත ගබඩාවෙන් පැතිකඩ ලබාගත නොහැක.';

  @override
  String get profileUnavailable => 'පැතිකඩ ලබාගත නොහැක.';

  @override
  String get profilePassenger => 'මගියා';

  @override
  String get profileContributor => 'ප්‍රජා දායකයා';

  @override
  String get profileOperator => 'බස් රියදුරු';

  @override
  String get profileAdministrator => 'පද්ධති පරිපාලක';

  @override
  String get profileCommuter => 'මගියා';

  @override
  String get profileEdit => 'සංස්කරණය';

  @override
  String get profileEditTitle => 'පැතිකඩ සංස්කරණය';

  @override
  String get profileFullName => 'සම්පූර්ණ නම';

  @override
  String get profileEmail => 'විද්‍යුත් තැපෑල';

  @override
  String get profilePhone => 'දුරකථන අංකය';

  @override
  String get profileNameRequired => 'ඔබේ නම ඇතුළත් කරන්න';

  @override
  String get profileSave => 'වෙනස්කම් සුරකින්න';

  @override
  String get profileSaved => 'පැතිකඩ යාවත්කාලීන විය!';

  @override
  String get profileSaveFailed =>
      'පැතිකඩ වෙනස්කම් තහවුරු කළ නොහැකි විය. නැවත උත්සාහ කරන්න.';

  @override
  String get profileSignOutFailed =>
      'පෞද්ගලික කෙටුම්පත් ඉවත් කිරීමට හෝ පිටවීමට නොහැකි විය. නැවත උත්සාහ කරන්න.';

  @override
  String get profileSignedOut => 'ඔබ ගිණුමෙන් පිටවී ඇත.';

  @override
  String get profileSignOut => 'පිටවන්න';

  @override
  String get profileCancel => 'අවලංගු කරන්න';

  @override
  String get profileRetry => 'නැවත උත්සාහ කරන්න';

  @override
  String get profileLogoutQuestion =>
      'පිටවී මෙම උපාංගයේ පොරොත්තු වාර්තා කෙටුම්පත් සහ ඡායාරූප ඉවත් කරන්නද? දැනටමත් යැවූ ඉල්ලීම් තවමත් සම්පූර්ණ විය හැක. නැවත පිවිසීමෙන් පළ කළ වාර්තා ලබාගත හැක.';

  @override
  String get profileSettings => 'සැකසුම්';

  @override
  String get profileSupport => 'සහාය';

  @override
  String get profilePersonalInfo => 'පෞද්ගලික තොරතුරු';

  @override
  String get profileAdminConsole => 'පරිපාලක පුවරුව';

  @override
  String get profileAccessibility => 'ප්‍රවේශතා මනාප';

  @override
  String get profilePush => 'තල්ලු දැනුම්දීම්';

  @override
  String get profilePassword => 'මුරපදය වෙනස් කරන්න';

  @override
  String get profilePlaces => 'සුරැකි ස්ථාන';

  @override
  String get profileRate => 'අපව ඇගයීමට ලක් කරන්න';

  @override
  String get profileHelp => 'උපකාර මධ්‍යස්ථානය';

  @override
  String get profileUpdates => 'යාවත්කාලීන පරීක්ෂා කරන්න';

  @override
  String get profileNotSet => 'සකසා නැත';

  @override
  String get profileReports => 'වාර්තා';

  @override
  String get profileVerifications => 'තහවුරු කිරීම්';

  @override
  String get profileBadges => 'ලාංඡන';

  @override
  String get profileImpact => 'ප්‍රජා දායකත්ව ලකුණු';

  @override
  String get profileSeeAll => 'සියල්ල බලන්න →';

  @override
  String get profileBadgeDetails => 'ලැබූ ලාංඡන බලන්න';

  @override
  String get profileDelete => 'ගිණුම මකන්න';

  @override
  String get profileDeleteUnavailable =>
      'මෙහි ස්වයං ගිණුම් මැකීම තවම ලබාගත නොහැක';

  @override
  String profileComingSoon(String feature) {
    return '$feature ඉදිරි යාවත්කාලීනයකින් ලබාගත හැක.';
  }

  @override
  String profileContributionSummary(int points, int reports, int badges) {
    return 'ලකුණු $points • වාර්තා $reports • ලාංඡන $badges';
  }

  @override
  String get driverDashboard => 'රියදුරු පුවරුව';

  @override
  String get driverFallback => 'රියදුරු';

  @override
  String get driverAddStop => 'මාර්ගයට නැවතුමක් එක් කරන්න';

  @override
  String get driverNoBuses =>
      'ඔබට පැවරූ මාර්ගයේ සැබෑ බස් රථ නොමැත. බස් රථයක් එක් කිරීමට හෝ සමාලෝචනයට පරිපාලකගෙන් ඉල්ලන්න.';

  @override
  String get driverNoGps => 'හවුල් GPS යාවත්කාලීනයක් නැත';

  @override
  String get driverBusUnavailable =>
      'තෝරාගත් බස් රථය ලබාගත නොහැක; උපාංගයෙන් විකාශනය නවතා ඇත';

  @override
  String get driverAssignmentUnavailable =>
      'බස් පැවරුම තහවුරු කළ නොහැක; උපාංගයෙන් විකාශනය නවතා ඇත';

  @override
  String get driverVerifyRuns =>
      'දින නියමිත පිටත්වීම් තහවුරු කිරීමට සම්බන්ධ වන්න.';

  @override
  String get driverSignInFirst => 'පළමුව අනුමත රියදුරෙකු ලෙස පිවිසෙන්න.';

  @override
  String get driverAssignedOnly =>
      'මෙම බස් රථය යාවත්කාලීන කළ හැක්කේ පැවරූ රියදුරුට පමණි.';

  @override
  String get driverClaimFailed =>
      'බස් පැවරුම තහවුරු නොවීය. යළි පූරණය කර නැවත උත්සාහ කරන්න.';

  @override
  String get driverRampWorkingSaved =>
      'බෑවුම් පුවරුව ක්‍රියාත්මක බවට නිරීක්ෂණය සුරැකිණි';

  @override
  String get driverRampBrokenSaved =>
      'බෑවුම් පුවරුව අක්‍රිය බවට නිරීක්ෂණය සුරැකිණි';

  @override
  String get driverRampFailed =>
      'සියලු බෑවුම් පුවරු යාවත්කාලීන තහවුරු නොවීය. යළි පූරණය කර නැවත උත්සාහ කරන්න.';

  @override
  String get driverOccupancyFailed =>
      'සියලු මගී පිරීමේ යාවත්කාලීන තහවුරු නොවීය. යළි පූරණය කර නැවත උත්සාහ කරන්න.';

  @override
  String get driverClaimFirst =>
      'ගමන ආරම්භ කිරීමට පෙර මෙම බස් රථය ඔබට පවරා ගන්න.';

  @override
  String get driverSelectRun => 'පරිපාලක පළ කළ දින නියමිත පිටත්වීමක් තෝරන්න.';

  @override
  String get driverLateTitle => 'ප්‍රමාද ආරම්භයට හේතුව';

  @override
  String get driverLateHelp =>
      'අවම අක්ෂර 5ක්. පිටත්වීමෙන් විනාඩි 30ක් දක්වා ආරම්භ කළ හැක.';

  @override
  String get driverContinue => 'ඉදිරියට';

  @override
  String get driverLateRequired =>
      'ප්‍රමාද ආරම්භයට අවම අක්ෂර 5ක හේතුවක් ඇතුළත් කරන්න.';

  @override
  String get driverGpsAcknowledged => 'හවුල් GPS ලැබීම තහවුරු විය';

  @override
  String get driverTrackingTitle => 'AccessTransit සජීවී බස් ස්ථානය';

  @override
  String get driverGpsUnavailable =>
      'GPS ලබාගත නොහැක; අවසන් හවුල් ස්ථානය පැරණි විය හැක';

  @override
  String get driverGpsStreamError =>
      'GPS යාවත්කාලීන නොලැබේ. ස්ථාන අවසර පරීක්ෂා කර නැවත උත්සාහ කරන්න.';

  @override
  String get driverBoardingStarted =>
      'මගීන් නැගීම ආරම්භ විය. පිටත්වන විට සැබෑ පිටත්වීම සටහන් කරන්න.';

  @override
  String get driverRunResumed =>
      'දින නියමිත සක්‍රිය ගමන නැවත ඇරඹිණි. GPS විකාශනය තහවුරු විය.';

  @override
  String get driverStartFailed =>
      'ගමන ආරම්භය තහවුරු නොවීය. යළි පූරණය කර නැවත උත්සාහ කරන්න.';

  @override
  String get driverGpsPending =>
      'GPS උඩුගත කිරීම පොරොත්තුවේ; ඛණ්ඩාංක උපාංගයේ පමණි';

  @override
  String get driverGpsRetry =>
      'GPS උඩුගත නොවීය/සම්බන්ධතාව නැත; ඊළඟ ස්ථාන දත්ත සමඟ නැවත උත්සාහ වේ';

  @override
  String get driverBoardingEnded => 'මගීන් නැගීම අවලංගු විය; විකාශනය අවසන්';

  @override
  String get driverCompletionAcknowledged => 'හවුල් ගමනේ අවසානය තහවුරු විය';

  @override
  String get driverBoardingCancelled =>
      'මගීන් නැගීම අවලංගු විය. විකාශනය අවසන්.';

  @override
  String get driverTripCompleted => 'ගමනේ අවසානය සුරැකිණි. විකාශනය අවසන්.';

  @override
  String get driverStopPending =>
      'උපාංගයේ GPS නවතා ඇත; හවුල් අවසානය තහවුරු නොවීය. නැවත නවත්වන්න.';

  @override
  String get driverStopFailed =>
      'හවුල් ගමනේ අවසානය තහවුරු නොවීය. නැවත නවත්වන්න.';

  @override
  String get driverDatedDeparture => 'දින නියමිත පිටත්වීම';

  @override
  String get driverNoRuns =>
      'දින නියමිත පිටත්වීම් පළ කර නැත. මෙම බස් රථය කාලසටහන්ගත කිරීමට පරිපාලකගෙන් ඉල්ලන්න.';

  @override
  String get driverColomboDeparture => 'කොළඹ වේලාවෙන් සේවා පිටත්වීම';

  @override
  String get driverBoardingHelp =>
      'ආරම්භ කිරීමෙන් මගීන් නැගීම ඇරඹේ. සැබෑ පිටත්වීම වෙනම සටහන් කරන්න; ප්‍රමාද ආරම්භයට හේතුවක් අවශ්‍යයි.';

  @override
  String get driverDepartureSaved => 'සැබෑ පිටත්වීම සේවාදායකය තහවුරු කළා.';

  @override
  String get driverDepartureFailed =>
      'පිටත්වීම තහවුරු නොවීය. යළි පූරණය කර නැවත උත්සාහ කරන්න.';

  @override
  String get driverRecordDeparture => 'සැබෑ පිටත්වීම සටහන් කරන්න';

  @override
  String get driverActive => 'ගමන ක්‍රියාත්මකයි';

  @override
  String get driverInactive => 'ගමන අක්‍රියයි';

  @override
  String get driverStart => 'ගමන ආරම්භ කරන්න';

  @override
  String get driverStop => 'ගමන නවත්වන්න';

  @override
  String get driverTelemetry => 'සජීවී ස්ථාන දත්ත';

  @override
  String get driverGpsInactive =>
      'GPS අක්‍රියයි. සජීවී ස්ථානය ලබාගැනීමට ගමන ආරම්භ කරන්න.';

  @override
  String get driverLatitude => 'අක්ෂාංශ:';

  @override
  String get driverLongitude => 'දේශාංශ:';

  @override
  String get driverSpeed => 'වේගය:';

  @override
  String get driverHeading => 'දිශාව:';

  @override
  String get driverLocalFix => 'උපාංගයේ GPS ස්ථානය:';

  @override
  String get driverAccessibility => 'බස් රථයේ ප්‍රවේශතා තත්ත්වය';

  @override
  String get driverReadOnly => 'කියවීමට පමණි (පවරා නැත)';

  @override
  String get driverRampObservation => 'රෝද පුටු බෑවුම් පුවරු නිරීක්ෂණය';

  @override
  String get driverUnknownRamp => 'නොදනී - තේරීමට පෙර පරීක්ෂා කරන්න';

  @override
  String get driverWorkingObserved => 'ක්‍රියාත්මක බව නිරීක්ෂණය කළා';

  @override
  String get driverBrokenObserved => 'අක්‍රිය බව නිරීක්ෂණය කළා';

  @override
  String get driverLift => 'පහත් බිම් සෝපානය ක්‍රියාත්මකයි';

  @override
  String get driverStopLiftHelp => 'නැවතුම් සෝපාන නිරීක්ෂණ වෙනම වාර්තා කෙරේ';

  @override
  String get driverOccupancy => 'මගී පිරීම:';

  @override
  String get driverLow => 'අඩු';

  @override
  String get driverMedium => 'මධ්‍යම';

  @override
  String get driverHigh => 'ඉහළ';

  @override
  String get driverAccess => 'රියදුරු ප්‍රවේශය';

  @override
  String get driverChecking => 'රියදුරු අනුමැතිය පරීක්ෂා කෙරේ...';

  @override
  String get driverSignInApproval =>
      'රියදුරු අනුමැතිය පරීක්ෂා කිරීමට පිවිසෙන්න.';

  @override
  String get driverApprovalRequired =>
      'රියදුරු අනුමැතිය අවශ්‍යයි. ගිණුම සමාලෝචනය කිරීමට පරිපාලකගෙන් ඉල්ලන්න. ලියාපදිංචියේ රියදුරු තේරීමෙන් අනුමැතිය නොලැබේ. ප්‍රවේශය තහවුරු කිරීමට සක්‍රිය සම්බන්ධතාවක් අවශ්‍යයි.';

  @override
  String get driverCheckAgain => 'නැවත පරීක්ෂා කරන්න';

  @override
  String get driverReturnSignIn => 'පිවිසීමට ආපසු යන්න';

  @override
  String get driverSignOutFailed => 'පිටවීමට නොහැකි විය. නැවත උත්සාහ කරන්න.';

  @override
  String get driverRouteAssignment => 'රියදුරු මාර්ග පැවරුම';

  @override
  String get driverRouteRequired =>
      'බස් රථයක් ධාවනයට පෙර පරිපාලක ඔබට ලබාගත හැකි මාර්ගයක් පැවරිය යුතුයි. පැවරුම තහවුරු කිරීමට සක්‍රිය සම්බන්ධතාවක් අවශ්‍යයි.';

  @override
  String get driverCheckAssignment => 'පැවරුම පරීක්ෂා කරන්න';

  @override
  String get driverScheduled => 'කාලසටහන්ගතයි';

  @override
  String get driverBoarding => 'මගීන් නැගීම';

  @override
  String get driverInProgress => 'ක්‍රියාත්මකයි';

  @override
  String get driverCompleted => 'සම්පූර්ණයි';

  @override
  String get driverCancelled => 'අවලංගුයි';

  @override
  String get driverUnknownState => 'තත්ත්වය ලබාගත නොහැක';

  @override
  String driverName(String name) {
    return 'රියදුරු: $name';
  }

  @override
  String driverBusAssigned(String bus) {
    return 'බස් $bus දැන් ඔබට පවරා ඇත!';
  }

  @override
  String driverOccupancySaved(String level) {
    return 'මගී පිරීම $level ලෙස යාවත්කාලීන විය';
  }

  @override
  String driverTrackingBody(String bus) {
    return 'බස් $bus සඳහා GPS ස්ථානය; හවුල් දත්ත ලැබීම යෙදුමේ පෙන්වයි';
  }

  @override
  String driverRunWindow(String earliest, String latest) {
    return 'ආරම්භ කළ හැකි කාලය: $earliest සිට $latest';
  }

  @override
  String driverRunOption(String time, String status) {
    return '$time · $status';
  }

  @override
  String driverActiveSummary(String status, String duration) {
    return '$status\nගත වූ කාලය: $duration';
  }

  @override
  String driverStartHelp(String bus) {
    return 'බස් $bus සඳහා පසුබිම් GPS ස්ථානය සක්‍රිය කිරීමට ගමන ආරම්භ කරන්න.';
  }

  @override
  String driverGpsStale(String status) {
    return 'හවුල් GPS පැරණියි; $status';
  }

  @override
  String driverLastReceipt(String time) {
    return 'අවසන් හවුල් දත්ත ලැබීම: $time';
  }

  @override
  String get driverProgress => 'ගමනේ මාර්ග ප්‍රගතිය';

  @override
  String get driverNoActive => 'සක්‍රිය ගමනක් නැත';

  @override
  String get driverNoActiveHelp =>
      'සක්‍රිය ගමනක් නැත. ඉහතින් දින නියමිත පිටත්වීමක් තෝරා මගීන් නැගීම අරඹන්න; පිටත්වන විට සැබෑ පිටත්වීම වෙනම සටහන් කරන්න.';

  @override
  String get driverFinalDestination => 'අවසන් ගමනාන්තයට ළඟා විය';

  @override
  String get driverFinalAcknowledged =>
      'අවසන් පැමිණීම සහ ගමනේ අවසානය තහවුරු විය';

  @override
  String get driverArrivalFailed =>
      'පැමිණීම තහවුරු නොවීය. යළි පූරණය කර නැවත උත්සාහ කරන්න.';

  @override
  String get driverNextReached => 'ඊළඟ නැවතුමට ළඟා විය';

  @override
  String get driverFinalReached => 'අවසන් නැවතුමට ළඟා විය';

  @override
  String get driverEnd => 'ගමන අවසන් කරන්න';

  @override
  String get driverUnknown => 'නොදනී';

  @override
  String get driverNotRecorded => 'සටහන් කර නැත';

  @override
  String get driverEtaHelp =>
      'ඇස්තමේන්තුගත පැමිණීම් සැබෑ පිටත්වීම හා සටහන් කළ පැමිණීම් අනුව යාවත්කාලීන වේ. කාලසටහන් පරතර නැති විට විනාඩි 6ක ඇස්තමේන්තුවක් යෙදේ; වේලාව රියදුරුගෙන් තහවුරු කරගන්න.';

  @override
  String get driverScheduledArrival => 'නියමිත පැමිණීම';

  @override
  String get driverTimetableTarget => 'කාලසටහන් ඉලක්කය';

  @override
  String get driverCurrentEta => 'වත්මන් පැමිණීමේ ඇස්තමේන්තුව';

  @override
  String get driverDelayCleared => 'ප්‍රමාද දැනුම්දීම ඉවත් කිරීම සුරැකිණි.';

  @override
  String get driverDelayClearFailed =>
      'ප්‍රමාද දැනුම්දීම ඉවත් කිරීම තහවුරු නොවීය. නැවත උත්සාහ කරන්න.';

  @override
  String get driverClear => 'ඉවත් කරන්න';

  @override
  String get driverUpdateDelay => 'ප්‍රමාදය / තදබද හේතුව යාවත්කාලීන කරන්න';

  @override
  String get driverReportDelay =>
      'තදබදය / ප්‍රමාදය වාර්තා කරන්න (+විනාඩි 5, 10)';

  @override
  String get driverTraffic => 'මාර්ග තදබදය';

  @override
  String get driverRain => 'තද වැසි / ගංවතුර';

  @override
  String get driverAccident => 'ඉදිරියේ අනතුරක්';

  @override
  String get driverRoadworks => 'මාර්ග ඉදිකිරීම්';

  @override
  String get driverBreakdown => 'යාන්ත්‍රික දෝෂය';

  @override
  String get driverDelayTitle => 'ප්‍රමාදය / සිදුවීම වාර්තා කරන්න';

  @override
  String get driverDelayHelp =>
      'මගී තිරවලට දැනුම්දී පැමිණීමේ ඇස්තමේන්තු යාවත්කාලීන කරයි.';

  @override
  String get driverDelayTime => 'ඇස්තමේන්තුගත ප්‍රමාද කාලය';

  @override
  String get driverDelayReason => 'ප්‍රමාදයට හේතුව';

  @override
  String get driverDelayFailed =>
      'ප්‍රමාද දත්ත උඩුගත කිරීම තහවුරු නොවීය. නැවත උත්සාහ කරන්න.';

  @override
  String get driverDepartsNow => 'නියමිත වේලාවට (දැන් පිටත්වේ)';

  @override
  String get driverOrigin => 'ආරම්භක නැවතුම';

  @override
  String get driverPreTrip => 'ගමනට පෙර කාලසටහන් පරීක්ෂාව';

  @override
  String get driverOnTimeMinute => 'නියමිත වේලාවට (±විනාඩි 1)';

  @override
  String get driverEarly => 'වේලාවට පෙර ධාවනය වේ';

  @override
  String get driverOnTimeTarget => 'නියමිත වේලා ඉලක්කය';

  @override
  String get driverDelayed => 'ප්‍රමාදයි';

  @override
  String get driverMinusFive => 'විනාඩි -5';

  @override
  String get driverZeroSchedule => '0 (කාලසටහන අනුව)';

  @override
  String get driverPlusFifteen => 'විනාඩි +15';

  @override
  String get driverZeroMinutes => 'විනාඩි 0';

  @override
  String get driverSelectBus => 'බස් ධාවනය තෝරන්න';

  @override
  String get driverAssigned => 'ඔබට පවරා ඇත';

  @override
  String get driverAssignMe => 'මට පවරන්න';

  @override
  String get driverAssignedOther => 'වෙනත් රියදුරෙකුට පවරා ඇත';

  @override
  String get driverUpcoming => 'ඉදිරියට නියමිතයි';

  @override
  String get driverDeparted => 'පිටත්ව ඇත';

  @override
  String get driverAssistanceUnavailable =>
      'හවුල් ඉල්ලීම් යාවත්කාලීන නොලැබේ. පෙන්වන ඉල්ලීම් පැරණි විය හැක.';

  @override
  String get driverAssistanceTitle => 'බසයට නැගීමේ සහාය ඉල්ලීම්';

  @override
  String get driverAssistanceEmpty => 'මෙම බස් රථයට සක්‍රිය සහාය ඉල්ලීම් නැත.';

  @override
  String get driverBoardingAt => 'බසයට නැගීම';

  @override
  String get driverAlightingAt => 'බසයෙන් බැසීම';

  @override
  String driverStopPosition(int index, int total) {
    return 'වත්මන් ස්ථානය: නැවතුම් $totalන් $index';
  }

  @override
  String driverNextStop(String stop) {
    return 'ඊළඟ නැවතුම: $stop';
  }

  @override
  String driverArrivalSaved(String stop, String next) {
    return '$stop පැමිණීම සුරැකිණි. ඊළඟට: $next';
  }

  @override
  String driverFinalSaved(String stop) {
    return 'අවසන් $stop පැමිණීම සුරැකිණි. ගමන සම්පූර්ණයි.';
  }

  @override
  String driverTarget(String stop) {
    return 'ඉලක්කය: $stop';
  }

  @override
  String driverDestination(String stop) {
    return 'ගමනාන්තය: $stop';
  }

  @override
  String driverPlannedDeparture(String time) {
    return 'නියමිත පිටත්වීම (කොළඹ): $time';
  }

  @override
  String driverActualDeparture(String time) {
    return 'සැබෑ පිටත්වීම (කොළඹ): $time';
  }

  @override
  String driverBroadcastReason(String reason) {
    return 'මගීන්ට විකාශනය කළේ: $reason';
  }

  @override
  String driverAddedMinutes(int minutes) {
    return 'මගී පැමිණීමේ ඇස්තමේන්තුවලට විනාඩි +$minutesක් එක් කර ඇත';
  }

  @override
  String driverMinuteOption(int minutes) {
    return 'විනාඩි +$minutes';
  }

  @override
  String driverDelaySaved(String reason, int minutes) {
    return 'ප්‍රමාද දැනුම්දීම සුරැකිණි: $reason (විනාඩි +$minutes)';
  }

  @override
  String driverBroadcastDelay(int minutes) {
    return 'ප්‍රමාදය විකාශනය කරන්න (විනාඩි +$minutes)';
  }

  @override
  String driverDepartsIn(int minutes) {
    return 'විනාඩි $minutesකින් පිටත්වේ';
  }

  @override
  String driverLateMinutes(int minutes) {
    return 'විනාඩි $minutesක් ප්‍රමාදයි';
  }

  @override
  String driverScheduledDep(String time, String stop) {
    return 'නියමිත පිටත්වීම: $time ($stop)';
  }

  @override
  String driverEarlyMinutes(int minutes) {
    return 'වේලාවට පෙර ධාවනය වේ (විනාඩි $minutes)';
  }

  @override
  String driverLateShort(int minutes) {
    return 'විනාඩි +$minutesක් ප්‍රමාදයි';
  }

  @override
  String driverEarlyShort(int minutes) {
    return 'විනාඩි $minutesක් කලින්';
  }

  @override
  String driverBusOption(
    String bus,
    String time,
    String endpoints,
    String assigned,
  ) {
    return 'බස් $bus (පිටත්වීම: $time)$endpoints$assigned';
  }

  @override
  String driverRouteName(String route) {
    return 'මාර්ගය $route';
  }

  @override
  String driverDepartureTime(String time) {
    return 'පිටත්වීම: $time';
  }

  @override
  String driverStopCount(int count) {
    return 'නැවතුම් $count';
  }

  @override
  String driverActiveRequests(int count) {
    return 'සක්‍රිය $count';
  }

  @override
  String driverClosedRequests(int count) {
    return 'අවසන් කළ ඉල්ලීම් ($count)';
  }

  @override
  String driverRequestSummary(String rider, String stop, String types) {
    return '$stop හි $rider ($types)';
  }

  @override
  String driverAssistanceStop(String purpose, String stop) {
    return '$purpose: $stop';
  }

  @override
  String get driverEtaUnavailable => 'පැමිණීමේ ඇස්තමේන්තුව නොමැත';

  @override
  String get driverSchedulePassed => 'නියමිත වේලාව පසු වී ඇත';

  @override
  String get driverArrivingNow => 'දැන් ළඟා වේ';

  @override
  String driverScheduledFor(String time) {
    return '$timeට නියමිතයි';
  }

  @override
  String driverTomorrowAt(String time) {
    return 'හෙට $timeට';
  }

  @override
  String driverTomorrowIn(String time, int hours, int minutes) {
    return 'හෙට $timeට (පැය $hours විනාඩි $minutesකින්)';
  }

  @override
  String driverDepartedAgo(int minutes) {
    return 'විනාඩි $minutesකට පෙර පිටත්ව ඇත';
  }

  @override
  String driverArrivingMinutes(int minutes) {
    return 'විනාඩි $minutesකින් ළඟා වේ';
  }

  @override
  String driverArrivingHours(int hours, int minutes) {
    return 'පැය $hours විනාඩි $minutesකින් ළඟා වේ';
  }

  @override
  String get recoveryTitle => 'මුරපදය යළි සකසන්න';

  @override
  String get recoveryCheckEmail => 'ඔබේ විද්‍යුත් තැපෑල බලන්න';

  @override
  String get recoveryInboxHelp =>
      'නව මුරපදයක් සෑදීමට ඔබේ තැපැල් පෙට්ටියේ ඇති සබැඳිය භාවිත කරන්න.';

  @override
  String get recoveryBackLogin => 'පිවිසුමට ආපසු යන්න';

  @override
  String get recoveryResend => 'ඊමේල් නැවත යවන්න';

  @override
  String get recoveryForgot => 'මුරපදය අමතකද?';

  @override
  String get recoveryEmailHelp =>
      'ඔබේ ගිණුමේ විද්‍යුත් තැපැල් ලිපිනය ඇතුළත් කරන්න. මුරපදය යළි සැකසීමට උපදෙස් යවන්නෙමු.';

  @override
  String get recoveryEmail => 'විද්‍යුත් තැපැල් ලිපිනය';

  @override
  String get recoveryEmailHint => 'උදා: name@example.com';

  @override
  String get recoveryPrivacy => 'ඔබේ විද්‍යුත් තැපැල් ලිපිනය බෙදා නොගන්නෙමු.';

  @override
  String get recoverySend => 'යළි සැකසුම් සබැඳිය යවන්න';

  @override
  String get recoveryCreate => 'නව මුරපදයක් සාදන්න';

  @override
  String get recoveryPasswordHelp =>
      'ඔබ මීට පෙර භාවිත නොකළ ශක්තිමත් මුරපදයක් තෝරන්න.';

  @override
  String get recoveryNewPassword => 'නව මුරපදය';

  @override
  String get recoveryPasswordHint => 'නව මුරපදය ඇතුළත් කරන්න';

  @override
  String get recoveryConfirm => 'නව මුරපදය තහවුරු කරන්න';

  @override
  String get recoveryConfirmHint => 'නව මුරපදය නැවත ඇතුළත් කරන්න';

  @override
  String get recoveryShow => 'මුරපදය පෙන්වන්න';

  @override
  String get recoveryHide => 'මුරපදය සඟවන්න';

  @override
  String get recoverySecurity => 'ඔබේ ආරක්ෂාව අපගේ ප්‍රමුඛතාවයි.';

  @override
  String get recoveryUpdated => 'මුරපදය යාවත්කාලීන විය';

  @override
  String get recoverySuccess =>
      'ඔබේ මුරපදය යළි සැකසිණි. දැන් නව මුරපදයෙන් පිවිසිය හැක.';

  @override
  String get recoveryGoLogin => 'පිවිසුමට යන්න';

  @override
  String get recoveryEmailRequired =>
      'ඔබේ විද්‍යුත් තැපැල් ලිපිනය ඇතුළත් කරන්න.';

  @override
  String get recoveryEmailInvalid =>
      'වලංගු විද්‍යුත් තැපැල් ලිපිනයක් ඇතුළත් කරන්න.';

  @override
  String get recoveryAccountMissing =>
      'මෙම විද්‍යුත් තැපැල් ලිපිනයට ගිණුමක් හමු නොවීය.';

  @override
  String get recoveryDisabled => 'මෙම ගිණුම අක්‍රිය කර ඇත.';

  @override
  String get recoveryTooMany => 'ඉල්ලීම් වැඩියි. පසුව නැවත උත්සාහ කරන්න.';

  @override
  String get recoveryNetwork =>
      'ජාල දෝෂයකි. අන්තර්ජාල සම්බන්ධතාව පරීක්ෂා කරන්න.';

  @override
  String get recoverySendFailed =>
      'මුරපද යළි සැකසුම් ඊමේල් යැවීම තහවුරු කළ නොහැක.';

  @override
  String get recoveryResetFailed =>
      'මුරපදය යළි සැකසීම තහවුරු නොවීය. නැවත උත්සාහ කරන්න.';

  @override
  String get recoveryLinkUnavailable =>
      'මෙම සබැඳිය අවලංගු හෝ කල් ඉකුත් වී ඇත. අලුත් සබැඳියක් ඉල්ලන්න.';

  @override
  String get recoveryExpired =>
      'මෙම සබැඳිය කල් ඉකුත් වී ඇත. අලුත් සබැඳියක් ඉල්ලන්න.';

  @override
  String get recoveryInvalid => 'මෙම සබැඳිය අවලංගුයි. අලුත් සබැඳියක් ඉල්ලන්න.';

  @override
  String get recoveryWeak =>
      'මුරපදය ඉතා දුර්වලයි. වඩා ශක්තිමත් මුරපදයක් තෝරන්න.';

  @override
  String get recoveryCreateRequired => 'මුරපදයක් සාදන්න.';

  @override
  String get recoveryEightCharacters => 'මුරපදයේ අවම අක්ෂර 8ක් තිබිය යුතුයි.';

  @override
  String get recoveryLetterRequired => 'මුරපදයේ අවම එක් අකුරක් තිබිය යුතුයි.';

  @override
  String get recoveryNumberRequired => 'මුරපදයේ අවම එක් අංකයක් තිබිය යුතුයි.';

  @override
  String get recoveryConfirmRequired => 'මුරපදය තහවුරු කරන්න.';

  @override
  String get recoveryMismatch => 'මුරපද නොගැළපේ.';

  @override
  String get recoveryStrength => 'මුරපදයේ ශක්තිය';

  @override
  String get recoveryStrengthWeak => 'දුර්වලයි — තවත් අක්ෂර එක් කරන්න';

  @override
  String get recoveryStrengthFair => 'සාමාන්‍යයි — අංක හෝ සංකේත එක් කරන්න';

  @override
  String get recoveryStrengthGood => 'හොඳ ශක්තියක්';

  @override
  String get recoveryStrengthStrong => 'ශක්තිමත් මුරපදයකි';

  @override
  String recoveryInstructionsSent(String email) {
    return 'මුරපදය යළි සැකසීමේ උපදෙස් යැව්වේ\n$email';
  }

  @override
  String get homeMorning => 'සුබ උදෑසනක්';

  @override
  String get homeAfternoon => 'සුබ දහවලක්';

  @override
  String get homeEvening => 'සුබ සන්ධ්‍යාවක්';

  @override
  String get homeReady => 'ගමනට සූදානම්ද?';

  @override
  String get homeWhere => 'ඔබ කොහෙද යන්නේ?';

  @override
  String get homePlanHint => 'ගමන සැලසුම් කිරීමට තට්ටු කරන්න';

  @override
  String get homeMenu => 'මෙනුව විවෘත කරන්න';

  @override
  String get homeProfileAction => 'පැතිකඩ විවෘත කරන්න';

  @override
  String get homeTrack => 'බස්\nස්ථානය';

  @override
  String get homePlanAction => 'ගමන\nසැලසුම් කරන්න';

  @override
  String get homePreferencesAction => 'ප්‍රවේශතා\nමනාප';

  @override
  String get homeHome => 'මුල් පිටුව';

  @override
  String get homePlan => 'සැලසුම';

  @override
  String get homePlanJourney => 'ගමන සැලසුම් කරන්න';

  @override
  String get homeCommunity => 'ප්‍රජාව';

  @override
  String get homeProfile => 'පැතිකඩ';

  @override
  String get homeRewards => 'ත්‍යාග සහ දායකත්ව';

  @override
  String get homeHelp => 'උපකාර සහ සහාය';

  @override
  String get homeLogout => 'පිටවන්න';

  @override
  String get homeRecentReports => 'මෑත ප්‍රජා වාර්තා';

  @override
  String get homeNoReports => 'මෑත ප්‍රජා වාර්තා නැත.';

  @override
  String get homeReportsUnavailable =>
      'ප්‍රජා වාර්තා ලබාගත නොහැක. පසුව නැවත උත්සාහ කරන්න.';

  @override
  String get homeReport => 'වාර්තාව';

  @override
  String get homeRecentJourney => 'මෑත ගමන';

  @override
  String get homeNoJourney => 'සටහන් කළ ගමනක් නැත';

  @override
  String get homeStartPlanning => 'ගමනක් සැලසුම් කර අරඹන්න';

  @override
  String get homeJourneysLoading => 'මෑත ගමන පූරණය වෙමින්…';

  @override
  String get homeJourneysUnavailable => 'මෑත ගමන ලබාගත නොහැක';

  @override
  String get homeRetryLater => 'පසුව නැවත උත්සාහ කරන්න';

  @override
  String get homeOrigin => 'ආරම්භය';

  @override
  String get homeDestination => 'ගමනාන්තය';

  @override
  String get homeRecent => 'මෑතදී';

  @override
  String get homeReplan => 'නැවත සැලසුම් කරන්න';

  @override
  String get homeAssistance => 'සහාය';

  @override
  String get homeJustNow => 'දැන්ම';

  @override
  String get homeUnknownAge => 'නිරීක්ෂණ වේලාව නොමැත';

  @override
  String homeGreeting(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String homeTrueCount(int count) {
    return 'සත්‍ය: $count';
  }

  @override
  String homeFalseCount(int count, int threshold) {
    return 'අසත්‍ය: $count/$threshold';
  }

  @override
  String homeJourneySegment(String origin, String destination) {
    return '$origin සිට $destination දක්වා';
  }

  @override
  String homeMinutesAgo(int count) {
    return 'විනාඩි $countකට පෙර';
  }

  @override
  String homeHoursAgo(int count) {
    return 'පැය $countකට පෙර';
  }

  @override
  String homeDaysAgo(int count) {
    return 'දින $countකට පෙර';
  }

  @override
  String homeMonthsAgo(int count) {
    return 'මාස $countකට පෙර';
  }

  @override
  String get registrationTitle => 'ලියාපදිංචිය';

  @override
  String get registrationJoin => 'Access Transit සමඟ එක්වන්න';

  @override
  String get registrationIntro =>
      'සැමට ප්‍රවේශ විය හැකි ඔබේ ගමන මෙතැනින් ඇරඹේ.';

  @override
  String get registrationNameHint => 'සම්පූර්ණ නම ඇතුළත් කරන්න';

  @override
  String get registrationEmailHint => 'විද්‍යුත් තැපෑල ඇතුළත් කරන්න';

  @override
  String get registrationPassword => 'මුරපදය';

  @override
  String get registrationPasswordHint => 'මුරපදයක් සාදන්න';

  @override
  String get registrationConfirm => 'මුරපදය තහවුරු කරන්න';

  @override
  String get registrationConfirmHint => 'මුරපදය නැවත ඇතුළත් කරන්න';

  @override
  String get registrationNeeds => 'මට විශේෂ ප්‍රවේශතා අවශ්‍යතා ඇත';

  @override
  String get registrationNeedsExample =>
      '(උදා: රෝද පුටු බෑවුම් පුවරුව, පහත් බිම් බස් රථය)';

  @override
  String get registrationAccountType => 'ගිණුම් වර්ගය';

  @override
  String get registrationCreate => 'ගිණුම සාදන්න';

  @override
  String get registrationOr => 'හෝ';

  @override
  String get registrationGoogle => 'Google සමඟ ලියාපදිංචි වන්න';

  @override
  String get registrationApple => 'Apple සමඟ ලියාපදිංචි වන්න';

  @override
  String get registrationGoogleFeature => 'Google ලියාපදිංචිය';

  @override
  String get registrationAppleFeature => 'Apple ලියාපදිංචිය';

  @override
  String get registrationAlready => 'දැනටමත් ගිණුමක් තිබේද? ';

  @override
  String get registrationLogin => 'පිවිසෙන්න';

  @override
  String get registrationExists => 'මෙම විද්‍යුත් තැපෑලට දැනටමත් ගිණුමක් ඇත.';

  @override
  String get registrationNotEnabled =>
      'විද්‍යුත් තැපෑල/මුරපද පිවිසුම සක්‍රිය කර නැත.';

  @override
  String get registrationRequiredFields =>
      'සියලු අනිවාර්ය තොරතුරු නිවැරදිව ඇතුළත් කරන්න.';

  @override
  String get registrationFailed =>
      'ලියාපදිංචිය තහවුරු නොවීය. සම්බන්ධතාව පරීක්ෂා කර නැවත උත්සාහ කරන්න.';

  @override
  String get registrationNameRequired => 'සම්පූර්ණ නම ඇතුළත් කරන්න.';

  @override
  String get registrationNameShort => 'නමේ අවම අක්ෂර 2ක් තිබිය යුතුයි.';

  @override
  String get registrationNameLetters =>
      'නම සඳහා අකුරු, හිස්තැන්, තනි උද්ධෘත ලකුණු, තිත් හෝ යා ඉරි යොදන්න.';

  @override
  String get onboardingSkipTooltip => 'හැඳින්වීම මඟහරින්න';

  @override
  String get onboardingSkip => 'මඟහරින්න';

  @override
  String get onboardingStart => 'අරඹන්න';

  @override
  String get onboardingNext => 'ඊළඟට';

  @override
  String get onboardingTailored => 'ඔබට ගැළපෙන සේවාවක්';

  @override
  String get onboardingNeedsHelp =>
      'රෝද පුටු සහ පඩි රහිත අවශ්‍යතා තෝරා වත්මන් සාක්ෂි සමාලෝචනය කරන්න. හඬ මඟපෙන්වීම ලබාගත නොහැක.';

  @override
  String get onboardingNavigate => 'විශ්වාසයෙන් ගමන් කරන්න';

  @override
  String get onboardingLiveHelp =>
      'මෙය පෙරදසුනක් පමණි. හවුල් GPS තිබේ නම් පරීක්ෂා කරන්න; සහාය සඳහා රියදුරුගේ ප්‍රතිචාරය අවශ්‍යයි.';

  @override
  String get onboardingCommunity => 'ප්‍රජාවේ නෙත් වන්න';

  @override
  String get onboardingReportsHelp =>
      'බෑවුම් පුවරු සහ සෝපාන නිරීක්ෂණ බෙදාගන්න. උඩුගත කිරීම තහවුරු වූ පසු වාර්තා ප්‍රසිද්ධ වේ; ත්‍යාග සමාලෝචනයට යටත්ය.';

  @override
  String get onboardingReportIssue => 'ගැටලුව වාර්තා කරන්න';

  @override
  String get onboardingRamps => 'බෑවුම් පුවරු';

  @override
  String get onboardingLowFloor => 'පහත් බිම්';

  @override
  String get onboardingExampleEta => 'උදාහරණ පැමිණීම: විනාඩි 3';

  @override
  String get onboardingBoardingHelp => 'බසයට නැගීමේ සහාය';

  @override
  String get onboardingAwaitingReply => 'උදාහරණය: පිළිතුරක් බලාපොරොත්තුවෙන්';

  @override
  String get loginFailed => 'පිවිසීම තහවුරු නොවීය. නැවත උත්සාහ කරන්න.';

  @override
  String get loginInvalidCredentials =>
      'විද්‍යුත් තැපෑල හෝ මුරපදය වැරදියි. තොරතුරු පරීක්ෂා කර නැවත උත්සාහ කරන්න.';

  @override
  String get loginDisabled => 'මෙම ගිණුම අක්‍රිය කර ඇත. සහාය අමතන්න.';

  @override
  String get loginTooMany =>
      'පිවිසුම් උත්සාහ වැඩියි. මඳක් රැඳී නැවත උත්සාහ කරන්න.';

  @override
  String get loginNetwork =>
      'ජාල දෝෂයකි. සම්බන්ධතාව පරීක්ෂා කර නැවත උත්සාහ කරන්න.';

  @override
  String get loginForgot => 'මුරපදය අමතකද?';

  @override
  String get loginPasswordHint => 'මුරපදය ඇතුළත් කරන්න';

  @override
  String get loginPasswordRequired => 'මුරපදය ඇතුළත් කරන්න.';

  @override
  String get loginPasswordShort => 'මුරපදයේ අවම අක්ෂර 6ක් තිබිය යුතුයි.';

  @override
  String get loginOrContinue => 'නැතහොත් මෙයින් ඉදිරියට යන්න';

  @override
  String get loginBiometrics => 'ජෛවමිතික දත්ත සමඟ පිවිසෙන්න';

  @override
  String get loginBiometricFeature => 'ජෛවමිතික පිවිසුම';

  @override
  String get loginGoogle => 'Google සමඟ පිවිසෙන්න';

  @override
  String get loginGoogleFeature => 'Google පිවිසුම';

  @override
  String get loginNoAccount => 'ගිණුමක් නැද්ද?';

  @override
  String get loginSignUp => 'ලියාපදිංචි වන්න';

  @override
  String get settingsSaveFailed =>
      'මනාප සුරැකීම තහවුරු නොවීය. නැවත උත්සාහ කරන්න.';

  @override
  String get settingsGuestSaved =>
      'උපාංග සැකසුම් සුරැකිණි. ආගන්තුක ගමන් අවශ්‍යතා මෙම සැසියට පමණි.';

  @override
  String get settingsAccountSaved =>
      'මෙම උපාංගයේ මෙම ගිණුම සඳහා මනාප සුරැකිණි.';

  @override
  String get settingsProfile => 'පරිශීලක පැතිකඩ';

  @override
  String get settingsPersonalized => 'ඔබට ගැළපෙන ගමන් අත්දැකීම';

  @override
  String get settingsScopeHelp =>
      'ඉහළ ප්‍රතිවිරුද්ධ වර්ණ හා තට්ටු ඉලක්ක මෙම උපාංගයට අදාළයි. ගමන් අවශ්‍යතා මෙම උපාංගයේ එක් එක් පිවිසි ගිණුමට වෙනම සුරැකේ. ආගන්තුක අවශ්‍යතා මෙම සැසියට පමණි. නව ගිණුම් රෝද පුටු ප්‍රවේශය අවශ්‍ය ලෙස ඇරඹේ; ඔබේ අවශ්‍යතා සමාලෝචනය කරන්න.';

  @override
  String get settingsMobility => 'චලනය සහ භෞතික ප්‍රවේශය';

  @override
  String get settingsWheelchair => 'රෝද පුටු ප්‍රවේශය අවශ්‍යයි';

  @override
  String get settingsRampHelp =>
      'ගැළපෙන බස් සඳහා වත්මන් බෑවුම් පුවරු සාක්ෂි අවශ්‍යයි';

  @override
  String get settingsStepFree => 'පඩි රහිත මාර්ග පමණි';

  @override
  String get settingsStepFreeHelp =>
      'පඩි භාවිතය අවශ්‍ය නැවතුම් සහ පර්යන්ත මඟහරින්න';

  @override
  String get settingsWalking => 'ඇවිදින දුර අඩු කරන්න';

  @override
  String get settingsWalkingUnavailable =>
      'තවම ලබාගත නොහැක — ඇවිදින මාර්ග හා දුර මැන නැත';

  @override
  String get settingsSensory => 'සංවේදන සහ දෘශ්‍ය';

  @override
  String get settingsContrast => 'ඉහළ ප්‍රතිවිරුද්ධ වර්ණ';

  @override
  String get settingsContrastHelp =>
      'පාඨ පැහැදිලිකම සහ තද මායිම් වැඩි කරන්න (WCAG AAA)';

  @override
  String get settingsLargeTargets => 'විශාල තට්ටු ඉලක්ක (48dp+)';

  @override
  String get settingsTargetsHelp =>
      'බොත්තම් හා පාලන සඳහා අවම 48dp තට්ටු ඉලක්ක යොදන්න';

  @override
  String get settingsTargetsEnabled => 'විශාල තට්ටු ඉලක්ක (48dp+) සක්‍රියයි';

  @override
  String get settingsTargetsStandard => 'සාමාන්‍ය තට්ටු ඉලක්ක සක්‍රියයි';

  @override
  String get settingsVoice => 'ගමන් සඳහා හඬ මඟපෙන්වීම';

  @override
  String get settingsVoiceUnavailable =>
      'තවම ලබාගත නොහැක — අතුරුමුහුණත් පාඨ කියවීමට දුරකථනයේ තිර කියවනය භාවිත කරන්න';

  @override
  String get settingsHaptics => 'නැවතුම් සඳහා කම්පන දැනුම්දීම්';

  @override
  String get settingsHapticsUnavailable =>
      'තවම ලබාගත නොහැක — ස්වයංක්‍රීය කම්පන දැනුම්දීම් සඳහා සහාය නැත';

  @override
  String get settingsAssistance => 'සහාය සහ පරිසරය';

  @override
  String get settingsBoarding => 'බසයට නැගීමේ සහාය අවශ්‍යයි';

  @override
  String get settingsBoardingUnavailable =>
      'ස්වයංක්‍රීය ඉල්ලීම් තවම නොමැත — ගමන් තිරයෙන් සහාය ඉල්ලන්න';

  @override
  String get settingsQuiet => 'නිහඬ මාර්ග පෙන්වන්න';

  @override
  String get settingsQuietUnavailable => 'තවම ලබාගත නොහැක — ශබ්ද මට්ටම් නොදනී';

  @override
  String get settingsSave => 'මනාප සුරකින්න';

  @override
  String get searchSwapped => '⇄ නැගීමේ සහ ගමනාන්ත නැවතුම් මාරු කළා';

  @override
  String get searchSelectBoarding => 'නගින නැවතුම තෝරන්න';

  @override
  String get searchSelectDestination => 'බසින නැවතුම තෝරන්න';

  @override
  String get searchTravelChoice => 'ගමන් වේලාව තෝරන්න';

  @override
  String get searchLeaveNow => 'දැන් පිටත් වන්න';

  @override
  String get searchSpecificTime => 'වේලාවක් තෝරන්න';

  @override
  String get searchChooseTime => 'පිටත්වීමේ වේලාව තෝරන්න';

  @override
  String get searchChangeDate => 'ගමන් දිනය වෙනස් කරන්න';

  @override
  String get searchNeedsTitle => 'ප්‍රවේශ පහසුකම් අවශ්‍යතා';

  @override
  String get searchTemporaryHelp =>
      'මෙම ගමනට පමණක් වෙනස් කරන්න. Settings හි සුරැකි ප්‍රවේශ පහසුකම් මනාප වෙනස් නොවේ.';

  @override
  String get searchWheelchairChip => '♿ රෝද පුටුව';

  @override
  String get searchStepFreeChip => 'පඩි රහිත';

  @override
  String get searchResetHelp => 'සුරැකි ප්‍රවේශ පහසුකම් මනාප යළි යොදන්න';

  @override
  String get searchReset => 'යළි සකසන්න';

  @override
  String get searchRamp => 'රෝද පුටු බෑවුම';

  @override
  String get searchRampHelp => 'ක්‍රියාකාරී රෝද පුටු බෑවුම් ඇති බස් අවශ්‍යයි';

  @override
  String get searchStepFree => 'නැවතුමට පඩි රහිත ප්‍රවේශය';

  @override
  String get searchStepFreeHelp =>
      'විදුලි සෝපාන හෝ සමතලා මාර්ග ඇති නැවතුම් පමණක්';

  @override
  String get searchMinWalking => 'ඇවිදින දුර අඩු කරන්න';

  @override
  String get searchWalkingUnknown => 'තවම නොමැත — ඇවිදින දුර නොදනී';

  @override
  String get searchApply => 'මෙම ගමනට යොදන්න';

  @override
  String get searchEndpointsRequired => 'නගින සහ බසින නැවතුම් තෝරන්න.';

  @override
  String get searchEndpointsDifferent => 'නගින සහ බසින නැවතුම් එකම විය නොහැක.';

  @override
  String get searchRampRequired => 'රෝද පුටු බෑවුම අවශ්‍යයි';

  @override
  String get searchStepFreeFilter => 'පඩි රහිත';

  @override
  String get searchMinWalkFilter => 'අඩු ඇවිදීම';

  @override
  String get searchFind => 'බස් සොයන්න';

  @override
  String get searchNoStops =>
      'හවුල් නැවතුම් දත්ත නොමැත. සම්බන්ධ වී යළි උත්සාහ කරන්න.';

  @override
  String get searchPlan => 'ගමන සැලසුම් කරන්න';

  @override
  String get searchSync => 'බස් දත්ත නැවත ලබාගන්න';

  @override
  String get searchBoardingHeading => 'නගින නැවතුම';

  @override
  String get searchChooseBoarding => 'නගින නැවතුම තෝරන්න';

  @override
  String get searchRampAvailable => '♿ රෝද පුටු බෑවුම ඇත';

  @override
  String get searchStandardStop => 'සාමාන්‍ය නැවතුම';

  @override
  String get searchTapBoarding => 'නගින නැවතුම තෝරන්න';

  @override
  String get searchSwap => 'නගින සහ බසින නැවතුම් මාරු කරන්න';

  @override
  String get searchDestinationHeading => 'ඔබ යන්නේ කොහේද?';

  @override
  String get searchChooseDestination => 'ගමනාන්තය තෝරන්න';

  @override
  String get searchAccessibleDestination => '♿ ප්‍රවේශ පහසුකම් සහිත ගමනාන්තය';

  @override
  String get searchTapDestination => 'බසින නැවතුම තෝරන්න';

  @override
  String get searchMyLocation => 'මගේ ස්ථානය';

  @override
  String get searchBoardingSuggestions => 'නගින නැවතුම් යෝජනා';

  @override
  String get searchDestinationSuggestions => 'බසින නැවතුම් යෝජනා';

  @override
  String get searchSuggestions => 'නැවතුම් යෝජනා බලන්න';

  @override
  String get searchDepartNow => 'දැන් පිටත් වන්න';

  @override
  String get searchTravelHeading => 'ගමන් වේලාව';

  @override
  String get searchChange => 'වෙනස් කරන්න';

  @override
  String get searchOptions => 'ප්‍රවේශ පහසුකම්';

  @override
  String get searchConfigure => 'සකසන්න';

  @override
  String get searchAllBusesHelp =>
      'සියලු බස් පෙන්වයි. රෝද පුටු බෑවුම් හෝ පඩි රහිත ප්‍රවේශය අවශ්‍ය නම් සකසන්න.';

  @override
  String get searchStationHint =>
      'නැවතුම හෝ නගරය ලියන්න (උදා: Pettah, Mount Lavinia)...';

  @override
  String get searchAllStops => 'සියලු නැවතුම්';

  @override
  String get searchNoMatches =>
      'ගැළපෙන නැවතුම් නැත.\nවෙනත් අක්ෂර වින්‍යාසයක් යොදන්න හෝ පෙරහන් ඉවත් කරන්න.';

  @override
  String get searchRampBadge => 'බෑවුම  ';

  @override
  String get searchElevatorBadge => 'සෝපානය  ';

  @override
  String get searchSuggestionIcon => 'නැවතුම් යෝජනා';

  @override
  String get searchSuggestedBoarding => 'නගින නැවතුම් යෝජනා';

  @override
  String get searchSuggestedDestination => 'බසින නැවතුම් යෝජනා';

  @override
  String get searchVoiceUnavailable =>
      'හඬ හඳුනාගැනීම තවම නොමැත. පහත නැවතුමක් තෝරන්න:';

  @override
  String searchSelectedTime(String time) {
    return 'තේරූ වේලාව: $time';
  }

  @override
  String searchTodayAt(String time) {
    return 'අද $time';
  }

  @override
  String searchDateAt(String date, String time) {
    return '$date දින $time';
  }

  @override
  String searchStopSelected(String name) {
    return 'තේරූ නැවතුම: $name';
  }

  @override
  String searchActiveNeeds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'සක්‍රිය $count',
      one: 'සක්‍රිය 1',
    );
    return '$_temp0';
  }

  @override
  String get resultsScheduled => 'කාලසටහන අනුව';

  @override
  String get resultsPastUnconfirmed =>
      'නියමිත වේලාව පසු වී ඇත — පිටත්වීම තහවුරු නැත';

  @override
  String get resultsNowUnconfirmed => 'නියමිත වේලාව දැන් — පිටත්වීම තහවුරු නැත';

  @override
  String get resultsRampReady => 'රෝද පුටු බෑවුම සූදානම් · පඩි රහිත පිවිසුම';

  @override
  String get resultsRampEquipped => 'බෑවුම සවි කර ඇත · රියදුරු සහාය විමසන්න';

  @override
  String get resultsStandardService => 'සාමාන්‍ය බස් සේවාව';

  @override
  String get resultsUnknown => 'නොදනී';

  @override
  String get resultsLow => 'අඩු';

  @override
  String get resultsMedium => 'මධ්‍යම';

  @override
  String get resultsHigh => 'වැඩි';

  @override
  String get resultsStarted => 'ආරම්භ කළ ධාවනය';

  @override
  String get resultsDemoTimetable => 'ආදර්ශ කාලසටහන';

  @override
  String get resultsPublishedTimetable => 'ප්‍රකාශිත කාලසටහන';

  @override
  String get resultsWheelchairBus => 'රෝද පුටු ප්‍රවේශ පහසුකම් ඇති බසය';

  @override
  String get resultsRampBus => 'බෑවුම සහිත සාමාන්‍ය බසය';

  @override
  String get resultsStandardBus => 'සාමාන්‍ය බසය';

  @override
  String get resultsEstimatedTimes =>
      'සමහර වේලාවන් ඇස්තමේන්තුය; රියදුරුගෙන් තහවුරු කරන්න.';

  @override
  String get resultsWalkingUnknown =>
      'මෙම ගමනේ ඇවිදින දුර නොමැත. ප්‍රතිඵල ඇවිදින දුර අනුව පෙළගස්වා නැත.';

  @override
  String get resultsReviewNeeds => 'ගමනේ අවශ්‍යතා සමාලෝචනය කරන්න';

  @override
  String get resultsReviewHelp =>
      'වෙනස්කම් මෙම සෙවුමට පමණි. අවශ්‍යතාවක් ඉවත් කළ විට ප්‍රවේශය නොදන්නා හෝ බාධා වාර්තා වූ සේවා පෙන්විය හැක. ගමන තේරීමට පෙර සාක්ෂි බලන්න.';

  @override
  String get resultsKeepNeeds => 'අවශ්‍යතා තබාගන්න';

  @override
  String get resultsApplyNeeds => 'මෙම සෙවුමට යොදන්න';

  @override
  String get resultsNoAccessible => 'ප්‍රවේශ අවශ්‍යතා සපුරන බස් හමු නොවීය';

  @override
  String get resultsNoDirect => 'සෘජු බස් හමු නොවීය';

  @override
  String get resultsNoAccessibleHelp =>
      'මෙම අවශ්‍යතාවලට ගැළපෙන තහවුරු කළ ප්‍රවේශ පහසුකම් ඇති නියමිත ගමන් නැත. නැවතුම් ප්‍රවේශය නොදන්නා හෝ බාධාවක් වාර්තා වී තිබිය හැක. ප්‍රවේශ පෙරහන් සමාලෝචනය කරන්න.';

  @override
  String get resultsShowAll => 'ගැළපෙන සියලු බස් පෙන්වන්න';

  @override
  String get resultsShowAllHelp =>
      'ප්‍රවේශය නොදන්නා හෝ බාධා වාර්තා වූ සේවා ඇතුළුව Accessible tab එකෙන් පිටත විකල්ප පෙන්වයි. ඔබේ ගමන් අවශ්‍යතා දිගටම යෙදේ.';

  @override
  String get resultsTitle => 'ලබාගත හැකි බස්';

  @override
  String get resultsChooseHelp => 'විස්තර බැලීමට බසයක් තෝරන්න';

  @override
  String get resultsFastest => 'වේගවත්ම';

  @override
  String get resultsRoute => 'මාර්ගය';

  @override
  String get resultsTimetableHelp =>
      'කාලසටහන් ඇස්තමේන්තු — පිටත්වීම තහවුරු නැත. GPS තත්ත්වය සඳහා බස් විස්තර බලන්න.';

  @override
  String get resultsDeparture => 'පිටත්වීම';

  @override
  String get resultsArrival => 'පැමිණීම';

  @override
  String get resultsRampAvailable => 'බෑවුම ඇත';

  @override
  String get resultsLowFloor => 'පහත් බිම';

  @override
  String get detailsAmbiguous => 'පිටත්වීම නිශ්චිත නැත. තේරීම නැවත ලබාගන්න.';

  @override
  String get detailsAccountChanged => 'ගිණුම වෙනස් විය. සෙවුමට ආපසු යන්න.';

  @override
  String get detailsUnavailable => 'සේවාව නොමැත. යළි උත්සාහ කරන්න';

  @override
  String get detailsRunUnavailable => 'ධාවන තත්ත්වය නොමැත';

  @override
  String get detailsRunUnverified => 'කාලසටහන අනුව · ධාවනය තහවුරු නැත';

  @override
  String get detailsCompleted => 'අවසන්';

  @override
  String get detailsCancelled => 'අවලංගුයි';

  @override
  String get detailsStale => 'ස්ථානය නොමැත හෝ පැරණියි';

  @override
  String get detailsLive => 'සජීවී GPS';

  @override
  String get detailsWheelchair => 'රෝද පුටු ප්‍රවේශය';

  @override
  String get detailsSavedHelp =>
      'සුරැකි තේරීම · වේලාවන් හා අවශ්‍යතා තබා ඇත; වත්මන් තත්ත්වයන් බලන්න.';

  @override
  String get detailsDefaultsDiffer =>
      'වත්මන් ප්‍රවේශ මනාප මෙම සුරැකි තේරීමට වෙනස්ය.';

  @override
  String get detailsCatalogueUnavailable => 'නාමාවලි යාවත්කාලීන නොමැත.';

  @override
  String get detailsStops => 'ඔබේ ගමනේ නැවතුම්';

  @override
  String get detailsIntermediateUnknown => 'අතරමැදි නැවතුම · වේලාව නොමැත';

  @override
  String get detailsEvidence => 'ප්‍රවේශ පහසුකම් පිළිබඳ සාක්ෂි';

  @override
  String get detailsAssistanceUnavailable => 'රියදුරු සහාය නොමැත';

  @override
  String get detailsReport => 'තත්ත්වයක් වාර්තා කරන්න';

  @override
  String get detailsLoadingReports => 'වාර්තා ලබාගනිමින්…';

  @override
  String get detailsRetry => 'යාවත්කාලීන නැවත උත්සාහ කරන්න';

  @override
  String get detailsVerifySave =>
      'සුරැකීමට පෙර සම්බන්ධ වී මෙම පිටත්වීම තහවුරු කරන්න.';

  @override
  String get resultsSafe => 'ප්‍රවේශ සාක්ෂි ගැළපේ';

  @override
  String get resultsWarning => 'සැලකිලිමත් වන්න';

  @override
  String get resultsNotAccessible => 'ප්‍රවේශ පහසුකම් නොගැළපේ';

  @override
  String get detailsResolved => 'විසඳා ඇත';

  @override
  String get detailsRecheckUnknown =>
      'නොවිසඳුණු බාධාවක් — නිරීක්ෂණ වේලාව නොදනී; නැවත පරීක්ෂා කරන්න';

  @override
  String get detailsObservationUnknown => 'නිරීක්ෂණ වේලාව නොදනී';

  @override
  String get detailsExpired => 'කල් ඉකුත් වී හෝ නොමැත';

  @override
  String get detailsRecheck => 'නොවිසඳුණු බාධාවක් — නැවත පරීක්ෂා කරන්න';

  @override
  String get detailsRecent => 'මෑත නිරීක්ෂණය';

  @override
  String resultsRouteNumber(String number) {
    return 'මාර්ගය $number';
  }

  @override
  String resultsScheduledDate(String date, String time) {
    return 'නියමිත: $date, $time';
  }

  @override
  String resultsScheduledAt(String date, String time) {
    return 'නියමිත: $date දින $time';
  }

  @override
  String resultsTomorrow(String time) {
    return 'හෙට නියමිත: $time';
  }

  @override
  String resultsTomorrowAt(String time) {
    return 'හෙට නියමිත වේලාව $time';
  }

  @override
  String resultsToday(String time) {
    return 'අද නියමිත: $time';
  }

  @override
  String resultsTodayAt(String time) {
    return 'අද නියමිත වේලාව $time';
  }

  @override
  String resultsScheduledIn(int minutes, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'මිනිත්තු $minutesකින් නියමිතයි - $time',
      one: 'මිනිත්තු 1කින් නියමිතයි - $time',
    );
    return '$_temp0';
  }

  @override
  String resultsBoardingEstimate(String time, String source) {
    return 'නැගීමේ ඇස්තමේන්තුව $time · $source';
  }

  @override
  String resultsCountTitle(int count) {
    return 'ලබාගත හැකි බස් ($count)';
  }

  @override
  String resultsAvailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'බස් $countක් ඇත',
      one: 'බස් 1ක් ඇත',
    );
    return '$_temp0';
  }

  @override
  String resultsNoDirectHelp(String origin, String destination) {
    return 'දැනට $origin සිට $destination දක්වා සෘජු බස් මාර්ග නැත.';
  }

  @override
  String resultsAllTab(int count) {
    return 'සියල්ල ($count)';
  }

  @override
  String resultsAccessibleTab(int count) {
    return 'ප්‍රවේශ පහසුකම් ($count)';
  }

  @override
  String resultsDuration(int minutes) {
    return '~මිනිත්තු $minutes';
  }

  @override
  String resultsCrowd(String level) {
    return 'මගී තදබදය: $level';
  }

  @override
  String resultsBoardingSource(String source) {
    return 'නැගීමේ ඇස්තමේන්තුව · $source';
  }

  @override
  String detailsBoardingAt(String date, String time) {
    return 'නියමිත නැගීම: $date · $time';
  }

  @override
  String detailsArrivalAt(String date, String time) {
    return 'නියමිත පැමිණීම: $date · $time';
  }

  @override
  String detailsDuration(int minutes) {
    return 'මිනිත්තු $minutes · තෝරාගත් ගමන් කොටස';
  }

  @override
  String detailsBoardHere(String time) {
    return 'මෙතැනින් නගින්න · $time';
  }

  @override
  String detailsAlightHere(String time) {
    return 'මෙතැනින් බසින්න · $time';
  }

  @override
  String detailsScheduledStop(String time) {
    return 'නියමිත $time';
  }

  @override
  String detailsNextStop(String name) {
    return 'ගමනේ ඊළඟ නැවතුම: $name';
  }

  @override
  String get resultsSourceDated => 'දින නියමිත කාලසටහන';

  @override
  String get resultsSourceRoad => 'මාර්ග ප්‍රගතිය + කාලසටහන (අඩු විශ්වාසය)';

  @override
  String get resultsSourceBoarding => 'නගින නැවතුමේ GPS';

  @override
  String get resultsSourceInterval =>
      'GPS නිරීක්ෂිත නැවතුමේ සිට කාලසටහන් කාල පරතරය';

  @override
  String get evidenceRecheckSummary => 'නොවිසඳුණු බාධාවක් - නැවත පරීක්ෂා කරන්න';

  @override
  String get evidenceBarrierSummary => 'බාධාවක් වාර්තා වී ඇත - ගමනට පෙර බලන්න';

  @override
  String get evidencePositiveSummary => 'ධනාත්මක නිරීක්ෂණයක් - විස්තර බලන්න';

  @override
  String get evidenceUnknownSummary => 'නොදනී - වත්මන් නිරීක්ෂණයක් නැත';

  @override
  String get evidenceTimeUnknown => 'නොදනී - නිරීක්ෂණ වේලාව නොමැත';

  @override
  String get evidenceExpired => 'නොදනී — අවසන් නිරීක්ෂණයේ කාලය ඉකුත් වී ඇත';

  @override
  String get evidenceRecheckUnknown =>
      'නොවිසඳුණු බාධාවක් — නැවත පරීක්ෂා කරන්න; වත්මන් තත්ත්වය නොදනී';

  @override
  String get evidenceConditionUnknown => 'නොදනී — තත්ත්වය නිශ්චය කළ නොහැකි විය';

  @override
  String get evidenceBarrierConfirmed =>
      'බාධාවක් — ප්‍රජාව තහවුරු කළ නිරීක්ෂණය';

  @override
  String get evidencePositiveConfirmed =>
      'ධනාත්මක — ප්‍රජාව තහවුරු කළ නිරීක්ෂණය';

  @override
  String get evidenceBarrierUnverified =>
      'බාධාවක් වාර්තා වී ඇත — තහවුරු කිරීම නොදනී';

  @override
  String get evidencePositiveUnverified =>
      'ධනාත්මක තත්ත්වයක් වාර්තා වී ඇත — තහවුරු කිරීම නොදනී';

  @override
  String get evidenceNoConfirmationTime => 'තහවුරු කළ වේලාව: නොදනී';

  @override
  String get evidenceVehicleSection => 'බසයේ බෑවුමේ තත්ත්වයන්';

  @override
  String get evidenceBoardingSection => 'නගින නැවතුමේ තත්ත්වයන්';

  @override
  String get evidenceDestinationSection => 'බසින නැවතුමේ තත්ත්වයන්';

  @override
  String get evidenceAssistanceSection => 'රියදුරු සහාය පිළිබඳ නිරීක්ෂණ';

  @override
  String get evidenceDisclosure =>
      'ප්‍රජා නිරීක්ෂණ විශේෂිත තත්ත්වයන් විස්තර කරයි; මුළු ගමනම තහවුරු නොකරයි.';

  @override
  String get evidenceEmpty => 'නොදනී — නිරීක්ෂණයක් නොමැත';

  @override
  String get evidenceMember => 'ප්‍රජා සාමාජිකයෙක්';

  @override
  String get rampWorkingObserved => 'ක්‍රියාකාරී බව නිරීක්ෂණය කර ඇත';

  @override
  String get rampBrokenUnresolved => 'දෝෂයක් වාර්තා වී ඇත - නොවිසඳුණු අවදානමක්';

  @override
  String get rampNewCheck => 'නොදනී - නව පරීක්ෂාවක් අවශ්‍යයි';

  @override
  String get rampEquipped => 'සවි කර ඇත';

  @override
  String get rampNotListed => 'ලැයිස්තුගත කර නැත';

  @override
  String get rampTitle => 'බසයේ බෑවුම';

  @override
  String get rampOperatorSource => 'රියදුරු නිරීක්ෂණය';

  @override
  String get rampBarrierDisclosure =>
      'ක්‍රියාකාරී බවට නිරීක්ෂණයක් තිබීමෙන් පවතින ප්‍රජා බාධා විසඳී ඇතැයි අදහස් නොවේ.';

  @override
  String get mapMissingCoordinates =>
      'සිතියම නොමැත · නැවතුම් ඛණ්ඩාංක සමාලෝචනය කර නැත. නැවතුම් ලැයිස්තුව භාවිත කරන්න.';

  @override
  String get mapCurrentBus => 'බසයේ වත්මන් ස්ථානය';

  @override
  String get mapNoRoadGeometry =>
      'නැවතුම් ස්ථාන · මාර්ගයේ ජ්‍යාමිතික දත්ත නොමැත';

  @override
  String get mapTileRetry =>
      'සිතියම් කොටස් නොමැත · යළි උත්සාහ කරන්න හෝ නැවතුම් ලැයිස්තුව බලන්න';

  @override
  String get timetableUnassigned => 'ප්‍රකාශිත කාලසටහන • බසයක් පවරා නැත';

  @override
  String get timetableUnknownDisclosure =>
      'වේලාවන් වෙනස් විය හැක. බස් ලියාපදිංචිය, ප්‍රවේශ පහසුකම් සහ සජීවී ස්ථානය නොදනී. අවසරලත් බසයක් සම්බන්ධ කරන තුරු රියදුරු සහාය නොමැත.';

  @override
  String evidenceCheckedAt(String time) {
    return 'අවසන් පරීක්ෂාව: $time';
  }

  @override
  String evidenceRecheckedAt(String time, String name) {
    return 'අවසන් නැවත පරීක්ෂාව: $time, $name විසින්. අනන්‍ය තහවුරු කිරීම් වෙනස් වී නැත.';
  }

  @override
  String evidenceDueAt(String time) {
    return 'නැවත පරීක්ෂා කළ යුතු වේලාව: $time';
  }

  @override
  String evidenceExpiresAt(String time) {
    return 'නිරීක්ෂණය කල් ඉකුත් වන වේලාව: $time';
  }

  @override
  String evidenceReportedAt(String time) {
    return 'වාර්තා කළ වේලාව: $time';
  }

  @override
  String evidenceConfirmedAt(String time) {
    return 'අවසන් තහවුරු කිරීම සටහන් කළ වේලාව: $time';
  }

  @override
  String evidenceReporter(String name) {
    return 'වාර්තා කළේ: $name';
  }

  @override
  String evidenceConfirmers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'තහවුරු කළේ: ප්‍රජා සාමාජිකයන් $countයි',
      one: 'තහවුරු කළේ: ප්‍රජා සාමාජිකයන් 1යි',
    );
    return '$_temp0';
  }

  @override
  String rampCapability(String capability) {
    return 'බෑවුම සවි කර තිබීම: $capability';
  }

  @override
  String rampCheckedAge(String age) {
    return 'බෑවුමේ අවසන් පරීක්ෂාව: $age';
  }

  @override
  String rampSource(String source) {
    return 'බෑවුම් නිරීක්ෂණයේ මූලාශ්‍රය: $source';
  }

  @override
  String rampRecordedAt(String time) {
    return 'පරීක්ෂාව සටහන් කළ වේලාව: $time';
  }

  @override
  String mapUpdatedAt(String time) {
    return 'ස්ථානය යාවත්කාලීන කළේ: $time';
  }

  @override
  String timetableSource(String source) {
    return 'මූලාශ්‍රය: $source';
  }

  @override
  String get reportSignInChange => 'හවුල් වාර්තාව වෙනස් කිරීමට පෙර පිවිසෙන්න.';

  @override
  String get reportChangeUnconfirmed =>
      'වෙනස තහවුරු නැත. සම්බන්ධතාව සහ පිවිසීම පරීක්ෂා කර යළි උත්සාහ කරන්න හෝ වාර්තාව නැවත ලබාගන්න.';

  @override
  String get reportCopied => 'දැනුම්දීමේ පෙළ පිටපත් කළා!';

  @override
  String get reportCopyFailed =>
      'දැනුම්දීම පිටපත් කළ නොහැකි විය. යළි උත්සාහ කරන්න.';

  @override
  String get reportImageUnavailable => 'ඡායාරූප පෙරදසුන නොමැත';

  @override
  String get reportDetailsTitle => 'වාර්තා විස්තර';

  @override
  String get reportRemoved =>
      'හවුල් වාර්තාව නොමැත හෝ ඉවත් කර ඇත. යාවත්කාලීන කිරීමට feed එක නැවත විවෘත කරන්න.';

  @override
  String get reportShare => 'දැනුම්දීම බෙදාගන්න';

  @override
  String get reportStaleUpdates =>
      'හවුල් යාවත්කාලීන නොමැත. අවසන් වරට ලැබුණු නිරීක්ෂණය පෙන්වයි; ක්‍රියා කිරීමට පෙර නැවත ලබාගන්න.';

  @override
  String get reportSignInActions =>
      'හවුල් වාර්තා තහවුරු කිරීමට, සලකුණු කිරීමට හෝ විසඳුම සටහන් කිරීමට පිවිසෙන්න.';

  @override
  String get reportResolutionDisclosure =>
      'විසඳුම කර්තෘ සටහන් කළ නිරීක්ෂණයකි; එය අලුත්වැඩියාවක් ස්වාධීනව තහවුරු නොකරයි.';

  @override
  String get reportResolutionUnknown => 'විසඳුම සටහන් කළ වේලාව: නොදනී';

  @override
  String get reportResolvedTitle => 'විසඳූ බව සටහන් කර ඇත';

  @override
  String get reportResolvedHelp => 'කර්තෘ මෙම තත්ත්වය විසඳූ බව සටහන් කර ඇත.';

  @override
  String get reportObservationUnknown => 'නිරීක්ෂණ වේලාව නොදනී';

  @override
  String get reportUnknownHelp =>
      'නිරීක්ෂණ දිනය නොමැත. වත්මන් තත්ත්වය තහවුරු කළ නොහැක.';

  @override
  String get reportConfirmedTitle => 'ප්‍රජාව තහවුරු කළ නිරීක්ෂණය';

  @override
  String get reportActiveTitle => 'ක්‍රියාත්මක ගමනාගමන වාර්තාව';

  @override
  String get reportActiveHelp =>
      'මගියකු වාර්තා කර ඇත. නිරීක්ෂණ වේලාව සහ වත්මන් සාක්ෂි බලන්න.';

  @override
  String get reportExpiredTitle => 'පැරණි වාර්තාව (කල් ඉකුත් වී ඇත)';

  @override
  String get reportExpiredHelp =>
      'මෙම නිරීක්ෂණය කල් ඉකුත් වී ඇත; එය වත්මන් තත්ත්වය තහවුරු නොකරයි.';

  @override
  String get reportYours => 'ඔබේ වාර්තාව';

  @override
  String get reportBus => 'බසය';

  @override
  String get reportStation => 'නැවතුම';

  @override
  String get reportHighSeverity => 'බරපතළ';

  @override
  String get reportMinorSeverity => 'සුළු ගැටලුවක්';

  @override
  String get reportModerateSeverity => 'මධ්‍යස්ථ';

  @override
  String get reportConditionDetails => 'වාර්තා කළ තත්ත්වයේ විස්තර';

  @override
  String get reportRiderNote => 'මගියාගේ සටහන:';

  @override
  String get reportPhotoEvidence => 'අමුණා ඇති ඡායාරූප සාක්ෂි';

  @override
  String get reportEnlarge => 'විශාල කිරීමට තට්ටු කරන්න';

  @override
  String get reportPhotoUnavailable => 'ඡායාරූපය නොමැත';

  @override
  String get reportMetrics => 'ප්‍රජා තහවුරු කිරීම් සහ සලකුණු';

  @override
  String get reportRecheckDisclosure =>
      'නැවත පරීක්ෂා කිරීම් දින සහිත නිරීක්ෂණ වේ; අනන්‍ය තහවුරු කිරීම් වෙනස් නොවේ.';

  @override
  String get reportVoteHeading => 'වාර්තාවේ නිරවද්‍යතාවට ඡන්දය දෙන්න';

  @override
  String get reportRecheckAction => 'තත්ත්වය නැවත පරීක්ෂා කරන්න';

  @override
  String get reportFixed => 'විසඳූ බව සලකුණු කර ඇත';

  @override
  String get reportResolveAction => 'තත්ත්වය විසඳූ බව සටහන් කරන්න';

  @override
  String get reportRampCategory => 'බෑවුම සහ ප්‍රවේශය';

  @override
  String get reportLiftCategory => 'විදුලි සෝපානය';

  @override
  String get reportCrowdingCategory => 'මගී තදබදය';

  @override
  String get reportCleanCategory => 'පිරිසිදුකම';

  @override
  String get reportSafetyCategory => 'ආරක්ෂාවට අවදානමක්';

  @override
  String get deliveryTitle => 'වාර්තාව යැවීම';

  @override
  String get deliveryStatus => 'ප්‍රකාශන තත්ත්වය';

  @override
  String get deliveryDraftUnavailable => 'කෙටුම්පත නොමැත';

  @override
  String get deliveryPublished => 'ප්‍රකාශිතයි';

  @override
  String get deliveryPending => 'යැවීමට රැඳී ඇත';

  @override
  String get deliveryFailed => 'අසාර්ථකයි';

  @override
  String get deliveryPublicHelp => 'ඔබේ වාර්තාව අනෙක් මගීන්ට දැකිය හැක.';

  @override
  String get deliveryRemovedHelp =>
      'මෙම කෙටුම්පත ඉවත් කර ඇත, කල් ඉකුත් වී ඇත හෝ වෙනත් ගිණුමකට අයත්ය. ප්‍රකාශනය තහවුරු වී නැත.';

  @override
  String get deliveryPendingHelp =>
      'මෙම උපාංගයේ සුරැකිණි. ප්‍රකාශනය තහවුරු වී නැත.';

  @override
  String get deliveryLocalUnavailable => 'උපාංගයේ කෙටුම්පත නොමැත';

  @override
  String get deliveryObservation => 'ඔබේ නිරීක්ෂණය';

  @override
  String get deliveryTarget => 'ස්ථානය / බසය';

  @override
  String get deliveryCondition => 'වාර්තා කළ තත්ත්වය';

  @override
  String get deliveryPhoto => 'අමුණා ඇති ඡායාරූපය';

  @override
  String get deliveryPhotoUnavailable => 'ඡායාරූප පෙරදසුන නොමැත';

  @override
  String get deliveryUploading => 'යවමින්…';

  @override
  String get deliveryRetry => 'නැවත යවන්න';

  @override
  String get deliveryRemoveDevice => 'මෙම උපාංගයෙන් කෙටුම්පත ඉවත් කරන්න';

  @override
  String get deliveryAboutDrafts => 'උපාංගයේ කෙටුම්පත් ගැන';

  @override
  String get deliveryDraftExpiry =>
      'කෙටුම්පත් දින 7කින් කල් ඉකුත් වන අතර පිටවීමේදී හෝ ගිණුම මාරු කිරීමේදී ඉවත් වේ.';

  @override
  String get deliveryViewFeed => 'ප්‍රජා වාර්තා බලන්න';

  @override
  String get deliveryHome => 'මුල් පිටුවට යන්න';

  @override
  String get deliverySaveFailed =>
      'යැවීමේ තත්ත්වය සුරැකිය නොහැකි විය. යළි උත්සාහ කරන්න.';

  @override
  String get deliveryRemoveQuestion => 'උපාංගයේ කෙටුම්පත ඉවත් කරන්නද?';

  @override
  String get deliveryRemoveHelp =>
      'ඉදිරි නැවත යැවීම් නවතා උපාංගයේ සටහන/ඡායාරූපය ඉවත් කරයි. දැනටමත් යැවූ ඉල්ලීමක් අවසන් විය හැක. මෙය ප්‍රසිද්ධ වාර්තාවක් හෝ යැවූ ඡායාරූපයක් මකා නොදමයි.';

  @override
  String get deliveryKeep => 'කෙටුම්පත තබාගන්න';

  @override
  String get deliveryRemove => 'කෙටුම්පත ඉවත් කරන්න';

  @override
  String get deliveryRemoveFailed =>
      'උපාංගයෙන් ඉවත් කිරීම සුරැකිය නොහැකි විය. යළි උත්සාහ කරන්න.';

  @override
  String get deliveryUnknownTime =>
      'නිරීක්ෂණ වේලාව නොදනී. යැවීමට පෙර නව වාර්තාවක් සාදන්න.';

  @override
  String get deliveryWaiting =>
      'සම්බන්ධතාවක් සඳහා රැඳී ඇත. මෙම වාර්තාව ප්‍රකාශිත බව තහවුරු නැත.';

  @override
  String get deliveryUploadFailed =>
      'යැවීම අසාර්ථකයි. පිවිසීම, ඡායාරූපය සහ සේවා ප්‍රවේශය පරීක්ෂා කර යළි උත්සාහ කරන්න.';

  @override
  String get reportAlreadySaved => 'මෙම ක්‍රියාව දැනටමත් සටහන් කර ඇත.';

  @override
  String get reportWaitRecheck =>
      'නැවත පරීක්ෂාව සුරැකී නැත. අවසන් පරීක්ෂාවෙන් මිනිත්තු 30කට පසු යළි උත්සාහ කරන්න.';

  @override
  String get reportChangeSaved =>
      'වෙනස සුරැකිණි. සම්බන්ධ වූ විට හවුල් විස්තර යාවත්කාලීන වේ.';

  @override
  String get reportConfirmationSaved => 'හවුල් වාර්තාවට තහවුරු කිරීම සුරැකිණි.';

  @override
  String get reportRecheckSaved =>
      'නැවත පරීක්ෂාව සුරැකිණි. අනන්‍ය තහවුරු කිරීම් සහ ලකුණු වෙනස් නොවේ.';

  @override
  String get reportFlagSaved => 'හවුල් වාර්තාවට සලකුණ සුරැකිණි.';

  @override
  String get reportFlagHiddenLegacy =>
      'සලකුණ සුරැකිණි. ස්වාධීන සලකුණු තුනකට පසු වාර්තාව සඟවා ඇත.';

  @override
  String get reportResolutionSaved => 'හවුල් වාර්තාවට විසඳුම සුරැකිණි.';

  @override
  String reportShareText(String title, String target) {
    return 'AccessTransit දැනුම්දීම: $target හි $title. AccessTransit තුළ නිරීක්ෂණය බලන්න.';
  }

  @override
  String reportResolvedBy(String name) {
    return 'විසඳුම සටහන් කළේ: $name';
  }

  @override
  String reportResolvedAt(String date, String time) {
    return 'විසඳුම සටහන් කළේ: $date, $time';
  }

  @override
  String reportHiddenHelp(int threshold) {
    return 'ස්වාධීන වැරදි බව දැක්වීමේ සලකුණු $thresholdකට පසු මෙම වාර්තාව සඟවා ඇත. තත්ත්වය අසත්‍ය බව මෙයින් සනාථ නොවේ.';
  }

  @override
  String reportRecheckAge(String age) {
    return 'අවසන් පරීක්ෂාව $age. වත්මන් තත්ත්වය නොදනී; අලුත්වැඩියාවක් සටහන් වී නැත.';
  }

  @override
  String reportConfirmedRiders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'සෙසු මගීන් $count දෙනකු තහවුරු කර ඇත.',
      one: 'සෙසු මගීන් 1 දෙනකු තහවුරු කර ඇත.',
    );
    return '$_temp0';
  }

  @override
  String reportTransitVehicle(String name) {
    return 'ගමනාගමන බසය • $name';
  }

  @override
  String reportTransitStation(String name) {
    return 'ගමනාගමන නැවතුම • $name';
  }

  @override
  String reportUniqueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'අනන්‍ය තහවුරු කිරීම්: මගීන් $countයි',
      one: 'අනන්‍ය තහවුරු කිරීම්: මගීන් 1යි',
    );
    return '$_temp0';
  }

  @override
  String reportFlagCount(int count, int threshold) {
    return 'වැරදි බව දැක්වීමේ සලකුණු: $count / $threshold (ස්වාධීන සලකුණු $thresholdකින් වාර්තාව සැඟවේ)';
  }

  @override
  String reportOriginally(String age) {
    return 'මුලින් වාර්තා කළේ: $age';
  }

  @override
  String reportLastRecheck(String age, String name) {
    return 'අවසන් නැවත පරීක්ෂාව: $age, $name විසින්';
  }

  @override
  String reportLastConfirmed(String age) {
    return 'අවසන් තහවුරු කිරීම: $age';
  }

  @override
  String reportLegacyVoteHelp(int threshold) {
    return 'ඔබ නිරීක්ෂණය කළ දේ පමණක් තහවුරු කරන්න. පෙර තහවුරු කළ අයට අවසන් පරීක්ෂාවෙන් මිනිත්තු 30කට පසු නැවත පරීක්ෂා කළ හැක; අනන්‍ය ඡන්ද සහ ලකුණු වැඩි නොවේ. තත්ත්වය වෙනස් වී නම් නව වාර්තාවක් දෙන්න. ස්වාධීන සලකුණු $thresholdකින් වාර්තාව සැඟවේ.';
  }

  @override
  String reportTrueCount(int count) {
    return 'සත්‍යයි ($count)';
  }

  @override
  String reportFalseCount(int count, int threshold) {
    return 'අසත්‍යයි ($count/$threshold)';
  }

  @override
  String reportFalseRecorded(int count, int threshold) {
    return 'අසත්‍යයි ($count/$threshold)';
  }

  @override
  String deliveryCooldownAt(String time) {
    return 'එම ගැටලුව නැවත වාර්තා කිරීමට රැඳී සිටින්න. $time (UTC) පසු නැවත උත්සාහ කරන්න. කෙටුම්පත සුරැකිණි.';
  }

  @override
  String get formPhotoFailed =>
      'ඡායාරූපය ඇමිණිය නොහැකි විය. අවසර පරීක්ෂා කර යළි උත්සාහ කරන්න.';

  @override
  String get formSubmitFailed =>
      'වාර්තාව යැවීම තහවුරු නැත. පිවිසීම සහ සම්බන්ධතාව පරීක්ෂා කර යළි උත්සාහ කරන්න.';

  @override
  String get formSignIn => 'වාර්තාව ප්‍රකාශ කිරීමට පෙර පිවිසෙන්න.';

  @override
  String get formAccountChanged =>
      'ගිණුම වෙනස් විය. වාර්තාව නැවත සමාලෝචනය කරන්න.';

  @override
  String formReviewTarget(String target) {
    return 'ස්ථානය / බසය: $target';
  }

  @override
  String formReviewCondition(String condition) {
    return 'තත්ත්වය: $condition';
  }

  @override
  String formReviewCrowding(String level) {
    return 'තදබදය: $level';
  }

  @override
  String formReviewNote(String note) {
    return 'සටහන: $note';
  }

  @override
  String formBusRoute(String number) {
    return 'බසය $number';
  }

  @override
  String formVehicleRoute(String vehicle, String number) {
    return '$vehicle (මාර්ගය $number)';
  }

  @override
  String formBusRamp(String vehicle) {
    return '$vehicle ♿ (බෑවුම)';
  }

  @override
  String get formLowCrowd => 'අඩු තදබදය';

  @override
  String get formPlentyOfRoomWheelchairBay => 'ඉඩ ඇත; රෝද පුටු ඉඩ හිස්ය';

  @override
  String get formModerate => 'මධ්‍යම';

  @override
  String get formSeatsFullStandingRoomAvailable =>
      'ආසන පිරී ඇත; හිටගෙන යාමට ඉඩ ඇත';

  @override
  String get formCrowdedPacked => 'තදබදය වැඩියි';

  @override
  String get formWheelchairSpaceOrAisleBlocked =>
      'රෝද පුටු ඉඩ හෝ මැද මාර්ගය අවහිරයි';

  @override
  String get formRampBay => 'බෑවුම සහ රෝද පුටු ඉඩ';

  @override
  String get formRampWorking => 'බෑවුම ක්‍රියාකරයි';

  @override
  String get formDriverAssistedDeployedRamp => 'රියදුරු උදව් කර බෑවුම යෙදවීය';

  @override
  String get formRampBroken => 'බෑවුම දෝෂ සහිතයි';

  @override
  String get formMotorJammedOrRampBroken => 'මෝටරය හිර වී හෝ බෑවුම කැඩී ඇත';

  @override
  String get formRampDenied => 'බෑවුම් සහාය ප්‍රතික්ෂේප කළා';

  @override
  String get formDriverDidNotLowerOr => 'රියදුරු බෑවුම පහත් කළේ හෝ යෙදවූයේ නැත';

  @override
  String get formBayBlocked => 'රෝද පුටු ඉඩ අවහිරයි';

  @override
  String get formBlockedByBagsOrStanding =>
      'බෑග් හෝ හිටගෙන සිටින මගීන් නිසා අවහිරයි';

  @override
  String get formSeats => 'ආසන';

  @override
  String get formSeatsFree => 'ආසන හිස්ය';

  @override
  String get formElderlyDisabledSeatsFree =>
      'වැඩිහිටි / ආබාධ සහිත අයට වෙන් කළ ආසන හිස්ය';

  @override
  String get formSeatsOccupied => 'ආසන පිරී ඇත';

  @override
  String get formOthersNotGivingUpSeats => 'අනෙක් අය ආසන ලබා දෙන්නේ නැත';

  @override
  String get formSeatBroken => 'ආසනය කැඩී ඇත';

  @override
  String get formDamagedOrLooseSeating => 'හානි වූ හෝ බුරුල් ආසන';

  @override
  String get formSafetyClean => 'ආරක්ෂාව සහ පිරිසිදුකම';

  @override
  String get formCleanSafe => 'පිරිසිදු සහ ආරක්ෂිතයි';

  @override
  String get formVehicleWellMaintained => 'බසය හොඳින් නඩත්තු කර ඇත';

  @override
  String get formDirtyOdor => 'අපිරිසිදු / දුර්ගන්ධය';

  @override
  String get formSpillOrUnpleasantSmell => 'දියර ඉහිරීමක් හෝ දුර්ගන්ධයක්';

  @override
  String get formRailBroken => 'අත් වැට කැඩී ඇත';

  @override
  String get formGrabRailsOrStrapsLoose => 'අත් වැටවල් හෝ අත් පටි බුරුල්ය';

  @override
  String get formRecklessDriving => 'අනාරක්ෂිත රිය පැදවීම';

  @override
  String get formSuddenJerksUnsafeRide => 'හදිසි ගැස්සීම්; අනාරක්ෂිත ගමනක්';

  @override
  String get formElevator => 'විදුලි සෝපානය';

  @override
  String get formElevatorWorking => 'සෝපානය ක්‍රියාකරයි';

  @override
  String get formOperatingSmoothlyAccessible =>
      'හොඳින් ක්‍රියාකරයි; ප්‍රවේශ විය හැක';

  @override
  String get formOutOfService => 'සේවයෙන් ඉවත් කර ඇත';

  @override
  String get formElevatorShutDownOrRepair =>
      'සෝපානය නවතා හෝ අලුත්වැඩියා කරමින් ඇත';

  @override
  String get formDoorButtonFault => 'දොර / බොත්තම් දෝෂයක්';

  @override
  String get formDoorsStuckOrButtonsBroken =>
      'දොරවල් හිර වී හෝ බොත්තම් කැඩී ඇත';

  @override
  String get formRampPath => 'බෑවුම සහ මාර්ගය';

  @override
  String get formRampClear => 'බෑවුම පැහැදිලියි';

  @override
  String get formSmoothWheelchairSlope => 'සුමට රෝද පුටු බෑවුමක්';

  @override
  String get formPathBlocked => 'මාර්ගය අවහිරයි';

  @override
  String get formVendorsOrParkedVehicles => 'වෙළෙන්දන් හෝ නවතා ඇති වාහන';

  @override
  String get formDamagedSteep => 'හානි වූ / දැඩි බෑවුමක්';

  @override
  String get formPavementCrackedOrSteepSlope =>
      'පදික මාර්ගය ඉරිතලා හෝ බෑවුම දැඩියි';

  @override
  String get formTactileTiles => 'ස්පර්ශ මාර්ග ටයිල්';

  @override
  String get formTilesIntact => 'ටයිල් හොඳ තත්ත්වයේ';

  @override
  String get formGuidedTactileTilesClear => 'ස්පර්ශ මාර්ග ටයිල් අවහිර නැත';

  @override
  String get formTilesBroken => 'ටයිල් කැඩී ඇත';

  @override
  String get formLooseTilesCausingTripHazard =>
      'බුරුල් ටයිල් නිසා පැකිළීමේ අවදානමක්';

  @override
  String get formUnsafeEdgeGap => 'අනාරක්ෂිත දාර පරතරයක්';

  @override
  String get formExcessiveGapBetweenCurbBus =>
      'පදික දාරය හා බසය අතර වැඩි පරතරයක්';

  @override
  String get formShelterLight => 'ආවරණය සහ ආලෝකය';

  @override
  String get formShelterGood => 'ආවරණය හොඳ තත්ත්වයේ';

  @override
  String get formRainProtectionSeatingIntact =>
      'වැසි ආවරණය සහ ආසන හොඳ තත්ත්වයේ';

  @override
  String get formRoofDamaged => 'වහලයට හානි වී ඇත';

  @override
  String get formDamagedRoofOrBrokenBenches => 'හානි වූ වහලය හෝ කැඩුණු බංකු';

  @override
  String get formDarkUnsafe => 'අඳුරු / අනාරක්ෂිතයි';

  @override
  String get formPoorNightLightingInWalkway =>
      'රාත්‍රියේ ඇවිදින මාර්ගයේ ආලෝකය අඩුයි';

  @override
  String get formPhotoAttachedSuccessfully => 'ඡායාරූපය අමුණා ඇත!';

  @override
  String get formAttachEvidencePhoto => 'සාක්ෂි ඡායාරූපයක් අමුණන්න';

  @override
  String get formHelpVerifyConditionForCommuters =>
      'ආබාධ සහිත මගීන්ට තත්ත්වය තේරුම් ගැනීමට උදව් කරන්න';

  @override
  String get formTakePhoto => 'ඡායාරූපයක් ගන්න';

  @override
  String get formFromGallery => 'ගැලරියෙන් තෝරන්න';

  @override
  String get formSelectTheExactBusOr =>
      'ඔබ නිරීක්ෂණය කළ නිශ්චිත බසය හෝ නැවතුම තෝරන්න.';

  @override
  String get formChooseTheConditionAndCrowding =>
      'ඔබ නිරීක්ෂණය කළ තත්ත්වය සහ තදබද මට්ටම තෝරන්න.';

  @override
  String get formChooseTheConditionYouObserved =>
      'ඔබ නිරීක්ෂණය කළ තත්ත්වය තෝරන්න.';

  @override
  String get formConfirmYourObservation => 'ඔබේ නිරීක්ෂණය තහවුරු කරන්න';

  @override
  String get formEvidence1PhotoAttached => 'සාක්ෂි: ඡායාරූප 1ක් අමුණා ඇත';

  @override
  String get formYourObservationNoteAndAttached =>
      'ප්‍රකාශනයෙන් පසු නිරීක්ෂණය, සටහන සහ ඡායාරූපය ප්‍රසිද්ධ වේ. මුහුණු, හඳුනාගත හැකි විස්තර සහ සංවේදී පෞද්ගලික තොරතුරු ඇතුළත් නොකරන්න. බෙදාගැනීමට අවසර ඇති ඡායාරූප පමණක් යවන්න.';

  @override
  String get formPendingDraftsStayOnThis =>
      'කෙටුම්පත් දින 7ක් දක්වා මෙම උපාංගයේ පවතින අතර පිටවීමේදී හෝ ගිණුම මාරු කිරීමේදී ඉවත් වේ. Your uploads වෙතින් ඉවත් කළ හැක. දැනටමත් යැවූ ඉල්ලීමක් ආපසු ගැනීමට හෝ ප්‍රසිද්ධ වාර්තාවක්/ඡායාරූපයක් මැකීමට කෙටුම්පත ඉවත් කිරීම ප්‍රමාණවත් නොවේ.';

  @override
  String get formAndroidDraftsUseEncryptedPrivate =>
      'Android කෙටුම්පත් සංකේතනය කළ පෞද්ගලික ගබඩාවක පවතී. අනෙක් platforms වල කෙටුම්පත් මෙම app session එකට පමණි.';

  @override
  String get formEditReport => 'වාර්තාව සංස්කරණය කරන්න';

  @override
  String get formConfirmAndSubmit => 'තහවුරු කර යවන්න';

  @override
  String get formCommunityReport => 'ප්‍රජා වාර්තාව';

  @override
  String get formHelpAccessibleTransitCommutersIn =>
      'මගීන්ට ඔබේ නිරීක්ෂණ බෙදාගන්න';

  @override
  String get formSelectBusRoute => 'බස් මාර්ගය තෝරන්න';

  @override
  String get formWhichRouteAreYouTraveling =>
      'ඔබ ගමන් කරන හෝ බලා සිටින මාර්ගය කුමක්ද?';

  @override
  String get formWhereIsTheIssue => 'ගැටලුව කොතැනද?';

  @override
  String get formChooseWhetherYouAreInside =>
      'ඔබ බසය තුළද නැවතුමකද යන්න තෝරන්න';

  @override
  String get formVehicleAccessibilityCondition =>
      'බසයේ ප්‍රවේශ පහසුකම් තත්ත්වය';

  @override
  String get formStationAccessibilityCondition =>
      'නැවතුමේ ප්‍රවේශ පහසුකම් තත්ත්වය';

  @override
  String get formReportCrowdingLevelAndWheelchair =>
      'බසයේ තදබදය සහ රෝද පුටු ප්‍රවේශය වාර්තා කරන්න';

  @override
  String get formReportElevatorRampAndPlatform =>
      'නැවතුමේ සෝපාන, බෑවුම් සහ වේදිකා තත්ත්වයන් වාර්තා කරන්න';

  @override
  String get formEvidencePhotoOptional => 'සාක්ෂි ඡායාරූපය (අත්‍යවශ්‍ය නැත)';

  @override
  String get formTakeAPhotoOrUpload =>
      'තත්ත්වයට අදාළ ඡායාරූපයක් ගන්න හෝ ගැලරියෙන් තෝරන්න';

  @override
  String get formAdditionalNoteOptional => 'අමතර සටහන (අත්‍යවශ්‍ය නැත)';

  @override
  String get formAddHelpfulDetailsForFellow =>
      'රෝද පුටු භාවිත කරන හෝ වැඩිහිටි මගීන්ට උපකාරී විස්තර එක් කරන්න';

  @override
  String get formEGRampWasLowered =>
      'උදා: බෑවුම පහත් කළ නමුත් රියදුරුට වෙනත් අයකුගේ උදව් අවශ්‍ය විය';

  @override
  String get formSubmittingReport => 'වාර්තාව යවමින්…';

  @override
  String get formReviewAndSubmitReport => 'වාර්තාව බලලා යවන්න';

  @override
  String get formSelectARouteOptional => 'මාර්ගයක් තෝරන්න (අත්‍යවශ්‍ය නැත)';

  @override
  String get formOnABus => 'බසයක් තුළ';

  @override
  String get formInsideTheVehicle => 'බසය තුළ';

  @override
  String get formAtABusStop => 'බස් නැවතුමක';

  @override
  String get formStationPlatform => 'නැවතුම සහ වේදිකාව';

  @override
  String get formSelectSpecificBusLicensePlate =>
      'නිශ්චිත බසය / ලියාපදිංචි අංකය තෝරන්න';

  @override
  String get formSelectStopAlongThisRoute => 'මෙම මාර්ගයේ නැවතුම තෝරන්න';

  @override
  String get formCrowdingLevel => 'තදබද මට්ටම';

  @override
  String get formChooseTheCrowdingLevelYou =>
      'ඔබ නිරීක්ෂණය කළ තදබද මට්ටම තෝරන්න.';

  @override
  String get formAccessibilityIssueCategory => 'ප්‍රවේශ ගැටලු කාණ්ඩය';

  @override
  String get formStationFacilityCategory => 'නැවතුම් පහසුකම් කාණ්ඩය';

  @override
  String get formPhotoUploadsAreCurrentlyUnavailable =>
      'දැනට ඡායාරූප යැවිය නොහැක. ඡායාරූපයක් නැතිව වාර්තාව යැවිය හැක.';

  @override
  String get formPhotoAttached => 'ඡායාරූපය අමුණා ඇත';

  @override
  String get formWillBeUploadedWithReport => 'වාර්තාව සමඟ යවනු ඇත';

  @override
  String get formRemovePhoto => 'ඡායාරූපය ඉවත් කරන්න';

  @override
  String get formAddPhoto => 'ඡායාරූපයක් එක් කරන්න';

  @override
  String get formTapToTakePhotoOr => 'ඡායාරූපයක් ගන්න හෝ උපාංගයෙන් තෝරන්න';

  @override
  String get formNotSelected => 'තෝරා නැත';

  @override
  String get formReportSummary => 'වාර්තා සාරාංශය';

  @override
  String get formLocationVehicle => 'ස්ථානය / බසය';

  @override
  String get formAccessibilityStatus => 'ප්‍රවේශ පහසුකම් තත්ත්වය';

  @override
  String get formPhotoEvidence => 'ඡායාරූප සාක්ෂි';

  @override
  String get form1PhotoAttached => 'ඡායාරූප 1ක් අමුණා ඇත';

  @override
  String get communityHubTitle => 'ප්‍රජා මධ්‍යස්ථානය';

  @override
  String get communitySubtitle => 'මගීන්ගේ ප්‍රවේශ පහසුකම් නිරීක්ෂණ';

  @override
  String get communityReportAction => 'තත්ත්වයක් වාර්තා කරන්න';

  @override
  String get communityPastReports => 'විසඳූ සහ පැරණි වාර්තා';

  @override
  String get communityNoOwnReports => 'තවම වාර්තා නැත';

  @override
  String get communityEmptyTitle => 'වත්මන් වාර්තා නැත';

  @override
  String get communityOwnEmptyHelp =>
      'රෝද පුටු ප්‍රවේශය, තදබදය හෝ සෝපාන ගැන ඔබ යවන වාර්තා මෙහි පෙන්වයි.';

  @override
  String get communityEmptyHelp =>
      'මෙම ලැයිස්තුවේ වත්මන් වාර්තා නොමැත. මෙයින් ප්‍රවේශ පහසුකම් හෝ ආරක්ෂාව තහවුරු නොවේ.';

  @override
  String get communitySubmitReport => 'තත්ත්ව වාර්තාවක් යවන්න';

  @override
  String get communityUpdatesTab => 'යාවත්කාලීන';

  @override
  String get communityMyReportsTab => 'මගේ වාර්තා';

  @override
  String get communityContributor => 'ප්‍රජා දායකයා';

  @override
  String get communityPhoto => 'ඡායාරූපය';

  @override
  String get communityRecheckHelp =>
      'අවසන් පරීක්ෂාවෙන් මිනිත්තු 30කට පසු එම තත්ත්වය නැවත පරීක්ෂා කරන්න. අමතර ඡන්ද හෝ ලකුණු නැත. වෙනස් වූ තත්ත්වයන් වෙනම වාර්තා කරන්න.';

  @override
  String get communityActiveBadge => 'ක්‍රියාත්මකයි';

  @override
  String get communityConfirmedBadge => 'ප්‍රජාව තහවුරු කර ඇත';

  @override
  String get communityResolvedBadge => 'විසඳූ බව සටහන් කර ඇත';

  @override
  String get communityPastBadge => 'පැරණි';

  @override
  String get communityUnavailable =>
      'ප්‍රජා වාර්තා නොමැත. සම්බන්ධ වී යළි උත්සාහ කරන්න.';

  @override
  String get communityRetry => 'වාර්තා නැවත ලබාගන්න';

  @override
  String get communityOwnSignIn =>
      'ඔබේ වාර්තා සහ උපාංගයේ කෙටුම්පත් බැලීමට පිවිසෙන්න.';

  @override
  String get outboxTitle => 'ඔබේ යැවීම්';

  @override
  String get outboxHelp =>
      'කෙටුම්පත් දින 7කින් කල් ඉකුත් වේ. යළි යැවීමට හෝ ඉවත් කිරීමට යැවීමක් විවෘත කරන්න. පිටවීමේදී උපාංගයේ කෙටුම්පත් ඉවත් වේ.';

  @override
  String communityStationTarget(String id) {
    return 'නැවතුම $id';
  }

  @override
  String communityBusTarget(String id) {
    return 'බසය $id';
  }

  @override
  String communityRouteTarget(String number) {
    return 'බස් මාර්ගය $number';
  }

  @override
  String communityContributionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'දැනට හවුල් වාර්තා $countක් ලැයිස්තුගතයි. මෙහි ත්‍යාග ගණනය නොවේ.',
      one: 'දැනට හවුල් වාර්තා 1ක් ලැයිස්තුගතයි. මෙහි ත්‍යාග ගණනය නොවේ.',
    );
    return '$_temp0';
  }

  @override
  String communityChecked(String freshness, String age) {
    return '$freshness · අවසන් පරීක්ෂාව: $age';
  }

  @override
  String communityTrueCount(int count) {
    return 'සත්‍යයි: $count';
  }

  @override
  String communityFalseCount(int count, int threshold) {
    return 'අසත්‍යයි: $count/$threshold';
  }

  @override
  String get helpIntro => 'AccessTransit භාවිතය';

  @override
  String get helpSearchTitle => 'බස් රථයක් සොයන්නේ කෙසේද?';

  @override
  String get helpSearchBody =>
      'නගින නැවතුම, ගමනාන්තය සහ ඉදිරි පැය 24 ඇතුළත නගින වේලාව තෝරන්න. සෙවීමට ඔබ සුරැකි ප්‍රවේශ පහසුකම් අවශ්‍යතා යෙදේ. සෙවීමේදී කරන වෙනස්කම් එම සෙවීමට පමණි. ගිණුමේ පෙරනිමි අවශ්‍යතා වෙනස් කිරීමට Settings හි සුරකින්න.';

  @override
  String get helpSaveTitle => 'Save Trip මඟින් සිදුවන්නේ කුමක්ද?';

  @override
  String get helpSaveBody =>
      'ප්‍රතිඵලයක් විවෘත කර බස් විස්තර සහ තෝරාගත් නැවතුම් කොටස බලන්න. සුරැකීම අත්‍යවශ්‍ය නැත. එය පසුව සුරැකි ගමන් වෙතින් විස්තර නැවත බැලීමට තෝරාගැනීම සුරකියි. ආසනයක් වෙන් කිරීමක් හෝ ගමන ආරම්භ කිරීමක් සිදු නොවේ. නැවත විවෘත කරන විට යාවත්කාලීන වේලාවන් සහ අවලංගු කිරීම් බලන්න.';

  @override
  String get helpLocationTitle => 'My Location භාවිතය';

  @override
  String get helpLocationBody =>
      'අසල නගින නැවතුම් සෙවීමට ඉල්ලූ විට ස්ථාන අවසරය දෙන්න. සෙවීමට පෙර තෝරාගත් නැවතුම සහ දිශාව පරීක්ෂා කරන්න. ළඟ පිහිටීම පඩි රහිත ඇවිදින මාර්ගයක් ඇති බව තහවුරු නොකරයි. ස්ථානය ලබාගත නොහැකි නම් හෝ අවසර නොදුන්නේ නම් නැවතුම ඔබම තෝරන්න.';

  @override
  String get helpLiveTitle => 'කාලසටහන සහ සජීවී ස්ථානය';

  @override
  String get helpLiveBody =>
      'කාලසටහන සැලැස්මකි; බස් රථය ආරම්භ වූ බවට සාක්ෂියක් නොවේ. අනාගත හෝ ආරම්භ නොකළ ධාවන සඳහා කාලසටහන පෙන්වයි. සජීවී ස්ථානයට තෝරාගත් ධාවනය ආරම්භ වී අලුත් GPS දත්ත තිබිය යුතුය. ස්ථානය පැරණි හෝ නොමැති නම් අවසන් යාවත්කාලීන පණිවිඩය බලන්න. ඇස්තමේන්තු සහ පැමිණීමේ වේලාවන් වෙනස් විය හැක.';

  @override
  String get helpReportsTitle => 'වාර්තා සහ යැවීමට ඇති කෙටුම්පත්';

  @override
  String get helpReportsBody =>
      'නිවැරදි බස් රථය හෝ නැවතුම සහ ඔබ නිරීක්ෂණය කළ දේ වාර්තා කරන්න. උපකරණයේ කෙටුම්පතක් පෞද්ගලිකය; එය ප්‍රකාශිත වාර්තාවක් නොවේ. My Reports යටතේ ඔබේ යැවීම් විවෘත කර යළි යැවීමට හෝ ඉවත් කිරීමට හැක. කෙටුම්පත් දින 7කින් කල් ඉකුත් වන අතර පිටවීමේදී ඉවත් වේ. ප්‍රසිද්ධ සටහන් සහ ඡායාරූපවල පෞද්ගලික තොරතුරු නොදමන්න.';

  @override
  String get helpVotesTitle => 'ඡන්ද සහ ප්‍රජා විවාද';

  @override
  String get helpVotesBody =>
      'කර්තෘට තම වාර්තාවට True හෝ False ඡන්ද දිය නොහැක. ඔබේ නිරීක්ෂණ මත පමණක් ඡන්ද දෙන්න; False සඳහා හේතුවක් දෙන්න. v2 ප්‍රතිපත්තිය අනුව සුදුසු වෙනත් පරිශීලකයන් පස්දෙනෙකුගේ False ඡන්දවලින් වාර්තාව සඟවා අදාළ ලකුණු දඩය සහ වරද සටහන් වේ. මෙය ප්‍රජා විවාදයකි; වාර්තාව බොරු බවට සාක්ෂියක් නොවේ. කර්තෘට වාර්තා සමාලෝචන සහ අභියාචනා තිර භාවිත කළ හැක.';

  @override
  String get helpAssistanceTitle => 'බස් රථයට නැගීමට සහාය';

  @override
  String get helpAssistanceBody =>
      'බස් විස්තර තුළ සහාය ඉල්ලීම විකල්පයකි. බස් රථය, ධාවනය සහ නගින නැවතුම පරීක්ෂා කරන්න. Submitted යනු ඉල්ලීම සටහන් වූ බවය; Accepted යනු පැවරූ රියදුරු එය පිළිගත් බවය. ගමන සුරැකීම හෝ ඉල්ලීම යැවීම සහාය සහතික නොකරයි. ප්‍රතික්ෂේප කිරීම, අවලංගු කිරීම හෝ කල් ඉකුත් වීම ඇතුළු අලුත්ම තත්ත්වය බලන්න.';

  @override
  String get helpAccessTitle => 'ගිණුම් ප්‍රවේශය සහ සමාලෝචනය';

  @override
  String get helpAccessBody =>
      'ප්‍රවේශය සීමා වී ඇත්නම් පෙන්වන හේතුව සහ කල් ඉකුත් වන වේලාව කියවා තිබෙන අභියාචනා ක්‍රියාව භාවිත කරන්න. අභියාචනයක් යැවීමෙන් සීමාව ස්වයංක්‍රීයව ඉවත් නොවේ. ස්ථිර තහනමකට පරිපාලක සමාලෝචනය අවශ්‍යය. Profile තුළ තමන්ම ගිණුම මකා දැමීම නැත; පරිපාලක සමාලෝචනයෙන් මකා දැමීම වෙනම ක්‍රියාවලියකි.';

  @override
  String get rewardsTitle => 'ලකුණු සහ දායකත්ව';

  @override
  String get rewardsMine => 'මගේ දායකත්ව';

  @override
  String get rewardsSettingsSoon => 'සැකසුම් පසුව ලබාගත හැක.';

  @override
  String get rewardsReports => 'යැවූ වාර්තා';

  @override
  String get rewardsConfirmations => 'සටහන් කළ තහවුරු කිරීම්';

  @override
  String get rewardsViewCard => 'සාමාජික කාඩ්පත බලන්න';

  @override
  String get rewardsTotal => 'මුළු ලකුණු';

  @override
  String get rewardsGold => 'රන් දායකයා';

  @override
  String get rewardsSilver => 'රිදී දායකයා';

  @override
  String get rewardsBronze => 'ලෝකඩ දායකයා';

  @override
  String get memberGold => 'රන් සාමාජිකයා';

  @override
  String get memberSilver => 'රිදී සාමාජිකයා';

  @override
  String get memberBronze => 'ලෝකඩ සාමාජිකයා';

  @override
  String get memberBack => 'ලකුණු වෙත ආපසු';

  @override
  String get memberTitle => 'ඩිජිටල් සාමාජික කාඩ්පත';

  @override
  String get memberPointsLabel => 'දායකත්ව ලකුණු';

  @override
  String get memberNoCash => 'ලකුණුවලට මුදල් හෝ වවුචර් වටිනාකමක් නැත';

  @override
  String get memberNoRedemption => 'ලකුණු හුවමාරුව ලබාගත නොහැක';

  @override
  String get memberAvailability => 'ප්‍රතිලාභ ලබාගත හැකි බව';

  @override
  String get memberNoVouchers => 'හවුල්කාර වට්ටම් සහ වවුචර් ලබාගත නොහැක.';

  @override
  String get memberBenefits => 'සාමාජික ප්‍රතිලාභ';

  @override
  String get memberNoPriority =>
      'සාමාජිකත්වයෙන් ප්‍රමුඛ සහාය හෝ සහතික කළ ප්‍රවේශයක් නොලැබේ.';

  @override
  String get memberRecognition => 'ප්‍රජා ඇගයීම';

  @override
  String get memberLedgerNotice =>
      'දායකත්ව ලකුණු සටහන් කළ ලකුණු ප්‍රතිපත්තිය අනුව යාවත්කාලීන වේ. ඒවා ප්‍රවේශ පහසුකම් තහවුරු නොකරයි.';

  @override
  String get rewardsLegacyNotice =>
      'පැරණි ප්‍රතිපත්තිය: පරිපාලක සමාලෝචනයෙන් පසු ලකුණු යාවත්කාලීන වීමට කාලයක් ගත විය හැක. ප්‍රකාශිත වාර්තාවකට ලකුණු 10කි; අනන්‍ය තහවුරු කිරීමකට ලකුණු 5කි. ඡන්ද ඉවත් කළ විට සහ වාර්තා සැඟවූ හෝ මැකූ විට ලකුණු ආපසු හැරේ. ලකුණු ප්‍රවේශ පහසුකම් තහවුරු නොකරන අතර මුදල් වටිනාකමක් නැත.';

  @override
  String rewardsLevel(String level) {
    return 'මට්ටම: $level';
  }

  @override
  String memberPointCount(int count) {
    return 'ලකුණු $count';
  }

  @override
  String memberIdentity(String id) {
    return 'හැඳුනුම් අංකය: $id';
  }

  @override
  String get assistFormUnknown =>
      'සහාය සඳහා බස් රථය හෝ නැවතුම නොදනී. පළමුව නිශ්චිත නැවතුමක් සහිත ගමනක් තෝරන්න.';

  @override
  String get assistFormSelect => 'අවම වශයෙන් එක් සහාය විකල්පයක් තෝරන්න.';

  @override
  String get assistFormTarget =>
      'සහාය ඉල්ලීමට පෙර ගමනෙන් නිවැරදි බස් රථය සහ නැවතුම තෝරන්න.';

  @override
  String get assistFormWrongStop =>
      'තෝරාගත් බස් රථයේ මෙම නැවතුම තහවුරු කළ නොහැකි විය. ගමනට ආපසු ගොස් නිවැරදි ඉලක්කය තෝරන්න.';

  @override
  String get assistFormConfirm => 'සහාය ඉල්ලීමේ ඉලක්කය තහවුරු කරන්න';

  @override
  String get assistFormEdit => 'ඉල්ලීම සංස්කරණය කරන්න';

  @override
  String get assistFormSendConfirm => 'තහවුරු කර යවන්න';

  @override
  String get assistFormSignIn => 'සහාය ඉල්ලීමක් යැවීමට පෙර පිවිසෙන්න.';

  @override
  String get assistFormPrepareError =>
      'ඉල්ලීම සූදානම් කළ නොහැකි විය. පිවිසීම සහ උපකරණයේ ගබඩාව පරීක්ෂා කර යළි උත්සාහ කරන්න.';

  @override
  String get assistFormTitle => 'සහාය ඉල්ලන්න';

  @override
  String get assistFormRamp => 'බෑවුම් පුවරුව යොදන්න';

  @override
  String get assistFormTime => 'අමතර කාලය';

  @override
  String get assistFormBoarding => 'නැගීමට සහාය';

  @override
  String get assistFormAlighting => 'බැසීමට සහාය';

  @override
  String get assistFormSend => 'ඉල්ලීම යවන්න';

  @override
  String get assistFormAckHelp =>
      'සහාය තහවුරු වන්නේ රියදුරු ඔබේ ඉල්ලීම පිළිගත් පසුව පමණි.';

  @override
  String get assistFormEtaUnknown => 'පැමිණීමේ ඇස්තමේන්තුව නොදනී';

  @override
  String get assistFormMinutes => 'මිනිත්තු (ඇස්.)';

  @override
  String get assistFormAccountChanged =>
      'සමාලෝචනය අතරතුර ගිණුම වෙනස් විය. යැවීමට පෙර ඉල්ලීම නැවත සමාලෝචනය කරන්න.';

  @override
  String assistFormBoardAt(String stop) {
    return 'නගින නැවතුම: $stop';
  }

  @override
  String assistFormAlightAt(String stop) {
    return 'බසින නැවතුම: $stop';
  }

  @override
  String assistFormBusRoute(String bus, String route) {
    return '$bus (මාර්ගය $route)';
  }

  @override
  String assistFormArrival(String bus, int minutes) {
    return '$bus - මිනිත්තු $minutesකින් පැමිණීමට ඇස්තමේන්තු කර ඇත';
  }

  @override
  String get assistReceiptTitle => 'සහාය ඉල්ලීම';

  @override
  String get assistReceiptOwner =>
      'මෙම ඉල්ලීමේ තත්ත්වය බැලීමට එය සෑදූ ගිණුමෙන් පිවිසෙන්න.';

  @override
  String get assistReceiptSent => 'පොදු සේවාවට යවා ඇත';

  @override
  String get assistReceiptUnknown => 'ඉල්ලීමේ තත්ත්වය නොදනී';

  @override
  String get assistReceiptPendingHint =>
      'ඉල්ලීම සුරැකීමෙන් රියදුරු එය පිළිගත් බව අදහස් නොවේ.';

  @override
  String get assistReceiptAcceptedHint =>
      'රියදුරු ඉල්ලීම පිළිගෙන ඇත. සහාය සම්පූර්ණ කළ බව තවම සටහන් කර නැත.';

  @override
  String get assistReceiptDelivery => 'ඉල්ලීම යැවීම';

  @override
  String get assistReceiptOwn => 'ඔබේ සහාය ඉල්ලීම';

  @override
  String get assistReceiptSupport => 'ඉල්ලූ සහාය';

  @override
  String get assistReceiptUnspecified => 'සඳහන් කර නැත';

  @override
  String get assistReceiptDriver => 'රියදුරු ප්‍රතිචාරය';

  @override
  String get assistReceiptUnconfirmed => 'රියදුරුගේ පිළිගැනීම තහවුරු වී නැත.';

  @override
  String get assistReceiptStale =>
      'සජීවී තත්ත්ව යාවත්කාලීන නොමැත. පෙන්වන්නේ අවසන් වරට ලැබුණු රියදුරු තත්ත්වයයි.';

  @override
  String get assistReceiptSending => 'යවමින් තිබේද?';

  @override
  String get assistReceiptRetry => 'නැවත යවන්න';

  @override
  String get assistReceiptCancelling => 'අවලංගු වෙමින් තිබේද?';

  @override
  String get assistReceiptCancel => 'ඉල්ලීම අවලංගු කරන්න';

  @override
  String get assistReceiptRetryError =>
      'නැවත යැවීම මෙම උපකරණයේ සුරැකිය නොහැකි විය. යළි උත්සාහ කරන්න.';

  @override
  String get assistReceiptCancelError =>
      'අවලංගු කිරීම තහවුරු වී නැත. සම්බන්ධතාව පරීක්ෂා කර නැවත උත්සාහ කරන්න.';

  @override
  String get assistReceiptPendingUpload => 'යැවීමට නියමිතයි';

  @override
  String get assistReceiptDeliverySent => 'යවා ඇත';

  @override
  String get assistReceiptFailed => 'අසාර්ථකයි';

  @override
  String get assistReceiptExpired => 'නැවත යැවීමේ කාලය ඉකුත් වී ඇත';

  @override
  String get assistReceiptOld =>
      'මෙම ඉල්ලීම පැරණි බැවින් ස්වයංක්‍රීය නැවත යැවීම් නැවැත්වීය. රියදුරු තත්ත්වය බලන්න; යැවීම තවම තහවුරු නොවී තිබිය හැක.';

  @override
  String get assistReceiptDeliveryError =>
      'යැවීම තහවුරු වී නැත. සම්බන්ධ වූ විට නැවත යවා රියදුරු තත්ත්වයත් පරීක්ෂා කරන්න.';

  @override
  String get assistReceiptSendError =>
      'ඉල්ලීම යැවිය නොහැකි විය. පිවිසීම සහ ඉලක්කය පරීක්ෂා කර නැවත උත්සාහ කරන්න.';

  @override
  String get assistReceiptRestoreError =>
      'සුරැකි සහාය ඉල්ලීම් කිහිපයක් නැවත ලබාගත නොහැකි විය. පොදු සේවාවේ ඉල්ලීම් ඉතිහාසය බලන්න.';

  @override
  String get assistReceiptSaveError =>
      'නවතම ඉල්ලීමේ තත්ත්වය මෙම උපකරණයේ සුරැකිය නොහැකි විය. පොදු සේවාවේ ඉල්ලීම් ඉතිහාසය බලන්න.';

  @override
  String get assistReceiptHistory => 'ඔබේ සහාය ඉල්ලීම්';

  @override
  String get assistReceiptHistoryStale =>
      'පොදු සේවාවේ ඉල්ලීම් යාවත්කාලීන නොමැත. සුරැකි ලදුපත් පැරණි විය හැක.';

  @override
  String get assistReceiptError =>
      'ඉල්ලීමේ තත්ත්වය ලබාගත නොහැක. සම්බන්ධතාව සහ ගිණුම පරීක්ෂා කර නැවත උත්සාහ කරන්න.';

  @override
  String assistReceiptRoute(String route) {
    return 'මාර්ගය $route';
  }

  @override
  String assistReceiptSummary(String route, String stop) {
    return 'මාර්ගය $route · $stop';
  }

  @override
  String get sharedCatalogueDemo =>
      'ආදර්ශනය: නියැදි ප්‍රවාහන දත්ත. හවුල් වාර්තා, සහාය සහ ගමන් අක්‍රියයි.';

  @override
  String get sharedCatalogueSaved =>
      'සුරැකි ප්‍රවාහන දත්ත. යාවත්කාලීන බැලීමට නැවුම් කරන්න; කාලසටහන් හා ලබාගත හැකි සේවා වෙනස් වී තිබිය හැක.';

  @override
  String get sharedCatalogueUnavailable =>
      'ප්‍රවාහන දත්ත නොමැත. සම්බන්ධ වී නැවත උත්සාහ කරන්න; ඒ වෙනුවට නියැදි සේවා පෙන්වන්නේ නැත.';

  @override
  String get sharedCatalogueEmpty =>
      'මෙම නාමාවලිය සඳහා හවුල් ප්‍රවාහන දත්ත නොමැත. පසුව නැවත උත්සාහ කරන්න.';

  @override
  String get sharedRefresh => 'නැවුම් කරන්න';

  @override
  String get sharedRefreshing => 'නැවුම් කරමින්…';

  @override
  String get sharedSavingStatus => 'තත්ත්වය සුරකිමින්…';

  @override
  String get sharedOperatorStatusError =>
      'තත්ත්ව වෙනස තහවුරු වී නැත. සම්බන්ධතාව, රියදුරු අනුමැතිය සහ බස් පැවරීම පරීක්ෂා කර නැවත උත්සාහ කරන්න.';

  @override
  String get sharedAdminAccess => 'පරිපාලක ප්‍රවේශය';

  @override
  String get sharedAdminChecking => 'පරිපාලක ප්‍රවේශය පරීක්ෂා කරමින්…';

  @override
  String get sharedAdminRequired =>
      'පරිපාලක අවසරය සහ අන්තර්ජාල සම්බන්ධතාව අවශ්‍යයි. පැතිකඩෙහි භූමිකාව පමණක් ප්‍රවේශය ලබා නොදෙයි.';

  @override
  String get sharedCheckAgain => 'නැවත පරීක්ෂා කරන්න';

  @override
  String get sharedSignIn => 'පිවිසෙන්න';

  @override
  String get sharedSavedJourney => 'සුරැකි ගමන';

  @override
  String get sharedJourneyUpdatesError =>
      'සුරැකි ගමනේ යාවත්කාලීන නොමැත. සම්බන්ධතාව පරීක්ෂා කර මුල් පිටුව නැවත විවෘත කරන්න.';

  @override
  String get sharedJourneyChangeError =>
      'ගමනේ තත්ත්ව වෙනස තහවුරු වී නැත. සම්බන්ධ වූ පසු නැවත උත්සාහ කරන්න.';

  @override
  String get sharedResume => 'ගමන නැවත විවෘත කරන්න';

  @override
  String get sharedComplete => 'අවසන් ලෙස සලකුණු කරන්න';

  @override
  String get sharedCancelJourney => 'සුරැකි ගමන අවලංගු කරන්න';

  @override
  String get sharedSaveDisclosure =>
      'සුරැකීමෙන් මෙම තේරීම තබා ගනී. එයින් අසුනක් වෙන් කිරීමක් හෝ ගමනක් ආරම්භ කිරීමක් සිදු නොවේ.';

  @override
  String get sharedSaveStatusError =>
      'සුරැකි තත්ත්වය නොමැත. සුරැකීම තහවුරු කිරීමට නැවත උත්සාහ කරන්න.';

  @override
  String get sharedSaveError =>
      'සුරැකීමේ වෙනස තහවුරු වී නැත. සම්බන්ධතාව පරීක්ෂා කර නැවත උත්සාහ කරන්න.';

  @override
  String get sharedSaveOwner => 'මෙම ගමන සුරකින ගිණුමෙන් පිවිසෙන්න.';

  @override
  String get sharedSaveMismatch => 'සුරැකි ගමනේ තහවුරු කිරීම නොගැළපේ.';

  @override
  String get sharedSaveSignIn => 'මෙම ගමන සුරැකීමට පිවිසෙන්න.';

  @override
  String get sharedSaving => 'සුරකිමින්…';

  @override
  String get sharedStopAlert => 'නැවතුම් දැනුම්දීම නොමැත';

  @override
  String get sharedStopAlertHelp =>
      'ස්වයංක්‍රීය නැවතුම් හා පසුබිම් දැනුම්දීම් නොමැත. ගමනේ ප්‍රගතිය ඔබම බලන්න; ඔබේ නැවතුමට පෙර යෙදුම දැනුම් නොදෙයි.';

  @override
  String get sharedSplashTagline =>
      'සැමට පහසු ගමන් සඳහා ඔබේ ගමන මෙතැනින් ඇරඹේ.';

  @override
  String get sharedLoading => 'පූරණය වෙමින්.';

  @override
  String get sharedStopsOrder => 'ගමන් අනුපිළිවෙළට නැවතුම්';

  @override
  String get sharedDriverReviewHelp =>
      'රියදුරු ලියාපදිංචිය ප්‍රවේශය සඳහා අයදුම්පතකි. අනුමැතියට පෙර අනන්‍යතාව හා ධාවන අවසරය සමාලෝචනය කරන්න. අනුමැතියෙන් උපකරණ තහවුරු කිරීමක් හෝ සේවා සහතිකයක් නොලැබේ.';

  @override
  String get sharedAddStation => 'නව නැවතුමක් එක් කරන්න';

  @override
  String get sharedStationName => 'නැවතුමේ නම';

  @override
  String get sharedStationExample => 'උදා. බම්බලපිටිය හන්දිය';

  @override
  String get sharedStationId => 'නැවතුම් හැඳුනුම (උදා. bambalapitiya_junc)';

  @override
  String get sharedTargetRoute => 'අදාළ බස් මාර්ගය';

  @override
  String get sharedInsertIndex => 'එක් කරන ස්ථානයේ අංකය (0 සිට)';

  @override
  String get sharedInsertHint => '1 (දෙවන නැවතුම ලෙස එක් කරන්න)';

  @override
  String get sharedRequired => 'අවශ්‍යයි';

  @override
  String get sharedRamp => 'ප්‍රවේශ බෑවුම';

  @override
  String get sharedElevator => 'විදුලි සෝපානය';

  @override
  String get sharedCancel => 'අවලංගු කරන්න';

  @override
  String get sharedAddStationAction => 'නැවතුම එක් කරන්න';

  @override
  String get sharedStationError =>
      'නැවතුම එක් කළ නොහැකි විය. ප්‍රවේශය හා සම්බන්ධතාව පරීක්ෂා කර නැවත උත්සාහ කරන්න.';

  @override
  String get sharedLiveAccessibility => 'ප්‍රවේශ පහසුකම් පිළිබඳ නිරීක්ෂණ';

  @override
  String get sharedEquipmentHelp =>
      'උපකරණ පරීක්ෂා සජීවී GPS වෙතින් වෙනස්ය. ක්‍රියාකරන බවට වාර්තාවකින් මුළු ගමනම තහවුරු නොවේ.';

  @override
  String get sharedConditionsUnavailable =>
      'තත්ත්ව යාවත්කාලීන නොමැත. ක්‍රියාකාරී තත්ත්වය නොදනී; පෙර අනතුරු ඇඟවීම් තබා ඇත.';

  @override
  String get sharedRampWarning =>
      'වාහනයේ බෑවුම පිළිබඳ දත්ත ගැටලුවක් දක්වයි. උපකරණ පරීක්ෂා කළ වේලාව නොදනී; නැගීමට පෙර පරීක්ෂා කරන්න.';

  @override
  String get sharedCommunityObservations => 'ප්‍රජා නිරීක්ෂණ';

  @override
  String get sharedRampUnknown =>
      'නොදනී — වාහන බෑවුම් අනතුරු ඇඟවීම පරීක්ෂා කළ යුතුය';

  @override
  String get sharedDriverAssistance => 'රියදුරු සහාය';

  @override
  String get sharedPositiveAssistance => 'සහාය ලැබුණු බවට නිරීක්ෂණය';

  @override
  String get sharedOperatorCheck => 'රියදුරු වාහන පරීක්ෂාව';

  @override
  String get sharedHideObservations => 'නිරීක්ෂණ විස්තර සඟවන්න';

  @override
  String get sharedViewObservations => 'නිරීක්ෂණ විස්තර බලන්න';

  @override
  String sharedVehicle(String vehicle) {
    return 'වාහනය: $vehicle';
  }

  @override
  String sharedTimetable(String time) {
    return 'කාලසටහන: $time';
  }

  @override
  String sharedStationAdded(String name, String bus, String index) {
    return '\"$name\" නැවතුම $bus වෙත $index ස්ථානයේ එක් කළා.';
  }

  @override
  String sharedBusOption(String route, String id) {
    return 'බස් $route ($id)';
  }

  @override
  String sharedBoardingElevator(String stop) {
    return 'නගින නැවතුමේ සෝපානය — $stop';
  }

  @override
  String sharedDestinationElevator(String stop) {
    return 'බසින නැවතුමේ සෝපානය — $stop';
  }

  @override
  String get legacyUi0 => 'ක්‍රියාකරන බව වාර්තා කර ඇත';

  @override
  String get legacyUi1 => 'බාධාවක් වාර්තා කර ඇත';

  @override
  String get legacyUi2 => 'ගමන සුරැකීමට සහ නැවත විවෘත කිරීමට පිවිසෙන්න.';

  @override
  String get legacyUi3 =>
      'ගමනේ හිමිකාරිත්වය හෝ තත්ත්වය වෙනස් විය. සුරැකි ගමන් නැවත විවෘත කරන්න.';

  @override
  String get legacyUi4 =>
      'ගමන සුරැකීම තහවුරු වී නැත. සම්බන්ධතාව හා පිවිසීම පරීක්ෂා කර නැවත උත්සාහ කරන්න.';

  @override
  String get legacyUi5 => 'වාහනය සඳහන් කර නැත';

  @override
  String get legacyUi6 => 'ආපසු';

  @override
  String get legacyUi7 => 'ගමන තහවුරු කරන්න';

  @override
  String get legacyUi8 => 'ගමන් කාලසටහන';

  @override
  String get legacyUi9 => 'තෝරාගත් දිනය';

  @override
  String get legacyUi10 => 'තෝරාගත් වේලාව';

  @override
  String get legacyUi11 => 'තෝරාගත් දිනයේ පළමුව ලබාගත හැකි සේවාව';

  @override
  String get legacyUi12 => 'කාලසටහනේ පිටත්වීම';

  @override
  String get legacyUi13 => 'ඇස්තමේන්තුගත පැමිණීම';

  @override
  String get legacyUi14 =>
      'කාලසටහනේ ඇතැම් කාල පරතර නොමැත. වේලාවලට ආකෘති ඇස්තමේන්තු ඇතුළත්ය; රියදුරුගෙන් තහවුරු කරන්න.';

  @override
  String get legacyUi15 => 'ඇස්තමේන්තුගත ගාස්තුව';

  @override
  String get legacyUi16 =>
      'මූලාකෘති ඇස්තමේන්තුවකි. සැබෑ ගාස්තුව රියදුරුගෙන් තහවුරු කරන්න.';

  @override
  String get legacyUi17 => 'ගාස්තු විස්තර';

  @override
  String get legacyUi18 => 'ගමන් අවශ්‍යතා';

  @override
  String get legacyUi19 =>
      'ගමන සුරැකීමෙන් අසුනක් වෙන් කිරීමක් හෝ බස් රථය ධාවනය වන බව තහවුරු කිරීමක් සිදු නොවේ. වත්මන් තත්ත්ව සාක්ෂි බලන්න.';

  @override
  String get legacyUi20 => 'ගමන සුරකිමින්…';

  @override
  String get legacyUi21 => 'තහවුරු කර ගමන සුරකින්න';

  @override
  String get legacyUi22 => 'සේවාව නොමැත. පළමුව හවුල් සේවාවක් තෝරන්න.';

  @override
  String get legacyUi23 => 'මෙම සේවාව නොමැත. සෙවීමට ආපසු යන්න.';

  @override
  String get legacyUi24 => 'පිටත්වීම සහ මාර්ග විස්තර';

  @override
  String get legacyUi25 =>
      'සුරැකි පිහිටීමකි — සජීවී යාවත්කාලීන නොමැත. මෙය වත්මන් බස් චලනය නොවේ.';

  @override
  String get legacyUi26 => 'කාලසටහන';

  @override
  String get legacyUi27 => 'කාලසටහන්ගත';

  @override
  String get legacyUi28 => 'අපේක්ෂිත පැමිණීම';

  @override
  String get legacyUi29 => 'නැගීමේ සහාය ඉල්ලන්න';

  @override
  String get legacyUi30 => 'මාර්ග නැවතුම් කාලසටහන සහ සජීවී ප්‍රගතිය';

  @override
  String get legacyUi31 => 'ඔබ නගින නැවතුම';

  @override
  String get legacyUi32 => 'බස් රථය දැන් මෙහි ඇත';

  @override
  String get legacyUi33 =>
      'තෝරාගත් කොටස සඳහා ඇස්තමේන්තුවකි; ගෙවීම් ක්‍රම තහවුරු කර නැත.';

  @override
  String get legacyUi34 => 'නොදනී — තත්ත්ව සාක්ෂි නොමැත.';

  @override
  String get legacyUi35 => 'වාහනයේ ප්‍රවේශ පහසුකම්';

  @override
  String get legacyUi36 => 'ප්‍රවේශ පහසුකම් අනතුරු ඇඟවීම';

  @override
  String get legacyUi37 => 'ප්‍රවේශ අපහසුතා දැනුම්දීම';

  @override
  String get legacyUi38 => 'තත්ත්වය නොදනී';

  @override
  String get legacyUi39 => 'ආරක්ෂාව සහ ගමන් තත්ත්ව';

  @override
  String get legacyUi40 => 'බස් රථයේ තදබද මට්ටම';

  @override
  String get legacyUi41 => 'ප්‍රජා ආරක්ෂක වාර්තා';

  @override
  String get legacyUi42 => 'ගමන සමාලෝචනය කර තහවුරු කරන්න';

  @override
  String get legacyUi43 => 'ගමන් සැලැස්මට සුරකින්න';

  @override
  String get legacyUi44 => 'ප්‍රවේශ තත්ත්වය වාර්තා කරන්න';

  @override
  String get legacyUi45 => 'ගමන පූරණය කළ නොහැක';

  @override
  String get legacyUi46 => 'සේවාදායකයෙන් සජීවී ගමන් විස්තර පූරණය කරමින්';

  @override
  String get legacyUi47 => 'ඔබේ ගමන පූරණය කරමින්…';

  @override
  String get legacyUi48 => 'බස් රථයක් තවම පවරා නැත.';

  @override
  String get legacyUi49 =>
      'සුරැකි ගමනකින් අසුනක් වෙන් කිරීමක් හෝ බස් පැවරීමක් සහතික නොවේ. තෝරාගත් සේවාවේ තත්ත්වය බලන්න.';

  @override
  String get legacyUi50 => 'මුල් පිටුවට ආපසු යන්න';

  @override
  String get legacyUi51 => 'සජීවී මගපෙන්වීම වසන්න';

  @override
  String get legacyUi52 => 'සජීවී මගපෙන්වීම';

  @override
  String get legacyUi53 => 'මාර්ග ප්‍රතිඵල වෙත ආපසු';

  @override
  String get legacyUi54 => 'සජීවී ගමන් ප්‍රගතිය';

  @override
  String get legacyUi55 => 'සජීවී';

  @override
  String get legacyUi56 => 'කාලසටහන';

  @override
  String get legacyUi57 => 'සජීවී නැවතුම් ප්‍රගතිය සහ පැමිණීමේ ඇස්තමේන්තුව';

  @override
  String get legacyUi58 => 'සජීවී නැවතුම්';

  @override
  String get legacyUi59 => 'ඔබේ නැවතුම';

  @override
  String get legacyUi60 => 'බස් රථය දැනට මෙහි ඇත';

  @override
  String get legacyUi61 => 'පසු කර ඇත';

  @override
  String get legacyUi62 =>
      'සජීවී GPS යාවත්කාලීන නොමැත. උපකරණ නිරීක්ෂණ පහතින් වෙනම දැක්වේ.';

  @override
  String get legacyUi63 => '● සිදුවෙමින්';

  @override
  String get legacyUi64 => '● කාලසටහන්ගත';

  @override
  String get legacyUi65 =>
      'ලුහුබැඳීම වාහනයේ වත්මන් පිහිටීම දක්වයි; ඔබේ කාලසටහන්ගත ධාවනය තහවුරු නොකරයි.';

  @override
  String get legacyUi66 => 'සවිස්තර වාහන දත්ත';

  @override
  String get legacyUi67 => 'වේගය, GPS සංඥා සහ මුල් ගමන් දත්ත';

  @override
  String get legacyUi68 => 'ළඟාවෙමින්';

  @override
  String get legacyUi69 => 'ඔබ මෙතැනින් නගින්න';

  @override
  String get legacyUi70 => 'කාලසටහන';

  @override
  String get legacyUi71 => 'සිතියම කුඩා කරන්න';

  @override
  String get legacyUi72 => 'සිතියම විශාල කරන්න';

  @override
  String get legacyUi73 => 'ගමන සම්පූර්ණයෙන් පෙන්වන්න';

  @override
  String get legacyUi74 => 'බස් රථය පෙන්වන්න';

  @override
  String get legacyUi75 => 'මගේ නැවතුම පෙන්වන්න';

  @override
  String get legacyUi76 => 'විශාල කරන්න';

  @override
  String get legacyUi77 => 'කුඩා කරන්න';

  @override
  String get legacyUi78 => 'GPS සංඥාව නොමැත';

  @override
  String get legacyUi79 => 'සංඥාව නැති විය';

  @override
  String get legacyUi80 => 'මාර්ගයේ ගමන් කරමින්';

  @override
  String get legacyUi81 => 'නවතා ඇත';

  @override
  String get legacyUi82 => 'ගමන අවසන්';

  @override
  String get legacyUi83 => 'සම්බන්ධතාව නොමැත';

  @override
  String get legacyUi84 => 'සුරැකි පිහිටීම — යාවත්කාලීන නොමැත';

  @override
  String get legacyUi85 => 'තත්ත්වය: සජීවී GPS යාවත්කාලීන ලැබෙමින්';

  @override
  String get legacyUi86 => 'තත්ත්වය: පිහිටීම නොමැත';

  @override
  String get legacyUi87 => 'ලබාගත නොහැක';

  @override
  String get legacyUi88 => 'වත්මන් තත්ත්වය';

  @override
  String get legacyUi89 => 'අවසන් යාවත්කාලීනය';

  @override
  String get legacyUi90 => 'ඊළඟ නැවතුම';

  @override
  String get legacyUi91 => 'ඔබේ ගමනාන්තය';

  @override
  String get legacyUi92 => 'ඊළඟ: ';

  @override
  String get legacyUi93 => 'අවසාන: ';

  @override
  String get legacyUi94 => 'නැගීමට හෝ බැසීමට රියදුරු සහාය ඉල්ලන්න';

  @override
  String get legacyUi95 => 'නැවතුම් සහාය ඉල්ලන්න';

  @override
  String get legacyUi96 =>
      'හදිසි ඇමතුම් නොමැත. සහාය ඇමතීමට ඔබේ දුරකථනය භාවිත කරන්න.';

  @override
  String get legacyUi97 => 'හදිසි සහාය';

  @override
  String get legacyUi98 => 'ප්‍රවේශ ගැටලුවක් හෝ වාහන තත්ත්වයක් වාර්තා කරන්න';

  @override
  String get legacyUi99 =>
      'මෙම යෙදුමේ හදිසි ඇමතුම් නොමැත. සහාය ඇමතීමට ඔබේ දුරකථනය භාවිත කරන්න.';

  @override
  String get legacyUi100 => 'එක් එක් නැවතුමේ සජීවී කාලරේඛාව';

  @override
  String get legacyUi101 => 'සජීවී ධාවනය';

  @override
  String get sharedCatalogueRefreshError =>
      'ප්‍රවාහන දත්ත නැවුම් කළ නොහැකි විය. සුරැකි දත්ත පැරණි විය හැක; සම්බන්ධ වූ පසු නැවත උත්සාහ කරන්න.';

  @override
  String legacyFormat0(String p0) {
    return 'බස් $p0';
  }

  @override
  String legacyFormat1(String p0) {
    return 'මාර්ගය $p0';
  }

  @override
  String legacyFormat2(String p0) {
    return 'ඉදිරි නැවතුම් ($p0)';
  }

  @override
  String legacyFormat3(String p0) {
    return 'කාලසටහන: $p0';
  }

  @override
  String legacyFormat4(String p0) {
    return 'මිනිත්තු $p0කින් පැමිණේ';
  }

  @override
  String legacyFormat5(String p0) {
    return 'ගමනාන්තය: $p0';
  }

  @override
  String legacyFormat6(String p0, String p1) {
    return '$p1 වෙත යන $p0 බස් රථය පෙන්වන සජීවී සිතියම';
  }

  @override
  String legacyFormat7(String p0) {
    return 'ඊළඟ නැවතුම: $p0';
  }

  @override
  String legacyFormat8(String p0, String p1, String p2, String p3) {
    return 'බස් තත්ත්වය: $p0. අවසන් යාවත්කාලීනය: $p1. ඊළඟ නැවතුම: $p2. මගියාගේ නැවතුම: $p3.';
  }

  @override
  String legacyFormat9(String p0) {
    return '$p0 හිදී';
  }

  @override
  String legacyFormat10(String p0) {
    return 'කාලසටහන: $p0';
  }

  @override
  String legacyFormat11(String p0) {
    return 'අපේක්ෂිත: $p0';
  }

  @override
  String legacyFormat12(String p0, String p1) {
    return 'රියදුරු දැනුම්දීම: $p0 (+මිනිත්තු $p1)';
  }

  @override
  String legacyFormat13(String p0, String p1) {
    return 'දුර: $p1 වෙත කි.මී. $p0';
  }

  @override
  String legacyFormat14(String p0, String p1) {
    return 'ගමන් ප්‍රගතිය: $p1 වෙත යන බස් රථය ඊළඟ $p0 නැවතුමට ළඟාවෙමින්';
  }

  @override
  String legacyFormat15(String p0) {
    return '$p0 හිදී අමතර කාලය හෝ බෑවුම අවශ්‍ය බව රියදුරුට දන්වන්න.';
  }

  @override
  String legacyFormat16(String p0) {
    return '$p0ට ළඟා විය';
  }

  @override
  String legacyFormat17(String p0) {
    return 'බස් රථය දැන් මෙහි ඇත ($p0ට තහවුරු කළා)';
  }

  @override
  String legacyFormat18(String p0, String p1) {
    return 'ඇස්තමේන්තුව: $p0 (මිනිත්තු $p1කින් පමණ)';
  }

  @override
  String legacyFormat19(String p0) {
    return 'තෝරාගත් කාලසටහන් පිටත්වීම: $p0 — වත්මන් GPS මෙම ධාවනය තහවුරු නොකරයි.';
  }

  @override
  String legacyFormat20(String p0) {
    return 'මිනිත්තු $p0ක් ප්‍රමාදයි';
  }

  @override
  String legacyFormat21(String p0, String p1) {
    return 'රියදුරු දැනුම්දීම: $p0 (+මිනිත්තු $p1)';
  }

  @override
  String legacyFormat22(String p0) {
    return '$p0 හිදී';
  }

  @override
  String legacyFormat23(String p0) {
    return '$p0ට පසු කළා';
  }

  @override
  String legacyFormat24(String p0, String p1) {
    return 'කාලසටහන: $p0 · අපේක්ෂිත: $p1';
  }

  @override
  String legacyFormat25(String p0) {
    return '(මිනිත්තු $p0ක් ප්‍රමාදයි)';
  }

  @override
  String legacyFormat26(String p0) {
    return 'තදබදය: $p0';
  }

  @override
  String get sharedOnTime => 'නියමිත වේලාවට';

  @override
  String get sharedSampleNotice =>
      'SAMPLE / TEST MODE — කල්පිත වාහන, වාර්තා, උපකරණ සහ GPS. ගමන් තීරණ සඳහා නොවේ.';

  @override
  String get sharedLocalNotice =>
      'LOCAL TEST ONLY — නියැදි සේවා පමණි; සැබෑ ප්‍රවාහනය හෝ Cloudinary උඩුගත කිරීම් නොමැත.';

  @override
  String get legacyEtaNow => 'බස් රථය දැන් පැමිණේ';

  @override
  String legacyEtaApprox(String minutes) {
    return 'බස් රථය මිනිත්තු $minutesකින් පමණ පැමිණේ';
  }

  @override
  String legacySpeedNext(String speed, String stop) {
    return 'පැ.කි.මී. $speed · ඊළඟ: $stop';
  }

  @override
  String get formReviewPublicNotice =>
      'ඔබේ වාර්තාව සහ ඡායාරූපය සියලු දෙනාට පෙනේ. මුහුණු සහ පෞද්ගලික තොරතුරු ඇතුළත් නොකරන්න.';

  @override
  String get formReviewDetails => 'පෞද්ගලිකත්වය සහ සුරැකි කෙටුම්පත්';

  @override
  String get formReviewCooldownShort =>
      'මෙම ස්ථානයේ එකම ගැටලුව නැවත වාර්තා කිරීමට විනාඩි 5ක් රැඳී සිටින්න.';

  @override
  String get deliveryServiceUnavailable =>
      'වාර්තා සේවාවට සම්බන්ධ විය නොහැක. කෙටුම්පත සුරැකී ඇත. සේවාව තිබෙන විට නැවත උත්සාහ කරන්න.';

  @override
  String get deliveryServiceConfiguration =>
      'මෙම යෙදුම වාර්තා සේවාවට සම්බන්ධ කර නැත. නිසි ලෙස සකස් කළ ප්‍රධාන යෙදුම විවෘත කර සුරැකි කෙටුම්පත නැවත යවන්න.';

  @override
  String get deliveryPermissionDenied =>
      'වාර්තාව පළ කිරීමට අවසර ලැබුණේ නැත. නිසි ලෙස සකස් කළ ප්‍රධාන යෙදුම භාවිත කරන බව පරීක්ෂා කර නැවත පිවිස උත්සාහ කරන්න. කෙටුම්පත සුරැකී ඇත.';

  @override
  String get deliveryTargetIneligible =>
      'මෙම බසය හෝ නැවතුම සඳහා වාර්තාව පළ කළ නොහැක. පරිපාලකයෙකු එහි නාමාවලි වාර්තාව පරීක්ෂා කළ යුතුය. කෙටුම්පත සුරැකී ඇත.';

  @override
  String get deliveryInvalidReport =>
      'සේවාවට මෙම වාර්තාවේ විස්තර පිළිගත නොහැකි විය. තෝරාගත් බසය හෝ නැවතුම සහ නිරීක්ෂණය පරීක්ෂා කර නැවත උත්සාහ කරන්න.';

  @override
  String get adminAccessibilityDetails => 'ප්‍රවේශ පහසුකම් විස්තර';

  @override
  String resultsOutsideNeeds(int count) {
    return 'ඔබගේ වත්මන් ප්‍රවේශ අවශ්‍යතා සපුරන්නේ නැති කාලසටහන් $countක් ඇත.';
  }

  @override
  String get resultsRemoveAccessFilters => 'ප්‍රවේශ පෙරහන් ඉවත් කර පෙන්වන්න';

  @override
  String get resultsTemporaryFiltersHelp =>
      'මෙම සෙවීමට පමණයි. මෙම සේවාවල ප්‍රවේශය නොදන්නා හෝ බාධා තිබිය හැක. සුරැකි මනාප වෙනස් නොවේ.';
}
