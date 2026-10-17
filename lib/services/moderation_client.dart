import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'sample_test_mode.dart';
import 'moderation_mode.dart';
import '../models/report.dart';
import '../models/boarding_request.dart';

class ModerationException implements Exception {
  const ModerationException(this.code, {this.retryAt});
  final String code;
  final DateTime? retryAt;
  @override
  String toString() => 'Moderation request failed: $code';
}

class ModerationIdentity {
  const ModerationIdentity(this.uid, this.token);
  final String uid, token;
}

class ModerationVoteReceipt {
  const ModerationVoteReceipt({
    required this.hidden,
    required this.duplicate,
    required this.falseCount,
    required this.confirmCount,
  });
  final bool hidden, duplicate;
  final int falseCount, confirmCount;
}

class ModerationAccountStatus {
  const ModerationAccountStatus({
    required this.state,
    required this.serverTime,
    required this.suspendedUntil,
    required this.points,
    this.banReason,
  });
  final String state;
  final DateTime serverTime;
  final DateTime? suspendedUntil;
  final int? points;
  final String? banReason;
  bool get isSuspended => state != 'active';
}

/// Staged HTTPS transport. It never writes Firestore or enables v2 by itself.
/// Configure only after the v2 publication, privacy and account gates are ready.
class ModerationVoteStatus {
  const ModerationVoteStatus(
    this.userVote,
    this.isAuthor,
    this.status,
    this.falseCount,
    this.confirmCount,
  );
  final String? userVote;
  final bool isAuthor;
  final String status;
  final int falseCount, confirmCount;
}

class ModerationClient {
  ModerationClient({
    Uri? origin,
    http.Client? client,
    Future<ModerationIdentity?> Function()? identity,
    String? Function()? currentUid,
    bool? sample,
    this.timeout = const Duration(seconds: 15),
  }) : _explicitOrigin = origin,
       _client = client ?? http.Client(),
       _ownsClient = client == null,
       _identity = identity ?? _firebaseIdentity,
       _currentUid = currentUid ?? _firebaseUid,
       _scope = (sample ?? SampleTestMode.enabled) ? 'sample' : 'normal';

  final Uri? _explicitOrigin;
  // Long-lived clients must follow main-app initialization rather than keeping
  // an empty origin captured before startup (or during a debug hot reload).
  Uri? get _origin => _explicitOrigin ?? ModerationMode.apiOrigin;
  final http.Client _client;
  final bool _ownsClient;
  final Future<ModerationIdentity?> Function() _identity;
  final String? Function() _currentUid;
  final String _scope;
  final Duration timeout;
  String? get currentAccountId => _currentUid();
  bool _disposed = false;

  static String? _firebaseUid() => FirebaseAuth.instance.currentUser?.uid;
  static Future<ModerationIdentity?> _firebaseIdentity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final token = await user.getIdToken();
    if (token == null || FirebaseAuth.instance.currentUser?.uid != user.uid) {
      return null;
    }
    return ModerationIdentity(user.uid, token);
  }

  bool get isConfigured => ModerationMode.configuration.acceptsOrigin(_origin);

  Future<Map<String, dynamic>> _request(
    String path,
    Map<String, dynamic> data,
  ) async {
    if (_disposed) throw const ModerationException('disposed');
    if (!isConfigured) {
      throw const ModerationException('backend-not-configured');
    }
    final expectedUid = _currentUid();
    if (expectedUid == null || expectedUid.isEmpty) {
      throw const ModerationException('authentication-required');
    }
    try {
      final identity = await _identity().timeout(timeout);
      if (identity == null ||
          identity.uid != expectedUid ||
          identity.token.isEmpty) {
        throw const ModerationException('authentication-required');
      }
      void checkSession() {
        if (_disposed || _currentUid() != expectedUid) {
          throw const ModerationException('account-changed');
        }
      }

      checkSession();
      final request = http.Request('POST', _origin!.resolve(path))
        ..followRedirects = false
        ..headers.addAll({
          'authorization': 'Bearer ${identity.token}',
          'content-type': 'application/json',
        })
        ..body = jsonEncode({...data, 'scope': _scope});
      final response = await _client.send(request).timeout(timeout);
      final bytes = <int>[];
      await (() async {
        await for (final chunk in response.stream) {
          bytes.addAll(chunk);
          if (bytes.length > (path == '/v2/assistance/list' ? 65536 : 16384)) {
            throw const ModerationException('invalid-response');
          }
        }
      })().timeout(timeout);
      checkSession();
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw const ModerationException('invalid-response');
      }
      if (response.statusCode != 200) {
        final error = decoded['error'];
        final code = error is Map ? error['code'] : null;
        const allowed = {
          'authentication-required',
          'authentication-unavailable',
          'author-cannot-vote',
          'account-suspended',
          'account-missing',
          'false-reason-required',
          'invalid-request',
          'invalid-id',
          'scope-denied',
          'report-ineligible',
          'migration-required',
          'voting-closed',
          'service-unavailable',
          'report-cooldown',
          'report-id-conflict',
          'admin-required',
          'self-review-forbidden',
          'reason-required',
          'dispute-unavailable',
          'review-already-decided',
          'invalid-state',
          'review-unavailable',
          'review-stale',
          'appeals-pending',
          'admin-account-protected',
          'assistance-unavailable',
          'assistance-transition-denied',
          'request-id-conflict',
          'operation-unavailable',
          'operation-stale',
          'driver-ineligible',
          'gps-unavailable',
          'notification-unavailable',
          'device-limit',
          'auth-scope-denied',
          'auth-operation-pending',
          'account-deleted',
          'auth-account-missing',
          'disable-before-delete',
          'active-operation-blocks-delete',
          'deletion-confirmation-required',
        };
        throw ModerationException(
          allowed.contains(code) ? code as String : 'service-unavailable',
          retryAt: code == 'report-cooldown' && error is Map
              ? DateTime.tryParse(error['retryAt']?.toString() ?? '')
              : null,
        );
      }
      if (decoded['policyVersion'] != 2 ||
          decoded['uid'] != expectedUid ||
          decoded['scope'] != _scope) {
        throw const ModerationException('invalid-response');
      }
      return decoded;
    } on ModerationException {
      rethrow;
    } on TimeoutException {
      throw const ModerationException('service-unavailable');
    } on FormatException {
      throw const ModerationException('invalid-response');
    } catch (_) {
      throw const ModerationException('service-unavailable');
    }
  }

  Future<ModerationVoteReceipt> voteReport({
    required String reportId,
    required bool isTrue,
    String reason = '',
  }) async {
    if (reportId.isEmpty || reportId.length > 128 || reportId.contains('/')) {
      throw const ModerationException('invalid-id');
    }
    if (!isTrue && (reason.trim().length < 5 || reason.length > 1000)) {
      throw const ModerationException('false-reason-required');
    }
    final data = await _request('/v2/reports/vote', {
      'reportId': reportId,
      'value': isTrue ? 'true' : 'false',
      if (!isTrue) 'reason': reason.trim(),
    });
    final negative = data['falseCount'], positive = data['confirmCount'];
    if (data['reportId'] != reportId ||
        data['hidden'] is! bool ||
        data['duplicate'] is! bool ||
        negative is! int ||
        negative < 0 ||
        negative > 5 ||
        positive is! int ||
        positive < 0 ||
        data['hidden'] != (negative == 5)) {
      throw const ModerationException('invalid-response');
    }
    return ModerationVoteReceipt(
      hidden: data['hidden'],
      duplicate: data['duplicate'],
      falseCount: negative,
      confirmCount: positive,
    );
  }

  Future<ModerationAccountStatus> accountStatus() async {
    final data = await _request('/v2/account/status', {});
    final state = data['state'],
        server = DateTime.tryParse(data['serverTime']?.toString() ?? '');
    final until = data['suspendedUntil'] == null
        ? null
        : DateTime.tryParse(data['suspendedUntil'].toString());
    if (!const [
          'active',
          'temporary',
          'suspended',
          'permanent',
        ].contains(state) ||
        server == null ||
        !server.isUtc ||
        (data['points'] != null && data['points'] is! int) ||
        (state == 'temporary' &&
            (until == null || !until.isUtc || !until.isAfter(server))) ||
        (state != 'temporary' && data['suspendedUntil'] != null)) {
      throw const ModerationException('invalid-response');
    }
    return ModerationAccountStatus(
      state: state,
      serverTime: server,
      suspendedUntil: until,
      points: data['points'],
      banReason: data['banReason'] is String ? data['banReason'] : null,
    );
  }

  Future<Map<String, dynamic>> manualAppeals({
    bool admin = false,
    String? after,
  }) => _request('/v2/manual-appeals/list', {'queue': admin, 'after': ?after});

  Future<Map<String, dynamic>> currentManualAppeal() =>
      _request('/v2/manual-appeals/current', {});

  Future<void> submitManualAppeal(int revision, String reason) async {
    final data = await _request('/v2/manual-appeals/submit', {
      'expectedRevision': revision,
      'reason': reason,
    });
    _manualReceipt(data);
  }

  Future<void> reviewManualAppeal(
    String appealId,
    String outcome,
    String reason,
  ) async {
    final data = await _request('/v2/manual-appeals/review', {
      'appealId': appealId,
      'outcome': outcome,
      'reason': reason,
    });
    if (data['appealId'] != appealId) {
      throw const ModerationException('invalid-response');
    }
    _manualReceipt(data);
  }

  void _manualReceipt(Map<String, dynamic> data) {
    if (data['duplicate'] is! bool ||
        data['appealId'] is! String ||
        !const ['pending', 'accepted', 'rejected'].contains(data['status'])) {
      throw const ModerationException('invalid-response');
    }
  }

  Future<ModerationVoteStatus> voteStatus(String reportId) async {
    final data = await _request('/v2/reports/vote-status', {
      'reportId': reportId,
    });
    final negative = data['falseCount'], positive = data['confirmCount'];
    if (data['reportId'] != reportId ||
        data['isAuthor'] is! bool ||
        !const [null, 'true', 'false'].contains(data['userVote']) ||
        !const ['active', 'resolved', 'hidden'].contains(data['status']) ||
        negative is! int ||
        negative < 0 ||
        negative > 5 ||
        positive is! int ||
        positive < 0) {
      throw const ModerationException('invalid-response');
    }
    return ModerationVoteStatus(
      data['userVote'],
      data['isAuthor'],
      data['status'],
      negative,
      positive,
    );
  }

  Future<void> publishReport(Report report) async {
    if (report.createdAt == null) {
      throw const ModerationException('invalid-request');
    }
    final data = await _request('/v2/reports/publish', {
      'reportId': report.id,
      'report': {
        'targetType': report.targetType,
        'targetId': report.targetId,
        'targetName': report.targetName,
        'problemType': report.problemType,
        'severity': report.severity,
        'category': report.category,
        'subCategory': report.subCategory,
        'description': report.description,
        'photoUrl': report.photoUrl,
        'condition': report.observedCondition.name,
        'crowdingLevel': report.crowdingLevel,
        'observedAt': (report.observedAt ?? report.createdAt!)
            .toUtc()
            .toIso8601String(),
      },
    });
    if (data['reportId'] != report.id ||
        data['awardedPoints'] != 10 ||
        data['duplicate'] is! bool) {
      throw const ModerationException('invalid-response');
    }
  }

  void dispose() {
    _disposed = true;
    if (_ownsClient) _client.close();
  }

  Future<Map<String, dynamic>> reviews({bool admin = false, String? after}) =>
      _request('/v2/reviews/list', {'queue': admin, 'after': ?after});

  Future<Map<String, dynamic>> reviewDetail(String reportId) =>
      _request('/v2/reviews/detail', {'reportId': reportId});

  Future<Map<String, dynamic>> reviewEvidence(
    String reportId, {
    String? after,
  }) =>
      _request('/v2/reviews/evidence', {'reportId': reportId, 'after': ?after});

  Future<void> appealReport(String reportId, String reason) async {
    final data = await _request('/v2/reviews/appeal', {
      'reportId': reportId,
      'reason': reason,
    });
    if (data['duplicate'] is! bool ||
        !const ['pending', 'accepted', 'rejected'].contains(data['status'])) {
      throw const ModerationException('invalid-response');
    }
  }

  Future<void> decideReport(
    String reportId,
    String outcome,
    String reason,
  ) async {
    final data = await _request('/v2/reviews/decide', {
      'reportId': reportId,
      'outcome': outcome,
      'reason': reason,
    });
    if (data['duplicate'] is! bool || data['outcome'] != outcome) {
      throw const ModerationException('invalid-response');
    }
  }

  Future<Map<String, dynamic>> banReviews({String? after}) =>
      _request('/v2/bans/list', {'after': ?after});

  Future<String> registerNotificationDevice({
    required String token,
    required String locale,
    required String accountId,
  }) async {
    if (_currentUid() != accountId) {
      throw const ModerationException('account-changed');
    }
    final value = await _request('/v2/notifications/register', {
      'token': token,
      'locale': locale,
      'platform': 'android',
    });
    if (value['deviceId'] is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(value['deviceId']) ||
        value['generation'] is! int ||
        value['generation'] < 1 ||
        !['local', 'fcm'].contains(value['provider'])) {
      throw const ModerationException('invalid-response');
    }
    return value['deviceId'];
  }

  Future<void> removeNotificationDevice(
    String deviceId, {
    required String accountId,
  }) async {
    if (_currentUid() != accountId) {
      throw const ModerationException('account-changed');
    }
    final value = await _request('/v2/notifications/remove', {
      'deviceId': deviceId,
    });
    if (value['removed'] != true) {
      throw const ModerationException('invalid-response');
    }
  }

  Future<BoardingRequest> openAssistanceNotification(
    Map<String, dynamic> payload,
  ) async {
    // A push is an untrusted wake-up hint, never a source of passenger details.
    final uid = _currentUid(), eventId = payload['eventId'];
    if (uid == null ||
        payload['kind'] != 'boarding-assistance' ||
        eventId is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(eventId) ||
        payload.keys.any((k) => !['kind', 'eventId'].contains(k))) {
      throw const ModerationException('invalid-request');
    }
    final value = await _request('/v2/notifications/open', {
      'eventId': eventId,
    });
    final raw = value['request'];
    if (raw is! Map ||
        raw['id'] is! String ||
        raw['driverId'] != uid ||
        !['pending', 'acknowledged'].contains(raw['status'])) {
      throw const ModerationException('invalid-response');
    }
    return _assistanceReceipt(value, raw['id']);
  }

  BoardingRequest _assistanceReceipt(Map<String, dynamic> data, String id) {
    final raw = data['request'];
    if (raw is! Map<String, dynamic> ||
        raw['id'] != id ||
        raw['policyVersion'] != 2 ||
        raw['driverId'] is! String ||
        raw['serviceRunId'] is! String ||
        raw['assignmentVersion'] is! int ||
        DateTime.tryParse(raw['expiresAt']?.toString() ?? '') == null ||
        DateTime.tryParse(raw['createdAt']?.toString() ?? '') == null ||
        !const [
          'pending',
          'acknowledged',
          'completed',
          'rejected',
          'cancelled',
          'expired',
        ].contains(raw['status'])) {
      throw const ModerationException('invalid-response');
    }
    return BoardingRequest.fromMap(raw, id: id);
  }

  Future<BoardingRequest> submitAssistance(BoardingRequest r) async {
    if (r.riderId != _currentUid()) {
      throw const ModerationException('account-changed');
    }
    return _assistanceReceipt(
      await _request('/v2/assistance/submit', {
        'requestId': r.id,
        'serviceRunId': r.serviceRunId,
        'busId': r.busId,
        'stationId': r.stationId,
        'boardingStationId': r.boardingStationId,
        'alightingStationId': r.alightingStationId,
        'purpose': r.purpose,
        'assistanceTypes': r.assistanceTypes,
      }),
      r.id,
    );
  }

  Future<BoardingRequest> assistanceRequest(String id) async =>
      _assistanceReceipt(
        await _request('/v2/assistance/get', {'requestId': id}),
        id,
      );
  Future<BoardingRequest> assistanceAction(String id, String status) async =>
      _assistanceReceipt(
        await _request('/v2/assistance/action', {
          'requestId': id,
          'status': status,
        }),
        id,
      );
  Future<({List<BoardingRequest> items, String? next})> assistanceRequests({
    String? runId,
    String? after,
  }) async {
    final data = await _request('/v2/assistance/list', {
      'serviceRunId': ?runId,
      'after': ?after,
    });
    if (data['items'] is! List ||
        (data['next'] != null && data['next'] is! String)) {
      throw const ModerationException('invalid-response');
    }
    final items = (data['items'] as List)
        .map((r) => _assistanceReceipt({'request': r}, r['id'] as String))
        .toList();
    if (items.any(
      (r) => runId != null
          ? (r.serviceRunId != runId || r.driverId != _currentUid())
          : r.riderId != _currentUid(),
    )) {
      throw const ModerationException('invalid-response');
    }
    return (items: items, next: data['next'] as String?);
  }

  Future<Map<String, dynamic>> banDetail(String accountId) =>
      _request('/v2/bans/detail', {'accountId': accountId});

  Future<Map<String, dynamic>> managedAccount(String accountId) async {
    final data = await _request('/v2/accounts/detail', {
      'accountId': accountId,
    });
    if (data['accountId'] != accountId ||
        data['revision'] is! int ||
        data['revision'] < 0 ||
        data['manualActive'] is! bool ||
        data['restricted'] is! bool ||
        data['communityRestricted'] is! bool ||
        (data['manualReason'] != null && data['manualReason'] is! String) ||
        (data['manualUntil'] != null &&
            (data['manualUntil'] is! String ||
                DateTime.tryParse(data['manualUntil']) == null))) {
      throw const ModerationException('invalid-response');
    }
    return data;
  }

  Future<void> changeManagedAccount({
    required String accountId,
    required String operationId,
    required int revision,
    required String action,
    required String reason,
    int? durationHours,
  }) async {
    final data = await _request('/v2/accounts/change', {
      'accountId': accountId,
      'operationId': operationId,
      'expectedRevision': revision,
      'action': action,
      'reason': reason,
      'durationHours': ?durationHours,
    });
    if (data['accountId'] != accountId ||
        data['operationId'] != operationId ||
        data['duplicate'] is! bool ||
        data['revision'] != revision + 1) {
      throw const ModerationException('invalid-response');
    }
  }

  Future<Map<String, dynamic>> operations({String? after}) =>
      _request('/v2/operations/list', {'after': ?after});

  Map<String, dynamic> _authDetail(Map<String, dynamic> d, String accountId) {
    if (d['accountId'] != accountId ||
        d['revision'] is! int ||
        d['revision'] < 0 ||
        [
          'authExists',
          'authDisabled',
          'authBlocked',
          'deleted',
          'protected',
          'activeOperation',
        ].any((key) => d[key] is! bool) ||
        ![
          'none',
          'pending',
          'approved',
          'rejected',
        ].contains(d['reviewStatus'])) {
      throw const ModerationException('invalid-response');
    }
    final job = d['lastOperation'];
    if (job != null &&
        (job is! Map ||
            job['operationId'] is! String ||
            job['action'] is! String ||
            ![
              'pending',
              'processing',
              'completed',
              'review-required',
            ].contains(job['status']))) {
      throw const ModerationException('invalid-response');
    }
    return d;
  }

  Future<Map<String, dynamic>> authAccount(String accountId) async =>
      _authDetail(
        await _request('/v2/auth/detail', {'accountId': accountId}),
        accountId,
      );

  Future<Map<String, dynamic>> changeAuthAccount({
    required String accountId,
    required String operationId,
    required int revision,
    required String action,
    required String reason,
    String? confirmAccountId,
  }) async {
    final d = await _request('/v2/auth/change', {
      'accountId': accountId,
      'operationId': operationId,
      'expectedRevision': revision,
      'action': action,
      'reason': reason,
      'confirmAccountId': ?confirmAccountId,
    });
    if (d['accountId'] != accountId ||
        d['operationId'] != operationId ||
        d['revision'] != revision + 1 ||
        d['action'] != action ||
        d['duplicate'] is! bool ||
        ![
          'pending',
          'processing',
          'completed',
          'review-required',
        ].contains(d['status'])) {
      throw const ModerationException('invalid-response');
    }
    return d;
  }

  Future<Map<String, dynamic>> retryAuthAccount(
    String accountId,
    String operationId,
  ) async => _authDetail(
    await _request('/v2/auth/retry', {
      'accountId': accountId,
      'operationId': operationId,
    }),
    accountId,
  );
  Future<Map<String, dynamic>> operationDetail(String runId) =>
      _request('/v2/operations/detail', {'runId': runId});
  Future<Map<String, dynamic>> operationCandidates(
    String runId, {
    String? after,
  }) =>
      _request('/v2/operations/candidates', {'runId': runId, 'after': ?after});
  Future<void> handoverOperation({
    required String operationId,
    required String runId,
    required String newDriverId,
    required String expectedDriverId,
    required int expectedVersion,
    required String reason,
  }) async {
    final data = await _request('/v2/operations/handover', {
      'operationId': operationId,
      'runId': runId,
      'newDriverId': newDriverId,
      'expectedDriverId': expectedDriverId,
      'expectedVersion': expectedVersion,
      'reason': reason,
    });
    if (data['operationId'] != operationId ||
        data['runId'] != runId ||
        data['handoverVersion'] != expectedVersion + 1) {
      throw const ModerationException('invalid-response');
    }
  }

  Future<void> acceptOperation(
    String runId,
    int version,
    Map<String, dynamic> gps, {
    required String driverId,
  }) async {
    if (_currentUid() != driverId) {
      throw const ModerationException('authentication-required');
    }
    final data = await _request('/v2/operations/accept', {
      'runId': runId,
      'handoverVersion': version,
      'gps': gps,
    });
    if (data['runId'] != runId ||
        data['handoverVersion'] != version ||
        data['accepted'] != true) {
      throw const ModerationException('invalid-response');
    }
  }

  Future<Map<String, dynamic>> banEvidence(String accountId, {String? after}) =>
      _request('/v2/bans/evidence', {'accountId': accountId, 'after': ?after});
  Future<void> decideBan(
    String accountId,
    String outcome,
    String reason,
    int revision,
  ) async {
    final data = await _request('/v2/bans/decide', {
      'accountId': accountId,
      'outcome': outcome,
      'reason': reason,
      'expectedRevision': revision,
    });
    if (data['duplicate'] is! bool || data['outcome'] != outcome) {
      throw const ModerationException('invalid-response');
    }
  }
}
