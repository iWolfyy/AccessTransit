import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/localization_context.dart';
import '../../services/eta_evaluation_store.dart';
import '../../services/accessibility_preferences_service.dart';

class EtaDiagnosticsScreen extends StatefulWidget {
  const EtaDiagnosticsScreen({super.key, this.store});
  final EtaEvaluationStore? store;
  @override
  State<EtaDiagnosticsScreen> createState() => _EtaDiagnosticsScreenState();
}

class _EtaDiagnosticsScreenState extends State<EtaDiagnosticsScreen> {
  late final store = widget.store ?? EtaEvaluationStore.instance;
  @override
  void initState() {
    super.initState();
    AccessibilityPreferencesService.instance.addListener(accountChanged);
  }

  void accountChanged() {
    store.open(AccessibilityPreferencesService.instance.userId);
  }

  @override
  void dispose() {
    AccessibilityPreferencesService.instance.removeListener(accountChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.etaDiagnostics)),
    body: ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (!store.available || !store.ready || store.owner == null) {
          return Center(child: Text(context.l10n.etaDiagnosticsUnavailable));
        }
        final export = store.ledger.export(), counts = export['counts'] as Map;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(context.l10n.etaDiagnosticsHelp),
            SwitchListTile(
              title: Text(context.l10n.etaCapture),
              value: store.enabled,
              onChanged: store.setEnabled,
            ),
            Text(
              context.l10n.etaCounts(
                counts['captured'],
                counts['pending'],
                counts['excluded'],
              ),
            ),
            if (store.error != null) Text(context.l10n.etaStorageError),
            if ((export['summaries'] as List).isEmpty)
              Text(context.l10n.etaNoMatchedSamples),
            for (final group in export['summaries'] as List)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${group['source']} · ${group['routeId']} · ${group['leadBucket']}',
                      ),
                      Text(
                        '${group['algorithmVersion']} · ${group['geometryVersion'] ?? "—"}',
                      ),
                      Text(
                        context.l10n.etaMetrics(
                          group['count'],
                          (group['medianAbsoluteErrorSeconds'] as num)
                              .toStringAsFixed(1),
                          (group['p90AbsoluteErrorSeconds'] as num)
                              .toStringAsFixed(1),
                        ),
                      ),
                      if (group['smallSample'] == true)
                        Text(context.l10n.etaSmallSample),
                    ],
                  ),
                ),
              ),
            OutlinedButton(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: store.exportJson()),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.etaCopied)),
                  );
                }
              },
              child: Text(context.l10n.etaExport),
            ),
            TextButton(
              onPressed: store.clear,
              child: Text(context.l10n.etaClear),
            ),
          ],
        );
      },
    ),
  );
}
