import 'dart:async';

import 'package:access_transit/models/boarding_request.dart';
import 'package:access_transit/services/assistance_submission_service.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

BoardingRequest request({String id = '', String rider = 'rider'}) =>
    BoardingRequest(
      id: id,
      riderId: rider,
      riderName: 'Rider',
      busId: 'delivery_bus',
      routeNo: '138',
      stationId: 'delivery_stop',
      stopName: 'Stop',
      assistanceTypes: const ['Deploy Ramp'],
      status: 'pending',
      createdAt: DateTime(2026, 10, 14, 10),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'durable pending request waits for acknowledgement; retries use one ID',
    () async {
      final started = Completer<void>();
      final ack = Completer<BoardingRequest>();
      var calls = 0;
      final service = AssistanceSubmissionService(
        currentRiderId: () => 'rider',
        publisher: (r) {
          calls++;
          started.complete();
          return ack.future;
        },
      );
      final queued = await service.enqueue(request());
      expect(queued.request.id, startsWith('assist_'));
      final attempt = service.retry(queued.request.id);
      await started.future;
      final concurrent = service.retry(queued.request.id);
      expect(
        service.find(queued.request.id)!.delivery,
        AssistanceDeliveryState.pendingUpload,
      );
      expect(service.isUploading(queued.request.id), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(AssistanceSubmissionService.storageKey),
        contains(queued.request.id),
      );
      ack.complete(queued.request);
      expect((await attempt).delivery, AssistanceDeliveryState.sent);
      expect((await concurrent).request.id, queued.request.id);
      expect(calls, 1);
      expect(
        (await service.retry(queued.request.id)).request.status,
        'pending',
      );
      expect(calls, 1);
      service.dispose();
    },
  );

  test('transient failure restores pending across restart and preserves driver response', () async {
    final first = AssistanceSubmissionService(
      currentRiderId: () => 'rider',
      publisher: (_) async => throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      ),
    );
    final pending = await first.submit(request());
    expect(pending.delivery, AssistanceDeliveryState.pendingUpload);
    first.dispose();
    final sentIds = <String>[];
    final restored = AssistanceSubmissionService(
      currentRiderId: () => 'rider',
      publisher: (r) async {
        sentIds.add(r.id);
        return r.copyWith(status: 'acknowledged');
      },
    );
    await restored.init();
    expect(
      restored.find(pending.request.id)!.request.createdAt,
      pending.request.createdAt,
    );
    await restored.retryPendingForUser('rider');
    expect(sentIds, [pending.request.id]);
    expect(
      restored.find(pending.request.id)!.delivery,
      AssistanceDeliveryState.sent,
    );
    expect(restored.find(pending.request.id)!.request.status, 'acknowledged');
    restored.dispose();
  });

  test('permission failure is Failed, does not auto retry, but owner can retry explicitly', () async {
    var rejected = true;
    var calls = 0;
    final service = AssistanceSubmissionService(
      currentRiderId: () => 'rider',
      publisher: (r) async {
        calls++;
        if (rejected) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          );
        }
        return r;
      },
    );
    final failed = await service.submit(request());
    expect(failed.delivery, AssistanceDeliveryState.failed);
    await service.retryPendingForUser('rider');
    expect(calls, 1);
    rejected = false;
    expect(
      (await service.retry(failed.request.id)).delivery,
      AssistanceDeliveryState.sent,
    );
    expect(calls, 2);
    service.dispose();
  });

  test('timeout stays unconfirmed and later retry reads the same completed request', () async {
    var calls = 0;
    final service = AssistanceSubmissionService(
      currentRiderId: () => 'rider',
      operationTimeout: const Duration(milliseconds: 5),
      publisher: (r) async {
        if (++calls == 1) return Completer<BoardingRequest>().future;
        return r.copyWith(status: 'completed');
      },
    );
    final pending = await service.submit(request());
    expect(pending.delivery, AssistanceDeliveryState.pendingUpload);
    final sent = await service.retry(pending.request.id);
    expect(sent.request.id, pending.request.id);
    expect(sent.request.status, 'completed');
    service.dispose();
  });

  test('account switch cannot submit or retry another rider request', () async {
    String? actor = 'rider';
    var calls = 0;
    final service = AssistanceSubmissionService(
      currentRiderId: () => actor,
      publisher: (r) async {
        calls++;
        return r;
      },
    );
    final queued = await service.enqueue(request());
    actor = 'other';
    await expectLater(
      service.retry(queued.request.id),
      throwsA(isA<FirebaseException>()),
    );
    await service.retryPendingForUser('rider');
    await expectLater(
      service.enqueue(request()),
      throwsA(isA<FirebaseException>()),
    );
    expect(calls, 0);
    expect(
      service.find(queued.request.id)!.delivery,
      AssistanceDeliveryState.pendingUpload,
    );
    service.dispose();
  });

  test(
    'old retry expires without claiming cancellation or known delivery',
    () async {
      var clock = DateTime(2026, 10, 14, 10);
      final service = AssistanceSubmissionService(
        currentRiderId: () => 'rider',
        now: () => clock,
        publisher: (_) async => fail('Old request must not be uploaded'),
      );
      final queued = await service.enqueue(request());
      clock = clock.add(const Duration(minutes: 30));
      final expired = await service.retry(queued.request.id);
      expect(expired.delivery, AssistanceDeliveryState.expired);
      expect(expired.request.status, 'pending');
      expect(expired.error, contains('unconfirmed'));
      service.dispose();
    },
  );

  test('request identity reuse and a mismatched publisher target cannot claim Sent', () async {
    final service = AssistanceSubmissionService(
      currentRiderId: () => 'rider',
      publisher: (r) async => r.copyWith(purpose: 'alighting'),
    );
    final queued = await service.enqueue(request(id: 'target_identity'));
    await expectLater(
      service.enqueue(queued.request.copyWith(busId: 'different')),
      throwsStateError,
    );
    expect(
      (await service.retry(queued.request.id)).delivery,
      AssistanceDeliveryState.failed,
    );
    await expectLater(
      service.enqueue(request(id: 'fabricated').copyWith(status: 'completed')),
      throwsStateError,
    );
    service.dispose();
  });

  test(
    'malformed saved outbox reports restoration error without failing startup',
    () async {
      SharedPreferences.setMockInitialValues({
        AssistanceSubmissionService.storageKey: 'invalid',
      });
      final service = AssistanceSubmissionService(
        currentRiderId: () => 'rider',
      );
      await service.init();
      expect(service.entries, isEmpty);
      expect(service.loadError, contains('could not be restored'));
      service.dispose();
    },
  );

  test('failed repository publication never appears in driver or passenger shared streams', () async {
    final repository = FirestoreService(
      boardingWriter: (_) async => throw StateError('offline'),
    );
    final value = request(id: 'failed_repository', rider: 'failed_rider');
    await expectLater(
      repository.publishBoardingRequest(value),
      throwsStateError,
    );
    expect(await repository.watchBoardingRequest(value.id).first, isNull);
    expect(
      await repository.streamBoardingRequestsForRider(value.riderId).first,
      isEmpty,
    );
  });

  test('subscribed streams receive acknowledged transitions; failed status keeps old state', () async {
    var failStatus = true;
    final repository = FirestoreService(
      boardingWriter: (r) async => r,
      boardingStatusWriter: (r, status) async {
        if (failStatus) throw StateError('denied');
        return r.copyWith(status: status);
      },
    );
    final value = request(
      id: 'stream_lifecycle',
      rider: 'stream_rider',
    ).copyWith(busId: 'stream_bus');
    final riderValues = <List<BoardingRequest>>[];
    final busValues = <List<BoardingRequest>>[];
    final riderSub = repository
        .streamBoardingRequestsForRider(value.riderId)
        .listen(riderValues.add);
    final busSub = repository
        .streamBoardingRequestsForBus(value.busId)
        .listen(busValues.add);
    await repository.publishBoardingRequest(value);
    await expectLater(
      repository.updateBoardingRequestStatus(value.id, 'completed'),
      throwsStateError,
    );
    await expectLater(
      repository.updateBoardingRequestStatus(value.id, 'acknowledged'),
      throwsStateError,
    );
    expect(
      (await repository.watchBoardingRequest(value.id).first)!.status,
      'pending',
    );
    failStatus = false;
    await repository.updateBoardingRequestStatus(value.id, 'acknowledged');
    await repository.updateBoardingRequestStatus(value.id, 'completed');
    await Future<void>.delayed(Duration.zero);
    expect(riderValues.where((r) => r.isNotEmpty).map((r) => r.single.status), [
      'pending',
      'acknowledged',
      'completed',
    ]);
    expect(busValues.where((r) => r.isNotEmpty).map((r) => r.single.status), [
      'pending',
      'acknowledged',
      'completed',
    ]);
    await riderSub.cancel();
    await busSub.cancel();
  });

  test(
    'account switch clears assistance cache and isolates old session streams',
    () async {
      String? actor = 'alice';
      final repository = FirestoreService(
        boardingViewerId: () => actor,
        boardingWriter: (r) async => r,
      );
      final value = request(id: 'private_cache', rider: 'alice');
      await repository.publishBoardingRequest(value);
      expect(await repository.watchBoardingRequest(value.id).first, isNotNull);
      final oldEvents = <List<BoardingRequest>>[];
      final oldStream = repository
          .streamBoardingRequestsForBus(value.busId)
          .listen(oldEvents.add);
      actor = 'bob';
      expect(await repository.watchBoardingRequest(value.id).first, isNull);
      await repository.publishBoardingRequest(
        value.copyWith(id: 'bob_request', riderId: 'bob'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(oldEvents.last, isEmpty);
      expect(
        (await repository.streamBoardingRequestsForBus(value.busId).first)
            .single
            .riderId,
        'bob',
      );
      actor = null;
      expect(
        await repository.streamBoardingRequestsForBus(value.busId).first,
        isEmpty,
      );
      await oldStream.cancel();
    },
  );

  test('late acknowledgement from an old account cannot populate new account cache', () async {
    String? actor = 'alice';
    final ack = Completer<BoardingRequest>();
    final repository = FirestoreService(
      boardingViewerId: () => actor,
      boardingWriter: (_) => ack.future,
    );
    final value = request(id: 'late_private', rider: 'alice');
    final write = repository.publishBoardingRequest(value);
    actor = 'bob';
    ack.complete(value);
    await write;
    expect(await repository.watchBoardingRequest(value.id).first, isNull);
  });
}
