import 'transit_catalogue.dart';
import 'sample_test_mode.dart';

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
    this.operatorActorId,
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
  final String? Function()? operatorActorId;

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore get _db => _customFirestore ?? FirebaseFirestore.instance;

  static final List<Report> _localReportsFallback = [];
  static final StreamController<List<Report>> _localStreamController =
      StreamController<List<Report>>.broadcast();

  static final List<Bus> _localBusesFallback = [];
  static final StreamController<List<Bus>> _localBusesStreamController =
      StreamController<List<Bus>>.broadcast();

  static final List<BoardingRequest> _localRequestsFallback = [];
  static String? _localRequestsViewer;
  static final StreamController<List<BoardingRequest>>
  _localRequestsStreamController =
      StreamController<List<BoardingRequest>>.broadcast();

  /// Refresh every collection represented by the shared catalogue notice.
  Future<void> refreshCatalogue() async {
    await Future.wait([getStations(), getRoutes(), getBuses()]);
  }

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

  static List<Station> get cachedStations => [
    for (final entry in TransitCatalogue.cached('stations').entries)
      Station.fromMap(entry.value, id: entry.key),
  ];

  @visibleForTesting
  static void installCatalogueFixtures() {
    // ignore: invalid_use_of_visible_for_testing_member
    TransitCatalogue.installFixtures({
      'buses': {
        for (final bus in SeedData.sampleBuses)
          bus.id: {...bus.toMap(), 'catalogueSource': 'operator_catalogue'},
      },
      'routes': {
        for (final route in SeedData.sampleRoutes)
          route.id: {...route.toMap(), 'catalogueSource': 'operator_catalogue'},
      },
      'stations': {
        for (final station in SeedData.colomboStations)
          station.id: {
            ...station.toMap(),
            'catalogueSource': 'operator_catalogue',
          },
      },
    });
    _syncBusCache();
  }

  static void _syncBusCache() {
    _localBusesFallback
      ..clear()
      ..addAll([
        for (final entry in TransitCatalogue.cached('buses').entries)
          Bus.fromMap(entry.value, id: entry.key),
      ]);
  }

  Future<List<Station>> getStations() async {
    await TransitCatalogue.read(
      'stations',
      () => _stationsRef.get(const GetOptions(source: Source.server)),
    );
    return cachedStations;
  }

  Future<Station?> getStationById(String id) async {
    final data = await TransitCatalogue.readDocument(
      'stations',
      id,
      () => _stationsRef.doc(id).get(const GetOptions(source: Source.server)),
    );
    return data == null ? null : Station.fromMap(data, id: id);
  }

  Future<List<BusRoute>> getRoutes() async {
    final records = await TransitCatalogue.read(
      'routes',
      () => _routesRef.get(const GetOptions(source: Source.server)),
    );
    return [
      for (final entry in records.entries)
        BusRoute.fromMap(entry.value, id: entry.key),
    ];
  }

  Future<BusRoute?> getRouteById(String id) async {
    final data = await TransitCatalogue.readDocument(
      'routes',
      id,
      () => _routesRef.doc(id).get(const GetOptions(source: Source.server)),
    );
    return data == null ? null : BusRoute.fromMap(data, id: id);
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
    unawaited(
      TransitCatalogue.accept('buses', {
        bus.id: {
          ...?TransitCatalogue.cached('buses')[bus.id],
          'rampCheckedAt': null,
          'rampCheckedBy': null,
          ...bus.toMap(),
        },
      }, replace: false),
    );
    _localBusesStreamController.add(List.unmodifiable(_localBusesFallback));
  }

  Future<List<Bus>> getBuses() async {
    await TransitCatalogue.read(
      'buses',
      () => _busesRef.get(const GetOptions(source: Source.server)),
    );
    _syncBusCache();
    return List.unmodifiable(_localBusesFallback);
  }

  Future<List<Bus>> getBusesForRoute(String routeIdOrNo) async =>
      (await getBuses())
          .where(
            (bus) => bus.routeId == routeIdOrNo || bus.routeNo == routeIdOrNo,
          )
          .toList();

  Future<Bus?> getBusById(String id) async {
    final data = await TransitCatalogue.readDocument(
      'buses',
      id,
      () => _busesRef.doc(id).get(const GetOptions(source: Source.server)),
    );
    _syncBusCache();
    return data == null ? null : Bus.fromMap(data, id: id);
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
    if (TransitCatalogue.demo) return Stream.value([]);
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
          ..sort(
            (a, b) => Report.compareDatesDescending(a.createdAt, b.createdAt),
          );
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
    TransitCatalogue.requireSharedWrites();
    if (report.createdAt == null) {
      throw StateError(
        'Observation time unknown. Create a new observation before publishing.',
      );
    }
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
        if ((r.createdAt?.isAfter(cutoff) ?? false)) {
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
        if ((report.createdAt?.isAfter(cutoff) ?? false)) {
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
  Future<ReportMutationResult> recheckReport(String reportId, String userId) =>
      _mutateReport(reportId, userId, ReportMutationAction.recheck);
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
    TransitCatalogue.requireSharedWrites();
    if (actorId.isEmpty || actorId != currentReportActorId) {
      throw StateError('Sign in before changing a shared report.');
    }
    final recheckId = action != ReportMutationAction.recheck
        ? null
        : reportMutationWriter != null
        ? 'injected-${DateTime.now().microsecondsSinceEpoch}'
        : _reportsRef.doc(reportId).collection('rechecks').doc().id;
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
        recheckId: recheckId,
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
            recheckId: recheckId,
          );
          if (!plan.changed) return plan;
          if (action == ReportMutationAction.recheck) {
            transaction.update(ref, {
              'lastRecheckedAt': FieldValue.serverTimestamp(),
              'lastRecheckedBy': actorId,
              'lastRecheckId': recheckId,
            });
            transaction.set(ref.collection('rechecks').doc(recheckId), {
              'reportId': reportId,
              'userId': actorId,
              'checkedAt': FieldValue.serverTimestamp(),
            });
          } else if (action == ReportMutationAction.resolve) {
            transaction.update(ref, {
              'status': 'resolved',
              'resolvedBy': actorId,
              'resolvedAt': FieldValue.serverTimestamp(),
            });
            transaction.set(
              _db
                  .collection(SampleTestMode.collection('report_resolutions'))
                  .doc(reportId),
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
    if (TransitCatalogue.demo) {
      _syncBusCache();
      return Stream.value(
        busId == null
            ? List.unmodifiable(_localBusesFallback)
            : _localBusesFallback.where((bus) => bus.id == busId).toList(),
      );
    }
    late StreamController<List<Bus>> controller;
    StreamSubscription? remote;
    StreamSubscription? local;
    bool cancelled = false;
    void emit() {
      if (cancelled) return;
      _syncBusCache();
      controller.add(
        busId == null
            ? List.unmodifiable(_localBusesFallback)
            : _localBusesFallback.where((bus) => bus.id == busId).toList(),
      );
    }

    Future<void> start() async {
      await TransitCatalogue.ensureLoaded();
      if (cancelled) return;
      emit();
      local = _localBusesStreamController.stream.listen((_) => emit());
      try {
        if (busId == null) {
          remote = _busesRef.snapshots(includeMetadataChanges: true).listen((
            snapshot,
          ) async {
            if (snapshot.metadata.hasPendingWrites ||
                snapshot.metadata.isFromCache) {
              TransitCatalogue.markUnavailable('buses');
              return;
            }
            await TransitCatalogue.accept('buses', {
              for (final doc in snapshot.docs) doc.id: doc.data(),
            });
            emit();
          }, onError: (Object _) => TransitCatalogue.markUnavailable('buses'));
        } else {
          var receivedServerSnapshot = false;
          remote = _busesRef
              .doc(busId)
              .snapshots(includeMetadataChanges: true)
              .listen(
                (snapshot) async {
                  if (snapshot.metadata.hasPendingWrites) return;
                  if (snapshot.metadata.isFromCache) {
                    // A new document listener starts with SDK cache even when
                    // the full catalogue was just acknowledged by the server.
                    // Only a later cache transition indicates lost freshness.
                    if (receivedServerSnapshot) {
                      TransitCatalogue.markUnavailable('buses');
                    }
                    return;
                  }
                  receivedServerSnapshot = true;
                  if (snapshot.exists &&
                      !TransitCatalogue.isDemonstration(
                        'buses',
                        busId,
                        snapshot.data()!,
                      )) {
                    await TransitCatalogue.accept('buses', {
                      busId: snapshot.data()!,
                    }, replace: false);
                  } else {
                    await TransitCatalogue.remove('buses', busId);
                  }
                  emit();
                },
                onError: (Object _) =>
                    TransitCatalogue.markUnavailable('buses'),
              );
        }
      } catch (_) {
        TransitCatalogue.markUnavailable('buses');
      }
    }

    controller = StreamController<List<Bus>>(
      onListen: start,
      onCancel: () async {
        cancelled = true;
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
    TransitCatalogue.requireSharedWrites();
    final updates = <String, dynamic>{
      'rampOk': ?rampOk,
      if (occupancy != null) 'occupancy': occupancy.toLowerCase(),
      'driverId': ?driverId,
    };
    if (updates.isEmpty) return;
    Bus? acknowledged;
    if (busWriter != null) {
      await busWriter!(busId, updates);
    } else {
      final target = await _busesRef
          .doc(busId)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));
      if (!target.exists ||
          target.metadata.hasPendingWrites ||
          target.metadata.isFromCache) {
        throw StateError('A shared bus record is required');
      }
      TransitCatalogue.requireVehicleRecord(busId, target.data()!);
      if (rampOk != null) {
        final uid = operatorActorId?.call() ?? currentReportActorId;
        if (uid == null || uid.isEmpty) {
          throw StateError('Sign in to record a ramp observation');
        }
        updates['rampCheckedAt'] = FieldValue.serverTimestamp();
        updates['rampCheckedBy'] = uid;
      }
      await _busesRef
          .doc(busId)
          .update(updates)
          .timeout(const Duration(seconds: 12));
      try {
        final snapshot = await _busesRef
            .doc(busId)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 8));
        if (snapshot.exists &&
            !snapshot.metadata.hasPendingWrites &&
            !snapshot.metadata.isFromCache) {
          acknowledged = Bus.fromFirestore(snapshot);
        }
      } catch (_) {
        // Write is acknowledged; a failed metadata read cannot invent a check time.
      }
    }
    final idx = _localBusesFallback.indexWhere((b) => b.id == busId);
    if (idx != -1) {
      final current = _localBusesFallback[idx];
      _localBusesFallback[idx] =
          acknowledged ??
          current.copyWith(
            rampOk: rampOk,
            occupancy: occupancy?.toLowerCase(),
            driverId: driverId,
            clearRampCheck: rampOk != null,
          );
      _cacheAcknowledgedBus(_localBusesFallback[idx]);
    }
  }

  /// Assigns a driver to a bus document (`buses/{busId}`) (AC-84).
  Future<void> assignBusDriver(String busId, String driverId) async {
    TransitCatalogue.requireSharedWrites();
    final uid = operatorActorId?.call() ?? currentReportActorId;
    if (uid == null || uid.isEmpty || driverId != uid) {
      throw StateError('Only the signed-in approved operator can claim a bus');
    }
    final bus = await _db
        .runTransaction<Bus>((tx) async {
          final approval = await tx.get(
            _db
                .collection(SampleTestMode.collection('operator_access'))
                .doc(uid),
          );
          final ref = _busesRef.doc(busId);
          final snapshot = await tx.get(ref);
          if (approval.data()?['approved'] != true) {
            throw StateError('Operator approval required');
          }
          if (!snapshot.exists) throw StateError('Bus unavailable');
          TransitCatalogue.requireVehicleRecord(busId, snapshot.data()!);
          final existing = Bus.fromFirestore(snapshot);
          if (existing.driverId != null &&
              existing.driverId!.isNotEmpty &&
              existing.driverId != uid) {
            throw StateError('This bus is assigned to another operator');
          }
          if (existing.driverId != uid) tx.update(ref, {'driverId': uid});
          return existing.copyWith(driverId: uid);
        })
        .timeout(const Duration(seconds: 12));
    final index = _localBusesFallback.indexWhere((item) => item.id == busId);
    if (index >= 0) {
      _cacheAcknowledgedBus(bus);
    }
  }

  /// Adds a new [Station] to Firestore (`stations/{id}`) and inserts its ID
  /// into an existing [Bus] route's ordered `stops` list at [insertIndex].
  Future<void> addStationAndInsertIntoBusRoute({
    required Station newStation,
    required String busId,
    required int insertIndex,
  }) async {
    TransitCatalogue.requireSharedWrites();
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
    TransitCatalogue.requireSharedWrites();
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
      return _localRequestsFallback.where(matches).toList()..sort(
        (a, b) => Report.compareDatesDescending(a.createdAt, b.createdAt),
      );
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
    TransitCatalogue.requireSharedWrites();
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
