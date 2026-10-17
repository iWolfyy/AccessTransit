import 'admin_scaffold.dart';

import 'package:intl/intl.dart';

import '../../l10n/admin_catalogue_labels.dart';

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
  Object? failure;
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
      failure = null;
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
    } catch (e) {
      if (mounted && version == epoch) {
        setState(() {
          error = 'load';
          failure = e;
        });
      }
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
        failure = null;
      });
    } catch (e) {
      setState(() {
        preview = null;
        error = 'invalid';
        failure = e;
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
      failure = null;
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
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'save';
          failure = e;
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> archive(AdminRecord record) async {
    final input = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (c) => AdminDialog(
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
      failure = null;
    });
    try {
      await service.archive(record, text);
      if (mounted) await load();
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'save';
          failure = e;
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _day(BuildContext c, String value) =>
      MaterialLocalizations.of(c).formatMediumDate(DateTime.parse(value));
  @override
  Widget build(BuildContext c) {
    final l = c.l10n;
    return AdminScaffold(
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
                      l.adminFarePreviewRoute(
                        preview!.table.routePatternId,
                        preview!.table.serviceClass,
                      ),
                    ),
                    Text(
                      l.adminFarePreviewDates(
                        _day(c, preview!.mapping.effectiveFrom),
                        _day(c, preview!.mapping.effectiveUntil),
                      ),
                    ),
                    Text(l.adminImportSource(preview!.table.source.toString())),
                    Text(
                      l.adminFareVersions(
                        preview!.table.version,
                        preview!.mapping.version,
                      ),
                    ),
                    Text(l.adminFareBuses(preview!.busIds.join(', '))),
                    for (final row in preview!.table.amounts.entries)
                      for (final cell in row.value.entries)
                        Text(
                          l.adminFareCell(
                            row.key,
                            cell.key,
                            NumberFormat.currency(
                              locale: Localizations.localeOf(c).toString(),
                              name: 'LKR',
                              symbol: 'LKR ',
                              decimalDigits: 2,
                            ).format(cell.value / 100),
                          ),
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
            Text(
              error == 'invalid'
                  ? l.fareInvalidImport
                  : error == 'load'
                  ? l.adminFareLoadFailed
                  : l.fareAdminError,
            ),
          if (error != null && c.adminImportFailure(failure) != null)
            Text(c.adminImportFailure(failure)!),
          if (loading || busy) const Center(child: CircularProgressIndicator()),
          TextButton(
            onPressed: busy ? null : () => load(),
            child: Text(l.operationsRefresh),
          ),
          if (!loading && error == null && rows.isEmpty)
            Text(l.fareNoPublications),
          for (final row in rows)
            Card(
              child: ListTile(
                title: Text(row.id),
                subtitle: Text(
                  l.adminFareRowStatus(
                    c.adminFareState(row.text('state')),
                    ((row.data['table'] as Map?)?['version'] ?? '').toString(),
                  ),
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
