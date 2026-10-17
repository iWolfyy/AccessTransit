import 'dart:convert';

import 'package:access_transit/l10n/admin_catalogue_labels.dart';
import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/screens/admin/fare_publications_screen.dart';
import 'package:access_transit/screens/admin/route_geometry_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fare_publications_test.dart' as fares;
import 'route_geometry_test.dart' as geometry;

Future<void> reveal(WidgetTester t, Finder target) async {
  final outer = t.state<ScrollableState>(find.byType(Scrollable).first);
  outer.position.jumpTo(0);
  await t.pump();
  for (var i = 0; i < 50 && target.evaluate().isEmpty; i++) {
    outer.position.jumpTo(
      (outer.position.pixels + 200).clamp(0, outer.position.maxScrollExtent),
    );
    await t.pump();
  }
  await t.ensureVisible(target);
  await t.pumpAndSettle();
}

Widget host(String lang, Widget child) => MaterialApp(
  locale: Locale(lang),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: child,
);

void main() {
  for (final lang in ['en', 'si', 'ta']) {
    testWidgets(
      'fare invalid minor units $lang explain the rejected import without writes',
      (t) async {
        final repo = fares.repository();
        addTearDown(repo.dispose);
        final l = lookupAppLocalizations(Locale(lang));
        await t.pumpWidget(
          host(lang, FarePublicationsScreen(repository: repo)),
        );
        await t.pumpAndSettle();
        await t.enterText(find.byKey(const ValueKey('fare-id')), 'fare-v1');
        await reveal(t, find.byKey(const ValueKey('fare-json')));
        await t.enterText(
          find.byKey(const ValueKey('fare-json')),
          jsonEncode(fares.publication(amount: -1)),
        );
        await reveal(t, find.byType(OutlinedButton));
        await t.tap(find.byType(OutlinedButton));
        await t.pumpAndSettle();
        await reveal(t, find.text(l.adminFareMinorInvalid));
        expect(find.text(l.adminFareMinorInvalid), findsOneWidget);
        expect(find.byType(Checkbox), findsNothing);
        expect(repo.actions, isEmpty);
      },
    );
    testWidgets(
      'geometry duplicate reviewed version $lang preserves retry and shows reason',
      (t) async {
        final repo = geometry.repo();
        addTearDown(repo.dispose);
        final l = lookupAppLocalizations(Locale(lang));
        repo.seed('route_geometries', 'route', geometry.geometryData());
        await t.pumpWidget(host(lang, RouteGeometryScreen(repository: repo)));
        await t.pumpAndSettle();
        await t.enterText(
          find.byKey(const ValueKey('geometry-route')),
          'route',
        );
        await reveal(t, find.byKey(const ValueKey('geometry-json')));
        await t.enterText(
          find.byKey(const ValueKey('geometry-json')),
          jsonEncode(geometry.geometryData()),
        );
        await reveal(t, find.byType(OutlinedButton));
        await t.tap(find.byType(OutlinedButton));
        await t.pumpAndSettle();
        await reveal(t, find.byType(Checkbox));
        await t.tap(find.byType(Checkbox));
        await t.pumpAndSettle();
        await reveal(t, find.byKey(const ValueKey('geometry-reason')));
        await t.enterText(
          find.byKey(const ValueKey('geometry-reason')),
          'Reviewed fictional road source',
        );
        await reveal(t, find.byType(FilledButton));
        await t.tap(find.byType(FilledButton));
        await t.pumpAndSettle();
        await reveal(t, find.text(l.adminGeometryVersionRequired));
        expect(find.text(l.adminGeometryVersionRequired), findsOneWidget);
        expect(repo.actions, isEmpty);
        expect(find.text(l.geometrySaved), findsNothing);
      },
    );
  }
  testWidgets(
    'unavailable fare catalogue does not claim empty and unknown state stays unknown',
    (t) async {
      final repo = fares.repository()..failReads = true;
      addTearDown(repo.dispose);
      await t.pumpWidget(host('en', FarePublicationsScreen(repository: repo)));
      await t.pumpAndSettle();
      final l = lookupAppLocalizations(const Locale('en'));
      await reveal(t, find.text(l.adminFareLoadFailed));
      expect(find.text(l.adminFareLoadFailed), findsOneWidget);
      expect(find.text(l.fareNoPublications), findsNothing);
      await t.pumpWidget(
        host(
          'en',
          Builder(builder: (c) => Text(c.adminFareState('future-state'))),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text(l.adminRunUnknown), findsOneWidget);
    },
  );
  testWidgets(
    'geometry validation errors follow locale changes and hide raw JSON parser output',
    (t) async {
      final repo = geometry.repo();
      addTearDown(repo.dispose);
      final locale = ValueNotifier('en');
      addTearDown(locale.dispose);
      await t.pumpWidget(
        ValueListenableBuilder<String>(
          valueListenable: locale,
          builder: (_, value, _) =>
              host(value, RouteGeometryScreen(repository: repo)),
        ),
      );
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const ValueKey('geometry-route')), 'route');
      await reveal(t, find.byKey(const ValueKey('geometry-json')));
      await t.enterText(
        find.byKey(const ValueKey('geometry-json')),
        'untrusted raw JSON',
      );
      await reveal(t, find.byType(OutlinedButton));
      await t.tap(find.byType(OutlinedButton));
      await t.pumpAndSettle();
      locale.value = 'si';
      await t.pumpAndSettle();
      final l = lookupAppLocalizations(const Locale('si'));
      await reveal(t, find.text(l.geometryInvalid));
      expect(find.text(l.geometryInvalid), findsOneWidget);
      expect(find.textContaining('Unexpected character'), findsNothing);
      expect(repo.actions, isEmpty);
    },
  );
}
