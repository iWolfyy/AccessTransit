import 'package:flutter/material.dart';

import '../services/transit_catalogue.dart';
import '../services/firestore_service.dart';

class CatalogueNotice extends StatefulWidget {
  const CatalogueNotice({super.key, this.onRefresh});
  final Future<void> Function()? onRefresh;
  @override
  State<CatalogueNotice> createState() => _CatalogueNoticeState();
}

class _CatalogueNoticeState extends State<CatalogueNotice> {
  bool refreshing = false;
  Future<void> refresh() async {
    setState(() => refreshing = true);
    try {
      await (widget.onRefresh ?? FirestoreService().refreshCatalogue)();
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: TransitCatalogue.receipts,
    builder: (context, receipts, _) {
      final String? message;
      if (TransitCatalogue.demo) {
        message = 'DEMONSTRATION: Sample transit data. Shared reporting, assistance and journeys are disabled.';
      } else if (receipts.values.any(
        (receipt) => receipt.source == CatalogueSource.saved,
      )) {
        message = 'Saved transit data. Refresh to check for updates; timetables and availability may have changed.';
      } else if (receipts.values.any(
        (receipt) => receipt.source == CatalogueSource.unavailable,
      )) {
        message = 'Transit data unavailable. Connect and retry; no sample services are substituted.';
      } else if (receipts.isNotEmpty &&
          receipts.values.any((receipt) => receipt.count == 0)) {
        message = 'No shared transit data available for this catalogue. Please retry later.';
      } else {
        message = null;
      }
      if (message == null) return const SizedBox.shrink();
      return Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (!TransitCatalogue.demo)
                  TextButton(
                    onPressed: refreshing ? null : refresh,
                    child: Text(refreshing ? 'Refreshing…' : 'Refresh'),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
