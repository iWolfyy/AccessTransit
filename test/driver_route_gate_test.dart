import 'dart:async';

import 'package:access_transit/models/bus.dart';
import 'package:access_transit/services/driver_route_service.dart';
import 'package:access_transit/widgets/driver_route_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class RouteServiceFake extends DriverRouteService {
  String? uid = 'a';
  final auth = StreamController<String?>.broadcast();
  final routes = <String, StreamController<String?>>{};
  @override
  Stream<String?> get userIds async* {
    yield uid;
    yield* auth.stream;
  }

  @override
  Stream<String?> watchRoute(String uid) =>
      routes.putIfAbsent(uid, () => StreamController.broadcast()).stream;
  Future<void> close() async {
    await auth.close();
    for (final r in routes.values) {
      await r.close();
    }
  }
}

class OperationProbe extends StatefulWidget {
  const OperationProbe({
    super.key,
    required this.route,
    required this.onDispose,
  });
  final String route;
  final VoidCallback onDispose;
  @override
  State<OperationProbe> createState() => _OperationProbeState();
}

class _OperationProbeState extends State<OperationProbe> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text('Operate ${widget.route}');
}

void main() {
  testWidgets(
    'missing route blocks operation; change/revocation disposes old workspace',
    (tester) async {
      final service = RouteServiceFake();
      var disposed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: DriverRouteGate(
            service: service,
            builder: (_, id) =>
                OperationProbe(route: id, onDispose: () => disposed++),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Driver route assignment'), findsOneWidget);
      service.routes['a']!.add('r1');
      await tester.pumpAndSettle();
      expect(find.text('Operate r1'), findsOneWidget);
      service.routes['a']!.add('r2');
      await tester.pumpAndSettle();
      expect(disposed, 1);
      expect(find.text('Operate r2'), findsOneWidget);
      service.routes['a']!.add(null);
      await tester.pumpAndSettle();
      expect(disposed, 2);
      expect(find.text('Operate r2'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await service.close();
    },
  );

  testWidgets(
    'account switch, stream failure and resume require fresh authorization',
    (tester) async {
      final service = RouteServiceFake();
      await tester.pumpWidget(
        MaterialApp(
          home: DriverRouteGate(
            service: service,
            builder: (_, id) => Text('Operate $id'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      service.routes['a']!.add('r1');
      await tester.pumpAndSettle();
      service.uid = 'b';
      service.auth.add('b');
      await tester.pumpAndSettle();
      service.routes['a']!.add('old-account-route');
      await tester.pumpAndSettle();
      expect(find.textContaining('Operate'), findsNothing);
      service.routes['b']!.add('r2');
      await tester.pumpAndSettle();
      service.routes['b']!.addError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text('Operate r2'), findsNothing);
      service.routes['b']!.add('r2');
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Operate r2'), findsNothing);
      service.routes['b']!.add('r2');
      await tester.pumpAndSettle();
      expect(find.text('Operate r2'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await service.close();
    },
  );

  test('bus selector excludes other route IDs and published timetables', () {
    Bus bus(String id, String? route, {String type = 'vehicle'}) => Bus(
      id: id,
      routeNo: '1',
      routeId: route,
      hasRamp: false,
      lowFloor: false,
      occupancy: 'low',
      catalogueRecordType: type,
    );
    final buses = [
      bus('allowed', 'r1'),
      bus('other-direction', 'r2'),
      bus('unknown-route', null),
      bus('timetable', 'r1', type: 'published_timetable'),
    ];
    expect(DriverRouteService.eligibleBuses(buses, 'r1').map((b) => b.id), [
      'allowed',
    ]);
    expect(DriverRouteService.eligibleBuses(buses, ''), isEmpty);
  });
}
