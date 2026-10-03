import 'package:access_transit/models/report.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirestoreService Report Tests', () {
    late FirestoreService service;

    setUp(() {
      service = FirestoreService();
    });

    test('createReport adds report and streamReports yields it', () async {
      final testReport = Report(
        id: 'test_report_101',
        targetType: 'station',
        targetId: 'st_fort',
        problemType: 'Ramp broken test',
        status: 'active',
        createdAt: DateTime.now(),
        userId: 'user_test_1',
      );

      await service.createReport(testReport);

      final reports = await service.streamReports().first;
      expect(reports.any((r) => r.id == 'test_report_101'), isTrue);
      final found = reports.firstWhere((r) => r.id == 'test_report_101');
      expect(found.problemType, equals('Ramp broken test'));
      expect(found.targetId, equals('st_fort'));
    });

    test('createReport stores subCategory and photoUrl in Firestore', () async {
      final testReport = Report(
        id: 'test_report_subcategory_101',
        targetType: 'station',
        targetId: 'st_fort',
        problemType: 'Ramp broken / deployment motor jammed',
        category: 'rampAccess',
        subCategory: 'Ramp broken / deployment motor jammed',
        photoUrl: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957',
        status: 'active',
        createdAt: DateTime.now(),
        userId: 'user_test_sub',
      );

      await service.createReport(testReport);

      final reports = await service.streamReports().first;
      final found = reports.firstWhere((r) => r.id == 'test_report_subcategory_101');
      expect(found.subCategory, equals('Ramp broken / deployment motor jammed'));
      expect(found.photoUrl, equals('https://images.unsplash.com/photo-1544620347-c4fd4a3d5957'));
    });

    test('checkRateLimit returns true when user submitted report within 15 minutes', () async {
      final userId = 'user_rate_limit_${DateTime.now().millisecondsSinceEpoch}';
      final targetId = 'st_ Pettah';

      final isLimitedBefore = await service.checkRateLimit(userId, targetId);
      expect(isLimitedBefore, isFalse);

      final report = Report(
        id: 'rate_report_1',
        targetType: 'station',
        targetId: targetId,
        problemType: 'Elevator down',
        status: 'active',
        createdAt: DateTime.now(),
        userId: userId,
      );

      await service.createReport(report);

      final isLimitedAfter = await service.checkRateLimit(userId, targetId);
      expect(isLimitedAfter, isTrue);
    });

    test('confirmReport increments confirmCount and tracks user', () async {
      final reportId = 'test_report_confirm_${DateTime.now().millisecondsSinceEpoch}';
      final report = Report(
        id: reportId,
        targetType: 'bus',
        targetId: 'bus_100',
        problemType: 'Door stuck',
        status: 'active',
        createdAt: DateTime.now(),
        confirmCount: 0,
        confirmedBy: const [],
        userId: 'creator_1',
      );

      await service.createReport(report);
      await service.confirmReport(reportId, 'confirmer_1');

      final reports = await service.streamReports().first;
      final updated = reports.firstWhere((r) => r.id == reportId);

      expect(updated.confirmCount, equals(1));
      expect(updated.confirmedBy.contains('confirmer_1'), isTrue);
    });

    test('resolveReport sets report status to resolved', () async {
      final reportId = 'test_report_resolve_${DateTime.now().millisecondsSinceEpoch}';
      final report = Report(
        id: reportId,
        targetType: 'station',
        targetId: 'st_maradana',
        problemType: 'Scaffolding blocking entrance',
        status: 'active',
        createdAt: DateTime.now(),
        userId: 'creator_2',
      );

      await service.createReport(report);
      await service.resolveReport(reportId);

      final reports = await service.streamReports(status: 'resolved').first;
      expect(reports.any((r) => r.id == reportId), isTrue);
    });

    test('flagReport hides report when false count reaches 3', () async {
      final reportId = 'test_report_flag_${DateTime.now().millisecondsSinceEpoch}';
      final report = Report(
        id: reportId,
        targetType: 'bus',
        targetId: 'bus_138',
        problemType: 'Fake issue',
        status: 'active',
        createdAt: DateTime.now(),
        falseCount: 0,
        flaggedBy: const [],
        userId: 'creator_3',
      );

      await service.createReport(report);
      await service.flagReport(reportId, 'flagger_1');
      await service.flagReport(reportId, 'flagger_2');
      await service.flagReport(reportId, 'flagger_3');

      final reports = await service.streamReports().first;
      // Hidden reports are excluded from stream
      expect(reports.any((r) => r.id == reportId), isFalse);
    });
  });
}
