import 'dart:io';
import 'dart:ui' as ui;

import 'package:access_transit/core/theme/app_theme.dart';
import 'package:access_transit/models/enums/report_condition.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/widgets/accessibility_evidence_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 16, 12);
  final reports = [
    Report(
      id: 'positive',
      targetType: 'bus',
      targetId: 'layout-bus',
      problemType: 'Ramp working',
      condition: ReportCondition.positive,
      status: 'active',
      createdAt: now.subtract(const Duration(minutes: 5)),
      userId: 'private-reporter-id',
      confirmedBy: const [
        'private-confirmer-a',
        'private-confirmer-a',
        'private-confirmer-b',
      ],
      confirmCount: 2,
      lastConfirmedAt: now.subtract(const Duration(minutes: 2)),
    ),
    Report(
      id: 'barrier',
      targetType: 'bus',
      targetId: 'layout-bus',
      problemType: 'Ramp broken',
      condition: ReportCondition.barrier,
      status: 'active',
      createdAt: now.subtract(const Duration(days: 3)),
      userId: 'private-reporter-id',
      lastRecheckedAt: now.subtract(const Duration(days: 2)),
      lastRecheckedBy: 'private-rechecker-id',
    ),
  ];
  for (final scenario in [
    (name: 'normal', scale: 1.0, contrast: false),
    (name: 'large', scale: 2.0, contrast: false),
    (name: 'contrast-large', scale: 2.0, contrast: true),
  ]) {
    testWidgets(
      'evidence ${scenario.name}: unresolved barrier remains visible beside newer positive checks',
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
                    child: AccessibilityEvidenceCard(
                      reports: reports,
                      busId: 'layout-bus',
                      origin: 'boarding-stop',
                      destination: 'destination-stop',
                      strictStopIds: true,
                      currentTime: now,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Unresolved barrier - needs recheck'), findsOneWidget);
        expect(find.text('Positive observation - view details'), findsNothing);
        expect(find.textContaining('Reported at:'), findsNothing);
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
              'build/ui-evidence-style/${scenario.name}-$suffix.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            picture.dispose();
          });
        }

        await capture('collapsed');
        await Scrollable.ensureVisible(
          tester.element(find.text('Vehicle ramp conditions')),
          alignment: .5,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Vehicle ramp conditions'));
        await tester.pumpAndSettle();
        expect(find.text('Ramp working'), findsOneWidget);
        expect(find.text('Ramp broken'), findsOneWidget);
        expect(find.text('Confirmed by: 2 community members'), findsOneWidget);
        expect(
          find.textContaining(
            'by Community member. Unique confirmations unchanged.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('private-'), findsNothing);
        expect(tester.takeException(), isNull);
        await capture('expanded');
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
