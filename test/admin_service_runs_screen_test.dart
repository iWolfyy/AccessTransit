import 'package:access_transit/screens/admin/service_runs_screen.dart';
import 'package:access_transit/services/admin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_admin_repository.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'dated-departure editor at text scale $scale publishes and cancels',
      (tester) async {
        final repo = adminFixture();
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(320, 800),
                textScaler: TextScaler.linear(scale),
              ),
              child: ServiceRunsScreen(
                bus: repo.get('buses', 'b1'),
                service: AdminService(repo),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Publish dated departure'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Publish dated departure'));
        await tester.pumpAndSettle();
        expect(
          repo.data['service_runs']!.values.single.text('status'),
          'scheduled',
        );
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Cancel scheduled run'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel scheduled run'));
        await tester.pumpAndSettle();
        expect(
          repo.data['service_runs']!.values.single.text('status'),
          'cancelled',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await repo.dispose();
      },
    );
  }
}
