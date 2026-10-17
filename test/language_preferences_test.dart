import 'dart:async';

import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/services/language_preferences_service.dart';
import 'package:access_transit/widgets/language_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageStorage extends Fake implements SharedPreferences {
  final values = <String, String>{};
  Completer<void>? gate;
  bool reject = false;

  @override
  String? getString(String key) => values[key];

  @override
  Future<bool> setString(String key, String value) async {
    if (gate != null) await gate!.future;
    if (reject) return false;
    values[key] = value;
    return true;
  }
}

void main() {
  test(
    'account and guest selections stay isolated and restore on return',
    () async {
      final storage = LanguageStorage();
      final service = LanguagePreferencesService();
      addTearDown(service.dispose);
      await service.init(prefs: storage);
      await service.setLanguage('si');
      service.activateAccount('a');
      expect(service.locale.languageCode, 'en');
      await service.setLanguage('ta');
      service.activateAccount('b');
      expect(service.locale.languageCode, 'en');
      service.activateAccount(null);
      expect(service.locale.languageCode, 'si');
      service.activateAccount('a');
      expect(service.locale.languageCode, 'ta');
      storage.values[LanguagePreferencesService.storageKey('b')] = 'invalid';
      service.activateAccount('b');
      expect(service.locale.languageCode, 'en');
    },
  );

  test('delayed old-owner save does not change the new account', () async {
    final storage = LanguageStorage();
    final service = LanguagePreferencesService();
    addTearDown(service.dispose);
    await service.init(prefs: storage, userId: 'a');
    storage.gate = Completer<void>();
    final saving = service.setLanguage('ta');
    await Future<void>.delayed(Duration.zero);
    service.activateAccount('b');
    storage.gate!.complete();
    await saving;
    expect(service.locale.languageCode, 'en');
    expect(storage.values[LanguagePreferencesService.storageKey('b')], isNull);
    service.activateAccount('a');
    expect(service.locale.languageCode, 'ta');
  });

  test(
    'rejected saves retain selected language; later saves recover',
    () async {
      final storage = LanguageStorage();
      final service = LanguagePreferencesService();
      addTearDown(service.dispose);
      await service.init(prefs: storage);
      storage.reject = true;
      await expectLater(service.setLanguage('ta'), throwsStateError);
      expect(service.locale.languageCode, 'en');
      storage.reject = false;
      await service.setLanguage('si');
      expect(service.locale.languageCode, 'si');
      await expectLater(
        service.setLanguage('unsupported'),
        throwsArgumentError,
      );
    },
  );

  testWidgets('all three locales load Material delegates and named messages', (
    tester,
  ) async {
    for (final code in ['en', 'si', 'ta']) {
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(code),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: Text(AppLocalizations.of(context)!.accountReady('Nimal')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Nimal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'language selector changes locale and restores after rejected save',
    (tester) async {
      final storage = LanguageStorage();
      final service = LanguagePreferencesService();
      addTearDown(service.dispose);
      await service.init(prefs: storage);
      await tester.pumpWidget(
        ListenableBuilder(
          listenable: service,
          builder: (context, _) => MaterialApp(
            locale: service.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: SizedBox(
                width: 320,
                child: MediaQuery(
                  data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LanguageSelector(service: service),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('தமிழ்').last);
      await tester.pumpAndSettle();
      expect(service.locale.languageCode, 'ta');
      expect(find.text('மொழி'), findsOneWidget);
      storage.reject = true;
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('සිංහල').last);
      await tester.pumpAndSettle();
      expect(service.locale.languageCode, 'ta');
      final field = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(field.initialValue, 'ta');
      expect(tester.takeException(), isNull);
    },
  );
}
