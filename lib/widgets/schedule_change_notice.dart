import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/localization_context.dart';
import '../logic/transit_time.dart';
import '../models/journey_model.dart';
import '../models/service_run.dart';

String scheduleTime(BuildContext context, DateTime instant) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .add_jm()
        .format(TransitTime.civil(instant));

class ScheduleChangeNotice extends StatelessWidget {
  const ScheduleChangeNotice({
    super.key,
    this.saved,
    required this.run,
    this.unavailable = false,
  });
  final JourneyModel? saved;
  final ServiceRun? run;
  final bool unavailable;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = run;
    final changed =
        saved != null &&
        r != null &&
        (r.stopTimes[saved!.fromStationId] != saved!.departureAt?.toUtc() ||
            r.stopTimes[saved!.toStationId] !=
                saved!.departureAt
                    ?.add(Duration(minutes: saved!.durationMinutes ?? 0))
                    .toUtc() ||
            (saved!.scheduleSnapshot?.runVersion != null &&
                saved!.scheduleSnapshot!.runVersion != r.scheduleVersion));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (unavailable) Text(l.scheduleStatusUnavailable),
        if (r?.status == 'cancelled') Text(l.scheduleCancelled),
        if (changed) Text(l.scheduleChanged),
        if (r?.replacementRunId != null)
          Text(
            r!.replacementDepartureAt == null
                ? l.scheduleReplacement
                : l.scheduleReplacementAt(
                    scheduleTime(context, r.replacementDepartureAt!),
                  ),
          ),
        if (r?.changeReason?.trim().isNotEmpty == true) Text(r!.changeReason!),
      ],
    );
  }
}
