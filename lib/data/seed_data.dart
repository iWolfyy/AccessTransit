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
    const Station(
      id: 'st_homagama',
      name: 'Homagama Central Bus Stand',
      hasElevator: false,
      hasRamp: true,
      lat: 6.8400,
      lng: 80.0030,
    ),
    const Station(
      id: 'st_moratuwa',
      name: 'Moratuwa Bus Stand',
      hasElevator: false,
      hasRamp: true,
      lat: 6.7730,
      lng: 79.8816,
    ),
    const Station(
      id: 'st_panadura',
      name: 'Panadura Main Bus Stand',
      hasElevator: true,
      hasRamp: true,
      lat: 6.7135,
      lng: 79.9074,
    ),
    const Station(
      id: 'st_battaramulla',
      name: 'Battaramulla Junction Stop',
      hasElevator: false,
      hasRamp: true,
      lat: 6.8990,
      lng: 79.9180,
    ),
    const Station(
      id: 'st_malabe',
      name: 'Malabe Bus Terminal',
      hasElevator: false,
      hasRamp: true,
      lat: 6.9042,
      lng: 79.9545,
    ),
    const Station(
      id: 'st_kaduwela',
      name: 'Kaduwela Central Bus Stand',
      hasElevator: false,
      hasRamp: true,
      lat: 6.9360,
      lng: 79.9830,
    ),
  ];

  /// Master list of authentic transit routes with route numbers, names, descriptions, and ordered stops.
  static final List<BusRoute> sampleRoutes = [
    // 1. Route 138 (Pettah - Homagama Outbound)
    const BusRoute(
      id: 'route_138_pettah_homagama',
      routeNo: '138',
      routeName: 'Pettah - Homagama (High Level Road)',
      description: 'Via Maradana, Borella, Kirulapone, Nugegoda, Maharagama, Kottawa, Homagama',
      stops: [
        'st_pettah',
        'st_maradana',
        'st_borella',
        'st_kirulapone',
        'st_nugegoda',
        'st_maharagama',
        'st_kottawa',
        'st_homagama'
      ],
    ),
    // 2. Route 138 (Homagama - Pettah Inbound)
    const BusRoute(
      id: 'route_138_homagama_pettah',
      routeNo: '138',
      routeName: 'Homagama - Pettah (Inbound)',
      description: 'Via Homagama, Kottawa, Maharagama, Nugegoda, Kirulapone, Borella, Maradana, Pettah',
      stops: [
        'st_homagama',
        'st_kottawa',
        'st_maharagama',
        'st_nugegoda',
        'st_kirulapone',
        'st_borella',
        'st_maradana',
        'st_pettah'
      ],
    ),
    // 3. Route 100 (Pettah - Panadura Outbound)
    const BusRoute(
      id: 'route_100_pettah_panadura',
      routeNo: '100',
      routeName: 'Pettah - Panadura (Galle Road)',
      description: 'Via Fort, Kollupitiya, Bambalapitiya, Wellawatte, Dehiwala, Mount Lavinia, Moratuwa, Panadura',
      stops: [
        'st_pettah',
        'st_fort',
        'st_kollupitiya',
        'st_bambalapitiya',
        'st_wellawatte',
        'st_dehiwala',
        'st_mt_lavinia',
        'st_moratuwa',
        'st_panadura'
      ],
    ),
    // 4. Route 100 (Panadura - Pettah Inbound)
    const BusRoute(
      id: 'route_100_panadura_pettah',
      routeNo: '100',
      routeName: 'Panadura - Pettah (Inbound)',
      description: 'Via Panadura, Moratuwa, Mount Lavinia, Dehiwala, Wellawatte, Bambalapitiya, Kollupitiya, Fort, Pettah',
      stops: [
        'st_panadura',
        'st_moratuwa',
        'st_mt_lavinia',
        'st_dehiwala',
        'st_wellawatte',
        'st_bambalapitiya',
        'st_kollupitiya',
        'st_fort',
        'st_pettah'
      ],
    ),
    // 5. Route 120 (Pettah - Horana)
    const BusRoute(
      id: 'route_120_pettah_horana',
      routeNo: '120',
      routeName: 'Pettah - Horana (Via 120 Road)',
      description: 'Via Slave Island, Town Hall, Kirulapone, Nugegoda, Maharagama, Kottawa',
      stops: [
        'st_pettah',
        'st_slave_island',
        'st_town_hall',
        'st_kirulapone',
        'st_nugegoda',
        'st_maharagama',
        'st_kottawa'
      ],
    ),
    // 6. Route 177 (Kollupitiya - Kaduwela)
    const BusRoute(
      id: 'route_177_kollupitiya_kaduwela',
      routeNo: '177',
      routeName: 'Kollupitiya - Kaduwela (Via Malabe)',
      description: 'Via Town Hall, Borella, Battaramulla, Malabe, Kaduwela',
      stops: [
        'st_kollupitiya',
        'st_town_hall',
        'st_borella',
        'st_battaramulla',
        'st_malabe',
        'st_kaduwela'
      ],
    ),
    // 7. Route 171 (Pettah - Battaramulla)
    const BusRoute(
      id: 'route_171_pettah_battaramulla',
      routeNo: '171',
      routeName: 'Pettah - Battaramulla (Administrative Corridor)',
      description: 'Via Colombo Fort, Town Hall, Borella, Battaramulla',
      stops: [
        'st_pettah',
        'st_fort',
        'st_town_hall',
        'st_borella',
        'st_battaramulla'
      ],
    ),
    // 8. Route 154 (Kirulapone - Borella)
    const BusRoute(
      id: 'route_154_kirulapone_borella',
      routeNo: '154',
      routeName: 'Kirulapone - Borella',
      description: 'Via Bambalapitiya, Kollupitiya, Town Hall, Borella',
      stops: [
        'st_kirulapone',
        'st_bambalapitiya',
        'st_kollupitiya',
        'st_town_hall',
        'st_borella'
      ],
    ),
    // 9. Route 176 (Dehiwala - Borella)
    const BusRoute(
      id: 'route_176_dehiwala_borella',
      routeNo: '176',
      routeName: 'Dehiwala - Borella (Via Nugegoda)',
      description: 'Via Dehiwala, Kirulapone, Nugegoda, Borella',
      stops: [
        'st_dehiwala',
        'st_kirulapone',
        'st_nugegoda',
        'st_borella'
      ],
    ),
    // 10. Route 101 (Pettah - Moratuwa)
    const BusRoute(
      id: 'route_101_pettah_moratuwa',
      routeNo: '101',
      routeName: 'Pettah - Moratuwa',
      description: 'Via Kollupitiya, Bambalapitiya, Wellawatte, Dehiwala, Mount Lavinia, Moratuwa',
      stops: [
        'st_pettah',
        'st_kollupitiya',
        'st_bambalapitiya',
        'st_wellawatte',
        'st_dehiwala',
        'st_mt_lavinia',
        'st_moratuwa'
      ],
    ),
  ];

  /// Sample bus vehicles with real Sri Lankan registration numbers, route references, schedules, and accessibility features.
  static final List<Bus> sampleBuses = [
    // --- Route 138 Buses (Pettah -> Homagama) ---
    // 1. SLTB Ashok Leyland JanBus (Modern Accessible)
    const Bus(
      id: 'bus_138_nd4521',
      busNo: 'WP ND-4521',
      routeId: 'route_138_pettah_homagama',
      routeNo: '138',
      scheduledDeparture: '06:30 AM',
      stops: [
        'st_pettah',
        'st_maradana',
        'st_borella',
        'st_kirulapone',
        'st_nugegoda',
        'st_maharagama',
        'st_kottawa',
        'st_homagama'
      ],
      scheduleTimes: [
        '06:30 AM',
        '06:42 AM',
        '06:55 AM',
        '07:08 AM',
        '07:22 AM',
        '07:38 AM',
        '07:55 AM',
        '08:10 AM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
    ),
    // 2. SLTB Low-Floor Accessible Bus
    const Bus(
      id: 'bus_138_nb7812',
      busNo: 'WP NB-7812',
      routeId: 'route_138_pettah_homagama',
      routeNo: '138',
      scheduledDeparture: '07:15 AM',
      stops: [
        'st_pettah',
        'st_maradana',
        'st_borella',
        'st_kirulapone',
        'st_nugegoda',
        'st_maharagama',
        'st_kottawa',
        'st_homagama'
      ],
      scheduleTimes: [
        '07:15 AM',
        '07:27 AM',
        '07:40 AM',
        '07:53 AM',
        '08:08 AM',
        '08:25 AM',
        '08:42 AM',
        '08:58 AM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'medium',
    ),
    // 3. Private Standard Bus (Step entry, no ramp)
    const Bus(
      id: 'bus_138_na1234',
      busNo: 'WP NA-1234',
      routeId: 'route_138_pettah_homagama',
      routeNo: '138',
      scheduledDeparture: '08:00 AM',
      stops: [
        'st_pettah',
        'st_maradana',
        'st_borella',
        'st_kirulapone',
        'st_nugegoda',
        'st_maharagama',
        'st_kottawa',
        'st_homagama'
      ],
      scheduleTimes: [
        '08:00 AM',
        '08:12 AM',
        '08:25 AM',
        '08:38 AM',
        '08:52 AM',
        '09:08 AM',
        '09:25 AM',
        '09:40 AM'
      ],
      hasRamp: false,
      lowFloor: false,
      rampOk: false,
      occupancy: 'high',
    ),
    // 4. Warning Bus (Ramp defect reported)
    const Bus(
      id: 'bus_138_nc5566',
      busNo: 'WP NC-5566',
      routeId: 'route_138_pettah_homagama',
      routeNo: '138',
      scheduledDeparture: '08:45 AM',
      stops: [
        'st_pettah',
        'st_maradana',
        'st_borella',
        'st_kirulapone',
        'st_nugegoda',
        'st_maharagama',
        'st_kottawa',
        'st_homagama'
      ],
      scheduleTimes: [
        '08:45 AM',
        '08:57 AM',
        '09:10 AM',
        '09:23 AM',
        '09:38 AM',
        '09:55 AM',
        '10:12 AM',
        '10:28 AM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: false,
      occupancy: 'high',
    ),
    // 5. SLTB AC Semi-Luxury Accessible Bus
    const Bus(
      id: 'bus_138_nd3045',
      busNo: 'WP ND-3045',
      routeId: 'route_138_pettah_homagama',
      routeNo: '138',
      scheduledDeparture: '09:30 AM',
      stops: [
        'st_pettah',
        'st_maradana',
        'st_borella',
        'st_kirulapone',
        'st_nugegoda',
        'st_maharagama',
        'st_kottawa',
        'st_homagama'
      ],
      scheduleTimes: [
        '09:30 AM',
        '09:42 AM',
        '09:55 AM',
        '10:08 AM',
        '10:22 AM',
        '10:38 AM',
        '10:55 AM',
        '11:10 AM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
    ),

    // --- Route 138 Inbound Bus ---
    const Bus(
      id: 'bus_138_nb2190',
      busNo: 'WP NB-2190',
      routeId: 'route_138_homagama_pettah',
      routeNo: '138',
      scheduledDeparture: '07:00 AM',
      stops: [
        'st_homagama',
        'st_kottawa',
        'st_maharagama',
        'st_nugegoda',
        'st_kirulapone',
        'st_borella',
        'st_maradana',
        'st_pettah'
      ],
      scheduleTimes: [
        '07:00 AM',
        '07:15 AM',
        '07:32 AM',
        '07:48 AM',
        '08:02 AM',
        '08:15 AM',
        '08:28 AM',
        '08:40 AM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'medium',
    ),

    // --- Route 100 Buses (Pettah -> Panadura) ---
    // 7. SLTB Galle Road Accessible Bus
    const Bus(
      id: 'bus_100_nd1002',
      busNo: 'WP ND-1002',
      routeId: 'route_100_pettah_panadura',
      routeNo: '100',
      scheduledDeparture: '06:45 AM',
      stops: [
        'st_pettah',
        'st_fort',
        'st_kollupitiya',
        'st_bambalapitiya',
        'st_wellawatte',
        'st_dehiwala',
        'st_mt_lavinia',
        'st_moratuwa',
        'st_panadura'
      ],
      scheduleTimes: [
        '06:45 AM',
        '06:52 AM',
        '07:02 AM',
        '07:12 AM',
        '07:22 AM',
        '07:35 AM',
        '07:46 AM',
        '08:02 AM',
        '08:20 AM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
    ),
    // 8. SLTB City Bus Accessible
    const Bus(
      id: 'bus_100_nb9912',
      busNo: 'WP NB-9912',
      routeId: 'route_100_pettah_panadura',
      routeNo: '100',
      scheduledDeparture: '07:30 AM',
      stops: [
        'st_pettah',
        'st_fort',
        'st_kollupitiya',
        'st_bambalapitiya',
        'st_wellawatte',
        'st_dehiwala',
        'st_mt_lavinia',
        'st_moratuwa',
        'st_panadura'
      ],
      scheduleTimes: [
        '07:30 AM',
        '07:37 AM',
        '07:48 AM',
        '07:58 AM',
        '08:09 AM',
        '08:22 AM',
        '08:34 AM',
        '08:52 AM',
        '09:10 AM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'medium',
    ),
    // 9. Private High-Deck Bus (No ramp)
    const Bus(
      id: 'bus_100_na6654',
      busNo: 'WP NA-6654',
      routeId: 'route_100_pettah_panadura',
      routeNo: '100',
      scheduledDeparture: '08:15 AM',
      stops: [
        'st_pettah',
        'st_fort',
        'st_kollupitiya',
        'st_bambalapitiya',
        'st_wellawatte',
        'st_dehiwala',
        'st_mt_lavinia',
        'st_moratuwa',
        'st_panadura'
      ],
      scheduleTimes: [
        '08:15 AM',
        '08:22 AM',
        '08:33 AM',
        '08:44 AM',
        '08:55 AM',
        '09:08 AM',
        '09:20 AM',
        '09:38 AM',
        '09:55 AM'
      ],
      hasRamp: false,
      lowFloor: false,
      rampOk: false,
      occupancy: 'high',
    ),
    // 10. AC Low-Floor Cityliner
    const Bus(
      id: 'bus_100_nc4110',
      busNo: 'WP NC-4110',
      routeId: 'route_100_pettah_panadura',
      routeNo: '100',
      scheduledDeparture: '09:00 AM',
      stops: [
        'st_pettah',
        'st_fort',
        'st_kollupitiya',
        'st_bambalapitiya',
        'st_wellawatte',
        'st_dehiwala',
        'st_mt_lavinia',
        'st_moratuwa',
        'st_panadura'
      ],
      scheduleTimes: [
        '09:00 AM',
        '09:07 AM',
        '09:18 AM',
        '09:28 AM',
        '09:38 AM',
        '09:50 AM',
        '10:02 AM',
        '10:20 AM',
        '10:38 AM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
    ),

    // --- Route 100 Inbound Bus ---
    const Bus(
      id: 'bus_100_nd8871',
      busNo: 'WP ND-8871',
      routeId: 'route_100_panadura_pettah',
      routeNo: '100',
      scheduledDeparture: '07:15 AM',
      stops: [
        'st_panadura',
        'st_moratuwa',
        'st_mt_lavinia',
        'st_dehiwala',
        'st_wellawatte',
        'st_bambalapitiya',
        'st_kollupitiya',
        'st_fort',
        'st_pettah'
      ],
      scheduleTimes: [
        '07:15 AM',
        '07:32 AM',
        '07:48 AM',
        '08:00 AM',
        '08:12 AM',
        '08:23 AM',
        '08:34 AM',
        '08:45 AM',
        '08:52 AM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'medium',
    ),

    // --- Route 120 Buses (Pettah -> Horana) ---
    const Bus(
      id: 'bus_120_ga1205',
      busNo: 'WP GA-1205',
      routeId: 'route_120_pettah_horana',
      routeNo: '120',
      scheduledDeparture: '07:00 AM',
      stops: [
        'st_pettah',
        'st_slave_island',
        'st_town_hall',
        'st_kirulapone',
        'st_nugegoda',
        'st_maharagama',
        'st_kottawa'
      ],
      scheduleTimes: [
        '07:00 AM',
        '07:10 AM',
        '07:22 AM',
        '07:38 AM',
        '07:52 AM',
        '08:08 AM',
        '08:25 AM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
    ),
    const Bus(
      id: 'bus_120_gb3320',
      busNo: 'WP GB-3320',
      routeId: 'route_120_pettah_horana',
      routeNo: '120',
      scheduledDeparture: '08:00 AM',
      stops: [
        'st_pettah',
        'st_slave_island',
        'st_town_hall',
        'st_kirulapone',
        'st_nugegoda',
        'st_maharagama',
        'st_kottawa'
      ],
      scheduleTimes: [
        '08:00 AM',
        '08:10 AM',
        '08:22 AM',
        '08:38 AM',
        '08:52 AM',
        '09:08 AM',
        '09:25 AM'
      ],
      hasRamp: false,
      lowFloor: false,
      rampOk: false,
      occupancy: 'high',
    ),

    // --- Route 177 Buses (Kollupitiya -> Kaduwela) ---
    const Bus(
      id: 'bus_177_na7711',
      busNo: 'WP NA-7711',
      routeId: 'route_177_kollupitiya_kaduwela',
      routeNo: '177',
      scheduledDeparture: '07:45 AM',
      stops: [
        'st_kollupitiya',
        'st_town_hall',
        'st_borella',
        'st_battaramulla',
        'st_malabe',
        'st_kaduwela'
      ],
      scheduleTimes: [
        '07:45 AM',
        '07:56 AM',
        '08:08 AM',
        '08:25 AM',
        '08:42 AM',
        '09:00 AM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
    ),
    const Bus(
      id: 'bus_177_nf4412',
      busNo: 'WP NF-4412',
      routeId: 'route_177_kollupitiya_kaduwela',
      routeNo: '177',
      scheduledDeparture: '08:30 AM',
      stops: [
        'st_kollupitiya',
        'st_town_hall',
        'st_borella',
        'st_battaramulla',
        'st_malabe',
        'st_kaduwela'
      ],
      scheduleTimes: [
        '08:30 AM',
        '08:41 AM',
        '08:53 AM',
        '09:10 AM',
        '09:28 AM',
        '09:45 AM'
      ],
      hasRamp: true,
      lowFloor: false,
      rampOk: false,
      occupancy: 'high',
    ),

    // --- Route 171 Bus (Pettah -> Battaramulla) ---
    const Bus(
      id: 'bus_171_nd1710',
      busNo: 'WP ND-1710',
      routeId: 'route_171_pettah_battaramulla',
      routeNo: '171',
      scheduledDeparture: '08:00 AM',
      stops: [
        'st_pettah',
        'st_fort',
        'st_town_hall',
        'st_borella',
        'st_battaramulla'
      ],
      scheduleTimes: [
        '08:00 AM',
        '08:08 AM',
        '08:22 AM',
        '08:34 AM',
        '08:52 AM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
    ),

    // --- Route 154 Bus (Kirulapone -> Borella) ---
    const Bus(
      id: 'bus_154_nb8822',
      busNo: 'WP NB-8822',
      routeId: 'route_154_kirulapone_borella',
      routeNo: '154',
      scheduledDeparture: '09:15 AM',
      stops: [
        'st_kirulapone',
        'st_bambalapitiya',
        'st_kollupitiya',
        'st_town_hall',
        'st_borella'
      ],
      scheduleTimes: [
        '09:15 AM',
        '09:27 AM',
        '09:38 AM',
        '09:48 AM',
        '10:02 AM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'medium',
    ),

    // --- Route 176 Bus (Dehiwala -> Borella) ---
    const Bus(
      id: 'bus_176_nc3319',
      busNo: 'WP NC-3319',
      routeId: 'route_176_dehiwala_borella',
      routeNo: '176',
      scheduledDeparture: '08:30 AM',
      stops: [
        'st_dehiwala',
        'st_kirulapone',
        'st_nugegoda',
        'st_borella'
      ],
      scheduleTimes: [
        '08:30 AM',
        '08:44 AM',
        '08:55 AM',
        '09:12 AM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
    ),

    // --- Route 101 Bus (Pettah -> Moratuwa) ---
    const Bus(
      id: 'bus_101_ne3390',
      busNo: 'WP NE-3390',
      routeId: 'route_101_pettah_moratuwa',
      routeNo: '101',
      scheduledDeparture: '08:15 AM',
      stops: [
        'st_pettah',
        'st_kollupitiya',
        'st_bambalapitiya',
        'st_wellawatte',
        'st_dehiwala',
        'st_mt_lavinia',
        'st_moratuwa'
      ],
      scheduleTimes: [
        '08:15 AM',
        '08:28 AM',
        '08:38 AM',
        '08:48 AM',
        '09:00 AM',
        '09:12 AM',
        '09:30 AM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: false,
      occupancy: 'high',
    ),

    // --- Route 101 Afternoon / Evening Buses (Pettah -> Moratuwa) ---
    const Bus(
      id: 'bus_101_nb1145',
      busNo: 'WP NB-1145',
      routeId: 'route_101_pettah_moratuwa',
      routeNo: '101',
      scheduledDeparture: '11:45 AM',
      stops: [
        'st_pettah',
        'st_kollupitiya',
        'st_bambalapitiya',
        'st_wellawatte',
        'st_dehiwala',
        'st_mt_lavinia',
        'st_moratuwa'
      ],
      scheduleTimes: [
        '11:45 AM',
        '11:58 AM',
        '12:08 PM',
        '12:18 PM',
        '12:30 PM',
        '12:42 PM',
        '01:00 PM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
    ),
    const Bus(
      id: 'bus_101_nc3150',
      busNo: 'WP NC-3150',
      routeId: 'route_101_pettah_moratuwa',
      routeNo: '101',
      scheduledDeparture: '03:15 PM',
      stops: [
        'st_pettah',
        'st_kollupitiya',
        'st_bambalapitiya',
        'st_wellawatte',
        'st_dehiwala',
        'st_mt_lavinia',
        'st_moratuwa'
      ],
      scheduleTimes: [
        '03:15 PM',
        '03:28 PM',
        '03:38 PM',
        '03:48 PM',
        '04:00 PM',
        '04:12 PM',
        '04:30 PM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'medium',
    ),
    const Bus(
      id: 'bus_101_nd6300',
      busNo: 'WP ND-6300',
      routeId: 'route_101_pettah_moratuwa',
      routeNo: '101',
      scheduledDeparture: '06:30 PM',
      stops: [
        'st_pettah',
        'st_kollupitiya',
        'st_bambalapitiya',
        'st_wellawatte',
        'st_dehiwala',
        'st_mt_lavinia',
        'st_moratuwa'
      ],
      scheduleTimes: [
        '06:30 PM',
        '06:45 PM',
        '06:56 PM',
        '07:07 PM',
        '07:20 PM',
        '07:33 PM',
        '07:52 PM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'high',
    ),
    const Bus(
      id: 'bus_101_ne9150',
      busNo: 'WP NE-9150',
      routeId: 'route_101_pettah_moratuwa',
      routeNo: '101',
      scheduledDeparture: '09:15 PM',
      stops: [
        'st_pettah',
        'st_kollupitiya',
        'st_bambalapitiya',
        'st_wellawatte',
        'st_dehiwala',
        'st_mt_lavinia',
        'st_moratuwa'
      ],
      scheduleTimes: [
        '09:15 PM',
        '09:27 PM',
        '09:36 PM',
        '09:45 PM',
        '09:56 PM',
        '10:07 PM',
        '10:24 PM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
    ),

    // --- Route 100 Afternoon / Evening Buses (Pettah -> Panadura) ---
    const Bus(
      id: 'bus_100_ne1130',
      busNo: 'WP NE-1130',
      routeId: 'route_100_pettah_panadura',
      routeNo: '100',
      scheduledDeparture: '11:30 AM',
      stops: [
        'st_pettah',
        'st_fort',
        'st_kollupitiya',
        'st_bambalapitiya',
        'st_wellawatte',
        'st_dehiwala',
        'st_mt_lavinia',
        'st_moratuwa',
        'st_panadura'
      ],
      scheduleTimes: [
        '11:30 AM',
        '11:37 AM',
        '11:48 AM',
        '11:58 AM',
        '12:08 PM',
        '12:20 PM',
        '12:32 PM',
        '12:50 PM',
        '01:08 PM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'medium',
    ),
    const Bus(
      id: 'bus_100_nf2300',
      busNo: 'WP NF-2300',
      routeId: 'route_100_pettah_panadura',
      routeNo: '100',
      scheduledDeparture: '02:30 PM',
      stops: [
        'st_pettah',
        'st_fort',
        'st_kollupitiya',
        'st_bambalapitiya',
        'st_wellawatte',
        'st_dehiwala',
        'st_mt_lavinia',
        'st_moratuwa',
        'st_panadura'
      ],
      scheduleTimes: [
        '02:30 PM',
        '02:37 PM',
        '02:48 PM',
        '02:58 PM',
        '03:09 PM',
        '03:21 PM',
        '03:33 PM',
        '03:52 PM',
        '04:10 PM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
    ),
    const Bus(
      id: 'bus_100_ng5450',
      busNo: 'WP NG-5450',
      routeId: 'route_100_pettah_panadura',
      routeNo: '100',
      scheduledDeparture: '05:45 PM',
      stops: [
        'st_pettah',
        'st_fort',
        'st_kollupitiya',
        'st_bambalapitiya',
        'st_wellawatte',
        'st_dehiwala',
        'st_mt_lavinia',
        'st_moratuwa',
        'st_panadura'
      ],
      scheduleTimes: [
        '05:45 PM',
        '05:54 PM',
        '06:06 PM',
        '06:18 PM',
        '06:30 PM',
        '06:44 PM',
        '06:58 PM',
        '07:18 PM',
        '07:38 PM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'high',
    ),
    const Bus(
      id: 'bus_100_nh8300',
      busNo: 'WP NH-8300',
      routeId: 'route_100_pettah_panadura',
      routeNo: '100',
      scheduledDeparture: '08:30 PM',
      stops: [
        'st_pettah',
        'st_fort',
        'st_kollupitiya',
        'st_bambalapitiya',
        'st_wellawatte',
        'st_dehiwala',
        'st_mt_lavinia',
        'st_moratuwa',
        'st_panadura'
      ],
      scheduleTimes: [
        '08:30 PM',
        '08:37 PM',
        '08:47 PM',
        '08:56 PM',
        '09:06 PM',
        '09:17 PM',
        '09:28 PM',
        '09:45 PM',
        '10:02 PM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
    ),

    // --- Route 138 Afternoon / Evening Buses (Pettah -> Homagama) ---
    const Bus(
      id: 'bus_138_ne1215',
      busNo: 'WP NE-1215',
      routeId: 'route_138_pettah_homagama',
      routeNo: '138',
      scheduledDeparture: '12:15 PM',
      stops: [
        'st_pettah',
        'st_maradana',
        'st_borella',
        'st_kirulapone',
        'st_nugegoda',
        'st_maharagama',
        'st_kottawa',
        'st_homagama'
      ],
      scheduleTimes: [
        '12:15 PM',
        '12:27 PM',
        '12:40 PM',
        '12:53 PM',
        '01:07 PM',
        '01:23 PM',
        '01:40 PM',
        '01:55 PM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
    ),
    const Bus(
      id: 'bus_138_ng6450',
      busNo: 'WP NG-6450',
      routeId: 'route_138_pettah_homagama',
      routeNo: '138',
      scheduledDeparture: '06:45 PM',
      stops: [
        'st_pettah',
        'st_maradana',
        'st_borella',
        'st_kirulapone',
        'st_nugegoda',
        'st_maharagama',
        'st_kottawa',
        'st_homagama'
      ],
      scheduleTimes: [
        '06:45 PM',
        '06:58 PM',
        '07:12 PM',
        '07:26 PM',
        '07:42 PM',
        '08:00 PM',
        '08:18 PM',
        '08:35 PM'
      ],
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'high',
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
      // Active older report on Route 101 bus (testing ramp issue)
      Report(
        id: 'report_2',
        targetType: 'bus',
        targetId: 'bus_101_ne3390',
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

  /// Cleans existing collections and executes batched writes to populate `stations`, `routes`, `buses`, and `reports`.
  Future<void> seedAll() async {
    debugPrint('Starting AccessTransit Clean Firestore Seeding...');
    
    // 0. Clean old existing routes, buses, active_buses, and stations documents first
    try {
      final oldRoutes = await _db.collection(FirestoreConstants.routesCollection).get();
      for (final doc in oldRoutes.docs) {
        await doc.reference.delete();
      }
      final oldBuses = await _db.collection(FirestoreConstants.staticBusesCollection).get();
      for (final doc in oldBuses.docs) {
        await doc.reference.delete();
      }
      final oldActiveBuses = await _db.collection(FirestoreConstants.busesCollection).get();
      for (final doc in oldActiveBuses.docs) {
        await doc.reference.delete();
      }
      final oldStations = await _db.collection(FirestoreConstants.stationsCollection).get();
      for (final doc in oldStations.docs) {
        await doc.reference.delete();
      }
      debugPrint('Cleared old Firestore routes, buses, and stations.');
    } catch (e) {
      debugPrint('Note: Error or no old docs while clearing: $e');
    }

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
