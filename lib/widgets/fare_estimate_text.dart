import 'package:flutter/material.dart';

import '../logic/journey_fare.dart';
import '../l10n/localization_context.dart';
import '../logic/tariff_fare.dart';

String fareDisclosure(BuildContext context, [TariffFareQuote? quote]) =>
    quote != null
    ? context.l10n.fareReviewedSource(
        quote.source.toString(),
        quote.tariffVersion,
        quote.mappingVersion,
      )
    : JourneyFare.prototypeEnabled
    ? context.l10n.fareSampleDisclosure
    : context.l10n.fareUnavailableDisclosure;

class FareDisclosureText extends StatelessWidget {
  const FareDisclosureText({super.key, this.style, this.quote});
  final TextStyle? style;
  final TariffFareQuote? quote;
  @override
  Widget build(BuildContext context) =>
      Text(fareDisclosure(context, quote), style: style);
}

/// The visible amount always identifies its estimate/unknown status.
class FareEstimateText extends StatelessWidget {
  const FareEstimateText({
    super.key,
    required this.amount,
    this.style,
    this.quote,
  });
  final int? amount;
  final TextStyle? style;
  final TariffFareQuote? quote;
  @override
  Widget build(BuildContext context) {
    final reviewed = quote;
    final value = reviewed == null
        ? ''
        : '${reviewed.amountMinor ~/ 100}.${(reviewed.amountMinor % 100).toString().padLeft(2, '0')}';
    final label = reviewed != null
        ? (JourneyFare.prototypeEnabled
              ? context.l10n.fareSampleReviewed(value)
              : context.l10n.fareReviewedAmount(value))
        : JourneyFare.prototypeEnabled && amount != null && amount! > 0
        ? context.l10n.fareSampleAmount(amount!)
        : context.l10n.fareUnavailable;
    return Tooltip(
      message: fareDisclosure(context, quote),
      child: Text(
        label,
        style: style,
        semanticsLabel: '$label. ${fareDisclosure(context, quote)}',
      ),
    );
  }
}
