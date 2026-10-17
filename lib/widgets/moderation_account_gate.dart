import '../l10n/localization_context.dart';

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/moderation_client.dart';
import '../screens/community/report_reviews_screen.dart';
import '../services/sample_test_mode.dart';

/// Disposes authenticated workspaces on a confirmed restriction or unavailable
/// access check. Backend rules independently protect all client mutations.
class ModerationAccountGate extends StatefulWidget {
  const ModerationAccountGate({
    super.key,
    required this.child,
    this.client,
    this.accounts,
    this.changes,
  });
  final Widget child;
  final ModerationClient? client;
  final Stream<String?>? accounts;
  final Stream<void> Function(String)? changes;
  @override
  State<ModerationAccountGate> createState() => _ModerationAccountGateState();
}

class _ModerationAccountGateState extends State<ModerationAccountGate>
    with WidgetsBindingObserver {
  late final client = widget.client ?? ModerationClient();
  StreamSubscription? auth, access;
  Timer? expiry;
  String? uid;
  ModerationAccountStatus? status;
  bool ready = false, failed = false;
  bool showReviews = false;
  int revision = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    auth =
        (widget.accounts ??
                FirebaseAuth.instance.authStateChanges().map((u) => u?.uid))
            .distinct()
            .listen((next) {
              access?.cancel();
              expiry?.cancel();
              uid = next;
              revision++;
              setState(() {
                ready = next == null;
                status = null;
                failed = false;
                showReviews = false;
              });
              if (next != null) {
                final watchedOwner = next;
                final stream =
                    widget.changes?.call(next) ??
                    FirebaseFirestore.instance
                        .collection(SampleTestMode.collection('account_access'))
                        .doc(next)
                        .snapshots(includeMetadataChanges: true)
                        .map((s) {
                          if (s.metadata.isFromCache ||
                              s.metadata.hasPendingWrites) {
                            throw StateError(
                              'Connect to verify account access.',
                            );
                          }
                        });
                access = stream.listen(
                  (_) {
                    if (mounted && uid == watchedOwner) reload();
                  },
                  onError: (_) {
                    if (!mounted || uid != watchedOwner) return;
                    revision++;
                    expiry?.cancel();
                    if (mounted) {
                      setState(() {
                        ready = false;
                        failed = true;
                      });
                    }
                  },
                );
              }
            });
  }

  Future<void> reload() async {
    if (uid == null) return;
    final owner = uid, version = ++revision;
    expiry?.cancel();
    setState(() {
      ready = false;
      failed = false;
    });
    try {
      final value = await client.accountStatus();
      if (!mounted || owner != uid || version != revision) return;
      setState(() {
        status = value;
        ready = true;
      });
      if (value.suspendedUntil != null) {
        expiry = Timer(
          value.suspendedUntil!.difference(value.serverTime),
          reload,
        );
      }
    } catch (_) {
      if (mounted && version == revision) {
        setState(() {
          ready = false;
          failed = true;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && uid != null) reload();
  }

  @override
  void dispose() {
    revision++;
    auth?.cancel();
    access?.cancel();
    expiry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (widget.client == null) client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ready && (uid == null || status?.isSuspended == false)) {
      return widget.child;
    }
    if (uid != null && showReviews) {
      return ReportReviewsScreen(
        client: client,
        onClose: () => setState(() => showReviews = false),
      );
    }
    return Material(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!ready && !failed) const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  failed
                      ? context.l10n.accountStatusUnavailable
                      : !ready
                      ? context.l10n.accountStatusChecking
                      : status!.state == 'temporary'
                      ? context.l10n.accountTemporaryUntil(
                          status!.suspendedUntil!.toUtc().toIso8601String(),
                        )
                      : context.l10n.accountSuspended,
                ),
                TextButton(
                  onPressed: reload,
                  child: Text(context.l10n.accountStatusRetry),
                ),
                if (uid != null && status?.banReason != null)
                  Text(status!.banReason!),
                if (uid != null)
                  TextButton(
                    onPressed: () => setState(() => showReviews = true),
                    child: Text(context.l10n.reviewsTitle),
                  ),
                TextButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: Text(context.l10n.accountSignOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
