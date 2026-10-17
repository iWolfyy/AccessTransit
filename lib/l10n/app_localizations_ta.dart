// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get authControlsTitle => 'Firebase கணக்குக் கட்டுப்பாடுகள்';

  @override
  String get authControlsExplanation =>
      'உள்நுழைவு மற்றும் அமர்வுகளை நிர்வகிக்கவும். உள்நுழைவை மீட்டாலும் தனியான நிர்வாக மற்றும் சமூகத் தடைகள் தொடரும். சேவையக உறுதிப்படுத்தல் தேவை.';

  @override
  String get authDeleteExplanation =>
      'Firebase உள்நுழைவுக் கணக்கை நீக்கி தனிப்பட்ட சுயவிவரத்தின் அடையாளத் தகவல்களை அகற்றும். பொதுவான அறிக்கைகள், பயணங்கள் மற்றும் தணிக்கைக் குறிப்புகள் பாதுகாக்கப்படும். முதலில் உள்நுழைவை முடக்கி இயங்கும் பயணங்களைச் சீரமைக்கவும். இதை மீட்டமைக்க முடியாது.';

  @override
  String get authCancel => 'ரத்துசெய்';

  @override
  String get authConfirmRequired =>
      'நீக்கத்தை உறுதிப்படுத்த சரியான கணக்கு UID ஐ உள்ளிடவும்.';

  @override
  String get authDisableFirst =>
      'நீக்கத்தை அங்கீகரிப்பதற்கு முன் உள்நுழைவை முடக்கவும்.';

  @override
  String get authActiveTrip =>
      'நீக்கத்திற்கு முன் இயங்கும் பயணத்தைச் சீரமைக்க வேண்டும்.';

  @override
  String get authPending =>
      'செயல் நிலுவையில் உள்ளது அல்லது மறுஆய்வு தேவை. அடுத்த முடிவுக்கு முன் முடிவை மீண்டும் ஏற்றவும்.';

  @override
  String get authNormalScope =>
      'Firebase Auth கட்டுப்பாடுகள் சாதாரண கணக்குச் சூழலில் மட்டுமே கிடைக்கும்.';

  @override
  String get authReload => 'கணக்கு நிலையை மீண்டும் ஏற்று';

  @override
  String get authDeleted =>
      'கணக்கு நீக்கப்பட்டது; அனுமதிக்கப்பட்ட ஆய்வாளர்களுக்கு வரலாறு பாதுகாக்கப்பட்டுள்ளது.';

  @override
  String get authDisabled => 'Firebase உள்நுழைவு முடக்கப்பட்டுள்ளது';

  @override
  String get authEnabled => 'Firebase உள்நுழைவு செயலிலுள்ளது';

  @override
  String get authCompleted => 'கடைசி செயல் முடிந்தது';

  @override
  String get authReconcile => 'அதே செயலை ஆய்வு செய்து மீண்டும் முயலவும்';

  @override
  String get authConfirmLabel => 'நீக்கத்தை உறுதிப்படுத்தும் கணக்கு UID';

  @override
  String get authEnable => 'உள்நுழைவை இயக்கு';

  @override
  String get authDisable => 'உள்நுழைவை முடக்கு';

  @override
  String get authRevoke => 'தற்போதைய அமர்வுகளை ரத்துசெய்';

  @override
  String get authDeleteRequest => 'நீக்க மறுஆய்வைக் கோரு';

  @override
  String get authDeleteReject => 'நீக்கத்தை நிராகரி';

  @override
  String get authDeleteApprove => 'கணக்கு நீக்கத்தை அங்கீகரி';

  @override
  String accountControlsUntil(String when) {
    return '$when வரை (Asia/Colombo)';
  }

  @override
  String get accountControlsTitle => 'கணக்கு அணுகல்';

  @override
  String get accountControlsExplanation =>
      'இந்தச் சூழலில் செயலி அணுகலை நிர்வகிக்கவும். நிர்வாகத் தடையை நீக்கினாலும் சமூகத் தடைகள் தொடரும். இயங்கும் ஓட்டுநர் பயணங்கள் சேவையகத்தால் சீரமைக்கப்படும்.';

  @override
  String get accountControlsReasonRequired =>
      '5 முதல் 2,000 எழுத்துகள் கொண்ட காரணத்தை உள்ளிடவும்.';

  @override
  String get accountControlsStale =>
      'கணக்கு அணுகல் மாறியுள்ளது. முடிவுக்கு முன் மீண்டும் ஏற்றவும்.';

  @override
  String get accountControlsProtected =>
      'உங்கள் கணக்கும் நிர்வாகி கணக்குகளும் பாதுகாக்கப்பட்டுள்ளன.';

  @override
  String get accountControlsUnavailable =>
      'அணுகலை உறுதிப்படுத்த முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get accountControlsRestricted => 'நிர்வாகத் தடை செயலிலுள்ளது';

  @override
  String get accountControlsClear => 'செயலில் நிர்வாகத் தடை இல்லை';

  @override
  String get accountControlsCommunity =>
      'தனியான சமூகத் தடை தொடர்ந்து செயலிலுள்ளது.';

  @override
  String get accountControlsIndefinite => 'நிர்வாகி அணுகலை மீட்டமைக்கும் வரை';

  @override
  String get accountControlsDuration =>
      'இல்லையெனில் சேவையக நேரத்திலிருந்து 72 மணிநேரம் இடைநிறுத்தப்படும்.';

  @override
  String get accountControlsSuspend => 'அணுகலை இடைநிறுத்து';

  @override
  String get accountControlsRestore => 'நிர்வாகத் தடையை நீக்கு';

  @override
  String get accountControlsRetry => 'மீண்டும் முயலவும்';

  @override
  String get busDetails => 'பேருந்து விவரங்கள்';

  @override
  String get communityReports => 'சமூக அறிக்கைகள்';

  @override
  String get saveTrip => 'பயணத்தைச் சேமிக்கவும்';

  @override
  String get removeSavedTrip => 'சேமித்த பயணத்தை அகற்றவும்';

  @override
  String get savedTrip => 'சேமித்த பயணம்';

  @override
  String get noRecentReports => 'சமீபத்திய அறிக்கைகள் இல்லை';

  @override
  String get loadingReports => 'அறிக்கைகள் ஏற்றப்படுகின்றன…';

  @override
  String get requestBoardingAssistance => 'ஏறுவதற்கான உதவியைக் கோரவும்';

  @override
  String get reportCondition => 'நிலையைப் புகாரளிக்கவும்';

  @override
  String get language => 'மொழி';

  @override
  String get languageSaveFailed =>
      'மொழியைச் சேமிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get searchWindowInvalid =>
      'அடுத்த 24 மணி நேரத்திற்குள் பேருந்தில் ஏறும் நேரத்தைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get searchSelectionExpired =>
      'இந்தத் தேர்வு காலாவதியாகிவிட்டது. தற்போதைய முடிவுகளை மீண்டும் பார்க்கவும்.';

  @override
  String get searchAccountChanged =>
      'கணக்கு மாறிவிட்டது. புதிய தேடலைத் தொடங்க தேடல் பக்கத்திற்குத் திரும்பவும்.';

  @override
  String get searchWindowNotice =>
      'அடுத்த 24 மணி நேரத்திற்குள் ஏறக்கூடிய சேவைகள். கால அட்டவணை நேரம் பேருந்து இயங்குவதை உறுதிப்படுத்தாது.';

  @override
  String get welcomeBack => 'மீண்டும் வரவேற்கிறோம்';

  @override
  String get signIn => 'உள்நுழைக';

  @override
  String get email => 'மின்னஞ்சல்';

  @override
  String get emailHint => 'உங்கள் மின்னஞ்சல் முகவரியை உள்ளிடவும்';

  @override
  String get passenger => 'பயணி';

  @override
  String get passengerDescription =>
      'அணுகல் வசதியுள்ள பயணங்களைத் திட்டமிடுங்கள்';

  @override
  String get reporter => 'அறிக்கையாளர்';

  @override
  String get reporterDescription =>
      'பேருந்து மற்றும் நிறுத்த நிலைகளைப் பதிவிடுங்கள்';

  @override
  String get driver => 'பேருந்து ஓட்டுநர்';

  @override
  String get driverDescription => 'நிர்வாகியின் ஒப்புதல் தேவை';

  @override
  String get operatorApprovalRequired =>
      'கணக்கு உருவாக்கப்பட்டது. ஓட்டுநர் அணுகலுக்கு நிர்வாகியின் ஒப்புதல் தேவை.';

  @override
  String accountReady(String name) {
    return 'வரவேற்கிறோம், $name! உங்கள் கணக்கு தயாராக உள்ளது.';
  }

  @override
  String get verifyingSearchTime => 'தேடல் நேரம் சரிபார்க்கப்படுகிறது…';

  @override
  String get searchTimeUnavailable =>
      'தேடல் நேரம் கிடைக்கவில்லை. இணையத்தில் இணைந்து மீண்டும் முயலவும்.';

  @override
  String get retrySearchTime => 'நேரத்தை மீண்டும் சரிபார்க்கவும்';

  @override
  String get retrySearch => 'மீண்டும் தேடவும்';

  @override
  String get verifyingDatedSearch =>
      'தேடல் நேரமும் தேதியிட்ட பயணங்களும் சரிபார்க்கப்படுகின்றன…';

  @override
  String get datedSearchUnavailable =>
      'தேதியிட்ட பயணங்கள் கிடைக்கவில்லை. இணையத்தில் இணைந்து மீண்டும் முயலவும்.';

  @override
  String get nearbyStopsTitle => 'அருகிலுள்ள ஏறும் நிறுத்தங்கள்';

  @override
  String get nearbyStopsExplanation =>
      'ஏறும் நிறுத்தத்தைத் தேர்ந்தெடுக்கவும். இவை தோராயமான நேர்கோட்டுத் தூரங்கள்; நடைபாதையோ பயண நேரமோ அல்ல. நிறுத்தத்தின் திசையையும் சாலையின் பக்கத்தையும் சரிபார்க்கவும்.';

  @override
  String get nearbyLocating => 'உங்கள் இருப்பிடம் கண்டறியப்படுகிறது...';

  @override
  String get nearbyLocationDisabled =>
      'சாதனத்தின் இருப்பிடச் சேவையை இயக்கி மீண்டும் முயலவும்.';

  @override
  String get nearbyLocationDenied =>
      'இருப்பிட அனுமதி மறுக்கப்பட்டது. நிறுத்தத்தை நீங்களே தேர்ந்தெடுக்கலாம்.';

  @override
  String get nearbyLocationBlocked =>
      'செயலி அமைப்புகளில் இருப்பிட அனுமதியை வழங்கி மீண்டும் முயலவும்.';

  @override
  String get nearbyLocationUnavailable =>
      'பயன்படுத்தக்கூடிய இருப்பிடம் கிடைக்கவில்லை. மீண்டும் முயலவும் அல்லது நிறுத்தத்தை நீங்களே தேர்ந்தெடுக்கவும்.';

  @override
  String get nearbyOpenSettings => 'அமைப்புகளைத் திறக்கவும்';

  @override
  String get nearbyRetry => 'இருப்பிடத்தை மீண்டும் தேடவும்';

  @override
  String get nearbyChooseManually => 'நிறுத்தத்தை நீங்களே தேர்ந்தெடுக்கவும்';

  @override
  String get nearbyStopsEmpty =>
      'சரியான ஆயத்தொலைவுகளைக் கொண்ட நிறுத்தங்கள் இல்லை.';

  @override
  String nearbyDistance(String km) {
    return 'சுமார் $km கி.மீ. தொலைவில்';
  }

  @override
  String get reportCooldownNotice =>
      'வெவ்வேறு பிரச்சினைகளைப் புகாரளிக்க தினசரி வரம்பு இல்லை. அதே பேருந்து அல்லது நிறுத்தத்தில் அதே பிரச்சினை வகையை மீண்டும் புகாரளிக்க 5 நிமிடங்கள் காத்திருக்கவும்.';

  @override
  String get falseVoteReason => 'இந்தப் புகார் ஏன் தவறானது?';

  @override
  String get falseVoteReasonMinimum => 'குறைந்தது 5 எழுத்துகளை உள்ளிடவும்.';

  @override
  String get voteCancel => 'ரத்து';

  @override
  String get voteSubmit => 'வாக்கைச் சமர்ப்பிக்கவும்';

  @override
  String get voteAcknowledged => 'வாக்கு பதிவு செய்யப்பட்டது.';

  @override
  String get voteUnavailable =>
      'வாக்கு உறுதிப்படுத்தப்படவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get voteSignIn => 'வாக்களிக்க உள்நுழையவும்.';

  @override
  String get authorVoteDisabled =>
      'உங்கள் சொந்தப் புகாருக்கு வாக்களிக்க முடியாது.';

  @override
  String get voteRetry => 'வாக்கு நிலையை மீண்டும் பார்க்கவும்';

  @override
  String get votingClosed => 'வாக்களிப்பு முடிவடைந்தது.';

  @override
  String get voteNoPoints =>
      'வாக்குகளுக்குப் புள்ளிகள் இல்லை. ஐந்து தவறு வாக்குகள் புகாரை மறைக்கும்.';

  @override
  String get voteTrue => 'உண்மை';

  @override
  String get voteFalse => 'தவறு';

  @override
  String get accountStatusChecking => 'கணக்கு அணுகல் சரிபார்க்கப்படுகிறது...';

  @override
  String get accountStatusUnavailable =>
      'கணக்கு அணுகலைச் சரிபார்க்க முடியவில்லை. இணைந்து மீண்டும் முயலவும்.';

  @override
  String get accountSuspended =>
      'கணக்கு இடைநிறுத்தப்பட்டுள்ளது. நிர்வாகியின் மதிப்பாய்வு தேவை.';

  @override
  String accountTemporaryUntil(String until) {
    return 'கணக்கு $until (UTC) வரை தற்காலிகமாக இடைநிறுத்தப்பட்டுள்ளது.';
  }

  @override
  String get accountStatusRetry => 'கணக்கு நிலையை மீண்டும் பார்க்கவும்';

  @override
  String get accountSignOut => 'வெளியேறு';

  @override
  String get v2PointsNotice =>
      'வெளியிடப்பட்ட புகாருக்கு 10 புள்ளிகள்; வாக்குகளுக்குப் புள்ளிகள் இல்லை. ஐந்து தவறு வாக்குகள் கிடைத்த புள்ளிகளின் இருமடங்கைக் கழிக்கும். புள்ளிகளுக்குப் பண மதிப்பு இல்லை.';

  @override
  String get refreshV2Points => 'v2 புள்ளிகளைப் புதுப்பிக்கவும்';

  @override
  String get reviewsTitle => 'என் அறிக்கை மதிப்பாய்வுகள்';

  @override
  String get reviewsAdminTitle => 'அறிக்கை மதிப்பாய்வு';

  @override
  String get reviewsError =>
      'மதிப்பாய்வைச் சரிபார்க்க முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get reviewsReasonRequired =>
      '5 முதல் 2,000 எழுத்துகளுக்குள் காரணத்தை உள்ளிடவும்.';

  @override
  String get reviewsPending => 'மேல்முறையீடு நிலுவையில் உள்ளது';

  @override
  String get reviewsUpheld => 'முடிவு உறுதிப்படுத்தப்பட்டது';

  @override
  String get reviewsOverturned =>
      'முடிவு மாற்றப்பட்டு கழித்த புள்ளிகள் மீட்டளிக்கப்பட்டன';

  @override
  String get reviewsUnreviewed => 'மதிப்பாய்வுக்காகக் காத்திருக்கிறது';

  @override
  String get reviewsEmpty => 'சமூகத்தால் மறுக்கப்பட்ட அறிக்கைகள் இல்லை.';

  @override
  String get reviewsMore => 'மேலும் காட்டு';

  @override
  String reviewsPenalty(int points, int strikes) {
    return 'கழித்த புள்ளிகள்: $points. கணக்கிட்ட தவறுகள்: $strikes.';
  }

  @override
  String reviewsHiddenReason(int count) {
    return 'மற்ற பயனர்கள் $count பேர் தவறு எனக் குறிப்பிட்டதால் அறிக்கை தானாக மறைக்கப்பட்டது.';
  }

  @override
  String get reviewsAppealLabel => 'உங்கள் மேல்முறையீடு';

  @override
  String get reviewsDecisionReason => 'நிர்வாக முடிவின் காரணம்';

  @override
  String get reviewsVotes => 'சமூக வாக்குச் சான்றுகள்';

  @override
  String get reviewsReason => 'காரணம்';

  @override
  String get reviewsDecisionExplanation =>
      'முடிவை மாற்றுவது கழித்த புள்ளிகளையும் இந்தத் தவறின் எண்ணிக்கையையும் ஒருமுறை மீட்டமைக்கும். பிற கணக்குக் கட்டுப்பாடுகள் தொடரும்.';

  @override
  String get reviewsUphold => 'முடிவை உறுதிசெய்';

  @override
  String get reviewsOverturn => 'முடிவை மாற்று';

  @override
  String get reviewsSubmit => 'மேல்முறையீடு அனுப்பு';

  @override
  String get reviewsAcknowledged =>
      'மாற்றம் சேவையகத்தால் உறுதிப்படுத்தப்பட்டது.';

  @override
  String get reviewsPhoto => 'அறிக்கை புகைப்படம்';

  @override
  String get reviewsPhotoUnavailable => 'அறிக்கை புகைப்படம் கிடைக்கவில்லை.';

  @override
  String get bansTitle => 'நிரந்தரத் தடை மதிப்பாய்வுகள்';

  @override
  String get bansApproved => 'நிரந்தரத் தடை அங்கீகரிக்கப்பட்டது';

  @override
  String get bansRejected => 'நிரந்தரத் தடை நிராகரிக்கப்பட்டது';

  @override
  String get bansWithdrawn => 'மதிப்பாய்வு திரும்பப் பெறப்பட்டது';

  @override
  String get bansPending => 'நிர்வாக மதிப்பாய்வு நிலுவையில் உள்ளது';

  @override
  String get bansEmpty => 'நிரந்தரத் தடை மதிப்பாய்வுகள் இல்லை.';

  @override
  String bansStrikes(int count) {
    return 'தற்போதைய தவறுகள்: $count';
  }

  @override
  String get bansAppealsPending =>
      'நிரந்தரத் தடையை அங்கீகரிக்கும் முன் நிலுவை அறிக்கை மேல்முறையீடுகளைத் தீர்க்கவும்.';

  @override
  String get bansStale =>
      'சான்றுகள் மாறியுள்ளன. முடிவுக்கு முன் மீண்டும் ஏற்றவும்.';

  @override
  String get bansAdminProtected =>
      'இந்தச் செயல்முறை நிர்வாகக் கணக்குகளைத் தடை செய்யாது.';

  @override
  String get bansEvidence => 'தொடர்புடைய அறிக்கைகளும் மேல்முறையீடுகளும்';

  @override
  String get bansCounted => 'தவறு கணக்கிடப்பட்டுள்ளது';

  @override
  String get bansRemoved => 'தவறின் எண்ணிக்கை நீக்கப்பட்டது';

  @override
  String get bansExplanation =>
      'பத்து தவறுகள் மதிப்பாய்வைத் தொடங்கும். வெளிப்படையான அங்கீகாரம் மட்டுமே நிரந்தரக் கட்டுப்பாட்டை விதிக்கும். நிராகரிப்பு தற்காலிகத் தடையை நீட்டிக்காது.';

  @override
  String get bansReject => 'நிரந்தரத் தடையை நிராகரி';

  @override
  String get bansApprove => 'நிரந்தரத் தடையை அங்கீகரி';

  @override
  String get assistanceInbox => 'இந்தப் பயண உதவிக் கோரிக்கைகள்';

  @override
  String get assistanceChooseRun =>
      'Bus Details மூலம் ஓட்டுநர் ஒதுக்கப்பட்ட தேதியுள்ள பயணத்தைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get assistanceUnavailable =>
      'உதவி கிடைக்கவில்லை. பயணம், ஓட்டுநர் ஒதுக்கீடு மற்றும் இணைப்பைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get assistanceEmpty => 'இந்தப் பயணத்திற்கு உதவிக் கோரிக்கைகள் இல்லை.';

  @override
  String get assistanceRetargeted =>
      'ஓட்டுநர் மாறியுள்ளார். தற்போதைய ஓட்டுநரின் ஒப்புதலுக்காகக் காத்திருக்கிறது.';

  @override
  String get assistancePending => 'ஓட்டுநரின் ஒப்புதலுக்காகக் காத்திருக்கிறது';

  @override
  String get assistanceAccepted => 'ஓட்டுநர் ஏற்றுக்கொண்டார்';

  @override
  String get assistanceDeclined => 'ஓட்டுநர் நிராகரித்தார்';

  @override
  String get assistanceCompleted => 'ஓட்டுநர் உதவி முடிந்ததாகக் குறித்தார்';

  @override
  String get assistanceCancelled => 'ரத்து செய்யப்பட்டது';

  @override
  String get assistanceExpired => 'கோரிக்கை காலாவதியானது';

  @override
  String get assistanceAcknowledge => 'ஏற்றுக்கொள்';

  @override
  String get assistanceDecline => 'நிராகரி';

  @override
  String get assistanceComplete => 'முடி';

  @override
  String get assistanceInAppOnly =>
      'செயலியின் கோரிக்கைப் பட்டியலுக்கு அனுப்பப்பட்டது. உள்ளூர் சோதனையில் பின்னணி push அறிவிப்புகள் செயல்படுத்தப்படவில்லை.';

  @override
  String assistanceExpiry(String time) {
    return 'கோரிக்கை காலாவதியாகும் நேரம் (UTC): $time';
  }

  @override
  String get assistanceRunEnded =>
      'இந்தப் பயணம் முடிந்துவிட்டது அல்லது ரத்து செய்யப்பட்டது.';

  @override
  String get assistanceStopPassed =>
      'கோரிய ஏறும் வாய்ப்பைப் பேருந்து கடந்துவிட்டது.';

  @override
  String get assistanceDriverUnavailable =>
      'ஒதுக்கப்பட்ட ஓட்டுநர் இப்போது கிடைக்கவில்லை.';

  @override
  String get assistanceRamp => 'சாய்வுப் பலகையை அமைக்கவும்';

  @override
  String get assistanceExtraTime => 'கூடுதல் நேரம்';

  @override
  String get assistanceBoardingHelp => 'ஏறுவதற்கான உதவி';

  @override
  String get assistanceAlightingHelp => 'இறங்குவதற்கான உதவி';

  @override
  String get operationsTitle => 'செயலில் உள்ள பயணங்கள்';

  @override
  String get operationsRefresh => 'சேவையகத்திலிருந்து புதுப்பிக்கவும்';

  @override
  String get operationsEmpty => 'செயலில் உள்ள தேதியிட்ட பயணங்கள் இல்லை.';

  @override
  String get operationsMore => 'மேலும் ஏற்றவும்';

  @override
  String get operationsExplanation =>
      'இதே வழித்தடத்திற்கு ஒதுக்கப்பட்ட அங்கீகரிக்கப்பட்ட ஓட்டுநரிடம் பயணத்தை மாற்றவும். பயண முன்னேற்றமும் பதிவான நேரங்களும் மாறாது. புதிய ஓட்டுநர் புதிய இருப்பிடத்துடன் தொடரும் வரை GPS இடைநிறுத்தப்படும். உதவிக் கோரிக்கைகளை புதிய ஓட்டுநர் ஏற்க வேண்டும்.';

  @override
  String get operationsDone =>
      'மாற்றம் உறுதிசெய்யப்பட்டது. புதிய ஓட்டுநர் தொடரும் வரை GPS இடைநிறுத்தப்பட்டுள்ளது. உதவிக் கோரிக்கைகள் பின்னணியில் மீண்டும் ஒதுக்கப்படும்; முந்தைய ஏற்பு தொடராது.';

  @override
  String get operationsNoDrivers =>
      'இந்தப் பக்கத்தில் தகுதியான ஓட்டுநர் இல்லை. முதலில் கிடைக்கக்கூடிய ஓட்டுநரை அங்கீகரித்து இந்த வழித்தடத்திற்கு ஒதுக்கவும்.';

  @override
  String get operationsReason => 'மாற்றத்திற்கான காரணம் (5–2000 எழுத்துகள்)';

  @override
  String get operationsTransfer => 'பயணத்தை மாற்றவும்';

  @override
  String get operationsSaving => 'மாற்றப்படுகிறது…';

  @override
  String get operationsError =>
      'இந்தச் செயலை உறுதிப்படுத்த முடியவில்லை. அதே கோரிக்கையை மீண்டும் முயலவும் அல்லது தற்போதைய நிலையைப் புதுப்பித்துப் பார்க்கவும்.';

  @override
  String get operationsStale =>
      'பயணம் அல்லது ஓட்டுநரின் தகுதி மாறியுள்ளது. மாற்றுவதற்கு முன் புதுப்பிக்கவும்.';

  @override
  String get operationsResume => 'ஏற்று GPS ஐ தொடரவும்';

  @override
  String get operationsGpsError =>
      '100 மீட்டருக்குள் துல்லியமான புதிய GPS இருப்பிடம் கிடைக்கும் வரை காத்திருந்து மீண்டும் ஏற்றுத் தொடரவும்.';

  @override
  String get pushTitle => 'உதவிக் கோரிக்கை அறிவிப்புகள்';

  @override
  String get pushChannelDescription =>
      'பயணிகளின் உதவிக் கோரிக்கைகள் பற்றிய அறிவிப்புகள்';

  @override
  String get pushOff =>
      'அறிவிப்புகள் அணைக்கப்பட்டுள்ளன. ஓட்டுநரின் கோரிக்கைப் பட்டியல் தொடர்ந்து கிடைக்கும்.';

  @override
  String get pushConnecting => 'அறிவிப்புகள் இணைக்கப்படுகின்றன…';

  @override
  String get pushDenied =>
      'அறிவிப்பு அனுமதி மறுக்கப்பட்டுள்ளது. Android செயலி அமைப்புகளில் அனுமதிக்கலாம்.';

  @override
  String get pushReady =>
      'இந்தச் சாதனம் பதிவு செய்யப்பட்டுள்ளது. அறிவிப்பு வந்ததால் உதவிக் கோரிக்கை ஏற்கப்பட்டதாகாது.';

  @override
  String get pushUnavailable =>
      'அறிவிப்பு அமைப்பை உறுதிப்படுத்த முடியவில்லை. மீண்டும் முயலவும் அல்லது கோரிக்கைப் பட்டியலைப் பயன்படுத்தவும்.';

  @override
  String get pushEnable => 'அறிவிப்புகளை இயக்கவும்';

  @override
  String get pushDisable => 'அணைக்கவும்';

  @override
  String get pushOpenUnavailable =>
      'இந்தக் கோரிக்கை கிடைக்கவில்லை அல்லது இனி உங்கள் கணக்கிற்கு ஒதுக்கப்படவில்லை.';

  @override
  String get pushForeground => 'ஒரு பயணி உதவி கோரியுள்ளார்.';

  @override
  String get pushReview => 'கோரிக்கையைப் பார்க்கவும்';

  @override
  String get fareUnavailable => 'கட்டணம் கிடைக்கவில்லை';

  @override
  String get fareUnavailableDisclosure =>
      'இந்தத் தேர்விற்கான சரிபார்க்கப்பட்ட கட்டண அட்டவணையும் கட்டண நிலை இணைப்பும் கிடைக்கவில்லை. நடத்துநரிடம் கட்டணத்தை உறுதிப்படுத்தவும்.';

  @override
  String get fareSampleDisclosure =>
      'Sample/Test மதிப்பீடு மட்டுமே. நேரம்/நிறுத்தங்கள் சார்ந்த இக்கணக்கு அதிகாரப்பூர்வ கட்டணம் அல்ல. உண்மையான கட்டணத்தை நடத்துநரிடம் உறுதிப்படுத்தவும்.';

  @override
  String fareSampleAmount(int amount) {
    return 'Sample மதிப்பீடு LKR $amount';
  }

  @override
  String fareReviewedSource(String source, String tariff, String mapping) {
    return 'சரிபார்க்கப்பட்ட மூலம்: $source. கட்டணம் $tariff; இணைப்பு $mapping.';
  }

  @override
  String fareReviewedAmount(String amount) {
    return 'LKR $amount';
  }

  @override
  String fareSampleReviewed(String amount) {
    return 'Sample கட்டணம் LKR $amount';
  }

  @override
  String get fareChanged =>
      'கட்டணப் பதிப்பு மாறியுள்ளது அல்லது கிடைக்கவில்லை. சேமித்த தேர்வு பாதுகாக்கப்பட்டுள்ளது; பயணத்திற்கு முன் தற்போதைய கட்டணத்தைச் சரிபார்க்கவும்.';

  @override
  String get fareAdminTitle => 'கட்டண வெளியீடுகள்';

  @override
  String get fareImportHelp =>
      'சரிபார்க்கப்பட்ட கட்டண அட்டவணை, வரிசைப்படியான நிறுத்த-நிலை இணைப்பு மற்றும் bus IDs ஐ இறக்குமதி செய்யவும். LKR 1 = 100 சிறு அலகுகள். வெளியிடும் முன் மதிப்புகள், மூலம், வகுப்பு மற்றும் தேதிகளைச் சரிபார்க்கவும். வெளியிட்ட பதிப்புகளை மாற்ற முடியாது; காப்பகப்படுத்தி புதிய ID உருவாக்கவும்.';

  @override
  String get farePublicationId => 'புதிய வெளியீட்டு ID';

  @override
  String get fareImportJson => 'சரிபார்க்கப்பட்ட import JSON';

  @override
  String get farePreview => 'சரிபார்த்து முன்னோட்டம் பார்க்கவும்';

  @override
  String get fareReviewCheck =>
      'மூலம், வாகன வகுப்பு, திசை, நிறுத்த-நிலை இணைப்பு மற்றும் தேதிகளைச் சரிபார்த்தேன்.';

  @override
  String get fareReviewReason =>
      'சரிபார்ப்பு/காப்பகக் காரணம் (10–2000 எழுத்துகள்)';

  @override
  String get farePublish => 'சரிபார்த்த பதிப்பை வெளியிடவும்';

  @override
  String get fareArchive => 'பதிப்பைக் காப்பகப்படுத்தவும்';

  @override
  String get fareCancel => 'ரத்து செய்யவும்';

  @override
  String get fareInvalidImport =>
      'இறக்குமதி செல்லாது. ஆவணப்படுத்திய வடிவம், IDs, முழு எண் மதிப்புகள், மூலம் மற்றும் தேதி/இணைப்பைச் சரிபார்க்கவும்.';

  @override
  String get fareAdminError =>
      'செயலை உறுதிப்படுத்த முடியவில்லை. இணைப்பு, admin அனுமதி, காரணம் மற்றும் தற்போதைய bus/route தரவைச் சரிபார்க்கவும். மாறிய வெளியீட்டை மீண்டும் ஏற்றவும்.';

  @override
  String get fareNoPublications =>
      'கட்டண வெளியீடுகள் இல்லை. விடுபட்ட கட்டணங்கள் கிடைக்காததாகக் காட்டப்படும்.';

  @override
  String get geometryTitle => 'வழித்தட வடிவத் தரவு';

  @override
  String get geometryHelp =>
      'சரிபார்க்கப்பட்ட திசைசார் சாலைப் பாதையையும் வரிசைப்படுத்திய நிறுத்தப் புள்ளிகளையும் உள்ளிடவும். தற்போதைய வழித்தடம் மற்றும் நிறுத்த ஆயத்தொலைவுகளுடன் பொருந்த வேண்டும். திருத்தங்களுக்கு புதிய பதிப்பைப் பயன்படுத்தவும். இது நேரடி போக்குவரத்துத் தரவை வழங்காது.';

  @override
  String get geometryReview =>
      'சாலைப் பாதை, திசை, நிறுத்தப் புள்ளிகள் மற்றும் மூலத்தைச் சரிபார்த்தேன்.';

  @override
  String get geometryInvalid =>
      'தரவு செல்லாது. JSON, route ID, ஆயத்தொலைவுகள், மூலம் மற்றும் நிறுத்த வரிசையைச் சரிபார்க்கவும்.';

  @override
  String get geometrySaved =>
      'சரிபார்க்கப்பட்ட வழித்தடத் தரவு வெளியிடப்பட்டது.';

  @override
  String get geometryWithdraw => 'தற்போதைய வழித்தடத் தரவை விலக்கவும்';

  @override
  String get geometryMap =>
      'சரிபார்க்கப்பட்ட சாலைப் பாதை · தேர்ந்தெடுத்த பகுதி';

  @override
  String geometryEta(String target, String start, String end) {
    return '$target: மதிப்பீடு $start–$end · பாதை முன்னேற்றம் மற்றும் நேர அட்டவணை; குறைந்த நம்பகத்தன்மை.';
  }

  @override
  String get geometryWithdrawn => 'வழித்தடத் தரவு விலக்கப்பட்டது.';

  @override
  String get etaDiagnostics => 'உள்ளூர் ETA ஆய்வு';

  @override
  String get etaDiagnosticsUnavailable =>
      'உள்ளூர் சோதனை ஆய்விற்கு உள்நுழைந்த கணக்கு ஏற்றப்பட வேண்டும்.';

  @override
  String get etaDiagnosticsHelp =>
      'LOCAL TEST ONLY. Bus Details திறந்திருக்கும் போது கணிப்புகளைப் பதிவு செய்ய இயக்கவும். வருகைகள் ஓட்டுநர் உறுதிப்படுத்திய நேரங்கள்; சுயாதீன GPS அளவீடுகள் அல்ல. செயல்பாட்டு துல்லியக் கூற்று இல்லை. பதிவுகள் இந்தச் சாதனம்/கணக்கில் மட்டும் இருக்கும் (அதிகபட்சம் 500; பதிவு செய்யும்போது ஏழு நாள் வரம்பு). ஆயத்தொலைவுகள், மின்னஞ்சல்கள் அல்லது ஓட்டுநர் IDs சேமிக்கப்படாது.';

  @override
  String get etaCapture => 'உள்ளூர் கணிப்புகளைப் பதிவு செய்';

  @override
  String etaCounts(int captured, int pending, int excluded) {
    return 'பதிவுகள்: $captured · நிலுவை: $pending · விலக்கப்பட்டவை: $excluded';
  }

  @override
  String etaMetrics(int count, String median, String p90) {
    return 'பொருந்திய மாதிரிகள்: $count · இடைநிலைப் பிழை: ${median}s · P90 பிழை: ${p90}s';
  }

  @override
  String get etaStorageError =>
      'உள்ளூர் சேமிப்பு/வாசிப்பு உறுதியாகவில்லை. ஏற்றுமதியில் சேமிக்கப்படாத பதிவுகள் இருக்கலாம்; மீண்டும் முயலவும்.';

  @override
  String get etaNoMatchedSamples =>
      'பொருந்திய வருகைகள் இன்னும் இல்லை. நிலுவை/விலக்கப்பட்ட கணிப்புகள் பூஜ்ஜியப் பிழையாகக் கணக்கிடப்படாது.';

  @override
  String get etaSmallSample =>
      'சிறிய செயற்கை மாதிரி; இது நிஜ உலகத் துல்லியத்தை நிறுவாது.';

  @override
  String get etaCopied => 'உள்ளூர் ஆய்வு JSON நகலெடுக்கப்பட்டது.';

  @override
  String get etaExport => 'ஆய்வு JSON நகலெடு';

  @override
  String get etaClear => 'இந்தக் கணக்கின் உள்ளூர் அளவீடுகளை அழி';

  @override
  String get savedTripsTitle => 'சேமித்த பயணங்கள்';

  @override
  String get savedTripsViewAll => 'சேமித்த அனைத்து பயணங்களையும் காண்க';

  @override
  String get savedTripsHelp =>
      'கடந்த பதிவுகள் உட்பட உங்கள் சேமித்த தேர்வுகள். சேமிப்பது இருக்கை முன்பதிவு அல்லது கண்காணிப்பு தொடக்கம் அல்ல. தேர்ந்தெடுத்த பயணத்தின் தற்போதைய நிலையைப் புதுப்பிக்க விவரங்களைத் திறக்கவும்.';

  @override
  String get savedTripsRefresh => 'சேமித்த பயணங்களைப் புதுப்பி';

  @override
  String get savedTripsAccountChanged =>
      'கணக்கு மாறியுள்ளது. முகப்பிற்குச் சென்று சேமித்த பயணங்களை மீண்டும் திறக்கவும்.';

  @override
  String get savedTripsRemoveError =>
      'நீக்கம் உறுதியாகவில்லை. சேமித்த பதிவு தக்கவைக்கப்பட்டுள்ளது; இணைத்து மீண்டும் முயலவும்.';

  @override
  String get savedTripsOpenError =>
      'சேமித்த விவரங்களை உறுதிப்படுத்த முடியவில்லை. இணைத்து மீண்டும் முயலவும்.';

  @override
  String get savedTripsLoadError =>
      'சேமித்த பயணங்கள் கிடைக்கவில்லை. இணைப்பையும் கணக்கு அணுகலையும் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get savedTripsRetry => 'மீண்டும் முயல்';

  @override
  String get savedTripsEmpty =>
      'சேமித்த பயணங்கள் இன்னும் இல்லை. Bus Details இல் பயணத்தைச் சேமிக்கவும்.';

  @override
  String get savedTripsEmptyPage =>
      'இந்தப் பக்கத்தில் சேமித்த பதிவுகள் இல்லை. புதுப்பிக்கவும் அல்லது முந்தைய பக்கத்திற்குச் செல்லவும்.';

  @override
  String get savedTripsCompletedRecord => 'முடிக்கப்பட்ட சேமித்த பதிவு';

  @override
  String get savedTripsCancelledRecord => 'ரத்து செய்யப்பட்ட சேமித்த பதிவு';

  @override
  String get savedTripsOpen => 'பேருந்து விவரங்களைத் திற';

  @override
  String get savedTripsPrevious => 'முந்தைய பக்கம்';

  @override
  String get savedTripsNext => 'அடுத்த பக்கம்';

  @override
  String get savedTripsVehicleUnavailable =>
      'சேமித்த பேருந்து கிடைக்கவில்லை. சேமித்த பதிவைப் பார்க்கவும் அல்லது மீண்டும் தேடவும்.';

  @override
  String get segmentReportsPreview =>
      'வரையறுக்கப்பட்ட அறிக்கை முன்னோட்டம்; மேலும் சான்றுகளுக்கு தொடர்புடைய பக்கங்களைத் திறக்கவும். அறிக்கைகள் இல்லாதது அணுகல்தன்மையை உறுதிப்படுத்தாது.';

  @override
  String get segmentReportsHelp =>
      'இந்தப் பேருந்தை அல்லது தேர்ந்தெடுத்த பகுதியின் நிறுத்தத்தைத் தேர்வு செய்யவும். பக்கங்கள் நிலையான பதிவு வரிசையில் உள்ளன; கவனிப்பு நேர வரிசையில் அல்ல. காலாவதியான/மறைக்கப்பட்ட அறிக்கைகள் விலக்கப்படும்; வெற்றுப் பக்கம் பழைய தொடர்புடைய அறிக்கைகள் இல்லை எனப் பொருளல்ல.';

  @override
  String get segmentReportsUnavailable =>
      'அறிக்கைகள் கிடைக்கவில்லை. இணைத்து புதுப்பிக்கவும்.';

  @override
  String get segmentReportsEmptyPage =>
      'இந்தப் பக்கத்தில் தற்போதைய காணக்கூடிய அறிக்கைகள் இல்லை. அடுத்த பக்கம் இருந்தால் பார்க்கவும்.';

  @override
  String get segmentReportsEmptyPreview =>
      'இந்த முன்னோட்டத்தில் தற்போதைய அறிக்கைகள் இல்லை.';

  @override
  String get segmentReportsViewAll => 'தொடர்புடைய அனைத்து அறிக்கைகளையும் காண்க';

  @override
  String get calendarTitle => 'சேவை நாட்காட்டி';

  @override
  String get calendarHelp =>
      'சரிபார்க்கப்பட்ட வார நாட்கள், கொழும்பு புறப்படும் நேரம் மற்றும் அதிகபட்சம் 31 சேவைத் தேதிகளை வெளியிடவும். பின்னர் புறப்பாடுகளை உருவாக்கவும். ஏற்கனவே உள்ள பயணங்கள் பாதுகாக்கப்படும். நாட்காட்டியை ஓய்வுபடுத்துவது பயணங்களை ரத்து செய்யாது.';

  @override
  String get calendarDates => 'சேவைத் தேதிகளைத் தேர்ந்தெடுக்கவும்';

  @override
  String get calendarTime => 'கொழும்பு புறப்படும் நேரத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get calendarPublish => 'நாட்காட்டியை வெளியிடவும்';

  @override
  String get calendarGenerate => 'தேதியிட்ட புறப்பாடுகளை உருவாக்கவும்';

  @override
  String get calendarRetire => 'நாட்காட்டியை ஓய்வுபடுத்தவும்';

  @override
  String get calendarFailed =>
      'மாற்றம் அல்லது தரவு ஏற்றம் உறுதிப்படுத்தப்படவில்லை. இணைந்து மீண்டும் ஏற்றவும். வார நாட்களையும் அதிகபட்சம் 31 நாட்களையும் தேர்ந்தெடுக்கவும். மாற்றிய அட்டவணைக்கு புதிய நாட்காட்டி தேவை.';

  @override
  String get calendarConfirmed => 'நாட்காட்டி மாற்றம் உறுதிப்படுத்தப்பட்டது.';

  @override
  String calendarGenerated(int created, int preserved) {
    return '$created புறப்பாடுகள் உருவாக்கப்பட்டன; ஏற்கனவே உள்ள $preserved பாதுகாக்கப்பட்டன.';
  }

  @override
  String get calendarPublished => 'வெளியிடப்பட்ட நாட்காட்டி';

  @override
  String get calendarRetired => 'ஓய்வுபடுத்தப்பட்ட நாட்காட்டி';

  @override
  String get calendarEmpty => 'இந்தப் பேருந்திற்கு நாட்காட்டிகள் இல்லை.';

  @override
  String get loopStopHelp =>
      'நிறுத்தங்களை வரிசையில் சேர்க்கவும். ஒரே நிறுத்தம் மீண்டும் வரலாம்; ஒவ்வொரு வருகைக்கும் தனி நேரமும் அடையாளமும் உண்டு. வரிசையை மாற்றும்போது அந்த வருகையின் நேரமும் நகரும்.';

  @override
  String journeyVisitPositions(int boarding, int alighting) {
    return 'வழித்தடத்தின் $boardingவது நிறுத்தத்தில் ஏறி $alightingவது நிறுத்தத்தில் இறங்கவும்.';
  }

  @override
  String get scheduleReschedule => 'மாற்றுப் புறப்பாட்டை வெளியிடவும்';

  @override
  String get scheduleRescheduleHelp =>
      'பழைய புறப்பாட்டை ரத்து செய்து தேர்ந்தெடுத்த கொழும்பு தேதி/நேரத்தில் இணைக்கப்பட்ட மாற்றுப் புறப்பாட்டை வெளியிடவும். சேமித்த பயணங்களின் அசல் தேர்வு பாதுகாக்கப்படும். கீழுள்ள காரணம் பொதுவில் தெரியும்.';

  @override
  String get schedulePublicReason => 'பொதுவில் தெரியும் மாற்றக் காரணம்';

  @override
  String get scheduleReasonRequired => 'குறைந்தது ஐந்து எழுத்துகளை உள்ளிடவும்.';

  @override
  String get scheduleStatusUnavailable =>
      'தற்போதைய பயண நிலை கிடைக்கவில்லை. சேமித்த நேரங்கள் பேருந்து இயங்கும் என்பதை உறுதிப்படுத்தாது.';

  @override
  String get scheduleCancelled =>
      'இந்தப் புறப்பாடு ரத்து செய்யப்பட்டது. உங்கள் சேமித்த தேர்வு வேறு பயணத்திற்கு மாற்றப்படவில்லை.';

  @override
  String get scheduleChanged =>
      'தற்போதைய அட்டவணை சேமித்த தேர்விலிருந்து மாறியுள்ளது. அசல் சேமித்த நேரங்கள் காட்டப்படுகின்றன; தற்போதைய வாய்ப்புகளை மீண்டும் தேடவும்.';

  @override
  String get scheduleReplacement =>
      'இணைக்கப்பட்ட மாற்றுப் புறப்பாடு வெளியிடப்பட்டது. அதன் தற்போதைய கிடைப்பை மீண்டும் தேடி சரிபார்க்கவும்.';

  @override
  String scheduleReplacementAt(String time) {
    return '$time நேரத்திற்கு மாற்றுப் புறப்பாடு வெளியிடப்பட்டது. அதன் தற்போதைய கிடைப்பை மீண்டும் தேடி சரிபார்க்கவும்.';
  }

  @override
  String get scheduleSavedRecord =>
      'அசல் சேமித்த அட்டவணை. தற்போதைய வாகனம் அல்லது வழித்தடம் கிடைக்கவில்லை அல்லது மாறியுள்ளது. இந்தப் பதிவு நேரடி இருப்பிடம் அல்லது தற்போதைய அணுகல் வசதியை உறுதிப்படுத்தாது.';

  @override
  String get scheduleTimeUnknown => 'சேமித்த இடைநிலை நேரம் கிடைக்கவில்லை';

  @override
  String scheduleSavedFare(String fare) {
    return 'சேமித்த கட்டணம்: $fare';
  }

  @override
  String get manualAppealsTitle => 'கட்டுப்பாட்டு மேல்முறையீடுகள்';

  @override
  String get manualAppealsExplanation =>
      'நிர்வாகக் கணக்குக் கட்டுப்பாட்டிற்கு மேல்முறையீடு செய்யவும். சமர்ப்பிப்பதால் அணுகல் மீளாது. ஏற்றுக்கொள்ளப்பட்ட மேல்முறையீடு அந்த நிர்வாகக் கட்டுப்பாட்டை மட்டும் மாற்றும்.';

  @override
  String get manualAppealReason => 'மேல்முறையீட்டை விளக்கவும்';

  @override
  String get manualAppealSubmit => 'மேல்முறையீட்டைச் சமர்ப்பிக்கவும்';

  @override
  String get manualAppealNoNew =>
      'தற்போதைய கட்டுப்பாட்டிற்கு புதிய மேல்முறையீடு கிடைக்கவில்லை.';

  @override
  String get manualAppealRestore => 'நிர்வாக அணுகலை மீட்டமைக்கவும்';

  @override
  String get manualAppealUphold => 'கட்டுப்பாட்டை உறுதிசெய்யவும்';

  @override
  String get manualAppealClose => 'மதிப்பாய்வை மூடவும்';

  @override
  String get manualAppealPending => 'மதிப்பாய்வு நிலுவையில்';

  @override
  String get manualAppealAccepted => 'மேல்முறையீடு ஏற்கப்பட்டது';

  @override
  String get manualAppealRejected => 'மேல்முறையீடு நிராகரிக்கப்பட்டது';

  @override
  String get manualAppealReview => 'மேல்முறையீட்டை மதிப்பாய்வு செய்யவும்';

  @override
  String get manualAppealEmpty => 'கட்டுப்பாட்டு மேல்முறையீடுகள் இல்லை.';

  @override
  String get manualAppealFailed =>
      'கோரிக்கையை உறுதிப்படுத்த முடியவில்லை. புதிய முடிவிற்கு முன் தற்போதைய கட்டுப்பாட்டை மீண்டும் ஏற்றவும். உறுதியாகாத கோரிக்கையை அதே விவரங்களுடன் மீண்டும் முயலவும்.';

  @override
  String get adminLoadMore => 'மேலும் ஏற்றவும்';

  @override
  String get adminSearchLoaded => 'ஏற்றிய பதிவுகளைத் தேடவும்';

  @override
  String get adminLoadedPages =>
      'எண்ணிக்கையும் தேடலும் ஏற்றிய பக்கங்களுக்கு மட்டுமே பொருந்தும். கூடுதல் பதிவுகளுக்கு மேலும் ஏற்றவும்.';

  @override
  String manualAppealRevision(int revision) {
    return 'கட்டுப்பாட்டுப் பதிப்பு $revision';
  }

  @override
  String get adminConsole => 'நிர்வாகப் பலகை';

  @override
  String get adminOverview => 'கண்ணோட்டம்';

  @override
  String get adminBuses => 'பேருந்துகள்';

  @override
  String get adminRoutes => 'வழித்தடங்கள்';

  @override
  String get adminStops => 'பேருந்து நிறுத்தங்கள்';

  @override
  String get adminUsers => 'பயனர்கள்';

  @override
  String get adminDrivers => 'ஓட்டுநர்கள்';

  @override
  String get adminActivity => 'செயல்பாடுகள்';

  @override
  String get adminRefresh => 'சேவையகத் தரவை மீண்டும் ஏற்றவும்';

  @override
  String get adminSignOut => 'வெளியேறு';

  @override
  String get adminSampleCatalogue => 'மாதிரி/சோதனைப் பட்டியல் நிர்வாகம்';

  @override
  String get adminUnavailable => 'சேவையகத் தரவு கிடைக்கவில்லை.';

  @override
  String get adminLoading => 'சேவையகப் பதிவுகள் ஏற்றப்படுகின்றன...';

  @override
  String get adminNoMatches => 'பொருத்தமான பதிவுகள் இல்லை.';

  @override
  String get adminReviewAccess => 'அணுகலை மதிப்பாய்வு செய்யவும்';

  @override
  String get adminAssignRoute => 'வழித்தடத்தை ஒதுக்கவும்';

  @override
  String get adminEditProfile => 'சுயவிவரத்தைத் திருத்தவும்';

  @override
  String get adminReviewDriver => 'ஓட்டுநரை மதிப்பாய்வு செய்யவும்';

  @override
  String get adminDatedDepartures => 'தேதியிட்ட புறப்பாடுகள்';

  @override
  String get adminRestore => 'மீட்டமைக்கவும்';

  @override
  String get adminEdit => 'திருத்தவும்';

  @override
  String get adminDelete => 'நீக்கவும்';

  @override
  String get adminFinishDeletion => 'நீக்குதலை முடிக்கவும்';

  @override
  String get adminCancel => 'ரத்துசெய்';

  @override
  String get adminDeleteRecord => 'பதிவை நீக்கவும்';

  @override
  String get adminEditUser => 'பயனர் சுயவிவரத்தைத் திருத்தவும்';

  @override
  String get adminName => 'பெயர்';

  @override
  String get adminPhone => 'தொலைபேசி';

  @override
  String get adminSaveProfile => 'சுயவிவரத்தைச் சேமிக்கவும்';

  @override
  String get adminAssignedRoute => 'ஒதுக்கப்பட்ட வழித்தடம்';

  @override
  String get adminNoRoute => 'வழித்தடம் இல்லை / ஒதுக்கீட்டை அகற்றவும்';

  @override
  String get adminAssignmentReason =>
      'ஒதுக்கீட்டுக் காரணம் (குறைந்தது 10 எழுத்துகள்)';

  @override
  String get adminSaveAssignment => 'ஒதுக்கீட்டைச் சேமிக்கவும்';

  @override
  String get adminDecision => 'முடிவு';

  @override
  String get adminApprove => 'அங்கீகரிக்கவும்';

  @override
  String get adminReject => 'நிராகரிக்கவும்';

  @override
  String get adminRevoke => 'அணுகலை நீக்கவும்';

  @override
  String get adminReviewReason => 'மதிப்பாய்வு ஆதாரம் / காரணம்';

  @override
  String get adminConfirmDecision => 'முடிவை உறுதிசெய்யவும்';

  @override
  String get adminApproved => 'அங்கீகரிக்கப்பட்டது';

  @override
  String get adminRejected => 'நிராகரிக்கப்பட்டது';

  @override
  String get adminRevoked => 'நீக்கப்பட்டது';

  @override
  String get adminPending => 'மதிப்பாய்வு நிலுவையில்';

  @override
  String get adminUnassigned => 'ஒதுக்கப்படவில்லை';

  @override
  String get adminAdd => 'சேர்க்கவும்';

  @override
  String get adminBusStop => 'பேருந்து நிறுத்தம்';

  @override
  String get adminBusTimetable => 'பேருந்து / நேர அட்டவணை';

  @override
  String get adminRoute => 'வழித்தடம்';

  @override
  String get adminRecordId => 'பதிவு அடையாளம்';

  @override
  String get adminStopName => 'நிறுத்தத்தின் பெயர்';

  @override
  String get adminSourceUrl => 'மூல இணைப்பு';

  @override
  String get adminUnknown => 'தெரியாது / மதிப்பிடப்படவில்லை';

  @override
  String get adminEquipped => 'வசதி உள்ளது';

  @override
  String get adminNotEquipped => 'வசதி இல்லை';

  @override
  String get adminYesAssessed => 'ஆம் - மதிப்பிடப்பட்டது';

  @override
  String get adminNoAssessed => 'இல்லை - மதிப்பிடப்பட்டது';

  @override
  String get adminCatalogueType => 'பட்டியல் பதிவு வகை';

  @override
  String get adminPhysicalVehicle => 'உண்மையான வாகனம்';

  @override
  String get adminPublishedTimetable => 'வெளியிடப்பட்ட நேர அட்டவணை';

  @override
  String get adminRouteField => 'வழித்தடம்';

  @override
  String get adminDriverField => 'ஒதுக்கப்பட்ட ஓட்டுநர்';

  @override
  String get adminScheduledTime => 'திட்டமிட்ட நேரம் (HH:mm)';

  @override
  String get adminAddStop => 'நிறுத்தத்தைச் சேர்க்கவும்';

  @override
  String get adminSaving => 'சேமிக்கப்படுகிறது...';

  @override
  String get adminSaveCatalogue => 'பட்டியல் பதிவைச் சேமிக்கவும்';

  @override
  String get adminReloadReferences => 'குறிப்புத் தரவை மீண்டும் ஏற்றவும்';

  @override
  String get adminOpenPassenger => 'பயணியர் செயலியைத் திறக்கவும்';

  @override
  String get adminTransit => 'போக்குவரத்து நிர்வாகம்';

  @override
  String get adminChangeConfirmed => 'மாற்றம் சேவையகத்தால் உறுதிசெய்யப்பட்டது.';

  @override
  String get adminSourceChecked =>
      'மூலத்தையும் உள்ளிட்ட பட்டியல் விவரங்களையும் மதிப்பாய்வு செய்தேன்.';

  @override
  String get adminDeleteHelp =>
      'இது பட்டியல் பதிவை அகற்றும். குறிப்பிடப்பட்ட பதிவுகளையும் செயலில் உள்ள பேருந்துகளையும் நீக்க முடியாது. இதை மீளப்பெற முடியாது.';

  @override
  String get adminDriverChecked =>
      'இந்த ஓட்டுநரின் அடையாளத்தையும் இயக்க அனுமதியையும் சரிபார்த்தேன்.';

  @override
  String get adminSourceLoadError =>
      'சேவையகப் பதிவுகளை ஏற்ற முடியவில்லை. இணைப்பு/அணுகலைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get adminLatitude => 'அட்சரேகை';

  @override
  String get adminLongitude => 'தீர்க்கரேகை';

  @override
  String get adminRamp => 'சாய்வுப்பாதை வசதி';

  @override
  String get adminElevator => 'மின்தூக்கி வசதி';

  @override
  String get adminStepFree => 'மதிப்பிடப்பட்ட படியற்ற பாதை';

  @override
  String get adminRouteNumber => 'வழித்தட எண்';

  @override
  String get adminRouteName => 'வழித்தடப் பெயர்';

  @override
  String get adminDescription => 'விவரம்';

  @override
  String get adminVehicleRegistration => 'வாகனப் பதிவு எண்';

  @override
  String get adminLowFloor => 'தாழ்தள வசதி';

  @override
  String get adminStableId =>
      'நிலையான அடையாளம். உருவாக்கிய பின் மாற்ற முடியாது.';

  @override
  String get adminSourceHelp =>
      'அதிகாரப்பூர்வ நேர அட்டவணை, நிறுத்தம் அல்லது இயக்குநர் மூலம். இது நேரடி சேவை உறுதிப்படுத்தல் அல்ல.';

  @override
  String get adminOverviewHelp =>
      'மூலமுள்ள பட்டியல் பதிவுகளைப் பராமரித்து இயக்குநர் அணுகலை மதிப்பாய்வு செய்யவும். எல்லா மாற்றங்களுக்கும் சேவையக உறுதிப்படுத்தல் தேவை.';

  @override
  String get adminRegistrationHelp =>
      'ஓட்டுநர் பதிவு அணுகலுக்கான விண்ணப்பம். அங்கீகாரத்திற்கு முன் அடையாளத்தையும் இயக்க அனுமதியையும் மதிப்பாய்வு செய்யவும். அங்கீகாரம் உபகரணங்களையோ சேவையையோ உறுதிசெய்யாது.';

  @override
  String get adminBusCountLabel =>
      'பேருந்துகள் மற்றும் நேர அட்டவணைகள் (ஏற்றியவை)';

  @override
  String get adminRouteCountLabel => 'வழித்தடங்கள் (ஏற்றியவை)';

  @override
  String get adminStopCountLabel => 'பேருந்து நிறுத்தங்கள் (ஏற்றியவை)';

  @override
  String get adminUserCountLabel => 'பயனர்கள் (ஏற்றியவை)';

  @override
  String get adminDriverCountLabel =>
      'மதிப்பாய்வுக்குக் காத்திருக்கும் ஓட்டுநர்கள் (ஏற்றியவை)';

  @override
  String get adminReferencesError =>
      'குறிப்புப் பதிவுகளை முழுமையாக ஏற்ற முடியவில்லை. சேமிப்பதற்கு முன் மீண்டும் ஏற்றவும்.';

  @override
  String adminRouteFor(String name) {
    return '$name என்பவருக்கான வழித்தடம்';
  }

  @override
  String adminReviewFor(String name) {
    return '$name மதிப்பாய்வு';
  }

  @override
  String adminDeleteFor(String name) {
    return '$name நீக்கவா?';
  }

  @override
  String adminAssignedRouteFor(String name) {
    return 'ஒதுக்கப்பட்ட வழித்தடம்: $name';
  }

  @override
  String adminCurrentAccessFor(String name) {
    return 'தற்போதைய அணுகல்: $name';
  }

  @override
  String adminPreviousReviewFor(String name) {
    return 'முந்தைய மதிப்பாய்வு: $name';
  }

  @override
  String get adminNoActiveRoute => 'செயலில் உள்ள வழித்தட ஒதுக்கீடு இல்லை';

  @override
  String get adminRequired => 'தேவை';

  @override
  String get adminReviewSource =>
      'சேமிப்பதற்கு முன் மூலத்தை மதிப்பாய்வு செய்யவும்.';

  @override
  String get adminRouteFirst =>
      'முதலில் அங்கீகரிக்கப்பட்ட ஓட்டுநரை இந்த வழித்தடத்திற்கு ஒதுக்கவும் அல்லது முந்தைய ஒதுக்கீட்டை விடுவிக்கவும்.';

  @override
  String get adminAuthProfileHelp =>
      'உள்நுழைவு மின்னஞ்சல், கடவுச்சொற்கள் மற்றும் Auth கணக்கு நீக்கம் Firebase Authentication மூலம் நிர்வகிக்கப்படுகின்றன.';

  @override
  String get adminReferenceWithdrawHelp =>
      'அணுகல் நீக்கப்பட்டு பேருந்து ஒதுக்கீடுகள் விடுவிக்கப்படும். செயலில் உள்ள பயண/இருப்பிடப் பதிவுகள் சரிசெய்வதற்காகத் தக்கவைக்கப்படும்; முடிந்ததாகக் குறிக்கப்படாது.';

  @override
  String get adminCapabilityHelp =>
      'வசதி இருப்பதும் அது செயல்படுவதும் தனித்தனி தகவல்கள். செயல்பாட்டுச் சோதனைகளை ஒதுக்கப்பட்ட ஓட்டுநர் பதிவு செய்கிறார்.';

  @override
  String get adminTimetableHelp =>
      'வெளியிடப்பட்ட நேர அட்டவணைக்கு உண்மையான வாகனம், ஓட்டுநர் அல்லது உபகரண நிலை உறுதிசெய்யப்படவில்லை.';

  @override
  String get adminOrderedStops => 'பயண வரிசையில் நிறுத்தங்கள்';

  @override
  String get adminMoveUp => 'நிறுத்தத்தை மேலே நகர்த்தவும்';

  @override
  String get adminMoveDown => 'நிறுத்தத்தை கீழே நகர்த்தவும்';

  @override
  String get adminRemoveStop => 'நிறுத்தத்தை அகற்றவும்';

  @override
  String get adminChooseRoute => 'வழித்தடத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get adminTimeFormat => '24 மணி HH:mm வடிவத்தைப் பயன்படுத்தவும்';

  @override
  String get adminAssignmentHelp =>
      'அங்கீகாரமும் வழித்தட ஒதுக்கீடும் தனித்தனியானவை. வழித்தடத்தை மாற்றவோ அகற்றவோ முன் செயலில் உள்ள பயணத்தை முடிக்கவும்.';

  @override
  String get adminReviewChecksHelp =>
      'அடையாளம், இயக்க அனுமதிச் சோதனைகள் அல்லது முடிவிற்கான காரணத்தைப் பதிவு செய்யவும்.';

  @override
  String get adminChangeUnconfirmed =>
      'மாற்றம் உறுதிசெய்யப்படவில்லை. அணுகல்/இணைப்பைச் சரிபார்த்து மீண்டும் முயலும் முன் தரவை ஏற்றவும்.';

  @override
  String get adminSaveUnconfirmed =>
      'சேமிப்பு உறுதிசெய்யப்படவில்லை. இணைப்பு/அணுகலைச் சரிபார்த்து மீண்டும் முயலும் முன் தரவை ஏற்றவும்.';

  @override
  String get adminCursorChanged =>
      'பக்கத் தரவு மாறியுள்ளது. மீண்டும் ஏற்றவும்.';

  @override
  String get adminAccountReferenceChanged =>
      'கணக்கு மாறியுள்ளது. குறிப்புத் தரவை மீண்டும் ஏற்றவும்.';

  @override
  String get adminAccessRequired => 'நிர்வாக அணுகல் தேவை.';

  @override
  String get adminAccountSignInChanged =>
      'கணக்கு மாறியுள்ளது. மீண்டும் உள்நுழையவும்.';

  @override
  String get adminConnectionRequired =>
      'சேவையக இணைப்பு தேவை. இணையம் கிடைக்கும்போது மீண்டும் முயலவும்.';

  @override
  String get adminRecordChanged =>
      'இந்தப் பதிவு மாறியுள்ளது. சேமிப்பதற்கு முன் மீண்டும் ஏற்றவும்.';

  @override
  String get adminTwoStops =>
      'பயண வரிசையில் குறைந்தது இரண்டு தனித்த நிறுத்தங்களைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get adminOccurrenceStation =>
      'ஒவ்வொரு நிறுத்த நிகழ்வுக்கும் தெளிவான உண்மையான நிறுத்தம் தேவை.';

  @override
  String get adminSourceInvalid => 'பட்டியலின் மூல இணைப்பை உள்ளிடவும்.';

  @override
  String get adminVehicleTypeInvalid =>
      'வாகனம் அல்லது வெளியிடப்பட்ட நேர அட்டவணையைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get adminNoTimetableDriver =>
      'நேர அட்டவணைக்கு ஓட்டுநரை ஒதுக்க முடியாது.';

  @override
  String get adminTimePerStop =>
      'ஒவ்வொரு நிறுத்தத்திற்கும் ஒரு HH:mm (24 மணி) நேரத்தை உள்ளிடவும். நள்ளிரவுக்குப் பிந்தைய நேரங்கள் அடுத்த நாளுக்கு மாறலாம்.';

  @override
  String get adminRecordIdInvalid =>
      'பதிவு அடையாளத்திற்கு எழுத்துகள், எண்கள், அடிக்கோடுகள் அல்லது இணைப்புக்குறிகளைப் பயன்படுத்தவும்.';

  @override
  String get adminRestoreFirst =>
      'திருத்துவதற்கு முன் இந்தப் பதிவை மீட்டமைக்கவும்.';

  @override
  String get adminReferenceDeleting =>
      'குறிப்பிடப்பட்ட பதிவு நீக்கப்படக் காத்திருக்கிறது. அதை மீட்டமைக்கவும் அல்லது வேறு பதிவைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get adminStopMissing =>
      'தேர்ந்தெடுத்த நிறுத்தம் இனி இல்லை. படிவத்தை மீண்டும் ஏற்றவும்.';

  @override
  String get adminDependentBuses =>
      'வழித்தட எண்ணை மாற்றவோ நிறுத்தங்களை அகற்றவோ மறுவரிசைப்படுத்தவோ முன் சார்ந்த பேருந்துகளைப் புதுப்பிக்கவும்.';

  @override
  String get adminOccurrenceRebind =>
      'ஏற்கனவே உள்ள நிறுத்த நிகழ்வுகளை வேறொரு நிறுத்தத்துடன் இணைக்க முடியாது. புதிய நிகழ்வு அடையாளங்களைப் பயன்படுத்தவும்.';

  @override
  String get adminRouteMismatch =>
      'அதே வழித்தட எண்ணைக் கொண்ட ஏற்கனவே உள்ள வழித்தடத்தைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get adminStopOrderInvalid =>
      'வாகன நிறுத்தங்கள் தேர்ந்தெடுத்த வழித்தட வரிசையைப் பின்பற்ற வேண்டும்.';

  @override
  String get adminApprovedOnly =>
      'அங்கீகரிக்கப்பட்ட இயக்குநரை மட்டுமே ஒதுக்கலாம்.';

  @override
  String get adminGrantFirst =>
      'முதலில் அங்கீகரிக்கப்பட்ட ஓட்டுநரை இந்த வழித்தடத்திற்கு ஒதுக்கவும்.';

  @override
  String get adminBusActive =>
      'இந்தப் பேருந்தில் செயலில் உள்ள பயணம் அல்லது இருப்பிட ஒளிபரப்பு உள்ளது. ஒதுக்கீடு, வழித்தடம் அல்லது நிறுத்தங்களை மாற்றுவதற்கு முன் அதை முடிக்கவும்.';

  @override
  String get adminNotDeleting => 'இந்தப் பதிவு நீக்கப்படக் காத்திருக்கவில்லை.';

  @override
  String get adminReviewInputInvalid =>
      'இயக்குநரைத் தேர்ந்தெடுத்து 10–2000 எழுத்துகளில் மதிப்பாய்வு/காரணத்தை உள்ளிடவும்.';

  @override
  String get adminGrantInputInvalid =>
      'ஓட்டுநரைத் தேர்ந்தெடுத்து 10–2000 எழுத்துகளில் காரணத்தை உள்ளிடவும்.';

  @override
  String get adminApproveFirst =>
      'வழித்தடத்தை ஒதுக்குவதற்கு முன் ஓட்டுநரை அங்கீகரிக்கவும்.';

  @override
  String get adminReviewedRoute =>
      'கிடைக்கக்கூடிய மதிப்பாய்வு செய்யப்பட்ட வழித்தடத்தைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get adminProfileInputInvalid =>
      'பெயரையும் (100 எழுத்துகள் வரை) தொலைபேசியையும் (40 வரை) உள்ளிடவும்.';

  @override
  String adminFieldRequired(String field, int maximum) {
    return '$field தேவை (அதிகபட்சம் $maximum எழுத்துகள்).';
  }

  @override
  String adminCoordinateInvalid(String field) {
    return 'செல்லுபடியாகும் $field ஆயத்தொலைவுகளை உள்ளிடவும்.';
  }

  @override
  String adminDependencyDelete(String kind) {
    return 'நீக்க முடியாது: $kind இந்தப் பதிவைக் குறிப்பிடுகிறது. சார்பை அகற்றவும் அல்லது வரலாற்றிற்காகத் தக்கவைக்கவும்.';
  }

  @override
  String adminLoadKindsFailed(String kinds) {
    return 'சேவையகத்திலிருந்து $kinds சரிபார்க்க முடியவில்லை. செயல்கள் முடக்கப்பட்டுள்ளன. மீண்டும் ஏற்றி முயலவும்.';
  }

  @override
  String adminBusSummary(String route, String kind, String driver) {
    return 'வழித்தடம் $route | $kind\nஓட்டுநர்: $driver';
  }

  @override
  String adminStopCount(int count) {
    return 'வரிசைப்படுத்தப்பட்ட நிறுத்தங்கள் $count';
  }

  @override
  String adminAuditBy(String actor) {
    return 'செய்தவர் $actor';
  }

  @override
  String adminTimetableFor(String route) {
    return 'வழித்தடம் $route நேர அட்டவணை';
  }

  @override
  String get adminRunHelp =>
      'இந்தப் பேருந்து நேர அட்டவணையை கொழும்பு நேர மண்டலத்தின் குறிப்பிட்ட சேவைத் தேதிக்கு வெளியிடவும். பயணத்தைத் தொடங்குவது ஏறுதலைத் திறக்கும்; புறப்பாடு தனியாகப் பதிவு செய்யப்படும்.';

  @override
  String get adminRunRescheduleHelp =>
      'மீண்டும் திட்டமிட முந்தைய திட்டமிட்ட பயணத்தை ரத்துசெய்து மாற்றுப் பயணத்தை வெளியிடவும். நிறுத்த இடைவெளிகளும் பேருந்தின் நேர அட்டவணையும் தக்கவைக்கப்படும்.';

  @override
  String get adminRunWindowHelp =>
      'தொடங்கும் காலவரம்பு: புறப்பாட்டிற்கு 5 நிமிடங்கள் முன்பிருந்து 30 நிமிடங்கள் பின்வரை. தாமதமாகத் தொடங்கக் காரணம் தேவை.';

  @override
  String get adminRunPublish => 'தேதியிட்ட புறப்பாட்டை வெளியிடவும்';

  @override
  String get adminRunReload => 'புறப்பாடுகளை மீண்டும் ஏற்றவும்';

  @override
  String get adminRunCancel => 'திட்டமிட்ட பயணத்தை ரத்துசெய்யவும்';

  @override
  String get adminRunConfirmed =>
      'தேதியிட்ட புறப்பாட்டு மாற்றம் உறுதிசெய்யப்பட்டது.';

  @override
  String get adminRunLoadFailed =>
      'தேதியிட்ட புறப்பாடுகளை ஏற்ற முடியவில்லை. இணையம் கிடைக்கும்போது மீண்டும் முயலவும்.';

  @override
  String get adminRunChangeFailed =>
      'மாற்றம் உறுதிசெய்யப்படவில்லை. மீண்டும் ஏற்றி முயலவும்.';

  @override
  String get adminRunReviewTimetable =>
      'சேமித்த நேர அட்டவணைக்கு நிர்வாக மதிப்பாய்வு தேவை.';

  @override
  String get adminRunEmpty =>
      'இந்தப் பேருந்திற்கு தேதியிட்ட புறப்பாடுகள் இல்லை.';

  @override
  String get adminRunScheduled => 'திட்டமிடப்பட்டது';

  @override
  String get adminRunBoarding => 'பயணிகள் ஏறுகின்றனர்';

  @override
  String get adminRunInProgress => 'பயணம் நடைபெறுகிறது';

  @override
  String get adminRunCompleted => 'முடிந்தது';

  @override
  String get adminRunCancelled => 'ரத்துசெய்யப்பட்டது';

  @override
  String get adminRunUnknown => 'நிலை கிடைக்கவில்லை';

  @override
  String get adminCalendarDatesInvalid =>
      'வார நாட்களையும் அதிகபட்சம் 31 நாட்கள் கொண்ட தேதிக் காலவரம்பையும் தேர்ந்தெடுக்கவும்.';

  @override
  String get adminCalendarReload =>
      'வெளியிடப்பட்ட நாள்காட்டியை மீண்டும் ஏற்றவும்.';

  @override
  String get adminCalendarPublishedOnly =>
      'வெளியிடப்பட்ட நாள்காட்டி மட்டுமே புறப்பாடுகளை உருவாக்க முடியும்.';

  @override
  String get adminCalendarInvalid =>
      'செல்லாத நாள்காட்டி. மதிப்பாய்வு செய்யப்பட்ட மாற்றை வெளியிடவும்.';

  @override
  String get adminCalendarBusChanged =>
      'பேருந்து நேர அட்டவணை மாறியுள்ளது. மதிப்பாய்வு செய்யப்பட்ட மாற்று நாள்காட்டியை வெளியிடவும்.';

  @override
  String get adminColomboTimeInvalid =>
      'செல்லுபடியாகும் கொழும்பு புறப்பாட்டு நேரத்தைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get adminPhysicalBusRequired =>
      'கிடைக்கக்கூடிய உண்மையான பேருந்தைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get adminCompleteTimetableRequired =>
      'தேதியிட்ட பயணத்திற்கு முழுமையான மதிப்பாய்வு செய்யப்பட்ட நேர அட்டவணை தேவை.';

  @override
  String get adminRouteUnavailable => 'வழித்தடம் கிடைக்கவில்லை.';

  @override
  String get adminRescheduleInputInvalid =>
      'மாற்றப்படாத, தொடங்காத பயணத்தைத் தேர்ந்தெடுத்து பொதுக் காரணத்தை (5–300 எழுத்துகள்) உள்ளிடவும்.';

  @override
  String get adminReviewBusTimetable =>
      'முதலில் உண்மையான பேருந்தின் தற்போதைய நேர அட்டவணையை மதிப்பாய்வு செய்யவும்.';

  @override
  String get adminDifferentDeparture =>
      'வேறொரு புறப்பாட்டு நேரத்தைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get adminReviewScheduleVersion =>
      'மூல நேர அட்டவணைப் பதிப்பை மதிப்பாய்வு செய்யவும்.';

  @override
  String get adminReconcileFirst =>
      'முதலில் செயலில் உள்ள இயக்கத்தைச் சரிசெய்யவும்.';

  @override
  String get adminCancelNotStartedOnly =>
      'தொடங்காத பயணத்தை மட்டுமே இங்கு ரத்துசெய்ய முடியும்.';

  @override
  String adminServiceDate(String date) {
    return 'சேவைத் தேதி: $date';
  }

  @override
  String adminColomboDeparture(String time) {
    return 'கொழும்பு புறப்பாடு: $time';
  }

  @override
  String adminLateReason(String reason) {
    return 'தாமதமாகத் தொடங்கியதற்கான காரணம்: $reason';
  }

  @override
  String adminPublishedStopTimes(String times) {
    return 'வெளியிடப்பட்ட நிறுத்த நேரங்கள்: $times';
  }

  @override
  String adminColomboDateTime(String date, String time) {
    return '$date $time (Asia/Colombo)';
  }

  @override
  String get adminGeometryRouteId => 'வழித்தட அடையாளம்';

  @override
  String get adminGeometryImportJson =>
      'மதிப்பாய்வு செய்யப்பட்ட சாலை வடிவத் தரவு JSON';

  @override
  String get adminGeometryActionFailed =>
      'சாலை வடிவத் தரவு மாற்றம் உறுதிசெய்யப்படவில்லை. மீண்டும் முயலும் முன் அணுகல், காரணம் மற்றும் தற்போதைய வழித்தட/நிறுத்தத் தரவைச் சரிபார்க்கவும்.';

  @override
  String get adminFareLoadFailed =>
      'கட்டண வெளியீடுகளை ஏற்ற முடியவில்லை. இணைப்பு கிடைக்கும்போது மீண்டும் ஏற்றவும்; பட்டியல் காலியாக இருப்பது உறுதிசெய்யப்படவில்லை.';

  @override
  String get adminFarePublished => 'வெளியிடப்பட்டது';

  @override
  String get adminFareArchived => 'காப்பகப்படுத்தப்பட்டது';

  @override
  String get adminFarePublicationInvalid => 'செல்லாத கட்டண வெளியீடு';

  @override
  String get adminFareBusesRequired =>
      'மதிப்பாய்வு செய்யப்பட்ட பேருந்துகளைத் தேர்ந்தெடுக்கவும்';

  @override
  String get adminFareSplitRequired =>
      'இந்த வெளியீட்டை சிறிய மதிப்பாய்வு செய்யப்பட்ட பதிவுகளாகப் பிரிக்கவும்';

  @override
  String get adminFareApplicabilityMismatch =>
      'கட்டண அட்டவணை மற்றும் நிறுத்தப் பொருத்தத்தின் பொருந்தும் வரம்புகள் ஒத்திருக்கவில்லை';

  @override
  String get adminFareReviewRequired =>
      'மூலம், கட்டண நிலைகள், சேவை வகை மற்றும் அமல்தேதிகளை மதிப்பாய்வு செய்து காரணத்தை உள்ளிடவும்.';

  @override
  String get adminFareRouteUnavailable => 'வழித்தடம் கிடைக்கவில்லை';

  @override
  String get adminFareItineraryMismatch =>
      'பேருந்துப் பயண வரிசை அல்லது வழித்தடம் மதிப்பாய்வு செய்யப்பட்ட பொருத்தத்துடன் ஒத்திருக்கவில்லை';

  @override
  String get adminFareArchiveReasonRequired =>
      'காப்பகப்படுத்துவதற்கான காரணத்தை உள்ளிடவும்';

  @override
  String get adminFareTextInvalid => 'செல்லாத கட்டணப் பட்டியல் உரை';

  @override
  String get adminFareDateInvalid => 'செல்லாத கட்டண அமல்தேதி';

  @override
  String get adminFareSourceInvalid => 'செல்லாத கட்டண மூலம்';

  @override
  String get adminFareUnreviewed =>
      'மதிப்பாய்வு செய்யப்படாத அல்லது ஆதரிக்கப்படாத கட்டண அட்டவணை';

  @override
  String get adminFareTableInvalid => 'செல்லாத கட்டண அட்டவணை';

  @override
  String get adminFareMatrixInvalid => 'செல்லாத கட்டண மதிப்பு அட்டவணை';

  @override
  String get adminFareMinorInvalid =>
      'சிறிய நாணய அலகிலுள்ள கட்டண மதிப்பு செல்லாது';

  @override
  String get adminFareMappingInvalid =>
      'கட்டணப் பொருத்தம் மதிப்பாய்வு செய்யப்படவில்லை அல்லது செல்லாது';

  @override
  String get adminFareOccurrencesInvalid => 'செல்லாத கட்டண நிறுத்த நிகழ்வுகள்';

  @override
  String get adminGeometryReviewRequired =>
      'சாலை வடிவத் தரவை மதிப்பாய்வு செய்து காரணத்தை உள்ளிடவும்';

  @override
  String get adminGeometryRouteChanged =>
      'தற்போதைய திசை வழித்தடப் பயண வரிசையை மதிப்பாய்வு செய்யவும்';

  @override
  String get adminGeometryModeMismatch =>
      'சாலை வடிவத் தரவு வேறொரு தரவு முறைக்கு உரியது';

  @override
  String get adminGeometryVersionRequired =>
      'புதிய மதிப்பாய்வு செய்யப்பட்ட பதிப்பைப் பயன்படுத்தவும்';

  @override
  String get adminGeometryStopMismatch =>
      'ஒவ்வொரு நிறுத்த ஆயத்தொலைவையும் அதன் சாலைப் புள்ளியையும் மதிப்பாய்வு செய்யவும்';

  @override
  String get adminGeometryReasonRequired => 'மதிப்பாய்வுக் காரணத்தை உள்ளிடவும்';

  @override
  String get adminGeometryMissing =>
      'திரும்பப் பெறுவதற்கு சாலை வடிவத் தரவு இல்லை';

  @override
  String get adminGeometryDataInvalid =>
      'செல்லாத மதிப்பாய்வு செய்யப்பட்ட சாலை வடிவத் தரவு';

  @override
  String get adminGeometryStopsInvalid =>
      'சாலை வடிவத்தின் நிறுத்த வரிசை செல்லாது';

  @override
  String get adminGeometryCoordinatesInvalid => 'செல்லாத ஆயத்தொலைவுகள்';

  @override
  String get adminGeometryVerticesInvalid =>
      'நிறுத்தச் சாலைப் புள்ளிகள் வரிசையாக அதிகரிக்க வேண்டும்';

  @override
  String get adminGeometryResolutionInvalid =>
      'சாலைப் பாதையின் விவரத் துல்லியத்தை மதிப்பாய்வு செய்யவும்';

  @override
  String get adminGeometryTooLong => 'வழித்தடம் மிக நீளமானது';

  @override
  String adminFarePreviewRoute(String route, String serviceClass) {
    return 'வழித்தடம்: $route · சேவை வகை: $serviceClass';
  }

  @override
  String adminFarePreviewDates(String from, String until) {
    return 'அமல்தேதிகள்: $from – $until';
  }

  @override
  String adminImportSource(String source) {
    return 'மூலம்: $source';
  }

  @override
  String adminFareVersions(String table, String mapping) {
    return 'கட்டணப் பதிப்பு: $table · பொருத்தப் பதிப்பு: $mapping';
  }

  @override
  String adminFareBuses(String buses) {
    return 'பேருந்துகள்: $buses';
  }

  @override
  String adminFareCell(String from, String to, String amount) {
    return '$from → $to: $amount';
  }

  @override
  String adminGeometryVersion(String route, String version) {
    return 'வழித்தடம்: $route · பதிப்பு: $version';
  }

  @override
  String adminGeometryDistance(String stops, String distance) {
    return '$stops · $distance கி.மீ.';
  }

  @override
  String adminFareRowStatus(String status, String version) {
    return '$status · பதிப்பு: $version';
  }

  @override
  String get reviewAccessRequired =>
      'இந்த வழக்கை மதிப்பாய்வு செய்ய நிர்வாக அணுகல் தேவை.';

  @override
  String get reviewSelfForbidden =>
      'உங்கள் சொந்தக் கணக்கு தொடர்பான வழக்கை நீங்கள் மதிப்பாய்வு செய்ய முடியாது.';

  @override
  String get reviewSignInRequired =>
      'உங்கள் அமர்வு இனி செல்லாது. தொடர்வதற்கு முன் மீண்டும் உள்நுழையவும்.';

  @override
  String get reviewAccountChanged =>
      'உள்நுழைந்த கணக்கு மாறியுள்ளது. தற்போதைய கணக்கிலிருந்து இந்தத் திரையை மீண்டும் திறக்கவும்.';

  @override
  String get reviewRestricted =>
      'கட்டுப்படுத்தப்பட்டிருக்கும்போது இந்தக் கணக்கால் நிர்வாகச் செயல்களைச் செய்ய முடியாது.';

  @override
  String get reviewAlreadyDecided =>
      'இந்த மதிப்பாய்வுக்கு ஏற்கனவே முடிவு உள்ளது. பதிவான முடிவைப் பார்க்க மீண்டும் ஏற்றவும்.';

  @override
  String get reviewUnavailable =>
      'இந்த மதிப்பாய்வு கிடைக்கவில்லை. அடுத்த செயலைச் செய்வதற்கு முன் மீண்டும் ஏற்றவும்.';

  @override
  String get reviewOperationUnavailable =>
      'இந்தச் செயலுக்கு இந்தப் பயணம் இனி கிடைக்கவில்லை. தற்போதைய நிலையை மீண்டும் ஏற்றவும்.';

  @override
  String get reviewRetryConflict =>
      'இந்தக் கோரிக்கை பதிவான கோரிக்கையுடன் முரண்படுகிறது. புதிய செயலுக்கு முன் மீண்டும் ஏற்றி முடிவைப் பரிசோதிக்கவும்.';

  @override
  String get reviewVoteUnknown => 'வாக்கு கிடைக்கவில்லை';

  @override
  String reviewRunDriver(String run, String driver) {
    return 'பயணம்: $run\nஓட்டுநர்: $driver';
  }

  @override
  String reviewDriverId(String driver) {
    return 'ஓட்டுநர்: $driver';
  }

  @override
  String reviewVoteEvidence(String user, String vote) {
    return '$user · $vote';
  }

  @override
  String get profileMissing =>
      'சுயவிவரம் கிடைக்கவில்லை. மீண்டும் உள்நுழையவும்.';

  @override
  String get profileLoadFailed =>
      'தரவுத்தளத்திலிருந்து சுயவிவரத்தை ஏற்ற முடியவில்லை.';

  @override
  String get profileUnavailable => 'சுயவிவரம் கிடைக்கவில்லை.';

  @override
  String get profilePassenger => 'பயணி';

  @override
  String get profileContributor => 'சமூகப் பங்களிப்பாளர்';

  @override
  String get profileOperator => 'பேருந்து ஓட்டுநர்';

  @override
  String get profileAdministrator => 'கணினி நிர்வாகி';

  @override
  String get profileCommuter => 'பயணி';

  @override
  String get profileEdit => 'திருத்து';

  @override
  String get profileEditTitle => 'சுயவிவரத்தைத் திருத்து';

  @override
  String get profileFullName => 'முழுப் பெயர்';

  @override
  String get profileEmail => 'மின்னஞ்சல் முகவரி';

  @override
  String get profilePhone => 'தொலைபேசி எண்';

  @override
  String get profileNameRequired => 'உங்கள் பெயரை உள்ளிடவும்';

  @override
  String get profileSave => 'மாற்றங்களைச் சேமி';

  @override
  String get profileSaved => 'சுயவிவரம் புதுப்பிக்கப்பட்டது!';

  @override
  String get profileSaveFailed =>
      'சுயவிவர மாற்றங்களை உறுதிப்படுத்த முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get profileSignOutFailed =>
      'தனிப்பட்ட வரைவுகளை அகற்றவோ வெளியேறவோ முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get profileSignedOut => 'நீங்கள் வெளியேறிவிட்டீர்கள்.';

  @override
  String get profileSignOut => 'வெளியேறு';

  @override
  String get profileCancel => 'ரத்து செய்';

  @override
  String get profileRetry => 'மீண்டும் முயல்';

  @override
  String get profileLogoutQuestion =>
      'வெளியேறி, இந்தச் சாதனத்தில் நிலுவையிலுள்ள அறிக்கை வரைவுகளையும் படங்களையும் அகற்றவா? ஏற்கனவே அனுப்பிய கோரிக்கைகள் இன்னும் நிறைவடையலாம். மீண்டும் உள்நுழைந்தால் வெளியிட்ட அறிக்கைகளைப் பார்க்கலாம்.';

  @override
  String get profileSettings => 'அமைப்புகள்';

  @override
  String get profileSupport => 'உதவி';

  @override
  String get profilePersonalInfo => 'தனிப்பட்ட தகவல்கள்';

  @override
  String get profileAdminConsole => 'நிர்வாகப் பலகம்';

  @override
  String get profileAccessibility => 'அணுகல்தன்மை விருப்பங்கள்';

  @override
  String get profilePush => 'புஷ் அறிவிப்புகள்';

  @override
  String get profilePassword => 'கடவுச்சொல்லை மாற்று';

  @override
  String get profilePlaces => 'சேமித்த இடங்கள்';

  @override
  String get profileRate => 'எங்களை மதிப்பிடு';

  @override
  String get profileHelp => 'உதவி மையம்';

  @override
  String get profileUpdates => 'புதுப்பிப்புகளைச் சரிபார்';

  @override
  String get profileNotSet => 'அமைக்கப்படவில்லை';

  @override
  String get profileReports => 'அறிக்கைகள்';

  @override
  String get profileVerifications => 'உறுதிப்படுத்தல்கள்';

  @override
  String get profileBadges => 'பதக்கங்கள்';

  @override
  String get profileImpact => 'சமூகப் பங்களிப்புப் புள்ளிகள்';

  @override
  String get profileSeeAll => 'அனைத்தையும் பார் →';

  @override
  String get profileBadgeDetails => 'பெற்ற பதக்கங்களைப் பார்';

  @override
  String get profileDelete => 'கணக்கை நீக்கு';

  @override
  String get profileDeleteUnavailable =>
      'இங்கு சுயமாகக் கணக்கை நீக்கும் வசதி இன்னும் இல்லை';

  @override
  String profileComingSoon(String feature) {
    return '$feature எதிர்காலப் புதுப்பிப்பில் கிடைக்கும்.';
  }

  @override
  String profileContributionSummary(int points, int reports, int badges) {
    return 'புள்ளிகள் $points • அறிக்கைகள் $reports • பதக்கங்கள் $badges';
  }

  @override
  String get driverDashboard => 'ஓட்டுநர் பலகம்';

  @override
  String get driverFallback => 'ஓட்டுநர்';

  @override
  String get driverAddStop => 'வழித்தடத்தில் நிறுத்தத்தைச் சேர்';

  @override
  String get driverNoBuses =>
      'உங்களுக்கு ஒதுக்கிய வழித்தடத்தில் உண்மையான பேருந்துகள் இல்லை. பேருந்தைச் சேர்க்க அல்லது பரிசீலிக்க நிர்வாகியிடம் கேளுங்கள்.';

  @override
  String get driverNoGps => 'பகிரப்பட்ட GPS புதுப்பிப்பு இல்லை';

  @override
  String get driverBusUnavailable =>
      'தேர்ந்த பேருந்து கிடைக்கவில்லை; சாதனத்தில் ஒளிபரப்பு நிறுத்தப்பட்டது';

  @override
  String get driverAssignmentUnavailable =>
      'பேருந்து ஒதுக்கீட்டை உறுதிப்படுத்த முடியவில்லை; சாதனத்தில் ஒளிபரப்பு நிறுத்தப்பட்டது';

  @override
  String get driverVerifyRuns =>
      'தேதியிட்ட புறப்பாடுகளை உறுதிப்படுத்த இணைக்கவும்.';

  @override
  String get driverSignInFirst =>
      'முதலில் அங்கீகரிக்கப்பட்ட ஓட்டுநராக உள்நுழையவும்.';

  @override
  String get driverAssignedOnly =>
      'ஒதுக்கப்பட்ட ஓட்டுநர் மட்டுமே இந்தப் பேருந்தைப் புதுப்பிக்கலாம்.';

  @override
  String get driverClaimFailed =>
      'பேருந்து ஒதுக்கீடு உறுதியாகவில்லை. புதுப்பித்து மீண்டும் முயலவும்.';

  @override
  String get driverRampWorkingSaved =>
      'சாய்வுப்பாதை இயங்குவதாகப் பதிவு சேமிக்கப்பட்டது';

  @override
  String get driverRampBrokenSaved =>
      'சாய்வுப்பாதை பழுதாக உள்ளதாகப் பதிவு சேமிக்கப்பட்டது';

  @override
  String get driverRampFailed =>
      'அனைத்து சாய்வுப்பாதைப் புதுப்பிப்புகளையும் உறுதிப்படுத்த முடியவில்லை. புதுப்பித்து மீண்டும் முயலவும்.';

  @override
  String get driverOccupancyFailed =>
      'அனைத்து பயணிகள் நெரிசல் புதுப்பிப்புகளையும் உறுதிப்படுத்த முடியவில்லை. புதுப்பித்து மீண்டும் முயலவும்.';

  @override
  String get driverClaimFirst =>
      'பயணத்தைத் தொடங்கும் முன் இந்தப் பேருந்தை உங்களுக்கு ஒதுக்கிக்கொள்ளவும்.';

  @override
  String get driverSelectRun =>
      'நிர்வாகி வெளியிட்ட தேதியிட்ட புறப்பாட்டைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get driverLateTitle => 'தாமதமாகத் தொடங்குவதற்கான காரணம்';

  @override
  String get driverLateHelp =>
      'குறைந்தது 5 எழுத்துகள். புறப்பாட்டுக்கு 30 நிமிடங்கள் வரை தொடங்கலாம்.';

  @override
  String get driverContinue => 'தொடர்';

  @override
  String get driverLateRequired =>
      'தாமதமாகத் தொடங்குவதற்குக் குறைந்தது 5 எழுத்துகளில் காரணம் உள்ளிடவும்.';

  @override
  String get driverGpsAcknowledged => 'பகிரப்பட்ட GPS பெறப்பட்டது';

  @override
  String get driverTrackingTitle =>
      'AccessTransit நேரடிப் பேருந்துக் கண்காணிப்பு';

  @override
  String get driverGpsUnavailable =>
      'GPS கிடைக்கவில்லை; கடைசியாகப் பகிர்ந்த இடம் பழையதாக இருக்கலாம்';

  @override
  String get driverGpsStreamError =>
      'GPS புதுப்பிப்புகள் கிடைக்கவில்லை. இருப்பிட அனுமதியைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get driverBoardingStarted =>
      'பயணிகள் ஏறும் அமர்வு தொடங்கியது. புறப்படும்போது உண்மையான புறப்பாட்டைப் பதிவு செய்யவும்.';

  @override
  String get driverRunResumed =>
      'தேதியிட்ட செயலில் உள்ள பயணம் மீண்டும் தொடங்கியது. GPS ஒளிபரப்பு உறுதியானது.';

  @override
  String get driverStartFailed =>
      'பயணத் தொடக்கம் உறுதியாகவில்லை. புதுப்பித்து மீண்டும் முயலவும்.';

  @override
  String get driverGpsPending =>
      'GPS பதிவேற்றம் நிலுவையில்; ஆயத்தொலைவுகள் சாதனத்தில் மட்டுமே உள்ளன';

  @override
  String get driverGpsRetry =>
      'GPS பதிவேற்றம் தோல்வி/இணைப்பு இல்லை; அடுத்த இருப்பிடத்தில் மீண்டும் முயலும்';

  @override
  String get driverBoardingEnded =>
      'ஏறும் அமர்வு ரத்தானது; ஒளிபரப்பு முடிந்தது';

  @override
  String get driverCompletionAcknowledged => 'பகிரப்பட்ட பயண நிறைவு உறுதியானது';

  @override
  String get driverBoardingCancelled =>
      'ஏறும் அமர்வு ரத்தானது. ஒளிபரப்பு முடிந்தது.';

  @override
  String get driverTripCompleted =>
      'பயண நிறைவு சேமிக்கப்பட்டது. ஒளிபரப்பு முடிந்தது.';

  @override
  String get driverStopPending =>
      'சாதனத்தில் GPS நிறுத்தப்பட்டது; பகிரப்பட்ட நிறைவு உறுதியாகவில்லை. நிறுத்த மீண்டும் முயலவும்.';

  @override
  String get driverStopFailed =>
      'பகிரப்பட்ட பயண நிறைவு உறுதியாகவில்லை. நிறுத்த மீண்டும் முயலவும்.';

  @override
  String get driverDatedDeparture => 'தேதியிட்ட புறப்பாடு';

  @override
  String get driverNoRuns =>
      'தேதியிட்ட புறப்பாடுகள் வெளியிடப்படவில்லை. இந்தப் பேருந்தை அட்டவணைப்படுத்த நிர்வாகியிடம் கேளுங்கள்.';

  @override
  String get driverColomboDeparture => 'கொழும்பு நேரச் சேவைப் புறப்பாடு';

  @override
  String get driverBoardingHelp =>
      'தொடங்கினால் பயணிகள் ஏறலாம். உண்மையான புறப்பாட்டைத் தனியாகப் பதிவு செய்யவும்; தாமதமான தொடக்கத்திற்குக் காரணம் தேவை.';

  @override
  String get driverDepartureSaved =>
      'உண்மையான புறப்பாட்டைச் சேவையகம் உறுதிப்படுத்தியது.';

  @override
  String get driverDepartureFailed =>
      'புறப்பாடு உறுதியாகவில்லை. புதுப்பித்து மீண்டும் முயலவும்.';

  @override
  String get driverRecordDeparture => 'உண்மையான புறப்பாட்டைப் பதிவு செய்';

  @override
  String get driverActive => 'பயணம் நடைபெறுகிறது';

  @override
  String get driverInactive => 'பயணம் செயல்படவில்லை';

  @override
  String get driverStart => 'பயணத்தைத் தொடங்கு';

  @override
  String get driverStop => 'பயணத்தை நிறுத்து';

  @override
  String get driverTelemetry => 'நேரடி இருப்பிடத் தரவு';

  @override
  String get driverGpsInactive =>
      'GPS செயல்படவில்லை. நேரடி இருப்பிடத்தைப் பெற பயணத்தைத் தொடங்கவும்.';

  @override
  String get driverLatitude => 'அட்சரேகை:';

  @override
  String get driverLongitude => 'தீர்க்கரேகை:';

  @override
  String get driverSpeed => 'வேகம்:';

  @override
  String get driverHeading => 'திசை:';

  @override
  String get driverLocalFix => 'சாதனத்தின் GPS இருப்பிடம்:';

  @override
  String get driverAccessibility => 'வாகன அணுகல்தன்மை நிலை';

  @override
  String get driverReadOnly => 'பார்க்க மட்டும் (ஒதுக்கப்படவில்லை)';

  @override
  String get driverRampObservation =>
      'சக்கர நாற்காலிச் சாய்வுப்பாதை அவதானிப்பு';

  @override
  String get driverUnknownRamp =>
      'தெரியவில்லை - தேர்வுக்கு முன் சரிபார்க்கவும்';

  @override
  String get driverWorkingObserved => 'இயங்குவதாகக் கவனிக்கப்பட்டது';

  @override
  String get driverBrokenObserved => 'பழுதாக உள்ளதாகக் கவனிக்கப்பட்டது';

  @override
  String get driverLift => 'தாழ்தள உயர்த்தி இயங்குகிறது';

  @override
  String get driverStopLiftHelp =>
      'நிறுத்த உயர்த்தி அவதானிப்புகள் தனியாகப் பதிவிடப்படுகின்றன';

  @override
  String get driverOccupancy => 'பயணிகள் நெரிசல்:';

  @override
  String get driverLow => 'குறைவு';

  @override
  String get driverMedium => 'நடுத்தரம்';

  @override
  String get driverHigh => 'அதிகம்';

  @override
  String get driverAccess => 'ஓட்டுநர் அணுகல்';

  @override
  String get driverChecking => 'ஓட்டுநர் அங்கீகாரம் சரிபார்க்கப்படுகிறது...';

  @override
  String get driverSignInApproval =>
      'ஓட்டுநர் அங்கீகாரத்தைச் சரிபார்க்க உள்நுழையவும்.';

  @override
  String get driverApprovalRequired =>
      'ஓட்டுநர் அங்கீகாரம் தேவை. உங்கள் கணக்கைப் பரிசீலிக்க நிர்வாகியிடம் கேளுங்கள். பதிவில் ஓட்டுநரைத் தேர்ந்தெடுப்பது அங்கீகாரம் அளிக்காது. அணுகலை உறுதிப்படுத்த நேரடி இணைப்பு தேவை.';

  @override
  String get driverCheckAgain => 'மீண்டும் சரிபார்';

  @override
  String get driverReturnSignIn => 'உள்நுழைவுக்குத் திரும்பு';

  @override
  String get driverSignOutFailed => 'வெளியேற முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get driverRouteAssignment => 'ஓட்டுநர் வழித்தட ஒதுக்கீடு';

  @override
  String get driverRouteRequired =>
      'பேருந்தை இயக்கும் முன் நிர்வாகி ஒரு கிடைக்கக்கூடிய வழித்தடத்தை ஒதுக்க வேண்டும். ஒதுக்கீட்டை உறுதிப்படுத்த நேரடி இணைப்பு தேவை.';

  @override
  String get driverCheckAssignment => 'ஒதுக்கீட்டைச் சரிபார்';

  @override
  String get driverScheduled => 'அட்டவணைப்படி';

  @override
  String get driverBoarding => 'பயணிகள் ஏறுகின்றனர்';

  @override
  String get driverInProgress => 'நடைபெறுகிறது';

  @override
  String get driverCompleted => 'நிறைவடைந்தது';

  @override
  String get driverCancelled => 'ரத்தானது';

  @override
  String get driverUnknownState => 'நிலை கிடைக்கவில்லை';

  @override
  String driverName(String name) {
    return 'ஓட்டுநர்: $name';
  }

  @override
  String driverBusAssigned(String bus) {
    return 'பேருந்து $bus உங்களுக்கு ஒதுக்கப்பட்டது!';
  }

  @override
  String driverOccupancySaved(String level) {
    return 'பயணிகள் நெரிசல் $level எனப் புதுப்பிக்கப்பட்டது';
  }

  @override
  String driverTrackingBody(String bus) {
    return 'பேருந்து $bus GPS கண்காணிப்பு; பகிரப்பட்ட தரவு கிடைப்பது செயலியில் காட்டப்படும்';
  }

  @override
  String driverRunWindow(String earliest, String latest) {
    return 'தொடங்கக்கூடிய நேரம்: $earliest முதல் $latest வரை';
  }

  @override
  String driverRunOption(String time, String status) {
    return '$time · $status';
  }

  @override
  String driverActiveSummary(String status, String duration) {
    return '$status\nகால அளவு: $duration';
  }

  @override
  String driverStartHelp(String bus) {
    return 'பேருந்து $busக்குப் பின்னணி GPS கண்காணிப்பை இயக்க பயணத்தைத் தொடங்கவும்.';
  }

  @override
  String driverGpsStale(String status) {
    return 'பகிரப்பட்ட GPS பழையது; $status';
  }

  @override
  String driverLastReceipt(String time) {
    return 'கடைசிப் பகிரப்பட்ட தரவு கிடைத்த நேரம்: $time';
  }

  @override
  String get driverProgress => 'பயண வழித்தட முன்னேற்றம்';

  @override
  String get driverNoActive => 'செயலில் பயணம் இல்லை';

  @override
  String get driverNoActiveHelp =>
      'செயலில் பயணம் இல்லை. மேலே தேதியிட்ட புறப்பாட்டைத் தேர்ந்து பயணிகள் ஏறுவதைத் தொடங்கவும்; புறப்படும்போது உண்மையான புறப்பாட்டைத் தனியாகப் பதிவு செய்யவும்.';

  @override
  String get driverFinalDestination => 'இறுதி இலக்கை அடைந்தது';

  @override
  String get driverFinalAcknowledged =>
      'இறுதி வருகையும் பயண நிறைவும் உறுதியானது';

  @override
  String get driverArrivalFailed =>
      'வருகை உறுதியாகவில்லை. புதுப்பித்து மீண்டும் முயலவும்.';

  @override
  String get driverNextReached => 'அடுத்த நிறுத்தத்தை அடைந்தது';

  @override
  String get driverFinalReached => 'இறுதி நிறுத்தத்தை அடைந்தது';

  @override
  String get driverEnd => 'பயணத்தை முடி';

  @override
  String get driverUnknown => 'தெரியவில்லை';

  @override
  String get driverNotRecorded => 'பதிவு செய்யப்படவில்லை';

  @override
  String get driverEtaHelp =>
      'வருகைக் கணிப்புகள் உண்மையான புறப்பாடு மற்றும் பதிவான வருகைகளின்படி மாறும். அட்டவணை இடைவெளிகள் இல்லாவிட்டால் 6 நிமிடக் கணிப்பு பயன்படுத்தப்படும்; ஓட்டுநரிடம் நேரத்தை உறுதிப்படுத்தவும்.';

  @override
  String get driverScheduledArrival => 'திட்டமிட்ட வருகை';

  @override
  String get driverTimetableTarget => 'அட்டவணை இலக்கு';

  @override
  String get driverCurrentEta => 'தற்போதைய வருகைக் கணிப்பு';

  @override
  String get driverDelayCleared => 'தாமத அறிவிப்பு அகற்றப்பட்டது.';

  @override
  String get driverDelayClearFailed =>
      'தாமத அறிவிப்பை அகற்றியது உறுதியாகவில்லை. மீண்டும் முயலவும்.';

  @override
  String get driverClear => 'அகற்று';

  @override
  String get driverUpdateDelay => 'தாமதம் / போக்குவரத்துக் காரணத்தைப் புதுப்பி';

  @override
  String get driverReportDelay =>
      'போக்குவரத்து / தாமதத்தைப் பதிவு செய் (+5, +10 நிமி)';

  @override
  String get driverTraffic => 'போக்குவரத்து நெரிசல்';

  @override
  String get driverRain => 'கனமழை / வெள்ளம்';

  @override
  String get driverAccident => 'முன்னால் விபத்து';

  @override
  String get driverRoadworks => 'சாலைப் பணிகள்';

  @override
  String get driverBreakdown => 'இயந்திரக் கோளாறு';

  @override
  String get driverDelayTitle => 'தாமதம் / சம்பவத்தைப் பதிவு செய்';

  @override
  String get driverDelayHelp =>
      'பயணிகள் திரைகளுக்கு அறிவித்து வருகைக் கணிப்புகளைப் புதுப்பிக்கும்.';

  @override
  String get driverDelayTime => 'கணிக்கப்பட்ட தாமத நேரம்';

  @override
  String get driverDelayReason => 'தாமதக் காரணம்';

  @override
  String get driverDelayFailed =>
      'தாமதப் பதிவேற்றம் உறுதியாகவில்லை. மீண்டும் முயலவும்.';

  @override
  String get driverDepartsNow => 'சரியான நேரம் (இப்போது புறப்படும்)';

  @override
  String get driverOrigin => 'தொடக்க நிறுத்தம்';

  @override
  String get driverPreTrip => 'பயணத்துக்கு முன் அட்டவணைச் சரிபார்ப்பு';

  @override
  String get driverOnTimeMinute => 'சரியான நேரம் (±1 நிமி)';

  @override
  String get driverEarly => 'நேரத்துக்கு முன் செல்கிறது';

  @override
  String get driverOnTimeTarget => 'சரியான நேர இலக்கு';

  @override
  String get driverDelayed => 'தாமதம்';

  @override
  String get driverMinusFive => '-5 நிமி';

  @override
  String get driverZeroSchedule => '0 (அட்டவணைப்படி)';

  @override
  String get driverPlusFifteen => '+15 நிமி';

  @override
  String get driverZeroMinutes => '0 நிமி';

  @override
  String get driverSelectBus => 'பேருந்து இயக்கத்தைத் தேர்ந்தெடு';

  @override
  String get driverAssigned => 'உங்களுக்கு ஒதுக்கப்பட்டது';

  @override
  String get driverAssignMe => 'எனக்கு ஒதுக்கு';

  @override
  String get driverAssignedOther => 'வேறொரு ஓட்டுநருக்கு ஒதுக்கப்பட்டது';

  @override
  String get driverUpcoming => 'வரவுள்ளது';

  @override
  String get driverDeparted => 'புறப்பட்டது';

  @override
  String get driverAssistanceUnavailable =>
      'பகிரப்பட்ட கோரிக்கைப் புதுப்பிப்புகள் கிடைக்கவில்லை. காட்டப்படும் கோரிக்கைகள் பழையதாக இருக்கலாம்.';

  @override
  String get driverAssistanceTitle =>
      'பேருந்தில் ஏறுவதற்கான உதவிக் கோரிக்கைகள்';

  @override
  String get driverAssistanceEmpty =>
      'இந்தப் பேருந்துக்குச் செயலில் உதவிக் கோரிக்கைகள் இல்லை.';

  @override
  String get driverBoardingAt => 'ஏறுதல்';

  @override
  String get driverAlightingAt => 'இறங்குதல்';

  @override
  String driverStopPosition(int index, int total) {
    return 'தற்போதைய இடம்: $total நிறுத்தங்களில் $index';
  }

  @override
  String driverNextStop(String stop) {
    return 'அடுத்த நிறுத்தம்: $stop';
  }

  @override
  String driverArrivalSaved(String stop, String next) {
    return '$stop வருகை சேமிக்கப்பட்டது. அடுத்தது: $next';
  }

  @override
  String driverFinalSaved(String stop) {
    return '$stop இறுதி வருகை சேமிக்கப்பட்டது. பயணம் முடிந்தது.';
  }

  @override
  String driverTarget(String stop) {
    return 'இலக்கு: $stop';
  }

  @override
  String driverDestination(String stop) {
    return 'செல்லுமிடம்: $stop';
  }

  @override
  String driverPlannedDeparture(String time) {
    return 'திட்டமிட்ட புறப்பாடு (கொழும்பு): $time';
  }

  @override
  String driverActualDeparture(String time) {
    return 'உண்மையான புறப்பாடு (கொழும்பு): $time';
  }

  @override
  String driverBroadcastReason(String reason) {
    return 'பயணிகளுக்குப் பகிரப்பட்டது: $reason';
  }

  @override
  String driverAddedMinutes(int minutes) {
    return 'பயணிகள் வருகைக் கணிப்புகளில் +$minutes நிமிடங்கள் சேர்க்கப்பட்டன';
  }

  @override
  String driverMinuteOption(int minutes) {
    return '+$minutes நிமி';
  }

  @override
  String driverDelaySaved(String reason, int minutes) {
    return 'தாமத அறிவிப்பு சேமிக்கப்பட்டது: $reason (+$minutes நிமி)';
  }

  @override
  String driverBroadcastDelay(int minutes) {
    return 'தாமதத்தைப் பகிர் (+$minutes நிமி)';
  }

  @override
  String driverDepartsIn(int minutes) {
    return '$minutes நிமிடங்களில் புறப்படும்';
  }

  @override
  String driverLateMinutes(int minutes) {
    return '$minutes நிமிடங்கள் தாமதம்';
  }

  @override
  String driverScheduledDep(String time, String stop) {
    return 'திட்டமிட்ட புறப்பாடு: $time ($stop)';
  }

  @override
  String driverEarlyMinutes(int minutes) {
    return 'நேரத்துக்கு முன் செல்கிறது ($minutes நிமி)';
  }

  @override
  String driverLateShort(int minutes) {
    return '+$minutes நிமி தாமதம்';
  }

  @override
  String driverEarlyShort(int minutes) {
    return '$minutes நிமி முன்னதாக';
  }

  @override
  String driverBusOption(
    String bus,
    String time,
    String endpoints,
    String assigned,
  ) {
    return 'பேருந்து $bus (புறப்பாடு: $time)$endpoints$assigned';
  }

  @override
  String driverRouteName(String route) {
    return 'வழித்தடம் $route';
  }

  @override
  String driverDepartureTime(String time) {
    return 'புறப்பாடு: $time';
  }

  @override
  String driverStopCount(int count) {
    return '$count நிறுத்தங்கள்';
  }

  @override
  String driverActiveRequests(int count) {
    return 'செயலில் $count';
  }

  @override
  String driverClosedRequests(int count) {
    return 'முடிக்கப்பட்ட கோரிக்கைகள் ($count)';
  }

  @override
  String driverRequestSummary(String rider, String stop, String types) {
    return '$stop இல் $rider ($types)';
  }

  @override
  String driverAssistanceStop(String purpose, String stop) {
    return '$purpose: $stop';
  }

  @override
  String get driverEtaUnavailable => 'வருகைக் கணிப்பு இல்லை';

  @override
  String get driverSchedulePassed => 'திட்டமிட்ட நேரம் கடந்துவிட்டது';

  @override
  String get driverArrivingNow => 'இப்போது வருகிறது';

  @override
  String driverScheduledFor(String time) {
    return '$timeக்குத் திட்டமிடப்பட்டது';
  }

  @override
  String driverTomorrowAt(String time) {
    return 'நாளை $timeக்கு';
  }

  @override
  String driverTomorrowIn(String time, int hours, int minutes) {
    return 'நாளை $timeக்கு ($hours மணி $minutes நிமிடங்களில்)';
  }

  @override
  String driverDepartedAgo(int minutes) {
    return '$minutes நிமிடங்களுக்கு முன் புறப்பட்டது';
  }

  @override
  String driverArrivingMinutes(int minutes) {
    return '$minutes நிமிடங்களில் வரும்';
  }

  @override
  String driverArrivingHours(int hours, int minutes) {
    return '$hours மணி $minutes நிமிடங்களில் வரும்';
  }

  @override
  String get recoveryTitle => 'கடவுச்சொல்லை மீட்டமை';

  @override
  String get recoveryCheckEmail => 'உங்கள் மின்னஞ்சலைப் பார்க்கவும்';

  @override
  String get recoveryInboxHelp =>
      'புதிய கடவுச்சொல்லை உருவாக்க மின்னஞ்சலில் உள்ள இணைப்பைப் பின்பற்றவும்.';

  @override
  String get recoveryBackLogin => 'உள்நுழைவுக்குத் திரும்பு';

  @override
  String get recoveryResend => 'மின்னஞ்சலை மீண்டும் அனுப்பு';

  @override
  String get recoveryForgot => 'கடவுச்சொல் மறந்துவிட்டதா?';

  @override
  String get recoveryEmailHelp =>
      'உங்கள் கணக்கின் மின்னஞ்சல் முகவரியை உள்ளிடவும். கடவுச்சொல்லை மீட்டமைக்கும் வழிமுறைகளை அனுப்புவோம்.';

  @override
  String get recoveryEmail => 'மின்னஞ்சல் முகவரி';

  @override
  String get recoveryEmailHint => 'எ.கா., name@example.com';

  @override
  String get recoveryPrivacy => 'உங்கள் மின்னஞ்சலைப் பகிரமாட்டோம்.';

  @override
  String get recoverySend => 'மீட்டமைப்பு இணைப்பை அனுப்பு';

  @override
  String get recoveryCreate => 'புதிய கடவுச்சொல்லை உருவாக்கு';

  @override
  String get recoveryPasswordHelp =>
      'முன்பு பயன்படுத்தாத வலுவான கடவுச்சொல்லைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get recoveryNewPassword => 'புதிய கடவுச்சொல்';

  @override
  String get recoveryPasswordHint => 'புதிய கடவுச்சொல்லை உள்ளிடவும்';

  @override
  String get recoveryConfirm => 'புதிய கடவுச்சொல்லை உறுதிப்படுத்து';

  @override
  String get recoveryConfirmHint => 'புதிய கடவுச்சொல்லை மீண்டும் உள்ளிடவும்';

  @override
  String get recoveryShow => 'கடவுச்சொல்லைக் காட்டு';

  @override
  String get recoveryHide => 'கடவுச்சொல்லை மறை';

  @override
  String get recoverySecurity => 'உங்கள் பாதுகாப்பே எங்கள் முன்னுரிமை.';

  @override
  String get recoveryUpdated => 'கடவுச்சொல் புதுப்பிக்கப்பட்டது';

  @override
  String get recoverySuccess =>
      'உங்கள் கடவுச்சொல் மீட்டமைக்கப்பட்டது. இப்போது புதிய கடவுச்சொல்லுடன் உள்நுழையலாம்.';

  @override
  String get recoveryGoLogin => 'உள்நுழைவுக்குச் செல்';

  @override
  String get recoveryEmailRequired => 'உங்கள் மின்னஞ்சல் முகவரியை உள்ளிடவும்.';

  @override
  String get recoveryEmailInvalid => 'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்.';

  @override
  String get recoveryAccountMissing =>
      'இந்த மின்னஞ்சல் முகவரியில் கணக்கு கிடைக்கவில்லை.';

  @override
  String get recoveryDisabled => 'இந்தக் கணக்கு முடக்கப்பட்டுள்ளது.';

  @override
  String get recoveryTooMany => 'அதிக கோரிக்கைகள். பின்னர் மீண்டும் முயலவும்.';

  @override
  String get recoveryNetwork =>
      'வலைப்பின்னல் பிழை. இணைய இணைப்பைச் சரிபார்க்கவும்.';

  @override
  String get recoverySendFailed =>
      'கடவுச்சொல் மீட்டமைப்பு மின்னஞ்சல் அனுப்பியதை உறுதிப்படுத்த முடியவில்லை.';

  @override
  String get recoveryResetFailed =>
      'கடவுச்சொல் மீட்டமைப்பு உறுதியாகவில்லை. மீண்டும் முயலவும்.';

  @override
  String get recoveryLinkUnavailable =>
      'இந்த இணைப்பு செல்லாதது அல்லது காலாவதியானது. புதியதைப் பெறவும்.';

  @override
  String get recoveryExpired => 'இந்த இணைப்பு காலாவதியானது. புதியதைப் பெறவும்.';

  @override
  String get recoveryInvalid => 'இந்த இணைப்பு செல்லாதது. புதியதைப் பெறவும்.';

  @override
  String get recoveryWeak =>
      'கடவுச்சொல் மிகவும் பலவீனமானது. வலுவான ஒன்றைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get recoveryCreateRequired => 'கடவுச்சொல்லை உருவாக்கவும்.';

  @override
  String get recoveryEightCharacters =>
      'கடவுச்சொல்லில் குறைந்தது 8 எழுத்துகள் தேவை.';

  @override
  String get recoveryLetterRequired =>
      'கடவுச்சொல்லில் குறைந்தது ஓர் எழுத்து தேவை.';

  @override
  String get recoveryNumberRequired => 'கடவுச்சொல்லில் குறைந்தது ஓர் எண் தேவை.';

  @override
  String get recoveryConfirmRequired => 'கடவுச்சொல்லை உறுதிப்படுத்தவும்.';

  @override
  String get recoveryMismatch => 'கடவுச்சொற்கள் பொருந்தவில்லை.';

  @override
  String get recoveryStrength => 'கடவுச்சொல் வலிமை';

  @override
  String get recoveryStrengthWeak =>
      'பலவீனம் — மேலும் எழுத்துகளைச் சேர்க்கவும்';

  @override
  String get recoveryStrengthFair =>
      'ஓரளவு — எண்கள் அல்லது குறியீடுகளைச் சேர்க்கவும்';

  @override
  String get recoveryStrengthGood => 'நல்ல வலிமை';

  @override
  String get recoveryStrengthStrong => 'வலுவான கடவுச்சொல்';

  @override
  String recoveryInstructionsSent(String email) {
    return 'கடவுச்சொல் மீட்டமைப்பு வழிமுறைகளை அனுப்பிய முகவரி\n$email';
  }

  @override
  String get homeMorning => 'காலை வணக்கம்';

  @override
  String get homeAfternoon => 'மதிய வணக்கம்';

  @override
  String get homeEvening => 'மாலை வணக்கம்';

  @override
  String get homeReady => 'பயணத்துக்குத் தயாரா?';

  @override
  String get homeWhere => 'எங்கு செல்கிறீர்கள்?';

  @override
  String get homePlanHint => 'பயணத்தைத் திட்டமிடத் தட்டவும்';

  @override
  String get homeMenu => 'பட்டியலைத் திற';

  @override
  String get homeProfileAction => 'சுயவிவரத்தைத் திற';

  @override
  String get homeTrack => 'பேருந்தைக்\nகண்காணி';

  @override
  String get homePlanAction => 'பயணத்தைத்\nதிட்டமிடு';

  @override
  String get homePreferencesAction => 'அணுகல்\nவிருப்பங்கள்';

  @override
  String get homeHome => 'முகப்பு';

  @override
  String get homePlan => 'திட்டம்';

  @override
  String get homePlanJourney => 'பயணத்தைத் திட்டமிடு';

  @override
  String get homeCommunity => 'சமூகம்';

  @override
  String get homeProfile => 'சுயவிவரம்';

  @override
  String get homeRewards => 'வெகுமதிகளும் பங்களிப்புகளும்';

  @override
  String get homeHelp => 'உதவியும் ஆதரவும்';

  @override
  String get homeLogout => 'வெளியேறு';

  @override
  String get homeRecentReports => 'அண்மைய சமூக அறிக்கைகள்';

  @override
  String get homeNoReports => 'அண்மைய சமூக அறிக்கைகள் இல்லை.';

  @override
  String get homeReportsUnavailable =>
      'சமூக அறிக்கைகள் கிடைக்கவில்லை. பின்னர் மீண்டும் முயலவும்.';

  @override
  String get homeReport => 'அறிக்கை';

  @override
  String get homeRecentJourney => 'அண்மைய பயணம்';

  @override
  String get homeNoJourney => 'பதிவான பயணம் இல்லை';

  @override
  String get homeStartPlanning => 'பயணத்தைத் திட்டமிட்டுத் தொடங்குங்கள்';

  @override
  String get homeJourneysLoading => 'அண்மைய பயணம் ஏற்றப்படுகிறது…';

  @override
  String get homeJourneysUnavailable => 'அண்மைய பயணம் கிடைக்கவில்லை';

  @override
  String get homeRetryLater => 'பின்னர் மீண்டும் முயலவும்';

  @override
  String get homeOrigin => 'தொடக்கம்';

  @override
  String get homeDestination => 'செல்லுமிடம்';

  @override
  String get homeRecent => 'அண்மையில்';

  @override
  String get homeReplan => 'மீண்டும் திட்டமிடு';

  @override
  String get homeAssistance => 'உதவி';

  @override
  String get homeJustNow => 'இப்போது';

  @override
  String get homeUnknownAge => 'அவதானிப்பு நேரம் இல்லை';

  @override
  String homeGreeting(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String homeTrueCount(int count) {
    return 'உண்மை: $count';
  }

  @override
  String homeFalseCount(int count, int threshold) {
    return 'தவறு: $count/$threshold';
  }

  @override
  String homeJourneySegment(String origin, String destination) {
    return '$origin முதல் $destination வரை';
  }

  @override
  String homeMinutesAgo(int count) {
    return '$count நிமிடங்களுக்கு முன்';
  }

  @override
  String homeHoursAgo(int count) {
    return '$count மணிநேரங்களுக்கு முன்';
  }

  @override
  String homeDaysAgo(int count) {
    return '$count நாட்களுக்கு முன்';
  }

  @override
  String homeMonthsAgo(int count) {
    return '$count மாதங்களுக்கு முன்';
  }

  @override
  String get registrationTitle => 'பதிவு';

  @override
  String get registrationJoin => 'Access Transit இல் இணையுங்கள்';

  @override
  String get registrationIntro =>
      'அனைவரும் அணுகக்கூடிய உங்கள் பயணம் இங்கே தொடங்குகிறது.';

  @override
  String get registrationNameHint => 'முழுப் பெயரை உள்ளிடவும்';

  @override
  String get registrationEmailHint => 'மின்னஞ்சலை உள்ளிடவும்';

  @override
  String get registrationPassword => 'கடவுச்சொல்';

  @override
  String get registrationPasswordHint => 'கடவுச்சொல்லை உருவாக்கவும்';

  @override
  String get registrationConfirm => 'கடவுச்சொல்லை உறுதிப்படுத்து';

  @override
  String get registrationConfirmHint => 'கடவுச்சொல்லை மீண்டும் உள்ளிடவும்';

  @override
  String get registrationNeeds =>
      'எனக்குக் குறிப்பிட்ட அணுகல்தன்மைத் தேவைகள் உள்ளன';

  @override
  String get registrationNeedsExample =>
      '(எ.கா., சக்கர நாற்காலிச் சாய்வுப்பாதை, தாழ்தளப் பேருந்து)';

  @override
  String get registrationAccountType => 'கணக்கு வகை';

  @override
  String get registrationCreate => 'கணக்கை உருவாக்கு';

  @override
  String get registrationOr => 'அல்லது';

  @override
  String get registrationGoogle => 'Google மூலம் பதிவு செய்';

  @override
  String get registrationApple => 'Apple மூலம் பதிவு செய்';

  @override
  String get registrationGoogleFeature => 'Google பதிவு';

  @override
  String get registrationAppleFeature => 'Apple பதிவு';

  @override
  String get registrationAlready => 'ஏற்கனவே கணக்கு உள்ளதா? ';

  @override
  String get registrationLogin => 'உள்நுழை';

  @override
  String get registrationExists => 'இந்த மின்னஞ்சலில் ஏற்கனவே கணக்கு உள்ளது.';

  @override
  String get registrationNotEnabled =>
      'மின்னஞ்சல்/கடவுச்சொல் உள்நுழைவு இயக்கப்படவில்லை.';

  @override
  String get registrationRequiredFields =>
      'தேவையான அனைத்துத் தகவல்களையும் சரியாக நிரப்பவும்.';

  @override
  String get registrationFailed =>
      'பதிவு உறுதியாகவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get registrationNameRequired => 'முழுப் பெயரை உள்ளிடவும்.';

  @override
  String get registrationNameShort => 'பெயரில் குறைந்தது 2 எழுத்துகள் தேவை.';

  @override
  String get registrationNameLetters =>
      'பெயரில் எழுத்துகள், இடைவெளிகள், ஒற்றை மேற்கோள்கள், முற்றுப்புள்ளிகள் அல்லது இணைப்புக்கோடுகளைப் பயன்படுத்தவும்.';

  @override
  String get onboardingSkipTooltip => 'அறிமுகத்தைத் தவிர்';

  @override
  String get onboardingSkip => 'தவிர்';

  @override
  String get onboardingStart => 'தொடங்கு';

  @override
  String get onboardingNext => 'அடுத்து';

  @override
  String get onboardingTailored => 'உங்களுக்கு ஏற்ற சேவை';

  @override
  String get onboardingNeedsHelp =>
      'சக்கர நாற்காலி மற்றும் படியற்ற அணுகல் தேவைகளைத் தேர்ந்து தற்போதைய ஆதாரங்களைப் பாருங்கள். குரல் வழிகாட்டல் இல்லை.';

  @override
  String get onboardingNavigate => 'நம்பிக்கையுடன் பயணியுங்கள்';

  @override
  String get onboardingLiveHelp =>
      'இது முன்னோட்டம் மட்டுமே. கிடைக்கும்போது பகிரப்பட்ட GPSஐப் பார்க்கவும்; உதவிக்கு ஓட்டுநரின் பதில் தேவை.';

  @override
  String get onboardingCommunity => 'சமூகத்தின் கண்களாக இருங்கள்';

  @override
  String get onboardingReportsHelp =>
      'சாய்வுப்பாதை மற்றும் உயர்த்தி அவதானிப்புகளைப் பகிரவும். பதிவேற்றம் உறுதியானதும் அறிக்கைகள் பொதுவாகும்; வெகுமதிகளுக்கு பரிசீலனை தேவை.';

  @override
  String get onboardingReportIssue => 'சிக்கலைப் பதிவு செய்';

  @override
  String get onboardingRamps => 'சாய்வுப்பாதைகள்';

  @override
  String get onboardingLowFloor => 'தாழ்தளம்';

  @override
  String get onboardingExampleEta => 'மாதிரி வருகை: 3 நிமி';

  @override
  String get onboardingBoardingHelp => 'ஏறுவதற்கான உதவி';

  @override
  String get onboardingAwaitingReply => 'மாதிரி: பதிலுக்காகக் காத்திருக்கிறது';

  @override
  String get loginFailed => 'உள்நுழைவு உறுதியாகவில்லை. மீண்டும் முயலவும்.';

  @override
  String get loginInvalidCredentials =>
      'மின்னஞ்சல் அல்லது கடவுச்சொல் தவறு. தகவல்களைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get loginDisabled =>
      'இந்தக் கணக்கு முடக்கப்பட்டுள்ளது. உதவியைத் தொடர்புகொள்ளவும்.';

  @override
  String get loginTooMany =>
      'அதிக உள்நுழைவு முயற்சிகள். சிறிது காத்திருந்து மீண்டும் முயலவும்.';

  @override
  String get loginNetwork =>
      'வலைப்பின்னல் பிழை. இணைப்பைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get loginForgot => 'கடவுச்சொல் மறந்துவிட்டதா?';

  @override
  String get loginPasswordHint => 'கடவுச்சொல்லை உள்ளிடவும்';

  @override
  String get loginPasswordRequired => 'கடவுச்சொல்லை உள்ளிடவும்.';

  @override
  String get loginPasswordShort =>
      'கடவுச்சொல்லில் குறைந்தது 6 எழுத்துகள் தேவை.';

  @override
  String get loginOrContinue => 'அல்லது இதன்மூலம் தொடரவும்';

  @override
  String get loginBiometrics => 'உயிரளவியல் மூலம் உள்நுழை';

  @override
  String get loginBiometricFeature => 'உயிரளவியல் உள்நுழைவு';

  @override
  String get loginGoogle => 'Google மூலம் உள்நுழை';

  @override
  String get loginGoogleFeature => 'Google உள்நுழைவு';

  @override
  String get loginNoAccount => 'கணக்கு இல்லையா?';

  @override
  String get loginSignUp => 'பதிவு செய்';

  @override
  String get settingsSaveFailed =>
      'விருப்பங்கள் சேமிக்கப்பட்டது உறுதியாகவில்லை. மீண்டும் முயலவும்.';

  @override
  String get settingsGuestSaved =>
      'சாதன அமைப்புகள் சேமிக்கப்பட்டன. விருந்தினர் பயணத் தேவைகள் இந்த அமர்வுக்கு மட்டுமே.';

  @override
  String get settingsAccountSaved =>
      'இந்தச் சாதனத்தில் இந்தக் கணக்கிற்கான விருப்பங்கள் சேமிக்கப்பட்டன.';

  @override
  String get settingsProfile => 'பயனர் சுயவிவரம்';

  @override
  String get settingsPersonalized => 'தனிப்பயன் பயண அனுபவம்';

  @override
  String get settingsScopeHelp =>
      'உயர் நிற வேறுபாடும் தொடு இலக்குகளும் இந்தச் சாதனத்திற்கானவை. பயணத் தேவைகள் இந்தச் சாதனத்தில் ஒவ்வொரு உள்நுழைந்த கணக்கிற்கும் தனியாகச் சேமிக்கப்படும். விருந்தினர் தேவைகள் இந்த அமர்வுக்கு மட்டும். புதிய கணக்குகளில் சக்கர நாற்காலி அணுகல் தேவை எனத் தொடங்கும்; உங்கள் தேவைகளைப் பாருங்கள்.';

  @override
  String get settingsMobility => 'இயக்கம் மற்றும் உடல் அணுகல்';

  @override
  String get settingsWheelchair => 'சக்கர நாற்காலி அணுகல் தேவை';

  @override
  String get settingsRampHelp =>
      'பொருத்தமான பேருந்துகளுக்குத் தற்போதைய சாய்வுப்பாதை ஆதாரம் தேவை';

  @override
  String get settingsStepFree => 'படியற்ற வழித்தடங்கள் மட்டும்';

  @override
  String get settingsStepFreeHelp =>
      'படிகள் தேவைப்படும் நிறுத்தங்களையும் முனையங்களையும் தவிர்க்கவும்';

  @override
  String get settingsWalking => 'நடக்கும் தூரத்தைக் குறை';

  @override
  String get settingsWalkingUnavailable =>
      'இன்னும் இல்லை — நடைபாதைகளும் தூரங்களும் அளவிடப்படவில்லை';

  @override
  String get settingsSensory => 'புலனுணர்வும் பார்வையும்';

  @override
  String get settingsContrast => 'உயர் நிற வேறுபாட்டு முறை';

  @override
  String get settingsContrastHelp =>
      'உரைத் தெளிவையும் வலுவான எல்லைகளையும் மேம்படுத்து (WCAG AAA)';

  @override
  String get settingsLargeTargets => 'பெரிய தொடு இலக்குகள் (48dp+)';

  @override
  String get settingsTargetsHelp =>
      'பொத்தான்களுக்கும் கட்டுப்பாடுகளுக்கும் குறைந்தது 48dp தொடு இலக்குகளைப் பயன்படுத்து';

  @override
  String get settingsTargetsEnabled =>
      'பெரிய தொடு இலக்குகள் (48dp+) இயக்கப்பட்டன';

  @override
  String get settingsTargetsStandard => 'வழக்கமான தொடு இலக்குகள் இயக்கப்பட்டன';

  @override
  String get settingsVoice => 'பயணத்திற்கான குரல் வழிகாட்டல்';

  @override
  String get settingsVoiceUnavailable =>
      'இன்னும் இல்லை — இடைமுகப் பெயர்களைக் கேட்கத் தொலைபேசியின் திரை வாசிப்பானைப் பயன்படுத்தவும்';

  @override
  String get settingsHaptics => 'நிறுத்தங்களுக்கான அதிர்வு அறிவிப்புகள்';

  @override
  String get settingsHapticsUnavailable =>
      'இன்னும் இல்லை — தானியங்கி அதிர்வு அறிவிப்புகள் ஆதரிக்கப்படவில்லை';

  @override
  String get settingsAssistance => 'உதவியும் சூழலும்';

  @override
  String get settingsBoarding => 'ஏறுவதற்கான உதவி தேவை';

  @override
  String get settingsBoardingUnavailable =>
      'தானியங்கி கோரிக்கைகள் இன்னும் இல்லை — பயணத் திரையிலிருந்து உதவி கோரவும்';

  @override
  String get settingsQuiet => 'அமைதியான வழித்தடங்களைக் காட்டு';

  @override
  String get settingsQuietUnavailable =>
      'இன்னும் இல்லை — ஒலி அளவுகள் தெரியவில்லை';

  @override
  String get settingsSave => 'விருப்பங்களைச் சேமி';

  @override
  String get searchSwapped =>
      '⇄ ஏறும் மற்றும் சேருமிட நிறுத்தங்கள் மாற்றப்பட்டன';

  @override
  String get searchSelectBoarding => 'ஏறும் நிறுத்தத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get searchSelectDestination =>
      'இறங்கும் நிறுத்தத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get searchTravelChoice => 'பயண நேரத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get searchLeaveNow => 'இப்போது புறப்படவும்';

  @override
  String get searchSpecificTime => 'குறிப்பிட்ட நேரத்தை அமைக்கவும்';

  @override
  String get searchChooseTime => 'புறப்படும் நேரத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get searchChangeDate => 'பயணத் தேதியை மாற்றவும்';

  @override
  String get searchNeedsTitle => 'அணுகல் தேவைகள்';

  @override
  String get searchTemporaryHelp =>
      'இந்தப் பயணத்திற்கு மட்டும் மாற்றவும். அமைப்புகளில் சேமித்த அணுகல் விருப்பங்கள் மாறாது.';

  @override
  String get searchWheelchairChip => '♿ சக்கர நாற்காலி';

  @override
  String get searchStepFreeChip => 'படிகள் அற்றது';

  @override
  String get searchResetHelp => 'சேமித்த அணுகல் விருப்பங்களை மீட்டமைக்கவும்';

  @override
  String get searchReset => 'மீட்டமைக்கவும்';

  @override
  String get searchRamp => 'சக்கர நாற்காலிச் சாய்வுப்பாதை';

  @override
  String get searchRampHelp =>
      'செயல்படும் சக்கர நாற்காலிச் சாய்வுப்பாதைகள் உள்ள பேருந்துகள் தேவை';

  @override
  String get searchStepFree => 'நிறுத்தத்தில் படிகள் அற்ற அணுகல்';

  @override
  String get searchStepFreeHelp =>
      'மின்தூக்கிகள் அல்லது சமதளப் பாதைகள் உள்ள நிறுத்தங்கள் மட்டும்';

  @override
  String get searchMinWalking => 'நடக்கும் தூரத்தைக் குறைக்கவும்';

  @override
  String get searchWalkingUnknown =>
      'இன்னும் கிடைக்கவில்லை — நடக்கும் தூரம் தெரியவில்லை';

  @override
  String get searchApply => 'இந்தப் பயணத்திற்குப் பயன்படுத்தவும்';

  @override
  String get searchEndpointsRequired =>
      'ஏறும் மற்றும் இறங்கும் நிறுத்தங்களைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get searchEndpointsDifferent =>
      'ஏறும் மற்றும் இறங்கும் நிறுத்தங்கள் ஒன்றாக இருக்க முடியாது.';

  @override
  String get searchRampRequired => 'சாய்வுப்பாதை தேவை';

  @override
  String get searchStepFreeFilter => 'படிகள் அற்றது';

  @override
  String get searchMinWalkFilter => 'குறைந்த நடை';

  @override
  String get searchFind => 'பேருந்துகளைத் தேடவும்';

  @override
  String get searchNoStops =>
      'பகிரப்பட்ட நிறுத்தத் தரவு இல்லை. இணைந்து மீண்டும் முயலவும்.';

  @override
  String get searchPlan => 'பயணத்தைத் திட்டமிடவும்';

  @override
  String get searchSync => 'பேருந்துத் தரவை மீண்டும் பெறவும்';

  @override
  String get searchBoardingHeading => 'ஏறும் நிறுத்தம்';

  @override
  String get searchChooseBoarding => 'ஏறும் நிறுத்தத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get searchRampAvailable => '♿ சக்கர நாற்காலிச் சாய்வுப்பாதை உள்ளது';

  @override
  String get searchStandardStop => 'வழக்கமான நிறுத்தம்';

  @override
  String get searchTapBoarding => 'ஏறும் நிறுத்தத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get searchSwap => 'ஏறும் மற்றும் இறங்கும் நிறுத்தங்களை மாற்றவும்';

  @override
  String get searchDestinationHeading => 'எங்கு செல்கிறீர்கள்?';

  @override
  String get searchChooseDestination => 'சேருமிடத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get searchAccessibleDestination => '♿ அணுகல் வசதியுள்ள சேருமிடம்';

  @override
  String get searchTapDestination => 'இறங்கும் நிறுத்தத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get searchMyLocation => 'எனது இருப்பிடம்';

  @override
  String get searchBoardingSuggestions => 'ஏறும் நிறுத்தப் பரிந்துரைகள்';

  @override
  String get searchDestinationSuggestions => 'இறங்கும் நிறுத்தப் பரிந்துரைகள்';

  @override
  String get searchSuggestions => 'நிறுத்தப் பரிந்துரைகளைக் காணவும்';

  @override
  String get searchDepartNow => 'இப்போது புறப்படவும்';

  @override
  String get searchTravelHeading => 'பயண நேரம்';

  @override
  String get searchChange => 'மாற்றவும்';

  @override
  String get searchOptions => 'அணுகல் விருப்பங்கள்';

  @override
  String get searchConfigure => 'அமைக்கவும்';

  @override
  String get searchAllBusesHelp =>
      'அனைத்துப் பேருந்துகளும் காட்டப்படும். சாய்வுப்பாதை அல்லது படிகள் அற்ற அணுகல் தேவை எனில் அமைக்கவும்.';

  @override
  String get searchStationHint =>
      'நிறுத்தம் அல்லது நகரத்தை உள்ளிடவும் (எ.கா. Pettah, Mount Lavinia)...';

  @override
  String get searchAllStops => 'அனைத்து நிறுத்தங்களும்';

  @override
  String get searchNoMatches =>
      'பொருந்தும் நிறுத்தங்கள் இல்லை.\nவேறு எழுத்துக்கூட்டலை முயலவும் அல்லது வடிகட்டிகளை அகற்றவும்.';

  @override
  String get searchRampBadge => 'சாய்வுப்பாதை  ';

  @override
  String get searchElevatorBadge => 'மின்தூக்கி  ';

  @override
  String get searchSuggestionIcon => 'நிறுத்தப் பரிந்துரைகள்';

  @override
  String get searchSuggestedBoarding => 'ஏறும் நிறுத்தப் பரிந்துரைகள்';

  @override
  String get searchSuggestedDestination => 'இறங்கும் நிறுத்தப் பரிந்துரைகள்';

  @override
  String get searchVoiceUnavailable =>
      'குரல் அறிதல் இன்னும் கிடைக்கவில்லை. கீழே ஒரு நிறுத்தத்தைத் தேர்ந்தெடுக்கவும்:';

  @override
  String searchSelectedTime(String time) {
    return 'தேர்ந்த நேரம்: $time';
  }

  @override
  String searchTodayAt(String time) {
    return 'இன்று $time';
  }

  @override
  String searchDateAt(String date, String time) {
    return '$date அன்று $time';
  }

  @override
  String searchStopSelected(String name) {
    return 'தேர்ந்த நிறுத்தம்: $name';
  }

  @override
  String searchActiveNeeds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count செயலில்',
      one: '1 செயலில்',
    );
    return '$_temp0';
  }

  @override
  String get resultsScheduled => 'அட்டவணைப்படி';

  @override
  String get resultsPastUnconfirmed =>
      'நியமித்த நேரம் கடந்தது — புறப்பாடு உறுதியாகவில்லை';

  @override
  String get resultsNowUnconfirmed =>
      'நியமித்த நேரம் இப்போது — புறப்பாடு உறுதியாகவில்லை';

  @override
  String get resultsRampReady =>
      'சக்கர நாற்காலிச் சாய்வுப்பாதை தயார் · படிகள் அற்ற நுழைவு';

  @override
  String get resultsRampEquipped =>
      'சாய்வுப்பாதை உள்ளது · ஓட்டுநர் உதவியை விசாரிக்கவும்';

  @override
  String get resultsStandardService => 'வழக்கமான பேருந்துச் சேவை';

  @override
  String get resultsUnknown => 'தெரியவில்லை';

  @override
  String get resultsLow => 'குறைவு';

  @override
  String get resultsMedium => 'நடுத்தரம்';

  @override
  String get resultsHigh => 'அதிகம்';

  @override
  String get resultsStarted => 'தொடங்கிய சேவை';

  @override
  String get resultsDemoTimetable => 'மாதிரி அட்டவணை';

  @override
  String get resultsPublishedTimetable => 'வெளியிடப்பட்ட அட்டவணை';

  @override
  String get resultsWheelchairBus => 'சக்கர நாற்காலி அணுகல் வசதியுள்ள பேருந்து';

  @override
  String get resultsRampBus => 'சாய்வுப்பாதையுள்ள வழக்கமான பேருந்து';

  @override
  String get resultsStandardBus => 'வழக்கமான பேருந்து';

  @override
  String get resultsEstimatedTimes =>
      'சில நேரங்கள் மாதிரி மதிப்பீடுகள்; ஓட்டுநரிடம் உறுதிப்படுத்தவும்.';

  @override
  String get resultsWalkingUnknown =>
      'இந்தப் பயணத்தின் நடைத் தூரம் கிடைக்கவில்லை. முடிவுகள் நடைத் தூரப்படி வரிசைப்படுத்தப்படவில்லை.';

  @override
  String get resultsReviewNeeds => 'பயணத் தேவைகளை மீளாய்வு செய்யவும்';

  @override
  String get resultsReviewHelp =>
      'மாற்றங்கள் இந்தத் தேடலுக்கு மட்டும். தேவையை நீக்கினால் அணுகல் தெரியாத அல்லது தடைகள் அறிவிக்கப்பட்ட சேவைகள் காட்டப்படலாம். பயணத்தைத் தேர்வதற்கு முன் ஆதாரங்களைப் பார்க்கவும்.';

  @override
  String get resultsKeepNeeds => 'தேவைகளை வைத்திருக்கவும்';

  @override
  String get resultsApplyNeeds => 'இந்தத் தேடலுக்குப் பயன்படுத்தவும்';

  @override
  String get resultsNoAccessible =>
      'அணுகல் தேவைகளைப் பூர்த்திசெய்யும் பேருந்துகள் இல்லை';

  @override
  String get resultsNoDirect => 'நேரடிப் பேருந்துகள் இல்லை';

  @override
  String get resultsNoAccessibleHelp =>
      'இந்தத் தேவைகளுக்குப் பொருந்தும் அறியப்பட்ட அணுகல் வசதியுள்ள அட்டவணைப் பயணங்கள் இல்லை. நிறுத்த அணுகல் தெரியாமல் இருக்கலாம் அல்லது தடை அறிவிக்கப்பட்டிருக்கலாம். அணுகல் வடிகட்டிகளை மீளாய்வு செய்யவும்.';

  @override
  String get resultsShowAll => 'பொருந்தும் அனைத்துப் பேருந்துகளையும் காட்டவும்';

  @override
  String get resultsShowAllHelp =>
      'அணுகல் தெரியாத அல்லது தடைகள் அறிவிக்கப்பட்ட சேவைகள் உட்பட அணுகல் தாவலுக்கு வெளியேயுள்ள விருப்பங்களைக் காட்டும். உங்கள் பயணத் தேவைகள் தொடர்ந்து பொருந்தும்.';

  @override
  String get resultsTitle => 'கிடைக்கும் பேருந்துகள்';

  @override
  String get resultsChooseHelp =>
      'விவரங்களைக் காண ஒரு பேருந்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get resultsFastest => 'வேகமானது';

  @override
  String get resultsRoute => 'வழித்தடம்';

  @override
  String get resultsTimetableHelp =>
      'அட்டவணை மதிப்பீடுகள் — புறப்பாடு உறுதியாகவில்லை. GPS நிலைக்குப் பேருந்து விவரங்களைப் பார்க்கவும்.';

  @override
  String get resultsDeparture => 'புறப்பாடு';

  @override
  String get resultsArrival => 'வருகை';

  @override
  String get resultsRampAvailable => 'சாய்வுப்பாதை உள்ளது';

  @override
  String get resultsLowFloor => 'தாழ்தளம்';

  @override
  String get detailsAmbiguous =>
      'புறப்பாட்டின் அடையாளம் தெளிவில்லை. தேர்வைப் புதுப்பிக்கவும்.';

  @override
  String get detailsAccountChanged =>
      'கணக்கு மாறியது. தேடலுக்குத் திரும்பவும்.';

  @override
  String get detailsUnavailable => 'சேவை கிடைக்கவில்லை. மீண்டும் முயலவும்';

  @override
  String get detailsRunUnavailable => 'சேவையின் நிலை கிடைக்கவில்லை';

  @override
  String get detailsRunUnverified => 'அட்டவணைப்படி · சேவை உறுதியாகவில்லை';

  @override
  String get detailsCompleted => 'முடிந்தது';

  @override
  String get detailsCancelled => 'ரத்துசெய்யப்பட்டது';

  @override
  String get detailsStale => 'இருப்பிடம் இல்லை அல்லது பழையது';

  @override
  String get detailsLive => 'நேரடி GPS';

  @override
  String get detailsWheelchair => 'சக்கர நாற்காலி அணுகல்';

  @override
  String get detailsSavedHelp =>
      'சேமித்த தேர்வு · நேரங்களும் தேவைகளும் பாதுகாக்கப்பட்டுள்ளன; தற்போதைய நிலைமைகளைப் பார்க்கவும்.';

  @override
  String get detailsDefaultsDiffer =>
      'தற்போதைய அணுகல் விருப்பங்கள் இந்தச் சேமித்த தேர்விலிருந்து வேறுபடுகின்றன.';

  @override
  String get detailsCatalogueUnavailable =>
      'பட்டியல் புதுப்பிப்புகள் கிடைக்கவில்லை.';

  @override
  String get detailsStops => 'உங்கள் பயண நிறுத்தங்கள்';

  @override
  String get detailsIntermediateUnknown => 'இடைநிறுத்தம் · நேரம் கிடைக்கவில்லை';

  @override
  String get detailsEvidence => 'அணுகல் ஆதாரங்கள்';

  @override
  String get detailsAssistanceUnavailable => 'ஓட்டுநர் உதவி கிடைக்கவில்லை';

  @override
  String get detailsReport => 'நிலைமையை அறிவிக்கவும்';

  @override
  String get detailsLoadingReports => 'அறிக்கைகள் ஏற்றப்படுகின்றன…';

  @override
  String get detailsRetry => 'புதுப்பிப்புகளை மீண்டும் முயலவும்';

  @override
  String get detailsVerifySave =>
      'சேமிப்பதற்கு முன் இணைந்து இந்தப் புறப்பாட்டை உறுதிப்படுத்தவும்.';

  @override
  String get resultsSafe => 'அணுகல் ஆதாரங்கள் பொருந்துகின்றன';

  @override
  String get resultsWarning => 'கவனம் தேவை';

  @override
  String get resultsNotAccessible => 'அணுகல் வசதிகள் பொருந்தவில்லை';

  @override
  String get detailsResolved => 'தீர்க்கப்பட்டது';

  @override
  String get detailsRecheckUnknown =>
      'தீர்க்கப்படாத தடை — கவனித்த நேரம் தெரியவில்லை; மீள்சோதனை தேவை';

  @override
  String get detailsObservationUnknown => 'கவனித்த நேரம் தெரியவில்லை';

  @override
  String get detailsExpired => 'காலாவதியானது அல்லது கிடைக்கவில்லை';

  @override
  String get detailsRecheck => 'தீர்க்கப்படாத தடை — மீள்சோதனை தேவை';

  @override
  String get detailsRecent => 'அண்மைய கவனிப்பு';

  @override
  String resultsRouteNumber(String number) {
    return 'வழித்தடம் $number';
  }

  @override
  String resultsScheduledDate(String date, String time) {
    return 'நியமித்த நேரம்: $date, $time';
  }

  @override
  String resultsScheduledAt(String date, String time) {
    return 'நியமித்த நேரம்: $date அன்று $time';
  }

  @override
  String resultsTomorrow(String time) {
    return 'நாளை நியமித்த நேரம்: $time';
  }

  @override
  String resultsTomorrowAt(String time) {
    return 'நாளை நியமித்த நேரம் $time';
  }

  @override
  String resultsToday(String time) {
    return 'இன்று நியமித்த நேரம்: $time';
  }

  @override
  String resultsTodayAt(String time) {
    return 'இன்று நியமித்த நேரம் $time';
  }

  @override
  String resultsScheduledIn(int minutes, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes நிமிடங்களில் நியமிக்கப்பட்டுள்ளது - $time',
      one: '1 நிமிடத்தில் நியமிக்கப்பட்டுள்ளது - $time',
    );
    return '$_temp0';
  }

  @override
  String resultsBoardingEstimate(String time, String source) {
    return 'ஏறும் நேர மதிப்பீடு $time · $source';
  }

  @override
  String resultsCountTitle(int count) {
    return 'கிடைக்கும் பேருந்துகள் ($count)';
  }

  @override
  String resultsAvailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count பேருந்துகள் கிடைக்கின்றன',
      one: '1 பேருந்து கிடைக்கிறது',
    );
    return '$_temp0';
  }

  @override
  String resultsNoDirectHelp(String origin, String destination) {
    return 'தற்போது $origin முதல் $destination வரை நேரடிப் பேருந்து வழித்தடங்கள் இல்லை.';
  }

  @override
  String resultsAllTab(int count) {
    return 'அனைத்தும் ($count)';
  }

  @override
  String resultsAccessibleTab(int count) {
    return 'அணுகல் வசதி ($count)';
  }

  @override
  String resultsDuration(int minutes) {
    return '~$minutes நிமிடம்';
  }

  @override
  String resultsCrowd(String level) {
    return 'பயணிகள் நெரிசல்: $level';
  }

  @override
  String resultsBoardingSource(String source) {
    return 'ஏறும் நேர மதிப்பீடு · $source';
  }

  @override
  String detailsBoardingAt(String date, String time) {
    return 'நியமித்த ஏறும் நேரம்: $date · $time';
  }

  @override
  String detailsArrivalAt(String date, String time) {
    return 'நியமித்த வருகை: $date · $time';
  }

  @override
  String detailsDuration(int minutes) {
    return '$minutes நிமிடம் · தேர்ந்த பயணப் பகுதி';
  }

  @override
  String detailsBoardHere(String time) {
    return 'இங்கே ஏறவும் · $time';
  }

  @override
  String detailsAlightHere(String time) {
    return 'இங்கே இறங்கவும் · $time';
  }

  @override
  String detailsScheduledStop(String time) {
    return 'நியமித்த நேரம் $time';
  }

  @override
  String detailsNextStop(String name) {
    return 'பயணத்தின் அடுத்த நிறுத்தம்: $name';
  }

  @override
  String get resultsSourceDated => 'தேதியிட்ட அட்டவணை';

  @override
  String get resultsSourceRoad =>
      'சாலை முன்னேற்றம் + அட்டவணை (குறைந்த நம்பகத்தன்மை)';

  @override
  String get resultsSourceBoarding => 'ஏறும் நிறுத்தத்தில் GPS';

  @override
  String get resultsSourceInterval =>
      'GPS கவனித்த நிறுத்தத்திலிருந்து அட்டவணை நேர இடைவெளி';

  @override
  String get evidenceRecheckSummary => 'தீர்க்கப்படாத தடை - மீள்சோதனை தேவை';

  @override
  String get evidenceBarrierSummary =>
      'தடை அறிவிக்கப்பட்டுள்ளது - பயணத்திற்கு முன் பார்க்கவும்';

  @override
  String get evidencePositiveSummary =>
      'சாதகமான கவனிப்பு - விவரங்களைப் பார்க்கவும்';

  @override
  String get evidenceUnknownSummary => 'தெரியவில்லை - தற்போதைய கவனிப்பு இல்லை';

  @override
  String get evidenceTimeUnknown => 'தெரியவில்லை - கவனித்த நேரம் கிடைக்கவில்லை';

  @override
  String get evidenceExpired => 'தெரியவில்லை — அண்மைய கவனிப்பு காலாவதியானது';

  @override
  String get evidenceRecheckUnknown =>
      'தீர்க்கப்படாத தடை — மீள்சோதனை தேவை; தற்போதைய நிலை தெரியவில்லை';

  @override
  String get evidenceConditionUnknown =>
      'தெரியவில்லை — நிலையைத் தீர்மானிக்க முடியவில்லை';

  @override
  String get evidenceBarrierConfirmed =>
      'தடை — சமூகத்தால் உறுதிப்படுத்தப்பட்ட கவனிப்பு';

  @override
  String get evidencePositiveConfirmed =>
      'சாதகமானது — சமூகத்தால் உறுதிப்படுத்தப்பட்ட கவனிப்பு';

  @override
  String get evidenceBarrierUnverified =>
      'தடை அறிவிக்கப்பட்டுள்ளது — உறுதிப்படுத்தல் தெரியவில்லை';

  @override
  String get evidencePositiveUnverified =>
      'சாதகமான நிலை அறிவிக்கப்பட்டுள்ளது — உறுதிப்படுத்தல் தெரியவில்லை';

  @override
  String get evidenceNoConfirmationTime => 'உறுதிப்படுத்திய நேரம்: தெரியவில்லை';

  @override
  String get evidenceVehicleSection => 'பேருந்துச் சாய்வுப்பாதை நிலைமைகள்';

  @override
  String get evidenceBoardingSection => 'ஏறும் நிறுத்த நிலைமைகள்';

  @override
  String get evidenceDestinationSection => 'இறங்கும் நிறுத்த நிலைமைகள்';

  @override
  String get evidenceAssistanceSection => 'ஓட்டுநர் உதவி குறித்த கவனிப்புகள்';

  @override
  String get evidenceDisclosure =>
      'சமூகக் கவனிப்புகள் குறிப்பிட்ட நிலைமைகளை விவரிக்கின்றன; முழுப் பயணத்தையும் உறுதிப்படுத்துவதில்லை.';

  @override
  String get evidenceEmpty => 'தெரியவில்லை — கவனிப்பு கிடைக்கவில்லை';

  @override
  String get evidenceMember => 'சமூக உறுப்பினர்';

  @override
  String get rampWorkingObserved => 'செயல்படுவதாகக் கவனிக்கப்பட்டது';

  @override
  String get rampBrokenUnresolved =>
      'பழுது அறிவிக்கப்பட்டுள்ளது - தீர்க்கப்படாத எச்சரிக்கை';

  @override
  String get rampNewCheck => 'தெரியவில்லை - புதிய சோதனை தேவை';

  @override
  String get rampEquipped => 'பொருத்தப்பட்டுள்ளது';

  @override
  String get rampNotListed => 'பட்டியலிடப்படவில்லை';

  @override
  String get rampTitle => 'பேருந்தின் சாய்வுப்பாதை';

  @override
  String get rampOperatorSource => 'ஓட்டுநர் கவனிப்பு';

  @override
  String get rampBarrierDisclosure =>
      'செயல்படுவதாகக் கவனித்தது ஏற்கனவே அறிவிக்கப்பட்ட சமூகத் தடைகளைத் தீர்ப்பதில்லை.';

  @override
  String get mapMissingCoordinates =>
      'வரைபடம் கிடைக்கவில்லை · நிறுத்த ஆயங்கள் மீளாய்வு செய்யப்படவில்லை. நிறுத்தப் பட்டியலைப் பயன்படுத்தவும்.';

  @override
  String get mapCurrentBus => 'பேருந்தின் தற்போதைய இருப்பிடம்';

  @override
  String get mapNoRoadGeometry =>
      'நிறுத்த இருப்பிடங்கள் · சாலை வழித்தட வடிவத் தரவு கிடைக்கவில்லை';

  @override
  String get mapTileRetry =>
      'வரைபடப் பகுதிகள் கிடைக்கவில்லை · மீண்டும் முயலவும் அல்லது நிறுத்தப் பட்டியலைப் பயன்படுத்தவும்';

  @override
  String get timetableUnassigned =>
      'வெளியிடப்பட்ட அட்டவணை • வாகனம் ஒதுக்கப்படவில்லை';

  @override
  String get timetableUnknownDisclosure =>
      'நேரங்கள் மாறலாம். வாகனப் பதிவு, அணுகல் வசதி மற்றும் நேரடி இருப்பிடம் தெரியவில்லை. அங்கீகரிக்கப்பட்ட வாகனம் இணைக்கப்படும் வரை ஓட்டுநர் உதவி கிடைக்காது.';

  @override
  String evidenceCheckedAt(String time) {
    return 'கடைசியாகச் சோதித்தது: $time';
  }

  @override
  String evidenceRecheckedAt(String time, String name) {
    return 'கடைசி மீள்சோதனை: $time, $name மூலம். தனித்துவமான உறுதிப்படுத்தல்கள் மாறவில்லை.';
  }

  @override
  String evidenceDueAt(String time) {
    return 'மீள்சோதனை செய்யவேண்டிய நேரம்: $time';
  }

  @override
  String evidenceExpiresAt(String time) {
    return 'கவனிப்பு காலாவதியாகும் நேரம்: $time';
  }

  @override
  String evidenceReportedAt(String time) {
    return 'அறிவித்த நேரம்: $time';
  }

  @override
  String evidenceConfirmedAt(String time) {
    return 'கடைசி உறுதிப்படுத்தல் பதிவான நேரம்: $time';
  }

  @override
  String evidenceReporter(String name) {
    return 'அறிவித்தவர்: $name';
  }

  @override
  String evidenceConfirmers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'உறுதிப்படுத்தியவர்கள்: $count சமூக உறுப்பினர்கள்',
      one: 'உறுதிப்படுத்தியவர்: 1 சமூக உறுப்பினர்',
    );
    return '$_temp0';
  }

  @override
  String rampCapability(String capability) {
    return 'சாய்வுப்பாதை பொருத்தம்: $capability';
  }

  @override
  String rampCheckedAge(String age) {
    return 'சாய்வுப்பாதை கடைசியாகச் சோதித்தது: $age';
  }

  @override
  String rampSource(String source) {
    return 'சாய்வுப்பாதைக் கவனிப்பின் மூலம்: $source';
  }

  @override
  String rampRecordedAt(String time) {
    return 'சோதனை பதிவான நேரம்: $time';
  }

  @override
  String mapUpdatedAt(String time) {
    return 'இருப்பிடம் புதுப்பிக்கப்பட்டது: $time';
  }

  @override
  String timetableSource(String source) {
    return 'மூலம்: $source';
  }

  @override
  String get reportSignInChange =>
      'பகிரப்பட்ட அறிக்கையை மாற்றுவதற்கு முன் உள்நுழையவும்.';

  @override
  String get reportChangeUnconfirmed =>
      'மாற்றம் உறுதியாகவில்லை. இணைப்பையும் உள்நுழைவையும் சரிபார்த்து மீண்டும் முயலவும் அல்லது அறிக்கையைப் புதுப்பிக்கவும்.';

  @override
  String get reportCopied => 'அறிவிப்பின் உரை நகலெடுக்கப்பட்டது!';

  @override
  String get reportCopyFailed =>
      'அறிவிப்பை நகலெடுக்க முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get reportImageUnavailable => 'பட முன்னோட்டம் கிடைக்கவில்லை';

  @override
  String get reportDetailsTitle => 'அறிக்கை விவரங்கள்';

  @override
  String get reportRemoved =>
      'பகிரப்பட்ட அறிக்கை இல்லை அல்லது அகற்றப்பட்டது. புதுப்பிக்கப் பட்டியலை மீண்டும் திறக்கவும்.';

  @override
  String get reportShare => 'அறிவிப்பைப் பகிரவும்';

  @override
  String get reportStaleUpdates =>
      'பகிரப்பட்ட புதுப்பிப்புகள் இல்லை. கடைசியாகப் பெற்ற கவனிப்பு காட்டப்படுகிறது; செயல்படுவதற்கு முன் புதுப்பிக்கவும்.';

  @override
  String get reportSignInActions =>
      'பகிரப்பட்ட அறிக்கைகளை உறுதிப்படுத்த, குறிக்க அல்லது தீர்வைப் பதிவு செய்ய உள்நுழையவும்.';

  @override
  String get reportResolutionDisclosure =>
      'தீர்வு என்பது ஆசிரியர் பதிவுசெய்த கவனிப்பு; அது பழுதுபார்ப்பைச் சுயாதீனமாக உறுதிப்படுத்துவதில்லை.';

  @override
  String get reportResolutionUnknown => 'தீர்வு நேரம்: தெரியவில்லை';

  @override
  String get reportResolvedTitle => 'தீர்க்கப்பட்டதாகப் பதிவு செய்யப்பட்டது';

  @override
  String get reportResolvedHelp =>
      'இந்த நிலை தீர்க்கப்பட்டதாக ஆசிரியர் பதிவு செய்துள்ளார்.';

  @override
  String get reportObservationUnknown => 'கவனித்த நேரம் தெரியவில்லை';

  @override
  String get reportUnknownHelp =>
      'கவனித்த தேதி கிடைக்கவில்லை. தற்போதைய நிலையை உறுதிப்படுத்த முடியாது.';

  @override
  String get reportConfirmedTitle => 'சமூகத்தால் உறுதிப்படுத்தப்பட்ட கவனிப்பு';

  @override
  String get reportActiveTitle => 'செயலில் உள்ள போக்குவரத்து அறிக்கை';

  @override
  String get reportActiveHelp =>
      'பயணியால் அறிவிக்கப்பட்டது. கவனித்த நேரத்தையும் தற்போதைய ஆதாரங்களையும் பார்க்கவும்.';

  @override
  String get reportExpiredTitle => 'முந்தைய அறிக்கை (காலாவதியானது)';

  @override
  String get reportExpiredHelp =>
      'இந்தக் கவனிப்பு காலாவதியானது; தற்போதைய நிலையை அது உறுதிப்படுத்துவதில்லை.';

  @override
  String get reportYours => 'உங்கள் அறிக்கை';

  @override
  String get reportBus => 'பேருந்து';

  @override
  String get reportStation => 'நிறுத்தம்';

  @override
  String get reportHighSeverity => 'கடுமையானது';

  @override
  String get reportMinorSeverity => 'சிறிய பிரச்சினை';

  @override
  String get reportModerateSeverity => 'மிதமானது';

  @override
  String get reportConditionDetails => 'அறிவிக்கப்பட்ட நிலையின் விவரங்கள்';

  @override
  String get reportRiderNote => 'பயணியின் குறிப்பு:';

  @override
  String get reportPhotoEvidence => 'இணைக்கப்பட்ட பட ஆதாரம்';

  @override
  String get reportEnlarge => 'பெரிதாக்கத் தட்டவும்';

  @override
  String get reportPhotoUnavailable => 'படம் கிடைக்கவில்லை';

  @override
  String get reportMetrics => 'சமூக உறுதிப்படுத்தல்களும் குறிகளும்';

  @override
  String get reportRecheckDisclosure =>
      'மீள்சோதனைகள் தேதியிட்ட கவனிப்புகள்; தனித்துவமான உறுதிப்படுத்தல்கள் மாறாது.';

  @override
  String get reportVoteHeading => 'அறிக்கையின் துல்லியத்திற்கு வாக்களிக்கவும்';

  @override
  String get reportRecheckAction => 'நிலையை மீண்டும் சோதிக்கவும்';

  @override
  String get reportFixed => 'தீர்க்கப்பட்டதாகக் குறிக்கப்பட்டது';

  @override
  String get reportResolveAction => 'நிலை தீர்க்கப்பட்டதாகப் பதிவு செய்யவும்';

  @override
  String get reportRampCategory => 'சாய்வுப்பாதையும் அணுகலும்';

  @override
  String get reportLiftCategory => 'மின்தூக்கி';

  @override
  String get reportCrowdingCategory => 'பயணிகள் நெரிசல்';

  @override
  String get reportCleanCategory => 'தூய்மை';

  @override
  String get reportSafetyCategory => 'பாதுகாப்பு ஆபத்து';

  @override
  String get deliveryTitle => 'அறிக்கை அனுப்புதல்';

  @override
  String get deliveryStatus => 'வெளியீட்டு நிலை';

  @override
  String get deliveryDraftUnavailable => 'வரைவு கிடைக்கவில்லை';

  @override
  String get deliveryPublished => 'வெளியிடப்பட்டது';

  @override
  String get deliveryPending => 'பதிவேற்றம் நிலுவையில் உள்ளது';

  @override
  String get deliveryFailed => 'தோல்வியடைந்தது';

  @override
  String get deliveryPublicHelp => 'உங்கள் அறிக்கையை மற்ற பயணிகள் காணலாம்.';

  @override
  String get deliveryRemovedHelp =>
      'இந்த வரைவு அகற்றப்பட்டது, காலாவதியானது அல்லது வேறு கணக்கிற்குரியது. வெளியீடு உறுதியாகவில்லை.';

  @override
  String get deliveryPendingHelp =>
      'இந்தச் சாதனத்தில் சேமிக்கப்பட்டது. வெளியீடு உறுதியாகவில்லை.';

  @override
  String get deliveryLocalUnavailable => 'சாதன வரைவு கிடைக்கவில்லை';

  @override
  String get deliveryObservation => 'உங்கள் கவனிப்பு';

  @override
  String get deliveryTarget => 'இடம் / வாகனம்';

  @override
  String get deliveryCondition => 'அறிவித்த நிலை';

  @override
  String get deliveryPhoto => 'இணைக்கப்பட்ட படம்';

  @override
  String get deliveryPhotoUnavailable => 'பட முன்னோட்டம் கிடைக்கவில்லை';

  @override
  String get deliveryUploading => 'பதிவேற்றப்படுகிறது…';

  @override
  String get deliveryRetry => 'மீண்டும் பதிவேற்றவும்';

  @override
  String get deliveryRemoveDevice => 'இந்தச் சாதனத்திலிருந்து வரைவை அகற்றவும்';

  @override
  String get deliveryAboutDrafts => 'சாதன வரைவுகள் பற்றி';

  @override
  String get deliveryDraftExpiry =>
      'வரைவுகள் 7 நாட்களில் காலாவதியாகும்; வெளியேறும்போது அல்லது கணக்கு மாறும்போது அகற்றப்படும்.';

  @override
  String get deliveryViewFeed => 'சமூக அறிக்கைகளைக் காணவும்';

  @override
  String get deliveryHome => 'முகப்புக்குத் திரும்பவும்';

  @override
  String get deliverySaveFailed =>
      'பதிவேற்ற நிலையைச் சேமிக்க முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get deliveryRemoveQuestion => 'சாதன வரைவை அகற்றவா?';

  @override
  String get deliveryRemoveHelp =>
      'இனிவரும் முயற்சிகளை நிறுத்தி சாதனக் குறிப்பு/படத்தை அகற்றும். ஏற்கனவே அனுப்பிய கோரிக்கை நிறைவடையலாம். இது பொது அறிக்கையையோ பதிவேற்றிய படத்தையோ நீக்காது.';

  @override
  String get deliveryKeep => 'வரைவை வைத்திருக்கவும்';

  @override
  String get deliveryRemove => 'வரைவை அகற்றவும்';

  @override
  String get deliveryRemoveFailed =>
      'சாதனத்திலிருந்து அகற்றியதைச் சேமிக்க முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get deliveryUnknownTime =>
      'கவனித்த நேரம் தெரியவில்லை. பதிவேற்றுவதற்கு முன் புதிய அறிக்கையை உருவாக்கவும்.';

  @override
  String get deliveryWaiting =>
      'இணைப்புக்காகக் காத்திருக்கிறது. இந்த அறிக்கை வெளியிடப்பட்டதாக உறுதியாகவில்லை.';

  @override
  String get deliveryUploadFailed =>
      'பதிவேற்றம் தோல்வியடைந்தது. உள்நுழைவு, படம் மற்றும் சேவை அணுகலைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get reportAlreadySaved => 'இந்தச் செயல் ஏற்கனவே பதிவுசெய்யப்பட்டது.';

  @override
  String get reportWaitRecheck =>
      'மீள்சோதனை சேமிக்கப்படவில்லை. கடைசிச் சோதனையிலிருந்து 30 நிமிடங்கள் கழித்து மீண்டும் முயலவும்.';

  @override
  String get reportChangeSaved =>
      'மாற்றம் சேமிக்கப்பட்டது. இணைந்ததும் பகிரப்பட்ட விவரங்கள் புதுப்பிக்கப்படும்.';

  @override
  String get reportConfirmationSaved =>
      'பகிரப்பட்ட அறிக்கையில் உறுதிப்படுத்தல் சேமிக்கப்பட்டது.';

  @override
  String get reportRecheckSaved =>
      'மீள்சோதனை சேமிக்கப்பட்டது. தனித்துவமான உறுதிப்படுத்தல்களும் புள்ளிகளும் மாறவில்லை.';

  @override
  String get reportFlagSaved => 'பகிரப்பட்ட அறிக்கையில் குறி சேமிக்கப்பட்டது.';

  @override
  String get reportFlagHiddenLegacy =>
      'குறி சேமிக்கப்பட்டது. மூன்று தனித்த குறிகளுக்குப் பின் அறிக்கை மறைக்கப்பட்டது.';

  @override
  String get reportResolutionSaved =>
      'பகிரப்பட்ட அறிக்கையில் தீர்வு சேமிக்கப்பட்டது.';

  @override
  String reportShareText(String title, String target) {
    return 'AccessTransit அறிவிப்பு: $target இல் $title. AccessTransit இல் கவனிப்பைப் பார்க்கவும்.';
  }

  @override
  String reportResolvedBy(String name) {
    return 'தீர்வைப் பதிவு செய்தவர்: $name';
  }

  @override
  String reportResolvedAt(String date, String time) {
    return 'தீர்வு பதிவானது: $date, $time';
  }

  @override
  String reportHiddenHelp(int threshold) {
    return '$threshold தனித்த தவறான தகவல் குறிகளுக்குப் பின் அறிக்கை மறைக்கப்பட்டது. நிலை பொய்யானது என்பதை இது நிரூபிப்பதில்லை.';
  }

  @override
  String reportRecheckAge(String age) {
    return 'கடைசிச் சோதனை $age. தற்போதைய நிலை தெரியவில்லை; பழுதுபார்ப்பு பதிவாகவில்லை.';
  }

  @override
  String reportConfirmedRiders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count சக பயணிகள் உறுதிப்படுத்தியுள்ளனர்.',
      one: '1 சக பயணி உறுதிப்படுத்தியுள்ளார்.',
    );
    return '$_temp0';
  }

  @override
  String reportTransitVehicle(String name) {
    return 'போக்குவரத்து வாகனம் • $name';
  }

  @override
  String reportTransitStation(String name) {
    return 'போக்குவரத்து நிறுத்தம் • $name';
  }

  @override
  String reportUniqueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'தனித்துவமான உறுதிப்படுத்தல்கள்: $count பயணிகள்',
      one: 'தனித்துவமான உறுதிப்படுத்தல்கள்: 1 பயணி',
    );
    return '$_temp0';
  }

  @override
  String reportFlagCount(int count, int threshold) {
    return 'தவறான தகவல் குறிகள்: $count / $threshold ($threshold தனித்த குறிகளில் அறிக்கை மறைக்கப்படும்)';
  }

  @override
  String reportOriginally(String age) {
    return 'முதலில் அறிவித்தது: $age';
  }

  @override
  String reportLastRecheck(String age, String name) {
    return 'கடைசி மீள்சோதனை: $age, $name மூலம்';
  }

  @override
  String reportLastConfirmed(String age) {
    return 'கடைசியாக உறுதிப்படுத்தியது: $age';
  }

  @override
  String reportLegacyVoteHelp(int threshold) {
    return 'நீங்கள் கவனித்ததை மட்டும் உறுதிப்படுத்தவும். முன்பு உறுதிப்படுத்தியவர்கள் கடைசிச் சோதனையிலிருந்து 30 நிமிடங்களுக்குப் பின் மீள்சோதிக்கலாம்; தனித்துவமான வாக்குகளும் புள்ளிகளும் அதிகரிக்காது. நிலை மாறியிருந்தால் புதிய அறிக்கை அளிக்கவும். $threshold தனித்த குறிகளில் அறிக்கை மறைக்கப்படும்.';
  }

  @override
  String reportTrueCount(int count) {
    return 'உண்மை ($count)';
  }

  @override
  String reportFalseCount(int count, int threshold) {
    return 'தவறு ($count/$threshold)';
  }

  @override
  String reportFalseRecorded(int count, int threshold) {
    return 'தவறு ($count/$threshold)';
  }

  @override
  String deliveryCooldownAt(String time) {
    return 'அதே பிரச்சினையை மீண்டும் அறிவிக்கக் காத்திருக்கவும். $time (UTC) க்குப் பின் மீண்டும் முயலவும். உங்கள் வரைவு சேமிக்கப்பட்டுள்ளது.';
  }

  @override
  String get formPhotoFailed =>
      'படத்தை இணைக்க முடியவில்லை. அனுமதியைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get formSubmitFailed =>
      'அறிக்கை அனுப்பியது உறுதியாகவில்லை. உள்நுழைவையும் இணைப்பையும் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get formSignIn => 'அறிக்கையை வெளியிடுவதற்கு முன் உள்நுழையவும்.';

  @override
  String get formAccountChanged =>
      'கணக்கு மாறியது. அறிக்கையை மீண்டும் மீளாய்வு செய்யவும்.';

  @override
  String formReviewTarget(String target) {
    return 'இடம் / வாகனம்: $target';
  }

  @override
  String formReviewCondition(String condition) {
    return 'நிலை: $condition';
  }

  @override
  String formReviewCrowding(String level) {
    return 'நெரிசல்: $level';
  }

  @override
  String formReviewNote(String note) {
    return 'குறிப்பு: $note';
  }

  @override
  String formBusRoute(String number) {
    return 'பேருந்து $number';
  }

  @override
  String formVehicleRoute(String vehicle, String number) {
    return '$vehicle (வழித்தடம் $number)';
  }

  @override
  String formBusRamp(String vehicle) {
    return '$vehicle ♿ (சாய்வுப்பாதை)';
  }

  @override
  String get formLowCrowd => 'குறைந்த நெரிசல்';

  @override
  String get formPlentyOfRoomWheelchairBay =>
      'போதுமான இடம்; சக்கர நாற்காலி இடம் காலியாக உள்ளது';

  @override
  String get formModerate => 'நடுத்தரம்';

  @override
  String get formSeatsFullStandingRoomAvailable =>
      'இருக்கைகள் நிரம்பியுள்ளன; நிற்க இடம் உள்ளது';

  @override
  String get formCrowdedPacked => 'அதிக நெரிசல்';

  @override
  String get formWheelchairSpaceOrAisleBlocked =>
      'சக்கர நாற்காலி இடம் அல்லது நடைபாதை தடைப்பட்டுள்ளது';

  @override
  String get formRampBay => 'சாய்வுப்பாதையும் நாற்காலி இடமும்';

  @override
  String get formRampWorking => 'சாய்வுப்பாதை செயல்படுகிறது';

  @override
  String get formDriverAssistedDeployedRamp =>
      'ஓட்டுநர் உதவி செய்து சாய்வுப்பாதையை விரித்தார்';

  @override
  String get formRampBroken => 'சாய்வுப்பாதை பழுதடைந்துள்ளது';

  @override
  String get formMotorJammedOrRampBroken =>
      'மோட்டார் சிக்கியது அல்லது சாய்வுப்பாதை உடைந்துள்ளது';

  @override
  String get formRampDenied => 'சாய்வுப்பாதை உதவி மறுக்கப்பட்டது';

  @override
  String get formDriverDidNotLowerOr =>
      'ஓட்டுநர் சாய்வுப்பாதையை இறக்கவோ விரிக்கவோ இல்லை';

  @override
  String get formBayBlocked => 'சக்கர நாற்காலி இடம் தடைப்பட்டுள்ளது';

  @override
  String get formBlockedByBagsOrStanding =>
      'பைகள் அல்லது நிற்கும் பயணிகளால் தடைப்பட்டுள்ளது';

  @override
  String get formSeats => 'இருக்கைகள்';

  @override
  String get formSeatsFree => 'இருக்கைகள் காலியாக உள்ளன';

  @override
  String get formElderlyDisabledSeatsFree =>
      'முதியோர் / மாற்றுத்திறனாளிகளுக்கான இருக்கைகள் காலியாக உள்ளன';

  @override
  String get formSeatsOccupied => 'இருக்கைகள் நிரம்பியுள்ளன';

  @override
  String get formOthersNotGivingUpSeats =>
      'மற்றவர்கள் இருக்கைகளை விட்டுக்கொடுக்கவில்லை';

  @override
  String get formSeatBroken => 'இருக்கை உடைந்துள்ளது';

  @override
  String get formDamagedOrLooseSeating => 'சேதமான அல்லது தளர்ந்த இருக்கைகள்';

  @override
  String get formSafetyClean => 'பாதுகாப்பும் தூய்மையும்';

  @override
  String get formCleanSafe => 'தூய்மையாகவும் பாதுகாப்பாகவும் உள்ளது';

  @override
  String get formVehicleWellMaintained => 'வாகனம் நன்கு பராமரிக்கப்பட்டுள்ளது';

  @override
  String get formDirtyOdor => 'அழுக்கு / துர்நாற்றம்';

  @override
  String get formSpillOrUnpleasantSmell => 'திரவக் கசிவு அல்லது துர்நாற்றம்';

  @override
  String get formRailBroken => 'கைப்பிடி உடைந்துள்ளது';

  @override
  String get formGrabRailsOrStrapsLoose =>
      'கைப்பிடிகள் அல்லது பட்டைகள் தளர்ந்துள்ளன';

  @override
  String get formRecklessDriving => 'பொறுப்பற்ற ஓட்டுதல்';

  @override
  String get formSuddenJerksUnsafeRide =>
      'திடீர் குலுக்கல்கள்; பாதுகாப்பற்ற பயணம்';

  @override
  String get formElevator => 'மின்தூக்கி';

  @override
  String get formElevatorWorking => 'மின்தூக்கி செயல்படுகிறது';

  @override
  String get formOperatingSmoothlyAccessible =>
      'சீராகச் செயல்படுகிறது; அணுக முடியும்';

  @override
  String get formOutOfService => 'சேவையில் இல்லை';

  @override
  String get formElevatorShutDownOrRepair =>
      'மின்தூக்கி நிறுத்தப்பட்டுள்ளது அல்லது பழுதுபார்க்கப்படுகிறது';

  @override
  String get formDoorButtonFault => 'கதவு / பொத்தான் கோளாறு';

  @override
  String get formDoorsStuckOrButtonsBroken =>
      'கதவுகள் சிக்கியுள்ளன அல்லது பொத்தான்கள் உடைந்துள்ளன';

  @override
  String get formRampPath => 'சாய்வுப்பாதையும் பாதையும்';

  @override
  String get formRampClear => 'சாய்வுப்பாதை தடையின்றி உள்ளது';

  @override
  String get formSmoothWheelchairSlope => 'சீரான சக்கர நாற்காலிச் சாய்வுப்பாதை';

  @override
  String get formPathBlocked => 'பாதை தடைப்பட்டுள்ளது';

  @override
  String get formVendorsOrParkedVehicles =>
      'விற்பனையாளர்கள் அல்லது நிறுத்தப்பட்ட வாகனங்கள்';

  @override
  String get formDamagedSteep => 'சேதமானது / செங்குத்தானது';

  @override
  String get formPavementCrackedOrSteepSlope =>
      'நடைபாதை விரிசல் அல்லது செங்குத்தான சாய்வு';

  @override
  String get formTactileTiles => 'தொட்டுணரும் வழிகாட்டித் தரை';

  @override
  String get formTilesIntact => 'தரை ஓடுகள் சேதமின்றி உள்ளன';

  @override
  String get formGuidedTactileTilesClear =>
      'தொட்டுணரும் வழிகாட்டித் தரை தடையின்றி உள்ளது';

  @override
  String get formTilesBroken => 'தரை ஓடுகள் உடைந்துள்ளன';

  @override
  String get formLooseTilesCausingTripHazard =>
      'தளர்ந்த ஓடுகளால் தடுமாறும் ஆபத்து';

  @override
  String get formUnsafeEdgeGap => 'பாதுகாப்பற்ற விளிம்பு இடைவெளி';

  @override
  String get formExcessiveGapBetweenCurbBus =>
      'நடைபாதை விளிம்புக்கும் பேருந்துக்கும் அதிக இடைவெளி';

  @override
  String get formShelterLight => 'நிழற்குடையும் விளக்கும்';

  @override
  String get formShelterGood => 'நிழற்குடை நல்ல நிலையில் உள்ளது';

  @override
  String get formRainProtectionSeatingIntact =>
      'மழைப் பாதுகாப்பும் இருக்கைகளும் சேதமின்றி உள்ளன';

  @override
  String get formRoofDamaged => 'கூரை சேதமடைந்துள்ளது';

  @override
  String get formDamagedRoofOrBrokenBenches =>
      'சேதமான கூரை அல்லது உடைந்த இருக்கைகள்';

  @override
  String get formDarkUnsafe => 'இருள் / பாதுகாப்பற்றது';

  @override
  String get formPoorNightLightingInWalkway =>
      'நடைபாதையில் இரவு வெளிச்சம் குறைவு';

  @override
  String get formPhotoAttachedSuccessfully => 'படம் இணைக்கப்பட்டது!';

  @override
  String get formAttachEvidencePhoto => 'ஆதாரப் படத்தை இணைக்கவும்';

  @override
  String get formHelpVerifyConditionForCommuters =>
      'மாற்றுத்திறனாளிப் பயணிகள் நிலையைப் புரிந்துகொள்ள உதவவும்';

  @override
  String get formTakePhoto => 'படம் எடுக்கவும்';

  @override
  String get formFromGallery => 'படத்தொகுப்பிலிருந்து தேர்ந்தெடுக்கவும்';

  @override
  String get formSelectTheExactBusOr =>
      'நீங்கள் கவனித்த குறிப்பிட்ட பேருந்து அல்லது நிறுத்தத்தைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get formChooseTheConditionAndCrowding =>
      'நீங்கள் கவனித்த நிலையையும் நெரிசல் அளவையும் தேர்ந்தெடுக்கவும்.';

  @override
  String get formChooseTheConditionYouObserved =>
      'நீங்கள் கவனித்த நிலையைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get formConfirmYourObservation => 'உங்கள் கவனிப்பை உறுதிப்படுத்தவும்';

  @override
  String get formEvidence1PhotoAttached => 'ஆதாரம்: 1 படம் இணைக்கப்பட்டுள்ளது';

  @override
  String get formYourObservationNoteAndAttached =>
      'வெளியிட்ட பின் கவனிப்பு, குறிப்பு மற்றும் படம் பொதுவாகும். முகங்கள், அடையாள விவரங்கள் மற்றும் தனிப்பட்ட தகவல்களைத் தவிர்க்கவும். பகிர அனுமதியுள்ள படங்களை மட்டும் அனுப்பவும்.';

  @override
  String get formPendingDraftsStayOnThis =>
      'வரைவுகள் 7 நாட்கள் வரை சாதனத்தில் இருக்கும்; வெளியேறும்போது அல்லது கணக்கு மாறும்போது அகற்றப்படும். உங்கள் பதிவேற்றங்களில் அவற்றை அகற்றலாம். ஏற்கனவே அனுப்பிய கோரிக்கையைத் திரும்பப்பெறவோ பொது அறிக்கை/படத்தை நீக்கவோ வரைவை அகற்றுவதால் முடியாது.';

  @override
  String get formAndroidDraftsUseEncryptedPrivate =>
      'Android வரைவுகள் மறையாக்கப்பட்ட தனிச் சேமிப்பில் இருக்கும். பிற தளங்களில் வரைவுகள் இந்தச் செயலி அமர்வுக்கு மட்டும்.';

  @override
  String get formEditReport => 'அறிக்கையைத் திருத்தவும்';

  @override
  String get formConfirmAndSubmit => 'உறுதிப்படுத்தி அனுப்பவும்';

  @override
  String get formCommunityReport => 'சமூக அறிக்கை';

  @override
  String get formHelpAccessibleTransitCommutersIn =>
      'உங்கள் கவனிப்புகளைப் பயணிகளுடன் பகிரவும்';

  @override
  String get formSelectBusRoute => 'பேருந்து வழித்தடத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get formWhichRouteAreYouTraveling =>
      'நீங்கள் பயணிக்கும் அல்லது காத்திருக்கும் வழித்தடம் எது?';

  @override
  String get formWhereIsTheIssue => 'பிரச்சினை எங்கே?';

  @override
  String get formChooseWhetherYouAreInside =>
      'பேருந்தினுள்ளா அல்லது நிறுத்தத்திலா என்பதைத் தேர்ந்தெடுக்கவும்';

  @override
  String get formVehicleAccessibilityCondition => 'பேருந்தின் அணுகல் வசதி நிலை';

  @override
  String get formStationAccessibilityCondition =>
      'நிறுத்தத்தின் அணுகல் வசதி நிலை';

  @override
  String get formReportCrowdingLevelAndWheelchair =>
      'பேருந்தில் நெரிசலையும் சக்கர நாற்காலி அணுகலையும் அறிவிக்கவும்';

  @override
  String get formReportElevatorRampAndPlatform =>
      'நிறுத்தத்தின் மின்தூக்கி, சாய்வுப்பாதை மற்றும் மேடை நிலையை அறிவிக்கவும்';

  @override
  String get formEvidencePhotoOptional => 'ஆதாரப் படம் (விருப்பம்)';

  @override
  String get formTakeAPhotoOrUpload =>
      'நிலைக்குரிய படத்தை எடுக்கவும் அல்லது படத்தொகுப்பிலிருந்து தேர்ந்தெடுக்கவும்';

  @override
  String get formAdditionalNoteOptional => 'கூடுதல் குறிப்பு (விருப்பம்)';

  @override
  String get formAddHelpfulDetailsForFellow =>
      'சக்கர நாற்காலி அல்லது முதிய பயணிகளுக்கு உதவும் விவரங்களைச் சேர்க்கவும்';

  @override
  String get formEGRampWasLowered =>
      'எ.கா. சாய்வுப்பாதை இறக்கப்பட்டது; ஓட்டுநருக்கு மற்றவரின் உதவி தேவைப்பட்டது';

  @override
  String get formSubmittingReport => 'அறிக்கை அனுப்பப்படுகிறது…';

  @override
  String get formReviewAndSubmitReport =>
      'அறிக்கையை மீளாய்வு செய்து அனுப்பவும்';

  @override
  String get formSelectARouteOptional =>
      'வழித்தடத்தைத் தேர்ந்தெடுக்கவும் (விருப்பம்)';

  @override
  String get formOnABus => 'பேருந்தினுள்';

  @override
  String get formInsideTheVehicle => 'வாகனத்தினுள்';

  @override
  String get formAtABusStop => 'பேருந்து நிறுத்தத்தில்';

  @override
  String get formStationPlatform => 'நிறுத்தமும் மேடையும்';

  @override
  String get formSelectSpecificBusLicensePlate =>
      'குறிப்பிட்ட பேருந்து / பதிவு எண்ணைத் தேர்ந்தெடுக்கவும்';

  @override
  String get formSelectStopAlongThisRoute =>
      'இந்த வழித்தடத்தின் நிறுத்தத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get formCrowdingLevel => 'நெரிசல் அளவு';

  @override
  String get formChooseTheCrowdingLevelYou =>
      'நீங்கள் கவனித்த நெரிசல் அளவைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get formAccessibilityIssueCategory => 'அணுகல் பிரச்சினை வகை';

  @override
  String get formStationFacilityCategory => 'நிறுத்த வசதி வகை';

  @override
  String get formPhotoUploadsAreCurrentlyUnavailable =>
      'தற்போது படங்களைப் பதிவேற்ற முடியாது. படம் இல்லாமல் அறிக்கையை அனுப்பலாம்.';

  @override
  String get formPhotoAttached => 'படம் இணைக்கப்பட்டுள்ளது';

  @override
  String get formWillBeUploadedWithReport => 'அறிக்கையுடன் பதிவேற்றப்படும்';

  @override
  String get formRemovePhoto => 'படத்தை அகற்றவும்';

  @override
  String get formAddPhoto => 'படத்தைச் சேர்க்கவும்';

  @override
  String get formTapToTakePhotoOr =>
      'படம் எடுக்கவும் அல்லது சாதனத்திலிருந்து தேர்ந்தெடுக்கவும்';

  @override
  String get formNotSelected => 'தேர்ந்தெடுக்கப்படவில்லை';

  @override
  String get formReportSummary => 'அறிக்கைச் சுருக்கம்';

  @override
  String get formLocationVehicle => 'இடம் / வாகனம்';

  @override
  String get formAccessibilityStatus => 'அணுகல் வசதி நிலை';

  @override
  String get formPhotoEvidence => 'பட ஆதாரம்';

  @override
  String get form1PhotoAttached => '1 படம் இணைக்கப்பட்டுள்ளது';

  @override
  String get communityHubTitle => 'சமூக மையம்';

  @override
  String get communitySubtitle => 'சக பயணிகளின் அணுகல் வசதிக் கவனிப்புகள்';

  @override
  String get communityReportAction => 'நிலையை அறிவிக்கவும்';

  @override
  String get communityPastReports => 'தீர்க்கப்பட்ட மற்றும் முந்தைய அறிக்கைகள்';

  @override
  String get communityNoOwnReports => 'இன்னும் அறிக்கைகள் இல்லை';

  @override
  String get communityEmptyTitle => 'தற்போதைய அறிக்கைகள் இல்லை';

  @override
  String get communityOwnEmptyHelp =>
      'சக்கர நாற்காலி அணுகல், நெரிசல் அல்லது மின்தூக்கிகள் பற்றிய உங்கள் அறிக்கைகள் இங்கே காட்டப்படும்.';

  @override
  String get communityEmptyHelp =>
      'இந்தப் பட்டியலில் தற்போதைய அறிக்கைகள் இல்லை. அணுகல் வசதியையோ பாதுகாப்பையோ இது உறுதிப்படுத்துவதில்லை.';

  @override
  String get communitySubmitReport => 'நிலை அறிக்கையை அனுப்பவும்';

  @override
  String get communityUpdatesTab => 'புதுப்பிப்புகள்';

  @override
  String get communityMyReportsTab => 'எனது அறிக்கைகள்';

  @override
  String get communityContributor => 'சமூகப் பங்களிப்பாளர்';

  @override
  String get communityPhoto => 'படம்';

  @override
  String get communityRecheckHelp =>
      'கடைசிச் சோதனையிலிருந்து 30 நிமிடங்களுக்குப் பின் அதே நிலையை மீள்சோதிக்கவும். கூடுதல் வாக்குகளோ புள்ளிகளோ இல்லை. மாறிய நிலைகளைத் தனியாக அறிவிக்கவும்.';

  @override
  String get communityActiveBadge => 'செயலில்';

  @override
  String get communityConfirmedBadge => 'சமூகம் உறுதிப்படுத்தியது';

  @override
  String get communityResolvedBadge => 'தீர்க்கப்பட்டதாகப் பதிவு செய்யப்பட்டது';

  @override
  String get communityPastBadge => 'முந்தையது';

  @override
  String get communityUnavailable =>
      'சமூக அறிக்கைகள் கிடைக்கவில்லை. இணைந்து மீண்டும் முயலவும்.';

  @override
  String get communityRetry => 'அறிக்கைகளை மீண்டும் பெறவும்';

  @override
  String get communityOwnSignIn =>
      'உங்கள் அறிக்கைகளையும் சாதன வரைவுகளையும் காண உள்நுழையவும்.';

  @override
  String get outboxTitle => 'உங்கள் பதிவேற்றங்கள்';

  @override
  String get outboxHelp =>
      'வரைவுகள் 7 நாட்களில் காலாவதியாகும். மீண்டும் முயல அல்லது அகற்ற பதிவேற்றத்தைத் திறக்கவும். வெளியேறும்போது சாதன வரைவுகள் அகற்றப்படும்.';

  @override
  String communityStationTarget(String id) {
    return 'நிறுத்தம் $id';
  }

  @override
  String communityBusTarget(String id) {
    return 'பேருந்து $id';
  }

  @override
  String communityRouteTarget(String number) {
    return 'பேருந்து வழித்தடம் $number';
  }

  @override
  String communityContributionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'தற்போது $count பகிரப்பட்ட அறிக்கைகள் பட்டியலிடப்பட்டுள்ளன. இங்கு வெகுமதிகள் கணக்கிடப்படுவதில்லை.',
      one: 'தற்போது 1 பகிரப்பட்ட அறிக்கை பட்டியலிடப்பட்டுள்ளது. இங்கு வெகுமதிகள் கணக்கிடப்படுவதில்லை.',
    );
    return '$_temp0';
  }

  @override
  String communityChecked(String freshness, String age) {
    return '$freshness · கடைசிச் சோதனை: $age';
  }

  @override
  String communityTrueCount(int count) {
    return 'உண்மை: $count';
  }

  @override
  String communityFalseCount(int count, int threshold) {
    return 'தவறு: $count/$threshold';
  }

  @override
  String get helpIntro => 'AccessTransit பயன்பாடு';

  @override
  String get helpSearchTitle => 'பேருந்தைத் தேடுவது எப்படி?';

  @override
  String get helpSearchBody =>
      'ஏறும் நிறுத்தம், சேருமிடம் மற்றும் அடுத்த 24 மணிநேரத்திற்குள் ஏறும் நேரத்தைத் தேர்ந்தெடுக்கவும். சேமித்த அணுகல் விருப்பங்கள் தேடலில் பயன்படுத்தப்படும். தேடலில் செய்யும் மாற்றங்கள் அந்தத் தேடலுக்கு மட்டுமே பொருந்தும். கணக்கின் இயல்புநிலை விருப்பங்களை அமைப்புகளில் சேமிக்கவும்.';

  @override
  String get helpSaveTitle => 'பயணத்தைச் சேமிப்பது எதற்காக?';

  @override
  String get helpSaveBody =>
      'முடிவைத் திறந்து பேருந்து விவரங்களையும் தேர்ந்தெடுத்த நிறுத்தப் பகுதியையும் காணலாம். சேமிப்பது விருப்பமானது. பின்னர் சேமித்த பயணங்களிலிருந்து விவரங்களைத் திறக்கலாம்; இது இருக்கையை முன்பதிவு செய்யவோ பயணத்தைத் தொடங்கவோ செய்யாது. மீண்டும் திறக்கும்போது புதுப்பித்த நேரங்களையும் ரத்து அறிவிப்புகளையும் பார்க்கவும்.';

  @override
  String get helpLocationTitle => 'எனது இருப்பிடத்தைப் பயன்படுத்துதல்';

  @override
  String get helpLocationBody =>
      'அருகிலுள்ள ஏறும் நிறுத்தங்களைக் கண்டறியக் கேட்கும்போது இருப்பிட அனுமதி வழங்கவும். தேடுவதற்கு முன் நிறுத்தத்தையும் திசையையும் சரிபார்க்கவும். அருகில் இருப்பது படியற்ற நடைபாதையை உறுதி செய்யாது. இருப்பிடம் கிடைக்காவிட்டால் அல்லது அனுமதி மறுக்கப்பட்டால் நிறுத்தத்தை நீங்களே தேர்ந்தெடுக்கவும்.';

  @override
  String get helpLiveTitle => 'கால அட்டவணையும் நேரடி இருப்பிடமும்';

  @override
  String get helpLiveBody =>
      'கால அட்டவணை ஒரு திட்டமே; பேருந்து தொடங்கியதற்கான சான்றல்ல. எதிர்கால அல்லது தொடங்காத சேவைகளுக்கு அட்டவணை காட்டப்படும். நேரடி இருப்பிடத்திற்கு தேர்ந்தெடுத்த சேவை தொடங்கி புதிய GPS தரவு இருக்க வேண்டும். இருப்பிடம் பழையதாகவோ கிடைக்காமலோ இருந்தால் கடைசிப் புதுப்பிப்பைப் பார்க்கவும். மதிப்பீடுகளும் வருகை நேரங்களும் மாறலாம்.';

  @override
  String get helpReportsTitle => 'அறிக்கைகளும் நிலுவைப் பதிவேற்றங்களும்';

  @override
  String get helpReportsBody =>
      'சரியான பேருந்து அல்லது நிறுத்தத்தையும் நீங்கள் கண்ட நிலையையும் தெரிவிக்கவும். சாதன வரைவு தனிப்பட்டது; அது வெளியிடப்பட்ட அறிக்கையல்ல. எனது அறிக்கைகளில் உங்கள் பதிவேற்றங்களைத் திறந்து மீண்டும் முயலலாம் அல்லது அகற்றலாம். வரைவுகள் 7 நாட்களில் காலாவதியாகி வெளியேறும்போது அகற்றப்படும். பொதுக் குறிப்புகளிலும் படங்களிலும் தனிப்பட்ட தகவல்களைச் சேர்க்க வேண்டாம்.';

  @override
  String get helpVotesTitle => 'வாக்குகளும் சமூக மறுப்புகளும்';

  @override
  String get helpVotesBody =>
      'அறிக்கையின் ஆசிரியர் தனது அறிக்கைக்கு True அல்லது False வாக்களிக்க முடியாது. உங்கள் கவனிப்பின் அடிப்படையில் மட்டும் வாக்களித்து False என்பதற்குக் காரணம் தரவும். v2 கொள்கையில் தகுதியுள்ள பிற பயனர்கள் ஐவரின் False வாக்குகள் அறிக்கையை மறைத்து அதற்குரிய புள்ளிக் கழிப்பையும் தவறுப் பதிவையும் சேர்க்கும். இது சமூக மறுப்பு; அறிக்கை பொய் என்பதற்கான சான்றல்ல. ஆசிரியர் அறிக்கை மீளாய்வு மற்றும் முறையீட்டுத் திரைகளைப் பயன்படுத்தலாம்.';

  @override
  String get helpAssistanceTitle => 'பேருந்தில் ஏற உதவி';

  @override
  String get helpAssistanceBody =>
      'பேருந்து விவரங்களில் உதவி கேட்பது விருப்பமானது. பேருந்து, சேவை மற்றும் ஏறும் நிறுத்தத்தைச் சரிபார்க்கவும். சமர்ப்பிக்கப்பட்டது என்பது கோரிக்கை பதிவானதையும் ஏற்கப்பட்டது என்பது பொறுப்பான ஓட்டுநர் ஏற்றதையும் குறிக்கும். சேமித்த பயணமோ அனுப்பிய கோரிக்கையோ உதவியை உறுதி செய்யாது. மறுப்பு, ரத்து அல்லது காலாவதி உட்பட சமீபத்திய கோரிக்கை நிலையைக் காணவும்.';

  @override
  String get helpAccessTitle => 'கணக்கு அணுகலும் மீளாய்வும்';

  @override
  String get helpAccessBody =>
      'அணுகல் கட்டுப்படுத்தப்பட்டால் காட்டப்படும் காரணத்தையும் முடிவு நேரத்தையும் படித்து கிடைக்கும் முறையீட்டுச் செயலைப் பயன்படுத்தவும். முறையீடு தானாகக் கட்டுப்பாட்டை நீக்காது. நிரந்தரத் தடைக்கு நிர்வாகி மீளாய்வு தேவை. சுயமாகக் கணக்கை நீக்குவது சுயவிவரத்தில் இல்லை; நிர்வாகி மீளாய்வு செய்து நீக்குவது தனிச் செயல்முறை.';

  @override
  String get rewardsTitle => 'புள்ளிகளும் பங்களிப்புகளும்';

  @override
  String get rewardsMine => 'எனது பங்களிப்புகள்';

  @override
  String get rewardsSettingsSoon => 'அமைப்புகள் பின்னர் கிடைக்கும்.';

  @override
  String get rewardsReports => 'சமர்ப்பித்த அறிக்கைகள்';

  @override
  String get rewardsConfirmations => 'பதிவான உறுதிப்படுத்தல்கள்';

  @override
  String get rewardsViewCard => 'உறுப்பினர் அட்டையைப் பார்க்கவும்';

  @override
  String get rewardsTotal => 'மொத்தப் புள்ளிகள்';

  @override
  String get rewardsGold => 'தங்கப் பங்களிப்பாளர்';

  @override
  String get rewardsSilver => 'வெள்ளிப் பங்களிப்பாளர்';

  @override
  String get rewardsBronze => 'வெண்கலப் பங்களிப்பாளர்';

  @override
  String get memberGold => 'தங்க உறுப்பினர்';

  @override
  String get memberSilver => 'வெள்ளி உறுப்பினர்';

  @override
  String get memberBronze => 'வெண்கல உறுப்பினர்';

  @override
  String get memberBack => 'புள்ளிகளுக்குத் திரும்பவும்';

  @override
  String get memberTitle => 'மின்னணு உறுப்பினர் அட்டை';

  @override
  String get memberPointsLabel => 'பங்களிப்புப் புள்ளிகள்';

  @override
  String get memberNoCash => 'புள்ளிகளுக்குப் பண அல்லது வவுச்சர் மதிப்பு இல்லை';

  @override
  String get memberNoRedemption => 'புள்ளிகளைப் பயன்படுத்தும் வசதி இல்லை';

  @override
  String get memberAvailability => 'வெகுமதி கிடைக்கும் நிலை';

  @override
  String get memberNoVouchers =>
      'கூட்டாளர் தள்ளுபடிகளும் வவுச்சர்களும் கிடைக்கவில்லை.';

  @override
  String get memberBenefits => 'உறுப்பினர் நன்மைகள்';

  @override
  String get memberNoPriority =>
      'உறுப்பினர் நிலை முன்னுரிமை உதவியையோ உறுதியான அணுகலையோ வழங்காது.';

  @override
  String get memberRecognition => 'சமூக அங்கீகாரம்';

  @override
  String get memberLedgerNotice =>
      'பங்களிப்புப் புள்ளிகள் பதிவான புள்ளிக் கொள்கையைப் பின்பற்றுகின்றன. அவை அணுகல் வசதியை உறுதி செய்யாது.';

  @override
  String get rewardsLegacyNotice =>
      'பழைய கொள்கை: நிர்வாகி மீளாய்வுக்குப் பின் புள்ளிகள் புதுப்பிக்க நேரமாகலாம். வெளியிட்ட அறிக்கைக்கு 10 புள்ளிகள்; தனித்த உறுதிப்படுத்தலுக்கு 5 புள்ளிகள். நீக்கிய வாக்குகளும் மறைத்த அல்லது நீக்கிய அறிக்கைகளும் புள்ளிகளைத் திரும்பப் பெறும். புள்ளிகள் அணுகலை உறுதி செய்யாது; பண மதிப்பும் இல்லை.';

  @override
  String rewardsLevel(String level) {
    return 'நிலை: $level';
  }

  @override
  String memberPointCount(int count) {
    return '$count புள்ளிகள்';
  }

  @override
  String memberIdentity(String id) {
    return 'அடையாளம்: $id';
  }

  @override
  String get assistFormUnknown =>
      'உதவிக்கான பேருந்து அல்லது நிறுத்தம் தெரியவில்லை. முதலில் சரியான நிறுத்தமுள்ள பயணத்தைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get assistFormSelect =>
      'குறைந்தது ஓர் உதவி விருப்பத்தைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get assistFormTarget =>
      'உதவி கேட்கும் முன் உங்கள் பயணத்திலிருந்து சரியான பேருந்தையும் நிறுத்தத்தையும் தேர்ந்தெடுக்கவும்.';

  @override
  String get assistFormWrongStop =>
      'தேர்ந்தெடுத்த பேருந்தில் இந்த நிறுத்தத்தை உறுதி செய்ய முடியவில்லை. பயணத்திற்குத் திரும்பிச் சரியான இலக்கைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get assistFormConfirm =>
      'உதவிக் கோரிக்கையின் இலக்கை உறுதிப்படுத்தவும்';

  @override
  String get assistFormEdit => 'கோரிக்கையைத் திருத்தவும்';

  @override
  String get assistFormSendConfirm => 'உறுதிப்படுத்தி அனுப்பவும்';

  @override
  String get assistFormSignIn =>
      'உதவிக் கோரிக்கையை அனுப்பும் முன் உள்நுழையவும்.';

  @override
  String get assistFormPrepareError =>
      'கோரிக்கையைத் தயாரிக்க முடியவில்லை. உள்நுழைவையும் சாதனச் சேமிப்பகத்தையும் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get assistFormTitle => 'உதவி கோரவும்';

  @override
  String get assistFormRamp => 'சாய்வுப் பலகையை அமைக்கவும்';

  @override
  String get assistFormTime => 'கூடுதல் நேரம்';

  @override
  String get assistFormBoarding => 'ஏறுவதற்கு உதவி';

  @override
  String get assistFormAlighting => 'இறங்குவதற்கு உதவி';

  @override
  String get assistFormSend => 'கோரிக்கையை அனுப்பவும்';

  @override
  String get assistFormAckHelp =>
      'ஓட்டுநர் உங்கள் கோரிக்கையை ஏற்ற பிறகே உதவி உறுதியாகும்.';

  @override
  String get assistFormEtaUnknown => 'வருகை மதிப்பீடு தெரியவில்லை';

  @override
  String get assistFormMinutes => 'நிமிடம் (மதிப்பீடு)';

  @override
  String get assistFormAccountChanged =>
      'மீளாய்வின்போது கணக்கு மாறியது. அனுப்புவதற்கு முன் கோரிக்கையை மீண்டும் சரிபார்க்கவும்.';

  @override
  String assistFormBoardAt(String stop) {
    return 'ஏறும் நிறுத்தம்: $stop';
  }

  @override
  String assistFormAlightAt(String stop) {
    return 'இறங்கும் நிறுத்தம்: $stop';
  }

  @override
  String assistFormBusRoute(String bus, String route) {
    return '$bus (வழித்தடம் $route)';
  }

  @override
  String assistFormArrival(String bus, int minutes) {
    return '$bus - $minutes நிமிடங்களில் வருமென மதிப்பீடு';
  }

  @override
  String get assistReceiptTitle => 'உதவிக் கோரிக்கை';

  @override
  String get assistReceiptOwner =>
      'இந்தக் கோரிக்கையின் நிலையைக் காண அதை உருவாக்கிய கணக்கில் உள்நுழையவும்.';

  @override
  String get assistReceiptSent => 'பகிரப்பட்ட சேவைக்கு அனுப்பப்பட்டது';

  @override
  String get assistReceiptUnknown => 'கோரிக்கையின் நிலை தெரியவில்லை';

  @override
  String get assistReceiptPendingHint =>
      'கோரிக்கையைச் சேமிப்பது ஓட்டுநர் அதை ஏற்றதைக் குறிக்காது.';

  @override
  String get assistReceiptAcceptedHint =>
      'ஓட்டுநர் கோரிக்கையை ஏற்றுள்ளார். உதவி முடிந்ததாக இன்னும் குறிக்கப்படவில்லை.';

  @override
  String get assistReceiptDelivery => 'கோரிக்கையை அனுப்பும் நிலை';

  @override
  String get assistReceiptOwn => 'உங்கள் உதவிக் கோரிக்கை';

  @override
  String get assistReceiptSupport => 'கோரிய உதவி';

  @override
  String get assistReceiptUnspecified => 'குறிப்பிடப்படவில்லை';

  @override
  String get assistReceiptDriver => 'ஓட்டுநரின் பதில்';

  @override
  String get assistReceiptUnconfirmed =>
      'ஓட்டுநரின் ஏற்பு உறுதிப்படுத்தப்படவில்லை.';

  @override
  String get assistReceiptStale =>
      'நேரடி நிலைப் புதுப்பிப்புகள் கிடைக்கவில்லை. காட்டப்படுவது கடைசியாகப் பெற்ற ஓட்டுநர் நிலையாகும்.';

  @override
  String get assistReceiptSending => 'அனுப்பப்படுகிறதா?';

  @override
  String get assistReceiptRetry => 'மீண்டும் அனுப்பவும்';

  @override
  String get assistReceiptCancelling => 'ரத்து செய்யப்படுகிறதா?';

  @override
  String get assistReceiptCancel => 'கோரிக்கையை ரத்து செய்யவும்';

  @override
  String get assistReceiptRetryError =>
      'மீண்டும் அனுப்புவதை இந்தச் சாதனத்தில் சேமிக்க முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get assistReceiptCancelError =>
      'ரத்து செய்தது உறுதியாகவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get assistReceiptPendingUpload => 'பதிவேற்றம் நிலுவையில் உள்ளது';

  @override
  String get assistReceiptDeliverySent => 'அனுப்பப்பட்டது';

  @override
  String get assistReceiptFailed => 'தோல்வி';

  @override
  String get assistReceiptExpired => 'மீண்டும் முயலும் காலம் முடிந்தது';

  @override
  String get assistReceiptOld =>
      'கோரிக்கை பழையதால் தானியங்கி மறுமுயற்சிகள் நிறுத்தப்பட்டன. ஓட்டுநர் நிலையைக் காணவும்; அனுப்பியது இன்னும் உறுதியாகாமல் இருக்கலாம்.';

  @override
  String get assistReceiptDeliveryError =>
      'அனுப்பியது உறுதியாகவில்லை. இணைந்ததும் மீண்டும் முயன்று ஓட்டுநர் நிலையையும் பார்க்கவும்.';

  @override
  String get assistReceiptSendError =>
      'கோரிக்கையை அனுப்ப முடியவில்லை. உள்நுழைவையும் இலக்கையும் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get assistReceiptRestoreError =>
      'சேமித்த சில உதவிக் கோரிக்கைகளை மீட்டெடுக்க முடியவில்லை. பகிரப்பட்ட சேவையின் கோரிக்கை வரலாற்றைப் பார்க்கவும்.';

  @override
  String get assistReceiptSaveError =>
      'சமீபத்திய கோரிக்கை நிலையை இந்தச் சாதனத்தில் சேமிக்க முடியவில்லை. பகிரப்பட்ட கோரிக்கை வரலாற்றைப் பார்க்கவும்.';

  @override
  String get assistReceiptHistory => 'உங்கள் உதவிக் கோரிக்கைகள்';

  @override
  String get assistReceiptHistoryStale =>
      'பகிரப்பட்ட கோரிக்கை புதுப்பிப்புகள் கிடைக்கவில்லை. சேமித்த பதிவுகள் பழையதாக இருக்கலாம்.';

  @override
  String get assistReceiptError =>
      'கோரிக்கையின் நிலை கிடைக்கவில்லை. இணைப்பையும் கணக்கையும் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String assistReceiptRoute(String route) {
    return 'வழித்தடம் $route';
  }

  @override
  String assistReceiptSummary(String route, String stop) {
    return 'வழித்தடம் $route · $stop';
  }

  @override
  String get sharedCatalogueDemo =>
      'செயல்விளக்கம்: மாதிரிப் போக்குவரத்துத் தரவு. பகிரப்பட்ட அறிக்கைகள், உதவி மற்றும் பயணங்கள் முடக்கப்பட்டுள்ளன.';

  @override
  String get sharedCatalogueSaved =>
      'சேமித்த போக்குவரத்துத் தரவு. புதுப்பிப்புகளைச் சரிபார்க்கவும்; கால அட்டவணைகளும் சேவை கிடைப்பும் மாறியிருக்கலாம்.';

  @override
  String get sharedCatalogueUnavailable =>
      'போக்குவரத்துத் தரவு கிடைக்கவில்லை. இணைந்து மீண்டும் முயலவும்; மாற்றாக மாதிரிச் சேவைகள் காட்டப்படாது.';

  @override
  String get sharedCatalogueEmpty =>
      'இந்தப் பட்டியலுக்குப் பகிரப்பட்ட போக்குவரத்துத் தரவு இல்லை. பின்னர் மீண்டும் முயலவும்.';

  @override
  String get sharedRefresh => 'புதுப்பிக்கவும்';

  @override
  String get sharedRefreshing => 'புதுப்பிக்கிறது…';

  @override
  String get sharedSavingStatus => 'நிலையைச் சேமிக்கிறது…';

  @override
  String get sharedOperatorStatusError =>
      'நிலை மாற்றம் உறுதியாகவில்லை. இணைப்பு, ஓட்டுநர் ஒப்புதல் மற்றும் பேருந்து ஒதுக்கீட்டைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get sharedAdminAccess => 'நிர்வாகி அணுகல்';

  @override
  String get sharedAdminChecking => 'நிர்வாகி அணுகலைச் சரிபார்க்கிறது…';

  @override
  String get sharedAdminRequired =>
      'நிர்வாகி அங்கீகாரமும் இணைய இணைப்பும் தேவை. சுயவிவரப் பங்கு மட்டும் அணுகலை வழங்காது.';

  @override
  String get sharedCheckAgain => 'மீண்டும் சரிபார்க்கவும்';

  @override
  String get sharedSignIn => 'உள்நுழையவும்';

  @override
  String get sharedSavedJourney => 'சேமித்த பயணம்';

  @override
  String get sharedJourneyUpdatesError =>
      'சேமித்த பயணப் புதுப்பிப்புகள் கிடைக்கவில்லை. இணைப்பைச் சரிபார்த்து முகப்பை மீண்டும் திறக்கவும்.';

  @override
  String get sharedJourneyChangeError =>
      'பயண நிலை மாற்றம் உறுதியாகவில்லை. இணைந்ததும் மீண்டும் முயலவும்.';

  @override
  String get sharedResume => 'பயணத்தை மீண்டும் திறக்கவும்';

  @override
  String get sharedComplete => 'முடிந்ததாகக் குறிக்கவும்';

  @override
  String get sharedCancelJourney => 'சேமித்த பயணத்தை ரத்து செய்யவும்';

  @override
  String get sharedSaveDisclosure =>
      'சேமிப்பது இந்தத் தேர்வை வைத்திருக்கும். அது இருக்கையை முன்பதிவு செய்யவோ பயணத்தைத் தொடங்கவோ செய்யாது.';

  @override
  String get sharedSaveStatusError =>
      'சேமிப்பு நிலை கிடைக்கவில்லை. சேமித்ததை உறுதிப்படுத்த மீண்டும் முயலவும்.';

  @override
  String get sharedSaveError =>
      'சேமிப்பு மாற்றம் உறுதியாகவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get sharedSaveOwner =>
      'இந்தப் பயணத்தைச் சேமிக்கும் கணக்கில் உள்நுழையவும்.';

  @override
  String get sharedSaveMismatch => 'சேமித்த பயண உறுதிப்படுத்தல் பொருந்தவில்லை.';

  @override
  String get sharedSaveSignIn => 'இந்தப் பயணத்தைச் சேமிக்க உள்நுழையவும்.';

  @override
  String get sharedSaving => 'சேமிக்கிறது…';

  @override
  String get sharedStopAlert => 'நிறுத்த அறிவிப்பு கிடைக்கவில்லை';

  @override
  String get sharedStopAlertHelp =>
      'தானியங்கி நிறுத்த எச்சரிக்கைகளும் பின்னணி அறிவிப்புகளும் கிடைக்கவில்லை. பயண முன்னேற்றத்தை நீங்களே கவனிக்கவும்; உங்கள் நிறுத்தத்திற்கு முன் செயலி அறிவிக்காது.';

  @override
  String get sharedSplashTagline =>
      'அனைவரையும் உள்ளடக்கும் பயணத்திற்கான உங்கள் பயணம் இங்கே தொடங்குகிறது.';

  @override
  String get sharedLoading => 'ஏற்றுகிறது.';

  @override
  String get sharedStopsOrder => 'பயண வரிசையில் நிறுத்தங்கள்';

  @override
  String get sharedDriverReviewHelp =>
      'ஓட்டுநர் பதிவு என்பது அணுகலுக்கான விண்ணப்பம். ஒப்புதலுக்கு முன் அடையாளத்தையும் இயக்க அனுமதியையும் மதிப்பாய்வு செய்யவும். ஒப்புதல் சாதனங்களைச் சரிபார்ப்பதோ சேவையை உறுதிசெய்வதோ அல்ல.';

  @override
  String get sharedAddStation => 'புதிய நிறுத்தத்தைச் சேர்க்கவும்';

  @override
  String get sharedStationName => 'நிறுத்தத்தின் பெயர்';

  @override
  String get sharedStationExample => 'எ.கா. பம்பலப்பிட்டிச் சந்தி';

  @override
  String get sharedStationId => 'நிறுத்த அடையாளம் (எ.கா. bambalapitiya_junc)';

  @override
  String get sharedTargetRoute => 'தொடர்புடைய பேருந்து வழித்தடம்';

  @override
  String get sharedInsertIndex => 'சேர்க்கும் இடத்தின் எண் (0 முதல்)';

  @override
  String get sharedInsertHint => '1 (இரண்டாவது நிறுத்தமாகச் சேர்க்கவும்)';

  @override
  String get sharedRequired => 'தேவை';

  @override
  String get sharedRamp => 'சாய்வுப்பாதை';

  @override
  String get sharedElevator => 'மின்தூக்கி';

  @override
  String get sharedCancel => 'ரத்து செய்யவும்';

  @override
  String get sharedAddStationAction => 'நிறுத்தத்தைச் சேர்க்கவும்';

  @override
  String get sharedStationError =>
      'நிறுத்தத்தைச் சேர்க்க முடியவில்லை. அணுகலையும் இணைப்பையும் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get sharedLiveAccessibility => 'அணுகல் வசதி நிலவரம்';

  @override
  String get sharedEquipmentHelp =>
      'சாதனச் சோதனைகள் நேரடி GPS இலிருந்து தனியானவை. செயல்படும் அறிக்கை முழுப் பயணத்தையும் உறுதிசெய்யாது.';

  @override
  String get sharedConditionsUnavailable =>
      'நிலைப் புதுப்பிப்புகள் கிடைக்கவில்லை. செயல்பாட்டு நிலை தெரியவில்லை; முந்தைய எச்சரிக்கைகள் தொடர்கின்றன.';

  @override
  String get sharedRampWarning =>
      'வாகனச் சாய்வுப்பாதைத் தரவு சிக்கலைக் காட்டுகிறது. சாதனச் சோதனை நேரம் தெரியவில்லை; ஏறும் முன் சரிபார்க்கவும்.';

  @override
  String get sharedCommunityObservations => 'சமூகக் கவனிப்புகள்';

  @override
  String get sharedRampUnknown =>
      'தெரியவில்லை — வாகனச் சாய்வுப்பாதை எச்சரிக்கையைச் சரிபார்க்க வேண்டும்';

  @override
  String get sharedDriverAssistance => 'ஓட்டுநர் உதவி';

  @override
  String get sharedPositiveAssistance => 'உதவி கிடைத்ததாகக் கவனிப்பு';

  @override
  String get sharedOperatorCheck => 'ஓட்டுநரின் வாகனச் சோதனை';

  @override
  String get sharedHideObservations => 'கவனிப்பு விவரங்களை மறைக்கவும்';

  @override
  String get sharedViewObservations => 'கவனிப்பு விவரங்களைக் காண்க';

  @override
  String sharedVehicle(String vehicle) {
    return 'வாகனம்: $vehicle';
  }

  @override
  String sharedTimetable(String time) {
    return 'கால அட்டவணை: $time';
  }

  @override
  String sharedStationAdded(String name, String bus, String index) {
    return '\"$name\" நிறுத்தம் $bus இல் $index இடத்தில் சேர்க்கப்பட்டது.';
  }

  @override
  String sharedBusOption(String route, String id) {
    return 'பேருந்து $route ($id)';
  }

  @override
  String sharedBoardingElevator(String stop) {
    return 'ஏறும் நிறுத்த மின்தூக்கி — $stop';
  }

  @override
  String sharedDestinationElevator(String stop) {
    return 'இறங்கும் நிறுத்த மின்தூக்கி — $stop';
  }

  @override
  String get legacyUi0 => 'செயல்படுவதாக அறிவிக்கப்பட்டது';

  @override
  String get legacyUi1 => 'தடை அறிவிக்கப்பட்டது';

  @override
  String get legacyUi2 => 'பயணத்தைச் சேமித்து மீண்டும் திறக்க உள்நுழையவும்.';

  @override
  String get legacyUi3 =>
      'பயண உரிமை அல்லது நிலை மாறியது. சேமித்த பயணங்களை மீண்டும் திறக்கவும்.';

  @override
  String get legacyUi4 =>
      'பயணம் சேமிக்கப்பட்டது உறுதியாகவில்லை. இணைப்பையும் உள்நுழைவையும் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get legacyUi5 => 'வாகனம் குறிப்பிடப்படவில்லை';

  @override
  String get legacyUi6 => 'பின்செல்';

  @override
  String get legacyUi7 => 'பயணத்தை உறுதிசெய்யவும்';

  @override
  String get legacyUi8 => 'பயண அட்டவணை';

  @override
  String get legacyUi9 => 'தேர்ந்தெடுத்த தேதி';

  @override
  String get legacyUi10 => 'தேர்ந்தெடுத்த நேரம்';

  @override
  String get legacyUi11 => 'தேர்ந்தெடுத்த தேதியில் கிடைக்கும் முதல் சேவை';

  @override
  String get legacyUi12 => 'அட்டவணைப் புறப்பாடு';

  @override
  String get legacyUi13 => 'கணிக்கப்பட்ட வருகை';

  @override
  String get legacyUi14 =>
      'சில அட்டவணைக் கால இடைவெளிகள் இல்லை. நேரங்களில் மாதிரிக் கணிப்புகள் உள்ளன; இயக்குநரிடம் உறுதிசெய்யவும்.';

  @override
  String get legacyUi15 => 'கணிக்கப்பட்ட கட்டணம்';

  @override
  String get legacyUi16 =>
      'முன்மாதிரிக் கணிப்பு. உண்மைக் கட்டணத்தை இயக்குநரிடம் உறுதிசெய்யவும்.';

  @override
  String get legacyUi17 => 'கட்டண விவரங்கள்';

  @override
  String get legacyUi18 => 'பயணத் தேவைகள்';

  @override
  String get legacyUi19 =>
      'பயணத்தைச் சேமிப்பது இருக்கையை முன்பதிவு செய்யாது; பேருந்து இயங்குவதை உறுதிசெய்யாது. தற்போதைய நிலை ஆதாரங்களைப் பார்க்கவும்.';

  @override
  String get legacyUi20 => 'பயணத்தைச் சேமிக்கிறது…';

  @override
  String get legacyUi21 => 'உறுதிசெய்து பயணத்தைச் சேமிக்கவும்';

  @override
  String get legacyUi22 =>
      'சேவை கிடைக்கவில்லை. முதலில் பகிரப்பட்ட சேவையைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get legacyUi23 =>
      'இந்தச் சேவை கிடைக்கவில்லை. தேடலுக்குத் திரும்பவும்.';

  @override
  String get legacyUi24 => 'புறப்பாடு மற்றும் வழித்தட விவரங்கள்';

  @override
  String get legacyUi25 =>
      'சேமித்த இடம் — நேரடிப் புதுப்பிப்புகள் இல்லை. இது தற்போதைய பேருந்து இயக்கம் அல்ல.';

  @override
  String get legacyUi26 => 'கால அட்டவணை';

  @override
  String get legacyUi27 => 'அட்டவணைப்படி';

  @override
  String get legacyUi28 => 'எதிர்பார்க்கும் வருகை';

  @override
  String get legacyUi29 => 'ஏறும் உதவியைக் கோரவும்';

  @override
  String get legacyUi30 => 'வழித்தட நிறுத்த அட்டவணையும் நேரடி முன்னேற்றமும்';

  @override
  String get legacyUi31 => 'நீங்கள் ஏறும் நிறுத்தம்';

  @override
  String get legacyUi32 => 'பேருந்து இப்போது இங்கே உள்ளது';

  @override
  String get legacyUi33 =>
      'தேர்ந்தெடுத்த பகுதிக்கான கணிப்பு; கட்டண முறைகள் உறுதிசெய்யப்படவில்லை.';

  @override
  String get legacyUi34 => 'தெரியவில்லை — நிலை ஆதாரம் இல்லை.';

  @override
  String get legacyUi35 => 'வாகன அணுகல் வசதிகள்';

  @override
  String get legacyUi36 => 'அணுகல் வசதி எச்சரிக்கை';

  @override
  String get legacyUi37 => 'அணுகல் இல்லை என்ற அறிவிப்பு';

  @override
  String get legacyUi38 => 'நிலை தெரியவில்லை';

  @override
  String get legacyUi39 => 'பாதுகாப்பு மற்றும் பயண நிலை';

  @override
  String get legacyUi40 => 'பேருந்துக் கூட்ட அளவு';

  @override
  String get legacyUi41 => 'சமூகப் பாதுகாப்பு அறிக்கைகள்';

  @override
  String get legacyUi42 => 'பயணத்தை மதிப்பாய்வு செய்து உறுதிசெய்யவும்';

  @override
  String get legacyUi43 => 'பயணத் திட்டத்தில் சேமிக்கவும்';

  @override
  String get legacyUi44 => 'அணுகல் வசதி நிலையை அறிவிக்கவும்';

  @override
  String get legacyUi45 => 'பயணத்தை ஏற்ற முடியவில்லை';

  @override
  String get legacyUi46 =>
      'சேவையகத்திலிருந்து நேரடிப் பயண விவரங்களை ஏற்றுகிறது';

  @override
  String get legacyUi47 => 'உங்கள் பயணத்தை ஏற்றுகிறது…';

  @override
  String get legacyUi48 => 'பேருந்து இன்னும் ஒதுக்கப்படவில்லை.';

  @override
  String get legacyUi49 =>
      'சேமித்த பயணம் இருக்கையை ஒதுக்கவோ பேருந்து ஒதுக்கீட்டை உறுதிசெய்யவோ செய்யாது. தேர்ந்தெடுத்த சேவை நிலையைப் பார்க்கவும்.';

  @override
  String get legacyUi50 => 'முகப்புத் திரைக்குத் திரும்பவும்';

  @override
  String get legacyUi51 => 'நேரடி வழிகாட்டலை மூடவும்';

  @override
  String get legacyUi52 => 'நேரடி வழிகாட்டல்';

  @override
  String get legacyUi53 => 'வழித்தட முடிவுகளுக்குத் திரும்பவும்';

  @override
  String get legacyUi54 => 'நேரடிப் பயண முன்னேற்றம்';

  @override
  String get legacyUi55 => 'நேரடி';

  @override
  String get legacyUi56 => 'அட்டவணை';

  @override
  String get legacyUi57 => 'நேரடி நிறுத்த முன்னேற்றமும் வருகைக் கணிப்பும்';

  @override
  String get legacyUi58 => 'நேரடி நிறுத்தங்கள்';

  @override
  String get legacyUi59 => 'உங்கள் நிறுத்தம்';

  @override
  String get legacyUi60 => 'பேருந்து தற்போது இங்கே உள்ளது';

  @override
  String get legacyUi61 => 'கடந்தது';

  @override
  String get legacyUi62 =>
      'நேரடி GPS புதுப்பிப்புகள் கிடைக்கவில்லை. சாதனக் கவனிப்புகள் கீழே தனியாகக் காட்டப்படுகின்றன.';

  @override
  String get legacyUi63 => '● நடைபெறுகிறது';

  @override
  String get legacyUi64 => '● அட்டவணைப்படி';

  @override
  String get legacyUi65 =>
      'கண்காணிப்பு வாகனத்தின் தற்போதைய இடத்தைக் காட்டுகிறது; உங்கள் அட்டவணைப் பயணத்தை உறுதிசெய்யாது.';

  @override
  String get legacyUi66 => 'விரிவான வாகனத் தரவு';

  @override
  String get legacyUi67 => 'வேகம், GPS சமிக்ஞைகள் மற்றும் மூலப் பயணத் தரவு';

  @override
  String get legacyUi68 => 'நெருங்குகிறது';

  @override
  String get legacyUi69 => 'நீங்கள் இங்கே ஏறுகிறீர்கள்';

  @override
  String get legacyUi70 => 'கால அட்டவணை';

  @override
  String get legacyUi71 => 'வரைபடத்தைச் சுருக்கவும்';

  @override
  String get legacyUi72 => 'வரைபடத்தை விரிக்கவும்';

  @override
  String get legacyUi73 => 'முழுப் பயணத்தையும் காட்டவும்';

  @override
  String get legacyUi74 => 'பேருந்தைக் காட்டவும்';

  @override
  String get legacyUi75 => 'என் நிறுத்தத்தைக் காட்டவும்';

  @override
  String get legacyUi76 => 'பெரிதாக்கவும்';

  @override
  String get legacyUi77 => 'சிறிதாக்கவும்';

  @override
  String get legacyUi78 => 'GPS சமிக்ஞை இல்லை';

  @override
  String get legacyUi79 => 'சமிக்ஞை இழந்தது';

  @override
  String get legacyUi80 => 'வழியில் செல்கிறது';

  @override
  String get legacyUi81 => 'நிறுத்தப்பட்டுள்ளது';

  @override
  String get legacyUi82 => 'பயணம் முடிந்தது';

  @override
  String get legacyUi83 => 'இணைப்பு இல்லை';

  @override
  String get legacyUi84 => 'சேமித்த இடம் — புதுப்பிப்புகள் இல்லை';

  @override
  String get legacyUi85 => 'நிலை: நேரடி GPS புதுப்பிப்புகள் பெறப்படுகின்றன';

  @override
  String get legacyUi86 => 'நிலை: இடம் கிடைக்கவில்லை';

  @override
  String get legacyUi87 => 'கிடைக்கவில்லை';

  @override
  String get legacyUi88 => 'தற்போதைய நிலை';

  @override
  String get legacyUi89 => 'கடைசிப் புதுப்பிப்பு';

  @override
  String get legacyUi90 => 'அடுத்த நிறுத்தம்';

  @override
  String get legacyUi91 => 'உங்கள் சேருமிடம்';

  @override
  String get legacyUi92 => 'அடுத்து: ';

  @override
  String get legacyUi93 => 'இறுதியாக: ';

  @override
  String get legacyUi94 =>
      'ஏறுவதற்கு அல்லது இறங்குவதற்கு ஓட்டுநர் உதவியைக் கோரவும்';

  @override
  String get legacyUi95 => 'நிறுத்த உதவியைக் கோரவும்';

  @override
  String get legacyUi96 =>
      'அவசர அழைப்பு கிடைக்கவில்லை. உதவியை அழைக்க உங்கள் தொலைபேசியைப் பயன்படுத்தவும்.';

  @override
  String get legacyUi97 => 'அவசர உதவி';

  @override
  String get legacyUi98 => 'அணுகல் சிக்கலை அல்லது வாகன நிலையைக் கூறவும்';

  @override
  String get legacyUi99 =>
      'இந்தச் செயலியில் அவசர அழைப்பு இல்லை. உதவியை அழைக்க உங்கள் தொலைபேசியைப் பயன்படுத்தவும்.';

  @override
  String get legacyUi100 => 'ஒவ்வொரு நிறுத்தத்திற்குமான நேரடிக் காலவரிசை';

  @override
  String get legacyUi101 => 'நேரடிப் பயணம்';

  @override
  String get sharedCatalogueRefreshError =>
      'போக்குவரத்துத் தரவைப் புதுப்பிக்க முடியவில்லை. சேமித்த தரவு பழையதாக இருக்கலாம்; இணைந்ததும் மீண்டும் முயலவும்.';

  @override
  String legacyFormat0(String p0) {
    return 'பேருந்து $p0';
  }

  @override
  String legacyFormat1(String p0) {
    return 'வழித்தடம் $p0';
  }

  @override
  String legacyFormat2(String p0) {
    return 'அடுத்து வரும் நிறுத்தங்கள் ($p0)';
  }

  @override
  String legacyFormat3(String p0) {
    return 'அட்டவணை: $p0';
  }

  @override
  String legacyFormat4(String p0) {
    return '$p0 நிமிடங்களில் வரும்';
  }

  @override
  String legacyFormat5(String p0) {
    return 'சேருமிடம்: $p0';
  }

  @override
  String legacyFormat6(String p0, String p1) {
    return '$p1 நோக்கிச் செல்லும் $p0 பேருந்தைக் காட்டும் நேரடி வரைபடம்';
  }

  @override
  String legacyFormat7(String p0) {
    return 'அடுத்த நிறுத்தம்: $p0';
  }

  @override
  String legacyFormat8(String p0, String p1, String p2, String p3) {
    return 'பேருந்து நிலை: $p0. கடைசிப் புதுப்பிப்பு: $p1. அடுத்த நிறுத்தம்: $p2. பயணியின் நிறுத்தம்: $p3.';
  }

  @override
  String legacyFormat9(String p0) {
    return '$p0 இல்';
  }

  @override
  String legacyFormat10(String p0) {
    return 'அட்டவணை: $p0';
  }

  @override
  String legacyFormat11(String p0) {
    return 'எதிர்பார்ப்பு: $p0';
  }

  @override
  String legacyFormat12(String p0, String p1) {
    return 'ஓட்டுநர் அறிவிப்பு: $p0 (+$p1 நிமிடங்கள்)';
  }

  @override
  String legacyFormat13(String p0, String p1) {
    return 'தூரம்: $p1 க்கு $p0 கி.மீ.';
  }

  @override
  String legacyFormat14(String p0, String p1) {
    return 'பயண முன்னேற்றம்: $p1 நோக்கிச் செல்லும் பேருந்து அடுத்த $p0 நிறுத்தத்தை நெருங்குகிறது';
  }

  @override
  String legacyFormat15(String p0) {
    return '$p0 இல் கூடுதல் நேரம் அல்லது சாய்வுப்பாதை தேவை என்பதை ஓட்டுநருக்கு அறிவிக்கவும்.';
  }

  @override
  String legacyFormat16(String p0) {
    return '$p0 இல் அடைந்தது';
  }

  @override
  String legacyFormat17(String p0) {
    return 'பேருந்து இப்போது இங்கே உள்ளது ($p0 இல் உறுதியானது)';
  }

  @override
  String legacyFormat18(String p0, String p1) {
    return 'கணிப்பு: $p0 (சுமார் $p1 நிமிடங்களில்)';
  }

  @override
  String legacyFormat19(String p0) {
    return 'தேர்ந்தெடுத்த அட்டவணைப் புறப்பாடு: $p0 — தற்போதைய GPS இந்தப் பயணத்தை உறுதிசெய்யாது.';
  }

  @override
  String legacyFormat20(String p0) {
    return '$p0 நிமிடங்கள் தாமதம்';
  }

  @override
  String legacyFormat21(String p0, String p1) {
    return 'ஓட்டுநர் எச்சரிக்கை: $p0 (+$p1 நிமி.)';
  }

  @override
  String legacyFormat22(String p0) {
    return '$p0 இல்';
  }

  @override
  String legacyFormat23(String p0) {
    return '$p0 இல் கடந்தது';
  }

  @override
  String legacyFormat24(String p0, String p1) {
    return 'அட்டவணை: $p0 · எதிர்பார்ப்பு: $p1';
  }

  @override
  String legacyFormat25(String p0) {
    return '($p0 நிமிடங்கள் தாமதம்)';
  }

  @override
  String legacyFormat26(String p0) {
    return 'கூட்டம்: $p0';
  }

  @override
  String get sharedOnTime => 'நேரத்திற்கு';

  @override
  String get sharedSampleNotice =>
      'SAMPLE / TEST MODE — கற்பனை வாகனங்கள், அறிக்கைகள், சாதனங்கள் மற்றும் GPS. பயண முடிவுகளுக்காக அல்ல.';

  @override
  String get sharedLocalNotice =>
      'LOCAL TEST ONLY — மாதிரிச் சேவைகள் மட்டும்; உண்மைப் போக்குவரத்தோ Cloudinary பதிவேற்றங்களோ இல்லை.';

  @override
  String get legacyEtaNow => 'பேருந்து இப்போது வருகிறது';

  @override
  String legacyEtaApprox(String minutes) {
    return 'பேருந்து சுமார் $minutes நிமிடங்களில் வரும்';
  }

  @override
  String legacySpeedNext(String speed, String stop) {
    return '$speed கி.மீ./மணி · அடுத்து: $stop';
  }

  @override
  String get formReviewPublicNotice =>
      'உங்கள் அறிக்கையும் படமும் அனைவருக்கும் தெரியும். முகங்களையும் தனிப்பட்ட தகவல்களையும் சேர்க்க வேண்டாம்.';

  @override
  String get formReviewDetails => 'தனியுரிமையும் சேமித்த வரைவுகளும்';

  @override
  String get formReviewCooldownShort =>
      'இதே இடத்தில் இதே சிக்கலை மீண்டும் தெரிவிக்க 5 நிமிடங்கள் காத்திருக்கவும்.';

  @override
  String get deliveryServiceUnavailable =>
      'அறிக்கை சேவையை அணுக முடியவில்லை. உங்கள் வரைவு சேமிக்கப்பட்டுள்ளது. சேவை கிடைக்கும்போது மீண்டும் முயலவும்.';

  @override
  String get deliveryServiceConfiguration =>
      'இந்தச் செயலி அறிக்கை சேவையுடன் இணைக்கப்படவில்லை. சரியாக அமைக்கப்பட்ட முதன்மைச் செயலியைத் திறந்து சேமித்த வரைவை மீண்டும் அனுப்பவும்.';

  @override
  String get deliveryPermissionDenied =>
      'அறிக்கையை வெளியிட அனுமதி மறுக்கப்பட்டது. சரியாக அமைக்கப்பட்ட முதன்மைச் செயலியைப் பயன்படுத்துவதை உறுதிசெய்து மீண்டும் உள்நுழைந்து முயலவும். வரைவு சேமிக்கப்பட்டுள்ளது.';

  @override
  String get deliveryTargetIneligible =>
      'இந்தப் பேருந்து அல்லது நிறுத்தத்திற்கான அறிக்கையை வெளியிட முடியாது. நிர்வாகி அதன் பட்டியல் பதிவைச் சரிபார்க்க வேண்டும். வரைவு சேமிக்கப்பட்டுள்ளது.';

  @override
  String get deliveryInvalidReport =>
      'இந்த அறிக்கை விவரங்களைச் சேவை ஏற்கவில்லை. தேர்ந்தெடுத்த பேருந்து அல்லது நிறுத்தத்தையும் கவனிப்பையும் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get adminAccessibilityDetails => 'அணுகல் வசதி விவரங்கள்';

  @override
  String resultsOutsideNeeds(int count) {
    return 'உங்கள் தற்போதைய அணுகல் தேவைகளைப் பூர்த்தி செய்யாத $count அட்டவணைச் சேவைகள் உள்ளன.';
  }

  @override
  String get resultsRemoveAccessFilters => 'அணுகல் வடிகட்டிகள் இல்லாமல் காட்டு';

  @override
  String get resultsTemporaryFiltersHelp =>
      'இந்தத் தேடலுக்கு மட்டும். இந்தச் சேவைகளில் அணுகல் தெரியாமல் இருக்கலாம் அல்லது தடைகள் இருக்கலாம். சேமித்த விருப்பங்கள் மாறாது.';
}
