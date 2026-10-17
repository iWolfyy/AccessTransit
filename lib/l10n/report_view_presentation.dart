import 'package:flutter/widgets.dart';

import 'localization_context.dart';

/// Only known UI messages are translated; original report text stays data.
extension ReportViewPresentation on BuildContext {
  String reportViewText(String value) => switch (value) {
    "Sign in before changing a shared report." => l10n.reportSignInChange,
    "Change is not confirmed. Check your connection and sign-in, then retry or refresh the shared report." =>
      l10n.reportChangeUnconfirmed,
    "Alert text copied to clipboard!" => l10n.reportCopied,
    "Could not copy the alert. Please retry." => l10n.reportCopyFailed,
    "Image preview unavailable" => l10n.reportImageUnavailable,
    "Report Details" => l10n.reportDetailsTitle,
    "Shared report unavailable or removed. Reopen the feed to refresh." =>
      l10n.reportRemoved,
    "Share alert" => l10n.reportShare,
    "Shared updates unavailable. Showing the last received observation; refresh before acting." =>
      l10n.reportStaleUpdates,
    "Sign in to confirm, flag or resolve shared reports." =>
      l10n.reportSignInActions,
    "Resolution is the author's recorded observation; it does not independently verify a repair." =>
      l10n.reportResolutionDisclosure,
    "Resolution time: Unknown" => l10n.reportResolutionUnknown,
    "Condition Resolved" => l10n.reportResolvedTitle,
    "The author recorded this condition as resolved." =>
      l10n.reportResolvedHelp,
    "Observation time unknown" => l10n.reportObservationUnknown,
    "The observation date is unavailable. Current condition cannot be confirmed." =>
      l10n.reportUnknownHelp,
    "Community-confirmed observation" => l10n.reportConfirmedTitle,
    "Active Transit Alert" => l10n.reportActiveTitle,
    "Reported by a commuter. Review the observation time and current evidence." =>
      l10n.reportActiveHelp,
    "Past Report (Expired)" => l10n.reportExpiredTitle,
    "This observation has expired; it does not establish the current condition." =>
      l10n.reportExpiredHelp,
    "YOUR REPORT" => l10n.reportYours,
    "BUS" => l10n.reportBus,
    "STATION" => l10n.reportStation,
    "High Severity" => l10n.reportHighSeverity,
    "Minor Issue" => l10n.reportMinorSeverity,
    "Moderate" => l10n.reportModerateSeverity,
    "Reported Condition Details" => l10n.reportConditionDetails,
    "Rider Note:" => l10n.reportRiderNote,
    "Attached Photo Evidence" => l10n.reportPhotoEvidence,
    "Tap to enlarge" => l10n.reportEnlarge,
    "Photo unavailable" => l10n.reportPhotoUnavailable,
    "Community Trust & Verification Metrics" => l10n.reportMetrics,
    "Rechecks are dated observations; unique confirmations are unchanged." =>
      l10n.reportRecheckDisclosure,
    "Vote Report Accuracy" => l10n.reportVoteHeading,
    "Recheck condition" => l10n.reportRecheckAction,
    "Condition Marked Fixed" => l10n.reportFixed,
    "Mark Condition as Fixed / Resolved" => l10n.reportResolveAction,
    "Ramp & Access" => l10n.reportRampCategory,
    "Elevator / Lift" => l10n.reportLiftCategory,
    "Crowding" => l10n.reportCrowdingCategory,
    "Cleanliness" => l10n.reportCleanCategory,
    "Safety Hazard" => l10n.reportSafetyCategory,
    "Report delivery" => l10n.deliveryTitle,
    "Publication status" => l10n.deliveryStatus,
    "Draft unavailable" => l10n.deliveryDraftUnavailable,
    "Published" => l10n.deliveryPublished,
    "Pending upload" => l10n.deliveryPending,
    "Failed" => l10n.deliveryFailed,
    "Your report is available to other commuters." => l10n.deliveryPublicHelp,
    "This draft was removed, expired or belongs to another account. Publication has not been confirmed." =>
      l10n.deliveryRemovedHelp,
    "Saved on this device. Publication has not been confirmed." =>
      l10n.deliveryPendingHelp,
    "Local draft unavailable" => l10n.deliveryLocalUnavailable,
    "Your observation" => l10n.deliveryObservation,
    "Location / Vehicle" => l10n.deliveryTarget,
    "Condition reported" => l10n.deliveryCondition,
    "Attached photo" => l10n.deliveryPhoto,
    "Photo preview unavailable" => l10n.deliveryPhotoUnavailable,
    "Uploading…" => l10n.deliveryUploading,
    "Retry upload" => l10n.deliveryRetry,
    "Remove draft from this device" => l10n.deliveryRemoveDevice,
    "About local drafts" => l10n.deliveryAboutDrafts,
    "Drafts expire after 7 days and are removed on sign-out/account change." =>
      l10n.deliveryDraftExpiry,
    "View in Community Feed" => l10n.deliveryViewFeed,
    "Back to Home" => l10n.deliveryHome,
    "Could not save the upload status. Please retry." =>
      l10n.deliverySaveFailed,
    "Remove local draft?" => l10n.deliveryRemoveQuestion,
    "Stops future retries and removes the local note/photo. A request already sent may still complete. This does not delete a public report or an uploaded photo." =>
      l10n.deliveryRemoveHelp,
    "Keep draft" => l10n.deliveryKeep,
    "Remove draft" => l10n.deliveryRemove,
    "Local removal could not be saved. Please retry." =>
      l10n.deliveryRemoveFailed,
    "Observation time unknown. Create a new report before uploading." =>
      l10n.deliveryUnknownTime,
    "Waiting for a connection. This report is not confirmed as published." =>
      l10n.deliveryWaiting,
    "Upload failed. Check your sign-in, photo and service access, then retry." =>
      l10n.deliveryUploadFailed,
    "This action was already recorded." => l10n.reportAlreadySaved,
    "Recheck not saved. Wait 30 minutes after the latest check, then retry." =>
      l10n.reportWaitRecheck,
    "Change saved. Shared details will refresh when connected." =>
      l10n.reportChangeSaved,
    "Confirmation saved to the shared report." => l10n.reportConfirmationSaved,
    "Recheck saved. Unique confirmations and points are unchanged." =>
      l10n.reportRecheckSaved,
    "Flag saved to the shared report." => l10n.reportFlagSaved,
    "Flag saved. Report hidden after three independent flags." =>
      l10n.reportFlagHiddenLegacy,
    "Resolution saved to the shared report." => l10n.reportResolutionSaved,
    _ => value,
  };
  String deliveryError(String? value) {
    if (value == null) return l10n.deliveryPendingHelp;
    if (value.startsWith('Same-issue cooldown.') ||
        value.startsWith(
          'The same issue can be reported once every 5 minutes.',
        )) {
      final match = RegExp(r'Retry after (.+) \(UTC\)').firstMatch(value);
      final at = DateTime.tryParse(match?.group(1) ?? '');
      return at == null
          ? l10n.reportCooldownNotice
          : l10n.deliveryCooldownAt(at.toUtc().toIso8601String());
    }
    return switch (value) {
      'publication:service-unavailable' => l10n.deliveryServiceUnavailable,
      'publication:backend-not-configured' => l10n.deliveryServiceConfiguration,
      'publication:permission-denied' => l10n.deliveryPermissionDenied,
      'publication:authentication-required' ||
      'publication:unauthenticated' ||
      'publication:not-authorized' => l10n.reviewSignInRequired,
      'publication:account-changed' => l10n.reviewAccountChanged,
      'publication:account-suspended' => l10n.reviewRestricted,
      'publication:report-ineligible' => l10n.deliveryTargetIneligible,
      'publication:invalid-request' => l10n.deliveryInvalidReport,
      'Observation time unknown. Create a new report before uploading.' =>
        l10n.deliveryUnknownTime,
      'Waiting for a connection. This report is not confirmed as published.' =>
        l10n.deliveryWaiting,
      _ => l10n.deliveryUploadFailed,
    };
  }
}
