/// Meaning of a condition observation, independent of its severity/category.
enum ReportCondition {
  positive,
  barrier,
  unknown;

  static ReportCondition fromOptionId(String id) {
    if (const {
      'ramp_working',
      'seats_available',
      'clean_vehicle',
      'elevator_ok',
      'ramp_ok',
      'tactile_ok',
      'shelter_ok',
    }.contains(id)) {
      return positive;
    }
    if (const {
      'ramp_broken',
      'driver_refused',
      'bay_blocked',
      'seats_occupied',
      'seat_broken',
      'dirty_vehicle',
      'broken_grab_rail',
      'reckless_driving',
      'elevator_out',
      'elevator_doors',
      'ramp_blocked',
      'ramp_damaged',
      'tactile_missing',
      'unsafe_gap',
      'shelter_broken',
      'poor_lighting',
    }.contains(id)) {
      return barrier;
    }
    return unknown;
  }

  /// Compatibility for older reports; positive text must match a known option.
  static ReportCondition fromLegacyText(String text) {
    final normalized = text.trim().toLowerCase();
    if (const {
      'ramp working',
      'seats free',
      'clean & safe',
      'elevator working',
      'ramp clear',
      'tiles intact',
      'shelter good',
    }.contains(normalized)) {
      return positive;
    }
    if (RegExp(
      r'out of service|not working|power failure|\b(broken|blocked|denied|occupied|dirty|odor|reckless|fault|damaged|steep|unsafe|jammed|hazard|crowding|crowded|packed)\b',
    ).hasMatch(normalized)) {
      return barrier;
    }
    return unknown;
  }
}
