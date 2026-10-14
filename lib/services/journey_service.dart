import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'dart:math';

import '../constants/firestore_constants.dart';
import '../models/journey_model.dart';

/// Firestore service for the `journeys` collection.
///
/// Documents are stored at `journeys/{journeyId}`.
/// Each document links a [JourneyModel.passengerId] to a [JourneyModel.busId]
/// so the passenger's [LiveJourneyScreen] can subscribe to
/// `live_locations/{busId}` for real-time tracking.
class JourneyService {
  JourneyService({
    FirebaseFirestore? firestore,
    this.writer,
    this.activeReader,
    this.journeyReader,
    this.statusWriter,
    this.currentPassengerId,
  }) : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;
  final Future<JourneyModel> Function(JourneyModel)? writer;
  final Stream<JourneyModel?> Function(String)? activeReader;
  final Stream<JourneyModel?> Function(String)? journeyReader;
  final Future<void> Function(String, JourneyStatus)? statusWriter;
  final String? Function()? currentPassengerId;
  String? get signedInPassenger {
    if (currentPassengerId != null) return currentPassengerId!();
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  String newJourneyId() =>
      'journey_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';

  FirebaseFirestore get _firestore {
    if (_customFirestore != null) return _customFirestore;
    return FirebaseFirestore.instance;
  }

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
    if (journey.passengerId.isEmpty ||
        signedInPassenger != journey.passengerId) {
      throw StateError('Sign in with the account saving this journey.');
    }
    final withId = journey.copyWith(
      journeyId: journey.journeyId.isEmpty ? newJourneyId() : journey.journeyId,
    );
    final saved = writer != null
        ? await writer!(withId)
        : await _firestore.runTransaction<JourneyModel>(
            (transaction) async {
              final ref = journeyDocument(withId.journeyId);
              final snapshot = await transaction.get(ref);
              if (snapshot.exists) {
                final existing = JourneyModel.fromMap(
                  snapshot.data()!,
                  documentId: snapshot.id,
                );
                Map<String, dynamic> selection(JourneyModel j) => j.toMap()
                  ..remove('createdAt')
                  ..remove('status');
                if (!mapEquals(selection(existing), selection(withId))) {
                  throw StateError(
                    'This journey ID belongs to a different selection.',
                  );
                }
                return existing;
              }
              transaction.set(ref, withId.toMap(isCreate: true));
              return withId;
            },
            timeout: const Duration(seconds: 10),
            maxAttempts: 3,
          );
    Map<String, dynamic> selection(JourneyModel j) => j.toMap()
      ..remove('createdAt')
      ..remove('status');
    if (!mapEquals(selection(saved), selection(withId))) {
      throw StateError('The saved journey does not match your selection.');
    }
    return saved;
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
    if (statusWriter != null) {
      return statusWriter!(journeyId, JourneyStatus.completed);
    }
    await journeyDocument(journeyId).update({
      FirestoreConstants.fieldJourneyStatus: JourneyStatus.completed.value,
    });
  }

  Future<void> cancelJourney(String journeyId) async {
    if (statusWriter != null) {
      return statusWriter!(journeyId, JourneyStatus.cancelled);
    }
    await journeyDocument(journeyId)
        .update({'status': JourneyStatus.cancelled.value});
  }

  Stream<JourneyModel?> watchJourney(String journeyId) => journeyReader != null
      ? journeyReader!(journeyId)
      : journeyDocument(journeyId)
            .snapshots(includeMetadataChanges: true)
            .where((s) => !s.metadata.hasPendingWrites)
            .map(
              (s) => s.exists
                  ? JourneyModel.fromMap(s.data()!, documentId: s.id)
                  : null,
            );

  // ---------------------------------------------------------------------------
  // Read — one-shot
  // ---------------------------------------------------------------------------

  /// Fetches the most recent active/confirmed journey for [passengerId].
  ///
  /// Returns `null` if no journey exists.
  Future<JourneyModel?> getActiveJourney(String passengerId) async {
    final snapshot = await _journeysCollection
        .where(FirestoreConstants.fieldPassengerId, isEqualTo: passengerId)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final activeJourneys = snapshot.docs
        .where((d) => !d.metadata.hasPendingWrites)
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
    if (activeReader != null) return activeReader!(passengerId);
    final history = AcknowledgedJourneyHistory(passengerId);
    try {
      return _journeysCollection
          .where(FirestoreConstants.fieldPassengerId, isEqualTo: passengerId)
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) {
            return history.accept(
              snapshot.docs
                  .map(
                    (doc) => (
                      JourneyModel.fromMap(doc.data(), documentId: doc.id),
                      doc.metadata.hasPendingWrites,
                    ),
                  )
                  .toList(),
              authoritative:
                  !snapshot.metadata.isFromCache &&
                  !snapshot.metadata.hasPendingWrites,
            );
          });
    } catch (error, stack) {
      return Stream.error(error, stack);
    }
  }
}

/// Per-subscription receipts: pending local status writes cannot close a saved plan.
class AcknowledgedJourneyHistory {
  AcknowledgedJourneyHistory(this.passengerId);
  final String passengerId;
  final Map<String, JourneyModel> _acknowledged = {};
  JourneyModel? accept(
    List<(JourneyModel, bool)> records, {
    required bool authoritative,
  }) {
    for (final record in records) {
      if (!record.$2 && record.$1.passengerId == passengerId) {
        _acknowledged[record.$1.journeyId] = record.$1;
      }
    }
    if (authoritative) {
      final ids = records
          .where((r) => !r.$2 && r.$1.passengerId == passengerId)
          .map((r) => r.$1.journeyId)
          .toSet();
      _acknowledged.removeWhere((id, _) => !ids.contains(id));
    }
    final open = _acknowledged.values.where((j) => j.isOpen).toList()
      ..sort(
        (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
    return open.isEmpty ? null : open.first;
  }
}
