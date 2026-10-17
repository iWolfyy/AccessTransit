import 'admin_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/accessible_tap_target.dart';
import '../../l10n/admin_catalogue_labels.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/localization_context.dart';
import '../../models/service_run.dart';
import '../../services/admin_service.dart';

class ServiceCalendarScreen extends StatefulWidget {
  const ServiceCalendarScreen({
    super.key,
    required this.bus,
    required this.service,
  });
  final AdminRecord bus;
  final AdminService service;
  @override
  State<ServiceCalendarScreen> createState() => _ServiceCalendarScreenState();
}

class _ServiceCalendarScreenState extends State<ServiceCalendarScreen> {
  final _weekdays = <int>{1, 2, 3, 4, 5};
  DateTimeRange? _range;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  List<AdminRecord> _calendars = [];
  bool _busy = true, _failed = false;
  Object? _failure;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final records = await widget.service.repository.load('service_schedules');
      if (mounted) {
        setState(() {
          _calendars = records
              .where((r) => r.text('busId') == widget.bus.id)
              .toList();
          _failed = false;
          _failure = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _failed = true;
          _failure = e;
          _calendars = [];
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _act(Future<String> Function() action) async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final message = await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      await _reload();
    } catch (e) {
      if (mounted) {
        setState(() {
          _failed = true;
          _failure = e;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _date(DateTime d) =>
      DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(d);
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AdminScaffold(
      appBar: AppBar(title: Text(l.calendarTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.bus.text('busNo'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(l.calendarHelp),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () async {
                    final now = ServiceRun.colomboClock(DateTime.now());
                    final today = DateTime(now.year, now.month, now.day);
                    final value = await showDateRangePicker(
                      initialEntryMode:
                          context.hasLargeTargets &&
                              MediaQuery.sizeOf(context).width < 420
                          ? DatePickerEntryMode.inputOnly
                          : DatePickerEntryMode.calendar,
                      context: context,
                      firstDate: today,
                      lastDate: today.add(const Duration(days: 365)),
                      initialDateRange: _range,
                    );
                    if (value != null && mounted) {
                      setState(() => _range = value);
                    }
                  },
            child: Text(
              _range == null
                  ? l.calendarDates
                  : '${_date(_range!.start)} – ${_date(_range!.end)}',
            ),
          ),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () async {
                    final value = await showTimePicker(
                      initialEntryMode:
                          context.hasLargeTargets &&
                              MediaQuery.sizeOf(context).width < 420
                          ? TimePickerEntryMode.inputOnly
                          : TimePickerEntryMode.dial,
                      context: context,
                      initialTime: _time,
                    );
                    if (value != null && mounted) setState(() => _time = value);
                  },
            child: Text('${l.calendarTime}: ${_time.format(context)}'),
          ),
          Wrap(
            spacing: 8,
            children: [
              for (var day = 1; day <= 7; day++)
                AccessibleTapTarget(
                  child: FilterChip(
                    label: Text(
                      DateFormat.EEEE(
                        Localizations.localeOf(context).toString(),
                      ).format(DateTime(2026, 10, 19 + day - 1)),
                    ),
                    selected: _weekdays.contains(day),
                    onSelected: _busy
                        ? null
                        : (selected) => setState(() {
                            if (selected) {
                              _weekdays.add(day);
                            } else {
                              _weekdays.remove(day);
                            }
                          }),
                  ),
                ),
            ],
          ),
          FilledButton(
            onPressed: _busy || _range == null || _weekdays.isEmpty
                ? null
                : () => _act(() async {
                    await widget.service.publishServiceSchedule(
                      widget.bus,
                      from: _range!.start,
                      until: _range!.end,
                      weekdays: Set.of(_weekdays),
                      departureMinutes: _time.hour * 60 + _time.minute,
                    );
                    return l.calendarConfirmed;
                  }),
            child: Text(l.calendarPublish),
          ),
          if (_busy) const Center(child: CircularProgressIndicator()),
          if (_failed) ...[
            Text(l.calendarFailed),
            if (_failure != null) Text(context.adminFailure(_failure!)),
          ],
          TextButton(
            onPressed: _busy
                ? null
                : () {
                    setState(() => _busy = true);
                    _reload();
                  },
            child: Text(l.operationsRefresh),
          ),
          if (!_busy && !_failed && _calendars.isEmpty) Text(l.calendarEmpty),
          for (final c in _calendars)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.text('state') == 'published'
                          ? l.calendarPublished
                          : c.text('state') == 'retired'
                          ? l.calendarRetired
                          : l.adminRunUnknown,
                    ),
                    Text(
                      '${_date((c.data['from'] as Timestamp).toDate().toUtc())} – ${_date((c.data['until'] as Timestamp).toDate().toUtc())}',
                    ),
                    Text(
                      TimeOfDay(
                        hour: (c.data['departureMinutes'] as int) ~/ 60,
                        minute: (c.data['departureMinutes'] as int) % 60,
                      ).format(context),
                    ),
                    Text(
                      (c.data['weekdays'] as List)
                          .map(
                            (d) => DateFormat.EEEE(
                              Localizations.localeOf(context).toString(),
                            ).format(DateTime(2026, 10, 18 + (d as int))),
                          )
                          .join(', '),
                    ),
                    if (c.text('state') == 'published') ...[
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _act(() async {
                                final result = await widget.service
                                    .generateServiceSchedule(c);
                                return l.calendarGenerated(
                                  result.created,
                                  result.preserved,
                                );
                              }),
                        child: Text(l.calendarGenerate),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _act(() async {
                                await widget.service.retireServiceSchedule(c);
                                return l.calendarConfirmed;
                              }),
                        child: Text(l.calendarRetire),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
