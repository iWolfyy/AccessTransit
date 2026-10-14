import 'package:access_transit/logic/status_logic.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/enums/report_condition.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/models/station.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart'
    show AccessibilityStatus;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 14, 10);
  const bus = Bus(
    id: 'bus',
    routeNo: '138',
    stops: ['before', 'boarding', 'passing', 'destination', 'after'],
    hasRamp: true,
    lowFloor: true,
    rampOk: true,
    occupancy: 'low',
  );
  Station station(String id, {bool ramp = true, bool? access}) => Station(
    id: id,
    name: id,
    hasElevator: false,
    hasRamp: ramp,
    lat: 0,
    lng: 0,
    stepFreeAccess: access,
  );
  final stations = {
    'boarding': station('boarding'),
    'destination': station('destination'),
  };
  Report issue(String id, {String target = 'station'}) => Report(
    id: 'issue-$id',
    targetType: target,
    targetId: id,
    problemType: 'Path Blocked',
    condition: ReportCondition.barrier,
    status: 'active',
    createdAt: now,
    userId: 'rider',
  );
  BusStatusResult assess({
    Bus vehicle = bus,
    List<Report> reports = const [],
    Map<String, Station>? stops,
    bool wheelchair = true,
    bool stepFree = false,
  }) => StatusLogic.getBusStatus(
    vehicle,
    reports,
    currentTime: now,
    stationsMap: stops ?? stations,
    fromStationId: 'boarding',
    toStationId: 'destination',
    wheelchairAccessRequired: wheelchair,
    stepFreeOnly: stepFree,
  );

  test(
    'working ramp and accessible endpoints satisfy wheelchair requirements',
    () {
      expect(assess().status, AccessibilityStatus.accessible);
    },
  );
  test('broken ramp never satisfies wheelchair requirements even on a low-floor bus', () {
    expect(
      assess(vehicle: bus.copyWith(rampOk: false)).status,
      AccessibilityStatus.notAccessible,
    );
  });
  test('low floor alone does not satisfy a wheelchair ramp requirement', () {
    expect(
      assess(vehicle: bus.copyWith(hasRamp: false)).status,
      AccessibilityStatus.notAccessible,
    );
  });
  test('bus access alone does not establish destination access', () {
    final result = assess(stops: {'boarding': station('boarding')});
    expect(result.status, AccessibilityStatus.unknown);
    expect(result.reasons.join(' '), contains('destination'));
  });
  test(
    'an explicitly inaccessible endpoint excludes an otherwise accessible bus',
    () {
      expect(
        assess(
          stops: {
            ...stations,
            'destination': station('destination', access: false),
          },
        ).status,
        AccessibilityStatus.notAccessible,
      );
    },
  );
  test(
    'missing facility flags are unknown rather than proof of inaccessibility',
    () {
      expect(
        assess(
          stops: {...stations, 'boarding': station('boarding', ramp: false)},
        ).status,
        AccessibilityStatus.unknown,
      );
    },
  );
  test('fresh positive path observation supplies access information for an unknown stop', () {
    final observation = issue('boarding').copyWith(
      condition: ReportCondition.positive,
      problemType: 'Ramp Clear',
      category: 'rampAccess',
    );
    expect(
      assess(
        stops: {...stations, 'boarding': station('boarding', ramp: false)},
        reports: [observation],
      ).status,
      AccessibilityStatus.accessible,
    );
  });
  test(
    'step-free checks both endpoints, not only low-floor bus capability',
    () {
      expect(
        assess(
          wheelchair: false,
          stepFree: true,
          stops: {
            ...stations,
            'destination': station('destination', access: false),
          },
        ).status,
        AccessibilityStatus.notAccessible,
      );
    },
  );
  test('an operational ramp can provide step-free boarding without a low-floor bus', () {
    expect(
      assess(
        wheelchair: false,
        stepFree: true,
        vehicle: bus.copyWith(lowFloor: false),
      ).status,
      AccessibilityStatus.accessible,
    );
  });
  test('bus without low floor or operational ramp cannot meet step-free requirements', () {
    expect(
      assess(
        wheelchair: false,
        stepFree: true,
        vehicle: bus.copyWith(lowFloor: false, hasRamp: false),
      ).status,
      AccessibilityStatus.notAccessible,
    );
  });
  test('station issues before, after, or passed through do not affect boarding/alighting', () {
    final result = assess(
      reports: [issue('before'), issue('passing'), issue('after')],
    );
    expect(result.status, AccessibilityStatus.accessible);
    expect(result.relevantReports, isEmpty);
  });
  for (final target in ['boarding', 'destination']) {
    test('barrier at $target affects this passenger journey', () {
      expect(
        assess(reports: [issue(target)]).status,
        AccessibilityStatus.partial,
      );
    });
  }
  test('vehicle reports still apply to the passenger segment', () {
    expect(
      assess(reports: [issue('bus', target: 'bus')]).status,
      AccessibilityStatus.partial,
    );
  });
  test('explicit stop assessment survives serialization and copies', () {
    final blocked = station('boarding', access: false);
    final restored = Station.fromMap(blocked.toMap(), id: blocked.id);
    expect(restored.stepFreeAccess, false);
    expect(restored.copyWith(name: 'Updated name').stepFreeAccess, false);
  });
  test('a legacy seating report does not establish step-free stop access', () {
    final seating = Report(
      id: 'seat-report',
      targetType: 'station',
      targetId: 'boarding',
      problemType: 'Seats Free',
      status: 'active',
      createdAt: now,
      userId: 'rider',
    );
    expect(
      assess(
        stops: {...stations, 'boarding': station('boarding', ramp: false)},
        reports: [seating],
      ).status,
      AccessibilityStatus.unknown,
    );
  });
}
