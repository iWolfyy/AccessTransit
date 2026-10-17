import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/logic/route_geometry.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/models/bus_location_model.dart';
import 'package:access_transit/models/enums/report_condition.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/models/station.dart';
import 'package:access_transit/models/user_model.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/services/user_service.dart';
import 'package:access_transit/widgets/accessibility_evidence_card.dart';
import 'package:access_transit/widgets/bus_ramp_observation.dart';
import 'package:access_transit/widgets/published_timetable_notice.dart';
import 'package:access_transit/widgets/route_progress_eta_text.dart';
import 'package:access_transit/widgets/selected_segment_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'registration_onboarding_localization_test.dart' show host, narrow;

final now = DateTime(2026, 10, 17, 12);
Widget screen(String lang, Widget child) =>
    host(lang, Scaffold(body: SingleChildScrollView(child: child)));
Report observation(
  String id, {
  bool broken = false,
  bool expired = false,
  int flags = 0,
}) => Report(
  id: id,
  targetType: 'bus',
  targetId: 'bus',
  category: 'rampAccess',
  problemType: broken ? 'Original Ramp Broken' : 'Original observation',
  condition: broken ? ReportCondition.barrier : ReportCondition.positive,
  status: 'active',
  userId: 'fixture-reporter',
  falseCount: flags,
  createdAt: now.subtract(Duration(hours: expired ? 72 : 1)),
  confirmedBy: const ['other-1', 'other-2'],
  lastConfirmedAt: now.subtract(Duration(hours: expired ? 71 : 1)),
);
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init();
    await AccessibilityPreferencesService.instance.setHighContrast(true);
    // No Firebase app is initialized: UserService uses its in-memory fixture cache.
    await UserService().createUser(
      const UserModel(
        uid: 'fixture-reporter',
        name: 'Community member',
        email: 'fixture@example.com',
      ),
    );
  });
  for (final lang in ['en', 'si', 'ta']) {
    testWidgets(
      'evidence $lang preserves names and unresolved barriers at 200 percent',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        await t.pumpWidget(
          screen(
            lang,
            AccessibilityEvidenceCard(
              reports: [
                observation('old', broken: true, expired: true),
                observation('recent'),
                observation('hidden', flags: 5),
              ],
              busId: 'bus',
              origin: 'a',
              destination: 'b',
              strictStopIds: true,
              currentTime: now,
              initiallyExpanded: true,
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.text(l.evidenceRecheckSummary), findsOneWidget);
        expect(find.text('Original observation'), findsOneWidget);
        expect(find.text('Original Ramp Broken'), findsOneWidget);
        expect(
          find.text(l.evidenceReporter('Community member')),
          findsNWidgets(2),
        );
        expect(find.text(l.evidenceConfirmers(2)), findsNWidgets(2));
        expect(find.text(l.evidenceRecheckUnknown), findsOneWidget);
        expect(find.text(l.evidenceEmpty), findsNWidgets(3));
        expect(find.textContaining('fixture-reporter'), findsNothing);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'ramp $lang distinguishes equipment, expired positive and old broken check',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        for (final broken in [false, true]) {
          final bus = Bus(
            id: 'bus',
            routeNo: '17',
            hasRamp: true,
            lowFloor: true,
            occupancy: 'unknown',
            rampOk: !broken,
            rampCheckedAt: now.subtract(const Duration(days: 3)),
            rampCheckedBy: 'private-driver',
          );
          await t.pumpWidget(
            screen(
              lang,
              BusRampObservation(
                key: ValueKey(broken),
                bus: bus,
                currentTime: now,
              ),
            ),
          );
          await t.pumpAndSettle();
          expect(
            find.text(broken ? l.rampBrokenUnresolved : l.rampNewCheck),
            findsOneWidget,
          );
          expect(find.text(l.rampCapability(l.rampEquipped)), findsOneWidget);
          await t.tap(find.text(l.rampTitle));
          await t.pumpAndSettle();
          expect(find.text(l.rampSource(l.rampOperatorSource)), findsOneWidget);
          expect(find.text(l.rampBarrierDisclosure), findsOneWidget);
          expect(find.textContaining('private-driver'), findsNothing);
          expect(t.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'map $lang has honest unavailable/static/current marker labels',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        await t.pumpWidget(
          screen(lang, const SelectedSegmentMap(stations: [])),
        );
        expect(find.text(l.mapMissingCoordinates), findsOneWidget);
        final stations = [
          const Station(
            id: 's',
            name: 'Original Stop',
            lat: 6.9,
            lng: 79.8,
            hasElevator: false,
            hasRamp: false,
          ),
        ];
        await t.pumpWidget(
          screen(lang, SelectedSegmentMap(stations: stations)),
        );
        await t.pumpAndSettle();
        expect(find.text(l.mapNoRoadGeometry), findsOneWidget);
        expect(find.text(l.mapTileRetry), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is Icon && w.semanticLabel == l.mapCurrentBus,
          ),
          findsNothing,
        );
        final gps = BusLocationModel(
          busId: 'bus',
          tripId: 'run',
          driverId: 'driver',
          latitude: 6.9,
          longitude: 79.8,
          timestamp: now,
        );
        await t.pumpWidget(
          screen(lang, SelectedSegmentMap(stations: stations, location: gps)),
        );
        await t.pumpAndSettle();
        expect(
          find.byWidgetPredicate(
            (w) => w is Icon && w.semanticLabel == l.mapCurrentBus,
          ),
          findsOneWidget,
        );
        expect(find.byTooltip('Original Stop'), findsOneWidget);
        expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
        expect(find.text(l.mapUpdatedAt(now.toString())), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'timetable and ETA $lang retain source, uncertainty and original target',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        const source = 'https://example.invalid/original-timetable';
        const bus = Bus(
          id: 'published',
          routeNo: '17',
          hasRamp: false,
          lowFloor: false,
          occupancy: 'unknown',
          catalogueRecordType: 'published_timetable',
          sourceUrl: source,
        );
        final estimate = RouteProgressEstimate(
          now,
          now.subtract(const Duration(minutes: 2)),
          now.add(const Duration(minutes: 3)),
          1000,
          'geometry-v1',
        );
        await t.pumpWidget(
          screen(
            lang,
            Column(
              children: [
                const PublishedTimetableNotice(bus: bus),
                RouteProgressEtaText(
                  estimate: estimate,
                  target: 'Original Target',
                ),
              ],
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.text(l.timetableUnassigned), findsOneWidget);
        expect(find.text(l.timetableUnknownDisclosure), findsOneWidget);
        expect(find.text(l.timetableSource(source)), findsOneWidget);
        expect(find.textContaining('Original Target'), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }
}
