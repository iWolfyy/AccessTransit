import 'dart:async';

import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/models/boarding_request.dart';
import 'package:access_transit/screens/journey/assistance_request_status_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/services/assistance_submission_service.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:access_transit/widgets/app_bottom_nav_bar.dart';
import 'package:access_transit/widgets/assistance_requests_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'registration_onboarding_localization_test.dart' show host, narrow;

BoardingRequest receipt({int policy = 2}) => BoardingRequest(
  id: 'receipt',
  riderId: 'owner',
  riderName: 'Original Rider',
  busId: 'bus',
  routeNo: '138',
  stationId: 'stop',
  stopName: 'Original stop',
  purpose: 'alighting',
  assistanceTypes: const [
    'Deploy Ramp',
    'Extra Time',
    'Alighting Help',
    'Original custom help',
  ],
  status: 'pending',
  createdAt: DateTime.now(),
  policyVersion: policy,
);

class ReceiptRepository extends FirestoreService {
  final rows = StreamController<List<BoardingRequest>>.broadcast();
  @override
  Stream<List<BoardingRequest>> streamBoardingRequestsForRider(String id) =>
      rows.stream;
  @override
  Stream<BoardingRequest?> watchBoardingRequest(String id) =>
      Stream.value(null);
  @override
  Future<BoardingRequest> updateBoardingRequestStatus(
    String id,
    String status,
  ) async => throw StateError('private provider error');
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init();
    await AccessibilityPreferencesService.instance.setHighContrast(false);
  });
  for (final lang in ['en', 'si', 'ta']) {
    for (final contrast in [false, true]) {
      testWidgets(
        '$lang bottom navigation routes canonical IDs and updates locale contrast=$contrast',
        (t) async {
          narrow(t);
          await AccessibilityPreferencesService.instance.setHighContrast(
            contrast,
          );
          var selected = 'Home';
          Widget ui(String locale) => host(
            locale,
            StatefulBuilder(
              builder: (context, update) => Scaffold(
                body: Text('selected:$selected'),
                bottomNavigationBar: AppBottomNavBar(
                  currentTab: selected,
                  onTabSelected: (id) => update(() => selected = id),
                ),
              ),
            ),
          );
          await t.pumpWidget(ui(lang));
          await t.pumpAndSettle();
          final l = lookupAppLocalizations(Locale(lang));
          for (final tab in [
            ('Home', l.homeHome),
            ('Plan', l.homePlan),
            ('Community', l.homeCommunity),
            ('Profile', l.homeProfile),
          ]) {
            expect(find.text(tab.$2), findsOneWidget);
            await t.tap(find.text(tab.$2));
            await t.pumpAndSettle();
            expect(selected, tab.$1);
            expect(find.text('selected:${tab.$1}'), findsOneWidget);
            expect(
              t.getSize(find.byKey(ValueKey('main-nav-${tab.$1}'))).height,
              greaterThanOrEqualTo(48),
            );
            final semantics = find
                .ancestor(
                  of: find.text(tab.$2),
                  matching: find.byWidgetPredicate(
                    (w) => w is Semantics && w.properties.selected != null,
                  ),
                )
                .first;
            expect(t.widget<Semantics>(semantics).properties.selected, isTrue);
          }
          await t.pumpWidget(ui(lang == 'en' ? 'si' : 'en'));
          await t.pumpAndSettle();
          expect(selected, 'Profile');
          expect(
            t.widget<AppBottomNavBar>(find.byType(AppBottomNavBar)).currentTab,
            'Profile',
          );
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
        },
      );

      testWidgets(
        '$lang receipt separates delivery, acceptance and completion contrast=$contrast',
        (t) async {
          narrow(t);
          await AccessibilityPreferencesService.instance.setHighContrast(
            contrast,
          );
          var actor = 'owner', attempts = 0;
          final value = receipt(policy: contrast ? 2 : 1);
          final acknowledgement = Completer<BoardingRequest>();
          final service = AssistanceSubmissionService(
            currentRiderId: () => actor,
            publisher: (r) {
              if (++attempts == 1) throw StateError('private provider error');
              return acknowledgement.future;
            },
          );
          final repo = ReceiptRepository();
          final updates = StreamController<BoardingRequest?>.broadcast();
          addTearDown(service.dispose);
          addTearDown(repo.rows.close);
          addTearDown(updates.close);
          await service.enqueue(value);
          await t.pumpWidget(
            host(
              lang,
              AssistanceRequestStatusScreen(
                request: value,
                service: service,
                repository: repo,
                requestUpdates: updates.stream,
              ),
            ),
          );
          await t.pumpAndSettle();
          final l = lookupAppLocalizations(Locale(lang));
          expect(find.text(l.assistReceiptPendingUpload), findsOneWidget);
          expect(find.text(l.assistReceiptUnconfirmed), findsOneWidget);
          expect(find.text('Original custom help'), findsOneWidget);
          await service.retry(value.id);
          await t.pumpAndSettle();
          expect(find.text(l.assistReceiptFailed), findsOneWidget);
          expect(find.text(l.assistReceiptSendError), findsOneWidget);
          expect(find.textContaining('private provider'), findsNothing);
          await t.ensureVisible(find.text(l.assistReceiptRetry));
          await t.pumpAndSettle();
          await t.tap(find.text(l.assistReceiptRetry));
          await t.pumpAndSettle();
          expect(find.text(l.assistReceiptSent), findsNothing);
          acknowledgement.complete(value);
          await t.pumpAndSettle();
          expect(find.text(l.assistReceiptSent), findsOneWidget);
          expect(find.text(l.assistancePending), findsOneWidget);
          updates.add(value.copyWith(status: 'acknowledged'));
          await t.pumpAndSettle();
          expect(find.text(l.assistanceAccepted), findsOneWidget);
          expect(find.text(l.assistReceiptAcceptedHint), findsOneWidget);
          await t.ensureVisible(find.text(l.assistReceiptCancel));
          await t.pumpAndSettle();
          await t.tap(find.text(l.assistReceiptCancel));
          await t.pumpAndSettle();
          expect(find.text(l.assistReceiptCancelError), findsOneWidget);
          expect(find.text(l.assistanceCancelled), findsNothing);
          updates.add(value.copyWith(status: 'completed'));
          await t.pumpAndSettle();
          expect(find.text(l.assistanceCompleted), findsOneWidget);
          expect(find.text(l.assistReceiptCancel), findsNothing);
          actor = 'other';
          service.notifyListeners();
          await t.pumpAndSettle();
          expect(find.text(l.assistReceiptOwner), findsOneWidget);
          expect(find.text('Original custom help'), findsNothing);
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
        },
      );
    }
    testWidgets(
      '$lang saved receipts localize failures and hide other accounts',
      (t) async {
        narrow(t);
        var actor = 'owner';
        final value = receipt();
        final service = AssistanceSubmissionService(
          currentRiderId: () => actor,
        );
        final repo = ReceiptRepository();
        addTearDown(service.dispose);
        addTearDown(repo.rows.close);
        await service.enqueue(value);
        service.loadError = 'unknown private storage details';
        Widget ui() => host(
          lang,
          Scaffold(
            body: SingleChildScrollView(
              child: AssistanceRequestsPanel(
                userId: actor,
                service: service,
                repository: repo,
              ),
            ),
          ),
        );
        await t.pumpWidget(ui());
        await t.pumpAndSettle();
        final l = lookupAppLocalizations(Locale(lang));
        expect(find.text(l.assistReceiptPendingUpload), findsOneWidget);
        expect(
          find.text(l.assistReceiptSummary('138', 'Original stop')),
          findsOneWidget,
        );
        expect(find.text(l.assistReceiptError), findsOneWidget);
        expect(find.textContaining('private storage'), findsNothing);
        repo.rows.addError(StateError('offline'));
        await t.pumpAndSettle();
        expect(find.text(l.assistReceiptHistoryStale), findsOneWidget);
        actor = 'other';
        await t.pumpWidget(ui());
        await t.pumpAndSettle();
        expect(find.textContaining('Original stop'), findsNothing);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
}
