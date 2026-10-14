import 'package:access_transit/logic/status_logic.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/enums/report_condition.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart'
    show AccessibilityStatus;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 14, 10);
  const bus = Bus(
    id: 'bus',
    routeNo: '138',
    stops: ['stop'],
    hasRamp: true,
    lowFloor: true,
    rampOk: true,
    occupancy: 'low',
  );

  Report report(
    String text, {
    String subCategory = '',
    String target = 'bus',
    ReportCondition? condition,
    String crowding = '',
    String severity = 'minor',
  }) => Report(
    id: text,
    targetType: target,
    targetId: target == 'bus' ? 'bus' : 'stop',
    problemType: text,
    subCategory: subCategory,
    condition: condition,
    crowdingLevel: crowding,
    severity: severity,
    status: 'active',
    createdAt: now,
    userId: 'commuter',
  );

  BusStatusResult status(List<Report> reports, {Bus vehicle = bus}) =>
      StatusLogic.getBusStatus(vehicle, reports, currentTime: now);

  const positives = {
    'ramp_working': 'Ramp Working',
    'seats_available': 'Seats Free',
    'clean_vehicle': 'Clean & Safe',
    'elevator_ok': 'Elevator Working',
    'ramp_ok': 'Ramp Clear',
    'tactile_ok': 'Tiles Intact',
    'shelter_ok': 'Shelter Good',
  };
  for (final entry in positives.entries) {
    test('${entry.value} is a positive observation, not a warning', () {
      expect(ReportCondition.fromOptionId(entry.key), ReportCondition.positive);
      final observation = report(entry.value);
      final result = status([observation]);
      expect(result.status, AccessibilityStatus.accessible);
      expect(result.relevantReports, [observation]);
      expect(result.reasons.first, contains('Positive condition'));
    });
  }

  test('positive station observation does not mark its bus route Warning', () {
    final result = status([report('Elevator Working', target: 'station')]);
    expect(result.status, AccessibilityStatus.accessible);
  });

  test('legacy combined crowding text retains its positive subcategory', () {
    final observation = report(
      'Crowding: Moderate • Ramp Working',
      subCategory: 'Ramp Working',
    );
    expect(status([observation]).status, AccessibilityStatus.accessible);
    expect(
      status([report('Crowding: Low Crowd • Seats Free')]).status,
      AccessibilityStatus.accessible,
    );
  });

  test('known minor barrier still warns; severity does not imply positive', () {
    expect(
      status([report('Dirty / Odor')]).status,
      AccessibilityStatus.partial,
    );
  });

  test('positive report cannot cancel a simultaneous barrier', () {
    final result = status([report('Ramp Working'), report('Ramp Broken')]);
    expect(result.status, AccessibilityStatus.partial);
    expect(result.reasons.first, contains('Ramp Broken'));
    expect(result.relevantReports.length, 2);
  });

  test('positive report cannot override an operator-marked broken ramp', () {
    final result = status([
      report('Ramp Working'),
    ], vehicle: bus.copyWith(rampOk: false));
    expect(result.status, AccessibilityStatus.partial);
  });

  test('working ramp on packed bus remains Warning with legacy reports', () {
    expect(
      status([
        report(
          'Crowding: Crowded / Packed • Ramp Working',
          subCategory: 'Ramp Working',
        ),
      ]).status,
      AccessibilityStatus.partial,
    );
  });

  test(
    'structured high crowding remains a barrier with a positive condition',
    () {
      final observation = report(
        'Ramp Working',
        condition: ReportCondition.positive,
        crowding: 'high',
      );
      expect(observation.effectiveCondition, ReportCondition.barrier);
      final result = status([observation]);
      expect(result.status, AccessibilityStatus.partial);
      expect(result.reasons.first, contains('crowding: high'));
    },
  );

  test(
    'unrecognized observation has an Unknown status, not Safe or Warning',
    () {
      final result = status([report('Condition could not be checked')]);
      expect(result.status, AccessibilityStatus.unknown);
      expect(result.statusLabel, 'Unknown');
      expect(result.reasons.first, contains('Condition unknown'));
    },
  );

  test('known positive observation does not clear an unrelated unknown observation', () {
    final result = status([report('Seats Free'), report('New condition type')]);
    expect(result.status, AccessibilityStatus.unknown);
  });

  test('unknown report does not hide a known barrier', () {
    expect(
      status([report('New condition type'), report('Path Blocked')]).status,
      AccessibilityStatus.partial,
    );
  });

  test('explicit condition survives storage and copy even when display text changes', () {
    final observation = report(
      'Localized display label',
      condition: ReportCondition.positive,
      crowding: 'low',
    );
    final restored = Report.fromMap(observation.toMap(), id: observation.id);
    expect(restored.condition, ReportCondition.positive);
    expect(restored.crowdingLevel, 'low');
    expect(
      restored.copyWith(confirmCount: 1).effectiveCondition,
      ReportCondition.positive,
    );
    expect(status([restored]).status, AccessibilityStatus.accessible);
  });

  test('unrecognized stored condition is explicitly Unknown', () {
    final observation = Report.fromMap({
      ...report('Ramp Working').toMap(),
      'condition': 'future-type',
    });
    expect(observation.effectiveCondition, ReportCondition.unknown);
  });

  test('unknown option ids do not silently become positive observations', () {
    expect(ReportCondition.fromOptionId('new-option'), ReportCondition.unknown);
  });
}
