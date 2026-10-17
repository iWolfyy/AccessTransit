import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/time_utils.dart';
import '../../services/admin_service.dart';

class CatalogueEditorScreen extends StatefulWidget {
  const CatalogueEditorScreen({
    super.key,
    required this.service,
    required this.kind,
    this.original,
  });
  final AdminService service;
  final String kind;
  final AdminRecord? original;
  @override
  State<CatalogueEditorScreen> createState() => _CatalogueEditorScreenState();
}

class _CatalogueEditorScreenState extends State<CatalogueEditorScreen> {
  final _form = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _times = <String, TextEditingController>{};
  final _stops = <String>[];
  List<AdminRecord> _stations = [],
      _routes = [],
      _drivers = [],
      _assignments = [];
  List<AdminRecord> get _routeDrivers => _drivers
      .where(
        (d) => _assignments.any(
          (a) =>
              a.id == d.id &&
              a.data['active'] == true &&
              a.text('routeId') == _routeId,
        ),
      )
      .toList();
  bool _loading = true, _saving = false;
  String? _error, _routeId, _driverId;
  String _recordType = 'vehicle';
  bool? _ramp, _elevator, _lowFloor, _stepFree;
  bool _sourceReviewed = false;
  bool get _bus => widget.kind == 'buses';
  bool get _station => widget.kind == 'stations';
  Map<String, dynamic> get _original => widget.original?.data ?? {};
  TextEditingController _c(String name) => _controllers.putIfAbsent(
    name,
    () => TextEditingController(text: _original[name]?.toString() ?? ''),
  );
  @override
  void initState() {
    super.initState();
    _c('id').text = widget.original?.id ?? '';
    _stops.addAll(List<String>.from(_original['stops'] ?? []));
    _recordType = _original['catalogueRecordType']?.toString() ?? 'vehicle';
    _routeId = _original['routeId']?.toString();
    _driverId = _original['driverId']?.toString();
    _ramp = _original['hasRamp'] as bool?;
    _lowFloor = _original['lowFloor'] as bool?;
    _elevator = _original['hasElevator'] as bool?;
    _stepFree = _original['stepFreeAccess'] as bool?;
    final times = _original['scheduleTimes'] as List? ?? [];
    for (var i = 0; i < _stops.length; i++) {
      var value = i < times.length ? times[i].toString() : '';
      if (RegExp(
        r'^\d{1,2}:\d{2}\s*(AM|PM)$',
        caseSensitive: false,
      ).hasMatch(value)) {
        final parsed = TimeUtils.parseTimeStringToDateTime(
          value,
          DateTime(2026),
        );
        value =
            '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      }
      _times[_stops[i]] = TextEditingController(text: value);
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stations = await widget.service.repository.load('stations');
      final routes = _bus
          ? await widget.service.repository.load('routes')
          : <AdminRecord>[];
      final users = _bus
          ? await widget.service.repository.load('users')
          : <AdminRecord>[];
      final access = _bus
          ? await widget.service.repository.load('operator_access')
          : <AdminRecord>[];
      final assignments = _bus
          ? await widget.service.repository.load('driver_route_assignments')
          : <AdminRecord>[];
      if (!mounted) return;
      setState(() {
        _stations = stations;
        _routes = routes;
        _assignments = assignments;
        _drivers = users
            .where(
              (u) =>
                  u.text('role') == 'operator' &&
                  access.any((a) => a.id == u.id && a.data['approved'] == true),
            )
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not load server records. Check your connection/access and retry.';
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (final c in [..._controllers.values, ..._times.values]) {
      c.dispose();
    }
    super.dispose();
  }

  String _stopName(String id) =>
      _stations.where((s) => s.id == id).firstOrNull?.text('name') ??
      'Missing stop ($id)';
  Widget _field(
    String key,
    String label, {
    int lines = 1,
    String? hint,
    bool required = true,
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: _c(key),
      enabled: !_saving && (key != 'id' || widget.original == null),
      minLines: lines,
      maxLines: lines == 1 ? 1 : lines + 2,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, helperText: hint),
      validator: required
          ? (v) => v?.trim().isNotEmpty == true ? null : 'Required'
          : null,
    ),
  );
  Widget _assessment(
    String label,
    bool? value,
    ValueChanged<bool?> update, {
    bool capability = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<String>(
      initialValue: value == null
          ? 'unknown'
          : value
          ? 'yes'
          : 'no',
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem(
          value: 'unknown',
          child: Text('Unknown / not assessed'),
        ),
        DropdownMenuItem(
          value: 'yes',
          child: Text(capability ? 'Equipped' : 'Yes - assessed'),
        ),
        DropdownMenuItem(
          value: 'no',
          child: Text(capability ? 'Not equipped' : 'No - assessed'),
        ),
      ],
      onChanged: _saving
          ? null
          : (v) => setState(() => update(v == 'unknown' ? null : v == 'yes')),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final label = _station
        ? 'bus stop'
        : _bus
        ? 'bus / timetable'
        : 'route';
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        title: Text('${widget.original == null ? 'Add' : 'Edit'} $label'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  _field(
                    'id',
                    'Record ID',
                    hint:
                        'Stable identifier. Cannot be changed after creation.',
                  ),
                  if (_station) ...[
                    _field('name', 'Stop name'),
                    _field(
                      'lat',
                      'Latitude',
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                    _field(
                      'lng',
                      'Longitude',
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                    _assessment('Ramp capability', _ramp, (v) => _ramp = v),
                    _assessment(
                      'Elevator capability',
                      _elevator,
                      (v) => _elevator = v,
                    ),
                    _assessment(
                      'Assessed step-free path',
                      _stepFree,
                      (v) => _stepFree = v,
                      capability: false,
                    ),
                  ] else if (!_bus) ...[
                    _field('routeNo', 'Route number'),
                    _field('routeName', 'Route name'),
                    _field(
                      'description',
                      'Description',
                      lines: 2,
                      required: false,
                    ),
                  ] else ...[
                    DropdownButtonFormField<String>(
                      initialValue: _recordType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Catalogue record type',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'vehicle',
                          child: Text('Physical vehicle'),
                        ),
                        DropdownMenuItem(
                          value: 'published_timetable',
                          child: Text('Published timetable'),
                        ),
                      ],
                      onChanged: _saving
                          ? null
                          : (v) => setState(() {
                              _recordType = v!;
                              if (v == 'published_timetable') _driverId = '';
                            }),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _routes.any((r) => r.id == _routeId)
                          ? _routeId
                          : null,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Route'),
                      items: [
                        for (final route in _routes)
                          DropdownMenuItem(
                            value: route.id,
                            child: Text(
                              '${route.text('routeNo')} - ${route.text('routeName')}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: _saving
                          ? null
                          : (v) => setState(() {
                              _routeId = v;
                              _driverId = '';
                              _stops.clear();
                            }),
                      validator: (v) => v == null ? 'Choose a route' : null,
                    ),
                    const SizedBox(height: 16),
                    if (_recordType == 'vehicle') ...[
                      _field('busNo', 'Vehicle registration number'),
                      DropdownButtonFormField<String>(
                        key: ValueKey('driver-$_routeId'),
                        initialValue:
                            _routeDrivers.any((d) => d.id == _driverId)
                            ? _driverId
                            : '',
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Assigned driver',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Unassigned'),
                          ),
                          for (final driver in _routeDrivers)
                            DropdownMenuItem(
                              value: driver.id,
                              child: Text(
                                '${driver.text('name')} (${driver.text('email')})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: _saving ? null : (v) => _driverId = v,
                      ),
                      const SizedBox(height: 16),
                      if (_driverId?.isNotEmpty == true &&
                          !_routeDrivers.any((d) => d.id == _driverId))
                        const Text(
                          'Assign an approved driver to this route first, or release the previous assignment.',
                        ),
                      _assessment('Ramp capability', _ramp, (v) => _ramp = v),
                      _assessment(
                        'Low-floor capability',
                        _lowFloor,
                        (v) => _lowFloor = v,
                      ),
                      const Text(
                        'Capability is separate from a working-equipment observation. Operational checks are recorded by the assigned driver.',
                      ),
                    ] else
                      const Text(
                        'A published timetable has no verified physical vehicle, driver or equipment status.',
                      ),
                  ],
                  if (!_station) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Stops in travel order',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Text(
                      'Add each stop in sequence. Reordering a bus stop moves its scheduled time with it.',
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < _stops.length; i++)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '${i + 1}. ${_stopName(_stops[i])}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Wrap(
                                alignment: WrapAlignment.end,
                                children: [
                                  IconButton(
                                    tooltip: 'Move stop up',
                                    onPressed: _saving || i == 0
                                        ? null
                                        : () => setState(() {
                                            final value = _stops.removeAt(i);
                                            _stops.insert(i - 1, value);
                                          }),
                                    icon: const Icon(Icons.arrow_upward),
                                  ),
                                  IconButton(
                                    tooltip: 'Move stop down',
                                    onPressed: _saving || i == _stops.length - 1
                                        ? null
                                        : () => setState(() {
                                            final value = _stops.removeAt(i);
                                            _stops.insert(i + 1, value);
                                          }),
                                    icon: const Icon(Icons.arrow_downward),
                                  ),
                                  IconButton(
                                    tooltip: 'Remove stop',
                                    onPressed: _saving
                                        ? null
                                        : () => setState(
                                            () => _stops.removeAt(i),
                                          ),
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              ),
                              if (_bus)
                                TextFormField(
                                  controller: _times.putIfAbsent(
                                    _stops[i],
                                    () => TextEditingController(),
                                  ),
                                  enabled: !_saving,
                                  decoration: const InputDecoration(
                                    labelText: 'Scheduled time (HH:mm)',
                                    hintText: '23:50',
                                  ),
                                  validator: (v) =>
                                      RegExp(r'^([01]\d|2[0-3]):[0-5]\d$')
                                          .hasMatch(v?.trim() ?? '')
                                      ? null
                                      : 'Use 24-hour HH:mm',
                                ),
                            ],
                          ),
                        ),
                      ),
                    DropdownButtonFormField<String>(
                      key: ValueKey('${_routeId}_${_stops.join(',')}'),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Add a stop',
                      ),
                      items: [
                        for (final stop in _availableStops())
                          DropdownMenuItem(
                            value: stop.id,
                            child: Text(
                              stop.text('name'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: _saving
                          ? null
                          : (v) {
                              if (v != null) setState(() => _stops.add(v));
                            },
                    ),
                  ],
                  const SizedBox(height: 24),
                  _field(
                    'sourceUrl',
                    'Source URL',
                    hint: 'Authoritative timetable, stop or operator source. This is not a live-service verification.',
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _sourceReviewed,
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _sourceReviewed = v!),
                    title: const Text(
                      'I reviewed the source and the entered catalogue details.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _saving ? 'Saving...' : 'Save catalogue record',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  if (_error != null)
                    TextButton(
                      onPressed: _saving ? null : _load,
                      child: const Text('Reload reference data'),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  List<AdminRecord> _availableStops() {
    final route = _routes.where((r) => r.id == _routeId).firstOrNull;
    final allowed = route?.data['stops'] as List? ?? [];
    return _stations
        .where(
          (s) => !_stops.contains(s.id) && (!_bus || allowed.contains(s.id)),
        )
        .toList();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (!_sourceReviewed) {
      setState(() => _error = 'Review the source before saving.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final data = <String, dynamic>{'sourceUrl': _c('sourceUrl').text.trim()};
      if (_station) {
        data.addAll({
          'name': _c('name').text.trim(),
          'lat': double.tryParse(_c('lat').text),
          'lng': double.tryParse(_c('lng').text),
          'hasRamp': _ramp,
          'hasElevator': _elevator,
          'stepFreeAccess': _stepFree,
        });
      } else {
        data['stops'] = List<String>.of(_stops);
        if (!_bus) {
          data.addAll({
            'routeNo': _c('routeNo').text.trim(),
            'routeName': _c('routeName').text.trim(),
            'description': _c('description').text.trim(),
          });
        } else {
          final route = _routes.where((r) => r.id == _routeId).firstOrNull;
          final times = _stops
              .map((s) => _times[s]?.text.trim() ?? '')
              .toList();
          data.addAll({
            'routeId': _routeId,
            'routeNo': route?.text('routeNo') ?? '',
            'busNo': _recordType == 'vehicle' ? _c('busNo').text.trim() : null,
            'catalogueRecordType': _recordType,
            'driverId': _recordType == 'vehicle' ? _driverId ?? '' : '',
            'scheduleTimes': times,
            'scheduledDeparture': times.firstOrNull ?? '',
            'hasRamp': _recordType == 'vehicle' ? _ramp : null,
            'lowFloor': _recordType == 'vehicle' ? _lowFloor : null,
            'occupancy': _original['occupancy'] ?? 'unknown',
          });
          if (_recordType != 'vehicle' || _original['hasRamp'] != _ramp) {
            data.addAll({
              'rampOk': null,
              'rampCheckedAt': null,
              'rampCheckedBy': null,
            });
          }
        }
      }
      await widget.service.saveCatalogue(
        widget.kind,
        _c('id').text.trim(),
        data,
        original: widget.original,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is FormatException
              ? e.message
              : e is StateError
              ? e.message
              : 'Save was not confirmed. Check connection/access and reload before retrying.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
