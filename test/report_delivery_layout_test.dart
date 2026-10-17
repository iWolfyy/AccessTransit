import 'dart:io';
import 'dart:ui' as ui;

import 'package:access_transit/core/theme/app_theme.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/screens/journey/report_submitted_screen.dart';
import 'package:access_transit/services/report_outbox_storage.dart';
import 'package:access_transit/services/report_submission_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryStorage extends ReportOutboxStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    this.value = value;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final scenario in [
    (name: 'normal', scale: 1.0, contrast: false),
    (name: 'large', scale: 2.0, contrast: false),
    (name: 'contrast-large', scale: 2.0, contrast: true),
  ]) {
    testWidgets(
      'report receipt ${scenario.name}: retry acknowledges publication without overflow',
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
        final report = Report(
          id: 'private-report-id',
          targetType: 'station',
          targetId: 'private-stop-id',
          targetName: 'Kandy Central Accessible Boarding Area',
          problemType: 'Wheelchair boarding ramp is blocked',
          description: 'Private local note',
          userId: 'private-owner-id',
          status: 'active',
          createdAt: DateTime(2026, 10, 16),
        );
        var failure = 'unavailable';
        final storage = MemoryStorage();
        final service = ReportSubmissionService(
          storage: storage,
          clock: () => DateTime(2026, 10, 16),
          publisher: (_) async {
            if (failure.isNotEmpty) {
              throw FirebaseException(plugin: 'test', code: failure);
            }
          },
        );
        final pending = await service.submit(report);
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
                child: ReportSubmittedScreen(
                  report: pending.report,
                  targetName: report.targetName,
                  submissionService: service,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Pending upload'), findsOneWidget);
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
              'build/ui-report-delivery/${scenario.name}-$suffix.png',
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
        failure = 'permission-denied';
        await tester.tap(find.text('Retry upload'));
        await tester.pumpAndSettle();
        expect(find.text('Failed'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await capture('failed');
        failure = '';
        await tester.ensureVisible(find.text('Retry upload'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Retry upload'));
        await tester.pumpAndSettle();
        expect(find.text('Published'), findsOneWidget);
        expect(
          find.text('Your report is available to other commuters.'),
          findsOneWidget,
        );
        expect(find.text('Retry upload'), findsNothing);
        expect(find.text('Remove draft from this device'), findsNothing);
        expect(service.entries, isEmpty);
        expect(storage.value, '[]');
        await tester.drag(find.byType(ListView), const Offset(0, 1800));
        await tester.pumpAndSettle();
        await capture('published');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        service.dispose();
      },
    );
  }
}
