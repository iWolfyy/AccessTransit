import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/services/locale_provider.dart';
import 'package:access_transit/core/extensions/context_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Localization & Language Switcher Verification Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('AppLocalizations loads correct translations for English, Sinhala, and Tamil', () async {
      final enLoc = await AppLocalizations.delegate.load(const Locale('en'));
      final siLoc = await AppLocalizations.delegate.load(const Locale('si'));
      final taLoc = await AppLocalizations.delegate.load(const Locale('ta'));

      // Verify English strings
      expect(enLoc.selectLanguageTitle, equals('Select Language'));
      expect(enLoc.reportConditionTitle, equals('Report Route Condition'));
      expect(enLoc.crowdingLow, equals('Low Crowd'));
      expect(enLoc.rewardPointsMessage(10), equals('You earned 10 Community Points!'));

      // Verify Sinhala translations (සිංහල)
      expect(siLoc.selectLanguageTitle, equals('භාෂාව තෝරන්න'));
      expect(siLoc.reportConditionTitle, equals('ගමන් මාර්ග තත්ත්වය වාර්තා කරන්න'));
      expect(siLoc.crowdingLow, equals('අඩු සෙනඟ'));
      expect(siLoc.rewardPointsMessage(10), equals('ඔබ ප්‍රජා ප්‍රසාද ලකුණු 10 ක් දිනා ගත්තා!'));

      // Verify Tamil translations (தமிழ்)
      expect(taLoc.selectLanguageTitle, equals('மொழியைத் தேர்ந்தெடுக்கவும்'));
      expect(taLoc.reportConditionTitle, equals('பயண வழியின் நிலையை அறிவிக்கவும்'));
      expect(taLoc.crowdingLow, equals('குறைந்த கூட்டம்'));
      expect(taLoc.rewardPointsMessage(10), equals('நீங்கள் 10 சமூகப் புள்ளிகளைப் பெற்றுள்ளீர்கள்!'));
    });

    test('LocaleProvider persists selected locale across sessions', () async {
      final provider = LocaleProvider();
      expect(provider.locale, equals(const Locale('en')));

      await provider.setLocale(const Locale('si'));
      expect(provider.locale, equals(const Locale('si')));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_user_locale'), equals('si'));

      // Verify loading saved locale from SharedPreferences
      final newProvider = LocaleProvider();
      await Future.delayed(Duration.zero); // Allow async preference load
      expect(newProvider.locale, equals(const Locale('si')));
    });

    testWidgets('Instant Widget Tree Rebuild on Language Change', (WidgetTester tester) async {
      final provider = LocaleProvider();

      await tester.pumpWidget(
        ListenableBuilder(
          listenable: provider,
          builder: (context, _) {
            return MaterialApp(
              locale: provider.locale,
              supportedLocales: LocaleProvider.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: Text(context.loc.reportConditionTitle),
                  );
                },
              ),
            );
          },
        ),
      );

      // Initially in English
      expect(find.text('Report Route Condition'), findsOneWidget);
      expect(find.text('ගමන් මාර්ග තත්ත්වය වාර්තා කරන්න'), findsNothing);

      // Switch to Sinhala
      await provider.setLocale(const Locale('si'));
      await tester.pumpAndSettle();

      // Instantly rebuilds to Sinhala
      expect(find.text('Report Route Condition'), findsNothing);
      expect(find.text('ගමන් මාර්ග තත්ත්වය වාර්තා කරන්න'), findsOneWidget);

      // Switch to Tamil
      await provider.setLocale(const Locale('ta'));
      await tester.pumpAndSettle();

      // Instantly rebuilds to Tamil
      expect(find.text('ගමන් මාර්ග තත්ත්වය වාර්තා කරන්න'), findsNothing);
      expect(find.text('பயண வழியின் நிலையை அறிவிக்கவும்'), findsOneWidget);
    });
  });
}
