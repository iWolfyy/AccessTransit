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
  String? _error;
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
    try {
      final runs = await widget.service.repository.load('service_runs');
      final notes = await widget.service.repository.load('driver_trip_notes');
      if (mounted) {
        setState(() {
          _runs = runs.where((r) => r.text('busId') == widget.bus.id).toList();
          _notes = notes;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not load dated departures. Retry when online.',
        );
      }
    }
  }

  Future<void> _action(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dated departure change confirmed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is StateError
              ? e.message
              : e is FormatException
              ? e.message
              : 'Change was not confirmed. Reload and retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Dated departures')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          widget.bus.text('busNo'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        TextButton(
          onPressed: _busy
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
        const Text(
          'Publish this bus timetable for a specific Colombo service date. Starting the run opens boarding; departure is recorded separately.',
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () async {
                  final now = ServiceRun.colomboClock(DateTime.now());
                  final chosen = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(now.year, now.month, now.day),
                    lastDate: DateTime(now.year, now.month, now.day + 30),
                  );
                  if (chosen != null && mounted) setState(() => _date = chosen);
                },
          child: Text(
            'Service date: ${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
          ),
        ),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () async {
                  final selected = await showTimePicker(
                    context: context,
                    initialTime: _departure,
                  );
                  if (selected != null && mounted) {
                    setState(() => _departure = selected);
                  }
                },
          child: Text(
            'Colombo departure: ${_departure.hour.toString().padLeft(2, '0')}:${_departure.minute.toString().padLeft(2, '0')}',
          ),
        ),
        const Text(
          'To reschedule, cancel the previous scheduled run and publish its replacement. Stop intervals are retained; the bus timetable stays unchanged.',
        ),
        const Text(
          'Start window: 5 minutes before to 30 minutes after departure. Late starts require a reason.',
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy
              ? null
              : () => _action(
                  () => widget.service.scheduleServiceRun(
                    widget.bus,
                    _date,
                    departureMinutes: _departure.hour * 60 + _departure.minute,
                  ),
                ),
          child: const Text('Publish dated departure'),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(_error!),
          ),
        TextButton(
          onPressed: _busy ? null : _load,
          child: const Text('Reload departures'),
        ),
        for (final r in _runs)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${r.text('serviceDate')} · ${r.text('status')}'),
                  if (_notes.any((n) => n.id == r.id))
                    Text(
                      'Late-start reason: ${_notes.firstWhere((n) => n.id == r.id).text('reason')}',
                    ),
                  Text(_snapshotTimes(r)),
                  if (r.text('status') == 'scheduled')
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _action(
                              () => widget.service.cancelScheduledRun(r),
                            ),
                      child: const Text('Cancel scheduled run'),
                    ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
  String _snapshotTimes(AdminRecord record) {
    try {
      final run = ServiceRun.fromMap(record.id, record.data);
      return 'Published stop times: ${run.stopTimes.values.map((t) {
        final c = ServiceRun.colomboClock(t);
        return '${c.month}/${c.day} ${c.hour.toString().padLeft(2, '0')}:${c.minute.toString().padLeft(2, '0')}';
      }).join(' → ')}';
    } catch (_) {
      return 'Stored timetable needs administrator review.';
    }
  }
}
