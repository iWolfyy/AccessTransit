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
  /// Optionally filters by [status] (e.g. "active" or "resolved").
  Stream<List<Report>> streamReports({String? status}) {
    Query<Map<String, dynamic>> query = _reportsRef;
    if (status != null && status.isNotEmpty) {
      query = query.where(FirestoreConstants.fieldStatus, isEqualTo: status);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Report.fromFirestore(doc)).toList();
    });
  }

  /// Submits a new condition report to Firestore (`reports/{id}`).
  Future<void> createReport(Report report) async {
    final docRef = report.id.isNotEmpty
        ? _reportsRef.doc(report.id)
        : _reportsRef.doc();
    await docRef.set(report.toMap(isServerTimestamp: true));
  }
}
