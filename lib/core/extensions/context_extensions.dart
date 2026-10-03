import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

extension LocalizationExtension on BuildContext {
  /// Convenient shortcut to access localizations: `context.loc.yourKey`
  AppLocalizations get loc => AppLocalizations.of(this);
}
