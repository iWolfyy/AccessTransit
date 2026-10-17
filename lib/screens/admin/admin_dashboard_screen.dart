import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/localization_context.dart';
import '../../services/moderation_mode.dart';
import '../community/report_reviews_screen.dart';

import '../../core/theme/app_theme.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/sample_test_mode.dart';
import '../../widgets/admin_access_gate.dart';
import '../auth/login_screen.dart';
import '../main_shell.dart';
import 'catalogue_editor_screen.dart';
import 'service_runs_screen.dart';
import 'ban_reviews_screen.dart';
import 'active_operations_screen.dart';
import 'fare_publications_screen.dart';
import 'route_geometry_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => AdminAccessGate(
    child: AdminWorkspace(repository: FirestoreAdminRepository()),
  );
}

class AdminWorkspace extends StatefulWidget {
  const AdminWorkspace({super.key, required this.repository});
  final AdminRepository repository;
  @override
  State<AdminWorkspace> createState() => _AdminWorkspaceState();
}

class _AdminWorkspaceState extends State<AdminWorkspace> {
  static const _kinds = [
    'buses',
    'routes',
    'stations',
    'users',
    'operator_access',
    'driver_route_assignments',
    'admin_audit',
  ];
  static const _tabs = [
    'Overview',
    'Buses',
    'Routes',
    'Bus stops',
    'Users',
    'Driver reviews',
    'Activity',
  ];
  final _subscriptions = <StreamSubscription<List<AdminRecord>>>[];
  final _records = <String, List<AdminRecord>>{};
  final _errors = <String, String>{};
  final _search = TextEditingController();
  late final _service = AdminService(widget.repository);
  String _tab = 'Overview';
  bool _busy = false;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    final generation = ++_generation;
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _records.clear();
    _errors.clear();
    for (final kind in _kinds) {
      _subscriptions.add(
        widget.repository
            .watch(kind)
            .listen(
              (records) {
                if (!mounted || generation != _generation) return;
                setState(() {
                  _records[kind] = records;
                  _errors.remove(kind);
                });
              },
              onError: (_) {
                if (!mounted || generation != _generation) return;
                setState(() {
                  _records.remove(kind);
                  _errors[kind] = 'Could not verify $kind from the server.';
                });
              },
            ),
      );
    }
  }

  @override
  void dispose() {
    ++_generation;
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _search.dispose();
    super.dispose();
  }

  List<AdminRecord> _of(String kind) => _records[kind] ?? [];
  AdminRecord? _access(String uid) =>
      _of('operator_access').where((a) => a.id == uid).firstOrNull;
  String _status(AdminRecord user) {
    final access = _access(user.id);
    return access?.data['approved'] == true
        ? 'Approved'
        : switch (access?.text('status')) {
            'rejected' => 'Rejected',
            'revoked' => 'Revoked',
            _ => 'Pending review',
          };
  }

  bool get _ready => _errors.isEmpty && _kinds.every(_records.containsKey);
  Future<void> _action(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) _message('Change confirmed by the server.');
    } catch (e) {
      if (mounted) {
        _message(
          e is FormatException
              ? e.message
              : e is StateError
              ? e.message
              : 'Change was not confirmed. Check access/connection and reload before retrying.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(20) > 30
            ? 96
            : 56,
        centerTitle: true,
        title: const Text('Admin console'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => value == 'geometry'
                    ? RouteGeometryScreen(repository: widget.repository)
                    : value == 'fares'
                    ? FarePublicationsScreen(repository: widget.repository)
                    : value == 'operations'
                    ? const ActiveOperationsScreen()
                    : value == 'bans'
                    ? const BanReviewsScreen()
                    : const ReportReviewsScreen(admin: true),
              ),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'geometry',
                child: Text(context.l10n.geometryTitle),
              ),
              PopupMenuItem(
                value: 'fares',
                child: Text(context.l10n.fareAdminTitle),
              ),
              if (ModerationMode.enabled)
                PopupMenuItem(
                  value: 'operations',
                  child: Text(context.l10n.operationsTitle),
                ),
              if (ModerationMode.enabled)
                PopupMenuItem(
                  value: 'bans',
                  child: Text(context.l10n.bansTitle),
                ),
              if (ModerationMode.enabled)
                PopupMenuItem(
                  value: 'reviews',
                  child: Text(context.l10n.reviewsAdminTitle),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Refresh server data',
            onPressed: _busy ? null : () => setState(_listen),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _busy
                ? null
                : () async {
                    await AuthService().logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    }
                  },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          if (SampleTestMode.enabled)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Sample/Test catalogue administration'),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final tab in _tabs)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(tab == 'Driver reviews' ? 'Drivers' : tab),
                      selected: _tab == tab,
                      onSelected: _busy
                          ? null
                          : (_) => setState(() {
                              _tab = tab;
                              _search.clear();
                            }),
                    ),
                  ),
              ],
            ),
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_errors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${_errors.values.join(' ')} Actions are disabled. Use Refresh to retry.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (!_ready && _errors.isEmpty) const LinearProgressIndicator(),
          if (_tab != 'Overview')
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Search records',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
          Expanded(
            child: !_ready
                ? Center(
                    child: Text(
                      _errors.isEmpty
                          ? 'Loading verified server records...'
                          : 'Server data unavailable.',
                    ),
                  )
                : _content(),
          ),
        ],
      ),
      floatingActionButton:
          _ready && ['Buses', 'Routes', 'Bus stops'].contains(_tab)
          ? FloatingActionButton.extended(
              onPressed: _busy ? null : () => _edit(_kind),
              icon: const Icon(Icons.add),
              label: Text(
                'Add ${_tab == 'Bus stops'
                    ? 'stop'
                    : _tab == 'Buses'
                    ? 'bus'
                    : 'route'}',
              ),
            )
          : null,
    );
  }

  String get _kind => switch (_tab) {
    'Buses' => 'buses',
    'Routes' => 'routes',
    'Bus stops' => 'stations',
    'Users' || 'Driver reviews' => 'users',
    _ => 'admin_audit',
  };
  Widget _content() {
    if (_tab == 'Overview') {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            const Icon(Icons.admin_panel_settings_outlined, size: 36),
            'Transit administration',
            'Maintain sourced catalogue records and review operator access. All changes require server acknowledgement.',
          ),
          for (final (title, count, tab) in [
            ('Buses & timetables', _of('buses').length, 'Buses'),
            ('Routes', _of('routes').length, 'Routes'),
            ('Bus stops', _of('stations').length, 'Bus stops'),
            ('Users', _of('users').length, 'Users'),
            (
              'Drivers awaiting review',
              _of('users')
                  .where(
                    (u) =>
                        u.text('role') == 'operator' &&
                        _status(u) == 'Pending review',
                  )
                  .length,
              'Driver reviews',
            ),
          ])
            _card(
              const Icon(Icons.chevron_right),
              '$count $title',
              'Open $tab',
              onTap: () => setState(() => _tab = tab),
            ),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const MainShell())),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Open passenger app'),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Driver registration is an application for access. Review identity and operating authority before approval. Approval does not verify equipment or guarantee a service.',
            ),
          ),
        ],
      );
    }
    var records = _of(_kind)
        .where((r) => _tab != 'Driver reviews' || r.text('role') == 'operator')
        .toList();
    final query = _search.text.trim().toLowerCase();
    records = records
        .where(
          (r) =>
              '${r.id} ${r.text('name')} ${r.text('email')} ${r.text('routeName')} ${r.text('routeNo')} ${r.text('busNo')} ${r.text('action')} ${r.text('actorId')} ${_tab == 'Driver reviews' ? _status(r) : ''}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    records.sort(
      (a, b) => _tab == 'Activity'
          ? b.data['createdAt'].toString().compareTo(
              a.data['createdAt'].toString(),
            )
          : _title(a).compareTo(_title(b)),
    );
    if (records.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No matching records.'),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: records.length,
      itemBuilder: (_, i) {
        final r = records[i];
        return _card(
          Icon(switch (_kind) {
            'buses' => Icons.directions_bus,
            'routes' => Icons.route,
            'stations' => Icons.location_on_outlined,
            'users' => Icons.person_outline,
            _ => Icons.history,
          }),
          _title(r),
          _subtitle(r),
          actions: _tab == 'Driver reviews'
              ? [
                  TextButton(
                    onPressed: _busy ? null : () => _review(r),
                    child: const Text('Review access'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => _assignRoute(r),
                    child: const Text('Assign route'),
                  ),
                ]
              : _kind == 'users'
              ? [
                  TextButton(
                    onPressed: _busy ? null : () => _editUser(r),
                    child: const Text('Edit profile'),
                  ),
                  if (r.text('role') == 'operator')
                    TextButton(
                      onPressed: _busy ? null : () => _review(r),
                      child: const Text('Review driver'),
                    ),
                ]
              : _kind == 'admin_audit'
              ? []
              : [
                  if (_kind == 'buses' &&
                      r.text('catalogueRecordType') == 'vehicle')
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ServiceRunsScreen(
                                  bus: r,
                                  service: _service,
                                ),
                              ),
                            ),
                      child: const Text('Dated departures'),
                    ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => r.data['deletionPending'] == true
                              ? _action(() => _service.restoreCatalogue(r))
                              : _edit(_kind, r),
                    child: Text(
                      r.data['deletionPending'] == true ? 'Restore' : 'Edit',
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => _delete(r),
                    child: Text(
                      r.data['deletionPending'] == true
                          ? 'Finish deletion'
                          : 'Delete',
                    ),
                  ),
                ],
        );
      },
    );
  }

  String _title(AdminRecord r) => switch (r.kind) {
    'buses' =>
      r.text('busNo').isNotEmpty
          ? r.text('busNo')
          : 'Route ${r.text('routeNo')} timetable',
    'routes' => '${r.text('routeNo')} - ${r.text('routeName')}',
    'stations' || 'users' => r.text('name'),
    _ => r.text('action').replaceAll('_', ' '),
  };
  String _subtitle(AdminRecord r) => switch (r.kind) {
    'buses' =>
      'Route ${r.text('routeNo')} | ${r.text('catalogueRecordType') == 'published_timetable' ? 'Published timetable' : 'Vehicle'}\nDriver: ${_of('users').where((u) => u.id == r.text('driverId')).firstOrNull?.text('name') ?? 'Unassigned'}',
    'routes' => '${(r.data['stops'] as List? ?? []).length} ordered stops',
    'stations' => '${r.text('lat')}, ${r.text('lng')}',
    'users' =>
      '${r.text('email')}\n${r.text('role')}${r.text('role') == 'operator' ? ' | ${_status(r)}\n${_assignedRouteLabel(r.id)}' : ''}',
    _ =>
      'By ${r.text('actorId')}\n${r.data['createdAt']}\n${(r.data['targets'] as List? ?? []).join(', ')}',
  };
  Widget _card(
    Widget icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
    List<Widget> actions = const [],
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      color: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(subtitle),
              if (actions.isNotEmpty)
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  children: actions,
                ),
            ],
          ),
        ),
      ),
    ),
  );
  Future<void> _edit(String kind, [AdminRecord? record]) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CatalogueEditorScreen(
            service: _service,
            kind: kind,
            original: record,
          ),
        ),
      );
  Future<void> _delete(AdminRecord r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${_title(r)}?'),
        content: const Text(
          'This removes the catalogue record. Referenced records and active buses cannot be deleted. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete record'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _action(() => _service.deleteCatalogue(r));
    }
  }

  Future<void> _editUser(AdminRecord user) async {
    final name = TextEditingController(text: user.text('name'));
    final phone = TextEditingController(text: user.text('phone'));
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit user profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(user.text('email')),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
                maxLength: 100,
              ),
              TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                maxLength: 40,
              ),
              const Text(
                'Login email, passwords and Auth account deletion are managed in Firebase Authentication.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save profile'),
          ),
        ],
      ),
    );
    if (save == true && mounted) {
      await _action(() => _service.updateUser(user, name.text, phone.text));
    }
    // Dialog exit animations may still use its text fields.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
    phone.dispose();
  }

  String _assignedRouteLabel(String uid) {
    final grant = _of('driver_route_assignments')
        .where((g) => g.id == uid && g.data['active'] == true)
        .firstOrNull;
    final route = _of('routes')
        .where((r) => r.id == grant?.text('routeId'))
        .firstOrNull;
    return route == null
        ? 'No active route assignment'
        : 'Assigned route: ${_title(route)}';
  }

  Future<void> _assignRoute(AdminRecord user) async {
    final note = TextEditingController();
    final grant = _of('driver_route_assignments')
        .where((g) => g.id == user.id && g.data['active'] == true)
        .firstOrNull;
    final routes = _of('routes')
        .where(
          (r) =>
              r.data['deletionPending'] != true &&
              r.data['isDemo'] != true &&
              r.text('catalogueSource') != 'demo',
        )
        .toList();
    String selected = routes.any((r) => r.id == grant?.text('routeId'))
        ? grant!.text('routeId')
        : '';
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text('Route for ${user.text('name')}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Approval is separate from route assignment. End any active trip before changing or removing a route.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selected,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Assigned route',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('No route / remove assignment'),
                    ),
                    for (final r in routes)
                      DropdownMenuItem(
                        value: r.id,
                        child: Text(
                          _title(r),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => update(() => selected = v ?? ''),
                ),
                TextField(
                  controller: note,
                  maxLength: 2000,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Assignment reason (at least 10 characters)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save assignment'),
            ),
          ],
        ),
      ),
    );
    if (save == true && mounted) {
      await _action(
        () => _service.assignDriverRoute(
          user,
          selected.isEmpty ? null : selected,
          note.text,
        ),
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    note.dispose();
  }

  Future<void> _review(AdminRecord user) async {
    final note = TextEditingController();
    var decision = 'approved';
    var verified = false;
    final access = _access(user.id);
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text('Review ${user.text('name')}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.text('email')),
                Text('Current access: ${_status(user)}'),
                if (access?.text('reviewNote').isNotEmpty == true)
                  Text('Previous review: ${access!.text('reviewNote')}'),
                DropdownButtonFormField<String>(
                  initialValue: decision,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Decision'),
                  items: const [
                    DropdownMenuItem(value: 'approved', child: Text('Approve')),
                    DropdownMenuItem(value: 'rejected', child: Text('Reject')),
                    DropdownMenuItem(
                      value: 'revoked',
                      child: Text('Revoke access'),
                    ),
                  ],
                  onChanged: (v) => update(() => decision = v!),
                ),
                TextField(
                  controller: note,
                  maxLength: 2000,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Review evidence / reason',
                    helperText: 'Record the identity and operating-authority checks or decision reason.',
                  ),
                ),
                if (decision == 'approved')
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'I checked this driver\'s identity and operating authority.',
                    ),
                    value: verified,
                    onChanged: (v) => update(() => verified = v!),
                  ),
                if (decision != 'approved')
                  const Text(
                    'Access will be withdrawn and bus assignments released. Active trip/telemetry records remain for reconciliation; they are not marked completed.',
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: decision == 'approved' && !verified
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: const Text('Confirm decision'),
            ),
          ],
        ),
      ),
    );
    if (save == true && mounted) {
      await _action(() => _service.reviewOperator(user, decision, note.text));
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    note.dispose();
  }
}
