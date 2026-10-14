import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../constants/firestore_constants.dart';
import '../logic/report_mutation.dart';
import '../data/seed_data.dart';
import '../models/boarding_request.dart';
import '../models/bus.dart';
import '../models/bus_route.dart';
import '../models/report.dart';
import '../models/enums/report_publication_state.dart';
import '../models/station.dart';

/// Repository service for accessing stations, static bus routes, and reports in Firestore.
class FirestoreService {
  FirestoreService({
    FirebaseFirestore? firestore,
    this.reportWriter,
    this.busWriter,
    this.reportMutationWriter,
    this.reportActorId,
    this.boardingWriter,
    this.boardingStatusWriter,
    this.boardingViewerId,
  }) : _customFirestore = firestore;
  final Future<void> Function(String, Map<String, dynamic>)? busWriter;
  final Future<void> Function(Report)? reportWriter;
  final Future<ReportMutationResult> Function(ReportMutationPlan)?
  reportMutationWriter;
  final String? Function()? reportActorId;
  String? get currentReportActorId {
    if (reportActorId != null) return reportActorId!();
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  final Future<BoardingRequest> Function(BoardingRequest)? boardingWriter;
  final Future<BoardingRequest> Function(BoardingRequest, String)?
  boardingStatusWriter;
  final String? Function()? boardingViewerId;

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore get _db => _customFirestore ?? FirebaseFirestore.instance;

  static final List<Report> _localReportsFallback = [];
  static final StreamController<List<Report>> _localStreamController =
      StreamController<List<Report>>.broadcast();

  static final List<BusRoute> _localRoutesFallback = [...SeedData.sampleRoutes];

  static final List<Bus> _localBusesFallback = [...SeedData.sampleBuses];
  static final StreamController<List<Bus>> _localBusesStreamController =
      StreamController<List<Bus>>.broadcast();

  static final List<BoardingRequest> _localRequestsFallback = [];
  static String? _localRequestsViewer;
  static final StreamController<List<BoardingRequest>>
  _localRequestsStreamController =
      StreamController<List<BoardingRequest>>.broadcast();

  /// Collection reference for `stations`.
  CollectionReference<Map<String, dynamic>> get _stationsRef =>
      _db.collection(FirestoreConstants.stationsCollection);

  /// Collection reference for `routes`.
  CollectionReference<Map<String, dynamic>> get _routesRef =>
      _db.collection(FirestoreConstants.routesCollection);

  /// Collection reference for `buses`.
  CollectionReference<Map<String, dynamic>> get _busesRef =>
      _db.collection(FirestoreConstants.staticBusesCollection);

  /// Collection reference for `reports`.
  CollectionReference<Map<String, dynamic>> get _reportsRef =>
      _db.collection(FirestoreConstants.reportsCollection);

  /// Collection reference for `boarding_requests`.
  CollectionReference<Map<String, dynamic>> get _boardingRequestsRef =>
      _db.collection(FirestoreConstants.boardingRequestsCollection);

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

  // ==========================================
  // Routes APIs (`routes` collection)
  // ==========================================

  /// Fetches a snapshot list of all bus routes (`routes`).
  Future<List<BusRoute>> getRoutes() async {
    try {
      final snapshot = await _routesRef.get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => BusRoute.fromFirestore(doc)).toList();
      }
    } catch (e) {
      debugPrint('Firestore getRoutes fallback: $e');
    }
    return _localRoutesFallback;
  }

  /// Fetches a single bus route by its ID (`routes/{id}`).
  Future<BusRoute?> getRouteById(String routeId) async {
    try {
      final doc = await _routesRef.doc(routeId).get();
      if (doc.exists) return BusRoute.fromFirestore(doc);
    } catch (e) {
      debugPrint('Firestore getRouteById fallback: $e');
    }
    try {
      return _localRoutesFallback.firstWhere((r) => r.id == routeId);
    } catch (_) {
      return null;
    }
  }

  /// Finds all bus routes that connect [fromStopId] to [toStopId] in valid directional order.
  Future<List<BusRoute>> findRoutesConnectingStops(
    String fromStopId,
    String toStopId,
  ) async {
    final allRoutes = await getRoutes();
    return allRoutes
        .where((route) => route.isValidDirection(fromStopId, toStopId))
        .toList();
  }

  // ==========================================
  // Buses APIs (`buses` collection)
  // ==========================================

  void _cacheAcknowledgedBus(Bus bus) {
    final index = _localBusesFallback.indexWhere((b) => b.id == bus.id);
    if (index == -1) {
      _localBusesFallback.add(bus);
    } else {
      _localBusesFallback[index] = bus;
    }
    _localBusesStreamController.add(List.unmodifiable(_localBusesFallback));
  }

  /// 2. Fetches a snapshot list of all static bus vehicles (`buses`).
  Future<List<Bus>> getBuses() async {
    try {
      final snapshot = await _busesRef.get();
      if (!snapshot.metadata.hasPendingWrites && snapshot.docs.isNotEmpty) {
        final buses = snapshot.docs
            .map((doc) => Bus.fromFirestore(doc))
            .toList();
        for (final bus in buses) {
          _cacheAcknowledgedBus(bus);
        }
        return buses;
      }
    } catch (e) {
      debugPrint('Firestore getBuses fallback: $e');
    }
    return _localBusesFallback;
  }

  /// Fetches all buses assigned to a specific [routeId] or [routeNo].
  Future<List<Bus>> getBusesForRoute(String routeIdOrNo) async {
    try {
      final snapshot = await _busesRef
          .where('routeId', isEqualTo: routeIdOrNo)
          .get();
      if (!snapshot.metadata.hasPendingWrites && snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => Bus.fromFirestore(doc)).toList();
      }
      final snapshotByNo = await _busesRef
          .where(FirestoreConstants.fieldRouteNo, isEqualTo: routeIdOrNo)
          .get();
      if (!snapshotByNo.metadata.hasPendingWrites &&
          snapshotByNo.docs.isNotEmpty) {
        return snapshotByNo.docs.map((doc) => Bus.fromFirestore(doc)).toList();
      }
    } catch (e) {
      debugPrint('Firestore getBusesForRoute fallback: $e');
    }
    return _localBusesFallback
        .where((b) => b.routeId == routeIdOrNo || b.routeNo == routeIdOrNo)
        .toList();
  }

  /// Fetches a single static bus vehicle by its ID (`buses/{id}`).
  Future<Bus?> getBusById(String busId) async {
    try {
      final doc = await _busesRef.doc(busId).get();
      if (!doc.metadata.hasPendingWrites && doc.exists) {
        final bus = Bus.fromFirestore(doc);
        _cacheAcknowledgedBus(bus);
        return bus;
      }
    } catch (e) {
      debugPrint('Firestore getBusById fallback: $e');
    }
    try {
      return _localBusesFallback.firstWhere((b) => b.id == busId);
    } catch (_) {
      return null;
    }
  }

  /// 3. Returns a real-time stream of accessibility reports (`reports`).
  ///
  /// Excludes reports with status 'hidden'.
  /// Optionally filters by [status] (e.g. "active" or "resolved") and [userId].
  Stream<List<Report>> streamReports({
    String? status,
    String? userId,
    bool surfaceErrors = false,
  }) {
    bool matches(Report r) =>
        (status == null || status.isEmpty || r.status == status) &&
        (userId == null || userId.isEmpty || r.userId == userId);
    List<Report> cached() =>
        _localReportsFallback
            .where(
              (r) =>
                  matches(r) &&
                  r.isPublic &&
                  r.status != 'hidden' &&
                  r.falseCount < 3 &&
                  r.flaggedBy.length < 3,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    late StreamController<List<Report>> controller;
    StreamSubscription? local;
    StreamSubscription? remote;
    void readError(Object error, StackTrace stack) {
      if (controller.isClosed) return;
      if (surfaceErrors) {
        controller.addError(error, stack);
        unawaited(controller.close());
      } else {
        debugPrint('Firestore streamReports fallback: $error');
      }
    }

    controller = StreamController<List<Report>>(
      onListen: () {
        controller.add(cached());
        local = _localStreamController.stream.listen((_) {
          if (!controller.isClosed) controller.add(cached());
        });
        try {
          Query<Map<String, dynamic>> query = _reportsRef;
          if (status != null && status.isNotEmpty) {
            query = query.where('status', isEqualTo: status);
          }
          if (userId != null && userId.isNotEmpty) {
            query = query.where('userId', isEqualTo: userId);
          }
          remote = query.snapshots(includeMetadataChanges: true).listen((
            snapshot,
          ) {
            final shared = snapshot.docs
                .where((d) => !d.metadata.hasPendingWrites)
                .map(Report.fromFirestore)
                .toList();
            if (!snapshot.metadata.isFromCache &&
                !snapshot.metadata.hasPendingWrites) {
              final ids = shared.map((r) => r.id).toSet();
              _localReportsFallback.removeWhere(
                (r) => matches(r) && !ids.contains(r.id),
              );
            }
            for (final report in shared) {
              if (!snapshot.metadata.isFromCache ||
                  !_localReportsFallback.any((r) => r.id == report.id)) {
                _localReportsFallback.removeWhere((r) => r.id == report.id);
                _localReportsFallback.add(report);
              }
            }
            _localStreamController.add(
              List.unmodifiable(_localReportsFallback),
            );
          }, onError: readError);
        } catch (error, stack) {
          readError(error, stack);
        }
      },
      onCancel: () async {
        await local?.cancel();
        await remote?.cancel();
      },
    );
    return controller.stream;
  }

  /// Server deletion and hidden/resolved records cannot fall back to stale input.
  Stream<Report?> streamReportById(
    String reportId, {
    bool surfaceErrors = false,
  }) {
    Report? cached() {
      for (final r in _localReportsFallback) {
        if (r.id == reportId && r.isPublic) return r;
      }
      return null;
    }

    late StreamController<Report?> controller;
    StreamSubscription? local;
    StreamSubscription? remote;
    void readError(Object error, StackTrace stack) {
      if (controller.isClosed) return;
      if (surfaceErrors) {
        controller.addError(error, stack);
        unawaited(controller.close());
      } else {
        debugPrint('Firestore streamReportById fallback: $error');
      }
    }

    controller = StreamController<Report?>(
      onListen: () {
        controller.add(cached());
        local = _localStreamController.stream.listen((_) {
          if (!controller.isClosed) controller.add(cached());
        });
        try {
          remote = _reportsRef
              .doc(reportId)
              .snapshots(includeMetadataChanges: true)
              .listen((snapshot) {
                if (snapshot.metadata.hasPendingWrites) return;
                if (snapshot.exists) {
                  if (!snapshot.metadata.isFromCache || cached() == null) {
                    _cacheReport(Report.fromFirestore(snapshot));
                  }
                } else if (!snapshot.metadata.isFromCache) {
                  _localReportsFallback.removeWhere((r) => r.id == reportId);
                  _localStreamController.add(
                    List.unmodifiable(_localReportsFallback),
                  );
                }
              }, onError: readError);
        } catch (error, stack) {
          readError(error, stack);
        }
      },
      onCancel: () async {
        await local?.cancel();
        await remote?.cancel();
      },
    );
    return controller.stream;
  }

  /// Submits a new condition report to Firestore (`reports/{id}`).
  Future<void> createReport(Report report) async {
    final reportId = report.id.isNotEmpty
        ? report.id
        : 'rep_${DateTime.now().millisecondsSinceEpoch}';
    final newReport = report.copyWith(
      id: reportId,
      publicationState: ReportPublicationState.published,
    );
    if (newReport.photoUrl.isNotEmpty &&
        !newReport.photoUrl.startsWith('https://')) {
      throw ArgumentError('Report photos must use a shared HTTPS URL.');
    }
    Report saved = newReport;
    if (reportWriter != null) {
      await reportWriter!(newReport);
    } else {
      saved = await _db.runTransaction<Report>((transaction) async {
        final ref = _reportsRef.doc(reportId);
        final existing = await transaction.get(ref);
        if (existing.exists) {
          final current = Report.fromFirestore(existing);
          if (current.userId != newReport.userId ||
              current.targetType != newReport.targetType ||
              current.targetId != newReport.targetId ||
              current.problemType != newReport.problemType) {
            throw StateError('This report ID belongs to a different report.');
          }
          return current;
        }
        transaction.set(ref, newReport.toMap(isServerTimestamp: true));
        return newReport;
      }, timeout: const Duration(seconds: 10));
    }

    _cacheReport(saved);
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

  void _cacheReport(Report report) {
    _localReportsFallback.removeWhere((r) => r.id == report.id);
    _localReportsFallback.add(report);
    _localStreamController.add(List.unmodifiable(_localReportsFallback));
  }

  Future<ReportMutationResult> confirmReport(String reportId, String userId) =>
      _mutateReport(reportId, userId, ReportMutationAction.confirm);
  Future<ReportMutationResult> flagReport(String reportId, String userId) =>
      _mutateReport(reportId, userId, ReportMutationAction.flag);
  Future<ReportMutationResult> resolveReport(String reportId) => _mutateReport(
    reportId,
    currentReportActorId ?? '',
    ReportMutationAction.resolve,
  );

  Future<ReportMutationResult> _mutateReport(
    String reportId,
    String actorId,
    ReportMutationAction action,
  ) async {
    if (actorId.isEmpty || actorId != currentReportActorId) {
      throw StateError('Sign in before changing a shared report.');
    }
    final ReportMutationResult result;
    if (reportMutationWriter != null) {
      final existing = _localReportsFallback.firstWhere(
        (r) => r.id == reportId,
        orElse: () => throw StateError(
          'Published report not available. Refresh and retry.',
        ),
      );
      final plan = ReportMutationPlan.apply(
        existing,
        actorId,
        action,
        DateTime.now(),
      );
      result = plan.changed
          ? await reportMutationWriter!(plan)
          : ReportMutationResult(
              action: action,
              changed: false,
              report: existing,
            );
    } else {
      final ref = _reportsRef.doc(reportId);
      final plan = await _db.runTransaction<ReportMutationPlan>(
        (transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) {
            throw StateError('This report is no longer available.');
          }
          if (snapshot.data()?['createdAt'] is! Timestamp) {
            throw StateError(
              'Observation time is unknown. Refresh this report.',
            );
          }
          final existing = Report.fromFirestore(snapshot);
          final plan = ReportMutationPlan.apply(
            existing,
            actorId,
            action,
            DateTime.now(),
          );
          if (!plan.changed) return plan;
          if (action == ReportMutationAction.resolve) {
            transaction.update(ref, {
              'status': 'resolved',
              'resolvedBy': actorId,
              'resolvedAt': FieldValue.serverTimestamp(),
            });
            transaction.set(
              _db.collection('report_resolutions').doc(reportId),
              {
                'reportId': reportId,
                'resolvedBy': actorId,
                'resolvedAt': FieldValue.serverTimestamp(),
                'targetType': existing.targetType,
                'targetId': existing.targetId,
                'problemType': existing.problemType,
                'category': existing.category,
                'previousStatus': 'active',
                'status': 'resolved',
              },
            );
          } else {
            final update = <String, dynamic>{
              'confirmedBy': action == ReportMutationAction.confirm
                  ? FieldValue.arrayUnion([actorId])
                  : FieldValue.arrayRemove([actorId]),
              'flaggedBy': action == ReportMutationAction.flag
                  ? FieldValue.arrayUnion([actorId])
                  : FieldValue.arrayRemove([actorId]),
            };
            if (action == ReportMutationAction.confirm) {
              update['confirmCount'] = FieldValue.increment(1);
              if (existing.flaggedBy.contains(actorId)) {
                update['falseCount'] = FieldValue.increment(-1);
              }
              update['lastConfirmedAt'] = FieldValue.serverTimestamp();
            } else {
              update['falseCount'] = FieldValue.increment(1);
              if (existing.confirmedBy.contains(actorId)) {
                update['confirmCount'] = FieldValue.increment(-1);
                update['lastConfirmedAt'] = null;
              }
            }
            if (plan.after.status != existing.status) {
              update['status'] = plan.after.status;
            }
            transaction.update(ref, update);
          }
          return plan;
        },
        timeout: const Duration(seconds: 10),
        maxAttempts: 5,
      );
      if (!plan.changed) {
        result = ReportMutationResult(
          action: action,
          changed: false,
          report: plan.before,
        );
      } else {
        Report? acknowledged;
        try {
          final shared = await ref
              .get(const GetOptions(source: Source.server))
              .timeout(const Duration(seconds: 3));
          if (shared.exists) acknowledged = Report.fromFirestore(shared);
        } catch (_) {
          // The transaction is saved; do not fabricate exact server check times.
        }
        result = ReportMutationResult(
          action: action,
          changed: true,
          report: acknowledged,
        );
      }
    }
    if (result.action != action ||
        result.report != null && result.report!.id != reportId) {
      throw StateError('The shared response did not match this report action.');
    }
    if (result.report != null) _cacheReport(result.report!);
    return result;
  }

  // --- Sprint 3: Driver Side Bus Streams & Controls (AC-84, AC-85) ---

  /// Returns a real-time stream of all static buses (`buses`).
  Stream<List<Bus>> streamBuses() => _watchBuses(null).map((buses) => buses);

  Stream<Bus?> streamBusById(String busId) => _watchBuses(busId).map((buses) {
    for (final bus in buses) {
      if (bus.id == busId) return bus;
    }
    return null;
  });

  Stream<List<Bus>> _watchBuses(String? busId) {
    late StreamController<List<Bus>> controller;
    StreamSubscription? remote;
    StreamSubscription? local;
    List<Bus> current() => List.unmodifiable(
      busId == null
          ? _localBusesFallback
          : _localBusesFallback.where((b) => b.id == busId),
    );
    void cache(Bus bus) {
      final index = _localBusesFallback.indexWhere((b) => b.id == bus.id);
      if (index == -1) {
        _localBusesFallback.add(bus);
      } else {
        _localBusesFallback[index] = bus;
      }
    }

    controller = StreamController<List<Bus>>(
      onListen: () {
        controller.add(current());
        local = _localBusesStreamController.stream.listen(
          (_) => controller.add(current()),
        );
        try {
          if (busId == null) {
            remote = _busesRef
                .snapshots(includeMetadataChanges: true)
                .listen(
                  (snapshot) {
                    if (snapshot.metadata.hasPendingWrites) return;
                    for (final doc in snapshot.docs) {
                      cache(Bus.fromFirestore(doc));
                    }
                    controller.add(current());
                  },
                  onError: (Object e) {
                    debugPrint('Bus catalogue read failed: $e');
                  },
                );
          } else {
            remote = _busesRef
                .doc(busId)
                .snapshots(includeMetadataChanges: true)
                .listen(
                  (snapshot) {
                    if (snapshot.metadata.hasPendingWrites) return;
                    if (snapshot.exists) {
                      cache(Bus.fromFirestore(snapshot));
                    } else if (!snapshot.metadata.isFromCache) {
                      _localBusesFallback.removeWhere((b) => b.id == busId);
                    }
                    controller.add(current());
                  },
                  onError: (Object e) {
                    debugPrint('Bus read failed: $e');
                  },
                );
          }
        } catch (e) {
          debugPrint('Bus catalogue unavailable: $e');
        }
      },
      onCancel: () async {
        await local?.cancel();
        await remote?.cancel();
      },
    );
    return controller.stream;
  }

  /// Updates ramp operational status and/or occupancy on a bus document (`buses/{busId}`) (AC-84).
  Future<void> updateBusAccessibility(
    String busId, {
    bool? rampOk,
    String? occupancy,
    String? driverId,
  }) async {
    final updates = <String, dynamic>{
      'rampOk': ?rampOk,
      if (occupancy != null) 'occupancy': occupancy.toLowerCase(),
      'driverId': ?driverId,
    };
    if (updates.isEmpty) return;
    if (busWriter != null) {
      await busWriter!(busId, updates);
    } else {
      await _busesRef
          .doc(busId)
          .update(updates)
          .timeout(const Duration(seconds: 12));
    }
    final idx = _localBusesFallback.indexWhere((b) => b.id == busId);
    if (idx != -1) {
      final current = _localBusesFallback[idx];
      _localBusesFallback[idx] = current.copyWith(
        rampOk: rampOk,
        occupancy: occupancy?.toLowerCase(),
        driverId: driverId,
      );
      _localBusesStreamController.add(List.unmodifiable(_localBusesFallback));
    }
  }

  /// Assigns a driver to a bus document (`buses/{busId}`) (AC-84).
  Future<void> assignBusDriver(String busId, String driverId) async {
    await updateBusAccessibility(busId, driverId: driverId);
  }

  /// Adds a new [Station] to Firestore (`stations/{id}`) and inserts its ID
  /// into an existing [Bus] route's ordered `stops` list at [insertIndex].
  Future<void> addStationAndInsertIntoBusRoute({
    required Station newStation,
    required String busId,
    required int insertIndex,
  }) async {
    final updated = await _db
        .runTransaction<Bus>((tx) async {
          final ref = _busesRef.doc(busId);
          final snapshot = await tx.get(ref);
          if (!snapshot.exists) throw StateError('Bus unavailable');
          final bus = Bus.fromFirestore(snapshot);
          final stops = List<String>.from(bus.stops);
          if (!stops.contains(newStation.id)) {
            if (insertIndex < 0 || insertIndex > stops.length) {
              throw RangeError.range(insertIndex, 0, stops.length);
            }
            stops.insert(insertIndex, newStation.id);
          }
          tx.set(
            _stationsRef.doc(newStation.id),
            newStation.toMap(),
            SetOptions(merge: true),
          );
          tx.update(ref, {'stops': stops});
          return bus.copyWith(stops: stops);
        })
        .timeout(const Duration(seconds: 12));
    final idx = _localBusesFallback.indexWhere((b) => b.id == busId);
    if (idx != -1) _localBusesFallback[idx] = updated;
    _localBusesStreamController.add(List.unmodifiable(_localBusesFallback));
  }

  // --- Acknowledged assistance persistence ---
  String? get _boardingViewer {
    if (boardingViewerId != null) return boardingViewerId!();
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  void _scopeBoardingCache() {
    final viewer = _boardingViewer;
    if (_localRequestsViewer != viewer) {
      _localRequestsViewer = viewer;
      _localRequestsFallback.clear();
      _localRequestsStreamController.add([]);
    }
  }

  void _cacheBoardingRequest(BoardingRequest request) {
    _scopeBoardingCache();
    _localRequestsFallback.removeWhere((r) => r.id == request.id);
    _localRequestsFallback.add(request);
    _localRequestsStreamController.add(
      List.unmodifiable(_localRequestsFallback),
    );
  }

  Future<void> createBoardingRequest(BoardingRequest request) async {
    await publishBoardingRequest(request);
  }

  /// Server transaction acknowledgement precedes every shared cache update.
  /// Retry reads an existing document and preserves the driver's response.
  Future<BoardingRequest> publishBoardingRequest(
    BoardingRequest request,
  ) async {
    final viewer = _boardingViewer;
    if (request.id.isEmpty || request.riderId.isEmpty) {
      throw ArgumentError('An assistance request needs a stable ID and rider.');
    }
    final BoardingRequest saved;
    if (boardingWriter != null) {
      saved = await boardingWriter!(request);
    } else {
      saved = await _db.runTransaction<BoardingRequest>(
        (transaction) async {
          final ref = _boardingRequestsRef.doc(request.id);
          final snapshot = await transaction.get(ref);
          if (snapshot.exists) {
            final existing = BoardingRequest.fromFirestore(snapshot);
            if (existing.riderId != request.riderId ||
                existing.busId != request.busId ||
                existing.stationId != request.stationId ||
                existing.purpose != request.purpose ||
                !listEquals(
                  existing.assistanceTypes,
                  request.assistanceTypes,
                )) {
              throw StateError(
                'This request ID already belongs to a different request.',
              );
            }
            return existing;
          }
          transaction.set(ref, request.toMap(isServerTimestamp: true));
          return request;
        },
        timeout: const Duration(seconds: 10),
        maxAttempts: 3,
      );
    }
    if (saved.id != request.id ||
        saved.riderId != request.riderId ||
        saved.busId != request.busId ||
        saved.stationId != request.stationId ||
        saved.purpose != request.purpose ||
        !listEquals(saved.assistanceTypes, request.assistanceTypes)) {
      throw StateError('The service returned a different assistance request.');
    }
    if (_boardingViewer == viewer) _cacheBoardingRequest(saved);
    return saved;
  }

  bool get _hasBoardingBackend {
    try {
      _db;
      return true;
    } catch (_) {
      return false;
    }
  }

  Stream<List<BoardingRequest>> _watchAcknowledgedRequests(
    String field,
    String value,
  ) {
    final viewer = _boardingViewer;
    bool matches(BoardingRequest r) =>
        field == 'busId' ? r.busId == value : r.riderId == value;
    List<BoardingRequest> cached() {
      _scopeBoardingCache();
      if (viewer != _boardingViewer) return [];
      return _localRequestsFallback.where(matches).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    late StreamController<List<BoardingRequest>> controller;
    StreamSubscription? localSub;
    StreamSubscription? remoteSub;
    StreamSubscription? authSub;
    controller = StreamController<List<BoardingRequest>>(
      onListen: () {
        controller.add(cached());
        localSub = _localRequestsStreamController.stream.listen(
          (_) => controller.add(cached()),
        );
        if (!_hasBoardingBackend) return;
        if (boardingViewerId == null) {
          authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
            controller.add(cached());
          });
        }
        remoteSub = _boardingRequestsRef
            .where(field, isEqualTo: value)
            .snapshots(includeMetadataChanges: true)
            .listen((snapshot) {
              if (viewer != _boardingViewer || snapshot.metadata.isFromCache) {
                return;
              }
              final acknowledged = snapshot.docs
                  .where((doc) => !doc.metadata.hasPendingWrites)
                  .map(BoardingRequest.fromFirestore)
                  .toList();
              if (!snapshot.metadata.isFromCache &&
                  !snapshot.metadata.hasPendingWrites) {
                final ids = acknowledged.map((r) => r.id).toSet();
                _localRequestsFallback.removeWhere(
                  (r) => matches(r) && !ids.contains(r.id),
                );
              }
              for (final r in acknowledged) {
                _localRequestsFallback.removeWhere((old) => old.id == r.id);
                _localRequestsFallback.add(r);
              }
              _localRequestsStreamController.add(
                List.unmodifiable(_localRequestsFallback),
              );
            }, onError: controller.addError);
      },
      onCancel: () async {
        await localSub?.cancel();
        await remoteSub?.cancel();
        await authSub?.cancel();
      },
    );
    return controller.stream;
  }

  Stream<List<BoardingRequest>> streamBoardingRequestsForBus(String busId) =>
      _watchAcknowledgedRequests('busId', busId);
  Stream<List<BoardingRequest>> streamBoardingRequestsForRider(
    String riderId,
  ) => _watchAcknowledgedRequests('riderId', riderId);

  Stream<BoardingRequest?> watchBoardingRequest(String id) {
    final viewer = _boardingViewer;
    BoardingRequest? cached() {
      _scopeBoardingCache();
      if (viewer != _boardingViewer) return null;
      for (final r in _localRequestsFallback) {
        if (r.id == id) return r;
      }
      return null;
    }

    late StreamController<BoardingRequest?> controller;
    StreamSubscription? localSub;
    StreamSubscription? remoteSub;
    StreamSubscription? authSub;
    controller = StreamController<BoardingRequest?>(
      onListen: () {
        controller.add(cached());
        localSub = _localRequestsStreamController.stream.listen(
          (_) => controller.add(cached()),
        );
        if (!_hasBoardingBackend) return;
        if (boardingViewerId == null) {
          authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
            controller.add(cached());
          });
        }
        remoteSub = _boardingRequestsRef
            .doc(id)
            .snapshots(includeMetadataChanges: true)
            .listen((snapshot) {
              if (viewer != _boardingViewer ||
                  snapshot.metadata.isFromCache ||
                  snapshot.metadata.hasPendingWrites) {
                return;
              }
              if (snapshot.exists) {
                _cacheBoardingRequest(BoardingRequest.fromFirestore(snapshot));
              } else if (!snapshot.metadata.isFromCache) {
                _localRequestsFallback.removeWhere((r) => r.id == id);
                _localRequestsStreamController.add(
                  List.unmodifiable(_localRequestsFallback),
                );
              }
            }, onError: controller.addError);
      },
      onCancel: () async {
        await localSub?.cancel();
        await remoteSub?.cancel();
        await authSub?.cancel();
      },
    );
    return controller.stream;
  }

  static bool _validAssistanceTransition(String old, String next) =>
      old == next ||
      old == 'pending' &&
          const ['acknowledged', 'rejected', 'cancelled'].contains(next) ||
      old == 'acknowledged' && const ['completed', 'cancelled'].contains(next);

  Future<BoardingRequest> updateBoardingRequestStatus(
    String requestId,
    String status,
  ) async {
    final viewer = _boardingViewer;
    _scopeBoardingCache();
    final BoardingRequest updated;
    if (boardingStatusWriter != null) {
      final existing = _localRequestsFallback.firstWhere(
        (r) => r.id == requestId,
      );
      if (!_validAssistanceTransition(existing.status, status)) {
        throw StateError('Invalid assistance status transition.');
      }
      updated = await boardingStatusWriter!(existing, status);
    } else {
      updated = await _db.runTransaction<BoardingRequest>(
        (transaction) async {
          final ref = _boardingRequestsRef.doc(requestId);
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) {
            throw StateError('This assistance request is no longer available.');
          }
          final existing = BoardingRequest.fromFirestore(snapshot);
          if (!_validAssistanceTransition(existing.status, status)) {
            throw StateError('Invalid assistance status transition.');
          }
          if (existing.status != status) {
            transaction.update(ref, {'status': status});
          }
          return existing.copyWith(status: status);
        },
        timeout: const Duration(seconds: 10),
        maxAttempts: 3,
      );
    }
    if (updated.id != requestId || updated.status != status) {
      throw StateError('The requested assistance update was not confirmed.');
    }
    if (_boardingViewer == viewer) _cacheBoardingRequest(updated);
    return updated;
  }
}
