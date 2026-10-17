import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:access_transit/models/journey_model.dart';
import 'package:access_transit/services/journey_service.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/screens/journey/saved_trips_screen.dart';
import 'package:access_transit/screens/journey/bus_details_screen.dart';
import 'package:access_transit/widgets/saved_journey_panel.dart';
import 'package:access_transit/l10n/app_localizations.dart';

import 'journey_persistence_flow_test.dart' as f;

JourneyModel record(
  int n, {
  String owner = 'rider',
  JourneyStatus status = JourneyStatus.confirmed,
}) => f.saved().copyWith(
  journeyId: 'saved_${n.toString().padLeft(3, '0')}',
  passengerId: owner,
  status: status,
);

class Records {
  String owner = 'rider';
  bool failPage = false, failRemove = false, failOpen = false;
  final rows = [
    for (var i = 0; i < 45; i++)
      record(
        i,
        status: i == 44 ? JourneyStatus.completed : JourneyStatus.confirmed,
      ),
  ];
  final requests = <String?>[];
  Future<SavedJourneyPage> page(String uid, SavedJourneyCursor? after) async {
    requests.add(after?.id);
    if (failPage) throw StateError('offline');
    final values =
        rows
            .where(
              (r) =>
                  r.passengerId == uid &&
                  (after == null || r.journeyId.compareTo(after.id) < 0),
            )
            .toList()
          ..sort((a, b) => b.journeyId.compareTo(a.journeyId));
    final items = values.take(20).toList();
    return SavedJourneyPage(
      items,
      next: values.length > 20
          ? SavedJourneyCursor(uid, items.last.journeyId)
          : null,
    );
  }

  late final service = JourneyService(
    currentPassengerId: () => owner,
    pageReader: page,
    activeReader: (_) => Stream.value(null),
    journeyReader: (id) =>
        Stream.value(rows.where((r) => r.journeyId == id).firstOrNull),
    savedReader: (id) async {
      if (failOpen) throw StateError('offline');
      return rows.where((r) => r.journeyId == id).firstOrNull;
    },
    remover: (id) async {
      if (failRemove) throw StateError('denied');
      rows.removeWhere((r) => r.journeyId == id);
    },
  );
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
  for (var i = 0; i < 60 && finder.evaluate().isEmpty; i++) {
    scroll.position.jumpTo(
      (scroll.position.pixels + 250).clamp(0, scroll.position.maxScrollExtent),
    );
    await tester.pump();
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init(userId: 'rider');
  });
  test('owner-scoped pages are bounded, stable and retain past/closed/legacy records', () async {
    final r = Records();
    final all = <String>[];
    SavedJourneyCursor? cursor;
    do {
      final page = await r.service.pageSavedJourneys('rider', after: cursor);
      expect(page.items.length, lessThanOrEqualTo(20));
      all.addAll(page.items.map((r) => r.journeyId));
      cursor = page.next;
    } while (cursor != null);
    expect(all.length, 45);
    expect(all.toSet().length, 45);
    expect(all.first, 'saved_044');
    expect(r.requests, [null, 'saved_025', 'saved_005']);
    await expectLater(r.service.pageSavedJourneys('other'), throwsStateError);
    await expectLater(
      r.service.pageSavedJourneys(
        'rider',
        after: const SavedJourneyCursor('other', 'saved_025'),
      ),
      throwsStateError,
    );
    final first = await r.service.pageSavedJourneys('rider');
    r.rows.removeWhere((j) => j.journeyId == first.next!.id);
    final next = await r.service.pageSavedJourneys('rider', after: first.next);
    expect(next.items.first.journeyId, 'saved_024');
  });
  test(
    'wrong-owner, duplicate, excessive and wrong-order pages fail closed',
    () async {
      for (final rows in [
        [record(2, owner: 'other')],
        [record(1), record(1)],
        [for (var i = 21; i >= 0; i--) record(i)],
        [record(1), record(2)],
      ]) {
        final service = JourneyService(
          currentPassengerId: () => 'rider',
          pageReader: (_, _) async => SavedJourneyPage(rows),
        );
        await expectLater(service.pageSavedJourneys('rider'), throwsStateError);
      }
    },
  );
  test('account switch while a page or exact saved read is pending rejects its late response', () async {
    var owner = 'rider';
    final page = Completer<SavedJourneyPage>(),
        read = Completer<JourneyModel?>();
    final service = JourneyService(
      currentPassengerId: () => owner,
      pageReader: (_, _) => page.future,
      savedReader: (_) => read.future,
    );
    final pending = service.pageSavedJourneys('rider'),
        opening = service.getSavedJourney('saved_001', 'rider');
    owner = 'other';
    page.complete(SavedJourneyPage([record(1)]));
    read.complete(record(1));
    await expectLater(pending, throwsStateError);
    await expectLater(opening, throwsStateError);
  });
  testWidgets('Home keeps all-saved entry even when no open preview exists', (
    tester,
  ) async {
    final r = Records();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavedJourneyPanel(userId: 'rider', service: r.service),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('View all saved trips'), findsOneWidget);
    await tester.tap(find.text('View all saved trips'));
    await tester.pumpAndSettle();
    expect(find.byType(SavedTripsScreen), findsOneWidget);
    expect(r.requests, [null]);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'Next/previous pages and a failed next-page retry retain the requested cursor',
    (tester) async {
      final r = Records();
      await tester.pumpWidget(
        MaterialApp(home: SavedTripsScreen(service: r.service)),
      );
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Next page'));
      r.failPage = true;
      await tester.tap(find.text('Next page'));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      r.failPage = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(r.requests, [null, 'saved_025', 'saved_025']);
      await reveal(tester, find.text('Previous page'));
      await tester.tap(find.text('Previous page'));
      await tester.pumpAndSettle();
      expect(r.requests.last, isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'failed removal retains the saved row; acknowledged retry removes only the bookmark',
    (tester) async {
      final r = Records()..rows.removeRange(1, 45);
      r.failRemove = true;
      await tester.pumpWidget(
        MaterialApp(home: SavedTripsScreen(service: r.service)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove saved trip'));
      await tester.pumpAndSettle();
      expect(find.text('Boarding → Destination'), findsOneWidget);
      expect(find.textContaining('Removal is not confirmed'), findsOneWidget);
      r.failRemove = false;
      await tester.tap(find.text('Remove saved trip'));
      await tester.pumpAndSettle();
      expect(find.text('Boarding → Destination'), findsNothing);
      expect(r.rows, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'opening revalidates exact selection and uses the same consolidated Details destination',
    (tester) async {
      final r = Records()..rows.removeRange(1, 45);
      await tester.pumpWidget(
        MaterialApp(
          home: SavedTripsScreen(
            service: r.service,
            repository: f.ResumeCatalog(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open bus details'));
      await tester.pumpAndSettle();
      expect(find.byType(BusDetailsScreen), findsOneWidget);
      final details = tester.widget<BusDetailsScreen>(
        find.byType(BusDetailsScreen),
      );
      expect(details.savedJourney!.journeyId, 'saved_000');
      expect(details.route.selectedTimeMinutes, 540);
      expect(details.route.fromStationId, 'b');
      expect(details.route.toStationId, 'c');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'stale page callbacks cannot display private rows after account switches away and back',
    (tester) async {
      var owner = 'rider';
      final pending = Completer<SavedJourneyPage>();
      final service = JourneyService(
        currentPassengerId: () => owner,
        pageReader: (_, _) => pending.future,
      );
      await tester.pumpWidget(
        MaterialApp(home: SavedTripsScreen(service: service)),
      );
      await tester.pump();
      owner = 'other';
      await AccessibilityPreferencesService.instance.init(userId: 'other');
      await tester.pump();
      owner = 'rider';
      await AccessibilityPreferencesService.instance.init(userId: 'rider');
      pending.complete(SavedJourneyPage([record(1)]));
      await tester.pumpAndSettle();
      expect(find.text('Boarding → Destination'), findsNothing);
      expect(find.textContaining('Account changed'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final locale in ['en', 'si', 'ta']) {
    testWidgets('saved trip list $locale fits 320dp/200 percent text', (
      tester,
    ) async {
      final r = Records()..rows.removeRange(1, 45);
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 760),
              textScaler: TextScaler.linear(2),
            ),
            child: child!,
          ),
          home: SavedTripsScreen(service: r.service),
        ),
      );
      await tester.pumpAndSettle();
      await reveal(tester, find.byType(FilledButton));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
