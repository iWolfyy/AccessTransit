// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

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
  String get calendarTitle => '???? ??????????';

  @override
  String get calendarHelp =>
      '???????????????? ??? ???????, ???????? ?????????? ????? ??????? ?????????? 31 ?????? ??????? ???????????. ??????? ???????????? ????????????. ??????? ???? ???????? ????????????????. ???????????? ??????????????? ???????? ????? ????????.';

  @override
  String get calendarDates => '?????? ????????? ?????????????????';

  @override
  String get calendarTime => '???????? ?????????? ????????? ?????????????????';

  @override
  String get calendarPublish => '???????????? ???????????';

  @override
  String get calendarGenerate => '????????? ???????????? ????????????';

  @override
  String get calendarRetire => '???????????? ???????????????';

  @override
  String get calendarFailed =>
      '??????? ?????? ???? ?????? ???????????????????????. ??????? ???????? ????????. ??? ??????????? ?????????? 31 ??????????? ?????????????????. ??????? ??????????? ????? ?????????? ????.';

  @override
  String get calendarConfirmed => '?????????? ??????? ?????????????????????.';

  @override
  String calendarGenerated(int created, int preserved) {
    return '$created ???????????? ???????????????; ??????? ???? $preserved ????????????????.';
  }

  @override
  String get calendarPublished => '????????????? ??????????';

  @override
  String get calendarRetired => '????????????????? ??????????';

  @override
  String get calendarEmpty => '?????? ???????????? ????????????? ?????.';
}
