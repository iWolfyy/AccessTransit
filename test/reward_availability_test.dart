import 'package:access_transit/screens/profile/membership_card_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('high points cannot claim cash or deduct a balance', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MembershipCardScreen(memberName: 'Rider', points: 200),
      ),
    );
    final claim = find.widgetWithText(FilledButton, 'Redemption unavailable');
    await tester.scrollUntilVisible(claim, 200);
    expect(tester.widget<FilledButton>(claim).onPressed, isNull);
    expect(find.text('Points have no cash or voucher value'), findsOneWidget);
    expect(find.textContaining('Reward Claimed'), findsNothing);
  });
}
