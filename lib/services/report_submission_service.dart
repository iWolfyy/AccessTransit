import 'transit_catalogue.dart';
import '../logic/report_cooldown.dart';
import 'moderation_client.dart';
import 'sample_test_mode.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/enums/report_publication_state.dart';
import '../models/report.dart';
import 'firestore_service.dart';
import 'report_photo_storage.dart';
import 'report_outbox_storage.dart';

class ReportSubmission {
  const ReportSubmission(
    this.report, {
    this.photoBytes,
    this.error,
    this.savedAt,
  });
  final Report report;
  final Uint8List? photoBytes;
  final String? error;
  final DateTime? savedAt;
}

/// Sender-only drafts. Acknowledged payloads are removed from durable storage.
class ReportSubmissionService extends ChangeNotifier {
  ReportSubmissionService({
    Future<void> Function(Report)? publisher,
    Future<String> Function(Report, Uint8List)? photoUploader,
    DateTime Function()? clock,
    ReportOutboxStorage? storage,
    this.operationTimeout = const Duration(seconds: 20),
  }) : _publisher = publisher ?? _publishReport,
       _photoUploader = photoUploader ?? _uploadPhoto,
       _now = clock ?? DateTime.now,
       _storage = storage ?? ReportOutboxStorage();

  static final instance = ReportSubmissionService();
  static final storageKey = SampleTestMode.storage(
    'report_outbox_v1',
  ); // Legacy plaintext migration only.
  static const retention = Duration(days: 7);
  static const maxEntries = 10;
  static const maxPhotoBytes = 2 * 1024 * 1024;
  static const maxStoredBytes = 15 * 1024 * 1024;
  final Future<void> Function(Report) _publisher;
  final Future<String> Function(Report, Uint8List) _photoUploader;
  final DateTime Function() _now;
  final ReportOutboxStorage _storage;
  final Duration operationTimeout;
  final Map<String, ReportSubmission> _entries = {};
  final Map<String, Future<ReportSubmission>> _attempts = {};
  // Receipts contain no report text/photo and prevent repeat publication this session.
  final Set<String> _acknowledged = {};
  final Map<String, int> _versions = {};
  int _nextVersion = 0;
  SharedPreferences? _prefs;
  SharedPreferences? _testPrefs;
  Future<void>? _initializing;
  Future<void> _saving = Future.value();
  String? _lastSaved;
  Timer? _retryTimer;
  StreamSubscription<User?>? _authSubscription;
  bool _disposed = false;
  bool _accountBound = false;
  String? _owner;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  List<ReportSubmission> get entries => List.unmodifiable(
    _entries.values.where((e) => !_accountBound || e.report.userId == _owner),
  );
  ReportSubmission? find(String id) {
    final entry = _entries[id];
    return entry != null && (!_accountBound || entry.report.userId == _owner)
        ? entry
        : null;
  }

  bool isUploading(String id) => _attempts.containsKey(id);
  bool isAcknowledged(String id) => _acknowledged.contains(id);
  bool _current(String id, int version) =>
      !_disposed &&
      _versions[id] == version &&
      _entries.containsKey(id) &&
      (!_accountBound || _entries[id]!.report.userId == _owner);

  Future<void> init({SharedPreferences? prefs}) =>
      _initializing ??= _load(prefs);
  Future<void> _load(SharedPreferences? prefs) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();
    _testPrefs = prefs; // Explicit test adapter only; app uses private storage.
    final saved =
        prefs?.getString(storageKey) ??
        await _storage.read() ??
        _prefs!.getString(storageKey);
    if (saved != null && utf8.encode(saved).length <= maxStoredBytes) {
      try {
        final list = jsonDecode(saved) as List;
        for (final value in list.take(maxEntries)) {
          try {
            final data = Map<String, dynamic>.from(value as Map);
            final report = Report.fromMap(
              Map<String, dynamic>.from(data['report'] as Map),
            );
            final savedAt =
                DateTime.tryParse(data['savedAt'] as String? ?? '') ??
                report.createdAt;
            if (report.id.isEmpty ||
                report.userId.isEmpty ||
                savedAt == null ||
                savedAt.isAfter(_now()) ||
                _now().difference(savedAt) >= retention ||
                report.publicationState == ReportPublicationState.published) {
              continue;
            }
            final bytes = data['photo'] == null
                ? null
                : base64Decode(data['photo'] as String);
            if (bytes != null && bytes.length > maxPhotoBytes) continue;
            _entries[report.id] = ReportSubmission(
              report,
              photoBytes: bytes,
              savedAt: savedAt,
              error: data['error'] as String?,
            );
          } catch (_) {
            /* Discard malformed drafts individually. */
          }
        }
      } catch (_) {
        /* Invalid legacy payload is removed, never retried. */
      }
    }
    await _save();
    if (prefs == null && !await _prefs!.remove(storageKey)) {
      throw StateError('Could not remove legacy report drafts.');
    }
    _notify();
  }

  String _encode() => jsonEncode(
    _entries.values
        .map(
          (entry) => {
            'report': {
              ...entry.report.toMap().map(
                (key, value) => MapEntry(
                  key,
                  value is Timestamp ? value.millisecondsSinceEpoch : value,
                ),
              ),
              'id': entry.report.id,
            },
            'savedAt': entry.savedAt!.toIso8601String(),
            if (entry.photoBytes != null)
              'photo': base64Encode(entry.photoBytes!),
            if (entry.error != null) 'error': entry.error,
          },
        )
        .toList(),
  );

  Future<void> _save() {
    return _saving = _saving.catchError((Object _) {}).then((_) async {
      // Encode when the queued write executes, so an old save cannot restore deleted data.
      final json = _encode();
      if (json == _lastSaved) return;
      if (utf8.encode(json).length > maxStoredBytes) {
        throw StateError('Report storage is full.');
      }
      if (_testPrefs != null) {
        if (!await _testPrefs!.setString(storageKey, json)) {
          throw StateError('Could not save report drafts.');
        }
      } else {
        await _storage.write(json);
      }
      _lastSaved = json;
    });
  }

  Future<void> prune() async {
    await init();
    for (final entry in List<ReportSubmission>.of(_entries.values)) {
      if (_now().difference(entry.savedAt!) >= retention) {
        _forget(entry.report.id);
      }
    }
    await _save();
    _notify();
  }

  void _forget(String id) {
    _versions.remove(id);
    _entries.remove(id);
  }

  /// Removes this device's draft, not a request already sent to a remote service.
  Future<void> remove(String id, {required String userId}) async {
    await init();
    final entry = find(id);
    if (entry == null || entry.report.userId != userId) {
      throw StateError('Draft unavailable for this account.');
    }
    _forget(id);
    try {
      await _save();
    } catch (_) {
      if (!_entries.containsKey(id) &&
          (!_accountBound || entry.report.userId == _owner)) {
        _entries[id] = entry;
      }
      _notify();
      rethrow;
    }
    _notify();
  }

  /// Account transitions discard other owners, including sign-out and deleted accounts.
  Future<void> activateAccount(String? uid) async {
    _accountBound = true;
    _owner = uid; // Hide immediately, before asynchronous storage access.
    _notify();
    await init();
    for (final entry in List<ReportSubmission>.of(_entries.values)) {
      if (entry.report.userId != _owner) _forget(entry.report.id);
    }
    _acknowledged.clear();
    await prune();
  }

  Future<ReportSubmission> submit(
    Report report, {
    Uint8List? photoBytes,
  }) async {
    TransitCatalogue.requireSharedWrites();
    await init();
    await prune();
    if (_accountBound && (report.userId != _owner || _owner == null)) {
      throw StateError('Sign in to save this report.');
    }
    if (photoBytes != null &&
        (photoBytes.isEmpty || photoBytes.length > maxPhotoBytes)) {
      throw ArgumentError('Photo must be at most 2 MB.');
    }
    if (report.description.length > 4000) {
      throw ArgumentError('Report note is too long.');
    }
    final id = report.id.isEmpty
        ? 'rep_${_now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}'
        : report.id;
    if (_entries.containsKey(id)) return retry(id);
    if (_acknowledged.contains(id)) {
      return ReportSubmission(
        report.copyWith(publicationState: ReportPublicationState.published),
      );
    }
    if (_entries.length >= maxEntries) {
      throw StateError(
        'Draft limit reached. Remove an upload before adding another.',
      );
    }
    _versions[id] = ++_nextVersion;
    _entries[id] = ReportSubmission(
      report.copyWith(
        id: id,
        publicationState: ReportPublicationState.pendingUpload,
      ),
      photoBytes: photoBytes == null ? null : Uint8List.fromList(photoBytes),
      savedAt: _now(),
    );
    try {
      await _save();
    } catch (_) {
      _forget(id);
      rethrow;
    }
    _notify();
    return retry(id);
  }

  Future<ReportSubmission> retry(String id) {
    if (_acknowledged.contains(id)) {
      return Future.value(
        ReportSubmission(
          Report(
            id: id,
            targetType: '',
            targetId: '',
            problemType: '',
            userId: '',
            status: 'active',
            createdAt: null,
            publicationState: ReportPublicationState.published,
          ),
        ),
      );
    }
    final existing = _attempts[id];
    if (existing != null) return existing;
    final task = _attempt(id);
    _attempts[id] = task;
    _notify();
    return task.whenComplete(() {
      _attempts.remove(id);
      _notify();
    });
  }

  Future<ReportSubmission> _attempt(String id) async {
    TransitCatalogue.requireSharedWrites();
    await init();
    await prune();
    final initial = find(id);
    if (initial == null) throw StateError('Draft was removed or expired.');
    var entry = initial;
    final version = _versions.putIfAbsent(id, () => ++_nextVersion);
    void check() {
      if (!_current(id, version)) {
        throw StateError('Draft removed or account changed.');
      }
    }

    entry = ReportSubmission(
      entry.report.copyWith(
        publicationState: ReportPublicationState.pendingUpload,
      ),
      photoBytes: entry.photoBytes,
      savedAt: entry.savedAt,
    );
    _entries[id] = entry;
    await _save();
    _notify();
    try {
      check();
      if (entry.report.createdAt == null) {
        throw StateError('Observation time unknown. Create a new report.');
      }
      if (entry.photoBytes != null &&
          !entry.report.photoUrl.startsWith('https://')) {
        final url = await _photoUploader(
          entry.report,
          entry.photoBytes!,
        ).timeout(operationTimeout);
        check();
        if (!url.startsWith('https://')) {
          throw StateError('Photo upload did not return a shared URL.');
        }
        entry = ReportSubmission(
          entry.report.copyWith(photoUrl: url),
          savedAt: entry.savedAt,
        );
        _entries[id] = entry;
        await _save();
      }
      check();
      final published = ReportSubmission(
        entry.report.copyWith(
          publicationState: ReportPublicationState.published,
        ),
        savedAt: entry.savedAt,
      );
      await _publisher(published.report).timeout(operationTimeout);
      check();
      _forget(id);
      _acknowledged.add(id);
      if (_acknowledged.length > 100) _acknowledged.remove(_acknowledged.first);
      await _save();
      _notify();
      return published;
    } catch (error) {
      check(); // Never resurrect a removed draft after a late upload/failure.
      // Log only a stable code: report text, photos and credentials stay private.
      if (kDebugMode) {
        final code = error is ModerationException
            ? error.code
            : error is FirebaseException
            ? error.code
            : error.runtimeType.toString();
        debugPrint('Report publication failed: $code');
      }
      final transient =
          error is TimeoutException ||
          error is http.ClientException ||
          error is ModerationException && error.code == 'service-unavailable' ||
          error is PhotoUploadException && error.isTransient ||
          error is FirebaseException &&
              const {
                'unavailable',
                'deadline-exceeded',
                'network-request-failed',
                'retry-limit-exceeded',
                'unknown',
              }.contains(error.code);
      entry = ReportSubmission(
        entry.report.copyWith(
          publicationState: transient
              ? ReportPublicationState.pendingUpload
              : ReportPublicationState.failed,
        ),
        photoBytes: entry.photoBytes,
        savedAt: entry.savedAt,
        error: entry.report.createdAt == null
            ? 'Observation time unknown. Create a new report before uploading.'
            : error is ReportCooldownException
            ? error.toString()
            : error is ModerationException && error.code == 'report-cooldown'
            ? 'Same-issue cooldown. Retry after ${error.retryAt?.toUtc().toIso8601String() ?? '5 minutes'} (UTC). Your draft is saved.'
            : error is ModerationException
            ? 'publication:${error.code}'
            : error is FirebaseException &&
                  const {
                    'permission-denied',
                    'not-authorized',
                    'unauthenticated',
                  }.contains(error.code)
            ? 'publication:${error.code}'
            : transient
            ? 'Waiting for a connection. This report is not confirmed as published.'
            : 'Upload failed. Check your sign-in, photo and service access, then retry.',
      );
      _entries[id] = entry;
      await _save();
      _notify();
      return entry;
    }
  }

  static Future<String> _uploadPhoto(Report report, Uint8List bytes) async {
    _requireOwner(report);
    return ReportPhotoStorage.configured.upload(bytes);
  }

  static void _requireOwner(Report report) {
    if (FirebaseAuth.instance.currentUser?.uid != report.userId) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-authorized',
        message: 'Sign in with the account that created this report.',
      );
    }
  }

  static Future<void> _publishReport(Report report) async {
    _requireOwner(report);
    await FirestoreService().createReport(report);
  }

  void startAutoRetry() {
    _authSubscription ??= FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) {
      unawaited(
        activateAccount(user?.uid)
            .then((_) async {
              if (user != null) await retryPendingForUser(user.uid);
            })
            .catchError((Object _) {
              debugPrint('Report outbox account cleanup failed.');
            }),
      );
    });
    _retryTimer ??= Timer.periodic(const Duration(seconds: 60), (_) {
      final user = FirebaseAuth.instance.currentUser;
      unawaited(
        prune()
            .then((_) async {
              if (user != null) await retryPendingForUser(user.uid);
            })
            .catchError((Object _) {
              debugPrint('Report outbox cleanup/retry failed.');
            }),
      );
    });
  }

  Future<void> retryPendingForUser(String uid) async {
    if (TransitCatalogue.demo) return;
    await prune();
    for (final entry in entries) {
      if (entry.report.userId == uid &&
          entry.report.publicationState ==
              ReportPublicationState.pendingUpload) {
        await retry(entry.report.id);
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
