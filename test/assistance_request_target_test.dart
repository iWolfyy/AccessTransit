import 'package:access_transit/models/assistance_target.dart';
import 'package:access_transit/models/boarding_request.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/station.dart';
import 'package:access_transit/screens/journey/boarding_assistance_screen.dart';
import 'package:access_transit/services/auth_service.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:access_transit/services/assistance_submission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const fixtureBus = Bus(
  id: 'bus_101',
  routeNo: '101',
  busNo: 'NE-3390',
  hasRamp: true,
  lowFloor: true,
  rampOk: true,
  occupancy: 'low',
  stops: ['boarding', 'destination'],
);
const fixtureStop = Station(
  id: 'destination',
  name: 'Actual getting-off stop',
  hasRamp: true,
  hasElevator: false,
  lat: 6.8,
  lng: 79.8,
);

class FixtureService extends FirestoreService {
  final sent = <BoardingRequest>[];
  @override
  Future<Bus?> getBusById(String id) async =>
      id == fixtureBus.id ? fixtureBus : null;
  @override
  Future<Station?> getStationById(String id) async =>
      id == fixtureStop.id ? fixtureStop : null;
  @override
  Future<void> createBoardingRequest(BoardingRequest request) async {
    sent.add(request);
  }
}

class FixtureUser extends Fake implements User {
  @override
  String get uid => 'real-rider';
  @override
  String? get displayName => 'Rider';
  @override
  String? get email => 'rider@example.test';
}

class FixtureAuth extends AuthService {
  FixtureAuth({this.signedIn = true});
  final bool signedIn;
  @override
  User? get currentUser => signedIn ? FixtureUser() : null;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<FixtureService> show(
    WidgetTester tester, {
    String stopId = 'destination',
    bool signedIn = true,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = FixtureService();
    final auth = FixtureAuth(signedIn: signedIn);
    final submission = AssistanceSubmissionService(
      currentRiderId: () => auth.currentUser?.uid,
      publisher: (r) async {
        await service.createBoardingRequest(r);
        return r;
      },
    );
    addTearDown(submission.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: BoardingAssistanceScreen(
          busId: 'bus_101',
          stationId: stopId,
          stopName: fixtureStop.name,
          busLabel: 'NE-3390 (Route 101)',
          purpose: AssistancePurpose.alighting,
          firestoreService: service,
          authService: auth,
          submissionService: submission,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return service;
  }

  Future<void> review(WidgetTester tester) async {
    await tester.tap(find.text('Getting Off Help'));
    final send = find.widgetWithText(FilledButton, 'Send Request');
    await tester.scrollUntilVisible(
      send,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(send);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'review and submission use the same exact bus/stop and alighting purpose',
    (tester) async {
      final service = await show(tester);
      await review(tester);
      expect(find.text('Confirm assistance target'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining(
            'Getting off at Actual getting-off stop',
          ),
        ),
        findsOneWidget,
      );
      expect(service.sent, isEmpty);
      await tester.tap(find.text('Confirm and send'));
      await tester.pumpAndSettle();
      final sent = service.sent.single;
      expect(sent.busId, 'bus_101');
      expect(sent.stationId, 'destination');
      expect(sent.routeNo, '101');
      expect(sent.stopName, fixtureStop.name);
      expect(sent.riderId, 'real-rider');
      expect(sent.purpose, 'alighting');
      expect(sent.assistanceTypes, ['Alighting Help']);
      expect(
        BoardingRequest.fromMap(sent.toMap(), id: sent.id).purpose,
        'alighting',
      );
    },
  );
  testWidgets('cancelling review does not send a request', (tester) async {
    final service = await show(tester);
    await review(tester);
    await tester.tap(find.text('Edit request'));
    await tester.pumpAndSettle();
    expect(service.sent, isEmpty);
  });
  testWidgets('invalid stop is rejected without selecting another target', (
    tester,
  ) async {
    final service = await show(tester, stopId: 'wrong-stop');
    await review(tester);
    expect(find.textContaining('stop could not be verified'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(service.sent, isEmpty);
  });
  testWidgets(
    'guest identity cannot be substituted when committing a request',
    (tester) async {
      final service = await show(tester, signedIn: false);
      await review(tester);
      await tester.tap(find.text('Confirm and send'));
      await tester.pumpAndSettle();
      expect(
        find.text('Please sign in before sending an assistance request.'),
        findsOneWidget,
      );
      expect(service.sent, isEmpty);
    },
  );
}
