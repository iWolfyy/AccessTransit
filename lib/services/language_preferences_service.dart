import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sample_test_mode.dart';

/// Account-scoped local language; guest selection never overwrites an account.
/// Cross-device locale sync is a later profile migration, not implied here.
class LanguagePreferencesService extends ChangeNotifier {
  static final instance = LanguagePreferencesService();
  static const languages = ['en', 'si', 'ta'];

  SharedPreferences? _prefs;
  StreamSubscription<String?>? _accounts;
  Future<void> _writes = Future.value();
  String? _uid;
  Locale _locale = const Locale('en');
  bool _disposed = false;

  Locale get locale => _locale;
  String? get userId => _uid;

  static String storageKey(String? uid) => SampleTestMode.storage(
    uid == null
        ? 'language_v1_guest'
        : 'language_v1_account_${base64Url.encode(utf8.encode(uid))}',
  );

  Future<void> init({SharedPreferences? prefs, String? userId}) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();
    activateAccount(userId);
  }

  void activateAccount(String? uid) {
    _uid = uid;
    final saved = _prefs?.getString(storageKey(uid));
    _locale = Locale(languages.contains(saved) ? saved! : 'en');
    if (!_disposed) notifyListeners();
  }

  void bindAccounts(Stream<String?> accounts) {
    unawaited(_accounts?.cancel());
    _accounts = accounts.distinct().listen((uid) {
      if (uid != _uid) activateAccount(uid);
    });
  }

  Future<void> setLanguage(String code) async {
    if (!languages.contains(code)) throw ArgumentError.value(code, 'code');
    final prefs = _prefs;
    if (prefs == null) throw StateError('Language preferences not initialized');
    final uid = _uid;
    // Capture the owner before queuing; an account switch cannot redirect a save.
    final operation = _writes.catchError((Object _) {}).then((_) async {
      if (!await prefs.setString(storageKey(uid), code)) {
        throw StateError('Language was not saved');
      }
      if (!_disposed && _uid == uid) {
        _locale = Locale(code);
        notifyListeners();
      }
    });
    _writes = operation;
    await operation;
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_accounts?.cancel());
    super.dispose();
  }
}
