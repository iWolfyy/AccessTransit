import 'dart:io';
import 'dart:ui' as ui;

import 'package:access_transit/core/theme/app_theme.dart';
import 'package:access_transit/logic/journey_fare.dart';
import 'package:access_transit/models/bus.dart';
import 'package:access_transit/screens/journey/journey_confirmation_screen.dart';
import 'package:access_transit/screens/journey/route_results_screen.dart';
import 'package:access_transit/services/journey_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final scenario in [
    (name: 'normal', scale: 1.0, contrast: false),
    (name: 'large', scale: 2.0, contrast: false),
    (name: 'contrast-large', scale: 2.0, contrast: true),
  ]) {
    testWidgets(
      'confirmation ${scenario.name}: full names, fare disclosure and save failure remain usable',
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
        final route = RouteResultItem(
          id: 'layout-route',
          title: 'Route 17 - private-bus-id',
          busId: 'private-bus-id',
          rawBus: const Bus(
            id: 'private-bus-id',
            routeNo: '17',
            hasRamp: false,
            lowFloor: false,
            occupancy: 'unknown',
            stops: ['private-boarding-id', 'private-destination-id'],
          ),
          busNo: 'private-bus-id',
          routeNo: '17',
          durationMinutes: 90,
          etaLabel: 'Scheduled',
          transfers: 0,
          crowdLevel: 'Unknown',
          accessibilityStatus: AccessibilityStatus.unknown,
          accessibilityLabel: 'Unknown',
          safetyLabel: 'Review evidence',
          summary: '',
          origin: 'Panadura Main Boarding Stop',
          destination: 'Kandy Central Destination Stop',
          fromStationId: 'private-boarding-id',
          toStationId: 'private-destination-id',
          selectedDate: DateTime(2026, 10, 17),
          selectedTimeMinutes: 540,
          nextDepartureDateTime: DateTime(2026, 10, 17, 9),
          estimatedPriceLkr: 150,
          wheelchairAccessRequired: true,
          stepFreeOnly: true,
          usesEstimatedTimes: true,
        );
        var writes = 0;
        final service = JourneyService(
          currentPassengerId: () => 'layout-rider',
          writer: (_) async {
            writes++;
            throw StateError('Connection unavailable. Please retry.');
          },
        );
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
                child: JourneyConfirmationScreen(
                  origin: route.origin,
                  destination: route.destination,
                  route: route,
                  service: service,
                  onSaved: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(route.origin), findsOneWidget);
        expect(find.text(route.destination), findsOneWidget);
        expect(find.text('Vehicle not specified'), findsOneWidget);
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
              'build/ui-confirmation-style/${scenario.name}-$suffix.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            picture.dispose();
          });
        }

        await capture('overview');
        await tester.scrollUntilVisible(
          find.text('Fare details').hitTestable(),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Fare details'));
        await tester.pumpAndSettle();
        expect(find.text(JourneyFare.disclosure), findsOneWidget);
        expect(tester.takeException(), isNull);
        await capture('fare');
        await tester.scrollUntilVisible(
          find.text('Confirm and save journey').hitTestable(),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Confirm and save journey'));
        await tester.pumpAndSettle();
        expect(writes, 1);
        expect(
          find.text('Connection unavailable. Please retry.'),
          findsOneWidget,
        );
        expect(find.byType(JourneyConfirmationScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        await capture('failure');
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
