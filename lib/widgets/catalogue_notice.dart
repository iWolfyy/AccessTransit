import 'package:flutter/material.dart';

import '../l10n/shared_presentation.dart';
import '../l10n/localization_context.dart';

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
  bool failed = false;
  Future<void> refresh() async {
    if (refreshing) return;
    setState(() {
      refreshing = true;
      failed = false;
    });
    try {
      await (widget.onRefresh ?? FirestoreService().refreshCatalogue)();
    } catch (_) {
      if (mounted) setState(() => failed = true);
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
      if (message == null && !failed) return const SizedBox.shrink();
      return Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: SafeArea(
          bottom: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .35,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (message != null)
                      Text(
                        context.sharedText(message),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    if (failed) Text(context.l10n.sharedCatalogueRefreshError),
                    if (!TransitCatalogue.demo)
                      TextButton(
                        onPressed: refreshing ? null : refresh,
                        child: Text(
                          context.sharedText(
                            refreshing ? 'Refreshing…' : 'Refresh',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
