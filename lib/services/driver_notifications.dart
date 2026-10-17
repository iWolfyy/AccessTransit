import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/boarding_request.dart';
import 'moderation_client.dart';

enum DriverPushState { off, connecting, denied, ready, unavailable }

abstract interface class DriverPushDevice {
  Stream<String> get tokens;
  Stream<Map<String, dynamic>> get foreground;
  Stream<Map<String, dynamic>> get opened;
  Future<bool> permission({required bool request});
  Future<String?> token();
  Future<void> deleteToken();
  Future<Map<String, dynamic>?> initialMessage();
}

/// Account-bound lifecycle. Messages are untrusted hints; resolve reloads server
/// authority before exposing passenger data. OS auto-init remains disabled.
class DriverNotifications extends ChangeNotifier {
  DriverNotifications({
    required this.device,
    required this.client,
    required this.currentUid,
    required this.readEnabled,
    required this.saveEnabled,
    required this.onOpen,
    required this.onForeground,
    this.cleanupTimeout = const Duration(seconds: 10),
  }) {
    _subscriptions.add(
      device.tokens.listen((token) {
        if (_enabled && _uid != null) {
          final version = _epoch, uid = _uid!;
          unawaited(_queue(() => _register(uid, version, token)));
        }
      }, onError: (_) => _error()),
    );
    _subscriptions.add(
      device.foreground.listen(
        (p) => _hint(p, false),
        onError: (_) => _error(),
      ),
    );
    _subscriptions.add(
      device.opened.listen((p) => _hint(p, true), onError: (_) => _error()),
    );
  }
  final DriverPushDevice device;
  final ModerationClient client;
  final String? Function() currentUid;
  final Future<bool> Function(String) readEnabled;
  final Future<void> Function(String, bool) saveEnabled;
  final void Function(BoardingRequest, Map<String, dynamic>) onOpen;
  final void Function(Map<String, dynamic>) onForeground;
  final Duration cleanupTimeout;
  final _subscriptions = <StreamSubscription>[];
  final _seen = <String>{};
  final _bindings = <({String uid, String deviceId})>{};
  Future<void> _tail = Future.value();
  String? _uid;
  String _locale = 'en';
  bool _enabled = false, _disposed = false;
  int _epoch = 0;
  DriverPushState _state = DriverPushState.off;
  DriverPushState get state => _state;
  String? get accountId => _uid;
  bool get enabled => _enabled;
  bool _current(String uid, int version) =>
      !_disposed && _epoch == version && _uid == uid && currentUid() == uid;
  void _set(DriverPushState state) {
    if (!_disposed) {
      _state = state;
      notifyListeners();
    }
  }

  void _error() {
    if (_enabled) _set(DriverPushState.unavailable);
  }

  Future<void> _queue(Future<void> Function() work) {
    final next = _tail.then((_) => work());
    _tail = next.catchError((_) {});
    return next;
  }

  Future<void> activate(String? uid, String locale) {
    if (_uid == uid && _locale == locale) return _tail;
    final previous = _uid, previouslyEnabled = _enabled;
    final version = ++_epoch;
    _uid = uid;
    _locale = ['en', 'si', 'ta'].contains(locale) ? locale : 'en';
    _enabled = false;
    _seen.clear();
    _set(DriverPushState.off);
    return _queue(() async {
      if (previous != uid && (previouslyEnabled || _bindings.isNotEmpty)) {
        await _cleanup();
      }
      if (uid == null || !_current(uid, version)) return;
      try {
        final saved = await readEnabled(uid);
        if (!_current(uid, version) || !saved) return;
        _enabled = true;
        await _start(uid, version, false);
      } catch (_) {
        if (_current(uid, version)) _set(DriverPushState.unavailable);
      }
    });
  }

  Future<void> enable() {
    final uid = _uid, version = _epoch;
    if (uid == null || !_current(uid, version)) return Future.value();
    return _queue(() async {
      if (!_current(uid, version)) return;
      _enabled = true;
      try {
        await _start(uid, version, true);
      } catch (_) {
        if (_current(uid, version)) _set(DriverPushState.unavailable);
      }
    });
  }

  Future<void> _start(String uid, int version, bool request) async {
    _set(DriverPushState.connecting);
    if (!await device.permission(request: request)) {
      if (_current(uid, version)) {
        _enabled = false;
        await saveEnabled(uid, false);
        await _cleanup();
        if (_current(uid, version)) _set(DriverPushState.denied);
      }
      return;
    }
    if (!_current(uid, version)) return;
    await saveEnabled(uid, true);
    if (!_current(uid, version)) return;
    final token = await device.token();
    if (!_current(uid, version)) return;
    if (token == null || token.isEmpty) throw StateError('token-unavailable');
    await _register(uid, version, token);
  }

  Future<void> refreshPermission() {
    final uid = _uid, version = _epoch;
    if (uid == null || !_enabled || !_current(uid, version)) {
      return Future.value();
    }
    return _queue(() async {
      if (!_current(uid, version) || !_enabled) return;
      try {
        await _start(uid, version, false);
      } catch (_) {
        if (_current(uid, version)) _set(DriverPushState.unavailable);
      }
    });
  }

  Future<void> _register(String uid, int version, String token) async {
    if (!_current(uid, version) || !_enabled) return;
    try {
      final deviceId = await client.registerNotificationDevice(
        token: token,
        locale: _locale,
        accountId: uid,
      );
      _bindings.add((uid: uid, deviceId: deviceId));
      if (!_current(uid, version) || !_enabled) return;
      for (final binding in _bindings.toList()) {
        if (binding.uid == uid && binding.deviceId != deviceId) {
          await client.removeNotificationDevice(
            binding.deviceId,
            accountId: uid,
          );
          _bindings.remove(binding);
        }
      }
      if (_current(uid, version)) _set(DriverPushState.ready);
    } catch (_) {
      if (_current(uid, version)) _set(DriverPushState.unavailable);
    }
  }

  Future<void> _cleanup() async {
    for (final binding in _bindings.toList()) {
      if (currentUid() == binding.uid) {
        try {
          await client.removeNotificationDevice(
            binding.deviceId,
            accountId: binding.uid,
          );
          _bindings.remove(binding);
        } catch (_) {}
      }
    }
    try {
      await device.deleteToken().timeout(cleanupTimeout);
      _bindings.clear();
    } catch (_) {}
  }

  /// Run before Firebase signOut; offline cleanup does not block logout.
  Future<void> disable() {
    final uid = _uid;
    ++_epoch;
    _enabled = false;
    _seen.clear();
    _set(DriverPushState.off);
    return _queue(() async {
      if (uid != null) {
        try {
          await saveEnabled(uid, false);
        } catch (_) {}
      }
      await _cleanup();
    }).timeout(cleanupTimeout, onTimeout: () {});
  }

  Future<BoardingRequest> resolve(Map<String, dynamic> payload) async {
    final uid = _uid, version = _epoch;
    if (uid == null || !_enabled || !_current(uid, version)) {
      throw const ModerationException('account-changed');
    }
    final request = await client.openAssistanceNotification(payload);
    if (!_current(uid, version) || !_enabled) {
      throw const ModerationException('account-changed');
    }
    return request;
  }

  void _hint(Map<String, dynamic> p, bool opened) {
    final uid = _uid, version = _epoch;
    if (uid == null || !_enabled || !_current(uid, version)) return;
    unawaited(
      _queue(() async {
        if (!_current(uid, version) || !_enabled) return;
        try {
          final request = await resolve(p);
          if (!_current(uid, version)) return;
          final key = '${opened ? 'open' : 'foreground'}:${p['eventId']}';
          if (!_seen.add(key)) return;
          if (_seen.length > 100) _seen.remove(_seen.first);
          if (opened) {
            onOpen(request, p);
          } else {
            onForeground(p);
          }
        } catch (_) {
          /* Stale/unauthorized hints never expose private data. */
        }
      }),
    );
  }

  Future<void> initialMessage() async {
    final uid = _uid, version = _epoch;
    try {
      final p = await device.initialMessage();
      if (p != null && uid != null && _current(uid, version)) _hint(p, true);
    } catch (_) {}
    await _tail;
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
