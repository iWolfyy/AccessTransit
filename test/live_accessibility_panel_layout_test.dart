import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:access_transit/core/theme/app_theme.dart';
import 'package:access_transit/models/enums/report_condition.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/widgets/accessibility_evidence_card.dart';
import 'package:access_transit/widgets/live_accessibility_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 16, 12);
  final reports = [
    Report(
      id: 'ramp',
      targetType: 'bus',
      targetId: 'private-bus-id',
      category: 'rampAccess',
      problemType: 'Ramp working',
      condition: ReportCondition.positive,
      status: 'active',
      createdAt: now.subtract(const Duration(minutes: 5)),
      userId: 'private-reporter-id',
    ),
    Report(
      id: 'elevator',
      targetType: 'station',
      targetId: 'private-boarding-id',
      category: 'elevatorOut',
      problemType: 'Elevator broken',
      condition: ReportCondition.barrier,
      status: 'active',
      createdAt: now.subtract(const Duration(days: 3)),
      userId: 'private-reporter-id',
    ),
    Report(
      id: 'assistance',
      targetType: 'bus',
      targetId: 'private-bus-id',
      category: 'driverAssistanceDenied',
      problemType: 'Driver refused assistance',
      condition: ReportCondition.barrier,
      status: 'active',
      createdAt: now.subtract(const Duration(minutes: 5)),
      userId: 'private-reporter-id',
    ),
  ];
  for (final scenario in [
    (name: 'normal', scale: 1.0, contrast: false),
    (name: 'large', scale: 2.0, contrast: false),
    (name: 'contrast-large', scale: 2.0, contrast: true),
  ]) {
    testWidgets(
      'live panel ${scenario.name}: compact warnings, evidence disclosure and failed-update states',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final font = Platform.environment['UI_FONT_PATH'];
        if (font != null) {
          await (FontLoader('Roboto')..addFont(
                Future.value(
                  ByteData.sublistView(File(font).readAsBytesSync()),
                ),
              ))
              .load();
          await (FontLoader('MaterialIcons')
                ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
              .load();
        }
        final theme = scenario.contrast
            ? AppTheme.highContrastTheme
            : AppTheme.lightTheme;
        final updates = StreamController<List<Report>>();
        final key = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: theme.copyWith(
              textTheme: theme.textTheme.apply(
                fontFamily: font == null ? null : 'Roboto',
              ),
            ),
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(320, 800),
                textScaler: TextScaler.linear(scenario.scale),
              ),
              child: RepaintBoundary(
                key: key,
                child: Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: LiveAccessibilityPanel(
                      busId: 'private-bus-id',
                      originId: 'private-boarding-id',
                      destinationId: 'private-destination-id',
                      origin: 'Panadura Main Boarding Stop',
                      destination: 'Kandy Central Destination Stop',
                      reportsStream: updates.stream,
                      now: () => now,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        updates.add(reports);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Working reported'), findsOneWidget);
        expect(
          find.text('Unresolved barrier \u2014 needs recheck'),
          findsOneWidget,
        );
        expect(find.text('Driver assistance'), findsOneWidget);
        expect(find.text('Barrier reported'), findsOneWidget);
        expect(find.text('Unknown'), findsOneWidget);
        expect(find.byType(AccessibilityEvidenceCard), findsNothing);
        expect(find.textContaining('private-'), findsNothing);
        Future<void> capture(String suffix) async {
          if (Platform.environment['UI_CAPTURE'] != 'true') return;
          await tester.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final picture = await boundary.toImage(pixelRatio: 2);
            final bytes = await picture.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File(
              'build/ui-live-panel-style/${scenario.name}-$suffix.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            picture.dispose();
          });
        }

        await capture('overview');
        await tester.scrollUntilVisible(
          find.text('View observation details').hitTestable(),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('View observation details'));
        await tester.pumpAndSettle();
        expect(find.byType(AccessibilityEvidenceCard), findsOneWidget);
        expect(find.textContaining('Reported at:'), findsNWidgets(3));
        expect(find.textContaining('private-'), findsNothing);
        expect(tester.takeException(), isNull);
        await capture('details');
        updates.addError(StateError('offline'));
        await tester.pumpAndSettle();
        expect(find.text('Working reported'), findsNothing);
        expect(
          find.textContaining('Condition updates unavailable'),
          findsOneWidget,
        );
        expect(find.text('Barrier reported'), findsOneWidget);
        expect(
          find.text('Unresolved barrier \u2014 needs recheck'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        unawaited(updates.close());
      },
    );
  }
}
