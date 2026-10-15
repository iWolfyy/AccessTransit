import 'dart:typed_data';

import 'package:access_transit/services/transit_catalogue.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:access_transit/services/report_submission_service.dart';
import 'package:access_transit/services/live_bus_service.dart';
import 'package:access_transit/services/assistance_submission_service.dart';
import 'package:access_transit/services/journey_service.dart';
import 'package:access_transit/services/trip_service.dart';
import 'package:access_transit/models/boarding_request.dart';
import 'package:access_transit/models/journey_model.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/widgets/catalogue_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demo flag is compile-time and defaults to shared mode', () {
    expect(
      TransitCatalogue.demo,
      const bool.fromEnvironment('TRANSIT_DEMO', defaultValue: false),
    );
  });
  testWidgets(
    'explicit demo shows a label, sample catalogue and rejects shared uploads/claims',
    (tester) async {
      if (!TransitCatalogue.demo) return;
      final service = FirestoreService();
      expect(await service.getBuses(), isNotEmpty);
      expect(await service.getStations(), isNotEmpty);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CatalogueNotice())),
      );
      expect(find.textContaining('DEMONSTRATION'), findsOneWidget);
      expect(await LiveBusService().getLiveLocation('bus_138_nd4521'), isNull);
      await expectLater(
        service.assignBusDriver('bus_138_nd4521', 'operator'),
        throwsStateError,
      );
      await expectLater(
        service.updateBusAccessibility('bus_138_nd4521', rampOk: true),
        throwsStateError,
      );
      final outbox = ReportSubmissionService(
        photoUploader: (_, _) async => fail('Demo must not upload'),
        publisher: (_) async => fail('Demo must not publish'),
      );
      await expectLater(
        outbox.submit(
          Report(
            id: 'demo-report',
            userId: 'rider',
            targetType: 'bus',
            targetId: 'bus_138_nd4521',
            problemType: 'Ramp Working',
            status: 'active',
            createdAt: DateTime.now(),
          ),
          photoBytes: Uint8List.fromList([1]),
        ),
        throwsStateError,
      );
      expect(outbox.entries, isEmpty);
      final assistance = AssistanceSubmissionService();
      await expectLater(
        assistance.enqueue(
          BoardingRequest(
            id: 'demo',
            riderId: 'rider',
            riderName: 'Rider',
            busId: 'bus_138_nd4521',
            routeNo: '138',
            stationId: 'st_fort',
            stopName: 'Fort',
            assistanceTypes: const ['Deploy Ramp'],
            status: 'pending',
            createdAt: DateTime.now(),
          ),
        ),
        throwsStateError,
      );
      await expectLater(
        JourneyService().createJourney(
          const JourneyModel(
            journeyId: 'demo',
            passengerId: 'rider',
            routeId: 'route',
            routeNumber: '138',
            routeTitle: 'Demo',
            busId: 'bus_138_nd4521',
            origin: 'Fort',
            destination: 'Pettah',
          ),
        ),
        throwsStateError,
      );
      await expectLater(
        TripService().startTrip(
          busId: 'bus_138_nd4521',
          routeNo: '138',
          stops: const ['st_fort', 'st_pettah'],
          driverId: 'operator',
        ),
        throwsStateError,
      );
      assistance.dispose();
      outbox.dispose();
    },
  );
}
