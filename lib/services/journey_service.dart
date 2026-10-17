import 'transit_catalogue.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'dart:math';
import 'dart:convert';

import '../constants/firestore_constants.dart';
import '../models/journey_model.dart';

class SavedJourneyCursor {
  const SavedJourneyCursor(this.owner, this.id);
  final String owner, id;
}

class SavedJourneyPage {
  SavedJourneyPage(List<JourneyModel> items, {this.next})
    : items = List.unmodifiable(items);
  final List<JourneyModel> items;
  final SavedJourneyCursor? next;
}

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
    this.remover,
    this.pageReader,
    this.savedReader,
  }) : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;
  final Future<JourneyModel> Function(JourneyModel)? writer;
  final Stream<JourneyModel?> Function(String)? activeReader;
  final Stream<JourneyModel?> Function(String)? journeyReader;
  final Future<void> Function(String, JourneyStatus)? statusWriter;
  final String? Function()? currentPassengerId;
  final Future<void> Function(String)? remover;
  final Future<SavedJourneyPage> Function(String, SavedJourneyCursor?)?
  pageReader;
  final Future<JourneyModel?> Function(String)? savedReader;
  static const savedPageSize = 20;

  void _owner(String owner) {
    if (owner.isEmpty || signedInPassenger != owner) {
      throw StateError('Saved-trip account changed');
    }
  }

  Future<SavedJourneyPage> pageSavedJourneys(
    String owner, {
    SavedJourneyCursor? after,
  }) async {
    _owner(owner);
    if (after != null &&
        (after.owner != owner || after.id.isEmpty || after.id.contains('/'))) {
      throw StateError('Invalid saved-trip cursor');
    }
    if (TransitCatalogue.demo) return SavedJourneyPage([]);
    SavedJourneyPage page;
    if (pageReader != null) {
      page = await pageReader!(owner, after);
    } else {
      Query<Map<String, dynamic>> query = _journeysCollection
          .where('passengerId', isEqualTo: owner)
          .orderBy(FieldPath.documentId, descending: true)
          .limit(savedPageSize + 1);
      if (after != null) query = query.startAfter([after.id]);
      final result = await query
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 12));
      if (result.metadata.isFromCache ||
          result.metadata.hasPendingWrites ||
          result.docs.any((d) => d.metadata.hasPendingWrites)) {
        throw StateError('Connect to verify saved trips');
      }
      final docs = result.docs.take(savedPageSize).toList();
      page = SavedJourneyPage(
        docs
            .map((d) => JourneyModel.fromMap(d.data(), documentId: d.id))
            .toList(),
        next: result.docs.length > savedPageSize
            ? SavedJourneyCursor(owner, docs.last.id)
            : null,
      );
    }
    _owner(owner);
    final ids = page.items.map((j) => j.journeyId).toList();
    if (page.items.length > savedPageSize ||
        ids.toSet().length != ids.length ||
        page.items.any(
          (j) =>
              j.passengerId != owner ||
              j.journeyId.isEmpty ||
              j.journeyId.contains('/'),
        ) ||
        (after != null && ids.any((id) => id.compareTo(after.id) >= 0)) ||
        List.generate(
          ids.isNotEmpty ? ids.length - 1 : 0,
          (i) => ids[i].compareTo(ids[i + 1]) <= 0,
        ).any((v) => v) ||
        (page.next != null &&
            (page.next!.owner != owner ||
                ids.isEmpty ||
                page.next!.id != ids.last))) {
      throw StateError('Saved-trip page did not match its owner/order');
    }
    return page;
  }

  Future<JourneyModel?> getSavedJourney(String id, String owner) async {
    _owner(owner);
    JourneyModel? value;
    if (savedReader != null) {
      value = await savedReader!(id);
    } else {
      final snapshot = await journeyDocument(id)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 12));
      if (snapshot.metadata.isFromCache || snapshot.metadata.hasPendingWrites) {
        throw StateError('Saved trip unavailable');
      }
      value = snapshot.exists
          ? JourneyModel.fromMap(snapshot.data()!, documentId: snapshot.id)
          : null;
    }
    _owner(owner);
    if (value != null && (value.passengerId != owner || value.journeyId != id)) {
      throw StateError('Saved trip does not match its owner');
    }
    return value;
  }

  Future<void> removeJourney(String id) async {
    TransitCatalogue.requireSharedWrites();
    final owner = signedInPassenger;
    if (owner == null) throw StateError('Sign in to remove this saved trip.');
    if (remover != null) return remover!(id);
    await _firestore.runTransaction((tx) async {
      final ref = journeyDocument(id);
      final snapshot = await tx.get(ref);
      if (!snapshot.exists) return;
      if (snapshot.data()?['passengerId'] != owner ||
          signedInPassenger != owner) {
        throw StateError('The signed-in account changed.');
      }
      tx.delete(ref);
    });
  }

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
    TransitCatalogue.requireSharedWrites();
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
                  ..['fareQuote'] = j.fareQuote == null
                      ? null
                      : jsonEncode(j.fareQuote!.toMap())
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
      ..['fareQuote'] = j.fareQuote == null
          ? null
          : jsonEncode(j.fareQuote!.toMap())
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
    TransitCatalogue.requireSharedWrites();
    await journeyDocument(journeyId).update({
      FirestoreConstants.fieldBusId: busId,
      FirestoreConstants.fieldJourneyStatus: JourneyStatus.active.value,
    });
  }

  /// Marks a journey as completed.
  Future<void> completeJourney(String journeyId) async {
    TransitCatalogue.requireSharedWrites();
    if (statusWriter != null) {
      return statusWriter!(journeyId, JourneyStatus.completed);
    }
    await journeyDocument(journeyId).update({
      FirestoreConstants.fieldJourneyStatus: JourneyStatus.completed.value,
    });
  }

  Future<void> cancelJourney(String journeyId) async {
    TransitCatalogue.requireSharedWrites();
    if (statusWriter != null) {
      return statusWriter!(journeyId, JourneyStatus.cancelled);
    }
    await journeyDocument(journeyId)
        .update({'status': JourneyStatus.cancelled.value});
  }

  Stream<JourneyModel?> watchJourney(String journeyId) => TransitCatalogue.demo
      ? Stream.value(null)
      : journeyReader != null
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
    _owner(passengerId);
    if (TransitCatalogue.demo) return null;
    final snapshot = await _activeQuery(passengerId)
        .get(const GetOptions(source: Source.server));
    _owner(passengerId);

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
    if (signedInPassenger != passengerId) {
      return Stream.error(StateError('Saved-trip account changed'));
    }
    if (TransitCatalogue.demo) return Stream.value(null);
    if (activeReader != null) return activeReader!(passengerId);
    final history = AcknowledgedJourneyHistory(passengerId);
    try {
      return _activeQuery(passengerId)
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) {
            _owner(passengerId);
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

  Query<Map<String, dynamic>> _activeQuery(String owner) => _journeysCollection
      .where('passengerId', isEqualTo: owner)
      .where('status', whereIn: ['confirmed', 'active'])
      .orderBy('createdAt', descending: true)
      .orderBy(FieldPath.documentId, descending: true)
      .limit(1);
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
