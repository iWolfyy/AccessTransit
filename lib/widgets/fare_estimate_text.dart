import 'package:flutter/material.dart';

import '../logic/journey_fare.dart';

/// The visible amount always identifies its estimate/unknown status.
class FareEstimateText extends StatelessWidget {
  const FareEstimateText({super.key, required this.amount, this.style});
  final int? amount;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: JourneyFare.disclosure,
    child: Text(
      JourneyFare.label(amount),
      style: style,
      semanticsLabel: '${JourneyFare.label(amount)}. ${JourneyFare.disclosure}',
    ),
  );
}
