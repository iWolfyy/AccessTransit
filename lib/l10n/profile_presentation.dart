import 'package:flutter/widgets.dart';

import 'localization_context.dart';

/// Presentation labels only; profile values and stored roles remain unchanged.
extension ProfilePresentation on BuildContext {
  String profileText(String label) => switch (label) {
    "No profile found. Please sign in again." => l10n.profileMissing,
    "Unable to load profile from the database." => l10n.profileLoadFailed,
    "Profile unavailable." => l10n.profileUnavailable,
    "Passenger" => l10n.profilePassenger,
    "Community Contributor" => l10n.profileContributor,
    "Transit Bus Operator" => l10n.profileOperator,
    "System Administrator" => l10n.profileAdministrator,
    "Inclusive Commuter" => l10n.profileCommuter,
    "Edit" => l10n.profileEdit,
    "Edit Profile" => l10n.profileEditTitle,
    "Full Name" => l10n.profileFullName,
    "Email Address" => l10n.profileEmail,
    "Phone Number" => l10n.profilePhone,
    "Please enter your name" => l10n.profileNameRequired,
    "Save Changes" => l10n.profileSave,
    "Profile updated successfully!" => l10n.profileSaved,
    "Profile changes could not be confirmed. Please retry." =>
      l10n.profileSaveFailed,
    "Could not clear private drafts or sign out. Please retry." =>
      l10n.profileSignOutFailed,
    "You have been signed out successfully." => l10n.profileSignedOut,
    "Sign Out" => l10n.profileSignOut,
    "Cancel" => l10n.profileCancel,
    "Retry" => l10n.profileRetry,
    "Sign out and remove pending report drafts and photos from this device? Requests already sent may still complete. Published reports remain available after signing back in." =>
      l10n.profileLogoutQuestion,
    "SETTINGS" => l10n.profileSettings,
    "SUPPORT" => l10n.profileSupport,
    "PERSONAL INFORMATION" => l10n.profilePersonalInfo,
    "Admin console" => l10n.profileAdminConsole,
    "Accessibility Preferences" => l10n.profileAccessibility,
    "Push Notifications" => l10n.profilePush,
    "Change Password" => l10n.profilePassword,
    "Saved Places" => l10n.profilePlaces,
    "Rate Us" => l10n.profileRate,
    "Help Center" => l10n.profileHelp,
    "Check for Updates" => l10n.profileUpdates,
    "Not set" => l10n.profileNotSet,
    "Reports" => l10n.profileReports,
    "Verifications" => l10n.profileVerifications,
    "Badges" => l10n.profileBadges,
    "Community Impact Score" => l10n.profileImpact,
    "See All →" => l10n.profileSeeAll,
    "View earned badges" => l10n.profileBadgeDetails,
    "Delete Account" => l10n.profileDelete,
    "Self-service deletion is not available here yet" =>
      l10n.profileDeleteUnavailable,
    "Full name" => l10n.profileFullName,
    "Phone number" => l10n.profilePhone,
    "Email address" => l10n.profileEmail,
    "Permanently remove your account" => l10n.profileDeleteUnavailable,
    _ => label,
  };
}
