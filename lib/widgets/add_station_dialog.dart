import 'accessible_dropdown.dart';

import 'package:flutter/material.dart';

import '../l10n/localization_context.dart';
import '../core/theme/app_theme.dart';
import '../models/bus.dart';
import '../models/station.dart';
import '../services/firestore_service.dart';

/// Admin/debug dialog to create a new station and insert it into a bus route's ordered stops.
class AddStationDialog extends StatefulWidget {
  const AddStationDialog({super.key, required this.buses, this.defaultBusId});

  final List<Bus> buses;
  final String? defaultBusId;

  static Future<void> show(
    BuildContext context, {
    required List<Bus> buses,
    String? defaultBusId,
  }) {
    return showDialog(
      context: context,
      builder: (_) =>
          AddStationDialog(buses: buses, defaultBusId: defaultBusId),
    );
  }

  @override
  State<AddStationDialog> createState() => _AddStationDialogState();
}

class _AddStationDialogState extends State<AddStationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _latController = TextEditingController(text: '6.9200');
  final _lngController = TextEditingController(text: '79.8600');
  final _indexController = TextEditingController(text: '1');

  bool _hasRamp = true;
  bool _hasElevator = false;
  late String _selectedBusId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedBusId =
        widget.defaultBusId ??
        (widget.buses.isNotEmpty ? widget.buses.first.id : 'bus_138_outbound');
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _indexController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final id = _idController.text.trim().toLowerCase().replaceAll(' ', '_');
      final stationId = id.startsWith('st_') ? id : 'st_$id';
      final name = _nameController.text.trim();
      final lat = double.tryParse(_latController.text.trim()) ?? 6.9200;
      final lng = double.tryParse(_lngController.text.trim()) ?? 79.8600;
      final insertIndex = int.tryParse(_indexController.text.trim()) ?? 1;

      final newStation = Station(
        id: stationId,
        name: name,
        hasElevator: _hasElevator,
        hasRamp: _hasRamp,
        lat: lat,
        lng: lng,
      );

      await FirestoreService().addStationAndInsertIntoBusRoute(
        newStation: newStation,
        busId: _selectedBusId,
        insertIndex: insertIndex,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.sharedStationAdded(
                name,
                _selectedBusId,
                '$insertIndex',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.sharedStationError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.add_location_alt, color: context.primaryColor),
          SizedBox(width: 8),
          Expanded(child: Text(context.l10n.sharedAddStation)),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: context.l10n.sharedStationName,
                  hintText: context.l10n.sharedStationExample,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.l10n.sharedRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: context.l10n.sharedStationId,
                  hintText: 'st_bambalapitiya_junc',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.l10n.sharedRequired
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                itemHeight: null,
                initialValue: widget.buses.any((b) => b.id == _selectedBusId)
                    ? _selectedBusId
                    : (widget.buses.isNotEmpty ? widget.buses.first.id : null),
                decoration: InputDecoration(
                  labelText: context.l10n.sharedTargetRoute,
                ),
                items: widget.buses.map((b) {
                  return AccessibleDropdownMenuItem(
                    value: b.id,
                    child: Text(context.l10n.sharedBusOption(b.routeNo, b.id)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBusId = val);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _indexController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.l10n.sharedInsertIndex,
                  hintText: context.l10n.sharedInsertHint,
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  CheckboxListTile(
                    title: Text(context.l10n.sharedRamp),
                    value: _hasRamp,
                    onChanged: (v) => setState(() => _hasRamp = v ?? true),
                    dense: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: Text(context.l10n.sharedElevator),
                    value: _hasElevator,
                    onChanged: (v) => setState(() => _hasElevator = v ?? false),
                    dense: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: Size(
              context.hasLargeTargets ? 88 : 64,
              context.buttonHeight,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            context.l10n.sharedCancel,
            style: TextStyle(fontSize: context.buttonFontSize),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: Size(
              context.hasLargeTargets ? 100 : 80,
              context.buttonHeight,
            ),
          ),
          onPressed: _isSaving ? null : _submit,
          child: Text(
            _isSaving
                ? context.l10n.sharedSaving
                : context.l10n.sharedAddStationAction,
            style: TextStyle(fontSize: context.buttonFontSize),
          ),
        ),
      ],
    );
  }
}
