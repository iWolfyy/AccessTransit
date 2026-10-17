import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:access_transit/core/theme/app_theme.dart';
import 'package:access_transit/models/boarding_request.dart';
import 'package:access_transit/screens/journey/assistance_request_status_screen.dart';
import 'package:access_transit/services/assistance_submission_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final scenario in [
    (name: 'normal', scale: 1.0, contrast: false),
    (name: 'large', scale: 2.0, contrast: false),
    (name: 'contrast-large', scale: 2.0, contrast: true),
  ]) {
    testWidgets(
      'assistance receipt ${scenario.name}: delivery and driver states remain distinct and readable',
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
        final renderTheme = font == null
            ? theme
            : theme.copyWith(
                appBarTheme: theme.appBarTheme.copyWith(
                  titleTextStyle:
                      (theme.appBarTheme.titleTextStyle ?? const TextStyle())
                          .copyWith(fontFamily: 'Roboto'),
                ),
                filledButtonTheme: FilledButtonThemeData(
                  style: (theme.filledButtonTheme.style ?? const ButtonStyle())
                      .copyWith(
                        textStyle: WidgetStatePropertyAll(
                          (theme.filledButtonTheme.style?.textStyle?.resolve(
                                    {},
                                  ) ??
                                  const TextStyle())
                              .copyWith(fontFamily: 'Roboto'),
                        ),
                      ),
                ),
              );
        final request = BoardingRequest(
          id: 'private-request-id',
          riderId: 'layout-rider',
          riderName: 'Rider',
          busId: 'private-bus-id',
          stationId: 'private-stop-id',
          routeNo: '138',
          stopName: 'Kandy Central Accessible Boarding Area',
          purpose: 'alighting',
          assistanceTypes: const [
            'Deploy Ramp',
            'Extra Time',
            'Alighting Help',
          ],
          status: 'pending',
          createdAt: DateTime.now(),
        );
        final service = AssistanceSubmissionService(
          currentRiderId: () => 'layout-rider',
          publisher: (_) async => throw StateError('offline'),
        );
        await service.enqueue(request);
        final updates = StreamController<BoardingRequest?>();
        final key = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: renderTheme.copyWith(
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
                child: AssistanceRequestStatusScreen(
                  request: request,
                  service: service,
                  requestUpdates: updates.stream,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Pending upload'), findsOneWidget);
        expect(
          find.text('Driver acknowledgement is not confirmed.'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Getting off at Kandy Central'),
          findsOneWidget,
        );
        expect(find.textContaining('private-'), findsNothing);
        expect(tester.takeException(), isNull);
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
              'build/ui-assistance-status/${scenario.name}-$suffix.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            picture.dispose();
          });
        }

        await capture('pending');
        await tester.scrollUntilVisible(
          find.text('Retry upload').hitTestable(),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Retry upload'));
        await tester.pumpAndSettle();
        expect(find.text('Failed'), findsOneWidget);
        expect(find.text('Sent to shared service'), findsNothing);
        expect(find.text('Retry upload'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await capture('failed');
        for (final status in [
          'pending',
          'acknowledged',
          'completed',
          'rejected',
          'cancelled',
        ]) {
          final remote = request.copyWith(status: status);
          updates.add(remote);
          await tester.pumpAndSettle();
          expect(find.text('Sent to shared service'), findsOneWidget);
          expect(find.text(remote.driverStatusLabel), findsOneWidget);
          expect(find.text('Retry upload'), findsNothing);
          expect(
            find.text('Cancel request'),
            const ['pending', 'acknowledged'].contains(status)
                ? findsOneWidget
                : findsNothing,
          );
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox.shrink());
        unawaited(updates.close());
        service.dispose();
      },
    );
  }
}
