import '../screens/community/manual_appeals_screen.dart';
import '../l10n/localization_context.dart';

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/moderation_client.dart';
import '../screens/community/report_reviews_screen.dart';
import '../services/sample_test_mode.dart';
import '../services/server_snapshot_stream.dart';

/// Verifies initial access before mounting the workspace. Subsequent checks run
/// in the background; restrictions/failed checks dispose the workspace.
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
  bool showReviews = false, showManualAppeals = false;
  int revision = 0;
  String? loadingOwner;
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
              loadingOwner = null;
              revision++;
              setState(() {
                ready = next == null;
                status = null;
                failed = false;
                showReviews = false;
                showManualAppeals = false;
              });
              if (next != null) {
                final watchedOwner = next;
                final stream =
                    widget.changes?.call(next) ??
                    serverSnapshotStream(
                      FirebaseFirestore.instance
                          .collection(
                            SampleTestMode.collection('account_access'),
                          )
                          .doc(next)
                          .snapshots(includeMetadataChanges: true),
                      isVerified: (s) =>
                          !s.metadata.isFromCache &&
                          !s.metadata.hasPendingWrites,
                    ).map((_) {});
                access = stream.listen(
                  (_) {
                    if (mounted && uid == watchedOwner) reload();
                  },
                  onError: (_) {
                    if (!mounted || uid != watchedOwner) return;
                    // Metadata can temporarily become cached during token
                    // refresh. Verify through the trusted API rather than
                    // restarting the entire Navigator on each cache event.
                    reload();
                  },
                );
                reload();
              }
            });
  }

  Future<void> reload() async {
    if (uid == null || loadingOwner == uid) return;
    final owner = uid, version = ++revision;
    loadingOwner = owner;
    expiry?.cancel();
    setState(() {
      // A previously verified account can keep navigating during revalidation.
      // Every mutation still checks server-owned access independently. Initial
      // checks and account switches have no verified status and remain blocked.
      ready = status?.isSuspended == false;
      failed = false;
    });
    try {
      ModerationAccountStatus? result;
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          result = await client.accountStatus();
          break;
        } on ModerationException catch (e) {
          if (attempt == 2 ||
              !{
                'service-unavailable',
                'authentication-unavailable',
                'network-error',
              }.contains(e.code)) {
            rethrow;
          }
          await Future<void>.delayed(
            Duration(milliseconds: 300 * (attempt + 1)),
          );
          if (!mounted || owner != uid || version != revision) return;
        }
      }
      final value = result!;
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
    } finally {
      if (version == revision) loadingOwner = null;
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
    final allowed = ready && (uid == null || status?.isSuspended == false);
    final retainWorkspace =
        allowed || (!failed && uid != null && status?.isSuspended == false);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (retainWorkspace)
          Offstage(
            offstage: !allowed,
            child: ExcludeFocus(
              excluding: !allowed,
              child: IgnorePointer(
                ignoring: !allowed,
                child: TickerMode(enabled: allowed, child: widget.child),
              ),
            ),
          ),
        if (!allowed)
          Overlay(
            key: ValueKey((
              uid,
              revision,
              failed,
              ready,
              showReviews,
              showManualAppeals,
            )),
            initialEntries: [OverlayEntry(builder: _blockedBody)],
          ),
      ],
    );
  }

  Widget _blockedBody(BuildContext context) {
    if (uid != null && showManualAppeals) {
      return ManualAppealsScreen(
        client: client,
        onClose: () => setState(() => showManualAppeals = false),
      );
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
                if (uid != null)
                  TextButton(
                    onPressed: () => setState(() => showManualAppeals = true),
                    child: Text(context.l10n.manualAppealsTitle),
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
