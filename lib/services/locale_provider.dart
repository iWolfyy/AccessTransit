import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'selected_user_locale';
  
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('si'),
    Locale('ta'),
  ];

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_prefKey);
    if (languageCode != null && _isSupported(languageCode)) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale || !_isSupported(newLocale.languageCode)) return;

    _locale = newLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, newLocale.languageCode);
  }

  bool _isSupported(String languageCode) {
    return supportedLocales.any((l) => l.languageCode == languageCode);
  }
}
