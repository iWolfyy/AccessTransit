import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/localization_context.dart';

import '../services/operator_access_service.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';

/// Every dashboard entry goes through this gate, including direct navigation.
class OperatorAccessGate extends StatefulWidget {
  const OperatorAccessGate({super.key, required this.builder, this.service});
  final WidgetBuilder builder;
  final OperatorAccessService? service;

  @override
  State<OperatorAccessGate> createState() => _OperatorAccessGateState();
}

class _OperatorAccessGateState extends State<OperatorAccessGate>
    with WidgetsBindingObserver {
  StreamSubscription<String?>? _auth;
  StreamSubscription<bool>? _approval;
  String? _uid;
  bool _approved = false;
  bool _checking = true;
  int _generation = 0;
  late final OperatorAccessService _service =
      widget.service ?? OperatorAccessService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  void _start() {
    _auth?.cancel();
    _auth = _service.userIds.listen(_watch, onError: (_) => _watch(null));
  }

  void _watch(String? uid) {
    final generation = ++_generation;
    _approval?.cancel();
    setState(() {
      _uid = uid;
      _approved = false;
      _checking = uid != null;
    });
    if (uid == null) return;
    _approval = _service
        .watchApproval(uid)
        .listen(
          (approved) {
            if (!mounted || generation != _generation) return;
            setState(() {
              _approved = approved;
              _checking = false;
            });
          },
          onError: (_) {
            if (!mounted || generation != _generation) return;
            setState(() {
              _approved = false;
              _checking = false;
            });
          },
        );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _start();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      ++_generation;
      _auth?.cancel();
      _approval?.cancel();
      setState(() {
        _approved = false;
        _checking = true;
      });
    }
  }

  @override
  void dispose() {
    ++_generation;
    WidgetsBinding.instance.removeObserver(this);
    _auth?.cancel();
    _approval?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_approved) {
      return KeyedSubtree(key: ValueKey(_uid), child: widget.builder(context));
    }
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.driverAccess)),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _checking
                      ? context.l10n.driverChecking
                      : _uid == null
                      ? context.l10n.driverSignInApproval
                      : context.l10n.driverApprovalRequired,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    _watch(null);
                    _start();
                  },
                  child: Text(context.l10n.driverCheckAgain),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      if (_uid != null) await AuthService().logout();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.driverSignOutFailed),
                        ),
                      );
                    }
                  },
                  child: Text(context.l10n.driverReturnSignIn),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
