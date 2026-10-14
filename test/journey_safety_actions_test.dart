import 'package:access_transit/screens/journey/live_journey_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'unavailable emergency action cannot claim contact; reporting remains enabled',
    (tester) async {
      var reportsOpened = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: JourneySafetyActions(onReport: () => reportsOpened++),
            ),
          ),
        ),
      );
      final emergency = find.widgetWithText(FilledButton, 'Emergency');
      expect(tester.widget<FilledButton>(emergency).onPressed, isNull);
      expect(
        find.text(
          'Emergency calling is unavailable in this app. Use your phone to call for help.',
        ),
        findsOneWidget,
      );
      await tester.tap(emergency);
      await tester.pump();
      expect(find.text('Emergency services contacted.'), findsNothing);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Report Issue'));
      expect(reportsOpened, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
