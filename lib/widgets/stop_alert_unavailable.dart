import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

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
    label: 'Stop alert unavailable. $explanation',
    excludeSemantics: true,
    child: OutlinedButton.icon(
      onPressed: null,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(0, context.minTapHeight),
        disabledForegroundColor: context.textColor,
        side: BorderSide(color: context.textColor),
      ),
      icon: Icon(
        Icons.notifications_off_outlined,
        size: context.tapIconSize - 2,
      ),
      label: const Text('Stop alert unavailable', textAlign: TextAlign.center),
    ),
  );
}
