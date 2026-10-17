import 'dart:io';
import 'dart:ui' as ui;

import 'package:access_transit/core/theme/app_theme.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/widgets/bus_ramp_observation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 16, 12);
  for (final scenario in [
    (name: 'working', condition: true, scale: 1.0, contrast: false),
    (name: 'unknown-large', condition: null, scale: 2.0, contrast: false),
    (name: 'broken-large', condition: false, scale: 2.0, contrast: false),
    (name: 'contrast-large', condition: false, scale: 2.0, contrast: true),
  ]) {
    testWidgets(
      'ramp card ${scenario.name} keeps status readable when collapsed and expanded',
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
        final bus = Bus(
          id: 'layout-bus',
          routeNo: '17',
          hasRamp: true,
          lowFloor: true,
          rampOk: scenario.condition,
          rampCheckedAt: now.subtract(const Duration(minutes: 5)),
          rampCheckedBy: 'private-operator-identifier',
          occupancy: 'low',
        );
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
                    child: BusRampObservation(bus: bus, currentTime: now),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final expected = scenario.condition == true
            ? 'Working observed'
            : scenario.condition == false
            ? 'Broken reported - unresolved warning'
            : 'Unknown - a new check is required';
        expect(find.text(expected), findsOneWidget);
        expect(
          find.text(
            'A working observation does not resolve existing community barriers.',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('private-operator-identifier'),
          findsNothing,
        );
        expect(find.textContaining('Check recorded:'), findsNothing);
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
              'build/ui-ramp-style/${scenario.name}-$suffix.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            picture.dispose();
          });
        }

        await capture('collapsed');
        await tester.tap(find.text('Vehicle ramp'));
        await tester.pumpAndSettle();
        expect(
          find.text('Ramp observation source: Operator observation'),
          findsOneWidget,
        );
        expect(find.textContaining('Check recorded:'), findsOneWidget);
        expect(
          find.textContaining('private-operator-identifier'),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        await capture('expanded');
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
