import 'package:access_transit/widgets/stop_alert_unavailable.dart';
import 'package:access_transit/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'unavailable alert cannot toggle or claim notification delivery',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StopAlertUnavailable())),
      );
      final button = find.byType(OutlinedButton);
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
      await tester.tap(button, warnIfMissed: false);
      await tester.pump();
      expect(find.text('Stop alert unavailable'), findsOneWidget);
      expect(find.text('Alert Active'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    },
  );

  testWidgets('screen readers receive disabled state and delivery limitation', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StopAlertUnavailable())),
    );
    final node = tester.getSemantics(find.byType(StopAlertUnavailable));
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
    expect(node.label, contains('background notifications are unavailable'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    semantics.dispose();
  });

  testWidgets(
    'availability is readable at 200 percent text in a narrow action row',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.highContrastTheme,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  width: 320,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(child: StopAlertUnavailable()),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {},
                              child: const Text('Assistance'),
                            ),
                          ),
                        ],
                      ),
                      const Text(StopAlertUnavailable.explanation),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(StopAlertUnavailable.explanation), findsOneWidget);
      expect(
        tester.getSize(find.byType(OutlinedButton)).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    },
  );
}
