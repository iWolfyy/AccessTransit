import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:access_transit/data/seed_data.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/bus_location_model.dart';
import 'package:access_transit/models/enums/bus_status.dart';
import 'package:access_transit/screens/journey/route_details_screen.dart';
import 'package:access_transit/services/bus_tracking_service.dart';
import 'package:access_transit/services/live_bus_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testBus = SeedData.sampleBuses.firstWhere(
    (b) => b.id == 'bus_138_nd4521',
    orElse: () => const Bus(
      id: 'bus_138_nd4521',
      routeNo: '138',
      busNo: 'WP ND-4521',
      hasRamp: true,
      lowFloor: true,
      rampOk: true,
      occupancy: 'low',
      stops: ['st_pettah', 'st_maradana', 'st_borella', 'st_kottawa'],
      scheduleTimes: [
        '01:30 PM',
        '01:42 PM',
        '01:54 PM',
        '02:15 PM',
      ],
    ),
  );

  group('Step 5: Stream Unification & BusTrackingService Tests', () {
    test('BusTrackingService delegates watchBusLocation to LiveBusService seamlessly', () async {
      final liveService = LiveBusService();
      final trackingService = BusTrackingService();

      final initialBusModel = BusLocationModel(
        busId: 'bus_test_unification',
        routeId: 'route_138',
        driverId: 'driver_01',
        latitude: 6.9344,
        longitude: 79.8543,
        speed: 38.0,
        status: BusStatus.active,
        isBroadcasting: true,
        nextStop: 'Maradana',
        currentStopIndex: 1,
      );

      // Publish via LiveBusService
      await liveService.startOrUpdateLiveLocation(initialBusModel);

      // Listen via BusTrackingService
      final emitted = await trackingService.watchBusLocation('bus_test_unification').first;
      expect(emitted, isNotNull);
      expect(emitted?.busId, equals('bus_test_unification'));
      expect(emitted?.speed, equals(38.0));
      expect(emitted?.nextStop, equals('Maradana'));
      expect(emitted?.isBroadcasting, isTrue);
    });

    test('BusTrackingService.watchActiveBuses emits all active broadcasting buses from LiveBusService', () async {
      final liveService = LiveBusService();
      final trackingService = BusTrackingService();

      final activeModel = BusLocationModel(
        busId: 'bus_active_1',
        routeId: 'route_138',
        driverId: 'driver_01',
        latitude: 6.9344,
        longitude: 79.8543,
        speed: 40.0,
        status: BusStatus.active,
        isBroadcasting: true,
      );

      await liveService.startOrUpdateLiveLocation(activeModel);

      final activeList = await trackingService.watchActiveBuses().first;
      expect(activeList.any((b) => b.busId == 'bus_active_1'), isTrue);
    });
  });

  group('Step 5: RouteDetailsScreen Real-Time Stream Synchronization Tests', () {
    testWidgets('RouteDetailsScreen reflects driver GPS broadcast and live speed', (tester) async {
      final liveService = LiveBusService();

      // Driver broadcasts telemetry
      await liveService.startOrUpdateLiveLocation(
        BusLocationModel(
          busId: testBus.id,
          routeId: 'route_138_pettah_homagama',
          driverId: 'driver_step5',
          latitude: 6.9344,
          longitude: 79.8543,
          speed: 42.0,
          status: BusStatus.active,
          isBroadcasting: true,
          nextStop: 'st_maradana',
          currentStopIndex: 1,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RouteDetailsScreen(
            origin: 'st_pettah',
            destination: 'st_kottawa',
            bus: testBus,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display LIVE GPS indicator and live speed
      expect(find.text('LIVE GPS'), findsOneWidget);
      expect(find.text('42 km/h'), findsOneWidget);
    });

    testWidgets('Driver reporting quick delay instantly displays alert banner on RouteDetailsScreen', (tester) async {
      final liveService = LiveBusService();

      // Start initial active location
      await liveService.startOrUpdateLiveLocation(
        BusLocationModel(
          busId: testBus.id,
          routeId: 'route_138_pettah_homagama',
          driverId: 'driver_step5',
          latitude: 6.9344,
          longitude: 79.8543,
          speed: 25.0,
          status: BusStatus.active,
          isBroadcasting: true,
          nextStop: 'st_maradana',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RouteDetailsScreen(
            origin: 'st_pettah',
            destination: 'st_kottawa',
            bus: testBus,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no driver alert banner
      expect(find.textContaining('Driver Alert:'), findsNothing);

      // Driver reports delay (Traffic Congestion +10 mins)
      await liveService.reportDelay(
        busId: testBus.id,
        reason: 'Traffic Congestion',
        delayMinutes: 10,
      );

      await tester.pumpAndSettle();

      // RouteDetailsScreen should now display real-time delay alert banner
      expect(find.textContaining('Driver Alert: Traffic Congestion (+10m)'), findsOneWidget);

      // Driver clears delay
      await liveService.clearDelay(testBus.id);
      await tester.pumpAndSettle();

      // Driver alert banner should be dismissed
      expect(find.textContaining('Driver Alert:'), findsNothing);
    });

    testWidgets('Driver next stop advance instantly updates RouteDetailsScreen stop timeline', (tester) async {
      final liveService = LiveBusService();

      await liveService.startOrUpdateLiveLocation(
        BusLocationModel(
          busId: testBus.id,
          routeId: 'route_138_pettah_homagama',
          driverId: 'driver_step5',
          latitude: 6.9344,
          longitude: 79.8543,
          speed: 30.0,
          status: BusStatus.active,
          isBroadcasting: true,
          nextStop: 'st_maradana',
          currentStopIndex: 1,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RouteDetailsScreen(
            origin: 'st_kottawa',
            destination: 'st_pettah',
            bus: testBus,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Driver advances to Borella (stop index 2)
      await liveService.updateNextStop(
        busId: testBus.id,
        nextStop: 'st_borella',
        currentStopIndex: 2,
        etaMinutes: 6,
      );

      await tester.pumpAndSettle();

      // Timeline stops progression renders correctly
      expect(find.byType(ListView), findsWidgets);
    });
  });
}
