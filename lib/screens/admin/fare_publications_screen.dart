import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../services/fare_catalogue.dart';
import '../../l10n/localization_context.dart';

class FarePublicationsScreen extends StatefulWidget {
  const FarePublicationsScreen({super.key, required this.repository});
  final AdminRepository repository;
  @override
  State<FarePublicationsScreen> createState() => _FarePublicationsScreenState();
}

class _FarePublicationsScreenState extends State<FarePublicationsScreen> {
  final id = TextEditingController(),
      json = TextEditingController(),
      reason = TextEditingController();
  final rows = <AdminRecord>[];
  FarePublication? preview;
  String? next, error;
  bool loading = true, busy = false, reviewed = false;
  int epoch = 0;
  late final service = AdminFareService(widget.repository);
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    epoch++;
    id.dispose();
    json.dispose();
    reason.dispose();
    super.dispose();
  }

  Future<void> load({bool more = false}) async {
    final version = ++epoch;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await widget.repository.page(
        'fare_publications',
        after: more ? next : null,
      );
      if (!mounted || version != epoch) return;
      setState(() {
        if (!more) rows.clear();
        rows.addAll(result.items);
        next = result.next;
      });
    } catch (_) {
      if (mounted && version == epoch) setState(() => error = 'load');
    } finally {
      if (mounted && version == epoch) setState(() => loading = false);
    }
  }

  void validate() {
    try {
      final value = jsonDecode(json.text);
      if (value is! Map<String, dynamic>) throw const FormatException();
      final candidate = FarePublication.parse(id.text.trim(), value);
      setState(() {
        preview = candidate;
        reviewed = false;
        error = null;
      });
    } catch (_) {
      setState(() {
        preview = null;
        error = 'invalid';
      });
    }
  }

  Future<void> publish() async {
    final value = preview;
    if (value == null || !reviewed || reason.text.trim().length < 10 || busy) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await service.publish(value, reason.text);
      if (!mounted) return;
      setState(() {
        preview = null;
        reviewed = false;
        id.clear();
        json.clear();
        reason.clear();
      });
      await load();
    } catch (_) {
      if (mounted) setState(() => error = 'save');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> archive(AdminRecord record) async {
    final input = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(c.l10n.fareArchive),
        content: TextField(
          controller: input,
          maxLength: 2000,
          decoration: InputDecoration(labelText: c.l10n.fareReviewReason),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(c.l10n.fareCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, input.text),
            child: Text(c.l10n.fareArchive),
          ),
        ],
      ),
    );
    Future<void>.delayed(const Duration(seconds: 1), input.dispose);
    if (!mounted || text == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await service.archive(record, text);
      if (mounted) await load();
    } catch (_) {
      if (mounted) setState(() => error = 'save');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext c) {
    final l = c.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.fareAdminTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.fareImportHelp),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('fare-id'),
            controller: id,
            enabled: !busy,
            maxLength: 128,
            decoration: InputDecoration(labelText: l.farePublicationId),
            onChanged: (_) => setState(() => preview = null),
          ),
          TextField(
            key: const ValueKey('fare-json'),
            controller: json,
            enabled: !busy,
            minLines: 4,
            maxLines: 12,
            maxLength: 120000,
            decoration: InputDecoration(labelText: l.fareImportJson),
            onChanged: (_) => setState(() => preview = null),
          ),
          OutlinedButton(
            onPressed: busy ? null : validate,
            child: Text(l.farePreview),
          ),
          if (preview != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${preview!.table.routePatternId} · ${preview!.table.serviceClass}',
                    ),
                    Text(
                      '${preview!.mapping.effectiveFrom} – ${preview!.mapping.effectiveUntil}',
                    ),
                    Text(preview!.table.source.toString()),
                    Text(
                      '${preview!.table.version} / ${preview!.mapping.version}',
                    ),
                    Text(preview!.busIds.join(', ')),
                    for (final row in preview!.table.amounts.entries)
                      for (final cell in row.value.entries)
                        Text(
                          '${row.key} → ${cell.key}: LKR ${cell.value ~/ 100}.${(cell.value % 100).toString().padLeft(2, '0')}',
                        ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.fareReviewCheck),
                      value: reviewed,
                      onChanged: busy
                          ? null
                          : (v) => setState(() => reviewed = v ?? false),
                    ),
                  ],
                ),
              ),
            ),
          TextField(
            key: const ValueKey('fare-reason'),
            controller: reason,
            enabled: !busy,
            minLines: 2,
            maxLines: 4,
            maxLength: 2000,
            decoration: InputDecoration(labelText: l.fareReviewReason),
            onChanged: (_) => setState(() {}),
          ),
          FilledButton(
            onPressed:
                busy ||
                    preview == null ||
                    !reviewed ||
                    reason.text.trim().length < 10
                ? null
                : publish,
            child: Text(l.farePublish),
          ),
          if (error != null)
            Text(error == 'invalid' ? l.fareInvalidImport : l.fareAdminError),
          if (loading || busy) const Center(child: CircularProgressIndicator()),
          TextButton(
            onPressed: busy ? null : () => load(),
            child: Text(l.operationsRefresh),
          ),
          if (!loading && rows.isEmpty) Text(l.fareNoPublications),
          for (final row in rows)
            Card(
              child: ListTile(
                title: Text(row.id),
                subtitle: Text(
                  '${row.text('state')} · ${(row.data['table'] as Map?)?['version'] ?? ''}',
                ),
                trailing: row.text('state') == 'published'
                    ? IconButton(
                        tooltip: l.fareArchive,
                        onPressed: busy ? null : () => archive(row),
                        icon: const Icon(Icons.archive_outlined),
                      )
                    : null,
              ),
            ),
          if (next != null)
            TextButton(
              onPressed: busy ? null : () => load(more: true),
              child: Text(l.operationsMore),
            ),
        ],
      ),
    );
  }
}
