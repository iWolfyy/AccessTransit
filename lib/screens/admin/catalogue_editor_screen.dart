import 'admin_scaffold.dart';
import '../../widgets/accessible_dropdown.dart';
import '../../l10n/admin_catalogue_labels.dart';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/localization_context.dart';
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
  final _stationIds = <String, String>{};
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
  bool _loading = true, _saving = false, _referencesReady = false;
  Object? _error;
  String? _routeId, _driverId;
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
    _stationIds.addAll(
      Map<String, String>.from(_original['stopStationIds'] as Map? ?? {}),
    );
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
      _referencesReady = false;
      _error = null;
    });
    try {
      final stations = await widget.service.repository.referencePages(
        'stations',
      );
      final routes = _bus
          ? await widget.service.repository.referencePages('routes')
          : <AdminRecord>[];
      final users = _bus
          ? await widget.service.repository.referencePages('users')
          : <AdminRecord>[];
      final access = _bus
          ? await widget.service.repository.referencePages('operator_access')
          : <AdminRecord>[];
      final assignments = _bus
          ? await widget.service.repository.referencePages(
              'driver_route_assignments',
            )
          : <AdminRecord>[];
      if (!mounted) return;
      setState(() {
        _stations = stations;
        _referencesReady = true;
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
      _stations
          .where((s) => s.id == (_stationIds[id] ?? id))
          .firstOrNull
          ?.text('name') ??
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
      decoration: InputDecoration(
        labelText: context.adminText(label),
        helperText: hint == null ? null : context.adminText(hint),
        helperMaxLines: 6,
        prefixIcon: key == 'id'
            ? const Icon(Icons.tag)
            : key == 'sourceUrl'
            ? const Icon(Icons.link)
            : null,
      ),
      validator: required
          ? (v) =>
                v?.trim().isNotEmpty == true ? null : context.l10n.adminRequired
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
      isDense: false,
      itemHeight: null,
      initialValue: value == null
          ? 'unknown'
          : value
          ? 'yes'
          : 'no',
      isExpanded: true,
      decoration: InputDecoration(labelText: context.adminText(label)),
      items: [
        AccessibleDropdownMenuItem(
          value: 'unknown',
          child: Text(context.l10n.adminUnknown),
        ),
        AccessibleDropdownMenuItem(
          value: 'yes',
          child: Text(
            context.adminText(capability ? 'Equipped' : 'Yes - assessed'),
          ),
        ),
        AccessibleDropdownMenuItem(
          value: 'no',
          child: Text(
            context.adminText(capability ? 'Not equipped' : 'No - assessed'),
          ),
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
    return AdminScaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        title: Text(
          '${context.adminText(widget.original == null ? 'Add' : 'Edit')} ${context.adminText(label)}',
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
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
                          _error is String
                              ? context.adminText(_error! as String)
                              : context.adminFailure(_error!),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  _sectionTitle(Icons.info_outline, context.adminText(label)),
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
                    _sectionTitle(
                      Icons.accessible,
                      context.l10n.adminAccessibilityDetails,
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
                      isDense: false,
                      itemHeight: null,
                      initialValue: _recordType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.l10n.adminCatalogueType,
                      ),
                      items: [
                        AccessibleDropdownMenuItem(
                          value: 'vehicle',
                          child: Text(context.l10n.adminPhysicalVehicle),
                        ),
                        AccessibleDropdownMenuItem(
                          value: 'published_timetable',
                          child: Text(context.l10n.adminPublishedTimetable),
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
                      isDense: false,
                      itemHeight: null,
                      initialValue: _routes.any((r) => r.id == _routeId)
                          ? _routeId
                          : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.l10n.adminRouteField,
                      ),
                      items: [
                        for (final route in _routes)
                          AccessibleDropdownMenuItem(
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
                      validator: (v) =>
                          v == null ? context.l10n.adminChooseRoute : null,
                    ),
                    const SizedBox(height: 16),
                    if (_recordType == 'vehicle') ...[
                      _field('busNo', 'Vehicle registration number'),
                      DropdownButtonFormField<String>(
                        isDense: false,
                        itemHeight: null,
                        key: ValueKey('driver-$_routeId'),
                        initialValue:
                            _routeDrivers.any((d) => d.id == _driverId)
                            ? _driverId
                            : '',
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: context.l10n.adminDriverField,
                        ),
                        items: [
                          AccessibleDropdownMenuItem(
                            value: '',
                            child: Text(context.l10n.adminUnassigned),
                          ),
                          for (final driver in _routeDrivers)
                            AccessibleDropdownMenuItem(
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
                        Text(context.l10n.adminRouteFirst),
                      _assessment('Ramp capability', _ramp, (v) => _ramp = v),
                      _assessment(
                        'Low-floor capability',
                        _lowFloor,
                        (v) => _lowFloor = v,
                      ),
                      Text(context.l10n.adminCapabilityHelp),
                    ] else
                      Text(context.l10n.adminTimetableHelp),
                  ],
                  if (!_station) ...[
                    const SizedBox(height: 20),
                    _sectionTitle(
                      Icons.route_outlined,
                      context.l10n.sharedStopsOrder,
                    ),
                    Text(context.l10n.loopStopHelp),
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
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                alignment: WrapAlignment.end,
                                children: [
                                  IconButton.outlined(
                                    tooltip: context.l10n.adminMoveUp,
                                    onPressed: _saving || i == 0
                                        ? null
                                        : () => setState(() {
                                            final value = _stops.removeAt(i);
                                            _stops.insert(i - 1, value);
                                          }),
                                    icon: const Icon(Icons.arrow_upward),
                                  ),
                                  IconButton.outlined(
                                    tooltip: context.l10n.adminMoveDown,
                                    onPressed: _saving || i == _stops.length - 1
                                        ? null
                                        : () => setState(() {
                                            final value = _stops.removeAt(i);
                                            _stops.insert(i + 1, value);
                                          }),
                                    icon: const Icon(Icons.arrow_downward),
                                  ),
                                  IconButton.outlined(
                                    tooltip: context.l10n.adminRemoveStop,
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
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.schedule),
                                    labelText: context.l10n.adminScheduledTime,
                                    hintText: '23:50',
                                  ),
                                  validator: (v) =>
                                      RegExp(r'^([01]\d|2[0-3]):[0-5]\d$')
                                          .hasMatch(v?.trim() ?? '')
                                      ? null
                                      : context.l10n.adminTimeFormat,
                                ),
                            ],
                          ),
                        ),
                      ),
                    DropdownButtonFormField<String>(
                      isDense: false,
                      itemHeight: null,
                      key: ValueKey('${_routeId}_${_stops.join(',')}'),
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.l10n.adminAddStop,
                      ),
                      items: [
                        for (final stop in _availableStops())
                          AccessibleDropdownMenuItem(
                            value: stop.id,
                            child: Text(
                              '${stop.text('name')}${_bus && AdminService.stationIdFor(_routes.firstWhere((r) => r.id == _routeId).data, stop.id) != stop.id ? ' (${(_routes.firstWhere((r) => r.id == _routeId).data['stops'] as List).indexOf(stop.id) + 1})' : ''}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: _saving
                          ? null
                          : (v) {
                              if (v != null) {
                                setState(() {
                                  if (_bus) {
                                    final route = _routes.firstWhere(
                                      (r) => r.id == _routeId,
                                    );
                                    _stationIds[v] = AdminService.stationIdFor(
                                      route.data,
                                      v,
                                    );
                                    _stops.add(v);
                                  } else {
                                    final key = _stops.contains(v)
                                        ? 'occ_${DateTime.now().microsecondsSinceEpoch}'
                                        : v;
                                    _stationIds[key] = v;
                                    _stops.add(key);
                                  }
                                });
                              }
                            },
                    ),
                  ],
                  const SizedBox(height: 24),
                  _sectionTitle(
                    Icons.fact_check_outlined,
                    context.adminText('Source URL'),
                  ),
                  _field(
                    'sourceUrl',
                    'Source URL',
                    hint: 'Authoritative timetable, stop or operator source. This is not a live-service verification.',
                  ),
                  CheckboxListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    tileColor: context.cardColor,
                    value: _sourceReviewed,
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _sourceReviewed = v!),
                    title: Text(context.l10n.adminSourceChecked),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving || !_referencesReady ? null : _save,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        context.adminText(
                          _saving ? 'Saving...' : 'Save catalogue record',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  if (_error != null)
                    TextButton(
                      onPressed: _saving ? null : _load,
                      child: Text(context.l10n.adminReloadReferences),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 16),
    child: Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  List<AdminRecord> _availableStops() {
    final route = _routes.where((r) => r.id == _routeId).firstOrNull;
    final allowed = route?.data['stops'] as List? ?? [];
    if (_bus) {
      return [
        for (final key in allowed.cast<String>())
          if (!_stops.contains(key))
            for (final s in _stations)
              if (s.id == AdminService.stationIdFor(route!.data, key))
                AdminRecord('stations', key, s.data),
      ];
    }
    return _stations;
  }

  Future<void> _save() async {
    if (!_referencesReady) return;
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
        data['stopStationIds'] = {
          for (final key in _stops) key: _stationIds[key] ?? key,
        };
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
        setState(() => _error = e);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
