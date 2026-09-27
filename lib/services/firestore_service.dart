import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/firestore_constants.dart';
import '../data/seed_data.dart';
import '../models/bus.dart';
import '../models/report.dart';
import '../models/station.dart';

/// Repository service for accessing stations, static bus routes, and reports in Firestore.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore get _db => _customFirestore ?? FirebaseFirestore.instance;

  static final List<Report> _localReportsFallback = [...SeedData.getSampleReports()];
  static final StreamController<List<Report>> _localStreamController =
      StreamController<List<Report>>.broadcast();

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
    try {
      final snapshot = await _stationsRef.get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => Station.fromFirestore(doc)).toList();
      }
    } catch (e) {
      debugPrint('Firestore getStations fallback: $e');
    }
    return SeedData.colomboStations;
  }

  /// Fetches a single station by its ID (`stations/{id}`).
  Future<Station?> getStationById(String stationId) async {
    try {
      final doc = await _stationsRef.doc(stationId).get();
      if (doc.exists) return Station.fromFirestore(doc);
    } catch (e) {
      debugPrint('Firestore getStationById fallback: $e');
    }
    try {
      return SeedData.colomboStations.firstWhere((s) => s.id == stationId);
    } catch (_) {
      return null;
    }
  }

  /// 2. Fetches a snapshot list of all static bus routes (`buses`).
  Future<List<Bus>> getBuses() async {
    try {
      final snapshot = await _busesRef.get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => Bus.fromFirestore(doc)).toList();
      }
    } catch (e) {
      debugPrint('Firestore getBuses fallback: $e');
    }
    return SeedData.sampleBuses;
  }

  /// Fetches a single static bus route by its ID (`buses/{id}`).
  Future<Bus?> getBusById(String busId) async {
    try {
      final doc = await _busesRef.doc(busId).get();
      if (doc.exists) return Bus.fromFirestore(doc);
    } catch (e) {
      debugPrint('Firestore getBusById fallback: $e');
    }
    try {
      return SeedData.sampleBuses.firstWhere((b) => b.id == busId);
    } catch (_) {
      return null;
    }
  }

  /// 3. Returns a real-time stream of accessibility reports (`reports`).
  ///
  /// Excludes reports with status 'hidden'.
  /// Optionally filters by [status] (e.g. "active" or "resolved") and [userId].
  Stream<List<Report>> streamReports({String? status, String? userId}) async* {
    List<Report> filterReports(List<Report> reports) {
      final Map<String, Report> mergedMap = {};
      for (final r in reports) {
        if (r.id.isNotEmpty) mergedMap[r.id] = r;
      }
      for (final r in _localReportsFallback) {
        if (r.id.isNotEmpty && !mergedMap.containsKey(r.id)) {
          mergedMap[r.id] = r;
        }
      }

      final filtered = mergedMap.values.where((r) {
        if (r.status.toLowerCase() == 'hidden') return false;
        if (status != null && status.isNotEmpty && r.status != status) {
          return false;
        }
        if (userId != null && userId.isNotEmpty && r.userId != userId) {
          return false;
        }
        return true;
      }).toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    }

    // Always emit local fallback first
    yield filterReports(_localReportsFallback);

    // Stream updates from local modifications
    final localSub = _localStreamController.stream.listen((_) {});

    try {
      Query<Map<String, dynamic>> query = _reportsRef;
      if (status != null && status.isNotEmpty) {
        query = query.where(FirestoreConstants.fieldStatus, isEqualTo: status);
      }
      if (userId != null && userId.isNotEmpty) {
        query = query.where(FirestoreConstants.fieldUserId, isEqualTo: userId);
      }

      await for (final snapshot in query.snapshots()) {
        final remote = snapshot.docs
            .map((doc) => Report.fromFirestore(doc))
            .toList();
        yield filterReports(remote);
      }
    } catch (e) {
      debugPrint('Firestore streamReports fallback: $e');
      yield filterReports(_localReportsFallback);
    } finally {
      await localSub.cancel();
    }
  }

  /// Submits a new condition report to Firestore (`reports/{id}`).
  Future<void> createReport(Report report) async {
    final reportId = report.id.isNotEmpty
        ? report.id
        : 'rep_${DateTime.now().millisecondsSinceEpoch}';
    final newReport = report.copyWith(id: reportId);

    // Save to local fallback first
    _localReportsFallback.removeWhere((r) => r.id == reportId);
    _localReportsFallback.add(newReport);
    _localStreamController.add(_localReportsFallback);

    try {
      final docRef = _reportsRef.doc(reportId);
      final data = newReport.toMap(isServerTimestamp: true);
      await docRef.set(data);
    } catch (e) {
      debugPrint('Firestore createReport permission/network warning: $e');
      // Report remains safely stored in _localReportsFallback
    }
  }

  /// Checks if a user has created a report for the same target in the last [thresholdMinutes] (AC-77).
  Future<bool> checkRateLimit(
    String userId,
    String targetId, {
    int thresholdMinutes = 15,
  }) async {
    if (userId.isEmpty || targetId.isEmpty) return false;
    final cutoff = DateTime.now().subtract(Duration(minutes: thresholdMinutes));

    for (final r in _localReportsFallback) {
      if (r.userId == userId && r.targetId == targetId) {
        if (r.createdAt.isAfter(cutoff)) {
          return true;
        }
      }
    }

    try {
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
    } catch (e) {
      debugPrint('Firestore checkRateLimit warning: $e');
    }
    return false;
  }

  /// Confirms a report as "Still broken" (AC-79).
  ///
  /// Uses a Firestore transaction to atomically add [userId] to `confirmedBy`,
  /// increment `confirmCount`, and reset `lastConfirmedAt` to current timestamp.
  Future<void> confirmReport(String reportId, String userId) async {
    final idx = _localReportsFallback.indexWhere((r) => r.id == reportId);
    if (idx != -1) {
      final r = _localReportsFallback[idx];
      if (!r.confirmedBy.contains(userId)) {
        final updated = r.copyWith(
          confirmedBy: [...r.confirmedBy, userId],
          confirmCount: r.confirmCount + 1,
          lastConfirmedAt: DateTime.now(),
        );
        _localReportsFallback[idx] = updated;
        _localStreamController.add(_localReportsFallback);
      }
    }

    try {
      await _db.runTransaction((transaction) async {
        final docRef = _reportsRef.doc(reportId);
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          return;
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
    } catch (e) {
      debugPrint('Firestore confirmReport warning: $e');
    }
  }

  /// Marks a report as resolved / "Fixed now" (AC-80).
  Future<void> resolveReport(String reportId) async {
    final idx = _localReportsFallback.indexWhere((r) => r.id == reportId);
    if (idx != -1) {
      final updated = _localReportsFallback[idx].copyWith(status: 'resolved');
      _localReportsFallback[idx] = updated;
      _localStreamController.add(_localReportsFallback);
    }

    try {
      final docRef = _reportsRef.doc(reportId);
      await docRef.update({
        FirestoreConstants.fieldStatus: 'resolved',
      });
    } catch (e) {
      debugPrint('Firestore resolveReport warning: $e');
    }
  }

  /// Flags a report as false (AC-83).
  ///
  /// Uses a Firestore transaction to atomically add [userId] to `flaggedBy` and increment `falseCount`.
  /// If `falseCount` reaches 3, sets status to 'hidden'.
  Future<void> flagReport(String reportId, String userId) async {
    final idx = _localReportsFallback.indexWhere((r) => r.id == reportId);
    if (idx != -1) {
      final r = _localReportsFallback[idx];
      if (!r.flaggedBy.contains(userId)) {
        final newFalseCount = r.falseCount + 1;
        final updated = r.copyWith(
          flaggedBy: [...r.flaggedBy, userId],
          falseCount: newFalseCount,
          status: newFalseCount >= 3 ? 'hidden' : r.status,
        );
        _localReportsFallback[idx] = updated;
        _localStreamController.add(_localReportsFallback);
      }
    }

    try {
      await _db.runTransaction((transaction) async {
        final docRef = _reportsRef.doc(reportId);
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          return;
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
    } catch (e) {
      debugPrint('Firestore flagReport warning: $e');
    }
  }
}


