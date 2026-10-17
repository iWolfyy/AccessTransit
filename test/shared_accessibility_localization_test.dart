import 'dart:async';

import 'package:access_transit/core/theme/app_theme.dart';
import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/l10n/driver_presentation.dart';
import 'package:access_transit/models/boarding_request.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:access_transit/services/transit_catalogue.dart';
import 'package:access_transit/widgets/accessible_dropdown.dart';
import 'package:access_transit/widgets/accessible_tap_target.dart';
import 'package:access_transit/widgets/add_station_dialog.dart';
import 'package:access_transit/widgets/assistance_operator_actions.dart';
import 'package:access_transit/widgets/catalogue_notice.dart';
import 'package:access_transit/widgets/stop_alert_unavailable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin_access_gate_test.dart' show FakeAccess;

import 'package:access_transit/widgets/admin_access_gate.dart';

Widget shell(String lang, Widget child, {bool contrast = false}) => MaterialApp(
  locale: Locale(lang),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => ListenableBuilder(
    listenable: AccessibilityPreferencesService.instance,
    builder: (context, _) => Theme(
      data: AppTheme.forPreferences(
        highContrast: contrast,
        largeTargets: AccessibilityPreferencesService.instance.hasLargeTargets,
      ),
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
    ),
  ),
  home: child,
);

void viewport(WidgetTester t) {
  t.view.physicalSize = const Size(320, 1500);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init();
    await AccessibilityPreferencesService.instance.setLargeTargets(true);
    TransitCatalogue.receipts.value = {};
  });
  tearDown(() => TransitCatalogue.receipts.value = {});

  for (final lang in ['en', 'si', 'ta']) {
    for (final contrast in [false, true]) {
      testWidgets(
        '$lang shared controls react to large targets in dialogs contrast=$contrast',
        (t) async {
          viewport(t);
          final l = lookupAppLocalizations(Locale(lang));
          String? selected;
          var tapped = 0;
          await t.pumpWidget(
            shell(
              lang,
              Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    key: const Key('appbar'),
                    onPressed: () {},
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      FilledButton(
                        key: const Key('filled'),
                        onPressed: () {},
                        child: Text(l.sharedRefresh),
                      ),
                      OutlinedButton(
                        key: const Key('outlined'),
                        onPressed: () {},
                        child: Text(l.sharedRefresh),
                      ),
                      TextButton(
                        key: const Key('text'),
                        onPressed: () {},
                        child: Text(l.sharedRefresh),
                      ),
                      IconButton(
                        key: const Key('icon'),
                        onPressed: () {},
                        icon: const Icon(Icons.refresh),
                      ),
                      AccessibleTapTarget(
                        child: InkWell(
                          key: const Key('custom'),
                          onTap: () => tapped++,
                          child: const Icon(Icons.person),
                        ),
                      ),
                      TextFormField(
                        key: const Key('input'),
                        decoration: InputDecoration(
                          labelText: l.sharedStationName,
                        ),
                      ),
                      AccessibleTapTarget(
                        child: FilterChip(
                          key: const Key('chip'),
                          label: Text(l.sharedRefresh),
                          selected: true,
                          onSelected: (_) {},
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        itemHeight: null,
                        isExpanded: true,
                        items: [
                          AccessibleDropdownMenuItem(
                            value: 'stable-id',
                            child: Text(l.sharedCatalogueUnavailable),
                          ),
                        ],
                        onChanged: (v) => selected = v,
                      ),
                      Builder(
                        builder: (context) => TextButton(
                          key: const Key('dialog'),
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: Text(l.sharedAdminAccess),
                              actions: [
                                TextButton(
                                  key: const Key('dialog-action'),
                                  onPressed: () => Navigator.pop(c),
                                  child: Text(l.sharedCancel),
                                ),
                              ],
                            ),
                          ),
                          child: Text(l.sharedCheckAgain),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              contrast: contrast,
            ),
          );
          await t.pumpAndSettle();
          for (final id in [
            'filled',
            'outlined',
            'text',
            'icon',
            'custom',
            'input',
            'chip',
            'appbar',
          ]) {
            final size = t.getSize(find.byKey(Key(id)));
            expect(size.height, greaterThanOrEqualTo(60), reason: id);
            expect(size.width, greaterThanOrEqualTo(60), reason: id);
          }
          await t.tap(find.byKey(const Key('custom')));
          expect(tapped, 1);
          await t.tap(find.byType(DropdownButtonFormField<String>));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          await t.tap(find.text(l.sharedCatalogueUnavailable).last);
          await t.pumpAndSettle();
          expect(selected, 'stable-id');
          await t.ensureVisible(find.byKey(const Key('dialog')));
          await t.tap(find.byKey(const Key('dialog')));
          await t.pumpAndSettle();
          expect(
            t.getSize(find.byKey(const Key('dialog-action'))).height,
            greaterThanOrEqualTo(60),
          );
          await t.tap(find.byKey(const Key('dialog-action')));
          await t.pumpAndSettle();
          await AccessibilityPreferencesService.instance.setLargeTargets(false);
          await t.pumpAndSettle();
          expect(t.getSize(find.byKey(const Key('icon'))), const Size(48, 48));
          expect(t.takeException(), isNull);
        },
      );
    }

    testWidgets(
      '$lang catalogue states and retry receipt stay localized with large text',
      (t) async {
        viewport(t);
        final l = lookupAppLocalizations(Locale(lang));
        var wait = Completer<void>();
        TransitCatalogue.receipts.value = {
          'buses': const CatalogueReceipt(CatalogueSource.saved, null, 2),
        };
        await t.pumpWidget(
          shell(
            lang,
            Scaffold(
              body: SingleChildScrollView(
                child: CatalogueNotice(onRefresh: () => wait.future),
              ),
            ),
            contrast: true,
          ),
        );
        expect(find.text(l.sharedCatalogueSaved), findsOneWidget);
        final refresh = find.widgetWithText(TextButton, l.sharedRefresh);
        expect(t.getSize(refresh).height, greaterThanOrEqualTo(60));
        await t.ensureVisible(refresh);
        await t.tap(refresh);
        await t.pump();
        expect(find.text(l.sharedRefreshing), findsOneWidget);
        wait.complete();
        await t.pumpAndSettle();
        TransitCatalogue.receipts.value = {
          'buses': const CatalogueReceipt(CatalogueSource.unavailable, null, 0),
        };
        await t.pump();
        expect(find.text(l.sharedCatalogueUnavailable), findsOneWidget);
        TransitCatalogue.receipts.value = {
          'buses': const CatalogueReceipt(CatalogueSource.shared, null, 0),
        };
        await t.pump();
        expect(find.text(l.sharedCatalogueEmpty), findsOneWidget);
        wait = Completer<void>();
        await t.ensureVisible(find.text(l.sharedRefresh));
        await t.tap(find.text(l.sharedRefresh));
        await t.pump();
        wait.completeError(StateError('private network detail'));
        await t.pumpAndSettle();
        expect(find.text(l.sharedCatalogueRefreshError), findsOneWidget);
        expect(find.text('private network detail'), findsNothing);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      '$lang admin denial and stop alert remain readable at 320dp/200%',
      (t) async {
        viewport(t);
        t.view.physicalSize = const Size(320, 800);
        final l = lookupAppLocalizations(Locale(lang));
        final access = FakeAccess();
        await t.pumpWidget(
          shell(
            lang,
            AdminAccessGate(service: access, child: const Text('Private')),
            contrast: true,
          ),
        );
        access.changes.add('unapproved');
        await t.pump();
        access.checks['unapproved']!.complete(false);
        await t.pumpAndSettle();
        expect(find.text(l.sharedAdminRequired), findsOneWidget);
        expect(find.text('Private'), findsNothing);
        await t.ensureVisible(find.text(l.sharedCheckAgain));
        expect(
          t
              .getSize(find.widgetWithText(FilledButton, l.sharedCheckAgain))
              .height,
          greaterThanOrEqualTo(60),
        );
        await t.pumpWidget(
          shell(
            lang,
            const Scaffold(
              body: SingleChildScrollView(child: StopAlertUnavailable()),
            ),
            contrast: true,
          ),
        );
        final semantics = t.ensureSemantics();
        expect(find.text(l.sharedStopAlert), findsOneWidget);
        expect(
          find.bySemanticsLabel(
            '${l.sharedStopAlert}. ${l.sharedStopAlertHelp}',
          ),
          findsOneWidget,
        );
        expect(t.takeException(), isNull);
        semantics.dispose();
        await t.pumpWidget(const SizedBox.shrink());
        await access.changes.close();
      },
    );

    testWidgets(
      '$lang driver actions translate busy/failure and preserve acknowledged transitions',
      (t) async {
        viewport(t);
        final l = lookupAppLocalizations(Locale(lang));
        final value = BoardingRequest(
          id: 'shared-test',
          riderId: 'fixture',
          riderName: 'Original Rider',
          busId: 'bus-test',
          routeNo: '138',
          stationId: 'stop-test',
          stopName: 'Original Stop',
          assistanceTypes: const ['Deploy Ramp'],
          status: 'pending',
          createdAt: DateTime(2026, 10, 17),
        );
        var fail = true;
        final gate = Completer<void>();
        final repository = FirestoreService(
          boardingWriter: (r) async => r,
          boardingStatusWriter: (r, status) async {
            if (fail) {
              await gate.future;
              throw StateError('private provider detail');
            }
            return r.copyWith(status: status);
          },
        );
        await repository.publishBoardingRequest(value);
        await t.pumpWidget(
          shell(
            lang,
            Scaffold(
              body: SingleChildScrollView(
                child: AssistanceOperatorActions(
                  request: value,
                  repository: repository,
                ),
              ),
            ),
            contrast: true,
          ),
        );
        expect(
          t
              .getSize(find.widgetWithText(TextButton, l.assistanceDecline))
              .height,
          greaterThanOrEqualTo(60),
        );
        await t.tap(find.text(l.assistanceAcknowledge));
        await t.pump();
        expect(find.text(l.sharedSavingStatus), findsOneWidget);
        gate.complete();
        await t.pumpAndSettle();
        expect(find.text(l.sharedOperatorStatusError), findsOneWidget);
        expect(find.text('private provider detail'), findsNothing);
        expect(find.text(l.assistanceComplete), findsNothing);
        final changedLanguage = lang == 'en' ? 'si' : 'en';
        final changed = lookupAppLocalizations(Locale(changedLanguage));
        await t.pumpWidget(
          shell(
            changedLanguage,
            Scaffold(
              body: SingleChildScrollView(
                child: AssistanceOperatorActions(
                  request: value,
                  repository: repository,
                ),
              ),
            ),
            contrast: true,
          ),
        );
        await t.pumpAndSettle();
        expect(find.text(changed.sharedOperatorStatusError), findsOneWidget);
        fail = false;
        await t.tap(find.text(changed.assistanceAcknowledge));
        await t.pumpAndSettle();
        expect(find.text(changed.assistanceComplete), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets('$lang add-stop dialog validation wraps with large targets', (
      t,
    ) async {
      viewport(t);
      final l = lookupAppLocalizations(Locale(lang));
      await t.pumpWidget(
        shell(
          lang,
          const AddStationDialog(
            buses: [
              Bus(
                id: 'fixture',
                routeNo: '138',
                hasRamp: false,
                lowFloor: false,
                occupancy: 'Low',
              ),
            ],
          ),
          contrast: true,
        ),
      );
      expect(find.text(l.sharedAddStation), findsOneWidget);
      final save = find.text(l.sharedAddStationAction);
      await t.ensureVisible(save);
      await t.tap(save);
      await t.pumpAndSettle();
      expect(find.text(l.sharedRequired), findsNWidgets(2));
      expect(find.text(l.sharedRamp), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets(
      '$lang dynamic delay labels translate units and retain custom reason text',
      (t) async {
        final l = lookupAppLocalizations(Locale(lang));
        await t.pumpWidget(
          shell(
            lang,
            Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    Text(
                      context.driverText(
                        'Delayed by 7 mins • Traffic Congestion',
                      ),
                    ),
                    Text(context.driverText('Running 2 mins early')),
                    Text(
                      context.driverText(
                        'Delayed by 3 mins • Original rider description',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        expect(
          find.text('${l.driverLateMinutes(7)} • ${l.driverTraffic}'),
          findsOneWidget,
        );
        expect(find.text(l.driverEarlyMinutes(2)), findsOneWidget);
        expect(
          find.text('${l.driverLateMinutes(3)} • Original rider description'),
          findsOneWidget,
        );
      },
    );
  }
}
