import 'dart:async';

import 'package:access_transit/data/seed_data.dart';
import 'package:access_transit/logic/status_logic.dart';
import 'package:access_transit/models/enums/report_condition.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/screens/community/community_screen.dart';
import 'package:access_transit/screens/community/report_details_screen.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:access_transit/services/transit_catalogue.dart';
import 'package:access_transit/widgets/accessibility_evidence_card.dart';
import 'package:access_transit/widgets/evidence_refresh.dart';
import 'package:access_transit/widgets/live_accessibility_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 10, 15, 10);
  late DateTime now;
  setUp(() => now = start);
  tearDown(FirestoreService.installCatalogueFixtures);

  Report report({bool broken = false, bool crowding = false}) => Report(
    id: 'clock-${broken ? 'barrier' : 'positive'}',
    targetType: 'bus',
    targetId: 'clock-bus',
    userId: 'observer',
    category: crowding ? 'crowding' : 'rampAccess',
    problemType: broken ? 'Ramp Broken' : 'Ramp Working',
    condition: broken ? ReportCondition.barrier : ReportCondition.positive,
    status: 'active',
    createdAt: start.subtract(
      crowding
          ? const Duration(minutes: 29, seconds: 59)
          : const Duration(hours: 23, minutes: 59, seconds: 59),
    ),
  );

  Future<void> show(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EvidenceClock(
          now: () => now,
          child: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('visible positive evidence expires without a stream event', (
    tester,
  ) async {
    await show(
      tester,
      AccessibilityEvidenceCard(
        reports: [report()],
        busId: 'clock-bus',
        origin: 'a',
        destination: 'b',
      ),
    );
    expect(find.textContaining('Positive reported'), findsOneWidget);
    now = start.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    // Existing policy includes the exact end instant.
    expect(find.textContaining('Positive reported'), findsOneWidget);
    now = now.add(const Duration(microseconds: 1));
    await tester.pump(const Duration(microseconds: 1));
    expect(find.textContaining('latest observation expired'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('expired structural barrier stays visible and needs recheck', (
    tester,
  ) async {
    final barrier = report(broken: true);
    await show(
      tester,
      AccessibilityEvidenceCard(
        reports: [barrier],
        busId: 'clock-bus',
        origin: 'a',
        destination: 'b',
      ),
    );
    now = start.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(find.textContaining('Unresolved barrier'), findsOneWidget);
    expect(StatusLogic.isReportActive(barrier, currentTime: now), isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'live panel expires a received observation while stream stays open',
    (tester) async {
      final updates = StreamController<List<Report>>();
      await show(
        tester,
        LiveAccessibilityPanel(
          busId: 'clock-bus',
          origin: 'A',
          destination: 'B',
          reportsStream: updates.stream,
        ),
      );
      updates.add([report()]);
      await tester.pumpAndSettle();
      expect(find.text('Working reported'), findsOneWidget);
      now = start.add(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Working reported'), findsNothing);
      expect(find.text('Unknown'), findsNWidgets(3));
      await tester.pumpWidget(const SizedBox());
      unawaited(updates.close());
    },
  );

  testWidgets(
    'community crowding moves to past reports without a backend event',
    (tester) async {
      final r = report(crowding: true);
      await FirestoreService(reportWriter: (_) async {}).createReport(r);
      await tester.pumpWidget(
        MaterialApp(
          home: EvidenceClock(now: () => now, child: const CommunityScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Resolved & Past Reports'), findsNothing);
      now = start.add(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Resolved & Past Reports'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'accessible results drop expired ramp checks without bus updates',
    (tester) async {
      TransitCatalogue.installFixtures({
        'buses': {
          for (final bus in SeedData.sampleBuses)
            bus.id: {
              ...bus.toMap(),
              'rampOk': true,
              'rampCheckedAt': start.subtract(
                const Duration(hours: 23, minutes: 59, seconds: 59),
              ),
              'rampCheckedBy': 'approved-operator',
              'catalogueSource': 'operator_catalogue',
            },
        },
        'routes': {
          for (final r in SeedData.sampleRoutes)
            r.id: {...r.toMap(), 'catalogueSource': 'operator_catalogue'},
        },
        'stations': {
          for (final s in SeedData.colomboStations)
            s.id: {
              ...s.toMap(),
              'hasRamp': true,
              'stepFreeAccess': true,
              'catalogueSource': 'operator_catalogue',
            },
        },
      });
      await tester.pumpWidget(
        MaterialApp(
          home: EvidenceClock(
            now: () => now,
            child: const RouteResultsScreen(
              fromStationId: 'st_pettah',
              wheelchairAccessRequired: true,
              stepFreeOnly: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Accessible (0)'), findsNothing);
      now = start.add(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Accessible (0)'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('report details expires without another report update', (
    tester,
  ) async {
    final updates = StreamController<Report?>();
    await tester.pumpWidget(
      MaterialApp(
        home: EvidenceClock(
          now: () => now,
          child: ReportDetailsScreen(
            report: report(crowding: true),
            reportUpdates: updates.stream,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Active Transit Alert'), findsOneWidget);
    now = start.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Past Report (Expired)'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    unawaited(updates.close());
  });

  testWidgets(
    'resume immediately rechecks evidence after time passes in background',
    (tester) async {
      final r = report(crowding: true);
      var builds = 0;
      await show(
        tester,
        EvidenceRefresh(
          reports: [r],
          builder: (_, time) {
            builds++;
            return Text(StatusLogic.freshnessLabel(r, currentTime: time));
          },
        ),
      );
      expect(find.text('Recent observation'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final before = builds;
      now = start.add(const Duration(hours: 1));
      await tester.pump(const Duration(hours: 1));
      expect(builds, before);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('Expired or unavailable'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'new confirmation rearms the deadline; disposal cancels the timer',
    (tester) async {
      var r = report(crowding: true);
      Widget content() => EvidenceRefresh(
        reports: [r],
        builder: (_, time) => Text(
          StatusLogic.isReportFresh(r, currentTime: time) ? 'fresh' : 'expired',
        ),
      );
      await show(tester, content());
      r = r.copyWith(lastConfirmedAt: start, confirmedBy: ['second-observer']);
      await show(tester, content());
      now = start.add(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('fresh'), findsOneWidget);
      now = start.add(const Duration(minutes: 30, microseconds: 1));
      await tester.pump(const Duration(minutes: 30));
      expect(find.text('expired'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(days: 2));
      expect(tester.takeException(), isNull);
    },
  );
}
