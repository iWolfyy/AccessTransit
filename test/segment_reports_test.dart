import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/screens/journey/segment_reports_screen.dart';
import 'package:access_transit/services/bus_details_repository.dart';
import 'package:access_transit/services/segment_reports.dart';
import 'package:access_transit/l10n/app_localizations.dart';

class Repository extends BusDetailsRepository {
  final events = <StreamController<SegmentReportPage>>[];
  final requests = <(String, String?)>[];
  @override
  Stream<SegmentReportPage> reportPage(ReportTarget target, {String? after}) {
    requests.add((target.key, after));
    final c = StreamController<SegmentReportPage>();
    events.add(c);
    return c.stream;
  }

  void emit(List<Report> reports, {String? next}) =>
      events.last.add(SegmentReportPage(reports, next: next));
  void close() {
    for (final c in events) {
      unawaited(c.close());
    }
  }
}

Report current(String id, {String type = 'bus', String target = 'physical'}) =>
    Report(
      id: id,
      targetType: type,
      targetId: target,
      targetName: target,
      problemType: 'Condition $id',
      severity: 'minor',
      status: 'active',
      createdAt: DateTime.now(),
      userId: 'other',
    );
Widget host(Repository repo, {String locale = 'en'}) => MaterialApp(
  locale: Locale(locale),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: SegmentReportsScreen(
    busId: 'physical',
    busName: 'TEST BUS',
    stops: const {'b': 'Boarding', 'c': 'Intermediate', 'd': 'Destination'},
    repository: repo,
  ),
);
void main() {
  testWidgets(
    'exact target page excludes unrelated reports and removes hidden/errored visible state',
    (tester) async {
      final r = Repository();
      addTearDown(r.close);
      await tester.pumpWidget(host(r));
      await tester.pump();
      expect(r.requests, [('bus/physical', null)]);
      r.emit([
        current('one'),
        current('foreign', target: 'other'),
        current('stop', type: 'station', target: 'c'),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Condition one'), findsOneWidget);
      expect(find.text('Condition foreign'), findsNothing);
      expect(find.text('Condition stop'), findsNothing);
      r.emit([current('one').copyWith(status: 'hidden')]);
      await tester.pumpAndSettle();
      expect(find.text('Condition one'), findsNothing);
      r.emit([current('two')]);
      await tester.pumpAndSettle();
      r.events.last.addError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text('Condition two'), findsNothing);
      expect(find.textContaining('Reports unavailable'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'next/previous retain boundaries; target change clears old rows and starts at first page',
    (tester) async {
      final r = Repository();
      addTearDown(r.close);
      await tester.pumpWidget(host(r));
      await tester.pump();
      r.emit([current('one')], next: 'cursor-one');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next page'));
      await tester.pump();
      expect(r.requests.last, ('bus/physical', 'cursor-one'));
      expect(find.text('Condition one'), findsNothing);
      r.emit([], next: 'cursor-two');
      await tester.pumpAndSettle();
      expect(find.text('Next page'), findsOneWidget);
      await tester.tap(find.text('Previous page'));
      await tester.pump();
      expect(r.requests.last, ('bus/physical', null));
      r.emit([current('one')]);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Intermediate').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(r.requests.last, ('station/c', null));
      expect(find.text('Condition one'), findsNothing);
      r.emit([current('stop', type: 'station', target: 'c')]);
      await tester.pumpAndSettle();
      expect(find.text('Condition stop'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final locale in ['en', 'si', 'ta']) {
    testWidgets('scoped reports $locale fits narrow screen at 200 percent', (
      tester,
    ) async {
      final r = Repository();
      addTearDown(r.close);
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
          home: SegmentReportsScreen(
            busId: 'physical',
            busName: 'TEST BUS',
            stops: const {'b': 'Boarding'},
            repository: r,
          ),
        ),
      );
      await tester.pump();
      r.emit([current('one')]);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
