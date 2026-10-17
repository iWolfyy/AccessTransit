import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../logic/transit_time.dart';
import '../models/service_run.dart';
import 'bus_details_repository.dart';
import 'sample_test_mode.dart';
import 'server_snapshot_stream.dart';

class TransitSearchBackend extends BusDetailsRepository {
  Stream<List<ServiceRun>> searchRuns(String busId) async* {
    yield* serverSnapshotStream(
      FirebaseFirestore.instance
          .collection(SampleTestMode.collection('service_runs'))
          .where('busId', isEqualTo: busId)
          .where('status', whereIn: ['scheduled', 'boarding', 'in_progress'])
          .snapshots(includeMetadataChanges: true),
      isVerified: (s) =>
          !s.metadata.isFromCache && !s.metadata.hasPendingWrites,
    ).map((s) {
      return s.docs.map((d) => ServiceRun.fromMap(d.id, d.data())).toList();
    });
  }

  SearchTimeAnchor? _anchor;
  String? _owner;
  Future<SearchTimeAnchor>? _pending;

  Future<SearchTimeAnchor> synchronizeTime() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Sign in and connect to verify search time.');
    }
    if (_owner == uid && _anchor?.isFresh == true) return _anchor!;
    if (_owner == uid && _pending != null) return _pending!;
    _owner = uid;
    final future = _readTime(uid);
    _pending = future;
    try {
      final receipt = await future;
      if (FirebaseAuth.instance.currentUser?.uid != uid || _owner != uid) {
        throw StateError('The search account changed.');
      }
      return _anchor = receipt;
    } finally {
      if (identical(_pending, future)) _pending = null;
    }
  }

  Future<SearchTimeAnchor> _readTime(String uid) async {
    final ref = FirebaseFirestore.instance
        .collection(SampleTestMode.collection('search_clock'))
        .doc(uid);
    final roundTrip = Stopwatch()..start();
    await ref
        .set({'serverTime': FieldValue.serverTimestamp()})
        .timeout(const Duration(seconds: 10));
    final reply = await ref
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 10));
    final time = reply.data()?['serverTime'];
    if (reply.metadata.isFromCache ||
        reply.metadata.hasPendingWrites ||
        time is! Timestamp ||
        roundTrip.elapsed > const Duration(seconds: 5)) {
      throw StateError('Search time could not be verified promptly. Retry.');
    }
    // Conservative receipt: server timestamp is no later than receipt time.
    // Add the measured round trip so an already-past opportunity is not offered.
    return SearchTimeAnchor(time.toDate(), uncertainty: roundTrip.elapsed);
  }

  void invalidateTime() {
    _anchor = null;
  }
}
