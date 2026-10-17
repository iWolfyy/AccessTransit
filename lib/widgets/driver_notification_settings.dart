import 'package:flutter/material.dart';

import '../services/driver_notifications.dart';
import '../l10n/localization_context.dart';

class DriverNotificationSettings extends StatelessWidget {
  const DriverNotificationSettings({super.key, required this.session});
  final DriverNotifications session;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (c, _) {
      final l = c.l10n;
      final description = switch (session.state) {
        DriverPushState.off => l.pushOff,
        DriverPushState.connecting => l.pushConnecting,
        DriverPushState.denied => l.pushDenied,
        DriverPushState.ready => l.pushReady,
        DriverPushState.unavailable => l.pushUnavailable,
      };
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.pushTitle, style: Theme.of(c).textTheme.titleMedium),
            Text(description),
            Wrap(
              spacing: 8,
              children: [
                if (session.state != DriverPushState.ready)
                  OutlinedButton(
                    onPressed: session.state == DriverPushState.connecting
                        ? null
                        : session.enable,
                    child: Text(l.pushEnable),
                  ),
                if (session.enabled)
                  TextButton(
                    onPressed: session.disable,
                    child: Text(l.pushDisable),
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
