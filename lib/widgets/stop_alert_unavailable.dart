import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../l10n/localization_context.dart';

/// Truthful availability state until stop detection and delivery are connected.
class StopAlertUnavailable extends StatelessWidget {
  const StopAlertUnavailable({super.key});

  static const explanation =
      'Automatic stop alerts and background notifications are unavailable. '
      'Follow trip progress manually; the app will not notify you before your stop.';

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: false,
    label:
        '${context.l10n.sharedStopAlert}. ${context.l10n.sharedStopAlertHelp}',
    excludeSemantics: true,
    child: OutlinedButton.icon(
      onPressed: null,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(context.buttonHeight, context.minTapHeight),
        disabledForegroundColor: context.textColor,
        side: BorderSide(color: context.textColor),
      ),
      icon: Icon(
        Icons.notifications_off_outlined,
        size: context.tapIconSize - 2,
      ),
      label: Text(context.l10n.sharedStopAlert, textAlign: TextAlign.center),
    ),
  );
}
