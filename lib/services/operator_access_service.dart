import 'package:cloud_firestore/cloud_firestore.dart';

import 'sample_test_mode.dart';

import 'package:firebase_auth/firebase_auth.dart';

/// A profile's operator role expresses intent; only this trusted record grants access.
class OperatorAccessService {
  Stream<String?> get userIds {
    try {
      return FirebaseAuth.instance.authStateChanges().map((user) => user?.uid);
    } catch (_) {
      return Stream.value(null);
    }
  }

  Stream<bool> watchApproval(String uid) {
    try {
      return FirebaseFirestore.instance
          .collection(SampleTestMode.collection('operator_access'))
          .doc(uid)
          .snapshots(includeMetadataChanges: true)
          .map(
            (snapshot) =>
                !snapshot.metadata.isFromCache &&
                !snapshot.metadata.hasPendingWrites &&
                snapshot.data()?['approved'] == true,
          );
    } catch (_) {
      return Stream.value(false);
    }
  }
}
