import '../l10n/localization_context.dart';

import 'package:flutter/material.dart';

import '../models/bus.dart';

class PublishedTimetableNotice extends StatelessWidget {
  const PublishedTimetableNotice({super.key, required this.bus});
  final Bus bus;
  @override
  Widget build(BuildContext context) {
    if (!bus.isPublishedTimetable) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.timetableUnassigned,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(context.l10n.timetableUnknownDisclosure),
          if (bus.sourceUrl?.isNotEmpty == true)
            Text(
              context.l10n.timetableSource(bus.sourceUrl!),
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
    );
  }
}
