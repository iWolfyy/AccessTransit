import 'package:access_transit/services/admin_service.dart';
import 'package:access_transit/screens/admin/admin_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/memory_admin_repository.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'users expose bounded pages, loaded-page search and recoverable load-more failure',
    (t) async {
      final repo = adminFixture();
      addTearDown(repo.dispose);
      for (var i = 0; i < 45; i++) {
        final id = 'u${i.toString().padLeft(3, '0')}';
        repo.seed('users', id, {'name': id, 'role': 'passenger'});
      }
      await t.pumpWidget(MaterialApp(home: AdminWorkspace(repository: repo)));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(ChoiceChip, 'Users'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'u030');
      await t.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(Card), matching: find.text('u030')),
        findsNothing,
      );
      expect(find.text('Load more'), findsOneWidget);
      repo.failReads = true;
      await t.tap(find.text('Load more'));
      await t.pumpAndSettle();
      expect(find.text('Retry account status'), findsOneWidget);
      repo.failReads = false;
      await t.tap(find.text('Retry account status'));
      await t.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(Card), matching: find.text('u030')),
        findsOneWidget,
      );
      await t.tap(find.byTooltip('Refresh server data'));
      await t.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(Card), matching: find.text('u030')),
        findsNothing,
      );
    },
  );
  test(
    'activity pages use descending time and stable ID ties; users page by ID',
    () async {
      final repo = adminFixture();
      addTearDown(repo.dispose);
      for (var i = 0; i < 45; i++) {
        repo.seed('admin_audit', 'a${i.toString().padLeft(3, '0')}', {
          'createdAt': '2026-10-17T10:00:00Z',
        });
      }
      final first = await repo.page('admin_audit');
      final second = await repo.page('admin_audit', after: first.next);
      expect(first.items.first.id, 'a044');
      expect(first.items.last.id, 'a025');
      expect(second.items.first.id, 'a024');
      expect(
        {
          ...first.items.map((r) => r.id),
          ...second.items.map((r) => r.id),
        }.length,
        40,
      );
    },
  );
}
