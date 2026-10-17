import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/enums/report_condition.dart';
import 'package:access_transit/models/enums/user_role.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/models/user_model.dart';
import 'package:access_transit/screens/journey/route_details_screen.dart';
import 'package:access_transit/services/user_service.dart';
import 'package:access_transit/widgets/accessibility_evidence_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 14, 10);
  Report report({
    String category = 'rampAccess',
    String targetType = 'bus',
    String targetId = 'test-bus',
    DateTime? createdAt,
    DateTime? confirmedAt,
    List<String> accounts = const [],
    int count = 0,
  }) => Report(
    id: 'evidence-report',
    targetType: targetType,
    targetId: targetId,
    category: category,
    problemType: 'Ramp Working',
    condition: ReportCondition.positive,
    status: 'active',
    createdAt: createdAt ?? now.subtract(const Duration(hours: 1)),
    lastConfirmedAt: confirmedAt,
    confirmedBy: accounts,
    confirmCount: count,
    userId: 'reporter-account',
  );

  Future<void> show(WidgetTester tester, List<Report> reports) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AccessibilityEvidenceCard(
              reports: reports,
              initiallyExpanded: true,
              busId: 'test-bus',
              origin: 'origin-stop',
              destination: 'destination-stop',
              currentTime: now,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'no evidence shows Unknown for each condition without verification claims',
    (tester) async {
      await show(tester, []);
      expect(find.text('Unknown — no observation available'), findsNWidgets(4));
      expect(find.textContaining('verified by driver'), findsNothing);
      expect(find.text('Accessibility Verified'), findsNothing);
    },
  );

  testWidgets(
    'confirmation shows the observation, names and actual recorded times',
    (tester) async {
      await UserService().createUser(
        const UserModel(
          uid: 'reporter-account',
          name: 'Alice',
          email: 'alice@example.com',
        ),
      );
      await UserService().createUser(
        const UserModel(
          uid: 'confirming-account',
          name: 'Bob',
          email: 'bob@example.com',
          role: UserRole.passenger,
        ),
      );
      await show(tester, [
        report(
          confirmedAt: now.subtract(const Duration(minutes: 15)),
          accounts: ['confirming-account'],
          count: 1,
        ),
      ]);
      expect(find.text('Ramp Working'), findsOneWidget);
      expect(find.text('Reported by: Alice'), findsOneWidget);
      expect(find.text('Confirmed by: 1 community member'), findsOneWidget);
      expect(find.text('Reported at: 2026-10-14 09:00 AM'), findsOneWidget);
      expect(
        find.text('Last confirmation recorded at: 2026-10-14 09:45 AM'),
        findsOneWidget,
      );
      expect(
        find.text('Positive — community-confirmed observation'),
        findsOneWidget,
      );
      // A ramp report does not verify paths or driver assistance.
      expect(find.text('Unknown — no observation available'), findsNWidgets(3));
    },
  );

  testWidgets(
    'a reporter-set confirmation timestamp without confirming identities is unverified',
    (tester) async {
      await show(tester, [report(confirmedAt: now, count: 10)]);
      expect(
        find.text('Positive reported — verification unknown'),
        findsOneWidget,
      );
      expect(find.text('Confirmation time: Unknown'), findsOneWidget);
      expect(find.textContaining('community-confirmed'), findsNothing);
    },
  );

  testWidgets(
    'confirmations without a timestamp cannot claim current verification',
    (tester) async {
      await show(tester, [
        report(accounts: ['missing-profile']),
      ]);
      expect(
        find.text('Positive reported — verification unknown'),
        findsOneWidget,
      );
      expect(find.text('Confirmation time: Unknown'), findsOneWidget);
    },
  );

  testWidgets('future confirmation time cannot claim verification', (
    tester,
  ) async {
    await show(tester, [
      report(
        confirmedAt: now.add(const Duration(minutes: 1)),
        accounts: ['confirming-account'],
      ),
    ]);
    expect(find.textContaining('community-confirmed'), findsNothing);
    expect(find.text('Confirmation time: Unknown'), findsOneWidget);
  });

  testWidgets(
    'expired observation is evidence of the past, not current verification',
    (tester) async {
      await show(tester, [
        report(
          createdAt: now.subtract(const Duration(days: 2)),
          confirmedAt: now.subtract(const Duration(hours: 25)),
          accounts: ['confirming-account'],
        ),
      ]);
      expect(find.text('Unknown — latest observation expired'), findsOneWidget);
      expect(
        find.textContaining('community-confirmed observation'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'old broken ramp shows unresolved state and last check, not verification',
    (tester) async {
      await show(tester, [
        report(createdAt: now.subtract(const Duration(days: 3))).copyWith(
          problemType: 'Ramp broken',
          condition: ReportCondition.barrier,
        ),
      ]);
      expect(
        find.text(
          'Unresolved barrier — needs recheck; current condition unknown',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Last checked:'), findsOneWidget);
      expect(find.textContaining('Recheck due:'), findsOneWidget);
      expect(
        find.text('Barrier — community-confirmed observation'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'other buses and unrelated stops do not verify the selected journey',
    (tester) async {
      await show(tester, [
        report(targetId: 'other-bus'),
        report(targetType: 'station', targetId: 'other-stop'),
      ]);
      expect(find.text('Ramp Working'), findsNothing);
      expect(find.text('Unknown — no observation available'), findsNWidgets(4));
    },
  );

  testWidgets('a seats report does not verify a ramp', (tester) async {
    await show(tester, [
      report(category: 'crowding').copyWith(problemType: 'Seats Free'),
    ]);
    expect(find.text('Seats Free'), findsNothing);
    expect(find.text('Unknown — no observation available'), findsNWidgets(4));
  });

  testWidgets(
    'route details excludes demonstration reports from condition evidence',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RouteDetailsScreen(
            origin: 'st_fort',
            destination: 'st_pettah',
            bus: Bus(
              id: 'bus_138_nd4521',
              routeNo: '138',
              hasRamp: true,
              lowFloor: true,
              occupancy: 'low',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unknown — no observation available'), findsNWidgets(4));
      expect(
        find.text('Operational ramp verified by driver today'),
        findsNothing,
      );
      expect(find.text('Accessibility Verified'), findsNothing);
    },
  );
}
