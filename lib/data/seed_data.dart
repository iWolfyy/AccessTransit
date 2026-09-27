import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/firestore_constants.dart';
import '../models/bus.dart';
import '../models/report.dart';
import '../models/station.dart';

/// Seeder utility to populate Firestore with initial stations, bus routes, and sample reports.
///
/// Uses batched writes and fixed document IDs so executing it multiple times is idempotent.
class SeedData {
  SeedData({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;
  FirebaseFirestore get _db => _customFirestore ?? FirebaseFirestore.instance;

  /// Sample stations along major transit corridors in Colombo, Sri Lanka (AC-69).
  static final List<Station> colomboStations = [
    const Station(
      id: 'st_fort',
      name: 'Colombo Fort Station',
      hasElevator: true,
      hasRamp: true,
      lat: 6.9333,
      lng: 79.8500,
    ),
    const Station(
      id: 'st_pettah',
      name: 'Pettah Central Bus Stand',
      hasElevator: false,
      hasRamp: true,
      lat: 6.9360,
      lng: 79.8527,
    ),
    const Station(
      id: 'st_slave_island',
      name: 'Slave Island Station',
      hasElevator: false,
      hasRamp: false,
      lat: 6.9245,
      lng: 79.8540,
    ),
    const Station(
      id: 'st_kollupitiya',
      name: 'Kollupitiya Station',
      hasElevator: true,
      hasRamp: true,
      lat: 6.9147,
      lng: 79.8510,
    ),
    const Station(
      id: 'st_bambalapitiya',
      name: 'Bambalapitiya Station',
      hasElevator: false,
      hasRamp: true,
      lat: 6.8920,
      lng: 79.8552,
    ),
    const Station(
      id: 'st_wellawatte',
      name: 'Wellawatte Station',
      hasElevator: false,
      hasRamp: true,
      lat: 6.8740,
      lng: 79.8605,
    ),
    const Station(
      id: 'st_dehiwala',
      name: 'Dehiwala Station',
      hasElevator: false,
      hasRamp: false,
      lat: 6.8517,
      lng: 79.8640,
    ),
    const Station(
      id: 'st_mt_lavinia',
      name: 'Mount Lavinia Station',
      hasElevator: false,
      hasRamp: true,
      lat: 6.8350,
      lng: 79.8633,
    ),
    const Station(
      id: 'st_maradana',
      name: 'Maradana Station',
      hasElevator: true,
      hasRamp: true,
      lat: 6.9272,
      lng: 79.8648,
    ),
    const Station(
      id: 'st_borella',
      name: 'Borella Junction Bus Stop',
      hasElevator: false,
      hasRamp: true,
      lat: 6.9142,
      lng: 79.8778,
    ),
    const Station(
      id: 'st_town_hall',
      name: 'Colombo Town Hall Stop',
      hasElevator: true,
      hasRamp: true,
      lat: 6.9147,
      lng: 79.8640,
    ),
    const Station(
      id: 'st_nugegoda',
      name: 'Nugegoda Bus Stand',
      hasElevator: false,
      hasRamp: true,
      lat: 6.8700,
      lng: 79.8885,
    ),
    const Station(
      id: 'st_kirulapone',
      name: 'Kirulapone Market Stop',
      hasElevator: false,
      hasRamp: false,
      lat: 6.8833,
      lng: 79.8755,
    ),
    const Station(
      id: 'st_maharagama',
      name: 'Maharagama Bus Complex',
      hasElevator: true,
      hasRamp: true,
      lat: 6.8480,
      lng: 79.9265,
    ),
    const Station(
      id: 'st_kottawa',
      name: 'Kottawa Highway Bus Station',
      hasElevator: true,
      hasRamp: true,
      lat: 6.8420,
      lng: 79.9650,
    ),
  ];

  /// Sample bus routes with varied accessibility features for testing and demo (AC-70).
  static final List<Bus> sampleBuses = [
    // 1. Safe Bus #1 (Route 138 Outbound)
    const Bus(
      id: 'bus_138_outbound',
      routeNo: '138',
      stops: [
        'st_pettah',
        'st_maradana',
        'st_borella',
        'st_nugegoda',
        'st_maharagama',
        'st_kottawa'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
    ),
    // 2. Directional test bus (Route 138 Inbound: Kottawa to Pettah)
    const Bus(
      id: 'bus_138_inbound',
      routeNo: '138',
      stops: [
        'st_kottawa',
        'st_maharagama',
        'st_nugegoda',
        'st_borella',
        'st_maradana',
        'st_pettah'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'medium',
    ),
    // 3. Safe Bus #2 (Route 100 Outbound: Galle Road Corridor)
    const Bus(
      id: 'bus_100_outbound',
      routeNo: '100',
      stops: [
        'st_pettah',
        'st_fort',
        'st_kollupitiya',
        'st_bambalapitiya',
        'st_wellawatte',
        'st_dehiwala',
        'st_mt_lavinia'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'medium',
    ),
    // 4. Warning Bus #1 (Route 101: Broken Ramp, rampOk = false)
    const Bus(
      id: 'bus_101_outbound',
      routeNo: '101',
      stops: [
        'st_pettah',
        'st_kollupitiya',
        'st_bambalapitiya',
        'st_wellawatte',
        'st_dehiwala',
        'st_mt_lavinia'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: false,
      occupancy: 'high',
    ),
    // 5. Warning Bus #2 (Route 177: Broken Ramp, rampOk = false)
    const Bus(
      id: 'bus_177_outbound',
      routeNo: '177',
      stops: ['st_kollupitiya', 'st_town_hall', 'st_borella'],
      hasRamp: true,
      lowFloor: false,
      rampOk: false,
      occupancy: 'high',
    ),
    // 6. Not Accessible Bus #1 (Route 120: High step, no ramp, no low floor)
    const Bus(
      id: 'bus_120_outbound',
      routeNo: '120',
      stops: [
        'st_pettah',
        'st_slave_island',
        'st_kirulapone',
        'st_nugegoda',
        'st_maharagama'
      ],
      hasRamp: false,
      lowFloor: false,
      rampOk: false,
      occupancy: 'high',
    ),
    // 7. Not Accessible Bus #2 (Route 122: Standard non-accessible coach)
    const Bus(
      id: 'bus_122_outbound',
      routeNo: '122',
      stops: ['st_pettah', 'st_maradana', 'st_borella'],
      hasRamp: false,
      lowFloor: false,
      rampOk: false,
      occupancy: 'medium',
    ),
    // 8. Safe Accessible Bus #3 (Route 171)
    const Bus(
      id: 'bus_171_outbound',
      routeNo: '171',
      stops: ['st_pettah', 'st_fort', 'st_town_hall', 'st_borella'],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
    ),
    // 9. Safe Accessible Bus #4 (Route 154)
    const Bus(
      id: 'bus_154_outbound',
      routeNo: '154',
      stops: ['st_kirulapone', 'st_bambalapitiya', 'st_town_hall', 'st_borella'],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'medium',
    ),
    // 10. Safe Accessible Bus #5 (Route 176)
    const Bus(
      id: 'bus_176_outbound',
      routeNo: '176',
      stops: ['st_dehiwala', 'st_kirulapone', 'st_nugegoda'],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
    ),
  ];

  /// Sample community reports for testing expiry and condition flags.
  static List<Report> getSampleReports() {
    final now = DateTime.now();
    return [
      // Active fresh report (2 hours ago)
      Report(
        id: 'report_1',
        targetType: 'station',
        targetId: 'st_fort',
        problemType: 'Elevator entrance 2 out of service',
        status: 'active',
        createdAt: now.subtract(const Duration(hours: 2)),
        lastConfirmedAt: now.subtract(const Duration(minutes: 30)),
        confirmCount: 3,
        falseCount: 0,
        userId: 'user_demo_1',
        confirmedBy: const ['user_demo_1', 'user_demo_2'],
        flaggedBy: const [],
      ),
      // Active older report (> 15 hours ago for expiry testing)
      Report(
        id: 'report_2',
        targetType: 'bus',
        targetId: 'bus_101_outbound',
        problemType: 'Wheelchair ramp deployment motor jammed',
        status: 'active',
        createdAt: now.subtract(const Duration(hours: 15)),
        lastConfirmedAt: now.subtract(const Duration(hours: 14)),
        confirmCount: 1,
        falseCount: 0,
        userId: 'user_demo_2',
        confirmedBy: const ['user_demo_2'],
        flaggedBy: const [],
      ),
      // Resolved report (1 day ago)
      Report(
        id: 'report_3',
        targetType: 'station',
        targetId: 'st_bambalapitiya',
        problemType: 'Ramp pathway blocked by temporary scaffolding',
        status: 'resolved',
        createdAt: now.subtract(const Duration(days: 1)),
        lastConfirmedAt: now.subtract(const Duration(hours: 10)),
        confirmCount: 2,
        falseCount: 1,
        userId: 'user_demo_3',
        confirmedBy: const ['user_demo_3'],
        flaggedBy: const ['user_demo_4'],
      ),
    ];
  }

  /// Executes batched writes to populate `stations`, `buses`, and `reports`.
  Future<void> seedAll() async {
    debugPrint('Starting AccessTransit Firestore Seeding...');
    final batch = _db.batch();

    // 1. Seed Stations
    for (final station in colomboStations) {
      final docRef = _db
          .collection(FirestoreConstants.stationsCollection)
          .doc(station.id);
      batch.set(docRef, station.toMap(), SetOptions(merge: true));
    }

    // 2. Seed Buses
    for (final bus in sampleBuses) {
      final docRef = _db
          .collection(FirestoreConstants.staticBusesCollection)
          .doc(bus.id);
      batch.set(docRef, bus.toMap(), SetOptions(merge: true));
    }

    // 3. Seed Reports
    for (final report in getSampleReports()) {
      final docRef = _db
          .collection(FirestoreConstants.reportsCollection)
          .doc(report.id);
      batch.set(docRef, report.toMap(), SetOptions(merge: true));
    }

    await batch.commit();
    debugPrint(
      'Firestore Seeding Complete! Wrote ${colomboStations.length} stations, ${sampleBuses.length} buses, and ${getSampleReports().length} reports.',
    );
  }
}
