import 'dart:async';
import 'dart:typed_data';

import 'package:access_transit/data/seed_data.dart';
import 'package:access_transit/logic/report_cooldown.dart';
import 'package:access_transit/logic/status_logic.dart';
import 'package:access_transit/models/enums/report_publication_state.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:access_transit/services/report_submission_service.dart';
import 'package:access_transit/services/report_photo_storage.dart';
import 'package:access_transit/services/moderation_client.dart';
import 'package:access_transit/screens/journey/report_submitted_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Report report() => Report(
    id: '',
    targetType: 'station',
    targetId: 'station',
    problemType: 'Ramp Working',
    status: 'active',
    createdAt: DateTime.now(),
    userId: 'owner',
  );
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'v2 publication failures retain safe codes and retry the same draft',
    () async {
      for (final code in [
        'service-unavailable',
        'backend-not-configured',
        'report-ineligible',
        'authentication-required',
      ]) {
        var unavailable = true;
        final service = ReportSubmissionService(
          publisher: (_) async {
            if (unavailable) throw ModerationException(code);
          },
        );
        final entry = await service.submit(report());
        expect(entry.error, 'publication:$code');
        expect(
          entry.report.publicationState,
          code == 'service-unavailable'
              ? ReportPublicationState.pendingUpload
              : ReportPublicationState.failed,
        );
        expect(entry.report.isPublic, isFalse);
        unavailable = false;
        final retried = await service.retry(entry.report.id);
        expect(retried.report.id, entry.report.id);
        expect(
          retried.report.publicationState,
          ReportPublicationState.published,
        );
        service.dispose();
      }
    },
  );

  test('cooldown denial preserves draft identity and deadline until a successful retry', () async {
    final deadline = DateTime.utc(2026, 10, 16, 12);
    var denied = true;
    final service = ReportSubmissionService(
      publisher: (_) async {
        if (denied) throw ReportCooldownException(deadline);
      },
    );
    final result = await service.submit(report());
    expect(result.report.publicationState, ReportPublicationState.failed);
    expect(result.error, contains('2026-10-16T12:00:00.000Z'));
    expect(result.report.isPublic, isFalse);
    denied = false;
    final retried = await service.retry(result.report.id);
    expect(retried.report.id, result.report.id);
    expect(retried.report.publicationState, ReportPublicationState.published);
    service.dispose();
  });

  test(
    'Cloudinary rate limits keep photos pending; invalid preset fails',
    () async {
      for (final status in [429, 400]) {
        final service = ReportSubmissionService(
          photoUploader: (_, _) async => throw PhotoUploadException(status),
          publisher: (_) async => fail('Photo failure must not publish'),
        );
        final entry = await service.submit(
          report(),
          photoBytes: Uint8List.fromList([1, 2]),
        );
        expect(
          entry.report.publicationState,
          status == 429
              ? ReportPublicationState.pendingUpload
              : ReportPublicationState.failed,
        );
        expect(entry.photoBytes, [1, 2]);
        expect(entry.report.isPublic, isFalse);
        service.dispose();
      }
    },
  );

  test('publication waits for upload and cloud acknowledgement', () async {
    final started = Completer<void>();
    final ack = Completer<void>();
    final order = <String>[];
    final service = ReportSubmissionService(
      photoUploader: (r, bytes) async {
        order.add('photo');
        return 'https://example.com/shared.jpg';
      },
      publisher: (r) async {
        order.add('report');
        expect(r.photoUrl, 'https://example.com/shared.jpg');
        started.complete();
        await ack.future;
      },
    );
    final result = service.submit(
      report(),
      photoBytes: Uint8List.fromList([1, 2]),
    );
    await started.future;
    expect(
      service.entries.single.report.publicationState,
      ReportPublicationState.pendingUpload,
    );
    expect(service.entries.single.report.isPublic, false);
    ack.complete();
    expect(
      (await result).report.publicationState,
      ReportPublicationState.published,
    );
    expect(order, ['photo', 'report']);
    service.dispose();
  });

  test(
    'network failure restores durable photo bytes and stable ID after restart',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final original = ReportSubmissionService(
        photoUploader: (_, _) async {
          throw FirebaseException(
            plugin: 'firebase_storage',
            code: 'network-request-failed',
          );
        },
        publisher: (_) async => fail('Cannot publish before the photo upload'),
      );
      await original.init(prefs: prefs);
      final pending = await original.submit(
        report(),
        photoBytes: Uint8List.fromList([1, 2, 3]),
      );
      expect(
        pending.report.publicationState,
        ReportPublicationState.pendingUpload,
      );
      original.dispose();
      final restored = ReportSubmissionService(
        photoUploader: (r, bytes) async {
          expect(bytes, [1, 2, 3]);
          return 'https://example.com/shared.jpg';
        },
        publisher: (_) async {},
      );
      await restored.init(prefs: prefs);
      final published = await restored.retry(pending.report.id);
      expect(published.report.id, pending.report.id);
      expect(
        published.report.publicationState,
        ReportPublicationState.published,
      );
      restored.dispose();
    },
  );

  test(
    'Firestore failure keeps the uploaded URL; retry does not upload twice',
    () async {
      var uploads = 0;
      var writes = 0;
      final service = ReportSubmissionService(
        photoUploader: (_, _) async {
          uploads++;
          return 'https://example.com/shared.jpg';
        },
        publisher: (_) async {
          if (++writes == 1) {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'unavailable',
            );
          }
        },
      );
      final pending = await service.submit(
        report(),
        photoBytes: Uint8List.fromList([1]),
      );
      expect(
        pending.report.publicationState,
        ReportPublicationState.pendingUpload,
      );
      expect(pending.report.photoUrl, 'https://example.com/shared.jpg');
      await service.retry(pending.report.id);
      expect(uploads, 1);
      expect(writes, 2);
      service.dispose();
    },
  );

  test('permission failure is Failed, rather than a success message', () async {
    final service = ReportSubmissionService(
      publisher: (_) async {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        );
      },
    );
    final result = await service.submit(report());
    expect(result.report.publicationState, ReportPublicationState.failed);
    expect(result.report.isPublic, false);
    expect(StatusLogic.isReportActive(result.report), false);
    service.dispose();
  });

  test('published report retry is idempotent', () async {
    var writes = 0;
    final service = ReportSubmissionService(
      publisher: (_) async {
        writes++;
      },
    );
    final result = await service.submit(report());
    await service.retry(result.report.id);
    expect(writes, 1);
    service.dispose();
  });

  test('auto retry is scoped to the original reporter account', () async {
    var writes = 0;
    final service = ReportSubmissionService(
      publisher: (_) async {
        writes++;
        throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
      },
    );
    await service.submit(report());
    await service.retryPendingForUser('different-account');
    expect(writes, 1);
    service.dispose();
  });

  test('failed cloud write does not put a report in the public feed', () async {
    final store = FirestoreService(
      reportWriter: (_) async {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        );
      },
    );
    await expectLater(
      store.createReport(report()),
      throwsA(isA<FirebaseException>()),
    );
    expect(await store.streamReports().first, isEmpty);
  });

  test('local file paths are rejected before publishing', () async {
    var writes = 0;
    final store = FirestoreService(
      reportWriter: (_) async {
        writes++;
      },
    );
    await expectLater(
      store.createReport(report().copyWith(photoUrl: '/phone/temp/photo.jpg')),
      throwsArgumentError,
    );
    expect(writes, 0);
  });

  test(
    'new and historical demo reports are excluded from public conditions',
    () {
      expect(report().copyWith(isDemo: true).isPublic, false);
      for (final demo in SeedData.getSampleReports()) {
        expect(demo.isPublic, false);
        expect(StatusLogic.isReportActive(demo), false);
      }
    },
  );

  testWidgets('pending receipt shows retry without claiming delivery', (
    tester,
  ) async {
    final service = ReportSubmissionService(
      publisher: (_) async {
        throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
      },
    );
    final pending = await service.submit(report());
    await tester.pumpWidget(
      MaterialApp(
        home: ReportSubmittedScreen(
          report: pending.report,
          submissionService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pending upload'), findsOneWidget);
    expect(find.text('Retry upload'), findsOneWidget);
    expect(
      find.text('Your report is available to other commuters.'),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    service.dispose();
  });
}
