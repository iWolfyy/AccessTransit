import 'admin_scaffold.dart';
import '../../widgets/accessible_tap_target.dart';
import '../../widgets/accessible_dropdown.dart';
import '../../l10n/admin_catalogue_labels.dart';
import '../community/manual_appeals_screen.dart';
import 'account_controls_screen.dart';

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
  final _nextPages = <String, String?>{};
  final _pageVersions = <String, int>{};
  final _pageBusy = <String>{};
  final _pageErrors = <String>{};
  bool _paged(String kind) =>
      ['users', 'admin_audit', 'buses', 'routes', 'stations'].contains(kind);
  Future<void> _more(String kind) async {
    final cursor = _nextPages[kind];
    if (cursor == null || _pageBusy.contains(kind)) return;
    final generation = _generation, version = _pageVersions[kind];
    setState(() {
      _pageBusy.add(kind);
      _pageErrors.remove(kind);
    });
    try {
      final result = await widget.repository.page(kind, after: cursor);
      if (!mounted ||
          generation != _generation ||
          version != _pageVersions[kind]) {
        return;
      }
      setState(() {
        final ids = _of(kind).map((r) => r.id).toSet();
        _records[kind] = [
          ..._of(kind),
          ...result.items.where((r) => ids.add(r.id)),
        ];
        _nextPages[kind] = result.next;
        _pageBusy.remove(kind);
      });
    } catch (_) {
      if (mounted &&
          generation == _generation &&
          version == _pageVersions[kind]) {
        setState(() {
          _pageBusy.remove(kind);
          _pageErrors.add(kind);
        });
      }
    }
  }

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
    _nextPages.clear();
    _pageBusy.clear();
    _pageErrors.clear();
    _pageVersions.clear();
    for (final kind in _kinds) {
      _subscriptions.add(
        widget.repository
            .watch(kind)
            .listen(
              (records) {
                if (!mounted || generation != _generation) return;
                setState(() {
                  if (_paged(kind)) {
                    _pageVersions[kind] = (_pageVersions[kind] ?? 0) + 1;
                    _records[kind] = records.take(20).toList();
                    _nextPages[kind] = records.length > 20
                        ? records[19].id
                        : null;
                    _pageBusy.remove(kind);
                    _pageErrors.remove(kind);
                  } else {
                    _records[kind] = records;
                  }
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
      if (mounted) _message(context.l10n.adminChangeConfirmed);
    } catch (e) {
      if (mounted) {
        _message(context.adminFailure(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(20) > 30
            ? 96
            : 56,
        centerTitle: false,
        title: Text(context.l10n.adminConsole),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => value == 'manual-appeals'
                    ? const ManualAppealsScreen(admin: true)
                    : value == 'geometry'
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
              if (ModerationMode.enabled)
                PopupMenuItem(
                  height: context.buttonHeight,
                  value: 'manual-appeals',
                  child: Text(context.l10n.manualAppealsTitle),
                ),
              PopupMenuItem(
                height: context.buttonHeight,
                value: 'geometry',
                child: Text(context.l10n.geometryTitle),
              ),
              PopupMenuItem(
                height: context.buttonHeight,
                value: 'fares',
                child: Text(context.l10n.fareAdminTitle),
              ),
              if (ModerationMode.enabled)
                PopupMenuItem(
                  height: context.buttonHeight,
                  value: 'operations',
                  child: Text(context.l10n.operationsTitle),
                ),
              if (ModerationMode.enabled)
                PopupMenuItem(
                  height: context.buttonHeight,
                  value: 'bans',
                  child: Text(context.l10n.bansTitle),
                ),
              if (ModerationMode.enabled)
                PopupMenuItem(
                  height: context.buttonHeight,
                  value: 'reviews',
                  child: Text(context.l10n.reviewsAdminTitle),
                ),
            ],
          ),
          IconButton(
            tooltip: context.l10n.adminRefresh,
            onPressed: _busy ? null : () => setState(_listen),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: context.l10n.adminSignOut,
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
            Padding(
              padding: EdgeInsets.all(12),
              child: Text(context.l10n.adminSampleCatalogue),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final tab in _tabs)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AccessibleTapTarget(
                      child: ChoiceChip(
                        label: Text(
                          context.adminText(
                            tab == 'Driver reviews' ? 'Drivers' : tab,
                          ),
                        ),
                        selected: _tab == tab,
                        onSelected: _busy
                            ? null
                            : (_) => setState(() {
                                _tab = tab;
                                _search.clear();
                              }),
                      ),
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
                context.l10n.adminLoadKindsFailed(
                  _errors.keys.map(context.adminKind).join(', '),
                ),
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
                decoration: InputDecoration(
                  labelText: _paged(_kind)
                      ? context.l10n.adminSearchLoaded
                      : context.l10n.adminSearchLoaded,
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
          Expanded(
            child: !_ready
                ? Center(
                    child: Text(
                      _errors.isEmpty
                          ? context.l10n.adminLoading
                          : context.l10n.adminUnavailable,
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
                '${context.l10n.adminAdd} ${context.adminText(_tab == 'Bus stops'
                    ? 'bus stop'
                    : _tab == 'Buses'
                    ? 'bus / timetable'
                    : 'route')}',
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
            ('Buses & timetables (loaded)', _of('buses').length, 'Buses'),
            ('Routes (loaded)', _of('routes').length, 'Routes'),
            ('Bus stops (loaded)', _of('stations').length, 'Bus stops'),
            ('Users (loaded)', _of('users').length, 'Users'),
            (
              'Drivers awaiting review (loaded)',
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
              Icon(switch (tab) {
                'Buses' => Icons.directions_bus_outlined,
                'Routes' => Icons.route_outlined,
                'Bus stops' => Icons.location_on_outlined,
                'Users' => Icons.people_outline,
                _ => Icons.badge_outlined,
              }),
              '$count ${context.adminText(title)}',
              context.adminText(tab),
              onTap: () => setState(() => _tab = tab),
            ),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const MainShell())),
            icon: const Icon(Icons.home_outlined),
            label: Text(context.l10n.adminOpenPassenger),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Text(context.l10n.sharedDriverReviewHelp),
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
    if (records.isEmpty && !_paged(_kind)) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(context.l10n.adminNoMatches),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: records.length + (_paged(_kind) ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == records.length) {
          return Column(
            children: [
              Text(context.l10n.adminLoadedPages),
              if (records.isEmpty) Text(context.l10n.adminNoMatches),
              if (_pageErrors.contains(_kind))
                Text(context.l10n.accountControlsUnavailable),
              if (_nextPages[_kind] != null)
                TextButton(
                  onPressed: _pageBusy.contains(_kind)
                      ? null
                      : () => _more(_kind),
                  child: Text(
                    _pageErrors.contains(_kind)
                        ? context.l10n.accountStatusRetry
                        : context.l10n.adminLoadMore,
                  ),
                ),
              if (_pageBusy.contains(_kind)) const LinearProgressIndicator(),
            ],
          );
        }
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
                    child: Text(context.l10n.adminReviewAccess),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => _assignRoute(r),
                    child: Text(context.l10n.adminAssignRoute),
                  ),
                ]
              : _kind == 'users'
              ? [
                  TextButton(
                    onPressed: _busy ? null : () => _editUser(r),
                    child: Text(context.l10n.adminEditProfile),
                  ),
                  if (ModerationMode.enabled)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    AccountControlsScreen(accountId: r.id),
                              ),
                            ),
                      child: Text(context.l10n.accountControlsTitle),
                    ),
                  if (r.text('role') == 'operator')
                    TextButton(
                      onPressed: _busy ? null : () => _review(r),
                      child: Text(context.l10n.adminReviewDriver),
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
                      child: Text(context.l10n.adminDatedDepartures),
                    ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => r.data['deletionPending'] == true
                              ? _action(() => _service.restoreCatalogue(r))
                              : _edit(_kind, r),
                    child: Text(
                      context.adminText(
                        r.data['deletionPending'] == true ? 'Restore' : 'Edit',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => _delete(r),
                    child: Text(
                      context.adminText(
                        r.data['deletionPending'] == true
                            ? 'Finish deletion'
                            : 'Delete',
                      ),
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
          : context.l10n.adminTimetableFor(r.text('routeNo')),
    'routes' => '${r.text('routeNo')} - ${r.text('routeName')}',
    'stations' || 'users' => r.text('name'),
    _ => r.text('action').replaceAll('_', ' '),
  };
  String _subtitle(AdminRecord r) => switch (r.kind) {
    'buses' => context.l10n.adminBusSummary(
      r.text('routeNo'),
      r.text('catalogueRecordType') == 'published_timetable'
          ? context.l10n.adminPublishedTimetable
          : context.l10n.adminPhysicalVehicle,
      _of('users')
              .where((u) => u.id == r.text('driverId'))
              .firstOrNull
              ?.text('name') ??
          (r.text('driverId').isEmpty
              ? context.l10n.adminUnassigned
              : r.text('driverId')),
    ),
    'routes' => context.l10n.adminStopCount(
      (r.data['stops'] as List? ?? []).length,
    ),
    'stations' => '${r.text('lat')}, ${r.text('lng')}',
    'users' =>
      '${r.text('email')}\n${r.text('role')}${r.text('role') == 'operator' ? ' | ${context.adminText(_status(r))}\n${_assignedRouteLabel(r.id)}' : ''}',
    _ =>
      '${context.l10n.adminAuditBy(r.text('actorId'))}\n${r.data['createdAt']}\n${(r.data['targets'] as List? ?? []).join(', ')}',
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
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.isHighContrast
              ? Theme.of(context).colorScheme.outline
              : Theme.of(context).colorScheme.outlineVariant
                    .withValues(alpha: .5),
          width: context.isHighContrast ? 2 : 1,
        ),
      ),
      child: AccessibleTapTarget(
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
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary
                            .withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconTheme(
                        data: IconThemeData(
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        child: icon,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if (actions.isNotEmpty) const SizedBox(height: 8),
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
      builder: (ctx) => AdminDialog(
        title: Text(context.l10n.adminDeleteFor(_title(r))),
        content: Text(context.l10n.adminDeleteHelp),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.adminCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.adminDeleteRecord),
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
      builder: (ctx) => AdminDialog(
        title: Text(context.l10n.adminEditUser),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(user.text('email')),
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: context.l10n.adminName),
                maxLength: 100,
              ),
              TextField(
                controller: phone,
                decoration: InputDecoration(labelText: context.l10n.adminPhone),
                maxLength: 40,
              ),
              Text(context.l10n.adminAuthProfileHelp),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.adminCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.adminSaveProfile),
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
    return grant == null
        ? context.l10n.adminNoActiveRoute
        : context.l10n.adminAssignedRouteFor(
            route == null ? grant.text('routeId') : _title(route),
          );
  }

  Future<void> _assignRoute(AdminRecord user) async {
    final grant = _of('driver_route_assignments')
        .where((g) => g.id == user.id && g.data['active'] == true)
        .firstOrNull;
    List<AdminRecord> allRoutes;
    try {
      allRoutes = await widget.repository.referencePages('routes');
    } catch (_) {
      if (mounted) _message(context.l10n.adminSourceLoadError);
      return;
    }
    if (!mounted) return;
    final note = TextEditingController();
    final routes = allRoutes
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
        builder: (ctx, update) => AdminDialog(
          title: Text(context.l10n.adminRouteFor(user.text('name'))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.adminAssignmentHelp),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isDense: false,
                  itemHeight: null,
                  initialValue: selected,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.adminAssignedRoute,
                  ),
                  items: [
                    AccessibleDropdownMenuItem(
                      value: '',
                      child: Text(context.l10n.adminNoRoute),
                    ),
                    for (final r in routes)
                      AccessibleDropdownMenuItem(
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
                  decoration: InputDecoration(
                    labelText: context.l10n.adminAssignmentReason,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.adminCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.adminSaveAssignment),
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
        builder: (ctx, update) => AdminDialog(
          title: Text(context.l10n.adminReviewFor(user.text('name'))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.text('email')),
                Text(
                  context.l10n.adminCurrentAccessFor(
                    context.adminText(_status(user)),
                  ),
                ),
                if (access?.text('reviewNote').isNotEmpty == true)
                  Text(
                    context.l10n.adminPreviousReviewFor(
                      access!.text('reviewNote'),
                    ),
                  ),
                DropdownButtonFormField<String>(
                  isDense: false,
                  itemHeight: null,
                  initialValue: decision,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.adminDecision,
                  ),
                  items: [
                    AccessibleDropdownMenuItem(
                      value: 'approved',
                      child: Text(context.l10n.adminApprove),
                    ),
                    AccessibleDropdownMenuItem(
                      value: 'rejected',
                      child: Text(context.l10n.adminReject),
                    ),
                    AccessibleDropdownMenuItem(
                      value: 'revoked',
                      child: Text(context.l10n.adminRevoke),
                    ),
                  ],
                  onChanged: (v) => update(() => decision = v!),
                ),
                TextField(
                  controller: note,
                  maxLength: 2000,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: context.l10n.adminReviewReason,
                    helperText: context.l10n.adminReviewChecksHelp,
                  ),
                ),
                if (decision == 'approved')
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.l10n.adminDriverChecked),
                    value: verified,
                    onChanged: (v) => update(() => verified = v!),
                  ),
                if (decision != 'approved')
                  Text(context.l10n.adminReferenceWithdrawHelp),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.adminCancel),
            ),
            FilledButton(
              onPressed: decision == 'approved' && !verified
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: Text(context.l10n.adminConfirmDecision),
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
