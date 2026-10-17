import 'package:access_transit/l10n/admin_catalogue_labels.dart';
import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/screens/admin/catalogue_editor_screen.dart';
import 'package:access_transit/services/admin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_admin_repository.dart';

void main() {
  test(
    'required-field and coordinate metadata preserve validation behavior',
    () {
      expect(
        () => AdminService.requiredText({}, 'name'),
        throwsA(
          isA<AdminValidationException>()
              .having((e) => e.code, 'code', 'required-field')
              .having((e) => e.maximum, 'limit', 200)
              .having(
                (e) => e.message,
                'diagnostic',
                'name is required (maximum 200 characters).',
              ),
        ),
      );
      expect(
        () => AdminService.validate('stations', {
          'name': 'Reviewed stop',
          'sourceUrl': 'https://example.test',
          'lat': 91,
          'lng': 79,
        }),
        throwsA(
          isA<AdminValidationException>()
              .having((e) => e.code, 'code', 'coordinate-invalid')
              .having((e) => e.field, 'field', 'lat'),
        ),
      );
      expect(AdminDependencyException('buses'), isA<StateError>());
    },
  );
  for (final locale in ['en', 'si', 'ta']) {
    testWidgets('structured admin errors retain parameters in $locale', (
      t,
    ) async {
      final l = lookupAppLocalizations(Locale(locale));
      await t.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (c) => Scaffold(
              body: Column(
                children: [
                  Text(
                    c.adminFailure(
                      const AdminValidationException(
                        'required-field',
                        'diagnostic',
                        field: 'name',
                        maximum: 37,
                      ),
                    ),
                  ),
                  Text(
                    c.adminFailure(
                      const AdminValidationException(
                        'coordinate-invalid',
                        'diagnostic',
                        field: 'lat',
                      ),
                    ),
                  ),
                  Text(c.adminFailure(AdminDependencyException('buses'))),
                  Text(
                    c.adminFailure(
                      StateError(
                        'This record changed. Reload it before saving.',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text(l.adminFieldRequired(l.adminName, 37)), findsOneWidget);
      expect(
        find.text(l.adminCoordinateInvalid(l.adminLatitude)),
        findsOneWidget,
      );
      expect(find.text(l.adminDependencyDelete(l.adminBuses)), findsOneWidget);
      expect(find.text(l.adminRecordChanged), findsOneWidget);
      expect(find.text('diagnostic'), findsNothing);
    });
    testWidgets(
      'advanced catalogue controls and validators $locale fit 320dp/200 percent',
      (t) async {
        t.view.physicalSize = const Size(320, 1500);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final repo = adminFixture();
        addTearDown(repo.dispose);
        final l = lookupAppLocalizations(Locale(locale));
        await t.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (c, w) => MediaQuery(
              data: MediaQuery.of(c)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: w!,
            ),
            home: CatalogueEditorScreen(
              service: AdminService(repo),
              kind: 'buses',
              original: repo.get('buses', 'b1'),
            ),
          ),
        );
        await t.pumpAndSettle();
        await t.scrollUntilVisible(
          find.text(l.adminCapabilityHelp),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(t.takeException(), isNull);
        await t.scrollUntilVisible(
          find.text('1. Fort Main Boarding Stop'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.byTooltip(l.adminRemoveStop), findsWidgets);
        expect(t.takeException(), isNull);
        expect(l.adminCapabilityHelp.contains('???'), false);
      },
    );
  }
}
