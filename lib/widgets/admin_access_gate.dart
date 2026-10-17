import 'dart:async';

import '../l10n/shared_presentation.dart';

import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../services/admin_access_service.dart';

/// A profile role never grants administrative authority.
class AdminAccessGate extends StatefulWidget {
  const AdminAccessGate({super.key, required this.child, this.service});
  final Widget child;
  final AdminAccessService? service;
  @override
  State<AdminAccessGate> createState() => _AdminAccessGateState();
}

class _AdminAccessGateState extends State<AdminAccessGate>
    with WidgetsBindingObserver {
  StreamSubscription<String?>? _auth;
  late final _service = widget.service ?? AdminAccessService();
  String? _uid;
  bool _foreground = true;
  bool _allowed = false;
  bool _checking = true;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth = _service.userIds.listen((uid) {
      _uid = uid;
      _check();
    }, onError: (_) => _deny());
  }

  void _deny() {
    ++_generation;
    if (mounted) {
      setState(() {
        _allowed = false;
        _checking = false;
      });
    }
  }

  Future<void> _check() async {
    if (!_foreground) {
      _deny();
      return;
    }
    final generation = ++_generation;
    setState(() {
      _allowed = false;
      _checking = true;
    });
    var allowed = false;
    try {
      final uid = _uid;
      allowed = uid != null && await _service.check(uid);
    } catch (_) {
      /* Fail closed on token/network errors. */
    }
    if (!mounted || generation != _generation) return;
    setState(() {
      _allowed = allowed;
      _checking = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      _check();
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _foreground = false;
      _deny();
    }
  }

  @override
  void dispose() {
    ++_generation;
    _auth?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_allowed) return widget.child;
    return Scaffold(
      appBar: AppBar(title: Text(context.sharedText('Administrator access'))),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_checking)
                  const CircularProgressIndicator()
                else
                  const Icon(Icons.admin_panel_settings_outlined, size: 48),
                const SizedBox(height: 20),
                Text(
                  context.sharedText(
                    _checking ? 'Checking administrator access...' : 'An administrator claim and an online connection are required. A profile role does not grant access.',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _checking ? null : _check,
                  child: Text(context.sharedText('Check again')),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  ),
                  child: Text(context.sharedText('Sign in')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
