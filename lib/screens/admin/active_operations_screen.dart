import 'admin_scaffold.dart';
import '../../l10n/moderation_presentation.dart';

import 'dart:math';

import 'package:flutter/material.dart';

import '../../l10n/localization_context.dart';
import '../../services/moderation_client.dart';

class ActiveOperationsScreen extends StatefulWidget {
  const ActiveOperationsScreen({super.key, this.client});
  final ModerationClient? client;
  @override
  State<ActiveOperationsScreen> createState() => _ActiveOperationsScreenState();
}

class _ActiveOperationsScreenState extends State<ActiveOperationsScreen> {
  late final client = widget.client ?? ModerationClient();
  final reason = TextEditingController();
  List<Map<String, dynamic>> items = [], candidates = [];
  Map<String, dynamic>? detail;
  String? next, candidateNext, selected, error, operationId;
  bool loading = true, busy = false, acknowledged = false;
  int generation = 0;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    generation++;
    reason.dispose();
    if (widget.client == null) client.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> rows(Map<String, dynamic> value) {
    if (value['items'] is! List ||
        (value['next'] != null && value['next'] is! String)) {
      throw const ModerationException('invalid-response');
    }
    return (value['items'] as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
  }

  Future<void> load({bool more = false}) async {
    final version = ++generation;
    setState(() {
      loading = true;
      error = null;
      detail = null;
      acknowledged = false;
    });
    try {
      final result = await client.operations(after: more ? next : null);
      final values = rows(result);
      if (values.any(
        (v) =>
            v['runId'] is! String ||
            v['busId'] is! String ||
            v['driverId'] is! String,
      )) {
        throw const ModerationException('invalid-response');
      }
      if (!mounted || version != generation) return;
      setState(() {
        items = more ? [...items, ...values] : values;
        next = result['next'];
        loading = false;
      });
    } catch (e) {
      if (mounted && version == generation) {
        setState(() {
          loading = false;
          error = e is ModerationException ? e.code : 'unavailable';
        });
      }
    }
  }

  Future<void> open(String runId) async {
    final version = ++generation;
    setState(() {
      loading = true;
      error = null;
      detail = null;
      selected = null;
      operationId = null;
      acknowledged = false;
      reason.clear();
    });
    try {
      final data = await client.operationDetail(runId);
      final result = await client.operationCandidates(runId);
      final values = rows(result);
      if (data['runId'] != runId ||
          data['handoverVersion'] is! int ||
          data['driverId'] is! String ||
          data['currentStopIndex'] is! int ||
          values.any((v) => v['driverId'] is! String || v['name'] is! String)) {
        throw const ModerationException('invalid-response');
      }
      if (!mounted || version != generation) return;
      setState(() {
        detail = data;
        candidates = values;
        candidateNext = result['next'];
        loading = false;
      });
    } catch (e) {
      if (mounted && version == generation) {
        setState(() {
          loading = false;
          error = e is ModerationException ? e.code : 'unavailable';
        });
      }
    }
  }

  Future<void> moreCandidates() async {
    final version = generation;
    setState(() => busy = true);
    try {
      final result = await client.operationCandidates(
        detail!['runId'],
        after: candidateNext,
      );
      final values = rows(result);
      if (values.any((v) => v['driverId'] is! String || v['name'] is! String)) {
        throw const ModerationException('invalid-response');
      }
      if (mounted && version == generation) {
        setState(() {
          candidates.addAll(values);
          candidateNext = result['next'];
        });
      }
    } catch (e) {
      if (mounted && version == generation) {
        setState(
          () => error = e is ModerationException ? e.code : 'unavailable',
        );
      }
    } finally {
      if (mounted && version == generation) setState(() => busy = false);
    }
  }

  Future<void> transfer() async {
    final current = detail;
    if (busy ||
        current == null ||
        selected == null ||
        reason.text.trim().length < 5) {
      return;
    }
    final version = generation;
    operationId ??= List.generate(
      24,
      (_) => Random.secure().nextInt(16).toRadixString(16),
    ).join();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await client.handoverOperation(
        operationId: operationId!,
        runId: current['runId'],
        newDriverId: selected!,
        expectedDriverId: current['driverId'],
        expectedVersion: current['handoverVersion'],
        reason: reason.text.trim(),
      );
      if (mounted && version == generation) setState(() => acknowledged = true);
    } on ModerationException catch (e) {
      if (mounted && version == generation) setState(() => error = e.code);
    } catch (e) {
      if (mounted && version == generation) {
        setState(
          () => error = e is ModerationException ? e.code : 'unavailable',
        );
      }
    } finally {
      if (mounted && version == generation) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AdminScaffold(
      appBar: AppBar(title: Text(l.operationsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (loading) const Center(child: CircularProgressIndicator()),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                error == 'operation-stale' || error == 'driver-ineligible'
                    ? l.operationsStale
                    : context.reviewFailure(error) ?? l.operationsError,
              ),
            ),
          if (!loading && detail == null) ...[
            OutlinedButton(
              onPressed: () => load(),
              child: Text(l.operationsRefresh),
            ),
            if (items.isEmpty && error == null) Text(l.operationsEmpty),
            for (final item in items)
              Card(
                child: ListTile(
                  title: Text('${item['routeNo']} · ${item['busId']}'),
                  subtitle: Text(
                    l.reviewRunDriver(item['runId'], item['driverId']),
                  ),
                  isThreeLine: true,
                  onTap: () => open(item['runId']),
                ),
              ),
            if (next != null)
              TextButton(
                onPressed: () => load(more: true),
                child: Text(l.operationsMore),
              ),
          ],
          if (!loading && detail != null) ...[
            Text(
              '${detail!['routeNo']} · ${detail!['busId']}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l.reviewRunDriver(detail!['runId'], detail!['driverId'])),
            const SizedBox(height: 16),
            Text(acknowledged ? l.operationsDone : l.operationsExplanation),
            if (!acknowledged) ...[
              RadioGroup<String>(
                groupValue: selected,
                onChanged: (v) {
                  // Keep a failed request immutable until its outcome is resolved.
                  if (!busy && operationId == null) {
                    setState(() => selected = v);
                  }
                },
                child: Column(
                  children: [
                    for (final driver in candidates)
                      RadioListTile<String>(
                        title: Text(driver['name']),
                        subtitle: Text(l.reviewDriverId(driver['driverId'])),
                        value: driver['driverId'],
                        enabled: !busy && operationId == null,
                      ),
                  ],
                ),
              ),
              if (candidates.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(l.operationsNoDrivers),
                ),
              if (candidateNext != null)
                TextButton(
                  onPressed: busy ? null : moreCandidates,
                  child: Text(l.operationsMore),
                ),
              TextField(
                controller: reason,
                readOnly: busy || operationId != null,
                maxLength: 2000,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(labelText: l.operationsReason),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed:
                    busy || selected == null || reason.text.trim().length < 5
                    ? null
                    : transfer,
                child: Text(busy ? l.operationsSaving : l.operationsTransfer),
              ),
            ],
            TextButton(
              onPressed: busy ? null : () => load(),
              child: Text(l.operationsRefresh),
            ),
          ],
        ],
      ),
    );
  }
}
