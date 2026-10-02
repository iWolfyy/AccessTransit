import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global service managing user accessibility preferences.
///
/// Implements [ChangeNotifier] to allow real-time reactive updates across
/// the entire app (e.g. dynamic high contrast theme switching and default
/// journey route filter synchronization) in accordance with WCAG 2.2 AA.
class AccessibilityPreferencesService extends ChangeNotifier {
  AccessibilityPreferencesService._();

  /// Global singleton instance.
  static final AccessibilityPreferencesService instance =
      AccessibilityPreferencesService._();

  // SharedPreferences Keys
  static const String keyHighContrast = 'isHighContrast';
  static const String keyWheelchairOnly = 'isWheelchairOnly';
  static const String keyStepFree = 'isStepFree';
  static const String keyHasLargeTargets = 'hasLargeTargets';
  static const String keyMinimizeWalking = 'minimizeWalking';
  static const String keyVoiceGuidance = 'voiceGuidance';
  static const String keyHapticAlerts = 'hapticAlerts';
  static const String keyBoardingAssistance = 'boardingAssistance';
  static const String keyQuietRoutes = 'quietRoutes';

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // Defaults aligned with WCAG AA accessibility needs
  bool _isHighContrast = false;
  bool _isWheelchairOnly = true;
  bool _isStepFree = false;
  bool _hasLargeTargets = true;
  bool _minimizeWalking = false;
  bool _voiceGuidance = true;
  bool _hapticAlerts = false;
  bool _boardingAssistance = false;
  bool _quietRoutes = false;

  /// Whether the service has completed loading from storage.
  bool get isInitialized => _isInitialized;

  // Getters
  bool get isHighContrast => _isHighContrast;
  bool get isWheelchairOnly => _isWheelchairOnly;
  bool get isStepFree => _isStepFree;
  bool get hasLargeTargets => _hasLargeTargets;
  bool get minimizeWalking => _minimizeWalking;
  bool get voiceGuidance => _voiceGuidance;
  bool get hapticAlerts => _hapticAlerts;
  bool get boardingAssistance => _boardingAssistance;
  bool get quietRoutes => _quietRoutes;

  /// Semantic alias for wheelchair access requirement.
  bool get wheelchairAccessRequired => _isWheelchairOnly;

  /// Initializes preferences by reading saved settings from [SharedPreferences].
  ///
  /// Can accept an optional [prefs] instance for testing.
  Future<void> init({SharedPreferences? prefs}) async {
    try {
      _prefs = prefs ?? await SharedPreferences.getInstance();
      _isHighContrast = _prefs?.getBool(keyHighContrast) ?? false;
      _isWheelchairOnly = _prefs?.getBool(keyWheelchairOnly) ?? true;
      _isStepFree = _prefs?.getBool(keyStepFree) ?? false;
      _hasLargeTargets = _prefs?.getBool(keyHasLargeTargets) ?? true;
      _minimizeWalking = _prefs?.getBool(keyMinimizeWalking) ?? false;
      _voiceGuidance = _prefs?.getBool(keyVoiceGuidance) ?? true;
      _hapticAlerts = _prefs?.getBool(keyHapticAlerts) ?? false;
      _boardingAssistance = _prefs?.getBool(keyBoardingAssistance) ?? false;
      _quietRoutes = _prefs?.getBool(keyQuietRoutes) ?? false;
    } catch (e) {
      debugPrint('AccessibilityPreferencesService init warning: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Sets High Contrast mode and notifies listeners immediately.
  Future<void> setHighContrast(bool value) async {
    if (_isHighContrast == value) return;
    _isHighContrast = value;
    await _prefs?.setBool(keyHighContrast, value);
    notifyListeners();
  }

  /// Sets Wheelchair-Only filter preference.
  Future<void> setWheelchairOnly(bool value) async {
    if (_isWheelchairOnly == value) return;
    _isWheelchairOnly = value;
    await _prefs?.setBool(keyWheelchairOnly, value);
    notifyListeners();
  }

  /// Sets Step-Free routes preference.
  Future<void> setStepFree(bool value) async {
    if (_isStepFree == value) return;
    _isStepFree = value;
    await _prefs?.setBool(keyStepFree, value);
    notifyListeners();
  }

  /// Sets 48dp+ Large Tap Targets enforcement preference.
  Future<void> setLargeTargets(bool value) async {
    if (_hasLargeTargets == value) return;
    _hasLargeTargets = value;
    await _prefs?.setBool(keyHasLargeTargets, value);
    notifyListeners();
  }

  /// Sets Minimize Walking distance preference.
  Future<void> setMinimizeWalking(bool value) async {
    if (_minimizeWalking == value) return;
    _minimizeWalking = value;
    await _prefs?.setBool(keyMinimizeWalking, value);
    notifyListeners();
  }

  /// Sets Voice Guidance preference.
  Future<void> setVoiceGuidance(bool value) async {
    if (_voiceGuidance == value) return;
    _voiceGuidance = value;
    await _prefs?.setBool(keyVoiceGuidance, value);
    notifyListeners();
  }

  /// Sets Haptic Alerts preference.
  Future<void> setHapticAlerts(bool value) async {
    if (_hapticAlerts == value) return;
    _hapticAlerts = value;
    await _prefs?.setBool(keyHapticAlerts, value);
    notifyListeners();
  }

  /// Sets Boarding Assistance preference.
  Future<void> setBoardingAssistance(bool value) async {
    if (_boardingAssistance == value) return;
    _boardingAssistance = value;
    await _prefs?.setBool(keyBoardingAssistance, value);
    notifyListeners();
  }

  /// Sets Quiet Routes preference.
  Future<void> setQuietRoutes(bool value) async {
    if (_quietRoutes == value) return;
    _quietRoutes = value;
    await _prefs?.setBool(keyQuietRoutes, value);
    notifyListeners();
  }

  /// Batch updates multiple preferences in a single pass and notifies listeners.
  Future<void> savePreferences({
    bool? isHighContrast,
    bool? isWheelchairOnly,
    bool? isStepFree,
    bool? hasLargeTargets,
    bool? minimizeWalking,
    bool? voiceGuidance,
    bool? hapticAlerts,
    bool? boardingAssistance,
    bool? quietRoutes,
  }) async {
    if (isHighContrast != null) _isHighContrast = isHighContrast;
    if (isWheelchairOnly != null) _isWheelchairOnly = isWheelchairOnly;
    if (isStepFree != null) _isStepFree = isStepFree;
    if (hasLargeTargets != null) _hasLargeTargets = hasLargeTargets;
    if (minimizeWalking != null) _minimizeWalking = minimizeWalking;
    if (voiceGuidance != null) _voiceGuidance = voiceGuidance;
    if (hapticAlerts != null) _hapticAlerts = hapticAlerts;
    if (boardingAssistance != null) _boardingAssistance = boardingAssistance;
    if (quietRoutes != null) _quietRoutes = quietRoutes;

    if (_prefs != null) {
      await Future.wait([
        if (isHighContrast != null) _prefs!.setBool(keyHighContrast, isHighContrast),
        if (isWheelchairOnly != null) _prefs!.setBool(keyWheelchairOnly, isWheelchairOnly),
        if (isStepFree != null) _prefs!.setBool(keyStepFree, isStepFree),
        if (hasLargeTargets != null) _prefs!.setBool(keyHasLargeTargets, hasLargeTargets),
        if (minimizeWalking != null) _prefs!.setBool(keyMinimizeWalking, minimizeWalking),
        if (voiceGuidance != null) _prefs!.setBool(keyVoiceGuidance, voiceGuidance),
        if (hapticAlerts != null) _prefs!.setBool(keyHapticAlerts, hapticAlerts),
        if (boardingAssistance != null) _prefs!.setBool(keyBoardingAssistance, boardingAssistance),
        if (quietRoutes != null) _prefs!.setBool(keyQuietRoutes, quietRoutes),
      ]);
    }

    notifyListeners();
  }

  /// Resets all preferences to default values.
  Future<void> resetToDefaults() async {
    await savePreferences(
      isHighContrast: false,
      isWheelchairOnly: true,
      isStepFree: false,
      hasLargeTargets: true,
      minimizeWalking: false,
      voiceGuidance: true,
      hapticAlerts: false,
      boardingAssistance: false,
      quietRoutes: false,
    );
  }
}
