import 'dart:typed_data';

import 'package:access_transit/core/utils/time_utils.dart';
import 'package:access_transit/logic/live_accessibility_evidence.dart';
import 'package:access_transit/logic/report_mutation.dart';
import 'package:access_transit/logic/status_logic.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/models/enums/report_publication_state.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:access_transit/services/report_submission_service.dart';
import 'package:access_transit/widgets/accessibility_evidence_card.dart';
import 'package:access_transit/screens/community/report_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 10, 15, 12);
  Report parse([Map<String, dynamic> extra = const {}]) => Report.fromMap({
    'id': 'unknown-date',
    'userId': 'owner',
    'targetType': 'bus',
    'targetId': 'bus',
    'category': 'rampAccess',
    'problemType': 'Ramp Working',
    'condition': 'positive',
    'status': 'active',
    ...extra,
  });

  test('missing, malformed and overflowing dates stay unknown after repeated parsing', () {
    for (final value in [
      null,
      false,
      {},
      [],
      2.5,
      'yesterday',
      '',
      '2026-02-30T10:00:00Z',
      '2026-10-15T25:00:00Z',
      9223372036854775807,
    ]) {
      final report = parse({'createdAt': value});
      expect(report.createdAt, isNull, reason: '$value');
      final restored = Report.fromMap(report.toMap());
      expect(restored.createdAt, isNull);
      expect(report.copyWith(status: 'active').createdAt, isNull);
      expect(report.toMap(isServerTimestamp: true)['createdAt'], isNull);
    }
  });

  test('Firestore, local DateTime, ISO and epoch timestamps retain their actual instant', () {
    for (final value in [
      now,
      Timestamp.fromDate(now),
      now.toIso8601String(),
      now.millisecondsSinceEpoch,
    ]) {
      expect(parse({'createdAt': value}).createdAt, now);
    }
    expect(
      parse({'createdAt': '2026-10-15T12:00:00+05:30'}).createdAt,
      DateTime.utc(2026, 10, 15, 6, 30),
    );
    expect(parse({'createdAt': 0}).createdAt!.millisecondsSinceEpoch, 0);
  });

  test('unknown creation cannot become fresh via a recent confirmation', () {
    final report = parse({
      'lastConfirmedAt': Timestamp.fromDate(now),
      'confirmedBy': ['rider'],
      'confirmCount': 1,
    });
    expect(StatusLogic.lastCheckedAt(report, currentTime: now), isNull);
    expect(StatusLogic.isReportFresh(report, currentTime: now), isFalse);
    expect(StatusLogic.hasFreshCrowding(report, currentTime: now), isFalse);
    expect(StatusLogic.isReportActive(report, currentTime: now), isFalse);
    expect(StatusLogic.freshUntil(report, currentTime: now), isNull);
    expect(TimeUtils.formatRelativeTime(report.createdAt), 'Unknown');
    expect(
      LiveAccessibilityEvidence.forEquipment(
        reports: [report],
        targetType: 'bus',
        targetId: 'bus',
        category: 'rampAccess',
        now: now,
      ).state,
      EquipmentObservation.unknown,
    );
  });

  test('undated structural faults persist as unresolved warnings without fresh evidence', () {
    final report = parse({
      'condition': 'barrier',
      'problemType': 'Ramp Broken',
    });
    expect(StatusLogic.isReportActive(report, currentTime: now), isTrue);
    expect(StatusLogic.needsRecheck(report, currentTime: now), isTrue);
    expect(StatusLogic.isReportFresh(report, currentTime: now), isFalse);
    expect(
      StatusLogic.freshnessLabel(report, currentTime: now),
      contains('time unknown'),
    );
    expect(
      LiveAccessibilityEvidence.forEquipment(
        reports: [report],
        targetType: 'bus',
        targetId: 'bus',
        category: 'rampAccess',
        now: now,
      ).state,
      EquipmentObservation.unresolved,
    );
    expect(
      StatusLogic.isReportActive(
        report.copyWith(status: 'resolved'),
        currentTime: now,
      ),
      isFalse,
    );
  });

  test('unknown dates sort last and mutation/publication cannot manufacture check times', () async {
    final undated = parse();
    final dated = parse({'createdAt': now});
    final sorted = [undated, dated]
      ..sort((a, b) => Report.compareDatesDescending(a.createdAt, b.createdAt));
    expect(sorted.first, dated);
    expect(
      () => ReportMutationPlan.apply(
        undated,
        'rider',
        ReportMutationAction.confirm,
        now,
      ),
      throwsStateError,
    );
    await expectLater(
      FirestoreService(reportWriter: (_) async => fail('Must not publish'))
          .createReport(undated),
      throwsStateError,
    );
  });

  test('undated outbox entries fail before uploading or publishing and retain unknown time', () async {
    SharedPreferences.setMockInitialValues({});
    final service = ReportSubmissionService(
      photoUploader: (_, _) async => fail('Must not upload'),
      publisher: (_) async => fail('Must not publish'),
    );
    final entry = await service.submit(
      parse(),
      photoBytes: Uint8List.fromList([1, 2]),
    );
    expect(entry.report.publicationState, ReportPublicationState.failed);
    expect(entry.report.createdAt, isNull);
    expect(entry.error, contains('Observation time unknown'));
    final restored = ReportSubmissionService();
    await restored.init();
    expect(restored.entries.single.report.createdAt, isNull);
    service.dispose();
    restored.dispose();
  });

  testWidgets(
    'evidence card shows unknown observation and expiry dates without fresh claims',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AccessibilityEvidenceCard(
                initiallyExpanded: true,
                reports: [parse()],
                busId: 'bus',
                origin: 'a',
                destination: 'b',
                currentTime: now,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Last checked: Unknown'), findsOneWidget);
      expect(find.text('Reported at: Unknown'), findsOneWidget);
      expect(find.text('Observation expires: Unknown'), findsOneWidget);
      expect(find.textContaining('community-confirmed'), findsNothing);
    },
  );

  testWidgets(
    'report details label unknown time without claiming archived or recent condition',
    (tester) async {
      final report = parse();
      await tester.pumpWidget(
        MaterialApp(
          home: ReportDetailsScreen(
            report: report,
            reportUpdates: Stream.value(report),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Observation time unknown'), findsOneWidget);
      expect(find.text('Past Report (Expired)'), findsNothing);
      expect(find.text('Active Transit Alert'), findsNothing);
    },
  );
}
