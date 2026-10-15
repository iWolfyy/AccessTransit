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
          const Text(
            'Published timetable • vehicle unassigned',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            'Times may change. Vehicle registration, accessibility and live location are unknown. Driver assistance is unavailable until an authorized vehicle is connected.',
          ),
          if (bus.sourceUrl?.isNotEmpty == true)
            Text(
              'Source: ${bus.sourceUrl}',
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
    );
  }
}
