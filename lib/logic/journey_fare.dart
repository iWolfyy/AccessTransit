import 'package:flutter/foundation.dart';

/// The legacy prototype is limited to explicitly identified synthetic builds.
abstract final class JourneyFare {
  static const prototypeEnabled =
      kDebugMode &&
      (bool.fromEnvironment('LOCAL_VALIDATION') ||
          bool.fromEnvironment('SAMPLE_TEST') ||
          bool.fromEnvironment('TRANSIT_DEMO'));
  static const source = prototypeEnabled
      ? 'Sample prototype duration/stop model'
      : 'No reviewed tariff mapping';
  static const disclosure = prototypeEnabled
      ? 'Sample/Test estimate only. This duration/stop model is not an official fare. Confirm the actual fare with the operator.'
      : 'A reviewed tariff and fare-stage mapping are not available for this selection. Confirm the fare with the operator.';
  static int estimate({
    required int durationMinutes,
    required int intermediateStops,
  }) {
    if (!prototypeEnabled || durationMinutes < 0 || intermediateStops < 0) {
      return 0;
    }
    final price = 35 + durationMinutes * 2.2 + intermediateStops * 4;
    return ((price / 5).round() * 5).clamp(40, 450);
  }

  static String label(int? amount) =>
      prototypeEnabled && amount != null && amount > 0
      ? 'Sample est. LKR $amount'
      : 'Fare unavailable';
}
