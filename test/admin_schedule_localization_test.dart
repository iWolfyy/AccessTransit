import 'dart:async';

import 'package:access_transit/l10n/admin_catalogue_labels.dart';
import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/screens/admin/service_runs_screen.dart';
import 'package:access_transit/screens/admin/service_calendar_screen.dart';
import 'package:access_transit/services/admin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_admin_repository.dart';

Widget host(String lang, Widget child) => MaterialApp(
  locale: Locale(lang),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (c, w) => MediaQuery(
    data: MediaQuery.of(c).copyWith(textScaler: const TextScaler.linear(2)),
    child: w!,
  ),
  home: child,
);

class WaitingRepository implements AdminRepository {
  WaitingRepository(this.base);
  final MemoryAdminRepository base;
  final runs = Completer<List<AdminRecord>>();
  @override
  Future<List<AdminRecord>> load(String kind) =>
      kind == 'service_runs' ? runs.future : base.load(kind);
  @override
  Stream<List<AdminRecord>> watch(String kind) => base.watch(kind);
  @override
  Future<void> commit(List<AdminChange> changes, String action) =>
      base.commit(changes, action);
}

void main() {
  for (final lang in ['en', 'si', 'ta']) {
    testWidgets(
      'dated run labels/status/notes $lang fit 320dp at 200 percent',
      (t) async {
        t.view.physicalSize = const Size(320, 1500);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final repo = adminFixture();
        addTearDown(repo.dispose);
        final service = AdminService(repo);
        await service.scheduleServiceRun(
          repo.get('buses', 'b1'),
          DateTime(2026, 10, 20),
        );
        final run = repo.data['service_runs']!.values.single;
        repo.seed('service_runs', run.id, {...run.data, 'status': 'boarding'});
        repo.seed('driver_trip_notes', run.id, {
          'reason': 'Original driver reason',
        });
        final l = lookupAppLocalizations(Locale(lang));
        await t.pumpWidget(
          host(
            lang,
            ServiceRunsScreen(bus: repo.get('buses', 'b1'), service: service),
          ),
        );
        await t.pumpAndSettle();
        expect(find.text(l.adminDatedDepartures), findsOneWidget);
        await t.scrollUntilVisible(
          find.textContaining(l.adminRunBoarding),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await t.scrollUntilVisible(
          find.text(l.adminLateReason('Original driver reason')),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        expect(t.takeException(), isNull);
        expect(find.text(l.adminRunEmpty), findsNothing);
      },
    );
    testWidgets(
      'calendar stale timetable error $lang is localized without generating runs',
      (t) async {
        t.view.physicalSize = const Size(320, 1500);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final repo = adminFixture();
        addTearDown(repo.dispose);
        final service = AdminService(repo), bus = repo.get('buses', 'b1');
        await service.publishServiceSchedule(
          bus,
          from: DateTime(2026, 10, 19),
          until: DateTime(2026, 10, 20),
          weekdays: {1},
          departureMinutes: 480,
        );
        repo.seed('buses', 'b1', {
          ...bus.data,
          'scheduleTimes': ['23:50', '00:15'],
        });
        final l = lookupAppLocalizations(Locale(lang));
        await t.pumpWidget(
          host(lang, ServiceCalendarScreen(bus: bus, service: service)),
        );
        await t.pumpAndSettle();
        await t.scrollUntilVisible(
          find.text(l.calendarGenerate),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await t.pumpAndSettle();
        await t.tap(find.text(l.calendarGenerate));
        await t.pumpAndSettle();
        await t.scrollUntilVisible(
          find.text(l.adminCalendarBusChanged),
          -150,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(l.adminCalendarBusChanged), findsOneWidget);
        expect(repo.data['service_runs'], isNull);
        expect(t.takeException(), isNull);
      },
    );
    testWidgets(
      'unknown run status $lang never claims scheduled or completed',
      (t) async {
        final l = lookupAppLocalizations(Locale(lang));
        await t.pumpWidget(
          host(
            lang,
            Builder(
              builder: (c) => Scaffold(
                body: Text(c.adminRunStatus('future-unknown-state')),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.text(l.adminRunUnknown), findsOneWidget);
      },
    );
  }
  testWidgets(
    'dated loading failure is distinct from no departures and blocks publish while loading',
    (t) async {
      t.view.physicalSize = const Size(600, 1800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final base = adminFixture();
      addTearDown(base.dispose);
      final repo = WaitingRepository(base);
      await t.pumpWidget(
        MaterialApp(
          home: ServiceRunsScreen(
            bus: base.get('buses', 'b1'),
            service: AdminService(repo),
          ),
        ),
      );
      await t.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
        t
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Publish dated departure'),
            )
            .onPressed,
        isNull,
      );
      expect(find.text('No dated departures for this bus.'), findsNothing);
      repo.runs.completeError(StateError('offline'));
      await t.pumpAndSettle();
      expect(
        find.text('Could not load dated departures. Retry when online.'),
        findsOneWidget,
      );
      expect(find.text('No dated departures for this bus.'), findsNothing);
      expect(base.actions, isEmpty);
    },
  );
}
