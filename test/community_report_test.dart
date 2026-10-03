import 'package:access_transit/models/report.dart';
import 'package:access_transit/screens/journey/report_condition_screen.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Community Report Real-World Data & Service Tests', () {
    late FirestoreService service;

    setUp(() {
      service = FirestoreService();
    });

    test('Report model serialization preserves targetName, severity, category, description', () {
      final now = DateTime.now();
      final reportMap = {
        'targetType': 'station',
        'targetId': 'st_fort',
        'targetName': 'Colombo Fort Main Terminal',
        'problemType': 'Elevator out of service',
        'severity': 'major',
        'category': 'elevatorOut',
        'description': 'Elevator 2 near platform 1 is stuck.',
        'status': 'active',
        'createdAt': now.toIso8601String(),
        'lastConfirmedAt': null,
        'confirmCount': 2,
        'falseCount': 0,
        'userId': 'usr_test_1',
        'confirmedBy': ['usr_test_1'],
        'flaggedBy': [],
      };

      final report = Report.fromMap(reportMap, id: 'rep_test_001');

      expect(report.id, equals('rep_test_001'));
      expect(report.targetType, equals('station'));
      expect(report.targetId, equals('st_fort'));
      expect(report.targetName, equals('Colombo Fort Main Terminal'));
      expect(report.problemType, equals('Elevator out of service'));
      expect(report.severity, equals('major'));
      expect(report.category, equals('elevatorOut'));
      expect(report.description, equals('Elevator 2 near platform 1 is stuck.'));
      expect(report.status, equals('active'));

      final map = report.toMap();
      expect(map['targetName'], equals('Colombo Fort Main Terminal'));
      expect(map['severity'], equals('major'));
      expect(map['category'], equals('elevatorOut'));
      expect(map['description'], equals('Elevator 2 near platform 1 is stuck.'));
    });

    test('FirestoreService createReport stores and streams new report', () async {
      final newReport = Report(
        id: 'rep_test_create_99',
        targetType: 'station',
        targetId: 'st_maradana',
        targetName: 'Maradana Station',
        problemType: 'Ramp broken',
        severity: 'moderate',
        category: 'rampAccess',
        description: 'Main ramp board cracked',
        status: 'active',
        createdAt: DateTime.now(),
        userId: 'test_user_77',
      );

      await service.createReport(newReport);

      final reports = await service.streamReports().first;
      final match = reports.firstWhere((r) => r.id == 'rep_test_create_99');
      expect(match.targetName, equals('Maradana Station'));
      expect(match.description, equals('Main ramp board cracked'));
    });

    test('FirestoreService checkRateLimit enforces 15-minute window for target', () async {
      final userId = 'rate_limit_user_${DateTime.now().millisecondsSinceEpoch}';
      final targetId = 'st_rate_limit_target';

      final freshReport = Report(
        id: 'rep_rate_limit_1',
        targetType: 'station',
        targetId: targetId,
        targetName: 'Test Target Station',
        problemType: 'Crowding',
        severity: 'minor',
        category: 'crowding',
        status: 'active',
        createdAt: DateTime.now(),
        userId: userId,
      );

      await service.createReport(freshReport);

      final isLimited = await service.checkRateLimit(userId, targetId, thresholdMinutes: 15);
      expect(isLimited, isTrue);

      final isDifferentTargetLimited = await service.checkRateLimit(
        userId,
        'different_target_id',
        thresholdMinutes: 15,
      );
      expect(isDifferentTargetLimited, isFalse);
    });

    test('FirestoreService confirmReport, resolveReport, flagReport update report state', () async {
      final reportId = 'rep_action_test_100';
      final testReport = Report(
        id: reportId,
        targetType: 'bus',
        targetId: 'bus_138_test',
        targetName: 'Bus Route 138',
        problemType: 'Safety hazard on floor',
        severity: 'major',
        category: 'safetyHazard',
        status: 'active',
        createdAt: DateTime.now(),
        userId: 'creator_1',
        confirmCount: 0,
        falseCount: 0,
        confirmedBy: [],
        flaggedBy: [],
      );

      await service.createReport(testReport);

      // Confirm
      await service.confirmReport(reportId, 'reviewer_user_1');
      var updated = await service.streamReportById(reportId).first;
      expect(updated?.confirmCount, equals(1));
      expect(updated?.confirmedBy, contains('reviewer_user_1'));

      // Resolve
      await service.resolveReport(reportId);
      updated = await service.streamReportById(reportId).first;
      expect(updated?.status, equals('resolved'));

      // Flag to hidden threshold (3 flags)
      final flagReportId = 'rep_flag_test_200';
      await service.createReport(testReport.copyWith(id: flagReportId, status: 'active'));
      
      await service.flagReport(flagReportId, 'flagger_1');
      await service.flagReport(flagReportId, 'flagger_2');
      await service.flagReport(flagReportId, 'flagger_3');

      final flaggedDoc = await service.streamReportById(flagReportId).first;
      expect(flaggedDoc, isNull);
    });

    testWidgets('ReportConditionScreen target selection and photo upload sheet rendering test', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportConditionScreen(
            targetType: 'bus',
            initialLocation: 'Bus Route 100',
          ),
        ),
      );
      await tester.pump();

      // Check title and target chips
      expect(find.text('Report a Condition'), findsOneWidget);
      expect(find.text('Station / Stop'), findsOneWidget);
      expect(find.text('Bus Route / Vehicle'), findsOneWidget);

      // Check Location textfield
      expect(find.text('Bus Route 100'), findsOneWidget);
    });
  });
}
