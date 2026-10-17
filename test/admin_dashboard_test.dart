import 'dart:io';
import 'dart:ui' as ui;

import 'package:access_transit/core/theme/app_theme.dart';
import 'package:access_transit/screens/admin/admin_dashboard_screen.dart';
import 'package:access_transit/screens/admin/catalogue_editor_screen.dart';
import 'package:access_transit/services/admin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/memory_admin_repository.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final scenario in [
    (name: 'normal', scale: 1.0, contrast: false),
    (name: 'large', scale: 2.0, contrast: false),
    (name: 'contrast', scale: 2.0, contrast: true),
  ]) {
    final boundaryKey = GlobalKey();
    Future<void> capture(WidgetTester tester, String name) async {
      if (Platform.environment['UI_CAPTURE'] != 'true') return;
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final picture = await boundary.toImage(pixelRatio: 2);
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/ui-admin/${scenario.name}-$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        picture.dispose();
      });
    }

    Future<void> mount(WidgetTester tester, Widget page) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var theme = scenario.contrast
          ? AppTheme.highContrastTheme
          : AppTheme.lightTheme;
      final font = Platform.environment['UI_FONT_PATH'];
      if (font != null) {
        await (FontLoader('Roboto')..addFont(
              Future.value(ByteData.sublistView(File(font).readAsBytesSync())),
            ))
            .load();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
        theme = theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
          appBarTheme: theme.appBarTheme.copyWith(
            titleTextStyle: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: theme.filledButtonTheme.style?.copyWith(
              textStyle: const WidgetStatePropertyAll(
                TextStyle(fontFamily: 'Roboto', fontSize: 16),
              ),
            ),
          ),
        );
      }
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(320, 800),
              textScaler: TextScaler.linear(scenario.scale),
            ),
            child: RepaintBoundary(key: boundaryKey, child: page),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'admin workspace ${scenario.name}: pending registration, approval and offline guard',
      (tester) async {
        final repository = adminFixture();
        await mount(tester, AdminWorkspace(repository: repository));
        await capture(tester, 'overview');
        final tab = find.text('Drivers');
        await tester.ensureVisible(tab);
        await tester.pumpAndSettle();
        await tester.tap(tab);
        await tester.pumpAndSettle();
        expect(find.textContaining('Pending review'), findsOneWidget);
        final review = find.text('Review access');
        await tester.ensureVisible(review);
        await tester.pumpAndSettle();
        await tester.tap(review);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Confirm decision'),
              )
              .onPressed,
          isNull,
        );
        await tester.enterText(
          find.byType(TextField).last,
          'Licence and operating authority reviewed against supplied documents.',
        );
        final check = find.byType(CheckboxListTile);
        await tester.ensureVisible(check);
        await tester.pumpAndSettle();
        await tester.tap(check);
        await tester.pumpAndSettle();
        final confirm = find.text('Confirm decision');
        await tester.ensureVisible(confirm);
        await tester.pumpAndSettle();
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        expect(
          repository.get('operator_access', 'driver').data['approved'],
          isTrue,
        );
        expect(find.textContaining('operator | Approved'), findsOneWidget);
        // Let the acknowledged-approval snackbar dismiss before tapping a
        // lower-page action at 200% text size.
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Assign route'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Assign route'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('1 - Fort to Kandy').last);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField).last,
          'Approved route and direction reviewed.',
        );
        await tester.ensureVisible(find.text('Save assignment'));
        await tester.tap(find.text('Save assignment'));
        await tester.pumpAndSettle();
        expect(
          repository.get('driver_route_assignments', 'driver').text('routeId'),
          'r1',
        );
        expect(
          find.textContaining('Assigned route: 1 - Fort to Kandy'),
          findsOneWidget,
        );
        await capture(tester, 'drivers');
        repository.failStream('users');
        await tester.pumpAndSettle();
        expect(find.text('Server data unavailable.'), findsOneWidget);
        expect(find.text('Review access'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await repository.dispose();
      },
    );
    testWidgets(
      'stop editor ${scenario.name}: validates and acknowledges a new sourced stop',
      (tester) async {
        final repository = adminFixture();
        await mount(
          tester,
          CatalogueEditorScreen(
            service: AdminService(repository),
            kind: 'stations',
          ),
        );
        for (final (label, value) in [
          ('Record ID', 'new_stop'),
          ('Stop name', 'New Boarding Stop'),
          ('Latitude', '6.93'),
          ('Longitude', '79.85'),
          ('Source URL', 'https://example.test/source'),
        ]) {
          final field = find.widgetWithText(TextFormField, label);
          await tester.ensureVisible(field);
          await tester.pumpAndSettle();
          await tester.enterText(field, value);
        }
        final checkbox = find.byType(CheckboxListTile);
        await tester.ensureVisible(checkbox);
        await tester.pumpAndSettle();
        await tester.tap(checkbox);
        await tester.pumpAndSettle();
        final save = find.text('Save catalogue record');
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(
          repository.get('stations', 'new_stop').text('name'),
          'New Boarding Stop',
        );
        expect(repository.get('stations', 'new_stop').data['hasRamp'], isNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await repository.dispose();
      },
    );
  }
}
