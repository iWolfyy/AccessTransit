import 'dart:async';
import 'dart:convert';

import 'sample_test_mode.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device display controls persist globally; travel needs belong to an account.
class AccessibilityPreferencesService extends ChangeNotifier {
  AccessibilityPreferencesService();
  static final instance = AccessibilityPreferencesService();
  static const keyHighContrast = 'isHighContrast';
  static const keyHasLargeTargets = 'hasLargeTargets';
  // Legacy personal keys have no reliable owner and are discarded.
  static const keyWheelchairOnly = 'isWheelchairOnly';
  static const keyStepFree = 'isStepFree';
  static const keyMinimizeWalking = 'minimizeWalking';
  static const keyVoiceGuidance = 'voiceGuidance';
  static const keyHapticAlerts = 'hapticAlerts';
  static const keyBoardingAssistance = 'boardingAssistance';
  static const keyQuietRoutes = 'quietRoutes';
  static String accountKey(String uid) => SampleTestMode.storage(
    'travel_preferences_v2_${base64Url.encode(utf8.encode(uid))}',
  );

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  bool _disposed = false;
  int _revision = 0;
  String? _userId;
  String? _storageError;
  Future<void>? _writes;
  StreamSubscription<String?>? _authSubscription;
  bool _isHighContrast = false;
  bool _hasLargeTargets = true;
  // Retain the product's conservative default for every new account/guest.
  bool _isWheelchairOnly = true;
  bool _isStepFree = false;
  bool get isInitialized => _isInitialized;
  String? get userId => _userId;
  String? get storageError => _storageError;
  bool get isHighContrast => _isHighContrast;
  bool get hasLargeTargets => _hasLargeTargets;
  bool get isWheelchairOnly => _isWheelchairOnly;
  bool get wheelchairAccessRequired => _isWheelchairOnly;
  bool get isStepFree => _isStepFree;
  bool get minimizeWalking => false;
  bool get voiceGuidance => false;
  bool get hapticAlerts => false;
  bool get boardingAssistance => false;
  bool get quietRoutes => false;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _loadNeeds() {
    _isWheelchairOnly = true;
    _isStepFree = false;
    final uid = _userId;
    if (uid == null || _prefs == null) return;
    try {
      final raw = _prefs!.getString(accountKey(uid));
      if (raw == null || raw.length > 512) return;
      final data = jsonDecode(raw) as Map;
      if (data['wheelchair'] is! bool || data['stepFree'] is! bool) return;
      _isWheelchairOnly = data['wheelchair'] as bool;
      _isStepFree = data['stepFree'] as bool;
    } catch (_) {
      /* Invalid needs load explicit defaults, never another owner. */
    }
  }

  Future<void> init({SharedPreferences? prefs, String? userId}) async {
    final revision = ++_revision;
    _userId = userId;
    _isWheelchairOnly = true;
    _isStepFree = false;
    _notify();
    final loaded = prefs ?? await SharedPreferences.getInstance();
    if (_disposed || revision != _revision) return;
    _prefs = loaded;
    _isHighContrast = loaded.getBool(keyHighContrast) ?? false;
    _hasLargeTargets = loaded.getBool(keyHasLargeTargets) ?? true;
    _loadNeeds();
    _isInitialized = true;
    _storageError = null;
    _notify();
    // No implicit migration of anonymous travel needs into a signed-in account.
    for (final key in [
      keyWheelchairOnly,
      keyStepFree,
      keyMinimizeWalking,
      keyVoiceGuidance,
      keyHapticAlerts,
      keyBoardingAssistance,
      keyQuietRoutes,
    ]) {
      if (!await loaded.remove(key)) {
        throw StateError('Could not clear legacy preferences.');
      }
    }
  }

  Future<void> activateAccount(String? uid) async {
    final revision = ++_revision;
    _userId = uid;
    _storageError = null;
    _loadNeeds(); // Synchronous reset/load before any await or notification.
    _notify();
    if (_prefs == null) {
      final loaded = await SharedPreferences.getInstance();
      if (_disposed || revision != _revision) return;
      _prefs = loaded;
      _isHighContrast = loaded.getBool(keyHighContrast) ?? false;
      _hasLargeTargets = loaded.getBool(keyHasLargeTargets) ?? true;
      _isInitialized = true;
    }
    // Finish captured old-owner writes before reading this owner's latest save.
    if (_writes != null) await _writes!.catchError((Object _) {});
    if (_disposed || revision != _revision) return;
    _loadNeeds();
    _notify();
  }

  /// The initial identity is loaded by main before rendering the app.
  void startAuthSync({FirebaseAuth? auth}) {
    bindAccounts(
      (auth ?? FirebaseAuth.instance).authStateChanges().map(
        (user) => user?.uid,
      ),
    );
  }

  void bindAccounts(Stream<String?> accounts) {
    _authSubscription?.cancel();
    _authSubscription = accounts.distinct().listen((uid) {
      if (uid == _userId) return;
      unawaited(
        activateAccount(uid).catchError((Object _) {
          _storageError = 'Could not load preferences for this account.';
          _notify();
        }),
      );
    });
  }

  Future<void> setHighContrast(bool value) =>
      savePreferences(isHighContrast: value);
  Future<void> setLargeTargets(bool value) =>
      savePreferences(hasLargeTargets: value);
  Future<void> setWheelchairOnly(bool value) =>
      savePreferences(isWheelchairOnly: value);
  Future<void> setStepFree(bool value) => savePreferences(isStepFree: value);
  Future<void> setMinimizeWalking(bool value) async {}
  Future<void> setVoiceGuidance(bool value) async {}
  Future<void> setHapticAlerts(bool value) async {}
  Future<void> setBoardingAssistance(bool value) async {}
  Future<void> setQuietRoutes(bool value) async {}

  Future<void> savePreferences({
    bool? isHighContrast,
    bool? hasLargeTargets,
    bool? isWheelchairOnly,
    bool? isStepFree,
    bool? minimizeWalking,
    bool? voiceGuidance,
    bool? hapticAlerts,
    bool? boardingAssistance,
    bool? quietRoutes,
  }) async {
    final revision = ++_revision;
    final uid = _userId;
    if (isHighContrast != null) _isHighContrast = isHighContrast;
    if (hasLargeTargets != null) _hasLargeTargets = hasLargeTargets;
    if (isWheelchairOnly != null) _isWheelchairOnly = isWheelchairOnly;
    if (isStepFree != null) _isStepFree = isStepFree;
    final needs = jsonEncode({
      'wheelchair': _isWheelchairOnly,
      'stepFree': _isStepFree,
    });
    _storageError = null;
    _notify();
    final previous = _writes;
    Future<void> persist() async {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      if (isHighContrast != null &&
          !await prefs.setBool(keyHighContrast, isHighContrast)) {
        throw StateError('Display save failed.');
      }
      if (hasLargeTargets != null &&
          !await prefs.setBool(keyHasLargeTargets, hasLargeTargets)) {
        throw StateError('Display save failed.');
      }
      // Guests have session-only needs; never persist into an anonymous shared slot.
      if (uid != null &&
          (isWheelchairOnly != null || isStepFree != null) &&
          !await prefs.setString(accountKey(uid), needs)) {
        throw StateError('Travel preferences save failed.');
      }
    }

    final write = previous == null
        ? persist()
        : previous.catchError((Object _) {}).then((_) => persist());
    _writes = write;
    try {
      await write;
    } catch (_) {
      if (!_disposed && revision == _revision) {
        _storageError = 'Preferences changed for this session but could not be saved. Please retry.';
        _notify();
      }
      rethrow;
    } finally {
      if (identical(_writes, write)) _writes = null;
    }
  }

  Future<void> resetToDefaults() => savePreferences(
    isHighContrast: false,
    hasLargeTargets: true,
    isWheelchairOnly: true,
    isStepFree: false,
  );

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }
}
