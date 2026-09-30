import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/firestore_constants.dart';
import '../models/bus.dart';
import '../models/bus_route.dart';
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

  /// Master list of transit routes with route numbers, names, descriptions, and ordered stops.
  static final List<BusRoute> sampleRoutes = [
    const BusRoute(
      id: 'route_138_outbound',
      routeNo: '138',
      routeName: 'Pettah - Kottawa (Outbound)',
      description: 'Via High Level Road, Maradana, Borella, Nugegoda, Maharagama, Kottawa',
      stops: [
        'st_pettah',
        'st_maradana',
        'st_borella',
        'st_nugegoda',
        'st_maharagama',
        'st_kottawa'
      ],
    ),
    const BusRoute(
      id: 'route_138_inbound',
      routeNo: '138',
      routeName: 'Kottawa - Pettah (Inbound)',
      description: 'Via High Level Road, Maharagama, Nugegoda, Borella, Maradana, Pettah',
      stops: [
        'st_kottawa',
        'st_maharagama',
        'st_nugegoda',
        'st_borella',
        'st_maradana',
        'st_pettah'
      ],
    ),
    const BusRoute(
      id: 'route_100_outbound',
      routeNo: '100',
      routeName: 'Pettah - Mount Lavinia (Galle Road)',
      description: 'Via Galle Road, Fort, Kollupitiya, Bambalapitiya, Wellawatte, Dehiwala, Mount Lavinia',
      stops: [
        'st_pettah',
        'st_fort',
        'st_kollupitiya',
        'st_bambalapitiya',
        'st_wellawatte',
        'st_dehiwala',
        'st_mt_lavinia'
      ],
    ),
    const BusRoute(
      id: 'route_101_outbound',
      routeNo: '101',
      routeName: 'Pettah - Mount Lavinia',
      description: 'Via Kollupitiya, Bambalapitiya, Wellawatte, Dehiwala',
      stops: [
        'st_pettah',
        'st_kollupitiya',
        'st_bambalapitiya',
        'st_wellawatte',
        'st_dehiwala',
        'st_mt_lavinia'
      ],
    ),
    const BusRoute(
      id: 'route_177_outbound',
      routeNo: '177',
      routeName: 'Kollupitiya - Borella',
      description: 'Via Town Hall, Borella',
      stops: ['st_kollupitiya', 'st_town_hall', 'st_borella'],
    ),
    const BusRoute(
      id: 'route_120_outbound',
      routeNo: '120',
      routeName: 'Pettah - Maharagama',
      description: 'Via Slave Island, Kirulapone, Nugegoda, Maharagama',
      stops: [
        'st_pettah',
        'st_slave_island',
        'st_kirulapone',
        'st_nugegoda',
        'st_maharagama'
      ],
    ),
    const BusRoute(
      id: 'route_122_outbound',
      routeNo: '122',
      routeName: 'Pettah - Avissawella',
      description: 'Via Maradana, Borella',
      stops: ['st_pettah', 'st_maradana', 'st_borella'],
    ),
    const BusRoute(
      id: 'route_171_outbound',
      routeNo: '171',
      routeName: 'Pettah - Borella',
      description: 'Via Fort, Town Hall, Borella',
      stops: ['st_pettah', 'st_fort', 'st_town_hall', 'st_borella'],
    ),
    const BusRoute(
      id: 'route_154_outbound',
      routeNo: '154',
      routeName: 'Kirulapone - Borella',
      description: 'Via Bambalapitiya, Town Hall, Borella',
      stops: ['st_kirulapone', 'st_bambalapitiya', 'st_town_hall', 'st_borella'],
    ),
    const BusRoute(
      id: 'route_176_outbound',
      routeNo: '176',
      routeName: 'Dehiwala - Nugegoda',
      description: 'Via Kirulapone, Nugegoda',
      stops: ['st_dehiwala', 'st_kirulapone', 'st_nugegoda'],
    ),
  ];

  /// Sample bus vehicles with registration numbers, route references, schedules, and accessibility features.
  static final List<Bus> sampleBuses = [
    // 1. Safe Bus #1 (Route 138 Outbound - Morning Express)
    const Bus(
      id: 'bus_138_outbound',
      busNo: 'WP NA-1381',
      routeId: 'route_138_outbound',
      routeNo: '138',
      scheduledDeparture: '08:00 AM',
      stops: [
        'st_pettah',
        'st_maradana',
        'st_borella',
        'st_nugegoda',
        'st_maharagama',
        'st_kottawa'
      ],
      scheduleTimes: [
        '08:00 AM',
        '08:12 AM',
        '08:25 AM',
        '08:40 AM',
        '08:55 AM',
        '09:15 AM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
    ),
    // 2. Safe Bus #1b (Route 138 Outbound - Mid-morning)
    const Bus(
      id: 'bus_138_outbound_2',
      busNo: 'WP NB-5420',
      routeId: 'route_138_outbound',
      routeNo: '138',
      scheduledDeparture: '08:30 AM',
      stops: [
        'st_pettah',
        'st_maradana',
        'st_borella',
        'st_nugegoda',
        'st_maharagama',
        'st_kottawa'
      ],
      scheduleTimes: [
        '08:30 AM',
        '08:42 AM',
        '08:55 AM',
        '09:10 AM',
        '09:25 AM',
        '09:45 AM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'medium',
    ),
    // 3. Directional bus (Route 138 Inbound: Kottawa to Pettah)
    const Bus(
      id: 'bus_138_inbound',
      busNo: 'WP NC-2041',
      routeId: 'route_138_inbound',
      routeNo: '138',
      scheduledDeparture: '09:30 AM',
      stops: [
        'st_kottawa',
        'st_maharagama',
        'st_nugegoda',
        'st_borella',
        'st_maradana',
        'st_pettah'
      ],
      scheduleTimes: [
        '09:30 AM',
        '09:50 AM',
        '10:05 AM',
        '10:20 AM',
        '10:33 AM',
        '10:45 AM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'medium',
    ),
    // 4. Safe Bus #2 (Route 100 Outbound: Galle Road Corridor)
    const Bus(
      id: 'bus_100_outbound',
      busNo: 'WP ND-1001',
      routeId: 'route_100_outbound',
      routeNo: '100',
      scheduledDeparture: '07:30 AM',
      stops: [
        'st_pettah',
        'st_fort',
        'st_kollupitiya',
        'st_bambalapitiya',
        'st_wellawatte',
        'st_dehiwala',
        'st_mt_lavinia'
      ],
      scheduleTimes: [
        '07:30 AM',
        '07:38 AM',
        '07:48 AM',
        '07:58 AM',
        '08:08 AM',
        '08:20 AM',
        '08:30 AM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'medium',
    ),
    // 5. Accessible Bus #2b (Route 100 Outbound - Later Run)
    const Bus(
      id: 'bus_100_outbound_2',
      busNo: 'WP ND-1002',
      routeId: 'route_100_outbound',
      routeNo: '100',
      scheduledDeparture: '08:45 AM',
      stops: [
        'st_pettah',
        'st_fort',
        'st_kollupitiya',
        'st_bambalapitiya',
        'st_wellawatte',
        'st_dehiwala',
        'st_mt_lavinia'
      ],
      scheduleTimes: [
        '08:45 AM',
        '08:53 AM',
        '09:03 AM',
        '09:13 AM',
        '09:23 AM',
        '09:35 AM',
        '09:45 AM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
    ),
    // 6. Warning Bus #1 (Route 101: Broken Ramp, rampOk = false)
    const Bus(
      id: 'bus_101_outbound',
      busNo: 'WP NE-3390',
      routeId: 'route_101_outbound',
      routeNo: '101',
      scheduledDeparture: '08:15 AM',
      stops: [
        'st_pettah',
        'st_kollupitiya',
        'st_bambalapitiya',
        'st_wellawatte',
        'st_dehiwala',
        'st_mt_lavinia'
      ],
      scheduleTimes: [
        '08:15 AM',
        '08:30 AM',
        '08:40 AM',
        '08:50 AM',
        '09:02 AM',
        '09:15 AM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: false,
      occupancy: 'high',
    ),
    // 7. Warning Bus #2 (Route 177: Broken Ramp, rampOk = false)
    const Bus(
      id: 'bus_177_outbound',
      busNo: 'WP NF-4412',
      routeId: 'route_177_outbound',
      routeNo: '177',
      scheduledDeparture: '09:00 AM',
      stops: ['st_kollupitiya', 'st_town_hall', 'st_borella'],
      scheduleTimes: ['09:00 AM', '09:10 AM', '09:22 AM'],
      hasRamp: true,
      lowFloor: false,
      rampOk: false,
      occupancy: 'high',
    ),
    // 8. Not Accessible Bus #1 (Route 120: High step, no ramp, no low floor)
    const Bus(
      id: 'bus_120_outbound',
      busNo: 'WP GA-6710',
      routeId: 'route_120_outbound',
      routeNo: '120',
      scheduledDeparture: '10:00 AM',
      stops: [
        'st_pettah',
        'st_slave_island',
        'st_kirulapone',
        'st_nugegoda',
        'st_maharagama'
      ],
      scheduleTimes: [
        '10:00 AM',
        '10:12 AM',
        '10:28 AM',
        '10:42 AM',
        '11:00 AM'
      ],
      hasRamp: false,
      lowFloor: false,
      rampOk: false,
      occupancy: 'high',
    ),
    // 9. Not Accessible Bus #2 (Route 122: Standard non-accessible coach)
    const Bus(
      id: 'bus_122_outbound',
      busNo: 'WP GB-9011',
      routeId: 'route_122_outbound',
      routeNo: '122',
      scheduledDeparture: '11:15 AM',
      stops: ['st_pettah', 'st_maradana', 'st_borella'],
      scheduleTimes: ['11:15 AM', '11:25 AM', '11:38 AM'],
      hasRamp: false,
      lowFloor: false,
      rampOk: false,
      occupancy: 'medium',
    ),
    // 10. Safe Accessible Bus #3 (Route 171)
    const Bus(
      id: 'bus_171_outbound',
      busNo: 'WP NA-7711',
      routeId: 'route_171_outbound',
      routeNo: '171',
      scheduledDeparture: '08:45 AM',
      stops: ['st_pettah', 'st_fort', 'st_town_hall', 'st_borella'],
      scheduleTimes: ['08:45 AM', '08:53 AM', '09:08 AM', '09:20 AM'],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
    ),
    // 11. Safe Accessible Bus #4 (Route 154)
    const Bus(
      id: 'bus_154_outbound',
      busNo: 'WP NB-8822',
      routeId: 'route_154_outbound',
      routeNo: '154',
      scheduledDeparture: '10:30 AM',
      stops: ['st_kirulapone', 'st_bambalapitiya', 'st_town_hall', 'st_borella'],
      scheduleTimes: ['10:30 AM', '10:42 AM', '10:55 AM', '11:10 AM'],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'medium',
    ),
    // 12. Safe Accessible Bus #5 (Route 176)
    const Bus(
      id: 'bus_176_outbound',
      busNo: 'WP NC-3319',
      routeId: 'route_176_outbound',
      routeNo: '176',
      scheduledDeparture: '01:00 PM',
      stops: ['st_dehiwala', 'st_kirulapone', 'st_nugegoda'],
      scheduleTimes: ['01:00 PM', '01:15 PM', '01:28 PM'],
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

    // 2. Seed Routes
    for (final route in sampleRoutes) {
      final docRef = _db
          .collection(FirestoreConstants.routesCollection)
          .doc(route.id);
      batch.set(docRef, route.toMap(), SetOptions(merge: true));
    }

    // 3. Seed Buses
    for (final bus in sampleBuses) {
      final docRef = _db
          .collection(FirestoreConstants.staticBusesCollection)
          .doc(bus.id);
      batch.set(docRef, bus.toMap(), SetOptions(merge: true));
    }

    // 4. Seed Reports
    for (final report in getSampleReports()) {
      final docRef = _db
          .collection(FirestoreConstants.reportsCollection)
          .doc(report.id);
      batch.set(docRef, report.toMap(), SetOptions(merge: true));
    }

    await batch.commit();
    debugPrint(
      'Firestore Seeding Complete! Wrote ${colomboStations.length} stations, ${sampleRoutes.length} routes, ${sampleBuses.length} buses, and ${getSampleReports().length} reports.',
    );
  }
}
