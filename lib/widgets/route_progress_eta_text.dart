import 'package:flutter/material.dart';

import '../l10n/localization_context.dart';
import '../logic/route_geometry.dart';
import '../logic/transit_time.dart';

class RouteProgressEtaText extends StatelessWidget {
  const RouteProgressEtaText({
    super.key,
    required this.estimate,
    required this.target,
  });
  final RouteProgressEstimate estimate;
  final String target;
  @override
  Widget build(BuildContext context) {
    String time(DateTime at) =>
        TimeOfDay.fromDateTime(TransitTime.civil(at)).format(context);
    return Text(
      context.l10n.geometryEta(
        target,
        time(estimate.earliest),
        time(estimate.latest),
      ),
      semanticsLabel:
          '${context.l10n.geometryEta(target, time(estimate.earliest), time(estimate.latest))} · ${estimate.geometryVersion}',
    );
  }
}
