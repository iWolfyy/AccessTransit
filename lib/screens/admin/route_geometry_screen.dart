import 'dart:convert';

import 'package:flutter/material.dart';

import '../../l10n/localization_context.dart';
import '../../logic/route_geometry.dart';
import '../../services/admin_service.dart';
import '../../services/route_geometry_service.dart';

class RouteGeometryScreen extends StatefulWidget {
  const RouteGeometryScreen({super.key, required this.repository});
  final AdminRepository repository;
  @override
  State<RouteGeometryScreen> createState() => _RouteGeometryScreenState();
}

class _RouteGeometryScreenState extends State<RouteGeometryScreen> {
  final route = TextEditingController(),
      json = TextEditingController(),
      reason = TextEditingController();
  ReviewedRouteGeometry? preview;
  bool reviewed = false, busy = false;
  String? error;
  @override
  void dispose() {
    route.dispose();
    json.dispose();
    reason.dispose();
    super.dispose();
  }

  void validate() {
    try {
      if (utf8.encode(json.text).length > 300000) throw const FormatException();
      final value = ReviewedRouteGeometry.parse(
        route.text.trim(),
        Map<String, dynamic>.from(jsonDecode(json.text)),
      );
      setState(() {
        preview = value;
        reviewed = false;
        error = null;
      });
    } catch (_) {
      setState(() {
        preview = null;
        error = context.l10n.geometryInvalid;
      });
    }
  }

  Future<void> publish() async {
    if (preview == null ||
        !reviewed ||
        busy ||
        reason.text.trim().length < 10) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await AdminRouteGeometryService(widget.repository)
          .publish(preview!, reason.text);
      if (!mounted) return;
      setState(() {
        preview = null;
        json.clear();
        reason.clear();
        reviewed = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.geometrySaved)));
    } catch (_) {
      if (mounted) setState(() => error = context.l10n.fareAdminError);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.geometryTitle)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(context.l10n.geometryHelp),
        TextField(
          key: const ValueKey('geometry-route'),
          controller: route,
          enabled: !busy,
          maxLength: 128,
          decoration: const InputDecoration(labelText: 'Route ID'),
          onChanged: (_) => setState(() => preview = null),
        ),
        TextField(
          key: const ValueKey('geometry-json'),
          controller: json,
          enabled: !busy,
          minLines: 4,
          maxLines: 10,
          maxLength: 300000,
          decoration: InputDecoration(labelText: context.l10n.fareImportJson),
          onChanged: (_) => setState(() => preview = null),
        ),
        OutlinedButton(
          onPressed: busy ? null : validate,
          child: Text(context.l10n.farePreview),
        ),
        if (preview != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${preview!.routeId} · ${preview!.version}'),
                  Text(preview!.source),
                  Text(
                    '${preview!.stops.join(' → ')} · ${(preview!.distances.last / 1000).toStringAsFixed(2)} km',
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: reviewed,
                    title: Text(context.l10n.geometryReview),
                    onChanged: busy
                        ? null
                        : (v) => setState(() => reviewed = v ?? false),
                  ),
                ],
              ),
            ),
          ),
        TextField(
          key: const ValueKey('geometry-reason'),
          controller: reason,
          enabled: !busy,
          maxLength: 2000,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(labelText: context.l10n.fareReviewReason),
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
          child: Text(context.l10n.farePublish),
        ),
        TextButton(
          onPressed:
              busy ||
                  route.text.trim().isEmpty ||
                  reason.text.trim().length < 10
              ? null
              : () async {
                  setState(() {
                    busy = true;
                    error = null;
                  });
                  try {
                    await AdminRouteGeometryService(widget.repository)
                        .withdraw(route.text.trim(), reason.text);
                    if (mounted && context.mounted) {
                      setState(() {
                        preview = null;
                        reviewed = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.l10n.geometryWithdrawn)),
                      );
                    }
                  } catch (_) {
                    if (mounted) {
                      setState(() => error = context.l10n.fareAdminError);
                    }
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
          child: Text(context.l10n.geometryWithdraw),
        ),
        if (busy) const Center(child: CircularProgressIndicator()),
        if (error != null) Text(error!),
      ],
    ),
  );
}
