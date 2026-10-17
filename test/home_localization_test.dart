import 'dart:async';

import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/l10n/home_presentation.dart';
import 'package:access_transit/models/enums/user_role.dart';
import 'package:access_transit/models/journey_model.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/models/user_model.dart';
import 'package:access_transit/screens/home/home_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
void narrow(WidgetTester t) {
  t.view.physicalSize = const Size(320, 1500);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

const user = UserModel(
  uid: '',
  name: 'Community Original',
  email: 'original@example.com',
  role: UserRole.passenger,
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init();
    await AccessibilityPreferencesService.instance.setHighContrast(false);
  });
  for (final lang in ['en', 'si', 'ta']) {
    testWidgets(
      'Home $lang recent segment keeps original endpoints and updates on locale change',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        final journeys = StreamController<List<JourneyModel>>();
        addTearDown(journeys.close);
        const record = JourneyModel(
          journeyId: 'saved',
          passengerId: '',
          routeId: 'route',
          routeNumber: '138',
          routeTitle: 'Original route',
          busId: 'bus',
          origin: 'Home',
          destination: 'Profile',
        );
        final reportStream = Stream.value(<Report>[]);
        await t.pumpWidget(
          host(
            lang,
            HomeScreen(
              initialUser: user,
              reports: reportStream,
              recentJourneys: journeys.stream,
            ),
          ),
        );
        await t.pump();
        journeys.add([record]);
        await t.pumpAndSettle();
        await t.scrollUntilVisible(
          find.text(l.homeJourneySegment('Home', 'Profile')),
          350,
          scrollable: find.byType(Scrollable).first,
        );
        await t.pumpAndSettle();
        expect(
          find.text(l.homeJourneySegment('Home', 'Profile')),
          findsOneWidget,
        );
        final other = lang == 'en' ? 'ta' : 'en';
        final nextLabels = lookupAppLocalizations(Locale(other));
        await t.pumpWidget(
          host(
            other,
            HomeScreen(
              initialUser: user,
              reports: reportStream,
              recentJourneys: journeys.stream,
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(
          find.text(nextLabels.homeJourneySegment('Home', 'Profile')),
          findsOneWidget,
        );
        expect(find.text(nextLabels.homeReplan), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets('desktop Home $lang navigates with stable Profile key', (
      t,
    ) async {
      t.view.physicalSize = const Size(1100, 1500);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final l = lookupAppLocalizations(Locale(lang));
      await t.pumpWidget(
        host(
          lang,
          HomeScreen(
            initialUser: user,
            reports: Stream.value([]),
            recentJourneys: Stream.value([]),
          ),
        ),
      );
      await t.pumpAndSettle();
      final profileTab = find.text(l.homeProfile).first;
      await t.ensureVisible(profileTab);
      await t.pumpAndSettle();
      await t.tap(profileTab);
      await t.pumpAndSettle();
      expect(find.text(l.profilePersonalInfo), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets(
      'Home $lang labels and drawer preserve name and unavailable actions at 320dp/200%',
      (t) async {
        narrow(t);
        await AccessibilityPreferencesService.instance.setHighContrast(true);
        final l = lookupAppLocalizations(Locale(lang));
        await t.pumpWidget(
          host(
            lang,
            HomeScreen(
              initialUser: user,
              reports: Stream.value([]),
              recentJourneys: Stream.value([]),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.text(l.homeWhere), findsOneWidget);
        await t.scrollUntilVisible(
          find.text(l.homeTrack),
          350,
          scrollable: find.byType(Scrollable).first,
        );
        await t.pumpAndSettle();
        expect(find.text(l.homeTrack), findsOneWidget);
        await t.scrollUntilVisible(
          find.byTooltip(l.homeMenu),
          -350,
          scrollable: find.byType(Scrollable).first,
        );
        await t.pumpAndSettle();
        await t.tap(find.byTooltip(l.homeMenu));
        await t.pumpAndSettle();
        expect(find.text('Community Original'), findsOneWidget);
        expect(find.text(l.profileCommuter), findsOneWidget);
        await t.scrollUntilVisible(
          find.text(l.profilePlaces),
          250,
          scrollable: find
              .descendant(
                of: find.byType(Drawer),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await t.pumpAndSettle();
        await t.tap(find.text(l.profilePlaces));
        await t.pumpAndSettle();
        expect(find.text(l.profileComingSoon(l.profilePlaces)), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'Home $lang live report hide removes cached card and keeps authored text original',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        final reports = StreamController<List<Report>>();
        addTearDown(reports.close);
        final report = Report(
          id: 'fixture',
          targetType: 'station',
          targetId: 'stop',
          targetName: 'Profile',
          problemType: 'Original condition',
          status: 'active',
          createdAt: DateTime.now(),
          userId: 'author',
          policyVersion: 2,
          falseCount: 4,
        );
        await t.pumpWidget(
          host(
            lang,
            HomeScreen(
              initialUser: user,
              reports: reports.stream,
              recentJourneys: Stream.value([]),
            ),
          ),
        );
        await t.pump();
        reports.add([report]);
        await t.pumpAndSettle();
        await t.scrollUntilVisible(
          find.text('Original condition'),
          350,
          scrollable: find.byType(Scrollable).first,
        );
        await t.pumpAndSettle();
        expect(find.text('Profile'), findsOneWidget);
        expect(find.text(l.homeFalseCount(4, 5)), findsOneWidget);
        reports.add([report.copyWith(status: 'hidden', falseCount: 5)]);
        await t.pumpAndSettle();
        expect(find.text('Original condition'), findsNothing);
        expect(find.text(l.homeNoReports), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'Home $lang distinguishes unavailable streams from empty results',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        final reports = StreamController<List<Report>>();
        final journeys = StreamController<List<JourneyModel>>();
        addTearDown(reports.close);
        addTearDown(journeys.close);
        await t.pumpWidget(
          host(
            lang,
            HomeScreen(
              initialUser: user,
              reports: reports.stream,
              recentJourneys: journeys.stream,
            ),
          ),
        );
        await t.pump();
        reports.addError(StateError('private backend detail'));
        journeys.addError(StateError('private backend detail'));
        await t.pumpAndSettle();
        await t.scrollUntilVisible(
          find.text(l.homeJourneysUnavailable),
          350,
          scrollable: find.byType(Scrollable).first,
        );
        await t.pumpAndSettle();
        expect(find.text(l.homeReportsUnavailable), findsOneWidget);
        expect(find.text(l.homeNoReports), findsNothing);
        expect(find.text(l.homeNoJourney), findsNothing);
        expect(find.textContaining('private backend detail'), findsNothing);
        reports.add([]);
        journeys.add([]);
        await t.pumpAndSettle();
        expect(find.text(l.homeNoReports), findsOneWidget);
        expect(find.text(l.homeNoJourney), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets('Home ages $lang retain boundary and missing-time behavior', (
      t,
    ) async {
      late BuildContext c;
      final l = lookupAppLocalizations(Locale(lang));
      final now = DateTime.utc(2026, 10, 17, 10);
      await t.pumpWidget(
        host(
          lang,
          Builder(
            builder: (context) {
              c = context;
              return const SizedBox();
            },
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(c.homeAge(null, clock: now), l.homeUnknownAge);
      expect(c.homeAge(now, clock: now), l.homeJustNow);
      expect(
        c.homeAge(now.subtract(const Duration(minutes: 2)), clock: now),
        l.homeMinutesAgo(2),
      );
      expect(
        c.homeAge(now.subtract(const Duration(hours: 1)), clock: now),
        l.homeHoursAgo(1),
      );
      expect(
        c.homeAge(now.subtract(const Duration(days: 2)), clock: now),
        l.homeDaysAgo(2),
      );
      expect(
        c.homeAge(now.subtract(const Duration(days: 60)), clock: now),
        l.homeMonthsAgo(2),
      );
    });
  }
}
