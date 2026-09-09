import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_constants.dart';
import '../models/journey_model.dart';

/// Firestore service for the `journeys` collection.
///
/// Documents are stored at `journeys/{journeyId}`.
/// Each document links a [JourneyModel.passengerId] to a [JourneyModel.busId]
/// so the passenger's [LiveJourneyScreen] can subscribe to
/// `live_locations/{busId}` for real-time tracking.
class JourneyService {
  JourneyService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _journeysCollection =>
      _firestore.collection(FirestoreConstants.journeysCollection);

  DocumentReference<Map<String, dynamic>> journeyDocument(String journeyId) =>
      _journeysCollection.doc(journeyId);

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Creates a new journey document for the passenger.
  ///
  /// Generates a new Firestore document ID and writes the journey with
  /// server timestamp.  Returns the created [JourneyModel] with its ID.
  Future<JourneyModel> createJourney(JourneyModel journey) async {
    final ref = _journeysCollection.doc();
    final withId = journey.copyWith(journeyId: ref.id);
    await ref.set(withId.toMap(isCreate: true));
    return withId;
  }

  /// Updates the `busId` field of an existing journey document.
  ///
  /// Use this when an operator is later assigned to a journey.
  Future<void> assignBus(String journeyId, String busId) async {
    await journeyDocument(journeyId).update({
      FirestoreConstants.fieldBusId: busId,
      FirestoreConstants.fieldJourneyStatus: JourneyStatus.active.value,
    });
  }

  /// Marks a journey as completed.
  Future<void> completeJourney(String journeyId) async {
    await journeyDocument(journeyId).update({
      FirestoreConstants.fieldJourneyStatus: JourneyStatus.completed.value,
    });
  }

  // ---------------------------------------------------------------------------
  // Read — one-shot
  // ---------------------------------------------------------------------------

  /// Fetches the most recent active/confirmed journey for [passengerId].
  ///
  /// Returns `null` if no journey exists.
  Future<JourneyModel?> getActiveJourney(String passengerId) async {
    final snapshot = await _journeysCollection
        .where(
          FirestoreConstants.fieldPassengerId,
          isEqualTo: passengerId,
        )
        .get();

    if (snapshot.docs.isEmpty) return null;

    final activeJourneys = snapshot.docs
        .map((doc) => JourneyModel.fromMap(doc.data(), documentId: doc.id))
        .where(
          (j) =>
              j.status == JourneyStatus.confirmed ||
              j.status == JourneyStatus.active,
        )
        .toList();

    if (activeJourneys.isEmpty) return null;

    activeJourneys.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return activeJourneys.first;
  }

  // ---------------------------------------------------------------------------
  // Read — real-time
  // ---------------------------------------------------------------------------

  /// Real-time stream of the most recent active/confirmed journey for [passengerId].
  ///
  /// Emits `null` when no active journey exists for this passenger.
  /// The stream updates automatically whenever Firestore changes — no polling.
  Stream<JourneyModel?> watchActiveJourney(String passengerId) {
    return _journeysCollection
        .where(
          FirestoreConstants.fieldPassengerId,
          isEqualTo: passengerId,
        )
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      final activeJourneys = snapshot.docs
          .map((doc) => JourneyModel.fromMap(doc.data(), documentId: doc.id))
          .where(
            (j) =>
                j.status == JourneyStatus.confirmed ||
                j.status == JourneyStatus.active,
          )
          .toList();

      if (activeJourneys.isEmpty) return null;

      activeJourneys.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return activeJourneys.first;
    });
  }
}
