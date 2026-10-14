import 'package:access_transit/logic/status_logic.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/enums/report_condition.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart'
    show AccessibilityStatus;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 14, 12);
  Report observation({
    String category = 'rampAccess',
    String text = 'Ramp Working',
    ReportCondition condition = ReportCondition.positive,
    Duration age = Duration.zero,
    String crowding = '',
  }) => Report(
    id: 'r',
    targetType: 'bus',
    targetId: 'bus',
    userId: 'owner',
    problemType: text,
    condition: condition,
    category: category,
    crowdingLevel: crowding,
    status: 'active',
    createdAt: now.subtract(age),
  );
  const bus = Bus(
    occupancy: 'low',
    id: 'bus',
    routeNo: '1',
    stops: [],
    hasRamp: true,
    lowFloor: true,
    rampOk: true,
  );

  test('crowding expires at 30 minutes, including legacy seats reports', () {
    for (final text in [
      'Seats Free',
      'Seats Occupied',
      'Wheelchair bay blocked',
    ]) {
      final r = observation(
        category: 'crowding',
        text: text,
        age: const Duration(minutes: 30),
      );
      expect(StatusLogic.isReportActive(r, currentTime: now), isTrue);
      expect(
        StatusLogic.isReportActive(
          r,
          currentTime: now.add(const Duration(seconds: 1)),
        ),
        isFalse,
      );
    }
    final legacy = observation(
      text: 'Seats Free',
      age: const Duration(minutes: 31),
    );
    expect(StatusLogic.isReportActive(legacy, currentTime: now), isFalse);
  });

  test('driver assistance and cleanliness use different windows', () {
    final driver = observation(
      category: 'driverAssistanceDenied',
      age: const Duration(hours: 3),
    );
    final clean = observation(
      category: 'cleanliness',
      age: const Duration(hours: 3),
    );
    expect(StatusLogic.isReportActive(driver, currentTime: now), isFalse);
    expect(StatusLogic.isReportActive(clean, currentTime: now), isTrue);
    expect(
      StatusLogic.isReportActive(
        clean,
        currentTime: now.add(const Duration(hours: 4)),
      ),
      isFalse,
    );
  });

  test('old working ramp expires but broken ramp remains unresolved until resolved', () {
    final good = observation(age: const Duration(days: 3));
    final broken = observation(
      text: 'Ramp broken',
      condition: ReportCondition.barrier,
      age: const Duration(days: 3),
    );
    expect(StatusLogic.isReportActive(good, currentTime: now), isFalse);
    expect(StatusLogic.isReportActive(broken, currentTime: now), isTrue);
    expect(StatusLogic.isReportFresh(broken, currentTime: now), isFalse);
    expect(StatusLogic.needsRecheck(broken, currentTime: now), isTrue);
    final result = StatusLogic.getBusStatus(bus, [broken], currentTime: now);
    expect(result.status, AccessibilityStatus.partial);
    expect(result.reasons.join(' '), contains('needs recheck'));
    expect(
      StatusLogic.isReportActive(
        broken.copyWith(status: 'resolved'),
        currentTime: now,
      ),
      isFalse,
    );
  });

  test('confirmation refreshes the check only with valid account evidence', () {
    final old = observation(
      text: 'Ramp broken',
      condition: ReportCondition.barrier,
      age: const Duration(days: 3),
    );
    final checked = old.copyWith(
      lastConfirmedAt: now,
      confirmedBy: ['commuter'],
    );
    expect(StatusLogic.lastCheckedAt(checked, currentTime: now), now);
    expect(StatusLogic.needsRecheck(checked, currentTime: now), isFalse);
    expect(
      StatusLogic.lastCheckedAt(
        old.copyWith(lastConfirmedAt: now),
        currentTime: now,
      ),
      old.createdAt,
    );
    expect(
      StatusLogic.lastCheckedAt(
        checked.copyWith(lastConfirmedAt: now.add(const Duration(hours: 1))),
        currentTime: now,
      ),
      old.createdAt,
    );
    expect(
      StatusLogic.lastCheckedAt(
        checked.copyWith(
          lastConfirmedAt: old.createdAt.subtract(const Duration(seconds: 1)),
        ),
        currentTime: now,
      ),
      old.createdAt,
    );
  });

  test('expired crowding does not override a still-fresh working ramp', () {
    final mixed = observation(
      crowding: 'high',
      age: const Duration(minutes: 31),
    );
    expect(
      StatusLogic.planningCondition(mixed, currentTime: now),
      ReportCondition.positive,
    );
    expect(
      StatusLogic.getBusStatus(bus, [mixed], currentTime: now).status,
      AccessibilityStatus.accessible,
    );
    expect(
      StatusLogic.getBusStatus(bus, [
        mixed,
      ], currentTime: now.subtract(const Duration(minutes: 2))).status,
      AccessibilityStatus.partial,
    );
  });

  test('expired crowding cannot clear a broken ramp in a mixed report', () {
    final mixed = observation(
      text: 'Ramp Broken',
      condition: ReportCondition.barrier,
      crowding: 'high',
      age: const Duration(days: 2),
    );
    expect(StatusLogic.isPersistentBarrier(mixed), isTrue);
    expect(
      StatusLogic.getBusStatus(bus, [mixed], currentTime: now).status,
      AccessibilityStatus.partial,
    );
    expect(
      StatusLogic.isReportActive(
        mixed.copyWith(falseCount: 3),
        currentTime: now,
      ),
      isFalse,
    );
    expect(
      StatusLogic.isReportActive(
        mixed.copyWith(isDemo: true),
        currentTime: now,
      ),
      isFalse,
    );
  });
}
