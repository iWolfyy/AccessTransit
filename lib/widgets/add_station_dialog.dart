import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../models/bus.dart';
import '../models/station.dart';
import '../services/firestore_service.dart';

/// Admin/debug dialog to create a new station and insert it into a bus route's ordered stops.
class AddStationDialog extends StatefulWidget {
  const AddStationDialog({
    super.key,
    required this.buses,
    this.defaultBusId,
  });

  final List<Bus> buses;
  final String? defaultBusId;

  static Future<void> show(BuildContext context, {required List<Bus> buses, String? defaultBusId}) {
    return showDialog(
      context: context,
      builder: (_) => AddStationDialog(buses: buses, defaultBusId: defaultBusId),
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
    _selectedBusId = widget.defaultBusId ?? (widget.buses.isNotEmpty ? widget.buses.first.id : 'bus_138_outbound');
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
          SnackBar(content: Text('Station "$name" added and inserted into $_selectedBusId at index $insertIndex!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding station: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.add_location_alt, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Add New Halt / Station'),
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
                decoration: const InputDecoration(
                  labelText: 'Station Name',
                  hintText: 'e.g. Bambalapitiya Junction',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'Station ID (e.g. bambalapitiya_junc)',
                  hintText: 'st_bambalapitiya_junc',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: widget.buses.any((b) => b.id == _selectedBusId) ? _selectedBusId : (widget.buses.isNotEmpty ? widget.buses.first.id : null),
                decoration: const InputDecoration(labelText: 'Target Bus Route'),
                items: widget.buses.map((b) {
                  return DropdownMenuItem(value: b.id, child: Text('Bus ${b.routeNo} (${b.id})'));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBusId = val);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _indexController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Insert Position Index (0-based)',
                  hintText: '1 (insert as 2nd stop)',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text('Ramp', style: TextStyle(fontSize: 12)),
                      value: _hasRamp,
                      onChanged: (v) => setState(() => _hasRamp = v ?? true),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text('Elevator', style: TextStyle(fontSize: 12)),
                      value: _hasElevator,
                      onChanged: (v) => setState(() => _hasElevator = v ?? false),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
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
            minimumSize: Size(context.hasLargeTargets ? 88 : 64, context.buttonHeight),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(fontSize: context.buttonFontSize),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: Size(context.hasLargeTargets ? 100 : 80, context.buttonHeight),
          ),
          onPressed: _isSaving ? null : _submit,
          child: Text(
            _isSaving ? 'Saving...' : 'Add Station',
            style: TextStyle(fontSize: context.buttonFontSize),
          ),
        ),
      ],
    );
  }
}
