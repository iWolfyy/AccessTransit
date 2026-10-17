import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/screens/admin/admin_dashboard_screen.dart';
import 'package:access_transit/screens/admin/catalogue_editor_screen.dart';
import 'package:access_transit/services/admin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/memory_admin_repository.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final pair in [
    ('buses', 'Buses'),
    ('routes', 'Routes'),
    ('stations', 'Bus stops'),
  ]) {
    testWidgets(
      '${pair.$1} catalogue loads later pages through an empty search match',
      (t) async {
        final repo = adminFixture();
        addTearDown(repo.dispose);
        for (var n = 0; n < 45; n++) {
          final id = 'z${n.toString().padLeft(3, '0')}';
          repo.seed(pair.$1, id, {
            'name': id,
            'routeNo': id,
            'routeName': id,
            'busNo': id,
          });
        }
        await t.pumpWidget(MaterialApp(home: AdminWorkspace(repository: repo)));
        await t.pumpAndSettle();
        final chip = find.widgetWithText(ChoiceChip, pair.$2);
        await t.ensureVisible(chip);
        await t.tap(chip);
        await t.pumpAndSettle();
        await t.enterText(find.byType(TextField), 'z030');
        await t.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(Card),
            matching: find.textContaining('z030'),
          ),
          findsNothing,
        );
        await t.tap(find.text('Load more'));
        await t.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(Card),
            matching: find.textContaining('z030'),
          ),
          findsWidgets,
        );
      },
    );
  }
  test(
    'editor references include every page, with stable unique IDs',
    () async {
      final repo = adminFixture();
      addTearDown(repo.dispose);
      for (var n = 0; n < 65; n++) {
        repo.seed('stations', 'z$n', {'name': 'Stop $n'});
      }
      final refs = await repo.referencePages('stations');
      expect(refs.length, 67);
      expect(refs.map((r) => r.id).toSet().length, 67);
      expect(refs.any((r) => r.id == 'z64'), true);
    },
  );
  testWidgets(
    'route assignment includes routes beyond the loaded catalogue page',
    (t) async {
      final repo = adminFixture();
      addTearDown(repo.dispose);
      for (var n = 0; n < 45; n++) {
        final id = 'z${n.toString().padLeft(3, '0')}';
        repo.seed('routes', id, {
          'routeNo': id,
          'routeName': 'Route $id',
          'stops': ['s1', 's2'],
        });
      }
      repo.seed('driver_route_assignments', 'driver', {
        'routeId': 'z044',
        'active': true,
      });
      await t.pumpWidget(MaterialApp(home: AdminWorkspace(repository: repo)));
      await t.pumpAndSettle();
      final chip = find.widgetWithText(ChoiceChip, 'Drivers');
      await t.ensureVisible(chip);
      await t.tap(chip);
      await t.pumpAndSettle();
      expect(find.textContaining('Assigned route: z044'), findsOneWidget);
      await t.tap(find.text('Assign route'));
      await t.pumpAndSettle();
      final dropdown = t.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>).first,
      );
      expect(dropdown.items!.any((item) => item.value == 'z044'), true);
    },
  );
  for (final lang in ['en', 'si', 'ta']) {
    testWidgets('catalogue $lang labels wrap at 320dp and 200 percent', (
      t,
    ) async {
      t.view.physicalSize = const Size(320, 1500);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final repo = adminFixture();
      addTearDown(repo.dispose);
      Widget host(Widget child) => MaterialApp(
        locale: Locale(lang),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (c, w) => MediaQuery(
          data: MediaQuery.of(c)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: w!,
        ),
        home: child,
      );
      await t.pumpWidget(host(AdminWorkspace(repository: repo)));
      await t.pumpAndSettle();
      final strings = lookupAppLocalizations(Locale(lang));
      expect(find.text(strings.adminConsole), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(
        host(
          CatalogueEditorScreen(service: AdminService(repo), kind: 'stations'),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text(strings.adminRecordId), findsOneWidget);
      expect(t.takeException(), isNull);
      expect(strings.adminLatitude.contains('???'), false);
    });
  }
  testWidgets(
    'incomplete reference load disables save instead of using partial catalogue',
    (t) async {
      final repo = adminFixture()..failReads = true;
      addTearDown(repo.dispose);
      await t.pumpWidget(
        MaterialApp(
          home: CatalogueEditorScreen(
            service: AdminService(repo),
            kind: 'stations',
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('Save catalogue record'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      final button = t.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save catalogue record'),
      );
      expect(button.onPressed, isNull);
      expect(repo.actions, isEmpty);
    },
  );
}
