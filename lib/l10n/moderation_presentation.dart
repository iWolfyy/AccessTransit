import 'package:flutter/widgets.dart';

import 'localization_context.dart';

/// Presentation only: server enums, decisions and authority remain unchanged.
extension ModerationPresentation on BuildContext {
  String banReviewStatus(String? status) => switch (status) {
    'pending' => l10n.bansPending,
    'approved' => l10n.bansApproved,
    'rejected' => l10n.bansRejected,
    'withdrawn' => l10n.bansWithdrawn,
    _ => l10n.adminRunUnknown,
  };
  String reportReviewStatus(String? status) => switch (status) {
    'pending' => l10n.reviewsPending,
    'upheld' || 'rejected' => l10n.reviewsUpheld,
    'overturned' || 'accepted' => l10n.reviewsOverturned,
    'unreviewed' => l10n.reviewsUnreviewed,
    _ => l10n.adminRunUnknown,
  };
  String reviewVote(String? vote) => switch (vote) {
    'true' => l10n.voteTrue,
    'false' => l10n.voteFalse,
    _ => l10n.reviewVoteUnknown,
  };
  String? reviewFailure(String? code) => switch (code) {
    'admin-required' => l10n.reviewAccessRequired,
    'self-review-forbidden' => l10n.reviewSelfForbidden,
    'authentication-required' => l10n.reviewSignInRequired,
    'account-changed' => l10n.reviewAccountChanged,
    'account-suspended' => l10n.reviewRestricted,
    'review-already-decided' => l10n.reviewAlreadyDecided,
    'review-unavailable' || 'dispute-unavailable' => l10n.reviewUnavailable,
    'operation-unavailable' => l10n.reviewOperationUnavailable,
    'request-id-conflict' => l10n.reviewRetryConflict,
    'reason-required' => l10n.reviewsReasonRequired,
    _ => null,
  };
}
