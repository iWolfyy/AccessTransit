import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// English fallback keeps isolated screen hosts usable without an app delegate.
extension LocalizationContext on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? lookupAppLocalizations(const Locale('en'));
}
