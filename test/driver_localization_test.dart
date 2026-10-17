import 'dart:async';

import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/l10n/driver_presentation.dart';
import 'package:access_transit/logic/delay_eta_logic.dart';
import 'package:access_transit/models/service_run.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/services/operator_access_service.dart';
import 'package:access_transit/widgets/driver_route_gate.dart';
import 'package:access_transit/widgets/driver_delay_sheet.dart';
import 'package:access_transit/widgets/driver_run_controls.dart';
import 'package:access_transit/widgets/driver_vehicle_status.dart';
import 'package:access_transit/widgets/operator_access_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'driver_route_gate_test.dart' show RouteServiceFake;

class ApprovalFixture extends OperatorAccessService {
  final approval = StreamController<bool>.broadcast();
  @override
  Stream<String?> get userIds => Stream.value('driver');
  @override
  Stream<bool> watchApproval(String uid) => approval.stream;
}

Widget host(String lang, Widget child) => MaterialApp(
  locale: Locale(lang),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (c, w) => MediaQuery(
    data: MediaQuery.of(c).copyWith(textScaler: const TextScaler.linear(2)),
    child: w!,
  ),
  home: child,
);

final departure = DateTime.utc(2026, 10, 17, 4, 30);
ServiceRun run(
  String id, {
  String status = 'scheduled',
  bool handover = false,
}) => ServiceRun(
  id: id,
  busId: 'bus',
  routeId: 'route',
  routeNo: '138',
  serviceDate: '2026-10-17',
  plannedDepartureAt: departure,
  latestStartAt: departure.add(const Duration(minutes: 30)),
  stopTimes: const {},
  status: status,
  handoverPending: handover,
);

void narrow(WidgetTester t) {
  t.view.physicalSize = const Size(320, 1200);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init();
    await AccessibilityPreferencesService.instance.setHighContrast(false);
  });

  for (final lang in ['en', 'si', 'ta']) {
    testWidgets(
      'ETA wording $lang retains unavailable, scheduled and live distinctions',
      (t) async {
        late BuildContext c;
        final l = lookupAppLocalizations(Locale(lang));
        await t.pumpWidget(
          host(
            lang,
            Scaffold(
              body: Builder(
                builder: (context) {
                  c = context;
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        BusArrivalEtaResult estimate(String text, int minutes) =>
            BusArrivalEtaResult(
              busId: 'bus',
              routeNo: '138',
              targetStopId: 'stop',
              targetStopName: 'Original stop',
              scheduledArrival: departure,
              scheduledArrivalStr: '10:00 AM',
              estimatedArrival: departure,
              estimatedArrivalStr: '10:00 AM',
              delayMinutes: 0,
              delayType: DelayType.scheduled,
              delayLabel: 'Scheduled',
              delayReason: null,
              addedDelayMinutes: 0,
              countdownMinutes: minutes,
              countdownText: text,
              isLive: false,
              liveStatusDescription: '',
              stopsTimeline: const [],
            );
        expect(
          c.driverCountdown(estimate('ETA unavailable', 10)),
          l.driverEtaUnavailable,
        );
        expect(
          c.driverCountdown(estimate('Scheduled time passed', -5)),
          l.driverSchedulePassed,
        );
        expect(
          c.driverCountdown(estimate('Scheduled for 10:00 AM', 5)),
          l.driverScheduledFor(c.driverArrivalTime(departure)),
        );
        expect(
          c.driverCountdown(estimate('Arriving now', 0)),
          l.driverArrivingNow,
        );
        expect(
          c.driverCountdown(estimate('Arriving in 5 mins', 5)),
          l.driverArrivingMinutes(5),
        );
        expect(
          c.driverCountdown(estimate('Arriving in 1h 5m', 65)),
          l.driverArrivingHours(1, 5),
        );
        expect(
          c.driverCountdown(estimate('Departed 5 mins ago', -5)),
          l.driverDepartedAgo(5),
        );
        expect(
          c.driverCountdown(estimate('future-contract-value', 5)),
          l.driverEtaUnavailable,
        );
      },
    );

    testWidgets(
      'delay sheet $lang preserves stable reason and duration across locale changes',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        String? reason;
        int? minutes;
        Widget sheet() => Scaffold(
          body: DriverDelaySheet(
            onSubmit: (r, m) {
              reason = r;
              minutes = m;
            },
          ),
        );
        await t.pumpWidget(host(lang, sheet()));
        await t.pumpAndSettle();
        expect(find.text(l.driverDelayTitle), findsOneWidget);
        await t.tap(find.text(l.driverMinuteOption(10)));
        await t.pumpAndSettle();
        await t.ensureVisible(find.text(l.driverRain));
        await t.tap(find.text(l.driverRain));
        await t.pumpAndSettle();
        final other = lang == 'en' ? 'ta' : 'en';
        final otherLabels = lookupAppLocalizations(Locale(other));
        await t.pumpWidget(host(other, sheet()));
        await t.pumpAndSettle();
        await t.ensureVisible(find.text(otherLabels.driverBroadcastDelay(10)));
        await t.tap(find.text(otherLabels.driverBroadcastDelay(10)));
        await t.pumpAndSettle();
        expect(reason, 'Heavy Rain / Flooding');
        expect(minutes, 10);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'late-start dialog $lang collects reason and preserves cancellation at 320dp/200%',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        String? result;
        await t.pumpWidget(
          host(
            lang,
            Scaffold(
              body: Builder(
                builder: (c) => TextButton(
                  onPressed: () async {
                    result = await showDialog<String>(
                      context: c,
                      builder: (_) =>
                          DriverLateStartDialog(controller: controller),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await t.tap(find.text('open'));
        await t.pumpAndSettle();
        expect(find.text(l.driverLateHelp), findsOneWidget);
        await t.enterText(find.byType(TextField), '  Original driver reason  ');
        await t.ensureVisible(find.text(l.driverContinue));
        await t.tap(find.text(l.driverContinue));
        await t.pumpAndSettle();
        expect(result, 'Original driver reason');
        await t.tap(find.text('open'));
        await t.pumpAndSettle();
        await t.tap(find.text(l.profileCancel));
        await t.pumpAndSettle();
        expect(result, isNull);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'driver controls $lang keep exact window, busy and stop actions at 320dp/200%',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        var starts = 0, stops = 0;
        Future<void> render(
          DateTime now, {
          bool active = false,
          bool busy = false,
          ServiceRun? selected,
        }) async {
          await t.pumpWidget(
            host(
              lang,
              Scaffold(
                body: SingleChildScrollView(
                  child: DriverTripControlCard(
                    active: active,
                    initializing: false,
                    busy: busy,
                    selectedRun: selected ?? run('r'),
                    error: null,
                    publicationStatus:
                        'Pending GPS upload; coordinates are local',
                    duration: const Duration(seconds: 9),
                    routeNumber: '138',
                    now: now,
                    onStart: () => starts++,
                    onStop: () => stops++,
                  ),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
        }

        await render(
          departure.subtract(const Duration(minutes: 5, seconds: 1)),
        );
        expect(
          t.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        await render(departure.subtract(const Duration(minutes: 5)));
        await t.tap(find.text(l.driverStart));
        expect(starts, 1);
        await render(departure.add(const Duration(minutes: 30)));
        expect(
          t.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull,
        );
        await render(departure.add(const Duration(minutes: 30, seconds: 1)));
        expect(
          t.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        await render(departure, busy: true);
        expect(
          t.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        await render(departure, active: true);
        expect(
          find.text(l.driverActiveSummary(l.driverGpsPending, '00:09')),
          findsOneWidget,
        );
        expect(find.textContaining(l.driverGpsAcknowledged), findsNothing);
        await t.tap(find.text(l.driverStop));
        expect(stops, 1);
        await render(
          departure,
          selected: run('handover', status: 'boarding', handover: true),
        );
        expect(find.text(l.operationsResume), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'dated runs $lang preserve IDs, Colombo time and unavailable states',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        String? selected = 'r';
        Future<void> render({
          List<ServiceRun>? runs,
          String? error,
          bool active = false,
        }) async {
          await t.pumpWidget(
            host(
              lang,
              Scaffold(
                body: SingleChildScrollView(
                  child: DriverDatedDepartureCard(
                    runs:
                        runs ??
                        [run('r'), run('other', status: 'future-state')],
                    busId: 'bus',
                    selectedRunId: selected,
                    active: active,
                    initializing: false,
                    onSelected: (v) => selected = v,
                    error: error,
                  ),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
        }

        await render();
        expect(
          find.text(l.driverRunWindow('2026-10-17 09:55', '2026-10-17 10:30')),
          findsOneWidget,
        );
        await t.tap(find.byType(DropdownButtonFormField<String>));
        await t.pumpAndSettle();
        await t.tap(
          find
              .text(l.driverRunOption('2026-10-17 10:00', l.driverUnknownState))
              .last,
        );
        await t.pumpAndSettle();
        expect(selected, 'other');
        await render(active: true);
        expect(
          t
              .widget<DropdownButtonFormField<String>>(
                find.byType(DropdownButtonFormField<String>),
              )
              .onChanged,
          isNull,
        );
        selected = null;
        await render(runs: [], error: 'Connect to verify dated departures.');
        expect(find.text(l.driverVerifyRuns), findsOneWidget);
        expect(find.text(l.driverNoRuns), findsNothing);
        await render(runs: []);
        expect(find.text(l.driverNoRuns), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'telemetry $lang distinguishes stale shared receipts from local GPS',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        await t.pumpWidget(
          host(
            lang,
            Scaffold(
              body: SingleChildScrollView(
                child: DriverTelemetryCard(
                  latitude: 6.9,
                  longitude: 79.8,
                  speed: 0,
                  heading: 90,
                  lastPublishedAt: departure.subtract(
                    const Duration(minutes: 6),
                  ),
                  lastFixAt: departure,
                  active: true,
                  publicationStatus:
                      'Pending GPS upload; coordinates are local',
                  now: departure,
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.text(l.driverGpsStale(l.driverGpsPending)), findsOneWidget);
        expect(find.text(l.driverLatitude), findsOneWidget);
        expect(find.text(l.driverLocalFix), findsOneWidget);
        expect(find.text(l.driverGpsAcknowledged), findsNothing);
        expect(find.text('6.900000'), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'vehicle observations $lang send stable values and keep read-only gates',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        String? occupancy;
        bool? ramp;
        Future<void> render(bool assigned, {bool busy = false}) async {
          await t.pumpWidget(
            host(
              lang,
              Scaffold(
                body: SingleChildScrollView(
                  child: DriverVehicleStatusCard(
                    busId: 'bus',
                    isAssignedDriver: assigned,
                    rampOperational: null,
                    liftWorking: true,
                    busy: busy,
                    occupancy: 'Medium',
                    onRamp: (v) => ramp = v,
                    onOccupancy: (v) => occupancy = v,
                  ),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
        }

        await render(true);
        expect(find.text(l.driverUnknownRamp), findsOneWidget);
        await t.tap(find.byType(DropdownButtonFormField<bool>));
        await t.pumpAndSettle();
        await t.tap(find.text(l.driverWorkingObserved).last);
        await t.pumpAndSettle();
        expect(ramp, isTrue);
        await t.ensureVisible(find.byType(DropdownButton<String>));
        await t.tap(find.byType(DropdownButton<String>));
        await t.pumpAndSettle();
        await t.tap(find.text(l.driverHigh).last);
        await t.pumpAndSettle();
        expect(occupancy, 'High');
        await render(false);
        expect(find.text(l.driverReadOnly), findsOneWidget);
        expect(
          t
              .widget<DropdownButtonFormField<bool>>(
                find.byType(DropdownButtonFormField<bool>),
              )
              .onChanged,
          isNull,
        );
        expect(
          t
              .widget<DropdownButton<String>>(
                find.byType(DropdownButton<String>),
              )
              .onChanged,
          isNull,
        );
        await render(true, busy: true);
        expect(
          t
              .widget<DropdownButtonFormField<bool>>(
                find.byType(DropdownButtonFormField<bool>),
              )
              .onChanged,
          isNull,
        );
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'approval gate $lang closes operations after revoked approval',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        final f = ApprovalFixture();
        addTearDown(f.approval.close);
        await t.pumpWidget(
          host(
            lang,
            OperatorAccessGate(
              service: f,
              builder: (_) => const Scaffold(body: Text('operate')),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.text(l.driverChecking), findsOneWidget);
        f.approval.add(false);
        await t.pumpAndSettle();
        expect(find.text(l.driverApprovalRequired), findsOneWidget);
        expect(find.text('operate'), findsNothing);
        f.approval.add(true);
        await t.pumpAndSettle();
        expect(find.text('operate'), findsOneWidget);
        f.approval.add(false);
        await t.pumpAndSettle();
        expect(find.text('operate'), findsNothing);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'route gate $lang keeps assignment private and withdraws controls',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        final f = RouteServiceFake();
        addTearDown(f.close);
        await t.pumpWidget(
          host(
            lang,
            DriverRouteGate(
              service: f,
              builder: (_, route) => Scaffold(body: Text('operate $route')),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.text(l.driverRouteRequired), findsOneWidget);
        expect(find.text(l.driverCheckAssignment), findsOneWidget);
        f.routes['a']!.add('r1');
        await t.pumpAndSettle();
        expect(find.text('operate r1'), findsOneWidget);
        f.routes['a']!.add(null);
        await t.pumpAndSettle();
        expect(find.text('operate r1'), findsNothing);
        expect(t.takeException(), isNull);
      },
    );
  }
}
