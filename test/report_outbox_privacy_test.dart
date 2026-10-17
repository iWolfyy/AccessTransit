import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:access_transit/models/report.dart';
import 'package:access_transit/models/enums/report_publication_state.dart';
import 'package:access_transit/services/report_outbox_storage.dart';
import 'package:access_transit/services/report_submission_service.dart';
import 'package:access_transit/screens/journey/report_submitted_screen.dart';
import 'package:access_transit/widgets/report_outbox_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

class MemoryStorage extends ReportOutboxStorage {
  String? value;
  bool failWrite = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    if (failWrite) throw StateError('disk unavailable');
    this.value = value;
  }
}

void main() {
  var now = DateTime(2026, 10, 15, 10);
  Report report(String id, {String owner = 'a'}) => Report(
    id: id,
    targetType: 'station',
    targetId: 'station',
    targetName: 'Private target',
    problemType: 'Ramp Broken',
    description: 'Private note',
    userId: owner,
    status: 'active',
    createdAt: now,
  );
  Future<void> offline(Report _) async =>
      throw FirebaseException(plugin: 'test', code: 'unavailable');
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 10, 15, 10);
  });

  test(
    'acknowledgement erases durable text, URL and image; restart has no draft',
    () async {
      final storage = MemoryStorage();
      final service = ReportSubmissionService(
        storage: storage,
        publisher: (_) async {},
        clock: () => now,
      );
      final result = await service.submit(report('receipt'));
      expect(result.report.publicationState, ReportPublicationState.published);
      expect(storage.value, '[]');
      expect(service.entries, isEmpty);
      expect(service.isAcknowledged('receipt'), isTrue);
      final restored = ReportSubmissionService(
        storage: storage,
        clock: () => now,
      );
      await restored.init();
      expect(restored.entries, isEmpty);
      service.dispose();
      restored.dispose();
    },
  );

  test('seven-day retention uses saved time, survives retry and cleans bytes on disk', () async {
    final storage = MemoryStorage();
    final service = ReportSubmissionService(
      storage: storage,
      publisher: offline,
      photoUploader: (_, _) async =>
          throw FirebaseException(plugin: 'test', code: 'unavailable'),
      clock: () => now,
    );
    await service.submit(
      report('old'),
      photoBytes: Uint8List.fromList([1, 2, 3]),
    );
    now = now.add(const Duration(days: 6));
    await service.retry('old');
    now = now.add(const Duration(days: 1));
    await service.prune();
    expect(service.entries, isEmpty);
    expect(storage.value, '[]');
    await expectLater(service.retry('old'), throwsStateError);
    service.dispose();
  });

  test(
    'ten-draft and photo/note limits reject without evicting existing work',
    () async {
      final service = ReportSubmissionService(
        storage: MemoryStorage(),
        publisher: offline,
        clock: () => now,
      );
      await expectLater(
        service.submit(
          report('large'),
          photoBytes: Uint8List(2 * 1024 * 1024 + 1),
        ),
        throwsArgumentError,
      );
      await expectLater(
        service.submit(report('long').copyWith(description: 'x' * 4001)),
        throwsArgumentError,
      );
      for (var i = 0; i < 10; i++) {
        await service.submit(report('$i'));
      }
      await expectLater(service.submit(report('overflow')), throwsStateError);
      expect(service.entries.length, 10);
      await service.remove('0', userId: 'a');
      await service.submit(report('replacement'));
      expect(service.entries.length, 10);
      service.dispose();
    },
  );

  test(
    'account switch and signout hide and remove other-owner drafts permanently',
    () async {
      final storage = MemoryStorage();
      final service = ReportSubmissionService(
        storage: storage,
        publisher: offline,
        clock: () => now,
      );
      await service.activateAccount('a');
      await service.submit(report('a'));
      await expectLater(service.remove('a', userId: 'b'), throwsStateError);
      await service.activateAccount('b');
      expect(service.find('a'), isNull);
      expect(storage.value, '[]');
      await expectLater(service.submit(report('wrong')), throwsStateError);
      await service.submit(report('b', owner: 'b'));
      await service.activateAccount(null);
      expect(storage.value, '[]');
      await service.activateAccount('a');
      expect(service.entries, isEmpty);
      service.dispose();
    },
  );

  test(
    'removal during photo upload prevents later publish and resurrection',
    () async {
      final storage = MemoryStorage();
      final upload = Completer<String>();
      final started = Completer<void>();
      var published = 0;
      final service = ReportSubmissionService(
        storage: storage,
        clock: () => now,
        photoUploader: (_, _) {
          started.complete();
          return upload.future;
        },
        publisher: (_) async {
          published++;
        },
      );
      final result = service.submit(
        report('race'),
        photoBytes: Uint8List.fromList([1]),
      );
      await started.future;
      final expectation = expectLater(result, throwsStateError);
      await service.remove('race', userId: 'a');
      upload.complete('https://example.com/photo');
      await expectation;
      expect(published, 0);
      expect(storage.value, '[]');
      expect(service.entries, isEmpty);
      service.dispose();
    },
  );

  test(
    'switch during a sent publication cannot restore its local payload',
    () async {
      final storage = MemoryStorage();
      final ack = Completer<void>();
      final started = Completer<void>();
      final service = ReportSubmissionService(
        storage: storage,
        clock: () => now,
        publisher: (_) {
          started.complete();
          return ack.future;
        },
      );
      await service.activateAccount('a');
      final result = service.submit(report('sent'));
      await started.future;
      final expectation = expectLater(result, throwsStateError);
      await service.activateAccount('b');
      ack.complete();
      await expectation;
      expect(storage.value, '[]');
      expect(service.entries, isEmpty);
      service.dispose();
    },
  );

  test('legacy plaintext migration drops acknowledged, expired and malformed entries', () async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> record(Report report, DateTime saved) => {
      'report': {
        'id': report.id,
        'targetType': report.targetType,
        'targetId': report.targetId,
        'problemType': report.problemType,
        'userId': report.userId,
        'status': 'active',
        'createdAt': now.millisecondsSinceEpoch,
        'publicationState': report.publicationState.name,
      },
      'savedAt': saved.toIso8601String(),
      'photo': base64Encode([1, 2]),
    };
    await prefs.setString(
      ReportSubmissionService.storageKey,
      jsonEncode([
        record(
          report('keep')
              .copyWith(publicationState: ReportPublicationState.failed),
          now,
        ),
        record(report('ack'), now),
        record(
          report('expired')
              .copyWith(publicationState: ReportPublicationState.failed),
          now.subtract(const Duration(days: 7)),
        ),
        {'malformed': true},
      ]),
    );
    final storage = MemoryStorage();
    final service = ReportSubmissionService(storage: storage, clock: () => now);
    await service.init();
    expect(service.entries.map((e) => e.report.id), ['keep']);
    expect(service.entries.single.photoBytes, [1, 2]);
    expect(prefs.containsKey(ReportSubmissionService.storageKey), isFalse);
    expect(storage.value, contains('keep'));
    service.dispose();
  });

  test('failed removal save is visible and can be retried', () async {
    final storage = MemoryStorage();
    final service = ReportSubmissionService(
      storage: storage,
      publisher: offline,
      clock: () => now,
    );
    await service.submit(report('draft'));
    storage.failWrite = true;
    await expectLater(service.remove('draft', userId: 'a'), throwsStateError);
    expect(service.find('draft'), isNotNull);
    storage.failWrite = false;
    await service.remove('draft', userId: 'a');
    expect(storage.value, '[]');
    service.dispose();
  });

  testWidgets('uploads provide removal with truthful remote request warning', (
    tester,
  ) async {
    final storage = MemoryStorage();
    final service = ReportSubmissionService(
      storage: storage,
      publisher: offline,
      clock: () => now,
    );
    await service.submit(report('ui'));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportOutboxList(userId: 'a', submissionService: service),
        ),
      ),
    );
    await tester.tap(find.text('Ramp Broken'));
    await tester.pumpAndSettle();
    expect(find.byType(ReportSubmittedScreen), findsOneWidget);
    await tester.ensureVisible(find.text('Remove draft from this device'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove draft from this device'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('request already sent may still complete'),
      findsOneWidget,
    );
    await tester.tap(find.text('Remove draft'));
    await tester.pumpAndSettle();
    expect(find.text('Draft unavailable'), findsOneWidget);
    expect(storage.value, '[]');
    await tester.pumpWidget(const SizedBox.shrink());
    service.dispose();
  });
}
