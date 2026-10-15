import 'dart:async';

import 'package:access_transit/logic/report_mutation.dart';
import 'package:access_transit/logic/status_logic.dart';
import 'package:access_transit/models/enums/report_condition.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/screens/community/report_details_screen.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:access_transit/widgets/evidence_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 15, 12);
  Report report() => Report(
    id: 'repeat-check',
    targetType: 'bus',
    targetId: 'bus1',
    problemType: 'Ramp Broken',
    condition: ReportCondition.barrier,
    userId: 'author',
    status: 'active',
    createdAt: now.subtract(const Duration(days: 3)),
    lastConfirmedAt: now.subtract(const Duration(days: 2)),
    confirmedBy: const ['rider', 'other'],
    confirmCount: 2,
  );
  ReportMutationPlan recheck(
    Report r, {
    String actor = 'rider',
    DateTime? time,
  }) => ReportMutationPlan.apply(
    r,
    actor,
    ReportMutationAction.recheck,
    time ?? now,
    recheckId: 'check-1',
  );

  test('later recheck refreshes an unresolved barrier without adding a unique vote', () {
    final r = report();
    expect(StatusLogic.needsRecheck(r, currentTime: now), isTrue);
    final plan = recheck(r);
    expect(plan.changed, isTrue);
    expect(plan.after.confirmCount, 2);
    expect(plan.after.confirmedBy, r.confirmedBy);
    expect(plan.after.createdAt, r.createdAt);
    expect(plan.after.lastConfirmedAt, r.lastConfirmedAt);
    expect(plan.after.lastRecheckedAt, now);
    expect(plan.after.lastRecheckedBy, 'rider');
    expect(StatusLogic.lastCheckedAt(plan.after, currentTime: now), now);
    expect(StatusLogic.needsRecheck(plan.after, currentTime: now), isFalse);
    expect(plan.after.observedCondition, ReportCondition.barrier);
    expect(
      ReportMutationResult(
        action: plan.action,
        changed: true,
        report: plan.after,
      ).message,
      contains('points are unchanged'),
    );
  });

  test('legacy model remains unknown and recheck metadata survives map/copy round trips', () {
    expect(Report.fromMap(report().toMap()).lastRecheckedAt, isNull);
    final checked = recheck(report()).after;
    final copy = Report.fromMap(checked.toMap())
        .copyWith(description: 'same condition');
    expect(copy.lastRecheckedAt, now);
    expect(copy.lastRecheckedBy, 'rider');
    expect(copy.lastRecheckId, 'check-1');
    expect(copy.confirmCount, 2);
    final malformed = Report.fromMap({
      ...checked.toMap(),
      'lastRecheckedAt': 'bad-date',
      'lastRecheckedBy': 123,
      'lastRecheckId': [],
    });
    expect(malformed.lastRecheckedAt, isNull);
    expect(
      StatusLogic.lastCheckedAt(malformed, currentTime: now),
      report().lastConfirmedAt,
    );
  });

  test(
    'cooldown includes exact 30 minute boundary and latest report-wide check',
    () {
      final r = report().copyWith(
        lastConfirmedAt: now.subtract(const Duration(minutes: 30)),
      );
      expect(
        recheck(r, time: now.subtract(const Duration(microseconds: 1))).changed,
        isFalse,
      );
      final first = recheck(r).after;
      expect(recheck(first).changed, isFalse);
      expect(
        recheck(
          first,
          actor: 'other',
          time: now.add(const Duration(minutes: 29)),
        ).changed,
        isFalse,
      );
      expect(
        recheck(
          first,
          actor: 'other',
          time: now.add(const Duration(minutes: 30)),
        ).changed,
        isTrue,
      );
      final newVote = ReportMutationPlan.apply(
        first,
        'third',
        ReportMutationAction.confirm,
        now.add(const Duration(minutes: 20)),
      ).after;
      expect(
        ReportRecheck.availableAt(newVote),
        now.add(const Duration(minutes: 50)),
      );
    },
  );

  test('authors, non-confirmers, hidden/resolved/undated/inconsistent records cannot recheck', () {
    for (final actor in ['author', 'stranger', '']) {
      expect(() => recheck(report(), actor: actor), throwsStateError);
    }
    for (final r in [
      report().copyWith(status: 'resolved'),
      report().copyWith(status: 'hidden'),
      report().copyWith(clearCreatedAt: true),
      report().copyWith(confirmCount: 99),
      report().copyWith(isDemo: true),
      report().copyWith(falseCount: 3, flaggedBy: ['a', 'b', 'c']),
    ]) {
      expect(() => recheck(r), throwsStateError);
    }
  });

  test(
    'unattributed, future and reversed rechecks cannot manufacture freshness',
    () {
      final checked = recheck(report()).after;
      for (final r in [
        checked.copyWith(lastRecheckedAt: now.add(const Duration(minutes: 1))),
        checked.copyWith(lastRecheckId: ''),
        checked.copyWith(lastRecheckedBy: 'stranger'),
        checked.copyWith(clearCreatedAt: true),
      ]) {
        expect(StatusLogic.isReportFresh(r, currentTime: now), isFalse);
      }
      final flagged = ReportMutationPlan.apply(
        checked,
        'rider',
        ReportMutationAction.flag,
        now,
      ).after;
      expect(StatusLogic.needsRecheck(flagged, currentTime: now), isTrue);
      expect(flagged.confirmCount, 1);
    },
  );

  test('acknowledged service recheck caches receipt and immediate retry is idempotent', () async {
    var writes = 0;
    final service = FirestoreService(
      reportActorId: () => 'rider',
      reportWriter: (_) async {},
      reportMutationWriter: (plan) async {
        writes++;
        expect(plan.after.confirmCount, plan.before.confirmCount);
        return ReportMutationResult(
          action: plan.action,
          changed: true,
          report: plan.after,
        );
      },
    );
    final r = report().copyWith(id: 'service-recheck');
    await service.createReport(r);
    expect((await service.recheckReport(r.id, 'rider')).changed, isTrue);
    expect((await service.recheckReport(r.id, 'rider')).changed, isFalse);
    expect(writes, 1);
    final saved = await service.streamReportById(r.id).first;
    expect(saved!.confirmCount, 2);
    expect(saved.lastRecheckedAt, isNotNull);
    await expectLater(service.recheckReport(r.id, 'other'), throwsStateError);
  });

  testWidgets(
    'previous confirmer can recheck from details and waits for acknowledgement',
    (tester) async {
      final r = report().copyWith(id: 'widget-recheck');
      final receipt = Completer<ReportMutationResult>();
      ReportMutationPlan? sent;
      final service = FirestoreService(
        reportActorId: () => 'rider',
        reportWriter: (_) async {},
        reportMutationWriter: (plan) {
          sent = plan;
          return receipt.future;
        },
      );
      await service.createReport(r);
      await tester.pumpWidget(
        MaterialApp(
          home: EvidenceClock(
            now: () => now,
            child: ReportDetailsScreen(
              report: r,
              service: service,
              reportUpdates: service.streamReportById(r.id),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.widgetWithText(FilledButton, 'Recheck condition');
      await tester.scrollUntilVisible(
        find.text('Recheck condition'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(sent!.action, ReportMutationAction.recheck);
      expect(find.textContaining('Recheck saved.'), findsNothing);
      receipt.complete(
        ReportMutationResult(
          action: sent!.action,
          changed: true,
          report: sent!.after,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Recheck saved.'), findsOneWidget);
      expect(sent!.after.confirmCount, 2);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'cooldown disables the action and expiry enables it without a data event',
    (tester) async {
      var time = now;
      final r = report().copyWith(
        lastConfirmedAt: now.subtract(const Duration(minutes: 29, seconds: 59)),
      );
      final service = FirestoreService(reportActorId: () => 'rider');
      final updates = StreamController<Report?>();
      await tester.pumpWidget(
        MaterialApp(
          home: EvidenceClock(
            now: () => time,
            child: ReportDetailsScreen(
              report: r,
              service: service,
              reportUpdates: updates.stream,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.widgetWithText(FilledButton, 'Recheck condition');
      await tester.scrollUntilVisible(
        find.text('Recheck condition'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      time = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
      await tester.pumpWidget(const SizedBox());
      unawaited(updates.close());
    },
  );
}
