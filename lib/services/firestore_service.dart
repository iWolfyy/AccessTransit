import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_constants.dart';
import '../models/bus.dart';
import '../models/report.dart';
import '../models/station.dart';

/// Repository service for accessing stations, static bus routes, and reports in Firestore.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore get _db => _customFirestore ?? FirebaseFirestore.instance;

  /// Collection reference for `stations`.
  CollectionReference<Map<String, dynamic>> get _stationsRef =>
      _db.collection(FirestoreConstants.stationsCollection);

  /// Collection reference for `buses`.
  CollectionReference<Map<String, dynamic>> get _busesRef =>
      _db.collection(FirestoreConstants.staticBusesCollection);

  /// Collection reference for `reports`.
  CollectionReference<Map<String, dynamic>> get _reportsRef =>
      _db.collection(FirestoreConstants.reportsCollection);

  /// 1. Fetches a snapshot list of all transit stations (`stations`).
  Future<List<Station>> getStations() async {
    final snapshot = await _stationsRef.get();
    return snapshot.docs.map((doc) => Station.fromFirestore(doc)).toList();
  }

  /// Fetches a single station by its ID (`stations/{id}`).
  Future<Station?> getStationById(String stationId) async {
    final doc = await _stationsRef.doc(stationId).get();
    if (!doc.exists) return null;
    return Station.fromFirestore(doc);
  }

  /// 2. Fetches a snapshot list of all static bus routes (`buses`).
  Future<List<Bus>> getBuses() async {
    final snapshot = await _busesRef.get();
    return snapshot.docs.map((doc) => Bus.fromFirestore(doc)).toList();
  }

  /// Fetches a single static bus route by its ID (`buses/{id}`).
  Future<Bus?> getBusById(String busId) async {
    final doc = await _busesRef.doc(busId).get();
    if (!doc.exists) return null;
    return Bus.fromFirestore(doc);
  }

  /// 3. Returns a real-time stream of accessibility reports (`reports`).
  ///
  /// Excludes reports with status 'hidden'.
  /// Optionally filters by [status] (e.g. "active" or "resolved") and [userId].
  Stream<List<Report>> streamReports({String? status, String? userId}) {
    Query<Map<String, dynamic>> query = _reportsRef;
    if (status != null && status.isNotEmpty) {
      query = query.where(FirestoreConstants.fieldStatus, isEqualTo: status);
    }
    if (userId != null && userId.isNotEmpty) {
      query = query.where(FirestoreConstants.fieldUserId, isEqualTo: userId);
    }
    return query.snapshots().map((snapshot) {
      final reports = snapshot.docs
          .map((doc) => Report.fromFirestore(doc))
          .where((r) => r.status.toLowerCase() != 'hidden')
          .toList();
      // Sort newest first by createdAt
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports;
    });
  }

  /// Submits a new condition report to Firestore (`reports/{id}`).
  Future<void> createReport(Report report) async {
    final docRef = report.id.isNotEmpty
        ? _reportsRef.doc(report.id)
        : _reportsRef.doc();
    final data = report.toMap(isServerTimestamp: true);
    await docRef.set(data);
  }

  /// Checks if a user has created a report for the same target in the last [thresholdMinutes] (AC-77).
  Future<bool> checkRateLimit(
    String userId,
    String targetId, {
    int thresholdMinutes = 15,
  }) async {
    if (userId.isEmpty || targetId.isEmpty) return false;
    final cutoff = DateTime.now().subtract(Duration(minutes: thresholdMinutes));
    final snapshot = await _reportsRef
        .where(FirestoreConstants.fieldUserId, isEqualTo: userId)
        .where(FirestoreConstants.fieldTargetId, isEqualTo: targetId)
        .get();

    for (final doc in snapshot.docs) {
      final report = Report.fromFirestore(doc);
      if (report.createdAt.isAfter(cutoff)) {
        return true;
      }
    }
    return false;
  }

  /// Confirms a report as "Still broken" (AC-79).
  ///
  /// Uses a Firestore transaction to atomically add [userId] to `confirmedBy`,
  /// increment `confirmCount`, and reset `lastConfirmedAt` to current timestamp.
  Future<void> confirmReport(String reportId, String userId) async {
    await _db.runTransaction((transaction) async {
      final docRef = _reportsRef.doc(reportId);
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception('Report not found.');
      }
      final report = Report.fromFirestore(snapshot);

      if (report.confirmedBy.contains(userId)) {
        throw Exception('You already confirmed this report.');
      }

      final updatedConfirmedBy = [...report.confirmedBy, userId];
      transaction.update(docRef, {
        FirestoreConstants.fieldConfirmedBy: updatedConfirmedBy,
        FirestoreConstants.fieldConfirmCount: FieldValue.increment(1),
        FirestoreConstants.fieldLastConfirmedAt: FieldValue.serverTimestamp(),
      });
    });
  }

  /// Marks a report as resolved / "Fixed now" (AC-80).
  Future<void> resolveReport(String reportId) async {
    final docRef = _reportsRef.doc(reportId);
    await docRef.update({
      FirestoreConstants.fieldStatus: 'resolved',
    });
  }

  /// Flags a report as false (AC-83).
  ///
  /// Uses a Firestore transaction to atomically add [userId] to `flaggedBy` and increment `falseCount`.
  /// If `falseCount` reaches 3, sets status to 'hidden'.
  Future<void> flagReport(String reportId, String userId) async {
    await _db.runTransaction((transaction) async {
      final docRef = _reportsRef.doc(reportId);
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception('Report not found.');
      }
      final report = Report.fromFirestore(snapshot);

      if (report.flaggedBy.contains(userId)) {
        throw Exception('You already flagged this report.');
      }

      final updatedFlaggedBy = [...report.flaggedBy, userId];
      final newFalseCount = report.falseCount + 1;
      final Map<String, dynamic> updates = {
        FirestoreConstants.fieldFlaggedBy: updatedFlaggedBy,
        FirestoreConstants.fieldFalseCount: newFalseCount,
      };

      if (newFalseCount >= 3) {
        updates[FirestoreConstants.fieldStatus] = 'hidden';
      }

      transaction.update(docRef, updates);
    });
  }
}

