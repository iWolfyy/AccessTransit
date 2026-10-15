import 'transit_catalogue.dart';
import 'sample_test_mode.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/boarding_request.dart';
import 'firestore_service.dart';

enum AssistanceDeliveryState {
  pendingUpload('Pending upload'),
  sent('Sent'),
  failed('Failed'),
  expired('Retry expired');

  const AssistanceDeliveryState(this.label);
  final String label;
}

class AssistanceSubmission {
  const AssistanceSubmission({
    required this.request,
    required this.delivery,
    required this.queuedAt,
    this.error,
  });
  final BoardingRequest request;
  final AssistanceDeliveryState delivery;
  final DateTime queuedAt;
  final String? error;
}

/// Durable owner-only assistance outbox. A sent record is not a driver acceptance.
class AssistanceSubmissionService extends ChangeNotifier {
  AssistanceSubmissionService({
    Future<BoardingRequest> Function(BoardingRequest)? publisher,
    String? Function()? currentRiderId,
    DateTime Function()? now,
    this.operationTimeout = const Duration(seconds: 15),
    this.retryWindow = const Duration(minutes: 30),
  }) : _publisher = publisher ?? FirestoreService().publishBoardingRequest,
       _currentRiderId = currentRiderId ?? _signedInUid,
       _now = now ?? DateTime.now;
  static final instance = AssistanceSubmissionService();
  static final storageKey = SampleTestMode.storage('assistance_outbox_v1');
  final Future<BoardingRequest> Function(BoardingRequest) _publisher;
  final String? Function() _currentRiderId;
  final DateTime Function() _now;
  final Duration operationTimeout;
  final Duration retryWindow;
  final Map<String, AssistanceSubmission> _entries = {};
  final Map<String, Future<AssistanceSubmission>> _attempts = {};
  SharedPreferences? _prefs;
  Future<void>? _initializing;
  Future<void> _saving = Future.value();
  Timer? _retryTimer;
  StreamSubscription<User?>? _auth;
  String? loadError;
  String? get currentRiderId => _currentRiderId();
  List<AssistanceSubmission> get entries => List.unmodifiable(_entries.values);
  AssistanceSubmission? find(String id) => _entries[id];
  bool isUploading(String id) => _attempts.containsKey(id);
  static String? _signedInUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  Future<void> init({SharedPreferences? prefs}) =>
      _initializing ??= _load(prefs);
  Future<void> _load(SharedPreferences? prefs) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();
    final saved = _prefs!.getString(storageKey);
    if (saved != null) {
      try {
        for (final raw in jsonDecode(saved) as List) {
          final data = Map<String, dynamic>.from(raw as Map);
          final request = BoardingRequest.fromMap(
            Map<String, dynamic>.from(data['request'] as Map),
          );
          _entries[request.id] = AssistanceSubmission(
            request: request,
            delivery: AssistanceDeliveryState.values.byName(
              data['delivery'] as String,
            ),
            queuedAt: DateTime.fromMillisecondsSinceEpoch(
              data['queuedAt'] as int,
            ),
            error: data['error'] as String?,
          );
        }
      } catch (_) {
        loadError = 'Some saved assistance requests could not be restored. Check your shared request history.';
      }
    }
    notifyListeners();
  }

  Future<void> _save() {
    final saved = jsonEncode(
      _entries.values
          .map(
            (entry) => {
              'request': {
                ...entry.request.toMap().map(
                  (key, value) => MapEntry(
                    key,
                    value is Timestamp ? value.millisecondsSinceEpoch : value,
                  ),
                ),
                'id': entry.request.id,
              },
              'delivery': entry.delivery.name,
              'queuedAt': entry.queuedAt.millisecondsSinceEpoch,
              if (entry.error != null) 'error': entry.error,
            },
          )
          .toList(),
    );
    return _saving = _saving.catchError((Object _) {}).then((_) async {
      if (!await _prefs!.setString(storageKey, saved)) {
        throw StateError('Could not save this request on your device.');
      }
    });
  }

  void _requireOwner(BoardingRequest request) {
    if (currentRiderId != request.riderId) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-authorized',
        message: 'Sign in as the rider who created this request.',
      );
    }
  }

  Future<AssistanceSubmission> enqueue(BoardingRequest request) async {
    TransitCatalogue.requireSharedWrites();
    await init();
    _requireOwner(request);
    final id = request.id.isEmpty
        ? 'assist_${_now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}'
        : request.id;
    final existing = _entries[id];
    if (existing != null) {
      if (existing.request.riderId != request.riderId ||
          existing.request.busId != request.busId ||
          existing.request.stationId != request.stationId ||
          existing.request.purpose != request.purpose ||
          !listEquals(
            existing.request.assistanceTypes,
            request.assistanceTypes,
          )) {
        throw StateError(
          'This request ID belongs to a different assistance request.',
        );
      }
      return existing;
    }
    if (request.status != 'pending') {
      throw StateError(
        'New assistance requests must await driver acknowledgement.',
      );
    }
    final entry = AssistanceSubmission(
      request: request.copyWith(id: id),
      delivery: AssistanceDeliveryState.pendingUpload,
      queuedAt: _now(),
    );
    _entries[id] = entry;
    try {
      await _save();
    } catch (_) {
      _entries.remove(id);
      rethrow;
    }
    notifyListeners();
    return entry;
  }

  Future<AssistanceSubmission> submit(BoardingRequest request) async =>
      retry((await enqueue(request)).request.id);
  Future<AssistanceSubmission> retry(String id) {
    final existing = _attempts[id];
    if (existing != null) return existing;
    final task = _attempt(id);
    _attempts[id] = task;
    notifyListeners();
    return task.whenComplete(() {
      _attempts.remove(id);
      notifyListeners();
    });
  }

  Future<AssistanceSubmission> _attempt(String id) async {
    TransitCatalogue.requireSharedWrites();
    await init();
    var entry = _entries[id];
    if (entry == null) throw StateError('This saved request was not found.');
    _requireOwner(entry.request);
    if (entry.delivery == AssistanceDeliveryState.sent) return entry;
    if (_now().difference(entry.queuedAt) >= retryWindow) {
      _entries[id] = entry = AssistanceSubmission(
        request: entry.request,
        delivery: AssistanceDeliveryState.expired,
        queuedAt: entry.queuedAt,
        error: 'Automatic retries stopped because this request is old. Check the driver status; delivery may still be unconfirmed.',
      );
    } else {
      _entries[id] = entry = AssistanceSubmission(
        request: entry.request,
        delivery: AssistanceDeliveryState.pendingUpload,
        queuedAt: entry.queuedAt,
      );
      await _save();
      notifyListeners();
      try {
        _requireOwner(entry.request);
        final published = await _publisher(entry.request)
            .timeout(operationTimeout);
        if (published.id != id ||
            published.riderId != entry.request.riderId ||
            published.busId != entry.request.busId ||
            published.stationId != entry.request.stationId ||
            published.purpose != entry.request.purpose ||
            !listEquals(
              published.assistanceTypes,
              entry.request.assistanceTypes,
            )) {
          throw StateError(
            'The service returned a different assistance target.',
          );
        }
        _entries[id] = AssistanceSubmission(
          request: published,
          delivery: AssistanceDeliveryState.sent,
          queuedAt: entry.queuedAt,
        );
      } catch (error) {
        final transient =
            error is TimeoutException ||
            error is FirebaseException &&
                const {
                  'unavailable',
                  'deadline-exceeded',
                  'network-request-failed',
                  'aborted',
                  'unknown',
                }.contains(error.code);
        _entries[id] = AssistanceSubmission(
          request: entry.request,
          delivery: transient
              ? AssistanceDeliveryState.pendingUpload
              : AssistanceDeliveryState.failed,
          queuedAt: entry.queuedAt,
          error: transient
              ? 'Delivery is not confirmed. Retry when connected; keep checking the driver status.'
              : 'The request could not be sent. Check your sign-in and target, then retry.',
        );
      }
    }
    try {
      await _save();
    } catch (_) {
      // A cloud acknowledgement remains valid even if saving its receipt locally fails.
      loadError = 'The latest request status could not be saved on this device. Check the shared request history.';
    }
    notifyListeners();
    return _entries[id]!;
  }

  Future<void> retryPendingForUser(String uid) async {
    if (TransitCatalogue.demo) return;
    await init();
    if (uid != currentRiderId) return;
    for (final entry in entries) {
      if (entry.request.riderId == uid &&
          entry.delivery == AssistanceDeliveryState.pendingUpload) {
        await retry(entry.request.id);
      }
    }
  }

  void startAutoRetry() {
    void retryCurrent() {
      final uid = currentRiderId;
      if (uid != null) {
        unawaited(
          retryPendingForUser(uid).catchError((Object e) {
            debugPrint('Assistance outbox retry: $e');
          }),
        );
      }
    }

    _auth ??= FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
      retryCurrent();
    });
    _retryTimer ??= Timer.periodic(
      const Duration(seconds: 60),
      (_) => retryCurrent(),
    );
  }

  @override
  void dispose() {
    _auth?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }
}
