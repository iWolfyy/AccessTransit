import 'package:flutter/foundation.dart';

import '../services/accessibility_preferences_service.dart';
import 'transit_time.dart';

/// An account's defaults and the independent overrides for one search.
/// This object never writes preferences or saved journeys.
class SearchNeedsDraft extends ChangeNotifier {
  SearchNeedsDraft(this.preferences) {
    _owner = preferences.userId;
    preferences.addListener(_changed);
  }

  final AccessibilityPreferencesService preferences;
  String? _owner;
  int _accountRevision = 0;
  bool? _wheelchair;
  bool? _stepFree;

  int get accountRevision => _accountRevision;
  bool get isReady => preferences.isInitialized;
  bool get wheelchair => _wheelchair ?? preferences.isWheelchairOnly;
  bool get stepFree => _stepFree ?? preferences.isStepFree;
  bool get hasOverrides => _wheelchair != null || _stepFree != null;

  void setWheelchair(bool value) {
    _wheelchair = value;
    notifyListeners();
  }

  void setStepFree(bool value) {
    _stepFree = value;
    notifyListeners();
  }

  void reset() {
    _wheelchair = null;
    _stepFree = null;
    notifyListeners();
  }

  void _changed() {
    if (_owner != preferences.userId) {
      _owner = preferences.userId;
      _accountRevision++;
      _wheelchair = null;
      _stepFree = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    preferences.removeListener(_changed);
    super.dispose();
  }
}

/// The boarding window, rather than the destination arrival window.
/// Callers must use a consistent clock/time zone for all supplied values.
class BoardingSearchWindow {
  BoardingSearchWindow(this.now)
    : end = now.add(const Duration(hours: 24)),
      _colombo = false;
  BoardingSearchWindow.colombo(this.now, {DateTime? end})
    : end = end ?? now.add(const Duration(hours: 24)),
      _colombo = true;
  final bool _colombo;

  final DateTime now;
  final DateTime end;

  bool contains(DateTime boarding) =>
      !boarding.isBefore(now) && !boarding.isAfter(end);

  DateTime? lowerBound({DateTime? date, int? minutes}) {
    if (minutes != null && (minutes < 0 || minutes >= 1440)) return null;
    if (date == null && minutes == null) return now;
    final day = date ?? (_colombo ? TransitTime.civil(now) : now);
    final civil = DateTime.utc(
      day.year,
      day.month,
      day.day,
      (minutes ?? 0) ~/ 60,
      (minutes ?? 0) % 60,
    );
    final selected = _colombo
        ? TransitTime.instant(civil)
        : DateTime(
            day.year,
            day.month,
            day.day,
            (minutes ?? 0) ~/ 60,
            (minutes ?? 0) % 60,
          );
    // Date-only means first available service on that date, including today.
    if (minutes == null) {
      final endOfDay = _colombo
          ? TransitTime.instant(DateTime.utc(day.year, day.month, day.day + 1))
          : DateTime(day.year, day.month, day.day + 1);
      if (!endOfDay.isAfter(now) || selected.isAfter(end)) return null;
      return selected.isBefore(now) ? now : selected;
    }
    return contains(selected) ? selected : null;
  }
}
