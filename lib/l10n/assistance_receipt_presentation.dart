import 'package:flutter/widgets.dart';

import 'localization_context.dart';

/// Translate service-owned labels/errors; do not expose unknown provider messages.
extension AssistanceReceiptPresentation on BuildContext {
  String assistanceReceiptText(String value) => switch (value) {
    "Assistance request" => l10n.assistReceiptTitle,
    "Sign in with the account that created this request to view its status." =>
      l10n.assistReceiptOwner,
    "Sent to shared service" => l10n.assistReceiptSent,
    "Request status unknown" => l10n.assistReceiptUnknown,
    "Saving the request does not mean the driver has accepted it." =>
      l10n.assistReceiptPendingHint,
    "The driver has acknowledged the request. Assistance has not been marked completed." =>
      l10n.assistReceiptAcceptedHint,
    "Request delivery" => l10n.assistReceiptDelivery,
    "Your assistance request" => l10n.assistReceiptOwn,
    "Support requested" => l10n.assistReceiptSupport,
    "Not specified" => l10n.assistReceiptUnspecified,
    "Driver response" => l10n.assistReceiptDriver,
    "Driver acknowledgement is not confirmed." => l10n.assistReceiptUnconfirmed,
    "Live status updates are unavailable. Displayed driver status is the last received status." =>
      l10n.assistReceiptStale,
    "Sending?" => l10n.assistReceiptSending,
    "Retry upload" => l10n.assistReceiptRetry,
    "Cancelling?" => l10n.assistReceiptCancelling,
    "Cancel request" => l10n.assistReceiptCancel,
    "Could not save the retry on this device. Please try again." =>
      l10n.assistReceiptRetryError,
    "Cancellation is not confirmed. Check your connection and try again." =>
      l10n.assistReceiptCancelError,
    "Pending upload" => l10n.assistReceiptPendingUpload,
    "Sent" => l10n.assistReceiptDeliverySent,
    "Failed" => l10n.assistReceiptFailed,
    "Retry expired" => l10n.assistReceiptExpired,
    "Automatic retries stopped because this request is old. Check the driver status; delivery may still be unconfirmed." =>
      l10n.assistReceiptOld,
    "Delivery is not confirmed. Retry when connected; keep checking the driver status." =>
      l10n.assistReceiptDeliveryError,
    "The request could not be sent. Check your sign-in and target, then retry." =>
      l10n.assistReceiptSendError,
    "Some saved assistance requests could not be restored. Check your shared request history." =>
      l10n.assistReceiptRestoreError,
    "The latest request status could not be saved on this device. Check the shared request history." =>
      l10n.assistReceiptSaveError,
    "Your assistance requests" => l10n.assistReceiptHistory,
    "Shared request updates are unavailable. Saved receipts may be out of date." =>
      l10n.assistReceiptHistoryStale,
    "Request status is unavailable. Check your connection and account, then retry." =>
      l10n.assistReceiptError,
    _ => l10n.assistReceiptError,
  };
}
