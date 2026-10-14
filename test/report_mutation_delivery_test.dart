import 'dart:async';

import 'package:access_transit/logic/report_mutation.dart';
import 'package:access_transit/logic/status_logic.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/screens/community/report_details_screen.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Report report(String id) => Report(
  id: id,
  targetType: 'bus',
  targetId: 'bus177',
  targetName: 'Bus 177',
  problemType: 'Ramp Broken',
  status: 'active',
  createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
  userId: 'author',
);

void main() {
  test(
    'resolution serializes who/when without inventing fields on legacy reports',
    () {
      final original = report('resolution_model');
      final now = DateTime.now();
      final resolved = ReportMutationPlan.apply(
        original,
        'author',
        ReportMutationAction.resolve,
        now,
      ).after;
      final restored = Report.fromMap(resolved.toMap(), id: original.id);
      expect(restored.resolvedBy, 'author');
      expect(restored.resolvedAt, now);
      expect(restored.copyWith(description: 'Note').resolvedAt, now);
      expect(Report.fromMap(original.toMap()).resolvedBy, isNull);
      expect(Report.fromMap(original.toMap()).resolvedAt, isNull);
    },
  );
  test('author-only resolution, owner vote rejection and guest rejection', () {
    final r = report('permissions');
    final now = DateTime.now();
    expect(
      () => ReportMutationPlan.apply(
        r,
        'other',
        ReportMutationAction.resolve,
        now,
      ),
      throwsStateError,
    );
    expect(
      () => ReportMutationPlan.apply(
        r,
        'author',
        ReportMutationAction.confirm,
        now,
      ),
      throwsStateError,
    );
    expect(
      () =>
          ReportMutationPlan.apply(r, 'author', ReportMutationAction.flag, now),
      throwsStateError,
    );
    expect(
      () => ReportMutationPlan.apply(r, '', ReportMutationAction.confirm, now),
      throwsStateError,
    );
  });
  test('vote reversal preserves other voters and clears untraceable aggregate confirmation time', () {
    final now = DateTime.now();
    final r = report(
      'reverse',
    ).copyWith(confirmedBy: ['a', 'b'], confirmCount: 2, lastConfirmedAt: now);
    final flagged = ReportMutationPlan.apply(
      r,
      'a',
      ReportMutationAction.flag,
      now,
    ).after;
    expect(flagged.confirmedBy, ['b']);
    expect(flagged.confirmCount, 1);
    expect(flagged.falseCount, 1);
    expect(flagged.lastConfirmedAt, isNull);
    expect(StatusLogic.lastCheckedAt(flagged), r.createdAt);
    final confirmed = ReportMutationPlan.apply(
      flagged,
      'a',
      ReportMutationAction.confirm,
      now,
    ).after;
    expect(confirmed.confirmedBy, ['b', 'a']);
    expect(confirmed.falseCount, 0);
    expect(confirmed.flaggedBy, isEmpty);
  });
  test(
    'duplicate retry preserves totals, recorded check time and resolution time',
    () {
      final now = DateTime.now();
      final initial = report('duplicate');
      final checked = ReportMutationPlan.apply(
        initial,
        'a',
        ReportMutationAction.confirm,
        now,
      ).after;
      final retry = ReportMutationPlan.apply(
        checked,
        'a',
        ReportMutationAction.confirm,
        now.add(const Duration(hours: 1)),
      );
      expect(retry.changed, isFalse);
      expect(retry.after.lastConfirmedAt, now);
      expect(retry.after.confirmCount, 1);
      final resolved = ReportMutationPlan.apply(
        initial,
        'author',
        ReportMutationAction.resolve,
        now,
      ).after;
      final repeated = ReportMutationPlan.apply(
        resolved,
        'author',
        ReportMutationAction.resolve,
        now.add(const Duration(hours: 1)),
      );
      expect(repeated.changed, isFalse);
      expect(repeated.after.resolvedAt, now);
    },
  );
  test('third flag retains hidden record and a duplicate cannot create another flag', () {
    final now = DateTime.now();
    var r = report('hidden');
    for (final actor in ['a', 'b', 'c']) {
      r = ReportMutationPlan.apply(
        r,
        actor,
        ReportMutationAction.flag,
        now,
      ).after;
    }
    expect(r.status, 'hidden');
    expect(r.falseCount, 3);
    expect(r.flaggedBy, ['a', 'b', 'c']);
    expect(
      ReportMutationPlan.apply(r, 'c', ReportMutationAction.flag, now).changed,
      isFalse,
    );
    expect(
      () => ReportMutationPlan.apply(r, 'd', ReportMutationAction.flag, now),
      throwsStateError,
    );
  });
  test(
    'inconsistent totals cannot be written as an acknowledged observation',
    () {
      final r = report('invalid')
          .copyWith(confirmCount: 99, confirmedBy: ['a']);
      expect(
        () => ReportMutationPlan.apply(
          r,
          'b',
          ReportMutationAction.confirm,
          DateTime.now(),
        ),
        throwsStateError,
      );
    },
  );
  test('a saved transaction with unavailable exact details does not fabricate a check timestamp', () {
    const result = ReportMutationResult(
      action: ReportMutationAction.confirm,
      changed: true,
    );
    expect(result.report, isNull);
    expect(result.message, contains('Shared details will refresh'));
  });

  for (final action in ReportMutationAction.values) {
    test(
      'failed ${action.name} does not alter cache, votes, status or timestamp',
      () async {
        final r = report('failed_${action.name}');
        final actor = action == ReportMutationAction.resolve
            ? 'author'
            : 'voter';
        final service = FirestoreService(
          reportWriter: (_) async {},
          reportActorId: () => actor,
          reportMutationWriter: (_) async => throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        );
        await service.createReport(r);
        final task = switch (action) {
          ReportMutationAction.confirm => service.confirmReport(r.id, actor),
          ReportMutationAction.flag => service.flagReport(r.id, actor),
          ReportMutationAction.resolve => service.resolveReport(r.id),
        };
        await expectLater(task, throwsA(isA<FirebaseException>()));
        final cached = (await service.streamReportById(r.id).first)!;
        expect(cached.status, 'active');
        expect(cached.confirmCount, 0);
        expect(cached.falseCount, 0);
        expect(cached.lastConfirmedAt, isNull);
        expect(cached.resolvedAt, isNull);
      },
    );
  }
  test('mutations require the current authenticated actor, not a claimed guest/other UID', () async {
    var calls = 0;
    final service = FirestoreService(
      reportActorId: () => null,
      reportMutationWriter: (plan) async {
        calls++;
        return ReportMutationResult(
          action: plan.action,
          changed: true,
          report: plan.after,
        );
      },
    );
    await expectLater(
      service.confirmReport('id', 'guest_user'),
      throwsStateError,
    );
    await expectLater(service.resolveReport('id'), throwsStateError);
    final other = FirestoreService(reportActorId: () => 'rider');
    await expectLater(other.flagReport('id', 'someone_else'), throwsStateError);
    expect(calls, 0);
  });
  test('confirmation stays unchanged until writer acknowledgement, then streams update', () async {
    final ack = Completer<ReportMutationResult>();
    ReportMutationPlan? attempted;
    final service = FirestoreService(
      reportWriter: (_) async {},
      reportActorId: () => 'voter',
      reportMutationWriter: (plan) {
        attempted = plan;
        return ack.future;
      },
    );
    final r = report('ack_gate');
    await service.createReport(r);
    final events = <Report?>[];
    final sub = service.streamReportById(r.id).listen(events.add);
    final task = service.confirmReport(r.id, 'voter');
    await Future<void>.delayed(Duration.zero);
    expect(events.last!.confirmCount, 0);
    expect(
      (await service.streamReportById(r.id).first)!.lastConfirmedAt,
      isNull,
    );
    ack.complete(
      ReportMutationResult(
        action: attempted!.action,
        changed: true,
        report: attempted!.after,
      ),
    );
    await task;
    await Future<void>.delayed(Duration.zero);
    expect(events.last!.confirmCount, 1);
    expect(events.last!.confirmedBy, ['voter']);
    await sub.cancel();
  });
  test('successful resolution updates already-subscribed lists and preserves source details', () async {
    final service = FirestoreService(
      reportWriter: (_) async {},
      reportActorId: () => 'author',
      reportMutationWriter: (plan) async => ReportMutationResult(
        action: plan.action,
        changed: true,
        report: plan.after,
      ),
    );
    final r = report('resolution_stream');
    await service.createReport(r);
    final events = <List<Report>>[];
    final sub = service.streamReports().listen(events.add);
    await service.resolveReport(r.id);
    await Future<void>.delayed(Duration.zero);
    final shared = events.last.firstWhere((x) => x.id == r.id);
    expect(shared.status, 'resolved');
    expect(shared.resolvedBy, 'author');
    expect(shared.resolvedAt, isNotNull);
    expect(shared.targetId, r.targetId);
    expect(shared.problemType, r.problemType);
    await sub.cancel();
  });

  Future<FirestoreService> fixture(
    String id,
    String? actor, {
    Future<ReportMutationResult> Function(ReportMutationPlan)? writer,
  }) async {
    final service = FirestoreService(
      reportWriter: (_) async {},
      reportActorId: () => actor,
      reportMutationWriter:
          writer ??
          (plan) async => ReportMutationResult(
            action: plan.action,
            changed: true,
            report: plan.after,
          ),
    );
    await service.createReport(report(id));
    return service;
  }

  Future<void> show(
    WidgetTester tester,
    FirestoreService service,
    String id, {
    Stream<Report?>? updates,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReportDetailsScreen(
          report: report(id),
          service: service,
          reportUpdates: updates ?? service.streamReportById(id),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<Report?> read(
    WidgetTester tester,
    FirestoreService service,
    String id,
  ) async {
    return tester.runAsync<Report?>(() => service.streamReportById(id).first);
  }

  Future<void> bring(WidgetTester tester, String label) async {
    if (find.text(label).evaluate().isEmpty) {
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
    }
    await tester.scrollUntilVisible(
      find.text(label),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
  }

  Future<void> click(WidgetTester tester, String label) async {
    await bring(tester, label);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'failed confirm shows retry feedback and never claims shared confirmation',
    (tester) async {
      final service = await fixture(
        'ui_fail',
        'voter',
        writer: (_) async => throw StateError('denied'),
      );
      await show(tester, service, 'ui_fail');
      await click(tester, 'True Flag (0)');
      expect(find.textContaining('Change is not confirmed'), findsOneWidget);
      expect(
        find.text('Confirmation saved to the shared report.'),
        findsNothing,
      );
      expect(find.text('True Flag (0)'), findsOneWidget);
      expect((await read(tester, service, 'ui_fail'))!.confirmCount, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'pending confirmation disables both actions; success only follows acknowledgement',
    (tester) async {
      final ack = Completer<ReportMutationResult>();
      ReportMutationPlan? attempted;
      var calls = 0;
      final service = await fixture(
        'ui_pending',
        'voter',
        writer: (plan) {
          calls++;
          attempted = plan;
          return ack.future;
        },
      );
      await show(tester, service, 'ui_pending');
      await bring(tester, 'True Flag (0)');
      await tester.pumpAndSettle();
      await tester.tap(find.text('True Flag (0)'));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find
                  .ancestor(
                    of: find.text('True Flag (0)'),
                    matching: find.byWidgetPredicate((w) => w is FilledButton),
                  )
                  .first,
            )
            .onPressed,
        isNull,
      );
      expect(
        find.text('Confirmation saved to the shared report.'),
        findsNothing,
      );
      ack.complete(
        ReportMutationResult(
          action: attempted!.action,
          changed: true,
          report: attempted!.after,
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(
        find.text('Confirmation saved to the shared report.'),
        findsOneWidget,
      );
      expect((await read(tester, service, 'ui_pending'))!.confirmCount, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'author resolution displays actual recorder/time after acknowledgement',
    (tester) async {
      final service = await fixture('ui_resolve', 'author');
      await show(tester, service, 'ui_resolve');
      await click(tester, 'Mark Condition as Fixed / Resolved');
      expect(
        find.text('Resolution saved to the shared report.'),
        findsOneWidget,
      );
      await bring(tester, 'Resolved by: author');
      await tester.pumpAndSettle();
      expect(find.text('Resolved by: author'), findsOneWidget);
      expect(find.textContaining('Resolved at:'), findsOneWidget);
      expect(
        (await read(tester, service, 'ui_resolve'))!.resolvedAt,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'guest and nonauthor cannot resolve; no fabricated guest vote is emitted',
    (tester) async {
      final service = await fixture('ui_guest', null);
      await show(tester, service, 'ui_guest');
      await bring(tester, 'True Flag (0)');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find
                  .ancestor(
                    of: find.text('True Flag (0)'),
                    matching: find.byWidgetPredicate((w) => w is FilledButton),
                  )
                  .first,
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find
                  .ancestor(
                    of: find.text('Mark Condition as Fixed / Resolved'),
                    matching: find.byWidgetPredicate(
                      (w) => w is OutlinedButton,
                    ),
                  )
                  .first,
            )
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'remote removal does not resurrect the constructor report or active action buttons',
    (tester) async {
      final service = await fixture('ui_deleted', 'voter');
      final updates = StreamController<Report?>();
      await show(tester, service, 'ui_deleted', updates: updates.stream);
      updates.add(report('ui_deleted'));
      await tester.pumpAndSettle();
      updates.add(null);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Shared report unavailable or removed'),
        findsOneWidget,
      );
      expect(find.text('True Flag (0)'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      unawaited(updates.close());
    },
  );
  testWidgets('read errors label last received evidence and disable writes', (
    tester,
  ) async {
    final service = await fixture('ui_read_error', 'voter');
    final updates = StreamController<Report?>();
    await show(tester, service, 'ui_read_error', updates: updates.stream);
    updates.add(report('ui_read_error'));
    await tester.pumpAndSettle();
    updates.addError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Shared updates unavailable'), findsOneWidget);
    await bring(tester, 'True Flag (0)');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find
                .ancestor(
                  of: find.text('True Flag (0)'),
                  matching: find.byWidgetPredicate((w) => w is FilledButton),
                )
                .first,
          )
          .onPressed,
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
    unawaited(updates.close());
  });
}
