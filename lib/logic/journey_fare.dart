/// Prototype planning model, not an official fare-stage or operator tariff.
abstract final class JourneyFare {
  static const source = 'Prototype duration/stop model';
  static const disclosure =
      'Prototype duration/stop model, not an official fare. Service class, fare stages and concessions are not included. Confirm the actual fare with the operator.';
  static int estimate({
    required int durationMinutes,
    required int intermediateStops,
  }) {
    if (durationMinutes < 0 || intermediateStops < 0) return 0;
    final price = 35 + durationMinutes * 2.2 + intermediateStops * 4;
    return ((price / 5).round() * 5).clamp(40, 450);
  }

  static String label(int? amount) =>
      amount != null && amount > 0 ? 'Est. LKR $amount' : 'Fare unknown';
}
