import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/localization_context.dart';

import '../services/driver_route_service.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';

/// Nested inside the approval gate. Losing/changing a route disposes its GPS UI.
class DriverRouteGate extends StatefulWidget {
  const DriverRouteGate({super.key, required this.builder, this.service});
  final Widget Function(BuildContext, String) builder;
  final DriverRouteService? service;
  @override
  State<DriverRouteGate> createState() => _DriverRouteGateState();
}

class _DriverRouteGateState extends State<DriverRouteGate>
    with WidgetsBindingObserver {
  late final _service = widget.service ?? DriverRouteService();
  StreamSubscription<String?>? _auth, _grant;
  String? _route;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  void _start() {
    _auth?.cancel();
    _auth = _service.userIds.listen(
      _watch,
      onError: (Object _) => _watch(null),
    );
  }

  void _watch(String? uid) {
    final generation = ++_generation;
    _grant?.cancel();
    setState(() => _route = null);
    if (uid == null) return;
    _grant = _service
        .watchRoute(uid)
        .listen(
          (route) {
            if (mounted && generation == _generation) {
              setState(() => _route = route);
            }
          },
          onError: (Object _) {
            if (mounted && generation == _generation) {
              setState(() => _route = null);
            }
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
      _grant?.cancel();
      setState(() => _route = null);
    }
  }

  @override
  void dispose() {
    ++_generation;
    _auth?.cancel();
    _grant?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;
    if (route != null && route.isNotEmpty) {
      return KeyedSubtree(
        key: ValueKey('$_generation:$route'),
        child: widget.builder(context, route),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.driverRouteAssignment)),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.route, size: 40),
                const SizedBox(height: 16),
                Text(context.l10n.driverRouteRequired),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    _watch(null);
                    _start();
                  },
                  child: Text(context.l10n.driverCheckAssignment),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await AuthService().logout();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.driverSignOutFailed),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(context.l10n.profileSignOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
