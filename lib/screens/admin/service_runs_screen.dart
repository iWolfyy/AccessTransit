import 'admin_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/admin_catalogue_labels.dart';

import 'package:flutter/material.dart';

import '../../models/service_run.dart';
import '../../l10n/localization_context.dart';
import 'service_calendar_screen.dart';
import '../../services/admin_service.dart';
import '../../logic/ordered_schedule.dart';

class ServiceRunsScreen extends StatefulWidget {
  const ServiceRunsScreen({
    super.key,
    required this.bus,
    required this.service,
  });
  final AdminRecord bus;
  final AdminService service;
  @override
  State<ServiceRunsScreen> createState() => _ServiceRunsScreenState();
}

class _ServiceRunsScreenState extends State<ServiceRunsScreen> {
  DateTime _date = ServiceRun.colomboClock(DateTime.now());
  bool _busy = false;
  bool _loading = true;
  int _loadVersion = 0;
  Object? _error;
  List<AdminRecord> _runs = [];
  List<AdminRecord> _notes = [];
  late TimeOfDay _departure;
  @override
  void initState() {
    super.initState();
    final times = widget.bus.data['scheduleTimes'] as List? ?? [];
    final minutes = times.isEmpty
        ? null
        : OrderedSchedule.minutesOfDay(times.first.toString());
    _departure = TimeOfDay(
      hour: (minutes ?? 0) ~/ 60,
      minute: (minutes ?? 0) % 60,
    );
    _load();
  }

  Future<void> _load() async {
    final version = ++_loadVersion;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final runs = await widget.service.repository.load('service_runs');
      final notes = await widget.service.repository.load('driver_trip_notes');
      if (mounted && version == _loadVersion) {
        setState(() {
          _runs = runs.where((r) => r.text('busId') == widget.bus.id).toList();
          _notes = notes;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted && version == _loadVersion) {
        setState(() {
          _runs = [];
          _notes = [];
          _error = 'Could not load dated departures. Retry when online.';
        });
      }
    } finally {
      if (mounted && version == _loadVersion) setState(() => _loading = false);
    }
  }

  Future<void> _action(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.adminRunConfirmed)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reschedule(AdminRecord record) async {
    final form = GlobalKey<FormState>();
    var reason = '';
    final l = context.l10n;
    final chosen = await showDialog<String>(
      context: context,
      builder: (c) => AdminDialog(
        title: Text(l.scheduleReschedule),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.scheduleRescheduleHelp),
                Text(
                  l.adminColomboDateTime(
                    MaterialLocalizations.of(c).formatMediumDate(_date),
                    _departure.format(c),
                  ),
                ),
                TextFormField(
                  key: const ValueKey('reschedule-reason'),
                  maxLength: 300,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l.schedulePublicReason,
                  ),
                  onChanged: (v) => reason = v,
                  validator: (v) => (v?.trim().length ?? 0) >= 5
                      ? null
                      : l.scheduleReasonRequired,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(MaterialLocalizations.of(c).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(c, reason.trim());
              }
            },
            child: Text(l.scheduleReschedule),
          ),
        ],
      ),
    );
    if (chosen == null || !mounted) return;
    await _action(
      () => widget.service.rescheduleServiceRun(
        record,
        _date,
        departureMinutes: _departure.hour * 60 + _departure.minute,
        publicReason: chosen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AdminScaffold(
    appBar: AppBar(title: Text(context.l10n.adminDatedDepartures)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          widget.bus.text('busNo'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        TextButton(
          onPressed: _busy || _loading
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ServiceCalendarScreen(
                      bus: widget.bus,
                      service: widget.service,
                    ),
                  ),
                ),
          child: Text(context.l10n.calendarTitle),
        ),
        const SizedBox(height: 12),
        Text(context.l10n.adminRunHelp),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _busy || _loading
              ? null
              : () async {
                  final now = ServiceRun.colomboClock(DateTime.now());
                  final chosen = await showDatePicker(
                    initialEntryMode:
                        context.hasLargeTargets &&
                            MediaQuery.sizeOf(context).width < 420
                        ? DatePickerEntryMode.inputOnly
                        : DatePickerEntryMode.calendar,
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(now.year, now.month, now.day),
                    lastDate: DateTime(now.year, now.month, now.day + 30),
                  );
                  if (chosen != null && mounted) setState(() => _date = chosen);
                },
          child: Text(
            context.l10n.adminServiceDate(
              MaterialLocalizations.of(context).formatMediumDate(_date),
            ),
          ),
        ),
        OutlinedButton(
          onPressed: _busy || _loading
              ? null
              : () async {
                  final selected = await showTimePicker(
                    initialEntryMode:
                        context.hasLargeTargets &&
                            MediaQuery.sizeOf(context).width < 420
                        ? TimePickerEntryMode.inputOnly
                        : TimePickerEntryMode.dial,
                    context: context,
                    initialTime: _departure,
                  );
                  if (selected != null && mounted) {
                    setState(() => _departure = selected);
                  }
                },
          child: Text(
            context.l10n.adminColomboDeparture(_departure.format(context)),
          ),
        ),
        Text(context.l10n.adminRunRescheduleHelp),
        Text(context.l10n.adminRunWindowHelp),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy || _loading
              ? null
              : () => _action(
                  () => widget.service.scheduleServiceRun(
                    widget.bus,
                    _date,
                    departureMinutes: _departure.hour * 60 + _departure.minute,
                  ),
                ),
          child: Text(context.l10n.adminRunPublish),
        ),
        if (_loading) const LinearProgressIndicator(),
        if (!_loading && _error == null && _runs.isEmpty)
          Text(context.l10n.adminRunEmpty),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              _error is String
                  ? context.adminText(_error! as String)
                  : context.adminFailure(_error!),
            ),
          ),
        TextButton(
          onPressed: _busy || _loading ? null : _load,
          child: Text(context.l10n.adminRunReload),
        ),
        for (final r in _runs)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_civilDate(r.text('serviceDate'))} · ${context.adminRunStatus(r.text('status'))}',
                  ),
                  if (_notes.any((n) => n.id == r.id))
                    Text(
                      context.l10n.adminLateReason(
                        _notes.firstWhere((n) => n.id == r.id).text('reason'),
                      ),
                    ),
                  Text(_snapshotTimes(r)),
                  if (['scheduled', 'cancelled'].contains(r.text('status')) &&
                      r.data['replacementRunId'] == null)
                    TextButton(
                      onPressed: _busy || _loading
                          ? null
                          : () => _reschedule(r),
                      child: Text(context.l10n.scheduleReschedule),
                    ),
                  if (r.data['replacementRunId'] != null)
                    Text(context.l10n.scheduleReplacement),
                  if (r.text('status') == 'scheduled')
                    TextButton(
                      onPressed: _busy || _loading
                          ? null
                          : () => _action(
                              () => widget.service.cancelScheduledRun(r),
                            ),
                      child: Text(context.l10n.adminRunCancel),
                    ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
  String _civilDate(String value) {
    final date = DateTime.tryParse(value);
    return date == null
        ? value
        : MaterialLocalizations.of(context).formatMediumDate(date);
  }

  String _snapshotTimes(AdminRecord record) {
    try {
      final run = ServiceRun.fromMap(record.id, record.data);
      return context.l10n.adminPublishedStopTimes(
        run.stopTimes.values
            .map((t) {
              final c = ServiceRun.colomboClock(t);
              return '${MaterialLocalizations.of(context).formatMediumDate(c)} ${TimeOfDay(hour: c.hour, minute: c.minute).format(context)}';
            })
            .join(' → '),
      );
    } catch (_) {
      return context.l10n.adminRunReviewTimetable;
    }
  }
}
