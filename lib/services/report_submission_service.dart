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

class ReportSubmission {
  const ReportSubmission(this.report, {this.photoBytes, this.error});
  final Report report;
  final Uint8List? photoBytes;
  final String? error;
}

/// Durable sender-only outbox. Public reports are written only after photo upload.
class ReportSubmissionService extends ChangeNotifier {
  ReportSubmissionService({
    Future<void> Function(Report)? publisher,
    Future<String> Function(Report, Uint8List)? photoUploader,
    this.operationTimeout = const Duration(seconds: 20),
  }) : _publisher = publisher ?? _publishReport,
       _photoUploader = photoUploader ?? _uploadPhoto;

  static final instance = ReportSubmissionService();
  static const storageKey = 'report_outbox_v1';
  final Future<void> Function(Report) _publisher;
  final Future<String> Function(Report, Uint8List) _photoUploader;
  final Duration operationTimeout;
  final Map<String, ReportSubmission> _entries = {};
  final Map<String, Future<ReportSubmission>> _attempts = {};
  SharedPreferences? _prefs;
  Future<void>? _initializing;
  Future<void> _saving = Future.value();
  Timer? _retryTimer;
  StreamSubscription<User?>? _authSubscription;
  List<ReportSubmission> get entries => List.unmodifiable(_entries.values);
  ReportSubmission? find(String id) => _entries[id];
  bool isUploading(String id) => _attempts.containsKey(id);

  Future<void> init({SharedPreferences? prefs}) =>
      _initializing ??= _load(prefs);
  Future<void> _load(SharedPreferences? prefs) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();
    final saved = _prefs!.getString(storageKey);
    if (saved != null) {
      for (final value in jsonDecode(saved) as List) {
        final data = Map<String, dynamic>.from(value as Map);
        final report = Report.fromMap(
          Map<String, dynamic>.from(data['report'] as Map),
        );
        _entries[report.id] = ReportSubmission(
          report,
          photoBytes: data['photo'] == null
              ? null
              : base64Decode(data['photo'] as String),
          error: data['error'] as String?,
        );
      }
    }
    notifyListeners();
  }

  Future<void> _save() {
    final json = jsonEncode(
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
              if (entry.photoBytes != null)
                'photo': base64Encode(entry.photoBytes!),
              if (entry.error != null) 'error': entry.error,
            },
          )
          .toList(),
    );
    return _saving = _saving.catchError((Object _) {}).then((_) async {
      if (!await _prefs!.setString(storageKey, json)) {
        throw StateError('Could not save the report on this device.');
      }
    });
  }

  Future<ReportSubmission> submit(
    Report report, {
    Uint8List? photoBytes,
  }) async {
    await init();
    final random = Random.secure();
    final id = report.id.isEmpty
        ? 'rep_${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(1 << 32)}'
        : report.id;
    if (_entries.containsKey(id)) return retry(id);
    final queued = report.copyWith(
      id: id,
      publicationState: ReportPublicationState.pendingUpload,
    );
    _entries[id] = ReportSubmission(queued, photoBytes: photoBytes);
    await _save();
    notifyListeners();
    return retry(id);
  }

  Future<ReportSubmission> retry(String id) {
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

  Future<ReportSubmission> _attempt(String id) async {
    await init();
    var entry = _entries[id]!;
    if (entry.report.publicationState == ReportPublicationState.published) {
      return entry;
    }
    _entries[id] = entry = ReportSubmission(
      entry.report.copyWith(
        publicationState: ReportPublicationState.pendingUpload,
      ),
      photoBytes: entry.photoBytes,
    );
    await _save();
    notifyListeners();
    try {
      if (entry.photoBytes != null &&
          !entry.report.photoUrl.startsWith('https://')) {
        final url = await _photoUploader(
          entry.report,
          entry.photoBytes!,
        ).timeout(operationTimeout);
        if (!url.startsWith('https://')) {
          throw StateError('Photo upload did not return a shared URL.');
        }
        _entries[id] = entry = ReportSubmission(
          entry.report.copyWith(photoUrl: url),
        );
        // Preserve the URL before publishing, so retry does not upload twice.
        await _save();
      }
      await _publisher(
        entry.report.copyWith(
          publicationState: ReportPublicationState.published,
        ),
      ).timeout(operationTimeout);
      _entries[id] = ReportSubmission(
        entry.report.copyWith(
          publicationState: ReportPublicationState.published,
        ),
      );
    } catch (error) {
      final transient =
          error is TimeoutException ||
          error is http.ClientException ||
          error is PhotoUploadException && error.isTransient ||
          error is FirebaseException &&
              const {
                'unavailable',
                'deadline-exceeded',
                'network-request-failed',
                'retry-limit-exceeded',
                'unknown',
              }.contains(error.code);
      _entries[id] = ReportSubmission(
        entry.report.copyWith(
          publicationState: transient
              ? ReportPublicationState.pendingUpload
              : ReportPublicationState.failed,
        ),
        photoBytes: entry.photoBytes,
        error: transient
            ? 'Waiting for a connection. This report is not confirmed as published.'
            : 'Upload failed. Check your sign-in, photo and service access, then retry.',
      );
    }
    await _save();
    notifyListeners();
    return _entries[id]!;
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
      if (user != null) {
        unawaited(
          retryPendingForUser(user.uid).catchError((Object error) {
            debugPrint('Report outbox retry: $error');
          }),
        );
      }
    });
    _retryTimer ??= Timer.periodic(const Duration(seconds: 60), (_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        unawaited(
          retryPendingForUser(user.uid).catchError((Object error) {
            debugPrint('Report outbox retry: $error');
          }),
        );
      }
    });
  }

  Future<void> retryPendingForUser(String uid) async {
    await init();
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
    _retryTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
