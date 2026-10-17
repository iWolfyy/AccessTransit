import 'package:flutter/widgets.dart';

import 'localization_context.dart';

/// Fixed Home labels only. Navigation keys, names and report text stay data.
extension HomePresentation on BuildContext {
  String homeText(String key) => switch (key) {
    "Good Morning" => l10n.homeMorning,
    "Good Afternoon" => l10n.homeAfternoon,
    "Good Evening" => l10n.homeEvening,
    "Ready to ride?" => l10n.homeReady,
    "Where are you going?" => l10n.homeWhere,
    "Tap to plan your journey" => l10n.homePlanHint,
    "Open menu" => l10n.homeMenu,
    "Open profile" => l10n.homeProfileAction,
    "Track\nBus" => l10n.homeTrack,
    "Plan\nJourney" => l10n.homePlanAction,
    "Access\nPrefs" => l10n.homePreferencesAction,
    "Home" => l10n.homeHome,
    "Plan" => l10n.homePlan,
    "Plan Journey" => l10n.homePlanJourney,
    "Community" => l10n.homeCommunity,
    "Profile" => l10n.homeProfile,
    "Rewards & Contributions" => l10n.homeRewards,
    "Help & Support" => l10n.homeHelp,
    "Log out" => l10n.homeLogout,
    "Recent Community Reports" => l10n.homeRecentReports,
    "No recent community reports." => l10n.homeNoReports,
    "Community reports are unavailable. Try again later." =>
      l10n.homeReportsUnavailable,
    "Report" => l10n.homeReport,
    "Recent Journey" => l10n.homeRecentJourney,
    "No recorded journey" => l10n.homeNoJourney,
    "Plan a journey to get started" => l10n.homeStartPlanning,
    "Loading recent journey…" => l10n.homeJourneysLoading,
    "Recent journey unavailable" => l10n.homeJourneysUnavailable,
    "Try again later" => l10n.homeRetryLater,
    "Origin" => l10n.homeOrigin,
    "Destination" => l10n.homeDestination,
    "Recent" => l10n.homeRecent,
    "Re-plan" => l10n.homeReplan,
    "Assistance" => l10n.homeAssistance,
    "Just now" => l10n.homeJustNow,
    "Observation time unavailable" => l10n.homeUnknownAge,
    "Accessibility Preferences" => l10n.profileAccessibility,
    "Saved Places" => l10n.profilePlaces,
    "Operator Dashboard" => l10n.driverDashboard,
    _ => key,
  };
  String homeAge(DateTime? observedAt, {DateTime? clock}) {
    if (observedAt == null) return l10n.homeUnknownAge;
    final age = (clock ?? DateTime.now()).difference(observedAt);
    if (age.isNegative || age.inSeconds < 45) return l10n.homeJustNow;
    if (age.inMinutes < 60) return l10n.homeMinutesAgo(age.inMinutes);
    if (age.inHours < 24) return l10n.homeHoursAgo(age.inHours);
    if (age.inDays < 30) return l10n.homeDaysAgo(age.inDays);
    return l10n.homeMonthsAgo(age.inDays ~/ 30);
  }
}
